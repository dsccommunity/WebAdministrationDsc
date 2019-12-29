
$script:dscModuleName = 'xWebAdministration'
$script:dscResourceName = 'MSFT_xIISFeatureDelegation'

function Invoke-TestSetup
{
    try
    {
        Import-Module -Name DscResource.Test -Force
    }
    catch [System.IO.FileNotFoundException]
    {
        throw 'DscResource.Test module dependency not found. Please run ".\build.ps1 -Tasks build" first.'
    }

    $script:testEnvironment = Initialize-TestEnvironment `
        -DSCModuleName $script:dscModuleName `
        -DSCResourceName $script:dscResourceName `
        -ResourceType 'Mof' `
        -TestType 'Unit'

    Import-Module (Join-Path -Path $PSScriptRoot -ChildPath '..\MockWebAdministrationWindowsFeature.psm1')
}

function Invoke-TestCleanup
{
    Restore-TestEnvironment -TestEnvironment $script:testEnvironment
}

Invoke-TestSetup

try
{
    #region Pester Tests
    InModuleScope $script:dscResourceName {

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
            BeforeAll {
                Mock -CommandName Assert-Module
            }

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
            BeforeAll {
                Mock -CommandName Assert-Module
            }

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

        #region Helper functions
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

                    {Get-OverrideMode @getOverrideModeParameters} | Should Throw ($script:localizedData.UnableToGetConfig -f $getOverrideModeParameters.Filter)
                }

                It 'Should throw an error on the wrong value' {
                    $mockWebConfigOutput.Metadata.effectiveOverrideMode = 'Wrong'
                    Mock -CommandName Get-WebConfiguration  -MockWith { return $mockWebConfigOutput }

                    {Get-OverrideMode @getOverrideModeParameters} | Should Throw ($script:localizedData.UnableToGetConfig -f $getOverrideModeParameters.Filter)
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
        #endregion
    }
    #endregion
}
finally
{
    Invoke-TestCleanup
}
