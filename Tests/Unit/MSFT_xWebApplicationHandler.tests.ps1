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
            NodeName             = 'LocalHost'
            PSPath               = 'MACHINE/WEBROOT/APPHOST'
            Location             = 'Webtest'
            Name                 = 'ATest-WebHandler'
            Path                 = '*'     
            Verb                 = '*'
            Modules              = 'IsapiModule'
            RequireAccess        = 'None'
            ScriptProcessor      = "C:\Windows\Microsoft.NET\Framework64\v4.0.30319\aspnet_isapi.dll"
            ResourceType         = 'Unspecified'
            AllowPathInfo        = $false
            ResponseBufferLimit  = 0
            PhysicalPath         = "C:\Temp"
            Type                 = $null
            PreCondition         = $null
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

        Describe 'MN_CustomWebHandler/Get-TargetResource' {
        
            Context 'Web handler is Absent' {
            
                Mock Get-WebConfigurationProperty
            
                It 'should return Absent web handler' {
                
                    $result = Get-TargetResource @GetTargetRequiredParams

                    $result.Ensure              | Should be 'Absent'
                    $result.Name                | Should be $null
                    $result.Verb                | Should be $null
                    $result.Path                | Should be $null
                    $result.Modules             | Should be $null
                    $result.RequiredAccess      | Should be $null
                    $result.ScriptProcessor     | Should be $null
                    $result.AllowPathInfo       | Should be $null
                    $result.ResponseBufferLimit | Should be $null
                    $result.Type                | Should be $null
                    $result.PreCondition        | Should be $null
                }
            }

            Context 'Web handler is Present' {

                Mock Get-WebConfigurationProperty -MockWith {$mockCompliantHandler}

                It 'should return existing web handler' {
                
                    $result = Get-TargetResource @GetTargetRequiredParams

                    $result.Ensure              | Should be 'Present'
                    $result.Name                | Should be $mockCompliantHandler.Name
                    $result.Verb                | Should be $mockCompliantHandler.Verb
                    $result.Path                | Should be $mockCompliantHandler.Path
                    $result.Modules             | Should be $mockCompliantHandler.Modules
                    $result.RequiredAccess      | Should be $mockCompliantHandler.RequiredAccess
                    $result.ScriptProcessor     | Should be $mockCompliantHandler.ScriptProcessor
                    $result.AllowPathInfo       | Should be $mockCompliantHandler.AllowPathInfo
                    $result.ResponseBufferLimit | Should be $mockCompliantHandler.ResponseBufferLimit
                    $result.Type                | Should be $mockCompliantHandler.Type
                    $result.PreCondition        | Should be $mockCompliantHandler.PreCondition
                }
            }
        }

        Describe 'MN_CustomWebHandler/Set-TargetResource' {

            Mock Set-WebConfigurationProperty
            Mock Remove-WebHandler
            Mock Add-WebConfigurationProperty
        
            Context 'Ensure = Present and Web handler is Present' {

                It 'should not throw error' {
                    
                    Mock Get-WebConfigurationProperty -MockWith {$mockCompliantHandler}

                    {Set-TargetResource @customWebHandlerParameters} | Should not throw
                }

                It 'should call expected mocks' {

                    Assert-MockCalled -CommandName Get-WebConfigurationProperty -Exactly 1
                    Assert-MockCalled -CommandName Set-WebConfigurationProperty -Exactly 1
                    Assert-MockCalled -CommandName Add-WebConfigurationProperty -Exactly 0
                    Assert-MockCalled -CommandName Remove-WebHandler -Exactly 0
                }
            }

            Context 'Ensure = Present but Web handler is Absent' {

                Mock Get-WebConfigurationProperty

                It 'should not throw error' {

                    {Set-TargetResource @customWebHandlerParameters} | Should not throw
                }

                It 'should call the expected mocks' {

                    Assert-MockCalled -CommandName Get-WebConfigurationProperty -Exactly 1
                    Assert-MockCalled -CommandName Set-WebConfigurationProperty -Exactly 0
                    Assert-MockCalled -CommandName Add-WebConfigurationProperty -Exactly 1
                    Assert-MockCalled -CommandName Remove-WebHandler -Exactly 0
        
                }
            }

            Context 'Ensure = Absent but Web Handler is Present' {

                Mock Get-WebConfigurationProperty -MockWith {$mockCompliantHandler}

                It 'should not throw error' {

                    {Set-TargetResource @customWebHandlerAbsentParameters} | Should not throw
                }

                It 'should call the expected mocks' {

                    Assert-MockCalled -CommandName Get-WebConfigurationProperty -Exactly 1
                    Assert-MockCalled -CommandName Set-WebConfigurationProperty -Exactly 0
                    Assert-MockCalled -CommandName Add-WebConfigurationProperty -Exactly 0
                    Assert-MockCalled -CommandName Remove-WebHandler -Exactly 1
                }
            }
        }

        Describe 'MN_CustomWebHandler/Test-TargetResource' {

            Context 'Web Handler is Present' {
        
                Mock Get-WebConfigurationProperty -MockWith {$mockCompliantHandler}

                It 'should return true when Ensure = Present' {

                    Test-TargetResource @customWebHandlerParameters | Should be $true
                }

                It 'should return false when Ensure = Absent' {

                    Test-TargetResource @customWebHandlerAbsentParameters | should be $false
                }
            }

            Context 'Web Handler is Present but non-compliant' {            

                It 'should return false if Name is non-compliant' {

                    $mockNonCompliantHandler = $mockCompliantHandler.clone()
                    $mockNonCompliantHandler.Name = 'wrong-name'

                    Mock Get-WebConfigurationProperty -MockWith {$mockNonCompliantHandler}

                    Test-TargetResource @customWebHandlerParameters | Should be $false
                }

                It 'should return false if Path is non-compliant' {

                    $mockNonCompliantHandler = $mockCompliantHandler.clone()
                    $mockNonCompliantHandler.Path = 'WrongPath'

                    Mock Get-WebConfigurationProperty -MockWith {$mockNonCompliantHandler}

                    Test-TargetResource @customWebHandlerParameters | Should be $false
                }

                It 'should return false if Verb is non-compliant' {

                    $mockNonCompliantHandler = $mockCompliantHandler.clone()
                    $mockNonCompliantHandler.Verb = 'Wrong verb'

                    Mock Get-WebConfigurationProperty -MockWith {$mockNonCompliantHandler}

                    Test-TargetResource @customWebHandlerParameters | Should be $false
                }

                It 'should return false if Modules is non-compliant' {

                    $mockNonCompliantHandler = $mockCompliantHandler.clone()
                    $mockNonCompliantHandler.Modules = 'Wrong Module'

                    Mock Get-WebConfigurationProperty -MockWith {$mockNonCompliantHandler}

                    Test-TargetResource @customWebHandlerParameters | Should be $false
                }

                It 'should return false if RequireAccess is non-compliant' {

                    $mockNonCompliantHandler = $mockCompliantHandler.clone()
                    $mockNonCompliantHandler.RequireAccess = 'Wrong'

                    Mock Get-WebConfigurationProperty -MockWith {$mockNonCompliantHandler}

                    Test-TargetResource @customWebHandlerParameters | Should be $false
                }

                It 'should return false if ScriptProcessor is non-compliant' {

                    $mockNonCompliantHandler = $mockCompliantHandler.clone()
                    $mockNonCompliantHandler.ScriptProcessor = 'C:\inetpub\wwwroot\wrong.dll'

                    Mock Get-WebConfigurationProperty -MockWith {$mockNonCompliantHandler}

                    Test-TargetResource @customWebHandlerParameters | Should be $false
                }

                It 'should return false if ResourceType is non-compliant' {

                    $mockNonCompliantHandler = $mockCompliantHandler.clone()
                    $mockNonCompliantHandler.ResourceType = 'WrongType'

                    Mock Get-WebConfigurationProperty -MockWith {$mockNonCompliantHandler}

                    Test-TargetResource @customWebHandlerParameters | Should be $false
                }

                It 'should return false if AllowPathInfo is non-compliant' {

                    $mockNonCompliantHandler = $mockCompliantHandler.clone()
                    $mockNonCompliantHandler.AllowPathInfo = $true

                    Mock Get-WebConfigurationProperty -MockWith {$mockNonCompliantHandler}

                    Test-TargetResource @customWebHandlerParameters | Should be $false
                }

                It 'should return false if ResponseBufferLimit is non-compliant' {

                    $mockNonCompliantHandler = $mockCompliantHandler.clone()
                    $mockNonCompliantHandler.ResponseBufferLimit = 12345

                    Mock Get-WebConfigurationProperty -MockWith {$mockNonCompliantHandler}

                    Test-TargetResource @customWebHandlerParameters | Should be $false
                }

                It 'should return false if Type is non-compliant' {

                    $mockNonCompliantHandler = $mockCompliantHandler.clone()
                    $mockNonCompliantHandler.Type = 'WrongType'

                    Mock Get-WebConfigurationProperty -MockWith {$mockNonCompliantHandler}

                    Test-TargetResource @customWebHandlerParameters | Should be $false
                }

                It 'should return false if precondition is non-compliant' {

                    $mockNonCompliantHandler = $mockCompliantHandler.clone()
                    $mockNonCompliantHandler.Precondition = 'wrongPrecondition'

                    Mock Get-WebConfigurationProperty -MockWith {$mockNonCompliantHandler}

                    Test-TargetResource @customWebHandlerParameters | Should be $false
                }
            }
            
            Context 'Web Handler is Absent' {
        
                Mock Get-WebConfigurationProperty

                It 'should return true when Ensure = Absent' {

                    Test-TargetResource @customWebHandlerAbsentParameters | Should be $true
                }

                It 'should return false when Ensure = Present' {

                    Test-TargetResource @customWebHandlerParameters | Should be $false
                }
            }
        }
    }
}

finally {
    #region Footer
    Restore-TestEnvironment -TestEnvironment $TestEnvironment
    #endregion
}
