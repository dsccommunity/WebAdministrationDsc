[![Build status](https://ci.appveyor.com/api/projects/status/gnsxkjxht31ctan1/branch/WebAdministrationDsc?svg=true)](https://ci.appveyor.com/project/PowerShell/xwebadministration/branch/WebAdministrationDsc)

# WebAdministrationDsc

The **WebAdministrationDsc** module contains the **IisLogging**, **Website**, and **SslSettings** DSC resources for creating and configuring various IIS artifacts.

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/).
For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any additional questions or comments.

## Contributing
Please check out common DSC Resources [contributing guidelines](https://github.com/PowerShell/DscResource.Kit/blob/master/CONTRIBUTING.md).

## Requiremets to Run Module

* Must be using a Windows server
* Must have Windows-Feature Web-Server installed: -- >Install-WindowsFeature Web-Server

## Resources

### IisLogging
**Note** This will set the logfile settings for **all** websites; for individual websites use the Log options under **Website**
* **LogPath**: The directory to be used for logfiles.
* **LogFlags**: The W3C logging fields: The values that are allowed for this property are: `Date`,`Time`,`ClientIP`,`UserName`,`SiteName`,`ComputerName`,`ServerIP`,`Method`,`UriStem`,`UriQuery`,`HttpStatus`,`Win32Status`,`BytesSent`,`BytesRecv`,`TimeTaken`,`ServerPort`,`UserAgent`,`Cookie`,`Referer`,`ProtocolVersion`,`Host`,`HttpSubStatus`
* **LogPeriod**: How often the log file should rollover. The values that are allowed for this property are: `Hourly`,`Daily`,`Weekly`,`Monthly`,`MaxSize`
* **LogTruncateSize**: How large the file should be before it is truncated. If this is set then LogPeriod will be ignored if passed in and set to MaxSize. The value must be a valid integer between `1048576 (1MB)` and `4294967295 (4GB)`.
* **LoglocalTimeRollover**: Use the localtime for file naming and rollover. The acceptable values for this property are: `$true`, `$false`
* **LogFormat**: Format of the Logfiles. **Note** Only W3C supports LogFlags. The acceptable values for this property are: `IIS`,`W3C`,`NCSA`

### Website

* **Name**: The desired name of the website.
* **PhysicalPath**: The path to the files that compose the website.
* **State**: The state of the website: { Started | Stopped }
* **BindingInfo**: Website's binding information in the form of an array of embedded instances of the **MSFT_WebBindingInformation** CIM class that implements the following properties:
    * **Protocol**: The protocol of the binding. This property is required. The acceptable values for this property are: `http`, `https`, `msmq.formatname`, `net.msmq`, `net.pipe`, `net.tcp`.
    * **BindingInformation**: The binding information in the form a colon-delimited string that includes the IP address, port, and host name of the binding. This property is ignored for `http` and `https` bindings if at least one of the following properties is specified: **IPAddress**, **Port**, **HostName**.
    * **IPAddress**: The IP address of the binding. This property is only applicable for `http` and `https` bindings. The default value is `*`.
    * **Port**: The port of the binding. The value must be a positive integer between `1` and `65535`. This property is only applicable for `http` (the default value is `80`) and `https` (the default value is `443`) bindings.
    * **HostName**: The host name of the binding. This property is only applicable for `http` and `https` bindings.
    * **CertificateThumbprint**: The thumbprint of the certificate. This property is only applicable for `https` bindings.
    * **CertificateStoreName**: The name of the certificate store where the certificate is located. This property is only applicable for `https` bindings. The acceptable values for this property are: `My`, `WebHosting`. The default value is `My`.
    * **SslFlags**: The type of binding used for Secure Sockets Layer (SSL) certificates. This property is supported in IIS 8.0 or later, and is only applicable for `https` bindings. The acceptable values for this property are:
        * **0**: The default value. The secure connection be made using an IP/Port combination. Only one certificate can be bound to a combination of IP address and the port.
        * **1**: The secure connection be made using the port number and the host name obtained by using Server Name Indication (SNI). It allows multiple secure websites with different certificates to use the same IP address.
        * **2**: The secure connection be made using the Centralized Certificate Store without requiring a Server Name Indication.
        * **3**: The secure connection be made using the Centralized Certificate Store while requiring Server Name Indication.
* **ApplicationPool**: The website’s application pool.
* **EnabledProtocols**: The protocols that are enabled for the website.
* **Ensure**: Ensures that the website is **Present** or **Absent**.
* **PreloadEnabled**: When set to `$true` this will allow WebSite to automatically start without a request
* **ServiceAutoStartEnabled**: When set to `$true` this will enable Autostart on a Website
* **ServiceAutoStartProvider**: Adds a AutostartProvider
* **ApplicationType**: Adds a AutostartProvider ApplicationType
* **AuthenticationInformation**: Website's authentication information in the form of an array of embedded instances of the **MSFT_WebAuthenticationInformation** CIM class. **MSFT_WebAuthenticationInformation** take the following properties:
    * **Anonymous**: The acceptable values for this property are: `$true`, `$false`
    * **Basic**: The acceptable values for this property are: `$true`, `$false`
    * **Digest**: The acceptable values for this property are: `$true`, `$false`
    * **Windows**: The acceptable values for this property are: `$true`, `$false`
* **LogPath**: The directory to be used for logfiles.
* **LogFlags**: The W3C logging fields: The values that are allowed for this property are: `Date`,`Time`,`ClientIP`,`UserName`,`SiteName`,`ComputerName`,`ServerIP`,`Method`,`UriStem`,`UriQuery`,`HttpStatus`,`Win32Status`,`BytesSent`,`BytesRecv`,`TimeTaken`,`ServerPort`,`UserAgent`,`Cookie`,`Referer`,`ProtocolVersion`,`Host`,`HttpSubStatus`
* **LogPeriod**: How often the log file should rollover. The values that are allowed for this property are: `Hourly`,`Daily`,`Weekly`,`Monthly`,`MaxSize`
* **LogTruncateSize**: How large the file should be before it is truncated. If this is set then LogPeriod will be ignored if passed in and set to MaxSize. The value must be a valid integer between `1048576 (1MB)` and `4294967295 (4GB)`.
* **LoglocalTimeRollover**: Use the localtime for file naming and rollover. The acceptable values for this property are: `$true`, `$false`
* **LogFormat**: Format of the Logfiles. **Note**Only W3C supports LogFlags. The acceptable values for this property are: `IIS`,`W3C`,`NCSA`

### SslSettings
* **Name**: The Name of website in which to modify the SSL Settings
* **Bindings**: The SSL bindings to implement.
* **Ensure**: Ensures if the bindings are Present or Absent.

## Versions

### Unreleased

* Initial release with the following resources
    - **IisLogging**
    - **Website**
    - **SslSettings**


## Examples

## Stopping the default website

When configuring a new IIS server, several references recommend removing or stopping the default website for security purposes.
This example sets up your IIS web server by installing IIS Windows Feature.
After that, it will stop the default website by setting `State = Stopped`.

```powershell
Configuration Sample_Website_StopDefault
{
    param
    (
        # Target nodes to apply the configuration
        [String[]] $NodeName = 'localhost'
    )
    # Import the module that defines custom resources
    Import-DscResource -Module WebAdministrationDsc
    
    Node $NodeName
    {
        # Install the IIS role
        WindowsFeature IIS
        {
            Ensure          = "Present"
            Name            = "Web-Server"
        }
        
        # Stop the default website
        Website DefaultSite
        {
            Ensure          = "Present"
            Name            = "Default Web Site"
            State           = "Stopped"
            PhysicalPath    = "C:\inetpub\wwwroot"
            DependsOn       = "[WindowsFeature]IIS"
        }
    }
}
```

### Create a new website

While setting up IIS and stopping the default website is interesting, it isn’t quite useful yet.
After all, people typically use IIS to set up websites of their own with custom protocol and bindings.
Fortunately, using DSC, adding another website is as simple as using the File and Website resources to copy the website content and configure the website.

```powershell
Configuration Sample_Website_NewWebsite
{
    param
    (
        # Target nodes to apply the configuration
        [String[]] $NodeName = 'localhost',
        
        # Name of the website to create
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [String] $WebSiteName,
        
        # Source Path for Website content
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [String] $SourcePath,
        
        # Destination path for Website content
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [String] $DestinationPath
    )

    # Import the module that defines custom resources
    Import-DscResource -Module WebAdministrationDsc
    Node $NodeName
    {
        # Install the IIS role
        WindowsFeature IIS
        {
            Ensure          = "Present"
            Name            = "Web-Server"
        }

        # Install the ASP .NET 4.5 role
        WindowsFeature AspNet45
        {
            Ensure          = "Present"
            Name            = "Web-Asp-Net45"
        }

        # Stop the default website
        Website DefaultSite
        {
            Ensure          = "Present"
            Name            = "Default Web Site"
            State           = "Stopped"
            PhysicalPath    = "C:\inetpub\wwwroot"
            DependsOn       = "[WindowsFeature]IIS"
        }

        # Copy the website content
        File WebContent
        {
            Ensure          = "Present"
            SourcePath      = $SourcePath
            DestinationPath = $DestinationPath
            Recurse         = $true
            Type            = "Directory"
            DependsOn       = "[WindowsFeature]AspNet45"
        }

        # Create the new Website with HTTPS
        Website NewWebsite
        {
            Ensure          = "Present"
            Name            = $WebSiteName
            State           = "Started"
            PhysicalPath    = $DestinationPath
            BindingInfo     = @(
                MSFT_WebBindingInformation
                {
                    Protocol              = "HTTPS"
                    Port                  = 8443
                    CertificateThumbprint = "71AD93562316F21F74606F1096B85D66289ED60F"
                    CertificateStoreName  = "WebHosting"
                },
                MSFT_WebBindingInformation
                {
                    Protocol              = "HTTPS"
                    Port                  = 8444
                    CertificateThumbprint = "DEDDD963B28095837F558FE14DA1FDEFB7FA9DA7"
                    CertificateStoreName  = "MY"
                }
            )
            DependsOn       = "[File]WebContent"
        }
    }
}
```

### Creating the default website using configuration data

In this example, we’ve moved the parameters used to generate the website into a configuration data file.
All of the variant portions of the configuration are stored in a separate file.
This can be a powerful tool when using DSC to configure a project that will be deployed to multiple environments.
For example, users managing larger environments may want to test their configuration on a small number of machines before deploying it across many more machines in their production environment.

Configuration files are made with this in mind.
This is an example configuration data file (saved as a .psd1).

```powershell
Configuration Sample_Website_FromConfigurationData
{
    # Import the module that defines custom resources
    Import-DscResource -Module WebAdministrationDsc

    # Dynamically find the applicable nodes from configuration data
    Node $AllNodes.where{$_.Role -eq "Web"}.NodeName
    {
        # Install the IIS role
        WindowsFeature IIS
        {
            Ensure          = "Present"
            Name            = "Web-Server"
        }

        # Install the ASP .NET 4.5 role
        WindowsFeature AspNet45
        {
            Ensure          = "Present"
            Name            = "Web-Asp-Net45"
        }

        # Stop an existing website (set up in Sample_Website_Default)
        Website DefaultSite
        {
            Ensure          = "Present"
            Name            = "Default Web Site"
            State           = "Stopped"
            PhysicalPath    = $Node.DefaultWebSitePath
            DependsOn       = "[WindowsFeature]IIS"
        }

        # Copy the website content
        File WebContent
        {
            Ensure          = "Present"
            SourcePath      = $Node.SourcePath
            DestinationPath = $Node.DestinationPath
            Recurse         = $true
            Type            = "Directory"
            DependsOn       = "[WindowsFeature]AspNet45"
        }

        # Create a new website
        Website BakeryWebSite
        {
            Ensure          = "Present"
            Name            = $Node.WebsiteName
            State           = "Started"
            PhysicalPath    = $Node.DestinationPath
            DependsOn       = "[File]WebContent"
        }
    }
}

# Content of configuration data file (e.g. ConfigurationData.psd1) could be:
# Hashtable to define the environmental data
@{
    # Node specific data
    AllNodes = @(
       # All the WebServer has following identical information
       @{
            NodeName           = "*"
            WebsiteName        = "FourthCoffee"
            SourcePath         = "C:\BakeryWebsite\"
            DestinationPath    = "C:\inetpub\FourthCoffee"
            DefaultWebSitePath = "C:\inetpub\wwwroot"
       },
       @{
            NodeName           = "WebServer1.fourthcoffee.com"
            Role               = "Web"
        },
       @{
            NodeName           = "WebServer2.fourthcoffee.com"
            Role               = "Web"
        }
    );
}
# Pass the configuration data to configuration as follows:
Sample_Website_FromConfigurationData -ConfigurationData ConfigurationData.psd1
```
