# Welcome to the xWebAdministration wiki

<sup>*xWebAdministration v#.#.#*</sup>

Here you will find all the information you need to make use of the xWebAdministration
DSC resources in the latest release. This includes details of the resources
that are available, current capabilities and known issues, and information
to help plan a DSC based implementation of xWebAdministration.

Please leave comments, feature requests, and bug reports for this module in
the [issues section](https://github.com/dsccommunity/xWebAdministration/issues)
for this repository.

## Deprecated resources

The documentation, examples, unit test, and integration tests have been removed
for these deprecated resources. These resources will be removed
in a future release.

*No deprecated resources*.

## Getting started

To get started either:

- Install from the PowerShell Gallery using PowerShellGet by running the
  following command:

```powershell
Install-Module -Name xWebAdministration -Repository PSGallery
```

- Download xWebAdministration from the [PowerShell Gallery](http://www.powershellgallery.com/packages/xWebAdministration/)
  and then unzip it to one of your PowerShell modules folders (such as
  `$env:ProgramFiles\WindowsPowerShell\Modules`).

To confirm installation, run the below command and ensure you see the xWebAdministration
DSC resources available:

```powershell
Get-DscResource -Module xWebAdministration
```

## Prerequisites

### Powershell

The minimum Windows Management Framework (PowerShell) version required is 5.0
or higher, which ships with Windows 10 or Windows Server 2016,
but can also be installed on Windows 7 SP1, Windows 8.1, Windows Server 2012,
and Windows Server 2012 R2.

## Change log

A full list of changes in each version can be found in the [change log](https://github.com/dsccommunity/xWebAdministration/blob/main/CHANGELOG.md).
