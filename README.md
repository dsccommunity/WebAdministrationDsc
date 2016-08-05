[![Build status](https://ci.appveyor.com/api/projects/status/gnsxkjxht31ctan1/branch/master?svg=true)](https://ci.appveyor.com/project/PowerShell/xwebadministration/branch/master)

# WebAdministrationDsc

The **WebAdministrationDsc** module contains the **IISLogging**, **Website**, and **SSLSettings** DSC resources for creating and configuring various IIS artifacts.

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/).
For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any additional questions or comments.

## Contributing
Please check out common DSC Resources [contributing guidelines](https://github.com/PowerShell/DscResource.Kit/blob/master/CONTRIBUTING.md).

## Resources

### IISLogging
**Note** This will set the logfile settings for **all** websites; for individual websites use the Log options under **Website**
* **LogPath**: The directory to be used for logfiles.
* **LogFlags**: The W3C logging fields: The values that are allowed for this property are: `Date`,`Time`,`ClientIP`,`UserName`,`SiteName`,`ComputerName`,`ServerIP`,`Method`,`UriStem`,`UriQuery`,`HttpStatus`,`Win32Status`,`BytesSent`,`BytesRecv`,`TimeTaken`,`ServerPort`,`UserAgent`,`Cookie`,`Referer`,`ProtocolVersion`,`Host`,`HttpSubStatus`
* **LogPeriod**: How often the log file should rollover. The values that are allowed for this property are: `Hourly`,`Daily`,`Weekly`,`Monthly`,`MaxSize`
* **LogTruncateSize**: How large the file should be before it is truncated. If this is set then LogPeriod will be ignored if passed in and set to MaxSize. The value must be a valid integer between `1048576 (1MB)` and `4294967295 (4GB)`.
* **LoglocalTimeRollover**: Use the localtime for file naming and rollover. The acceptable values for this property are: `$true`, `$false`
* **LogFormat**: Format of the Logfiles. **Note**Only W3C supports LogFlags. The acceptable values for this property are: `IIS`,`W3C`,`NCSA`

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

### SSLSettings
* **Name**: The Name of website in which to modify the SSL Settings
* **Bindings**: The SSL bindings to implement.
* **Ensure**: Ensures if the bindings are Present or Absent.

## Versions

### Unreleased
* **xWebAppPool** updates:
    * Replaced 3 calls to Invoke-Expression with a call to a new helper function - Get-Property

* **xWebsite** updates:
    * Bugfix for #131 The site name should be passed in as argument for Test-AuthenticationInfo
    * Improved **BindingInfo** validation: the **HostName** property is required for use with Server Name Indication (i.e., when the **SslFlags** property is set to `1` or `3`).
* Adding conditional logic to install the test helper module from the gallery if the user downloaded the module from the gallery.
* Added **xSSLSettings** integration tests
* Added fixes to **xSSLSettings**. Corrected spelling and formatting in base resource and tests. Added misc comments. Added ValidateSet to bindings param.

* Added **xIISLogging** resource which supports for the following options:
    * LogPath
    * LogFlags
    * LogPeriod
    * LogTruncateSize
    * LoglocalTimeRollover
    * LogFormat
* Added IIS Logging to **xWebsite** which support for the following options:
    * LogPath
    * LogFlags
    * LogPeriod
    * LogTruncateSize
    * LoglocalTimeRollover
    * LogFormat

* Added **xWebApplication** integration tests
* Added fixes to **xWebApplication**. Formatted resources to DSC StyleGuideLines, fixed logging statements, fixed incorrect Get-TargetResource param block, fixed Test-SslFlags validation, fixed unit test mocking of Test-SslFlags, added Ssl128 option to SslFlags
* Added unit tests for **xWebConfigKeyValue** and cleaned up style formatting.
* Added a stubs file for the WebAdministration functions so that the unit tests do not require a server to run

### 1.11.0.0

* **xWebAppPool** updates:
    * Bug fixes, error handling and input validation improvements.
    * The resource was updated to ensure a specific state only for the explicitly specified properties.
    * The following properties were added: **idleTimeoutAction**, **logEventOnProcessModel**, **setProfileEnvironment**.
    * The type of the following properties was changed to **Boolean**: **autoStart**, **enable32BitAppOnWin64**, **enableConfigurationOverride**,
        **passAnonymousToken**, **cpuSmpAffinitized**, **loadUserProfile**, **manualGroupMembership**, **pingingEnabled**, **setProfileEnvironment**,
        **orphanWorkerProcess**, **rapidFailProtection**, **disallowOverlappingRotation**, **disallowRotationOnConfigChange**.
    * Unit and integration tests updated.
* **xWebsite** updated to remove invisible Unicode "LEFT-TO-RIGHT MARK" character from the **CertificateThumbprint** property value.
* Added Preload and ServiceAutoStart functionality to **xWebsite** and **xWebApplication**
* Added AuthenticationInformation to **xWebsite** and **xWebApplication**
* Added SslFlags to **xWebApplication**

### 1.10.0.0

* Fixed script analyzer failures in examples
* **xWebsite**: Fixed an issue in BindingInfo validation that caused multiple bindings with the same port and protocol treated as invalid.
* Changed PhysicalPath in xWebsite to be optional
* Changed WebApplication in xWebVirtualDirectory to accept empty strings for referring to the top-level IIS site

### 1.9.0.0

* Added the following resources:
    * xSSLSettings
* Fixed an issue in xWebApplication where Set-TargetResource attempted to modify a folder instead of an application.
    * Added Tests to xWebApplication which will allow more changes if desired.
* Modified README.MD to clean up Code Formatting
* Modified all unit/integration tests to utilize template system.
* xWebAppPool is now has feature parity to cWebAppPool - should now support most changes.
* Added Unit tests to IISFeatureDelegation, general script clean up
* Refactored xIisHandle to load script variables once, added unit tests.
* xWebsite updated:
    * Added support for the following binding protocols: `msmq.formatname`, `net.msmq`, `net.pipe`, `net.tcp`.
    * Added support for setting the `EnabledProtocols` property.
    * Fixed an issue in bindings comparison which was causing bindings to be reassigned on every consistency check.
    * Fixed an issue where binding conflict was not properly detected and handled. Stopped websites will not be checked for conflicting bindings anymore.
    * The qualifier for the Protocol property of the MSFT_xWebBindingInformation CIM class was changed from Write to Required.

### 1.8.0.0

* Modified xWebsite to allow Server Name Indication when specifiying SSL certificates.
* Change Test Get-Website to match other function
* Removed xDscResourceDesigner tests
* Suppress extra verbose messages when -verbose is specified to Start-DscConfiguration
* Moved tests into child folders Unit and Integration
* Added PSDesiredStateConfiguration to Import-DscResource statement
* Fixed issue where Set-TargetResource was being run unexpectedly
* Added Tests to MSFT_xWebVirtualDirectory
* xWebsite tests updates
* xWebVirtualDirectory tests updates

### 1.7.0.0

* Added following resources:
    * xIisHandler
    * xIisFeatureDelegation
    * xIisMimeTypeMapping
    * xWebAppPoolDefaults
    * xWebSiteDefaults
* Modified xWebsite schema to make PhysicalPath required

### 1.6.0.0

* Fixed bug in xWebsite resource regarding incorrect name of personal certificate store.

### 1.5.0.0

* xWebsite:
    - Fix issue with Get-Website when there are multiple sites.
    - Fix issue when trying to add a new website when no websites currently exist.
    - Fix typos.

### 1.4.0.0

Changed Key property in MSFT_xWebConfigKeyValue to be a Key, instead of Required. This allows multiple keys to be configured within the same web.config file.

### 1.3.2.4

* Fixed the confusion with mismatched versions and xWebDeploy resources
* Removed BakeryWebsite.zip for legal reasons. Please read Examples\README.md for the workaround.

### 1.3.2.3

* Fixed variable name typo in MSFT_xIisModule.
* Added OutputType attribute to Test-TargetResource and Get-TargetResource in MSFT_xWebSite.

### 1.3.2.2

* Documentation only change.
Module manifest metadata changed to improve PowerShell Gallery experience.

### 1.3.2.1

* Documentation-only change, added metadata to module manifest

### 1.3.2

* Added **xIisModule**

### 1.2

* Added the **xWebAppPool**, **xWebApplication**, **xWebVirtualDirectory**, and **xWebConfigKeyValue**.

### 1.1.0.0

* Added support for HTTPS protocol
* Updated binding information to include Certificate information for HTTPS
* Removed protocol property. Protocol is included in binding information
* Bug fixes

### 1.0.0.0

* Initial release with the following resources
    - **xWebsite**


## Examples

### Registering PHP

When configuring an IIS Application that uses PHP, you first need to register the PHP CGI module with IIS.
The following **xPhp** configuration downloads and installs the prerequisites for PHP, downloads PHP, registers the PHP CGI module with IIS and sets the system environment variable that PHP needs to run.

Note: This example is intended to be used as a composite resource, so it does not use Configuration Data.
Please see the [Composite Configuration Blog](http://blogs.msdn.com/b/powershell/archive/2014/02/25/reusing-existing-configuration-scripts-in-powershell-desired-state-configuration.aspx) on how to use this configuration in another configuration.

```powershell
# Composite configuration to install the IIS pre-requisites for PHP
Configuration IisPreReqs_php
{
    param
    (
        [Parameter(Mandatory = $true)]
        [Validateset("Present","Absent")]
        [String]
        $Ensure
    )
    foreach ($Feature in @("Web-Server","Web-Mgmt-Tools","web-Default-Doc", `
            "Web-Dir-Browsing","Web-Http-Errors","Web-Static-Content",`
            "Web-Http-Logging","web-Stat-Compression","web-Filtering",`
            "web-CGI","web-ISAPI-Ext","web-ISAPI-Filter"))
    {
        WindowsFeature "$Feature$Number"
        {
            Ensure = $Ensure
            Name = $Feature
        }
    }
}

