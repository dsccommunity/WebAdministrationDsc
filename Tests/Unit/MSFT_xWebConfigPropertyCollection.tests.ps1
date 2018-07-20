
#region HEADER
$script:DSCModuleName = 'xWebAdministration'
$script:DSCResourceName = 'MSFT_xWebConfigPropertyCollection'

# Unit Test Template Version: 1.2.2
$script:moduleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
if ( (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests'))) -or `
     (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1'))) )
{
    & git @('clone','https://github.com/PowerShell/DscResource.Tests.git',(Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests'))
}

Import-Module -Name (Join-Path -Path $script:moduleRoot -ChildPath (Join-Path -Path 'DSCResource.Tests' -ChildPath 'TestHelper.psm1')) -Force

$TestEnvironment = Initialize-TestEnvironment `
    -DSCModuleName $script:DSCModuleName `
    -DSCResourceName $script:DSCResourceName `
    -ResourceType 'Mof' `
    -TestType Unit

#endregion HEADER

# Begin Testing
try
{
    InModuleScope $script:DSCResourceName {
        $script:DSCModuleName = 'xWebAdministration'
        $script:DSCResourceName = 'MSFT_xWebConfigPropertyCollection'

        $script:presentParameters = @{
            WebsitePath       = 'MACHINE/WEBROOT/APPHOST'
            Filter            = 'system.webServer/advancedLogging/server'
            CollectionName    = 'verbs'
            ItemName          = 'add'
            ItemKeyName       = 'verb'
            ItemKeyValue      = 'TRACE'
            ItemPropertyName  = 'allowed'
            ItemPropertyValue = 'false'
            Ensure            = 'Present'
        }

        $script:absentParameters = @{
            WebsitePath       = 'MACHINE/WEBROOT/APPHOST'
            Filter            = 'system.webServer/advancedLogging/server'
            CollectionName    = 'verbs'
            ItemName          = 'add'
            ItemKeyName       = 'verb'
            ItemKeyValue      = 'TRACE'
            ItemPropertyName  = 'allowed'
            Ensure            = 'Absent'
        }

        #region Function Get-TargetResource
        Describe "$($script:DSCResourceName)\Get-TargetResource" {
            $parameters = @{
                WebsitePath      = 'MACHINE/WEBROOT/APPHOST'
                Filter           = 'system.webServer/advancedLogging/server'
                CollectionName   = 'verbs'
                ItemName         = 'add'
                ItemKeyName      = 'verb'
                ItemKeyValue     = 'TRACE'
                ItemPropertyName = 'allowed'
            }
            Context 'Collection item does not exist' {
                Mock -CommandName Get-ItemValues -ModuleName $script:DSCResourceName -MockWith {
                    return $null
                }

                $result = Get-TargetResource @parameters

                It 'Should return the correct values' {
                    $result.WebsitePath       | Should -Be $parameters.WebsitePath
                    $result.Filter            | Should -Be $parameters.Filter
                    $result.CollectionName    | Should -Be $parameters.CollectionName
                    $result.ItemName          | Should -Be $parameters.ItemName
                    $result.ItemKeyName       | Should -Be $parameters.ItemKeyName
                    $result.ItemKeyValue      | Should -Be $parameters.ItemKeyValue
                    $result.Ensure            | Should -Be 'Absent'
                    $result.ItemPropertyName  | Should -Be $parameters.ItemPropertyName
                    $result.ItemPropertyValue | Should -Be $null
                }

                It 'Should have called Get-ItemValues the correct amount of times' {
                    Assert-MockCalled -CommandName Get-ItemValues -Times 1 -Exactly
                }
            }

            Context 'Collection item exists but does not contain property' {
                Mock -CommandName Get-ItemValues -ModuleName $script:DSCResourceName -MockWith {
                    return @(@{
                        Name = 'Property1'
                        Value = 'Property1Value'
                    })
                }

                $result = Get-TargetResource @parameters

                It 'Should return the correct values' {
                    $result.WebsitePath       | Should -Be $parameters.WebsitePath
                    $result.Filter            | Should -Be $parameters.Filter
                    $result.CollectionName    | Should -Be $parameters.CollectionName
                    $result.ItemName          | Should -Be $parameters.ItemName
                    $result.ItemKeyName       | Should -Be $parameters.ItemKeyName
                    $result.ItemKeyValue      | Should -Be $parameters.ItemKeyValue
                    $result.Ensure            | Should -Be 'Absent'
                    $result.ItemPropertyName  | Should -Be $parameters.ItemPropertyName
                    $result.ItemPropertyValue | Should -Be $null
                }

                It 'Should have called Get-ItemValues the correct amount of times' {
                    Assert-MockCalled -CommandName Get-ItemValues -Times 1 -Exactly
                }
            }

            Context 'Collection item exists and contains property' {
                Mock -CommandName Get-ItemValues -ModuleName $script:DSCResourceName -MockWith {
                    return @{
                        Property1 = 'Property1Value'
                        allowed = 'false'
                    }
                }

                $result = Get-TargetResource @parameters

                It 'Should return the correct values' {
                    $result.WebsitePath       | Should -Be $parameters.WebsitePath
                    $result.Filter            | Should -Be $parameters.Filter
                    $result.CollectionName    | Should -Be $parameters.CollectionName
                    $result.ItemName          | Should -Be $parameters.ItemName
                    $result.ItemKeyName       | Should -Be $parameters.ItemKeyName
                    $result.ItemKeyValue      | Should -Be $parameters.ItemKeyValue
                    $result.Ensure            | Should -Be 'Present'
                    $result.ItemPropertyName  | Should -Be $parameters.ItemPropertyName
                    $result.ItemPropertyValue | Should -Be 'false'
                }

                It 'Should have called Get-ItemValues the correct amount of times' {
                    Assert-MockCalled -CommandName Get-ItemValues -Times 1 -Exactly
                }
            }
        }

        #endregion Function Get-TargetResource

        #region Function Test-TargetResource
        Describe "$($script:DSCResourceName)\Test-TargetResource" {
            Context 'Ensure is present but collection item does not exist' {
                Mock -CommandName Get-ItemValues -ModuleName $script:DSCResourceName -MockWith {
                    return $null
                }

                $result = Test-TargetResource @script:presentParameters

                It 'Should return false' {
                    $result | Should -Be $false
                }
            }

            Context 'Ensure is present and collection item exists but does not contain property' {
                Mock -CommandName Get-ItemValues -ModuleName $script:DSCResourceName -MockWith {
                    return @(@{
                        Name = 'Property1'
                        Value = 'Property1Value'
                    })
                }

                $result = Test-TargetResource @script:presentParameters

                It 'Should return false' {
                    $result | Should -Be $false
                }
            }

            Context 'Ensure is present and collection item and property exists but value is wrong' {
                Mock -CommandName Get-ItemValues -ModuleName $script:DSCResourceName -MockWith {
                    return @{
                        Property1 = 'Property1Value'
                        allowed = 'true'
                    }
                }

                $result = Test-TargetResource @script:presentParameters

                It 'Should return false' {
                    $result | Should -Be $false
                }
            }

            Context 'Ensure is present and collection item and property exists and value is same' {
                Mock -CommandName Get-ItemValues -ModuleName $script:DSCResourceName -MockWith {
                    return @{
                        Property1 = 'Property1Value'
                        allowed = 'false'
                    }
                }

                $result = Test-TargetResource @script:presentParameters

                It 'Should return true' {
                    $result | Should -Be $true
                }
            }

            Context 'Ensure is absent but collection item and property exists' {
                Mock -CommandName Get-ItemValues -ModuleName $script:DSCResourceName -MockWith {
                    return @{
                        Property1 = 'Property1Value'
                        allowed = 'false'
                    }
                }

                $result = Test-TargetResource @script:absentParameters

                It 'Should return false' {
                    $result | Should -Be $false
                }
            }

            Context 'Ensure is absent and collection item and property do not exist' {
                Mock -CommandName Get-ItemValues -ModuleName $script:DSCResourceName -MockWith {
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
            Context 'Ensure is present and collection item and property do not exist - String ItemPropertyValue' {
                Mock -CommandName Get-ItemValues -ModuleName $script:DSCResourceName
                Mock -CommandName Add-WebConfigurationProperty
                Mock -CommandName Get-CollectionItemPropertyType -MockWith { return 'String' }
                Mock -CommandName Convert-PropertyValue

                It 'Should call the right Mocks' {
                    Set-TargetResource @script:presentParameters

                    Assert-MockCalled -CommandName Get-ItemValues -Times 1 -Exactly
                    Assert-MockCalled -CommandName Add-WebConfigurationProperty -Times 1 -Exactly
                    Assert-MockCalled -CommandName Get-CollectionItemPropertyType -Times 1 -Exactly
                    Assert-MockCalled -CommandName Convert-PropertyValue -Times 0 -Exactly
                }
            }

            Context 'Ensure is present and collection item and property do not exist - Integer ItemPropertyValue' {
                Mock -CommandName Get-ItemValues -ModuleName $script:DSCResourceName
                Mock -CommandName Add-WebConfigurationProperty
                Mock -CommandName Get-CollectionItemPropertyType -MockWith { return 'Int64' }
                Mock -CommandName Convert-PropertyValue

                It 'Should call the right Mocks' {
                    Set-TargetResource @script:presentParameters

                    Assert-MockCalled -CommandName Get-ItemValues -Times 1 -Exactly
                    Assert-MockCalled -CommandName Add-WebConfigurationProperty -Times 1 -Exactly
                    Assert-MockCalled -CommandName Get-CollectionItemPropertyType -Times 1 -Exactly
                    Assert-MockCalled -CommandName Convert-PropertyValue -Times 1 -Exactly
                }
            }

            Context 'Ensure is present and collection item and property exist' {
                Mock -CommandName Get-ItemValues -ModuleName $script:DSCResourceName -MockWith {
                    return @{
                        Property1 = 'Property1Value'
                        allowed = 'false'
                    }
                }
                Mock -CommandName Set-WebConfigurationProperty -MockWith {}
                Mock -CommandName Get-CollectionItemPropertyType -MockWith { return 'String' }
                Mock -CommandName Convert-PropertyValue

                It 'Should call the right Mocks' {
                    Set-TargetResource @script:presentParameters

                    Assert-MockCalled -CommandName Get-ItemValues -Times 1 -Exactly
                    Assert-MockCalled -CommandName Set-WebConfigurationProperty -Times 1 -Exactly
                    Assert-MockCalled -CommandName Get-CollectionItemPropertyType -Times 1 -Exactly
                    Assert-MockCalled -CommandName Convert-PropertyValue -Times 0 -Exactly
                }
            }

            Context 'Ensure is absent' {
                Mock -CommandName Remove-WebConfigurationProperty -MockWith {}

                It 'Should call the right Mocks' {
                    Set-TargetResource @script:absentParameters

                    Assert-MockCalled -CommandName Remove-WebConfigurationProperty -Times 1 -Exactly
                }
            }
        }
        #endregion Function Set-TargetResource

        #endregion Exported Function Unit Tests

        #region Non-Exported Function Unit Tests

        Describe "$($script:DSCResourceName)\Get-ItemValues" {
            $parameters = @{
                WebsitePath    = 'MACHINE/WEBROOT/APPHOST'
                Filter         = 'system.webServer/advancedLogging/server'
                CollectionName = 'verbs'
                ItemName       = 'add'
                ItemKeyName    = 'verb'
                ItemKeyValue   = 'TRACE'
            }

            Context 'Collection item does not exist' {
                Mock -CommandName Get-WebConfigurationProperty -MockWith {
                    return $null
                }

                $result = Get-ItemValues @parameters

                It 'Should return the correct values' {
                    $result | Should -Be $null
                }

                It 'Should have called Get-WebConfigurationProperty the correct amount of times' {
                    Assert-MockCalled -CommandName Get-WebConfigurationProperty -Times 1 -Exactly
                }
            }

            Context 'Collection item exists' {
                Mock -CommandName Get-WebConfigurationProperty -MockWith {
                    return @{
                        Attributes = @(
                            @{
                                Name = 'verb'
                                Value = 'TRACE'
                            }
                            @{
                                Name = 'Property1'
                                Value = 'Property1Value'
                            }
                            @{
                                Name = 'Property2'
                                Value = 'Property2Value'
                            }
                        )
                    }
                }

                $result = Get-ItemValues @parameters

                It 'Should return the correct values' {
                    $result              | Should -Not -Be $null
                    $result.Count        | Should -Be 2
                    $result.Keys.Count   | Should -Be 2
                    $result['Property1'] | Should -Be 'Property1Value'
                    $result['Property2'] | Should -Be 'Property2Value'
                }

                It 'Should have called Get-WebConfigurationProperty the correct amount of times' {
                    Assert-MockCalled -CommandName Get-WebConfigurationProperty -Times 1 -Exactly
                }
            }
        }

        Describe "$($script:DSCResourceName)\Get-CollectionItemPropertyType" {
            $propertyType = 'UInt32'
            $parameters = @{
                WebsitePath  = 'IIS:\'
                Filter       = 'system.webServer/security/requestFiltering/requestLimits/headerlimits'
                PropertyName = 'Sizelimit'
                AddElement   = 'Add'
            }

            Mock -CommandName Get-WebConfiguration  -MockWith {
                @{
                    Schema = @{
                        CollectionSchema = @{
                            AddElementNames = 'Add'
                        }
                    }
                }
            }

            Mock -CommandName Get-AddElementSchema -MockWith {
                @{
                    Name    = $parameters.PropertyName
                    ClrType = @{
                        Name = $propertyType
                    }
                }
            }

            It 'Should return the expected ClrType' {
                Get-CollectionItemPropertyType @parameters | Should -Be $propertyType
            }
        }

        Describe "$($script:DSCResourceName)\Convert-PropertyValue" {
            $cases = @(
                @{DataType = 'Int32'},
                @{DataType = 'Int64'},
                @{DataType = 'UInt32'},
                @{DataType = 'UInt64'}
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
