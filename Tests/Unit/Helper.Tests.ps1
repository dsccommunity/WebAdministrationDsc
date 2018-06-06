$script:ModuleName = 'Helper'
$script:DSCModuleName = 'xWebAdministration'

#region HEADER
$script:moduleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
 if ( (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests'))) -or `
      (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1'))) )
{
    & git @('clone','https://github.com/PowerShell/DscResource.Tests.git',(Join-Path -Path $script:moduleRoot -ChildPath '\DSCResource.Tests\'))
}

Import-Module (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1') -Force
Import-Module (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResources\Helper.psm1')
#endregion

Import-Module (Join-Path -Path $script:moduleRoot -ChildPath 'Tests\TestHelper\CommonTestHelper.psm1') -Force -Global

# Begin Testing
try
{
    InModuleScope $script:ModuleName {

        Describe "$DSCResourceName\Find-Certificate" {

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

        Describe 'Get-LocalizedData' {
            $mockTestPath = {
                return $mockTestPathReturnValue
            }

            $mockImportLocalizedData = {
                $BaseDirectory | Should Be $mockExpectedLanguagePath
            }

            BeforeEach {
                Mock -CommandName Test-Path -MockWith $mockTestPath -Verifiable
                Mock -CommandName Import-LocalizedData -MockWith $mockImportLocalizedData -Verifiable
            }

            Context 'When loading localized data for English' {
                Mock -CommandName Join-Path -MockWith {
                    return 'en-US'
                } -Verifiable

                $mockExpectedLanguagePath = 'en-US'
                $mockTestPathReturnValue = $true

                It 'Should call Import-LocalizedData with en-US language' {
                    { Get-LocalizedData -ResourceName 'DummyResource' -ResourcePath ..\..\DSCResources\MSFT_xWebApplicationHandler\en-us\MSFT_xWebApplicationHandler.strings.psd1} | Should Not Throw
                }
            }

            Assert-VerifiableMock
        }
    }
}
finally
{
    #region FOOTER
    #endregion
}
