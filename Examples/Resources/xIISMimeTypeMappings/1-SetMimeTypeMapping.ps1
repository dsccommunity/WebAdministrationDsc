<#
    .EXAMPLE
    This example shows how to remove some mime types and set one mime type in particular.
#>

configuration Example
{
    param
    (
        # Target nodes to apply the configuration
        [string[]] $NodeName = 'localhost'
    )

    # Import the module that defines custom resources
    Import-DscResource -Module xWebAdministration

    Node $NodeName
    {
        # Remove a bunch of Video Mime Type mappings
        xIisMimeTypeMapping Mp2
        {
            Ensure      = 'Absent'
            Extension   = '.mp2'
            MimeType    = 'video/mpeg'
        }

        xIisMimeTypeMapping Mp4 
        {
            Ensure      = 'Absent'
            Extension   = '.mp4'
            MimeType    = 'video/mp4'
        }

        xIisMimeTypeMapping Mpeg 
        {
            Ensure      = 'Absent'
            Extension   = '.mpeg'
            MimeType    = 'video/mpeg'
        }

        xIisMimeTypeMapping Mpg 
        {
            Ensure      = 'Present'
            Extension   = '.mpg'
            MimeType    = 'video/mpeg'
        }
    }
}
