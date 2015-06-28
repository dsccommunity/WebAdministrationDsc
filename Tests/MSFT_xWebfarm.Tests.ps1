$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) "..\DSCResources\MSFT_xWebfarm\MSFT_xWebfarm.psm1"
Import-Module "$sut" -Force

$fakeapphost1 = [xml]'<?xml version="1.0" encoding="UTF-8"?>
<configuration>
    <webFarms>
        <webFarm name="SOMEFARMTHATEXISTS" enabled="true">
            <applicationRequestRouting>
                <loadBalancing algorithm="RequestHash" hashServerVariable="QUERY_STRING" queryStringNames="q1" />
            </applicationRequestRouting>
        </webFarm>
        <webFarm name="SOMEDISABLEDFARM" enabled="false">            
        </webFarm>
        <webFarm name="SOMEFARMWITHOUTBALANCING" enabled="false">            
        </webFarm>
        <webFarm name="SOMEFARMWITHWeightedRoundRobin" enabled="false">            
        </webFarm>
        <webFarm name="SOMEFARMWITHRequestHash" enabled="false">            
            <applicationRequestRouting>
                <loadBalancing algorithm="RequestHash" />
            </applicationRequestRouting>
        </webFarm>
    </webFarms>
</configuration>'

Describe "MSFT_xWebfarm" {
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
    }  
    It "must return the specific load balancing algorithm when present [WeightedRoundRobin]" {
        Mock GetApplicationHostConfig { return $fakeapphost1 } -ModuleName MSFT_xWebfarm
        $webFarm = Get-TargetResource -Name "SOMEFARMWITHWeightedRoundRobin"
        $webFarm.LoadBalancing.Algorithm | Should Be "WeightedRoundRobin"
    }   
    It "must return the specific load balancing algorithm when present [RequestHash]" {
        Mock GetApplicationHostConfig { return $fakeapphost1 } -ModuleName MSFT_xWebfarm
        $webFarm = Get-TargetResource -Name "SOMEFARMWITHRequestHash"
        $webFarm.LoadBalancing.Algorithm | Should Be "RequestHash"
    }   
}
