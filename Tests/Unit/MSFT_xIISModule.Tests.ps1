$script:DSCModuleName = 'xWebAdministration'
$script:DSCResourceName = 'MSFT_xIisModule'

# Unit Test Template Version: 1.1.0
$script:moduleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
if ( (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests'))) -or `
     (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1'))) )
{
    & git @('clone','https://github.com/PowerShell/DscResource.Tests.git',(Join-Path -Path $script:moduleRoot -ChildPath '\DSCResource.Tests\'))
}

Import-Module (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1') -Force

Import-Module (Join-Path -Path $script:moduleRoot -ChildPath 'Tests\MockWebAdministrationWindowsFeature.psm1')

$TestEnvironment = Initialize-TestEnvironment `
    -DSCModuleName $script:DSCModuleName `
    -DSCResourceName $script:DSCResourceName `
    -TestType Unit
#endregion HEADER

# Begin Testing
try
{
    #region Pester Tests

    InModuleScope $script:DSCResourceName {


        Describe "$script:DSCResourceName\Assert-Module" {

            Context 'WebAdminstration module is not installed' {
                Mock -ModuleName Helper -CommandName Get-Module -MockWith {
                    return $null
                }

                It 'Should throw an error' {
                    { Assert-Module } |
                    Should Throw

                }

            }

        }

        Describe "$script:DSCResourceName\Get-TargetResource" {

            Context 'Resource does not exist. We need to add it' {

                $TestParams = @{
                    Name       = "Test Module"
                    SiteName   = "Test Site"
                    Code       = "Litware.Contoso.Tests"
                }
                Mock -CommandName Get-WebManagedModule -MockWith {
                    return $null
                }

                Mock -CommandName New-WebManagedModule -MockWith {
                    return $null
                }

                Mock -CommandName Assert-Module -MockWith {}

                It 'Should Absent from the Get Method' {
                    (Get-TargetResource @TestParams).Ensure | Should Be 'Absent'
                }

                It 'Should create the module from the Set Method' {
                    Set-TargetResource @TestParams
                }

                It 'Should return false from the Test method' {
                    Test-TargetResource @TestParams | Should be $false
                }
            }
        }
    }
    #endregion
}

finally
{
    Restore-TestEnvironment -TestEnvironment $TestEnvironment
}
