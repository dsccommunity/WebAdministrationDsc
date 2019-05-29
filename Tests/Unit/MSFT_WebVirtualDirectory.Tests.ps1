$script:DSCModuleName   = 'xWebAdministration'
$script:DSCResourceName = 'MSFT_WebVirtualDirectory'

#region HEADER
$script:moduleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
 if ( (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests'))) -or `
      (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1'))) )
{
    & git @('clone','https://github.com/PowerShell/DscResource.Tests.git',(Join-Path -Path $script:moduleRoot -ChildPath '\DSCResource.Tests\'))
}

Import-Module (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1') -Force

Import-Module (Join-Path -Path $script:moduleRoot -ChildPath 'Tests\MockWebAdministrationWindowsFeature.psm1')

$TestEnvironment = Initialize-TestEnvironment -DSCModuleName $script:DSCModuleName `
                                              -DSCResourceName $script:DSCResourceName `
                                              -TestType Unit
#endregion

try
{
    #region Pester Tests
    InModuleScope $script:DSCResourceName {
        $script:DSCResourceName = 'MSFT_WebVirtualDirectory'

        Describe "how $DSCResourceName\Get-TargetResource responds" {

            $MockParameters = @{
                Name        = 'VirtualDirectory'
                Site        = 'Site'
                Application = 'Application'
            }

            Mock -CommandName Assert-Module
            Mock -CommandName Get-WebVirtualDirectory -MockWith {return $null}

            Context 'Expected behaviour' {

                It 'Should not throw' {
                    {Get-TargetResource @MockParameters} | Should Not Throw
                }

                It 'Should call expected mocks' {
                    Assert-MockCalled -CommandName Get-WebVirtualDirectory -Exactly 1
                }
            }

            Context 'Virtual directory does not exist' {

                It 'Should return the correct values' {
                    $result = Get-TargetResource @MockParameters

                    $result.Ensure                    | Should -Be 'Absent'
                    $result.Name                      | Should -Be $MockParameters.Name
                    $result.Site                      | Should -Be $MockParameters.Site
                    $result.Application               | Should -Be $MockParameters.Application
                    $result.PhysicalPath              | Should -BeNullOrEmpty
                    $result.PhysicalPathAccessAccount | Should -BeNullOrEmpty
                    $result.PhysicalPathAccessPass    | Should -BeNullOrEmpty
                }
            }

            Context 'Virtual directory exists' {

                $MockOutput = @{
                    PhysicalPath = 'C:\somepath'
                    userName     = 'mockUser'
                    password     = 'v3ry_53CRe7P@$$'
                    Count        = 1
                }

                It 'Should return the correct values with empty credential' {
                    $testMockOutput          = $MockOutput.Clone()
                    $testMockOutput.userName = ''
                    $testMockOutput.password = ''

                    Mock -CommandName Get-WebVirtualDirectory -MockWith {return $testMockOutput}

                    $result = Get-TargetResource @MockParameters

                    $result.Ensure                    | Should -Be 'Present'
                    $result.Name                      | Should -Be $MockParameters.Name
                    $result.Site                      | Should -Be $MockParameters.Site
                    $result.Application               | Should -Be $MockParameters.Application
                    $result.PhysicalPath              | Should -Be $MockOutput.PhysicalPath
                    $result.PhysicalPathAccessAccount | Should -BeNullOrEmpty
                    $result.PhysicalPathAccessPass    | Should -BeNullOrEmpty
                }

                It 'Should return the correct values with valid credential' {
                    Mock -CommandName Get-WebVirtualDirectory -MockWith {return $MockOutput}

                    $result = Get-TargetResource @MockParameters

                    $result.Ensure                    | Should -Be 'Present'
                    $result.Name                      | Should -Be $MockParameters.Name
                    $result.Site                      | Should -Be $MockParameters.Site
                    $result.Application               | Should -Be $MockParameters.Application
                    $result.PhysicalPath              | Should -Be $MockOutput.PhysicalPath
                    $result.PhysicalPathAccessAccount | Should -Be $MockOutput.userName
                    $result.PhysicalPathAccessPass    | Should -Be $MockOutput.password
                }
            }
        }

        Describe "how $DSCResourceName\Test-TargetResource responds to Ensure = 'Absent'" {

            $MockParameters = @{
                Ensure      = 'Absent'
                Site        = 'contoso.com'
                Application = 'contosoapp'
                Name        = 'shared_directory'
            }

            $MockOutput = @{
                PhysicalPath = 'C:\inetpub\wwwroot\shared'
                Count        = 1
            }

            Mock -CommandName Assert-Module
            Mock -CommandName Get-WebVirtualDirectory -MockWith { return $MockOutput }

            Context 'Virtual directory does not exist' {

                Mock -CommandName Get-WebVirtualDirectory -MockWith { return $null }

                $result = Test-TargetResource @MockParameters

                It 'Should return True' {
                    $result | Should -Be 'True'
                }

                It 'Should call expected mocks' {
                    Assert-MockCalled -CommandName Get-WebVirtualDirectory -Exactly 1
                }
            }

            Context 'Virtual directory exists' {

                $result = Test-TargetResource @MockParameters

                It 'Should return False for Ensure set to "Absent"' {
                    $result | Should -Be 'False'
                }

                It 'Should call expected mocks' {
                    Assert-MockCalled -CommandName Get-WebVirtualDirectory -Exactly 1
                }
            }
        }

        Describe "how $DSCResourceName\Test-TargetResource responds to Ensure = 'Present'" {

            $MockParameters = @{
                Ensure      = 'Present'
                Site        = 'contoso.com'
                Application = 'contosoapp'
                Name        = 'shared_directory'
            }

            $MockOutput = @{
                PhysicalPath = 'C:\inetpub\wwwroot\shared'
                userName     = ''
                password     = ''
                Count        = 1
            }

            Mock -CommandName Assert-Module
            Mock -CommandName Get-WebVirtualDirectory -MockWith { return $MockOutput }

            Context 'Virtual directory does not exist' {

                Mock -CommandName Get-WebVirtualDirectory -MockWith { return $null }

                $result = Test-TargetResource @MockParameters

                It 'Should return False' {
                    $result | Should -Be 'False'
                }

                It 'Should call expected mocks' {
                    Assert-MockCalled -CommandName Get-WebVirtualDirectory -Exactly 1
                }
            }

            Context 'Virtual directory exists' {

                $result = Test-TargetResource @MockParameters

                It 'Should return True for Ensure set to "Present"' {
                    $result | Should -Be 'True'
                }

                It 'Should call expected mocks' {
                    Assert-MockCalled -CommandName Get-WebVirtualDirectory -Exactly 1
                }
            }

            Context 'Check PhysicalPath is different' {

                $result = Test-TargetResource @MockParameters `
                                              -PhysicalPath 'C:\differentMockFolder'

                It 'Should return False' {
                    $result | Should -Be 'False'
                }

                It 'Should call expected mocks' {
                    Assert-MockCalled -CommandName Get-WebVirtualDirectory -Exactly 1
                }
            }

            Context 'Check PhysicalPathAccessAccount is different' {

                $result = Test-TargetResource @MockParameters `
                                              -PhysicalPathAccessAccount 'MockUser'

                It 'Should return False' {
                    $result | Should -Be 'False'
                }

                It 'Should call expected mocks' {
                    Assert-MockCalled -CommandName Get-WebVirtualDirectory -Exactly 1
                }
            }

            Context 'Check PhysicalPathAccessPass is different' {

                $result = Test-TargetResource @MockParameters `
                                              -PhysicalPathAccessPass 'MockPassword'

                It 'Should return False' {
                    $result | Should -Be 'False'
                }

                It 'Should call expected mocks' {
                    Assert-MockCalled -CommandName Get-WebVirtualDirectory -Exactly 1
                }
            }
        }

        Describe "how $DSCResourceName\Set-TargetResource responds to Ensure = 'Absent'" {

            $MockParameters = @{
                Ensure      = 'Absent'
                Site        = 'contoso.com'
                Application = 'contosoapp'
                Name        = 'shared_directory'
            }

            $MockOutput = @{
                Count = 1
            }

            Mock -CommandName Assert-Module
            Mock -CommandName Get-WebVirtualDirectory -MockWith {return $MockOutput}
            Mock -CommandName Remove-Item

            Context 'Virtual directory exists' {

                Set-TargetResource @MockParameters

                It 'Should call expected mocks' {
                    Assert-MockCalled -CommandName Get-WebVirtualDirectory -Exactly 1
                    Assert-MockCalled -CommandName Remove-Item -Exactly 1
                }
            }
        }

        Describe "how $DSCResourceName\Set-TargetResource responds to Ensure = 'Present'" {

            $MockParameters = @{
                Ensure                    = 'Present'
                Site                      = 'contoso.com'
                Application               = 'contosoapp'
                Name                      = 'shared_directory'
                PhysicalPath              = 'C:\mockFolder\anotherFolder'
                PhysicalPathAccessAccount = 'MockUser'
                PhysicalPathAccessPass    = 'MockPassword'
            }

            $MockOutput = @{
                PhysicalPath = 'C:\PhysicalPath'
                userName     = ''
                password     = ''
                Count        = 1
            }

            Mock -CommandName Assert-Module

            Context 'Virtual directory does not exist' {

                Mock -CommandName Get-WebVirtualDirectory -MockWith {return $null}
                Mock -CommandName New-WebVirtualDirectory
                Mock -CommandName Set-ItemProperty

                Set-TargetResource @MockParameters

                It 'Should call expected mocks' {
                    Assert-MockCalled -CommandName Get-WebVirtualDirectory -Exactly 1
                    Assert-MockCalled -CommandName New-WebVirtualDirectory -Exactly 1
                    Assert-MockCalled -CommandName Set-ItemProperty -Exactly 3
                }
            }

            Context 'Virtual directory exists with different parameters' {

                Mock -CommandName Get-WebVirtualDirectory -MockWith {return $MockOutput}
                Mock -CommandName Set-ItemProperty

                Set-TargetResource @MockParameters

                It 'Should call expected mocks' {
                    Assert-MockCalled -CommandName Get-WebVirtualDirectory -Exactly 1
                    Assert-MockCalled -CommandName Set-ItemProperty -Exactly 3
                }
            }
        }
    }
    #endregion
}
finally
{
    #region FOOTER
    Restore-TestEnvironment -TestEnvironment $TestEnvironment
    #endregion
}
