<#
    This module is loaded as a nested module when the xWebAdministration module is imported,
    remove the module from the session to avoid the error message:

        Multiple Script modules named 'xWebAdministration.Common'
        are currently loaded.  Make sure to remove any extra copies
        of the module from your session before testing.
#>
Get-Module -Name 'xWebAdministration.Common' -All | Remove-Module -Force

# Import the xWebAdministration.Common module to test
$script:resourceModulePath = Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent
$script:modulesFolderPath = Join-Path -Path $script:resourceModulePath -ChildPath 'Modules\xWebAdministration.Common'

Import-Module -Name (Join-Path -Path $script:modulesFolderPath -ChildPath 'xWebAdministration.Common.psm1') -Force

InModuleScope 'xWebAdministration.Common' {
    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\TestHelper\CommonTestHelper.psm1') -Force

    Describe 'xWebAdministration.Common\Get-LocalizedData' {
        $mockTestPath = {
            return $mockTestPathReturnValue
        }

        $mockImportLocalizedData = {
            $BaseDirectory | Should -Be $mockExpectedLanguagePath
        }

        BeforeEach {
            Mock -CommandName Test-Path -MockWith $mockTestPath -Verifiable
            Mock -CommandName Import-LocalizedData -MockWith $mockImportLocalizedData -Verifiable
        }

        Context 'When loading localized data for Swedish' {
            $mockExpectedLanguagePath = 'sv-SE'
            $mockTestPathReturnValue = $true

            It 'Should call Import-LocalizedData with sv-SE language' {
                Mock -CommandName Join-Path -MockWith {
                    return 'sv-SE'
                } -Verifiable

                { Get-LocalizedData -ResourceName 'DummyResource' } | Should -Not -Throw

                Assert-MockCalled -CommandName Join-Path -Exactly -Times 3 -Scope It
                Assert-MockCalled -CommandName Test-Path -Exactly -Times 1 -Scope It
                Assert-MockCalled -CommandName Import-LocalizedData -Exactly -Times 1 -Scope It
            }

            $mockExpectedLanguagePath = 'en-US'
            $mockTestPathReturnValue = $false

            It 'Should call Import-LocalizedData and fallback to en-US if sv-SE language does not exist' {
                Mock -CommandName Join-Path -MockWith {
                    return $ChildPath
                } -Verifiable

                { Get-LocalizedData -ResourceName 'DummyResource' } | Should -Not -Throw

                Assert-MockCalled -CommandName Join-Path -Exactly -Times 4 -Scope It
                Assert-MockCalled -CommandName Test-Path -Exactly -Times 1 -Scope It
                Assert-MockCalled -CommandName Import-LocalizedData -Exactly -Times 1 -Scope It
            }

            Context 'When $ScriptRoot is set to a path' {
                $mockExpectedLanguagePath = 'sv-SE'
                $mockTestPathReturnValue = $true

                It 'Should call Import-LocalizedData with sv-SE language' {
                    Mock -CommandName Join-Path -MockWith {
                        return 'sv-SE'
                    } -Verifiable

                    { Get-LocalizedData -ResourceName 'DummyResource' -ScriptRoot '.' } | Should -Not -Throw

                    Assert-MockCalled -CommandName Join-Path -Exactly -Times 1 -Scope It
                    Assert-MockCalled -CommandName Test-Path -Exactly -Times 1 -Scope It
                    Assert-MockCalled -CommandName Import-LocalizedData -Exactly -Times 1 -Scope It
                }

                $mockExpectedLanguagePath = 'en-US'
                $mockTestPathReturnValue = $false

                It 'Should call Import-LocalizedData and fallback to en-US if sv-SE language does not exist' {
                    Mock -CommandName Join-Path -MockWith {
                        return $ChildPath
                    } -Verifiable

                    { Get-LocalizedData -ResourceName 'DummyResource' -ScriptRoot '.' } | Should -Not -Throw

                    Assert-MockCalled -CommandName Join-Path -Exactly -Times 2 -Scope It
                    Assert-MockCalled -CommandName Test-Path -Exactly -Times 1 -Scope It
                    Assert-MockCalled -CommandName Import-LocalizedData -Exactly -Times 1 -Scope It
                }
            }
        }

        Context 'When loading localized data for English' {
            Mock -CommandName Join-Path -MockWith {
                return 'en-US'
            } -Verifiable

            $mockExpectedLanguagePath = 'en-US'
            $mockTestPathReturnValue = $true

            It 'Should call Import-LocalizedData with en-US language' {
                { Get-LocalizedData -ResourceName 'DummyResource' } | Should -Not -Throw
            }
        }

        Assert-VerifiableMock
    }

    Describe 'xWebAdministration.Common\New-InvalidResultException' {
        Context 'When calling with Message parameter only' {
            It 'Should throw the correct error' {
                $mockErrorMessage = 'Mocked error'

                { New-InvalidResultException -Message $mockErrorMessage } | Should -Throw $mockErrorMessage
            }
        }

        Context 'When calling with both the Message and ErrorRecord parameter' {
            It 'Should throw the correct error' {
                $mockErrorMessage = 'Mocked error'
                $mockExceptionErrorMessage = 'Mocked exception error message'

                $mockException = New-Object -TypeName 'System.Exception' -ArgumentList $mockExceptionErrorMessage
                $mockErrorRecord = New-Object -TypeName 'System.Management.Automation.ErrorRecord' -ArgumentList @($mockException, $null, 'InvalidResult', $null)

                { New-InvalidResultException -Message $mockErrorMessage -ErrorRecord $mockErrorRecord } | Should -Throw ('System.Exception: {0} ---> System.Exception: {1}' -f $mockErrorMessage, $mockExceptionErrorMessage)
            }
        }

        Assert-VerifiableMock
    }

    Describe 'xWebAdministration.Common\New-ObjectNotFoundException' {
        Context 'When calling with Message parameter only' {
            It 'Should throw the correct error' {
                $mockErrorMessage = 'Mocked error'

                { New-ObjectNotFoundException -Message $mockErrorMessage } | Should -Throw $mockErrorMessage
            }
        }

        Context 'When calling with both the Message and ErrorRecord parameter' {
            It 'Should throw the correct error' {
                $mockErrorMessage = 'Mocked error'
                $mockExceptionErrorMessage = 'Mocked exception error message'

                $mockException = New-Object -TypeName 'System.Exception' -ArgumentList $mockExceptionErrorMessage
                $mockErrorRecord = New-Object -TypeName 'System.Management.Automation.ErrorRecord' -ArgumentList @($mockException, $null, 'InvalidResult', $null)

                { New-ObjectNotFoundException -Message $mockErrorMessage -ErrorRecord $mockErrorRecord } | Should -Throw ('System.Exception: {0} ---> System.Exception: {1}' -f $mockErrorMessage, $mockExceptionErrorMessage)
            }
        }

        Assert-VerifiableMock
    }

    Describe 'xWebAdministration.Common\New-InvalidOperationException' {
        Context 'When calling with Message parameter only' {
            It 'Should throw the correct error' {
                $mockErrorMessage = 'Mocked error'

                { New-InvalidOperationException -Message $mockErrorMessage } | Should -Throw $mockErrorMessage
            }
        }

        Context 'When calling with both the Message and ErrorRecord parameter' {
            It 'Should throw the correct error' {
                $mockErrorMessage = 'Mocked error'
                $mockExceptionErrorMessage = 'Mocked exception error message'

                $mockException = New-Object -TypeName 'System.Exception' -ArgumentList $mockExceptionErrorMessage
                $mockErrorRecord = New-Object -TypeName 'System.Management.Automation.ErrorRecord' -ArgumentList @($mockException, $null, 'InvalidResult', $null)

                { New-InvalidOperationException -Message $mockErrorMessage -ErrorRecord $mockErrorRecord } | Should -Throw ('System.InvalidOperationException: {0} ---> System.Exception: {1}' -f $mockErrorMessage, $mockExceptionErrorMessage)
            }
        }

        Assert-VerifiableMock
    }

    Describe 'xWebAdministration.Common\New-InvalidArgumentException' {
        Context 'When calling with both the Message and ArgumentName parameter' {
            It 'Should throw the correct error' {
                $mockErrorMessage = 'Mocked error'
                $mockArgumentName = 'MockArgument'

                { New-InvalidArgumentException -Message $mockErrorMessage -ArgumentName $mockArgumentName } | Should -Throw ('Parameter name: {0}' -f $mockArgumentName)
            }
        }

        Assert-VerifiableMock
    }

    Describe 'DscResource.Common\Start-ProcessWithTimeout' {
        Context 'When starting a process successfully' {
            It 'Should return exit code 0' {
                $startProcessWithTimeoutParameters = @{
                    FilePath = 'powershell.exe'
                    ArgumentList = '-Command &{Start-Sleep -Seconds 2}'
                    Timeout = 300
                }

                $processExitCode = Start-ProcessWithTimeout @startProcessWithTimeoutParameters
                $processExitCode | Should -BeExactly 0
            }
        }

        Context 'When starting a process and the process does not finish before the timeout period' {
            It 'Should throw an error message' {
                $startProcessWithTimeoutParameters = @{
                    FilePath = 'powershell.exe'
                    ArgumentList = '-Command &{Start-Sleep -Seconds 4}'
                    Timeout = 2
                }

                { Start-ProcessWithTimeout @startProcessWithTimeoutParameters } | Should -Throw -ErrorId 'ProcessNotTerminated,Microsoft.PowerShell.Commands.WaitProcessCommand'
            }
        }
    }

    Describe 'xWebAdministration.Common\Assert-Module' {
        BeforeAll {
            $testModuleName = 'TestModule'
        }

        Context 'When module is not installed' {
            BeforeAll {
                Mock -CommandName Get-Module
            }

            It 'Should throw the correct error' {
                { Assert-Module -ModuleName $testModuleName } | Should -Throw ($script:localizedData.RoleNotFoundError -f $testModuleName)
            }
        }

        Context 'When module is available' {
            BeforeAll {
                Mock -CommandName Import-Module
                Mock -CommandName Get-Module -MockWith {
                    return @{
                        Name = $testModuleName
                    }
                }
            }

            Context 'When module should not be imported' {
                It 'Should not throw an error' {
                    { Assert-Module -ModuleName $testModuleName } | Should -Not -Throw

                    Assert-MockCalled -CommandName Import-Module -Exactly -Times 0 -Scope It
                }
            }

            Context 'When module should be imported' {
                It 'Should not throw an error' {
                    { Assert-Module -ModuleName $testModuleName -ImportModule } | Should -Not -Throw

                    Assert-MockCalled -CommandName Import-Module -Exactly -Times 1 -Scope It
                }
            }
        }
    }

    Describe 'DscResource.Common\Test-DscPropertyState' -Tag 'TestDscPropertyState' {
        Context 'When comparing tables' {
            It 'Should return true for two identical tables' {
                $mockValues = @{
                    CurrentValue = 'Test'
                    DesiredValue = 'Test'
                }

                Test-DscPropertyState -Values $mockValues | Should -BeTrue
            }
        }

        Context 'When comparing strings' {
            It 'Should return false when a value is different for [System.String]' {
                $mockValues = @{
                    CurrentValue = [System.String] 'something'
                    DesiredValue = [System.String] 'test'
                }

                Test-DscPropertyState -Values $mockValues | Should -BeFalse
            }

            It 'Should return false when a String value is missing' {
                $mockValues = @{
                    CurrentValue = $null
                    DesiredValue = [System.String] 'Something'
                }

                Test-DscPropertyState -Values $mockValues | Should -BeFalse
            }

            It 'Should return true when two strings are equal' {
                $mockValues = @{
                    CurrentValue = [System.String] 'Something'
                    DesiredValue = [System.String] 'Something'
                }

                Test-DscPropertyState -Values $mockValues | Should -Be $true
            }
        }

        Context 'When comparing integers' {
            It 'Should return false when a value is different for [System.Int32]' {
                $mockValues = @{
                    CurrentValue = [System.Int32] 1
                    DesiredValue = [System.Int32] 2
                }

                Test-DscPropertyState -Values $mockValues | Should -BeFalse
            }

            It 'Should return true when the values are the same for [System.Int32]' {
                $mockValues = @{
                    CurrentValue = [System.Int32] 2
                    DesiredValue = [System.Int32] 2
                }

                Test-DscPropertyState -Values $mockValues | Should -Be $true
            }

            It 'Should return false when a value is different for [System.UInt32]' {
                $mockValues = @{
                    CurrentValue = [System.UInt32] 1
                    DesiredValue = [System.UInt32] 2
                }

                Test-DscPropertyState -Values $mockValues | Should -Be $false
            }

            It 'Should return true when the values are the same for [System.UInt32]' {
                $mockValues = @{
                    CurrentValue = [System.UInt32] 2
                    DesiredValue = [System.UInt32] 2
                }

                Test-DscPropertyState -Values $mockValues | Should -Be $true
            }

            It 'Should return false when a value is different for [System.Int16]' {
                $mockValues = @{
                    CurrentValue = [System.Int16] 1
                    DesiredValue = [System.Int16] 2
                }

                Test-DscPropertyState -Values $mockValues | Should -BeFalse
            }

            It 'Should return true when the values are the same for [System.Int16]' {
                $mockValues = @{
                    CurrentValue = [System.Int16] 2
                    DesiredValue = [System.Int16] 2
                }

                Test-DscPropertyState -Values $mockValues | Should -Be $true
            }

            It 'Should return false when a value is different for [System.UInt16]' {
                $mockValues = @{
                    CurrentValue = [System.UInt16] 1
                    DesiredValue = [System.UInt16] 2
                }

                Test-DscPropertyState -Values $mockValues | Should -BeFalse
            }

            It 'Should return true when the values are the same for [System.UInt16]' {
                $mockValues = @{
                    CurrentValue = [System.UInt16] 2
                    DesiredValue = [System.UInt16] 2
                }

                Test-DscPropertyState -Values $mockValues | Should -Be $true
            }

            It 'Should return false when a Integer value is missing' {
                $mockValues = @{
                    CurrentValue = $null
                    DesiredValue = [System.Int32] 1
                }

                Test-DscPropertyState -Values $mockValues | Should -BeFalse
            }
        }

        Context 'When comparing booleans' {
            It 'Should return false when a value is different for [System.Boolean]' {
                $mockValues = @{
                    CurrentValue = [System.Boolean] $true
                    DesiredValue = [System.Boolean] $false
                }

                Test-DscPropertyState -Values $mockValues | Should -BeFalse
            }

            It 'Should return false when a Boolean value is missing' {
                $mockValues = @{
                    CurrentValue = $null
                    DesiredValue = [System.Boolean] $true
                }

                Test-DscPropertyState -Values $mockValues | Should -BeFalse
            }
        }

        Context 'When comparing arrays' {
            It 'Should return true when evaluating an array' {
                $mockValues = @{
                    CurrentValue = @('1','2')
                    DesiredValue = @('1','2')
                }

                Test-DscPropertyState -Values $mockValues | Should -BeTrue
            }

            It 'Should return false when evaluating an array with wrong values' {
                $mockValues = @{
                    CurrentValue = @('CurrentValueA','CurrentValueB')
                    DesiredValue = @('DesiredValue1','DesiredValue2')
                }

                Test-DscPropertyState -Values $mockValues | Should -BeFalse
            }

            It 'Should return false when evaluating an array, but the current value is $null' {
                $mockValues = @{
                    CurrentValue = $null
                    DesiredValue = @('1','2')
                }

                Test-DscPropertyState -Values $mockValues | Should -BeFalse
            }
        }

        Context -Name 'When passing invalid types for DesiredValue' {
            It 'Should write a warning when DesiredValue contain an unsupported type' {
                Mock -CommandName Write-Warning -Verifiable

                # This is a dummy type to test with a type that could never be a correct one.
                class MockUnknownType
                {
                    [ValidateNotNullOrEmpty()]
                    [System.String]
                    $Property1

                    [ValidateNotNullOrEmpty()]
                    [System.String]
                    $Property2

                    MockUnknownType()
                    {
                    }
                }

                $mockValues = @{
                    CurrentValue = New-Object -TypeName 'MockUnknownType'
                    DesiredValue = New-Object -TypeName 'MockUnknownType'
                }

                Test-DscPropertyState -Values $mockValues | Should -BeFalse

                Assert-MockCalled -CommandName Write-Warning -Exactly -Times 1 -Scope It
            }
        }

        Assert-VerifiableMock
    }

    Describe 'xWebAdministration.Common\Compare-ResourcePropertyState' {
        Context 'When one property is in desired state' {
            BeforeAll {
                $mockCurrentValues = @{
                    ComputerName = 'DC01'
                }

                $mockDesiredValues = @{
                    ComputerName = 'DC01'
                }
            }

            It 'Should return the correct values' {
                $compareTargetResourceStateParameters = @{
                    CurrentValues = $mockCurrentValues
                    DesiredValues = $mockDesiredValues
                }

                $compareTargetResourceStateResult = Compare-ResourcePropertyState @compareTargetResourceStateParameters
                $compareTargetResourceStateResult | Should -HaveCount 1
                $compareTargetResourceStateResult.ParameterName | Should -Be 'ComputerName'
                $compareTargetResourceStateResult.Expected | Should -Be 'DC01'
                $compareTargetResourceStateResult.Actual | Should -Be 'DC01'
                $compareTargetResourceStateResult.InDesiredState | Should -BeTrue
            }
        }

        Context 'When two properties are in desired state' {
            BeforeAll {
                $mockCurrentValues = @{
                    ComputerName = 'DC01'
                    Location = 'Sweden'
                }

                $mockDesiredValues = @{
                    ComputerName = 'DC01'
                    Location = 'Sweden'
                }
            }

            It 'Should return the correct values' {
                $compareTargetResourceStateParameters = @{
                    CurrentValues = $mockCurrentValues
                    DesiredValues = $mockDesiredValues
                }

                $compareTargetResourceStateResult = Compare-ResourcePropertyState @compareTargetResourceStateParameters
                $compareTargetResourceStateResult | Should -HaveCount 2
                $compareTargetResourceStateResult[0].ParameterName | Should -Be 'ComputerName'
                $compareTargetResourceStateResult[0].Expected | Should -Be 'DC01'
                $compareTargetResourceStateResult[0].Actual | Should -Be 'DC01'
                $compareTargetResourceStateResult[0].InDesiredState | Should -BeTrue
                $compareTargetResourceStateResult[1].ParameterName | Should -Be 'Location'
                $compareTargetResourceStateResult[1].Expected | Should -Be 'Sweden'
                $compareTargetResourceStateResult[1].Actual | Should -Be 'Sweden'
                $compareTargetResourceStateResult[1].InDesiredState | Should -BeTrue
            }
        }

        Context 'When passing just one property and that property is not in desired state' {
            BeforeAll {
                $mockCurrentValues = @{
                    ComputerName = 'DC01'
                }

                $mockDesiredValues = @{
                    ComputerName = 'APP01'
                }
            }

            It 'Should return the correct values' {
                $compareTargetResourceStateParameters = @{
                    CurrentValues = $mockCurrentValues
                    DesiredValues = $mockDesiredValues
                }

                $compareTargetResourceStateResult = Compare-ResourcePropertyState @compareTargetResourceStateParameters
                $compareTargetResourceStateResult | Should -HaveCount 1
                $compareTargetResourceStateResult.ParameterName | Should -Be 'ComputerName'
                $compareTargetResourceStateResult.Expected | Should -Be 'APP01'
                $compareTargetResourceStateResult.Actual | Should -Be 'DC01'
                $compareTargetResourceStateResult.InDesiredState | Should -BeFalse
            }
        }

        Context 'When passing two properties and one property is not in desired state' {
            BeforeAll {
                $mockCurrentValues = @{
                    ComputerName = 'DC01'
                    Location = 'Sweden'
                }

                $mockDesiredValues = @{
                    ComputerName = 'DC01'
                    Location = 'Europe'
                }
            }

            It 'Should return the correct values' {
                $compareTargetResourceStateParameters = @{
                    CurrentValues = $mockCurrentValues
                    DesiredValues = $mockDesiredValues
                }

                $compareTargetResourceStateResult = Compare-ResourcePropertyState @compareTargetResourceStateParameters
                $compareTargetResourceStateResult | Should -HaveCount 2
                $compareTargetResourceStateResult[0].ParameterName | Should -Be 'ComputerName'
                $compareTargetResourceStateResult[0].Expected | Should -Be 'DC01'
                $compareTargetResourceStateResult[0].Actual | Should -Be 'DC01'
                $compareTargetResourceStateResult[0].InDesiredState | Should -BeTrue
                $compareTargetResourceStateResult[1].ParameterName | Should -Be 'Location'
                $compareTargetResourceStateResult[1].Expected | Should -Be 'Europe'
                $compareTargetResourceStateResult[1].Actual | Should -Be 'Sweden'
                $compareTargetResourceStateResult[1].InDesiredState | Should -BeFalse
            }
        }

        Context 'When passing a common parameter set to desired value' {
            BeforeAll {
                $mockCurrentValues = @{
                    ComputerName = 'DC01'
                }

                $mockDesiredValues = @{
                    ComputerName = 'DC01'
                    Verbose = $true
                }
            }

            It 'Should return the correct values' {
                $compareTargetResourceStateParameters = @{
                    CurrentValues = $mockCurrentValues
                    DesiredValues = $mockDesiredValues
                }

                $compareTargetResourceStateResult = Compare-ResourcePropertyState @compareTargetResourceStateParameters
                $compareTargetResourceStateResult | Should -HaveCount 1
                $compareTargetResourceStateResult.ParameterName | Should -Be 'ComputerName'
                $compareTargetResourceStateResult.Expected | Should -Be 'DC01'
                $compareTargetResourceStateResult.Actual | Should -Be 'DC01'
                $compareTargetResourceStateResult.InDesiredState | Should -BeTrue
            }
        }

        Context 'When using parameter Properties to compare desired values' {
            BeforeAll {
                $mockCurrentValues = @{
                    ComputerName = 'DC01'
                    Location = 'Sweden'
                }

                $mockDesiredValues = @{
                    ComputerName = 'DC01'
                    Location = 'Europe'
                }
            }

            It 'Should return the correct values' {
                $compareTargetResourceStateParameters = @{
                    CurrentValues = $mockCurrentValues
                    DesiredValues = $mockDesiredValues
                    Properties = @(
                        'ComputerName'
                    )
                }

                $compareTargetResourceStateResult = Compare-ResourcePropertyState @compareTargetResourceStateParameters
                $compareTargetResourceStateResult | Should -HaveCount 1
                $compareTargetResourceStateResult.ParameterName | Should -Be 'ComputerName'
                $compareTargetResourceStateResult.Expected | Should -Be 'DC01'
                $compareTargetResourceStateResult.Actual | Should -Be 'DC01'
                $compareTargetResourceStateResult.InDesiredState | Should -BeTrue
            }
        }

        Context 'When using parameter Properties and IgnoreProperties to compare desired values' {
            BeforeAll {
                $mockCurrentValues = @{
                    ComputerName = 'DC01'
                    Location = 'Sweden'
                    Ensure = 'Present'
                }

                $mockDesiredValues = @{
                    ComputerName = 'DC01'
                    Location = 'Europe'
                    Ensure = 'Absent'
                }
            }

            It 'Should return the correct values' {
                $compareTargetResourceStateParameters = @{
                    CurrentValues = $mockCurrentValues
                    DesiredValues = $mockDesiredValues
                    IgnoreProperties = @(
                        'Ensure'
                    )
                }

                $compareTargetResourceStateResult = Compare-ResourcePropertyState @compareTargetResourceStateParameters
                $compareTargetResourceStateResult | Should -HaveCount 2
                $compareTargetResourceStateResult[0].ParameterName | Should -Be 'ComputerName'
                $compareTargetResourceStateResult[0].Expected | Should -Be 'DC01'
                $compareTargetResourceStateResult[0].Actual | Should -Be 'DC01'
                $compareTargetResourceStateResult[0].InDesiredState | Should -BeTrue
                $compareTargetResourceStateResult[1].ParameterName | Should -Be 'Location'
                $compareTargetResourceStateResult[1].Expected | Should -Be 'Europe'
                $compareTargetResourceStateResult[1].Actual | Should -Be 'Sweden'
                $compareTargetResourceStateResult[1].InDesiredState | Should -BeFalse
            }
        }

        Context 'When using parameter Properties and IgnoreProperties to compare desired values' {
            BeforeAll {
                $mockCurrentValues = @{
                    ComputerName = 'DC01'
                    Location = 'Sweden'
                    Ensure = 'Present'
                }

                $mockDesiredValues = @{
                    ComputerName = 'DC01'
                    Location = 'Europe'
                    Ensure = 'Absent'
                }
            }

            It 'Should return and empty array' {
                $compareTargetResourceStateParameters = @{
                    CurrentValues = $mockCurrentValues
                    DesiredValues = $mockDesiredValues
                    Properties = @(
                        'ComputerName'
                    )
                    IgnoreProperties = @(
                        'ComputerName'
                    )
                }

                $compareTargetResourceStateResult = Compare-ResourcePropertyState @compareTargetResourceStateParameters
                $compareTargetResourceStateResult | Should -BeNullOrEmpty
            }
        }
    }

    Describe 'xWebAdministration.Common\New-CimCredentialInstance' {
        Context 'When creating a new MSFT_Credential CIM instance credential object' {
            BeforeAll {
                $mockAdministratorUser = 'admin@contoso.com'
                $mockAdministratorPassword = 'P@ssw0rd-12P@ssw0rd-12'
                $mockAdministratorCredential = New-Object -TypeName 'System.Management.Automation.PSCredential' -ArgumentList @(
                    $mockAdministratorUser,
                    ($mockAdministratorPassword | ConvertTo-SecureString -AsPlainText -Force)
                )
            }

            It 'Should return the correct values' {
                $newCimCredentialInstanceResult = New-CimCredentialInstance -Credential $mockAdministratorCredential
                $newCimCredentialInstanceResult | Should -BeOfType 'Microsoft.Management.Infrastructure.CimInstance'
                $newCimCredentialInstanceResult.CimClass.CimClassName | Should -Be 'MSFT_Credential'
                $newCimCredentialInstanceResult.UserName | Should -Be $mockAdministratorUser
                $newCimCredentialInstanceResult.Password | Should -BeNullOrEmpty
            }
        }
    }

    Describe 'xWebAdministration.Common\Find-Certificate' {

        # Download and dot source the New-SelfSignedCertificateEx script
        . (Install-NewSelfSignedCertificateExScript)

        # Generate the Valid certificate for testing but remove it from the store straight away
        $certDNSNames = @('www.fabrikam.com', 'www.contoso.com')
        $certDNSNamesReverse = @('www.contoso.com', 'www.fabrikam.com')
        $certDNSNamesNoMatch = $certDNSNames + @('www.nothere.com')
        $certKeyUsage = @('DigitalSignature','DataEncipherment')
        $certKeyUsageReverse = @('DataEncipherment','DigitalSignature')
        $certKeyUsageNoMatch = $certKeyUsage + @('KeyEncipherment')
        $certEKU = @('Server Authentication','Client authentication')
        $certEKUReverse = @('Client authentication','Server Authentication')
        $certEKUNoMatch = $certEKU + @('Encrypting File System')
        $certSubject = 'CN=contoso, DC=com'
        $certSubjectLong = 'CN=contoso, E=myemail@contoso.com, O=Fabrikam., OU=IT, L=Location, S=State, C=Country'
        $certSubjectNoSpace = 'CN=contoso,E=myemail@contoso.com,O=Fabrikam.,OU=IT,L=Location,S=State,C=Country'
        $certSubjectLongReverse = 'E=myemail@contoso.com,O=Fabrikam.,L=Location,CN=contoso,OU=IT,S=State,C=Country'
        $certFriendlyName = 'Contoso Test Cert'
        $validCert = New-SelfSignedCertificateEx `
            -Subject $certSubject `
            -KeyUsage $certKeyUsage `
            -KeySpec 'Exchange' `
            -EKU $certEKU `
            -SubjectAlternativeName $certDNSNames `
            -FriendlyName $certFriendlyName `
            -StoreLocation 'CurrentUser' `
            -Exportable
        # Pull the generated certificate from the store so we have the friendlyname
        $validThumbprint = $validCert.Thumbprint
        $validCert = Get-Item -Path "cert:\CurrentUser\My\$validThumbprint"
        Remove-Item -Path $validCert.PSPath -Force

        # Generate the long subject certificate for testing but remove it from the store straight away
        $validCertSubjectLong = New-SelfSignedCertificateEx `
            -Subject $certSubjectLong `
            -KeyUsage $certKeyUsage `
            -KeySpec 'Exchange' `
            -EKU $certEKU `
            -SubjectAlternativeName $certDNSNames `
            -FriendlyName $certFriendlyName `
            -StoreLocation 'CurrentUser' `
            -Exportable
        # Pull the generated certificate from the store so we have the friendlyname
        $longThumbprint = $validCertSubjectLong.Thumbprint
        $validCertSubjectLong = Get-Item -Path "cert:\CurrentUser\My\$longThumbprint"
        Remove-Item -Path $validCertSubjectLong.PSPath -Force

        # Generate the Expired certificate for testing but remove it from the store straight away
        $expiredCert = New-SelfSignedCertificateEx `
            -Subject $certSubject `
            -KeyUsage $certKeyUsage `
            -KeySpec 'Exchange' `
            -EKU $certEKU `
            -SubjectAlternativeName $certDNSNames `
            -FriendlyName $certFriendlyName `
            -NotBefore ((Get-Date) - (New-TimeSpan -Days 2)) `
            -NotAfter ((Get-Date) - (New-TimeSpan -Days 1)) `
            -StoreLocation 'CurrentUser' `
            -Exportable
        # Pull the generated certificate from the store so we have the friendlyname
        $expiredThumbprint = $expiredCert.Thumbprint
        $expiredCert = Get-Item -Path "cert:\CurrentUser\My\$expiredThumbprint"
        Remove-Item -Path $expiredCert.PSPath -Force

        $nocertThumbprint = '1111111111111111111111111111111111111111'

        # Dynamic mock content for Get-ChildItem
        $mockGetChildItem = {
            switch ( $Path )
            {
                'cert:\LocalMachine\My'
                {
                    return @( $validCert )
                }

                'cert:\LocalMachine\NoCert'
                {
                    return @()
                }

                'cert:\LocalMachine\TwoCerts'
                {
                    return @( $expiredCert, $validCert )
                }

                'cert:\LocalMachine\Expired'
                {
                    return @( $expiredCert )
                }

                'cert:\LocalMachine\LongSubject'
                {
                    return @( $validCertSubjectLong )
                }

                default
                {
                    throw 'mock called with unexpected value {0}' -f $Path
                }
            }
        }

        BeforeEach {
            Mock `
                -CommandName Test-Path `
                -MockWith { $true }

            Mock `
                -CommandName Get-ChildItem `
                -MockWith $mockGetChildItem
        }

        Context 'Thumbprint only is passed and matching certificate exists' {
            It 'should not throw exception' {
                { $script:result = Find-Certificate -Thumbprint $validThumbprint } | Should Not Throw
            }

            It 'should return expected certificate' {
                $script:result.Thumbprint | Should Be $validThumbprint
            }

            It 'should call expected mocks' {
                Assert-MockCalled -CommandName Test-Path -Exactly -Times 1
                Assert-MockCalled -CommandName Get-ChildItem -Exactly -Times 1
            }
        }

        Context 'Thumbprint only is passed and matching certificate does not exist' {
            It 'should not throw exception' {
                { $script:result = Find-Certificate -Thumbprint $nocertThumbprint } | Should Not Throw
            }

            It 'should return null' {
                $script:result | Should BeNullOrEmpty
            }

            It 'should call expected mocks' {
                Assert-MockCalled -CommandName Test-Path -Exactly -Times 1
                Assert-MockCalled -CommandName Get-ChildItem -Exactly -Times 1
            }
        }

        Context 'FriendlyName only is passed and matching certificate exists' {
            It 'should not throw exception' {
                { $script:result = Find-Certificate -FriendlyName $certFriendlyName } | Should Not Throw
            }

            It 'should return expected certificate' {
                $script:result.Thumbprint | Should Be $validThumbprint
            }

            It 'should call expected mocks' {
                Assert-MockCalled -CommandName Test-Path -Exactly -Times 1
                Assert-MockCalled -CommandName Get-ChildItem -Exactly -Times 1
            }
        }

        Context 'FriendlyName only is passed and matching certificate does not exist' {
            It 'should not throw exception' {
                { $script:result = Find-Certificate -FriendlyName 'Does Not Exist' } | Should Not Throw
            }

            It 'should return null' {
                $script:result | Should BeNullOrEmpty
            }

            It 'should call expected mocks' {
                Assert-MockCalled -CommandName Test-Path -Exactly -Times 1
                Assert-MockCalled -CommandName Get-ChildItem -Exactly -Times 1
            }
        }

        Context 'Subject only is passed and matching certificate exists' {
            It 'should not throw exception' {
                { $script:result = Find-Certificate -Subject $certSubject } | Should Not Throw
            }

            It 'should return expected certificate' {
                $script:result.Thumbprint | Should Be $validThumbprint
            }

            It 'should call expected mocks' {
                Assert-MockCalled -CommandName Test-Path -Exactly -Times 1
                Assert-MockCalled -CommandName Get-ChildItem -Exactly -Times 1
            }
        }

        Context 'Subject only is passed and matching certificate does not exist' {
            It 'should not throw exception' {
                { $script:result = Find-Certificate -Subject 'CN=Does Not Exist' } | Should Not Throw
            }

            It 'should return null' {
                $script:result | Should BeNullOrEmpty
            }

            It 'should call expected mocks' {
                Assert-MockCalled -CommandName Test-Path -Exactly -Times 1
                Assert-MockCalled -CommandName Get-ChildItem -Exactly -Times 1
            }
        }

        Context 'Subject only is passed and certificate with a different subject order exists' {
            It 'should not throw exception' {
                { $script:result = Find-Certificate -Subject $certSubjectLongReverse -Store 'LongSubject' } | Should Not Throw
            }

            It 'should return expected certificate' {
                $script:result.Thumbprint | Should Be $longThumbprint
            }

            It 'should call expected mocks' {
                Assert-MockCalled -CommandName Test-Path -Exactly -Times 1
                Assert-MockCalled -CommandName Get-ChildItem -Exactly -Times 1
            }
        }

        Context 'Subject only is passed and certificate subject without spaces exists' {
            It 'should not throw exception' {
                { $script:result = Find-Certificate -Subject $certSubjectNoSpace -Store 'LongSubject' } | Should Not Throw
            }

            It 'should return expected certificate' {
                $script:result.Thumbprint | Should Be $longThumbprint
            }

            It 'should call expected mocks' {
                Assert-MockCalled -CommandName Test-Path -Exactly -Times 1
                Assert-MockCalled -CommandName Get-ChildItem -Exactly -Times 1
            }
        }

        Context 'Issuer only is passed and matching certificate exists' {
            It 'should not throw exception' {
                { $script:result = Find-Certificate -Issuer $certSubject } | Should Not Throw
            }

            It 'should return expected certificate' {
                $script:result.Thumbprint | Should Be $validThumbprint
            }

            It 'should call expected mocks' {
                Assert-MockCalled -CommandName Test-Path -Exactly -Times 1
                Assert-MockCalled -CommandName Get-ChildItem -Exactly -Times 1
            }
        }

        Context 'Issuer only is passed and matching certificate does not exist' {
            It 'should not throw exception' {
                { $script:result = Find-Certificate -Issuer 'CN=Does Not Exist' } | Should Not Throw
            }

            It 'should return null' {
                $script:result | Should BeNullOrEmpty
            }

            It 'should call expected mocks' {
                Assert-MockCalled -CommandName Test-Path -Exactly -Times 1
                Assert-MockCalled -CommandName Get-ChildItem -Exactly -Times 1
            }
        }

        Context 'DNSName only is passed and matching certificate exists' {
            It 'should not throw exception' {
                { $script:result = Find-Certificate -DnsName $certDNSNames } | Should Not Throw
            }

            It 'should return expected certificate' {
                $script:result.Thumbprint | Should Be $validThumbprint
            }

            It 'should call expected mocks' {
                Assert-MockCalled -CommandName Test-Path -Exactly -Times 1
                Assert-MockCalled -CommandName Get-ChildItem -Exactly -Times 1
            }
        }

        Context 'DNSName only is passed in reversed order and matching certificate exists' {
            It 'should not throw exception' {
                { $script:result = Find-Certificate -DnsName $certDNSNamesReverse } | Should Not Throw
            }

            It 'should return expected certificate' {
                $script:result.Thumbprint | Should Be $validThumbprint
            }

            It 'should call expected mocks' {
                Assert-MockCalled -CommandName Test-Path -Exactly -Times 1
                Assert-MockCalled -CommandName Get-ChildItem -Exactly -Times 1
            }
        }

        Context 'DNSName only is passed with only one matching DNS name and matching certificate exists' {
            It 'should not throw exception' {
                { $script:result = Find-Certificate -DnsName $certDNSNames[0] } | Should Not Throw
            }

            It 'should return expected certificate' {
                $script:result.Thumbprint | Should Be $validThumbprint
            }

            It 'should call expected mocks' {
                Assert-MockCalled -CommandName Test-Path -Exactly -Times 1
                Assert-MockCalled -CommandName Get-ChildItem -Exactly -Times 1
            }
        }

        Context 'DNSName only is passed but an entry is missing and matching certificate does not exist' {
            It 'should not throw exception' {
                { $script:result = Find-Certificate -DnsName $certDNSNamesNoMatch } | Should Not Throw
            }

            It 'should return null' {
                $script:result | Should BeNullOrEmpty
            }

            It 'should call expected mocks' {
                Assert-MockCalled -CommandName Test-Path -Exactly -Times 1
                Assert-MockCalled -CommandName Get-ChildItem -Exactly -Times 1
            }
        }

        Context 'KeyUsage only is passed and matching certificate exists' {
            It 'should not throw exception' {
                { $script:result = Find-Certificate -KeyUsage $certKeyUsage } | Should Not Throw
            }

            It 'should return expected certificate' {
                $script:result.Thumbprint | Should Be $validThumbprint
            }

            It 'should call expected mocks' {
                Assert-MockCalled -CommandName Test-Path -Exactly -Times 1
                Assert-MockCalled -CommandName Get-ChildItem -Exactly -Times 1
            }
        }

        Context 'KeyUsage only is passed in reversed order and matching certificate exists' {
            It 'should not throw exception' {
                { $script:result = Find-Certificate -KeyUsage $certKeyUsageReverse } | Should Not Throw
            }

            It 'should return expected certificate' {
                $script:result.Thumbprint | Should Be $validThumbprint
            }

            It 'should call expected mocks' {
                Assert-MockCalled -CommandName Test-Path -Exactly -Times 1
                Assert-MockCalled -CommandName Get-ChildItem -Exactly -Times 1
            }
        }

        Context 'KeyUsage only is passed with only one matching DNS name and matching certificate exists' {
            It 'should not throw exception' {
                { $script:result = Find-Certificate -KeyUsage $certKeyUsage[0] } | Should Not Throw
            }

            It 'should return expected certificate' {
                $script:result.Thumbprint | Should Be $validThumbprint
            }

            It 'should call expected mocks' {
                Assert-MockCalled -CommandName Test-Path -Exactly -Times 1
                Assert-MockCalled -CommandName Get-ChildItem -Exactly -Times 1
            }
        }

        Context 'KeyUsage only is passed but an entry is missing and matching certificate does not exist' {
            It 'should not throw exception' {
                { $script:result = Find-Certificate -KeyUsage $certKeyUsageNoMatch } | Should Not Throw
            }

            It 'should return null' {
                $script:result | Should BeNullOrEmpty
            }

            It 'should call expected mocks' {
                Assert-MockCalled -CommandName Test-Path -Exactly -Times 1
                Assert-MockCalled -CommandName Get-ChildItem -Exactly -Times 1
            }
        }

        Context 'EnhancedKeyUsage only is passed and matching certificate exists' {
            It 'should not throw exception' {
                { $script:result = Find-Certificate -EnhancedKeyUsage $certEKU } | Should Not Throw
            }

            It 'should return expected certificate' {
                $script:result.Thumbprint | Should Be $validThumbprint
            }

            It 'should call expected mocks' {
                Assert-MockCalled -CommandName Test-Path -Exactly -Times 1
                Assert-MockCalled -CommandName Get-ChildItem -Exactly -Times 1
            }
        }

        Context 'EnhancedKeyUsage only is passed in reversed order and matching certificate exists' {
            It 'should not throw exception' {
                { $script:result = Find-Certificate -EnhancedKeyUsage $certEKUReverse } | Should Not Throw
            }

            It 'should return expected certificate' {
                $script:result.Thumbprint | Should Be $validThumbprint
            }

            It 'should call expected mocks' {
                Assert-MockCalled -CommandName Test-Path -Exactly -Times 1
                Assert-MockCalled -CommandName Get-ChildItem -Exactly -Times 1
            }
        }

        Context 'EnhancedKeyUsage only is passed with only one matching DNS name and matching certificate exists' {
            It 'should not throw exception' {
                { $script:result = Find-Certificate -EnhancedKeyUsage $certEKU[0] } | Should Not Throw
            }

            It 'should return expected certificate' {
                $script:result.Thumbprint | Should Be $validThumbprint
            }

            It 'should call expected mocks' {
                Assert-MockCalled -CommandName Test-Path -Exactly -Times 1
                Assert-MockCalled -CommandName Get-ChildItem -Exactly -Times 1
            }
        }

        Context 'EnhancedKeyUsage only is passed but an entry is missing and matching certificate does not exist' {
            It 'should not throw exception' {
                { $script:result = Find-Certificate -EnhancedKeyUsage $certEKUNoMatch } | Should Not Throw
            }

            It 'should return null' {
                $script:result | Should BeNullOrEmpty
            }

            It 'should call expected mocks' {
                Assert-MockCalled -CommandName Test-Path -Exactly -Times 1
                Assert-MockCalled -CommandName Get-ChildItem -Exactly -Times 1
            }
        }

        Context 'Thumbprint only is passed and matching certificate does not exist in the store' {
            It 'should not throw exception' {
                { $script:result = Find-Certificate -Thumbprint $validThumbprint -Store 'NoCert'} | Should Not Throw
            }

            It 'should return null' {
                $script:result | Should BeNullOrEmpty
            }

            It 'should call expected mocks' {
                Assert-MockCalled -CommandName Test-Path -Exactly -Times 1
                Assert-MockCalled -CommandName Get-ChildItem -Exactly -Times 1
            }
        }

        Context 'FriendlyName only is passed and both valid and expired certificates exist' {
            It 'should not throw exception' {
                { $script:result = Find-Certificate -FriendlyName $certFriendlyName -Store 'TwoCerts' } | Should Not Throw
            }

            It 'should return expected certificate' {
                $script:result.Thumbprint | Should Be $validThumbprint
            }

            It 'should call expected mocks' {
                Assert-MockCalled -CommandName Test-Path -Exactly -Times 1
                Assert-MockCalled -CommandName Get-ChildItem -Exactly -Times 1
            }
        }

        Context 'FriendlyName only is passed and only expired certificates exist' {
            It 'should not throw exception' {
                { $script:result = Find-Certificate -FriendlyName $certFriendlyName -Store 'Expired' } | Should Not Throw
            }

            It 'should return expected certificate' {
                $script:result | Should BeNullOrEmpty
            }

            It 'should call expected mocks' {
                Assert-MockCalled -CommandName Test-Path -Exactly -Times 1
                Assert-MockCalled -CommandName Get-ChildItem -Exactly -Times 1
            }
        }

        Context 'FriendlyName only is passed and only expired certificates exist but allowexpired passed' {
            It 'should not throw exception' {
                { $script:result = Find-Certificate -FriendlyName $certFriendlyName -Store 'Expired' -AllowExpired:$true } | Should Not Throw
            }

            It 'should return expected certificate' {
                $script:result.Thumbprint | Should Be $expiredThumbprint
            }

            It 'should call expected mocks' {
                Assert-MockCalled -CommandName Test-Path -Exactly -Times 1
                Assert-MockCalled -CommandName Get-ChildItem -Exactly -Times 1
            }
        }
    }

}
