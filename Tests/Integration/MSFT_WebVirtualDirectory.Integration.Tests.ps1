$script:DSCModuleName   = 'xWebAdministration'
$script:DSCResourceName = 'MSFT_WebVirtualDirectory'

#region HEADER

# Integration Test Template Version: 1.1.0
$script:moduleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
if ( (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests'))) -or `
     (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1'))) )
{
    & git @('clone','https://github.com/PowerShell/DscResource.Tests.git',(Join-Path -Path $script:moduleRoot -ChildPath '\DSCResource.Tests\'))
}

Import-Module (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1') -Force
$TestEnvironment = Initialize-TestEnvironment -DSCModuleName $script:DSCModuleName `
                                              -DSCResourceName $script:DSCResourceName `
                                              -TestType Integration
#endregion

[string] $tempName = "$($script:DSCResourceName)_" + (Get-Date).ToString('yyyyMMdd_HHmmss')

try
{
    $null = Backup-WebConfiguration -Name $tempName

    # Now that xWebAdministration should be discoverable load the configuration data
    $ConfigFile = Join-Path -Path $PSScriptRoot -ChildPath "$($script:DSCResourceName).config.ps1"
    . $ConfigFile

    $DSCConfig = Import-LocalizedData -BaseDirectory $PSScriptRoot -FileName "$($script:DSCResourceName).config.psd1"

    Describe "$($script:DSCResourceName)_Initialize" {
        Invoke-Expression -Command "$($script:DSCResourceName)_Initialize -ConfigurationData `$DSCConfig -OutputPath `$TestDrive"
        Start-DscConfiguration -Path $TestDrive -ComputerName localhost -Wait -Verbose -Force
    }

    Describe "$($script:DSCResourceName)_Present" {

        #region DEFAULT TESTS
        Context 'Default tests' {

            It 'Should compile without throwing' {
                {
                    Invoke-Expression -Command "$($script:DSCResourceName)_Present -ConfigurationData `$DSCConfig -OutputPath `$TestDrive"
                    Start-DscConfiguration -Path $TestDrive -ComputerName localhost -Wait -Verbose -Force
                } | Should Not Throw
            }

            It 'Should be able to call Get-DscConfiguration without throwing' {
                { Get-DscConfiguration -Verbose -ErrorAction Stop } | Should Not Throw
            }

            It 'Should return True when calling Test-DscConfiguration' {
                $result = Test-DscConfiguration -Verbose -ErrorAction Stop

                $result | Should -Be 'True'
            }
        }
        #endregion

        Context 'Verify resources were created with correct settings' {

            It 'Should create a WebVirtualDirectory at site root' {
                # Build results to test
                $result = Get-WebVirtualDirectory -Site $DSCConfig.AllNodes.Website `
                                                  -Name $DSCConfig.AllNodes.WebVirtualDirectory

                # Test virtual directory settings are correct
                $result.path         | Should -Be "/$($DSCConfig.AllNodes.WebVirtualDirectory)"
                $result.physicalPath | Should -Be $DSCConfig.AllNodes.PhysicalPath1
            }

            It 'Should create a WebVirtualDirectory at site folder' {
                # Build results to test
                $result = Get-WebVirtualDirectory -Site $DSCConfig.AllNodes.Website `
                                                  -Name "$($DSCConfig.AllNodes.FolderName)/$($DSCConfig.AllNodes.WebVirtualDirectory)"

                # Test virtual directory settings are correct
                $result.path         | Should -Be "/$($DSCConfig.AllNodes.FolderName)/$($DSCConfig.AllNodes.WebVirtualDirectory)"
                $result.physicalPath | Should -Be $DSCConfig.AllNodes.PhysicalPath2
                $result.username     | Should -Be $DSCConfig.AllNodes.PhysicalPathUserName1
                $result.password     | Should -Be $DSCConfig.AllNodes.PhysicalPathPassword1
            }

            It 'Should create a WebVirtualDirectory at WebApplication root' {
                # Build results to test
                $result = Get-WebVirtualDirectory -Site $DSCConfig.AllNodes.Website `
                                                  -Application $DSCConfig.AllNodes.WebApplication `
                                                  -Name $DSCConfig.AllNodes.WebVirtualDirectory

                # Test virtual directory settings are correct
                $result.path         | Should -Be "/$($DSCConfig.AllNodes.WebVirtualDirectory)"
                $result.physicalPath | Should -Be $DSCConfig.AllNodes.PhysicalPath3
                $result.username     | Should -Be $DSCConfig.AllNodes.PhysicalPathUserName2
                $result.password     | Should -Be $DSCConfig.AllNodes.PhysicalPathPassword2
            }

            It 'Should create a WebVirtualDirectory at folder in the WebApplication' {
                # Build results to test
                $result = Get-WebVirtualDirectory -Site $DSCConfig.AllNodes.Website `
                                                  -Application $DSCConfig.AllNodes.WebApplication `
                                                  -Name "$($DSCConfig.AllNodes.FolderName)/$($DSCConfig.AllNodes.WebVirtualDirectory)"

                # Test virtual directory settings are correct
                $result.path            | Should Be "/$($DSCConfig.AllNodes.FolderName)/$($DSCConfig.AllNodes.WebVirtualDirectory)"
                $result.physicalPath    | Should Be $DSCConfig.AllNodes.PhysicalPath4
            }
        }
    }

    Describe "$($script:DSCResourceName)_Absent" {

        #region DEFAULT TESTS
        Context 'Default tests' {

            It 'Should compile without throwing' {
                {
                    Invoke-Expression -Command "$($script:DSCResourceName)_Absent -ConfigurationData `$DSCConfig -OutputPath `$TestDrive"
                    Start-DscConfiguration -Path $TestDrive -ComputerName localhost -Wait -Verbose -Force
                } | Should Not Throw
            }

            It 'Should be able to call Get-DscConfiguration without throwing' {
                { Get-DscConfiguration -Verbose -ErrorAction Stop } | Should Not throw
            }

            It 'Should return True when calling Test-DscConfiguration' {
                $result = Test-DscConfiguration -Verbose -ErrorAction Stop

                $result | Should -Be 'True'
            }
        }
        #endregion

        Context 'Verify resources were removed' {

            It 'Should remove a WebVirtualDirectory at site root' {
                # Build results to test
                $result = Get-WebVirtualDirectory -Site $DSCConfig.AllNodes.Website `
                                                  -Name $DSCConfig.AllNodes.WebVirtualDirectory

                # Test virtual directory is removed
                $result | Should -BeNullOrEmpty
            }

            It 'Should remove a WebVirtualDirectory at site folder' {
                # Build results to test
                $result = Get-WebVirtualDirectory -Site $DSCConfig.AllNodes.Website `
                                                  -Name "$($DSCConfig.AllNodes.FolderName)/$($DSCConfig.AllNodes.WebVirtualDirectory)"

                # Test virtual directory is removed
                $result | Should -BeNullOrEmpty
            }

            It 'Should remove a WebVirtualDirectory at WebApplication root' {
                # Build results to test
                $result = Get-WebVirtualDirectory -Site $DSCConfig.AllNodes.Website `
                                                  -Application $DSCConfig.AllNodes.WebApplication `
                                                  -Name $DSCConfig.AllNodes.WebVirtualDirectory

                # Test virtual directory is removed
                $result | Should -BeNullOrEmpty
            }

            It 'Should remove a WebVirtualDirectory at folder in the WebApplication' {
                # Build results to test
                $result = Get-WebVirtualDirectory -Site $DSCConfig.AllNodes.Website `
                                                  -Application $DSCConfig.AllNodes.WebApplication `
                                                  -Name "$($DSCConfig.AllNodes.FolderName)/$($DSCConfig.AllNodes.WebVirtualDirectory)"

                # Test virtual directory is removed
                $result | Should -BeNullOrEmpty
            }
        }
    }

    Describe "$($script:DSCResourceName)_Uninitialize" {
        Invoke-Expression -Command "$($script:DSCResourceName)_Initialize -Ensure 'Absent' -ConfigurationData `$DSCConfig -OutputPath `$TestDrive"
        Start-DscConfiguration -Path $TestDrive -ComputerName localhost -Wait -Verbose -Force
    }
}
finally
{
    #region FOOTER
    Restore-WebConfiguration -Name $tempName
    Remove-WebConfigurationBackup -Name $tempName
    Restore-TestEnvironment -TestEnvironment $TestEnvironment
    #endregion
}
