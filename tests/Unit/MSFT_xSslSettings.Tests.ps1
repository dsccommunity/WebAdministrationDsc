
$script:dscModuleName = 'xWebAdministration'
$script:dscResourceName = 'MSFT_xSslSettings'

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
        $script:dscResourceName = 'MSFT_xSslSettings'

        Describe "$script:dscResourceName\Test-TargetResource" {
            Context 'Ensure is Present and SSLSettings is Present' {
                Mock Get-TargetResource -Verifiable {return @{
                    Name = 'Test'
                    Bindings = @('Ssl')
                    Ensure = 'Present'
                }}

                $result = Test-TargetResource -Name 'Test' -Ensure 'Present' -Bindings 'Ssl'

                Assert-VerifiableMock

                It 'should return true' {
                    $result | should be $true
                }
            }

            Context 'Ensure is Absent and SslSettings is Absent' {
                Mock Get-TargetResource {return @{
                    Name = 'Test'
                    Bindings = @('Ssl')
                    Ensure = 'Absent'
                }}

                $result = Test-TargetResource -Name 'Test' -Ensure 'Absent' -Bindings 'Ssl'

                Assert-VerifiableMock

                It 'should return true' {
                    $result | should be $true
                }
            }

            Context 'Ensure is Present and SslSettings is Absent' {
                Mock Get-TargetResource {return @{
                    Name = 'Test'
                    Bindings = @('Ssl')
                    Ensure = 'Absent'
                }}

                $result = Test-TargetResource -Name 'Test' -Ensure 'Present' -Bindings 'Ssl'

                Assert-VerifiableMock

                It 'should return true' {
                    $result | should be $false
                }
            }
        }

        Describe "$script:dscResourceName\Get-TargetResource" {
            Context 'Command finds SSL Settings' {
                Mock Assert-Module -Verifiable {}
                Mock Get-WebConfigurationProperty -Verifiable { return 'Ssl' }

                $result = Get-TargetResource -Name 'Name' -Bindings 'Ssl'
                $expected = @{
                    Name = 'Name'
                    Bindings = 'Ssl'
                    Ensure = 'Present'
                }

                Assert-VerifiableMock

                It 'should return the correct bindings' {
                    $result.Bindings | should be $expected.Bindings
                }

                It 'should return the correct ensure' {
                    $result.Ensure | Should Be $expected.Ensure
                }
            }

            Context 'Command does not find Ssl Settings' {
                Mock Assert-Module -Verifiable {}
                Mock Get-WebConfigurationProperty -Verifiable { return $false }

                $result = Get-TargetResource -Name 'Name' -Bindings 'Ssl'
                $expected = @{
                    Name = 'Name'
                    Bindings = 'Ssl'
                    Ensure = 'Absent'
                }

                Assert-VerifiableMock

                It 'should return the correct bindings' {
                    $result.Bindings | should be $expected.Bindings
                }

                It 'should return the correct ensure' {
                    $result.Ensure | Should Be $expected.Ensure
                }
            }
        }

        Describe "$script:dscResourceName\Set-TargetResource" {
            Context 'SSL Bindings set to none' {
                Mock Assert-Module -Verifiable { }
                Mock Set-WebConfigurationProperty -Verifiable {}

                $result = (Set-TargetResource -Name 'Name' -Bindings '' -Ensure 'Present' -Verbose) 4>&1

                # Check that the LocalizedData message from the Set-TargetResource is correct
                $resultMessage = $script:localizedData.SettingSSLConfig -f 'Name', ''

                Assert-VerifiableMock

                It 'should return the correct string' {
                    $result | Should Be $resultMessage
                }
            }

            Context 'Ssl Bindings set to Ssl' {
                Mock Assert-Module -Verifiable { }
                Mock Set-WebConfigurationProperty -Verifiable {}

                $result = (Set-TargetResource -Name 'Name' -Bindings 'Ssl' -Ensure 'Present' -Verbose) 4>&1

                # Check that the LocalizedData message from the Set-TargetResource is correct
                $resultMessage = $script:localizedData.SettingSSLConfig -f 'Name', 'Ssl'

                Assert-VerifiableMock

                It 'should return the correct string' {
                    $result | Should Be $resultMessage
                }
            }

            Context 'Ssl Bindings set to Ssl,SslNegotiateCert,SslRequireCert' {
                Mock Assert-Module -Verifiable {}
                Mock Set-WebConfigurationProperty -Verifiable {}

                $result = (Set-TargetResource -Name 'Name' -Bindings @('Ssl','SslNegotiateCert','SslRequireCert') -Ensure 'Present' -Verbose) 4>&1

                # Check that the LocalizedData message from the Set-TargetResource is correct
                $resultMessage = $script:localizedData.SettingSSLConfig -f 'Name', 'Ssl,SslNegotiateCert,SslRequireCert'

                Assert-VerifiableMock

                It 'should return the correct string' {
                    $result | Should Be $resultMessage
                }
            }
        }
    }
}
finally
{
    Invoke-TestCleanup
}
