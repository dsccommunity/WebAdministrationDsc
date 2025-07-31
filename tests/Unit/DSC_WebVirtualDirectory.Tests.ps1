
$script:dscModuleName = 'WebAdministrationDsc'
$script:dscResourceName = 'DSC_WebVirtualDirectory'

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

        Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\MockWebAdministrationWindowsFeature.psm1')
        Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\TestHelper\CommonTestHelper.psm1')
}

function Invoke-TestCleanup
{
    Invoke-UnitTestCleanup -TestEnvironment $script:testEnvironment
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

            Mock -CommandName Assert-Module

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

            Context 'Directory is Present and PhysicalPath and Credential is Correct with no WebApplication' {
                It 'Should return true' {
                    $mockUsername = "SomeUsername"
                    $mockPassword = "SomePassword"

                    $returnCredentials = @{
                        'userName' = $mockUsername
                        'password' = $mockPassword
                    }

                    Mock -CommandName Get-WebConfiguration -MockWith { return $returnCredentials }
                    Mock -CommandName Get-WebVirtualDirectory -MockWith { return $virtualDir }

                    $result = Test-TargetResource -Website $MockSite.Website `
                        -WebApplication '' `
                        -Name $MockSite.Name `
                        -PhysicalPath $MockSite.PhysicalPath `
                        -Credential $mockCred `
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

            Context 'Directory is Present and Credential is incorrect' {
                It 'Should return false' {
                    $mockUsername = "SomeUsername"
                    $mockPassword = "SomePassword"
                    $passwordSecureString = $mockPassword | ConvertTo-SecureString -AsPlainText -Force
                    $mockCred = New-Object System.Management.Automation.PSCredential($mockUsername, $passwordSecureString)

                    $returnCredentials = @{
                        'userName' = 'SomeIncorrectUsername'
                        'password' = 'SomeIncorrectPassword'
                    }

                    Mock -CommandName Get-WebConfiguration -MockWith { return $returnCredentials }

                    Mock -CommandName Get-WebVirtualDirectory -MockWith { return $virtualDir }

                    $result = Test-TargetResource -Website $MockSite.Website `
                        -WebApplication $MockSite.WebApplication `
                        -Name $MockSite.Name `
                        -PhysicalPath $MockSite.PhysicalPath `
                        -Credential $mockCred `
                        -Ensure $MockSite.Ensure

                    $result | Should Be $false
                }
            }
        }

        Describe "$script:dscResourceName\Get-TargetResource" {
            Mock -CommandName Assert-Module

            Context 'Ensure = Absent and virtual directory does not exist' {
                It 'Should return the correct values' {
                    $returnSite = @{
                        Name = 'SomeName'
                        Website = 'Website'
                        WebApplication = 'Application'
                        PhysicalPath = 'PhysicalPath'
                        Ensure = 'Absent'
                    }

                    Mock -CommandName Get-WebVirtualDirectory

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
                Mock -CommandName Get-WebConfiguration -MockWith { return @{} }

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

            Context 'Ensure = Present and Physical Path and Credential Exists with no WebApplication' {
                $returnSite = @{
                    Name = 'SomeName'
                    Website = 'Website'
                    WebApplication = ''
                    PhysicalPath = 'PhysicalPath'
                    Ensure = 'Present'
                }

                $returnObj = @{
                    'Name' = $returnSite.Name
                    'PhysicalPath' = $returnSite.PhysicalPath
                    'Count' = 1
                }

                $mockUsername = "SomeUsername"
                $mockPassword = "SomePassword"

                $returnCredentials = [PSCustomObject]@{
                    'userName' = $mockUsername
                    'password' = $mockPassword
                }

                Mock -CommandName Get-WebConfiguration -MockWith { return $returnCredentials }

                Mock -CommandName Get-WebVirtualDirectory -MockWith { return $returnObj }

                $result = Get-TargetResource -Website $returnSite.Website `
                    -WebApplication $returnSite.WebApplication `
                    -Name $returnSite.Name `
                    -PhysicalPath $returnSite.PhysicalPath `
                    -Credential $mockCred

                $result.Name | Should Be $returnSite.Name
                $result.Website | Should Be $returnSite.Website
                $result.WebApplication | Should Be $returnSite.WebApplication
                $result.PhysicalPath | Should Be $returnSite.PhysicalPath
                $result.Ensure | Should Be $returnSite.Ensure
                $result.Credential.UserName | Should Be $mockUsername
            }
        }

        Describe "$script:dscResourceName\Set-TargetResource" {

            Mock -CommandName Assert-Module

            Context 'Ensure = Present and virtual directory does not exist' {
                It 'Should call New-WebVirtualDirectory' {
                    $mockSite = @{
                        Name = 'SomeName'
                        Website = 'Website'
                        WebApplication = 'Application'
                        PhysicalPath = 'PhysicalPath'
                    }

                    Mock -CommandName New-WebVirtualDirectory

                    Mock -CommandName Get-WebVirtualDirectory

                    Set-TargetResource -Website $mockSite.Website `
                        -WebApplication $mockSite.WebApplication `
                        -Name $mockSite.Name `
                        -PhysicalPath $mockSite.PhysicalPath `
                        -Ensure 'Present'

                    Assert-MockCalled -CommandName New-WebVirtualDirectory -Exactly 1
                }
            }

            Context 'Ensure = Present and virtual directory does not exist and Credential provided  with no WebApplication and UncPhysicalPath' {
                It 'Should call New-WebVirtualDirectory' {
                    $mockSite = @{
                        Name = 'SomeName'
                        Website = 'Website'
                        WebApplication = ''
                        PhysicalPath = '\\UncPhysicalPath'
                    }
                    $mockUsername = "SomeUsername"
                    $mockPassword = "SomePassword"
                    $passwordSecureString = $mockPassword | ConvertTo-SecureString -AsPlainText -Force
                    $mockCred = New-Object System.Management.Automation.PSCredential($mockUsername, $passwordSecureString)


                    Mock -CommandName Set-WebConfiguration

                    Mock -CommandName New-WebVirtualDirectory

                    Mock -CommandName Get-WebVirtualDirectory


                    Set-TargetResource -Website $mockSite.Website `
                        -WebApplication $mockSite.WebApplication `
                        -Name $mockSite.Name `
                        -PhysicalPath $mockSite.PhysicalPath `
                        -Credential $mockCred `
                        -Ensure 'Present'

                    Assert-MockCalled -CommandName New-WebVirtualDirectory -Exactly 1
                    Assert-MockCalled -CommandName Set-WebConfiguration -Exactly 1
                }
            }

            Context 'Ensure = Present and WebApplication = ''/''' {
                # Issue #366
                It 'Should change WebApplication to ''''' {
                    $mockSite = @{
                        Name = 'SomeName'
                        Website = 'Website'
                        WebApplication = '/'
                        PhysicalPath = 'PhysicalPath'
                    }

                    Mock -CommandName New-WebVirtualDirectory

                    Mock -CommandName Get-WebVirtualDirectory

                    Set-TargetResource -Website $mockSite.Website `
                        -WebApplication $mockSite.WebApplication `
                        -Name $mockSite.Name `
                        -PhysicalPath $mockSite.PhysicalPath `
                        -Ensure 'Present'

                    Assert-MockCalled -CommandName New-WebVirtualDirectory -Exactly 1 -ParameterFilter {
                        return "$Application" -eq ''
                    }
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
                    Mock -CommandName Set-ItemProperty

                    Set-TargetResource -Website $mockSite.Website `
                        -WebApplication $mockSite.WebApplication `
                        -Name $mockSite.Name `
                        -PhysicalPath $mockSite.PhysicalPath `
                        -Ensure 'Present'

                    Assert-MockCalled -CommandName Set-ItemProperty -Exactly 1
                }
            }

            Context 'Ensure = Present and virtual directory exists and Credential provided' {
                It 'Should call Set-ItemProperty' {
                    $mockSite = @{
                        Name = 'SomeName'
                        Website = 'Website'
                        WebApplication = 'Application'
                        PhysicalPath = 'PhysicalPath'
                        Count = 1
                    }

                    $mockUsername = "SomeUsername"
                    $mockPassword = "SomePassword"
                    $passwordSecureString = $mockPassword | ConvertTo-SecureString -AsPlainText -Force
                    $mockCred = New-Object System.Management.Automation.PSCredential($mockUsername, $passwordSecureString)

                    Mock -CommandName Get-WebVirtualDirectory -MockWith { return $mockSite }
                    Mock -CommandName Set-ItemProperty
                    Mock -CommandName Set-WebConfiguration


                    Set-TargetResource -Website $mockSite.Website `
                        -WebApplication $mockSite.WebApplication `
                        -Name $mockSite.Name `
                        -PhysicalPath $mockSite.PhysicalPath `
                        -Credential $mockCred `
                        -Ensure 'Present'

                    Assert-MockCalled -CommandName Set-ItemProperty -Exactly 1
                    Assert-MockCalled -CommandName Set-WebConfiguration -Exactly 1
                }
            }

            Context 'Ensure = Present and virtual directory exists with Credential provided and no WebApplication and UncPhysicalPath' {
                It 'Should call Set-ItemProperty' {
                    $mockSite = @{
                        Name = 'SomeName'
                        Website = 'Website'
                        WebApplication = ''
                        PhysicalPath = '\\UncPhysicalPath'
                        Count = 1
                    }

                    $mockUsername = "SomeUsername"
                    $mockPassword = "SomePassword"
                    $passwordSecureString = $mockPassword | ConvertTo-SecureString -AsPlainText -Force
                    $mockCred = New-Object System.Management.Automation.PSCredential($mockUsername, $passwordSecureString)

                    Mock -CommandName Get-WebVirtualDirectory -MockWith { return $mockSite }
                    Mock -CommandName Set-ItemProperty
                    Mock -CommandName Set-WebConfiguration

                    Set-TargetResource -Website $mockSite.Website `
                        -WebApplication $mockSite.WebApplication `
                        -Name $mockSite.Name `
                        -PhysicalPath $mockSite.PhysicalPath `
                        -Credential $mockCred `
                        -Ensure 'Present'

                    Assert-MockCalled -CommandName Set-ItemProperty -Exactly 1
                    Assert-MockCalled -CommandName Set-WebConfiguration -Exactly 1
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

                    Mock -CommandName Remove-WebVirtualDirectory

                    Set-TargetResource -Website $mockSite.Website `
                        -WebApplication $mockSite.WebApplication `
                        -Name $mockSite.Name `
                        -PhysicalPath $mockSite.PhysicalPath `
                        -Ensure 'Absent'

                    Assert-MockCalled -CommandName Remove-WebVirtualDirectory -Exactly 1
                }
            }

            Context 'Ensure = Absent and WebApplication = ''''' {
                # Issue #366
                It 'Should change WebApplication to ''/''' {
                    $mockSite = @{
                        Name = 'SomeName'
                        Website = 'Website'
                        WebApplication = ''
                        PhysicalPath = 'PhysicalPath'
                        Count = 1
                    }

                    Mock -CommandName Remove-WebVirtualDirectory

                    Set-TargetResource -Website $mockSite.Website `
                        -WebApplication $mockSite.WebApplication `
                        -Name $mockSite.Name `
                        -PhysicalPath $mockSite.PhysicalPath `
                        -Ensure 'Absent'

                    Assert-MockCalled -CommandName Remove-WebVirtualDirectory -Exactly 1 -ParameterFilter {
                        return "$Application" -eq '/'
                    }
                }
            }
        }
    }
}
finally
{
    Invoke-TestCleanup
}
