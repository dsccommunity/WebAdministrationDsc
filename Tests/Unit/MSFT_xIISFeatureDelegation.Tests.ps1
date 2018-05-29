
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

        $mockAllowOverrideMode = @{
            Metadata = @{
                effectiveOverrideMode = 'Allow'
            }
        }
        $mockDenyOverrideMode = @{
            Metadata = @{
                effectiveOverrideMode = 'Deny'
            }
        }

        $allowTargetResourceParameters = @{
            Path = 'IIS:\Sites\Default Web Site'
            Filter = '/system.web/httpCookies'
            OverrideMode = 'Allow'
        }

        $denytargetResourceParameters = @{
            Path = 'IIS:\Sites\Default Web Site'
            Filter = '/system.web/httpCookies'
            OverrideMode = 'Deny'
        }

        #region Function Get-TargetResource
        Describe 'MSFT_xIISFeatureDelegation\Get-TargetResource' {
            Context 'When OverrideMode is set to Allow' {
                Mock -CommandName Get-WebConfiguration -MockWith { return $mockAllowOverrideMode }
                $result = Get-TargetResource @allowTargetResourceParameters

                It 'Should return the correct properties' {
                    $result.Path         | Should Be $allowTargetResourceParameters.Path
                    $result.Filter       | Should Be $allowTargetResourceParameters.Filter
                    $result.OverrideMode | Should Be $allowTargetResourceParameters.OverrideMode
                }
            }
            Context 'When OverrideMode is set to Deny' {
                Mock -CommandName Get-WebConfiguration -MockWith { return $mockDenyOverrideMode }
                $result = Get-TargetResource @denytargetResourceParameters

                It 'Should return the correct properties' {
                    $result.Path         | Should Be $denytargetResourceParameters.Path
                    $result.Filter       | Should Be $denytargetResourceParameters.Filter
                    $result.OverrideMode | Should Be $denytargetResourceParameters.OverrideMode
                }
            }
        }
        #endregion

        #region Function Test-TargetResource
        Describe 'MSFT_xIISFeatureDelegation\Test-TargetResource' {
            Context 'When OverrideMode is set to Allow' {
                Mock -CommandName Get-WebConfiguration -MockWith { return $mockAllowOverrideMode }
                It 'Should return True when in desired state' {
                    $results = Test-TargetResource @allowTargetResourceParameters
                    $results | Should Be $true
                }

                Mock -CommandName Get-WebConfiguration -MockWith { return $mockDenyOverrideMode }
                It 'Should return False when not in desired state' {
                    $results = Test-TargetResource @allowTargetResourceParameters
                    $results | Should Be $false
                }
            }

            Context 'When OverrideMode is set to Deny' {
                Mock -CommandName Get-WebConfiguration -MockWith { return $mockDenyOverrideMode }
                It 'Should return True when in desired state' {
                    $results = Test-TargetResource @denyTargetResourceParameters
                    $results | Should Be $true
                }

                Mock -CommandName Get-WebConfiguration -MockWith { return $mockAllowOverrideMode }
                It 'Should return False when not in desired state' {
                    $results = Test-TargetResource @denyTargetResourceParameters
                    $results | Should Be $false
                }
            }
        }
        #endregion

        #region Function Set-TargetResource
        Describe 'MSFT_xIISFeatureDelegation\Set-TargetResource' {
            Context 'When resource not in desired state' {

                Mock -CommandName Set-WebConfiguration -ParameterFilter { $Filter -eq $allowTargetResourceParameters.Filter -and $PsPath -eq $allowTargetResourceParameters.Path }

                Set-TargetResource @allowTargetResourceParameters

                It 'Should call all the mocks' {
                    Assert-MockCalled Set-WebConfiguration -Exactly -Times 1
                }
            }
        }
        #endregion

        Describe 'MSFT_xIISFeatureDelegation\Get-OverrideMode' {
            $mockWebConfigOutput = @{
                Metadata = @{
                    effectiveOverrideMode = $null
                }
            }

            $getOverrideModeParameters = $allowTargetResourceParameters.clone()
            $getOverrideModeParameters.Remove('OverrideMode')

            Mock -CommandName Assert-Module -MockWith {}

            Context 'When OverrideMode is invalid' {
                It 'Should throw an error on null' {
                    Mock -CommandName Get-WebConfiguration  -MockWith { return $mockWebConfigOutput }

                    {Get-OverrideMode @getOverrideModeParameters} | Should Throw ($LocalizedData.UnableToGetConfig -f $getOverrideModeParameters.Filter)
                }

                It 'Should throw an error on the wrong value' {
                    $mockWebConfigOutput.Metadata.effectiveOverrideMode = 'Wrong'
                    Mock -CommandName Get-WebConfiguration  -MockWith { return $mockWebConfigOutput }

                    {Get-OverrideMode @getOverrideModeParameters} | Should Throw ($LocalizedData.UnableToGetConfig -f $getOverrideModeParameters.Filter)
                }
            }

            Context 'When OverrideMode is Allow' {
                Mock -CommandName Get-WebConfiguration -MockWith { return $mockAllowOverrideMode }

                $overrideMode = Get-OverrideMode @getOverrideModeParameters
                It 'Should be Allow' {
                    $overrideMode | Should Be 'Allow'
                }
            }

            Context 'When OverrideMode is Deny' {
                Mock -CommandName Get-WebConfiguration -MockWith { return $mockDenyOverrideMode }

                $overrideMode = Get-OverrideMode @getOverrideModeParameters
                It 'Should be Deny' {
                    $overrideMode | Should Be 'Deny'
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
