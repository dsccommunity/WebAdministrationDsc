data LocalizedData
{
    # culture="en-US"
    ConvertFrom-StringData @'
SetTargetResourceInstallwhatIfMessage=Trying to create website "{0}".
SetTargetResourceUnInstallwhatIfMessage=Trying to remove website "{0}".
WebsiteNotFoundError=The requested website "{0}" is not found on the target machine.
WebsiteDiscoveryFailureError=Failure to get the requested website "{0}" information from the target machine.
WebsiteCreationFailureError=Failure to successfully create the website "{0}".
WebsiteRemovalFailureError=Failure to successfully remove the website "{0}".
WebsiteUpdateFailureError=Failure to successfully update the properties for website "{0}".
WebsiteBindingUpdateFailureError=Failure to successfully update the bindings for website "{0}".
WebsiteBindingInputInvalidationError=Desired website bindings not valid for website "{0}".
WebsiteCompareFailureError=Failure to successfully compare properties for website "{0}".
WebBindingCertifcateError=Failure to add certificate to web binding. Please make sure that the certificate thumbprint "{0}" is valid.
WebsiteStateFailureError=Failure to successfully set the state of the website {0}.
WebsiteBindingConflictOnStartError = Website "{0}" could not be started due to binding conflict. Ensure that the binding information for this website does not conflict with any existing website's bindings before trying to start it.
'@
}

#region Tracing
$Debug = $true
Function Trace-Message
{
    param([string] $Message)
    if($Debug)
    {
        Write-Verbose $Message
    }
}
#endregion

#IIS Helpers

# Get the IIS Site Path
function Get-IisSitePath
{
    param
    (

        [string]$SiteName
    )

    if(-not $SiteName)
    {
        return 'IIS:\'
    }
    else
    {
        return Join-Path 'IIS:\sites\' $SiteName
    }
}

#Get a list on IIS handlers
function Get-IisHandler
{
    param
    (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]

        [string]$Name,

        [string]$SiteName
    )

    Trace-Message "Getting Handler for $Name in Site $SiteName"
    return get-webconfiguration -Filter 'System.WebServer/handlers/*' -PSPath (Get-IisSitePath -SiteName $SiteName) | ?{$_.Name -ieq $Name}
}

# Remove an IIS Handler
function Remove-IisHandler
{
    param
    (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]

        [string]$Name,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]

        [string]$SiteName
    )

    $handler = Get-IisHandler @PSBoundParameters

    if($handler)
    {
        Clear-WebConfiguration -PSPath $handler.PSPath -Filter $handler.ItemXPath -Location $handler.Location
    }
}

