#requires -Version 4
configuration MSFT_xWebVirtualDirectory_Initialize
{
    Import-DscResource -ModuleName xWebAdministration

    Node $AllNodes.NodeName
    {
        xWebSite Website
        {
            Ensure = 'Present'
            Name = $Node.Website
            PhysicalPath = $Node.WebsitePhysicalPath
            ApplicationPool = $Node.ApplicationPool
            BindingInfo     = MSFT_xWebBindingInformation
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

configuration MSFT_xWebVirtualDirectory_Present
{
    Import-DscResource -ModuleName xWebAdministration

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

configuration MSFT_xWebVirtualDirectory_Absent
{
    Import-DscResource -ModuleName xWebAdministration

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
