#region HEADER

$script:dscModuleName   = 'xWebAdministration'
$script:dscResourceName = 'MSFT_xWebAppPoolDefaults'

function Invoke-TestSetup
{
    try
    {
        Import-Module -Name DscResource.Test -Force -ErrorAction 'Stop'
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
    InModuleScope $script:dscResourceName {

        Describe 'xWebAppPoolDefaults\Get-TargetResource' {
            BeforeAll {
                Mock -CommandName Assert-Module
            }

            Context 'Get application pool defaults' {
                $mockAppPoolDefaults = @{
                    managedRuntimeVersion = 'v4.0'
                    processModel = @{
                        identityType = 'SpecificUser'
                    }
                }

                Mock Get-WebConfigurationProperty -MockWith {
                    $path = $Filter.Replace('system.applicationHost/applicationPools/applicationPoolDefaults', '')

                    if ([System.String]::IsNullOrEmpty($path)) {
                        return $mockAppPoolDefaults[$Name]
                    } else {
                        $path = $path.Replace('/', '')
                        return $mockAppPoolDefaults[$path][$Name]
                    }
                }

                Mock -CommandName Get-WebConfigurationPropertyValue -MockWith {
                    if ([System.String]::IsNullOrEmpty($path)) {
                        return $mockAppPoolDefaults[$Name]
                    } else {
                        $path = $path.Replace('/', '')
                        return $mockAppPoolDefaults[$path][$Name]
                    }
                }

                $result = Get-TargetResource -IsSingleInstance 'Yes'

                It 'Should return managedRuntimeVersion' {
                    $result.managedRuntimeVersion | `
                        Should Be $mockAppPoolDefaults.managedRuntimeVersion
                }

                It 'Should return processModel\identityType' {
                    $result.identityType | `
                        Should Be $mockAppPoolDefaults.processModel.identityType
                }
            }
        }

        Describe 'xWebAppPoolDefaults\Test-TargetResource' {
            BeforeAll {
                Mock -CommandName Assert-Module

                Mock -CommandName Get-Value -ParameterFilter {
                    $Name -eq 'managedRuntimeVersion'
                } -MockWith {
                    return 'v4.0'
                }

                Mock -CommandName Get-Value -ParameterFilter {
                    $Name -eq 'identityType'
                } -MockWith {
                    return 'NetworkService'
                }
            }

            $mockAppPoolDefaults = @{
                managedRuntimeVersion = 'v4.0'
                processModel = @{
                    identityType = 'NetworkService'
                }
            }

            Mock Get-WebConfigurationProperty -MockWith {
                $path = $Filter.Replace('system.applicationHost/applicationPools/applicationPoolDefaults', '')

                if ([System.String]::IsNullOrEmpty($path)) {
                    return $mockAppPoolDefaults[$Name]
                } else {
                    $path = $path.Replace('/', '')
                    return $mockAppPoolDefaults[$path][$Name]
                }
            }

            Mock -CommandName Get-WebConfigurationPropertyValue -MockWith {
                $path = $Filter.Replace('system.applicationHost/applicationPools/applicationPoolDefaults', '')

                if ([System.String]::IsNullOrEmpty($path)) {
                    return $mockAppPoolDefaults[$Name]
                } else {
                    $path = $path.Replace('/', '')
                    return $mockAppPoolDefaults[$path][$Name]
                }
            }

            Context 'Application pool defaults correct' {
                $result = Test-TargetResource -IsSingleInstance 'Yes' `
                            -ManagedRuntimeVersion 'v4.0' `
                            -IdentityType 'NetworkService'

                It 'Should return True' {
                    $result | Should Be $true
                }
            }

            Context 'Application pool different managedRuntimeVersion' {
                $result = Test-TargetResource -IsSingleInstance 'Yes' `
                            -ManagedRuntimeVersion 'v2.0' `
                            -IdentityType 'NetworkService'

                It 'Should return False' {
                    $result | Should Be $false
                }
            }

            Context 'Application pool different processModel/@identityType' {
                $result = Test-TargetResource -IsSingleInstance 'Yes' `
                            -ManagedRuntimeVersion 'v4.0' `
                            -IdentityType 'LocalSystem'

                It 'Should return False' {
                    $result | Should Be $false
                }
            }

            Context 'Application pool no value for managedRuntimeVersion' {
                $result = Test-TargetResource -IsSingleInstance 'Yes' `
                            -IdentityType 'NetworkService'

                It 'Should return True' {
                    $result | Should Be $true
                }
            }
        }

        Describe 'xWebAppPoolDefaults\Set-TargetResource' {
            BeforeAll {
                Mock -CommandName Assert-Module
            }

            $mockAppPoolDefaults = @{
                managedRuntimeVersion = 'v4.0'
                processModel = @{
                    identityType = 'NetworkService'
                }
            }

            Mock Get-WebConfigurationProperty -MockWith {
                $path = $Filter.Replace('system.applicationHost/applicationPools/applicationPoolDefaults', '')

                if ([System.String]::IsNullOrEmpty($path)) {
                    return $mockAppPoolDefaults[$Name]
                } else {
                    $path = $path.Replace('/', '')
                    return $mockAppPoolDefaults[$path][$Name]
                }
            }

            Mock -CommandName Get-WebConfigurationPropertyValue -MockWith {
                if ([System.String]::IsNullOrEmpty($path)) {
                    return $mockAppPoolDefaults[$Name]
                } else {
                    $path = $path.Replace('/', '')
                    return $mockAppPoolDefaults[$path][$Name]
                }
            }

            Mock Set-WebConfigurationProperty -MockWith { }

            Context 'Application pool defaults correct' {
                Set-TargetResource -IsSingleInstance 'Yes' `
                    -ManagedRuntimeVersion 'v4.0' `
                    -IdentityType 'NetworkService'

                It 'Should not call Set-WebConfigurationProperty' {
                    Assert-MockCalled Set-WebConfigurationProperty -Exactly 0
                }
            }

            Context 'Application pool different managedRuntimeVersion' {
                Set-TargetResource -IsSingleInstance 'Yes' `
                    -ManagedRuntimeVersion 'v2.0' `
                    -IdentityType 'NetworkService'

                It 'Should call Set-WebConfigurationProperty once' {
                    Assert-MockCalled Set-WebConfigurationProperty -Exactly 1 `
                        -ParameterFilter { $Name -eq 'managedRuntimeVersion' }
                }
            }

            Context 'Application pool different processModel/@identityType' {
                Set-TargetResource -IsSingleInstance 'Yes' `
                    -ManagedRuntimeVersion 'v4.0' `
                    -IdentityType 'LocalSystem'

                It 'Should call Set-WebConfigurationProperty once' {
                    Assert-MockCalled Set-WebConfigurationProperty -Exactly 1 `
                        -ParameterFilter { $Name -eq 'identityType' }
                }
            }
        }
    }
}
finally
{
    Invoke-TestCleanup
}