#EndRegion
function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $Path,

        [parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [parameter(Mandatory = $true)]
        [System.String]
        $RequestPath,

        [parameter(Mandatory = $true)]
        [System.String[]]
        $Verb,

        [ValidateSet('FastCgiModule')]
        [System.String]
        $ModuleType = 'FastCgiModule',

        [System.String]
        $SiteName
    )

        $currentVerbs = @()
        $Ensure = 'Absent'
        $getTargetResourceResult = $null;

        $modulePresent = $false;

        $handler = Get-IisHandler -Name $Name -SiteName $SiteName

        if($handler )
        {
            $Ensure = 'Present'
            $modulePresent = $true;
        }

        Trace-Message "Got Handler $($handler.Name)"

        foreach($thisVerb  in $handler.Verb)
        {
            $currentVerbs += $thisVerb
        }

        $fastCgiSetup = $false
        # bug(TBD) deal with this better, maybe a seperate resource....
        If($handler.Modules -eq 'FastCgiModule')
        {
            $fastCgi = Get-WebConfiguration /system.webServer/fastCgi/* -PSPath (Get-IisSitePath -SiteName $SiteName) | ?{$_.FullPath -ieq $handler.ScriptProcessor}
            if($fastCgi)
            {
                $fastCgiSetup = $true
            }
        }


        Trace-Message "Verb.Count: $($Verb.Count)"
        Trace-Message "handler.modules: $($handler.Modules)"

        #-and $Module -ieq $handler.Modules


    $returnValue = @{
        Path = $handler.ScriptProcessor
        Name = $handler.Name
        RequestPath = $handler.Path
        Verb = $currentVerbs
        SiteName = $SiteName
        Ensure = $Ensure
        ModuleType = $handler.Modules
        EndPointSetup = $fastCgiSetup
    }

    $returnValue
    
}

# From the parameter hashtable of a function, return the parameter hashtable to call Get-TargetResource
function Get-GetParameters
{
    param
    (
        [parameter(Mandatory = $true)]
        [Hashtable]
        $functionParameters
    )

    $getParameters = @{}
    foreach($key in $functionParameters.Keys)
    {
        if($key -ine 'Ensure')
        {
            $getParameters.Add($key, $functionParameters.$key) | Out-Null
        }
    }

    return $getParameters
}

# Make the IisModule consistent with the properties provided.
function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $Path,

        [parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [parameter(Mandatory = $true)]
        [System.String]
        $RequestPath,

        [parameter(Mandatory = $true)]
        [System.String[]]
        $Verb,

        [System.String]
        $SiteName,

        [ValidateSet('Present','Absent')]
        [System.String]
        $Ensure,

        [ValidateSet('FastCgiModule')]
        [System.String]
        $ModuleType = 'FastCgiModule'
    )
    $GetParameters = Get-GetParameters -functionParameters $PSBoundParameters
    $resourceStatus = Get-TargetResource @GetParameters
    $resourceTests = Test-TargetResourceImpl @PSBoundParameters -resourceStatus $resourceStatus
    if ($resourceTests.Result)
    {
        return
    }

    Trace-Message 'Get complete'

    if($Ensure -eq 'Present')
    {
        if($resourceTests.ModulePresent -and -not $resourceTests.ModuleConfigured)
        {
            Trace-Message 'Removing handler...'
            Remove-IisHandler
        }

        if(-not $resourceTests.ModulePresent -or -not $resourceTests.ModuleConfigured)
        {
            Trace-Message 'Adding handler...'
            add-webconfiguration /system.webServer/handlers iis:\ -value @{
                name = $Name
                path = $RequestPath
                verb = $Verb -join ','
                modules = $ModuleType
                scriptProcessor = $Path
            }
        }

        # bug(TBD) deal with this better, maybe a seperate resource....
        if(-not $resourceTests.EndPointSetup)
        {
            Trace-Message 'Adding fastCgi...'
            add-WebConfiguration /system.webServer/fastCgi iis:\ -value @{
                fullPath = $Path
            }
        }
    }
    else #Ensure is set to "Absent" so remove handler
    {
        Remove-IisHandler
    }
}


function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $Path,

        [parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [parameter(Mandatory = $true)]
        [System.String]
        $RequestPath,

        [parameter(Mandatory = $true)]
        [System.String[]]
        $Verb,


        [System.String]
        $SiteName,

        [ValidateSet('Present','Absent')]
        [System.String]
        $Ensure,

        [ValidateSet('FastCgiModule')]
        [System.String]
        $ModuleType = 'FastCgiModule'
    )

    $GetParameters = Get-GetParameters -functionParameters $PSBoundParameters
    $resourceStatus = Get-TargetResource @GetParameters

    return (Test-TargetResourceImpl @PSBoundParameters -resourceStatus $resourceStatus).Result
}


function Test-TargetResourceImpl
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $Path,

        [parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [parameter(Mandatory = $true)]
        [System.String]
        $RequestPath,

        [parameter(Mandatory = $true)]
        [System.String[]]
        $Verb,

        [ValidateSet('FastCgiModule')]
        [System.String]
        $ModuleType = 'FastCgiModule',

        [System.String]
        $SiteName,

        [ValidateSet('Present','Absent')]
        [System.String]
        $Ensure,

        [parameter(Mandatory = $true)]
        [HashTable]
        $resourceStatus
    )

    $matchedVerbs = @()
    $mismatchVerbs =@()
    foreach($thisVerb  in $resourceStatus.Verb)
    {
        if($Verb -icontains $thisVerb)
        {
            Trace-Message "Matched verb $Verb"
            $matchedVerbs += $thisVerb
        }
        else
        {
            Trace-Message "Extra verb $Verb"
            $mismatchVerbs += $thisVerb
        }
    }

    $modulePresent = $false
    if($resourceStatus.Name.Length -gt 0)
    {
        $modulePresent = $true
    }

    Trace-Message "RequestPath: $($RequestPath)"
    Trace-Message "Path: $($Path)"
    Trace-Message "resourceStatus.RequestPath: $($resourceStatus.RequestPath)"
    Trace-Message "resourceStatus.Path: $($resourceStatus.Path)"

    $moduleConfigured = $false
    if($modulePresent -and $mismatchVerbs.Count -eq 0 -and $matchedVerbs.Count-eq  $Verb.Count -and $resourceStatus.Path -eq $Path -and $resourceStatus.RequestPath -eq $RequestPath)
    {
        $moduleConfigured = $true
    }

    Trace-Message "ModulePresent: $ModulePresent"
    Trace-Message "ModuleConfigured: $ModuleConfigured"
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

Export-ModuleMember -Function *-TargetResource




