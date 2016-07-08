@{
# Version number of this module.
ModuleVersion = '1.12.0.0'

# ID used to uniquely identify this module
GUID = 'b3239f27-d7d3-4ae6-a5d2-d9a1c97d6ae4'

# Author of this module
Author = 'Microsoft Corporation'

# Company or vendor of this module
CompanyName = 'Microsoft Corporation'

# Copyright statement for this module
Copyright = '(c) 2013 Microsoft Corporation. All rights reserved.'

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
        ReleaseNotes = '* **xWebAppPool** updates:
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

* Added **xWebApplication** integration tests
* Added fixes to **xWebApplication**. Formatted resources to DSC StyleGuideLines, fixed logging statements, fixed incorrect Get-TargetResource param block, fixed Test-SslFlags validation, fixed unit test mocking of Test-SslFlags, added Ssl128 option to SslFlags
'

    } # End of PSData hashtable

} # End of PrivateData hashtable

# Functions to export from this module
FunctionsToExport = '*'

# Cmdlets to export from this module
CmdletsToExport = '*'
}




