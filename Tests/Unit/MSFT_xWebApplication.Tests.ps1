$Global:DSCModuleName = 'xWebAdministration'
$Global:DSCResourceName = 'MSFT_xWebApplication'

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
    -DSCResourceName $Global:DSCResourceName `
    -TestType Unit
#endregion

try
{
    InModuleScope -ModuleName $global:DSCResourceName -ScriptBlock {
        
        function Get-WebConfiguration {}
        function Get-WebApplication {}

        $MockParameters = @{
            Website                  = 'MockSite'
            Name                     = 'MockApp'
            WebAppPool               = 'MockPool'
            PhysicalPath             = 'C:\MockSite\MockApp'
            PreloadEnabled           = 'True'
            ServiceAutoStartProvider = 'MockServiceAutoStartProvider'
            ServiceAutoStartEnabled  = 'True'
            ApplicationType          = 'MockApplicationType'
        }

        $GetWebConfigurationOutput = @(
                @{
                    SectionPath = 'MockSectionPath'
                    PSPath      = 'MockPSPath'
                    Collection  = @(
                                [PSCustomObject]@{Name = 'MockServiceAutoStartProvider' ;Type = 'MockApplicationType'}   
                    )
                }
            )

        Describe "$Global:DSCResourceName\CheckDependencies" {
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

        Describe "$Global:DSCResourceName\Get-TargetResource" {
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
                        ApplicationPool          = $MockParameters.WebAppPool
                        PhysicalPath             = $MockParameters.PhysicalPath
                        PreloadEnabled           = $MockParameters.PreloadEnabled
                        ServiceAutoStartProvider = $MockParameters.ServiceAutoStartProvider
                        ServiceAutoStartEnabled  = $MockParameters.ServiceAutoStartEnabled 
                        Count = 1
                    }
                }

                It 'should return Present' {
                    $Result = Get-TargetResource @MockParameters
                    $Result.Ensure | Should Be 'Present'
                }
            }
        }

        Describe "how $Global:DSCResourceName\Test-TargetResource responds to Ensure = 'Absent'" {
            
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

        Describe "how $Global:DSCResourceName\Test-TargetResource responds to Ensure = 'Present'" {
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
                        ApplicationPool          = $MockParameters.WebAppPool
                        PhysicalPath             = $MockParameters.PhysicalPath
                        PreloadEnabled           = $MockParameters.PreloadEnabled
                        ServiceAutoStartEnabled  = $MockParameters.ServiceAutoStartEnabled 
                        ServiceAutoStartProvider = $MockParameters.ServiceAutoStartProvider
                        ApplicationType          = $MockParameters.ApplicationType
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
                        ApplicationPool          = 'MockPoolOther'
                        PhysicalPath             = $MockParameters.PhysicalPath
                        PreloadEnabled           = $MockParameters.PreloadEnabled
                        ServiceAutoStartEnabled  = $MockParameters.ServiceAutoStartEnabled 
                        ServiceAutoStartProvider = $MockParameters.ServiceAutoStartProvider
                        ApplicationType          = $MockParameters.ApplicationType
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
                        ApplicationPool          = $MockParameters.WebAppPool
                        PhysicalPath             = 'C:\MockSite\MockAppOther'
                        PreloadEnabled           = $MockParameters.PreloadEnabled
                        ServiceAutoStartProvider = $MockParameters.ServiceAutoStartProvider
                        ServiceAutoStartEnabled  = $MockParameters.ServiceAutoStartEnabled 
                        Count = 1
                    }
                }

                It 'should return False' {
                    $Result = Test-TargetResource -Ensure 'Present' @MockParameters
                    $Result | Should Be $False
                }
            }

            Context 'Check Preload is different' {

                Mock -CommandName Get-WebApplication -MockWith {
                    return @{
                        ApplicationPool          = $MockParameters.WebAppPool
                        PhysicalPath             = $MockParameters.PhysicalPath
                        PreloadEnabled           = 'false'
                        ServiceAutoStartProvider = $MockParameters.ServiceAutoStartProvider
                        ServiceAutoStartEnabled  = $MockParameters.ServiceAutoStartEnabled 
                        Count = 1
                        }
                    }

                $Result = Test-TargetResource -Ensure 'Present' @MockParameters

                It 'should return False' {
                    $Result | Should Be $false
                }

            }

            Context 'Check ServiceAutoStartEnabled is different' {

                Mock -CommandName Get-WebApplication -MockWith {
                    return @{
                        ApplicationPool          = $MockParameters.WebAppPool
                        PhysicalPath             = $MockParameters.PhysicalPath
                        PreloadEnabled           = $MockParameters.PreloadEnabled
                        ServiceAutoStartProvider = $MockParameters.ServiceAutoStartProvider
                        ServiceAutoStartEnabled  = 'false'
                        Count = 1
                        }
                    }

                $Result = Test-TargetResource -Ensure 'Present' @MockParameters

                It 'should return False' {
                    $Result | Should Be $false
                }

            }
            
            Context 'Check ServiceAutoStartProvider is different' {

                Mock -CommandName Get-WebApplication -MockWith {
                    return @{
                        ApplicationPool          = $MockParameters.WebAppPool
                        PhysicalPath             = $MockParameters.PhysicalPath
                        PreloadEnabled           = $MockParameters.PreloadEnabled
                        ServiceAutoStartEnabled  = $MockParameters.ServiceAutoStartEnabled
                        ServiceAutoStartProvider = 'ServiceAutoStartProviderOther'
                        ApplicationType          = 'ApplicationTypeOther'
                        Count = 1
                        }
                    }

                

                $Result = Test-TargetResource -Ensure 'Present' @MockParameters

                It 'should return False' {
                    $Result | Should Be $false
                }

            }
            
            
        }

        Describe "how $Global:DSCResourceName\Set-TargetResource responds to Ensure = 'Absent'" {
            
            
            Context 'Web Application exists' {
                Mock -CommandName Remove-WebApplication

                It 'should call expected mocks' {
                    $Result = Set-TargetResource -Ensure 'Absent' @MockParameters
                    Assert-MockCalled -CommandName Remove-WebApplication -Exactly 1
                }
            }
        }

        Describe "how $Global:DSCResourceName\Set-TargetResource responds to Ensure = 'Present'" {
            Context 'Web Application does not exist' {
                Mock -CommandName Get-WebApplication -MockWith {
                    return $null
                }

                Mock -CommandName New-WebApplication
                Mock -CommandName Set-ItemProperty
                Mock -CommandName Add-WebConfiguration
                Mock -CommandName Confirm-UniqueServiceAutoStartProviders {return $false}

                It 'should call expected mocks' {
                    $Result = Set-TargetResource -Ensure 'Present' @MockParameters
                    Assert-MockCalled -CommandName Get-WebApplication -Exactly 1
                    Assert-MockCalled -CommandName New-WebApplication -Exactly 1
                    Assert-MockCalled -CommandName Set-ItemProperty -Exactly 3
                    Assert-MockCalled -CommandName Add-WebConfiguration -Exactly 1
                    Assert-MockCalled -CommandName Confirm-UniqueServiceAutoStartProviders -Exactly 1
                }
            }

            Context 'Web Application exists but has a different WebAppPool' {
                Mock -CommandName Get-WebApplication -MockWith {
                    return @{
                        ApplicationPool          = 'MockPoolOther'
                        PhysicalPath             = $MockParameters.PhysicalPath
                        ItemXPath                = ("/system.applicationHost/sites/site[@name='{0}']/application[@path='/{1}']" -f $MockParameters.Website, $MockParameters.Name)
                        PreloadEnabled           = $MockParameters.PreloadEnabled
                        ServiceAutoStartEnabled  = $MockParameters.ServiceAutoStartEnabled
                        ServiceAutoStartProvider = $MockParameters.ServiceAutoStartProvider
                        ApplicationType          = $MockParameters.ApplicationType
                        Count = 1
                    }
                }

                Mock -CommandName Set-WebConfigurationProperty
                Mock -CommandName Set-ItemProperty

                It 'should call expected mocks' {
                    $Result = Set-TargetResource -Ensure 'Present' @MockParameters

                    Assert-MockCalled -CommandName Get-WebApplication -Exactly 1
                    Assert-MockCalled -CommandName Set-WebConfigurationProperty -Exactly 1
                }

            }

            Context 'Web Application exists but has a different PhysicalPath' {

                Mock -CommandName Get-WebApplication -MockWith {
                    return @{
                        ApplicationPool          = $MockParameters.WebAppPool
                        PhysicalPath             = 'C:\MockSite\MockAppOther'
                        ItemXPath                = ("/system.applicationHost/sites/site[@name='{0}']/application[@path='/{1}']" -f $MockParameters.Website, $MockParameters.Name)
                        PreloadEnabled           = $MockParameters.PreloadEnabled
                        ServiceAutoStartEnabled  = $MockParameters.ServiceAutoStartEnabled
                        ServiceAutoStartProvider = $MockParameters.ServiceAutoStartProvider
                        ApplicationType          = $MockParameters.ApplicationType
                        Count = 1
                    }
                }

                Mock -CommandName Set-WebConfigurationProperty
                Mock -CommandName Add-WebConfiguration

                It 'should call expected mocks' {

                    $Result = Set-TargetResource -Ensure 'Present' @MockParameters

                    Assert-MockCalled -CommandName Get-WebApplication -Exactly 1
                    Assert-MockCalled -CommandName Set-WebConfigurationProperty -Exactly 1
                }
            }

            Context 'Web Application exists but has Preload not set' {

                Mock -CommandName Get-WebApplication -MockWith {
                    return @{
                        ApplicationPool          = $MockParameters.WebAppPool
                        PhysicalPath             =  $MockParameters.PhysicalPath
                        ItemXPath                = ("/system.applicationHost/sites/site[@name='{0}']/application[@path='/{1}']" -f $MockParameters.Website, $MockParameters.Name)
                        PreloadEnabled           = 'false'
                        ServiceAutoStartEnabled  = $MockParameters.ServiceAutoStartEnabled
                        ServiceAutoStartProvider = $MockParameters.ServiceAutoStartProvider
                        ApplicationType          = $MockParameters.ApplicationType
                        Count = 1
                    }
                }

                Mock -CommandName Set-WebConfigurationProperty
                Mock -CommandName Set-ItemProperty

                It 'should call expected mocks' {

                    $Result = Set-TargetResource -Ensure 'Present' @MockParameters

                    Assert-MockCalled -CommandName Get-WebApplication -Exactly 1
                    Assert-MockCalled -CommandName Set-ItemProperty -Exactly 1
                }
            }

            Context 'Web Application exists but has ServiceAutoStartEnabled not set' {

                Mock -CommandName Get-WebApplication -MockWith {
                    return @{
                        ApplicationPool          = $MockParameters.WebAppPool
                        PhysicalPath             =  $MockParameters.PhysicalPath
                        ItemXPath                = ("/system.applicationHost/sites/site[@name='{0}']/application[@path='/{1}']" -f $MockParameters.Website, $MockParameters.Name)
                        PreloadEnabled           = $MockParameters.PreloadEnabled
                        ServiceAutoStartEnabled  = 'false'
                        ServiceAutoStartProvider = $MockParameters.ServiceAutoStartProvider    
                        ApplicationType          = $MockParameters.ApplicationType
                        Count = 1
                    }
                }

                Mock -CommandName Set-WebConfigurationProperty
                Mock -CommandName Set-ItemProperty

                It 'should call expected mocks' {

                    $Result = Set-TargetResource -Ensure 'Present' @MockParameters

                    Assert-MockCalled -CommandName Get-WebApplication -Exactly 1
                    Assert-MockCalled -CommandName Set-ItemProperty -Exactly 1
                }
            }

            Context 'Web Application exists but has different ServiceAutoStartProvider' {

                Mock -CommandName Get-WebApplication -MockWith {
                    return @{
                        ApplicationPool          = $MockParameters.WebAppPool
                        PhysicalPath             =  $MockParameters.PhysicalPath
                        ItemXPath                = ("/system.applicationHost/sites/site[@name='{0}']/application[@path='/{1}']" -f $MockParameters.Website, $MockParameters.Name)
                        PreloadEnabled           = $MockParameters.PreloadEnabled
                        ServiceAutoStartEnabled  = $MockParameters.ServiceAutoStartEnabled 
                        ServiceAutoStartProvider = 'OtherServiceAutoStartProvider'
                        ApplicationType          = 'OtherApplicationType'
                        
                        Count = 1
                    }
                }

                Mock -CommandName Set-WebConfigurationProperty
                Mock -CommandName Set-ItemProperty
                Mock -CommandName Add-WebConfiguration
                Mock -CommandName Confirm-UniqueServiceAutoStartProviders {Return $false}

                It 'should call expected mocks' {

                    $Result = Set-TargetResource -Ensure 'Present' @MockParameters

                    Assert-MockCalled -CommandName Get-WebApplication -Exactly 1
                    Assert-MockCalled -CommandName Set-ItemProperty -Exactly 1
                    Assert-MockCalled -CommandName Add-WebConfiguration -Exactly 1
                    Assert-MockCalled -CommandName Confirm-UniqueServiceAutoStartProviders -Exactly 1
                }
            }
        }

        Describe "$Global:DSCResourceName\Confirm-UniqueServiceAutoStartProviders" {
            
            $MockParameters = @{
                Name = 'MockServiceAutoStartProvider'
                Type = 'MockApplicationType'
            }

            Context 'Expected behavior' {

                $GetWebConfigurationOutput = @(
                    @{
                        SectionPath = 'MockSectionPath'
                        PSPath      = 'MockPSPath'
                        Collection  = @(
                                   [PSCustomObject]@{Name = 'MockServiceAutoStartProvider' ;Type = 'MockApplicationType'}   
                        )
                    }
                )

                Mock -CommandName Get-WebConfiguration -MockWith {return $GetWebConfigurationOutput}

                It 'should not throw an error' {
                    {Confirm-UniqueServiceAutoStartProviders -ServiceAutoStartProvider $MockParameters.Name -ApplicationType $MockParameters.Type} |
                    Should Not Throw
                }

                It 'should call Get-WebConfiguration once' {
                    Assert-MockCalled -CommandName Get-WebConfiguration -Exactly 1
                }

            }

            Context 'Conflicting Global Property' {
                                     
                $GetWebConfigurationOutput = @(
                    @{
                        SectionPath = 'MockSectionPath'
                        PSPath      = 'MockPSPath'
                        Collection  = @(
                                   [PSCustomObject]@{Name = 'MockServiceAutoStartProvider' ;Type = 'MockApplicationType'}   
                        )
                    }
                )

                Mock -CommandName Get-WebConfiguration -MockWith {$GetWebConfigurationOutput}

                It 'should return Throw' {

                $ErrorId = 'ServiceAutoStartProviderFailure'
                $ErrorCategory = [System.Management.Automation.ErrorCategory]::InvalidOperation
                $ErrorMessage = $LocalizedData.ErrorWebsiteTestAutoStartProviderFailure, 'ScriptHalted'
                $Exception = New-Object -TypeName System.InvalidOperationException -ArgumentList $ErrorMessage
                $ErrorRecord = New-Object -TypeName System.Management.Automation.ErrorRecord -ArgumentList $Exception, $ErrorId, $ErrorCategory, $null

                {Confirm-UniqueServiceAutoStartProviders -ServiceAutoStartProvider $MockParameters.Name -ApplicationType 'MockApplicationType2'} |
                Should Throw #$ErrorRecord
                }

            }

            Context 'ServiceAutoStartProvider does not exist' {

                $GetWebConfigurationOutput = @(
                    @{
                        Name = ''
                        Type = ''
                        
                    }
                )

                Mock -CommandName Get-WebConfiguration  -MockWith {return $GetWebConfigurationOutput}

                It 'should return False' {
                    Confirm-UniqueServiceAutoStartProviders -ServiceAutoStartProvider $MockParameters.Name -ApplicationType $MockParameters.Type |
                    Should Be $false
                }

            }

            Context 'ServiceAutoStartProvider does exist' {
                
                Mock -CommandName Get-WebConfiguration -MockWith {return $GetWebConfigurationOutput}

                It 'should return True' {
                    Confirm-UniqueServiceAutoStartProviders -ServiceAutoStartProvider $MockParameters.Name -ApplicationType $MockParameters.Type |
                    Should Be $true
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
