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
            Ensure = 'Present'
            State  = 'Started'
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
                    
                $result = Get-TargetResource @MockIISRMParameters
               
                It -name 'should call Get-WindowsFeature twice' -test {
                    Assert-MockCalled -CommandName Get-WindowsFeature -Exactly -Times 2
                }

                It -name 'should call Get-Service once' -test {
                    Assert-MockCalled -CommandName Get-Service -Exactly -Times 1
                }
                
                It -name 'should return State' -test {
                    $result.State | Should Be 'Started'
                }
                
                It -name 'should return Ensure' -test {
                    $result.Ensure | Should Be 'Present'
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
                
                Mock -CommandName Install-WindowsFeature
                Mock -CommandName Set-Service 
                Mock -CommandName Start-Service
                Mock -CommandName Set-ItemProperty
                
                $result = Set-TargetResource @MockIISRMParameters

                It -name 'should call all the mocks' -test {
                    Assert-MockCalled -CommandName Install-WindowsFeature -Exactly -Times 1
                    Assert-MockCalled -CommandName Set-Service -Exactly -Times 1
                    Assert-MockCalled -CommandName Start-Service -Exactly -Times 1
                    Assert-MockCalled -CommandName Set-ItemProperty -Exactly -Times 1
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
                    Ensure = 'Absent'
                    State  = 'Stopped'
                }

                Mock -CommandName Get-WindowsFeature `
                -MockWith {
                    return $MockGetWindowsFeatureInstalled
                }
                
                Mock -CommandName Get-Service `
                -MockWith {
                    return 'Started'
                }
                
                Mock -CommandName Uninstall-WindowsFeature

                $result = Set-TargetResource @MockIISRMParameters

                It -name 'should call all the mocks' -test {
                    Assert-MockCalled -CommandName Uninstall-WindowsFeature -Exactly -Times 1
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
