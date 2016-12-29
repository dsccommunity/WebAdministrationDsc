# xWebAdministration

[![Build status](https://ci.appveyor.com/api/projects/status/gnsxkjxht31ctan1/branch/master?svg=true)](https://ci.appveyor.com/project/PowerShell/xwebadministration/branch/master)

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/).
For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/)
or contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any
additional questions or comments.

## Contributing

Please check out common DSC Resources [contributing guidelines](https://github.com/PowerShell/DscResource.Kit/blob/master/CONTRIBUTING.md).

## Installation

To manually install the module, download the source code and unzip the contents
of the \Modules\xWebAdministration directory to the
$env:ProgramFiles\WindowsPowerShell\Modules folder

To install from the PowerShell gallery using PowerShellGet (in PowerShell 5.0)
run the following command:

    Find-Module -Name xWebAdministration -Repository PSGallery | Install-Module

To confirm installation, run the below command and ensure you see the
SharePoint DSC resoures available:

    Get-DscResource -Module xWebAdministration

## Changelog

A full list of changes in each version can be found in the
[change log](CHANGELOG.md)

## Resources

### xIISModule

* **Path**: The path to the module to be registered.
* **Name**: The logical name to register the module as in IIS.
* **RequestPath**: The allowed request paths, such as *.php
* **Verb**: An array of allowed verbs, such as get and post.
* **SiteName**: The name of the Site to register the module for. If empty, the
    resource will register the module with all of IIS.
* **ModuleType**: The type of the module. Currently, only FastCgiModule is supported.
* **Ensure**: Ensures that the module is **Present** or **Absent**.

### xIISLogging

**Note** This will set the logfile settings for **all** websites; for individual
    websites use the Log options under **xWebsite**

* **LogPath**: The directory to be used for logfiles.
* **LogFlags**: The W3C logging fields: The values that are allowed for this
    property are:
  * `Date`
  * `Time`
  * `ClientIP`
  * `UserName`
  * `SiteName`
  * `ComputerName`
  * `ServerIP`
  * `Method`
  * `UriStem`
  * `UriQuery`
  * `HttpStatus`
  * `Win32Status`
  * `BytesSent`
  * `BytesRecv`
  * `TimeTaken`
  * `ServerPort`
  * `UserAgent`
  * `Cookie`
  * `Referer`
  * `ProtocolVersion`
  * `Host`
  * `HttpSubStatus`
* **LogPeriod**: How often the log file should rollover. The values that are
    allowed for this property are: `Hourly`,`Daily`,`Weekly`,`Monthly`,`MaxSize`
* **LogTruncateSize**: How large the file should be before it is truncated.
    If this is set then LogPeriod will be ignored if passed in and set to MaxSize.
    The value must be a valid integer between `1048576 (1MB)` and `4294967295 (4GB)`.
* **LoglocalTimeRollover**: Use the localtime for file naming and rollover.
    The acceptable values for this property are: `$true`, `$false`
* **LogFormat**: Format of the Logfiles. **Note**Only W3C supports LogFlags.
    The acceptable values for this property are: `IIS`,`W3C`,`NCSA`

### xWebAppPool

* **Name** : Indicates the application pool name. The value must contain between
    `1` and `64` characters.
* **Ensure** : Indicates if the application pool exists. Set this property to
    `Absent` to ensure that the application pool does not exist.
    Setting it to `Present` (the default value) ensures that the application
    pool exists.
* **State** : Indicates the state of the application pool. The values that are
    allowed for this property are: `Started`, `Stopped`.
* **autoStart** : When set to `$true`, indicates to the World Wide Web Publishing
    Service (W3SVC) that the application pool should be automatically started
    when it is created or when IIS is started.
* **CLRConfigFile** : Indicates the .NET configuration file for the application pool.
* **enable32BitAppOnWin64** : When set to `$true`, enables a 32-bit application
    to run on a computer that runs a 64-bit version of Windows.
* **enableConfigurationOverride** : When set to `$true`, indicates that delegated
    settings in Web.config files will be processed for applications within this
    application pool.  When set to `$false`, all settings in Web.config files
    will be ignored for this application pool.
* **managedPipelineMode** : Indicates the request-processing mode that is used
    to process requests for managed content. The values that are allowed for this
    property are: `Integrated`, `Classic`.
* **managedRuntimeLoader** : Indicates the managed loader to use for pre-loading
    the application pool.
* **managedRuntimeVersion** : Indicates the CLR version to be used by the
    application pool. The values that are allowed for this property are: `v4.0`,
    `v2.0`, and `""`.
* **passAnonymousToken** : When set to `$true`, the Windows Process Activation
    Service (WAS) creates and passes a token for the built-in IUSR anonymous user
    account to the Anonymous authentication module. The Anonymous authentication
    module uses the token to impersonate the built-in account. When this property
    is set to `$false`, the token will not be passed.
* **startMode** : Indicates the startup type for the application pool. The values
    that are allowed for this property are: `OnDemand`, `AlwaysRunning`.
* **queueLength** : Indicates the maximum number of requests that HTTP.sys will
    queue for the application pool. The value must be a valid integer between
    `10` and `65535`.
* **cpuAction** : Configures the action that IIS takes when a worker process
    exceeds its configured CPU limit. The values that are allowed for this
    property are: `NoAction`, `KillW3wp`, `Throttle`, and `ThrottleUnderLoad`.
* **cpuLimit** : Configures the maximum percentage of CPU time (in 1/1000ths of
    one percent) that the worker processes in the application pool are allowed
    to consume over a period of time as indicated by the **cpuResetInterval** property.
    The value must be a valid integer between `0` and `100000`.
* **cpuResetInterval** : Indicates the reset period (in minutes) for CPU
    monitoring and throttling limits on the application pool.
    The value must be a string representation of a TimeSpan value.
    The valid range (in minutes) is `0` to `1440`.
    Setting the value of this property to `00:00:00` disables CPU monitoring.
* **cpuSmpAffinitized** : Indicates whether a particular worker process assigned
    to the application pool should also be assigned to a given CPU.
* **cpuSmpProcessorAffinityMask** : Indicates the hexadecimal processor mask for
    multi-processor computers, which indicates to which CPU the worker processes
    in the application pool should be bound.
    Before this property takes effect, the **cpuSmpAffinitized** property must
    be set to `$true` for the application pool.
    The value must be a valid integer between `0` and `4294967295`.
* **cpuSmpProcessorAffinityMask2** : Indicates the high-order DWORD hexadecimal
    processor mask for 64-bit multi-processor computers, which indicates to which
    CPU the worker processes in the application pool should be bound.
    Before this property takes effect, the **cpuSmpAffinitized** property must
    be set to `$true` for the application pool.
    The value must be a valid integer between `0` and `4294967295`.
* **identityType** : Indicates the account identity under which the application
    pool runs. The values that are allowed for this property are:
    `ApplicationPoolIdentity`, `LocalService`, `LocalSystem`, `NetworkService`,
    and `SpecificUser`.
* **Credential** : Indicates the custom account crededentials. This property is
    only valid when the **identityType** property is set to `SpecificUser`.
* **idleTimeout** : Indicates the amount of time (in minutes) a worker process
    will remain idle before it shuts down.
    The value must be a string representation of a TimeSpan value and must be
    less than the **restartTimeLimit** property value. The valid range
    (in minutes) is `0` to `43200`.
* **idleTimeoutAction** : Indicates the action to perform when the idle timeout
    duration has been reached.
    The values that are allowed for this property are: `Terminate`, `Suspend`.
* **loadUserProfile** : Indicates whether IIS loads the user profile for the
    application pool identity.
* **logEventOnProcessModel** : Indicates that IIS should generate an event log
    entry for each occurrence of the specified process model events.
* **logonType** : Indicates the logon type for the process identity.
    The values that are allowed for this property are: `LogonBatch`, `LogonService`.
* **manualGroupMembership** : Indicates whether the IIS_IUSRS group Security
    Identifier (SID) is added to the worker process token.
* **maxProcesses** : Indicates the maximum number of worker processes that would
    be used for the application pool.
    The value must be a valid integer between `0` and `2147483647`.
* **pingingEnabled** : Indicates whether pinging (health monitoring) is enabled
    for the worker process(es) serving this application pool.
* **pingInterval** : Indicates the period of time (in seconds) between health
    monitoring pings sent to the worker process(es) serving this application pool.
    The value must be a string representation of a TimeSpan value. The valid range
    (in seconds) is `1` to `4294967`.
* **pingResponseTime** : Indicates the maximum time (in seconds) that a worker
    process is given to respond to a health monitoring ping.
    The value must be a string representation of a TimeSpan value. The valid range
    (in seconds) is `1` to `4294967`.
* **setProfileEnvironment** : Indicates the environment to be set based on the
    user profile for the new process.
* **shutdownTimeLimit** : Indicates the period of time (in seconds) a worker
    process is given to finish processing requests and shut down.
    The value must be a string representation of a TimeSpan value. The valid
    range (in seconds) is `1` to `4294967`.
* **startupTimeLimit** : Indicates the period of time (in seconds) a worker
    process is given to start up and initialize.
    The value must be a string representation of a TimeSpan value. The valid range
    (in seconds) is `1` to `4294967`.
* **orphanActionExe** : Indicates an executable to run when a worker process is orphaned.
* **orphanActionParams** : Indicates parameters for the executable that is
    specified in the **orphanActionExe** property.
* **orphanWorkerProcess** : Indicates whether to assign a worker process to an
    orphan state instead of terminating it when the application pool fails.
    If `$true`, an unresponsive worker process will be orphaned instead of terminated.
* **loadBalancerCapabilities** : Indicates the response behavior of a service
    when it is unavailable. The values that are allowed for this property are:
    `HttpLevel`, `TcpLevel`.
    If set to `HttpLevel` and the application pool is stopped, HTTP.sys will
    return HTTP 503 error. If set to `TcpLevel`, HTTP.sys will reset the connection.
* **rapidFailProtection** : Indicates whether rapid-fail protection is enabled.
    If `$true`, the application pool is shut down if there are a specified number
    of worker process crashes within a specified time period.
* **rapidFailProtectionInterval** : Indicates the time interval (in minutes)
    during which the specified number of worker process crashes must occur
    before the application pool is shut down by rapid-fail protection.
    The value must be a string representation of a TimeSpan value.
    The valid range (in minutes) is `1` to `144000`.
* **rapidFailProtectionMaxCrashes** : Indicates the maximum number of worker
    process crashes permitted before the application pool is shut down by
    rapid-fail protection.
    The value must be a valid integer between `0` and `2147483647`.
* **autoShutdownExe** : Indicates an executable to run when the application pool
    is shut down by rapid-fail protection.
* **autoShutdownParams** : Indicates parameters for the executable that is
    specified in the **autoShutdownExe** property.
* **disallowOverlappingRotation** : Indicates whether the W3SVC service should
    start another worker process to replace the existing worker process while
    that process is shutting down.
    If `$true`, the application pool recycle will happen such that the existing
    worker process exits before another worker process is created.
* **disallowRotationOnConfigChange** : Indicates whether the W3SVC service should
    rotate worker processes in the application pool when the configuration has changed.
    If `$true`, the application pool will not recycle when its configuration is changed.
* **logEventOnRecycle** : Indicates that IIS should generate an event log entry
    for each occurrence of the specified recycling events.
* **restartMemoryLimit** : Indicates the maximum amount of virtual memory (in KB)
    a worker process can consume before causing the application pool to recycle.
    The value must be a valid integer between `0` and `4294967295`.
    A value of `0` means there is no limit.
* **restartPrivateMemoryLimit** : Indicates the maximum amount of private memory
    (in KB) a worker process can consume before causing the application pool to recycle.
    The value must be a valid integer between `0` and `4294967295`.
    A value of `0` means there is no limit.
* **restartRequestsLimit** : Indicates the maximum number of requests the
    application pool can process before it is recycled.
    The value must be a valid integer between `0` and `4294967295`.
    A value of `0` means the application pool can process an unlimited number
    of requests.
* **restartTimeLimit** : Indicates the period of time (in minutes) after which
    the application pool will recycle.
    The value must be a string representation of a TimeSpan value. The valid range
    (in minutes) is `0` to `432000`.
    A value of `00:00:00` means the application pool does not recycle on a
    regular interval.
* **restartSchedule** : Indicates a set of specific local times, in 24 hour
    format, when the application pool is recycled.
    The value must be an array of string representations of TimeSpan values.
    TimeSpan values must be between `00:00:00` and `23:59:59` seconds inclusive,
    with a granularity of 60 seconds.
    Setting the value of this property to `""` disables the schedule.

### xWebsite

* **Name** : The desired name of the website.
* **PhysicalPath**: The path to the files that compose the website.
* **State**: The state of the website: { Started | Stopped }
* **BindingInfo**: Website's binding information in the form of an array of
    embedded instances of the **MSFT_xWebBindingInformation** CIM class that
    implements the following properties:
  * **Protocol**: The protocol of the binding. This property is required.
    The acceptable values for this property are: `http`, `https`, `msmq.formatname`,
    `net.msmq`, `net.pipe`, `net.tcp`.
  * **BindingInformation**: The binding information in the form a colon-delimited
    string that includes the IP address, port, and host name of the binding.
    This property is ignored for `http` and `https` bindings if at least one of
    the following properties is specified: **IPAddress**, **Port**, **HostName**.
  * **IPAddress**: The IP address of the binding. This property is only applicable
    for `http` and `https` bindings. The default value is `*`.
  * **Port**: The port of the binding. The value must be a positive integer between
    `1` and `65535`. This property is only applicable for `http` (the default
    value is `80`) and `https` (the default value is `443`) bindings.
  * **HostName**: The host name of the binding. This property is only applicable
    for `http` and `https` bindings.
  * **CertificateThumbprint**: The thumbprint of the certificate. This property
    is only applicable for `https` bindings.
  * **CertificateStoreName**: The name of the certificate store where the
    certificate is located. This property is only applicable for `https` bindings.
    The acceptable values for this property are: `My`, `WebHosting`. The default
    value is `My`.
  * **SslFlags**: The type of binding used for Secure Sockets Layer (SSL)
    certificates. This property is supported in IIS 8.0 or later, and is only
    applicable for `https` bindings. The acceptable values for this property are:
    * **0**: The default value. The secure connection be made using an IP/Port
        combination. Only one certificate can be bound to a combination of IP
        address and the port.
    * **1**: The secure connection be made using the port number and the host
        name obtained by using Server Name Indication (SNI). It allows multiple
        secure websites with different certificates to use the same IP address.
    * **2**: The secure connection be made using the Centralized Certificate Store
    without requiring a Server Name Indication.
    * **3**: The secure connection be made using the Centralized Certificate Store
    while requiring Server Name Indication.
* **ApplicationPool**: The website’s application pool.
* **EnabledProtocols**: The protocols that are enabled for the website.
* **Ensure**: Ensures that the website is **Present** or **Absent**.
* **PreloadEnabled**: When set to `$true` this will allow WebSite to automatically
    start without a request
* **ServiceAutoStartEnabled**: When set to `$true` this will enable Autostart
    on a Website
* **ServiceAutoStartProvider**: Adds a AutostartProvider
* **ApplicationType**: Adds a AutostartProvider ApplicationType
* **AuthenticationInfo**: Website's authentication information in the form of an
    embedded instance of the **MSFT_xWebAuthenticationInformation** CIM class.
    **MSFT_xWebAuthenticationInformation** takes the following properties:
    * **Anonymous**: The acceptable values for this property are: `$true`, `$false`
    * **Basic**: The acceptable values for this property are: `$true`, `$false`
    * **Digest**: The acceptable values for this property are: `$true`, `$false`
    * **Windows**: The acceptable values for this property are: `$true`, `$false`
* **LogPath**: The directory to be used for logfiles.
* **LogFlags**: The W3C logging fields: The values that are allowed for this
    property are: `Date`,`Time`,`ClientIP`,`UserName`,`SiteName`,`ComputerName`,
    `ServerIP`,`Method`,`UriStem`,`UriQuery`,`HttpStatus`,`Win32Status`,`BytesSent`,
    `BytesRecv`,`TimeTaken`,`ServerPort`,`UserAgent`,`Cookie`,`Referer`,
    `ProtocolVersion`,`Host`,`HttpSubStatus`
* **LogPeriod**: How often the log file should rollover. The values that are
    allowed for this property are: `Hourly`,`Daily`,`Weekly`,`Monthly`,`MaxSize`
* **LogTruncateSize**: How large the file should be before it is truncated.
    If this is set then LogPeriod will be ignored if passed in and set to MaxSize.
    The value must be a valid integer between `1048576 (1MB)` and `4294967295 (4GB)`.
* **LoglocalTimeRollover**: Use the localtime for file naming and rollover.
    The acceptable values for this property are: `$true`, `$false`
* **LogFormat**: Format of the Logfiles. **Note**Only W3C supports LogFlags.
    The acceptable values for this property are: `IIS`,`W3C`,`NCSA`

### xWebApplication

* **Website**: Name of website with which the web application is associated.
* **Name**: The desired name of the web application.
* **WebAppPool**:  Web application’s application pool.
* **PhysicalPath**: The path to the files that compose the web application.
* **Ensure**: Ensures that the web application is **Present** or **Absent**.
* **PreloadEnabled**: When set to `$true` this will allow WebSite to automatically
    start without a request
* **ServiceAutoStartEnabled**: When set to `$true` this will enable Autostart on
    a Website
* **ServiceAutoStartProvider**: Adds a AutostartProvider
* **ApplicationType**: Adds a AutostartProvider ApplicationType
* **AuthenticationInfo**: Web Application's authentication information in the
    form of an embedded instance of the **MSFT_xWebApplicationAuthenticationInformation**
    CIM class. **MSFT_xWebApplicationAuthenticationInformation** takes the
    following properties:
  * **Anonymous**: The acceptable values for this property are: `$true`, `$false`
  * **Basic**: The acceptable values for this property are: `$true`, `$false`
  * **Digest**: The acceptable values for this property are: `$true`, `$false`
  * **Windows**: The acceptable values for this property are: `$true`, `$false`
* **SslFlags**: SslFlags for the application: The acceptable values for this
    property are: `''`, `Ssl`, `SslNegotiateCert`, `SslRequireCert`, `Ssl128`

### xWebVirtualDirectory

* **Website**: Name of website with which virtual directory is associated
* **WebApplication**:  The name of the containing web application or an empty
    string for the containing website
* **PhysicalPath**: The path to the files that compose the virtual directory
* **Name**: The name of the virtual directory
* **Ensure**: Ensures if the virtual directory is Present or Absent.

### xWebConfigKeyValue

* **WebsitePath**: Path to website location (IIS or WebAdministration format).
* **ConfigSection**: Section to update (only AppSettings supported as of now).
* **KeyValuePair**: Key value pair for AppSettings (ItemCollection format).

### xSSLSettings

* **Name**: The Name of website in which to modify the SSL Settings
* **Bindings**: The SSL bindings to implement.
* **Ensure**: Ensures if the bindings are Present or Absent.

### xIisFeatureDelegation

* **SectionName**: Relative path of the section to delegate such as **security/authentication**
* **OverrideMode**: Mode of that section { **Allow** | **Deny** }

### xIisMimeTypeMapping

* **Extension**: The file extension to map such as **.html** or **.xml**
* **MimeType**: The MIME type to map that extension to such as **text/html**
* **Ensure**: Ensures that the MIME type mapping is **Present** or **Absent**.

### xWebAppPoolDefaults

* **ApplyTo**: Required Key value, always **Machine**
* **ManagedRuntimeVersion**: CLR Version {v2.0|v4.0|} empty string for unmanaged.
* **ApplicationPoolIdentity**:
    {ApplicationPoolIdentity | LocalService | LocalSystem | NetworkService}
