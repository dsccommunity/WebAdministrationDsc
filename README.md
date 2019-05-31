# xWebAdministration

The **xWebAdministration** module contains the **xIISModule**, **xIISLogging**, **xWebAppPool**, **xWebsite**, **xWebApplication**, **xSSLSettings**, **xWebConfigKeyValue**, **xWebConfigProperty**, **xWebConfigPropertyCollection**, **WebApplicationHandler** and **WebVirtualDirectory** DSC resources for creating and configuring various IIS artifacts.

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/).
For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any additional questions or comments.

## Branches

### master

[![Build status](https://ci.appveyor.com/api/projects/status/gnsxkjxht31ctan1/branch/master?svg=true)](https://ci.appveyor.com/project/PowerShell/xWebAdministration/branch/master)
[![codecov](https://codecov.io/gh/PowerShell/xWebAdministration/branch/master/graph/badge.svg)](https://codecov.io/gh/PowerShell/xWebAdministration/branch/master)

This is the branch containing the latest release -
no contributions should be made directly to this branch.

### dev

[![Build status](https://ci.appveyor.com/api/projects/status/gnsxkjxht31ctan1/branch/dev?svg=true)](https://ci.appveyor.com/project/PowerShell/xWebAdministration/branch/dev)
[![codecov](https://codecov.io/gh/PowerShell/xWebAdministration/branch/dev/graph/badge.svg)](https://codecov.io/gh/PowerShell/xWebAdministration/branch/dev)

This is the development branch
to which contributions should be proposed by contributors as pull requests.
This development branch will periodically be merged to the master branch,
and be released to [PowerShell Gallery](https://www.powershellgallery.com/).

## Contributing

Please check out common DSC Resources [contributing guidelines](https://github.com/PowerShell/DscResource.Kit/blob/master/CONTRIBUTING.md).

## Resources

### xIisHandler (DEPRECATED)

> Please use WebApplicationHandler resource instead. xIISHandler will be removed in future release

* **Name**: The name of the handler, for example **PageHandlerFactory-Integrated-4.0**
* **Ensure**: Ensures that the handler is **Present** or **Absent**.

### xIISModule

* **Path**: The path to the module to be registered.
* **Name**: The logical name to register the module as in IIS.
* **RequestPath**: The allowed request paths, such as *.php
* **Verb**: An array of allowed verbs, such as get and post.
* **SiteName**: The name of the Site to register the module for. If empty, the resource will register the module with all of IIS.
* **ModuleType**: The type of the module. Currently, only FastCgiModule is supported.
* **Ensure**: Ensures that the module is **Present** or **Absent**.

### xIISLogging

**Note** This will set the logfile settings for **all** websites; for individual websites use the Log options under **xWebsite**

* **LogPath**: The directory to be used for logfiles.
* **LogFlags**: The W3C logging fields: The values that are allowed for this property are: `Date`,`Time`,`ClientIP`,`UserName`,`SiteName`,`ComputerName`,`ServerIP`,`Method`,`UriStem`,`UriQuery`,`HttpStatus`,`Win32Status`,`BytesSent`,`BytesRecv`,`TimeTaken`,`ServerPort`,`UserAgent`,`Cookie`,`Referer`,`ProtocolVersion`,`Host`,`HttpSubStatus`
* **LogPeriod**: How often the log file should rollover. The values that are allowed for this property are: `Hourly`,`Daily`,`Weekly`,`Monthly`,`MaxSize`
* **LogTruncateSize**: How large the file should be before it is truncated. If this is set then LogPeriod will be ignored if passed in and set to MaxSize. The value must be a valid integer between `1048576 (1MB)` and `4294967295 (4GB)`.
* **LoglocalTimeRollover**: Use the localtime for file naming and rollover. The acceptable values for this property are: `$true`, `$false`
* **LogFormat**: Format of the Logfiles. **Note**Only W3C supports LogFlags. The acceptable values for this property are: `IIS`,`W3C`,`NCSA`
* **LogTargetW3C**: Log Target of the W3C Logfiles. The acceptable values for this property are: `File`,`ETW`,`File,ETW`
* **LogCustomFields**: Custom logging field information the form of an array of embedded instances of the **MSFT_xLogCustomField** CIM class that implements the following properties:
  * **LogFieldName**: Field name to identify the custom field within the log file. Please note that the field name cannot contain spaces.
  * **SourceName**: You can select `RequestHeader`, `ResponseHeader`, or `ServerVariable` (note that enhanced logging cannot log a server variable with a name that contains lower-case characters - to include a server variable in the event log just make sure that its name consists of all upper-case characters).
  * **SourceType**: Name of the HTTP header or server variable (depending on the Source Type you selected) that contains a value that you want to log.

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

### xWebsite

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
* **ApplicationPool**: The website’s application pool.
* **EnabledProtocols**: The protocols that are enabled for the website.
* **Ensure**: Ensures that the website is **Present** or **Absent**.
* **PreloadEnabled**: When set to `$true` this will allow WebSite to automatically start without a request
* **ServiceAutoStartEnabled**: When set to `$true` this will enable Autostart on a Website
* **ServiceAutoStartProvider**: Adds a AutostartProvider
* **ApplicationType**: Adds a AutostartProvider ApplicationType
* **AuthenticationInfo**: Website's authentication information in the form of an embedded instance of the **MSFT_xWebAuthenticationInformation** CIM class. **MSFT_xWebAuthenticationInformation** takes the following properties:
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
  * **SourceName**: You can select `RequestHeader`, `ResponseHeader`, or `ServerVariable` (note that enhanced logging cannot log a server variable with a name that contains lower-case characters - to include a server variable in the event log just make sure that its name consists of all upper-case characters).
  * **SourceType**: Name of the HTTP header or server variable (depending on the Source Type you selected) that contains a value that you want to log.

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
* **AuthenticationInformation**: Web Application's authentication information in the form of an array of embedded instances of the **MSFT_xWebApplicationAuthenticationInformation** CIM class. **MSFT_xWebApplicationAuthenticationInformation** take the following properties:
  * **Anonymous**: The acceptable values for this property are: `$true`, `$false`
  * **Basic**: The acceptable values for this property are: `$true`, `$false`
  * **Digest**: The acceptable values for this property are: `$true`, `$false`
  * **Windows**: The acceptable values for this property are: `$true`, `$false`
* **SslFlags**: SslFlags for the application: The acceptable values for this property are: `''`, `Ssl`, `SslNegotiateCert`, `SslRequireCert`, `Ssl128`
* **EnabledProtocols**: EnabledProtocols for the application. The acceptable values for this property are: `http`, `https`, `net.tcp`, `net.msmq`, `net.pipe`

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

### WebVirtualDirectory

* **Site**: Name of website with which virtual directory is associated.
* **Application**:  The name of the containing web application or an empty string for the containing website.
* **PhysicalPath**: The path to the files that compose the virtual directory.
* **Name**: The name of the virtual directory.
* **Ensure**: Ensures if the virtual directory is **Present** or **Absent**.
* **PhysicalPathAccessAccount**: Specific username used for access to physical path. *Note* In case of using SMB as a physical path and if target server doesn't share identity database with device/server hosting the share, local user account must be created with the same username/password used for the access, section 'More Information' [support.microsoft.com](https://support.microsoft.com/en-us/help/247099/access-denied-when-connecting-to-a-ftp-directory-that-uses-a-unc-path)
* **PhysicalPathAccessPass**: Specifies password used for access to physical path.

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

### xSSLSettings

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

* **ApplyTo**: Required Key value, always **Machine**
* **ManagedRuntimeVersion**: CLR Version {v2.0|v4.0|} empty string for unmanaged.
* **ApplicationPoolIdentity**: {ApplicationPoolIdentity | LocalService | LocalSystem | NetworkService}

### xWebSiteDefaults

* **Key**: Required Key value, always **Machine**
* **LogFormat**: Format of the Logfiles. **Note**Only W3C supports LogFlags. The acceptable values for this property are: `IIS`,`W3C`,`NCSA`,`Custom`.
* **LogDirectory**: Directory for IIS logs.
* **TraceLogDirectory**: Directory for FREB (Failed Request Tracing) logs.
* **DefaultApplicationPool**: Name of the default application pool used by websites.
* **AllowSubDirConfig**: Should IIS look for config files in subdirectories, either **true** or **false**

## Versions

### Unreleased

* BREAKING CHANGE: Resource **xWebVirtualDirectory** renamed to **WebVirtualDirectory**.
  * Parameter **Website** renamed to **Site** to comply with other resources and PowerShell command.
  * Parameter **WebApplication** renamed to **Application** to comply with other resources and PowerShell command.
  * New parameters added: **PhysicalPathAccessAccount** and **PhysicalPathAccessPass** which define access credential to physical path.
  * Parameter **PhysicalPath** no longer required for Ensure = 'Absent' case.
  * UNC path can be used as a PhysicalPath value [#94](https://github.com/PowerShell/xWebAdministration/issues/94)
  * Removal command changed to `Remove-Item` to hide the confirmation errors [#366](https://github.com/PowerShell/xWebAdministration/issues/366)
  * Examples added to include different scenarios.

### 2.6.0.0

* Changed order of classes in schema.mof files to workaround [#423](https://github.com/PowerShell/xWebAdministration/issues/423)
* Fix subject comparison multiple entries for helper function `Find-Certificate` that could not find the test
  helper function `Install-NewSelfSignedCertificateExScript`.
* Updated unit test for helper function `Find-Certificate` to check for multiple
  subject names in different orders.

### 2.5.0.0

* Added SiteId to xWebSite to address [396]
* xWebSite: Full path is used to get list of default documents
* xIISLogging: Added support for LogTargetW3C
* xWebsite: Added support for LogTargetW3C

### 2.4.0.0

* Explicitly removed extra hidden files from release package

### 2.3.0.0

* Update appveyor.yml to use the default template.
* Added default template file .gitattributes, and added default settings for
  Visual Studio Code.
* Line endings was fixed in files that was committed with wrong line ending.

### 2.2.0.0

* Added new parameter 'Location' to **WebApplcationHandler** extending functionality to address [392]
* Changes to xWebAdministration
  * Update section header for WebApplicationHandler in README.
  * Fix tests for helper function `Get-LocalizedData` in Helper.Tests.ps1
    that referenced the wrong path.
* Remove duplication in MSFT_xWebsite.psm1. [Krzysztof Morcinek (@kmorcinek)](https://github.com/kmorcinek)
* Updates **xIISMimeTypeMapping** to add MIME type mapping for nested paths

### 2.1.0.0

* Added new resources **xWebConfigProperty** and **xWebConfigPropertyCollection** extending functionality provided by **xWebConfigKeyValue**, addresses #249.
* Fixed Get-DscConfiguration throw in xWebSite; addresses [#372](https://github.com/PowerShell/xWebAdministration/issues/372). [Reggie Gibson (@regedit32)](https://github.com/regedit32)
* Added **WebApplicationHandler** resource for creating and modifying IIS Web Handlers. Fixes #337
* Added **WebApplicationHandler** integration tests
* Added **WebApplicationHandler** unit tests
* Deprecated xIISHandler resource. This resource will be removed in future release

### 2.0.0.0

* Changes to xWebAdministration
  * Moved file Codecov.yml that was added to the wrong path in previous release.
* Updated **xWebSite** to include ability to manage custom logging fields.
  [Reggie Gibson (@regedit32)](https://github.com/regedit32)
* Updated **xIISLogging** to include ability to manage custom logging fields
  ([issue #267](https://github.com/PowerShell/xWebAdministration/issues/267)).
  [@ldillonel](https://github.com/ldillonel)
* BREAKING CHANGE: Updated **xIisFeatureDelegation** to be able to manage any
  configuration section.
  [Reggie Gibson (@regedit32)](https://github.com/regedit32)

### 1.20.0.0

* Fix Get-DscConfiguration failure with xWebApplication and xWebSite resources
  (issue #302 and issue #314).
* Add Codecov support.
* Added .vscode\settings.json so that code can be easily formatted in VSCode
  closer according to the style guideline.
* Updated README.md with a branches section, and added Codecov badges.
* Fix unit test for helper function `Find-Certificate` that could not find the test
  helper function `Install-NewSelfSignedCertificateExScript`.
* Fix unit tests for xWebSite that failed because `Get-Command` and 'Stop-WebStie`
  wasn't properly mocked.

### 1.19.0.0

* **xWebAppPoolDefaults** now returns values. Fixes #311.
* Added unit tests for **xWebAppPoolDefaults**. Fixes #183.

### 1.18.0.0

* Added sample for **xWebVirtualDirectory** for creating a new virtual directory. Bugfix for #195.
* Added integration tests for **xWebVirtualDirectory**. Fixes #188.
* xWebsite:
  * Fixed bugs when setting log properties, fixes #299.

### 1.17.0.0

* Added removal of self signed certificate to the integration tests of **xWebsite**, fixes #276.
* Added EnabledProtocols to **xWebApplication**.
* Changed SSLFlags for **xWebApplication** to comma seperate multiple SSL flags, fixes #232.

### 1.16.0.0

* Log directory configuration on **xWebsite** used the logPath attribute instead of the directory attribute. Bugfix for #256.
* Changed **xWebConfigKeyValue** to use the key for changing existing values. Bugfix for #107.
* Changed validation of LogTruncateSize for **xIisLogging** and **xWebsite** to UInt64 validation.
* Make PhysicalPath optional in **xWebsite**. Bugfix for #264.

### 1.15.0.0

* Corrected name of AuthenticationInfo parameter in Readme.md.
* Added sample for **xWebApplication** for adding new web application.
* Corrected description for AuthenticationInfo for xWebApplication and xWebsite.
* Added samples for **xWebConfigKeyValue** for adding and removing appSettings.
* Added sample for **xWebAppPoolDefaults** for configuring the application pool defaults.
* Added sample for **xWebSiteDefaults** for configuring the site defaults.
* Updated Readme.md for **xWebConfigKeyValue**. Added **xIISHandler** and **xWebSiteDefaults**.

### 1.14.0.0

* xWebApplication:
  * Fixed bug when setting PhysicalPath and WebAppPool
  * Changes to the application pool property are now applied correctly

### 1.13.0.0

* Added unit tests for **xWebConfigKeyValue** and cleaned up style formatting.
* Added a stubs file for the WebAdministration functions so that the unit tests do not require a server to run
* Converted appveyor.yml to install Pester from PSGallery instead of from Chocolatey.
* Updated appveyor.yml to use the default image.

### 1.12.0.0

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

* **xWebApplication** updates:
  * xWebApplication integration tests updated
  * Added fixes to **xWebApplication**. Formatted resources to DSC StyleGuideLines, fixed logging statements, fixed incorrect Get-TargetResource param block, fixed Test-SslFlags validation, fixed unit test mocking of Test-SslFlags, added Ssl128 option to SslFlags
  * Added EnabledProtocols
  * Fixed:
    * Formatted resources to DSC StyleGuideLines
      * Logging statements
      * Incorrect Get-TargetResource param block
      * Test-SslFlags validation
      * Unit test mocking of Test-SslFlags

### 1.11.0.0

* **xWebAppPool** updates:
  * Bug fixes, error handling and input validation improvements.
  * The following properties were added: **idleTimeoutAction**, **logEventOnProcessModel**, **setProfileEnvironment**.
  * The resource was updated to ensure a specific state only for the explicitly specified properties.
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
  * Fix issue with Get-Website when there are multiple sites.
  * Fix issue when trying to add a new website when no websites currently exist.
  * Fix typos.

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
  * **xWebsite**

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

When specifying a HTTPS web binding you can also specify a certifcate subject, for cases where the certificate
is being generated by the same configuration using something like xCertReq.

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
                    Port                  = 8444
                    CertificateSubject    = "CN=CertificateSubject"
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
    Import-DscResource -ModuleName PSDesiredStateConfiguration
    Import-DscResource -ModuleName xWebAdministration

    Node $AllNodes.NodeName
    {
        # Create a Web Application Pool
        xWebAppPool NewWebAppPool
        {
            Name   = $Node.WebAppPoolName
            Ensure = "Present"
            State  = "Started"
        }

        #Create physical path website
        File NewWebsitePath
        {
            DestinationPath = $Node.PhysicalPathWebSite
            Type = "Directory"
            Ensure = "Present"
        }

        #Create physical path web application
        File NewWebApplicationPath
        {
            DestinationPath = $Node.PhysicalPathWebApplication
            Type = "Directory"
            Ensure = "Present"
        }

        #Create physical path virtual directory
        File NewVirtualDirectoryPath
        {
            DestinationPath = $Node.PhysicalPathVirtualDir
            Type = "Directory"
            Ensure = "Present"
        }

        #Create a New Website with Port
        xWebSite NewWebSite
        {
            Name   = $Node.WebSiteName
            Ensure = "Present"
            BindingInfo = MSFT_xWebBindingInformation
            {
                Protocol = "http"
                Port = $Node.Port
            }

            PhysicalPath = $Node.PhysicalPathWebSite
            State = "Started"
            DependsOn = @("[xWebAppPool]NewWebAppPool","[File]NewWebsitePath")
        }

        #Create a new Web Application
        xWebApplication NewWebApplication
        {
            Name = $Node.WebApplicationName
            Website = $Node.WebSiteName
            WebAppPool =  $Node.WebAppPoolName
            PhysicalPath = $Node.PhysicalPathWebApplication
            Ensure = "Present"
            DependsOn = @("[xWebSite]NewWebSite","[File]NewWebApplicationPath")
        }

        #Create a new virtual Directory
        WebVirtualDirectory NewVirtualDir
        {
            Name = $Node.WebVirtualDirectoryName
            Site = $Node.WebSiteName
            Application =  $Node.WebApplicationName
            PhysicalPath = $Node.PhysicalPathVirtualDir
            Ensure = "Present"
            DependsOn = @("[xWebApplication]NewWebApplication","[File]NewVirtualDirectoryPath")
        }

        #Create an empty web.config file
        File CreateWebConfig
        {
             DestinationPath = $Node.PhysicalPathWebSite + "\web.config"
             Contents = "<?xml version=`"1.0`" encoding=`"UTF-8`"?>
                            <configuration>
                            </configuration>"
                    Ensure = "Present"
             DependsOn = @("[WebVirtualDirectory]NewVirtualDir")
        }

        #Add an appSetting key1
        xWebConfigKeyValue ModifyWebConfig
        {
            Ensure = "Present"
            ConfigSection = "AppSettings"
            Key = "key1"
            Value = "value1"
            IsAttribute = $false
            WebsitePath = "IIS:\sites\" + $Node.WebsiteName
            DependsOn = @("[File]CreateWebConfig")
        }

        #Add a webApplicationHandler
        WebApplicationHandler WebHandlerTest
        {
            PSPath               = $Node.PSPath
            Name                 = 'ATest-WebHandler'
            Path                 = '*'
            Verb                 = '*'
            Modules              = 'IsapiModule'
            RequireAccess        = 'None'
            ScriptProcessor      = "C:\Windows\Microsoft.NET\Framework64\v4.0.30319\aspnet_isapi.dll"
            ResourceType         = 'Unspecified'
            AllowPathInfo        = $false
            ResponseBufferLimit  = 0
            PhysicalPath         = $Node.PhysicalPathWebApplication
            Type                 = $null
            PreCondition         = $null
            Location             = 'Default Web Site/TestDir
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
            LogTargetW3C = 'File,ETW'
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
