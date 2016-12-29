<#
    .EXAMPLE 
    This example shows how to configure a new website on a node.
#>

configuration Example
{
    Import-DscResource -ModuleName xWebAdministration,PSDesiredStateConfiguration

    Node localhost
    {
        # Create a Web Application Pool
        xWebAppPool NewWebAppPool
        {
            Name   = 'TestAppPool'
            Ensure = "Present"
            State  = "Started"
        }

        #Create physical path website
        File NewWebsitePath
        {
            DestinationPath = 'C:\web\webApplication'
            Type = "Directory"
            Ensure = "Present"
        }

        #Create physical path web application
        File NewWebApplicationPath
        {
            DestinationPath = 'C:\web\webApplication'
            Type = "Directory"
            Ensure = "Present"
        }

        #Create physical path virtual directory
        File NewVirtualDirectoryPath
        {
            DestinationPath = 'C:\web\virtualDir'
            Type = "Directory"
            Ensure = "Present"
        }

        #Create a New Website with Port
        xWebSite NewWebSite
        {
            Name   = 'contoso.com'
            Ensure = "Present"
            BindingInfo = MSFT_xWebBindingInformation
            {
                Protocol = "http"
                Port = 100
            }

            PhysicalPath = 'C:\web\webApplication'
            State = "Started"
            DependsOn = @("[xWebAppPool]NewWebAppPool","[File]NewWebsitePath")
        }

        #Create a new Web Application
        xWebApplication NewWebApplication
        {
            Name = 'TestWebApplication'
            Website = 'contoso.com'
            WebAppPool =  'TestAppPool'
            PhysicalPath = 'C:\web\webApplication'
            Ensure = "Present"
            DependsOn = @("[xWebSite]NewWebSite","[File]NewWebApplicationPath")
        }

        #Create a new virtual Directory
        xWebVirtualDirectory NewVirtualDir
        {
            Name = 'TestVirtualDir'
            Website = 'contoso.com'
            WebApplication =  'TestWebApplication'
            PhysicalPath = 'C:\web\virtualDir'
            Ensure = "Present"
            DependsOn = @("[xWebApplication]NewWebApplication","[File]NewVirtualDirectoryPath")
        }

        #Create an empty web.config file
        File CreateWebConfig
        {
             DestinationPath = 'C:\web\webApplication' + "\web.config"
             Contents = "<?xml version=`"1.0`" encoding=`"UTF-8`"?>
                            <configuration>
                            </configuration>"
                    Ensure = "Present"
             DependsOn = @("[xWebVirtualDirectory]NewVirtualDir")
        }

        #Add an appSetting key1
        xWebConfigKeyValue ModifyWebConfig
        {
            Ensure = "Present"
            ConfigSection = "AppSettings"
            Key = "key1"
            Value = "value1"
            IsAttribute = $false
            WebsitePath = "IIS:\sites\contoso.com"
            DependsOn = @("[File]CreateWebConfig")
        }
    }
}
