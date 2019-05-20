$script:DSCModuleName       = 'xWebAdministration'
$script:DSCResourceName     = 'MSFT_xWebApplication'
$script:DSCHelperModuleName = 'Helper'

#region HEADER
$script:moduleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
if ( (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests'))) -or `
     (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1'))) )
{
    & git @('clone','https://github.com/PowerShell/DscResource.Tests.git',(Join-Path -Path $script:moduleRoot -ChildPath '\DSCResource.Tests\'))
}

Import-Module (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1') -Force
Import-Module (Join-Path -Path $script:moduleRoot -ChildPath 'Tests\MockWebAdministrationWindowsFeature.psm1')
$TestEnvironment = Initialize-TestEnvironment -DSCModuleName $script:DSCModuleName `
                                              -DSCResourceName $script:DSCResourceName `
                                              -TestType Unit
#endregion

try
{
    #region Pester Tests
    InModuleScope -ModuleName $script:DSCResourceName -ScriptBlock {
        $script:DSCResourceName     = 'MSFT_xWebApplication'
        $script:DSCHelperModuleName = 'Helper'

        $MockAuthenticationInfo = New-CimInstance `
                                    -ClassName MSFT_xWebApplicationAuthenticationInformation `
                                    -ClientOnly `
                                    -Property @{Anonymous=$true;Basic=$false;Digest=$false;Windows=$true} `
                                    -Namespace 'root/microsoft/Windows/DesiredStateConfiguration'

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
            ItemXPath                = ("/system.applicationHost/sites/site[@name='{0}']/application[@path='/{1}']" -f $MockParameters.Website, $MockParameters.Name)
            applicationPool          = 'MockPool'
            PhysicalPath             = 'C:\MockSite\MockApp'
            SslFlags                 = 'Ssl'
            PreloadEnabled           = $true
            ServiceAutoStartProvider = 'MockServiceAutoStartProvider'
            ServiceAutoStartEnabled  = $true
            ApplicationType          = 'MockApplicationType'
            AuthenticationInfo       = $MockAuthenticationInfo
            EnabledProtocols         = 'http'
            Count                    = 1
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

        Describe "$DSCResourceName\Get-TargetResource" {

            $MockParameters = @{
                Website      = 'MockSite'
                Name         = 'MockApp'
                WebAppPool   = 'MockPool'
                PhysicalPath = 'C:\MockSite\MockApp'
            }

            Mock -CommandName Get-WebConfiguration -MockWith {
                    return $GetWebConfigurationOutput
            }

            Mock -ModuleName $DSCHelperModuleName `
                 -CommandName Get-WebConfigurationProperty `
                 -MockWith {}

            Mock -CommandName Assert-Module -MockWith {}

            Context 'Absent should return correctly' {

                Mock -CommandName Get-WebApplication -MockWith {
                    return $null
                }

                It 'Should return Absent' {
                    $Result = Get-TargetResource @MockParameters
                    $Result.Ensure | Should Be 'Absent'
                }
            }

            Context 'Present should return correctly' {

                Mock -CommandName Get-WebApplication -MockWith {
                    return $MockWebApplicationOutput
                }

                It 'Should return Present' {
                    $Result = Get-TargetResource @MockParameters
                    $Result.Ensure | Should Be 'Present'
                }
            }
        }

        Describe "how $DSCResourceName\Test-TargetResource responds to Ensure = 'Absent'" {

            Mock -CommandName Assert-Module -MockWith {}

            Context 'Web Application does not exist' {

                Mock -CommandName Get-WebApplication -MockWith {
                    return $null
                }

                It 'Should return True' {
                    $Result = Test-TargetResource -Ensure 'Absent' @MockParameters
                    $Result | Should Be $true
                }
            }

            Context 'Web Application exists' {

                Mock -CommandName Get-WebApplication -MockWith {
                    return @{Count = 1}
                }

                It 'Should return False' {
                    $Result = Test-TargetResource -Ensure 'Absent' @MockParameters
                    $Result | Should Be $false
                }
            }
        }

        Describe "how $DSCResourceName\Test-TargetResource responds to Ensure = 'Present'" {

            Mock -CommandName Assert-Module -MockWith {}

            Context 'Web Application does not exist' {

                Mock -CommandName Get-WebApplication -MockWith {
                    return $null
                }

                It 'Should return False' {
                    $Result = Test-TargetResource -Ensure 'Present' @MockParameters
                    $Result | Should Be $false
                }
            }

            Context 'Web Application exists and is in the desired state' {

                Mock -CommandName Get-WebApplication -MockWith {
                    return $MockWebApplicationOutput
                }

                Mock -CommandName Get-WebConfiguration `
                    -ParameterFilter {$filter -eq 'system.webserver/security/access'} `
                    -MockWith { return $GetWebConfigurationOutput }

                Mock -ModuleName $DSCHelperModuleName `
                    -CommandName Test-AuthenticationEnabled `
                    -MockWith { return $true } `
                    -ParameterFilter { ($Type -in @('Anonymous', 'Windows')) }

                Mock -ModuleName $DSCHelperModuleName `
                    -CommandName Test-AuthenticationEnabled `
                    -MockWith { return $false } `
                    -ParameterFilter { ($Type -in @('Basic', 'Digest')) }

                It 'Should return True' {
                    $Result = Test-TargetResource -Ensure 'Present' @MockParameters
                    $Result | Should Be $true
                }
            }

            Context 'Web Application exists but has a different WebAppPool' {

                $contextMockWebApplicationOutput                 = $MockWebApplicationOutput.Clone()
                $contextMockWebApplicationOutput.applicationPool = 'MockPoolOther'

                Mock -CommandName Get-WebConfiguration `
                    -ParameterFilter {$filter -eq 'system.webserver/security/access'} `
                    -MockWith { return $GetWebConfigurationOutput }

                Mock -ModuleName $DSCHelperModuleName `
                    -CommandName Test-AuthenticationEnabled `
                    -MockWith { return $true } `
                    -ParameterFilter { ($Type -in @('Anonymous', 'Windows')) }

                Mock -ModuleName $DSCHelperModuleName `
                    -CommandName Test-AuthenticationEnabled `
                    -MockWith { return $false } `
                    -ParameterFilter { ($Type -in @('Basic', 'Digest')) }

                Mock -CommandName Get-WebApplication -MockWith {
                    return $contextMockWebApplicationOutput
                }

                It 'Should return False' {
                    $Result = Test-TargetResource -Ensure 'Present' @MockParameters
                    $Result | Should Be $False
                }
            }

            Context 'Web Application exists but has a different PhysicalPath' {

                $contextMockWebApplicationOutput              = $MockWebApplicationOutput.Clone()
                $contextMockWebApplicationOutput.PhysicalPath = 'C:\MockSite\MockAppOther'

                Mock -CommandName Get-WebConfiguration `
                    -ParameterFilter {$filter -eq 'system.webserver/security/access'} `
                    -MockWith { return $GetWebConfigurationOutput }

                Mock -ModuleName $DSCHelperModuleName `
                    -CommandName Test-AuthenticationEnabled `
                    -MockWith { return $true } `
                    -ParameterFilter { ($Type -in @('Anonymous', 'Windows')) }

                Mock -ModuleName $DSCHelperModuleName `
                    -CommandName Test-AuthenticationEnabled `
                    -MockWith { return $false } `
                    -ParameterFilter { ($Type -in @('Basic', 'Digest')) }

                Mock -CommandName Get-WebApplication -MockWith {
                    return $contextMockWebApplicationOutput
                }

                It 'Should return False' {
                    $Result = Test-TargetResource -Ensure 'Present' @MockParameters
                    $Result | Should Be $False
                }
            }

            Context 'Check SslFlags is different' {

                $contextGetWebConfigurationOutput             = @()
                $contextGetWebConfigurationOutput            += $GetWebConfigurationOutput[0].Clone()
                $contextGetWebConfigurationOutput[0].SslFlags = 'MockSsl'

                Mock -CommandName Get-WebConfiguration `
                    -ParameterFilter {$filter -eq 'system.webserver/security/access'} `
                    -MockWith { $contextGetWebConfigurationOutput }

                Mock -ModuleName $DSCHelperModuleName `
                    -CommandName Test-AuthenticationEnabled `
                    -MockWith { return $true } `
                    -ParameterFilter { ($Type -in @('Anonymous', 'Windows')) }

                Mock -ModuleName $DSCHelperModuleName `
                    -CommandName Test-AuthenticationEnabled `
                    -MockWith { return $false } `
                    -ParameterFilter { ($Type -in @('Basic', 'Digest')) }

                Mock -CommandName Get-WebApplication -MockWith {
                    return $MockWebApplicationOutput
                }

                $Result = Test-TargetResource -Ensure 'Present' @MockParameters

                It 'Should return False' {
                    $Result | Should Be $false
                }
            }

            Context 'Check AuthenticationInfo is different' {

                Mock -CommandName Get-WebConfiguration `
                    -ParameterFilter {$filter -eq 'system.webserver/security/access'} `
                    -MockWith { return $GetWebConfigurationOutput }

                Mock -ModuleName $DSCHelperModuleName `
                    -CommandName Test-AuthenticationEnabled `
                    -MockWith { return $true } `
                    -ParameterFilter { ($Type -eq 'Anonymous') }

                Mock -ModuleName $DSCHelperModuleName `
                    -CommandName Test-AuthenticationEnabled `
                    -MockWith { return $false } `
                    -ParameterFilter { ($Type -in @('Basic', 'Digest', 'Windows')) }

                Mock -CommandName Get-WebApplication -MockWith {
                    return $MockWebApplicationOutput
                }

                $Result = Test-TargetResource -Ensure 'Present' @MockParameters

                It 'Should return False' {
                    $Result | Should Be $false
                }

                It 'Should call all the mocks' {
                    Assert-MockCalled `
                        -ModuleName $DSCHelperModuleName `
                        -CommandName Test-AuthenticationEnabled `
                        -Exactly 4
                }
            }

            Context 'Check AuthenticationInfo is different from default' {

                Mock -CommandName Get-WebConfiguration `
                    -ParameterFilter {$filter -eq 'system.webserver/security/access'} `
                    -MockWith { return $GetWebConfigurationOutput }

                Mock -ModuleName $DSCHelperModuleName `
                    -CommandName Test-AuthenticationEnabled `
                    -MockWith { return $true } `
                    -ParameterFilter { ($Type -eq 'Windows') }

                Mock -ModuleName $DSCHelperModuleName `
                    -CommandName Test-AuthenticationEnabled `
                    -MockWith { return $false } `
                    -ParameterFilter { ($Type -in @('Anonymous', 'Basic', 'Digest')) }

                Mock -CommandName Get-WebApplication -MockWith {
                    return $MockWebApplicationOutput
                }

                $contextMockParameters = $MockParameters.Clone()
                $contextMockParameters.Remove('AuthenticationInfo')

                $Result = Test-TargetResource -Ensure 'Present' @contextMockParameters

                It 'Should return False' {
                    $Result | Should Be $false
                }

                It 'Should call all the mocks' {
                    Assert-MockCalled `
                        -ModuleName $DSCHelperModuleName `
                        -CommandName Test-AuthenticationEnabled `
                        -Exactly 4
                }
            }

            Context 'Check Preload is different' {

                $contextMockWebApplicationOutput                = $MockWebApplicationOutput.Clone()
                $contextMockWebApplicationOutput.PreloadEnabled = $false

                Mock -CommandName Get-WebConfiguration `
                    -ParameterFilter {$filter -eq 'system.webserver/security/access'} `
                    -MockWith { return $GetWebConfigurationOutput }

                Mock -ModuleName $DSCHelperModuleName `
                    -CommandName Test-AuthenticationEnabled `
                    -MockWith { return $true } `
                    -ParameterFilter { ($Type -in @('Anonymous', 'Windows')) }

                Mock -ModuleName $DSCHelperModuleName `
                    -CommandName Test-AuthenticationEnabled `
                    -MockWith { return $false } `
                    -ParameterFilter { ($Type -in @('Basic', 'Digest')) }

                Mock -CommandName Get-WebApplication -MockWith {
                    return $contextMockWebApplicationOutput
                }

                $Result = Test-TargetResource -Ensure 'Present' @MockParameters

                It 'Should return False' {
                    $Result | Should Be $false
                }
            }

            Context 'Check ServiceAutoStartEnabled is different' {

                $contextMockWebApplicationOutput                         = $MockWebApplicationOutput.Clone()
                $contextMockWebApplicationOutput.ServiceAutoStartEnabled = $false

                Mock -CommandName Get-WebConfiguration `
                    -ParameterFilter {$filter -eq 'system.webserver/security/access'} `
                    -MockWith { return $GetWebConfigurationOutput }

                Mock -ModuleName $DSCHelperModuleName `
                    -CommandName Test-AuthenticationEnabled `
                    -MockWith { return $true } `
                    -ParameterFilter { ($Type -in @('Anonymous', 'Windows')) }

                Mock -ModuleName $DSCHelperModuleName `
                    -CommandName Test-AuthenticationEnabled `
                    -MockWith { return $false } `
                    -ParameterFilter { ($Type -in @('Basic', 'Digest')) }

                Mock -CommandName Get-WebApplication -MockWith {
                    return $contextMockWebApplicationOutput
                }

                $Result = Test-TargetResource -Ensure 'Present' @MockParameters

                It 'Should return False' {
                    $Result | Should Be $false
                }
            }

            Context 'Check ServiceAutoStartProvider is different' {

                $contextMockWebApplicationOutput                          = $MockWebApplicationOutput.Clone()
                $contextMockWebApplicationOutput.ServiceAutoStartProvider = 'MockOtherServiceAutoStartProvider'
                $contextMockWebApplicationOutput.ApplicationType          = 'MockOtherApplicationType'

                Mock -CommandName Get-WebConfiguration `
                    -ParameterFilter {$filter -eq 'system.webserver/security/access'} `
                    -MockWith { return $GetWebConfigurationOutput }

                Mock -ModuleName $DSCHelperModuleName `
                    -CommandName Get-WebConfiguration `
                    -ParameterFilter { $filter -eq '/system.applicationHost/serviceAutoStartProviders' }`
                    -MockWith { return $null }

                Mock -ModuleName $DSCHelperModuleName `
                    -CommandName Test-AuthenticationEnabled `
                    -MockWith { return $true } `
                    -ParameterFilter { ($Type -in @('Anonymous', 'Windows')) }

                Mock -ModuleName $DSCHelperModuleName `
                    -CommandName Test-AuthenticationEnabled `
                    -MockWith { return $false } `
                    -ParameterFilter { ($Type -in @('Basic', 'Digest')) }

                Mock -CommandName Get-WebApplication -MockWith {
                    return $contextMockWebApplicationOutput
                }

                $Result = Test-TargetResource -Ensure 'Present' @MockParameters

                It 'Should return False' {
                    $Result | Should Be $false
                }
            }

            Context 'Check EnabledProtocols is different' {

                $contextMockWebApplicationOutput                  = $MockWebApplicationOutput.Clone()
                $contextMockWebApplicationOutput.EnabledProtocols = 'https'

                Mock -CommandName Get-WebConfiguration `
                    -ParameterFilter {$filter -eq 'system.webserver/security/access'} `
                    -MockWith { return $GetWebConfigurationOutput }

                Mock -ModuleName $DSCHelperModuleName `
                    -CommandName Test-AuthenticationEnabled `
                    -MockWith { return $true } `
                    -ParameterFilter { ($Type -in @('Anonymous', 'Windows')) }

                Mock -ModuleName $DSCHelperModuleName `
                    -CommandName Test-AuthenticationEnabled `
                    -MockWith { return $false } `
                    -ParameterFilter { ($Type -in @('Basic', 'Digest')) }

                Mock -CommandName Get-WebApplication -MockWith {
                    return $contextMockWebApplicationOutput
                }

                $Result = Test-TargetResource -Ensure 'Present' @MockParameters

                It 'Should return False' {
                    $Result | Should Be $false
                }
            }
        }

        Describe "how $DSCResourceName\Set-TargetResource responds to Ensure = 'Absent'" {

            Mock -CommandName Assert-Module -MockWith {}

            Context 'Web Application exists' {

                Mock -CommandName Remove-WebApplication

                It 'Should call expected mocks' {
                    Set-TargetResource -Ensure 'Absent' @MockParameters
                    Assert-MockCalled -CommandName Remove-WebApplication -Exactly 1
                }
            }
        }

        Describe "how $DSCResourceName\Set-TargetResource responds to Ensure = 'Present'" {

            Mock -CommandName Assert-Module -MockWith {}

            Context 'Web Application does not exist' {

                $script:mockGetWebApplicationCalled = 0
                $mockWebApplication = {
                    $script:mockGetWebApplicationCalled++
                    if($script:mockGetWebApplicationCalled -eq 1)
                    {
                        return $null
                    }
                    else
                    {
                        return @{
                            ApplicationPool = $MockParameters.WebAppPool
                            PhysicalPath    = $MockParameters.PhysicalPath
                            Count           = 1
                        }
                    }
                }

                Mock -CommandName Get-WebApplication -MockWith $mockWebApplication

                Mock -CommandName Get-WebConfiguration `
                    -ParameterFilter {$filter -eq 'system.webserver/security/access'} `
                    -MockWith { return $null }

                Mock -ModuleName $DSCHelperModuleName `
                    -CommandName Get-WebConfiguration `
                    -ParameterFilter { $filter -eq '/system.applicationHost/serviceAutoStartProviders' } `
                    -MockWith { return $null }

                Mock -ModuleName $DSCHelperModuleName `
                    -CommandName Get-WebConfigurationProperty `
                    -MockWith { return @{ Value = $false } }

                Mock -ModuleName $DSCHelperModuleName `
                    -CommandName Get-WebConfigurationProperty `
                    -ParameterFilter { $Filter -match 'Anonymous'} `
                    -MockWith { return @{ Value = $true } }

                Mock -CommandName Add-WebConfiguration
                Mock -CommandName New-WebApplication
                Mock -CommandName Set-WebConfigurationProperty
                Mock -CommandName Set-ItemProperty
                Mock -ModuleName $DSCHelperModuleName -CommandName Set-Authentication

                It 'Should call expected mocks' {
                    Set-TargetResource -Ensure 'Present' @MockParameters

                    Assert-MockCalled -CommandName Get-WebApplication -Exactly 2
                    Assert-MockCalled -CommandName New-WebApplication -Exactly 1
                    Assert-MockCalled -CommandName Get-WebConfiguration -Exactly 1
                    Assert-MockCalled -ModuleName $DSCHelperModuleName -CommandName Get-WebConfiguration -Exactly 1
                    Assert-MockCalled -CommandName Set-ItemProperty -Exactly 4
                    Assert-MockCalled -CommandName Add-WebConfiguration -Exactly 1
                    Assert-MockCalled -CommandName Set-WebConfigurationProperty -Exactly 1
                    Assert-MockCalled -ModuleName $DSCHelperModuleName -CommandName Get-WebConfigurationProperty -Exactly 4
                    Assert-MockCalled -ModuleName $DSCHelperModuleName -CommandName Set-Authentication -Exactly 4
                }
            }

            Context 'Web Application exists but has a different WebAppPool' {

                $contextMockWebApplicationOutput                 = $MockWebApplicationOutput.Clone()
                $contextMockWebApplicationOutput.ApplicationPool = 'MockPoolOther'

                Mock -CommandName Get-WebApplication -MockWith {
                    return $contextMockWebApplicationOutput
                }

                Mock -CommandName Get-WebConfiguration `
                    -ParameterFilter {$filter -eq 'system.webserver/security/access'} `
                    -MockWith { return $GetWebConfigurationOutput }

                Mock -ModuleName $DSCHelperModuleName `
                    -CommandName Test-AuthenticationEnabled `
                    -MockWith { return $true } `
                    -ParameterFilter { ($Type -in @('Anonymous', 'Windows')) }

                Mock -ModuleName $DSCHelperModuleName `
                    -CommandName Test-AuthenticationEnabled `
                    -MockWith { return $false } `
                    -ParameterFilter { ($Type -in @('Basic', 'Digest')) }

                Mock -CommandName Set-WebConfigurationProperty

                It 'Should call expected mocks' {
                    Set-TargetResource -Ensure 'Present' @MockParameters

                    Assert-MockCalled -CommandName Get-WebApplication -Exactly 1
                    Assert-MockCalled -CommandName Get-WebConfiguration -Exactly 1
                    Assert-MockCalled -ModuleName $DSCHelperModuleName -CommandName Test-AuthenticationEnabled -Exactly 4
                    Assert-MockCalled `
                        -CommandName Set-WebConfigurationProperty `
                        -Scope It `
                        -Exactly 1 `
                        -ParameterFilter {
                            ($Filter -eq "/system.applicationHost/sites/site[@name='MockSite']/application[@path='/MockApp']") -And `
                            ($Name   -eq 'applicationPool') -And `
                            ($Value  -eq 'MockPool') `
                        }
                }
            }

            Context 'Web Application exists but has a different PhysicalPath' {

                $contextMockWebApplicationOutput              = $MockWebApplicationOutput.Clone()
                $contextMockWebApplicationOutput.PhysicalPath = 'C:\MockSite\MockAppOther'

                Mock -CommandName Get-WebApplication -MockWith {
                    return $contextMockWebApplicationOutput
                }

                Mock -CommandName Get-WebConfiguration `
                    -ParameterFilter {$filter -eq 'system.webserver/security/access'} `
                    -MockWith { return $GetWebConfigurationOutput }

                Mock -ModuleName $DSCHelperModuleName `
                    -CommandName Test-AuthenticationEnabled `
                    -MockWith { return $true } `
                    -ParameterFilter { ($Type -in @('Anonymous', 'Windows')) }

                Mock -ModuleName $DSCHelperModuleName `
                    -CommandName Test-AuthenticationEnabled `
                    -MockWith { return $false } `
                    -ParameterFilter { ($Type -in @('Basic', 'Digest')) }

                Mock -CommandName Set-WebConfigurationProperty

                It 'Should call expected mocks' {
                    Set-TargetResource -Ensure 'Present' @MockParameters

                    Assert-MockCalled -CommandName Get-WebApplication -Exactly 1
                    Assert-MockCalled -CommandName Get-WebConfiguration -Exactly 1
                    Assert-MockCalled -CommandName Set-WebConfigurationProperty -Exactly 1
                    Assert-MockCalled -ModuleName $DSCHelperModuleName -CommandName Test-AuthenticationEnabled -Exactly 4
                }
            }

            Context 'Web Application exists but has different AuthenticationInfo' {

                Mock -CommandName Get-WebApplication -MockWith {
                    return $MockWebApplicationOutput
                }

                Mock -CommandName Get-WebConfiguration `
                    -ParameterFilter {$filter -eq 'system.webserver/security/access'} `
                    -MockWith { return $GetWebConfigurationOutput }

                Mock -ModuleName $DSCHelperModuleName `
                    -CommandName Test-AuthenticationEnabled `
                    -MockWith { return $true } `
                    -ParameterFilter { ($Type -eq 'Anonymous') }

                Mock -ModuleName $DSCHelperModuleName `
                    -CommandName Test-AuthenticationEnabled `
                    -MockWith { return $false } `
                    -ParameterFilter { ($Type -in @('Basic', 'Digest', 'Windows')) }

                Mock -ModuleName $DSCHelperModuleName -CommandName Set-WebConfigurationProperty

                It 'Should call expected mocks' {
                    Set-TargetResource -Ensure 'Present' @MockParameters

                    Assert-MockCalled -CommandName Get-WebApplication -Exactly 1
                    Assert-MockCalled -CommandName Get-WebConfiguration -Exactly 1
                    Assert-MockCalled -ModuleName $DSCHelperModuleName -CommandName Test-AuthenticationEnabled -Exactly 4
                    Assert-MockCalled -ModuleName $DSCHelperModuleName -CommandName Set-WebConfigurationProperty -Exactly 4
                }
            }

            Context 'Web Application exists but has different AuthenticationInfo from default' {

                Mock -CommandName Get-WebApplication -MockWith {
                    return $MockWebApplicationOutput
                }

                Mock -CommandName Get-WebConfiguration `
                    -ParameterFilter {$filter -eq 'system.webserver/security/access'} `
                    -MockWith { return $GetWebConfigurationOutput }

                Mock -ModuleName $DSCHelperModuleName `
                    -CommandName Test-AuthenticationEnabled `
                    -MockWith { return $true } `
                    -ParameterFilter { ($Type -eq 'Windows') }

                Mock -ModuleName $DSCHelperModuleName `
                    -CommandName Test-AuthenticationEnabled `
                    -MockWith { return $false } `
                    -ParameterFilter { ($Type -in @('Anonymous', 'Basic', 'Digest')) }

                Mock -ModuleName $DSCHelperModuleName -CommandName Set-WebConfigurationProperty

                It 'Should call expected mocks' {
                    $contextMockParameters = $MockParameters.Clone()
                    $contextMockParameters.Remove('AuthenticationInfo')

                    Set-TargetResource -Ensure 'Present' @contextMockParameters

                    Assert-MockCalled -CommandName Get-WebApplication -Exactly 1
                    Assert-MockCalled -CommandName Get-WebConfiguration -Exactly 1
                    Assert-MockCalled -ModuleName $DSCHelperModuleName -CommandName Test-AuthenticationEnabled -Exactly 4
                    Assert-MockCalled -ModuleName $DSCHelperModuleName -CommandName Set-WebConfigurationProperty -Exactly 4
                }
            }

            Context 'Web Application exists but has different SslFlags' {

                $contextGetWebConfigurationOutput             = @()
                $contextGetWebConfigurationOutput            += $GetWebConfigurationOutput[0].Clone()
                $contextGetWebConfigurationOutput[0].SslFlags = 'MockSsl'

                Mock -CommandName Get-WebApplication -MockWith {
                    return $MockWebApplicationOutput
                }

                Mock -CommandName Get-WebConfiguration `
                    -ParameterFilter {$filter -eq 'system.webserver/security/access'} `
                    -MockWith { return $contextGetWebConfigurationOutput }

                Mock -ModuleName $DSCHelperModuleName `
                    -CommandName Test-AuthenticationEnabled `
                    -MockWith { return $true } `
                    -ParameterFilter { ($Type -in @('Anonymous', 'Windows')) }

                Mock -ModuleName $DSCHelperModuleName `
                    -CommandName Test-AuthenticationEnabled `
                    -MockWith { return $false } `
                    -ParameterFilter { ($Type -in @('Basic', 'Digest')) }

                Mock -CommandName Set-WebConfigurationProperty

                It 'Should call expected mocks' {
                    Set-TargetResource -Ensure 'Present' @MockParameters

                    Assert-MockCalled -CommandName Get-WebApplication -Exactly 1
                    Assert-MockCalled -CommandName Get-WebConfiguration -Exactly 1
                    Assert-MockCalled -ModuleName $DSCHelperModuleName -CommandName Test-AuthenticationEnabled -Exactly 4
                    Assert-MockCalled `
                        -CommandName Set-WebConfigurationProperty `
                        -ParameterFilter { $Name -eq 'sslFlags' } `
                        -Exactly 1
                }
            }

            Context 'Web Application exists but has different and multiple SslFlags' {

                Mock -CommandName Get-WebApplication -MockWith {
                    return $MockWebApplicationOutput
                }

                Mock -CommandName Get-WebConfiguration `
                    -ParameterFilter {$filter -eq 'system.webserver/security/access'} `
                    -MockWith { return $GetWebConfigurationOutput }

                Mock -ModuleName $DSCHelperModuleName `
                    -CommandName Test-AuthenticationEnabled `
                    -MockWith { return $true } `
                    -ParameterFilter { ($Type -in @('Anonymous', 'Windows')) }

                Mock -ModuleName $DSCHelperModuleName `
                    -CommandName Test-AuthenticationEnabled `
                    -MockWith { return $false } `
                    -ParameterFilter { ($Type -in @('Basic', 'Digest')) }

                Mock -CommandName Set-WebConfigurationProperty

                It 'Should call expected mocks' {
                    $contextParameters = $MockParameters.Clone()
                    $contextParameters.SslFlags = @('Ssl', 'Ssl128')

                    Set-TargetResource -Ensure 'Present' @contextParameters

                    Assert-MockCalled -CommandName Get-WebApplication -Exactly 1
                    Assert-MockCalled -CommandName Get-WebConfiguration -Exactly 1
                    Assert-MockCalled -ModuleName $DSCHelperModuleName -CommandName Test-AuthenticationEnabled -Exactly 4
                    Assert-MockCalled `
                        -CommandName Set-WebConfigurationProperty `
                        -ParameterFilter { $Value -eq 'Ssl,Ssl128' -and $Name -eq 'sslFlags' } `
                        -Exactly 1
                }
            }

            Context 'Web Application exists but has Preload not set' {

                $contextMockWebApplicationOutput                = $MockWebApplicationOutput.Clone()
                $contextMockWebApplicationOutput.PreloadEnabled = $false

                Mock -CommandName Get-WebApplication -MockWith {
                    return $contextMockWebApplicationOutput
                }

                Mock -CommandName Get-WebConfiguration `
                    -ParameterFilter {$filter -eq 'system.webserver/security/access'} `
                    -MockWith { return $GetWebConfigurationOutput }

                Mock -ModuleName $DSCHelperModuleName `
                    -CommandName Test-AuthenticationEnabled `
                    -MockWith { return $true } `
                    -ParameterFilter { ($Type -in @('Anonymous', 'Windows')) }

                Mock -ModuleName $DSCHelperModuleName `
                    -CommandName Test-AuthenticationEnabled `
                    -MockWith { return $false } `
                    -ParameterFilter { ($Type -in @('Basic', 'Digest')) }

                Mock -CommandName Set-ItemProperty

                It 'Should call expected mocks' {
                    Set-TargetResource -Ensure 'Present' @MockParameters

                    Assert-MockCalled -CommandName Get-WebApplication -Exactly 1
                    Assert-MockCalled -CommandName Get-WebConfiguration -Exactly 1
                    Assert-MockCalled -ModuleName $DSCHelperModuleName -CommandName Test-AuthenticationEnabled -Exactly 4
                    Assert-MockCalled -CommandName Set-ItemProperty -Exactly 1
                }
            }

            Context 'Web Application exists but has ServiceAutoStartEnabled not set' {

                $contextMockWebApplicationOutput                         = $MockWebApplicationOutput.Clone()
                $contextMockWebApplicationOutput.ServiceAutoStartEnabled = $false

                Mock -CommandName Get-WebApplication -MockWith {
                    return $contextMockWebApplicationOutput
                }

                Mock -CommandName Get-WebConfiguration `
                    -ParameterFilter {$filter -eq 'system.webserver/security/access'} `
                    -MockWith { return $GetWebConfigurationOutput }

                Mock -ModuleName $DSCHelperModuleName `
                    -CommandName Test-AuthenticationEnabled `
                    -MockWith { return $true } `
                    -ParameterFilter { ($Type -in @('Anonymous', 'Windows')) }

                Mock -ModuleName $DSCHelperModuleName `
                    -CommandName Test-AuthenticationEnabled `
                    -MockWith { return $false } `
                    -ParameterFilter { ($Type -in @('Basic', 'Digest')) }

                Mock -CommandName Set-ItemProperty

                It 'Should call expected mocks' {
                    Set-TargetResource -Ensure 'Present' @MockParameters

                    Assert-MockCalled -CommandName Get-WebApplication -Exactly 1
                    Assert-MockCalled -CommandName Get-WebConfiguration -Exactly 1
                    Assert-MockCalled -ModuleName $DSCHelperModuleName -CommandName Test-AuthenticationEnabled -Exactly 4
                    Assert-MockCalled -CommandName Set-ItemProperty -Exactly 1
                }
            }

            Context 'Web Application exists but has different ServiceAutoStartProvider' {

                $contextMockWebApplicationOutput                          = $MockWebApplicationOutput.Clone()
                $contextMockWebApplicationOutput.ServiceAutoStartProvider = 'OtherServiceAutoStartProvider'
                $contextMockWebApplicationOutput.ApplicationType          = 'OtherApplicationType'

                Mock -CommandName Get-WebApplication -MockWith {
                    return $contextMockWebApplicationOutput
                }

                Mock -CommandName Get-WebConfiguration `
                    -ParameterFilter {$filter -eq 'system.webserver/security/access'} `
                    -MockWith { return $GetWebConfigurationOutput }

                Mock -ModuleName $DSCHelperModuleName -CommandName Get-WebConfiguration

                Mock -ModuleName $DSCHelperModuleName `
                    -CommandName Test-AuthenticationEnabled `
                    -MockWith { return $true } `
                    -ParameterFilter { ($Type -in @('Anonymous', 'Windows')) }

                Mock -ModuleName $DSCHelperModuleName `
                    -CommandName Test-AuthenticationEnabled `
                    -MockWith { return $false } `
                    -ParameterFilter { ($Type -in @('Basic', 'Digest')) }

                Mock -CommandName Set-ItemProperty
                Mock -CommandName Add-WebConfiguration

                It 'Should call expected mocks' {
                    Set-TargetResource -Ensure 'Present' @MockParameters

                    Assert-MockCalled -CommandName Get-WebApplication -Exactly 1
                    Assert-MockCalled -CommandName Get-WebConfiguration -Exactly 1
                    Assert-MockCalled -ModuleName $DSCHelperModuleName -CommandName Test-AuthenticationEnabled -Exactly 4
                    Assert-MockCalled -ModuleName $DSCHelperModuleName -CommandName Get-WebConfiguration -Exactly 1
                    Assert-MockCalled -CommandName Add-WebConfiguration -Exactly 1
                    Assert-MockCalled -CommandName Set-ItemProperty -Exactly 1
                }
            }

            Context 'Web Application exists but has different EnabledProtocols' {

                $contextMockWebApplicationOutput                  = $MockWebApplicationOutput.Clone()
                $contextMockWebApplicationOutput.EnabledProtocols = 'http,net.tcp'

                Mock -CommandName Get-WebApplication -MockWith {
                    return $contextMockWebApplicationOutput
                }

                Mock -CommandName Get-WebConfiguration `
                    -ParameterFilter {$filter -eq 'system.webserver/security/access'} `
                    -MockWith { return $GetWebConfigurationOutput }

                Mock -ModuleName $DSCHelperModuleName `
                    -CommandName Test-AuthenticationEnabled `
                    -MockWith { return $true } `
                    -ParameterFilter { ($Type -in @('Anonymous', 'Windows')) }

                Mock -ModuleName $DSCHelperModuleName `
                    -CommandName Test-AuthenticationEnabled `
                    -MockWith { return $false } `
                    -ParameterFilter { ($Type -in @('Basic', 'Digest')) }

                Mock -CommandName Set-ItemProperty

                It 'Should call expected mocks' {
                    Set-TargetResource -Ensure 'Present' @MockParameters

                    Assert-MockCalled -CommandName Get-WebApplication -Exactly 1
                    Assert-MockCalled -CommandName Get-WebConfiguration -Exactly 1
                    Assert-MockCalled -ModuleName $DSCHelperModuleName -CommandName Test-AuthenticationEnabled -Exactly 4
                    Assert-MockCalled -CommandName Set-ItemProperty -Exactly 1
                }
            }
        }

        Describe "$DSCResourceName\Confirm-UniqueEnabledProtocols" {

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

        Describe "$DSCResourceName\Get-SslFlags" {

            Context 'Expected behavior' {

                Mock -CommandName Get-WebConfiguration -MockWith { return $GetWebConfigurationOutput }

                It 'Should not throw an error' {
                    { Get-SslFlags -Location (${MockParameters}.Website + '\' + ${MockParameters}.Name) }|
                    Should Not Throw
                }

                It 'Should call Get-WebConfiguration once' {
                    Assert-MockCalled -CommandName Get-WebConfiguration -Exactly 1
                }
            }

            Context 'SslFlags do not exist' {

                Mock -CommandName Get-WebConfiguration -MockWith {return ''}

                It 'Should return nothing' {
                    Get-SslFlags -Location (${MockParameters}.Website + '\' + ${MockParameters}.Name) |
                    Should BeNullOrEmpty
                }
            }

            Context 'SslFlags do exist' {

                Mock -CommandName Get-WebConfiguration -MockWith { return $GetWebConfigurationOutput }

                It 'Should return SslFlags' {
                    Get-SslFlags -Location (${MockParameters}.Website + '\' + ${MockParameters}.Name) |
                    Should Be 'Ssl'
                }
            }
        }

        Describe "$DSCResourceName\Test-SslFlags" {

            Context 'Expected behavior' {

                Mock -CommandName Get-WebConfiguration -MockWith {
                    return $GetWebConfigurationOutput
                }

                It 'Should not throw an error' {
                    { Test-SslFlags -Location ${MockParameters.Website}/${MockParameters.Name} -SslFlags $MockParameters.SslFlags  }|
                    Should Not Throw
                }

                It 'Should call expected mocks' {
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

                It 'Should return false' {
                    Test-SslFlags -Location ${MockParameters.Website}/${MockParameters.Name} -SslFlags $MockParameters.SslFlags | Should be False
                }

                It 'Should call expected mocks' {
                    Assert-MockCalled -CommandName Get-WebConfiguration -Exactly 1
                }
            }

            Context 'Return True when SslFlags are correct' {

                Mock -CommandName Get-WebConfiguration -MockWith {
                    return $GetWebConfigurationOutput
                }

                It 'Should return true' {
                    Test-SslFlags -Location ${MockParameters.Website}/${MockParameters.Name} -SslFlags $MockParameters.SslFlags  | Should be True
                }

                It 'Should call expected mocks' {
                    Assert-MockCalled -CommandName Get-WebConfiguration -Exactly 1
                }
            }
        }
    }
    #endregion
}
finally
{
    #region FOOTER
    Restore-TestEnvironment -TestEnvironment $TestEnvironment
    #endregion
}
