# Suppressing this rule because the globals are appropriate for tests
[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '')]
param ()

$Global:DSCModuleName = 'xWebAdministration'
$Global:DSCResourceName = 'MSFT_xSSLSettings'

#region HEADER

[String] $moduleRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $Script:MyInvocation.MyCommand.Path))
$repoSource = (Get-Module -Name $Global:DSCModuleName -ListAvailable)

# If module was obtained from the gallery install test folder from the gallery instead of cloning from git
if (($null -ne $repoSource) -and ($repoSource[0].RepositorySourceLocation.Host -eq 'www.powershellgallery.com'))
{
    if ( -not (Test-Path -Path (Join-Path -Path $moduleRoot -ChildPath 'Tests\DscResourceTestHelper')) )
    {
        $choice = 'y'

        # If user wants to skip prompt - set this environment variale equal to 'true'
        if ($env:getDscTestHelper -ne $true)
        {
            $choice = read-host "In order to run this test you need to install a helper module, continue with installation? (Y/N)"
        }

        if ($choice -eq 'y')
        {
            # Install test folders from gallery
            Save-Module -Name 'DscResourceTestHelper' -Path (Join-Path -Path $moduleRoot -ChildPath 'Tests')
        }

        else 
        {
            Write-Error "Unable to run tests without the required helper module - Exiting test"
            return
        }
        
    }

    $testModuleVer = Get-ChildItem -Path (Join-Path -Path $moduleRoot -ChildPath '\Tests\DscResourceTestHelper')
    Import-Module (Join-Path -Path $moduleRoot -ChildPath "Tests\DscResourceTestHelper\$testModuleVer\TestHelper.psm1") -Force
} 
# Otherwise module was cloned from github
else
{
    # Get common tests and test helpers from gitHub rather than installing them from the gallery
    # This ensures that developers always have access to the most recent DscResource.Tests folder 
    $testHelperPath = (Join-Path -Path $moduleRoot -ChildPath '\Tests\DscResource.Tests\DscResourceTestHelper\TestHelper.psm1')
    if (-not (Test-Path -Path $testHelperPath))
    {
        # Clone test folders from gitHub
        $dscResourceTestsPath = Join-Path -Path $moduleRoot -ChildPath '\Tests\DscResource.Tests'
        & git @('clone','https://github.com/PowerShell/DscResource.Tests.git',$dscResourceTestsPath)
        
        # TODO get rid of this section once we update all other resources and merge the gitDependency branch with the main branch on DscResource.Tests
        Push-Location
        Set-Location $dscResourceTestsPath
        & git checkout gitDependency
        Pop-Location
    }

    Import-Module $testHelperPath -Force
}

$TestEnvironment = Initialize-TestEnvironment `
    -DSCModuleName $Global:DSCModuleName `
    -DSCResourceName $Global:DSCResourceName `
    -TestType Unit
#endregion

# Begin Testing

try
{
    #region Pester Tests

    InModuleScope $DSCResourceName {

        Describe "$Global:DSCResourceName\Test-TargetResource" {
            Context 'Ensure is Present and SSLSettings is Present' {
                Mock Get-TargetResource -Verifiable {return @{
                    Name = 'Test'
                    Bindings = @('SSL')
                    Ensure = 'Present'
                }}

                $result = Test-TargetResource -Name 'Test' -Ensure 'Present' -Bindings 'SSL'

                Assert-VerifiableMocks

                It 'should return true' {
                    $result | should be $true
                }
            }

            Context 'Ensure is Absent and SSLSettings is Absent' {
                Mock Get-TargetResource {return @{
                    Name = 'Test'
                    Bindings = @('SSL')
                    Ensure = 'Absent'
                }}

                $result = Test-TargetResource -Name 'Test' -Ensure 'Absent' -Bindings 'SSL'

                Assert-VerifiableMocks

                It 'should return true' {
                    $result | should be $true
                }
            }

            Context 'Ensure is Present and SSLSettings is Absent' {
                Mock Get-TargetResource {return @{
                    Name = 'Test'
                    Bindings = @('SSL')
                    Ensure = 'Absent'
                }}

                $result = Test-TargetResource -Name 'Test' -Ensure 'Present' -Bindings 'SSL'

                Assert-VerifiableMocks

                It 'should return true' {
                    $result | should be $false
                }
            }
        }

        Describe "$Global:DSCResourceName\Get-TargetResource" {
            Context 'Command finds SSL Settings' {
                Mock Assert-Module -Verifiable { }
                Mock Get-WebConfigurationProperty -Verifiable {return 'SSL'}

                $result = Get-TargetResource -Name 'Name' -Bindings 'Test'
                $expected = @{
                    Name = 'Name'
                    Bindings = 'SSL'
                    Ensure = 'Present'
                }

                Assert-VerifiableMocks

                It 'should return the correct bindings' {
                    $result.Bindings | should be $expected.Bindings
                }

                It 'should return the correct ensure' {
                    $result.Ensure | Should Be $expected.Ensure
                }
            }

            Context 'Command does not find SSL Settings' {
                Mock Assert-Module -Verifiable { }
                Mock Get-WebConfigurationProperty -Verifiable {return $false}

                $result = Get-TargetResource -Name 'Name' -Bindings 'Test'
                $expected = @{
                    Name = 'Name'
                    Bindings = 'None'
                    Ensure = 'Absent'
                }

                Assert-VerifiableMocks

                It 'should return the correct bindings' {
                    $result.Bindings | should be $expected.Bindings
                }

                It 'should return the correct ensure' {
                    $result.Ensure | Should Be $expected.Ensure
                }
            }
        }

        Describe "$Global:DSCResourceName\Set-TargetResource" {
            Context 'SSL Bindings set to none' {
                Mock Assert-Module -Verifiable { }
                Mock Set-WebConfigurationProperty -Verifiable {}

                $result = (Set-TargetResource -Name 'Name' -Bindings 'None' -Ensure 'Present' -Verbose) 4>&1
                $string = $LocalizedData.SettingSSLConfig -f 'Name', 'None'
                $expected = "Set-TargetResource: $string"

                Assert-VerifiableMocks

                It 'should return the correct string' {
                    $result | Should Be $expected
                }
            }

            Context 'SSL Bindings set to SSL' {
                Mock Assert-Module -Verifiable { }
                Mock Set-WebConfigurationProperty -Verifiable {}

                $result = (Set-TargetResource -Name 'Name' -Bindings 'SSL' -Ensure 'Present' -Verbose) 4>&1
                $string = $LocalizedData.SettingSSLConfig -f 'Name', 'SSL'
                $expected = "Set-TargetResource: $string"

                Assert-VerifiableMocks

                It 'should return the correct string' {
                    $result | Should Be $expected
                }
            }

            Context 'SSL Bindings set to Ssl,SslNegotiateCert,SslRequireCert' {
                Mock Assert-Module -Verifiable { }
                Mock Set-WebConfigurationProperty -Verifiable {}

                $result = (Set-TargetResource -Name 'Name' -Bindings @('Ssl','SslNegotiateCert','SslRequireCert') -Ensure 'Present' -Verbose) 4>&1
                $string = $LocalizedData.SettingSSLConfig -f 'Name', 'Ssl,SslNegotiateCert,SslRequireCert'
                $expected = "Set-TargetResource: $string"

                Assert-VerifiableMocks

                It 'should return the correct string' {
                    $result | Should Be $expected
                }
            }
        }
    }
}
finally
{
    #region FOOTER
    Restore-TestEnvironment -TestEnvironment $TestEnvironment
    #endregion
}
