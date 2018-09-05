$script:DSCModuleName = 'xWebAdministration'
$script:DSCResourceName = 'MSFT_WebApplicationHandler'

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
            Path                = 'MACHINE/WEBROOT/APPHOST'
            Name                = 'ATest-WebHandler'
            PhysicalHandlerPath = '*'
            Verb                = '*'
            Modules             = 'IsapiModule'
            RequireAccess       = 'None'
            ScriptProcessor     = "C:\Windows\Microsoft.NET\Framework64\v4.0.30319\aspnet_isapi.dll"
            ResourceType        = 'Unspecified'
            AllowPathInfo       = $false
            ResponseBufferLimit = 0
            Type                = 'SampleHandler'
            PreCondition        = 'ISAPIMode'
            Location            = 'Default Web Site/TestDir'
        }

        $mockCompliantHandler = @{
            Name                = $customWebHandlerParameters.Name
            PSPath              = $customWebHandlerParameters.Path
            Path                = $customWebHandlerParameters.PhysicalHandlerPath
            Verb                = $customWebHandlerParameters.Verb
            Modules             = $customWebHandlerParameters.Modules
            RequireAccess       = $customWebHandlerParameters.RequireAccess
            ScriptProcessor     = $customWebHandlerParameters.ScriptProcessor
            ResourceType        = $customWebHandlerParameters.ResourceType
            AllowPathInfo       = $customWebHandlerParameters.AllowPathInfo
            ResponseBufferLimit = $customWebHandlerParameters.ResponseBufferLimit
            Type                = $customWebHandlerParameters.Type
            PreCondition        = $customWebHandlerParameters.PreCondition
            Location            = $customWebHandlerParameters.Location
        }

        $mockGetTargetResource = @{
            Name                = 'ATest-WebHandler'
            PhysicalHandlerPath = '*'
            Verb                = '*'
            Type                = 'SampleHandler'
            Modules             = 'IsapiModule'
            ScriptProcessor     = "C:\Windows\Microsoft.NET\Framework64\v4.0.30319\aspnet_isapi.dll"
            PreCondition        = 'ISAPIMode'
            RequireAccess       = 'None'
            AllowPathInfo       = $false
            ResourceType        = 'Unspecified'
            ResponseBufferLimit = 0
            Path                = 'MACHINE/WEBROOT/APPHOST'
            Ensure              = 'Present'
            Location            = 'Default Web Site/TestDir'
        }

        $mockAbsentGetTargetResource = @{
            Name                = $null
            PhysicalHandlerPath = $null
            Verb                = $null
            Type                = $null
            Modules             = $null
            ScriptProcessor     = $null
            PreCondition        = $null
            RequireAccess       = $null
            AllowPathInfo       = $null
            ResourceType        = $null
            ResponseBufferLimit = $null
            Path                = $null
            Location            = $null
            Ensure              = 'Absent'
        }

        $GetTargetRequiredParameters = @{
            Name     = $customWebHandlerParameters.Name
            Path     = $customWebHandlerParameters.Path
            Location = $customWebHandlerParameters.Location
        }

        $customWebHandlerAbsentParameters = $customWebHandlerParameters.clone()
        $customWebHandlerAbsentParameters.Ensure = 'Absent'

        Describe 'MSFT_WebApplicationHandler/Get-TargetResource' {

            Context 'When Web handler is Absent' {

                Mock Get-WebConfigurationProperty

                It 'Should return Absent web handler' {

                    $result = Get-TargetResource @GetTargetRequiredParameters

                    $result.Ensure              | Should -Be 'Absent'
                    $result.Name                | Should -Be $null
                    $result.Verb                | Should -Be $null
                    $result.PhysicalHandlerPath | Should -Be $null
                    $result.Path                | Should -Be $GetTargetRequiredParameters.Path
                    $result.Modules             | Should -Be $null
                    $result.RequiredAccess      | Should -Be $null
                    $result.ScriptProcessor     | Should -Be $null
                    $result.AllowPathInfo       | Should -Be $null
                    $result.ResponseBufferLimit | Should -Be $null
                    $result.Type                | Should -Be $null
                    $result.ResourceType        | Should -Be $null
                    $result.PreCondition        | Should -Be $null
                    $result.Location            | Should -Be $GetTargetRequiredParameters.Location
                }
            }

            Context 'When Web handler is Present' {

                Mock Get-WebConfigurationProperty -MockWith {$mockCompliantHandler}

                It 'Should return existing web handler' {

                    $result = Get-TargetResource @GetTargetRequiredParameters

                    $result.Ensure              | Should -Be 'Present'
                    $result.Name                | Should -Be $mockCompliantHandler.Name
                    $result.Verb                | Should -Be $mockCompliantHandler.Verb
                    $result.PhysicalHandlerPath | Should -Be $mockCompliantHandler.Path
                    $result.Path                | Should -Be $mockCompliantHandler.PSPath
                    $result.Modules             | Should -Be $mockCompliantHandler.Modules
                    $result.RequiredAccess      | Should -Be $mockCompliantHandler.RequiredAccess
                    $result.ScriptProcessor     | Should -Be $mockCompliantHandler.ScriptProcessor
                    $result.AllowPathInfo       | Should -Be $mockCompliantHandler.AllowPathInfo
                    $result.ResponseBufferLimit | Should -Be $mockCompliantHandler.ResponseBufferLimit
                    $result.Type                | Should -Be $mockCompliantHandler.Type
                    $result.PreCondition        | Should -Be $mockCompliantHandler.PreCondition
                    $result.Location            | Should -Be $mockCompliantHandler.Location
                }
            }
        }

        Describe 'MSFT_WebApplicationHandler/Set-TargetResource' {

            Mock Set-WebConfigurationProperty
            Mock Remove-WebHandler
            Mock Add-WebConfigurationProperty

            Context 'When Ensure = Present and Web handler is Present' {

                It 'Should not throw error' {

                    Mock Get-TargetResource -MockWith {$mockGetTargetResource}

                    {Set-TargetResource @customWebHandlerParameters} | Should -Not -Throw
                }

                It 'Should call expected mocks' {

                    Assert-MockCalled -CommandName Get-TargetResource -Exactly -Times 1
                    Assert-MockCalled -CommandName Set-WebConfigurationProperty -Exactly -Times 1
                    Assert-MockCalled -CommandName Add-WebConfigurationProperty -Exactly -Times 0
                    Assert-MockCalled -CommandName Remove-WebHandler -Exactly -Times 0
                }
            }

            Context 'When Ensure = Present but Web handler is Absent' {

                Mock Get-TargetResource -MockWith {$mockAbsentGetTargetResource}

                It 'Should not throw error' {

                    {Set-TargetResource @customWebHandlerParameters} | Should -Not -Throw
                }

                It 'Should call the expected mocks' {

                    Assert-MockCalled -CommandName Get-TargetResource -Exactly -Times 1
                    Assert-MockCalled -CommandName Set-WebConfigurationProperty -Exactly -Times 0
                    Assert-MockCalled -CommandName Add-WebConfigurationProperty -Exactly -Times 1
                    Assert-MockCalled -CommandName Remove-WebHandler -Exactly -Times 0

                }
            }

            Context 'When Ensure = Absent but Web Handler is Present' {

                Mock Get-TargetResource -MockWith {$mockGetTargetResource}

                It 'Should not throw error' {

                    {Set-TargetResource @customWebHandlerAbsentParameters} | Should -Not -Throw
                }

                It 'Should call the expected mocks' {

                    Assert-MockCalled -CommandName Get-TargetResource -Exactly -Times 1
                    Assert-MockCalled -CommandName Set-WebConfigurationProperty -Exactly -Times 0
                    Assert-MockCalled -CommandName Add-WebConfigurationProperty -Exactly -Times 0
                    Assert-MockCalled -CommandName Remove-WebHandler -Exactly -Times 1
                }
            }

            Context 'When Ensure = Absent and Web Handler is Absent' {

                Mock Get-TargetResource -MockWith {$mockAbsentGetTargetResource}

                It 'Should not throw error' {

                    {Set-TargetResource @customWebHandlerAbsentParameters} | Should -Not -Throw
                }

                It 'Should do nothing'{

                    Assert-MockCalled -CommandName Get-TargetResource -Exactly -Times 1
                    Assert-MockCalled -CommandName Set-WebConfigurationProperty -Exactly -Times 0
                    Assert-MockCalled -CommandName Add-WebConfigurationProperty -Exactly -Times 0
                    Assert-MockCalled -CommandName Remove-WebHandler -Exactly -Times 0
                }
            }
        }

        Describe 'MSFT_WebApplicationHandler/Test-TargetResource' {

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
                BeforeEach {
                    $mockNonCompliantHandler = $mockCompliantHandler.clone()
                }

                It 'Should return false if Name is non-compliant' {

                    $mockNonCompliantHandler.Name = 'wrong-name'

                    Mock Get-WebConfigurationProperty -MockWith {$mockNonCompliantHandler}

                    Test-TargetResource @customWebHandlerParameters | Should Be $false
                }

                It 'Should return false if Path is non-compliant' {

                    $mockNonCompliantHandler.Path = 'WrongPath'

                    Mock Get-WebConfigurationProperty -MockWith {$mockNonCompliantHandler}

                    Test-TargetResource @customWebHandlerParameters | Should Be $false
                }

                It 'Should return false if Verb is non-compliant' {

                    $mockNonCompliantHandler.Verb = 'Wrong verb'

                    Mock Get-WebConfigurationProperty -MockWith {$mockNonCompliantHandler}

                    Test-TargetResource @customWebHandlerParameters | Should Be $false
                }

                It 'Should return false if Modules is non-compliant' {

                    $mockNonCompliantHandler.Modules = 'Wrong Module'

                    Mock Get-WebConfigurationProperty -MockWith {$mockNonCompliantHandler}

                    Test-TargetResource @customWebHandlerParameters | Should Be $false
                }

                It 'Should return false if RequireAccess is non-compliant' {

                    $mockNonCompliantHandler.RequireAccess = 'Wrong'

                    Mock Get-WebConfigurationProperty -MockWith {$mockNonCompliantHandler}

                    Test-TargetResource @customWebHandlerParameters | Should Be $false
                }

                It 'Should return false if ScriptProcessor is non-compliant' {

                    $mockNonCompliantHandler.ScriptProcessor = 'C:\inetpub\wwwroot\wrong.dll'

                    Mock Get-WebConfigurationProperty -MockWith {$mockNonCompliantHandler}

                    Test-TargetResource @customWebHandlerParameters | Should Be $false
                }

                It 'Should return false if ResourceType is non-compliant' {

                    $mockNonCompliantHandler.ResourceType = 'WrongType'

                    Mock Get-WebConfigurationProperty -MockWith {$mockNonCompliantHandler}

                    Test-TargetResource @customWebHandlerParameters | Should Be $false
                }

                It 'Should return false if AllowPathInfo is non-compliant' {

                    $mockNonCompliantHandler.AllowPathInfo = $true

                    Mock Get-WebConfigurationProperty -MockWith {$mockNonCompliantHandler}

                    Test-TargetResource @customWebHandlerParameters | Should Be $false
                }

                It 'Should return false if ResponseBufferLimit is non-compliant' {

                    $mockNonCompliantHandler.ResponseBufferLimit = 12345

                    Mock Get-WebConfigurationProperty -MockWith {$mockNonCompliantHandler}

                    Test-TargetResource @customWebHandlerParameters | Should Be $false
                }

                It 'Should return false if Type is non-compliant' {

                    $mockNonCompliantHandler.Type = 'WrongType'

                    Mock Get-WebConfigurationProperty -MockWith {$mockNonCompliantHandler}

                    Test-TargetResource @customWebHandlerParameters | Should Be $false
                }

                It 'Should return false if precondition is non-compliant' {

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
