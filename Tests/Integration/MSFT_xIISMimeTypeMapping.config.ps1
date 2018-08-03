configuration MSFT_xIISMimeTypeMapping_AddMimeType
{
    Import-DscResource -ModuleName xWebAdministration

    xIISMimeTypeMapping AddMimeType2
    {
        ConfigurationPath = ''
        Extension = $ConfigurationData.NonNodeData.FileExtension
        MimeType  = $ConfigurationData.NonNodeData.MimeType
        Ensure    = 'Present'
    }
}

configuration MSFT_xIISMimeTypeMapping_RemoveMimeType
{
    Import-DscResource -ModuleName xWebAdministration

    xIISMimeTypeMapping RemoveMimeType
    {
        ConfigurationPath = ''
        Extension = $ConfigurationData.NonNodeData.FileExtension
        MimeType  = $ConfigurationData.NonNodeData.MimeType
        Ensure    = 'Absent'
    }
}

Configuration MSFT_xIISMimeTypeMapping_AddMimeTypeNestedPath
{
    Import-DscResource -ModuleName xWebAdministration

    xIISMimeTypeMapping AddMimeTypeNestedPath
    {
        ConfigurationPath = $ConfigurationData.NonNodeData.VirtualConfigurationPath
        Extension         = $ConfigurationData.NonNodeData.FileExtension
        MimeType          = $ConfigurationData.NonNodeData.MimeType
        Ensure            = 'Present'
    }
}

Configuration MSFT_xIISMimeTypeMapping_RemoveMimeTypeNestedPath
{
    Import-DscResource -ModuleName xWebAdministration

    xIISMimeTypeMapping RemoveMimeTypeNestedPath
    {
        ConfigurationPath = $ConfigurationData.NonNodeData.VirtualConfigurationPath
        Extension         = $ConfigurationData.NonNodeData.FileExtension
        MimeType          = $ConfigurationData.NonNodeData.MimeType
        Ensure            = 'Absent'
    }
}

Configuration MSFT_xIISMimeTypeMapping_AddMimeTypeAtServer
{
    Import-DscResource -ModuleName xWebAdministration

    xIISMimeTypeMapping AddMimeTypeAtServer
    {
        ConfigurationPath = $ConfigurationData.NonNodeData.ServerConfigurationPath
        Extension         = $ConfigurationData.NonNodeData.FileExtension
        MimeType          = $ConfigurationData.NonNodeData.MimeType
        Ensure            = 'Present'
    }
}

Configuration MSFT_xIISMimeTypeMapping_RemoveMimeTypeAtServer
{
    Import-DscResource -ModuleName xWebAdministration

    xIISMimeTypeMapping AddMimeTypeAtServer
    {
        ConfigurationPath = $ConfigurationData.NonNodeData.ServerConfigurationPath
        Extension         = $ConfigurationData.NonNodeData.FileExtension
        MimeType          = $ConfigurationData.NonNodeData.MimeType
        Ensure            = 'Absent'
    }
}
