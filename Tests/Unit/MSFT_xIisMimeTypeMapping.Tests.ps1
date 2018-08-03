
$script:DSCModuleName = 'xWebAdministration'
$script:DSCResourceName = 'MSFT_xIisMimeTypeMapping'

#region HEADER

$moduleRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $Script:MyInvocation.MyCommand.Path))
if ( (-not (Test-Path -Path (Join-Path -Path $moduleRoot -ChildPath 'DSCResource.Tests'))) -or `
     (-not (Test-Path -Path (Join-Path -Path $moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1'))) )
{
    & git @('clone','https://github.com/PowerShell/DscResource.Tests.git',(Join-Path -Path $moduleRoot -ChildPath '\DSCResource.Tests\'))
}

Import-Module (Join-Path -Path $moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1') -Force
Import-Module (Join-Path -Path $moduleRoot -ChildPath 'Tests\MockWebAdministrationWindowsFeature.psm1')

$TestEnvironment = Initialize-TestEnvironment `
    -DSCModuleName $script:DSCModuleName `
    -DSCResourceName $script:DSCResourceName `
    -TestType Unit
#endregion HEADER


# Begin Testing
try
{
    #region Pester Tests

    InModuleScope $DSCResourceName {
        Set-Variable ConstDefaultConfigurationPath -Option Constant -Value 'MACHINE/WEBROOT/APPHOST'

        $mockMapping =
        @{
            fileExtension = 'mockFileExtension'
            mimeType = 'mockMimeType'
        }

        $defaultParameters = @{
            ConfigurationPath = ''
            Extension = 'mockExtension'
            MimeType = 'mockType'
        }

        $configPathParameters = @{
            ConfigurationPath = 'IIS:\DummyWebSite'
            Extension = 'mockExtension'
            MimeType = 'mockType'
        }

        #region testing Get-TargetResource
        Describe 'MSFT_xIisMimeTypeMapping\Get-TargetResource' {
            Mock -CommandName Assert-Module

            Context 'When MimeType is Absent' {
                Mock -CommandName Get-Mapping -MockWith { return $null }

                It 'Should return the correct hashtable' {
                    $result = Get-TargetResource @defaultParameters -Ensure 'Absent'

                    $result.Ensure            | Should Be 'Absent'
                    $result.ConfigurationPath | Should Be $ConstDefaultConfigurationPath
                    $result.Extension         | Should Be 'mockExtension'
                    $result.MimeType          | Should Be 'mockType'
                }
            }

            Context 'When MimeType is Present' {
                Mock -CommandName Get-Mapping -MockWith { return $mockMapping }

                It 'Should return the correct hashtable' {
                    $result = Get-TargetResource @configPathParameters -Ensure 'Absent'

                    $result.Ensure            | Should Be 'Present'
                    $result.ConfigurationPath | Should Be 'IIS:\DummyWebSite'
                    $result.Extension         | Should Be $mockMapping.fileExtension
                    $result.MimeType          | Should Be $mockMapping.mimeType
                }
            }
        }
        #endregion

        #region testing Set-TargetResource
        Describe 'MSFT_xIisMimeTypeMapping\Set-TargetResource' {
            Mock -CommandName Assert-Module

            Context 'When Adding a MimeType' {
                Mock -CommandName Remove-WebConfigurationProperty
                Mock -CommandName Add-WebConfigurationProperty

                Set-TargetResource @defaultParameters -Ensure 'Present'
                It 'Should call all the mocks' {
                    Assert-MockCalled -CommandName Remove-WebConfigurationProperty -Exactly -Times 0
                    Assert-MockCalled -CommandName Add-WebConfigurationProperty -Exactly -Times 1
                }
            }

            Context 'When Removing a MimeType' {
                Mock -CommandName Add-WebConfigurationProperty
                Mock -CommandName Remove-WebConfigurationProperty

                Set-TargetResource @configPathParameters -Ensure 'Absent'
                It 'Should call all the mocks' {
                    Assert-MockCalled -CommandName Add-WebConfigurationProperty -Exactly -Times 0
                    Assert-MockCalled -CommandName Remove-WebConfigurationProperty -Exactly -Times 1
                }
            }
        }
        #endregion

        #region testing Test-TargetResource
        Describe 'MSFT_xIisMimeTypeMapping\Test-TargetResource' {
            Mock -CommandName Assert-Module

            Context 'When Mapping could not be found with Ensure = to Present' {
                 Mock -CommandName Get-Mapping -MockWith { return $null }

                 $result = Test-TargetResource @defaultParameters -Ensure 'Present'
                 It 'Should return false' {
                    $result | Should Be $false
                 }
            }
            Context 'When Mapping found but Ensure = to Absent' {
                 Mock -CommandName Get-Mapping -MockWith { return $mockMapping }

                 $result = Test-TargetResource @defaultParameters -Ensure 'Absent'
                 It 'Should return false' {
                    $result | Should Be $false
                 }
            }
            Context 'When Mapping found and type exists' {
                 Mock -CommandName Get-Mapping -MockWith { return $mockMapping }

                 $result = Test-TargetResource @defaultParameters -Ensure 'Present'
                 It 'Should return true' {
                    $result | Should Be $true
                 }
            }
            Context 'When Mapping not found and type is absent' {
                 Mock -CommandName Get-Mapping -MockWith { return $null }

                 $result = Test-TargetResource @defaultParameters -Ensure 'Absent'
                 It 'Should return true' {
                    $result | Should Be $true
                 }
            }
        }
        #endregion

        #region Get-Mapping
        Describe 'MSFT_xIisMimeTypeMapping\Get-Mapping' {

            Context 'When Running Get-Mapping with Extension and Type' {
                Mock -CommandName Get-WebConfiguration -MockWith { return $mockMapping }

                $result = Get-Mapping -ConfigurationPath '' -Extension 'mockExtension' -Type 'mockType'
                It 'should return $mockMapping' {
                    $result | Should Be $mockMapping
                }
            }
        }
        #endregion
    }
}
finally
{
    #region FOOTER
    Restore-TestEnvironment -TestEnvironment $TestEnvironment
    Remove-Module -Name MockWebAdministrationWindowsFeature
    #endregion
}
