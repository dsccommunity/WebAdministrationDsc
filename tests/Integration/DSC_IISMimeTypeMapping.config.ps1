configuration DSC_IisMimeTypeMapping_AddMimeType
{
    Import-DscResource -ModuleName WebAdministrationDsc

    IisMimeTypeMapping AddMimeType2
    {
        ConfigurationPath = ''
        Extension = $ConfigurationData.NonNodeData.FileExtension
        MimeType  = $ConfigurationData.NonNodeData.MimeType
        Ensure    = 'Present'
    }
}

configuration DSC_IisMimeTypeMapping_RemoveMimeType
{
    Import-DscResource -ModuleName WebAdministrationDsc

    IisMimeTypeMapping RemoveMimeType
    {
        ConfigurationPath = ''
        Extension = $ConfigurationData.NonNodeData.FileExtension
        MimeType  = $ConfigurationData.NonNodeData.MimeType
        Ensure    = 'Absent'
    }
}

Configuration DSC_IisMimeTypeMapping_AddMimeTypeNestedPath
{
    Import-DscResource -ModuleName WebAdministrationDsc

    IisMimeTypeMapping AddMimeTypeNestedPath
    {
        ConfigurationPath = $ConfigurationData.NonNodeData.VirtualConfigurationPath
        Extension         = $ConfigurationData.NonNodeData.FileExtension
        MimeType          = $ConfigurationData.NonNodeData.MimeType
        Ensure            = 'Present'
    }
}

Configuration DSC_IisMimeTypeMapping_RemoveMimeTypeNestedPath
{
    Import-DscResource -ModuleName WebAdministrationDsc

    IisMimeTypeMapping RemoveMimeTypeNestedPath
    {
        ConfigurationPath = $ConfigurationData.NonNodeData.VirtualConfigurationPath
        Extension         = $ConfigurationData.NonNodeData.FileExtension
        MimeType          = $ConfigurationData.NonNodeData.MimeType
        Ensure            = 'Absent'
    }
}

Configuration DSC_IisMimeTypeMapping_AddMimeTypeAtServer
{
    Import-DscResource -ModuleName WebAdministrationDsc

    IisMimeTypeMapping AddMimeTypeAtServer
    {
        ConfigurationPath = $ConfigurationData.NonNodeData.ServerConfigurationPath
        Extension         = $ConfigurationData.NonNodeData.FileExtension
        MimeType          = $ConfigurationData.NonNodeData.MimeType
        Ensure            = 'Present'
    }
}

Configuration DSC_IisMimeTypeMapping_RemoveMimeTypeAtServer
{
    Import-DscResource -ModuleName WebAdministrationDsc

    IisMimeTypeMapping AddMimeTypeAtServer
    {
        ConfigurationPath = $ConfigurationData.NonNodeData.ServerConfigurationPath
        Extension         = $ConfigurationData.NonNodeData.FileExtension
        MimeType          = $ConfigurationData.NonNodeData.MimeType
        Ensure            = 'Absent'
    }
}
