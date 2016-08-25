# Load the Helper Module
Import-Module -Name "$PSScriptRoot\..\Helper.psm1"

# Localized messages
data LocalizedData
{
    # culture="en-US"
    ConvertFrom-StringData -StringData @'
        VerboseGetTargetResource                    = Get-TargetResource has been run.
        VerboseSetTargetRemoveHandler               = Removing handler.
        VerboseSetTargetAddHandler                  = Adding handler.
        VerboseSetTargetAddfastCgi                  = Adding fastCgi to requestPath {0}.
        VerboseTestTargetResource                   = Get-TargetResource has been run.
        VerboseGetIisHandler                        = Getting Handler for {0} in Site {1}.
        VerboseTestTargetResourceVerb               = Matched Verb {0}.
        VerboseTestTargetResourceExtraVerb          = Extra Verb {0}.
        VerboseTestTargetResourceRequestPath        = RequestPath is {0}.
        VerboseTestTargetResourcePath               = Path is {0}.
        VerboseTestTargetResourceActualRequestPath  = StatusRequestPath is {0}.
        VerboseTestTargetResourceActualPath         = StatusPath is {0}.
        VerboseTestTargetResourceModulePresent      = Module present is {0}.
        VerboseTestTargetResourceModuleConfigured   = ModuleConfigured is {0}.
        VerboseTestTargetResourceEndPointSetup      = EndPointSetup is {0}.
'@
}

<#
        .SYNOPSIS
        This will return a hashtable of results 
#>
function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory)]
        [String] $Path,

        [Parameter(Mandatory)]
        [String] $Name,

        [Parameter(Mandatory)]
        [String] $RequestPath,

        [Parameter(Mandatory)]
        [String[]] $Verb,

        [ValidateSet('FastCgiModule')]
        [String] $ModuleType = 'FastCgiModule',

        [String] $SiteName
    )

        Assert-Module
        
        $currentVerbs = @()
        $ensure = 'Absent'
        $fastCgiSetup = $false
        $type = $ModuleType

        $handler = Get-IisHandler -Name $Name -SiteName $SiteName

        if ($handler)
        {
            $ensure = 'Present'
            $Path = $handler.ScriptProcessor
            $RequestPath = $handler.Path
            $type = $handler.Modules
            $verbs = ($handler.Verb).Split(',')

            foreach ($thisVerb  in $verbs)
            {
                $currentVerbs += $thisVerb
            }

            if ($handler.Modules -eq 'FastCgiModule')
            {
                $fastCgiSetup = Get-FastCgi -Name $Name -SiteName $SiteName
            }
        }

        Write-Verbose -Message $LocalizedData.VerboseGetTargetResource
        
        $returnValue = @{
            Path          = $Path
            Name          = $Name
            RequestPath   = $RequestPath
            Verb          = $currentVerbs
            SiteName      = $SiteName
            Ensure        = $ensure
            ModuleType    = $ModuleType
            EndPointSetup = $fastCgiSetup
        }

        $returnValue
}

<#
        .SYNOPSIS
        This will set the desired state
