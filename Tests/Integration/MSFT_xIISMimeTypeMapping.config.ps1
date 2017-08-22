configuration MSFT_xIISMimeTypeMapping_Config
{
    Import-DscResource -ModuleName xWebAdministration

    xIIsMimeTypeMapping AddMimeType
    {
        ConfigurationPath = ''
        Extension         = '.PesterDummy'
        MimeType          = 'text/plain'
        Ensure            = 'Present'
    }
}

configuration MSFT_xIISMimeTypeMapping_AddMimeType
{
    Import-DscResource -ModuleName xWebAdministration

    xIIsMimeTypeMapping AddMimeType2
    {
        ConfigurationPath = ''
        Extension = $ConfigurationData.NonNodeData.PesterFileExtension2
        MimeType  = $ConfigurationData.NonNodeData.PesterMimeType2
        Ensure    = 'Present'
    }
}

configuration MSFT_xIISMimeTypeMapping_RemoveMimeType
{
    Import-DscResource -ModuleName xWebAdministration

    xIIsMimeTypeMapping RemoveMimeType
    {
        ConfigurationPath = ''
        Extension = $ConfigurationData.NonNodeData.PesterFileExtension
        MimeType  = $ConfigurationData.NonNodeData.PesterMimeType
        Ensure    = 'Absent'
    }
}

configuration MSFT_xIISMimeTypeMapping_RemoveDummyMime
{
    Import-DscResource -ModuleName xWebAdministration

    xIIsMimeTypeMapping RemoveMimeType2
    {
        ConfigurationPath = ''
        Extension = '.PesterDummy2'
        MimeType  = 'text/dummy'
        Ensure    = 'Absent'
    }
}

Configuration MSFT_xIISMimeTypeMapping_AddMimeTypeNestedPath
{
    Import-DscResource -ModuleName xWebAdministration

    xIIsMimeTypeMapping AddMimeTypeNestedPath
    {
        ConfigurationPath = $ConfigurationData.NonNodeData.ConfigurationPath
        Extension         = $ConfigurationData.NonNodeData.FileExtension
        MimeType          = $ConfigurationData.NonNodeData.MimeType
        Ensure            = 'Present'
    }
}

Configuration MSFT_xIISMimeTypeMapping_RemoveMimeTypeNestedPath
{
    Import-DscResource -ModuleName xWebAdministration

    xIIsMimeTypeMapping RemoveMimeTypeNestedPath
    {
        ConfigurationPath = $ConfigurationData.NonNodeData.ConfigurationPath
        Extension         = $ConfigurationData.NonNodeData.FileExtension
        MimeType          = $ConfigurationData.NonNodeData.MimeType
        Ensure            = 'Absent'
    }
}
