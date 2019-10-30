@{
    # Version number of this module.
    moduleVersion = '3.0.0.0'

    # ID used to uniquely identify this module
    GUID = 'b3239f27-d7d3-4ae6-a5d2-d9a1c97d6ae4'

    # Author of this module
    Author = 'Microsoft Corporation'

    # Company or vendor of this module
    CompanyName = 'Microsoft Corporation'

    # Copyright statement for this module
    Copyright = '(c) 2019 Microsoft Corporation. All rights reserved.'

    # Description of the functionality provided by this module
    Description = 'Module with DSC Resources for Web Administration'

    # Minimum version of the Windows PowerShell engine required by this module
    PowerShellVersion = '4.0'

    # Minimum version of the common language runtime (CLR) required by this module
    CLRVersion = '4.0'

    # Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
    PrivateData = @{

        PSData = @{

            # Tags applied to this module. These help with module discovery in online galleries.
            Tags = @('DesiredStateConfiguration', 'DSC', 'DSCResourceKit', 'DSCResource')

            # A URL to the license for this module.
            LicenseUri = 'https://github.com/PowerShell/xWebAdministration/blob/master/LICENSE'

            # A URL to the main website for this project.
            ProjectUri = 'https://github.com/PowerShell/xWebAdministration'

            # A URL to an icon representing this module.
            # IconUri = ''

            # ReleaseNotes of this module
        ReleaseNotes = '- Changes to xWebAdministration
  - Changes to PULL\_REQUEST\_TEMPLATE.md
    - Improving descriptive text around the CHANGELOG.md entry.
    - Adding note that entry in CHANGELOG.md is mandatory for all PRs.
  - Resolved custom Script Analyzer rules that was added to the test
    framework.
  - Moved change log from README.md to a separate CHANGELOG.md ([issue 446](https://github.com/PowerShell/xWebAdministration/issues/446)).
  - Remove example "Creating the default website using configuration
    data" from README.md ([issue 488](https://github.com/PowerShell/xWebAdministration/issues/488)).
  - Removed examples README.md as it was obsolete ([issue 482](https://github.com/PowerShell/xWebAdministration/issues/482)).
  - Updated `Ensure` property description for `xIisHandler` resource to
    match schema.mof
  - Moved examples from Readme.md to respective `/Examples/Resources/`
    folders ([issue 486](https://github.com/PowerShell/xWebAdministration/issues/486)).
  - Created new folder structure for examples so that examples will be
    placed in `/Examples/Resources/$resourceName` ([issue 483](https://github.com/PowerShell/xWebAdministration/issues/483)).
  - Added a table of contents for the resource list ([issue 450](https://github.com/PowerShell/xWebAdministration/issues/450)).
  - Alphabetized the resource list in the README.md ([issue 449](https://github.com/PowerShell/xWebAdministration/issues/449)).
  - Optimized exporting in the module manifest for best performance ([issue 448](https://github.com/PowerShell/xWebAdministration/issues/448)).
  - Updated hashtables in the repo to adhere to the style guidelines
    described at https://github.com/PowerShell/DscResources/blob/master/StyleGuidelines.mdcorrect-format-for-hashtables-or-objects
    ([issue 524](https://github.com/PowerShell/xWebAdministration/issues/524))
  - Moved example Sample_EndToEndxWebAdministration from readme.md to a
    separate .ps1 in `/examples/` ([issue 491](https://github.com/PowerShell/xWebAdministration/issues/491))
  - Removed example "Create and configure an application pool" from
    README.md ([issue 489](https://github.com/PowerShell/xWebAdministration/issues/489)).
- Changes to xIisHandler
  - Updated schema.mof to include descriptions for each property ([issue 453](https://github.com/PowerShell/xWebAdministration/issues/453)).
  - Moved MSFT_xIisHandler localization strings to strings.psd1 ([issue 463](https://github.com/PowerShell/xWebAdministration/issues/463)).
- Changes to xWebSite
  - Fix `Get-TargetResource` so that `LogFlags` are returned as expected
    array of strings (one for each flag) rather than an array containing
    a single comma-separated string of flags" ([issue 332](https://github.com/PowerShell/xWebAdministration/issues/332)).
  - Moved localization strings to strings.psd1 file ([issue 475](https://github.com/PowerShell/xWebAdministration/issues/475))
  - Updated schema.mof so that each property has an appropriate description ([issue 456](https://github.com/PowerShell/xWebAdministration/issues/456)).
  - Updated schema.mof and README so that `SourceType` and `SourceName`
    properties for `MSFT_xLogCustomFieldInformation` are associated with
    the appropriate descriptions and valuemaps/values ([issue 456](https://github.com/PowerShell/xWebAdministration/issues/456)).
  - Move examples from README.md to resource examples folder ([issue 487](https://github.com/PowerShell/xWebAdministration/issues/487)).
  - Fix case of resource name from `xWebsite` to `xWebSite` ([issue 535](https://github.com/PowerShell/xWebAdministration/issues/535)).
- Changes to xIISLogging
  - Fix `Get-TargetResource` so that `LogFlags` are returned as expected
    array of strings (one for each flag) rather than an array containing
    a single comma-separated string of flags ([issue 332](https://github.com/PowerShell/xWebAdministration/issues/332)).
  - Moved MSFT_xIisLogging localization strings to strings.psd1 ([issue 464](https://github.com/PowerShell/xWebAdministration/issues/464)).
- Changes to xSslSettings
  - Updated casing of `xSslSettings` in all file names, folder names,
    schema, and documentation ([issue 461](https://github.com/PowerShell/xWebAdministration/issues/461)).
  - Updated casing of `xSslSettings` in all file names, folder names,
    schema, and documentation ([issue 536](https://github.com/PowerShell/xWebAdministration/issues/536)).
  - Moved MSFT_xSslSettings localization strings to strings.psd1 ([issue 467](https://github.com/PowerShell/xWebAdministration/issues/467)).
- Changes to xWebConfigKeyValue
  - Updated schema.mof to include a description for the Ensure property ([issue 455](https://github.com/PowerShell/xWebAdministration/issues/455)).
  - Move localization strings to strings.psd1 file ([issue 472](https://github.com/PowerShell/xWebAdministration/issues/472)).
- Changes to xWebAppPoolDefaults
  - Move localization strings to strings.psd1 file ([issue 470](https://github.com/PowerShell/xWebAdministration/issues/470)).
  - BREAKING CHANGE: Changed `ApplyTo` key parameter to `IsSingleInstance`
    to bring the resource into compliance with published best practices ([issue 462](https://github.com/PowerShell/xWebAdministration/issues/462)).
- Changes to xWebApplication
  - Move localization strings to strings.psd1 file ([issue 468](https://github.com/PowerShell/xWebAdministration/issues/468))
  - Add description on class MSFT_xWebApplicationAuthenticationInformation ([issue 454](https://github.com/PowerShell/xWebAdministration/issues/454)).
- Changes to xIisModule entry
  - Moved xIisModule localization strings to strings.psd1 ([issue 466](https://github.com/PowerShell/xWebAdministration/issues/466)).
- Changes to xIisMimeTypeMapping
  - Moved MSFT_xIisMimeTypeMapping localization strings to strings.psd1 ([issue 465](https://github.com/PowerShell/xWebAdministration/issues/465)).
- Changes to xWebVirtualDirectory
  - Moved MSFT_xWebVirtualDirectory localization strings to strings.psd1 ([issue 477](https://github.com/PowerShell/xWebAdministration/issues/477)).
- Changes to xWebSiteDefaults
  - Move localization strings to strings.psd1 file ([issue 475](https://github.com/PowerShell/xWebAdministration/issues/475)).
  - BREAKING CHANGE: Changed `ApplyTo` key parameter to `IsSingleInstance`
    to bring the resource into compliance with published best practices ([issue 457](https://github.com/PowerShell/xWebAdministration/issues/457)).
  - Fix case of resource name from `xWebsiteDefaults` to `xWebSiteDefaults` ([issue 535](https://github.com/PowerShell/xWebAdministration/issues/535)).
- Changes to xWebConfigProperty
  - Move localization strings to strings.psd1 file ([issue 473](https://github.com/PowerShell/xWebAdministration/issues/473)).
- Changes to xWebConfigPropertyCollection
  - Move localization strings to strings.psd1 file ([issue 474](https://github.com/PowerShell/xWebAdministration/issues/474)).
- Changes to xIisFeatureDelegation
  - Moved MSFT_xIisFeatureDelegation localization strings to strings.psd1 ([issue 459](https://github.com/PowerShell/xWebAdministration/issues/459)).
- Changes to xWebAppPool
  - Moved MSFT_xWebAppPool localization strings to strings.psd1 ([issue 469](https://github.com/PowerShell/xWebAdministration/issues/469)).

'

        } # End of PSData hashtable

    } # End of PrivateData hashtable

    # Functions to export from this module
    FunctionsToExport = @()

    # Cmdlets to export from this module
    CmdletsToExport = @()

    # Variables to export from this module
    VariablesToExport = @()

    # Aliases to export from this module
    AliasesToExport = @()

}






















