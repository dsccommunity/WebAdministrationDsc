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
        $SiteName = "*",

        [Parameter(Mandatory = $true)]
        [System.String]
        $Code,

        [Parameter(Mandatory = $true)]
        [ValidateSet('Present', 'Absent')]
        [System.String]
        $Ensure
    )

    Assert-Module
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

        [Parameter(Mandatory = $true)]
        [ValidateSet('Present', 'Absent')]
        [String] $Ensure
    )

    $resourceStatus = Get-TargetResource @PSBoundParameters

    if($Ensure -eq 'Present')
    {
        if($resourceTests.ModulePresent -and -not $resourceTests.ModuleConfigured)
        {
            Write-Verbose -Message $LocalizedData.VerboseSetTargetRemoveHandler
            Remove-IisHandler -Name $Name -SiteName $SiteName
        }

        if(-not $resourceTests.ModulePresent -or -not $resourceTests.ModuleConfigured)
        {
            Write-Verbose -Message $LocalizedData.VerboseSetTargetAddHandler
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

        [Parameter(Mandatory = $true)]
        [ValidateSet('Present', 'Absent')]
        [System.String]
        $Ensure
    )
    $resourceStatus = Get-TargetResource @PSBoundParameters

    return (Test-TargetResourceImpl @PSBoundParameters -ResourceStatus $resourceStatus).Result
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



function Test-TargetResourceImpl
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [String] $Path,

        [Parameter(Mandatory = $true)]
        [String] $Name,

        [Parameter(Mandatory = $true)]
        [String] $RequestPath,

        [Parameter(Mandatory = $true)]
        [String[]] $Verb,

        [Parameter()]
        [ValidateSet('FastCgiModule')]
        [String] $ModuleType = 'FastCgiModule',

        [Parameter()]
        [String] $SiteName,

        [Parameter()]
        [ValidateSet('Present','Absent')]
        [String] $Ensure,

        [Parameter(Mandatory = $true)]
        [HashTable] $resourceStatus
    )

    $matchedVerbs = @()
    $mismatchVerbs =@()
    foreach($thisVerb  in $resourceStatus.Verb)
    {
        if($Verb -icontains $thisVerb)
        {
            Write-Verbose -Message ($LocalizedData.VerboseTestTargetResourceImplVerb `
                            -f $Verb)
            $matchedVerbs += $thisVerb
        }
        else
        {
            Write-Verbose -Message ($LocalizedData.VerboseTestTargetResourceImplExtraVerb `
                            -f $Verb)
            $mismatchVerbs += $thisVerb
        }
    }

    $modulePresent = $false
    if($resourceStatus.Name.Length -gt 0)
    {
        $modulePresent = $true
    }

    Write-Verbose -Message ($LocalizedData.VerboseTestTargetResourceImplRequestPath `
                            -f $RequestPath)
    Write-Verbose -Message ($LocalizedData.VerboseTestTargetResourceImplPath `
                            -f $Path)
    Write-Verbose -Message ($LocalizedData.VerboseTestTargetResourceImplresourceStatusRequestPath `
                            -f $($resourceStatus.RequestPath))
    Write-Verbose -Message ($LocalizedData.VerboseTestTargetResourceImplresourceStatusPath `
                            -f $($resourceStatus.Path))

    $moduleConfigured = $false
    if($modulePresent -and `
        $mismatchVerbs.Count -eq 0 -and `
        $matchedVerbs.Count-eq $Verb.Count -and `
        $resourceStatus.Path -eq $Path -and `
        $resourceStatus.RequestPath -eq $RequestPath)
    {
        $moduleConfigured = $true
    }

    Write-Verbose -Message ($LocalizedData.VerboseTestTargetResourceImplModulePresent `
                            -f $ModulePresent)
    Write-Verbose -Message ($LocalizedData.VerboseTestTargetResourceImplModuleConfigured `
                            -f $ModuleConfigured)
    if($moduleConfigured -and ($ModuleType -ne 'FastCgiModule' -or $resourceStatus.EndPointSetup))
    {
        return @{
                    Result = $true
                    ModulePresent = $modulePresent
                    ModuleConfigured = $moduleConfigured
                }
    }
    else
    {
        return @{
                    Result = $false
                    ModulePresent = $modulePresent
                    ModuleConfigured = $moduleConfigured
                }
    }
}


#endregion

Export-ModuleMember -Function *-TargetResource