# Composite configuration to install PHP on IIS
configuration xPhp
{
    param
    (
        [Parameter(Mandatory = $true)]
        [switch] $installMySqlExt,
        [Parameter(Mandatory = $true)]
        [string] $PackageFolder,
        [Parameter(Mandatory = $true)]
        [string] $DownloadUri,
        [Parameter(Mandatory = $true)]
        [string] $Vc2012RedistDownloadUri,
        [Parameter(Mandatory = $true)]
        [String] $DestinationPath,
        [Parameter(Mandatory = $true)]
        [string] $ConfigurationPath
    )
        # Make sure the IIS Prerequisites for PHP are present
        IisPreReqs_php Iis
        {
            Ensure = "Present"
            # Removed because this dependency does not work in
            # Windows Server 2012 R2 and below
            # This should work in WMF v5 and above
            # DependsOn = "[File]PackagesFolder"
        }

        # Download and install Visual C Redist2012 from chocolatey.org
        Package vcRedist
        {
            Path = $Vc2012RedistDownloadUri
            ProductId = "{CF2BEA3C-26EA-32F8-AA9B-331F7E34BA97}"
            Name = "Microsoft Visual C++ 2012 x64 Minimum Runtime - 11.0.61030"
            Arguments = "/install /passive /norestart"
        }

        $phpZip = Join-Path $PackageFolder "php.zip"

        # Make sure the PHP archine is in the package folder
        xRemoteFile phpArchive
        {
            uri = $DownloadURI
            DestinationPath = $phpZip
        }

        # Make sure the content of the PHP archine are in the PHP path
        Archive php
        {
            Path = $phpZip
            Destination  = $DestinationPath
        }

        if ($installMySqlExt )
        {
            # Make sure the MySql extention for PHP is in the main PHP path
            File phpMySqlExt
            {
                SourcePath = "$($DestinationPath)\ext\php_mysql.dll"
                DestinationPath = "$($DestinationPath)\php_mysql.dll"
                Ensure = "Present"
                DependsOn = @("[Archive]PHP")
                MatchSource = $true
            }
        }

        # Make sure the php.ini is in the Php folder
        File PhpIni
        {
            SourcePath = $ConfigurationPath
            DestinationPath = "$($DestinationPath)\php.ini"
            DependsOn = @("[Archive]PHP")
            MatchSource = $true
        }

        # Make sure the php cgi module is registered with IIS
        xIisModule phpHandler
        {
            Name = "phpFastCgi"
            Path = "$($DestinationPath)\php-cgi.exe"
            RequestPath = "*.php"
            Verb = "*"
            Ensure = "Present"
            DependsOn = @("[Package]vcRedist","[File]PhpIni")
            # Removed because this dependency does not work in
            # Windows Server 2012 R2 and below
            # This should work in WMF v5 and above
            # "[IisPreReqs_php]Iis"
        }

        # Make sure the php binary folder is in the path
        Environment PathPhp
        {
            Name = "Path"
            Value = ";$($DestinationPath)"
            Ensure = "Present"
            Path = $true
            DependsOn = "[Archive]PHP"
        }
}

