$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) "..\DSCResources\MSFT_xWebfarm\MSFT_xWebfarm.psm1"
Import-Module "$sut" -Force

$fakeapphost1 = [xml]'<?xml version="1.0" encoding="UTF-8"?><configuration><webFarms><webFarm name="SOMEFARMTHATEXISTS" enabled="true"></webFarm></webFarms></configuration>'
$fakeapphost2 = [xml]'<?xml version="1.0" encoding="UTF-8"?><configuration><webFarms><webFarm name="SOMEFARMTHATEXISTS" enabled="false"></webFarm></webFarms></configuration>'

Describe "MSFT_xWebfarm" {
    It "must return Ensures Absent if the webfarm does not exists" {
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
        Mock GetApplicationHostConfig { return $fakeapphost2 } -ModuleName MSFT_xWebfarm
        $webFarm = Get-TargetResource -Name "SOMEFARMTHATEXISTS"
        $webFarm.Enabled | Should Be $false
    }
}
