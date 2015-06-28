data LocalizedData
{   
}

# The Get-TargetResource cmdlet is used to fetch the status of role or Website on the target machine.
# It gives the Website info of the requested role/feature on the target machine.  
function Get-TargetResource 
{
    [OutputType([System.Collections.Hashtable])]
    param 
    (   
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Name
    )

    $resource = @{
        Ensures = "Absent"
    }
    
    $webFarm = Get-WebsiteFarm -Name $Name
    if($webFarm -ne $null){
        $resource.Ensures = "Present"
        $resource.Enabled = [System.Boolean]::Parse($webFarm.enabled)
    }

    $resource 
}


# The Set-TargetResource cmdlet is used to create, delete or configuure a website on the target machine. 
function Set-TargetResource 
{
    [CmdletBinding(SupportsShouldProcess=$true)]
    param 
    (       
        [ValidateSet("Present", "Absent")]
        [string]$Ensure = "Present",

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Name
    ) 
}


# The Test-TargetResource cmdlet is used to validate if the role or feature is in a state as expected in the instance document.
function Test-TargetResource 
{
    [OutputType([System.Boolean])]
    param 
    (       
        [ValidateSet("Present", "Absent")]
        [string]$Ensure = "Present",

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Name,       
                
        [bool]$Enabled = $true,

        [string]$ConfigPath = "C:\Windows\System32\inetsrv\config\applicationHost.config"
    )
    
    Write-Verbose "Searching for webfarm: $Name"

    $found = $false    
    $applicationHostConfig =[xml](gc $ConfigPath)
    $measure = $applicationHostConfig.configuration.webFarms.webFarm | ? name -eq $Name | measure-object

    Write-Verbose ("Webfarms found: " + $measure.Count)

    if($measure.Count -gt 1){
        Write-Error "More than one webfarm found! The config must be corrupted"
    }elseif($measure.Count -eq 0){

        $webfarmElement = ($applicationHostConfig.configuration.webFarms.webFarm | ? name -eq $Name)[0]
        if($webfarmElement.enabled -ne $Enabled){
            Write-Verbose "Webfarms is [$($webfarmElement.enabled)] but is requested to be [$Enabled]."
            return $false
        }

    }

    $measure.Count -gt 0     
}

function Get-WebsiteFarm{
    param 
    (       
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Name,
                
        [ValidateNotNullOrEmpty()]
        [string]$ConfigPath = "%windir%/system32/inetsrv/config/applicationhost.config"
    )

    Write-Verbose "Searching for webfarm: $Name"

    $ConfigPath = [System.Environment]::ExpandEnvironmentVariables($ConfigPath)

    $found = $false    
    $applicationHostConfig = GetApplicationHostConfig $ConfigPath
    $farms = $applicationHostConfig.configuration.webFarms.webFarm | ? name -eq $Name
    $measure = $farms | measure-object

    Write-Verbose ("Webfarms found: " + $measure.Count)

    if($measure.Count -gt 1){
        Write-Error "More than one webfarm found! The config must be corrupted"
    }elseif($measure.Count -eq 0){
        $null
    }else{
        $farms
    }
}

function GetApplicationHostConfig($path){
    [xml](gc $path)
}

#endregion