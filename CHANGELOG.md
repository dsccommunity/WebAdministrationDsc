# Changelog for WebAdministrationDsc

The format is based on and uses the types of changes according to [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

For older change log history see the [historic changelog](HISTORIC_CHANGELOG.md).

## [Unreleased]

### Changed

- `WebAdministrationDsc`
  - Update to latest Sampler files.
  - Remove `windows-2019` images. [#649](https://github.com/dsccommunity/WebAdministrationDsc/issues/649).
  - Add `windows-2025` images.

## [4.2.1] - 2024-11-13

### Added

- WebConfigPropertyCollection
  - Allowed different property collection key types to be added beyond the default.
  - Allowed control over single item property collection key types, including examples - fixes ([issue #379](https://github.com/dsccommunity/WebAdministrationDsc/issues/379)), ([issue #631](https://github.com/dsccommunity/WebAdministrationDsc/issues/631)).

### Changed

- IisModule
  - Set default for Ensure property to Present.
- IisMimeTypeMapping
  - Set default for Ensure property to Present.

### Fixed

- WebAdministrationDsc
  - Fixed CertificateStoreName default value from `MY` to `My` ([issue #642](https://github.com/dsccommunity/WebAdministrationDsc/issues/642))
- README.md
  - Fixed broken link.

### Removed

- Removed outdated resources documentation from README.md.

## [4.2.0] - 2024-08-26

### Removed

- WebAdministrationDsc
  - Removed the common function `Find-Certificate` in favor of the command
    present in the module DscResource.Common.
  - Removed the function `Get-CurrentUser` since no code were using it.

### Changed

- Website
  - Add Ensure to LogCustomFieldInformation. ([issue #571](https://github.com/dsccommunity/WebAdministrationDsc/issues/571))
  - Added code to ensure certificate selected has longest time until expiration when multiple matching certificates are found ([issue #578](https://github.com/dsccommunity/WebAdministrationDsc/issues/578))
- WebVirtualDirectory
  - Added Credential paramater

### Fixed

- WebAdministrationDsc
  - Fix so pipeline use GitVersion v5.
- IisLogging
  - Can now remove all LogCustomFields using Ensure. ([issue #571](https://github.com/dsccommunity/WebAdministrationDsc/issues/571))
-  WebSite
   - Added code to ensure certificate has private key. ([issue #578](https://github.com/dsccommunity/WebAdministrationDsc/issues/578))
- Removed duplicated resource descriptions in README.md
- Added documentation for ConfigurationPath attribute of IisMimeTypeMapping in README.md
- WebVirtualDirectory
  - Fixed error when using UNC PhysicalPath. ([issue #94](https://github.com/dsccommunity/WebAdministrationDsc/issues/94))
- Update build process to pin GitVersion to 5.* to resolve errors
  (https://github.com/gaelcolas/Sampler/issues/477).

## [4.1.0] - 2023-01-03

### Fixed

- WebApplication
  - Ensure CIM class names match for `WebApplicationAuthenticationInformation`.
    Prior to this change there as a mismatch between the class name for
    WebApplicationAuthenticationInformation in the schema and implementation.
    The schema referenced the class as DSC_WebApplicationAuthenticationInformation
    whereas the implementation referenced the class as MSFT_xWebApplicationAuthenticationInformation.
- WebVirtualDirectory
  [Issue #366](https://github.com/dsccommunity/WebAdministrationDsc/issues/366)
  In WebVirtualDirectory WebApplication '' and '/' can now be used interchangeably.
  - Fixed Add WebVirtualDirectory when WebApplication = '/'.
  - Fixed Remove WebVirtualDirectory when WebApplication = ''.
- CommonTestHelper
  Added `Invoke-UnitTestCleanup` to get consistent cleanup of stubs.
  Gives correct execution of integration tests when run in same PowerShell session as unit tests (no longer calling stubs).
  Gives correct `Restore-WebConfiguration` after integration tests when run in same PowerShell session as unit tests (no longer calling stub).
- MockWebAdministrationWindowsFeature
  [Issue #351](https://github.com/dsccommunity/WebAdministrationDsc/issues/351)
  Stubs now throw StubNotImplemented when they are called in order to show when a cmdlet is not mocked correctly.

## [4.0.0] - 2022-09-17

### Changed

- WebAdministrationDsc
  - BREAKING CHANGE
    - Renamed _xWebAdministration_ to _WebAdministrationDSC_ - fixes [Issue #69](https://github.com/dsccommunity/WebAdministrationDsc/issues/213).
    - Changed all MSFT_xResourceName to DSC_ResourceName.
    - Updated DSCResources, Examples, Modules and Tests for new naming.
    - Updated README.md from _xWebAdministration_ to _WebAdministrationDSC_
    - Removed deprecated resource `xIISHandler`
    - Removed deprecated resource `xWebConfigKeyValue`
- Website
  - Fixed Test-TargetResource in Website when LogTruncateSize parameter is
    passed. Fixes [Issue #380](https://github.com/dsccommunity/WebAdministrationDsc/issues/380)

### Fixed

- WebAdministrationDsc
  - Fixed URLs in README.md
- WebApplication
  - Fixed typo in README.md.

## [3.3.0] - 2022-06-03

### Deprecated

- **The module _xWebAdministration_ will be renamed to _WebAdministrationDsc_
  ([issue #213](https://github.com/dsccommunity/WebAdministrationDsc/issues/213)).
  The version `v3.3.0` will be the the last release of _xWebAdministration_.
  Version `v4.0.0` will be released as _WebAdministrationDsc_, it will be
  released shortly after the `v3.3.0` release to be able to start transition
  to the new module. The prefix 'x' will be removed from all resources in
  _WebAdministrationDsc_.**

### Changed

- xWebAdministration
  - Renamed `master` branch to `main` ([issue #591](https://github.com/dsccommunity/WebAdministrationDsc/issues/591)).
  - The pipeline will now update the module manifest property `DscResourcesToExport`
    automatically.
  - Only run the CI/CD pipeline on branch _main_ when there are changes to files
    inside the `source` folder.
  - Update the pipeline files to the latest from Sampler.
  - Switched build worker from Windows Server 2016 to Windows Server 2022,
    so that both Windows Server 2019 and Windows Server 2022 is now used.
  - Add resources README.md for wiki documentation.
- CommonTestHelper
  - Removed the helper function `Install-NewSelfSignedCertificateExScript`
    as the script it used is no longer available. Switched to using the
    module _PSPKI_ instead.

### Fixed

- xWebAdministration
  - The component `gitversion` that is used in the pipeline was wrongly configured
    when the repository moved to the new default branch `main`. It no longer throws
    an error when using newer versions of GitVersion.
- xIisLogging
  - Fixed the descriptions for SourceType and SourceName which were incorrectly
    switched around in the `README.md`.

## [3.2.0] - 2020-08-06

### Added

- xWebAdministration
  - Integration tests are running on more Microsoft-hosted agents to
    test all possible operating systems ([issue #550](https://github.com/dsccommunity/WebAdministrationDsc/issues/550)).
  - Fix a few lingering bugs in CICD ([issue #567](https://github.com/dsccommunity/WebAdministrationDsc/issues/567))
  - Remove an image from testing that MS will be deprecating soon ([issue #565](https://github.com/dsccommunity/WebAdministrationDsc/issues/567))

### Changed

- xWebAdminstration
  - Module was wrongly bumped to `4.0.0` (there a no merged breaking changes)
    so the versions `4.0.0-preview1` to `4.0.0-preview5` have been unlisted
    from the Gallery and removed as GitHub releases. The latest release is
    `3.2.0`.
  - Azure Pipelines will no longer trigger on changes to just the CHANGELOG.md
    (when merging to master).
  - The deploy step is no longer run if the Azure DevOps organization URL
    does not contain 'dsccommunity'.
  - Changed the VS Code project settings to trim trailing whitespace for
    markdown files too.
  - Update pipeline to use NuGetVersionV2 from `GitVersion`.
  - Pinned PowerShell module Pester to v4.10.1 in the pipeline due to
    tests is not yet compatible with Pester 5.
  - Using latest version of the PowerShell module ModuleBuilder.
    - Updated build.yaml to use the correct values.
- xWebSite
  - Ensure that Test-TargetResource in xWebSite tests all properties before
    returning true or false, and that it uses a consistent style ([issue #221](https://github.com/dsccommunity/WebAdministrationDsc/issues/550)).
- xIisMimeTypeMapping
  - Update misleading localization strings
- xIisLogging
  - Add Ensure to LogCustomFields. ([issue #571](https://github.com/dsccommunity/WebAdministrationDsc/issues/571))

### Fixed

- WebApplicationHandler
  - Integration test should no longer fail intermittent ([issue #558](https://github.com/dsccommunity/WebAdministrationDsc/issues/558)).

## [3.1.1] - 2020-01-10

### Changed

- xWebAdministration
  - Set `testRunTitle` for PublishTestResults task so that a helpful name is
    displayed in Azure DevOps for each test file artifact.
  - Update Visual Studio Code workspace settings for the repository.
  - Set a display name on all the jobs and tasks in the CI pipeline.

### Fixed

- xWebAdministration
  - Update GitVersion.yml with the correct regular expression.
  - Fix import statement in all tests, making sure it throws if module
    DscResource.Test cannot be imported.
- xWebsite
  - Fixed HTTPS binding issue causing failure when CertificateSubject matches
    multiple certificates.
  - Fix an issue where changes to LogFlags would fail to apply.

## [3.1.0] - 2019-12-30

### Added

- xWebAdministration
  - Added continuous delivery with a new CI pipeline
    ([issue #547](https://github.com/dsccommunity/WebAdministrationDsc/issues/547)).
  - Added CONTRIBUTION.md.

### Changed

- xWebAdministration.Common
  - Added new helper function `Get-WebConfigurationPropertyValue` to
    help return a value of a `WebConfigurationProperty`. _This helper_
    _function is unable to be unit tested because it is using a type_
    _that cannot be mocked._
- xWebAppPoolDefaults
  - Changed to use the new helper function `Get-WebConfigurationPropertyValue`
    so that the resource can be properly unit tested.
- xWebConfigProperty
  - Changed to use the new helper function `Get-WebConfigurationPropertyValue`
    so that the resource can be properly unit tested.

### Fixed

- WebApplicationHandler
  - Fix Test-TargetResource to compare only properties that are specified
    in the configuration ([issue #544](https://github.com/dsccommunity/WebAdministrationDsc/issues/544)).
- xWebConfigProperty
  - In some cases a verbose message was not outputted with any text, now
    all verbose messages are correctly shown.
- xWebSite
  - In some cases a verbose message was not outputted with any text, now
    all verbose messages are correctly shown.

### Removed

- CommonTestHelper
  - Removed unused functions `Get-InvalidArgumentRecord` and
    `Get-InvalidOperationRecord`.
