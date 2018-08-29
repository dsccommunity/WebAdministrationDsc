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
            VirtualDirectoryName = 'TestDir'
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
            Path                = $ConfigurationData.AllNodes.Path
            Name                = $ConfigurationData.AllNodes.Name
            PhysicalHandlerPath = $ConfigurationData.AllNodes.PhysicalHandlerPath
            Verb                = $ConfigurationData.AllNodes.Verb
            Modules             = $ConfigurationData.AllNodes.Modules
            RequireAccess       = $ConfigurationData.AllNodes.RequireAccess
            ScriptProcessor     = $ConfigurationData.AllNodes.ScriptProcessor
            ResourceType        = $ConfigurationData.AllNodes.ResourceType
            AllowPathInfo       = $ConfigurationData.AllNodes.AllowPathInfo
            ResponseBufferLimit = $ConfigurationData.AllNodes.ResponseBufferLimit
            Type                = $ConfigurationData.AllNodes.Type
            PreCondition        = $ConfigurationData.AllNodes.PreCondition
            Location            = "Default Web Site/$($ConfigurationData.AllNodes.VirtualDirectoryName)"
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
            Path                = $ConfigurationData.AllNodes.Path
            Name                = $ConfigurationData.AllNodes.Name
            PhysicalHandlerPath = $ConfigurationData.AllNodes.PhysicalHandlerPath
            Verb                = $ConfigurationData.AllNodes.Verb
            Modules             = $ConfigurationData.AllNodes.Modules
            RequireAccess       = $ConfigurationData.AllNodes.RequireAccess
            ScriptProcessor     = $ConfigurationData.AllNodes.ScriptProcessor
            ResourceType        = $ConfigurationData.AllNodes.ResourceType
            AllowPathInfo       = $ConfigurationData.AllNodes.AllowPathInfo
            ResponseBufferLimit = $ConfigurationData.AllNodes.ResponseBufferLimit
            Type                = $ConfigurationData.AllNodes.Type
            PreCondition        = $ConfigurationData.AllNodes.PreCondition
            Location            = "Default Web Site/$($ConfigurationData.AllNodes.VirtualDirectoryName)"
            Ensure              = 'Absent'
        }
    }
}
