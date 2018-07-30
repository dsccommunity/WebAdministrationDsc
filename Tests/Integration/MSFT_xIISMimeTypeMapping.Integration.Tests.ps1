
$script:DSCModuleName      = 'MSFT_WebAdministration'
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

    Describe "$($script:DSCResourceName)_Integration Default tests" {
        Set-Variable ConstDefaultConfigurationPath -Option Constant -Value 'MACHINE/WEBROOT/APPHOST'

        Context "$($script:DSCResourceName)_AddMimeType" {
            $node = (Get-WebConfiguration -PSPath $ConstDefaultConfigurationPath -Filter "system.webServer/staticContent/mimeMap") | Select-Object -First 1

            $configData = @{
                AllNodes    = @();
                NonNodeData =
                @{
                    PesterFileExtension2 = $node.fileExtension
                    PesterMimeType2      = $node.mimeType
                }
            }

            It 'Should compile without error' {
                {
                    & "$($script:DSCResourceName)_AddMimeType" -OutputPath $TestDrive -ConfigurationData $configData
                    Start-DscConfiguration -Path $TestDrive -ComputerName localhost -Wait -Verbose -Force
                } | Should not throw
            }

            It 'Should be able to call Get-DscConfiguration without throwing' {
                { Get-DscConfiguration -Verbose -ErrorAction Stop } | Should Not throw
            }

            It 'Adding an existing MimeType' {
                $filter = "system.webServer/staticContent/mimeMap[@fileExtension='{0}' and @mimeType='{1}']" -f `
                    $configData.NonNodeData.PesterFileExtension2, $configData.NonNodeData.PesterMimeType2
                $expected = ((Get-WebConfiguration -PSPath $ConstDefaultConfigurationPath -Filter $filter) | Measure-Object).Count

                $expected | should be 1
            }

            It 'Should return $true when Test-DscConfiguration is run' {
                Test-DscConfiguration -Verbose | Should Be $true
            }
        }

        Context "$($script:DSCResourceName)_RemoveMimeType" {
            $node = (Get-WebConfiguration -PSPath $ConstDefaultConfigurationPath -Filter "system.webServer/staticContent/mimeMap") | Select-Object -First 1

            $configData = @{
                AllNodes    = @();
                NonNodeData =
                @{
                    PesterFileExtension = $node.fileExtension
                    PesterMimeType      = $node.mimeType
                }
            }

            It 'Should not throw when removing a MimeType' {
                {
                    & "$($script:DSCResourceName)_RemoveMimeType" -OutputPath $TestDrive -ConfigurationData $configData
                    Start-DscConfiguration -Path $TestDrive -ComputerName localhost -Wait -Verbose -Force
                } | Should not throw
            }

            It 'Should be able to call Get-DscConfiguration without throwing' {
                { Get-DscConfiguration -Verbose -ErrorAction Stop } | Should Not throw
            }

            It 'Should not find the removed MimeType' {
                $filter = "system.webServer/staticContent/mimeMap[@fileExtension='{0}' and @mimeType='{1}']" -f `
                    $configData.NonNodeData.PesterFileExtension, $configData.NonNodeData.PesterMimeType
                ((Get-WebConfiguration -PSPath $ConstDefaultConfigurationPath -Filter $filter) | Measure-Object).Count | should be 0
            }

            It 'Should return $true when Test-DscConfiguration is run' {
                Test-DscConfiguration -Verbose | Should Be $true
            }
        }

        Context "$($script:DSCResourceName)_AddMimeTypeNestedPath" {
            $configData = @{
                AllNodes    = @();
                NonNodeData =
                @{
                    ConfigurationPath = $tempVirtualDirectoryIisPath
                    FileExtension     = 'PesterDummy3'
                    MimeType          = 'text/dummy'
                }
            }

            It 'Should not throw when adding a MimeType with a nested path' {
                {
                    & "$($script:DSCResourceName)_AddMimeTypeNestedPath" -OutputPath $TestDrive -ConfigurationData $configData
                    Start-DscConfiguration -Path $TestDrive -ComputerName localhost -Wait -Verbose -Force
                } | Should not throw
            }

            It 'Should be able to call Get-DscConfiguration without throwing' {
                { Get-DscConfiguration -Verbose -ErrorAction Stop } | Should Not throw
            }

            It 'Should be 1 Adding to a nested path a Mime Type not existing in the configuration hierarchy' {
                $filter = "system.webServer/staticContent/mimeMap[@fileExtension='{0}' and @mimeType='{1}']" -f `
                    $configData.NonNodeData.fileExtension, $configData.NonNodeData.mimeType
                $expected = ((Get-WebConfiguration -PSPath $tempVirtualDirectoryIisPath -Filter $filter) | Measure-Object).Count

                $expected | Should Be 1
            }

            It 'Should return $true when Test-DscConfiguration is run' {
                Test-DscConfiguration -Verbose | Should Be $true
            }
        }

        Context "$($script:DSCResourceName)_AddMimeTypeNestedPath" {
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

            It 'Should throw when adding to a nested path a Mime Type already existing in the configuration hierarchy with a different value' {
                {
                    & "$($script:DSCResourceName)_AddMimeTypeNestedPath" -OutputPath $TestDrive -ConfigurationData $configData
                    Start-DscConfiguration -Path $TestDrive -ComputerName localhost -Wait -Verbose -Force -ErrorAction Stop
                } | Should Throw
            }

            It 'Should be able to call Get-DscConfiguration without throwing' {
                { Get-DscConfiguration -Verbose -ErrorAction Stop } | Should Not throw
            }

            It 'Should return $true when Test-DscConfiguration is run' {
                Test-DscConfiguration -Verbose | Should Be $true
            }
        }

        Context "$($script:DSCResourceName)_RemoveMimeTypeNestedPath" {
            $configData = @{
                AllNodes    = @();
                NonNodeData =
                @{
                    ConfigurationPath = $tempVirtualDirectoryIisPath
                    FileExtension     = 'PesterDummy4'
                    MimeType          = 'text/dummy'
                }
            }

            It 'Should not throw when Removing MimeTypeNestedPath' {
                {
                    & "$($script:DSCResourceName)_RemoveMimeTypeNestedPath" -OutputPath $TestDrive -ConfigurationData $configData
                    Start-DscConfiguration -Path $TestDrive -ComputerName localhost -Wait -Verbose -Force
                } | Should not throw
            }

            It 'Should be able to call Get-DscConfiguration without throwing' {
                { Get-DscConfiguration -Verbose -ErrorAction Stop } | Should Not throw
            }

            It 'Removing from a nested path a Mime Type not existing in the configuration hierarchy' {
                $filter = "system.webServer/staticContent/mimeMap[@fileExtension='{0}' and @mimeType='{1}']" -f `
                    $configData.NonNodeData.fileExtension, $configData.NonNodeData.mimeType
                $expected = ((Get-WebConfiguration -PSPath $tempVirtualDirectoryIisPath -Filter $filter) | Measure-Object).Count

                $expected | Should Be 0
            }

            It 'Should return $true when Test-DscConfiguration is run' {
                Test-DscConfiguration -Verbose | Should Be $true
            }
        }

        Context "$($script:DSCResourceName)_AddMimeTypeAtServer" {
            $configData = @{
                AllNodes    = @();
                NonNodeData =
                @{
                    ConfigurationPath = 'IIS:\'
                    FileExtension     = 'PesterDummy5'
                    MimeType          = 'text/dummy'
                }
            }

            It 'Should not throw when adding MimeTypeAtServer' {
                {
                    & "$($script:DSCResourceName)_AddMimeTypeAtServer" -OutputPath $TestDrive -ConfigurationData $configData
                    Start-DscConfiguration -Path $TestDrive -ComputerName localhost -Wait -Verbose -Force
                } | Should not throw
            }

            It 'Should be able to call Get-DscConfiguration without throwing' {
                { Get-DscConfiguration -Verbose -ErrorAction Stop } | Should Not throw
            }

            It 'Adding an exetension at the server level' {
                $filter = "system.webServer/staticContent/mimeMap[@fileExtension='{0}' and @mimeType='{1}']" -f `
                    $configData.NonNodeData.fileExtension, $configData.NonNodeData.mimeType
                $expected = ((Get-WebConfiguration -PSPath $ConstDefaultConfigurationPath -Filter $filter) | Measure-Object).Count

                $expected | should be 1
            }

            It 'Should return $true when Test-DscConfiguration is run' {
                Test-DscConfiguration -Verbose | Should Be $true
            }
        }

        Context "$($script:DSCResourceName)_RemoveMimeTypeAtServer" {
            $configData = @{
                AllNodes    = @();
                NonNodeData =
                @{
                    ConfigurationPath = 'IIS:\'
                    FileExtension     = 'PesterDummy5'
                    MimeType          = 'text/dummy'
                }
            }

            It 'Should not throw when removing MimeTypeAtServer level' {
                {
                    & "$($script:DSCResourceName)_RemoveMimeTypeAtServer" -OutputPath $TestDrive -ConfigurationData $configData
                    Start-DscConfiguration -Path $TestDrive -ComputerName localhost -Wait -Verbose -Force
                } | Should not throw
            }

            It 'Should be able to call Get-DscConfiguration without throwing' {
                { Get-DscConfiguration -Verbose -ErrorAction Stop } | Should Not throw
            }

            It 'Removing an exetension at the server level' {
                $filter = "system.webServer/staticContent/mimeMap[@fileExtension='{0}' and @mimeType='{1}']" -f `
                    $configData.NonNodeData.fileExtension, $configData.NonNodeData.mimeType
                $expected = ((Get-WebConfiguration -PSPath $ConstDefaultConfigurationPath -Filter $filter) | Measure-Object).Count

                $expected | should be 0
            }

            It 'Should return $true when Test-DscConfiguration is run' {
                Test-DscConfiguration -Verbose | Should Be $true
            }
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
