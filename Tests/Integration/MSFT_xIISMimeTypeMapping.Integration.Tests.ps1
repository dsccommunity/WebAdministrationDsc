
$script:DSCModuleName      = 'xWebAdministration'
$script:DSCResourceName    = 'MSFT_xIISMimeTypeMapping'

#region HEADER
$script:moduleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
if ( (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests'))) -or `
     (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1'))) )
{
    & git @('clone','https://github.com/PowerShell/DscResource.Tests.git',(Join-Path -Path $script:moduleRoot -ChildPath '\DSCResource.Tests\'))
}

Import-Module (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1') -Force
$TestEnvironment = Initialize-TestEnvironment `
    -DSCModuleName $script:DSCModuleName `
    -DSCResourceName $script:DSCResourceName `
    -TestType Integration
#endregion

[string]$tempName = "$($script:DSCResourceName)_" + (Get-Date).ToString("yyyyMMdd_HHmmss")
[string]$tempVirtualDirectoryPhysicalPath

# Using try/finally to always cleanup even if something awful happens.
try
{
    #region Integration Tests

    $null = Backup-WebConfiguration -Name $tempName

    $ConfigFile = Join-Path -Path $PSScriptRoot -ChildPath "$($script:DSCResourceName).config.ps1"
    . $ConfigFile

    $tempVirtualDirectoryName = 'Dir01'
    $tempVirtualDirectoryPhysicalPath = Join-Path $env:SystemDrive "inetpub\wwwroot\$tempVirtualDirectoryName"
    $tempVirtualDirectoryIisPath = "IIS:\Sites\WebsiteForxIisMimeTypeMapping\$tempVirtualDirectoryName"

    New-Website -Name 'WebsiteForxIisMimeTypeMapping' `
        -PhysicalPath (Join-Path $env:SystemDrive 'inetpub\wwwroot\') `
        -Force `
        -ErrorAction Stop

    New-Item -Path $tempVirtualDirectoryPhysicalPath -ItemType Directory | Out-Null
    New-WebVirtualDirectory -Site 'WebsiteForxIisMimeTypeMapping' -Name $tempVirtualDirectoryName -PhysicalPath $tempVirtualDirectoryPhysicalPath

    Describe "$($script:DSCResourceName)_Integration" {
        Set-Variable ConstDefaultConfigurationPath -Option Constant -Value 'MACHINE/WEBROOT/APPHOST'

        #region DEFAULT TESTS
        It 'Should compile without throwing' {
            {
                & "$($script:DSCResourceName)_Config" -OutputPath $TestDrive
                Start-DscConfiguration -Path $TestDrive -ComputerName localhost -Wait -Verbose -Force
            } | Should not throw
        }

        It 'should be able to call Get-DscConfiguration without throwing' {
            { Get-DscConfiguration -Verbose -ErrorAction Stop } | Should Not throw
        }
        #endregion

        It 'Adding an existing MimeType' {
            $node = (Get-WebConfiguration -PSPath $ConstDefaultConfigurationPath -Filter "system.webServer/staticContent/mimeMap") | Select-Object -First 1

            $configData = @{
                AllNodes = @();
                NonNodeData =
                @{
                    PesterFileExtension2 = $node.fileExtension
                    PesterMimeType2      = $node.mimeType
                }
            }

            {
                & "$($script:DSCResourceName)_AddMimeType" -OutputPath $TestDrive -ConfigurationData $configData
                Start-DscConfiguration -Path $TestDrive -ComputerName localhost -Wait -Verbose -Force
            } | Should not throw

            $filter = "system.webServer/staticContent/mimeMap[@fileExtension='{0}' and @mimeType='{1}']" -f `
                $configData.NonNodeData.PesterFileExtension2, $configData.NonNodeData.PesterMimeType2
            $expected = ((Get-WebConfiguration -PSPath $ConstDefaultConfigurationPath -Filter $filter) | Measure-Object).Count

            $expected | should be 1
        }

        It 'Removing a MimeType' {
            $node = (Get-WebConfiguration -PSPath $ConstDefaultConfigurationPath -Filter "system.webServer/staticContent/mimeMap") | Select-Object -First 1
            
            $configData = @{
                AllNodes = @();
                NonNodeData =
                @{
                    PesterFileExtension = $node.fileExtension
                    PesterMimeType      = $node.mimeType
                }
            }

            {
                & "$($script:DSCResourceName)_RemoveMimeType" -OutputPath $TestDrive -ConfigurationData $configData
                Start-DscConfiguration -Path $TestDrive -ComputerName localhost -Wait -Verbose -Force
            } | Should not throw

            $filter = "system.webServer/staticContent/mimeMap[@fileExtension='{0}' and @mimeType='{1}']" -f `
                $configData.NonNodeData.PesterFileExtension, $configData.NonNodeData.PesterMimeType
            ((Get-WebConfiguration -PSPath $ConstDefaultConfigurationPath -Filter $filter) | Measure-Object).Count | should be 0
        }

        It 'Removing a non existing MimeType' {
            {
                & "$($script:DSCResourceName)_RemoveDummyMime" -OutputPath $TestDrive
                Start-DscConfiguration -Path $TestDrive -ComputerName localhost -Wait -Verbose -Force
            } | Should not throw
        }

        It 'Adding to a nested path a Mime Type already existing in the configuration hierarchy' {
            $node = (Get-WebConfiguration -PSPath $ConstDefaultConfigurationPath -Filter "system.webServer/staticContent/mimeMap") | Select-Object -First 1

            $configData = @{
                AllNodes    = @();
                NonNodeData =
                @{
                    ConfigurationPath = $tempVirtualDirectoryIisPath
                    FileExtension     = $node.fileExtension
                    MimeType          = $node.mimeType
                }
            }

            {
                & "$($script:DSCResourceName)_AddMimeTypeNestedPath" -OutputPath $TestDrive -ConfigurationData $configData
                Start-DscConfiguration -Path $TestDrive -ComputerName localhost -Wait -Verbose -Force
            } | Should not throw

            $filter = "system.webServer/staticContent/mimeMap[@fileExtension='{0}' and @mimeType='{1}']" -f `
                $configData.NonNodeData.fileExtension, $configData.NonNodeData.mimeType
            $expected = ((Get-WebConfiguration -PSPath $tempVirtualDirectoryIisPath -Filter $filter) | Measure-Object).Count

            $expected | Should Be 1
        }

        It 'Adding to a nested path a Mime Type not existing in the configuration hierarchy' {
            $configData = @{
                AllNodes    = @();
                NonNodeData =
                @{
                    ConfigurationPath = $tempVirtualDirectoryIisPath
                    FileExtension     = 'PesterDummy3'
                    MimeType          = 'text/dummy'
                }
            }

            {
                & "$($script:DSCResourceName)_AddMimeTypeNestedPath" -OutputPath $TestDrive -ConfigurationData $configData
                Start-DscConfiguration -Path $TestDrive -ComputerName localhost -Wait -Verbose -Force
            } | Should not throw

            $filter = "system.webServer/staticContent/mimeMap[@fileExtension='{0}' and @mimeType='{1}']" -f `
                $configData.NonNodeData.fileExtension, $configData.NonNodeData.mimeType
            $expected = ((Get-WebConfiguration -PSPath $tempVirtualDirectoryIisPath -Filter $filter) | Measure-Object).Count

            $expected | Should Be 1
        }

        It 'Adding to a nested path a Mime Type already existing in the configuration hierarchy with a different value' {
            $node = (Get-WebConfiguration -PSPath $ConstDefaultConfigurationPath -Filter "system.webServer/staticContent/mimeMap") | Select-Object -Skip 1 -First 1

            $configData = @{
                AllNodes    = @();
                NonNodeData =
                @{
                    ConfigurationPath = $tempVirtualDirectoryIisPath
                    FileExtension     = $node.fileExtension
                    MimeType          = 'text/dummy'
                }
            }

            {
                & "$($script:DSCResourceName)_AddMimeTypeNestedPath" -OutputPath $TestDrive -ConfigurationData $configData
                Start-DscConfiguration -Path $TestDrive -ComputerName localhost -Wait -Verbose -Force -ErrorAction Stop
            } | Should Throw
        }

        It 'Removing from a nested path a Mime Type already existing in the configuration hierarchy' {
            $node = (Get-WebConfiguration -PSPath $ConstDefaultConfigurationPath -Filter "system.webServer/staticContent/mimeMap") | Select-Object -Skip 2 -First 1

            $configData = @{
                AllNodes    = @();
                NonNodeData =
                @{
                    ConfigurationPath = $tempVirtualDirectoryIisPath
                    FileExtension     = $node.fileExtension
                    MimeType          = $node.mimeType
                }
            }

            {
                & "$($script:DSCResourceName)_RemoveMimeTypeNestedPath" -OutputPath $TestDrive -ConfigurationData $configData
                Start-DscConfiguration -Path $TestDrive -ComputerName localhost -Wait -Verbose -Force
            } | Should not throw

            $filter = "system.webServer/staticContent/mimeMap[@fileExtension='{0}' and @mimeType='{1}']" -f `
                $configData.NonNodeData.fileExtension, $configData.NonNodeData.mimeType
            $expected = ((Get-WebConfiguration -PSPath $tempVirtualDirectoryIisPath -Filter $filter) | Measure-Object).Count

            $expected | Should Be 0
        }

        It 'Removing from a nested path a Mime Type not existing in the configuration hierarchy' {
            $configData = @{
                AllNodes    = @();
                NonNodeData =
                @{
                    ConfigurationPath = $tempVirtualDirectoryIisPath
                    FileExtension     = 'PesterDummy4'
                    MimeType          = 'text/dummy'
                }
            }

            {
                & "$($script:DSCResourceName)_RemoveMimeTypeNestedPath" -OutputPath $TestDrive -ConfigurationData $configData
                Start-DscConfiguration -Path $TestDrive -ComputerName localhost -Wait -Verbose -Force
            } | Should not throw

            $filter = "system.webServer/staticContent/mimeMap[@fileExtension='{0}' and @mimeType='{1}']" -f `
                $configData.NonNodeData.fileExtension, $configData.NonNodeData.mimeType
            $expected = ((Get-WebConfiguration -PSPath $tempVirtualDirectoryIisPath -Filter $filter) | Measure-Object).Count

            $expected | Should Be 0
        }
    }
    #endregion
}
finally
{
    #region FOOTER
    Restore-WebConfiguration -Name $tempName
    Remove-WebConfigurationBackup -Name $tempName

    Remove-Item -Path $tempVirtualDirectoryPhysicalPath -Recurse -Force

    Restore-TestEnvironment -TestEnvironment $TestEnvironment
    #endregion
}
