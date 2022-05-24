<#
    .DESCRIPTION
        This example shows how to use the WebAdministrationDsc in an end to end scenario.
#>
configuration Sample_EndToEndWebAdministrationDsc
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
    Import-DscResource -ModuleName WebAdministrationDsc

    node $NodeName
    {
        # Create a Web Application Pool
        WebAppPool NewWebAppPool
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
        WebSite NewWebSite
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
            DependsOn    = @("[WebAppPool]NewWebAppPool", "[File]NewWebsitePath")
        }

        #Create a new Web Application
        WebApplication NewWebApplication
        {
            Name         = $WebApplicationName
            Website      = $WebSiteName
            WebAppPool   = $WebAppPoolName
            PhysicalPath = $PhysicalPathWebApplication
            Ensure       = "Present"
            DependsOn    = @("[WebSite]NewWebSite", "[File]NewWebApplicationPath")
        }

        #Create a new virtual Directory
        WebVirtualDirectory NewVirtualDir
        {
            Name           = $WebVirtualDirectoryName
            Website        = $WebSiteName
            WebApplication = $WebApplicationName
            PhysicalPath   = $PhysicalPathVirtualDir
            Ensure         = "Present"
            DependsOn      = @("[WebApplication]NewWebApplication", "[File]NewVirtualDirectoryPath")
        }

        #Create an empty web.config file
        File CreateWebConfig
        {
            DestinationPath = $PhysicalPathWebSite + "\web.config"
            Contents        = "<?xml version=`"1.0`" encoding=`"UTF-8`"?>
                            <configuration>
                            </configuration>"
            Ensure          = "Present"
            DependsOn       = @("[WebVirtualDirectory]NewVirtualDir")
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
