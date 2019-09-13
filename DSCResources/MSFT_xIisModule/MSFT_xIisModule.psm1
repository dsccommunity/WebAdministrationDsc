# Load the Helper Module
Import-Module -Name "$PSScriptRoot\..\Helper.psm1"

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
        $Name,

        [Parameter(Mandatory = $true)]
        [System.String]
        $SiteName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $Code,

        [Parameter()]
        [ValidateSet('Present', 'Absent')]
        [System.String]
        $Ensure= "Present"
    )

    Assert-Module
    Write-Verbose "Calling Get-TargetResource for $Name"
    # We are looking at the root, therefore remove the asterik
    if ('*' -eq $SiteName)
    {
        $SiteName = ""
    }
    $module = Get-WebManagedModule -Name $Name -Location $SiteName

    if($null -eq $module)
    {
        $returnValue = @{
            Name     = $Name
            SiteName = $SiteName
            Code     = $Code
            Ensure   = "Absent"
        }
    }
    else
    {
        $returnValue = @{
            Name     = $module.Name
            SiteName = $SiteName
            Code     = $module.Type
            Ensure   = "Present"
        }
    }

    $returnValue
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
        [Parameter(Mandatory = $true)]
        [String] $Name,

        [Parameter(Mandatory = $true)]
        [String] $SiteName,

        [Parameter(Mandatory = $true)]
        [String] $Code,

        [Parameter()]
        [ValidateSet('Present', 'Absent')]
        [System.String]
        $Ensure= "Present"
    )

    $resourceStatus = Get-TargetResource @PSBoundParameters

    if($Ensure -eq 'Present')
    {
        Write-Verbose "Setting Configuration"
        if($resourceTests.ModulePresent -and -not $resourceTests.ModuleConfigured)
        {
            Remove-IisHandler -Name $Name -SiteName $SiteName
        }

        if(-not $resourceTests.ModulePresent -or -not $resourceTests.ModuleConfigured)
        {
            Add-webconfiguration /system.webServer/handlers iis:\ -Value @{
                Name = $Name
                Path = $RequestPath
                Verb = $Verb -join ','
                Module = $ModuleType
                ScriptProcessor = $Path
            }
        }
    }
    else
    {
        Write-Verbose -Message $LocalizedData.VerboseSetTargetRemoveHandler
        Remove-IisHandler -Name $Name -SiteName $SiteName
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
        [Parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [Parameter(Mandatory = $true)]
        [System.String]
        $SiteName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $Code,

        [Parameter()]
        [ValidateSet('Present', 'Absent')]
        [System.String]
        $Ensure = "Present"
    )
    $resourceStatus = Get-TargetResource @PSBoundParameters

    $result = $true
    if ($resourceStatus.Ensure -ne $Ensure -or $resourceStatus.SiteName -ne $SiteName -or $resourceStatus.Code -ne $Code)
    {
        return $false
    }
    Write-Verbose "Testing $Name"
    return $result
}

function Export-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.String])]

    $InformationPreference = "Continue"
    Write-Information "Extracting xIISModule..."

    $Modules =  Get-WebManagedModule

    Write-Information "    Modules Defined at Root Level:"
    $i = 1
    foreach ($Module in $Modules)
    {
        Write-Information "        [$i/$($Modules.Count)] $($Module.Name)"
        $params = @{
            Name     = $Module.Name
            SiteName = "*"
            Code     = $Module.Type
            Ensure   = "Present"
        }
        $results = Get-TargetResource @params
        $DSCConfigContent += "        xIISModule " + (New-Guid).ToString() + "`r`n        {`r`n"
        $DSCConfigContent += Get-DSCBlock -Params $results -ModulePath $dscmodule
        $DSCConfigContent += "        }`r`n"
        $i++
    }

    $sites = Get-Website

    foreach ($site in $sites)
    {
        Write-Information "    Modules Defined at Site Level {$($site.Name)}"
        $Modules =  Get-WebManagedModule -Location $site.Name
        $i = 1
        foreach ($Module in $Modules)
        {
            Write-Information "        [$i/$($Modules.Count)] $($Module.Name)"
            $params =@{
                Name     = $Module.Name
                SiteName = $site.Name
                Code     = $Module.Type
                Ensure   = "Present"
            }
            $results = Get-TargetResource @params
            $DSCConfigContent += "        xIISModule " + (New-Guid).ToString() + "`r`n        {`r`n"
            $DSCConfigContent += Get-DSCBlock -Params $results -ModulePath $dscmodule
            $DSCConfigContent += "        }`r`n"
            $i++
        }
    }
    return $DSCConfigContent
}

#region Helper Functions


#endregion

Export-ModuleMember -Function *-TargetResource
