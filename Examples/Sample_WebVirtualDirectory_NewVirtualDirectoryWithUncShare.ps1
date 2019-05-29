<#
    .SYNOPSIS
        Create a new web virtual directories on the Default Web Site.

    .DESCRIPTION
        This example shows how to use the WebVirtualDirectory DSC resource to create a new virtual
        directories on the Default Web Site and use Azure File share as a physical path.
#>
configuration Sample_WebVirtualDirectory_NewVirtualDirectoryWithUncShare
{
    param
    (
        # Target nodes to apply the configuration
        [System.String[]]
        $NodeName = 'localhost',

        # Name of virtual directory to create
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $VirtualDirectoryName,

        # Physical path of the virtual directory
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $PhysicalPath = '\\testazurestorageaccount.core.windows.net\fileshare',

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $AzureStorageAccount = 'testazurestorageaccount',

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $AzureStorageConnectionString
    )

    # Import the module that defines custom resources
    Import-DscResource -Module PSDesiredStateConfiguration
    Import-DscResource -Module xWebAdministration

    [System.Management.Automation.PSCredential] $Credential = New-Object System.Management.Automation.PSCredential ($AzureStorageAccount, (ConvertTo-SecureString -String $AzureStorageConnectionString -AsPlaintText -Force))

    Node $NodeName
    {
        <#
            Create local user for physical path access
            Section "More Information" https://support.microsoft.com/en-us/help/247099/access-denied-when-connecting-to-a-ftp-directory-that-uses-a-unc-path
        #>
        User BlobStorageAccount
        {
            Ensure                   = 'Present'
            UserName                 = $AzureStorageAccount
            Password                 = $Credential
            Description              = 'User account needed for validation of connection to the blob storage'
            PasswordNeverExpires     = $true
            PasswordChangeNotAllowed = $true
        }

        # Install the IIS role
        WindowsFeature IIS
        {
            Ensure = 'Present'
            Name   = 'Web-Server'
        }

        # Start the default website
        xWebsite DefaultSite
        {
            Ensure       = 'Present'
            Name         = 'Default Web Site'
            State        = 'Started'
            PhysicalPath = 'C:\inetpub\wwwroot'
            DependsOn    = '[WindowsFeature]IIS'
        }

        # Create the new virtual directory at site root
        WebVirtualDirectory VD_UNC
        {
            Ensure                    = 'Present'
            Site                      = 'Default Web Site'
            Application               = ''
            Name                      = $VirtualDirectoryName
            PhysicalPath              = $PhysicalPath
            PhysicalPathAccessAccount = $AzureStorageAccount
            PhysicalPathAccessPass    = $AzureStorageConnectionString
            DependsOn                 = '[WindowsFeature]IIS', '[User]BlobStorageAccount'
        }
    }
}
