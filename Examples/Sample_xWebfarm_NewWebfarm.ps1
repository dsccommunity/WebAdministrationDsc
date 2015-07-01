Import-Module xWebAdministration -Force

Configuration Webfarm1
{
    Import-DscResource -Module xWebAdministration
    
    xWebfarm Farm1
    {
        Ensure = "Present"
        Name = "Farm1"        
    }
}

$VerbosePreference = "continue"

Webfarm1 -OutputPath ($modulePath + "\test\mof")
Start-DscConfiguration -Path ($modulePath + "\test\mof") -Wait -Force
 
#Get-WinEvent -LogName Microsoft-Windows-DSC/Operational | Select Message -First 10 | out-gridview