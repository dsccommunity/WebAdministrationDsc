# Changelog for WebAdministrationDsc

The format is based on and uses the types of changes according to [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

For older change log history see the [historic changelog](HISTORIC_CHANGELOG.md).

## [Unreleased]
- xWebConfigPropertyCollection
  - Fix compatibility with URLRewrite variables by doubling/escaping curly braces.

### Changed
  - Website
    - Fixed Test-TargetResource in Website when LogTruncateSize parameter is passed. Fixes [Issue #380](https://github.com/dsccommunity/WebAdministrationDsc/issues/380)

### Changed

- xWebAdministration
  - BREAKING CHANGE
    - Renamed _xWebAdministration_ to _WebAdministrationDSC_ - fixes [Issue #69](https://github.com/dsccommunity/WebAdministrationDsc/issues/213).
    - Changed all MSFT_xResourceName to DSC_ResourceName.
    - Updated DSCResources, Examples, Modules and Tests for new naming.
    - Updated README.md from _xWebAdministration_ to _WebAdministrationDSC_
    - Removed deprecated resource `xIISHandler`
    - Removed deprecated resource `xWebConfigKeyValue`

### Fixed

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
    help return a value of a `WebConfigurationProperty`. *This helper*
    *function is unable to be unit tested because it is using a type*
    *that cannot be mocked.*
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
