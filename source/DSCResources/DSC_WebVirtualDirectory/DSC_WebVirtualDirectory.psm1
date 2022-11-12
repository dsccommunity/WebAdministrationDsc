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
        $PhysicalPath
    )

    Assert-Module -ModuleName WebAdministration

    $virtualDirectory = Get-WebVirtualDirectory -Site $Website `
                                                -Name $Name `
                                                -Application $WebApplication

    $PhysicalPath = ''
    $Ensure = 'Absent'

    if ($virtualDirectory.Count -eq 1)
    {
        $PhysicalPath = $virtualDirectory.PhysicalPath
        $Ensure = 'Present'
    }

    Write-Verbose -Message ($script:localizedData.VerboseGetTargetResource)

    $returnValue = @{
        Name           = $Name
        Website        = $Website
        WebApplication = $WebApplication
        PhysicalPath   = $PhysicalPath
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
        $PhysicalPath
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

        $virtualDirectory = Get-WebVirtualDirectory -Site $Website `
                                                    -Name $Name `
                                                    -Application $WebApplication
        if ($virtualDirectory.count -eq 0)
        {
            Write-Verbose -Message ($script:localizedData.VerboseSetTargetCreateVirtualDirectory -f $Name)
            New-WebVirtualDirectory -Site $Website `
                                    -Application $WebApplication `
                                    -Name $Name `
                                    -PhysicalPath $PhysicalPath
        }
        else
        {
            Write-Verbose -Message ($script:localizedData.VerboseSetTargetPhysicalPath -f $Name)

            if ($WebApplication.Length -gt 0)
            {
                $ItemPath = "IIS:Sites\$Website\$WebApplication\$Name"
            }
            else
            {
                $ItemPath = "IIS:Sites\$Website\$Name"
            }

            Set-ItemProperty -Path $ItemPath `
                             -Name physicalPath `
                             -Value $PhysicalPath
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
        $PhysicalPath
    )

    Assert-Module -ModuleName WebAdministration

    $virtualDirectory = Get-WebVirtualDirectory -Site $Website `
                                                -Name $Name `
                                                -Application $WebApplication

    if ($virtualDirectory.Count -eq 1 -and $Ensure -eq 'Present')
    {
        if ($virtualDirectory.PhysicalPath -eq $PhysicalPath)
        {
            Write-Verbose -Message ($script:localizedData.VerboseTestTargetTrue)
            return $true
        }
        else
        {
            Write-Verbose -Message ($script:localizedData.VerboseTestTargetFalse -f $PhysicalPath, $Name)
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
