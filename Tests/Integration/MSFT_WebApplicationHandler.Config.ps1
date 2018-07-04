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

Configuration MSFT_WebApplicationHandler_AddHandler
{
    Import-DSCResource -ModuleName xWebAdministration

    Node 'localhost'
    {
        WebApplicationHandler WebHandlerTest
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

Configuration MSFT_WebApplicationHandler_RemoveHandler
{
    Import-DSCResource -ModuleName PSDesiredStateConfiguration
    Import-DSCResource -ModuleName xWebAdministration

    Node 'localhost'
    {
        WebApplicationHandler WebHandlerTest
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
    }
}
