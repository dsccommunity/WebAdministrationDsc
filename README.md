[![Build status](https://ci.appveyor.com/api/projects/status/gnsxkjxht31ctan1/branch/master?svg=true)](https://ci.appveyor.com/project/PowerShell/xwebadministration/branch/master)

# xWebAdministration

The **xWebAdministration** module contains the **xIisModule**, **xWebAppPool**, **xWebsite**, **xWebApplication**, **xWebVirtualDirectory**, and **xWebConfigKeyValue** DSC resources for creating and configuring various IIS artifacts.

## Contributing
Please check out common DSC Resources [contributing guidelines](https://github.com/PowerShell/DscResource.Kit/blob/master/CONTRIBUTING.md).


## Resources

### xIISModule

* **Path**: The path to the module to be registered.
* **Name**: The logical name to register the module as in IIS.
* **RequestPath**: The allowed request paths, such as *.php
* **Verb**: An array of allowed verbs, such as get and post.
* **SiteName**: The name of the Site to register the module for.
If empty, the resource will register the module with all of IIS.
* **ModuleType**: The type of the module.
Currently, only FastCgiModule is supported.
* **Ensure**: Ensures that the module is **Present** or **Absent**.

### xWebAppPool

* **Name**: The desired name of the web application pool
* **Ensure**: Should the application pool be present or absent
* **State**: State of the application pool – started or stopped

### xWebsite

* **Name**: The desired name of the website.
* **PhysicalPath**: The path to the files that compose the website.
* **State**: State of the website: { Started | Stopped }
* **BindingInfo**: Website's binding information.
* **ApplicationPool**: The website’s application pool.
* **Ensure**: Ensures that the website is **Present** or **Absent**.

### xWebApplication

* **Website**: Name of website with which the web application is associated.
* **Name**: The desired name of the web application.
* **WebAppPool**:  Web application’s application pool.
* **PhysicalPath**: The path to the files that compose the web application.
* **Ensure**: Ensures that the web application is **Present** or **Absent**.

### xWebVirtualDirectory

* **Website**: Name of website with which virtual directory is associated
* **WebApplication**:  Web application name for the virtual directory
* **PhysicalPath**: The path to the files that compose the virtual directory
* **Name**: The name of the virtual directory
* **Ensure**: Ensures if the virtual directory is Present or Absent.
* **State**: State of the application pool: { **Started** | **Stopped** }

### xWebConfigKeyValue

* **WebsitePath**: Path to website location (IIS or WebAdministration format).
* **ConfigSection**: Section to update (only AppSettings supported as of now).
* **KeyValuePair**: Key value pair for AppSettings (ItemCollection format).


## Versions

### Unreleased
* Added Tests to xWebVirtualDirectory
* Modified xWebsite to allow Server Name Indication when specifiying SSL certificates.

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
    param(
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
            BindingInfo     = MSFT_xWebBindingInformation
                             {
                               Protocol              = "HTTPS"
                               Port                  = 8443
                               CertificateThumbprint ="71AD93562316F21F74606F1096B85D66289ED60F"
                               CertificateStoreName  = "WebHosting"
                             }
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