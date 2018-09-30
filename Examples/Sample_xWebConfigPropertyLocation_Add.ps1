<#
.SYNOPSIS
    Configures the alternateHostName property of the default website

.DESCRIPTION
    This example shows how to use the xWebConfigPropertyLocation DSC resource for setting a configuration property on the default web site.
    It will set the value of the system.webServer/serverRuntime alternateHostName attribute to a specified hostname in the ApplicationHost.config file for the default web site.
#>
Configuration Sample_xWebConfigPropertyLocation_Add
{
    param
    (
        # Target nodes to apply the configuration.
        [Parameter()]
        [String[]]
        $NodeName = 'localhost'
    )

    # Import the modules that define custom resources
    Import-DscResource -ModuleName xWebAdministration

    Node $NodeName
    {
		xWebConfigPropertyLocation "$($NodeName)/Default Web Site - Specify the alternateHostName attribute of a site. - Add" 
		{
			WebSitePath = "MACHINE/WEBROOT/APPHOST"
			Filter = "system.webServer/serverRuntime"
			Location = "Default Web Site"
			PropertyName = "alternateHostName"
			Value = "<HostName>"
			Ensure = "Present"
		}
    }
}