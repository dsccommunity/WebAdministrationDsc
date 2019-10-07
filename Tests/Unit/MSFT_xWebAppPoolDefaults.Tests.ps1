#region HEADER

$script:DSCModuleName   = 'xWebAdministration'
$script:DSCResourceName = 'MSFT_xWebAppPoolDefaults'

# Unit Test Template Version: 1.2.1
$script:moduleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
if ( (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests'))) -or `
     (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1'))) )
{
    & git @('clone','https://github.com/PowerShell/DscResource.Tests.git', `
        (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests'))
}

Import-Module -Name (Join-Path -Path $script:moduleRoot -ChildPath (Join-Path `
    -Path 'DSCResource.Tests' -ChildPath 'TestHelper.psm1')) -Force


$TestEnvironment = Initialize-TestEnvironment `
    -DSCModuleName $script:DSCModuleName `
    -DSCResourceName $script:DSCResourceName `
    -TestType Unit

#endregion HEADER

function Invoke-TestSetup {
}

function Invoke-TestCleanup {
    Restore-TestEnvironment -TestEnvironment $TestEnvironment
}

# Begin Testing
try
{
    Invoke-TestSetup

    InModuleScope $script:DSCResourceName {

        Describe "$($script:DSCResourceName)\Get-TargetResource" {

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

        Describe "$($script:DSCResourceName)\Test-TargetResource" {

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

        Describe "$($script:DSCResourceName)\Set-TargetResource" {

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
