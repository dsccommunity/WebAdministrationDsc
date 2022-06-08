#requires -Version 4
configuration DSC_WebVirtualDirectory_Initialize
{
    Import-DscResource -ModuleName WebAdministrationDsc

    Node $AllNodes.NodeName
    {
        WebSite Website
        {
            Ensure = 'Present'
            Name = $Node.Website
            PhysicalPath = $Node.WebsitePhysicalPath
            ApplicationPool = $Node.ApplicationPool
            BindingInfo     = DSC_WebBindingInformation
            {
                Protocol              = 'http'
                Port                  = $Node.Port
                HostName              = $Node.Hostname
                IPAddress             = '*'
            }
        }

        File WebApplicationDirectory
        {
            Ensure = 'Present'
            DestinationPath = $Node.WebApplicationPhysicalPath
            Type = 'Directory'
        }

        WebApplication WebApplication
        {
            Name = $Node.WebApplication
            Website = $Node.Website
            WebAppPool = $Node.ApplicationPool
            PhysicalPath = $Node.WebApplicationPhysicalPath
            DependsOn = '[File]WebApplicationDirectory','[WebSite]Website'
        }

        File WebVirtualDirectory
        {
            Ensure = 'Present'
            DestinationPath = $Node.PhysicalPath
            Type = 'Directory'
        }
    }
}

configuration DSC_WebVirtualDirectory_Present
{
    Import-DscResource -ModuleName WebAdministrationDsc

    Node $AllNodes.NodeName
    {
        WebVirtualDirectory WebVirtualDirectory
        {
            Ensure = 'Present'
            Website = $Node.Website
            WebApplication = $Node.WebApplication
            Name = $Node.WebVirtualDirectory
            PhysicalPath = $Node.PhysicalPath
        }
    }
}

configuration DSC_WebVirtualDirectory_Absent
{
    Import-DscResource -ModuleName WebAdministrationDsc

    Node $AllNodes.NodeName
    {
        WebVirtualDirectory WebVirtualDirectory
        {
            Ensure = 'Absent'
            Website = $Node.Website
            WebApplication = $Node.WebApplication
            Name = $Node.WebVirtualDirectory
            PhysicalPath = $Node.PhysicalPath
        }
    }
}
