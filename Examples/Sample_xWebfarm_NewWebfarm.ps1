cd $PSScriptRoot

Import-Module xWebAdministration -Force

Configuration Webfarm1
{
    param($Ensure,$Name, $Enabled)
    Import-DscResource -Module xWebAdministration
    
    xWebfarm Farm1
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

Webfarm1 -Ensure "Present" -Name "Farm1" -Enabled $false -OutputPath ($modulePath + "\test\mof")
Start-DscConfiguration -Path ($modulePath + "\test\mof") -Wait -Force

Webfarm1 -Ensure "Absent" -Name "Farm1" -OutputPath ($modulePath + "\test\mof")
Start-DscConfiguration -Path ($modulePath + "\test\mof") -Wait -Force