param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $TargetName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $OutputPath
    )

Configuration Example
{
    Import-DscResource -ModuleName PSDesiredStateConfiguration, xWebAdministration

    Node $TargetName
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
            PhysicalPath         = "C:\Temp"
            Type                 = $null
            PreCondition         = $null
        }
    }
}

$null = Example -OutputPath $OutputPath
