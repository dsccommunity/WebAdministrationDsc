cd $PSScriptRoot

Import-Module xWebAdministration -Force

Configuration Webfarm1
{
    param($Ensure,$Name, $Enabled, $Algorithm, $QueryString, $ServerVariable)
    Import-DscResource -Module xWebAdministration
    
    xWebfarm Farm1
    {
        Ensure = $Ensure
        Name = $Name
        Enabled = $Enabled
        Algorithm = $Algorithm
        QueryString = $QueryString
        ServerVariable = $ServerVariable
    }

    xWebfarmServer Server1
    {
        Ensure = $Ensure
        Name = $Name
        Enabled = $Enabled
    }
}

$VerbosePreference = "continue"

Webfarm1 -Ensure "Absent" -Name "Farm1" -OutputPath ($modulePath + "\test\mof")
Start-DscConfiguration -Path ($modulePath + "\test\mof") -Wait -Force
Write-Host "Verify and Continue"
Read-Host

Webfarm1 -Ensure "Present" -Name "Farm1" -Enabled $true -OutputPath ($modulePath + "\test\mof")
Start-DscConfiguration -Path ($modulePath + "\test\mof") -Wait -Force
Write-Host "Verify and Continue"
Read-Host

Webfarm1 -Ensure "Present" -Name "Farm1" -Enabled $true -Algorithm "WeightedRoundRobin" -OutputPath ($modulePath + "\test\mof")
Start-DscConfiguration -Path ($modulePath + "\test\mof") -Wait -Force
Write-Host "Verify and Continue"
Read-Host


Webfarm1 -Ensure "Present" -Name "Farm1" -Enabled $true -Algorithm "QueryString" -QueryString "q1,q2" -OutputPath ($modulePath + "\test\mof")
Start-DscConfiguration -Path ($modulePath + "\test\mof") -Wait -Force
Write-Host "Verify and Continue"
Read-Host

Webfarm1 -Ensure "Present" -Name "Farm1" -Enabled $true -Algorithm "ServerVariable" -ServerVariable "x" -OutputPath ($modulePath + "\test\mof")
Start-DscConfiguration -Path ($modulePath + "\test\mof") -Wait -Force
Write-Host "Verify and Continue"
Read-Host

Webfarm1 -Ensure "Present" -Name "Farm1" -Enabled $false -OutputPath ($modulePath + "\test\mof")
Start-DscConfiguration -Path ($modulePath + "\test\mof") -Wait -Force
Write-Host "Verify and Continue"
Read-Host

Webfarm1 -Ensure "Absent" -Name "Farm1" -OutputPath ($modulePath + "\test\mof")
Start-DscConfiguration -Path ($modulePath + "\test\mof") -Wait -Force
Write-Host "Verify and Continue"
Read-Host
