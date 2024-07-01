$modulePath = Join-Path -Path (Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent) -ChildPath 'Modules'

# Import the WebAdministrationDsc Common Modules
Import-Module -Name (Join-Path -Path $modulePath `
        -ChildPath (Join-Path -Path 'WebAdministrationDsc.Common' `
            -ChildPath 'WebAdministrationDsc.Common.psm1'))

Import-Module -Name (Join-Path -Path $modulePath -ChildPath 'DscResource.Common')

# Import Localization Strings
$script:localizedData = Get-LocalizedData -DefaultUICulture 'en-US'

function Get-TargetResource
{
    <#
    .SYNOPSIS
        This will return a hashtable of results
    #>
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Website,

        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [System.String]
        $WebApplication,

        [Parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [Parameter(Mandatory = $true)]
        [System.String]
        $PhysicalPath,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $Credential
    )

    Assert-Module -ModuleName WebAdministration

    $virtualDirectory = Get-WebVirtualDirectory -Site $Website `
                                                -Name $Name `
                                                -Application $WebApplication

    $PhysicalPath = ''
    $Ensure = 'Absent'
    $Credential = $null

    if ($virtualDirectory.Count -eq 1)
    {
        $PhysicalPath = $virtualDirectory.PhysicalPath
        $Ensure = 'Present'

        if ([System.String]::IsNullOrEmpty($WebApplication))
        {
            $itemPath = "IIS:Sites\$Website\$Name"
        }
        else
        {
            $itemPath = "IIS:Sites\$Website\$WebApplication\$Name"
        }

        $userName = (Get-ItemProperty $itemPath -Name UserName).Value
        if (-not [System.String]::IsNullOrEmpty($userName))
        {
            $password = New-Object System.Security.SecureString # Blank Password
            $secStringPassword = $password | ConvertTo-SecureString -AsPlainText -Force
            $Credential = New-Object System.Management.Automation.PSCredential ($userName, $secStringPassword)
        }
    }

    Write-Verbose -Message ($script:localizedData.VerboseGetTargetResource)

    $returnValue = @{
        Name           = $Name
        Website        = $Website
        WebApplication = $WebApplication
        PhysicalPath   = $PhysicalPath
        Credential     = $Credential
        Ensure         = $Ensure
    }

    return $returnValue
}

