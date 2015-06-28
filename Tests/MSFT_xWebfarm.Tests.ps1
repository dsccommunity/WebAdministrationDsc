$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) "..\DSCResources\MSFT_xWebfarm\MSFT_xWebfarm.psm1"
Import-Module "$sut" -Force

$fakeapphost1 = [xml]'<?xml version="1.0" encoding="UTF-8"?>
<configuration>
    <webFarms>
        <webFarm name="SOMEFARMTHATEXISTS" enabled="true">           
        </webFarm>
        <webFarm name="SOMEDISABLEDFARM" enabled="false">            
        </webFarm>
        <webFarm name="SOMEFARMWITHOUTBALANCING" enabled="false">  
            <server address="fqdn1" enabled="true">                
            </server>
            <server address="fqdn2" enabled="true">                
            </server>          
        </webFarm>
        <webFarm name="SOMEFARMWITHWeightedRoundRobin" enabled="false"> 
            <server address="fqdn1" enabled="true">                
            </server>
            <server address="fqdn2" enabled="true">                
            </server>
            <server address="fqdn3" enabled="true">
                <applicationRequestRouting weight="150" />
            </server>     
            <applicationRequestRouting>
                <loadBalancing algorithm="WeightedRoundRobin" />
            </applicationRequestRouting>      
        </webFarm>
        <webFarm name="SOMEFARMWITHRequestHashQueryString" enabled="false">   
            <server address="fqdn1" enabled="true">                
            </server>
            <server address="fqdn2" enabled="true">
                <!-- Must be ignored because it is not in roud robin -->
                <applicationRequestRouting weight="150" />            
            </server>           
             <applicationRequestRouting>
                <loadBalancing algorithm="RequestHash" hashServerVariable="QUERY_STRING" queryStringNames="q1,q2" />
            </applicationRequestRouting>
        </webFarm>
        <webFarm name="SOMEFARMWITHRequestHashServerVariable" enabled="false">   
            <server address="fqdn1" enabled="true">                
            </server>
            <server address="fqdn2" enabled="true">
                <!-- Must be ignored because it is not in roud robin -->
                <applicationRequestRouting weight="150" />               
            </server>          
             <applicationRequestRouting>
                <loadBalancing algorithm="RequestHash" hashServerVariable="x" />
            </applicationRequestRouting> 
        </webFarm>        
    </webFarms>
</configuration>'

