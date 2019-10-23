@{
    # Version number of this module.
    moduleVersion = '2.8.0.0'

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
            ReleaseNotes = '* Fix multiple HTTPS bindings on one xWebSite receiving the first binding"s certificate [332](https://github.com/PowerShell/xWebAdministration/issues/332)
    * Added unit regression test
    * Changes to xWebSite
    * Added ServerAutoStart (controls website autostart) and changed documentation for ServiceAutoStartEnabled (controls application auto-initialization). Fixes 325.
    * Fix multiple HTTPS bindings on one xWebSite receiving the first binding"s certificate [332](https://github.com/PowerShell/xWebAdministration/issues/332)
        * Added unit regression test
    * Changes to xWebAppPool
    * Fix false `Test-TargetResource` failure for `logEventOnRecycle` if items in the Configuration property are specified in a different order than IIS natively stores them [434](https://github.com/PowerShell/xWebAdministration/issues/434)
    * Changes to xIisModule
    * Fixed the parameters specification for the internal Get-IISHandler and Remove-IISHandler function

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





















