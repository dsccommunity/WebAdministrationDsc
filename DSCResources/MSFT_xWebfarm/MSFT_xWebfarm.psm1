data LocalizedData
{   
}

$_xWebfarm_DefaultLoadBalancingAlgorithm = "WeightedRoundRobin"
$_xWebfarm_DefaultApplicationHostConfig = "%windir%\system32\inetsrv\config\applicationhost.config"

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

    Write-Verbose "xWebfarm/Get-TargetResource"
    Write-Verbose "Name: $Name"    
    Write-Verbose "ConfigPath: $ConfigPath"
    
    $config = GetApplicationHostConfig $ConfigPath
    $webFarm = GetWebsiteFarm $Name $config
    GetTargetResourceFromConfigElement $webFarm    
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
        [string]$Name,

        [bool]$Enabled = $true,

        [string]$Algorithm,
        [string]$QueryString,
        [string]$ServerVariable,

        [string]$ConfigPath
    )

    Write-Verbose "xWebfarm/Set-TargetResource"
    Write-Verbose "Ensure: $Ensure"
    Write-Verbose "Name: $Name"
    Write-Verbose "Enabled: $Enabled"
    Write-Verbose "Algorithm: $Algorithm"
    Write-Verbose "Algorithm: $QueryString"
    Write-Verbose "Algorithm: $ServerVariable"
    Write-Verbose "ConfigPath: $ConfigPath"
    
    Write-Verbose "Get current webfarm state"

    $config = GetApplicationHostConfig $ConfigPath
    $webFarm = GetWebsiteFarm $Name $config
    $resource = GetTargetResourceFromConfigElement $webFarm

    Write-Verbose "Webfarm presence. From [$($resource.Ensure )] to [$Ensure]"

    if(($Ensure -eq "present") -and ($resource.Ensure -eq "absent")){
        $webFarmElement = $config.CreateElement("webFarm")
        $webFarmElement.SetAttribute("name", $Name)        
        $config.configuration.webFarms.AppendChild($webFarmElement)

        Write-Verbose "Webfarm created: Name = $Name"
        
        $resource = GetTargetResourceFromConfigElement $webFarmElement
        $webFarm = GetWebsiteFarm $Name $config
    }elseif(($Ensure -eq "absent") -and ($resource.Ensure -eq "present")){
        $webFarmElement = $config.configuration.webFarms.webFarm | ? Name -eq $Name
        $config.configuration.webFarms.RemoveChild($webFarmElement)

        Write-Verbose "Webfarm deleted: Name = $Name"

        $resource = GetTargetResourceFromConfigElement $null
        $webFarm = $null
    }
    else {
    }
    
    if (($Ensure -eq "present") -and ($resource.Ensure -eq "present")){
        Write-Verbose "Webfarm configured: Enabled from [$($resource.Enabled)] to [$Enabled]"
        $webFarm.SetAttribute("enabled", $Enabled)
                
        if($LoadBalancing -eq $null){
            Write-Verbose "Webfarm configured: LoadBalancing from [$($resource.LoadBalancing|ConvertTo-Json -Compress)] to []"
            if($webFarm.applicationRequestRouting -ne $null){
                $webFarm.RemoveChild($webFarm.applicationRequestRouting)
            }
        }else{
            Write-Verbose "Webfarm configured: LoadBalancing from [$($resource.LoadBalancing|ConvertTo-Json -Compress)] to [$($LoadBalancing|ConvertTo-Json -Compress)]"
            if($LoadBalancing.Algorithm -ne $resource.LoadBalancing.Algorithm){
                $webFarm.applicationRequestRouting.loadBalancing.algorithm = $LoadBalancing.Algorithm
            }

            if($LoadBalancing.Algorithm -eq "querystring"){
                $webFarm.applicationRequestRouting.loadBalancing.algorithm = "RequestHash"
                $webFarm.applicationRequestRouting.loadBalancing.SetAttribute("hashServerVariable", "query_string")
                $webFarm.applicationRequestRouting.loadBalancing.SetAttribute("queryStringNames", [System.String]::Join(",", $LoadBalancing.QueryString))
            }elseif($LoadBalancing.Algorithm -eq "servervariable"){
                $webFarm.applicationRequestRouting.loadBalancing.algorithm = "RequestHash"
                $webFarm.applicationRequestRouting.loadBalancing.SetAttribute("hashServerVariable", $LoadBalancing.ServerVariable)
            }
        }
    }

    if($config -ne $null){
        Write-Verbose "Finished configuration. Saving the config."
        SetApplicationHostConfig $ConfigPath $config
    }
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
        [string]$Ensure = "Present",

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Name,       
                
        [bool]$Enabled = $true,

        [string]$Algorithm,
        [string]$QueryString,
        [string]$ServerVariable,

        [string]$ConfigPath
    )

    Write-Verbose "xWebfarm/Test-TargetResource"
    Write-Verbose "Name: $Name"
    Write-Verbose "ConfigPath: $ConfigPath"
    
    $config = GetApplicationHostConfig $ConfigPath
    $webFarm = GetWebsiteFarm $Name $config
    $resource = GetTargetResourceFromConfigElement $webFarm
    
    Write-Verbose "Testing Ensures: Requested [$Ensure] Resource [$($resource.Ensure)]"
    if($resource.Ensure -eq "absent"){
        if($Ensure -eq "absent"){            
            return $true
        }else{
            return $false
        }

    }elseif($resource.Ensure -eq "present"){
        if($Ensure -eq "absent"){
            return $false
        }

        Write-Verbose "Testing Enabled: Requested [$Enabled] Resource [$($resource.Enabled)]"

        if($resource.Enabled -ne $Enabled){
            return $false
        }          
    }    

    $true
}

