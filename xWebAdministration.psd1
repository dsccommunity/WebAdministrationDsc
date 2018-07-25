@{
# Version number of this module.
moduleVersion = '2.1.0.0'

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
        ReleaseNotes = '* Added new resources **xWebConfigProperty** and **xWebConfigPropertyCollection** extending functionality provided by **xWebConfigKeyValue**, addresses 249.
* Fixed Get-DscConfiguration throw in xWebSite; addresses [372](https://github.com/PowerShell/xWebAdministration/issues/372). [Reggie Gibson (@regedit32)](https://github.com/regedit32)
* Added **WebApplicationHandler** resource for creating and modifying IIS Web Handlers. Fixes 337
* Added **WebApplicationHandler** integration tests
* Added **WebApplicationHandler** unit tests
* Deprecated xIISHandler resource. This resource will be removed in future release

'

    } # End of PSData hashtable

} # End of PrivateData hashtable

# Functions to export from this module
FunctionsToExport = '*'

# Cmdlets to export from this module
CmdletsToExport = '*'
}













