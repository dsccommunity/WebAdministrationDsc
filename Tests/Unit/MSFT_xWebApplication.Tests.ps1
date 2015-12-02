$DSCModuleName = 'xWebAdministration'
$DSCResourceName = 'MSFT_xWebApplication'

$Splat = @{
    Path = $PSScriptRoot
    ChildPath = "..\..\DSCResources\$DSCResourceName\$DSCResourceName.psm1"
    Resolve = $true
    ErrorAction = 'Stop'
}
$DSCResourceModuleFile = Get-Item -Path (Join-Path @Splat)

# should check for the server OS
if ($env:APPVEYOR_BUILD_VERSION)
{
    Add-WindowsFeature -Name Web-Server -Verbose
}

if (Get-Module -Name $DSCResourceName)
{
    Remove-Module -Name $DSCResourceName
}

Import-Module -Name $DSCResourceModuleFile.FullName -Force

$ModuleRoot = "${env:ProgramFiles}\WindowsPowerShell\Modules\$DSCModuleName"

if (-not (Test-Path -Path $ModuleRoot -PathType Container))
{
    New-Item -Path $ModuleRoot -ItemType Directory | Out-Null
}

Copy-Item -Path "$PSScriptRoot\..\..\*" -Destination $ModuleRoot -Recurse -Force -Exclude '.git'


InModuleScope -ModuleName  $DSCResourceName -ScriptBlock {

    $MockParameters = @{
        Website       = 'MockSite'
        Name          = 'MockApp'
        WebAppPool    = 'MockPool'
        PhysicalPath  = 'C:\MockSite\MockApp'
    }

    Describe 'CheckDependencies' {

        Context 'WebAdminstration module is not installed' {

            Mock -CommandName Get-Module -MockWith {
                return $null
            }

            It 'should throw an error' {
                {
                    CheckDependencies
                } | Should Throw 'Please ensure that WebAdministration module is installed.'
            }

        }

    }


    Describe 'Get-TargetResource' {

        Context 'Absent should return correctly' {

            Mock -CommandName Get-WebApplication -MockWith {
                return $null
            }

            It 'should return Absent' {
                $Result = Get-TargetResource @MockParameters
                $Result.Ensure | Should Be 'Absent'
            }

        }

        Context 'Present should return correctly' {

            Mock -CommandName Get-WebApplication -MockWith {
                return @{
                    ApplicationPool = $MockParameters.WebAppPool
                    PhysicalPath = $MockParameters.PhysicalPath
                    Count = 1
                }
            }

            It 'should return Present' {
                $Result = Get-TargetResource @MockParameters
                $Result.Ensure | Should Be 'Present'
            }

        }

    }


    Describe "how Test-TargetResource responds to Ensure = 'Absent'" {

        Context 'Web Application does not exist' {

            Mock -CommandName Get-WebApplication -MockWith {
                return $null
            }

            It 'should return True' {
                $Result = Test-TargetResource -Ensure 'Absent' @MockParameters
                $Result | Should Be $true
            }

        }

        Context 'Web Application exists' {

            Mock -CommandName Get-WebApplication -MockWith {
                return @{Count = 1}
            }

            It 'should return False' {
                $Result = Test-TargetResource -Ensure 'Absent' @MockParameters
                $Result | Should Be $false
            }

        }

    }


    Describe "how Test-TargetResource responds to Ensure = 'Present'" {

        Context 'Web Application does not exist' {

            Mock -CommandName Get-WebApplication -MockWith {
                return $null
            }

            It 'should return False' {
                $Result = Test-TargetResource -Ensure 'Present' @MockParameters
                $Result | Should Be $false
            }

        }

        Context 'Web Application exists and is in the desired state' {

            Mock -CommandName Get-WebApplication -MockWith {
                return @{
                    ApplicationPool = $MockParameters.WebAppPool
                    PhysicalPath = $MockParameters.PhysicalPath
                    Count = 1
                }
            }

            It 'should return True' {
                $Result = Test-TargetResource -Ensure 'Present' @MockParameters
                $Result | Should Be $true
            }

        }

        Context 'Web Application exists but has a different WebAppPool' {

            Mock -CommandName Get-WebApplication -MockWith {
                return @{
                    ApplicationPool = 'MockPoolOther'
                    PhysicalPath = $MockParameters.PhysicalPath
                    Count = 1
                }
            }

            It 'should return False' {
                $Result = Test-TargetResource -Ensure 'Present' @MockParameters
                $Result | Should Be $False
            }

        }

        Context 'Web Application exists but has a different PhysicalPath' {

            Mock -CommandName Get-WebApplication -MockWith {
                return @{
                    ApplicationPool = $MockParameters.WebAppPool
                    PhysicalPath = 'C:\MockSite\MockAppOther'
                    Count = 1
                }
            }

            It 'should return False' {
                $Result = Test-TargetResource -Ensure 'Present' @MockParameters
                $Result | Should Be $False
            }

        }

    }


    Describe "how Set-TargetResource responds to Ensure = 'Absent'" {

        Context 'Web Application exists' {

            Mock -CommandName Remove-WebApplication

            It "should call expected mocks" {

                $Result = Set-TargetResource -Ensure 'Absent' @MockParameters

                Assert-MockCalled -CommandName Remove-WebApplication -Exactly 1

            }

        }

    }


    Describe "how Set-TargetResource responds to Ensure = 'Present'" {

        Context 'Web Application does not exist' {

            Mock -CommandName Get-WebApplication -MockWith {
                return $null
            }

            Mock -CommandName New-WebApplication

            It "should call expected mocks" {

                $Result = Set-TargetResource -Ensure 'Present' @MockParameters

                Assert-MockCalled -CommandName Get-WebApplication -Exactly 1
                Assert-MockCalled -CommandName New-WebApplication -Exactly 1

            }

        }

        Context 'Web Application exists but has a different WebAppPool' {

            Mock -CommandName Get-WebApplication -MockWith {
                return @{
                    ApplicationPool = 'MockPoolOther'
                    PhysicalPath = $MockParameters.PhysicalPath
                    ItemXPath = ("/system.applicationHost/sites/site[@name='{0}']/application[@path='/{1}']" -f $MockParameters.Website, $MockParameters.Name)
                    Count = 1
                }
            }

            Mock -CommandName Set-WebConfigurationProperty

            It "should call expected mocks" {

                $Result = Set-TargetResource -Ensure 'Present' @MockParameters

                Assert-MockCalled -CommandName Get-WebApplication -Exactly 1
                Assert-MockCalled -CommandName Set-WebConfigurationProperty -Exactly 1

            }

        }

        Context 'Web Application exists but has a different PhysicalPath' {

            Mock -CommandName Get-WebApplication -MockWith {
                return @{
                    ApplicationPool = $MockParameters.WebAppPool
                    PhysicalPath = 'C:\MockSite\MockAppOther'
                    ItemXPath = ("/system.applicationHost/sites/site[@name='{0}']/application[@path='/{1}']" -f $MockParameters.Website, $MockParameters.Name)
                    Count = 1
                }
            }

            Mock -CommandName Set-WebConfigurationProperty

            It "should call expected mocks" {

                $Result = Set-TargetResource -Ensure 'Present' @MockParameters

                Assert-MockCalled -CommandName Get-WebApplication -Exactly 1
                Assert-MockCalled -CommandName Set-WebConfigurationProperty -Exactly 1

            }

        }

    }

}


# Cleanup after the test
Remove-Item -Path $ModuleRoot -Recurse -Force

