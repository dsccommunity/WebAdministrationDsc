# Unreleased

## 1.17.0.0

* Added removal of self signed certificate to the integration tests of **xWebsite**, fixes #276.
* Added EnabledProtocols to **xWebApplication**.
* Changed SSLFlags for **xWebApplication** to comma seperate multiple SSL flags, fixes #232.

## 1.16.0.0

* Log directory configuration on **xWebsite** used the logPath attribute instead of the directory attribute. Bugfix for #256.
* Changed **xWebConfigKeyValue** to use the key for changing existing values. Bugfix for #107.
* Changed validation of LogTruncateSize for **xIisLogging** and **xWebsite** to UInt64 validation.
* Make PhysicalPath optional in **xWebsite**. Bugfix for #264.

## 1.15.0.0

* Corrected name of AuthenticationInfo parameter in Readme.md.
* Added sample for **xWebApplication** for adding new web application.
* Corrected description for AuthenticationInfo for xWebApplication and xWebsite.
* Added samples for **xWebConfigKeyValue** for adding and removing appSettings.
* Added sample for **xWebAppPoolDefaults** for configuring the application pool defaults.
* Added sample for **xWebSiteDefaults** for configuring the site defaults.
* Updated Readme.md for **xWebConfigKeyValue**. Added **xIISHandler** and **xWebSiteDefaults**.

## 1.14.0.0

* xWebApplication:
  * Fixed bug when setting PhysicalPath and WebAppPool
  * Changes to the application pool property are now applied correctly

## 1.13.0.0

* Added unit tests for **xWebConfigKeyValue** and cleaned up style formatting.
* Added a stubs file for the WebAdministration functions so that the unit tests do not require a server to run
* Converted appveyor.yml to install Pester from PSGallery instead of from Chocolatey.
* Updated appveyor.yml to use the default image.

## 1.12.0.0

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

## 1.11.0.0

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

## 1.10.0.0

* Fixed script analyzer failures in examples
* **xWebsite**: Fixed an issue in BindingInfo validation that caused multiple bindings with the same port and protocol treated as invalid.
* Changed PhysicalPath in xWebsite to be optional
* Changed WebApplication in xWebVirtualDirectory to accept empty strings for referring to the top-level IIS site

## 1.9.0.0

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

## 1.8.0.0

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

## 1.7.0.0

* Added following resources:
  * xIisHandler
  * xIisFeatureDelegation
  * xIisMimeTypeMapping
  * xWebAppPoolDefaults
  * xWebSiteDefaults
* Modified xWebsite schema to make PhysicalPath required

## 1.6.0.0

* Fixed bug in xWebsite resource regarding incorrect name of personal certificate store.

## 1.5.0.0

* xWebsite:
  * Fix issue with Get-Website when there are multiple sites.
  * Fix issue when trying to add a new website when no websites currently exist.
  * Fix typos.

## 1.4.0.0

Changed Key property in MSFT_xWebConfigKeyValue to be a Key, instead of Required. This allows multiple keys to be configured within the same web.config file.

## 1.3.2.4

* Fixed the confusion with mismatched versions and xWebDeploy resources
* Removed BakeryWebsite.zip for legal reasons. Please read Examples\README.md for the workaround.

## 1.3.2.3

* Fixed variable name typo in MSFT_xIisModule.
* Added OutputType attribute to Test-TargetResource and Get-TargetResource in MSFT_xWebSite.

## 1.3.2.2

* Documentation only change.

Module manifest metadata changed to improve PowerShell Gallery experience.

## 1.3.2.1

* Documentation-only change, added metadata to module manifest

## 1.3.2

* Added **xIisModule**

## 1.2

* Added the **xWebAppPool**, **xWebApplication**, **xWebVirtualDirectory**, and **xWebConfigKeyValue**.

## 1.1.0.0

* Added support for HTTPS protocol
* Updated binding information to include Certificate information for HTTPS
* Removed protocol property. Protocol is included in binding information
* Bug fixes

## 1.0.0.0

* Initial release with the following resources
  * **xWebsite**

