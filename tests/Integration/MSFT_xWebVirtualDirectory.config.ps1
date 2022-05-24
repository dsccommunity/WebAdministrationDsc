#requires -Version 4
configuration DSC_xWebVirtualDirectory_Initialize
{
    Import-DscResource -ModuleName WebAdministrationDsc

    Node $AllNodes.NodeName
    {
        xWebSite Website
        {
            Ensure = 'Present'
            Name = $Node.Website
            PhysicalPath = $Node.WebsitePhysicalPath
            ApplicationPool = $Node.ApplicationPool
            BindingInfo     = DSC_xWebBindingInformation
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

        xWebApplication WebApplication
        {
            Name = $Node.WebApplication
            Website = $Node.Website
            WebAppPool = $Node.ApplicationPool
            PhysicalPath = $Node.WebApplicationPhysicalPath
            DependsOn = '[File]WebApplicationDirectory','[xWebSite]Website'
        }

        File WebVirtualDirectory
        {
            Ensure = 'Present'
            DestinationPath = $Node.PhysicalPath
            Type = 'Directory'
        }
    }
}

configuration DSC_xWebVirtualDirectory_Present
{
    Import-DscResource -ModuleName WebAdministrationDsc

    Node $AllNodes.NodeName
    {
        xWebVirtualDirectory WebVirtualDirectory
        {
            Ensure = 'Present'
            Website = $Node.Website
            WebApplication = $Node.WebApplication
            Name = $Node.WebVirtualDirectory
            PhysicalPath = $Node.PhysicalPath
        }
    }
}

configuration DSC_xWebVirtualDirectory_Absent
{
    Import-DscResource -ModuleName WebAdministrationDsc

    Node $AllNodes.NodeName 
    {
        xWebVirtualDirectory WebVirtualDirectory
        {
            Ensure = 'Absent'
            Website = $Node.Website
            WebApplication = $Node.WebApplication
            Name = $Node.WebVirtualDirectory
            PhysicalPath = $Node.PhysicalPath
        }
    }
}
