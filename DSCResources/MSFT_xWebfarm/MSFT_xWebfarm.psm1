data LocalizedData
{   
}

$_xWebfarm_DefaultLoadBalancingAlgorithm = "WeightedRoundRobin"
$_xWebfarm_DefaultLoadBalancingAlgorithm = "WeightedRoundRobin"

# The Get-TargetResource cmdlet is used to fetch the status of role or Website on the target machine.
# It gives the Website info of the requested role/feature on the target machine.  
function Get-TargetResource 
{
    [OutputType([System.Collections.Hashtable])]
    param 
    (   
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Name,
                
        [string]$ConfigPath
    )

    $resource = @{
        Ensures = "Absent"
    }
    
    $webFarm = Get-WebsiteFarm -Name $Name -ConfigPath $ConfigPath
    if($webFarm -ne $null){
        $resource.Ensures = "Present"
        $resource.Enabled = [System.Boolean]::Parse($webFarm.enabled)

        #dows this farm have the specific request routing element
        if($webFarm.applicationRequestRouting -ne $null){
            $resource.LoadBalancing = @{
                Algorithm = $webFarm.applicationRequestRouting.loadBalancing.algorithm
            }

            if([System.String]::IsNullOrEmpty($resource.LoadBalancing.Algorithm)){
                $resource.LoadBalancing.Algorithm = $_xWebfarm_DefaultLoadBalancingAlgorithm
            }

            if($webFarm.applicationRequestRouting.loadBalancing.algorithm.ToLower() -eq "weightedroundrobin"){
                $resource.Servers = ($webFarm.server | % {@{Name=$_.address;Weigth=($_.applicationRequestRouting.weight, 100 -ne $null)[0]}})
            }else{
                $resource.Servers = ($webFarm.server | % {@{Name=$_.address}})
            }

            if($webFarm.applicationRequestRouting.loadBalancing -ne $null){
                if($webFarm.applicationRequestRouting.loadBalancing.hashServerVariable -ne $null){
                    if($webFarm.applicationRequestRouting.loadBalancing.hashServerVariable.ToLower() -eq "query_string"){
                        $resource.LoadBalancing.QueryString = $webFarm.applicationRequestRouting.loadBalancing.queryStringNames.Split(",")                
                    }else{
                        $resource.LoadBalancing.ServerVariable = $webFarm.applicationRequestRouting.loadBalancing.hashServerVariable
                    }
                }
            }
        }else{
            $resource.LoadBalancing = @{
                Algorithm = $_xWebfarm_DefaultLoadBalancingAlgorithm                
            }
            $resource.Servers = ($webFarm.server | % {@{Name=$_.address;Weigth=($_.applicationRequestRouting.weight, 100 -ne $null)[0]}})
        }
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
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]  
        [ValidateSet("Present", "Absent")]
        [string]$Ensures = "Present",

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Name,       
                
        [bool]$Enabled = $true,

        [string]$ConfigPath
    )
    
    $resource = Get-TargetResource -Name $Name -ConfigPath $ConfigPath
    
    if($resource.Ensures.ToLower() -eq "absent"){
        if($Ensures.ToLower() -eq "absent"){
            return $true
        }else{
            return $false
        }

    }elseif($resource.Ensures.ToLower() -eq "present"){
        if($Ensures.ToLower() -eq "absent"){
            return $false
        }

        if($resource.Enabled -ne $Enabled){
            return $false
        }          
    }    

    $true
}

function Get-WebsiteFarm{
    param 
    (       
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Name,
        
        [string]$ConfigPath = "%windir%/system32/inetsrv/config/applicationhost.config"
    )

    $ConfigPath = ($ConfigPath, "%windir%/system32/inetsrv/config/applicationhost.config" -ne $null)[0]

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