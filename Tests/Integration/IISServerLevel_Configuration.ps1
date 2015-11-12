configuration ManagedRuntimeVersion
{
    Import-DscResource -ModuleName xWebAdministration

    xWebAppPoolDefaults PoolDefaults
    {
        ApplyTo = "Machine"
        ManagedRuntimeVersion = "$env:PesterManagedRuntimeVersion"
    }
}

configuration InvalidManagedRuntimeVersion
{
    Import-DscResource -ModuleName xWebAdministration

    xWebAppPoolDefaults PoolDefaults
    {
        ApplyTo = "Machine"
        ManagedRuntimeVersion = "v1.5"
    }
}

configuration AppPoolIdentityType
{
    Import-DscResource -ModuleName xWebAdministration

    xWebAppPoolDefaults PoolDefaults
    {
        ApplyTo = "Machine"
        IdentityType = "$env:PesterApplicationPoolIdentity"
    }
}

configuration LogFormat
{
    Import-DscResource -ModuleName xWebAdministration

    xWebSiteDefaults LogFormat
    {
        ApplyTo = "Machine"
        LogFormat = "$env:PesterLogFormat"
    }
}

configuration DefaultPool
{
    Import-DscResource -ModuleName xWebAdministration

    xWebSiteDefaults DefaultPool
    {
        ApplyTo = "Machine"
        DefaultApplicationPool = "$env:PesterDefaultPool"
    }
}

configuration virtualDirectoryDefaults
{
    Import-DscResource -ModuleName xWebAdministration

    xWebSiteDefaults virtualDirectoryDefaults
    {
        ApplyTo = "Machine"
        AllowSubDirConfig = "$env:PesterVirtualDirectoryDefaults"
    }
}

configuration AddMimeType
{
    Import-DscResource -ModuleName xWebAdministration

    xIIsMimeTypeMapping AddMimeType
    {
        Extension = ".PesterDummy"
        MimeType = "text/plain"
        Ensure = "Present"
    }
}

configuration AddMimeType2
{
    Import-DscResource -ModuleName xWebAdministration

    xIIsMimeTypeMapping AddMimeType2
    {
        Extension = $env:PesterFileExtension2
        MimeType = "$env:PesterMimeType2"
        Ensure = "Present"
    }
}

configuration RemoveMimeType
{
    Import-DscResource -ModuleName xWebAdministration

    xIIsMimeTypeMapping RemoveMimeType
    {
        Extension = $env:PesterFileExtension
        MimeType = "$env:PesterMimeType"
        Ensure = "Absent"
    }
}

configuration RemoveMimeType2
{
    Import-DscResource -ModuleName xWebAdministration

    xIIsMimeTypeMapping RemoveMimeType2
    {
        Extension = ".PesterDummy2"
        MimeType = "text/dummy"
        Ensure = "Absent"
    }
}

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
