
$script:DSCModuleName = 'xWebSiteDefaults'
$script:DSCResourceName = 'MSFT_xWebSiteDefaults'

#region HEADER
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
#endregion

try
{
    InModuleScope $script:DSCResourceName {

        Describe "$script:DSCResourceName\Assert-Module" {
            Context 'WebAdminstration module is not installed' {
                Mock -ModuleName Helper -CommandName Get-Module -MockWith {
                    return $null
                }

                It 'Should throw an error' {
                    { Assert-Module } | Should Throw
                }
            }
        }

        Describe "$script:DSCResourceName\Test-TargetResource" {
            $mockWebSiteDefaults = @{
                logFormat = "W3C"
                directory = "c:\inetpub"
                applicationPool = "Default App Pool"
                allowSubDirConfig = $true
            }

            Mock Get-WebConfigurationProperty -MockWith {
                $path = $Filter.Replace('system.applicationHost/sites/siteDefaults/', '')

                if ([System.String]::IsNullOrEmpty($path)) {
                    return $MockWebSiteDefaults[$Name]
                } else {
                    $path = $path.Replace('/', '')
                    return $MockWebSiteDefaults[$path][$Name]
                }
            }

            Context 'Returns Defaults' {
                $params = @{
                    ApplyTo   = "Machine"
                    LogFormat = "W3C"
                    Ensure    = "Present"
                }
                It 'Should return true from the Test function' {
                    $result = Test-TargetResource @params

                    $result | Should Be $true
                }

                It 'Should update the default values in the Set function' {
                    Set-TargetResource @params
                }

                It 'Should return Present from the Get function' {
                    Set-TargetResource @params
                }

                It 'Should extract the default values from the Export function' {
                    Export-TargetResource
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
