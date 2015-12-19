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
