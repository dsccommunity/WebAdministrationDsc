<#
    .DESCRIPTION
        This example shows how to use the xWebAdministration in an end to end scenario.
#>
configuration Sample_EndToEndxWebAdministration
{
    param
    (
        # Target nodes to apply the configuration
        [Parameter()]
        [String[]] $NodeName = 'localhost',
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [String] $WebAppPoolName,
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [String] $WebSiteName,
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [String] $PhysicalPathWebSite,
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [String] $WebApplicationName,
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [String] $PhysicalPathWebApplication,
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [String] $WebVirtualDirectoryName,
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [String] $PhysicalPathVirtualDir,
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [String] $Port
    )
    Import-DscResource -ModuleName PSDesiredStateConfiguration
    Import-DscResource -ModuleName xWebAdministration

    node $NodeName
    {
        # Create a Web Application Pool
        xWebAppPool NewWebAppPool
        {
            Name   = $WebAppPoolName
            Ensure = "Present"
            State  = "Started"
        }

        #Create physical path website
        file NewWebsitePath
        {
            DestinationPath = $PhysicalPathWebSite
            Type            = "Directory"
            Ensure          = "Present"
        }

        #Create physical path web application
        file NewWebApplicationPath
        {
            DestinationPath = $PhysicalPathWebApplication
            Type            = "Directory"
            Ensure          = "Present"
        }

        #Create physical path virtual directory
        file NewVirtualDirectoryPath
        {
            DestinationPath = $PhysicalPathVirtualDir
            Type            = "Directory"
            Ensure          = "Present"
        }

        #Create a New Website with Port
        xWebSite NewWebSite
        {
            Name         = $WebSiteName
            Ensure       = "Present"
            BindingInfo  = MSFT_xWebBindingInformation
            {
                Protocol = "http"
                Port     = $Port
            }

            PhysicalPath = $PhysicalPathWebSite
            State        = "Started"
            DependsOn    = @("[xWebAppPool]NewWebAppPool", "[File]NewWebsitePath")
        }

        #Create a new Web Application
        xWebApplication NewWebApplication
        {
            Name         = $WebApplicationName
            Website      = $WebSiteName
            WebAppPool   = $WebAppPoolName
            PhysicalPath = $PhysicalPathWebApplication
            Ensure       = "Present"
            DependsOn    = @("[xWebSite]NewWebSite", "[File]NewWebApplicationPath")
        }

        #Create a new virtual Directory
        xWebVirtualDirectory NewVirtualDir
        {
            Name           = $WebVirtualDirectoryName
            Website        = $WebSiteName
            WebApplication = $WebApplicationName
            PhysicalPath   = $PhysicalPathVirtualDir
            Ensure         = "Present"
            DependsOn      = @("[xWebApplication]NewWebApplication", "[File]NewVirtualDirectoryPath")
        }

        #Create an empty web.config file
        File CreateWebConfig
        {
            DestinationPath = $PhysicalPathWebSite + "\web.config"
            Contents        = "<?xml version=`"1.0`" encoding=`"UTF-8`"?>
                            <configuration>
                            </configuration>"
            Ensure          = "Present"
            DependsOn       = @("[xWebVirtualDirectory]NewVirtualDir")
        }

        #Add an appSetting key1
        xWebConfigKeyValue ModifyWebConfig
        {
            Ensure        = "Present"
            ConfigSection = "AppSettings"
            Key           = "key1"
            Value         = "value1"
            IsAttribute   = $false
            WebsitePath   = "IIS:\sites\" + $WebsiteName
            DependsOn     = @("[File]CreateWebConfig")
        }

        #Add a webApplicationHandler
        WebApplicationHandler WebHandlerTest
        {
            Name                = 'ATest-WebHandler'
            Path                = '*'
            Verb                = '*'
            Modules             = 'IsapiModule'
            RequireAccess       = 'None'
            ScriptProcessor     = "C:\Windows\Microsoft.NET\Framework64\v4.0.30319\aspnet_isapi.dll"
            ResourceType        = 'Unspecified'
            AllowPathInfo       = $false
            ResponseBufferLimit = 0
            PhysicalHandlerPath = $PhysicalPathWebApplication
            type                = $null
            PreCondition        = $null
            Location            = 'Default Web Site/TestDir'
        }
    }
}
