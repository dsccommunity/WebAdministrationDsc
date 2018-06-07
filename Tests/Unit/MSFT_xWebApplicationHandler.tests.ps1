$script:DSCModuleName = 'xWebAdministration'
$script:DSCResourceName = 'MSFT_xWebApplicationHandler'

#region Header
#Unit Test Template Version: 1.0.0

$script:moduleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)

if ( (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests'))) -or `
    (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1'))) )
{
    & git @('clone','https://github.com/PowerShell/DscResource.Tests.git',(Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests'))
}

Import-Module -Name (Join-Path -Path $script:moduleRoot -ChildPath (Join-Path -Path 'DSCResource.Tests' -ChildPath 'TestHelper.psm1')) -Force

$TestEnvironment = Initialize-TestEnvironment `
    -DSCModuleName $script:DSCModuleName `
    -DSCResourceName $script:DSCResourceName `
    -TestType Unit
#endregion

# Begin Tests
try
{
    InModuleScope $DSCResourceName {

        $customWebHandlerParameters = @{
            PSPath               = 'MACHINE/WEBROOT/APPHOST'
            Name                 = 'ATest-WebHandler'
            Path                 = '*'
            Verb                 = '*'
            Modules              = 'IsapiModule'
            RequireAccess        = 'None'
            ScriptProcessor      = "C:\Windows\Microsoft.NET\Framework64\v4.0.30319\aspnet_isapi.dll"
            ResourceType         = 'Unspecified'
            AllowPathInfo        = $false
            ResponseBufferLimit  = 0
            Type                 = 'SampleHandler'
            PreCondition         = 'ISAPIMode'
        }

        $mockCompliantHandler = @{
            Name                = $customWebHandlerParameters.Name
            PSPath              = $customWebHandlerParameters.PSPath
            Path                = $customWebHandlerParameters.Path
            Verb                = $customWebHandlerParameters.Verb
            Modules             = $customWebHandlerParameters.Modules
            RequireAccess       = $customWebHandlerParameters.RequireAccess
            ScriptProcessor     = $customWebHandlerParameters.ScriptProcessor
            ResourceType        = $customWebHandlerParameters.ResourceType
            AllowPathInfo       = $customWebHandlerParameters.AllowPathInfo
            ResponseBufferLimit = $customWebHandlerParameters.ResponseBufferLimit
            Type                = $customWebHandlerParameters.Type
            PreCondition        = $customWebHandlerParameters.PreCondition
        }

        $GetTargetRequiredParams = @{
            Name     = $customWebHandlerParameters.Name
            PSPath   = $customWebHandlerParameters.PSPath
        }

        $customWebHandlerAbsentParameters = $customWebHandlerParameters.clone()
        $customWebHandlerAbsentParameters.Ensure = 'Absent'

        Describe 'MSFT_xWebApplicationHandler/Get-TargetResource' {

            Context 'When Web handler is Absent' {

                Mock Get-WebConfigurationProperty

                It 'Should return Absent web handler' {

                    $result = Get-TargetResource @GetTargetRequiredParams

                    $result.Ensure              | Should Be 'Absent'
                    $result.Name                | Should Be $null
                    $result.Verb                | Should Be $null
                    $result.Path                | Should Be $null
                    $result.Modules             | Should Be $null
                    $result.RequiredAccess      | Should Be $null
                    $result.ScriptProcessor     | Should Be $null
                    $result.AllowPathInfo       | Should Be $null
                    $result.ResponseBufferLimit | Should Be $null
                    $result.Type                | Should Be $null
                    $result.PreCondition        | Should Be $null
                }
            }

            Context 'When Web handler is Present' {

                Mock Get-WebConfigurationProperty -MockWith {$mockCompliantHandler}

                It 'Should return existing web handler' {

                    $result = Get-TargetResource @GetTargetRequiredParams

                    $result.Ensure              | Should Be 'Present'
                    $result.Name                | Should Be $mockCompliantHandler.Name
                    $result.Verb                | Should Be $mockCompliantHandler.Verb
                    $result.Path                | Should Be $mockCompliantHandler.Path
                    $result.Modules             | Should Be $mockCompliantHandler.Modules
                    $result.RequiredAccess      | Should Be $mockCompliantHandler.RequiredAccess
                    $result.ScriptProcessor     | Should Be $mockCompliantHandler.ScriptProcessor
                    $result.AllowPathInfo       | Should Be $mockCompliantHandler.AllowPathInfo
                    $result.ResponseBufferLimit | Should Be $mockCompliantHandler.ResponseBufferLimit
                    $result.Type                | Should Be $mockCompliantHandler.Type
                    $result.PreCondition        | Should Be $mockCompliantHandler.PreCondition
                }
            }
        }

        Describe 'MSFT_xWebApplicationHandler/Set-TargetResource' {

            Mock Set-WebConfigurationProperty
            Mock Remove-WebHandler
            Mock Add-WebConfigurationProperty

            Context 'When Ensure = Present and Web handler is Present' {

                It 'Should not throw error' {

                    Mock Get-WebConfigurationProperty -MockWith {$mockCompliantHandler}

                    {Set-TargetResource @customWebHandlerParameters} | Should -Not throw
                }

                It 'Should call expected mocks' {

                    Assert-MockCalled -CommandName Get-WebConfigurationProperty -Exactly -Times 1
                    Assert-MockCalled -CommandName Set-WebConfigurationProperty -Exactly -Times 1
                    Assert-MockCalled -CommandName Add-WebConfigurationProperty -Exactly -Times 0
                    Assert-MockCalled -CommandName Remove-WebHandler -Exactly -Times 0
                }
            }

            Context 'When Ensure = Present but Web handler is Absent' {

                Mock Get-WebConfigurationProperty

                It 'Should not throw error' {

                    {Set-TargetResource @customWebHandlerParameters} | Should -Not throw
                }

                It 'Should call the expected mocks' {

                    Assert-MockCalled -CommandName Get-WebConfigurationProperty -Exactly -Times 1
                    Assert-MockCalled -CommandName Set-WebConfigurationProperty -Exactly -Times 0
                    Assert-MockCalled -CommandName Add-WebConfigurationProperty -Exactly -Times 1
                    Assert-MockCalled -CommandName Remove-WebHandler -Exactly -Times 0

                }
            }

            Context 'When Ensure = Absent but Web Handler is Present' {

                Mock Get-WebConfigurationProperty -MockWith {$mockCompliantHandler}

                It 'Should not throw error' {

                    {Set-TargetResource @customWebHandlerAbsentParameters} | Should -Not throw
                }

                It 'Should call the expected mocks' {

                    Assert-MockCalled -CommandName Get-WebConfigurationProperty -Exactly -Times 1
                    Assert-MockCalled -CommandName Set-WebConfigurationProperty -Exactly -Times 0
                    Assert-MockCalled -CommandName Add-WebConfigurationProperty -Exactly -Times 0
                    Assert-MockCalled -CommandName Remove-WebHandler -Exactly -Times 1
                }
            }
        }

        Describe 'MSFT_xWebApplicationHandler/Test-TargetResource' {

            Context 'When Web Handler is Present' {

                Mock Get-WebConfigurationProperty -MockWith {$mockCompliantHandler}

                It 'Should return true when Ensure = Present' {

                    Test-TargetResource @customWebHandlerParameters | Should Be $true
                }

                It 'Should return false when Ensure = Absent' {

                    Test-TargetResource @customWebHandlerAbsentParameters | Should Be $false
                }
            }

            Context 'When Web Handler is Present but non-compliant' {

                It 'Should return false if Name is non-compliant' {

                    $mockNonCompliantHandler = $mockCompliantHandler.clone()
                    $mockNonCompliantHandler.Name = 'wrong-name'

                    Mock Get-WebConfigurationProperty -MockWith {$mockNonCompliantHandler}

                    Test-TargetResource @customWebHandlerParameters | Should Be $false
                }

                It 'Should return false if Path is non-compliant' {

                    $mockNonCompliantHandler = $mockCompliantHandler.clone()
                    $mockNonCompliantHandler.Path = 'WrongPath'

                    Mock Get-WebConfigurationProperty -MockWith {$mockNonCompliantHandler}

                    Test-TargetResource @customWebHandlerParameters | Should Be $false
                }

                It 'Should return false if Verb is non-compliant' {

                    $mockNonCompliantHandler = $mockCompliantHandler.clone()
                    $mockNonCompliantHandler.Verb = 'Wrong verb'

                    Mock Get-WebConfigurationProperty -MockWith {$mockNonCompliantHandler}

                    Test-TargetResource @customWebHandlerParameters | Should Be $false
                }

                It 'Should return false if Modules is non-compliant' {

                    $mockNonCompliantHandler = $mockCompliantHandler.clone()
                    $mockNonCompliantHandler.Modules = 'Wrong Module'

                    Mock Get-WebConfigurationProperty -MockWith {$mockNonCompliantHandler}

                    Test-TargetResource @customWebHandlerParameters | Should Be $false
                }

                It 'Should return false if RequireAccess is non-compliant' {

                    $mockNonCompliantHandler = $mockCompliantHandler.clone()
                    $mockNonCompliantHandler.RequireAccess = 'Wrong'

                    Mock Get-WebConfigurationProperty -MockWith {$mockNonCompliantHandler}

                    Test-TargetResource @customWebHandlerParameters | Should Be $false
                }

                It 'Should return false if ScriptProcessor is non-compliant' {

                    $mockNonCompliantHandler = $mockCompliantHandler.clone()
                    $mockNonCompliantHandler.ScriptProcessor = 'C:\inetpub\wwwroot\wrong.dll'

                    Mock Get-WebConfigurationProperty -MockWith {$mockNonCompliantHandler}

                    Test-TargetResource @customWebHandlerParameters | Should Be $false
                }

                It 'Should return false if ResourceType is non-compliant' {

                    $mockNonCompliantHandler = $mockCompliantHandler.clone()
                    $mockNonCompliantHandler.ResourceType = 'WrongType'

                    Mock Get-WebConfigurationProperty -MockWith {$mockNonCompliantHandler}

                    Test-TargetResource @customWebHandlerParameters | Should Be $false
                }

                It 'Should return false if AllowPathInfo is non-compliant' {

                    $mockNonCompliantHandler = $mockCompliantHandler.clone()
                    $mockNonCompliantHandler.AllowPathInfo = $true

                    Mock Get-WebConfigurationProperty -MockWith {$mockNonCompliantHandler}

                    Test-TargetResource @customWebHandlerParameters | Should Be $false
                }

                It 'Should return false if ResponseBufferLimit is non-compliant' {

                    $mockNonCompliantHandler = $mockCompliantHandler.clone()
                    $mockNonCompliantHandler.ResponseBufferLimit = 12345

                    Mock Get-WebConfigurationProperty -MockWith {$mockNonCompliantHandler}

                    Test-TargetResource @customWebHandlerParameters | Should Be $false
                }

                It 'Should return false if Type is non-compliant' {

                    $mockNonCompliantHandler = $mockCompliantHandler.clone()
                    $mockNonCompliantHandler.Type = 'WrongType'

                    Mock Get-WebConfigurationProperty -MockWith {$mockNonCompliantHandler}

                    Test-TargetResource @customWebHandlerParameters | Should Be $false
                }

                It 'Should return false if precondition is non-compliant' {

                    $mockNonCompliantHandler = $mockCompliantHandler.clone()
                    $mockNonCompliantHandler.Precondition = 'wrongPrecondition'

                    Mock Get-WebConfigurationProperty -MockWith {$mockNonCompliantHandler}

                    Test-TargetResource @customWebHandlerParameters | Should Be $false
                }
            }

            Context 'When Web Handler is Absent' {

                Mock Get-WebConfigurationProperty

                It 'Should return true when Ensure = Absent' {

                    Test-TargetResource @customWebHandlerAbsentParameters | Should Be $true
                }

                It 'Should return false when Ensure = Present' {

                    Test-TargetResource @customWebHandlerParameters | Should Be $false
                }
            }
        }
    }
}

finally
{
    #region Footer
    Restore-TestEnvironment -TestEnvironment $TestEnvironment
    #endregion
}
