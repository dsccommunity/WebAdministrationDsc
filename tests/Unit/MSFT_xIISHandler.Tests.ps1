
$script:dscModuleName = 'xWebAdministration'
$script:dscResourceName = 'MSFT_xIISHandler'

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
    #region Pester Tests

    InModuleScope $script:dscResourceName {

        #region Function Get-TargetResource
        Describe 'MSFT_xIISHandler\Get-TargetResource' {
            Context 'Ensure = Absent and Handler is not Present' {
                Mock Assert-Module
                Mock Get-Handler

                It 'Should return the right hashtable' {
                    $result = Get-TargetResource -Name 'StaticFile' -Ensure 'Absent'
                    $result.Ensure | Should Be 'Absent'
                    $result.Name   | Should Be 'StaticFile'
                }
            }
            Context 'Ensure = Present and Handler is Present' {
                Mock Assert-Module
                Mock Get-Handler {'Present'}

                It 'Should return the right hashtable' {
                    $result = Get-TargetResource -Name 'StaticFile' -Ensure 'Present'
                    $result.Ensure | Should Be 'Present'
                    $result.Name   | Should Be 'StaticFile'
                }
            }
        }
        #endregion


        #region Function Test-TargetResource
        Describe 'MSFT_xIISHandler\Test-TargetResource' {
            $Name = 'StaticFile'

            Context 'Handler is NULL and Ensure = Present' {
                Mock Assert-Module
                Mock Get-Handler

                $result = Test-TargetResource -Name $Name -Ensure 'Present' -Verbose *>&1
                It 'Should return False' {
                    $result[0] | Should Be $false
                }

                It 'Should not return a verbose message' {
                    $result[1] | Should Be $null
                }
            }

            Context 'Handler is Present and Ensure = Present' {
                Mock Assert-Module
                Mock Get-Handler {'Present'}

                $result = Test-TargetResource -Name $Name -Ensure 'Present' -Verbose *>&1

                It 'Should return the correct verbose message' {
                    $result[0] | Should Be ($script:localizedData.HandlerExists -f $Name)
                }

                It 'Should return False' {
                    $result[1] | Should Be $true
                }
            }

            Context 'Handler is Present and Ensure = Absent' {
                Mock Assert-Module
                Mock Get-Handler {'Present'}

                $result = Test-TargetResource -Name $Name -Ensure 'Absent' -Verbose *>&1
                It 'Should return False' {
                    $result[0] | Should Be $false
                }

                It 'Should not return a verbose message' {
                    $result[1] | Should Be $null
                }
            }

            Context 'Handler is Present and Ensure = Present' {
                Mock Assert-Module
                Mock Get-Handler

                $result = Test-TargetResource -Name $Name -Ensure 'Absent' -Verbose *>&1

                It 'Should return the correct verbose message' {
                    $result[0] | Should Be ($script:localizedData.HandlerNotPresent -f $Name)
                }

                It 'Should return False' {
                    $result[1] | Should Be $true
                }
            }
        }
        #endregion


        #region Function Set-TargetResource
        Describe 'MSFT_xIISHandler\Set-TargetResource' {
            Context 'Ensure = Present and Handler is NOT present' {
                $mockName = 'StaticFile'
                Mock Assert-Module
                Mock Get-Handler
                Mock Add-Handler {} -ParameterFilter {$Name -eq $mockName}

                $message = Set-TargetResource -Name $mockName -Ensure 'Present' -Verbose 4>&1

                It 'Should add the handler' {
                    Assert-MockCalled Add-Handler -ParameterFilter {$Name -eq $mockName}
                }

                It 'Should call the right Verbose Message' {
                    $message | Should Be ($script:localizedData.AddingHandler -f $mockName)
                }
            }

            Context 'Ensure = Absent and Handler IS present' {
                $mockName = 'StaticFile'
                Mock Assert-Module
                Mock Get-Handler {'Present'}
                Mock Remove-WebConfigurationProperty

                $message = Set-TargetResource -Name $mockName -Ensure 'Absent' -Verbose 4>&1

                It 'Should add the handler' {
                    Assert-MockCalled Remove-WebConfigurationProperty
                }

                It 'Should call the right Verbose Message' {
                    $message | Should Be ($script:localizedData.RemovingHandler -f $mockName)
                }
            }
        }
        #endregion

        Describe 'MSFT_xIISHandler\Add-Handler' {
            Context 'Should find all the handlers' {
                foreach ($key in $script:handlers.keys)
                {
                    Mock Add-WebConfigurationProperty {} -ParameterFilter {$Value -and $Value -eq $script:handlers[$key]}

                    Add-Handler -Name $key
                    It "Should find $key in `$script:handler" {
                        Assert-MockCalled Add-WebConfigurationProperty -Exactly 1 -ParameterFilter {$Value -and $Value -eq $script:handlers[$key]}
                    }
                }
            }

            Context 'It should throw when it cannot find the handler' {
                It 'Should throw an error' {
                    $keyName = 'Non-ExistantKey'
                    {Add-Handler -Name $keyName} | Should throw ($script:localizedData.HandlerNotSupported -f $KeyName)
                }
            }
        }

        Describe 'MSFT_xIISHandler\Get-Handler' {
            It 'Should call the mocks' {
                $name = 'StaticFile'
                $mockFilter = "system.webServer/handlers/Add[@Name='" + $name + "']"
                Mock Get-WebConfigurationProperty {} -ParameterFilter {$Filter -and $Filter -eq $mockFilter}
                Get-Handler -Name $Name
                Assert-MockCalled Get-WebConfigurationProperty
            }
        }
    }
    #endregion
}
finally
{
    Invoke-TestCleanup
}
