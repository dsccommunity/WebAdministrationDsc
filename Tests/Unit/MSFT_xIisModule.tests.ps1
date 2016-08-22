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
	        Context 'context-description' {
	            It 'Should ...test-description' {
	                # test-code
	            }
	        }
	    }
	}
}
finally
{

   Restore-TestEnvironment -TestEnvironment $TestEnvironment
    
    # TODO: Other optional cleanup code goes here
    
}
