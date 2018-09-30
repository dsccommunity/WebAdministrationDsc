<#
.SYNOPSIS
    Removes the alternateHostName property of the default website

.DESCRIPTION
    This example shows how to use the xWebConfigPropertyLocation DSC resource for removing a configuration property on the default web site.
    It will remove the system.webServer/serverRuntime alternateHostName attribute (if specified) for the default web site.
#>
Configuration Sample_xWebConfigPropertyLocation_Remove
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
		xWebConfigPropertyLocation "$($NodeName)/Default Web Site - Remove the alternateHostName attribute (if specified) - Remove" 
		{
			WebSitePath = "MACHINE/WEBROOT/APPHOST"
			Filter = "system.webServer/serverRuntime"
			Location = "Default Web Site"
			PropertyName = "alternateHostName"
			Ensure = "Absent"
		}
	}
}