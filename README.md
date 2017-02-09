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