function GetWebsiteFarm{
    param 
    (       
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Name,
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [xml]$Config
    )

    $found = $false        
    $farms = $Config.configuration.webFarms.webFarm | ? name -eq $Name
    $measure = $farms | measure-object
    
    if($measure.Count -gt 1){
        Write-Error "More than one webfarm found! The config must be corrupted"
    }elseif($measure.Count -eq 0){
        $null
    }else{
        $farms
    }
}

function GetTargetResourceFromConfigElement($webFarm){
    $resource = @{
        Ensure = "Absent"
    }

    if($webFarm -ne $null){
        $resource.Ensure = "Present"

        if([System.String]::IsNullOrEmpty($webFarm.enabled)){
            $resource.Enabled = $false
        }else{
            $resource.Enabled = [System.Boolean]::Parse($webFarm.enabled)
        }

        #dows this farm have the specific request routing element
        if($webFarm.applicationRequestRouting -ne $null){
            $resource.LoadBalancing = @{
                Algorithm = $webFarm.applicationRequestRouting.loadBalancing.algorithm
            }
            
            if([System.String]::IsNullOrEmpty($resource.LoadBalancing.Algorithm)){
                $resource.LoadBalancing.Algorithm = $_xWebfarm_DefaultLoadBalancingAlgorithm
            }

            if($webFarm.applicationRequestRouting.loadBalancing.algorithm -eq "weightedroundrobin"){
                $resource.Servers = ($webFarm.server | % {@{Name=$_.address;Weigth=($_.applicationRequestRouting.weight, 100 -ne $null)[0]}})
            }else{
                $resource.Servers = ($webFarm.server | % {@{Name=$_.address}})
            }

            if($webFarm.applicationRequestRouting.loadBalancing -ne $null){
                if($webFarm.applicationRequestRouting.loadBalancing.hashServerVariable -ne $null){
                    if($webFarm.applicationRequestRouting.loadBalancing.hashServerVariable -eq "query_string"){
                        $resource.LoadBalancing.Algorithm = "QueryString"
                        $resource.LoadBalancing.QueryString = $webFarm.applicationRequestRouting.loadBalancing.queryStringNames.Split(",")                
                    }else{
                        $resource.LoadBalancing.Algorithm = "ServerVariable"
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

function GetApplicationHostConfig($ConfigPath){
    
    if([System.String]::IsNullOrEmpty($ConfigPath)){
        $ConfigPath = [System.Environment]::ExpandEnvironmentVariables($_xWebfarm_DefaultApplicationHostConfig)
    }

    Write-Verbose "GetApplicationHostConfig $ConfigPath"

    [xml](gc $ConfigPath)
}

function SetApplicationHostConfig{
    param([string]$ConfigPath, [xml]$xml)

    if([System.String]::IsNullOrEmpty($ConfigPath)){
        $ConfigPath = [System.Environment]::ExpandEnvironmentVariables($_xWebfarm_DefaultApplicationHostConfig)
    }

    Write-Verbose "SetApplicationHostConfig $ConfigPath"

    $xml.Save($ConfigPath)
}

#endregion