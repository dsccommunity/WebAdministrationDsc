cd $PSScriptRoot

Import-Module xWebAdministration -Force

Configuration Webfarm1
{
    param($Ensure,$Name, $Enabled, $LoadBalancing)
    Import-DscResource -Module xWebAdministration
    
    xWebfarm Farm1
    {
        Ensure = $Ensure
        Name = $Name
        Enabled = $Enabled
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

Webfarm1 -Ensure "Present" -Name "Farm1" -Enabled $true -OutputPath ($modulePath + "\test\mof")
Start-DscConfiguration -Path ($modulePath + "\test\mof") -Wait -Force

Webfarm1 -Ensure "Present" -Name "Farm1" -Enabled $true -LoadBalancing @{Algorithm="WeightedRoundRobin"} -OutputPath ($modulePath + "\test\mof")
Start-DscConfiguration -Path ($modulePath + "\test\mof") -Wait -Force

Webfarm1 -Ensure "Present" -Name "Farm1" -Enabled $true -LoadBalancing @{Algorithm="QueryString";QueryString="q1","q2"} -OutputPath ($modulePath + "\test\mof")
Start-DscConfiguration -Path ($modulePath + "\test\mof") -Wait -Force

Webfarm1 -Ensure "Present" -Name "Farm1" -Enabled $true -LoadBalancing @{Algorithm="ServerVariable";ServerVariable="x"} -OutputPath ($modulePath + "\test\mof")
Start-DscConfiguration -Path ($modulePath + "\test\mof") -Wait -Force

Webfarm1 -Ensure "Present" -Name "Farm1" -Enabled $false -OutputPath ($modulePath + "\test\mof")
Start-DscConfiguration -Path ($modulePath + "\test\mof") -Wait -Force

Webfarm1 -Ensure "Absent" -Name "Farm1" -OutputPath ($modulePath + "\test\mof")
Start-DscConfiguration -Path ($modulePath + "\test\mof") -Wait -Force