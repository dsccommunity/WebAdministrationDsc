
$script:dscModuleName = 'xWebAdministration'
$script:dscResourceName = 'MSFT_xWebVirtualDirectory'

function Invoke-TestSetup
{
    try
    {
        Import-Module -Name DscResource.Test -Force
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
        Describe "$script:dscResourceName\Test-TargetResource" {
            $MockSite = @{
                Website        = 'contoso.com'
                WebApplication = 'contosoapp'
                Name           = 'shared_directory'
                PhysicalPath   = 'C:\inetpub\wwwroot\shared'
                Ensure         = 'Present'
            }
            $virtualDir = @{
                Name = 'shared_directory'
                PhysicalPath = 'C:\inetpub\wwwroot\shared'
                Count = 1
            }

            Mock -CommandName Assert-Module -MockWith {}

            Context 'Directory is Present and PhysicalPath is Correct' {
                It 'Should return true' {
                    Mock -CommandName Get-WebVirtualDirectory -MockWith { return $virtualDir }

                    $result = Test-TargetResource -Website $MockSite.Website `
                        -WebApplication $MockSite.WebApplication `
                        -Name $MockSite.Name `
                        -PhysicalPath $MockSite.PhysicalPath `
                        -Ensure $MockSite.Ensure

                    $result | Should Be $true
                }
            }

            Context 'Directory is Present and PhysicalPath is incorrect' {
                It 'Should return false' {
                    $virtualDir = @{
                        Name = 'shared_directory'
                        PhysicalPath = 'C:\inetpub\wwwroot\shared_wrong'
                        Count = 1
                    }

                    Mock -CommandName Get-WebVirtualDirectory -MockWith { return $virtualDir }

                    $result = Test-TargetResource -Website $MockSite.Website `
                        -WebApplication $MockSite.WebApplication `
                        -Name $MockSite.Name `
                        -PhysicalPath $MockSite.PhysicalPath `
                        -Ensure $MockSite.Ensure

                    $result | Should Be $false
                }
            }

            Context 'Directory is Present and PhysicalPath is incorrect' {
                It 'Should return false' {
                    $virtualDir = @{
                        Name = 'shared_directory'
                        PhysicalPath = 'C:\inetpub\wwwroot\shared_wrong'
                        Count = 1
                    }

                    Mock -CommandName Get-WebVirtualDirectory -MockWith { return $virtualDir }
                    $result = Test-TargetResource -Website $MockSite.Website `
                        -WebApplication $MockSite.WebApplication `
                        -Name $MockSite.Name `
                        -PhysicalPath $MockSite.PhysicalPath `
                        -Ensure $MockSite.Ensure

                    $result | Should Be $false
                }
            }
        }

        Describe "$script:dscResourceName\Get-TargetResource" {
            Mock -CommandName Assert-Module -MockWith {}

            Context 'Ensure = Absent and virtual directory does not exist' {
                It 'Should return the correct values' {
                    $returnSite = @{
                        Name = 'SomeName'
                        Website = 'Website'
                        WebApplication = 'Application'
                        PhysicalPath = 'PhysicalPath'
                        Ensure = 'Absent'
                    }

                    Mock -CommandName Get-WebVirtualDirectory -MockWith { return $null }

                    $result = Get-TargetResource -Website $returnSite.Website `
                        -WebApplication $returnSite.WebApplication `
                        -Name $returnSite.Name `
                        -PhysicalPath $returnSite.PhysicalPath

                    $result.Name | Should Be $returnSite.Name
                    $result.Website | Should Be $returnSite.Website
                    $result.WebApplication | Should Be $returnSite.WebApplication
                    $result.PhysicalPath | Should Be ''
                    $result.Ensure | Should Be $returnSite.Ensure
                }
            }

            Context 'Ensure = Present and Physical Path Exists' {
                $returnSite = @{
                    Name = 'SomeName'
                    Website = 'Website'
                    WebApplication = 'Application'
                    PhysicalPath = 'PhysicalPath'
                    Ensure = 'Present'
                }

                $returnObj = @{
                    'Name' = $returnSite.Name
                    'PhysicalPath' = $returnSite.PhysicalPath
                    'Count' = 1
                }

                Mock -CommandName Get-WebVirtualDirectory -MockWith { return $returnObj }

                $result = Get-TargetResource -Website $returnSite.Website `
                    -WebApplication $returnSite.WebApplication `
                    -Name $returnSite.Name `
                    -PhysicalPath $returnSite.PhysicalPath

                $result.Name | Should Be $returnSite.Name
                $result.Website | Should Be $returnSite.Website
                $result.WebApplication | Should Be $returnSite.WebApplication
                $result.PhysicalPath | Should Be $returnSite.PhysicalPath
                $result.Ensure | Should Be $returnSite.Ensure
            }
        }

        Describe "$script:dscResourceName\Set-TargetResource" {

            Mock -CommandName Assert-Module -MockWith {}

            Context 'Ensure = Present and virtual directory does not exist' {
                It 'Should call New-WebVirtualDirectory' {
                    $mockSite = @{
                        Name = 'SomeName'
                        Website = 'Website'
                        WebApplication = 'Application'
                        PhysicalPath = 'PhysicalPath'
                    }

                    Mock -CommandName New-WebVirtualDirectory -MockWith { return $null }

                    Set-TargetResource -Website $mockSite.Website `
                        -WebApplication $mockSite.WebApplication `
                        -Name $mockSite.Name `
                        -PhysicalPath $mockSite.PhysicalPath `
                        -Ensure 'Present'

                    Assert-MockCalled -CommandName New-WebVirtualDirectory -Exactly 1
                }
            }

            Context 'Ensure = Present and virtual directory exists' {
                It 'Should call Set-ItemProperty' {
                    $mockSite = @{
                        Name = 'SomeName'
                        Website = 'Website'
                        WebApplication = 'Application'
                        PhysicalPath = 'PhysicalPath'
                        Count = 1
                    }

                    Mock -CommandName Get-WebVirtualDirectory -MockWith { return $mockSite }
                    Mock -CommandName Set-ItemProperty -MockWith { return $null }

                    Set-TargetResource -Website $mockSite.Website `
                        -WebApplication $mockSite.WebApplication `
                        -Name $mockSite.Name `
                        -PhysicalPath $mockSite.PhysicalPath `
                        -Ensure 'Present'

                    Assert-MockCalled -CommandName Set-ItemProperty -Exactly 1
                }
            }

            Context 'Ensure = Absent' {
                It 'Should call Remove-WebVirtualDirectory' {
                    $mockSite = @{
                        Name = 'SomeName'
                        Website = 'Website'
                        WebApplication = 'Application'
                        PhysicalPath = 'PhysicalPath'
                        Count = 1
                    }

                    Mock -CommandName Remove-WebVirtualDirectory -MockWith { return $null }

                    Set-TargetResource -Website $mockSite.Website `
                        -WebApplication $mockSite.WebApplication `
                        -Name $mockSite.Name `
                        -PhysicalPath $mockSite.PhysicalPath `
                        -Ensure 'Absent'

                    Assert-MockCalled -CommandName Remove-WebVirtualDirectory -Exactly 1
                }
            }
        }
    }
}
finally
{
    Invoke-TestCleanup
}
