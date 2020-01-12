
$script:dscModuleName = 'xWebAdministration'
$script:dscResourceName = 'MSFT_xWebConfigProperty'

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

    Import-Module (Join-Path -Path $PSScriptRoot -ChildPath '..\MockWebAdministrationWindowsFeature.psm1') -Force -Scope Global
}

function Invoke-TestCleanup
{
    if (Get-Module -Name 'MockWebAdministrationWindowsFeature')
    {
        Write-Information 'Removing MockWebAdministrationWindowsFeature module...'
        Remove-Module -Name 'MockWebAdministrationWindowsFeature'
    }

    $mocks = (Get-ChildItem Function:) | Where-Object { $_.Source -eq 'MockWebAdministrationWindowsFeature' }

    if ($mocks)
    {
        Write-Information 'Removing MockWebAdministrationWindowsFeature functions...'
        $mocks | Remove-Item
    }

    Restore-TestEnvironment -TestEnvironment $script:testEnvironment
}

Invoke-TestSetup

try
{
    InModuleScope $script:dscResourceName {
        $script:dscModuleName = 'xWebAdministration'
        $script:dscResourceName = 'MSFT_xWebConfigProperty'

        $script:presentParameters = @{
            WebsitePath  = 'MACHINE/WEBROOT/APPHOST'
            Filter       = 'system.webServer/advancedLogging/server'
            PropertyName = 'enabled'
            Value        = 'true'
            Ensure       = 'Present'
        }

        $script:absentParameters = @{
            WebsitePath  = 'MACHINE/WEBROOT/APPHOST'
            Filter       = 'system.webServer/advancedLogging/server'
            PropertyName = 'enabled'
            Ensure       = 'Absent'
        }

        #region Function Get-TargetResource
        Describe "$($script:dscResourceName)\Get-TargetResource" {
            Context 'Value is absent' {
                $parameters = @{
                    WebsitePath  = 'MACHINE/WEBROOT/APPHOST'
                    Filter       = 'system.webServer/advancedLogging/server'
                    PropertyName = 'enabled'
                }

                Mock -CommandName Get-ItemValue -ModuleName $script:dscResourceName -MockWith {
                    return $null
                }

                $result = Get-TargetResource @parameters

                It 'Should return the correct values' {
                    $result.Ensure       | Should -Be 'Absent'
                    $result.PropertyName | Should -Be 'enabled'
                    $result.Value        | Should -Be $null
                }

                It 'Should have called Get-ItemValue the correct amount of times' {
                    Assert-MockCalled -CommandName Get-ItemValue -Times 1 -Exactly
                }
            }

            Context 'Value is present' {
                $parameters = @{
                    WebsitePath  = 'MACHINE/WEBROOT/APPHOST'
                    Filter       = 'system.webServer/advancedLogging/server'
                    PropertyName = 'enabled'
                }

                Mock -CommandName Get-ItemValue -ModuleName $script:dscResourceName -MockWith {
                    return 'true'
                }

                $result = Get-TargetResource @parameters

                It 'Should return the correct values' {
                    $result.Ensure       | Should -Be 'Present'
                    $result.PropertyName | Should -Be 'enabled'
                    $result.Value        | Should -Be 'true'
                }

                It 'Should have called Get-ItemValue the correct amount of times' {
                    Assert-MockCalled -CommandName Get-ItemValue -Times 1 -Exactly
                }
            }
        }
        #endregion Function Get-TargetResource

        #region Function Test-TargetResource
        Describe "$($script:dscResourceName)\Test-TargetResource" {
            Context 'Ensure is present but value is null' {
                Mock -CommandName Get-ItemValue -ModuleName $script:dscResourceName -MockWith {
                    return $null
                }

                $result = Test-TargetResource @script:presentParameters

                It 'Should return false' {
                    $result | Should -Be $false
                }
            }

            Context 'Ensure is present but value is an empty string' {
                Mock -CommandName Get-ItemValue -ModuleName $script:dscResourceName -MockWith {
                    return [System.String]::Empty
                }

                $result = Test-TargetResource @script:presentParameters

                It 'Should return false' {
                    $result | Should -Be $false
                }
            }

            Context 'Ensure is present but value is wrong' {
                Mock -CommandName Get-ItemValue -ModuleName $script:dscResourceName -MockWith {
                    return 'false'
                }

                $result = Test-TargetResource @script:presentParameters

                It 'Should return false' {
                    $result | Should -Be $false
                }
            }

            Context 'Ensure is present and the value is the same' {
                Mock -CommandName Get-ItemValue -ModuleName $script:dscResourceName -MockWith {
                    return 'true'
                }

                $result = Test-TargetResource @script:presentParameters

                It 'Should return true' {
                    $result | Should -Be $true
                }
            }

            Context 'Ensure is absent but value is not null' {
                Mock -CommandName Get-ItemValue -ModuleName $script:dscResourceName -MockWith {
                    return 'true'
                }

                $result = Test-TargetResource @script:absentParameters

                It 'Should return false' {
                    $result | Should -Be $false
                }
            }

            Context 'Ensure is absent and value is null' {
                Mock -CommandName Get-ItemValue -ModuleName $script:dscResourceName -MockWith {
                    return $null
                }

                $result = Test-TargetResource @script:absentParameters

                It 'Should return true' {
                    $result | Should -Be $true
                }
            }
        }
        #endregion Function Test-TargetResource

        #region Function Set-TargetResource
        Describe "$($script:dscResourceName)\Set-TargetResource" {
            Context 'Ensure is present - String Value' {
                Mock -CommandName Get-ItemPropertyType -MockWith { return 'String' }
                Mock -CommandName Convert-PropertyValue
                Mock -CommandName Set-WebConfigurationProperty

                Set-TargetResource @script:presentParameters

                It 'Should call the right Mocks' {
                    Assert-MockCalled -CommandName Get-ItemPropertyType -Times 1 -Exactly
                    Assert-MockCalled -CommandName Convert-PropertyValue -Times 0 -Exactly
                    Assert-MockCalled -CommandName Set-WebConfigurationProperty -Times 1 -Exactly
                }
            }

            Context 'Ensure is present - Integer Value' {
                Mock -CommandName Get-ItemPropertyType -MockWith { return 'Int32' }
                Mock -CommandName Convert-PropertyValue -MockWith { return '32' }
                Mock -CommandName Set-WebConfigurationProperty

                Set-TargetResource @script:presentParameters

                It 'Should call the right Mocks' {
                    Assert-MockCalled -CommandName Get-ItemPropertyType -Times 1 -Exactly
                    Assert-MockCalled -CommandName Convert-PropertyValue -Times 1 -Exactly
                    Assert-MockCalled -CommandName Set-WebConfigurationProperty -Times 1 -Exactly
                }
            }

            Context 'Ensure is absent' {
                Mock -CommandName Clear-WebConfiguration

                Set-TargetResource @script:absentParameters

                It 'Should call the right Mocks' {
                    Assert-MockCalled -CommandName Clear-WebConfiguration -Times 1 -Exactly
                }
            }
        }
        #endregion Function Set-TargetResource

        #region Non-Exported Function Unit Tests
        Describe "$($script:dscResourceName)\Get-ItemPropertyType" {
            $propertyType = 'UInt32'
            $parameters = @{
                WebsitePath  = 'IIS:\'
                Filter       = 'system.webServer/security/dynamicIpSecurity/denyByConcurrentRequests'
                PropertyName = 'maxConcurrentRequests'
            }

            Mock -CommandName 'Get-WebConfiguration' -MockWith {
                @{
                    Schema = @{
                        AttributeSchemas = @{
                            Name    = $parameters.PropertyName
                            ClrType = @{
                                Name = $propertyType
                            }
                        }
                    }
                }
            }

            It 'Should return the expected ClrType' {
                Get-ItemPropertyType @parameters | Should -Be $propertyType
            }
        }

        Describe "$($script:dscResourceName)\Convert-PropertyValue" {
            $cases = @(
                @{DataType = 'Int32'},
                @{DataType = 'Int64'},
                @{DataType = 'UInt32'}
            )
            It 'Should return <dataType> value' -TestCases $cases {
                param ($DataType)
                $returnValue = Convert-PropertyValue -PropertyType $dataType -InputValue 32

                $returnValue | Should -BeOfType [$dataType]
            }

        }
        #endregion Non-Exported Function Unit Tests
    }
}
finally
{
    Invoke-TestCleanup
}
