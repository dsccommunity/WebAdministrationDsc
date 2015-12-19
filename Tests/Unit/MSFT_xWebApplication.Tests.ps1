$global:DSCModuleName = 'xWebAdministration'
$global:DSCResourceName = 'MSFT_xWebApplication'

#region HEADER
if ( (-not (Test-Path -Path '.\DSCResource.Tests\')) -or `
     (-not (Test-Path -Path '.\DSCResource.Tests\TestHelper.psm1')) )
{
    & git @('clone','https://github.com/PowerShell/DscResource.Tests.git')
}
else
{
    & git @('-C',(Join-Path -Path (Get-Location) -ChildPath '\DSCResource.Tests\'),'pull')
}
Import-Module .\DSCResource.Tests\TestHelper.psm1 -Force
$TestEnvironment = Initialize-TestEnvironment `
    -DSCModuleName $Global:DSCModuleName `
    -DSCResourceName $Global:DSCResourceName `
    -TestType Unit
#endregion

try
{
    InModuleScope -ModuleName $global:DSCResourceName -ScriptBlock {
        $MockParameters = @{
            Website       = 'MockSite'
            Name          = 'MockApp'
            WebAppPool    = 'MockPool'
            PhysicalPath  = 'C:\MockSite\MockApp'
        }

        Describe "$global:DSCResourceName\CheckDependencies" {
            Context 'WebAdminstration module is not installed' {
                Mock -CommandName Get-Module -MockWith {
                    return $null
                }

                It 'should throw an error' {
                    {
                        CheckDependencies
                    } | Should Throw 'Please ensure that WebAdministration module is installed.'
                }
            }
        }


        Describe "$global:DSCResourceName\Get-TargetResource" {
            Context 'Absent should return correctly' {
                Mock -CommandName Get-WebApplication -MockWith {
                    return $null
                }

                It 'should return Absent' {
                    $Result = Get-TargetResource @MockParameters
                    $Result.Ensure | Should Be 'Absent'
                }
            }

            Context "Present should return correctly" {
                Mock -CommandName Get-WebApplication -MockWith {
                    return @{
                        ApplicationPool = $MockParameters.WebAppPool
                        PhysicalPath = $MockParameters.PhysicalPath
                        Count = 1
                    }
                }

                It 'should return Present' {
                    $Result = Get-TargetResource @MockParameters
                    $Result.Ensure | Should Be 'Present'
                }
            }
        }


        Describe "how $global:DSCResourceName\Test-TargetResource responds to Ensure = 'Absent'" {
            Context 'Web Application does not exist' {
                Mock -CommandName Get-WebApplication -MockWith {
                    return $null
                }

                It 'should return True' {
                    $Result = Test-TargetResource -Ensure 'Absent' @MockParameters
                    $Result | Should Be $true
                }

            }

            Context 'Web Application exists' {
                Mock -CommandName Get-WebApplication -MockWith {
                    return @{Count = 1}
                }

                It 'should return False' {
                    $Result = Test-TargetResource -Ensure 'Absent' @MockParameters
                    $Result | Should Be $false
                }
            }
        }


        Describe "how $global:DSCResourceName\Test-TargetResource responds to Ensure = 'Present'" {
            Context 'Web Application does not exist' {
                Mock -CommandName Get-WebApplication -MockWith {
                    return $null
                }

                It 'should return False' {
                    $Result = Test-TargetResource -Ensure 'Present' @MockParameters
                    $Result | Should Be $false
                }
            }

            Context 'Web Application exists and is in the desired state' {
                Mock -CommandName Get-WebApplication -MockWith {
                    return @{
                        ApplicationPool = $MockParameters.WebAppPool
                        PhysicalPath = $MockParameters.PhysicalPath
                        Count = 1
                    }
                }

                It 'should return True' {
                    $Result = Test-TargetResource -Ensure 'Present' @MockParameters
                    $Result | Should Be $true
                }
            }

            Context 'Web Application exists but has a different WebAppPool' {
                Mock -CommandName Get-WebApplication -MockWith {
                    return @{
                        ApplicationPool = 'MockPoolOther'
                        PhysicalPath = $MockParameters.PhysicalPath
                        Count = 1
                    }
                }

                It 'should return False' {
                    $Result = Test-TargetResource -Ensure 'Present' @MockParameters
                    $Result | Should Be $False
                }
            }

            Context 'Web Application exists but has a different PhysicalPath' {
                Mock -CommandName Get-WebApplication -MockWith {
                    return @{
                        ApplicationPool = $MockParameters.WebAppPool
                        PhysicalPath = 'C:\MockSite\MockAppOther'
                        Count = 1
                    }
                }

                It 'should return False' {
                    $Result = Test-TargetResource -Ensure 'Present' @MockParameters
                    $Result | Should Be $False
                }
            }
        }


        Describe "how $global:DSCResourceName\Set-TargetResource responds to Ensure = 'Absent'" {
            Context 'Web Application exists' {
                Mock -CommandName Remove-WebApplication

                It "should call expected mocks" {
                    $Result = Set-TargetResource -Ensure 'Absent' @MockParameters
                    Assert-MockCalled -CommandName Remove-WebApplication -Exactly 1
                }
            }
        }


        Describe "how $global:DSCResourceName\Set-TargetResource responds to Ensure = 'Present'" {
            Context 'Web Application does not exist' {
                Mock -CommandName Get-WebApplication -MockWith {
                    return $null
                }

                Mock -CommandName New-WebApplication

                It "should call expected mocks" {
                    $Result = Set-TargetResource -Ensure 'Present' @MockParameters
                    Assert-MockCalled -CommandName Get-WebApplication -Exactly 1
                    Assert-MockCalled -CommandName New-WebApplication -Exactly 1
                }
            }

            Context 'Web Application exists but has a different WebAppPool' {
                Mock -CommandName Get-WebApplication -MockWith {
                    return @{
                        ApplicationPool = 'MockPoolOther'
                        PhysicalPath = $MockParameters.PhysicalPath
                        ItemXPath = ("/system.applicationHost/sites/site[@name='{0}']/application[@path='/{1}']" -f $MockParameters.Website, $MockParameters.Name)
                        Count = 1
                    }
                }

                Mock -CommandName Set-WebConfigurationProperty

                It "should call expected mocks" {
                    $Result = Set-TargetResource -Ensure 'Present' @MockParameters

                    Assert-MockCalled -CommandName Get-WebApplication -Exactly 1
                    Assert-MockCalled -CommandName Set-WebConfigurationProperty -Exactly 1
                }

            }

            Context 'Web Application exists but has a different PhysicalPath' {

                Mock -CommandName Get-WebApplication -MockWith {
                    return @{
                        ApplicationPool = $MockParameters.WebAppPool
                        PhysicalPath = 'C:\MockSite\MockAppOther'
                        ItemXPath = ("/system.applicationHost/sites/site[@name='{0}']/application[@path='/{1}']" -f $MockParameters.Website, $MockParameters.Name)
                        Count = 1
                    }
                }

                Mock -CommandName Set-WebConfigurationProperty

                It "should call expected mocks" {

                    $Result = Set-TargetResource -Ensure 'Present' @MockParameters

                    Assert-MockCalled -CommandName Get-WebApplication -Exactly 1
                    Assert-MockCalled -CommandName Set-WebConfigurationProperty -Exactly 1
                }
            }
        }
    }
}
finally
{
    #region FOOTER
    Restore-TestEnvironment -TestEnvironment $TestEnvironment
    #endregion
}
