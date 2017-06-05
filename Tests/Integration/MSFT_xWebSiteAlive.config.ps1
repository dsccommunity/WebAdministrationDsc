Configuration MSFT_xWebSiteAlive_Config {
    Import-DscResource -ModuleName xWebAdministration

    Node $AllNodes.NodeName {
        xWebSiteAlive WebSiteAlive
        {
            WebSiteName      = $Node.WebSiteName
            RelativeUrl      = "/$($Node.RequestFileName)"
            ValidStatusCodes = 200
            ExpectedContent  = $Node.RequestFileContent
        }
    }
}
