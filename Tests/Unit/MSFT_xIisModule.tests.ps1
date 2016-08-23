#region HEADER

# Unit Test Template Version: 1.2.0
$script:moduleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
if ( (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests'))) -or `
     (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1'))) )
{
    & git @('clone','https://github.com/PowerShell/DscResource.Tests.git',(Join-Path -Path $script:moduleRoot -ChildPath '\DSCResource.Tests\'))
}

Import-Module (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1') -Force

Import-Module (Join-Path -Path $script:moduleRoot -ChildPath 'Tests\MockWebAdministrationWindowsFeature.psm1')

$TestEnvironment = Initialize-TestEnvironment `
    -DSCModuleName 'xWebAdministration' `
    -DSCResourceName 'MSFT_xIisModule' `
    -TestType Unit 

#endregion HEADER


# Begin Testing
try
{
    InModuleScope 'MSFT_xIisModule' {
        
        
        
        $mockHandler = @{
            ScriptProcessor  = 'mockScriptProcessor'
            Name             = 'mockName'
            Path             = 'mockPath'
            Modules          = 'mockModules'
            Verb             = @(
                                'MockVerb1'
                                'MockVerb2'
                            ) 
            
        }
        
        Describe 'Get-TargetResource' {
            
            BeforeAll {
                Mock -CommandName Assert-Module -MockWith {}
                
                $mockGetParams = @{
                    Path = 'mockPath'
                    Name = 'mockName'
                    RequestPath = 'mockRequestPath'
                    Verb = @(
                        'MockVerb1'
                        'MockVerb2'
                    )
                }
            }

            Context 'Handler cannot be found' {
                Mock -CommandName Get-IisHandler -MockWith { return $null }
                
                $result = Get-TargetResource @mockGetParams
                
                It 'Should return the correct values for when the Handler is Absent' {
                    $result.Ensure | Should Be 'Absent'
                    $result.Path | Should Be $mockGetParams.Path
                    $result.EndPointSetup | Should Be $false
                }

            }

            Context 'Handler is found without fastCgi' {
                Mock -CommandName Get-IisHandler -MockWith { return $mockHandler }
                
                $result = Get-TargetResource @mockGetParams
                
                It 'Should return the correct values for when the Handler is found and does not use fastCgi' {
                    $result.Ensure | Should Be 'Present'
                    $result.Path | Should Be $mockHandler.ScriptProcessor
                    $result.Verb[0] | Should Be $mockHandler.Verb[0]
                    $result.EndPointSetup | Should Be $false
                }
            }
            
            Context 'Handler is found with fastCgi' {
                $mockHandler.Modules = 'FastCgiModule'

                $mockFastCgi = @{
                    FullPath = $mockHandler.ScriptProcessor   
                }

                Mock -CommandName Get-IisHandler -MockWith { return $mockHandler }
                Mock -CommandName Get-WebConfiguration -MockWith { return $mockFastCgi }
                
                $result = Get-TargetResource @mockGetParams
                
                It 'Should return the correct values for when the Handler is found and uses fastCgi' {
                    $result.Ensure | Should Be 'Present'
                    $result.Path | Should Be $mockHandler.ScriptProcessor
                    $result.Verb[1] | Should Be $mockHandler.Verb[1]
                    $result.EndPointSetup | Should Be $true
                }
                It 'Should call all the mocks' {
                    Assert-MockCalled -CommandName Get-WebConfiguration -Exactly 1
                }
            }
        }

        Describe 'Set-TargetResource' {
            BeforeAll {
                Mock -CommandName Assert-Module -MockWith {}
                Mock Add-WebConfiguration -MockWith {}
                
                $mockSetParams = @{
                    Path = 'mockPath'
                    Name = 'mockName'
                    RequestPath = 'mockRequestPath'
                    Verb = @(
                        'MockVerb1'
                        'MockVerb2'
                    )
                    Ensure = 'Absent'
                    ModuleType = 'FastCgiModule'
                }
            }
            Context 'Resource is absent' {
                Mock -CommandName Remove-IisHandler -MockWith {}
                
                Set-TargetResource @mockSetParams
                
                It 'Should call all the mocks' {
                    Assert-MockCalled -CommandName Remove-IisHandler -Exactly 1
                    Assert-MockCalled -CommandName Add-WebConfiguration -Exactly 0
                }
            }
            
            Context 'Resource is present with FastCgi' {
                $mockSetParams.Ensure = 'Present'
                Mock Get-FastCgi -MockWith { return $true }
                
                Set-TargetResource @mockSetParams
                
                It 'Should call all the mocks' {
                    Assert-MockCalled -CommandName Add-WebConfiguration -Exactly 1
                    Assert-MockCalled -CommandName Get-FastCgi -Exactly 1
                }
            }
            
            Context 'Resource is present without FastCgi set' {
                $mockSetParams.Ensure = 'Present'
                Mock Get-FastCgi -MockWith { return $false }
                
                Set-TargetResource @mockSetParams
                
                It 'Should call all the mocks' {
                    Assert-MockCalled -CommandName Add-WebConfiguration -Exactly 2
                    Assert-MockCalled -CommandName Get-FastCgi -Exactly 1
                }
            }
        }
        
        Describe 'Test-TargetResource' {
            $mockTestParams = @{
                Path = 'mockPath'
                Name = 'mockName'
                RequestPath = 'mockRequestPath'
                Verb = @(
                    'MockVerb1'
                    'MockVerb2'
                )
                Ensure = 'Present'
                ModuleType = 'FastCgiModule'
            }
            $mockModuleSettings = @{
                Path = 'mockPath'
                Name = 'mockName'
                RequestPath = 'mockRequestPath'
                Verb = @(
                    'MockVerb1'
                    'MockVerb2'
                )
                Ensure = 'Present'
                ModuleType = 'FastCgiModule'
                EndPointSetup = $true
            }
            
            Context 'Settings are all correct' {
                Mock -CommandName Get-TargetResource -MockWith { return $mockModuleSettings }
                
                It 'Should return $true because all settings are correct' {
                    Test-TargetResource @mockTestParams | Should Be $true
                }
                It 'Should return $true because module is Absent and Ensure is set to Absent' {
                    $mockTestParams.Ensure = 'Absent'
                    $mockModuleSettings.Ensure = 'Absent'
                    Test-TargetResource @mockTestParams | Should Be $true
                }
            }
            
            Context 'Settings are incorrect' {
                Mock -CommandName Get-TargetResource -MockWith { return $mockModuleSettings }
                
                It 'Should return $false due to Ensure being set to Absent but module being Present' {
                    $mockTestParams.Ensure = 'Absent'
                    $mockModuleSettings.Ensure = 'Present'
                    Test-TargetResource @mockTestParams | Should Be $false
                }
                It 'Should return $false due to Ensure being set to Present but module being Absent' {
                    $mockTestParams.Ensure = 'Present'
                    $mockModuleSettings.Ensure = 'Absent'
                    Test-TargetResource @mockTestParams | Should Be $false
                }
                It 'Should return $false due to incorrect path' {
                    $mockModuleSettings.Ensure = 'Present'
                    $mockTestParams.Path = 'BadPath'
                    Test-TargetResource @mockTestParams | Should Be $false
                }
                It 'Should return $false due to incorrect Requestpath' {
                    $mockTestParams.Path = 'mockPath'
                    $mockTestParams.RequestPath = 'BadPath'
                    Test-TargetResource @mockTestParams | Should Be $false
                }
                It 'Should return $false due to incorrect Verb' {
                    $mockTestParams.RequestPath = 'mockRequestPath'
                    $mockTestParams.Verb[1] = 'BadVerb'
                    Test-TargetResource @mockTestParams | Should Be $false
                }
                It 'Should return $false due to incorrect FastCgi' {
                    $mockTestParams.Verb[1] = 'MockVerb2'
                    $mockModuleSettings.EndPointSetup = $false
                    Test-TargetResource @mockTestParams | Should Be $false
                }
                It 'Should return $false due to extra verb' {
                    $mockTestParams.Verb += 'MockVerb3'
                    $mockModuleSettings.EndPointSetup = $true
                    Test-TargetResource @mockTestParams | Should Be $false
                }
            }
        }
        
        Describe 'Get-IisSitePath' {
            It 'Should return IIS:\' {
                Get-IisSitePath | Should Be 'IIS:\'
            }
            
            $expected = 'IIS:\sites\mockSite'
            It 'Should return expected value' {
                Get-IisSitePath -SiteName 'mockSite' | Should Be $expected
            }
        }
        
        Describe 'Get-IisHandler' {

            Mock -CommandName Get-WebConfiguration -MockWith { return $mockHandler }
            
            $result = Get-IisHandler -Name 'mockName'
            
            It 'Should return the expected value' {
                $result | Should Be $mockHandler
            }
            It 'Should call all the mocks' {
                Assert-MockCalled -CommandName Get-WebConfiguration -Exactly 1
            }
        }
        
        Describe 'Remove-IisHandler' {
            Mock -CommandName Clear-WebConfiguration -MockWith {}
            
            Remove-IisHandler -Name 'MockName'
            
            It 'Should call all the mocks' {
                Assert-MockCalled -CommandName Clear-WebConfiguration
            } 
        }
        
        Describe 'Get-FastCgi' {
            Mock -CommandName Get-IisHandler -MockWith { return $mockHandler }
            
            
            It 'Should return $true because it has FastCgi' {
                Mock -CommandName Get-WebConfiguration -MockWith { return @{ FullPath = $mockHandler.ScriptProcessor } }
                Get-FastCgi -Name 'mockName' | Should be $true
            }
            
            It 'Should return $false because it does not have FastCgi' {
                Mock -CommandName Get-WebConfiguration -MockWith { return @{ FullPath = 'noFastCgi' } }
                Get-FastCgi -Name 'mockName' | Should be $false
            }
        }
    }
}
finally
{

    Restore-TestEnvironment -TestEnvironment $TestEnvironment
    
}