xPhp -PackageFolder "C:\packages" `
    -DownloadUri  -DownloadUri "http://windows.php.net/downloads/releases/php-5.5.13-Win32-VC11-x64.zip" `
    -Vc2012RedistDownloadUri "http://download.microsoft.com/download/1/6/B/16B06F60-3B20-4FF2-B699-5E9B7962F9AE/VSU_4/vcredist_x64.exe" `
    -DestinationPath "C:\php" `
    -ConfigurationPath "C:\MyPhp.ini" `
    -installMySqlExt $false
```

## Stopping the default website

When configuring a new IIS server, several references recommend removing or stopping the default website for security purposes.
This example sets up your IIS web server by installing IIS Windows Feature.
After that, it will stop the default website by setting `State = Stopped`.

```powershell
Configuration Sample_xWebsite_StopDefault
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
        # Stop the default website
        xWebsite DefaultSite
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
Fortunately, using DSC, adding another website is as simple as using the File and xWebsite resources to copy the website content and configure the website.

```powershell
Configuration Sample_xWebsite_NewWebsite
{
    param
    (
        # Target nodes to apply the configuration
        [string[]]$NodeName = 'localhost',
        # Name of the website to create
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [String]$WebSiteName,
        # Source Path for Website content
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [String]$SourcePath,
        # Destination path for Website content
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [String]$DestinationPath
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

        # Install the ASP .NET 4.5 role
        WindowsFeature AspNet45
        {
            Ensure          = "Present"
            Name            = "Web-Asp-Net45"
        }

        # Stop the default website
        xWebsite DefaultSite
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
        xWebsite NewWebsite
        {
            Ensure          = "Present"
            Name            = $WebSiteName
            State           = "Started"
            PhysicalPath    = $DestinationPath
            BindingInfo     = @(
                MSFT_xWebBindingInformation
                {
                    Protocol              = "HTTPS"
                    Port                  = 8443
                    CertificateThumbprint = "71AD93562316F21F74606F1096B85D66289ED60F"
                    CertificateStoreName  = "WebHosting"
                },
                MSFT_xWebBindingInformation
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
Configuration Sample_xWebsite_FromConfigurationData
{
    # Import the module that defines custom resources
    Import-DscResource -Module xWebAdministration

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

        # Stop an existing website (set up in Sample_xWebsite_Default)
        xWebsite DefaultSite
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
        xWebsite BakeryWebSite
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
Sample_xWebsite_FromConfigurationData -ConfigurationData ConfigurationData.psd1
```

### All resources (end-to-end scenario)

```powershell
# End to end sample for xWebAdministration

configuration Sample_EndToEndxWebAdministration
{

    Node $AllNodes.NodeName
    {
        # Create a Web Application Pool
        xWebAppPool NewWebAppPool
        {
            Name   = $Node.WebAppPoolName
            Ensure = "Present"
            State  = "Started"
        }

        #Create a New Website with Port
        xWebSite NewWebSite
        {
            Name   = $Node.WebSiteName
            Ensure = "Present"
            BindingInfo = MSFT_xWebBindingInformation
            {
                Port = $Node.Port
            }

            PhysicalPath = $Node.PhysicalPathWebSite
            State = "Started"
            DependsOn = @("[xWebAppPool]NewWebAppPool")
        }

        #Create a new Web Application
        xWebApplication NewWebApplication
        {
            Name = $Node.WebApplicationName
            Website = $Node.WebSiteName
            WebAppPool =  $Node.WebAppPoolName
            PhysicalPath = $Node.PhysicalPathWebApplication
            Ensure = "Present"
            DependsOn = @("[xWebSite]NewWebSite")
        }

        #Create a new virtual Directory
        xWebVirtualDirectory NewVirtualDir
        {
            Name = $Node.WebVirtualDirectoryName
            Website = $Node.WebSiteName
            WebApplication =  $Node.WebApplicationName
            PhysicalPath = $Node.PhysicalPathVirtualDir
            Ensure = "Present"
            DependsOn = @("[xWebApplication]NewWebApplication")
        }

        File CreateWebConfig
        {
             DestinationPath = $Node.PhysicalPathWebSite + "\web.config"
             Contents = "&amp;amp;amp;amp;lt;?xml version=`"1.0`" encoding=`"UTF-8`"?&amp;amp;amp;amp;gt;
                            &amp;amp;amp;amp;lt;configuration&amp;amp;amp;amp;gt;
                            &amp;amp;amp;amp;lt;/configuration&amp;amp;amp;amp;gt;"
                    Ensure = "Present"
             DependsOn = @("[xWebVirtualDirectory]NewVirtualDir")
        }

        xWebConfigKeyValue ModifyWebConfig
        {
            Ensure = "Present"
            ConfigSection = "AppSettings"
            KeyValuePair = @{key="key1";value="value1"}
            IsAttribute = $false
            WebsitePath = "IIS:\sites\" + $Node.WebsiteName
            DependsOn = @("[File]CreateWebConfig")
        }
    }
}

#You can place the below in another file to create multiple websites using the same configuration block.
$Config = @{
    AllNodes = @(
        @{
            NodeName = "localhost";
            WebAppPoolName = "TestAppPool";
            WebSiteName = "TestWebSite";
            PhysicalPathWebSite = "C:\web\webSite";
            WebApplicationName = "TestWebApplication";
            PhysicalPathWebApplication = "C:\web\webApplication";
            WebVirtualDirectoryName = "TestVirtualDir";
            PhysicalPathVirtualDir = "C:\web\virtualDir";
            Port = 100
        }
    )
}

Sample_EndToEndxWebAdministration -ConfigurationData $config
Start-DscConfiguration ./Sample_EndToEndxWebAdministration -wait -Verbose
```

```powershell
configuration Sample_IISServerDefaults
{
    param
    (
        # Target nodes to apply the configuration
        [string[]]$NodeName = 'localhost'
    )

    # Import the module that defines custom resources
    Import-DscResource -Module xWebAdministration, PSDesiredStateConfiguration

    Node $NodeName
    {
         xWebSiteDefaults SiteDefaults
         {
            ApplyTo = 'Machine'
            LogFormat = 'IIS'
            AllowSubDirConfig = 'true'
         }


         xWebAppPoolDefaults PoolDefaults
         {
            ApplyTo = 'Machine'
            ManagedRuntimeVersion = 'v4.0'
            IdentityType = 'ApplicationPoolIdentity'
         }
    }
}
```

### Create and configure an application pool

This example shows how to use the **xWebAppPool** DSC resource to create and configure an application pool.

```powershell
Configuration Sample_xWebAppPool
{
    param
    (
        [String[]]$NodeName = 'localhost'
    )

    Import-DscResource -ModuleName xWebAdministration

    Node $NodeName
    {
        xWebAppPool SampleAppPool
        {
            Name                           = 'SampleAppPool'
            Ensure                         = 'Present'
            State                          = 'Started'
            autoStart                      = $true
            CLRConfigFile                  = ''
            enable32BitAppOnWin64          = $false
            enableConfigurationOverride    = $true
            managedPipelineMode            = 'Integrated'
            managedRuntimeLoader           = 'webengine4.dll'
            managedRuntimeVersion          = 'v4.0'
            passAnonymousToken             = $true
            startMode                      = 'OnDemand'
            queueLength                    = 1000
            cpuAction                      = 'NoAction'
            cpuLimit                       = 90000
            cpuResetInterval               = (New-TimeSpan -Minutes 5).ToString()
            cpuSmpAffinitized              = $false
            cpuSmpProcessorAffinityMask    = 4294967295
            cpuSmpProcessorAffinityMask2   = 4294967295
            identityType                   = 'ApplicationPoolIdentity'
            idleTimeout                    = (New-TimeSpan -Minutes 20).ToString()
            idleTimeoutAction              = 'Terminate'
            loadUserProfile                = $true
            logEventOnProcessModel         = 'IdleTimeout'
            logonType                      = 'LogonBatch'
            manualGroupMembership          = $false
            maxProcesses                   = 1
            pingingEnabled                 = $true
            pingInterval                   = (New-TimeSpan -Seconds 30).ToString()
            pingResponseTime               = (New-TimeSpan -Seconds 90).ToString()
            setProfileEnvironment          = $false
            shutdownTimeLimit              = (New-TimeSpan -Seconds 90).ToString()
            startupTimeLimit               = (New-TimeSpan -Seconds 90).ToString()
            orphanActionExe                = ''
            orphanActionParams             = ''
            orphanWorkerProcess            = $false
            loadBalancerCapabilities       = 'HttpLevel'
            rapidFailProtection            = $true
            rapidFailProtectionInterval    = (New-TimeSpan -Minutes 5).ToString()
            rapidFailProtectionMaxCrashes  = 5
            autoShutdownExe                = ''
            autoShutdownParams             = ''
            disallowOverlappingRotation    = $false
            disallowRotationOnConfigChange = $false
            logEventOnRecycle              = 'Time,Requests,Schedule,Memory,IsapiUnhealthy,OnDemand,ConfigChange,PrivateMemory'
            restartMemoryLimit             = 0
            restartPrivateMemoryLimit      = 0
            restartRequestsLimit           = 0
            restartTimeLimit               = (New-TimeSpan -Minutes 1440).ToString()
            restartSchedule                = @('00:00:00', '08:00:00', '16:00:00')
        }
    }
}
```
