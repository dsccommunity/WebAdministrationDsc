<#
    This module is loaded as a nested module when the WebAdministrationDsc module is imported,
    remove the module from the session to avoid the error message:

        Multiple Script modules named 'WebAdministrationDsc.Common'
        are currently loaded.  Make sure to remove any extra copies
        of the module from your session before testing.
#>
Get-Module -Name 'WebAdministrationDsc.Common' -All | Remove-Module -Force

#region HEADER
$script:projectPath = "$PSScriptRoot\..\.." | Convert-Path
$script:projectName = (Get-ChildItem -Path "$script:projectPath\*\*.psd1" | Where-Object -FilterScript {
        ($_.Directory.Name -match 'source|src' -or $_.Directory.Name -eq $_.BaseName) -and
        $(try { Test-ModuleManifest -Path $_.FullName -ErrorAction Stop } catch { $false })
    }).BaseName

$script:parentModule = Get-Module -Name $script:projectName -ListAvailable | Select-Object -First 1
$script:subModulesFolder = Join-Path -Path $script:parentModule.ModuleBase -ChildPath 'Modules'
Remove-Module -Name $script:parentModule -Force -ErrorAction 'SilentlyContinue'

$script:subModuleName = (Split-Path -Path $PSCommandPath -Leaf) -replace '\.Tests.ps1'
$script:subModuleFile = Join-Path -Path $script:subModulesFolder -ChildPath "$($script:subModuleName)"

Import-Module $script:subModuleFile -Force -ErrorAction Stop

Import-Module -Name PSPKI

#endregion HEADER

InModuleScope $script:subModuleName {
    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\TestHelper\CommonTestHelper.psm1') -Force

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

    Describe 'WebAdministrationDsc.Common\New-CimCredentialInstance' {
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

    Describe 'WebAdministrationDsc.Common\Find-Certificate' {

        # technet no longer exists, function added directly to commontesthelper.psm1
        # Download and dot source the New-SelfSignedCertificateEx script
        #. (Install-NewSelfSignedCertificateExScript)

        # Generate the Valid certificate for testing but remove it from the store straight away
        $certDNSNames = @('www.fabrikam.com', 'www.contoso.com')
        $certificateCreationDNSNames = @('dns:www.fabrikam.com', 'dns:www.contoso.com')
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
            -EnhancedKeyUsage $certEKU `
            -SubjectAlternativeName $certificateCreationDNSNames `
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
            -EnhancedKeyUsage $certEKU `
            -SubjectAlternativeName $certificateCreationDNSNames `
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
            -EnhancedKeyUsage $certEKU `
            -SubjectAlternativeName $certificateCreationDNSNames `
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
