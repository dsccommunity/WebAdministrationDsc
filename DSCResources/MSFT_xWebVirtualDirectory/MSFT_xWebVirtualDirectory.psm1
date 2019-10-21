# Load the Helper Module
Import-Module -Name "$PSScriptRoot\..\Helper.psm1"

# Localized messages
data LocalizedData
{
    # culture="en-US"
    ConvertFrom-StringData -StringData @'
        VerboseGetTargetResource               = Get-TargetResource has been run.
        VerboseSetTargetPhysicalPath           = Updating physical path for web virtual directory "{0}".
        VerboseSetTargetCreateVirtualDirectory = Creating new Web Virtual Directory "{0}".
        VerboseSetTargetRemoveVirtualDirectory = Removing existing Virtual Directory "{0}".
        VerboseTestTargetFalse                 = Physical path "{0}" for web virtual directory "{1}" does not match desired state.
        VerboseTestTargetTrue                  = Web virtual directory is in required state.
        VerboseTestTargetAbsentTrue            = Web virtual directory "{0}" should be absent and is absent.
'@
}

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

    Assert-Module

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

    Write-Verbose -Message ($LocalizedData.VerboseGetTargetResource)

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

    Assert-Module

    if ($Ensure -eq 'Present')
    {
        $virtualDirectory = Get-WebVirtualDirectory -Site $Website `
                                                    -Name $Name `
                                                    -Application $WebApplication
        if ($virtualDirectory.count -eq 0)
        {
            Write-Verbose -Message ($LocalizedData.VerboseSetTargetCreateVirtualDirectory -f $Name)
            New-WebVirtualDirectory -Site $Website `
                                    -Application $WebApplication `
                                    -Name $Name `
                                    -PhysicalPath $PhysicalPath
        }
        else
        {
            Write-Verbose -Message ($LocalizedData.VerboseSetTargetPhysicalPath -f $Name)

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
        Write-Verbose -Message ($LocalizedData.VerboseSetTargetRemoveVirtualDirectory -f $Name)
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

    Assert-Module

    $virtualDirectory = Get-WebVirtualDirectory -Site $Website `
                                                -Name $Name `
                                                -Application $WebApplication

    if ($virtualDirectory.Count -eq 1 -and $Ensure -eq 'Present')
    {
        if ($virtualDirectory.PhysicalPath -eq $PhysicalPath)
        {
            Write-Verbose -Message ($LocalizedData.VerboseTestTargetTrue)
            return $true
        }
        else
        {
            Write-Verbose -Message ($LocalizedData.VerboseTestTargetFalse -f $PhysicalPath, $Name)
            return $false
        }
    }

    if ($virtualDirectory.count -eq 0 -and $Ensure -eq 'Absent')
    {
        Write-Verbose -Message ($LocalizedData.VerboseTestTargetAbsentTrue -f $Name)
        return $true
    }

    return $false
}

function Export-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param()

    $InformationPreference = 'Continue'
    Write-Information 'Extracting xWebVirtualDirectory...'
    $webSites = Get-WebSite

    $sb = [System.Text.StringBuilder]::new()
    $i = 1
    foreach($website in $webSites)
    {
        Write-Information "    [$i/$($webSites.Count)] Getting Virtual Directories from WebSite {$($website.Name)}"
        Write-Verbose "WebSite: $($website.name)"
        $webVirtualDirectories = Get-WebVirtualDirectory -Site $website.name

        if($webVirtualDirectories)
        {
            $j =1
            foreach($webvirtualdirectory in $webVirtualDirectories)
            {
                Write-Information "        [$j/$($webVirtualDirectories.Count)] $($webvirtualdirectory.PhysicalPath)"
                Write-Verbose "WebSite/VirtualDirectory: $($website.name)$($webvirtualdirectory.PhysicalPath)"
                $params = Get-DSCFakeParameters -ModulePath $PSScriptRoot

                <# Setting Primary Keys #>
                if ($null -ne $webvirtualdirectory.Name)
                {
                    $params.Name = $webvirtualdirectory.Name
                }
                else
                {
                    $params.Name = $webvirtualdirectory.Path
                }
                $params.PhysicalPath = $webvirtualdirectory.PhysicalPath
                $params.WebApplication = ''
                $params.Website = $website.Name
                <# Setting Required Keys #>
                #$params.PhysicalPath  = $webapplication.PhysicalPath
                Write-Verbose 'Key parameters as follows'
                $params | ConvertTo-Json | Write-Verbose

                $results = Get-TargetResource @params

                Write-Verbose 'All Parameters with values'
                $results | ConvertTo-Json | Write-Verbose

                [void]$sb.AppendLine('        xWebVirtualDirectory ' + (New-Guid).ToString())
                [void]$sb.AppendLine('        {')
                $dscBlock = Get-DSCBlock -Params $results -ModulePath $PSScriptRoot
                [void]$sb.Append($dscBlock)
                [void]$sb.AppendLine('        }')
                $j++
            }
        }
        $i++
    }
    return $sb.ToString()
}

Export-ModuleMember -Function *-TargetResource
