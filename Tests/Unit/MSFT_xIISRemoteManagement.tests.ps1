$global:DSCModuleName = 'xWebAdministration'
$global:DSCResourceName = 'MSFT_xIisRemoteManagement'

# Unit Test Template Version: 1.1.0
[String] $moduleRoot = Split-Path -Parent -Path (Split-Path -Parent -Path (Split-Path -Parent -Path $Script:MyInvocation.MyCommand.Path))
if ( (-not (Test-Path -Path (Join-Path -Path $moduleRoot -ChildPath 'DSCResource.Tests'))) -or `
(-not (Test-Path -Path (Join-Path -Path $moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1'))) )
{
    & git.exe @('clone', 'https://github.com/PowerShell/DscResource.Tests.git', (Join-Path -Path $moduleRoot -ChildPath '\DSCResource.Tests\'))
}

Import-Module (Join-Path -Path $moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1') -Force
$TestEnvironment = Initialize-TestEnvironment `
                    -DSCModuleName $global:DSCModuleName `
                    -DSCResourceName $global:DSCResourceName `
                    -TestType Unit 
#endregion HEADER

# Begin Testing
try
{
    #region Pester Tests

    InModuleScope -ModuleName $DSCResourceName -ScriptBlock {
        $MockIISRMParameters = 
        @{
            Ensure            = 'Present'
            State             = 'Started'
            WindowsCredential = $false
        }

        $MockGetIISRMParameters = 
        @{
            Ensure            = 'Present'
            State             = 'Started'
        }

        $MockGetWindowsFeatureInstalled = @{
            Installed = 'True'
        }

        $MockGetWindowsFeatureNotInstalled = @{
            Installed = 'False'
        }

        $MockServiceRunning = @{
            Status = 'Running'
        }

        $MockServiceStopped = @{
            Status = 'Stopped'
        }

        $MockWindowsCredentialDisabled = @{
            RequiresWindowsCredentials = '0'
        }

        $MockWindowsCredentialEnabled = @{
            RequiresWindowsCredentials = '1'
        }

        Describe -Name "$global:DSCResourceName\Assert-Module" -Fixture {
            Context -Name 'WebAdminstration module is not installed' -Fixture {
                Mock -ModuleName Helper -CommandName Get-Module -MockWith {
                    return $null
                }

                It -name 'should throw an error' -test {
                    {
                        Assert-Module 
                    } | 
                    Should Throw
                }
            }
        }
        
        Describe -Name "$global:DSCResourceName\Get-TargetResource" -Fixture {
            Mock -CommandName Get-WindowsFeature `
            -ParameterFilter {
                $Name -eq 'Web-Server'
            } `
            -MockWith {
                return $MockGetWindowsFeatureInstalled 
            }

            Context -Name 'Correct hashtable is returned' -Fixture {
                Mock -CommandName Get-WindowsFeature `
                -MockWith {
                    return $MockGetWindowsFeatureInstalled
                }

                Mock -CommandName Get-Service `
                -MockWith {
                    return $MockServiceRunning
                }

                Mock -CommandName Get-ItemProperty `
                -MockWith {
                    return $MockWindowsCredentialDisabled
                }

                $result = Get-TargetResource @MockGetIISRMParameters

                It -name 'should call Get-WindowsFeature twice' -test {
                    Assert-MockCalled -CommandName Get-WindowsFeature -Exactly -Times 2
                }

                It -name 'should call Get-Service once' -test {
                    Assert-MockCalled -CommandName Get-Service -Exactly -Times 1
                }

                It -name 'should call Get-ItemProperty once' -test {
                    Assert-MockCalled -CommandName Get-ItemProperty -Exactly -Times 1
                }

                It -name 'should return State' -test {
                    $result.State | Should Be 'Started'
                }

                It -name 'should return Ensure' -test {
                    $result.Ensure | Should Be 'Present'
                }

                It -name 'should return WindowsCredential' -test {
                    $result.WindowsCredential | Should Be '0'
                }
            }
        }

        Describe -Name "$global:DSCResourceName\Test-TargetResource" -Fixture {
            Mock -CommandName Get-WindowsFeature `
            -ParameterFilter {
                $Name -eq 'Web-Server'
            } `
            -MockWith {
                return $MockGetWindowsFeatureInstalled 
            }

            Context -Name 'All settings are correct' -Fixture {
                Mock -CommandName Get-WindowsFeature `
                -MockWith {
                    return $MockGetWindowsFeatureInstalled
                }
                
                Mock -CommandName Get-Service `
                -MockWith {
                    return $MockServiceRunning
                }

                Mock -CommandName Get-ItemProperty `
                -MockWith {
                    return $MockWindowsCredentialDisabled
                }
                
                $result = Test-TargetResource @MockIISRMParameters

                It -name 'Should return true' -test {
                    $result | Should be $true
                }
            }
            
            Context -Name 'All Settings are incorrect' -Fixture {
                Mock -CommandName Get-WindowsFeature `
                -MockWith {
                    return $MockGetWindowsFeatureNotInstalled
                }
                
                Mock -CommandName Get-Service `
                -MockWith {
                    return $MockServiceStopped
                }

                Mock -CommandName Get-ItemProperty `
                -MockWith {
                    return $MockWindowsCredentialEnabled
                }

                Mock -CommandName Get-ItemProperty `
                -MockWith {
                    return $MockWindowsCredentialDisabled
                }

                $result = Test-TargetResource @MockIISRMParameters

                It -name 'Should return true' -test {
                    $result | Should be $false
                }
            }

            Context -Name 'Check State should return false' -Fixture {
                Mock -CommandName Get-WindowsFeature `
                -MockWith {
                    return $MockGetWindowsFeatureInstalled
                }
                
                Mock -CommandName Get-Service `
                -MockWith {
                    return $MockServiceStopped
                }

                Mock -CommandName Get-ItemProperty `
                -MockWith {
                    return $MockWindowsCredentialDisabled
                }

                $result = Test-TargetResource @MockIISRMParameters

                It -name 'Should return false' -test {
                    $result | Should be $false
                }
            }

            Context -Name 'Check Ensure should return false' -Fixture {
                Mock -CommandName Get-WindowsFeature `
                -MockWith {
                    return $MockGetWindowsFeatureNotInstalled
                }
                
                Mock -CommandName Get-Service `
                -MockWith {
                    return $MockServiceRunning
                }

                Mock -CommandName Get-ItemProperty `
                -MockWith {
                    return $MockWindowsCredentialDisabled
                }

                $result = Test-TargetResource @MockIISRMParameters

                It -name 'Should return false' -test {
                    $result | Should be $false
                }

            }

            Context -Name 'Check WindowsCredential should return false' -Fixture {
                Mock -CommandName Get-WindowsFeature `
                -MockWith {
                    return $MockGetWindowsFeatureNotInstalled
                }
                
                Mock -CommandName Get-Service `
                -MockWith {
                    return $MockServiceRunning
                }

                Mock -CommandName Get-ItemProperty `
                -MockWith {
                    return $MockWindowsCredentialDisabled
                }

                $result = Test-TargetResource @MockIISRMParameters

                It -name 'Should return false' -test {
                    $result | Should be $false
                }

            }
        }

        Describe -Name "$global:DSCResourceName\Set-TargetResource" -Fixture {
            Mock -CommandName Get-WindowsFeature `
            -ParameterFilter {
                $Name -eq 'Web-Server'
            } `
            -MockWith {
                return $MockGetWindowsFeatureInstalled 
            }

            Context -Name 'All Settings are incorrect' -Fixture {
                Mock -CommandName Get-WindowsFeature `
                -MockWith {
                    return $MockGetWindowsFeatureNotInstalled
                }
                
                Mock -CommandName Get-Service `
                -MockWith {
                    return 'Stopped'
                }

                Mock -CommandName Get-ItemProperty `
                -MockWith {
                    return $MockWindowsCredentialEnabled
                }
                
                Mock -CommandName Import-Module
                Mock -CommandName Install-WindowsFeature
                Mock -CommandName Set-Service 
                Mock -CommandName Start-Service
                Mock -CommandName Set-ItemProperty
                Mock -CommandName Restart-Service
                
                $result = Set-TargetResource @MockIISRMParameters

                It -name 'should call all the mocks' -test {
                    Assert-MockCalled -CommandName Install-WindowsFeature -Exactly -Times 1
                    Assert-MockCalled -CommandName Set-Service -Exactly -Times 1
                    Assert-MockCalled -CommandName Start-Service -Exactly -Times 1
                    Assert-MockCalled -CommandName Restart-Service -Exactly -Times 1
                    Assert-MockCalled -CommandName Set-ItemProperty -Exactly -Times 2
                }
            }

            Context -Name 'State is incorrect' -Fixture {
                Mock -CommandName Get-WindowsFeature `
                -MockWith {
                    return $MockGetWindowsFeatureInstalled
                }
                
                Mock -CommandName Get-Service `
                -MockWith {
                    return 'Stopped'
                }

                Mock -CommandName Get-ItemProperty `
                -MockWith {
                    return $MockWindowsCredentialDisabled
                }
                
                Mock -CommandName Set-Service 
                Mock -CommandName Start-Service
                Mock -CommandName Set-ItemProperty
                
                $result = Set-TargetResource @MockIISRMParameters

                It -name 'should call all the mocks' -test {
                    Assert-MockCalled -CommandName Set-Service -Exactly -Times 1
                    Assert-MockCalled -CommandName Start-Service -Exactly -Times 1
                    Assert-MockCalled -CommandName Set-ItemProperty -Exactly -Times 1
                }
            }

            Context -Name 'Ensure is incorrect' -Fixture {
                $MockIISRMParameters = 
                @{
                    Ensure            = 'Absent'
                    State             = 'Stopped'
                    WindowsCredential = $false
                }

                Mock -CommandName Get-WindowsFeature `
                -MockWith {
                    return $MockGetWindowsFeatureInstalled
                }
                
                Mock -CommandName Get-Service `
                -MockWith {
                    return $MockServiceStopped
                }

                Mock -CommandName Get-ItemProperty `
                -MockWith {
                    return $MockWindowsCredentialDisabled
                }
                
                Mock -CommandName Import-Module
                Mock -CommandName Uninstall-WindowsFeature

                $result = Set-TargetResource @MockIISRMParameters

                It -name 'should call all the mocks' -test {
                    Assert-MockCalled -CommandName Uninstall-WindowsFeature -Exactly -Times 1
                }
            }

            Context -Name 'WindowsCredential is incorrect' -Fixture {

                Mock -CommandName Get-WindowsFeature `
                -MockWith {
                    return $MockGetWindowsFeatureInstalled
                }
                
                Mock -CommandName Get-Service `
                -MockWith {
                    return $MockServiceRunning
                }

                Mock -CommandName Get-ItemProperty `
                -MockWith {
                    return $MockWindowsCredentialEnabled
                }
                
                Mock -CommandName Set-ItemProperty
                Mock -CommandName Restart-Service

                $result = Set-TargetResource @MockIISRMParameters

                It -name 'should call all the mocks' -test {
                    Assert-MockCalled -CommandName Set-ItemProperty -Exactly -Times 1
                    Assert-MockCalled -CommandName Restart-Service -Exactly -Times 1
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
    #endregion
}
