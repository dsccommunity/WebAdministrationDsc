data LocalizedData
{   
}

$_xWebfarm_DefaultLoadBalancingAlgorithm = "WeightedRoundRobin"
$_xWebfarm_DefaultApplicationHostConfig = "%windir%\system32\inetsrv\config\applicationhost.config"

function Get-TargetResource 
{
    [OutputType([System.Collections.Hashtable])]
    param 
    (   
        [Parameter(Mandatory)]
        [ValidateSet("Present", "Absent")]
        [string]$Ensure,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Name,
                
        [string]$ConfigPath
    )        

    Write-Verbose "xWebfarm/Get-TargetResource"
    Write-Verbose "Name: $Name"    
    Write-Verbose "ConfigPath: $ConfigPath"
    
    $config = GetApplicationHostConfig $ConfigPath
    $webFarm = GetWebfarm $Name $config
    GetTargetResourceFromConfigElement $webFarm    
}

function Set-TargetResource 
{
    [CmdletBinding(SupportsShouldProcess=$true)]
    param 
    (       
        [Parameter(Mandatory)]
        [ValidateSet("Present", "Absent")]
        [string]$Ensure,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Name,

        [bool]$Enabled = $true,

        [string]$Algorithm,
        [string]$QueryString,
        [string]$ServerVariable,

        [string]$ConfigPath
    )

    #region

    Write-Verbose "xWebfarm/Set-TargetResource"
    Write-Verbose "Ensure: $Ensure"
    Write-Verbose "Name: $Name"
    Write-Verbose "Enabled: $Enabled"
    Write-Verbose "Algorithm: $Algorithm"
    Write-Verbose "QueryString: $QueryString"
    Write-Verbose "ServerVariable: $ServerVariable"
    Write-Verbose "ConfigPath: $ConfigPath"
    
    Write-Verbose "Get current webfarm state"

    $config = GetApplicationHostConfig $ConfigPath
    $webFarm = GetWebfarm $Name $config
    $resource = GetTargetResourceFromConfigElement $webFarm

    Write-Verbose "Webfarm presence. From [$($resource.Ensure )] to [$Ensure]"

    if(($Ensure -eq "present") -and ($resource.Ensure -eq "absent")){
        $webFarmElement = $config.CreateElement("webFarm")
        $webFarmElement.SetAttribute("name", $Name)        
        $config.configuration.webFarms.AppendChild($webFarmElement)

        Write-Verbose "Webfarm created: Name = $Name"
        
        $resource = GetTargetResourceFromConfigElement $webFarmElement
        $webFarm = GetWebfarm $Name $config
    }elseif(($Ensure -eq "absent") -and ($resource.Ensure -eq "present")){
        $webFarmElement = $config.configuration.webFarms.webFarm | Where-Object Name -eq $Name
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
                
        if($Algorithm -eq $null){
            Write-Verbose "Webfarm configured: LoadBalancing from [$($resource.Algorithm)] to []"
            if($null -ne $webFarm.applicationRequestRouting){
                $webFarm.RemoveChild($webFarm.applicationRequestRouting)
            }
        }else{
            Write-Verbose "Webfarm configured: LoadBalancing from [$($resource.Algorithm)] to [$Algorithm]"

            $applicationRequestRoutingElement = $webFarm.applicationRequestRouting
            $loadBalancingElement = $webFarm.applicationRequestRouting.loadBalancing

            if($null -eq $webFarm.applicationRequestRouting){
                $applicationRequestRoutingElement = $config.CreateElement("applicationRequestRouting")
                $webFarm.AppendChild($applicationRequestRoutingElement)
            }

            if($null -eq $webFarm.applicationRequestRouting.loadBalancing){
                $loadBalancingElement = $config.CreateElement("loadBalancing")
                $loadBalancingElement.SetAttribute("algorithm", $_xWebfarm_DefaultLoadBalancingAlgorithm)
                $applicationRequestRoutingElement.AppendChild($loadBalancingElement)
            }

            if($Algorithm -eq "weightedroundrobin"){
                $loadBalancingElement.SetAttribute("algorithm", "WeightedRoundRobin")
                $loadBalancingElement.RemoveAttribute("hashServerVariable")
                $loadBalancingElement.RemoveAttribute("queryStringNames")
            }
            elseif($Algorithm -eq "querystring"){
                $loadBalancingElement.SetAttribute("algorithm", "RequestHash")
                $loadBalancingElement.SetAttribute("hashServerVariable", "query_string")
                $loadBalancingElement.SetAttribute("queryStringNames", [System.String]::Join(",", $QueryString))
            }
            elseif($Algorithm -eq "servervariable"){
                $loadBalancingElement.SetAttribute("algorithm", "RequestHash")
                $loadBalancingElement.SetAttribute("hashServerVariable", $ServerVariable)
                $loadBalancingElement.RemoveAttribute("queryStringNames")
            }
            elseif($Algorithm -eq "requesthash"){
                $loadBalancingElement.SetAttribute("algorithm", "RequestHash")
                $loadBalancingElement.RemoveAttribute("hashServerVariable")
                $loadBalancingElement.RemoveAttribute("queryStringNames")
            }
        }
    }

    if($null -ne $config ){
        Write-Verbose "Finished configuration."

        if($pscmdlet.ShouldProcess($computername)){
            Write-Verbose "Should process: true"
            SetApplicationHostConfig $ConfigPath $config
        }else{
            Write-Verbose "Should process: false"
        }        
    }

    #endregion
}

