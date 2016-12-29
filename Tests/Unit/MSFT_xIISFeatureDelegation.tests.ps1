
$script:DSCModuleName = 'xWebAdministration'
$script:DSCResourceName = 'MSFT_xIISFeatureDelegation'

#region HEADER
$script:moduleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
 if ( (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests'))) -or `
      (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1'))) )
{
    & git @('clone','https://github.com/PowerShell/DscResource.Tests.git',(Join-Path -Path $script:moduleRoot -ChildPath '\DSCResource.Tests\'))
}

Import-Module (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1') -Force

Import-Module (Join-Path -Path $script:moduleRoot -ChildPath 'Tests\MockWebAdministrationWindowsFeature.psm1')

$TestEnvironment = Initialize-TestEnvironment `
    -DSCModuleName $script:DSCModuleName `
    -DSCResourceName $script:DSCResourceName `
    -TestType Unit
#endregion

# Begin Testing
try
{
    #region Pester Tests
    InModuleScope $DSCResourceName {
        $script:DSCModuleName = 'xWebAdministration'
        $script:DSCResourceName = 'MSFT_xIISFeatureDelegation'

        #region Function Get-TargetResource
        Describe "$script:DSCResourceName\Get-TargetResource" {
            Context 'OverRideMode is present' {
                Mock Get-OverrideMode {return 'Allow'}
                $result = Get-TargetResource -SectionName 'serverRunTime' -OverRideMode 'Allow'
                $expected = @{
                    SectionName = 'serverRunTime'
                    OverrideMode = 'Allow'
                    Ensure = 'Present'
                }
                It 'should return the correct hashtable' {
                    $result.SectionName  | Should Be $expected.SectionName
                    $result.OverrideMode | Should Be $expected.OverrideMode
                }
            }
            Context 'OverRideMode is absent' {
                Mock Get-OverrideMode {return 'Deny'}
                $result = Get-TargetResource -SectionName 'serverRunTime' -OverRideMode 'Allow'
                $expected = @{
                    SectionName = 'serverRunTime'
                    OverrideMode = 'Deny'
                    Ensure = 'Absent'
                }
                It 'should return the correct hashtable' {
                    $result.SectionName  | Should Be $expected.SectionName
                    $result.OverrideMode | Should Be $expected.OverrideMode
                }
            }
        }
        #endregion


        #region Function Test-TargetResource
        Describe "$script:DSCResourceName\Test-TargetResource" {
            Context 'OverRideMode is present' {
                Mock Get-OverrideMode {return 'Allow'}
                It 'should return true' {
                    $results = Test-TargetResource -SectionName 'serverRunTime' -OverRideMode 'Allow'
                    $results | Should Be $true
                }
            }

            Context 'OverRideMode is absent' {
                Mock Get-OverrideMode {return 'Allow'}
                It 'should return true' {
                    $results = Test-TargetResource -SectionName 'serverRunTime' -OverRideMode 'Deny'
                    $results | Should Be $false
                }
            }
        }
        #endregion


        #region Function Set-TargetResource
        Describe "$script:DSCResourceName\Set-TargetResource" {
            Context 'Settings are correct' {
                # Mock -CommandName Set-WebConfiguration -ModuleName $script:DSCResourceName -MockWith {}
                Mock Set-WebConfiguration -MockWith {return $null}

                Set-TargetResource -SectionName 'mockName' -OverrideMode 'Allow'

                It 'should call all the mocks' {
                    # Assert-MockCalled -ModuleName MSFT_xIisFeatureDelegation `
                    #     -CommandName Set-WebConfiguration -Exactly 1

                    Assert-MockCalled `
                        -CommandName Set-WebConfiguration -Exactly 1
                }
            }

        }
        #endregion

        Describe "$script:DSCResourceName\Get-OverrideMode" {
            $mockWebConfigOutput = 
            @{
                Metadata = 
                @{
                    effectiveOverrideMode = $null
                }
            }
            $mockSection = 'NonExistant'
            Mock -CommandName Assert-Module -MockWith {}
        
            Context 'function is not able to find a value' {
                It 'Should throw an error on null' {
                    Mock Get-WebConfiguration { return $mockWebConfigOutput }
                    {Get-OverrideMode -Section $mockSection} | Should Throw ($LocalizedData.UnableToGetConfig -f $mockSection)
                }

                It 'Should throw an error on the wrong value' {
                    $mockWebConfigOutput.Metadata.effectiveOverrideMode = 'Wrong'
                    Mock Get-WebConfiguration { return $mockWebConfigOutput }
                    {Get-OverrideMode -Section $mockSection} | Should Throw ($LocalizedData.UnableToGetConfig -f $mockSection)
                }
            }
                        
            Context 'oMode is set correctly' {
                $mockWebConfigOutput.Metadata.effectiveOverrideMode = 'Allow'
                Mock -CommandName Get-WebConfiguration -MockWith {return $mockWebConfigOutput}
                
                $oMode = Get-OverrideMode -Section $mockSection
                It 'Should be Allow' {
                    $oMode | Should Be 'Allow'
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
