$script:dscModuleName = 'xWebAdministration'
$script:dscResourceName = 'MSFT_xWebApplication'

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
        $script:dscResourceName = 'MSFT_xWebApplication'

        $MockAuthenticationInfo = New-CimInstance -ClassName MSFT_xWebApplicationAuthenticationInformation `
                            -ClientOnly `
                            -Property @{Anonymous=$true;Basic=$false;Digest=$false;Windows=$true}

        $MockParameters = @{
            Website                  = 'MockSite'
            Name                     = 'MockApp'
            WebAppPool               = 'MockPool'
            PhysicalPath             = 'C:\MockSite\MockApp'
            SslFlags                 = 'Ssl'
            PreloadEnabled           = $true
            ServiceAutoStartProvider = 'MockServiceAutoStartProvider'
            ServiceAutoStartEnabled  = $true
            ApplicationType          = 'MockApplicationType'
            AuthenticationInfo       = $MockAuthenticationInfo
            EnabledProtocols         = @('http')
        }

        $MockWebApplicationOutput = @{
            Website                  = 'MockSite'
            Name                     = 'MockApp'
            applicationPool          = 'MockPool'
            PhysicalPath             = 'C:\MockSite\MockApp'
            SslFlags                 = 'Ssl'
            PreloadEnabled           = $true
            ServiceAutoStartProvider = 'MockServiceAutoStartProvider'
            ServiceAutoStartEnabled  = $true
            ApplicationType          = 'MockApplicationType'
            AuthenticationInfo       = $MockAuthenticationInfo
            EnabledProtocols         = 'http'
            Count                    = '1'
        }

        $GetWebConfigurationOutput = @(
                @{
                    SectionPath = 'MockSectionPath'
                    PSPath      = 'MockPSPath'
                    SslFlags    = 'Ssl'
                    Collection  = @(
                                [PSCustomObject]@{Name = 'MockServiceAutoStartProvider' ;Type = 'MockApplicationType'}
                    )
                }
            )


        Describe "$script:dscResourceName\Get-TargetResource" {

            $MockParameters = @{
                Website                  = 'MockSite'
                Name                     = 'MockApp'
                WebAppPool               = 'MockPool'
                PhysicalPath             = 'C:\MockSite\MockApp'
            }

            Mock -CommandName Get-WebConfiguration -MockWith {
                    return $GetWebConfigurationOutput
            }

            Mock Test-AuthenticationEnabled { return $true } `
                    -ParameterFilter { ($Type -eq 'Anonymous') }

            Mock Test-AuthenticationEnabled { return $true } `
                    -ParameterFilter { ($Type -eq 'Windows') }

            Mock -CommandName Assert-Module -MockWith {}

            Context 'Absent should return correctly' {

                Mock -CommandName Get-WebApplication -MockWith {
                    return $null
                }

                Mock -CommandName Get-WebConfigurationProperty  -MockWith {
                    return $MockAuthenticationInfo
                }

                It 'should return Absent' {
                    $Result = Get-TargetResource @MockParameters
                    $Result.Ensure | Should Be 'Absent'
                }

            }

            Context 'Present should return correctly' {

                Mock -CommandName Get-WebApplication -MockWith {
                    return $MockWebApplicationOutput
                }

                Mock -CommandName Get-WebConfiguration -MockWith {
                       return $GetWebConfigurationOutput
                }

                Mock -CommandName Get-WebConfigurationProperty -MockWith {
                    return $GetAuthenticationInfo
                }

                Mock Test-AuthenticationEnabled { return $true } `
                    -ParameterFilter { ($Type -eq 'Anonymous') }

                Mock Test-AuthenticationEnabled { return $true } `
                    -ParameterFilter { ($Type -eq 'Windows') }

                It 'should return Present' {
                    $Result = Get-TargetResource @MockParameters
                    $Result.Ensure | Should Be 'Present'
                }

            }

        }

        Describe "how $script:dscResourceName\Test-TargetResource responds to Ensure = 'Absent'" {

            Mock -CommandName Get-SslFlags -MockWith {
                return $GetSslFlags
            }

            Mock -CommandName Get-WebConfigurationProperty -MockWith {
                return $GetAuthenticationInfo
            }

            Mock -CommandName Assert-Module -MockWith {}

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

        Describe "how $script:dscResourceName\Test-TargetResource responds to Ensure = 'Present'" {

            Mock -CommandName Assert-Module -MockWith {}

            Context 'Web Application does not exist' {

                $MockAuthenticationInfo = New-CimInstance -ClassName MSFT_xWebApplicationAuthenticationInformation `
                    -ClientOnly `
                    -Property @{Anonymous=$true;Basic=$false;Digest=$false;Windows=$false}

                Mock -CommandName Get-WebApplication -MockWith {
                    return $null
                }

                Mock -CommandName Get-WebConfiguration -ParameterFilter {$filter -eq 'system.webserver/security/access'}  -MockWith {
                    return $GetWebConfigurationOutput
                }

                Mock -CommandName Get-WebConfigurationProperty -MockWith {
                    return $MockAuthenticationInfo
                }

                It 'should return False' {
                    $Result = Test-TargetResource -Ensure 'Present' @MockParameters
                    $Result | Should Be $false
                }

            }

            Context 'Web Application exists and is in the desired state' {

                Mock -CommandName Get-WebApplication -MockWith {
                    return $MockWebApplicationOutput
                }

                Mock -CommandName Get-WebConfiguration -ParameterFilter {$filter -eq 'system.webserver/security/access'}  -MockWith {
                    return $GetWebConfigurationOutput
                }

                Mock -CommandName Get-WebConfigurationProperty -MockWith {
                    return $MockAuthenticationInfo
                }

                Mock Test-AuthenticationEnabled { return $true } `
                    -ParameterFilter { ($Type -eq 'Anonymous') }

                Mock Test-AuthenticationEnabled { return $false } `
                    -ParameterFilter { ($Type -eq 'Basic') }

                Mock Test-AuthenticationEnabled { return $false } `
                    -ParameterFilter { ($Type -eq 'Digest') }

                Mock Test-AuthenticationEnabled { return $true } `
                    -ParameterFilter { ($Type -eq 'Windows') }

                It 'should return True' {
                    $Result = Test-TargetResource -Ensure 'Present' @MockParameters
                    $Result | Should Be $true
                }

            }

            Context 'Web Application exists but has a different WebAppPool' {

                Mock -CommandName Get-WebConfiguration -ParameterFilter {$filter -eq 'system.webserver/security/access'}  -MockWith {
                    return $GetWebConfigurationOutput
                }

                Mock -CommandName Get-WebConfigurationProperty -MockWith {
                    return $MockAuthenticationInfo
                }

                Mock -CommandName Get-WebApplication -MockWith {
                    return @{
                        ApplicationPool          = 'MockPoolOther'
                        PhysicalPath             = $MockWebApplicationOutput.PhysicalPath
                        PreloadEnabled           = $MockWebApplicationOutput.PreloadEnabled
                        ServiceAutoStartEnabled  = $MockWebApplicationOutput.ServiceAutoStartEnabled
                        ServiceAutoStartProvider = $MockWebApplicationOutput.ServiceAutoStartProvider
                        ApplicationType          = $MockWebApplicationOutput.ApplicationType
                        EnabledProtocols         = $MockWebApplicationOutput.EnabledProtocols
                        Count                    = 1
                    }

                }

                It 'should return False' {
                    $Result = Test-TargetResource -Ensure 'Present' @MockParameters
                    $Result | Should Be $False
                }

            }

            Context 'Web Application exists but has a different PhysicalPath' {

                Mock -CommandName Get-WebConfiguration -ParameterFilter {$filter -eq 'system.webserver/security/access'}  -MockWith {
                    return $GetWebConfigurationOutput
                }

                Mock -CommandName Get-WebConfigurationProperty -MockWith {
                    return $MockAuthenticationInfo
                }

                Mock -CommandName Get-WebApplication -MockWith {
                    return @{
                        ApplicationPool          = $MockWebApplicationOutput.applicationPool
                        PhysicalPath             = 'C:\MockSite\MockAppOther'
                        PreloadEnabled           = $MockWebApplicationOutput.PreloadEnabled
                        ServiceAutoStartProvider = $MockWebApplicationOutput.ServiceAutoStartProvider
                        ServiceAutoStartEnabled  = $MockWebApplicationOutput.ServiceAutoStartEnabled
                        EnabledProtocols         = $MockWebApplicationOutput.EnabledProtocols
                        Count = 1
                    }

                }

                It 'should return False' {
                    $Result = Test-TargetResource -Ensure 'Present' @MockParameters
                    $Result | Should Be $False
                }

            }

            Context 'Check SslFlags is different' {

                Mock -CommandName Get-WebConfiguration -ParameterFilter {$filter -eq 'system.webserver/security/access'}  -MockWith {
                    return $GetWebConfigurationOutput
                }

                Mock -CommandName Get-WebConfigurationProperty -MockWith {
                    return $MockAuthenticationInfo
                }

                Mock -CommandName Get-WebApplication -MockWith {
                    return @{
                        ApplicationPool          = $MockWebApplicationOutput.applicationPool
                        PhysicalPath             = $MockWebApplicationOutput.PhysicalPath
                        PreloadEnabled           = 'false'
                        ServiceAutoStartProvider = $MockWebApplicationOutput.ServiceAutoStartProvider
                        ServiceAutoStartEnabled  = $MockWebApplicationOutput.ServiceAutoStartEnabled
                        EnabledProtocols         = $MockWebApplicationOutput.EnabledProtocols
                        Count = 1
                        }
                    }

                $Result = Test-TargetResource -Ensure 'Present' @MockParameters

                It 'should return False' {
                    $Result | Should Be $false
                }

            }

            Context 'Check AuthenticationInfo is different' {

                Mock -CommandName Get-WebApplication -MockWith {
                    return $MockWebApplicationOutput
                }

                Mock -CommandName Get-WebConfiguration -ParameterFilter {$filter -eq 'system.webserver/security/access'}  -MockWith {
                        return $GetWebConfigurationOutput
                    }

                Mock -CommandName Get-WebConfigurationProperty -MockWith {
                        return $MockAuthenticationInfo
                    }

                Mock Test-AuthenticationEnabled { return $true } `
                    -ParameterFilter { ($Type -eq 'Anonymous') }

                Mock Test-AuthenticationEnabled { return $false } `
                    -ParameterFilter { ($Type -eq 'Basic') }

                Mock Test-AuthenticationEnabled { return $false } `
                    -ParameterFilter { ($Type -eq 'Digest') }

                Mock Test-AuthenticationEnabled { return $false } `
                    -ParameterFilter { ($Type -eq 'Windows') }

                $MockAuthenticationInfo = New-CimInstance -ClassName MSFT_xWebApplicationAuthenticationInformation `
                                            -ClientOnly `
                                            -Property @{Anonymous=$true;Basic=$false;Digest=$false;Windows=$true}

                $Result = Test-TargetResource -Ensure 'Present' @MockParameters

                It 'should return False' {
                    $Result | Should Be $false
                }

            }

            Context 'Check Preload is different' {

                Mock -CommandName Get-WebConfiguration -ParameterFilter {$filter -eq 'system.webserver/security/access'}  -MockWith {
                    return $GetWebConfigurationOutput
                }

                Mock -CommandName Get-WebConfigurationProperty -MockWith {
                    return $MockAuthenticationInfo
                }

                Mock -CommandName Get-WebApplication -MockWith {
                    return @{
                        ApplicationPool          = $MockWebApplicationOutput.applicationPool
                        PhysicalPath             = $MockWebApplicationOutput.PhysicalPath
                        PreloadEnabled           = 'false'
                        ServiceAutoStartEnabled  = $MockWebApplicationOutput.ServiceAutoStartEnabled
                        ServiceAutoStartProvider = $MockWebApplicationOutput.ServiceAutoStartProvider
                        ApplicationType          = $MockWebApplicationOutput.ApplicationType
                        EnabledProtocols         = $MockWebApplicationOutput.EnabledProtocols
                        Count = 1
                        }
                    }

                $Result = Test-TargetResource -Ensure 'Present' @MockParameters

                It 'should return False' {
                    $Result | Should Be $false
                }

            }

            Context 'Check ServiceAutoStartEnabled is different' {

                Mock -CommandName Get-WebConfiguration -ParameterFilter {$filter -eq 'system.webserver/security/access'}  -MockWith {
                    return $GetWebConfigurationOutput
                }

                Mock -CommandName Get-WebConfigurationProperty -MockWith {
                    return $MockAuthenticationInfo
                }

                Mock -CommandName Get-WebApplication -MockWith {
                    return @{
                        ApplicationPool          = $MockWebApplicationOutput.applicationPool
                        PhysicalPath             = $MockWebApplicationOutput.PhysicalPath
                        PreloadEnabled           = $MockWebApplicationOutput.PreloadEnabled
                        ServiceAutoStartEnabled  = 'false'
                        ServiceAutoStartProvider = $MockWebApplicationOutput.ServiceAutoStartProvider
                        ApplicationType          = $MockWebApplicationOutput.ApplicationType
                        EnabledProtocols         = $MockWebApplicationOutput.EnabledProtocols
                        Count = 1
                        }
                    }

                $Result = Test-TargetResource -Ensure 'Present' @MockParameters

                It 'should return False' {
                    $Result | Should Be $false
                }

            }

            Context 'Check ServiceAutoStartProvider is different' {

                Mock -CommandName Get-WebConfiguration -ParameterFilter {$filter -eq 'system.webserver/security/access'}  -MockWith {
                    return $GetWebConfigurationOutput
                }

                Mock -CommandName Get-WebConfiguration -ParameterFilter {$filter -eq '/system.applicationHost/serviceAutoStartProviders'}  -MockWith {
                    return $null
                }

                Mock -CommandName Get-WebConfigurationProperty -MockWith {
                    return $MockAuthenticationInfo
                }

                Mock -CommandName Get-WebApplication -MockWith {
                    return @{
                        ApplicationPool          = $MockWebApplicationOutput.applicationPool
                        PhysicalPath             = $MockWebApplicationOutput.PhysicalPath
                        PreloadEnabled           = $MockWebApplicationOutput.PreloadEnabled
                        ServiceAutoStartEnabled  = $MockWebApplicationOutput.ServiceAutoStartEnabled
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

            Context 'Check EnabledProtocols is different' {

                Mock -CommandName Get-WebConfiguration -ParameterFilter {$filter -eq 'system.webserver/security/access'}  -MockWith {
                    return $GetWebConfigurationOutput
                }

                Mock -CommandName Get-WebConfiguration -ParameterFilter {$filter -eq '/system.applicationHost/serviceAutoStartProviders'}  -MockWith {
                    return $null
                }

                Mock -CommandName Get-WebConfigurationProperty -MockWith {
                    return $MockAuthenticationInfo
                }

                Mock -CommandName Get-WebApplication -MockWith {
                    return @{
                        ApplicationPool          = $MockWebApplicationOutput.applicationPool
                        PhysicalPath             = $MockWebApplicationOutput.PhysicalPath
                        PreloadEnabled           = $MockWebApplicationOutput.PreloadEnabled
                        ServiceAutoStartEnabled  = $MockWebApplicationOutput.ServiceAutoStartEnabled
                        ServiceAutoStartProvider = $MockWebApplicationOutput.ServiceAutoStartProvider
                        ApplicationType          = $MockWebApplicationOutput.ApplicationType
                        EnabledProtocols         = 'http'
                        Count = 1
                        }
                    }

                $Result = Test-TargetResource -Ensure 'Present' @MockParameters

                It 'should return False' {
                    $Result | Should Be $false
                }

            }

        }

        Describe "how $script:dscResourceName\Set-TargetResource responds to Ensure = 'Absent'" {

            Mock -CommandName Get-WebConfiguration -ParameterFilter {$filter -eq 'system.webserver/security/access'}  -MockWith {
                return $GetWebConfigurationOutput
            }

            Mock -CommandName Get-WebConfigurationProperty -MockWith {
                return $MockAuthenticationInfo
            }

            Mock -CommandName Assert-Module -MockWith {}

            Context 'Web Application exists' {
                Mock -CommandName Remove-WebApplication

                It 'should call expected mocks' {
                    Set-TargetResource -Ensure 'Absent' @MockParameters
                    Assert-MockCalled -CommandName Remove-WebApplication -Exactly 1
                }

            }

        }

        Describe "how $script:dscResourceName\Set-TargetResource responds to Ensure = 'Present'" {

            Mock -CommandName Assert-Module -MockWith {}

            Context 'Web Application does not exist' {

                $script:mockGetWebApplicationCalled = 0
                $mockWebApplication = {
                    $script:mockGetWebApplicationCalled++
                    if ($script:mockGetWebApplicationCalled -eq 1)
                    {
                    return $null
                    }
                    else
                    {
                        return @{
                            ApplicationPool = $MockParameters.WebAppPool
                            PhysicalPath    = $MockParameters.PhysicalPath
                            ItemXPath       = $MockItemXPath
                            Count           = 1
                        }
                    }
                }

                Mock -CommandName Get-WebApplication -MockWith $mockWebApplication

                Mock -CommandName Get-WebConfiguration -ParameterFilter {$filter -eq 'system.webserver/security/access'}  -MockWith {
                    return $GetWebConfigurationOutput
                }

                Mock -CommandName Get-WebConfiguration -ParameterFilter {$filter -eq '/system.applicationHost/serviceAutoStartProviders'}  -MockWith {
                    return $null
                }

                Mock -CommandName Get-WebConfigurationProperty -MockWith {
                    return $MockAuthenticationInfo
                }

                Mock Test-AuthenticationEnabled { return $true } `
                    -ParameterFilter { ($Type -eq 'Anonymous') }

                Mock Test-AuthenticationEnabled { return $false } `
                    -ParameterFilter { ($Type -eq 'Basic') }

                Mock Test-AuthenticationEnabled { return $false } `
                    -ParameterFilter { ($Type -eq 'Digest') }

                Mock Test-AuthenticationEnabled { return $false } `
                    -ParameterFilter { ($Type -eq 'Windows') }

                Mock Test-SslFlags { return $null }

                Mock -CommandName Add-WebConfiguration
                Mock -CommandName New-WebApplication
                Mock -CommandName Set-WebConfigurationProperty
                Mock -CommandName Set-ItemProperty
                Mock -CommandName Set-Authentication

                It 'should call expected mocks' {

                    Set-TargetResource -Ensure 'Present' @MockParameters
                    Assert-MockCalled -CommandName Get-WebApplication -Exactly 2
                    Assert-MockCalled -CommandName New-WebApplication -Exactly 1
                    Assert-MockCalled -CommandName Set-ItemProperty -Exactly 4
                    Assert-MockCalled -CommandName Add-WebConfiguration -Exactly 1
                    Assert-MockCalled -CommandName Set-WebConfigurationProperty -Exactly 1
                    Assert-MockCalled -CommandName Test-AuthenticationEnabled -Exactly 4
                    Assert-MockCalled -CommandName Set-Authentication -Exactly 4

                }

            }

            Context 'Web Application exists but has a different WebAppPool' {

                Mock -CommandName Get-WebConfigurationProperty -MockWith {
                    return $MockAuthenticationInfo
                }

                Mock -CommandName Get-WebApplication -MockWith {
                    return @{
                        ApplicationPool          = 'MockPoolOther'
                        PhysicalPath             = $MockWebApplicationOutput.PhysicalPath
                        ItemXPath                = ("/system.applicationHost/sites/site[@name='{0}']/application[@path='/{1}']" -f $MockWebApplicationOutput.Website, $MockWebApplicationOutput.Name)
                        PreloadEnabled           = $MockWebApplicationOutput.PreloadEnabled
                        ServiceAutoStartEnabled  = $MockWebApplicationOutput.ServiceAutoStartEnabled
                        ServiceAutoStartProvider = $MockWebApplicationOutput.ServiceAutoStartProvider
                        ApplicationType          = $MockWebApplicationOutput.ApplicationType
                        EnabledProtocols         = $MockWebApplicationOutput.EnabledProtocols
                        Count = 1
                    }

                }

                Mock -CommandName Get-WebConfiguration -ParameterFilter {$filter -eq 'system.webserver/security/access'}  -MockWith {
                    return $GetWebConfigurationOutput
                }

                Mock -CommandName Get-WebConfigurationProperty -MockWith {
                    return $MockAuthenticationInfo
                }

                Mock Test-AuthenticationEnabled { return $true } `
                    -ParameterFilter { ($Type -eq 'Anonymous') }

                Mock Test-AuthenticationEnabled { return $false } `
                    -ParameterFilter { ($Type -eq 'Basic') }

                Mock Test-AuthenticationEnabled { return $false } `
                    -ParameterFilter { ($Type -eq 'Digest') }

                Mock Test-AuthenticationEnabled { return $true } `
                    -ParameterFilter { ($Type -eq 'Windows') }

                Mock -CommandName Add-WebConfiguration
                Mock -CommandName New-WebApplication
                Mock -CommandName Set-WebConfigurationProperty
                Mock -CommandName Set-WebConfiguration
                Mock -CommandName Set-ItemProperty

                It 'should call expected mocks' {
                    Set-TargetResource -Ensure 'Present' @MockParameters

                    Assert-MockCalled -CommandName Get-WebApplication -Exactly 1
                    Assert-MockCalled -CommandName Set-WebConfigurationProperty -Scope It -Exactly 1 `
                                      -ParameterFilter { `
                                        ($Filter -eq "/system.applicationHost/sites/site[@name='MockSite']/application[@path='/MockApp']") -And `
                                        ($Name   -eq 'applicationPool') -And `
                                        ($Value  -eq 'MockPool') `
                                      }
                }

            }

            Context 'Web Application exists but has a different PhysicalPath' {

                Mock -CommandName Get-WebApplication -MockWith {
                    return @{
                        ApplicationPool          = $MockWebApplicationOutput.applicationPool
                        PhysicalPath             = 'C:\MockSite\MockAppOther'
                        ItemXPath                = ("/system.applicationHost/sites/site[@name='{0}']/application[@path='/{1}']" -f $MockWebApplicationOutput.Website, $MockWebApplicationOutput.Name)
                        PreloadEnabled           = $MockWebApplicationOutput.PreloadEnabled
                        ServiceAutoStartEnabled  = $MockWebApplicationOutput.ServiceAutoStartEnabled
                        ServiceAutoStartProvider = $MockWebApplicationOutput.ServiceAutoStartProvider
                        ApplicationType          = $MockWebApplicationOutput.ApplicationType
                        EnabledProtocols         = $MockWebApplicationOutput.EnabledProtocols
                        Count = 1
                    }

                }

                Mock -CommandName Get-WebConfiguration -ParameterFilter {$filter -eq 'system.webserver/security/access'}  -MockWith {
                    return $GetWebConfigurationOutput
                }

                Mock -CommandName Get-WebConfigurationProperty -MockWith {
                    return $MockAuthenticationInfo
                }

                Mock Test-AuthenticationEnabled { return $true } `
                    -ParameterFilter { ($Type -eq 'Anonymous') }

                Mock Test-AuthenticationEnabled { return $false } `
                    -ParameterFilter { ($Type -eq 'Basic') }

                Mock Test-AuthenticationEnabled { return $false } `
                    -ParameterFilter { ($Type -eq 'Digest') }

                Mock Test-AuthenticationEnabled { return $true } `
                    -ParameterFilter { ($Type -eq 'Windows') }

                Mock -CommandName Add-WebConfiguration
                Mock -CommandName New-WebApplication
                Mock -CommandName Set-WebConfigurationProperty
                Mock -CommandName Set-WebConfiguration
                Mock -CommandName Set-ItemProperty

                It 'should call expected mocks' {

                    Set-TargetResource -Ensure 'Present' @MockParameters

                    Assert-MockCalled -CommandName Get-WebApplication -Exactly 1
                    Assert-MockCalled -CommandName Set-WebConfigurationProperty -Exactly 1
                }

            }

            Context 'Web Application exists but has different AuthenticationInfo' {

                Mock -CommandName Get-WebApplication -MockWith {
                    return @{
                        ApplicationPool          = $MockWebApplicationOutput.applicationPool
                        PhysicalPath             = $MockWebApplicationOutput.PhysicalPath
                        ItemXPath                = ("/system.applicationHost/sites/site[@name='{0}']/application[@path='/{1}']" -f $MockWebApplicationOutput.Website, $MockWebApplicationOutput.Name)
                        PreloadEnabled           = $MockWebApplicationOutput.PreloadEnabled
                        ServiceAutoStartEnabled  = $MockWebApplicationOutput.ServiceAutoStartEnabled
                        ServiceAutoStartProvider = $MockWebApplicationOutput.ServiceAutoStartProvider
                        ApplicationType          = $MockWebApplicationOutput.ApplicationType
                        EnabledProtocols         = $MockWebApplicationOutput.EnabledProtocols
                        Count = 1
                    }
                }

                Mock -CommandName Get-WebConfiguration -ParameterFilter {$filter -eq 'system.webserver/security/access'}  -MockWith {
                        return $GetWebConfigurationOutput
                    }

                Mock -CommandName Test-AuthenticationEnabled { return $true } `
                    -ParameterFilter { ($Type -eq 'Anonymous') }

                Mock -CommandName Test-AuthenticationEnabled { return $false } `
                    -ParameterFilter { ($Type -eq 'Basic') }

                Mock -CommandName Test-AuthenticationEnabled { return $false } `
                    -ParameterFilter { ($Type -eq 'Digest') }

                Mock -CommandName Test-AuthenticationEnabled { return $false } `
                    -ParameterFilter { ($Type -eq 'Windows') }

                Mock -CommandName Set-WebConfiguration
                Mock -CommandName Set-Authentication

                $MockAuthenticationInfo = New-CimInstance -ClassName MSFT_xWebApplicationAuthenticationInformation `
                                            -ClientOnly `
                                            -Property @{Anonymous=$true;Basic=$false;Digest=$false;Windows=$true}

                It 'should call expected mocks' {

                    Set-TargetResource -Ensure 'Present' @MockParameters

                    Assert-MockCalled -CommandName Get-WebApplication -Exactly 1
                    Assert-MockCalled -CommandName Test-AuthenticationEnabled -Exactly 4
                    Assert-MockCalled -CommandName Set-Authentication -Exactly 4
                }

            }

            Context 'Web Application exists but has different SslFlags' {

                Mock -CommandName Get-WebApplication -MockWith {
                    return @{
                        ApplicationPool          = $MockParameters.WebAppPool
                        PhysicalPath             = $MockParameters.PhysicalPath
                        ItemXPath                = $MockItemXPath
                        PreloadEnabled           = $MockParameters.PreloadEnabled
                        ServiceAutoStartEnabled  = $MockParameters.ServiceAutoStartEnabled
                        ServiceAutoStartProvider = $MockParameters.ServiceAutoStartProvider
                        ApplicationType          = $MockParameters.ApplicationType
                        Count = 1
                    }

                }

                Mock -CommandName Get-WebConfiguration -ParameterFilter {$filter -eq 'system.webserver/security/access'}  -MockWith {
                    return @{
                        SectionPath = 'MockSectionPath'
                        PSPath      = 'MockPSPath'
                        SslFlags    = 'None'
                        Collection  = @(
                                    [PSCustomObject]@{Name = 'MockServiceAutoStartProvider' ;Type = 'MockApplicationType'}
                        )
                    }
                }

                Mock -CommandName Get-WebConfigurationProperty -MockWith {
                    return $MockAuthenticationInfo
                }

                Mock -CommandName Add-WebConfiguration
                Mock -CommandName New-WebApplication
                Mock -CommandName Set-WebConfigurationProperty
                Mock -CommandName Set-WebConfiguration
                Mock -CommandName Set-ItemProperty

                It 'Should call expected mocks' {
                    Set-TargetResource -Ensure 'Present' @MockParameters

                    Assert-MockCalled -CommandName Get-WebApplication -Exactly 1
                    Assert-MockCalled -CommandName Set-WebConfigurationProperty `
                        -ParameterFilter { $Name -eq 'sslFlags' } `
                        -Exactly 1
                }
            }

            Context 'Web Application exists but has different and multiple SslFlags' {
                Mock -CommandName Get-WebApplication -MockWith {
                    return @{
                        ApplicationPool          = $MockParameters.WebAppPool
                        PhysicalPath             = $MockParameters.PhysicalPath
                        ItemXPath                = $MockItemXPath
                        PreloadEnabled           = $MockParameters.PreloadEnabled
                        ServiceAutoStartEnabled  = $MockParameters.ServiceAutoStartEnabled
                        ServiceAutoStartProvider = $MockParameters.ServiceAutoStartProvider
                        ApplicationType          = $MockParameters.ApplicationType
                        Count = 1
                    }
                }

                Mock -CommandName Get-WebConfiguration `
                    -ParameterFilter {$filter -eq 'system.webserver/security/access'} `
                    -MockWith { return $GetWebConfigurationOutput }

                Mock -CommandName Get-WebConfigurationProperty -MockWith {
                    return $MockAuthenticationInfo
                }

                Mock -CommandName Add-WebConfiguration
                Mock -CommandName New-WebApplication
                Mock -CommandName Set-WebConfigurationProperty
                Mock -CommandName Set-WebConfiguration
                Mock -CommandName Set-ItemProperty

                It 'Should call expected mocks' {
                    $contextParameters = $MockParameters.Clone()
                    $contextParameters.SslFlags = @('Ssl', 'Ssl128')

                    Set-TargetResource -Ensure 'Present' @contextParameters

                    Assert-MockCalled -CommandName Get-WebApplication -Exactly 1
                    Assert-MockCalled -CommandName Set-WebConfigurationProperty `
                        -ParameterFilter { $Value -eq 'Ssl,Ssl128' -and $Name -eq 'sslFlags' } `
                        -Exactly 1
                }
            }

            Context 'Web Application exists but has Preload not set' {

                Mock -CommandName Get-WebApplication -MockWith {
                    return @{
                        ApplicationPool          = $MockWebApplicationOutput.applicationPool
                        PhysicalPath             = $MockWebApplicationOutput.PhysicalPath
                        ItemXPath                = ("/system.applicationHost/sites/site[@name='{0}']/application[@path='/{1}']" -f $MockWebApplicationOutput.Website, $MockWebApplicationOutput.Name)
                        PreloadEnabled           = 'false'
                        ServiceAutoStartEnabled  = $MockWebApplicationOutput.ServiceAutoStartEnabled
                        ServiceAutoStartProvider = $MockWebApplicationOutput.ServiceAutoStartProvider
                        ApplicationType          = $MockWebApplicationOutput.ApplicationType
                        EnabledProtocols         = $MockWebApplicationOutput.EnabledProtocols
                        Count = 1
                    }

                }
                Mock -CommandName Get-WebConfiguration -ParameterFilter {$filter -eq 'system.webserver/security/access'}  -MockWith {
                    return $GetWebConfigurationOutput
                }

                Mock -CommandName Get-WebConfigurationProperty -MockWith {
                    return $MockAuthenticationInfo
                }

                Mock -CommandName Add-WebConfiguration
                Mock -CommandName New-WebApplication
                Mock -CommandName Set-WebConfigurationProperty
                Mock -CommandName Set-WebConfiguration
                Mock -CommandName Set-ItemProperty

                It 'should call expected mocks' {

                    Set-TargetResource -Ensure 'Present' @MockParameters

                    Assert-MockCalled -CommandName Get-WebApplication -Exactly 1
                    Assert-MockCalled -CommandName Set-ItemProperty -Exactly 1
                }

            }

            Context 'Web Application exists but has ServiceAutoStartEnabled not set' {

                Mock -CommandName Get-WebApplication -MockWith {
                    return @{
                        ApplicationPool          = $MockWebApplicationOutput.applicationPool
                        PhysicalPath             = $MockWebApplicationOutput.PhysicalPath
                        ItemXPath                = ("/system.applicationHost/sites/site[@name='{0}']/application[@path='/{1}']" -f $MockWebApplicationOutput.Website, $MockWebApplicationOutput.Name)
                        PreloadEnabled           = $MockWebApplicationOutput.PreloadEnabled
                        ServiceAutoStartEnabled  = 'false'
                        ServiceAutoStartProvider = $MockWebApplicationOutput.ServiceAutoStartProvider
                        ApplicationType          = $MockWebApplicationOutput.ApplicationType
                        EnabledProtocols         = $MockWebApplicationOutput.EnabledProtocols
                        Count = 1
                    }

                }

                Mock -CommandName Get-WebConfiguration -ParameterFilter {$filter -eq 'system.webserver/security/access'}  -MockWith {
                    return $GetWebConfigurationOutput
                }

                Mock -CommandName Get-WebConfigurationProperty -MockWith {
                    return $MockAuthenticationInfo
                }

                Mock -CommandName Add-WebConfiguration
                Mock -CommandName New-WebApplication
                Mock -CommandName Set-WebConfigurationProperty
                Mock -CommandName Set-WebConfiguration
                Mock -CommandName Set-ItemProperty

                It 'should call expected mocks' {

                    Set-TargetResource -Ensure 'Present' @MockParameters

                    Assert-MockCalled -CommandName Get-WebApplication -Exactly 1
                    Assert-MockCalled -CommandName Set-ItemProperty -Exactly 1
                }

            }

            Context 'Web Application exists but has different ServiceAutoStartProvider' {

                $GetWebConfigurationOutput = @(
                    @{
                        SectionPath = 'MockSectionPath'
                        PSPath      = 'MockPSPath'
                        SslFlags    = 'Ssl'
                        Collection  = @(
                                    [PSCustomObject]@{Name = 'OtherMockServiceAutoStartProvider' ;Type = 'OtherMockApplicationType'}
                        )
                    }
                )

                Mock -CommandName Get-WebApplication -MockWith {
                    return @{
                        ApplicationPool          = $MockWebApplicationOutput.applicationPool
                        PhysicalPath             = $MockWebApplicationOutput.PhysicalPath
                        ItemXPath                = ("/system.applicationHost/sites/site[@name='{0}']/application[@path='/{1}']" -f $MockWebApplicationOutput.Website, $MockWebApplicationOutput.Name)
                        PreloadEnabled           = $MockWebApplicationOutput.PreloadEnabled
                        ServiceAutoStartEnabled  = $MockWebApplicationOutput.ServiceAutoStartEnabled
                        ServiceAutoStartProvider = 'OtherServiceAutoStartProvider'
                        ApplicationType          = 'OtherApplicationType'
                        EnabledProtocols         = $MockWebApplicationOutput.EnabledProtocols
                        Count = 1
                    }

                }

                Mock -CommandName Get-WebConfiguration -MockWith {
                    return $GetWebConfigurationOutput
                }

                Mock -CommandName Get-WebConfigurationProperty -MockWith {
                    return $MockAuthenticationInfo
                }

                Mock -CommandName Add-WebConfiguration
                Mock -CommandName New-WebApplication
                Mock -CommandName Set-WebConfigurationProperty
                Mock -CommandName Set-WebConfiguration
                Mock -CommandName Set-ItemProperty

                It 'should call expected mocks' {

                    Set-TargetResource -Ensure 'Present' @MockParameters

                    Assert-MockCalled -CommandName Get-WebApplication -Exactly 1
                    Assert-MockCalled -CommandName Set-ItemProperty -Exactly 1
                    Assert-MockCalled -CommandName Add-WebConfiguration -Exactly 1
                }

            }

            Context 'Web Application exists but has different EnabledProtocols' {

                $GetWebConfigurationOutput = @(
                    @{
                        SectionPath = 'MockSectionPath'
                        PSPath      = 'MockPSPath'
                        SslFlags    = 'Ssl'
                        Collection  = @(
                                    [PSCustomObject]@{Name = 'OtherMockServiceAutoStartProvider' ;Type = 'OtherMockApplicationType'}
                        )
                    }
                )

                Mock -CommandName Get-WebApplication -MockWith {
                    return @{
                        ApplicationPool          = $MockWebApplicationOutput.applicationPool
                        PhysicalPath             = $MockWebApplicationOutput.PhysicalPath
                        ItemXPath                = ("/system.applicationHost/sites/site[@name='{0}']/application[@path='/{1}']" -f $MockWebApplicationOutput.Website, $MockWebApplicationOutput.Name)
                        PreloadEnabled           = $MockWebApplicationOutput.PreloadEnabled
                        ServiceAutoStartEnabled  = $MockWebApplicationOutput.ServiceAutoStartEnabled
                        ServiceAutoStartProvider = $MockWebApplicationOutput.ServiceAutoStartProvider
                        ApplicationType          = $MockWebApplicationOutput.ApplicationType
                        EnabledProtocols         = 'http,net.tcp'
                        Count = 1
                    }

                }

                Mock -CommandName Get-WebConfiguration -MockWith {
                    return $GetWebConfigurationOutput
                }

                Mock -CommandName Get-WebConfigurationProperty -MockWith {
                    return $MockAuthenticationInfo
                }

                Mock -CommandName Add-WebConfiguration
                Mock -CommandName New-WebApplication
                Mock -CommandName Set-WebConfigurationProperty
                Mock -CommandName Set-WebConfiguration
                Mock -CommandName Set-ItemProperty

                It 'should call expected mocks' {

                    Set-TargetResource -Ensure 'Present' @MockParameters

                    Assert-MockCalled -CommandName Get-WebApplication -Exactly 1
                    Assert-MockCalled -CommandName Set-ItemProperty -Exactly 1
                }

            }

        }

        Describe "$script:dscResourceName\Confirm-UniqueEnabledProtocols" {

            Context 'Tests Confirm-UniqueEnabledProtocols' {

                It 'Should return true when settings match' {

                    Confirm-UniqueEnabledProtocols -ExistingProtocols 'http,net.tcp' `
                                                   -ProposedProtocols @('http','net.tcp') `
                                                   | Should be $true
                }

                It 'Should return false when settings do not match' {

                    Confirm-UniqueEnabledProtocols -ExistingProtocols 'http' `
                                                   -ProposedProtocols @('http','net.tcp') `
                                                   | Should be $false
                }
            }
        }

        Describe "$script:dscResourceName\Confirm-UniqueServiceAutoStartProviders" {

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
                    {Confirm-UniqueServiceAutoStartProviders -ServiceAutoStartProvider $MockParameters.Name -ApplicationType 'MockApplicationType'} |
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

                Mock -CommandName Get-WebConfiguration -MockWith {return $GetWebConfigurationOutput}

                It 'should return Throw' {

                    $ErrorId = 'ServiceAutoStartProviderFailure'
                    $ErrorCategory = [System.Management.Automation.ErrorCategory]::InvalidOperation
                    $ErrorMessage = $script:localizedData.ErrorWebApplicationTestAutoStartProviderFailure, 'ScriptHalted'
                    $Exception = New-Object -TypeName System.InvalidOperationException -ArgumentList $ErrorMessage
                    $ErrorRecord = New-Object -TypeName System.Management.Automation.ErrorRecord -ArgumentList $Exception, $ErrorId, $ErrorCategory, $null

                    {Confirm-UniqueServiceAutoStartProviders -ServiceAutoStartProvider $MockParameters.Name -ApplicationType 'MockApplicationType2'} |
                    Should Throw $ErrorRecord
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
                    Confirm-UniqueServiceAutoStartProviders -ServiceAutoStartProvider $MockParameters.Name -ApplicationType  'MockApplicationType' |
                    Should Be $false
                }

            }

            Context 'ServiceAutoStartProvider does exist' {

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

                It 'should return True' {
                    Confirm-UniqueServiceAutoStartProviders -ServiceAutoStartProvider $MockParameters.Name -ApplicationType  'MockApplicationType' |
                    Should Be $true
                }

            }

        }

        Describe "$script:dscResourceName\Get-AuthenticationInfo" {

            Context 'Expected behavior' {

                Mock -CommandName Get-WebConfigurationProperty -MockWith { return 'False'}

                It 'should not throw an error' {
                    { Get-AuthenticationInfo -site $MockParameters.Website -name $MockParameters.Name } |
                    Should Not Throw
                }

                It 'should call Get-WebConfigurationProperty four times' {
                    Assert-MockCalled -CommandName Get-WebConfigurationProperty -Exactly 4
                }

            }

            Context 'AuthenticationInfo is false' {

                $GetWebConfigurationOutput = @(
                    @{
                        Value = $false
                    }
                )

                Mock -CommandName Get-WebConfigurationProperty -MockWith { $GetWebConfigurationOutput}


                It 'should all be false' {
                    $result = Get-AuthenticationInfo -site $MockParameters.Website -name $MockParameters.Name
                    $result.Anonymous | Should be $false
                    $result.Digest | Should be $false
                    $result.Basic | Should be $false
                    $result.Windows | Should be $false
                }

                It 'should call Get-WebConfigurationProperty four times' {
                    Assert-MockCalled -CommandName Get-WebConfigurationProperty -Exactly 4
                }

            }

            Context 'AuthenticationInfo is true' {

                $GetWebConfigurationOutput = @(
                    @{
                        Value = 'True'
                    }
                )

                Mock -CommandName Get-WebConfigurationProperty -MockWith { $GetWebConfigurationOutput}

                It 'should all be true' {
                    $result = Get-AuthenticationInfo -site $MockParameters.Website -name $MockParameters.Name
                    $result.Anonymous | Should be True
                    $result.Digest | Should be True
                    $result.Basic | Should be True
                    $result.Windows | Should be True
                }

                It 'should call Get-WebConfigurationProperty four times' {
                    Assert-MockCalled -CommandName Get-WebConfigurationProperty -Exactly 4
                }

            }

        }

        Describe "$script:dscResourceName\Get-DefaultAuthenticationInfo" {

            Context 'Expected behavior' {

                It 'should not throw an error' {
                    { Get-DefaultAuthenticationInfo }|
                    Should Not Throw
                }

            }

            Context 'Get-DefaultAuthenticationInfo should produce a false CimInstance' {

                It 'should all be false' {
                    $result = Get-DefaultAuthenticationInfo
                    $result.Anonymous | Should be False
                    $result.Digest | Should be False
                    $result.Basic | Should be False
                    $result.Windows | Should be False
                }

            }

        }

        Describe "$script:dscResourceName\Get-SslFlags" {

            Context 'Expected behavior' {

                Mock -CommandName Get-WebConfiguration -MockWith {$GetWebConfigurationOutput}

                It 'should not throw an error' {
                    { Get-SslFlags -Location (${MockParameters}.Website + '\' + ${MockParameters}.Name) }|
                    Should Not Throw
                }

                It 'should call Get-WebConfiguration once' {
                    Assert-MockCalled -CommandName Get-WebConfiguration -Exactly 1
                }

            }

            Context 'SslFlags do not exist' {

                Mock -CommandName Get-WebConfiguration -MockWith {return ''}

                It 'should return nothing' {
                    Get-SslFlags -Location (${MockParameters}.Website + '\' + ${MockParameters}.Name) |
                    Should BeNullOrEmpty
                }

            }

            Context 'SslFlags do exist' {

                Mock -CommandName Get-WebConfiguration -MockWith {$GetWebConfigurationOutput}

                It 'should return SslFlags' {
                    Get-SslFlags -Location (${MockParameters}.Website + '\' + ${MockParameters}.Name) |
                    Should Be 'Ssl'
                }

            }

        }

        Describe "$script:dscResourceName\Set-Authentication" {

            Context 'Expected behavior' {

                Mock -CommandName Set-WebConfigurationProperty

                It 'should not throw an error' {
                    { Set-Authentication -Site $MockParameters.Website -Name $MockParameters.Name -Type Basic -Enabled $true }|
                    Should Not Throw
                }

                It 'should call Set-WebConfigurationProperty once' {
                    Assert-MockCalled -CommandName Set-WebConfigurationProperty -Exactly 1
                }

            }

        }

        Describe "$script:dscResourceName\Set-AuthenticationInfo" {

            Context 'Expected behavior' {

                Mock -CommandName Set-WebConfigurationProperty

                $AuthenticationInfo = New-CimInstance -ClassName MSFT_xWebApplicationAuthenticationInformation `
                                                  -ClientOnly `
                                                  -Property @{Anonymous='true';Basic='false';Digest='false';Windows='false'}

                It 'should not throw an error' {
                    { Set-AuthenticationInfo  -Site $MockParameters.Website -Name $MockParameters.Name -AuthenticationInfo $AuthenticationInfo }|
                    Should Not Throw
                }

                It 'should call should call expected mocks' {
                    Assert-MockCalled -CommandName Set-WebConfigurationProperty -Exactly 4
                }

            }

        }

        Describe "$script:dscResourceName\Test-AuthenticationEnabled" {

            Context 'Expected behavior' {

                $GetWebConfigurationOutput = @(
                    @{
                        Value = 'False'
                    }
                )

                Mock -CommandName Get-WebConfigurationProperty -MockWith {$GetWebConfigurationOutput}

                It 'should not throw an error' {
                    { Test-AuthenticationEnabled  -Site $MockParameters.Website -Name $MockParameters.Name -Type 'Basic'}|
                    Should Not Throw
                }

                It 'should call expected mocks' {
                    Assert-MockCalled -CommandName Get-WebConfigurationProperty -Exactly 1
                }

            }

            Context 'AuthenticationInfo is false' {

                $GetWebConfigurationOutput = @(
                    @{
                        Value = 'False'
                    }
                )

                Mock -CommandName Get-WebConfigurationProperty -MockWith { $GetWebConfigurationOutput}


                It 'should return false' {
                    Test-AuthenticationEnabled -site $MockParameters.Website -name $MockParameters.Name -Type 'Basic' | Should be False
                }

                It 'should call expected mocks' {
                    Assert-MockCalled -CommandName Get-WebConfigurationProperty -Exactly 1
                }

            }

            Context 'AuthenticationInfo is true' {

                $GetWebConfigurationOutput = @(
                    @{
                        Value = 'True'
                    }
                )

                Mock -CommandName Get-WebConfigurationProperty -MockWith { $GetWebConfigurationOutput}

                It 'should all be true' {
                    Test-AuthenticationEnabled -site $MockParameters.Website -name $MockParameters.Name -Type 'Basic' | Should be True
                }

                It 'should call expected mocks' {
                    Assert-MockCalled -CommandName Get-WebConfigurationProperty -Exactly 1
                }

            }

        }

        Describe "$script:dscResourceName\Test-AuthenticationInfo" {

            Mock -CommandName Get-WebConfigurationProperty -MockWith {$GetWebConfigurationOutput}

            $GetWebConfigurationOutput = @(
                    @{
                        Value = 'False'
                    }
                )

            $AuthenticationInfo = New-CimInstance -ClassName MSFT_xWebApplicationAuthenticationInformation `
                                    -ClientOnly `
                                    -Property @{Anonymous='false';Basic='true';Digest='false';Windows='false'}

            Context 'Expected behavior' {


                It 'should not throw an error' {
                    { Test-AuthenticationInfo  -Site $MockParameters.Website -Name $MockParameters.Name -AuthenticationInfo $AuthenticationInfo }|
                    Should Not Throw
                }

                It 'should call expected mocks' {
                    Assert-MockCalled -CommandName Get-WebConfigurationProperty -Exactly 2
                }

            }

            Context 'Return False when AuthenticationInfo is not correct' {

                Mock -CommandName Get-WebConfigurationProperty -MockWith { $GetWebConfigurationOutput}


                It 'should return false' {
                    Test-AuthenticationInfo -site $MockParameters.Website -name $MockParameters.Name -AuthenticationInfo $AuthenticationInfo | Should be False
                }

                It 'should call expected mocks' {
                    Assert-MockCalled -CommandName Get-WebConfigurationProperty -Exactly 2
                }

            }

            Context 'Return True when AuthenticationInfo is correct' {

                $GetWebConfigurationOutput = @(
                    @{
                        Value = 'True'
                    }
                )

                $AuthenticationInfo = New-CimInstance -ClassName MSFT_xWebApplicationAuthenticationInformation `
                                    -ClientOnly `
                                    -Property @{Anonymous='true';Basic='true';Digest='true';Windows='true'}

                Mock -CommandName Get-WebConfigurationProperty -MockWith { $GetWebConfigurationOutput}

                It 'should return true' {
                    Test-AuthenticationInfo -site $MockParameters.Website -name $MockParameters.Name -AuthenticationInfo $AuthenticationInfo | Should be True
                }

                It 'should call expected mocks' {
                    Assert-MockCalled -CommandName Get-WebConfigurationProperty -Exactly 4
                }

            }

        }

        Describe "$script:dscResourceName\Test-SslFlags" {

            Context 'Expected behavior' {

                Mock -CommandName Get-WebConfiguration -MockWith {
                    return $GetWebConfigurationOutput
                }

                It 'should not throw an error' {
                    { Test-SslFlags -Location ${MockParameters.Website}/${MockParameters.Name} -SslFlags $MockParameters.SslFlags  }|
                    Should Not Throw
                }

                It 'should call expected mocks' {
                    Assert-MockCalled -CommandName Get-WebConfiguration -Exactly 1
                }

            }

            Context 'Return False when SslFlags are not correct' {

                $GetWebConfigurationOutput = @(
                    @{
                        SslFlags    = ''
                    }
                )

                Mock -CommandName Get-WebConfiguration -MockWith {
                    return $GetWebConfigurationOutput
                }


                It 'should return false' {
                    Test-SslFlags -Location ${MockParameters.Website}/${MockParameters.Name} -SslFlags $MockParameters.SslFlags | Should be False
                }

                It 'should call expected mocks' {
                    Assert-MockCalled -CommandName Get-WebConfiguration -Exactly 1
                }

            }

            Context 'Return True when SslFlags are correct' {

                Mock -CommandName Get-WebConfiguration -MockWith {
                    return $GetWebConfigurationOutput
                }

                It 'should return true' {
                    Test-SslFlags -Location ${MockParameters.Website}/${MockParameters.Name} -SslFlags $MockParameters.SslFlags  | Should be True
                }

                It 'should call expected mocks' {
                    Assert-MockCalled -CommandName Get-WebConfiguration -Exactly 1
                }

            }

        }

    }

}
finally
{
    Invoke-TestCleanup
}
