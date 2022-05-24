Configuration Example
{
    Import-DscResource -ModuleName WebAdministrationDsc

    Node 'localhost'
    {

        WebApplicationHandler  WebHandlerTest
        {
            Path                 = 'MACHINE/WEBROOT/APPHOST'
            Name                 = 'ATest-WebHandler'
            PhysicalHandlerPath  = '*'
            Verb                 = '*'
            Modules              = 'IsapiModule'
            RequireAccess        = 'None'
            ScriptProcessor      = "C:\Windows\Microsoft.NET\Framework64\v4.0.30319\aspnet_isapi.dll"
            ResourceType         = 'Unspecified'
            AllowPathInfo        = $false
            ResponseBufferLimit  = 0
            Type                 = $null
            PreCondition         = $null
            Location             = 'Default Web Site/TestDir'
        }
    }
}
