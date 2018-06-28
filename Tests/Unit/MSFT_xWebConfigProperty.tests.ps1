
$script:DSCModuleName = 'xWebAdministration'
$script:DSCResourceName = 'MSFT_xWebConfigProperty'

#region HEADER
$script:moduleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
if ( (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests'))) -or `
      (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1'))) )
{
    if (Test-Path -Path (Join-Path -Path $moduleRoot -ChildPath 'DSCResource.Tests.zip'))
    {
        Expand-Archive -Path (Join-Path -Path $moduleRoot -ChildPath 'DSCResource.Tests.zip') -DestinationPath (Join-Path -Path $moduleRoot -ChildPath 'DSCResource.Tests') -Force
    }
    else
    {
        & git @('clone','https://github.com/PowerShell/DscResource.Tests.git',(Join-Path -Path $moduleRoot -ChildPath '\DSCResource.Tests\'))
    }
}

Import-Module (Join-Path -Path $moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1') -Force
Import-Module (Join-Path -Path $moduleRoot -ChildPath 'Tests\MockWebAdministrationWindowsFeature.psm1') -Force -Scope Global

$TestEnvironment = Initialize-TestEnvironment `
    -DSCModuleName $script:DSCModuleName `
    -DSCResourceName $script:DSCResourceName `
    -TestType Unit
#endregion HEADER

# Begin Testing
try
{
    InModuleScope $script:DSCResourceName {
        $script:DSCModuleName = 'xWebAdministration'
        $script:DSCResourceName = 'MSFT_xWebConfigProperty'

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
        Describe "$($script:DSCResourceName)\Get-TargetResource" {
            Context 'Value is absent' {
                $parameters = @{
                    WebsitePath  = 'MACHINE/WEBROOT/APPHOST'
                    Filter       = 'system.webServer/advancedLogging/server'
                    PropertyName = 'enabled'
                }

                Mock -CommandName Get-ItemValue -ModuleName $script:DSCResourceName -MockWith {
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

                Mock -CommandName Get-ItemValue -ModuleName $script:DSCResourceName -MockWith {
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
        Describe "$($script:DSCResourceName)\Test-TargetResource" {
            Context 'Ensure is present but value is null' {
                Mock -CommandName Get-ItemValue -ModuleName $script:DSCResourceName -MockWith {
                    return $null
                }

                $result = Test-TargetResource @script:presentParameters

                It 'Should return false' {
                    $result | Should -Be $false
                }
            }

            Context 'Ensure is present but value is an empty string' {
                Mock -CommandName Get-ItemValue -ModuleName $script:DSCResourceName -MockWith {
                    return [System.String]::Empty
                }

                $result = Test-TargetResource @script:presentParameters

                It 'Should return false' {
                    $result | Should -Be $false
                }
            }

            Context 'Ensure is present but value is wrong' {
                Mock -CommandName Get-ItemValue -ModuleName $script:DSCResourceName -MockWith {
                    return 'false'
                }

                $result = Test-TargetResource @script:presentParameters

                It 'Should return false' {
                    $result | Should -Be $false
                }
            }

            Context 'Ensure is present and the value is the same' {
                Mock -CommandName Get-ItemValue -ModuleName $script:DSCResourceName -MockWith {
                    return 'true'
                }

                $result = Test-TargetResource @script:presentParameters

                It 'Should return true' {
                    $result | Should -Be $true
                }
            }

            Context 'Ensure is absent but value is not null' {
                Mock -CommandName Get-ItemValue -ModuleName $script:DSCResourceName -MockWith {
                    return 'true'
                }

                $result = Test-TargetResource @script:absentParameters

                It 'Should return false' {
                    $result | Should -Be $false
                }
            }

            Context 'Ensure is absent and value is null' {
                Mock -CommandName Get-ItemValue -ModuleName $script:DSCResourceName -MockWith {
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
        Describe "$($script:DSCResourceName)\Set-TargetResource" {
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
        Describe "$($script:DSCResourceName)\Get-ItemPropertyType" {
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

        Describe "$($script:DSCResourceName)\Convert-PropertyValue" {
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
    #region FOOTER
    Restore-TestEnvironment -TestEnvironment $TestEnvironment
    #endregion
}
