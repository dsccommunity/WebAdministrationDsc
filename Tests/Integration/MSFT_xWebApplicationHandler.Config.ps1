$ConfigurationData = @{
    AllNodes = @(
        @{
            NodeName            = 'LocalHost'
            Path                = 'MACHINE/WEBROOT/APPHOST'
            Location            = 'Webtest'
            Name                = 'ATest-WebHandler'
            PhysicalHandlerPath = '*'
            Verb                = '*'
            Modules             = 'IsapiModule'
            RequireAccess       = 'None'
            ScriptProcessor     = "C:\Windows\Microsoft.NET\Framework64\v4.0.30319\aspnet_isapi.dll"
            ResourceType        = 'Unspecified'
            AllowPathInfo       = $false
            ResponseBufferLimit = 0
            PhysicalPath        = "C:\Temp"
            Type                = 'SampleHandler'
            PreCondition        = 'IsapiModule'
        }
    )
}

Configuration MSFT_xWebApplicationHandler_AddHandler
{
    Import-DSCResource -ModuleName xWebAdministration

    Node 'localhost'
    {
        xWebApplicationHandler WebHandlerTest
        {
            Path                = 'MACHINE/WEBROOT/APPHOST'
            Name                = 'ATest-WebHandler'
            PhysicalHandlerPath = '*'
            Verb                = '*'
            Modules             = 'IsapiModule'
            RequireAccess       = 'None'
            ScriptProcessor     = "C:\Windows\Microsoft.NET\Framework64\v4.0.30319\aspnet_isapi.dll"
            ResourceType        = 'Unspecified'
            AllowPathInfo       = $false
            ResponseBufferLimit = 0
            Type                = 'SampleHandler'
            PreCondition        = 'IsapiModule'
            Ensure              = 'Present'
        }
    }
}

Configuration MSFT_xWebApplicationHandler_RemoveHandler
{
    Import-DSCResource -ModuleName PSDesiredStateConfiguration
    Import-DSCResource -ModuleName xWebAdministration

    Node 'localhost'
    {
        xWebApplicationHandler WebHandlerTest
        {
            Path                = 'MACHINE/WEBROOT/APPHOST'
            Name                = 'ATest-WebHandler'
            PhysicalHandlerPath = '*'
            Verb                = '*'
            Modules             = 'IsapiModule'
            RequireAccess       = 'None'
            ScriptProcessor     = "C:\Windows\Microsoft.NET\Framework64\v4.0.30319\aspnet_isapi.dll"
            ResourceType        = 'Unspecified'
            AllowPathInfo       = $false
            ResponseBufferLimit = 0
            Type                = 'SampleHandler'
            PreCondition        = 'IsapiModule'
            Ensure              = 'Absent'
        }

        xWebsite Remove_IISWebsite
        {
            Name         = $node.Location
            Ensure       = "Absent"
            PhysicalPath = "$env:SystemDrive\inetpub\wwwroot"
            DependsOn    = "[xWebApplicationHandler]WebHandlerTest"
        }
    }
}
