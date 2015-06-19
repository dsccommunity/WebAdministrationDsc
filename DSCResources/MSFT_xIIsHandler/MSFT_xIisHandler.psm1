######################################################################################
# DSC Resource for IIS Server level http handlers
######################################################################################
data LocalizedData
{
    # culture="en-US"
    ConvertFrom-StringData @'
NoWebAdministrationModule=Please ensure that WebAdministration module is installed.
AddingHandler=Adding handler '{0}'
RemovingHandler=Removing handler '{0}'
HandlerExists=Handler with name '{0}' already exist
HandlerNotPresent=Handler with name '{0}' is not present as requested
HandlerStatusUnknown=Handler with name '{0}' is is an unknown status
'@
}

######################################################################################
# The Get-TargetResource cmdlet.
######################################################################################
function Get-TargetResource
{
    [OutputType([Hashtable])]
    param
    (        
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [String]$Name,

        [Parameter(Mandatory)]
        [ValidateSet("Present", "Absent")]
        [string]$Ensure = "Present"
    )
    
    # Check if WebAdministration module is present for IIS cmdlets
    CheckIISPoshModule

    $handler = GetHandler -name $Name

    if ($handler -eq $null)
    {
        return @{
            Ensure = 'Absent'
            Name = $Name
        }
    }
    else
    {
        return @{
            Ensure = 'Present'
            Name = $Name
        }
    }
}

######################################################################################
# The Set-TargetResource cmdlet.
######################################################################################
function Set-TargetResource
{
    param
    (        
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [String]$Name,

        [Parameter(Mandatory)]
        [ValidateSet("Present", "Absent")]
        [string]$Ensure = "Present"
    )

        CheckIISPoshModule

        [string]$psPathRoot = "MACHINE/WEBROOT/APPHOST"
        [string]$sectionNode = "system.webServer/handlers"

        $handler = GetHandler -name $Name 

        if ($handler -eq $null -and $Ensure -eq "Present")
        {
            # add the handler  
            AddHandler -name $Name    
            Write-Verbose($LocalizedData.AddingHandler -f $Name);
        }
        elseif ($handler -ne $null -and $Ensure -eq "Absent")
        {
            # remove the handler                      
            Remove-WebConfigurationProperty -pspath $psPathRoot -filter $sectionNode -name "." -AtElement @{name="$Name"}
            Write-Verbose($LocalizedData.RemovingHandler -f $Name);
        }
}

######################################################################################
# The Test-TargetResource cmdlet.
######################################################################################
function Test-TargetResource
{
    [OutputType([System.Boolean])]
    param
    (        
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [String]$Name,

        [Parameter(Mandatory)]
        [ValidateSet("Present", "Absent")]
        [string]$Ensure = "Present"
    )

    [bool]$DesiredConfigurationMatch = $true;
    
    CheckIISPoshModule

    $handler = GetHandler -name $Name 

    if (($handler -eq $null -and $Ensure -eq "Present") -or ($handler -ne $null -and $Ensure -eq "Absent"))
    {
        $DesiredConfigurationMatch = $false;
    }
    elseif ($handler -ne $null -and $Ensure -eq "Present")
    {
        # Already there 
        Write-Verbose($LocalizedData.HandlerExists -f $Name);
    }
    elseif ($handler -eq $null -and $Ensure -eq "Absent")
    {
        # handler not there and shouldn't be there.
        Write-Verbose($LocalizedData.HandlerNotPresent -f $Name);
    }
    else
    {
        $DesiredConfigurationMatch = $false;
        Write-Verbose($LocalizedData.HandlerStatusUnknown -f $Name);
    }
    
    return $DesiredConfigurationMatch
}

Function CheckIISPoshModule
{
    # Check if WebAdministration module is present for IIS cmdlets
    if(!(Get-Module -ListAvailable -Name WebAdministration))
    {
        Throw $LocalizedData.NoWebAdministrationModule
    }
}

Function GetHandler([string]$name)
{
    [string]$filter = "system.webServer/handlers/Add[@Name='" + $name + "']"
    return Get-WebConfigurationProperty  -pspath 'MACHINE/WEBROOT/APPHOST' -filter $filter -Name .
}

Function AddHandler([string]$name)
{

    $handlers = New-Object 'System.Collections.Generic.dictionary[string,object]'
    $handlers.Add("ASPClassic",(New-Object PSObject -Property @{name='ASPClassic';path='*.asp';verb='GET,HEAD,POST';modules='IsapiModule';scriptProcessor='%windir%\system32\inetsrv\asp.dll';resourceType='File'}))
 
    Add-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST'  -filter "system.webServer/handlers" -name "." -value $handlers["ASPClassic"]
    
}

#  FUNCTIONS TO BE EXPORTED 
Export-ModuleMember -Function *-TargetResource
