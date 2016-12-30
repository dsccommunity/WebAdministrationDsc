#requires -Version 4
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