function Test-TargetResource 
{
    [OutputType([System.Boolean])]
    param 
    (     
        [Parameter(Mandatory)]        
        [ValidateSet("Present", "Absent")]
        [string]$Ensure,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Name,       
                
        [bool]$Enabled = $true,

        [string]$Algorithm,
        [string]$QueryString,
        [string]$ServerVariable,

        [string]$ConfigPath
    )

    #region

    Write-Verbose "xWebfarm/Test-TargetResource"
    Write-Verbose "Name: $Name"
    Write-Verbose "ConfigPath: $ConfigPath"

    if([System.String]::IsNullOrEmpty($Algorithm)){
        $Algorithm = $_xWebfarm_DefaultLoadBalancingAlgorithm
    }
    
    $config = GetApplicationHostConfig $ConfigPath
    $webFarm = GetWebfarm $Name $config
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

        if($Algorithm -ne $resource.Algorithm){
            return $false
        }

        if($Algorithm -eq "querystring"){
            if([System.String]::IsNullOrEmpty($QueryString) -eq $false){
                $queryStringList1 = [System.String]::Join(",", ($QueryString.Split(",") | Sort-Object))
                $queryStringList2 = [System.String]::Join(",", ($resource.QueryString | Sort-Object))
            
                return $queryStringList1 -eq $queryStringList2
            }
        }elseif($Algorithm -eq "servervariable"){
            if([System.String]::IsNullOrEmpty($ServerVariable) -eq $false){
                $serverVariableList1 = [System.String]::Join(",", ($ServerVariable.Split(",") | Sort-Object))
                $serverVariableList2 = [System.String]::Join(",", ($resource.ServerVariable | Sort-Object))
            
                return $serverVariableList1 -eq $serverVariableList2
            }
        }
    }    

    $true

    #endregion
}

#region private methods

function GetWebfarm{
    param 
    (       
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Name,
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [xml]$Config
    )
    $farms = $Config.configuration.webFarms.webFarm | Where-Object name -eq $Name
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

    if($null -ne $webFarm){
        $resource.Ensure = "Present"

        if([System.String]::IsNullOrEmpty($webFarm.enabled)){
            $resource.Enabled = $false
        }else{
            $resource.Enabled = [System.Boolean]::Parse($webFarm.enabled)
        }

        #dows this farm have the specific request routing element
        if($null -ne $webFarm.applicationRequestRouting){
            $resource.Algorithm = $webFarm.applicationRequestRouting.loadBalancing.algorithm
            
            if([System.String]::IsNullOrEmpty($resource.Algorithm)){
                $resource.Algorithm = $_xWebfarm_DefaultLoadBalancingAlgorithm
            }

            if($null -ne $webFarm.applicationRequestRouting.loadBalancing){
                if($null -ne $webFarm.applicationRequestRouting.loadBalancing.hashServerVariable){
                    if($webFarm.applicationRequestRouting.loadBalancing.hashServerVariable -eq "query_string"){
                        $resource.Algorithm = "QueryString"
                        $resource.QueryString = $webFarm.applicationRequestRouting.loadBalancing.queryStringNames.Split(",")                
                    }else{
                        $resource.Algorithm = "ServerVariable"
                        $resource.ServerVariable = $webFarm.applicationRequestRouting.loadBalancing.hashServerVariable.Split(",")
                    }
                }
            }
        }else{
            $resource.Algorithm = $_xWebfarm_DefaultLoadBalancingAlgorithm            
        }
    }

    $resource 
}

function GetApplicationHostConfig($ConfigPath){
    
    if([System.String]::IsNullOrEmpty($ConfigPath)){
        $ConfigPath = [System.Environment]::ExpandEnvironmentVariables($_xWebfarm_DefaultApplicationHostConfig)
    }

    Write-Verbose "GetApplicationHostConfig $ConfigPath"

    [xml](Get-Content $ConfigPath)
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