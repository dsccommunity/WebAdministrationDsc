
$script:DSCModuleName = 'xWebAdministration'
$script:DSCResourceName = 'MSFT_xWebConfigPropertyCollection'

#region HEADER
$script:moduleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
if ( (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests'))) -or `
      (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1'))) )
{
    if (Test-Path -Path (Join-Path -Path $moduleRoot -ChildPath 'DSCResource.Tests.zip'))
    {
        Expand-Archive -Path (Join-Path -Path $moduleRoot -ChildPath 'DSCResource.Tests.zip') -DestinationPath (Join-Path -Path $moduleRoot -ChildPath 'DSCResource.Tests') -Force
    }
    else
    {
        & git @('clone','https://github.com/PowerShell/DscResource.Tests.git',(Join-Path -Path $moduleRoot -ChildPath '\DSCResource.Tests\'))
    }
}

Import-Module (Join-Path -Path $moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1') -Force
Import-Module (Join-Path -Path $moduleRoot -ChildPath 'Tests\MockWebAdministrationWindowsFeature.psm1') -Force -Scope Global

$TestEnvironment = Initialize-TestEnvironment `
    -DSCModuleName $script:DSCModuleName `
    -DSCResourceName $script:DSCResourceName `
    -TestType Unit
#endregion HEADER

# Begin Testing
try
{
    InModuleScope $script:DSCResourceName {
        $script:DSCModuleName = 'xWebAdministration'
        $script:DSCResourceName = 'MSFT_xWebConfigPropertyCollection'

        #region Function Get-TargetResource
        Describe "$($script:DSCResourceName)\Get-TargetResource" {
            Context 'Collection item does not exist' {
                $parameters = @{
                    WebsitePath      = 'MACHINE/WEBROOT/APPHOST'
                    Filter           = 'system.webServer/advancedLogging/server'
                    CollectionName   = 'verbs'
                    ItemName         = 'add'
                    ItemKeyName      = 'verb'
                    ItemKeyValue     = 'TRACE'
                    ItemPropertyName = 'allowed'
                }

                Mock -CommandName Get-ItemValues -ModuleName $script:DSCResourceName -MockWith {
                    return $null
                }

                $result = Get-TargetResource @parameters

                It 'Should return the correct values' {
                    $result.WebsitePath       | Should -Be 'MACHINE/WEBROOT/APPHOST'
                    $result.Filter            | Should -Be 'system.webServer/advancedLogging/server'
                    $result.CollectionName    | Should -Be 'verbs'
                    $result.ItemName          | Should -Be 'add'
                    $result.ItemKeyName       | Should -Be 'verb'
                    $result.ItemKeyValue      | Should -Be 'TRACE'
                    $result.Ensure            | Should -Be 'Absent'
                    $result.ItemPropertyName  | Should -Be 'allowed'
                    $result.ItemPropertyValue | Should -Be $null
                }

                It 'Should have called Get-ItemValues the correct amount of times' {
                    Assert-MockCalled -CommandName Get-ItemValues -Times 1 -Exactly
                }
            }

            Context 'Collection item exists but does not contain property' {
                $parameters = @{
                    WebsitePath      = 'MACHINE/WEBROOT/APPHOST'
                    Filter           = 'system.webServer/advancedLogging/server'
                    CollectionName   = 'verbs'
                    ItemName         = 'add'
                    ItemKeyName      = 'verb'
                    ItemKeyValue     = 'TRACE'
                    ItemPropertyName = 'allowed'
                }

                Mock -CommandName Get-ItemValues -ModuleName $script:DSCResourceName -MockWith {
                    return @(@{
                        Name = 'Property1'
                        Value = 'Property1Value'
                    })
                }

                $result = Get-TargetResource @parameters

                It 'Should return the correct values' {
                    $result.WebsitePath       | Should -Be 'MACHINE/WEBROOT/APPHOST'
                    $result.Filter            | Should -Be 'system.webServer/advancedLogging/server'
                    $result.CollectionName    | Should -Be 'verbs'
                    $result.ItemName          | Should -Be 'add'
                    $result.ItemKeyName       | Should -Be 'verb'
                    $result.ItemKeyValue      | Should -Be 'TRACE'
                    $result.Ensure            | Should -Be 'Absent'
                    $result.ItemPropertyName  | Should -Be 'allowed'
                    $result.ItemPropertyValue | Should -Be $null
                }

                It 'Should have called Get-ItemValues the correct amount of times' {
                    Assert-MockCalled -CommandName Get-ItemValues -Times 1 -Exactly
                }
            }

            Context 'Collection item exists and contains property' {
                $parameters = @{
                    WebsitePath      = 'MACHINE/WEBROOT/APPHOST'
                    Filter           = 'system.webServer/advancedLogging/server'
                    CollectionName   = 'verbs'
                    ItemName         = 'add'
                    ItemKeyName      = 'verb'
                    ItemKeyValue     = 'TRACE'
                    ItemPropertyName = 'allowed'
                }

                Mock -CommandName Get-ItemValues -ModuleName $script:DSCResourceName -MockWith {
                    return @{
                        Property1 = 'Property1Value'
                        allowed = 'false'
                    }
                }

                $result = Get-TargetResource @parameters

                It 'Should return the correct values' {
                    $result.WebsitePath       | Should -Be 'MACHINE/WEBROOT/APPHOST'
                    $result.Filter            | Should -Be 'system.webServer/advancedLogging/server'
                    $result.CollectionName    | Should -Be 'verbs'
                    $result.ItemName          | Should -Be 'add'
                    $result.ItemKeyName       | Should -Be 'verb'
                    $result.ItemKeyValue      | Should -Be 'TRACE'
                    $result.Ensure            | Should -Be 'Present'
                    $result.ItemPropertyName  | Should -Be 'allowed'
                    $result.ItemPropertyValue | Should -Be 'false'
                }

                It 'Should have called Get-ItemValues the correct amount of times' {
                    Assert-MockCalled -CommandName Get-ItemValues -Times 1 -Exactly
                }
            }
        }

        #endregion Function Get-TargetResource

        #region Function Test-TargetResource
        Describe "$($script:DSCResourceName)\Test-TargetResource" {
            Context 'Ensure is present but collection item does not exist' {
                $parameters = @{
                    WebsitePath       = 'MACHINE/WEBROOT/APPHOST'
                    Filter            = 'system.webServer/advancedLogging/server'
                    CollectionName    = 'verbs'
                    ItemName          = 'add'
                    ItemKeyName       = 'verb'
                    ItemKeyValue      = 'TRACE'
                    ItemPropertyName  = 'allowed'
                    ItemPropertyValue = 'false'
                    Ensure            = 'Present'
                }

                Mock -CommandName Get-ItemValues -ModuleName $script:DSCResourceName -MockWith {
                    return $null
                }

                $result = Test-TargetResource @parameters

                It 'Should return false' {
                    $result | Should -Be $false
                }
            }

            Context 'Ensure is present and collection item exists but does not contain property' {
                $parameters = @{
                    WebsitePath       = 'MACHINE/WEBROOT/APPHOST'
                    Filter            = 'system.webServer/advancedLogging/server'
                    CollectionName    = 'verbs'
                    ItemName          = 'add'
                    ItemKeyName       = 'verb'
                    ItemKeyValue      = 'TRACE'
                    ItemPropertyName  = 'allowed'
                    ItemPropertyValue = 'false'
                    Ensure            = 'Present'
                }

                Mock -CommandName Get-ItemValues -ModuleName $script:DSCResourceName -MockWith {
                    return @(@{
                        Name = 'Property1'
                        Value = 'Property1Value'
                    })
                }

                $result = Test-TargetResource @parameters

                It 'Should return false' {
                    $result | Should -Be $false
                }
            }

            Context 'Ensure is present and collection item and property exists but value is wrong' {
                $parameters = @{
                    WebsitePath       = 'MACHINE/WEBROOT/APPHOST'
                    Filter            = 'system.webServer/advancedLogging/server'
                    CollectionName    = 'verbs'
                    ItemName          = 'add'
                    ItemKeyName       = 'verb'
                    ItemKeyValue      = 'TRACE'
                    ItemPropertyName  = 'allowed'
                    ItemPropertyValue = 'false'
                    Ensure            = 'Present'
                }

                Mock -CommandName Get-ItemValues -ModuleName $script:DSCResourceName -MockWith {
                    return @{
                        Property1 = 'Property1Value'
                        allowed = 'true'
                    }
                }

                $result = Test-TargetResource @parameters

                It 'Should return false' {
                    $result | Should -Be $false
                }
            }

            Context 'Ensure is present and collection item and property exists and value is same' {
                $parameters = @{
                    WebsitePath       = 'MACHINE/WEBROOT/APPHOST'
                    Filter            = 'system.webServer/advancedLogging/server'
                    CollectionName    = 'verbs'
                    ItemName          = 'add'
                    ItemKeyName       = 'verb'
                    ItemKeyValue      = 'TRACE'
                    ItemPropertyName  = 'allowed'
                    ItemPropertyValue = 'false'
                    Ensure            = 'Present'
                }

                Mock -CommandName Get-ItemValues -ModuleName $script:DSCResourceName -MockWith {
                    return @{
                        Property1 = 'Property1Value'
                        allowed = 'false'
                    }
                }

                $result = Test-TargetResource @parameters

                It 'Should return true' {
                    $result | Should -Be $true
                }
            }

            Context 'Ensure is absent but collection item and property exists' {
                $parameters = @{
                    WebsitePath       = 'MACHINE/WEBROOT/APPHOST'
                    Filter            = 'system.webServer/advancedLogging/server'
                    CollectionName    = 'verbs'
                    ItemName          = 'add'
                    ItemKeyName       = 'verb'
                    ItemKeyValue      = 'TRACE'
                    ItemPropertyName  = 'allowed'
                    Ensure            = 'Absent'
                }

                Mock -CommandName Get-ItemValues -ModuleName $script:DSCResourceName -MockWith {
                    return @{
                        Property1 = 'Property1Value'
                        allowed = 'false'
                    }
                }

                $result = Test-TargetResource @parameters

                It 'Should return false' {
                    $result | Should -Be $false
                }
            }

            Context 'Ensure is absent and collection item and property do not exist' {
                $parameters = @{
                    WebsitePath       = 'MACHINE/WEBROOT/APPHOST'
                    Filter            = 'system.webServer/advancedLogging/server'
                    CollectionName    = 'verbs'
                    ItemName          = 'add'
                    ItemKeyName       = 'verb'
                    ItemKeyValue      = 'TRACE'
                    ItemPropertyName  = 'allowed'
                    Ensure            = 'Absent'
                }

                Mock -CommandName Get-ItemValues -ModuleName $script:DSCResourceName -MockWith {
                    return $null
                }

                $result = Test-TargetResource @parameters

                It 'Should return true' {
                    $result | Should -Be $true
                }
            }
        }
        #endregion Function Test-TargetResource

        #region Function Set-TargetResource
        Describe "$($script:DSCResourceName)\Set-TargetResource" {
            Context 'Ensure is present and collection item and property do not exist' {
                $parameters = @{
                    WebsitePath       = 'MACHINE/WEBROOT/APPHOST'
                    Filter            = 'system.webServer/advancedLogging/server'
                    CollectionName    = 'verbs'
                    ItemName          = 'add'
                    ItemKeyName       = 'verb'
                    ItemKeyValue      = 'TRACE'
                    ItemPropertyName  = 'allowed'
                    ItemPropertyValue = 'false'
                    Ensure            = 'Present'
                }

                Mock -CommandName Get-ItemValues -ModuleName $script:DSCResourceName -MockWith {
                    return $null
                }
                Mock -CommandName Add-WebConfigurationProperty -MockWith {}

                $result = Set-TargetResource @parameters

                It 'Should call the right Mocks' {
                    Assert-MockCalled -CommandName Get-ItemValues -Times 1 -Exactly
                    Assert-MockCalled -CommandName Add-WebConfigurationProperty -Times 1 -Exactly
                }
            }

            Context 'Ensure is present and collection item and property exist' {
                $parameters = @{
                    WebsitePath       = 'MACHINE/WEBROOT/APPHOST'
                    Filter            = 'system.webServer/advancedLogging/server'
                    CollectionName    = 'verbs'
                    ItemName          = 'add'
                    ItemKeyName       = 'verb'
                    ItemKeyValue      = 'TRACE'
                    ItemPropertyName  = 'allowed'
                    ItemPropertyValue = 'false'
                    Ensure            = 'Present'
                }

                Mock -CommandName Get-ItemValues -ModuleName $script:DSCResourceName -MockWith {
                    return @{
                        Property1 = 'Property1Value'
                        allowed = 'false'
                    }
                }
                Mock -CommandName Set-WebConfigurationProperty -MockWith {}

                $result = Set-TargetResource @parameters

                It 'Should call the right Mocks' {
                    Assert-MockCalled -CommandName Get-ItemValues -Times 1 -Exactly
                    Assert-MockCalled -CommandName Set-WebConfigurationProperty -Times 1 -Exactly
                }
            }

            Context 'Ensure is absent' {
                $parameters = @{
                    WebsitePath       = 'MACHINE/WEBROOT/APPHOST'
                    Filter            = 'system.webServer/advancedLogging/server'
                    CollectionName    = 'verbs'
                    ItemName          = 'add'
                    ItemKeyName       = 'verb'
                    ItemKeyValue      = 'TRACE'
                    ItemPropertyName  = 'allowed'
                    Ensure            = 'Absent'
                }

                Mock -CommandName Remove-WebConfigurationProperty -MockWith {}

                $result = Set-TargetResource @parameters

                It 'Should call the right Mocks' {
                    Assert-MockCalled -CommandName Remove-WebConfigurationProperty -Times 1 -Exactly
                }
            }
        }
        #endregion Function Set-TargetResource

        #endregion Exported Function Unit Tests

        #region Non-Exported Function Unit Tests

        Describe "$($script:DSCResourceName)\Get-ItemValues" {
            Context 'Collection item does not exist' {
                $parameters = @{
                    WebsitePath    = 'MACHINE/WEBROOT/APPHOST'
                    Filter         = 'system.webServer/advancedLogging/server'
                    CollectionName = 'verbs'
                    ItemName       = 'add'
                    ItemKeyName    = 'verb'
                    ItemKeyValue   = 'TRACE'
                }

                Mock -CommandName Get-WebConfigurationProperty -MockWith {
                    return $null
                }

                $result = Get-ItemValues @parameters

                It 'Should return the correct values' {
                    $result | Should -Be $null
                }

                It 'Should have called Get-WebConfigurationProperty the correct amount of times' {
                    Assert-MockCalled -CommandName Get-WebConfigurationProperty -Times 1 -Exactly
                }
            }

            Context 'Collection item exists' {
                $parameters = @{
                    WebsitePath    = 'MACHINE/WEBROOT/APPHOST'
                    Filter         = 'system.webServer/advancedLogging/server'
                    CollectionName = 'verbs'
                    ItemName       = 'add'
                    ItemKeyName    = 'verb'
                    ItemKeyValue   = 'TRACE'
                }

                Mock -CommandName Get-WebConfigurationProperty -MockWith {
                    return @{
                        Attributes = @(
                            @{
                                Name = 'verb'
                                Value = 'TRACE'
                            }
                            @{
                                Name = 'Property1'
                                Value = 'Property1Value'
                            }
                            @{
                                Name = 'Property2'
                                Value = 'Property2Value'
                            }
                        )
                    }
                }

                $result = Get-ItemValues @parameters

                It 'Should return the correct values' {
                    $result              | Should -Not -Be $null
                    $result.Count        | Should -Be 2
                    $result.Keys.Count   | Should -Be 2
                    $result['Property1'] | Should -Be 'Property1Value'
                    $result['Property2'] | Should -Be 'Property2Value'
                }

                It 'Should have called Get-WebConfigurationProperty the correct amount of times' {
                    Assert-MockCalled -CommandName Get-WebConfigurationProperty -Times 1 -Exactly
                }
            }
        }

        #endregion Non-Exported Function Unit Tests
    }
}
finally
{
    if (Get-Module -Name 'MockWebAdministrationWindowsFeature')
    {
        Write-Information 'Removing MockWebAdministrationWindowsFeature module...'
        Remove-Module -Name 'MockWebAdministrationWindowsFeature'
    }
    $mocks = (Get-ChildItem Function:) | Where-Object { $_.Source -eq 'MockWebAdministrationWindowsFeature' }
    if ($mocks)
    {
        Write-Information 'Removing MockWebAdministrationWindowsFeature functions...'
        $mocks | Remove-Item
    }
    #region FOOTER
    Restore-TestEnvironment -TestEnvironment $TestEnvironment
    #endregion
}
