configuration MSFT_xIISMimeTypeMapping_AddMimeType
{
    Import-DscResource -ModuleName MN_WebAdministration

    MN_xIIsMimeTypeMapping AddMimeType2
    {
        ConfigurationPath = ''
        Extension = $ConfigurationData.NonNodeData.PesterFileExtension2
        MimeType  = $ConfigurationData.NonNodeData.PesterMimeType2
        Ensure    = 'Present'
    }
}

configuration MSFT_xIISMimeTypeMapping_RemoveMimeType
{
    Import-DscResource -ModuleName MN_WebAdministration

    MN_xIIsMimeTypeMapping RemoveMimeType
    {
        ConfigurationPath = ''
        Extension = $ConfigurationData.NonNodeData.PesterFileExtension
        MimeType  = $ConfigurationData.NonNodeData.PesterMimeType
        Ensure    = 'Absent'
    }
}

Configuration MSFT_xIISMimeTypeMapping_AddMimeTypeNestedPath
{
    Import-DscResource -ModuleName MN_WebAdministration

    MN_xIIsMimeTypeMapping AddMimeTypeNestedPath
    {
        ConfigurationPath = $ConfigurationData.NonNodeData.ConfigurationPath
        Extension         = $ConfigurationData.NonNodeData.FileExtension
        MimeType          = $ConfigurationData.NonNodeData.MimeType
        Ensure            = 'Present'
    }
}

Configuration MSFT_xIISMimeTypeMapping_RemoveMimeTypeNestedPath
{
    Import-DscResource -ModuleName MN_WebAdministration

    MN_xIIsMimeTypeMapping RemoveMimeTypeNestedPath
    {
        ConfigurationPath = $ConfigurationData.NonNodeData.ConfigurationPath
        Extension         = $ConfigurationData.NonNodeData.FileExtension
        MimeType          = $ConfigurationData.NonNodeData.MimeType
        Ensure            = 'Absent'
    }
}

Configuration MSFT_xIISMimeTypeMapping_AddMimeTypeAtServer
{
    Import-DscResource -ModuleName MN_WebAdministration

    MN_xIIsMimeTypeMapping AddMimeTypeAtServer
    {
        ConfigurationPath = $ConfigurationData.NonNodeData.ConfigurationPath
        Extension         = $ConfigurationData.NonNodeData.FileExtension
        MimeType          = $ConfigurationData.NonNodeData.MimeType
        Ensure            = 'Present'
    }
}

Configuration MSFT_xIISMimeTypeMapping_RemoveMimeTypeAtServer
{
    Import-DscResource -ModuleName MN_WebAdministration

    MN_xIIsMimeTypeMapping AddMimeTypeAtServer
    {
        ConfigurationPath = $ConfigurationData.NonNodeData.ConfigurationPath
        Extension         = $ConfigurationData.NonNodeData.FileExtension
        MimeType          = $ConfigurationData.NonNodeData.MimeType
        Ensure            = 'Absent'
    }
}
