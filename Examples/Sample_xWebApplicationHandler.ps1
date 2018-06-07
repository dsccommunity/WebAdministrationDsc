Configuration Example
{
    Import-DscResource -ModuleName xWebAdministration

    Node 'localhost'
    {

        xWebApplicationHandler  WebHandlerTest
        {
            PSPath               = 'MACHINE/WEBROOT/APPHOST'
            Name                 = 'ATest-WebHandler'
            Path                 = '*'
            Verb                 = '*'
            Modules              = 'IsapiModule'
            RequireAccess        = 'None'
            ScriptProcessor      = "C:\Windows\Microsoft.NET\Framework64\v4.0.30319\aspnet_isapi.dll"
            ResourceType         = 'Unspecified'
            AllowPathInfo        = $false
            ResponseBufferLimit  = 0
            PhysicalPath         = "C:\temp"
            Type                 = $null
            PreCondition         = $null
        }
    }
}
