Configuration Sample_xWebSiteAlive_200ok
{
    Import-DscResource -Module xWebAdministration
    
    xWebsite DefaultWebSite
    {
        Ensure = 'Present'
        Name   = 'Default Web Site'
        State  = 'Started'
    }

    xWebSiteAlive WebSiteAlive
    {
        WebSiteName = 'Default Web Site'
        RelativeUrl = '/'
    }
}
