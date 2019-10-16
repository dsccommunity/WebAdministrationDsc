# Change log for xWebAdministration

## Unreleased

- Changes to xWebAppPool
  - Moved MSFT_xWebAppPool localization strings to strings.psd1 ([issue #469](https://github.com/PowerShell/xWebAdministration/issues/469)).
- Changes to xWebAdministration
  - Changes to PULL\_REQUEST\_TEMPLATE.md
    - Improving descriptive text around the CHANGELOG.md entry.
    - Adding note that entry in CHANGELOG.md is mandatory for all PRs.
  - Resolved custom Script Analyzer rules that was added to the test framework.
  - Moved change log from README.md to a separate CHANGELOG.md ([issue #446](https://github.com/PowerShell/xWebAdministration/issues/446)).
  - Remove example 'Creating the default website using configuration data' from README.md ([issue #488](https://github.com/PowerShell/xWebAdministration/issues/488)).
  - Removed examples README.md as it was obsolete ([issue #482](https://github.com/PowerShell/xWebAdministration/issues/482)).
  - Updated `Ensure` property description for `xIisHandler` resource to match schema.mof
  - Moved examples from Readme.md to respective `/Examples/Resources/`
    folders ([issue #486](https://github.com/PowerShell/xWebAdministration/issues/486)).
  - Created new folder structure for examples so that examples will be
    placed in `/Examples/Resources/$resourceName` ([issue #483](https://github.com/PowerShell/xWebAdministration/issues/483)).
  - Added a table of contents for the resource list ([issue #450](https://github.com/PowerShell/xWebAdministration/issues/450)).
  - Alphabetized the resource list in the README.md ([issue #449](https://github.com/PowerShell/xWebAdministration/issues/449)).
  - Optimized exporting in the module manifest for best performance ([issue #448](https://github.com/PowerShell/xWebAdministration/issues/448)).
  - Updated hashtables in the repo to adhere to the style guidelines described at https://github.com/PowerShell/DscResources/blob/master/StyleGuidelines.md#correct-format-for-hashtables-or-objects ([issue #524](https://github.com/PowerShell/xWebAdministration/issues/524))
  - Moved example Sample_EndToEndxWebAdministration from readme.md to a separate .ps1 in `/examples/` ([issue #491](https://github.com/PowerShell/xWebAdministration/issues/491))
- Changes to xIisHandler
  - Updated schema.mof to include descriptions for each property ([issue #453](https://github.com/PowerShell/xWebAdministration/issues/453)).
  - Moved MSFT_xIisHandler localization strings to strings.psd1 ([issue #463](https://github.com/PowerShell/xWebAdministration/issues/463)).
- Changes to xWebSite
  - Fix `Get-TargetResource` so that `LogFlags` are returned as expected
    array of strings (one for each flag) rather than an array containing
    a single comma-separated string of flags' ([issue #332](https://github.com/PowerShell/xWebAdministration/issues/332)).
  - Moved localization strings to strings.psd1 file ([issue #475](https://github.com/PowerShell/xWebAdministration/issues/475))
  - Updated schema.mof so that each property has an appropriate description ([issue #456](https://github.com/PowerShell/xWebAdministration/issues/456)).
  - Updated schema.mof and README so that `SourceType` and `SourceName` properties for `MSFT_xLogCustomFieldInformation` are associated with the appropriate descriptions and valuemaps/values ([issue #456](https://github.com/PowerShell/xWebAdministration/issues/456)).
  - Move examples from README.md to resource examples folder ([issue #487](https://github.com/PowerShell/xWebAdministration/issues/487)).
  - Fix case of resource name from `xWebsite` to `xWebSite` ([issue #535](https://github.com/PowerShell/xWebAdministration/issues/535)).
- Changes to xIISLogging
  - Fix `Get-TargetResource` so that `LogFlags` are returned as expected
  array of strings (one for each flag) rather than an array containing a
  single comma-separated string of flags ([issue #332](https://github.com/PowerShell/xWebAdministration/issues/332)).
  - Moved MSFT_xIisLogging localization strings to strings.psd1 ([issue #464](https://github.com/PowerShell/xWebAdministration/issues/464)).
- Changes to xSslSettings
  - Updated casing of `xSslSettings` in all file names, folder names, schema, and documentation
    ([issue #461](https://github.com/PowerShell/xWebAdministration/issues/461)).
  - Updated casing of `xSslSettings` in all file names, folder names, schema, and documentation
    ([issue #536](https://github.com/PowerShell/xWebAdministration/issues/536)).
  - Moved MSFT_xSslSettings localization strings to strings.psd1 ([issue #467](https://github.com/PowerShell/xWebAdministration/issues/467)).
- Changes to xWebConfigKeyValue
  - Updated schema.mof to include a description for the Ensure property ([issue #455](https://github.com/PowerShell/xWebAdministration/issues/455)).
  - Move localization strings to strings.psd1 file ([issue #472](https://github.com/PowerShell/xWebAdministration/issues/472)).
- Changes to xWebAppPoolDefaults
  - Move localization strings to strings.psd1 file ([issue #470](https://github.com/PowerShell/xWebAdministration/issues/470)).
  - BREAKING CHANGE: Changed `ApplyTo` key parameter to `IsSingleInstance` to
  bring the resource into compliance with published best practices. ([issue #462](https://github.com/PowerShell/xWebAdministration/issues/462))
- Changes to xWebApplication
  - Move localization strings to strings.psd1 file ([Issue #468](https://github.com/PowerShell/xWebAdministration/issues/468))
  - Add description on class MSFT_xWebApplicationAuthenticationInformation ([issue #454](https://github.com/PowerShell/xWebAdministration/issues/454)).
- Changes to xIisModule entry
  - Moved xIisModule localization strings to strings.psd1 ([issue #466](https://github.com/PowerShell/xWebAdministration/issues/466)).
- Changes to xIisMimeTypeMapping
  - Moved MSFT_xIisMimeTypeMapping localization strings to strings.psd1 ([issue #465](https://github.com/PowerShell/xWebAdministration/issues/465)).
- Changes to xWebVirtualDirectory
  - Moved MSFT_xWebVirtualDirectory localization strings to strings.psd1 ([issue #477](https://github.com/PowerShell/xWebAdministration/issues/477)).
- Changes to xWebSiteDefaults
  - Move localization strings to strings.psd1 file ([issue #475](https://github.com/PowerShell/xWebAdministration/issues/475)).
  - BREAKING CHANGE: Changed `ApplyTo` key parameter to `IsSingleInstance` to
  bring the resource into compliance with published best practices. ([issue #457](https://github.com/PowerShell/xWebAdministration/issues/457))
- Changes to xWebConfigProperty
  - Move localization strings to strings.psd1 file ([issue #473](https://github.com/PowerShell/xWebAdministration/issues/473)).
- Changes to xWebConfigPropertyCollection
  - Move localization strings to strings.psd1 file ([issue #474](https://github.com/PowerShell/xWebAdministration/issues/474)).
- Changes to xIisFeatureDelegation
  - Moved MSFT_xIisFeatureDelegation localization strings to strings.psd1 ([issue #459](https://github.com/PowerShell/xWebAdministration/issues/459)).

## 2.8.0.0

- Fix multiple HTTPS bindings on one xWebsite receiving the first binding's certificate [#332](https://github.com/PowerShell/xWebAdministration/issues/332)
  - Added unit regression test
- Changes to xWebsite
  - Added ServerAutoStart (controls website autostart) and changed documentation for ServiceAutoStartEnabled (controls application auto-initialization). Fixes #325.
  - Fix multiple HTTPS bindings on one xWebsite receiving the first binding's certificate [#332](https://github.com/PowerShell/xWebAdministration/issues/332)
    - Added unit regression test
- Changes to xWebAppPool
  - Fix false `Test-TargetResource` failure for `logEventOnRecycle` if items in the Configuration property are specified in a different order than IIS natively stores them [#434](https://github.com/PowerShell/xWebAdministration/issues/434)
- Changes to xIisModule
  - Fixed the parameters specification for the internal Get-IISHandler and Remove-IISHandler function

## 2.7.0.0

- Changes to xWebAdministration
  - Opt-in to the following DSC Resource Common Meta Tests:
    - Common Tests - Relative Path Length
    - Common Tests - Validate Script Files
    - Common Tests - Validate Module Files
    - Common Tests - Validate Markdown Files
    - Common Tests - Validate Markdown Links
    - Common Tests - Custom Script Analyzer Rules
    - Common Tests - Flagged Script Analyzer Rules
    - Common Tests - Required Script Analyzer Rules
    - Common Tests - Validate Example Files
  - Add ConfigurationPath to xIisMimeTypeMapping examples since it is now a required field.

## 2.6.0.0

- Changed order of classes in schema.mof files to workaround [#423](https://github.com/PowerShell/xWebAdministration/issues/423)
- Fix subject comparison multiple entries for helper function `Find-Certificate` that could not find the test
  helper function `Install-NewSelfSignedCertificateExScript`.
- Updated unit test for helper function `Find-Certificate` to check for multiple
  subject names in different orders.

## 2.5.0.0

- Added SiteId to xWebSite to address [396]
- xWebSite: Full path is used to get list of default documents
- xIISLogging: Added support for LogTargetW3C
- xWebsite: Added support for LogTargetW3C

## 2.4.0.0

- Explicitly removed extra hidden files from release package

## 2.3.0.0

- Update appveyor.yml to use the default template.
- Added default template file .gitattributes, and added default settings for
  Visual Studio Code.
- Line endings was fixed in files that was committed with wrong line ending.

## 2.2.0.0

- Added new parameter 'Location' to **WebApplcationHandler** extending functionality to address [392]
- Changes to xWebAdministration
  - Update section header for WebApplicationHandler in README.
  - Fix tests for helper function `Get-LocalizedData` in Helper.Tests.ps1
    that referenced the wrong path.
- Remove duplication in MSFT_xWebsite.psm1. [Krzysztof Morcinek (@kmorcinek)](https://github.com/kmorcinek)
- Updates **xIISMimeTypeMapping** to add MIME type mapping for nested paths

## 2.1.0.0

- Added new resources **xWebConfigProperty** and **xWebConfigPropertyCollection** extending functionality provided by **xWebConfigKeyValue**, addresses #249.
- Fixed Get-DscConfiguration throw in xWebSite; addresses [#372](https://github.com/PowerShell/xWebAdministration/issues/372). [Reggie Gibson (@regedit32)](https://github.com/regedit32)
- Added **WebApplicationHandler** resource for creating and modifying IIS Web Handlers. Fixes #337
- Added **WebApplicationHandler** integration tests
- Added **WebApplicationHandler** unit tests
- Deprecated xIISHandler resource. This resource will be removed in future release

## 2.0.0.0

- Changes to xWebAdministration
  - Moved file Codecov.yml that was added to the wrong path in previous release.
- Updated **xWebSite** to include ability to manage custom logging fields.
  [Reggie Gibson (@regedit32)](https://github.com/regedit32)
- Updated **xIISLogging** to include ability to manage custom logging fields
  ([issue #267](https://github.com/PowerShell/xWebAdministration/issues/267)).
  [@ldillonel](https://github.com/ldillonel)
- BREAKING CHANGE: Updated **xIisFeatureDelegation** to be able to manage any
  configuration section.
  [Reggie Gibson (@regedit32)](https://github.com/regedit32)

## 1.20.0.0

- Fix Get-DscConfiguration failure with xWebApplication and xWebSite resources
  (issue #302 and issue #314).
- Add Codecov support.
- Added .vscode\settings.json so that code can be easily formatted in VSCode
  closer according to the style guideline.
- Updated README.md with a branches section, and added Codecov badges.
- Fix unit test for helper function `Find-Certificate` that could not find the test
  helper function `Install-NewSelfSignedCertificateExScript`.
- Fix unit tests for xWebSite that failed because `Get-Command` and 'Stop-WebStie`
  wasn't properly mocked.

## 1.19.0.0

- **xWebAppPoolDefaults** now returns values. Fixes #311.
- Added unit tests for **xWebAppPoolDefaults**. Fixes #183.

## 1.18.0.0

- Added sample for **xWebVirtualDirectory** for creating a new virtual directory. Bugfix for #195.
- Added integration tests for **xWebVirtualDirectory**. Fixes #188.
- xWebsite:
  - Fixed bugs when setting log properties, fixes #299.

## 1.17.0.0

- Added removal of self signed certificate to the integration tests of **xWebsite**, fixes #276.
- Added EnabledProtocols to **xWebApplication**.
- Changed SSLFlags for **xWebApplication** to comma seperate multiple SSL flags, fixes #232.

## 1.16.0.0

- Log directory configuration on **xWebsite** used the logPath attribute instead of the directory attribute. Bugfix for #256.
- Changed **xWebConfigKeyValue** to use the key for changing existing values. Bugfix for #107.
- Changed validation of LogTruncateSize for **xIisLogging** and **xWebsite** to UInt64 validation.
- Make PhysicalPath optional in **xWebsite**. Bugfix for #264.

## 1.15.0.0

- Corrected name of AuthenticationInfo parameter in Readme.md.
- Added sample for **xWebApplication** for adding new web application.
- Corrected description for AuthenticationInfo for xWebApplication and xWebsite.
- Added samples for **xWebConfigKeyValue** for adding and removing appSettings.
- Added sample for **xWebAppPoolDefaults** for configuring the application pool defaults.
- Added sample for **xWebSiteDefaults** for configuring the site defaults.
- Updated Readme.md for **xWebConfigKeyValue**. Added **xIISHandler** and **xWebSiteDefaults**.

## 1.14.0.0

- xWebApplication:
  - Fixed bug when setting PhysicalPath and WebAppPool
  - Changes to the application pool property are now applied correctly

## 1.13.0.0

- Added unit tests for **xWebConfigKeyValue** and cleaned up style formatting.
- Added a stubs file for the WebAdministration functions so that the unit tests do not require a server to run
- Converted appveyor.yml to install Pester from PSGallery instead of from Chocolatey.
- Updated appveyor.yml to use the default image.

## 1.12.0.0

- **xWebAppPool** updates:
  -Replaced 3 calls to Invoke-Expression with a call to a new helper function - Get-Property

- **xWebsite** updates:
  - Bugfix for #131 The site name should be passed in as argument for Test-AuthenticationInfo
  - Improved **BindingInfo** validation: the **HostName** property is required for use with Server Name Indication (i.e., when the **SslFlags** property is set to `1` or `3`).
- Adding conditional logic to install the test helper module from the gallery if the user downloaded the module from the gallery.
- Added **xSslSettings** integration tests
- Added fixes to **xSslSettings**. Corrected spelling and formatting in base resource and tests. Added misc comments. Added ValidateSet to bindings param.

- Added **xIISLogging** resource which supports for the following options:
  - LogPath
  - LogFlags
  - LogPeriod
  - LogTruncateSize
  - LoglocalTimeRollover
  - LogFormat
- Added IIS Logging to **xWebsite** which support for the following options:
  - LogPath
  - LogFlags
  - LogPeriod
  - LogTruncateSize
  - LoglocalTimeRollover
  - LogFormat

- **xWebApplication** updates:
  - xWebApplication integration tests updated
  - Added fixes to **xWebApplication**. Formatted resources to DSC StyleGuideLines, fixed logging statements, fixed incorrect Get-TargetResource param block, fixed Test-SslFlags validation, fixed unit test mocking of Test-SslFlags, added Ssl128 option to SslFlags
  - Added EnabledProtocols
  - Fixed:
    - Formatted resources to DSC StyleGuideLines
      - Logging statements
      - Incorrect Get-TargetResource param block
      - Test-SslFlags validation
      - Unit test mocking of Test-SslFlags

## 1.11.0.0

- **xWebAppPool** updates:
  - Bug fixes, error handling and input validation improvements.
  - The following properties were added: **idleTimeoutAction**, **logEventOnProcessModel**, **setProfileEnvironment**.
  - The resource was updated to ensure a specific state only for the explicitly specified properties.
  - The type of the following properties was changed to **Boolean**: **autoStart**, **enable32BitAppOnWin64**, **enableConfigurationOverride**,
        **passAnonymousToken**, **cpuSmpAffinitized**, **loadUserProfile**, **manualGroupMembership**, **pingingEnabled**, **setProfileEnvironment**,
        **orphanWorkerProcess**, **rapidFailProtection**, **disallowOverlappingRotation**, **disallowRotationOnConfigChange**.
  - Unit and integration tests updated.
- **xWebsite** updated to remove invisible Unicode "LEFT-TO-RIGHT MARK" character from the **CertificateThumbprint*- property value.
- Added Preload and ServiceAutoStart functionality to **xWebsite** and **xWebApplication**
- Added AuthenticationInformation to **xWebsite** and **xWebApplication**
- Added SslFlags to **xWebApplication**

## 1.10.0.0

- Fixed script analyzer failures in examples
- **xWebsite**: Fixed an issue in BindingInfo validation that caused multiple bindings with the same port and protocol treated as invalid.
- Changed PhysicalPath in xWebsite to be optional
- Changed WebApplication in xWebVirtualDirectory to accept empty strings for referring to the top-level IIS site

## 1.9.0.0

- Added the following resources:
  - xSslSettings
- Fixed an issue in xWebApplication where Set-TargetResource attempted to modify a folder instead of an application.
  - Added Tests to xWebApplication which will allow more changes if desired.
- Modified README.MD to clean up Code Formatting
- Modified all unit/integration tests to utilize template system.
- xWebAppPool is now has feature parity to cWebAppPool - should now support most changes.
- Added Unit tests to IISFeatureDelegation, general script clean up
- Refactored xIisHandle to load script variables once, added unit tests.
- xWebsite updated:
  - Added support for the following binding protocols: `msmq.formatname`, `net.msmq`, `net.pipe`, `net.tcp`.
  - Added support for setting the `EnabledProtocols` property.
  - Fixed an issue in bindings comparison which was causing bindings to be reassigned on every consistency check.
  - Fixed an issue where binding conflict was not properly detected and handled. Stopped websites will not be checked for conflicting bindings anymore.
  - The qualifier for the Protocol property of the MSFT_xWebBindingInformation CIM class was changed from Write to Required.

## 1.8.0.0

- Modified xWebsite to allow Server Name Indication when specifiying SSL certificates.
- Change Test Get-Website to match other function
- Removed xDscResourceDesigner tests
- Suppress extra verbose messages when -verbose is specified to Start-DscConfiguration
- Moved tests into child folders Unit and Integration
- Added PSDesiredStateConfiguration to Import-DscResource statement
- Fixed issue where Set-TargetResource was being run unexpectedly
- Added Tests to MSFT_xWebVirtualDirectory
- xWebsite tests updates
- xWebVirtualDirectory tests updates

## 1.7.0.0

- Added following resources:
  - xIisHandler
  - xIisFeatureDelegation
  - xIisMimeTypeMapping
  - xWebAppPoolDefaults
  - xWebSiteDefaults
- Modified xWebsite schema to make PhysicalPath required

## 1.6.0.0

- Fixed bug in xWebsite resource regarding incorrect name of personal certificate store.

## 1.5.0.0

- xWebsite:
  - Fix issue with Get-Website when there are multiple sites.
  - Fix issue when trying to add a new website when no websites currently exist.
  - Fix typos.

## 1.4.0.0

Changed Key property in MSFT_xWebConfigKeyValue to be a Key, instead of Required. This allows multiple keys to be configured within the same web.config file.

## 1.3.2.4

- Fixed the confusion with mismatched versions and xWebDeploy resources
- Removed BakeryWebsite.zip for legal reasons. Please read Examples\README.md for the workaround.

## 1.3.2.3

- Fixed variable name typo in MSFT_xIisModule.
- Added OutputType attribute to Test-TargetResource and Get-TargetResource in MSFT_xWebSite.

## 1.3.2.2

- Documentation only change.

Module manifest metadata changed to improve PowerShell Gallery experience.

## 1.3.2.1

- Documentation-only change, added metadata to module manifest

## 1.3.2

- Added **xIisModule**

## 1.2

- Added the **xWebAppPool**, **xWebApplication**, **xWebVirtualDirectory**, and **xWebConfigKeyValue**.

## 1.1.0.0

- Added support for HTTPS protocol
- Updated binding information to include Certificate information for HTTPS
- Removed protocol property. Protocol is included in binding information
- Bug fixes

## 1.0.0.0

- Initial release with the following resources
  - **xWebsite**
