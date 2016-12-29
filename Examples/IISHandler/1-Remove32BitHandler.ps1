<#
    .EXAMPLE
    Remove 32 bit handler.
#>

configuration Example
{
    param
    (
        [string[]] $NodeName = 'localhost'
    )

    Import-DscResource -Module xWebAdministration

    Node $NodeName
    {
        xIisHandler aspq_ISAPI_4_0_32bit
        {
            Name   = 'aspq-ISAPI-4.0_32bit'
            Ensure = 'Absent'
        }

        xIisHandler cshtm_ISAPI_4_0_32bit
        {
            Name   = 'cshtm-ISAPI-4.0_32bit'
            Ensure = 'Absent'
        }

        xIisHandler cshtml_ISAPI_4_0_32bit
        {
            Name   = 'cshtml-ISAPI-4.0_32bit'
            Ensure = 'Absent'
        }

        xIisHandler vbhtm_ISAPI_4_0_32bit
        {
            Name   = 'vbhtm-ISAPI-4.0_32bit'
            Ensure = 'Absent'
        }

        xIisHandler vbhtml_ISAPI_4_0_32bit
        {
            Name   = 'vbhtml-ISAPI-4.0_32bit'
            Ensure = 'Absent'
        }
    }
}