function Set-TargetResource
{
    <#
    .SYNOPSIS
        This will set the desired state
    #>
    [CmdletBinding()]
    param
    (
        [Parameter()]
        [ValidateSet('Present','Absent')]
        [System.String]
        $Ensure = 'Present',

        [Parameter(Mandatory = $true)]
        [System.String]
        $Website,

        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [System.String]
        $WebApplication,

        [Parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [Parameter(Mandatory = $true)]
        [System.String]
        $PhysicalPath,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $Credential
    )

    Assert-Module -ModuleName WebAdministration

    if ($Ensure -eq 'Present')
    {
        <#
            Issue #366
            WebApplication = '/' will cause New-WebVirtualDirectory to write
            double slash ('//$Name') to config file.
            This in turn causes Get-WebVirtualDirectory to not find the Virtual Directory.
            WebApplication = '' works.
            Note the opposite problem with Remove-WebVirtualDirectory.
        #>
        if ($WebApplication -eq '/')
        {
            $WebApplication = ''
        }

        if ([System.String]::IsNullOrEmpty($WebApplication))
        {
            $itemPath = "IIS:Sites\$Website\$Name"
        }
        else
        {
            $itemPath = "IIS:Sites\$Website\$WebApplication\$Name"
        }

        $virtualDirectory = Get-WebVirtualDirectory -Site $Website `
                                                    -Name $Name `
                                                    -Application $WebApplication
        if ($virtualDirectory.count -eq 0)
        {
            Write-Verbose -Message ($script:localizedData.VerboseSetTargetCreateVirtualDirectory -f $Name)
            if (([System.Uri] $PhysicalPath).IsUnc)
            {
                # If physical path is provided using Unc syntax run New-WebVirtualDirectory with -Force flag
                New-WebVirtualDirectory -Site $Website `
                                        -Application $WebApplication `
                                        -Name $Name `
                                        -PhysicalPath $PhysicalPath `
                                        -ErrorAction Stop `
                                        -Force
            }
            else
            {
                # Run New-WebVirtualDirectory without -Force flag to verify that the path exists
                New-WebVirtualDirectory -Site $Website `
                                        -Application $WebApplication `
                                        -Name $Name `
                                        -PhysicalPath $PhysicalPath `
                                        -ErrorAction Stop
            }
        }
        else
        {
            Write-Verbose -Message ($script:localizedData.VerboseSetTargetPhysicalPath -f $Name)

            Set-ItemProperty -Path $itemPath `
                             -Name physicalPath `
                             -Value $PhysicalPath
        }

        if ($Credential)
        {
            Write-Verbose -Message ($script:localizedData.VerboseSetTargetCredential -f $Name)

            Set-ItemProperty $itemPath -Name UserName -Value $Credential.UserName
            Set-ItemProperty $itemPath -Name Password -Value $Credential.GetNetworkCredential().Password
        }
    }

    if ($Ensure -eq 'Absent')
    {
        <#
            Issue #366
            WebApplication = '' will cause Remove-WebVirtualDirectory to throw
            "PowerShell Desired State Configuration does not support execution of commands in an interactive mode ...".
            WebApplication = '/' works.
            Note the opposite problem with New-WebVirtualDirectory.
        #>
        if ($WebApplication -eq '')
        {
            $WebApplication = '/'
        }

        Write-Verbose -Message ($script:localizedData.VerboseSetTargetRemoveVirtualDirectory -f $Name)
        Remove-WebVirtualDirectory -Site $Website `
                                   -Application $WebApplication `
                                   -Name $Name
    }
}

function Test-TargetResource
{
    <#
    .SYNOPSIS
        This tests the desired state. If the state is not correct it will return $false.
        If the state is correct it will return $true
    #>
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter()]
        [ValidateSet('Present','Absent')]
        [System.String]
        $Ensure = 'Present',

        [Parameter(Mandatory = $true)]
        [System.String]
        $Website,

        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [System.String]
        $WebApplication,

        [Parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [Parameter(Mandatory = $true)]
        [System.String]
        $PhysicalPath,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $Credential
    )

    Assert-Module -ModuleName WebAdministration

    $virtualDirectory = Get-WebVirtualDirectory -Site $Website `
                                                -Name $Name `
                                                -Application $WebApplication

    if ($virtualDirectory.Count -eq 1 -and $Ensure -eq 'Present')
    {
        if ($virtualDirectory.PhysicalPath -eq $PhysicalPath)
        {
            if (-not $Credential)
            {
                Write-Verbose -Message ($script:localizedData.VerboseTestTargetTrue)
                return $true
            }

            if ([System.String]::IsNullOrEmpty($WebApplication))
            {
                $itemPath = "IIS:Sites\$Website\$Name"
            }
            else
            {
                $itemPath = "IIS:Sites\$Website\$WebApplication\$Name"
            }

            $userName = (Get-ItemProperty $itemPath -Name UserName).Value
            $password = (Get-ItemProperty $itemPath -Name Password).Value

            if (($Credential.UserName -eq $userName -and $Credential.GetNetworkCredential().Password -eq $password))
            {
                Write-Verbose -Message ($script:localizedData.VerboseTestTargetTrue)
                return $true
            }
            else
            {
                Write-Verbose -Message ($script:localizedData.VerboseTestTargetCredentialFalse -f $PhysicalPath, $Name)
                return $false
            }
        }
        else
        {
            Write-Verbose -Message ($script:localizedData.VerboseTestTargetPhysicalPathFalse -f $Credential.UserName, $Name)
            return $false
        }
    }

    if ($virtualDirectory.count -eq 0 -and $Ensure -eq 'Absent')
    {
        Write-Verbose -Message ($script:localizedData.VerboseTestTargetAbsentTrue -f $Name)
        return $true
    }

    return $false
}

Export-ModuleMember -Function *-TargetResource