Describe "MSFT_xWebfarm.Get-TargetResource" {
    It "must return Ensures Absent if the webfarm does not exists" {
        Mock GetApplicationHostConfig { return $fakeapphost1 } -ModuleName MSFT_xWebfarm
        $webFarm = Get-TargetResource -Name "SOMEFARMTHATDOESNOTEXISTS"
        $webFarm.Ensures | Should Be "Absent"
    }
    It "must return Ensures Present if webfarm exists" {
        Mock GetApplicationHostConfig { return $fakeapphost1 } -ModuleName MSFT_xWebfarm
        $webFarm = Get-TargetResource -Name "SOMEFARMTHATEXISTS"
        $webFarm.Ensures | Should Be "Present"
    }

    It "must return Enabled True if webfarm is enabled" {
        Mock GetApplicationHostConfig { return $fakeapphost1 } -ModuleName MSFT_xWebfarm
        $webFarm = Get-TargetResource -Name "SOMEFARMTHATEXISTS"
        $webFarm.Enabled | Should Be $true
    }
    It "must return Enabled False if webfarm is disabled" {
        Mock GetApplicationHostConfig { return $fakeapphost1 } -ModuleName MSFT_xWebfarm
        $webFarm = Get-TargetResource -Name "SOMEDISABLEDFARM"
        $webFarm.Enabled | Should Be $false
    }

    It "must return the default load balancing algorithm when the specific is not present" {
        Mock GetApplicationHostConfig { return $fakeapphost1 } -ModuleName MSFT_xWebfarm
        $webFarm = Get-TargetResource -Name "SOMEFARMWITHOUTBALANCING"
        $webFarm.LoadBalancing.Algorithm | Should Be "WeightedRoundRobin"
        $webFarm.LoadBalancing.QueryString | Should Be $null        
        $webFarm.LoadBalancing.ServerVariable | Should Be $null
        $webFarm.Servers.Length | Should Be 2
        $webFarm.Servers[0].Name | Should Be "fqdn1"
        $webFarm.Servers[0].Weigth | Should Be 100
        $webFarm.Servers[1].Name | Should Be "fqdn2"
        $webFarm.Servers[1].Weigth | Should Be 100 
    }  
    It "must return the specific load balancing algorithm when present [WeightedRoundRobin]" {
        Mock GetApplicationHostConfig { return $fakeapphost1 } -ModuleName MSFT_xWebfarm
        $webFarm = Get-TargetResource -Name "SOMEFARMWITHWeightedRoundRobin"
        $webFarm.LoadBalancing.Algorithm | Should Be "WeightedRoundRobin"
        $webFarm.LoadBalancing.QueryString | Should Be $null
        $webFarm.LoadBalancing.ServerVariable | Should Be $null
        $webFarm.Servers.Length | Should Be 3
        $webFarm.Servers[0].Name | Should Be "fqdn1"
        $webFarm.Servers[0].Weigth | Should Be 100
        $webFarm.Servers[1].Name | Should Be "fqdn2"
        $webFarm.Servers[1].Weigth | Should Be 100
        $webFarm.Servers[2].Name | Should Be "fqdn3"
        $webFarm.Servers[2].Weigth | Should Be 150
    }   
    It "must return the specific load balancing algorithm when present [RequestHash]" {
        Mock GetApplicationHostConfig { return $fakeapphost1 } -ModuleName MSFT_xWebfarm
        $webFarm = Get-TargetResource -Name "SOMEFARMWITHRequestHashQueryString"
        $webFarm.LoadBalancing.Algorithm | Should Be "RequestHash"
    }   
    It "must return the specific load balancing algorithm when present [RequestHash] with QueryString" {
        Mock GetApplicationHostConfig { return $fakeapphost1 } -ModuleName MSFT_xWebfarm
        $webFarm = Get-TargetResource -Name "SOMEFARMWITHRequestHashQueryString"
        $webFarm.LoadBalancing.QueryString.Length | Should Be 2
        $webFarm.LoadBalancing.QueryString[0] | Should Be "q1"
        $webFarm.LoadBalancing.QueryString[1] | Should Be "q2"
        $webFarm.Servers.Length | Should Be 2
        $webFarm.Servers[0].Name | Should Be "fqdn1"
        $webFarm.Servers[0].Weigth | Should Be $null
        $webFarm.Servers[1].Name | Should Be "fqdn2"
        $webFarm.Servers[1].Weigth | Should Be $null 
    }  
    It "must return the specific load balancing algorithm when present [RequestHash] with Server Variable" {
        Mock GetApplicationHostConfig { return $fakeapphost1 } -ModuleName MSFT_xWebfarm
        $webFarm = Get-TargetResource -Name "SOMEFARMWITHRequestHashServerVariable"
        $webFarm.LoadBalancing.ServerVariable | Should Be "x"
        $webFarm.Servers.Length | Should Be 2
        $webFarm.Servers[0].Name | Should Be "fqdn1"
        $webFarm.Servers[0].Weigth | Should Be $null
        $webFarm.Servers[1].Name | Should Be "fqdn2"
        $webFarm.Servers[1].Weigth | Should Be $null
    }   
}

Describe "MSFT_xWebfarm.Test-TargetResource"{
    It "must return true if requested Absent and resource is Absent" {
        Mock GetApplicationHostConfig { return $fakeapphost1 } -ModuleName MSFT_xWebfarm
        $result = Test-TargetResource -Name "SOMEFARMTHATDOESNOTEXISTS" -Ensures Absent
        $result | Should Be $true
    }
    It "must return false if requested Absent and resource is Present" {
        Mock GetApplicationHostConfig { return $fakeapphost1 } -ModuleName MSFT_xWebfarm
        $result = Test-TargetResource -Name "SOMEFARMTHATEXISTS" -Ensures Absent
        $result | Should Be $false
    }
    It "must return false if requested Present and resource is Absent" {
        Mock GetApplicationHostConfig { return $fakeapphost1 } -ModuleName MSFT_xWebfarm
        $result = Test-TargetResource -Name "SOMEFARMTHATDOESNOTEXISTS" -Ensures Present
        $result | Should Be $false
    }    
    It "must return false if requested Enabled=true and resource is Enabled=false" {
        Mock GetApplicationHostConfig { return $fakeapphost1 } -ModuleName MSFT_xWebfarm
        $result = Test-TargetResource -Name "SOMEDISABLEDFARM" -Ensures Present -Enabled $true
        $result | Should Be $false
    }
    It "must return true if requested Enabled=true and resource is Enabled=true" {
        Mock GetApplicationHostConfig { return $fakeapphost1 } -ModuleName MSFT_xWebfarm
        $result = Test-TargetResource -Name "SOMEFARMTHATEXISTS" -Ensures Present -Enabled $true
        $result | Should Be $true
    }
}
