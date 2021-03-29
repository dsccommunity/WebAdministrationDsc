# xWebAdministration

[![Build Status](https://dev.azure.com/dsccommunity/xWebAdministration/_apis/build/status/dsccommunity.xWebAdministration?branchName=main)](https://dev.azure.com/dsccommunity/xWebAdministration/_build/latest?definitionId=7&branchName=main)
![Azure DevOps coverage (branch)](https://img.shields.io/azure-devops/coverage/dsccommunity/xWebAdministration/7/main)
[![Azure DevOps tests](https://img.shields.io/azure-devops/tests/dsccommunity/xWebAdministration/7/main)](https://dsccommunity.visualstudio.com/xWebAdministration/_test/analytics?definitionId=7&contextType=build)
[![PowerShell Gallery (with prereleases)](https://img.shields.io/powershellgallery/vpre/xWebAdministration?label=xWebAdministration%20Preview)](https://www.powershellgallery.com/packages/xWebAdministration/)
[![PowerShell Gallery](https://img.shields.io/powershellgallery/v/xWebAdministration?label=xWebAdministration)](https://www.powershellgallery.com/packages/xWebAdministration/)

## Code of Conduct

This project has adopted this [Code of Conduct](CODE_OF_CONDUCT.md).

## Releases

For each merge to the branch `main` a preview release will be
deployed to [PowerShell Gallery](https://www.powershellgallery.com/).
Periodically a release version tag will be pushed which will deploy a
full release to [PowerShell Gallery](https://www.powershellgallery.com/).

## Contributing

Please check out common DSC Community [contributing guidelines](https://dsccommunity.org/guidelines/contributing).

## Installation

### From GitHub source code

To manually install the module, download the source code from GitHub and unzip
the contents to the '$env:ProgramFiles\WindowsPowerShell\Modules' folder.

### From PowerShell Gallery

To install from the PowerShell gallery using PowerShellGet (in PowerShell 5.0)
run the following command:

```powershell
Find-Module -Name xWebAdministration | Install-Module
```

To confirm installation, run the below command and ensure you see the
DSC resources available:

```powershell
Get-DscResource -Module xWebAdministration
```

## Requirements

The minimum Windows Management Framework (PowerShell) version required is
4.0 or higher.

>Note: In the CI pipeline the resource are only tested on PowerShell 5.1,
>so PowerShell 4.0 support is best effort as this time.

## Examples

You can review the [Examples](/source/Examples) directory in the xWebAdministration
module for some general use scenarios for all of the resources that are in
the module.

## Resources

* [WebApplicationHandler](#webapplicationhandler)
* [xIisFeatureDelegation](#xiisfeaturedelegation)
* [xIISLogging](#xiislogging)
* [xIisHandler (DEPRECATED)](#xiishandler-deprecated)
* [xIisMimeTypeMapping](#xiismimetypemapping)
* [xIISModule](#xiismodule)
* [xSslSettings](#xsslsettings)
* [xWebApplication](#xwebapplication)
* [xWebAppPool](#xwebapppool)
* [xWebAppPoolDefaults](#xwebapppooldefaults)
* [xWebConfigKeyValue (DEPRECATED)](#xwebconfigkeyvalue-deprecated)
* [xWebConfigProperty](#xwebconfigproperty)
* [xWebConfigPropertyCollection](#xwebconfigpropertycollection)
* [xWebSite](#xwebsite)
* [xWebSiteDefaults](#xwebsitedefaults)
* [xWebVirtualDirectory](#xwebvirtualdirectory)

### WebApplicationHandler

* **[String] Ensure** _(Write)_: Indicates if the application handler exists. Set this property to `Absent` to ensure that the application handler does not exist. Default value is 'Present'.
{ *Present* | Absent }
* **[String] Name** _(Key)_: Specifies the name of the new request handler.
* **[String] Location** _(Write)_: Specifies The location of the configuration setting. Location tags are frequently used for configuration settings that must be set more precisely than per application or per virtual directory.
* **[String] PhysicalHandlerPath** _(Write)_: Specifies the physical path to the handler. This parameter applies to native modules only.
* **[String] Verb** _(Write)_: Specifies the HTTP verbs that are handled by the new handler.
* **[String] Modules** _(Write)_: Specifies the modules used for the handler.
* **[String[]] Path** _(Required)_: Specifies an IIS configuration path.
* **[String] PreCondition** _(Write)_: Specifies preconditions for the new handler.
* **[String] RequiredAccess** _(Write)_: Specifies the user rights that are required for the new handler. { None | Read | Write | Script | Execute }
* **[String] ScriptProcessor** _(Write)_: Specifies the script processor that runs for the module.
* **[String] Type** _(Write)_: Specifies the managed type of the new module. This parameter applies to managed modules only.
* **[String] ResourceType** _(Write)_: Specifies the resource type this handler runs. See [ResourceType](https://docs.microsoft.com/en-us/iis/configuration/system.webserver/handlers/add).
* **[Boolean] AllowPathInfo** _(Write)_: Specifies whether the handler processes full path information in a URI, such as contoso/marketing/imageGallery.aspx. If the value is true, the
handler processes the full path, contoso/marketing/imageGallery. If the value is false, the handler processes only the last section of the path, /imageGallery.
* **[UInt64] ResponseBufferLimit** _(Write)_: Specifies the maximum size, in bytes, of the response buffer for a request handler runs.

### xIisFeatureDelegation

This resource manages the IIS configuration section locking (overrideMode) to control what configuration can be set in web.config.

* **Filter**: Specifies the IIS configuration section to lock or unlock in this format: **/system.webserver/security/authentication/anonymousAuthentication**
* **OverrideMode**: Mode of that section { **Allow** | **Deny** }
* **Path**: Specifies the configuration path. This can be either an IIS configuration path in the format computer machine/webroot/apphost, or the IIS module path in this format IIS:\sites\Default Web Site. *WARNING: both path types can be used to manage the same feature delegation, however, there is no way to control if two resources in the configuration set the same feature delegation*.

### xIisHandler (DEPRECATED)

> Please use WebApplicationHandler resource instead. xIISHandler will be removed in future release

* **Name**: The name of the handler, for example **PageHandlerFactory-Integrated-4.0**
* **Ensure**: Ensures that the handler is **Present** or **Absent**. Defaults to **Present**.

### xIISLogging

**Note** This will set the logfile settings for **all** websites; for individual websites use the Log options under **xWebSite**

* **LogPath**: The directory to be used for logfiles.
* **LogFlags**: The W3C logging fields: The values that are allowed for this property are: `Date`,`Time`,`ClientIP`,`UserName`,`SiteName`,`ComputerName`,`ServerIP`,`Method`,`UriStem`,`UriQuery`,`HttpStatus`,`Win32Status`,`BytesSent`,`BytesRecv`,`TimeTaken`,`ServerPort`,`UserAgent`,`Cookie`,`Referer`,`ProtocolVersion`,`Host`,`HttpSubStatus`
* **LogPeriod**: How often the log file should rollover. The values that are allowed for this property are: `Hourly`,`Daily`,`Weekly`,`Monthly`,`MaxSize`
* **LogTruncateSize**: How large the file should be before it is truncated. If this is set then LogPeriod will be ignored if passed in and set to MaxSize. The value must be a valid integer between `1048576 (1MB)` and `4294967295 (4GB)`.
* **LoglocalTimeRollover**: Use the localtime for file naming and rollover. The acceptable values for this property are: `$true`, `$false`
* **LogFormat**: Format of the Logfiles. **Note**Only W3C supports LogFlags. The acceptable values for this property are: `IIS`,`W3C`,`NCSA`
* **LogTargetW3C**: Log Target of the W3C Logfiles. The acceptable values for this property are: `File`,`ETW`,`File,ETW`
* **LogCustomFields**: Custom logging field information the form of an array of embedded instances of the **MSFT_xLogCustomField** CIM class that implements the following properties:
  * **LogFieldName**: Field name to identify the custom field within the log file. Please note that the field name cannot contain spaces.
  * **SourceType**: You can select `RequestHeader`, `ResponseHeader`, or `ServerVariable` (note that enhanced logging cannot log a server variable with a name that contains lower-case characters - to include a server variable in the event log just make sure that its name consists of all upper-case characters).
  * **SourceName**: Name of the HTTP header or server variable (depending on the Source Type you selected) that contains a value that you want to log.

### xIisMimeTypeMapping

* **Extension**: The file extension to map such as **.html** or **.xml**
* **MimeType**: The MIME type to map that extension to such as **text/html**
* **Ensure**: Ensures that the MIME type mapping is **Present** or **Absent**.

### xIISModule

* **Path**: The path to the module to be registered.
* **Name**: The logical name to register the module as in IIS.
* **RequestPath**: The allowed request paths, such as *.php
* **Verb**: An array of allowed verbs, such as get and post.
* **SiteName**: The name of the Site to register the module for. If empty, the resource will register the module with all of IIS.
* **ModuleType**: The type of the module. Currently, only FastCgiModule is supported.
* **Ensure**: Ensures that the module is **Present** or **Absent**.

### xSslSettings

* **Name**: The Name of website in which to modify the SSL Settings
* **Bindings**: The SSL bindings to implement.
* **Ensure**: Ensures if the bindings are **Present** or **Absent**.

### xWebApplication

* **Website**: Name of website with which the web application is associated.
* **Name**: The desired name of the web application.
* **WebAppPool**:  Web application’s application pool.
* **PhysicalPath**: The path to the files that compose the web application.
* **Ensure**: Ensures that the web application is **Present** or **Absent**.
* **PreloadEnabled**: When set to `$true` this will allow WebSite to automatically start without a request
* **ServiceAutoStartEnabled**: When set to `$true` this will enable Autostart on a Website
* **ServiceAutoStartProvider**: Adds a AutostartProvider
* **ApplicationType**: Adds a AutostartProvider ApplicationType
* **AuthenticationInfo**: Web Application's authentication information in the form of an array of embedded instances of the **MSFT_xWebApplicationAuthenticationInformation** CIM class. **MSFT_xWebApplicationAuthenticationInformation** take the following properties:
  * **Anonymous**: The acceptable values for this property are: `$true`, `$false`
  * **Basic**: The acceptable values for this property are: `$true`, `$false`
  * **Digest**: The acceptable values for this property are: `$true`, `$false`
  * **Windows**: The acceptable values for this property are: `$true`, `$false`
* **SslFlags**: SslFlags for the application: The acceptable values for this property are: `''`, `Ssl`, `SslNegotiateCert`, `SslRequireCert`, `Ssl128`
* **EnabledProtocols**: EnabledProtocols for the application. The acceptable values for this property are: `http`, `https`, `net.tcp`, `net.msmq`, `net.pipe`

### xWebAppPool

* **Name** : Indicates the application pool name. The value must contain between `1` and `64` characters.
* **Ensure** : Indicates if the application pool exists. Set this property to `Absent` to ensure that the application pool does not exist.
    Setting it to `Present` (the default value) ensures that the application pool exists.
* **State** : Indicates the state of the application pool. The values that are allowed for this property are: `Started`, `Stopped`.
* **autoStart** : When set to `$true`, indicates to the World Wide Web Publishing Service (W3SVC) that the application pool should be automatically started when it is created or when IIS is started.
* **CLRConfigFile** : Indicates the .NET configuration file for the application pool.
* **enable32BitAppOnWin64** : When set to `$true`, enables a 32-bit application to run on a computer that runs a 64-bit version of Windows.
* **enableConfigurationOverride** : When set to `$true`, indicates that delegated settings in Web.config files will be processed for applications within this application pool.
    When set to `$false`, all settings in Web.config files will be ignored for this application pool.
* **managedPipelineMode** : Indicates the request-processing mode that is used to process requests for managed content. The values that are allowed for this property are: `Integrated`, `Classic`.
* **managedRuntimeLoader** : Indicates the managed loader to use for pre-loading the application pool.
* **managedRuntimeVersion** : Indicates the CLR version to be used by the application pool. The values that are allowed for this property are: `v4.0`, `v2.0`, and `""`.
* **passAnonymousToken** : When set to `$true`, the Windows Process Activation Service (WAS) creates and passes a token for the built-in IUSR anonymous user account to the Anonymous authentication module.
    The Anonymous authentication module uses the token to impersonate the built-in account. When this property is set to `$false`, the token will not be passed.
* **startMode** : Indicates the startup type for the application pool. The values that are allowed for this property are: `OnDemand`, `AlwaysRunning`.
* **queueLength** : Indicates the maximum number of requests that HTTP.sys will queue for the application pool. The value must be a valid integer between `10` and `65535`.
* **cpuAction** : Configures the action that IIS takes when a worker process exceeds its configured CPU limit.
    The values that are allowed for this property are: `NoAction`, `KillW3wp`, `Throttle`, and `ThrottleUnderLoad`.
* **cpuLimit** : Configures the maximum percentage of CPU time (in 1/1000ths of one percent) that the worker processes in the application pool are allowed to consume over a period of time as indicated by the **cpuResetInterval** property.
    The value must be a valid integer between `0` and `100000`.
* **cpuResetInterval** : Indicates the reset period (in minutes) for CPU monitoring and throttling limits on the application pool.
    The value must be a string representation of a TimeSpan value. The valid range (in minutes) is `0` to `1440`.
    Setting the value of this property to `00:00:00` disables CPU monitoring.
* **cpuSmpAffinitized** : Indicates whether a particular worker process assigned to the application pool should also be assigned to a given CPU.
* **cpuSmpProcessorAffinityMask** : Indicates the hexadecimal processor mask for multi-processor computers, which indicates to which CPU the worker processes in the application pool should be bound.
    Before this property takes effect, the **cpuSmpAffinitized** property must be set to `$true` for the application pool.
    The value must be a valid integer between `0` and `4294967295`.
* **cpuSmpProcessorAffinityMask2** : Indicates the high-order DWORD hexadecimal processor mask for 64-bit multi-processor computers, which indicates to which CPU the worker processes in the application pool should be bound.
    Before this property takes effect, the **cpuSmpAffinitized** property must be set to `$true` for the application pool.
    The value must be a valid integer between `0` and `4294967295`.
* **identityType** : Indicates the account identity under which the application pool runs.
    The values that are allowed for this property are: `ApplicationPoolIdentity`, `LocalService`, `LocalSystem`, `NetworkService`, and `SpecificUser`.
* **Credential** : Indicates the custom account crededentials. This property is only valid when the **identityType** property is set to `SpecificUser`.
* **idleTimeout** : Indicates the amount of time (in minutes) a worker process will remain idle before it shuts down.
    The value must be a string representation of a TimeSpan value and must be less than the **restartTimeLimit** property value. The valid range (in minutes) is `0` to `43200`.
* **idleTimeoutAction** : Indicates the action to perform when the idle timeout duration has been reached.
    The values that are allowed for this property are: `Terminate`, `Suspend`.
* **loadUserProfile** : Indicates whether IIS loads the user profile for the application pool identity.
* **logEventOnProcessModel** : Indicates that IIS should generate an event log entry for each occurrence of the specified process model events.
* **logonType** : Indicates the logon type for the process identity. The values that are allowed for this property are: `LogonBatch`, `LogonService`.
* **manualGroupMembership** : Indicates whether the IIS_IUSRS group Security Identifier (SID) is added to the worker process token.
* **maxProcesses** : Indicates the maximum number of worker processes that would be used for the application pool.
    The value must be a valid integer between `0` and `2147483647`.
* **pingingEnabled** : Indicates whether pinging (health monitoring) is enabled for the worker process(es) serving this application pool.
* **pingInterval** : Indicates the period of time (in seconds) between health monitoring pings sent to the worker process(es) serving this application pool.
    The value must be a string representation of a TimeSpan value. The valid range (in seconds) is `1` to `4294967`.
* **pingResponseTime** : Indicates the maximum time (in seconds) that a worker process is given to respond to a health monitoring ping.
    The value must be a string representation of a TimeSpan value. The valid range (in seconds) is `1` to `4294967`.
* **setProfileEnvironment** : Indicates the environment to be set based on the user profile for the new process.
* **shutdownTimeLimit** : Indicates the period of time (in seconds) a worker process is given to finish processing requests and shut down.
    The value must be a string representation of a TimeSpan value. The valid range (in seconds) is `1` to `4294967`.
* **startupTimeLimit** : Indicates the period of time (in seconds) a worker process is given to start up and initialize.
    The value must be a string representation of a TimeSpan value. The valid range (in seconds) is `1` to `4294967`.
* **orphanActionExe** : Indicates an executable to run when a worker process is orphaned.
* **orphanActionParams** : Indicates parameters for the executable that is specified in the **orphanActionExe** property.
* **orphanWorkerProcess** : Indicates whether to assign a worker process to an orphan state instead of terminating it when the application pool fails.
    If `$true`, an unresponsive worker process will be orphaned instead of terminated.
* **loadBalancerCapabilities** : Indicates the response behavior of a service when it is unavailable. The values that are allowed for this property are: `HttpLevel`, `TcpLevel`.
    If set to `HttpLevel` and the application pool is stopped, HTTP.sys will return HTTP 503 error. If set to `TcpLevel`, HTTP.sys will reset the connection.
* **rapidFailProtection** : Indicates whether rapid-fail protection is enabled.
    If `$true`, the application pool is shut down if there are a specified number of worker process crashes within a specified time period.
* **rapidFailProtectionInterval** : Indicates the time interval (in minutes) during which the specified number of worker process crashes must occur before the application pool is shut down by rapid-fail protection.
    The value must be a string representation of a TimeSpan value. The valid range (in minutes) is `1` to `144000`.
* **rapidFailProtectionMaxCrashes** : Indicates the maximum number of worker process crashes permitted before the application pool is shut down by rapid-fail protection.
    The value must be a valid integer between `0` and `2147483647`.
* **autoShutdownExe** : Indicates an executable to run when the application pool is shut down by rapid-fail protection.
* **autoShutdownParams** : Indicates parameters for the executable that is specified in the **autoShutdownExe** property.
* **disallowOverlappingRotation** : Indicates whether the W3SVC service should start another worker process to replace the existing worker process while that process is shutting down.
    If `$true`, the application pool recycle will happen such that the existing worker process exits before another worker process is created.
* **disallowRotationOnConfigChange** : Indicates whether the W3SVC service should rotate worker processes in the application pool when the configuration has changed.
    If `$true`, the application pool will not recycle when its configuration is changed.
* **logEventOnRecycle** : Indicates that IIS should generate an event log entry for each occurrence of the specified recycling events.
* **restartMemoryLimit** : Indicates the maximum amount of virtual memory (in KB) a worker process can consume before causing the application pool to recycle.
    The value must be a valid integer between `0` and `4294967295`.
    A value of `0` means there is no limit.
* **restartPrivateMemoryLimit** : Indicates the maximum amount of private memory (in KB) a worker process can consume before causing the application pool to recycle.
    The value must be a valid integer between `0` and `4294967295`.
    A value of `0` means there is no limit.
* **restartRequestsLimit** : Indicates the maximum number of requests the application pool can process before it is recycled.
    The value must be a valid integer between `0` and `4294967295`.
    A value of `0` means the application pool can process an unlimited number of requests.
* **restartTimeLimit** : Indicates the period of time (in minutes) after which the application pool will recycle.
    The value must be a string representation of a TimeSpan value. The valid range (in minutes) is `0` to `432000`.
    A value of `00:00:00` means the application pool does not recycle on a regular interval.
* **restartSchedule** : Indicates a set of specific local times, in 24 hour format, when the application pool is recycled.
    The value must be an array of string representations of TimeSpan values.
    TimeSpan values must be between `00:00:00` and `23:59:59` seconds inclusive, with a granularity of 60 seconds.
    Setting the value of this property to `""` disables the schedule.

### xWebAppPoolDefaults

* **IsSingleInstance**: Specifies the resource is a single instance, the value must be **Yes**
* **ManagedRuntimeVersion**: CLR Version {v2.0|v4.0|} empty string for unmanaged.
* **ApplicationPoolIdentity**: {ApplicationPoolIdentity | LocalService | LocalSystem | NetworkService}

### xWebConfigKeyValue (DEPRECATED)

>NOTE: The **xWebConfigKeyValue** resource is deprecated and has been replaced by the **xWebConfigProperty** and **xWebConfigPropertyCollection** resources.
>It may be removed in a future release.

* **WebsitePath**: Path to website location (IIS or WebAdministration format).
* **ConfigSection**: Section to update (only AppSettings supported as of now).
* **Key**: Key for AppSettings.
* **Value**: Value for AppSettings.
* **Ensure**: Ensures if the appSetting is **Present** or **Absent**.
* **IsAttribute**: If the given key value pair is for attribute, default is element.

### xWebConfigProperty

Ensures the value of an identified property in the web.config file.

* **WebsitePath**: Path to website location (IIS or WebAdministration format).
* **Filter**: Filter used to locate property to update.
* **PropertyName**: Name of the property to update.
* **Value**: Value of the property to update.
* **Ensure**: Indicates if the property and value should be present or absent. Defaults to 'Present'. { *Present* | Absent }

### xWebConfigPropertyCollection

Ensures the value of an identified property collection item's property in the web.config file. Builds upon the **xWebConfigKeyValue** resource to support all web.config elements that contain collections of child items.

* **WebsitePath**: Path to website location (IIS or WebAdministration format).
* **Filter**: Filter used to locate property collection to update.
* **CollectionName**: Name of the property collection to update.
* **ItemName**: Name of the property collection item to update.
* **ItemKeyName**: Name of the key of the property collection item to update.
* **ItemKeyValue**: Value of the key of the property collection item to update.
* **ItemPropertyName**: Name of the property of the property collection item to update.
* **ItemPropertyValue**: Value of the property of the property collection item to update.
* **Ensure**: Indicates if the property and value should be present or absent. Defaults to 'Present'. { *Present* | Absent }

### xWebSite

* **Name** : The desired name of the website.
* **SiteId** : Optional. The desired IIS site Id for the website.
* **PhysicalPath**: The path to the files that compose the website.
* **State**: The state of the website: { Started | Stopped }
* **BindingInfo**: Website's binding information in the form of an array of embedded instances of the **MSFT_xWebBindingInformation** CIM class that implements the following properties:
  * **Protocol**: The protocol of the binding. This property is required. The acceptable values for this property are: `http`, `https`, `msmq.formatname`, `net.msmq`, `net.pipe`, `net.tcp`.
  * **BindingInformation**: The binding information in the form a colon-delimited string that includes the IP address, port, and host name of the binding. This property is ignored for `http` and `https` bindings if at least one of the following properties is specified: **IPAddress**, **Port**, **HostName**.
  * **IPAddress**: The IP address of the binding. This property is only applicable for `http` and `https` bindings. The default value is `*`.
  * **Port**: The port of the binding. The value must be a positive integer between `1` and `65535`. This property is only applicable for `http` (the default value is `80`) and `https` (the default value is `443`) bindings.
  * **HostName**: The host name of the binding. This property is only applicable for `http` and `https` bindings.
  * **CertificateThumbprint**: The thumbprint of the certificate. This property is only applicable for `https` bindings.
  * **CertificateSubject**: The subject of the certificate if the thumbprint isn't known. This property is only applicable for `https` bindings.
  * **CertificateStoreName**: The name of the certificate store where the certificate is located. This property is only applicable for `https` bindings. The acceptable values for this property are: `My`, `WebHosting`. The default value is `My`.
  * **SslFlags**: The type of binding used for Secure Sockets Layer (SSL) certificates. This property is supported in IIS 8.0 or later, and is only applicable for `https` bindings. The acceptable values for this property are:
    * **0**: The default value. The secure connection be made using an IP/Port combination. Only one certificate can be bound to a combination of IP address and the port.
    * **1**: The secure connection be made using the port number and the host name obtained by using Server Name Indication (SNI). It allows multiple secure websites with different certificates to use the same IP address.
    * **2**: The secure connection be made using the Centralized Certificate Store without requiring a Server Name Indication.
    * **3**: The secure connection be made using the Centralized Certificate Store while requiring Server Name Indication.
* **ApplicationPool**: The name of the website’s application pool.
* **DefaultPage**: One or more names of files that will be set as Default Documents for this website.
* **EnabledProtocols**: The protocols that are enabled for the website.
* **ServerAutoStart**: When set to `$true` this will enable Autostart on a Website
* **Ensure**: Ensures that the website is **Present** or **Absent**. Defaults to **Present**.
* **PreloadEnabled**: When set to `$true` this will allow WebSite to automatically start without a request
* **ServiceAutoStartEnabled**: When set to `$true` this will enable application Autostart (application initalization without an initial request) on a Website
* **ServiceAutoStartProvider**: Adds a AutostartProvider
* **ApplicationType**: Adds a AutostartProvider ApplicationType
* **AuthenticationInfo**: Website's authentication information in the form of an embedded instance of the **MSFT_xWebAuthenticationInformation** CIM class.
**MSFT_xWebAuthenticationInformation** takes the following properties:
  * **Anonymous**: The acceptable values for this property are: `$true`, `$false`
  * **Basic**: The acceptable values for this property are: `$true`, `$false`
  * **Digest**: The acceptable values for this property are: `$true`, `$false`
  * **Windows**: The acceptable values for this property are: `$true`, `$false`
* **LogPath**: The directory to be used for logfiles.
* **LogFlags**: The W3C logging fields: The values that are allowed for this property are: `Date`,`Time`,`ClientIP`,`UserName`,`SiteName`,`ComputerName`,`ServerIP`,`Method`,`UriStem`,`UriQuery`,`HttpStatus`,`Win32Status`,`BytesSent`,`BytesRecv`,`TimeTaken`,`ServerPort`,`UserAgent`,`Cookie`,`Referer`,`ProtocolVersion`,`Host`,`HttpSubStatus`
* **LogPeriod**: How often the log file should rollover. The values that are allowed for this property are: `Hourly`,`Daily`,`Weekly`,`Monthly`,`MaxSize`
* **LogTargetW3C**: Log Target of the W3C Logfiles. The acceptable values for this property are: `File`,`ETW`,`File,ETW`
* **LogTruncateSize**: How large the file should be before it is truncated. If this is set then LogPeriod will be ignored if passed in and set to MaxSize. The value must be a valid integer between `1048576 (1MB)` and `4294967295 (4GB)`.
* **LoglocalTimeRollover**: Use the localtime for file naming and rollover. The acceptable values for this property are: `$true`, `$false`
* **LogFormat**: Format of the Logfiles. **Note**Only W3C supports LogFlags. The acceptable values for this property are: `IIS`,`W3C`,`NCSA`
* **LogCustomFields**: Custom logging field information the form of an array of embedded instances of the **MSFT_xLogCustomFieldInformation** CIM class that implements the following properties:
  * **LogFieldName**: Field name to identify the custom field within the log file. Please note that the field name cannot contain spaces.
  * **SourceType**: The acceptable values for this property are: `RequestHeader`, `ResponseHeader`, or `ServerVariable` (note that enhanced logging cannot log a server variable with a name that contains lower-case characters - to include a server variable in the event log just make sure that its name consists of all upper-case characters).
  * **SourceName**: Name of the HTTP header or server variable (depending on the Source Type you selected) that contains a value that you want to log.

### xWebSiteDefaults

* **Key**: Required Key value, always **Machine**
* **LogFormat**: Format of the Logfiles. **Note**Only W3C supports LogFlags. The acceptable values for this property are: `IIS`,`W3C`,`NCSA`,`Custom`.
* **LogDirectory**: Directory for IIS logs.
* **TraceLogDirectory**: Directory for FREB (Failed Request Tracing) logs.
* **DefaultApplicationPool**: Name of the default application pool used by websites.
* **AllowSubDirConfig**: Should IIS look for config files in subdirectories, either **true** or **false**

### xWebVirtualDirectory

* **Website**: Name of website with which virtual directory is associated
* **WebApplication**:  The name of the containing web application or an empty string for the containing website
* **PhysicalPath**: The path to the files that compose the virtual directory
* **Name**: The name of the virtual directory
* **Ensure**: Ensures if the virtual directory is **Present** or **Absent**.

### xWebConfigKeyValue (DEPRECATED)

>NOTE: The **xWebConfigKeyValue** resource is deprecated and has been replaced by the **xWebConfigProperty** and **xWebConfigPropertyCollection** resources.
>It may be removed in a future release.

* **WebsitePath**: Path to website location (IIS or WebAdministration format).
* **ConfigSection**: Section to update (only AppSettings supported as of now).
* **Key**: Key for AppSettings.
* **Value**: Value for AppSettings.
* **Ensure**: Ensures if the appSetting is **Present** or **Absent**.
* **IsAttribute**: If the given key value pair is for attribute, default is element.

### xWebConfigProperty

Ensures the value of an identified property in the web.config file.

* **WebsitePath**: Path to website location (IIS or WebAdministration format).
* **Filter**: Filter used to locate property to update.
* **PropertyName**: Name of the property to update.
* **Value**: Value of the property to update.
* **Ensure**: Indicates if the property and value should be present or absent. Defaults to 'Present'. { *Present* | Absent }

### xWebConfigPropertyCollection

Ensures the value of an identified property collection item's property in the web.config file. Builds upon the **xWebConfigKeyValue** resource to support all web.config elements that contain collections of child items.

* **WebsitePath**: Path to website location (IIS or WebAdministration format).
* **Filter**: Filter used to locate property collection to update.
* **CollectionName**: Name of the property collection to update.
* **ItemName**: Name of the property collection item to update.
* **ItemKeyName**: Name of the key of the property collection item to update.
* **ItemKeyValue**: Value of the key of the property collection item to update.
* **ItemPropertyName**: Name of the property of the property collection item to update.
* **ItemPropertyValue**: Value of the property of the property collection item to update.
* **Ensure**: Indicates if the property and value should be present or absent. Defaults to 'Present'. { *Present* | Absent }

### xSslSettings

* **Name**: The Name of website in which to modify the SSL Settings
* **Bindings**: The SSL bindings to implement.
* **Ensure**: Ensures if the bindings are **Present** or **Absent**.

### xIisFeatureDelegation

This resource manages the IIS configuration section locking (overrideMode) to control what configuration can be set in web.config.

* **Filter**: Specifies the IIS configuration section to lock or unlock in this format: **/system.webserver/security/authentication/anonymousAuthentication**
* **OverrideMode**: Mode of that section { **Allow** | **Deny** }
* **Path**: Specifies the configuration path. This can be either an IIS configuration path in the format computer machine/webroot/apphost, or the IIS module path in this format IIS:\sites\Default Web Site. *WARNING: both path types can be used to manage the same feature delegation, however, there is no way to control if two resources in the configuration set the same feature delegation*.

### xIisMimeTypeMapping

* **Extension**: The file extension to map such as **.html** or **.xml**
* **MimeType**: The MIME type to map that extension to such as **text/html**
* **Ensure**: Ensures that the MIME type mapping is **Present** or **Absent**.

### xWebAppPoolDefaults

* **IsSingleInstance**: Specifies the resource is a single instance, the value must be **Yes**
* **ManagedRuntimeVersion**: CLR Version {v2.0|v4.0|} empty string for unmanaged.
* **ApplicationPoolIdentity**: {ApplicationPoolIdentity | LocalService | LocalSystem | NetworkService}

### xWebSiteDefaults

* **Key**: Required Key value, always **Machine**
* **LogFormat**: Format of the Logfiles. **Note**Only W3C supports LogFlags. The acceptable values for this property are: `IIS`,`W3C`,`NCSA`,`Custom`.
* **LogDirectory**: Directory for IIS logs.
* **TraceLogDirectory**: Directory for FREB (Failed Request Tracing) logs.
* **DefaultApplicationPool**: Name of the default application pool used by websites.
* **AllowSubDirConfig**: Should IIS look for config files in subdirectories, either **true** or **false**

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