#>
function Set-TargetResource
{

    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory)]
        [String] $Path,

        [Parameter(Mandatory)]
        [String] $Name,

        [Parameter(Mandatory)]
        [String] $RequestPath,

        [Parameter(Mandatory)]
        [String[]] $Verb,

        [ValidateSet('Present','Absent')]
        [String] $Ensure = 'Present',

        [ValidateSet('FastCgiModule')]
        [String] $ModuleType = 'FastCgiModule',

        [String] $SiteName
    )
    
    Assert-Module
    
    $iisSitePath = Get-IisSitePath -SiteName $SiteName

    if ($Ensure -eq 'Present')
    {
        # Update values
        Write-Verbose -Message $LocalizedData.VerboseSetTargetAddHandler 
        Add-Webconfiguration -Filter '/system.webServer/handlers' -PSPath $iisSitePath -Value @{
            Name = $Name
            Path = $RequestPath
            Verb = $Verb -join ','
            Module = $ModuleType
            ScriptProcessor = $Path
        }

        if (-not (Get-FastCgi -Name $Name -SiteName $SiteName))
        {
            Write-Verbose -Message ($LocalizedData.VerboseSetTargetAddfastCgi `
                    -f $RequestPath)
            Add-WebConfiguration -Filter '/system.webServer/fastCgi' -PSPath $iisSitePath -Value @{
                FullPath = $RequestPath
            }
        }
    }
    else 
    {
        # Ensure set to Absent so remove settings
        Write-Verbose -Message $LocalizedData.VerboseSetTargetRemoveHandler
        Remove-IisHandler -Name $Name -SiteName $SiteName
    }
}

<#
        .SYNOPSIS
        This tests the desired state. If the state is not correct it will return $false.
        If the state is correct it will return $true
#>
function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory)]
        [String] $Path,

        [Parameter(Mandatory)]
        [String] $Name,

        [Parameter(Mandatory)]
        [String] $RequestPath,

        [Parameter(Mandatory)]
        [String[]] $Verb,

        [ValidateSet('FastCgiModule')]
        [String] $ModuleType = 'FastCgiModule',

        [ValidateSet('Present','Absent')]
        [String] $Ensure = 'Present',

        [String] $SiteName
    )

    $moduleSettings = Get-TargetResource -Path $Path -Name $Name -RequestPath $RequestPath `
                                         -Verb $Verb -ModuleType $ModuleType -SiteName $SiteName

    Write-Verbose -Message $LocalizedData.VerboseTestTargetResource
    
    $matchedVerbs = @()
    $mismatchVerbs =@()
    foreach ($thisVerb  in $moduleSettings.Verb)
    {
        if ($Verb -icontains $thisVerb)
        {
            Write-Verbose -Message ($LocalizedData.VerboseTestTargetResourceVerb `
                            -f $Verb)
            $matchedVerbs += $thisVerb
        }
        else
        {
            Write-Verbose -Message ($LocalizedData.VerboseTestTargetResourceExtraVerb `
                            -f $Verb)
            $mismatchVerbs += $thisVerb
        }
    }

    Write-Verbose -Message ($LocalizedData.VerboseTestTargetResourceRequestPath `
                            -f $RequestPath)
    Write-Verbose -Message ($LocalizedData.VerboseTestTargetResourcePath `
                            -f $Path)
    Write-Verbose -Message ($LocalizedData.VerboseTestTargetResourceActualRequestPath `
                            -f $($moduleSettings.RequestPath))
    Write-Verbose -Message ($LocalizedData.VerboseTestTargetResourceActualPath `
                            -f $($moduleSettings.Path))

    $moduleConfigured = $false
    if ($moduleSettings.Ensure -eq 'Present' -and `
        $Ensure -eq 'Present' -and `
        $mismatchVerbs.Count -eq 0 -and `
        $matchedVerbs.Count-eq $Verb.Count -and `
        $moduleSettings.Path -eq $Path -and `
        $moduleSettings.RequestPath -eq $RequestPath)
    {
        $moduleConfigured = $true
    }

    Write-Verbose -Message ($LocalizedData.VerboseTestTargetResourceModulePresent `
                            -f $ModuleSettings.Ensure)
    Write-Verbose -Message ($LocalizedData.VerboseTestTargetResourceModuleConfigured `
                            -f $ModuleConfigured)
    Write-Verbose -Message ($LocalizedData.VerboseTestTargetResourceEndPointSetup `
                            -f $moduleSettings.EndPointSetup)
                            
    if ($moduleConfigured -and ($ModuleType -ne 'FastCgiModule' -or $moduleSettings.EndPointSetup) )
    {
        return $true
    }
    elseif (($Ensure -eq 'Absent') -and ($moduleSettings.Ensure -eq 'Absent') )
    {
        return $true
    }
    else
    {
        return $false
    }
    
}

#region Helper Functions

<#
    .SYNOPSIS
    Returns the IIS path as a string either with the SiteName if one is proveded
    or without one if not provided.
#>
function Get-IisSitePath
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param
    (
        [String] $SiteName
    )

    if (-not $SiteName)
    {
        return 'IIS:\'
    }
    else
    {
        return (Join-Path -Path 'IIS:\sites\' -ChildPath $SiteName)
    }
}

<#
    .SYNOPSIS
        Returns a list of IIS handlers for the module with the given Name
#>
function Get-IisHandler
{
    [CmdletBinding()]
    [OutputType([PSObject])]
    param
    (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [String] $Name,

        [String] $SiteName
    )

    Write-Verbose -Message ($LocalizedData.VerboseGetIisHandler -f $Name, $SiteName)
    return Get-WebConfiguration -Filter 'System.WebServer/handlers/*' `
                                -PSPath (Get-IisSitePath `
                                -SiteName $SiteName) | `
                                Where-Object{$_.Name -ieq $Name}
}

<#
    .SYNOPSIS
        Remove an IIS Handler with the given Name
#>
function Remove-IisHandler
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [String] $Name,

        [String] $SiteName
    )

    Clear-WebConfiguration -Filter 'System.WebServer/handlers/*' `
                           -PSPath (Get-IisSitePath -SiteName $SiteName)
}

function Get-FastCgi
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [String] $Name,

        [String] $SiteName
    )
    
    $handler = Get-IisHandler -Name $Name -SiteName $SiteName
    
    Write-Verbose -Message "Handler.ScriptProcessor: $($handler.ScriptProcessor)" -Verbose
    
    $fastCgi = Get-WebConfiguration -Filter /system.webServer/fastCgi/* `
                            -PSPath (Get-IisSitePath `
                            -SiteName $SiteName) | `
                            Where-Object {
                                Write-Verbose -Message $_.FullPath -Verbose
                                $_.FullPath -ieq $handler.ScriptProcessor }
    if ($fastCgi)
    {
        return $true;
    }
    else
    {
        return $false
    }

}

#endregion

Export-ModuleMember -Function *-TargetResource
