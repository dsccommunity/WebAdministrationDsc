configuration AllowDelegation
{
    Import-DscResource -ModuleName xWebAdministration

    xIisFeatureDelegation AllowDelegation
    {
        SectionName = "security/authentication/anonymousAuthentication"
        OverrideMode = "Allow"
    }
}

configuration DenyDelegation
{
    Import-DscResource -ModuleName xWebAdministration

    xIisFeatureDelegation DenyDelegation
    {
        SectionName = "defaultDocument"
        OverrideMode = "Deny"
    }
}

configuration RemoveHandler
{
    Import-DscResource -ModuleName xWebAdministration

    xIisHandler TRACEVerbHandler
    {
        Name = "TRACEVerbHandler"
        Ensure = "Absent"
    }
}

configuration AddHandler
{
    Import-DscResource -ModuleName xWebAdministration

    xIisHandler WebDAV
    {
        Name = "WebDAV"
        Ensure = "Present"
    }
}

configuration StaticFileHandler
{
    Import-DscResource -ModuleName xWebAdministration

    xIisHandler StaticFile
    {
        Name = "StaticFile"
        Ensure = "Present"
    }
}
