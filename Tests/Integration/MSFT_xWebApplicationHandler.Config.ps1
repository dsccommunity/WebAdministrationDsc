Configuration MSFT_xWebApplicationHandler_AddHandler
{
    Import-DSCResource -ModuleName xWebAdministration

    Node 'localhost'
    {
        xWebSite IISWebSite
        {
            Name                 = $node.Location
            State                = "Stopped"
            Ensure               = "Present"
            PhysicalPath         = "$env:SystemDrive\inetpub\wwwroot"
        }

        xWebApplicationHandler WebHandlerTest
        {
            PSPath               = $node.PSPath
            Name                 = $node.Name
            Path                 = $node.Path
            Verb                 = $node.Verb
            Modules              = $node.Modules
            RequireAccess        = $node.RequireAccess
            ScriptProcessor      = $node.ScriptProcessor
            ResourceType         = $node.ResourceType
            AllowPathInfo        = $node.AllowPathInfo
            ResponseBufferLimit  = $node.ResponseBufferLimit
            Type                 = $node.Type
            PreCondition         = $node.PreCondition
            Ensure               = 'Present'
            DependsOn            = "[xWebSite]IISWebSite"
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
            PSPath               = $node.PSPath
            Name                 = $node.Name
            Path                 = $node.Path
            Verb                 = $node.Verb
            Modules              = $node.Modules
            RequireAccess        = $node.RequireAccess
            ScriptProcessor      = $node.ScriptProcessor
            ResourceType         = $node.ResourceType
            AllowPathInfo        = $node.AllowPathInfo
            ResponseBufferLimit  = $node.ResponseBufferLimit
            Type                 = $node.Type
            PreCondition         = $node.PreCondition
            Ensure               = 'Absent'
        }

        xWebsite Remove_IISWebsite
        {
            Name                 = $node.Location
            Ensure               = "Absent"
            PhysicalPath         = "$env:SystemDrive\inetpub\wwwroot"
            DependsOn            = "[CustomWebHandler]WebHandlerTest"
        }
    }
}

$ConfigurationData = @{
    AllNodes = @(
        @{
            NodeName             = 'LocalHost'
            PSPath               = 'MACHINE/WEBROOT/APPHOST'
            Location             = 'Webtest'
            Name                 = 'ATest-WebHandler'
            Path                 = '*'
            Verb                 = '*'
            Modules              = 'IsapiModule'
            RequireAccess        = 'None'
            ScriptProcessor      = "C:\Windows\Microsoft.NET\Framework64\v4.0.30319\aspnet_isapi.dll"
            ResourceType         = 'Unspecified'
            AllowPathInfo        = $false
            ResponseBufferLimit  = 0
            PhysicalPath         = "C:\Temp"
            Type                 = $null
            PreCondition         = $null
        }
    )
}
