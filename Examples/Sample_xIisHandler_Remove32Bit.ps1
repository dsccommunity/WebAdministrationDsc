configuration Sample_RemoveVideoMimeTypeMappings
{
    param
    (
        # Target nodes to apply the configuration
        [string[]]$NodeName = 'localhost'
    )

    # Import the module that defines custom resources
    Import-DscResource -Module xWebAdministration

    Node $NodeName
    {
        # Install the IIS role
        WindowsFeature IIS
        {
            Ensure          = "Present"
            Name            = "Web-Server"
        }

        xIisHandler aspq_ISAPI_4_0_32bit
        {
            Name = "aspq-ISAPI-4.0_32bit"
            Ensure = "Absent"
        }

        xIisHandler cshtm_ISAPI_4_0_32bit
        {
            Name = "cshtm-ISAPI-4.0_32bit"
            Ensure = "Absent"
        }

        xIisHandler cshtml_ISAPI_4_0_32bit
        {
            Name = "cshtml-ISAPI-4.0_32bit"
            Ensure = "Absent"
        }

    }
}
