$script:ModuleName    = 'Helper'
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
    #region Pester Tests
    InModuleScope $script:ModuleName {
        $script:DSCResourceName = 'Helper'

        Describe "$DSCResourceName\Assert-Module" {

            Context 'WebAdminstration module is not installed' {

                Mock -CommandName Get-Module -MockWith { return $null }

                It 'Should throw an error' {
                    { Assert-Module } | Should Throw
                }
            }
        }

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
                It 'Should not throw exception' {
                    { $script:result = Find-Certificate -Thumbprint $validThumbprint } | Should Not Throw
                }

                It 'Should return expected certificate' {
                    $script:result.Thumbprint | Should Be $validThumbprint
                }

                It 'Should call expected mocks' {
                    Assert-MockCalled -CommandName Test-Path -Exactly -Times 1
                    Assert-MockCalled -CommandName Get-ChildItem -Exactly -Times 1
                }
            }

            Context 'Thumbprint only is passed and matching certificate does not exist' {
                It 'Should not throw exception' {
                    { $script:result = Find-Certificate -Thumbprint $nocertThumbprint } | Should Not Throw
                }

                It 'Should return null' {
                    $script:result | Should BeNullOrEmpty
                }

                It 'Should call expected mocks' {
                    Assert-MockCalled -CommandName Test-Path -Exactly -Times 1
                    Assert-MockCalled -CommandName Get-ChildItem -Exactly -Times 1
                }
            }

            Context 'FriendlyName only is passed and matching certificate exists' {
                It 'Should not throw exception' {
                    { $script:result = Find-Certificate -FriendlyName $certFriendlyName } | Should Not Throw
                }

                It 'Should return expected certificate' {
                    $script:result.Thumbprint | Should Be $validThumbprint
                }

                It 'Should call expected mocks' {
                    Assert-MockCalled -CommandName Test-Path -Exactly -Times 1
                    Assert-MockCalled -CommandName Get-ChildItem -Exactly -Times 1
                }
            }

            Context 'FriendlyName only is passed and matching certificate does not exist' {
                It 'Should not throw exception' {
                    { $script:result = Find-Certificate -FriendlyName 'Does Not Exist' } | Should Not Throw
                }

                It 'Should return null' {
                    $script:result | Should BeNullOrEmpty
                }

                It 'Should call expected mocks' {
                    Assert-MockCalled -CommandName Test-Path -Exactly -Times 1
                    Assert-MockCalled -CommandName Get-ChildItem -Exactly -Times 1
                }
            }

            Context 'Subject only is passed and matching certificate exists' {
                It 'Should not throw exception' {
                    { $script:result = Find-Certificate -Subject $certSubject } | Should Not Throw
                }

                It 'Should return expected certificate' {
                    $script:result.Thumbprint | Should Be $validThumbprint
                }

                It 'Should call expected mocks' {
                    Assert-MockCalled -CommandName Test-Path -Exactly -Times 1
                    Assert-MockCalled -CommandName Get-ChildItem -Exactly -Times 1
                }
            }

            Context 'Subject only is passed and matching certificate does not exist' {
                It 'Should not throw exception' {
                    { $script:result = Find-Certificate -Subject 'CN=Does Not Exist' } | Should Not Throw
                }

                It 'Should return null' {
                    $script:result | Should BeNullOrEmpty
                }

                It 'Should call expected mocks' {
                    Assert-MockCalled -CommandName Test-Path -Exactly -Times 1
                    Assert-MockCalled -CommandName Get-ChildItem -Exactly -Times 1
                }
            }

            Context 'Subject only is passed and certificate with a different subject order exists' {
                It 'Should not throw exception' {
                    { $script:result = Find-Certificate -Subject $certSubjectLongReverse -Store 'LongSubject' } | Should Not Throw
                }

                It 'Should return expected certificate' {
                    $script:result.Thumbprint | Should Be $longThumbprint
                }

                It 'Should call expected mocks' {
                    Assert-MockCalled -CommandName Test-Path -Exactly -Times 1
                    Assert-MockCalled -CommandName Get-ChildItem -Exactly -Times 1
                }
            }

            Context 'Subject only is passed and certificate subject without spaces exists' {
                It 'Should not throw exception' {
                    { $script:result = Find-Certificate -Subject $certSubjectNoSpace -Store 'LongSubject' } | Should Not Throw
                }

                It 'Should return expected certificate' {
                    $script:result.Thumbprint | Should Be $longThumbprint
                }

                It 'Should call expected mocks' {
                    Assert-MockCalled -CommandName Test-Path -Exactly -Times 1
                    Assert-MockCalled -CommandName Get-ChildItem -Exactly -Times 1
                }
            }

            Context 'Issuer only is passed and matching certificate exists' {
                It 'Should not throw exception' {
                    { $script:result = Find-Certificate -Issuer $certSubject } | Should Not Throw
                }

                It 'Should return expected certificate' {
                    $script:result.Thumbprint | Should Be $validThumbprint
                }

                It 'Should call expected mocks' {
                    Assert-MockCalled -CommandName Test-Path -Exactly -Times 1
                    Assert-MockCalled -CommandName Get-ChildItem -Exactly -Times 1
                }
            }

            Context 'Issuer only is passed and matching certificate does not exist' {
                It 'Should not throw exception' {
                    { $script:result = Find-Certificate -Issuer 'CN=Does Not Exist' } | Should Not Throw
                }

                It 'Should return null' {
                    $script:result | Should BeNullOrEmpty
                }

                It 'Should call expected mocks' {
                    Assert-MockCalled -CommandName Test-Path -Exactly -Times 1
                    Assert-MockCalled -CommandName Get-ChildItem -Exactly -Times 1
                }
            }

            Context 'DNSName only is passed and matching certificate exists' {
                It 'Should not throw exception' {
                    { $script:result = Find-Certificate -DnsName $certDNSNames } | Should Not Throw
                }

                It 'Should return expected certificate' {
                    $script:result.Thumbprint | Should Be $validThumbprint
                }

                It 'Should call expected mocks' {
                    Assert-MockCalled -CommandName Test-Path -Exactly -Times 1
                    Assert-MockCalled -CommandName Get-ChildItem -Exactly -Times 1
                }
            }

            Context 'DNSName only is passed in reversed order and matching certificate exists' {
                It 'Should not throw exception' {
                    { $script:result = Find-Certificate -DnsName $certDNSNamesReverse } | Should Not Throw
                }

                It 'Should return expected certificate' {
                    $script:result.Thumbprint | Should Be $validThumbprint
                }

                It 'Should call expected mocks' {
                    Assert-MockCalled -CommandName Test-Path -Exactly -Times 1
                    Assert-MockCalled -CommandName Get-ChildItem -Exactly -Times 1
                }
            }

            Context 'DNSName only is passed with only one matching DNS name and matching certificate exists' {
                It 'Should not throw exception' {
                    { $script:result = Find-Certificate -DnsName $certDNSNames[0] } | Should Not Throw
                }

                It 'Should return expected certificate' {
                    $script:result.Thumbprint | Should Be $validThumbprint
                }

                It 'Should call expected mocks' {
                    Assert-MockCalled -CommandName Test-Path -Exactly -Times 1
                    Assert-MockCalled -CommandName Get-ChildItem -Exactly -Times 1
                }
            }

            Context 'DNSName only is passed but an entry is missing and matching certificate does not exist' {
                It 'Should not throw exception' {
                    { $script:result = Find-Certificate -DnsName $certDNSNamesNoMatch } | Should Not Throw
                }

                It 'Should return null' {
                    $script:result | Should BeNullOrEmpty
                }

                It 'Should call expected mocks' {
                    Assert-MockCalled -CommandName Test-Path -Exactly -Times 1
                    Assert-MockCalled -CommandName Get-ChildItem -Exactly -Times 1
                }
            }

            Context 'KeyUsage only is passed and matching certificate exists' {
                It 'Should not throw exception' {
                    { $script:result = Find-Certificate -KeyUsage $certKeyUsage } | Should Not Throw
                }

                It 'Should return expected certificate' {
                    $script:result.Thumbprint | Should Be $validThumbprint
                }

                It 'Should call expected mocks' {
                    Assert-MockCalled -CommandName Test-Path -Exactly -Times 1
                    Assert-MockCalled -CommandName Get-ChildItem -Exactly -Times 1
                }
            }

            Context 'KeyUsage only is passed in reversed order and matching certificate exists' {
                It 'Should not throw exception' {
                    { $script:result = Find-Certificate -KeyUsage $certKeyUsageReverse } | Should Not Throw
                }

                It 'Should return expected certificate' {
                    $script:result.Thumbprint | Should Be $validThumbprint
                }

                It 'Should call expected mocks' {
                    Assert-MockCalled -CommandName Test-Path -Exactly -Times 1
                    Assert-MockCalled -CommandName Get-ChildItem -Exactly -Times 1
                }
            }

            Context 'KeyUsage only is passed with only one matching DNS name and matching certificate exists' {
                It 'Should not throw exception' {
                    { $script:result = Find-Certificate -KeyUsage $certKeyUsage[0] } | Should Not Throw
                }

                It 'Should return expected certificate' {
                    $script:result.Thumbprint | Should Be $validThumbprint
                }

                It 'Should call expected mocks' {
                    Assert-MockCalled -CommandName Test-Path -Exactly -Times 1
                    Assert-MockCalled -CommandName Get-ChildItem -Exactly -Times 1
                }
            }

            Context 'KeyUsage only is passed but an entry is missing and matching certificate does not exist' {
                It 'Should not throw exception' {
                    { $script:result = Find-Certificate -KeyUsage $certKeyUsageNoMatch } | Should Not Throw
                }

                It 'Should return null' {
                    $script:result | Should BeNullOrEmpty
                }

                It 'Should call expected mocks' {
                    Assert-MockCalled -CommandName Test-Path -Exactly -Times 1
                    Assert-MockCalled -CommandName Get-ChildItem -Exactly -Times 1
                }
            }

            Context 'EnhancedKeyUsage only is passed and matching certificate exists' {
                It 'Should not throw exception' {
                    { $script:result = Find-Certificate -EnhancedKeyUsage $certEKU } | Should Not Throw
                }

                It 'Should return expected certificate' {
                    $script:result.Thumbprint | Should Be $validThumbprint
                }

                It 'Should call expected mocks' {
                    Assert-MockCalled -CommandName Test-Path -Exactly -Times 1
                    Assert-MockCalled -CommandName Get-ChildItem -Exactly -Times 1
                }
            }

            Context 'EnhancedKeyUsage only is passed in reversed order and matching certificate exists' {
                It 'Should not throw exception' {
                    { $script:result = Find-Certificate -EnhancedKeyUsage $certEKUReverse } | Should Not Throw
                }

                It 'Should return expected certificate' {
                    $script:result.Thumbprint | Should Be $validThumbprint
                }

                It 'Should call expected mocks' {
                    Assert-MockCalled -CommandName Test-Path -Exactly -Times 1
                    Assert-MockCalled -CommandName Get-ChildItem -Exactly -Times 1
                }
            }

            Context 'EnhancedKeyUsage only is passed with only one matching DNS name and matching certificate exists' {
                It 'Should not throw exception' {
                    { $script:result = Find-Certificate -EnhancedKeyUsage $certEKU[0] } | Should Not Throw
                }

                It 'Should return expected certificate' {
                    $script:result.Thumbprint | Should Be $validThumbprint
                }

                It 'Should call expected mocks' {
                    Assert-MockCalled -CommandName Test-Path -Exactly -Times 1
                    Assert-MockCalled -CommandName Get-ChildItem -Exactly -Times 1
                }
            }

            Context 'EnhancedKeyUsage only is passed but an entry is missing and matching certificate does not exist' {
                It 'Should not throw exception' {
                    { $script:result = Find-Certificate -EnhancedKeyUsage $certEKUNoMatch } | Should Not Throw
                }

                It 'Should return null' {
                    $script:result | Should BeNullOrEmpty
                }

                It 'Should call expected mocks' {
                    Assert-MockCalled -CommandName Test-Path -Exactly -Times 1
                    Assert-MockCalled -CommandName Get-ChildItem -Exactly -Times 1
                }
            }

            Context 'Thumbprint only is passed and matching certificate does not exist in the store' {
                It 'Should not throw exception' {
                    { $script:result = Find-Certificate -Thumbprint $validThumbprint -Store 'NoCert'} | Should Not Throw
                }

                It 'Should return null' {
                    $script:result | Should BeNullOrEmpty
                }

                It 'Should call expected mocks' {
                    Assert-MockCalled -CommandName Test-Path -Exactly -Times 1
                    Assert-MockCalled -CommandName Get-ChildItem -Exactly -Times 1
                }
            }

            Context 'FriendlyName only is passed and both valid and expired certificates exist' {
                It 'Should not throw exception' {
                    { $script:result = Find-Certificate -FriendlyName $certFriendlyName -Store 'TwoCerts' } | Should Not Throw
                }

                It 'Should return expected certificate' {
                    $script:result.Thumbprint | Should Be $validThumbprint
                }

                It 'Should call expected mocks' {
                    Assert-MockCalled -CommandName Test-Path -Exactly -Times 1
                    Assert-MockCalled -CommandName Get-ChildItem -Exactly -Times 1
                }
            }

            Context 'FriendlyName only is passed and only expired certificates exist' {
                It 'Should not throw exception' {
                    { $script:result = Find-Certificate -FriendlyName $certFriendlyName -Store 'Expired' } | Should Not Throw
                }

                It 'Should return expected certificate' {
                    $script:result | Should BeNullOrEmpty
                }

                It 'Should call expected mocks' {
                    Assert-MockCalled -CommandName Test-Path -Exactly -Times 1
                    Assert-MockCalled -CommandName Get-ChildItem -Exactly -Times 1
                }
            }

            Context 'FriendlyName only is passed and only expired certificates exist but allowexpired passed' {
                It 'Should not throw exception' {
                    { $script:result = Find-Certificate -FriendlyName $certFriendlyName -Store 'Expired' -AllowExpired:$true } | Should Not Throw
                }

                It 'Should return expected certificate' {
                    $script:result.Thumbprint | Should Be $expiredThumbprint
                }

                It 'Should call expected mocks' {
                    Assert-MockCalled -CommandName Test-Path -Exactly -Times 1
                    Assert-MockCalled -CommandName Get-ChildItem -Exactly -Times 1
                }
            }
        }

        Describe "$DSCResourceName\Get-LocalizedData" {
            $mockTestPath = {
                return $mockTestPathReturnValue
            }

            $mockImportLocalizedData = {
                $BaseDirectory | Should Be $mockExpectedLanguagePath
            }

            BeforeEach {
                Mock -CommandName Import-LocalizedData -MockWith $mockImportLocalizedData -Verifiable
            }

            Context 'When loading localized data for English' {

                $mockExpectedLanguagePath = 'en-US'
                $mockTestPathReturnValue = $true

                It 'Should call Get-LocalizedData with en-US language' {
                    Mock -CommandName Test-Path -MockWith $mockTestPath -Verifiable
                    Mock -CommandName Join-Path -MockWith {
                        return 'en-US'
                    } -Verifiable

                    { Get-LocalizedData -ResourceName 'DummyResource' -ResourcePath '..\..\DSCResources\MSFT_WebApplicationHandler\en-us\MSFT_WebApplicationHandler.strings.psd1'} | Should Not Throw
                }

                It 'Should call Get-LocalizedData and fallback to en-US if input language does not exist' {

                    Mock -CommandName Test-Path -MockWith {$false} -Verifiable
                    Mock -CommandName Join-Path -MockWith {
                        '..\..\DSCResources\MSFT_WebApplicationHandler\en-us\Dummy.strings.psd1'
                    } -Verifiable
                    Mock -CommandName Import-LocalizedData -Verifiable

                    { Get-LocalizedData -ResourceName 'DummyResource' -ResourcePath '..\..\DSCResources\MSFT_WebApplicationHandler\en-us\Dummy.strings.psd1' } | Should -Not -Throw

                    Assert-MockCalled -CommandName Join-Path -Exactly -Times 2 -Scope It
                    Assert-MockCalled -CommandName Test-Path -Exactly -Times 1 -Scope It
                    Assert-MockCalled -CommandName Import-LocalizedData -Exactly -Times 1 -Scope It
                }
            }

            Assert-VerifiableMock
        }

        Describe "$DSCResourceName\Test-AccessCredential" {

            $MockWebsite = @{
                userName = 'MockUser'
                password = 'MockPassword'
            }

            $MockEmptyWebsite = @{
                userName = ''
                password = ''
            }

            $MockParameters = @{
                Site       = 'MockSite'
                Credential = New-Object System.Management.Automation.PSCredential ('MockUser', `
                                (ConvertTo-SecureString -String 'MockPassword' -AsPlainText -Force))
            }

            Mock -CommandName Get-Website -MockWith { return $MockWebsite }

            Context 'Expected behavior' {

                It 'Should not throw an error' {
                    { Test-AccessCredential @MockParameters } | Should Not Throw
                }

                It 'Should call expected mocks' {
                    Assert-MockCalled -CommandName Get-Website -Exactly 1
                }
            }

            Context 'passed non empty Credential object' {

                It 'Should return True when matches' {
                    $result = Test-AccessCredential @MockParameters

                    $result | Should -Be $true
                }

                It 'Should return False when userName do not match' {

                    $blockMockWebsite          = $MockWebsite.Clone()
                    $blockMockWebsite.userName = ''

                    Mock -CommandName Get-Website -MockWith { return $blockMockWebsite }

                    $result = Test-AccessCredential @MockParameters

                    $result | Should -Be $false
                }

                It 'Should return False when password do not match' {
                    $blockMockWebsite          = $MockWebsite.Clone()
                    $blockMockWebsite.password = ''

                    Mock -CommandName Get-Website -MockWith { return $blockMockWebsite }

                    $result = Test-AccessCredential @MockParameters

                    $result | Should -Be $false
                }
            }

            Context 'passed empty Credential object' {

                $contextMockParameters            = $MockParameters.Clone()
                $contextMockParameters.Credential = [System.Management.Automation.PSCredential]::Empty

                It 'Should return True when matches' {
                    Mock -CommandName Get-Website -MockWith { return $MockEmptyWebsite }

                    $result = Test-AccessCredential @contextMockParameters

                    $result | Should -Be $true
                }

                It 'Should return False when userName do not match' {
                    $blockMockWebsite          = $MockWebsite.Clone()
                    $blockMockWebsite.password = ''

                    Mock -CommandName Get-Website -MockWith { return $blockMockWebsite }

                    $result = Test-AccessCredential @contextMockParameters

                    $result | Should -Be $false
                }

                It 'Should return False when password do not match' {
                    $blockMockWebsite          = $MockWebsite.Clone()
                    $blockMockWebsite.userName = ''

                    Mock -CommandName Get-Website -MockWith { return $blockMockWebsite }

                    $result = Test-AccessCredential @contextMockParameters

                    $result | Should -Be $false
                }
            }
        }

        Describe "$DSCResourceName\Update-AccessCredential" {

            $MockWebsite = @{
                userName = 'MockUser'
                password = 'MockPassword'
            }

            $MockEmptyWebsite = @{
                userName = ''
                password = ''
            }

            $MockParameters = @{
                Site       = 'MockSite'
                Credential = New-Object System.Management.Automation.PSCredential ('MockUser', `
                                (ConvertTo-SecureString -String 'MockPassword' -AsPlainText -Force))
            }

            Mock -CommandName Set-ItemProperty
            Mock -CommandName Get-Website -MockWith { return $MockWebsite }

            Context 'Expected behavior' {

                It 'Should not throw an error' {
                    Mock -CommandName Get-Website -MockWith { return $MockEmptyWebsite }

                    { Update-AccessCredential @MockParameters } | Should Not Throw
                }

                It 'Should call expected mocks' {
                    Assert-MockCalled -CommandName Get-Website -Exactly 1
                    Assert-MockCalled -CommandName Set-ItemProperty -Exactly 2
                }
            }

            Context 'passed non empty Credential object' {

                It 'Should not call Set-ItemProperty' {
                    Update-AccessCredential @MockParameters

                    Assert-MockCalled -CommandName Set-ItemProperty -Exactly 0
                }

                It 'Should call Set-ItemProperty for userName' {

                    $blockMockWebsite          = $MockWebsite.Clone()
                    $blockMockWebsite.userName = ''

                    Mock -CommandName Get-Website -MockWith { return $blockMockWebsite }

                    Update-AccessCredential @MockParameters

                    Assert-MockCalled -CommandName Set-ItemProperty `
                                      -ParameterFilter {$Name -eq 'userName' -and $Value -eq $MockWebsite.UserName} `
                                      -Exactly 1
                }

                It 'Should call Set-ItemProperty for password' {
                    $blockMockWebsite          = $MockWebsite.Clone()
                    $blockMockWebsite.password = ''

                    Mock -CommandName Get-Website -MockWith { return $blockMockWebsite }

                    Update-AccessCredential @MockParameters

                    Assert-MockCalled -CommandName Set-ItemProperty `
                                      -ParameterFilter {$Name -eq 'password' -and $Value -eq $MockWebsite.password} `
                                      -Exactly 1
                }
            }

            Context 'passed empty Credential object' {

                $contextMockParameters            = $MockParameters.Clone()
                $contextMockParameters.Credential = [System.Management.Automation.PSCredential]::Empty

                It 'Should not call Set-ItemProperty' {
                    Mock -CommandName Get-Website -MockWith { return $MockEmptyWebsite }

                    Update-AccessCredential @contextMockParameters

                    Assert-MockCalled -CommandName Set-ItemProperty -Exactly 0
                }

                It 'Should call Set-ItemProperty for userName' {
                    $blockMockWebsite          = $MockWebsite.Clone()
                    $blockMockWebsite.password = ''

                    Mock -CommandName Get-Website -MockWith { return $blockMockWebsite }

                    Update-AccessCredential @contextMockParameters

                    Assert-MockCalled -CommandName Set-ItemProperty `
                                      -ParameterFilter {$Name -eq 'userName' -and $Value -eq ''} `
                                      -Exactly 1
                }

                It 'Should call Set-ItemProperty for password' {
                    $blockMockWebsite          = $MockWebsite.Clone()
                    $blockMockWebsite.userName = ''

                    Mock -CommandName Get-Website -MockWith { return $blockMockWebsite }

                    Update-AccessCredential @contextMockParameters

                    Assert-MockCalled -CommandName Set-ItemProperty `
                                      -ParameterFilter {$Name -eq 'password' -and $Value -eq ''} `
                                      -Exactly 1
                }
            }
        }

        Describe "$DSCResourceName\Confirm-UniqueServiceAutoStartProviders" {

            $MockParameters = @{
                Name = 'MockServiceAutoStartProvider'
                Type = 'MockApplicationType'
            }

            $GetWebConfigurationOutput = @(
                @{
                    SectionPath = 'MockSectionPath'
                    PSPath      = 'MockPSPath'
                    Collection  = @(
                                [PSCustomObject]@{Name = 'MockServiceAutoStartProvider' ;Type = 'MockApplicationType'}
                    )
                }
            )

            Context 'Expected behavior' {

                Mock -CommandName Get-WebConfiguration -MockWith {return $GetWebConfigurationOutput}

                It 'Should not throw an error' {
                    {Confirm-UniqueServiceAutoStartProviders -ServiceAutoStartProvider $MockParameters.Name -ApplicationType $MockParameters.Type} |
                    Should Not Throw
                }

                It 'Should call Get-WebConfiguration once' {
                    Assert-MockCalled -CommandName Get-WebConfiguration -Exactly 1
                }
            }

            Context 'Conflicting Global Property' {

                Mock -CommandName Get-WebConfiguration -MockWith {return $GetWebConfigurationOutput}

                It 'Should return Throw' {
                    $ErrorId       = 'ServiceAutoStartProviderFailure'
                    $ErrorCategory = [System.Management.Automation.ErrorCategory]::InvalidOperation
                    $ErrorMessage  = $LocalizedData.ErrorWebsiteTestAutoStartProviderFailure
                    $Exception     = New-Object -TypeName System.InvalidOperationException `
                                                -ArgumentList $ErrorMessage
                    $ErrorRecord   = New-Object -TypeName System.Management.Automation.ErrorRecord `
                                                -ArgumentList $Exception, $ErrorId, $ErrorCategory, $null

                    {Confirm-UniqueServiceAutoStartProviders -ServiceAutoStartProvider $MockParameters.Name -ApplicationType 'MockApplicationType2'} |
                    Should Throw $ErrorRecord
                }
            }

            Context 'ServiceAutoStartProvider does not exist' {

                Mock -CommandName Get-WebConfiguration  -MockWith {return $null}

                It 'Should return False' {
                    Confirm-UniqueServiceAutoStartProviders -ServiceAutoStartProvider $MockParameters.Name -ApplicationType $MockParameters.Type |
                    Should Be $false
                }
            }

            Context 'ServiceAutoStartProvider does exist' {

                Mock -CommandName Get-WebConfiguration -MockWith {return $GetWebConfigurationOutput}

                It 'Should return True' {
                    Confirm-UniqueServiceAutoStartProviders -ServiceAutoStartProvider $MockParameters.Name -ApplicationType $MockParameters.Type |
                    Should Be $true
                }
            }
        }

        Describe "$DSCResourceName\Confirm-UniqueBinding" {

            $MockParameters = @{
                Name = 'MockSite'
            }

            $testCases = @(
                @{
                    protocol            = 'http'
                    bindingInformation1 = '*:80:'
                    bindingInformation2 = '*:8080:'
                    bindingInformation3 = '*:81:'
                    bindingInformation4 = '*:8081:'
                }
                @{
                    protocol            = 'ftp'
                    bindingInformation1 = '*:21:'
                    bindingInformation2 = '*:2121:'
                    bindingInformation3 = '*:2122:'
                    bindingInformation4 = '*:2123:'
                }
            )

            Context 'Website does not exist' {

                Mock -CommandName Get-Website

                It 'Should throw the correct error' {
                    $ErrorId       = 'WebsiteNotFound'
                    $ErrorCategory = [System.Management.Automation.ErrorCategory]::InvalidResult
                    $ErrorMessage  = $LocalizedData.ErrorWebsiteNotFound -f $MockParameters.Name
                    $Exception     = New-Object -TypeName System.InvalidOperationException `
                                                -ArgumentList $ErrorMessage
                    $ErrorRecord   = New-Object -TypeName System.Management.Automation.ErrorRecord `
                                                -ArgumentList $Exception, $ErrorId, $ErrorCategory, $null

                    { Confirm-UniqueBinding -Name $MockParameters.Name } | Should Throw $ErrorRecord
                }
            }

            foreach($testCase in $testCases)
            {
                Context "Expected behavior for $($testCase.protocol) protocol" {

                    $GetWebsiteOutput = @(
                        @{
                            Name     = $MockParameters.Name
                            State    = 'Stopped'
                            Bindings = @{
                                Collection = @(
                                    @{ protocol = $testCase.protocol; bindingInformation = $testCase.bindingInformation1 }
                                )
                            }
                        }
                    )

                    Mock -CommandName Get-Website -MockWith { return $GetWebsiteOutput }

                    It 'Should not throw an error' {
                        { Confirm-UniqueBinding -Name $MockParameters.Name } | Should Not Throw
                    }

                    It 'Should call Get-Website twice' {
                        Assert-MockCalled -CommandName Get-Website -Exactly 2
                    }
                }

                Context "Bindings for $($testCase.protocol) protocol are unique" {

                    $GetWebsiteOutput = @(
                        @{
                            Name     = $MockParameters.Name
                            State    = 'Stopped'
                            Bindings = @{
                                Collection = @(
                                    @{ protocol = $testCase.protocol; bindingInformation = $testCase.bindingInformation1 }
                                    @{ protocol = $testCase.protocol; bindingInformation = $testCase.bindingInformation2 }
                                )
                            }
                        }
                        @{
                            Name     = 'MockSite2'
                            State    = 'Stopped'
                            Bindings = @{
                                Collection = @(
                                    @{ protocol = $testCase.protocol; bindingInformation = $testCase.bindingInformation3 }
                                )
                            }
                        }
                        @{
                            Name     = 'MockSite3'
                            State    = 'Started'
                            Bindings = @{
                                Collection = @(
                                    @{ protocol = $testCase.protocol; bindingInformation = $testCase.bindingInformation4 }
                                )
                            }
                        }
                    )

                    Mock -CommandName Get-Website -MockWith {return $GetWebsiteOutput}

                    It 'Should return True' {
                        Confirm-UniqueBinding -Name $MockParameters.Name | Should Be $true
                    }
                }

                Context "Bindings for $($testCase.protocol) protocol are not unique" {

                    $GetWebsiteOutput = @(
                        @{
                            Name     = $MockParameters.Name
                            State    = 'Stopped'
                            Bindings = @{
                                Collection = @(
                                    @{ protocol = $testCase.protocol; bindingInformation = $testCase.bindingInformation1 }
                                    @{ protocol = $testCase.protocol; bindingInformation = $testCase.bindingInformation2 }
                                )
                            }
                        }
                        @{
                            Name     = 'MockSite2'
                            State    = 'Started'
                            Bindings = @{
                                Collection = @(
                                    @{ protocol = $testCase.protocol; bindingInformation = $testCase.bindingInformation1 }
                                )
                            }
                        }
                        @{
                            Name     = 'MockSite3'
                            State    = 'Started'
                            Bindings = @{
                                Collection = @(
                                    @{ protocol = $testCase.protocol; bindingInformation = $testCase.bindingInformation2 }
                                )
                            }
                        }
                    )

                    Mock -CommandName Get-Website -MockWith {return $GetWebsiteOutput}

                    It 'Should return False' {
                        Confirm-UniqueBinding -Name $MockParameters.Name | Should Be $false
                    }
                }

                Context "One of the bindings for $($testCase.protocol) protocol is assigned to another website that is Stopped" {

                    $GetWebsiteOutput = @(
                        @{
                            Name     = $MockParameters.Name
                            State    = 'Stopped'
                            Bindings = @{
                                Collection = @(
                                    @{ protocol = $testCase.protocol; bindingInformation = $testCase.bindingInformation1 }
                                    @{ protocol = $testCase.protocol; bindingInformation = $testCase.bindingInformation2 }
                                )
                            }
                        }
                        @{
                            Name     = 'MockSite2'
                            State    = 'Stopped'
                            Bindings = @{
                                Collection = @(
                                    @{ protocol = $testCase.protocol; bindingInformation = $testCase.bindingInformation1 }
                                )
                            }
                        }
                    )

                    Mock -CommandName Get-Website -MockWith { return $GetWebsiteOutput }

                    It 'Should return True if stopped websites are excluded' {
                        Confirm-UniqueBinding -Name $MockParameters.Name -ExcludeStopped | Should Be $true
                    }

                    It 'Should return False if stopped websites are not excluded' {
                        Confirm-UniqueBinding -Name $MockParameters.Name | Should Be $false
                    }
                }

                Context "One of the bindings for $($testCase.protocol) protocol is assigned to another website that is Started" {

                    $GetWebsiteOutput = @(
                        @{
                            Name     = $MockParameters.Name
                            State    = 'Stopped'
                            Bindings = @{
                                Collection = @(
                                    @{ protocol = $testCase.protocol; bindingInformation = $testCase.bindingInformation1 }
                                    @{ protocol = $testCase.protocol; bindingInformation = $testCase.bindingInformation2 }
                                )
                            }
                        }
                        @{
                            Name     = 'MockSite2'
                            State    = 'Stopped'
                            Bindings = @{
                                Collection = @(
                                    @{ protocol = $testCase.protocol;  bindingInformation = $testCase.bindingInformation1 }
                                )
                            }
                        }
                        @{
                            Name     = 'MockSite3'
                            State    = 'Started'
                            Bindings = @{
                                Collection = @(
                                    @{ protocol = $testCase.protocol; bindingInformation = $testCase.bindingInformation1 }
                                )
                            }
                        }
                    )

                    Mock -CommandName Get-Website -MockWith { return $GetWebsiteOutput }

                    It 'Should return False' {
                        Confirm-UniqueBinding -Name $MockParameters.Name -ExcludeStopped | Should Be $false
                    }
                }
            }
        }

        Describe "$DSCResourceName\Format-IPAddressString" {

            Context 'Input value is not valid' {

                It 'Should throw an error' {
                    { Format-IPAddressString -InputString 'Invalid' } | Should Throw
                }
            }

            Context 'Input value is valid' {

                It 'Should return "*" when input value is null' {
                    Format-IPAddressString -InputString $null | Should Be '*'
                }

                It 'Should return "*" when input value is empty' {
                    Format-IPAddressString -InputString '' | Should Be '*'
                }

                It 'Should return normalized IPv4 address' {
                    Format-IPAddressString -InputString '192.10' | Should Be '192.0.0.10'
                }

                It 'Should return normalized IPv6 address enclosed in square brackets' {
                    Format-IPAddressString `
                        -InputString 'fe80:0000:0000:0000:0202:b3ff:fe1e:8329' | Should Be '[fe80::202:b3ff:fe1e:8329]'
                }
            }
        }

        Describe "$DSCResourceName\Test-IPAddress" {

            Context 'Input value is not valid' {

                It 'Should throw an error' {
                    { Test-IPAddress -InputString '256.192.134.80' } | Should Throw
                }
            }

            Context 'Input value is valid' {

                It 'Should return IP address' {
                    (Test-IPAddress -InputString '127.0.0.1').IPAddressToString | Should Be '127.0.0.1'
                }
            }
        }

        Describe "$DSCResourceName\Test-PortNumber" {

            Context 'Input value is not valid' {

                It 'Should not throw an error' {
                    {Test-PortNumber -InputString 'InvalidString'} | Should Not Throw
                }

                It 'Should return False' {
                    Test-PortNumber -InputString 'InvalidString' | Should Be $false
                }

                It 'Should return False when input value is null' {
                    Test-PortNumber -InputString $null | Should Be $false
                }

                It 'Should return False when input value is empty' {
                    Test-PortNumber -InputString '' | Should Be $false
                }

                It 'Should return False when input value is not between 1 and 65535' {
                    Test-PortNumber -InputString '100000' | Should Be $false
                }
            }

            Context 'Input value is valid' {
                It 'Should return True' {
                    Test-PortNumber -InputString '443' | Should Be $true
                }
            }
        }

        Describe "$DSCResourceName\Get-DefaultAuthenticationInfo" {

            $testCases = @('Website', 'Application', 'Ftp')

            Context 'Expected behavior' {

                It 'Should not throw an error' {
                    { Get-DefaultAuthenticationInfo -IisType Website}|
                    Should Not Throw
                }
            }

            foreach($testCase in $testCases)
            {
                Context "Get-DefaultAuthenticationInfo should produce a false CimInstance for $testCase" {

                    It 'Should all be false' {
                        $result = Get-DefaultAuthenticationInfo -IisType $testCase

                        foreach($auth in $result.CimInstanceProperties.Name)
                        {
                            $result.$auth | Should Be $false
                        }
                    }
                }
            }
        }

        Describe "$DSCResourceName\Get-AuthenticationInfo" {

            $testCases = @(
                @{
                    MockParameters = @{Site = 'MockName'; IisType = 'Website'}
                    AuthCount      = 4
                }
                @{
                    MockParameters = @{Site = 'MockName'; IisType = 'Application'; Application = 'MockApp'}
                    AuthCount      = 4
                }
                @{
                    MockParameters = @{Site = 'MockName'; IisType = 'Ftp'}
                    AuthCount      = 2
                }
            )

            foreach ($testCase in $testCases)
            {
                $MockParameters = $testCase.MockParameters

                Context "Expected behavior for $($MockParameters.IisType)" {

                    Mock -CommandName Get-WebConfigurationProperty -MockWith { return @{ Value = $false } }
                    Mock -CommandName Get-ItemProperty -MockWith { return @{ Value = $false } }

                    It 'Should not throw an error' {
                        { Get-AuthenticationInfo @MockParameters } |
                        Should Not Throw
                    }

                    It "Should call expected mocks" {
                        Assert-MockCalled -CommandName Get-WebConfigurationProperty -Exactly ($testCase.AuthCount * ($MockParameters.IisType -ne 'Ftp'))
                        Assert-MockCalled -CommandName Get-ItemProperty -Exactly ($testCase.AuthCount * ($MockParameters.IisType -eq 'Ftp'))
                    }
                }

                Context "AuthenticationInfo is False for $($MockParameters.IisType)" {

                    Mock -CommandName Get-WebConfigurationProperty -MockWith { return @{ Value = $false } }
                    Mock -CommandName Get-ItemProperty -MockWith { return @{ Value = $false } }

                    $result = Get-AuthenticationInfo @MockParameters

                    It 'Should all be false' {
                        $result.Anonymous | Should Be $false
                        $result.Basic | Should Be $false

                        if ($MockParameters.IisType -ne 'Ftp')
                        {
                            $result.Digest | Should Be $false
                            $result.Windows | Should Be $false
                        }
                    }

                    It "Should call expected mocks" {
                        Assert-MockCalled -CommandName Get-WebConfigurationProperty -Exactly ($testCase.AuthCount * ($MockParameters.IisType -ne 'Ftp'))
                        Assert-MockCalled -CommandName Get-ItemProperty -Exactly ($testCase.AuthCount * ($MockParameters.IisType -eq 'Ftp'))
                    }
                }

                Context "AuthenticationInfo is True for $($MockParameters.IisType)" {

                    Mock -CommandName Get-WebConfigurationProperty -MockWith { return @{ Value = $true } }
                    Mock -CommandName Get-ItemProperty -MockWith { return @{ Value = $true } }

                    $result = Get-AuthenticationInfo @MockParameters

                    It 'Should all be true' {
                        $result.Anonymous | Should Be $true
                        $result.Basic | Should Be $true

                        if ($MockParameters.IisType -ne 'Ftp')
                        {
                            $result.Digest | Should Be $true
                            $result.Windows | Should Be $true
                        }
                    }

                    It "Should call expected mocks" {
                        Assert-MockCalled -CommandName Get-WebConfigurationProperty -Exactly ($testCase.AuthCount * ($MockParameters.IisType -ne 'Ftp'))
                        Assert-MockCalled -CommandName Get-ItemProperty -Exactly ($testCase.AuthCount * ($MockParameters.IisType -eq 'Ftp'))
                    }
                }
            }
        }

        Describe "$DSCResourceName\Test-AuthenticationEnabled" {

            $testCases = @(
                @{Site = 'MockName'; IisType = 'Website';     Type = 'Basic'}
                @{Site = 'MockName'; IisType = 'Application'; Type = 'Basic'; Application = 'MockApp'}
                @{Site = 'MockName'; IisType = 'Ftp';         Type = 'Basic'}
            )

            foreach ($testCase in $testCases)
            {
                Context "Expected behavior for $($testCase.IisType)" {

                    Mock -CommandName Get-WebConfigurationProperty -MockWith { return @{ Value = $false } }
                    Mock -CommandName Get-ItemProperty -MockWith { return @{ Value = $false } }

                    It "Should not throw an error"{
                        { Test-AuthenticationEnabled @testCase}|
                        Should Not Throw
                    }

                    It 'Should call expected mocks' {
                        Assert-MockCalled -CommandName Get-WebConfigurationProperty -Exactly ($testCase.IisType -ne 'Ftp')
                        Assert-MockCalled -CommandName Get-ItemProperty -Exactly ($testCase.IisType -eq 'Ftp')
                    }
                }

                Context "AuthenticationInfo is False for $($testCase.IisType)" {

                    Mock -CommandName Get-WebConfigurationProperty -MockWith { return @{ Value = $false } }
                    Mock -CommandName Get-ItemProperty -MockWith { return @{ Value = $false } }

                    It 'Should return false' {
                        Test-AuthenticationEnabled @testCase | Should be $false
                    }

                    It 'Should call expected mocks' {
                        Assert-MockCalled -CommandName Get-WebConfigurationProperty -Exactly ($testCase.IisType -ne 'Ftp')
                        Assert-MockCalled -CommandName Get-ItemProperty -Exactly ($testCase.IisType -eq 'Ftp')
                    }
                }

                Context "AuthenticationInfo is True for $($testCase.IisType)" {

                    Mock -CommandName Get-WebConfigurationProperty -MockWith { return @{ Value = $true } }
                    Mock -CommandName Get-ItemProperty -MockWith { return @{ Value = $true } }

                    It 'Should all be true' {
                        Test-AuthenticationEnabled @testCase | Should be $true
                    }

                    It 'Should call expected mocks' {
                        Assert-MockCalled -CommandName Get-WebConfigurationProperty -Exactly ($testCase.IisType -ne 'Ftp')
                        Assert-MockCalled -CommandName Get-ItemProperty -Exactly ($testCase.IisType -eq 'Ftp')
                    }
                }
            }
        }

        Describe "$DSCResourceName\Test-AuthenticationInfo" {

            $testCases = @(
                @{
                    Site               = 'MockName'
                    IisType            = 'Website'
                    AuthenticationInfo = (
                        New-CimInstance -ClassName MSFT_xWebAuthenticationInformation -ClientOnly `
                                        -Property @{Anonymous=$false;Basic=$true;Digest=$false;Windows=$false} `
                                        -Namespace 'root/microsoft/Windows/DesiredStateConfiguration'
                    )
                }
                @{
                    Site               = 'MockName'
                    IisType            = 'Application'
                    Application        = 'MockApp'
                    AuthenticationInfo = (
                        New-CimInstance -ClassName MSFT_xWebApplicationAuthenticationInformation -ClientOnly `
                                        -Property @{Anonymous=$false;Basic=$true;Digest=$false;Windows=$false} `
                                        -Namespace 'root/microsoft/Windows/DesiredStateConfiguration'
                    )
                }
                @{
                    Site               = 'MockName'
                    IisType            = 'Ftp'
                    AuthenticationInfo = (
                        New-CimInstance -ClassName MSFT_FTPAuthenticationInformation -ClientOnly `
                                        -Property @{Anonymous=$false;Basic=$true} `
                                        -Namespace 'root/microsoft/Windows/DesiredStateConfiguration'
                    )
                }
            )

            $truthyTestCases = @(
                @{
                    Site               = 'MockName'
                    IisType            = 'Website'
                    AuthenticationInfo = (
                        New-CimInstance -ClassName MSFT_xWebAuthenticationInformation -ClientOnly `
                                        -Property @{Anonymous=$true;Basic=$true;Digest=$true;Windows=$true} `
                                        -Namespace 'root/microsoft/Windows/DesiredStateConfiguration'
                    )
                }
                @{
                    Site               = 'MockName'
                    IisType            = 'Application'
                    Application        = 'MockApp'
                    AuthenticationInfo = (
                        New-CimInstance -ClassName MSFT_xWebApplicationAuthenticationInformation -ClientOnly `
                                        -Property @{Anonymous=$true;Basic=$true;Digest=$true;Windows=$true} `
                                        -Namespace 'root/microsoft/Windows/DesiredStateConfiguration'
                    )
                }
                @{
                    Site               = 'MockName'
                    IisType            = 'Ftp'
                    AuthenticationInfo = (
                        New-CimInstance -ClassName MSFT_FTPAuthenticationInformation -ClientOnly `
                                        -Property @{Anonymous=$true;Basic=$true} `
                                        -Namespace 'root/microsoft/Windows/DesiredStateConfiguration'
                    )
                }
            )

            foreach($testCase in $testCases)
            {
                Context "Expected behavior for $($testCase.IisType)" {

                    Mock -CommandName Get-WebConfigurationProperty -MockWith { return @{ Value = $false } }
                    Mock -CommandName Get-ItemProperty -MockWith { return @{ Value = $false } }

                    It 'Should not throw an error' {
                        { Test-AuthenticationInfo @testCase }|
                        Should Not Throw
                    }

                    It 'Should call expected mocks' {
                        Assert-MockCalled -CommandName Get-WebConfigurationProperty -Exactly (2 * ($testCase.IisType -ne 'Ftp'))
                        Assert-MockCalled -CommandName Get-ItemProperty -Exactly (2 * ($testCase.IisType -eq 'Ftp'))
                    }
                }

                Context "Return False when AuthenticationInfo is not correct for $($testCase.IisType)" {

                    Mock -CommandName Get-WebConfigurationProperty -MockWith { return @{ Value = $false } }
                    Mock -CommandName Get-ItemProperty -MockWith { return @{ Value = $false } }

                    It 'Should return false' {
                        Test-AuthenticationInfo @testCase | Should be $false
                    }

                    It 'Should call expected mocks' {
                        Assert-MockCalled -CommandName Get-WebConfigurationProperty -Exactly (2 * ($testCase.IisType -ne 'Ftp'))
                        Assert-MockCalled -CommandName Get-ItemProperty -Exactly (2 * ($testCase.IisType -eq 'Ftp'))
                    }
                }
            }

            foreach($truthyTestCase in $truthyTestCases)
            {
                Context "Return True when AuthenticationInfo is correct for $($truthyTestCase.IisType)" {

                    Mock -CommandName Get-WebConfigurationProperty -MockWith { return @{ Value = $true }}
                    Mock -CommandName Get-ItemProperty -MockWith { return @{ Value = $true } }

                    It 'Should return true' {
                        Test-AuthenticationInfo @truthyTestCase | Should be $true
                    }

                    It 'Should call expected mocks' {
                        Assert-MockCalled -CommandName Get-WebConfigurationProperty -Exactly ($truthyTestCase.AuthenticationInfo.CimInstanceProperties.Count * ($truthyTestCase.IisType -ne 'Ftp'))
                        Assert-MockCalled -CommandName Get-ItemProperty -Exactly ($truthyTestCase.AuthenticationInfo.CimInstanceProperties.Count * ($truthyTestCase.IisType -eq 'Ftp'))
                    }
                }
            }
        }

        Describe "$DSCResourceName\Set-Authentication" {

            $testCases = @(
                @{Site = 'MockName'; IisType = 'Website';     Type = 'Basic'; Enabled = $true}
                @{Site = 'MockName'; IisType = 'Application'; Type = 'Basic'; Enabled = $true; Application = 'MockApp'}
                @{Site = 'MockName'; IisType = 'Ftp';         Type = 'Basic'; Enabled = $true}
            )

            foreach ($testCase in $testCases)
            {
                Context "Expected behavior for $($testCase.IisType)" {

                    Mock -CommandName Set-WebConfigurationProperty
                    Mock -CommandName Set-ItemProperty

                    It 'Should not throw an error' {
                        { Set-Authentication @testCase }|
                        Should Not Throw
                    }

                    It 'Should call expected mocks' {
                        Assert-MockCalled -CommandName Set-WebConfigurationProperty -Exactly ($testCase.IisType -ne 'Ftp')
                        Assert-MockCalled -CommandName Set-ItemProperty -Exactly ($testCase.IisType -eq 'Ftp')
                    }
                }
            }
        }

        Describe "$DSCResourceName\Set-AuthenticationInfo" {

            $websiteAuthenticationInfo = New-CimInstance `
                                    -ClassName MSFT_xWebAuthenticationInformation `
                                    -ClientOnly -Property @{Anonymous=$true;Basic=$false;Digest=$false;Windows=$false} `
                                    -Namespace 'root/microsoft/Windows/DesiredStateConfiguration'

            $webApplicationAuthenticationInfo = New-CimInstance `
                                    -ClassName MSFT_xWebApplicationAuthenticationInformation `
                                    -ClientOnly -Property @{Anonymous=$true;Basic=$false;Digest=$false;Windows=$false} `
                                    -Namespace 'root/microsoft/Windows/DesiredStateConfiguration'

            $ftpAuthenticationInfo = New-CimInstance `
                                    -ClassName MSFT_FTPAuthenticationInformation `
                                    -ClientOnly -Property @{Anonymous=$true;Basic=$false} `
                                    -Namespace 'root/microsoft/Windows/DesiredStateConfiguration'

            $testCases = @(
                @{Site = 'MockName'; IisType = 'Website';     AuthenticationInfo = $websiteAuthenticationInfo}
                @{Site = 'MockName'; IisType = 'Application'; AuthenticationInfo = $webApplicationAuthenticationInfo; Application = 'MockApp'}
                @{Site = 'MockName'; IisType = 'Ftp';         AuthenticationInfo = $ftpAuthenticationInfo}
            )

            foreach($testCase in $testCases)
            {
                Context "Expected behavior for $($testCase.IisType)" {

                    Mock -CommandName Set-WebConfigurationProperty
                    Mock -CommandName Set-ItemProperty

                    It 'Should not throw an error' {
                        { Set-AuthenticationInfo @testCase }|
                        Should Not Throw
                    }

                    It "Should call expected mocks" {
                        Assert-MockCalled -CommandName Set-WebConfigurationProperty -Exactly ($testCase.AuthenticationInfo.CimInstanceProperties.Count * ($testCase.IisType -ne 'Ftp'))
                        Assert-MockCalled -CommandName Set-ItemProperty -Exactly ($testCase.AuthenticationInfo.CimInstanceProperties.Count * ($testCase.IisType -eq 'Ftp'))
                    }
                }
            }
        }

        Describe "$DSCResourceName\Compare-LogFlags" {

            $logFileOutput = @{
                logFile = @{
                    logExtFileFlags = 'Date,Time,ClientIP,UserName,ServerIP'
                }
            }

            $testCases = @(
                @{
                    Type = 'WebSite'
                    MockParameters = @{
                        Name     = 'MockWebSite'
                        LogFlags = @('Date','Time','ClientIP','UserName','ServerIP')
                    }
                    MockOutput = $logFileOutput
                }
                @{
                    Type = 'FtpSite'
                    MockParameters = @{
                        Name     = 'MockWebSite'
                        LogFlags = @('Date','Time','ClientIP','UserName','ServerIP')
                        FtpSite  = $true
                    }
                    MockOutput = @{
                        ftpServer = $logFileOutput
                    }
                }
            )

            foreach($testCase in $testCases)
            {
                Context "Returns False when LogFlags are incorrect for $($testCase.Type)" {

                    $MockParameters          = $testCase.MockParameters.Clone()
                    $MockParameters.LogFlags = @('Date','Time','ClientIP','UserName','ServerIP','Method',`
                                                 'UriStem','UriQuery','HttpStatus','Win32Status','TimeTaken',`
                                                 'ServerPort','UserAgent','Referer','HttpSubStatus')

                    Mock -CommandName Get-WebSite -MockWith { return $testCase.MockOutput }

                    $result = Compare-LogFlags @MockParameters

                    It 'Should return false' {
                        $result | Should be $false
                    }
                }

                Context "Returns True when LogFlags are correct for $($testCase.Type)" {

                    $MockParameters = $testCase.MockParameters.Clone()

                    Mock -CommandName Get-WebSite -MockWith { return $testCase.MockOutput }

                    $result = Compare-LogFlags @MockParameters

                    It 'Should return true' {
                        $result | Should be $true
                    }
                }
            }
        }

        Describe "$DSCResourceName\ConvertTo-CimLogCustomFields"{

            $mockLogCustomFields = @(
                @{
                    LogFieldName = 'LogField1'
                    SourceName   = 'Accept-Encoding'
                    SourceType   = 'RequestHeader'
                }
                @{
                    LogFieldName = 'LogField2'
                    SourceName   = 'Warning'
                    SourceType   = 'ResponseHeader'
                }
            )

            Context 'Expected behavior'{
                $Result = ConvertTo-CimLogCustomFields -InputObject $mockLogCustomFields

                It 'Should return the LogFieldName' {
                    $Result[0].LogFieldName | Should Be $mockLogCustomFields[0].LogFieldName
                    $Result[0].LogFieldName | Should Be $mockLogCustomFields[0].LogFieldName
                }

                It 'Should return the SourceName' {
                    $Result[0].SourceName | Should Be $mockLogCustomFields[0].SourceName
                    $Result[0].SourceName | Should Be $mockLogCustomFields[0].SourceName
                }

                It 'Should return the SourceType' {
                    $Result[0].SourceType | Should Be $mockLogCustomFields[0].SourceType
                    $Result[0].SourceType | Should Be $mockLogCustomFields[0].SourceType
                }
            }
        }

        Describe "$DSCResourceName\ConvertTo-CimBinding" {

            $IPs = @(
                @{ Version = 'IPv4'; Address = '127.0.0.1' }
                @{ Version = 'IPv6'; Address = '[0:0:0:0:0:0:0:1]' }
            )

            foreach($ip in $IPs)
            {
                $testCases = @(
                    @{
                        InputObject = @{ protocol = 'http'; bindingInformation = "$($ip.Address):80:MockHostName1" }
                        MockOutput  = @{ Protocol = 'http'; HostName = 'MockHostName1'; IPAddress = "$($ip.Address.Trim('[',']'))"; Port = 80 }
                    }
                    @{
                        InputObject = @{ protocol = 'ftp'; bindingInformation = "$($ip.Address):21:MockHostName2" }
                        MockOutput  = @{ Protocol = 'ftp'; HostName = 'MockHostName2'; IPAddress = "$($ip.Address.Trim('[',']'))"; Port = 21 }
                    }
                    @{
                        InputObject = @{
                            bindingInformation   = "$($ip.Address):443:MockHostName3"
                            protocol             = 'https'
                            certificateHash      = '1D3324C6E2F7ABC794C9CB6CA426B8D0F81045CD'
                            certificateStoreName = 'MY'
                            sslFlags             = 1
                        }
                        MockOutput  = @{
                            IPAddress             = "$($ip.Address.Trim('[',']'))"
                            HostName              = 'MockHostName3'
                            Port                  = 443
                            Protocol              = 'https'
                            CertificateThumbprint = '1D3324C6E2F7ABC794C9CB6CA426B8D0F81045CD'
                            CertificateStoreName  = 'MY'
                            SslFlags              = 1
                        }
                    }
                )

                foreach ($testCase in $testCases)
                {
                    Context "$($ip.Version) address is passed and the protocol is $($testCase.InputObject.protocol)" {

                        $Result = ConvertTo-CimBinding -InputObject $testCase.inputObject

                        It "Should return the $($ip.Version) Address" {
                            $Result.IPAddress | Should Be $testCase.MockOutput.IPAddress
                        }

                        It 'Should return the Protocol' {
                            $Result.Protocol | Should Be $testCase.MockOutput.Protocol
                        }

                        It 'Should return the HostName' {
                            $Result.HostName | Should Be $testCase.MockOutput.HostName
                        }

                        It 'Should return the Port' {
                            $Result.Port | Should Be $testCase.MockOutput.Port
                        }

                        if ($testCase.InputObject.protocol -eq 'https')
                        {
                            It 'Should return the CertificateThumbprint' {
                                $Result.CertificateThumbprint | Should Be $testCase.MockOutput.CertificateThumbprint
                            }

                            It 'Should return the CertificateStoreName' {
                                $Result.CertificateStoreName | Should Be $testCase.MockOutput.CertificateStoreName
                            }

                            It 'Should return the SslFlags' {
                                $Result.SslFlags | Should Be $testCase.MockOutput.SslFlags
                            }
                        }

                        if ($testCase.InputObject.protocol -eq 'ftp')
                        {
                            It 'Should not return properties for certificate binding' {
                                $Result.CimInstanceProperties.Name | Should -Not -BeIn @('CertificateThumbprint',`
                                                                                         'CertificateStoreName', `
                                                                                         'SslFlags')
                            }
                        }
                    }
                }
            }
        }

        Describe "$DSCResourceName\ConvertTo-WebBinding" -Tag 'ConvertTo' {

            $testCases = @(
                @{
                    protocol       = 'http'
                    className      = 'MSFT_xWebBindingInformation'
                }
                @{
                    protocol       = 'ftp'
                    className      = 'MSFT_FTPBindingInformation'
                }
            )

            foreach($testCase in $testCases)
            {
                Context "IP address is invalid for $($testCase.protocol) protocol" {

                    $MockBindingInfo = @(
                        New-CimInstance -ClassName $testCase.className `
                                        -Namespace 'root/microsoft/Windows/DesiredStateConfiguration' `
                                        -ClientOnly `
                                        -Property @{
                                            Protocol  = $testCase.protocol
                                            IPAddress = '127.0.0.256'
                                        }
                    )

                    It 'Should throw the correct error' {
                        $ErrorId       = 'WebBindingInvalidIPAddress'
                        $ErrorCategory = [System.Management.Automation.ErrorCategory]::InvalidArgument
                        $ErrorMessage  = $LocalizedData.ErrorWebBindingInvalidIPAddress -f $MockBindingInfo.IPAddress, 'Exception calling "Parse" with "1" argument(s): "An invalid IP address was specified."'
                        $Exception     = New-Object -TypeName System.InvalidOperationException `
                                                    -ArgumentList $ErrorMessage
                        $ErrorRecord   = New-Object -TypeName System.Management.Automation.ErrorRecord `
                                                    -ArgumentList $Exception, $ErrorId, $ErrorCategory, $null

                        { ConvertTo-WebBinding -InputObject $MockBindingInfo } | Should Throw $ErrorRecord
                    }
                }

                Context "Port is invalid for $($testCase.protocol) protocol" {

                    $MockBindingInfo = @(
                        New-CimInstance -ClassName $testCase.className `
                                        -Namespace 'root/microsoft/Windows/DesiredStateConfiguration' `
                                        -ClientOnly `
                                        -Property @{
                                            Protocol = $testCase.protocol
                                            Port     = 0
                                        }
                    )

                    It 'Should throw the correct error' {
                        $ErrorId       = 'WebBindingInvalidPort'
                        $ErrorCategory = [System.Management.Automation.ErrorCategory]::InvalidArgument
                        $ErrorMessage  = $LocalizedData.ErrorWebBindingInvalidPort -f $MockBindingInfo.Port
                        $Exception     = New-Object -TypeName System.InvalidOperationException `
                                                    -ArgumentList $ErrorMessage
                        $ErrorRecord   = New-Object -TypeName System.Management.Automation.ErrorRecord `
                                                    -ArgumentList $Exception, $ErrorId, $ErrorCategory, $null

                        {ConvertTo-WebBinding -InputObject $MockBindingInfo} | Should Throw $ErrorRecord
                    }
                }
            }

            Context "Protocol is not HTTPS but HTTP" {

                $MockBindingInfo = @(
                    New-CimInstance -ClassName 'MSFT_xWebBindingInformation' `
                                    -Namespace 'root/microsoft/Windows/DesiredStateConfiguration' `
                                    -ClientOnly `
                                    -Property @{
                                        Protocol              = 'http'
                                        CertificateThumbprint = 'C65CE51E20C523DEDCE979B9922A0294602D9D5C'
                                        CertificateStoreName  = 'WebHosting'
                                        SslFlags              = 1
                                    }
                )

                It 'Should ignore SSL properties' {
                    $Result = ConvertTo-WebBinding -InputObject $MockBindingInfo

                    $Result.certificateHash      | Should Be ''
                    $Result.certificateStoreName | Should Be ''
                    $Result.sslFlags             | Should Be 0
                }
            }

            Context 'Expected behaviour for FTP' {

                $MockBindingInfo = @(
                    New-CimInstance -ClassName MSFT_FTPBindingInformation `
                                    -Namespace 'root/microsoft/Windows/DesiredStateConfiguration' `
                                    -ClientOnly `
                                    -Property @{
                                        Protocol           = 'ftp'
                                        BindingInformation = 'NonsenseString'
                                        IPAddress          = '*'
                                        Port               = '21'
                                        HostName           = 'ftp01.contoso.com'
                                    }
                )

                $Result = ConvertTo-WebBinding -InputObject $MockBindingInfo

                It 'Should not return properties for certificate binding' {
                    $Result.CimInstanceProperties.Name | Should -Not -BeIn @('CertificateThumbprint',`
                                                                             'CertificateStoreName', `
                                                                             'SslFlags')
                }

                It 'Should return the correct Protocol value' {
                    $Result.protocol | Should Be 'ftp'
                }

                It 'Should return the correct BindingInformation value' {
                    $Result.bindingInformation | Should Be '*:21:ftp01.contoso.com'
                }
            }

            Context "Expected behaviour for HTTPS" {

                $MockBindingInfo = @(
                    New-CimInstance -ClassName MSFT_xWebBindingInformation `
                                    -Namespace 'root/microsoft/Windows/DesiredStateConfiguration' `
                                    -ClientOnly `
                                    -Property @{
                                        Protocol              = 'https'
                                        BindingInformation    = 'NonsenseString'
                                        IPAddress             = '*'
                                        Port                  = 443
                                        HostName              = 'web01.contoso.com'
                                        CertificateThumbprint = 'C65CE51E20C523DEDCE979B9922A0294602D9D5C'
                                        CertificateStoreName  = 'WebHosting'
                                        SslFlags              = 1
                                    }
                )

                $Result = ConvertTo-WebBinding -InputObject $MockBindingInfo

                It 'Should return the correct Protocol value' {
                    $Result.protocol | Should Be 'https'
                }

                It 'Should return the correct BindingInformation value' {
                    $Result.bindingInformation | Should Be '*:443:web01.contoso.com'
                }

                It 'Should return the correct CertificateHash value' {
                    $Result.certificateHash | Should Be 'C65CE51E20C523DEDCE979B9922A0294602D9D5C'
                }

                It 'Should return the correct CertificateStoreName value' {
                    $Result.certificateStoreName | Should Be 'WebHosting'
                }

                It 'Should return the correct SslFlags value' {
                    $Result.sslFlags | Should Be 1
                }
            }

            Context "Port is not specified" {

                It 'Should set the default FTP port' {
                    $MockBindingInfo = @(
                        New-CimInstance -ClassName MSFT_xWebBindingInformation `
                                        -Namespace 'root/microsoft/Windows/DesiredStateConfiguration' `
                                        -ClientOnly `
                                        -Property @{
                                            Protocol = 'ftp'
                                        }
                    )

                    $Result = ConvertTo-WebBinding -InputObject $MockBindingInfo

                    $Result.bindingInformation | Should Be '*:21:'
                }

                It 'Should set the default HTTP port' {
                    $MockBindingInfo = @(
                        New-CimInstance -ClassName MSFT_xWebBindingInformation `
                                        -Namespace 'root/microsoft/Windows/DesiredStateConfiguration' `
                                        -ClientOnly `
                                        -Property @{
                                            Protocol = 'http'
                                        }
                    )

                    $Result = ConvertTo-WebBinding -InputObject $MockBindingInfo

                    $Result.bindingInformation | Should Be '*:80:'
                }

                It 'Should set the default HTTPS port' {
                    $MockBindingInfo = @(
                        New-CimInstance `
                        -ClassName MSFT_xWebBindingInformation `
                        -Namespace 'root/microsoft/Windows/DesiredStateConfiguration' `
                        -ClientOnly `
                        -Property @{
                            Protocol              = 'https'
                            CertificateThumbprint = 'C65CE51E20C523DEDCE979B9922A0294602D9D5C'
                        }
                    )

                    $Result = ConvertTo-WebBinding -InputObject $MockBindingInfo

                    $Result.bindingInformation | Should Be '*:443:'
                }
            }

            Context 'Protocol is neither HTTP, HTTPS or FTP' {

                It 'Should throw an error if BindingInformation is not specified' {
                    $MockBindingInfo = @(
                        New-CimInstance -ClassName MSFT_xWebBindingInformation `
                                        -Namespace 'root/microsoft/Windows/DesiredStateConfiguration' `
                                        -ClientOnly `
                                        -Property @{
                                            Protocol           = 'net.tcp'
                                            BindingInformation = ''
                                        }
                    )

                    $ErrorId       = 'WebBindingMissingBindingInformation'
                    $ErrorCategory = [System.Management.Automation.ErrorCategory]::InvalidArgument
                    $ErrorMessage  = $LocalizedData.ErrorWebBindingMissingBindingInformation -f $MockBindingInfo.Protocol
                    $Exception     = New-Object -TypeName System.InvalidOperationException `
                                                -ArgumentList $ErrorMessage
                    $ErrorRecord   = New-Object -TypeName System.Management.Automation.ErrorRecord `
                                                -ArgumentList $Exception, $ErrorId, $ErrorCategory, $null

                    { ConvertTo-WebBinding -InputObject $MockBindingInfo } | Should Throw $ErrorRecord
                }

                It 'Should use BindingInformation and ignore IPAddress, Port, and HostName' {
                    $MockBindingInfo = @(
                        New-CimInstance -ClassName MSFT_xWebBindingInformation `
                                        -Namespace 'root/microsoft/Windows/DesiredStateConfiguration' `
                                        -ClientOnly `
                                        -Property @{
                                            Protocol           = 'net.tcp'
                                            BindingInformation = '808:*'
                                            IPAddress          = '127.0.0.1'
                                            Port               = 80
                                            HostName           = 'web01.contoso.com'
                                        }
                    )

                    $Result = ConvertTo-WebBinding -InputObject $MockBindingInfo

                    $Result.BindingInformation | Should Be '808:*'
                }
            }

            Context 'Protocol is HTTPS and CertificateThumbprint contains the Left-to-Right Mark character' {

                $MockThumbprint = 'C65CE51E20C523DEDCE979B9922A0294602D9D5C'

                $AsciiEncoding   = [System.Text.Encoding]::ASCII
                $UnicodeEncoding = [System.Text.Encoding]::Unicode

                $AsciiBytes   = $AsciiEncoding.GetBytes($MockThumbprint)
                $UnicodeBytes = [System.Text.Encoding]::Convert($AsciiEncoding, $UnicodeEncoding, $AsciiBytes)
                $LrmCharBytes = $UnicodeEncoding.GetBytes([Char]0x200E)

                # Prepend the Left-to-Right Mark character to CertificateThumbprint
                $MockThumbprintWithLrmChar = $UnicodeEncoding.GetString(($LrmCharBytes + $UnicodeBytes))

                $MockBindingInfo = @(
                    New-CimInstance -ClassName MSFT_xWebBindingInformation `
                                    -Namespace 'root/microsoft/Windows/DesiredStateConfiguration' `
                                    -ClientOnly `
                                    -Property @{
                                        Protocol              = 'https'
                                        CertificateThumbprint = $MockThumbprintWithLrmChar
                                        CertificateStoreName  = 'MY'
                                    }
                )

                It 'Input - CertificateThumbprint should contain the Left-to-Right Mark character' {
                    $MockBindingInfo[0].CertificateThumbprint -match '^\u200E' | Should Be $true
                }

                It 'Output - certificateHash should not contain the Left-to-Right Mark character' {
                    $Result = ConvertTo-WebBinding -InputObject $MockBindingInfo

                    $Result.certificateHash -match '^\u200E' | Should Be $false
                }
            }

            Context 'Protocol is HTTPS and CertificateThumbprint is not specified' {

                $MockBindingInfo = @(
                    New-CimInstance -ClassName MSFT_xWebBindingInformation `
                                    -Namespace 'root/microsoft/Windows/DesiredStateConfiguration' `
                                    -ClientOnly `
                                    -Property @{
                                        Protocol              = 'https'
                                        CertificateThumbprint = ''
                                    }
                )

                It 'Should throw the correct error' {
                    $ErrorId       = 'WebBindingMissingCertificateThumbprint'
                    $ErrorCategory = [System.Management.Automation.ErrorCategory]::InvalidArgument
                    $ErrorMessage  = $LocalizedData.ErrorWebBindingMissingCertificateThumbprint -f $MockBindingInfo.Protocol
                    $Exception     = New-Object -TypeName System.InvalidOperationException `
                                                -ArgumentList $ErrorMessage
                    $ErrorRecord = New-Object   -TypeName System.Management.Automation.ErrorRecord `
                                                -ArgumentList $Exception, $ErrorId, $ErrorCategory, $null

                    { ConvertTo-WebBinding -InputObject $MockBindingInfo } | Should Throw $ErrorRecord
                }
            }

            Context 'Protocol is HTTPS and CertificateSubject is specified' {

                $MockBindingInfo = @(
                    New-CimInstance -ClassName MSFT_xWebBindingInformation `
                                    -Namespace 'root/microsoft/Windows/DesiredStateConfiguration' `
                                    -ClientOnly `
                                    -Property @{
                                        Protocol              = 'https'
                                        CertificateSubject    = 'TestCertificate'
                                    }
                )

                Mock Find-Certificate -MockWith {
                    return [PSCustomObject]@{
                        Thumbprint = 'C65CE51E20C523DEDCE979B9922A0294602D9D5C'
                    }
                }

                It 'Should not throw an error' {
                   { ConvertTo-WebBinding -InputObject $MockBindingInfo } | Should Not Throw
                }

                It 'Should return the correct thumbprint' {
                    $Result = ConvertTo-WebBinding -InputObject $MockBindingInfo

                    $Result.certificateHash | Should Be 'C65CE51E20C523DEDCE979B9922A0294602D9D5C'
                }

                It 'Should call Find-Certificate mock' {
                    Assert-MockCalled -CommandName Find-Certificate -Times 1
                }
            }

            Context 'Protocol is HTTPS and full CN of CertificateSubject is specified' {

                $MockBindingInfo = @(
                    New-CimInstance -ClassName MSFT_xWebBindingInformation `
                                    -Namespace 'root/microsoft/Windows/DesiredStateConfiguration' `
                                    -ClientOnly `
                                    -Property @{
                                        Protocol              = 'https'
                                        CertificateSubject    = 'CN=TestCertificate'
                                    }
                )

                Mock Find-Certificate -MockWith {
                    return [PSCustomObject]@{
                        Thumbprint = 'C65CE51E20C523DEDCE979B9922A0294602D9D5C'
                    }
                }

                It 'Should not throw an error' {
                   { ConvertTo-WebBinding -InputObject $MockBindingInfo } | Should Not Throw
                }

                It 'Should return the correct thumbprint' {
                    $Result = ConvertTo-WebBinding -InputObject $MockBindingInfo

                    $Result.certificateHash | Should Be 'C65CE51E20C523DEDCE979B9922A0294602D9D5C'
                }

                It 'Should call Find-Certificate mock' {
                    Assert-MockCalled -CommandName Find-Certificate -Times 1
                }
            }

            Context 'Protocol is HTTPS and invalid CertificateSubject is specified' {

                $MockBindingInfo = @(
                    New-CimInstance -ClassName MSFT_xWebBindingInformation `
                                    -Namespace 'root/microsoft/Windows/DesiredStateConfiguration' `
                                    -ClientOnly `
                                    -Property @{
                                        Protocol              = 'https'
                                        CertificateSubject    = 'TestCertificate'
                                        CertificateStoreName  = 'MY'
                                    }
                )

                Mock Find-Certificate

                It 'Should throw the correct error' {
                    $CertificateSubject = "CN=$($MockBindingInfo.CertificateSubject)"
                    $ErrorId            = 'WebBindingInvalidCertificateSubject'
                    $ErrorCategory      = [System.Management.Automation.ErrorCategory]::InvalidArgument
                    $ErrorMessage       = $LocalizedData.ErrorWebBindingInvalidCertificateSubject -f $CertificateSubject, $MockBindingInfo.CertificateStoreName
                    $Exception          = New-Object -TypeName System.InvalidOperationException `
                                                     -ArgumentList $ErrorMessage
                    $ErrorRecord        = New-Object -TypeName System.Management.Automation.ErrorRecord `
                                                     -ArgumentList $Exception, $ErrorId, $ErrorCategory, $null

                    { ConvertTo-WebBinding -InputObject $MockBindingInfo } | Should Throw $ErrorRecord
                }
            }

            Context 'Protocol is HTTPS and CertificateStoreName is not specified' {

                $MockBindingInfo = @(
                    New-CimInstance -ClassName MSFT_xWebBindingInformation `
                                    -Namespace 'root/microsoft/Windows/DesiredStateConfiguration' `
                                    -ClientOnly `
                                    -Property @{
                                        Protocol              = 'https'
                                        CertificateThumbprint = 'C65CE51E20C523DEDCE979B9922A0294602D9D5C'
                                        CertificateStoreName  = ''
                                    }
                )

                It 'Should set CertificateStoreName to the default value' {
                    $Result = ConvertTo-WebBinding -InputObject $MockBindingInfo

                    $Result.certificateStoreName | Should Be 'MY'
                }
            }

            Context 'Protocol is HTTPS and HostName is not specified for use with Server Name Indication' {

                $MockBindingInfo = @(
                    New-CimInstance -ClassName MSFT_xWebBindingInformation `
                                    -Namespace 'root/microsoft/Windows/DesiredStateConfiguration' `
                                    -ClientOnly `
                                    -Property @{
                                        Protocol              = 'https'
                                        IPAddress             = '*'
                                        Port                  = 443
                                        HostName              = ''
                                        CertificateThumbprint = 'C65CE51E20C523DEDCE979B9922A0294602D9D5C'
                                        CertificateStoreName  = 'WebHosting'
                                        SslFlags              = 1
                                    }
                )

                It 'Should throw the correct error' {
                    $ErrorId       = 'WebBindingMissingSniHostName'
                    $ErrorCategory = [System.Management.Automation.ErrorCategory]::InvalidArgument
                    $ErrorMessage  = $LocalizedData.ErrorWebBindingMissingSniHostName
                    $Exception     = New-Object -TypeName System.InvalidOperationException `
                                                -ArgumentList $ErrorMessage
                    $ErrorRecord   = New-Object -TypeName System.Management.Automation.ErrorRecord `
                                                -ArgumentList $Exception, $ErrorId, $ErrorCategory, $null

                    { ConvertTo-WebBinding -InputObject $MockBindingInfo } | Should Throw $ErrorRecord
                }
            }
        }

        Describe "$DSCResourceName\Update-WebsiteBinding" {

            $MockWebsite = @{
                Name      = 'MockSite'
                ItemXPath = "/system.applicationHost/sites/site[@name='MockSite']"
            }

            $testCases = @(
                @{
                    MockBindingInfo = @(
                        New-CimInstance -ClassName MSFT_xWebBindingInformation `
                                        -Namespace 'root/microsoft/Windows/DesiredStateConfiguration' `
                                        -ClientOnly `
                                        -Property @{
                                            Protocol              = 'https'
                                            IPAddress             = '*'
                                            Port                  = 443
                                            HostName              = ''
                                            CertificateThumbprint = '5846A1B276328B1A32A30150858F6383C1F30E1F'
                                            CertificateStoreName  = 'MY'
                                            SslFlags              = 0
                                        }
                    )
                }
                @{
                    MockBindingInfo = @(
                        New-CimInstance -ClassName MSFT_FTPBindingInformation `
                                        -Namespace 'root/microsoft/Windows/DesiredStateConfiguration' `
                                        -ClientOnly `
                                        -Property @{
                                            Protocol              = 'ftp'
                                            IPAddress             = '*'
                                            Port                  = 21
                                            HostName              = ''
                                        }
                    )
                }
            )

            Mock -CommandName Get-WebConfiguration `
                -ParameterFilter { $Filter -eq '/system.applicationHost/sites/site' } `
                -MockWith { return $MockWebsite } -Verifiable

            Mock -CommandName Clear-WebConfiguration -Verifiable

            foreach($testCase in $testCases)
            {
                Context "Expected behavior for $($testCase.MockBindingInfo.Protocol) website" {

                    Mock -CommandName Add-WebConfiguration
                    Mock -CommandName Set-WebConfigurationProperty

                    Mock -CommandName Get-WebConfiguration `
                         -ParameterFilter { $Filter -eq "$($MockWebsite.ItemXPath)/bindings/binding[last()]" } `
                         -MockWith { New-Module -AsCustomObject -ScriptBlock { function AddSslCertificate {} } } `
                         -Verifiable

                    Update-WebsiteBinding -Name $MockWebsite.Name -BindingInfo $testCases[0].MockBindingInfo

                    It 'Should call all the mocks' {
                        Assert-VerifiableMock
                        Assert-MockCalled -CommandName Add-WebConfiguration -Exactly $testCase.MockBindingInfo.Count
                        Assert-MockCalled -CommandName Set-WebConfigurationProperty
                    }
                }

                Context "$($testCase.MockBindingInfo.Protocol) website does not exist" {

                    Mock -CommandName Get-WebConfiguration `
                         -ParameterFilter { $Filter -eq '/system.applicationHost/sites/site' } `
                         -MockWith { return $null }

                    It 'Should throw the correct error' {
                        $ErrorId       = 'WebsiteNotFound'
                        $ErrorCategory = [System.Management.Automation.ErrorCategory]::InvalidResult
                        $ErrorMessage  = $LocalizedData.ErrorWebsiteNotFound -f $MockWebsite.Name
                        $Exception     = New-Object -TypeName System.InvalidOperationException `
                                                    -ArgumentList $ErrorMessage
                        $ErrorRecord   = New-Object -TypeName System.Management.Automation.ErrorRecord `
                                                    -ArgumentList $Exception, $ErrorId, $ErrorCategory, $null

                        { Update-WebsiteBinding `
                            -Name $MockWebsite.Name `
                            -BindingInfo $testCase.MockBindingInfo} | Should Throw $ErrorRecord
                    }
                }

                Context "Error on adding a new binding to the $($testCase.MockBindingInfo.Protocol) website" {

                    Mock -CommandName Add-WebConfiguration `
                         -ParameterFilter { $Filter -eq "$($MockWebsite.ItemXPath)/bindings" } `
                         -MockWith { throw }

                    It 'Should throw the correct error' {
                        $ErrorId       = 'WebsiteBindingUpdateFailure'
                        $ErrorCategory = [System.Management.Automation.ErrorCategory]::InvalidResult
                        $ErrorMessage  = $LocalizedData.ErrorWebsiteBindingUpdateFailure -f $MockWebsite.Name, 'ScriptHalted'
                        $Exception     = New-Object -TypeName System.InvalidOperationException `
                                                    -ArgumentList $ErrorMessage
                        $ErrorRecord   = New-Object -TypeName System.Management.Automation.ErrorRecord `
                                                    -ArgumentList $Exception, $ErrorId, $ErrorCategory, $null

                        { Update-WebsiteBinding `
                            -Name $MockWebsite.Name `
                            -BindingInfo $testCase.MockBindingInfo } | Should Throw $ErrorRecord
                    }
                }
            }

            Context 'Error on setting sslFlags attribute for HTTPS site' {

                Mock -CommandName Add-WebConfiguration

                Mock -CommandName Set-WebConfigurationProperty `
                     -ParameterFilter { $Filter -eq "$($MockWebsite.ItemXPath)/bindings/binding[last()]" -and $Name -eq 'sslFlags' } `
                     -MockWith { throw }

                It 'Should throw the correct error' {
                    $ErrorId       = 'WebsiteBindingUpdateFailure'
                    $ErrorCategory = [System.Management.Automation.ErrorCategory]::InvalidResult
                    $ErrorMessage  = $LocalizedData.ErrorWebsiteBindingUpdateFailure -f $MockWebsite.Name, 'ScriptHalted'
                    $Exception     = New-Object -TypeName System.InvalidOperationException `
                                                -ArgumentList $ErrorMessage
                    $ErrorRecord   = New-Object -TypeName System.Management.Automation.ErrorRecord `
                                                -ArgumentList $Exception, $ErrorId, $ErrorCategory, $null

                    { Update-WebsiteBinding `
                        -Name $MockWebsite.Name `
                        -BindingInfo $testCases[0].MockBindingInfo } | Should Throw $ErrorRecord
                }
            }

            Context 'Error on adding SSL certificate for HTTPS site' {

                Mock -CommandName Add-WebConfiguration

                Mock -CommandName Set-WebConfigurationProperty

                Mock -CommandName Get-WebConfiguration `
                    -ParameterFilter { $Filter -eq "$($MockWebsite.ItemXPath)/bindings/binding[last()]" } `
                    -MockWith {
                        New-Module -AsCustomObject -ScriptBlock {
                            function AddSslCertificate {throw}
                        }
                    }

                It 'Should throw the correct error' {
                    $ErrorId       = 'WebBindingCertificate'
                    $ErrorCategory = [System.Management.Automation.ErrorCategory]::InvalidOperation
                    $ErrorMessage  = $LocalizedData.ErrorWebBindingCertificate -f $testCases[0].MockBindingInfo.CertificateThumbprint, 'Exception calling "AddSslCertificate" with "2" argument(s): "ScriptHalted"'
                    $Exception     = New-Object -TypeName System.InvalidOperationException `
                                                -ArgumentList $ErrorMessage
                    $ErrorRecord   = New-Object -TypeName System.Management.Automation.ErrorRecord `
                                                -ArgumentList $Exception, $ErrorId, $ErrorCategory, $null

                    { Update-WebsiteBinding `
                        -Name $MockWebsite.Name `
                        -BindingInfo $testCases[0].MockBindingInfo } | Should Throw $ErrorRecord
                }
            }
        }

        Describe "$DSCResourceName\Test-WebsiteBinding" {

            $MockFtpOutputBinding = @(
                @{
                    bindingInformation   = '*:21:'
                    protocol             = 'ftp'
                }
            )

            $MockWebOutputBinding = @(
                @{
                    bindingInformation   = '*:80:'
                    protocol             = 'http'
                    certificateHash      = ''
                    certificateStoreName = ''
                    sslFlags             = '0'
                }
            )

            $MockWebHttpsOutputBinding = @(
                @{
                    bindingInformation   = '*:443:'
                    protocol             = 'https'
                    certificateHash      = 'B30F3184A831320382C61EFB0551766321FA88A5'
                    certificateStoreName = 'MY'
                    sslFlags             = '0'
                }
            )

            $testCases = @(
                @{
                    MockWebsite = @{
                        Name     = 'MockName'
                        Bindings = @{
                            Collection = @(
                                $MockFtpOutputBinding
                            )
                        }
                    }
                    BindingInfo = @(
                        New-CimInstance -ClassName MSFT_FTPBindingInformation `
                                        -Namespace 'root/microsoft/Windows/DesiredStateConfiguration' `
                                        -ClientOnly `
                                        -Property @{
                                            Protocol              = 'ftp'
                                            IPAddress             = '*'
                                            Port                  = 21
                                            HostName              = ''
                                        }
                    )
                }
                @{
                    MockWebsite = @{
                        Name     = 'MockName'
                        Bindings = @{
                            Collection = @(
                                $MockWebOutputBinding
                            )
                        }
                    }
                    BindingInfo = @(
                        New-CimInstance -ClassName MSFT_xWebBindingInformation `
                                        -Namespace 'root/microsoft/Windows/DesiredStateConfiguration' `
                                        -ClientOnly `
                                        -Property @{
                                            Protocol              = 'http'
                                            IPAddress             = '*'
                                            Port                  = 80
                                            HostName              = ''
                                            CertificateThumbprint = ''
                                            CertificateStoreName  = ''
                                            SslFlags              = 0
                                        }
                    )
                }
                @{
                    MockWebsite = @{
                        Name     = 'MockSite'
                        Bindings = @{
                            Collection = @(
                                $MockWebHttpsOutputBinding
                            )
                        }
                    }
                    BindingInfo = @(
                        New-CimInstance -ClassName MSFT_xWebBindingInformation `
                                        -Namespace 'root/microsoft/Windows/DesiredStateConfiguration' `
                                        -ClientOnly `
                                        -Property @{
                                            Protocol              = 'https'
                                            IPAddress             = '*'
                                            Port                  = 443
                                            HostName              = ''
                                            CertificateThumbprint = 'B30F3184A831320382C61EFB0551766321FA88A5'
                                            CertificateStoreName  = 'MY'
                                            SslFlags              = 0
                                        }
                    )
                }
            )

            foreach($testCase in $testCases)
            {
                Mock -CommandName Get-WebSite -MockWith {return $testCase.MockWebsite}

                Context "Test-BindingInfo returns False for $($testCase.BindingInfo.Protocol) website" {

                    It 'Should throw the correct error' {

                        Mock -CommandName Test-BindingInfo -MockWith {return $false}

                        $ErrorId       = 'WebsiteBindingInputInvalidation'
                        $ErrorCategory = [System.Management.Automation.ErrorCategory]::InvalidResult
                        $ErrorMessage  = $LocalizedData.ErrorWebsiteBindingInputInvalidation -f $testCase.MockWebsite.Name
                        $Exception     = New-Object -TypeName System.InvalidOperationException `
                                                    -ArgumentList $ErrorMessage
                        $ErrorRecord   = New-Object -TypeName System.Management.Automation.ErrorRecord `
                                                    -ArgumentList $Exception, $ErrorId, $ErrorCategory, $null

                        { Test-WebsiteBinding `
                            -Name $testCase.MockWebsite.Name `
                            -BindingInfo $testCase.BindingInfo } | Should Throw $ErrorRecord
                    }
                }

                Context "Bindings comparison throws an error for $($testCase.BindingInfo.Protocol) website" {

                    $ErrorId       = 'WebsiteCompareFailure'
                    $ErrorCategory = [System.Management.Automation.ErrorCategory]::InvalidResult
                    $ErrorMessage  = $LocalizedData.ErrorWebsiteCompareFailure -f $testCase.MockWebsite.Name, 'ScriptHalted'
                    $Exception     = New-Object -TypeName System.InvalidOperationException `
                                                -ArgumentList $ErrorMessage
                    $ErrorRecord   = New-Object -TypeName System.Management.Automation.ErrorRecord `
                                                -ArgumentList $Exception, $ErrorId, $ErrorCategory, $null

                    It 'Should not return an error' {
                        { Test-WebsiteBinding `
                            -Name $testCase.MockWebsite.Name `
                            -BindingInfo $testCase.BindingInfo} | Should Not Throw $ErrorRecord
                    }
                }

                Context "Port is different for $($testCase.BindingInfo.Protocol) website" {

                    $BindingInfo      = $testCase.BindingInfo[0].Clone()
                    $BindingInfo.Port = 8888

                    It 'Should return False' {
                        Test-WebsiteBinding `
                            -Name $testCase.MockWebsite.Name `
                            -BindingInfo $BindingInfo | Should Be $false
                    }
                }

                Context "Protocol is different for $($testCase.BindingInfo.Protocol) website" {

                    $BindingInfo          = $testCase.BindingInfo[0].Clone()
                    $BindingInfo.Protocol = 'net.tcp'
                    $bindingProperty = [Microsoft.Management.Infrastructure.CimProperty]::Create('BindingInformation', `
                                            "$($testCase.BindingInfo.IPAddress):$($testCase.BindingInfo.Port):$($testCase.BindingInfo.HostName)", `
                                            "String", `
                                            "Key"
                                        )
                    $BindingInfo.CimInstanceProperties.Add($bindingProperty)

                    It 'Should return False' {
                        Test-WebsiteBinding `
                            -Name $testCase.MockWebsite.Name `
                            -BindingInfo $BindingInfo -Verbose:$true | Should Be $false
                    }
                }

                Context "IPAddress is different for $($testCase.BindingInfo.Protocol) website" {

                    $BindingInfo           = $testCase.BindingInfo[0].Clone()
                    $BindingInfo.IPAddress = '127.0.0.1'

                    It 'Should return False' {
                        Test-WebsiteBinding `
                            -Name $testCase.MockWebsite.Name `
                            -BindingInfo $BindingInfo | Should Be $false
                    }
                }

                Context "HostName is different for $($testCase.BindingInfo.Protocol) website" {

                    $BindingInfo          = $testCase.BindingInfo[0].Clone()
                    $BindingInfo.HostName = 'MockHostName'

                    It 'Should return False' {
                        Test-WebsiteBinding `
                            -Name $testCase.MockWebsite.Name `
                            -BindingInfo $BindingInfo | Should Be $false
                    }
                }
            }

            Context 'CertificateThumbprint is different' {

                $BindingInfo                       = $testCases[2].BindingInfo[0].Clone()
                $BindingInfo.CertificateThumbprint = '1D3324C6E2F7ABC794C9CB6CA426B8D0F81045CD'
                $MockWebsite                       = $testCases[2].MockWebsite.Clone()

                Mock -CommandName Get-WebSite -MockWith {return $MockWebsite}

                It 'Should return False' {
                    Test-WebsiteBinding `
                        -Name $MockWebsite.Name `
                        -BindingInfo $BindingInfo | Should Be $false
                }
            }

            Context 'CertificateStoreName is different' {

                $BindingInfo                      = $testCases[2].BindingInfo[0].Clone()
                $BindingInfo.CertificateStoreName = 'WebHosting'
                $MockWebsite                      = $testCases[2].MockWebsite.Clone()

                Mock -CommandName Get-WebSite -MockWith {return $MockWebsite}

                It 'Should return False' {
                    Test-WebsiteBinding `
                        -Name $MockWebsite.Name `
                        -BindingInfo $BindingInfo | Should Be $false
                }
            }

            Context 'CertificateStoreName is different and no CertificateThumbprint is specified' {

                $BindingInfo                       = $testCases[2].BindingInfo[0].Clone()
                $BindingInfo.CertificateStoreName  = 'WebHosting'
                $BindingInfo.CertificateThumbprint = ''
                $MockWebsite                       = $testCases[2].MockWebsite.Clone()

                Mock -CommandName Get-WebSite -MockWith {return $MockWebsite}

                $ErrorId       = 'WebsiteBindingInputInvalidation'
                $ErrorCategory = [System.Management.Automation.ErrorCategory]::InvalidResult
                $ErrorMessage  = $LocalizedData.ErrorWebsiteBindingInputInvalidation -f $MockWebsite.Name
                $Exception     = New-Object -TypeName System.InvalidOperationException `
                                            -ArgumentList $ErrorMessage
                $ErrorRecord   = New-Object -TypeName System.Management.Automation.ErrorRecord `
                                            -ArgumentList $Exception, $ErrorId, $ErrorCategory, $null

                It 'Should throw the correct error' {
                    { Test-WebsiteBinding `
                        -Name $MockWebsite.Name `
                        -BindingInfo $BindingInfo} | Should Throw $ErrorRecord
                }
            }

            Context 'SslFlags is different' {

                $BindingInfo          = $testCases[2].BindingInfo[0].Clone()
                $BindingInfo.HostName = 'test.contoso.com'
                $BindingInfo.SslFlags = 1

                $MockWebsite = @{
                    Name     = 'MockSite'
                    Bindings = @{
                        Collection = @()
                    }
                }

                $MockWebsite.Bindings.Collection                      += $testCases[0].MockWebsite.Bindings.Collection[0].Clone()
                $MockWebsite.Bindings.Collection[0].bindingInformation = "$($BindingInfo.IPAddress):$($BindingInfo.Port):$($BindingInfo.HostName)"

                Mock -CommandName Get-WebSite -MockWith {return $MockWebsite}

                It 'Should return False' {
                    Test-WebsiteBinding `
                        -Name $MockWebsite.Name `
                        -BindingInfo $BindingInfo -Verbose:$true | Should Be $false
                }
            }

            Context 'Bindings are identical' {

                $MockWebsite                      = $testCases[0].MockWebsite.Clone()
                $MockWebsite.Bindings.Collection += $testCases[1].MockWebsite.Bindings.Collection[0].Clone()
                $MockWebsite.Bindings.Collection += $testCases[2].MockWebsite.Bindings.Collection[0].Clone()

                $BindingInfo  = @()
                $BindingInfo += $testCases[0].BindingInfo[0].Clone()
                $BindingInfo += $testCases[1].BindingInfo[0].Clone()
                $BindingInfo += $testCases[2].BindingInfo[0].Clone()

                Mock -CommandName Get-WebSite -MockWith {return $MockWebsite}

                It 'Should return True' {
                    Test-WebsiteBinding `
                        -Name $MockWebsite.Name `
                        -BindingInfo $BindingInfo | Should Be $true
                }
            }

            Context 'Bindings are different' {

                $MockWebsite                      = $testCases[0].MockWebsite.Clone()
                $MockWebsite.Bindings.Collection += $testCases[1].MockWebsite.Bindings.Collection[0].Clone()

                $BindingInfo  = @()
                $BindingInfo += $testCases[1].BindingInfo[0].Clone()
                $BindingInfo += $testCases[2].BindingInfo[0].Clone()

                Mock -CommandName Get-Website -MockWith {return $MockWebsite}

                It 'Should return False' {
                    Test-WebsiteBinding `
                        -Name $MockWebsite.Name `
                        -BindingInfo $BindingInfo | Should Be $false
                }
            }
        }

        Describe "$DSCResourceName\Test-BindingInfo" {

            $ftpMockBindingInfo = New-CimInstance `
                                        -ClassName MSFT_FTPBindingInformation `
                                        -Namespace 'root/microsoft/Windows/DesiredStateConfiguration' `
                                        -ClientOnly `
                                        -Property @{
                                            Protocol              = 'ftp'
                                            IPAddress             = '*'
                                            Port                  = 21
                                            HostName              = 'test.contoso.com'
                                        }

            $httpMockBindingInfo = New-CimInstance `
                                        -ClassName MSFT_xWebBindingInformation `
                                        -Namespace 'root/microsoft/Windows/DesiredStateConfiguration' `
                                        -ClientOnly `
                                        -Property @{
                                            Protocol              = 'http'
                                            IPAddress             = '*'
                                            Port                  = 80
                                            HostName              = 'test.contoso.com'
                                        }

            $httpsMockBindingInfo = New-CimInstance `
                                        -ClassName MSFT_xWebBindingInformation `
                                        -Namespace 'root/microsoft/Windows/DesiredStateConfiguration' `
                                        -ClientOnly `
                                        -Property @{
                                            Protocol              = 'https'
                                            IPAddress             = '*'
                                            Port                  = 443
                                            HostName              = 'test.contoso.com'
                                            CertificateThumbprint = 'C65CE51E20C523DEDCE979B9922A0294602D9D5C'
                                            CertificateStoreName  = 'WebHosting'
                                            SslFlags              = 1
                                        }

            Context 'BindingInfo is valid' {

                $MockBindingInfo = @(
                    $ftpMockBindingInfo
                    $httpMockBindingInfo
                    $httpsMockBindingInfo
                )

                It 'Should return True' {
                    Test-BindingInfo -BindingInfo $MockBindingInfo | Should Be $true
                }
            }

            Context 'BindingInfo contains multiple items with the same IPAddress, Port, and HostName combination' {

                $MockBindingInfo = @(
                    $httpMockBindingInfo
                    $httpMockBindingInfo
                )

                It 'Should return False' {
                    Test-BindingInfo -BindingInfo $MockBindingInfo | Should Be $false
                }
            }

            Context 'BindingInfo contains items that share the same Port but have different Protocols' {

                $ftpMockBindingInfo.Port   = 8080
                $httpMockBindingInfo.Port  = 8080
                $httpsMockBindingInfo.Port = 8080

                $MockBindingInfo = @(
                    $ftpMockBindingInfo
                    $httpMockBindingInfo
                    $httpsMockBindingInfo
                )

                It 'Should return False' {
                    Test-BindingInfo -BindingInfo $MockBindingInfo | Should Be $false
                }
            }

            Context 'BindingInfo contains multiple items with the same Protocol and BindingInformation combination' {

                $MockBindingInfo = @(
                    New-CimInstance -ClassName MSFT_xWebBindingInformation `
                                    -Namespace 'root/microsoft/Windows/DesiredStateConfiguration' `
                                    -ClientOnly `
                                    -Property @{
                                        Protocol           = 'net.tcp'
                                        BindingInformation = '808:*'
                                    }

                    New-CimInstance -ClassName MSFT_xWebBindingInformation `
                                    -Namespace 'root/microsoft/Windows/DesiredStateConfiguration' `
                                    -ClientOnly `
                                    -Property @{
                                        Protocol           = 'net.tcp'
                                        BindingInformation = '808:*'
                                    }
                )

                It 'Should return False' {
                    Test-BindingInfo -BindingInfo $MockBindingInfo | Should Be $false
                }
            }
        }
    }
    #endregion
}
finally
{
    #region FOOTER
    #endregion
}
