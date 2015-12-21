$global:DSCModuleName = 'xWebAdministration'
$global:DSCResourceName = 'MSFT_xWebVirtualDirectory'

#region HEADER
if ( (-not (Test-Path -Path '.\DSCResource.Tests\')) -or `
     (-not (Test-Path -Path '.\DSCResource.Tests\TestHelper.psm1')) )
{
    & git @('clone','https://github.com/PowerShell/DscResource.Tests.git')
}
else
{
    & git @('-C',(Join-Path -Path (Get-Location) -ChildPath '\DSCResource.Tests\'),'pull')
}
Import-Module .\DSCResource.Tests\TestHelper.psm1 -Force
$TestEnvironment = Initialize-TestEnvironment `
    -DSCModuleName $Global:DSCModuleName `
    -DSCResourceName $global:DSCResourceName `
    -TestType Unit
#endregion

try
{
    InModuleScope $global:DSCResourceName {
        Describe "$global:DSCResourceName\Test-TargetResource" {
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
            Context 'WebAdminstration is not installed' {
                It 'should throw an error if WebAdministration is not installed' {
                    Mock Get-Module -ModuleName $ModuleName { return $null }
                    {
                        Test-TargetResource -Website $MockSite.Website -WebApplication $MockSite.WebApplication -Name $MockSite.Name -PhysicalPath $MockSite.PhysicalPath -Ensure $MockSite.Ensure
                    } | Should Throw 'Please ensure that WebAdministration module is installed.'
                }
            }
            Context 'Directory is Present and PhysicalPath is Correct' {
                It 'should return true' {
                    Mock Get-WebVirtualDirectoryInternal { return $virtualDir }
                    Test-TargetResource -Website $MockSite.Website -WebApplication $MockSite.WebApplication -Name $MockSite.Name -PhysicalPath $MockSite.PhysicalPath -Ensure $MockSite.Ensure | Should Be $true
                }
            }

            Context 'Directory is Present and PhysicalPath is incorrect' {
                It 'should return false' {
                    $virtualDir = @{
                        Name = 'shared_directory'
                        PhysicalPath = 'C:\inetpub\wwwroot\shared_wrong'
                        Count = 1
                    }

                    Mock Get-WebVirtualDirectoryInternal { return $virtualDir }
                    Test-TargetResource -Website $MockSite.Website -WebApplication $MockSite.WebApplication -Name $MockSite.Name -PhysicalPath $MockSite.PhysicalPath -Ensure $MockSite.Ensure | Should Be $false
                }
            }

            Context 'Directory is Present and PhysicalPath is incorrect' {
                It 'should return false' {
                    $virtualDir = @{
                        Name = 'shared_directory'
                        PhysicalPath = 'C:\inetpub\wwwroot\shared_wrong'
                        Count = 1
                    }

                    Mock Get-WebVirtualDirectoryInternal { return $virtualDir }
                    Test-TargetResource -Website $MockSite.Website -WebApplication $MockSite.WebApplication -Name $MockSite.Name -PhysicalPath $MockSite.PhysicalPath -Ensure $MockSite.Ensure | Should Be $false
                }
            }
        }

        Describe "$global:DSCResourceName\Get-TargetResource" {
            Context 'Ensure = Absent and virtual directory does not exist' {
                It 'should return the correct values' {
                    $returnSite = @{
                        Name = 'SomeName'
                        Website = 'Website'
                        WebApplication = 'Application'
                        PhysicalPath = 'PhysicalPath'
                        Ensure = 'Absent'
                    }
                    Mock Test-Dependancies { return $null }
                    Mock Get-WebVirtualDirectoryInternal { return $null }
                    $result = Get-TargetResource -Website $returnSite.Website -WebApplication $returnSite.WebApplication -Name $returnSite.Name -PhysicalPath $returnSite.PhysicalPath

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

                Mock Test-Dependancies { return $null }
                Mock Get-WebVirtualDirectoryInternal { return $returnObj }
                $result = Get-TargetResource -Website $returnSite.Website -WebApplication $returnSite.WebApplication -Name $returnSite.Name -PhysicalPath $returnSite.PhysicalPath

                $result.Name | Should Be $returnSite.Name
                $result.Website | Should Be $returnSite.Website
                $result.WebApplication | Should Be $returnSite.WebApplication
                $result.PhysicalPath | Should Be $returnSite.PhysicalPath
                $result.Ensure | Should Be $returnSite.Ensure
            }
        }

        Describe "$global:DSCResourceName\Set-TargetResource" {
            Context 'Ensure = Present and virtual directory does not exist' {
                It 'should call New-WebVirtualDirectory' {
                    $mockSite = @{
                        Name = 'SomeName'
                        Website = 'Website'
                        WebApplication = 'Application'
                        PhysicalPath = 'PhysicalPath'
                    }

                    Mock Test-Dependancies { return $null }
                    Mock New-WebVirtualDirectory { return $null }
                    $null = Set-TargetResource -Website $mockSite.Website -WebApplication $mockSite.WebApplication -Name $mockSite.Name -PhysicalPath $mockSite.PhysicalPath -Ensure 'Present'
                    Assert-MockCalled New-WebVirtualDirectory -Exactly 1
                }
            }

            Context 'Ensure = Present and virtual directory exists' {
                It 'should call Set-ItemProperty' {
                    $mockSite = @{
                        Name = 'SomeName'
                        Website = 'Website'
                        WebApplication = 'Application'
                        PhysicalPath = 'PhysicalPath'
                        Count = 1
                    }

                    Mock Test-Dependancies { return $null }
                    Mock Get-WebVirtualDirectoryInternal { return $mockSite }
                    Mock Set-ItemProperty { return $null }
                    $null = Set-TargetResource -Website $mockSite.Website -WebApplication $mockSite.WebApplication -Name $mockSite.Name -PhysicalPath $mockSite.PhysicalPath -Ensure 'Present'
                    Assert-MockCalled Set-ItemProperty -Exactly 1
                }
            }

            Context 'Ensure = Absent' {
                It 'should call Remove-WebVirtualDirectory' {
                    $mockSite = @{
                        Name = 'SomeName'
                        Website = 'Website'
                        WebApplication = 'Application'
                        PhysicalPath = 'PhysicalPath'
                        Count = 1
                    }

                    Mock Test-Dependancies { return $null }
                    Mock Remove-WebVirtualDirectory { return $null }
                    $null = Set-TargetResource -Website $mockSite.Website -WebApplication $mockSite.WebApplication -Name $mockSite.Name -PhysicalPath $mockSite.PhysicalPath -Ensure 'Absent'
                    Assert-MockCalled Remove-WebVirtualDirectory -Exactly 1
                }
            }
        }

        Describe "$global:DSCResourceName\Get-WebVirtualDirectoryInternal" {
            $MockSite = @{
                Website        = 'contoso.com'
                WebApplication = 'contosoapp'
                Name           = 'shared_directory'
                PhysicalPath   = 'C:\inetpub\wwwroot\shared'
                Ensure         = 'Present'
            }

            Context 'Test-ApplicationExists returns false' {
                Mock Test-ApplicationExists { return $false }
                Mock Get-WebVirtualDirectory { return $Name }
                It 'return the correct string' {
                    Get-WebVirtualDirectoryInternal -Name $MockSite.Name -Site $MockSite.Website -Application $MockSite.WebApplication | should be "$($MockSite.WebApplication)/$($MockSite.Name)"
                }
            }

            Context 'Test-ApplicationExists returns true' {
                $returnObj = @{
                    'Name' = $MockSite.Name
                    'Physical Path' = $MockSite.PhysicalPath
                }
                Mock Test-ApplicationExists { return $false }
                Mock Get-WebVirtualDirectory { return $returnObj }

                It 'return the correct string' {
                    Get-WebVirtualDirectoryInternal -Name $MockSite.Name -Site $MockSite.Website -Application $MockSite.WebApplication | should be $returnObj
                }
            }
        }

        Describe "$global:DSCResourceName\Test-ApplicationExists" {
            $MockSite = @{
                Website        = 'contoso.com'
                WebApplication = 'contosoapp'
                Name           = 'shared_directory'
                PhysicalPath   = 'C:\inetpub\wwwroot\shared'
                Ensure         = 'Present'
            }

            Context 'Get-WebApplication returns a value' {
                It 'should return true' {
                    Mock Get-WebApplication { return @{Count = 1} }
                    Test-ApplicationExists -Site $MockSite.Website -Application $MockSite.WebApplication | should be $true
                }
            }

            Context 'Get-WebApplication returns no value' {
                It 'should return false' {
                    Mock Get-WebApplication { return @{Count = 0} }
                    Test-ApplicationExists -Site $MockSite.Website -Application $MockSite.WebApplication | should be $false
                }
            }
        }

        Describe "$global:DSCResourceName\Get-CompositeName" {
            Context 'data is passed in' {
                It 'should return the correct string' {
                    Get-CompositeName -Name 'Name' -Application 'Application' | should be 'Application/Name'
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
