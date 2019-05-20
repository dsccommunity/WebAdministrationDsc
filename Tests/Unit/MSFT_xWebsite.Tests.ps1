$script:DSCModuleName       = 'xWebAdministration'
$script:DSCResourceName     = 'MSFT_xWebsite'
$script:DSCHelperModuleName = 'Helper'

#region HEADER
$script:moduleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
if ( (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests'))) -or `
     (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1'))) )
{
    & git @('clone','https://github.com/PowerShell/DscResource.Tests.git',(Join-Path -Path $script:moduleRoot -ChildPath '\DSCResource.Tests\'))
}

Import-Module (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1') -Force

$TestEnvironment = Initialize-TestEnvironment -DSCModuleName $script:DSCModuleName `
                                              -DSCResourceName $script:DSCResourceName `
                                              -TestType Unit
#endregion

# Begin Testing
try
{
    #region Pester Tests
    InModuleScope -ModuleName $script:DSCResourceName -ScriptBlock {
        $script:DSCResourceName     = 'MSFT_xWebsite'
        $script:DSCHelperModuleName = 'Helper'

        # Make sure we don't have the original module in memory.
        Remove-Module -Name 'WebAdministration' -ErrorAction SilentlyContinue

        # Load the stubs
        $script:moduleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
        Import-Module (Join-Path -Path $script:moduleRoot -ChildPath 'Tests\MockWebAdministrationWindowsFeature.psm1') -Force

        $MockAuthenticationInfo = New-CimInstance `
                                    -ClassName MSFT_xWebApplicationAuthenticationInformation `
                                    -ClientOnly `
                                    -Property @{Anonymous=$true;Basic=$false;Digest=$false;Windows=$false} `
                                    -Namespace 'root/microsoft/Windows/DesiredStateConfiguration'

        $MockWebBinding = @(
            @{
                bindingInformation   = '*:443:web01.contoso.com'
                protocol             = 'https'
                certificateHash      = '1D3324C6E2F7ABC794C9CB6CA426B8D0F81045CD'
                certificateStoreName = 'WebHosting'
                sslFlags             = '1'
            }
        )

        $MockPreloadAndAutostartProviders = @(
            @{
                preloadEnabled           = 'True'
                ServiceAutoStartProvider = 'MockServiceAutoStartProvider'
                ServiceAutoStartEnabled  = 'True'
            }
        )

        $mockLogCustomFields = @(
            @{
                LogFieldName = 'LogField1'
                SourceName   = 'Accept-Encoding'
                SourceType   = 'RequestHeader'
            }
            @{
                LogFieldName = 'LogField2'
                SourceName   = 'Warning'
                SourceType   = 'ResponseHeader'
            }
        )

        $MockLogOutput = @{
            directory         = '%SystemDrive%\inetpub\logs\LogFiles'
            logExtFileFlags   = 'Date','Time','ClientIP','UserName','ServerIP','Method','UriStem','UriQuery','HttpStatus','Win32Status','TimeTaken','ServerPort','UserAgent','Referer','HttpSubStatus'
            logFormat         = $MockParameters.LogFormat
            period            = 'Daily'
            logTargetW3C      = 'File,ETW'
            truncateSize      = '1048576'
            localTimeRollover = 'False'
            customFields      = @{Collection = $mockLogCustomFields}
        }

        $MockWebsite = @{
            Name                = 'MockName'
            Id                  = 1234
            PhysicalPath        = 'C:\NonExistent'
            State               = 'Started'
            ApplicationPool     = 'MockPool'
            AuthenticationInfo  = $MockAuthenticationInfo
            Bindings            = @{Collection = @($MockWebBinding)}
            EnabledProtocols    = 'http'
            ApplicationDefaults = $MockPreloadAndAutostartProviders
            LogFile             = $MockLogOutput
            Count               = 1
        }

        $MockWebConfiguration = @(
            @{
                SectionPath = 'MockSectionPath'
                PSPath      = 'MockPSPath'
                Collection  = @(
                    [PSCustomObject] @{
                        Name = 'MockServiceAutoStartProvider';
                        Type = 'MockApplicationType'
                    }
                )
            }
        )

        Describe "how $DSCResourceName\Get-TargetResource responds" {

            Mock -CommandName Assert-Module -MockWith {}

            Context 'Website does not exist' {

                Mock -CommandName Get-Website

                $Result = Get-TargetResource -Name $MockWebsite.Name

                It 'Should return Absent' {
                    $Result.Ensure | Should Be 'Absent'
                }
            }

            Context 'There are multiple websites with the same name' {

                Mock -CommandName Get-Website -MockWith {
                    return @(
                        @{Name = 'MockName'}
                        @{Name = 'MockName'}
                    )
                }

                It 'Should throw the correct error' {
                    $ErrorId       = 'WebsiteDiscoveryFailure'
                    $ErrorCategory = [System.Management.Automation.ErrorCategory]::InvalidResult
                    $ErrorMessage  = $LocalizedData.ErrorWebsiteDiscoveryFailure -f 'MockName'
                    $Exception     = New-Object -TypeName System.InvalidOperationException `
                                                -ArgumentList $ErrorMessage
                    $ErrorRecord   = New-Object -TypeName System.Management.Automation.ErrorRecord `
                                                -ArgumentList $Exception, $ErrorId, $ErrorCategory, $null

                    {Get-TargetResource -Name 'MockName'} | Should Throw $ErrorRecord
                }
            }

            Context 'Single website exists' {

                Mock -CommandName Get-Website -MockWith {return $MockWebsite}

                Mock -CommandName Get-WebConfiguration  `
                        -ParameterFilter {$filter -eq '/system.webServer/defaultDocument/files/*'} `
                        -MockWith { return @{value = 'index.html'} }

                Mock -CommandName Get-WebConfiguration `
                        -ParameterFilter {$filter -eq '/system.applicationHost/serviceAutoStartProviders'} `
                        -MockWith { return $MockWebConfiguration}

                Mock -ModuleName $DSCHelperModuleName `
                    -CommandName Test-AuthenticationEnabled `
                    -MockWith { return $true } `
                    -ParameterFilter { ($Type -in ('Anonymous', 'Windows')) }

                Mock -ModuleName $DSCHelperModuleName `
                    -CommandName Test-AuthenticationEnabled `
                    -MockWith { return $false } `
                    -ParameterFilter { ($Type -in @('Basic', 'Digest')) }

                $Result = Get-TargetResource -Name $MockWebsite.Name

                It 'Should call Get-Website once' {
                    Assert-MockCalled -CommandName Get-Website -Exactly 1
                }

                It 'Should call Get-WebConfiguration twice' {
                    Assert-MockCalled -CommandName Get-WebConfiguration -Exactly 2
                }

                It 'Should call Test-AuthenticationEnabled four times' {
                    Assert-MockCalled `
                        -ModuleName $DSCHelperModuleName `
                        -CommandName Test-AuthenticationEnabled `
                        -Exactly 4
                }

                It 'Should return Ensure' {
                    $Result.Ensure | Should Be 'Present'
                }

                It 'Should return Name' {
                    $Result.Name | Should Be $MockWebsite.Name
                }

                It 'Should return SiteId' {
                    $Result.SiteId | Should Be $MockWebsite.Id
                }

                It 'Should return PhysicalPath' {
                    $Result.PhysicalPath | Should Be $MockWebsite.PhysicalPath
                }

                It 'Should return State' {
                    $Result.State | Should Be $MockWebsite.State
                }

                It 'Should return ApplicationPool' {
                    $Result.ApplicationPool | Should Be $MockWebsite.ApplicationPool
                }

                It 'Should return BindingInfo' {
                    $Result.BindingInfo.Protocol              | Should Be $MockWebBinding.protocol
                    $Result.BindingInfo.BindingInformation    | Should Be $MockWebBinding.bindingInformation
                    $Result.BindingInfo.IPAddress             | Should Be '*'
                    $Result.BindingInfo.Port                  | Should Be 443
                    $Result.BindingInfo.HostName              | Should Be 'web01.contoso.com'
                    $Result.BindingInfo.CertificateThumbprint | Should Be $MockWebBinding.certificateHash
                    $Result.BindingInfo.CertificateStoreName  | Should Be $MockWebBinding.certificateStoreName
                    $Result.BindingInfo.SslFlags              | Should Be $MockWebBinding.sslFlags
                }

                It 'Should return DefaultPage' {
                    $Result.DefaultPage | Should Be 'index.html'
                }

                It 'Should return EnabledProtocols' {
                    $Result.EnabledProtocols | Should Be $MockWebsite.EnabledProtocols
                }

                It 'Should return AuthenticationInfo' {
                    $Result.AuthenticationInfo.CimInstanceProperties['Anonymous'].Value | Should Be $true
                    $Result.AuthenticationInfo.CimInstanceProperties['Basic'].Value     | Should Be $false
                    $Result.AuthenticationInfo.CimInstanceProperties['Digest'].Value    | Should Be $false
                    $Result.AuthenticationInfo.CimInstanceProperties['Windows'].Value   | Should Be $true
                }

                It 'Should return Preload' {
                    $Result.PreloadEnabled | Should Be $MockWebsite.ApplicationDefaults.PreloadEnabled
                }

                It 'Should return ServiceAutoStartProvider' {
                    $Result.ServiceAutoStartProvider | Should Be $MockWebsite.ApplicationDefaults.ServiceAutoStartProvider
                }

                It 'Should return ServiceAutoStartEnabled' {
                    $Result.ServiceAutoStartEnabled | Should Be $MockWebsite.ApplicationDefaults.ServiceAutoStartEnabled
                }

                It 'Should return ApplicationType' {
                    $Result.ApplicationType | Should Be $MockPreloadAndAutostartProvider.ApplicationType
                }

                It 'Should return correct LogPath' {
                    $Result.LogPath | Should Be $MockWebsite.Logfile.directory
                }

                It 'Should return LogFlags' {
                    $Result.LogFlags | Should Be $MockWebsite.Logfile.logExtFileFlags
                }

                It 'Should return LogPeriod' {
                    $Result.LogPeriod | Should Be $MockWebsite.Logfile.period
                }

                It 'Should return LogTargetW3C' {
                    $Result.TargetW3C | Should Be $MockWebsite.Logfile.TargetW3C
                }

                It 'Should return LogTruncateSize' {
                    $Result.LogTruncateSize | Should Be $MockWebsite.Logfile.truncateSize
                }

                It 'Should return LoglocalTimeRollover' {
                    $Result.LoglocalTimeRollover | Should Be $MockWebsite.Logfile.localTimeRollover
                }

                It 'Should return LogFormat' {
                    $Result.logFormat | Should Be $MockWebsite.Logfile.logFormat
                }

                It 'Should return LogCustomFields' {
                    $Result.LogCustomFields[0].LogFieldName | Should Be $mockLogCustomFields[0].LogFieldName
                    $Result.LogCustomFields[0].SourceName   | Should Be $mockLogCustomFields[0].SourceName
                    $Result.LogCustomFields[0].SourceType   | Should Be $mockLogCustomFields[0].SourceType
                    $Result.LogCustomFields[1].LogFieldName | Should Be $mockLogCustomFields[1].LogFieldName
                    $Result.LogCustomFields[1].SourceName   | Should Be $mockLogCustomFields[1].SourceName
                    $Result.LogCustomFields[1].SourceType   | Should Be $mockLogCustomFields[1].SourceType
                }
            }
        }

        Describe "how $DSCResourceName\Test-TargetResource responds to Ensure = 'Present'" {

            $MockBindingInfo = @(
                New-CimInstance -ClassName MSFT_xWebBindingInformation `
                                -Namespace 'root/microsoft/Windows/DesiredStateConfiguration' `
                                -ClientOnly `
                                -Property @{
                                    Protocol              = 'https'
                                    IPAddress             = '*'
                                    Port                  = 443
                                    HostName              = 'web01.contoso.com'
                                    CertificateThumbprint = '1D3324C6E2F7ABC794C9CB6CA426B8D0F81045CD'
                                    CertificateStoreName  = 'WebHosting'
                                    SslFlags              = 1
                                }
            )

            $MockCimLogCustomFields = @(
                (New-CimInstance -ClassName MSFT_xLogCustomFieldInformation `
                    -Namespace 'root/microsoft/Windows/DesiredStateConfiguration' `
                    -Property @{
                        LogFieldName = 'LogField1'
                        SourceName   = 'Accept-Encoding'
                        SourceType   = 'RequestHeader'
                    } `
                    -ClientOnly
                ),
                (New-CimInstance -ClassName MSFT_xLogCustomFieldInformation `
                    -Namespace 'root/microsoft/Windows/DesiredStateConfiguration' `
                    -Property @{
                        LogFieldName = 'LogField2'
                        SourceName   = 'Warning'
                        SourceType   = 'ResponseHeader'
                    } `
                    -ClientOnly
                )
            )

            $MockAuthenticationInfo = New-CimInstance `
                                            -ClassName MSFT_xWebAuthenticationInformation `
                                            -ClientOnly `
                                            -Property @{ Anonymous=$true; Basic=$false; Digest=$false; Windows=$true } `
                                            -Namespace 'root/microsoft/Windows/DesiredStateConfiguration'

            $MockParameters = @{
                Ensure                   = 'Present'
                Name                     = 'MockName'
                PhysicalPath             = 'C:\NonExistent'
                State                    = 'Started'
                ApplicationPool          = 'MockPool'
                AuthenticationInfo       = $MockAuthenticationInfo
                BindingInfo              = $MockBindingInfo
                DefaultPage              = @('index.html')
                EnabledProtocols         = 'http'
                Preload                  = 'True'
                ServiceAutoStartProvider = 'MockAutoStartProvider'
                ServiceAutoStartEnabled  = 'True'
                ApplicationType          = 'MockApplicationType'
                LogPath                  = 'C:\MockLogLocation'
                LogFlags                 = 'Date','Time','ClientIP','UserName','ServerIP'
                LogPeriod                = 'Hourly'
                LogTargetW3C             = 'File,ETW'
                LogTruncateSize          = '2000000'
                LoglocalTimeRollover     = $True
                LogCustomFields          = $MockCimLogCustomFields
            }

            $MockWebBinding = @(
                @{
                    bindingInformation   = '*:443:web01.contoso.com'
                    protocol             = 'https'
                    certificateHash      = '1D3324C6E2F7ABC794C9CB6CA426B8D0F81045CD'
                    certificateStoreName = 'WebHosting'
                    sslFlags             = '1'
                }
            )

            $MockPreloadAndAutostartProviders = @(
                @{
                    Preload                  = 'True'
                    ServiceAutoStartProvider = 'MockServiceAutoStartProvider'
                    ServiceAutoStartEnabled  = 'True'
                }
            )

            $mockLogCustomFields = @(
                @{
                    LogFieldName = 'LogField1'
                    SourceName   = 'Accept-Encoding'
                    SourceType   = 'RequestHeader'
                }
                @{
                    LogFieldName = 'LogField2'
                    SourceName   = 'Warning'
                    SourceType   = 'ResponseHeader'
                }
            )

            $MockLogOutput = @{
                directory         = '%SystemDrive%\inetpub\logs\LogFiles'
                logExtFileFlags   = 'Date','Time','ClientIP','UserName','ServerIP','Method','UriStem','UriQuery','HttpStatus','Win32Status','TimeTaken','ServerPort','UserAgent','Referer','HttpSubStatus'
                logFormat         = $MockParameters.LogFormat
                period            = 'Daily'
                LogTargetW3C      = 'File,ETW'
                truncateSize      = '1048576'
                localTimeRollover = 'False'
                customFields      = @{Collection = $mockLogCustomFields}
            }

            $MockWebsite = @{
                Name                 = 'MockName'
                SiteId               = 1234
                PhysicalPath         = 'C:\NonExistent'
                State                = 'Started'
                ApplicationPool      = 'MockPool'
                Bindings             = @{ Collection = @($MockWebBinding) }
                EnabledProtocols     = 'http'
                ApplicationDefaults  = @{ Collection = @($MockPreloadAndAutostartProviders) }
                LogFile              = $MockLogOutput
                Count                = 1
            }

            Mock -CommandName Assert-Module -MockWith {}

            Context 'Website does not exist' {

                Mock -CommandName Get-Website

                $Result = Test-TargetResource `
                            -Ensure $MockParameters.Ensure `
                            -Name $MockParameters.Name `
                            -PhysicalPath $MockParameters.PhysicalPath

                It 'Should return False' {
                    $Result | Should Be $false
                }
            }

            Context 'Check SiteId is different' {

                Mock -CommandName Get-Website -MockWith {$MockWebsite}
                Mock -CommandName Test-AuthenticationInfo -MockWith { return $true }

                $Result = Test-TargetResource `
                            -Ensure $MockParameters.Ensure `
                            -Name $MockParameters.Name `
                            -SiteId 12345 `
                            -Verbose:$VerbosePreference

                It 'Should return False' {
                    $Result | Should Be $false
                }
            }

            Context 'Check PhysicalPath is different' {

                Mock -CommandName Get-Website -MockWith {return $MockWebsite}
                Mock -CommandName Test-AuthenticationInfo -MockWith { return $true }

                $Result = Test-TargetResource `
                            -Ensure $MockParameters.Ensure `
                            -Name $MockParameters.Name `
                            -PhysicalPath 'C:\Different' `
                            -Verbose:$VerbosePreference

                It 'Should return False' {
                    $Result | Should Be $false
                }
            }

            Context 'Check State is different' {

                Mock -CommandName Get-Website -MockWith {return $MockWebsite}
                Mock -CommandName Test-AuthenticationInfo -MockWith { return $true }

                $Result = Test-TargetResource `
                            -Ensure $MockParameters.Ensure `
                            -Name $MockParameters.Name `
                            -PhysicalPath $MockParameters.PhysicalPath `
                            -State 'Stopped' `
                            -Verbose:$VerbosePreference

                It 'Should return False' {
                    $Result | Should Be $false
                }
            }

            Context 'Check ApplicationPool is different' {

                Mock -CommandName Get-Website -MockWith {return $MockWebsite}
                Mock -CommandName Test-AuthenticationInfo -MockWith { return $true }

                $Result = Test-TargetResource `
                            -Name $MockParameters.Name `
                            -Ensure $MockParameters.Ensure `
                            -PhysicalPath $MockParameters.PhysicalPath `
                            -ApplicationPool 'MockPoolDifferent' `
                            -Verbose:$VerbosePreference

                It 'Should return False' {
                    $Result | Should Be $false
                }
            }

            Context 'Check BindingInfo is different' {

                Mock -CommandName Get-Website -MockWith {return $MockWebsite}
                Mock -CommandName Test-AuthenticationInfo -MockWith { return $true }
                Mock -ModuleName $DSCHelperModuleName `
                    -CommandName Test-WebsiteBinding `
                    -MockWith {return $false}

                $Result = Test-TargetResource `
                            -Name $MockParameters.Name `
                            -Ensure $MockParameters.Ensure `
                            -PhysicalPath $MockParameters.PhysicalPath `
                            -BindingInfo $MockParameters.BindingInfo `
                            -Verbose:$VerbosePreference

                It 'Should return False' {
                    $Result | Should Be $false
                }
            }

            Context 'Check DefaultPage is different' {

                Mock -CommandName Get-Website -MockWith {return $MockWebsite}
                Mock -CommandName Test-AuthenticationInfo -MockWith { return $true }
                Mock -CommandName Get-WebConfiguration -MockWith {return @{value = 'MockDifferent.html'}}

                $Result = Test-TargetResource `
                            -Name $MockParameters.Name `
                            -Ensure $MockParameters.Ensure `
                            -PhysicalPath $MockParameters.PhysicalPath `
                            -DefaultPage $MockParameters.DefaultPage `
                            -Verbose:$VerbosePreference

                It 'Should return False' {
                    $Result | Should Be $false
                }
            }

            Context 'Check EnabledProtocols is different' {

                Mock -CommandName Get-Website -MockWith {return $MockWebsite}
                Mock -CommandName Test-AuthenticationInfo -MockWith { return $true }

                $Result = Test-TargetResource `
                            -Ensure $MockParameters.Ensure `
                            -Name $MockParameters.Name `
                            -PhysicalPath $MockParameters.PhysicalPath `
                            -EnabledProtocols 'https' `
                            -Verbose:$VerbosePreference

                It 'Should return False' {
                    $Result | Should Be $false
                }
            }

            Context 'Check AuthenticationInfo is different' {

                Mock -CommandName Get-Website -MockWith {return $MockWebsite}

                Mock -ModuleName $DSCHelperModuleName `
                    -CommandName Test-AuthenticationEnabled { return $true } `
                    -ParameterFilter { ($Type -eq 'Anonymous') }

                Mock -ModuleName $DSCHelperModuleName `
                    -CommandName Test-AuthenticationEnabled { return $false } `
                    -ParameterFilter { ($Type -in @('Basic', 'Digest', 'Windows')) }

                $Result = Test-TargetResource `
                            -Ensure $MockParameters.Ensure `
                            -Name $MockParameters.Name `
                            -PhysicalPath $MockParameters.PhysicalPath `
                            -AuthenticationInfo $MockParameters.AuthenticationInfo `
                            -Verbose:$VerbosePreference

                It 'Should return False' {
                    $Result | Should Be $false
                }

                It 'Should call all the mocks' {
                    Assert-MockCalled -CommandName Get-Website -Exactly 1
                    Assert-MockCalled `
                        -ModuleName $DSCHelperModuleName `
                        -CommandName Test-AuthenticationEnabled `
                        -Exactly 4
                }
            }

            Context 'Check AuthenticationInfo is different from default' {

                Mock -CommandName Get-Website -MockWith {return $MockWebsite}

                Mock -ModuleName $DSCHelperModuleName `
                    -CommandName Test-AuthenticationEnabled { return $true } `
                    -ParameterFilter { ($Type -eq 'Windows') }

                Mock -ModuleName $DSCHelperModuleName `
                    -CommandName Test-AuthenticationEnabled { return $false } `
                    -ParameterFilter { ($Type -in @('Anonymous', 'Basic', 'Digest')) }

                $Result = Test-TargetResource `
                            -Ensure $MockParameters.Ensure `
                            -Name $MockParameters.Name `
                            -PhysicalPath $MockParameters.PhysicalPath `
                            -Verbose:$VerbosePreference

                It 'Should return False' {
                    $Result | Should Be $false
                }

                It 'Should call all the mocks' {
                    Assert-MockCalled -CommandName Get-Website -Exactly 1
                    Assert-MockCalled `
                        -ModuleName $DSCHelperModuleName `
                        -CommandName Test-AuthenticationEnabled `
                        -Exactly 4
                }
            }

            Context 'Check Preload is different' {

                Mock -CommandName Get-Website -MockWith {return $MockWebsite}
                Mock -CommandName Test-AuthenticationInfo -MockWith { return $true }

                $Result = Test-TargetResource `
                            -Ensure $MockParameters.Ensure `
                            -Name $MockParameters.Name `
                            -PhysicalPath $MockParameters.PhysicalPath `
                            -Preload $False `
                            -Verbose:$VerbosePreference

                It 'Should return False' {
                    $Result | Should Be $false
                }
            }

            Context 'Check AutoStartEnabled is different' {

                Mock -CommandName Get-Website -MockWith {return $MockWebsite}
                Mock -CommandName Test-AuthenticationInfo -MockWith { return $true }

                $Result = Test-TargetResource `
                            -Ensure $MockParameters.Ensure `
                            -Name $MockParameters.Name `
                            -PhysicalPath $MockParameters.PhysicalPath `
                            -ServiceAutoStartEnabled $False `
                            -Verbose:$VerbosePreference

                It 'Should return False' {
                    $Result | Should Be $false
                }
            }

            Context 'Check AutoStartProvider is different' {

                Mock -CommandName Get-Website -MockWith { return $MockWebsite }
                Mock -CommandName Test-AuthenticationInfo -MockWith { return $true }

                $result = Test-TargetResource `
                            -Ensure $MockParameters.Ensure `
                            -Name $MockParameters.Name `
                            -PhysicalPath $MockParameters.PhysicalPath `
                            -ServiceAutoStartProvider 'MockAutoStartProviderDifferent' `
                            -ApplicationType 'MockApplicationTypeDifferent' `
                            -Verbose:$VerbosePreference

                It 'Should return False' {
                    $result | Should Be $false
                }
            }

            Context 'Check LogPath is equal' {

                $MockLogOutput.directory = $MockParameters.LogPath

                Mock -CommandName Test-Path -MockWith { return $true }
                Mock -CommandName Get-Website -MockWith { return $MockWebsite }
                Mock -CommandName Test-AuthenticationInfo -MockWith { return $true }

                Mock -CommandName Get-WebConfigurationProperty `
                    -MockWith { return $MockLogOutput.logExtFileFlags }

                $result = Test-TargetResource `
                            -Ensure $MockParameters.Ensure `
                            -Name $MockParameters.Name `
                            -PhysicalPath $MockParameters.PhysicalPath `
                            -LogPath $MockParameters.LogPath `
                            -Verbose:$VerbosePreference

                It 'Should return true' {
                    $result | Should be $true
                }
            }

            Context 'Check LogPath is different' {

                $MockLogOutput.directory = $MockParameters.LogPath

                Mock -CommandName Test-Path -MockWith { return $true }
                Mock -CommandName Get-Website -MockWith { return $MockWebsite }
                Mock -CommandName Test-AuthenticationInfo -MockWith { return $true }

                Mock -ModuleName $DSCHelperModuleName `
                    -CommandName Get-WebConfigurationProperty `
                    -MockWith {return $MockLogOutput.logExtFileFlags }

                $result = Test-TargetResource `
                            -Ensure $MockParameters.Ensure `
                            -Name $MockParameters.Name `
                            -PhysicalPath $MockParameters.PhysicalPath `
                            -LogPath 'C:\MockLogPath2' `
                            -Verbose:$VerbosePreference

                It 'Should return false' {
                    $result | Should be $false
                }
            }

            Context 'Check LogFlags are different' {

                $MockLogOutput.logExtFileFlags = 'Date','Time','ClientIP','UserName','ServerIP','Method','UriStem','UriQuery','HttpStatus','Win32Status','TimeTaken','ServerPort','UserAgent','Referer','HttpSubStatus'

                Mock -CommandName Test-Path -MockWith { return $true }
                Mock -CommandName Get-Website -MockWith { return $MockWebsite }
                Mock -CommandName Test-AuthenticationInfo -MockWith { return $true }

                Mock -ModuleName $DSCHelperModuleName `
                    -CommandName Get-WebConfigurationProperty `
                    -MockWith { return $MockLogOutput.logExtFileFlags }

                $result = Test-TargetResource `
                            -Ensure $MockParameters.Ensure `
                            -Name $MockParameters.Name `
                            -PhysicalPath $MockParameters.PhysicalPath `
                            -LogFlags 'Date','Time','ClientIP','UserName','ServerIP' `
                            -Verbose:$VerbosePreference

                It 'Should return false' {
                    $result | Should be $false
                }
            }

            Context 'Check LogPeriod is equal' {

                $MockLogOutput.period = $MockParameters.LogPeriod

                Mock -CommandName Test-Path -MockWith {Return $true}
                Mock -CommandName Get-Website -MockWith {return $MockWebsite}
                Mock -CommandName Test-AuthenticationInfo -MockWith { return $true }

                Mock -ModuleName $DSCHelperModuleName `
                    -CommandName Get-WebConfigurationProperty `
                    -MockWith {return $MockLogOutput.logExtFileFlags }

                $Result = Test-TargetResource `
                            -Ensure $MockParameters.Ensure `
                            -Name $MockParameters.Name `
                            -PhysicalPath $MockParameters.PhysicalPath `
                            -LogPeriod 'Hourly' `
                            -Verbose:$VerbosePreference

                It 'Should return true' {
                    $result | Should be $true
                }
            }

            Context 'Check LogPeriod is different' {

                $MockLogOutput.period = 'Daily'

                Mock -CommandName Test-Path -MockWith {Return $true}
                Mock -CommandName Get-Website -MockWith {return $MockWebsite}
                Mock -CommandName Test-AuthenticationInfo -MockWith { return $true }

                Mock -ModuleName $DSCHelperModuleName `
                    -CommandName Get-WebConfigurationProperty `
                    -MockWith {return $MockLogOutput.logExtFileFlags }

                $Result = Test-TargetResource `
                            -Ensure $MockParameters.Ensure `
                            -Name $MockParameters.Name `
                            -PhysicalPath $MockParameters.PhysicalPath `
                            -LogPeriod 'Hourly' `
                            -Verbose:$VerbosePreference

                It 'Should return false' {
                    $result | Should be $false
                }
            }

            Context 'Check LogTruncateSize is different' {

                $MockLogOutput = @{
                    directory         = $MockParameters.LogPath
                    logExtFileFlags   = $MockParameters.LogFlags
                    logFormat         = $MockParameters.LogFormat
                    period            = $MockParameters.LogPeriod
                    truncateSize      = '1048576'
                    localTimeRollover = $MockParameters.LoglocalTimeRollover
                }

                Mock -CommandName Test-Path -MockWith {Return $true}
                Mock -CommandName Get-Website -MockWith {return $MockWebsite}
                Mock -CommandName Test-AuthenticationInfo -MockWith { return $true }

                Mock -ModuleName $DSCHelperModuleName `
                    -CommandName Get-WebConfigurationProperty `
                    -MockWith {return $MockLogOutput.logExtFileFlags }

                $Result = Test-TargetResource `
                            -Ensure $MockParameters.Ensure `
                            -Name $MockParameters.Name `
                            -PhysicalPath $MockParameters.PhysicalPath `
                            -LogTruncateSize '2000000' `
                            -Verbose:$VerbosePreference

                It 'Should return false' {
                    $result | Should be $false
                }
            }

            Context 'Check LoglocalTimeRollover is different' {

                $MockLogOutput = @{
                    directory         = $MockParameters.LogPath
                    logExtFileFlags   = $MockParameters.LogFlags
                    logFormat         = $MockParameters.LogFormat
                    period            = $MockParameters.LogPeriod
                    truncateSize      = $MockParameters.LogTruncateSize
                    localTimeRollover = 'False'
                }

                Mock -CommandName Test-Path -MockWith {Return $true}
                Mock -CommandName Get-Website -MockWith {return $MockWebsite}
                Mock -CommandName Test-AuthenticationInfo -MockWith { return $true }

                Mock -ModuleName $DSCHelperModuleName `
                    -CommandName Get-WebConfigurationProperty `
                    -MockWith {return $MockLogOutput.logExtFileFlags }

                $Result = Test-TargetResource `
                            -Ensure $MockParameters.Ensure `
                            -Name $MockParameters.Name `
                            -PhysicalPath $MockParameters.PhysicalPath `
                            -LoglocalTimeRollover $True `
                            -Verbose:$VerbosePreference

                It 'Should return false' {
                    $result | Should be $false
                }
            }

            Context 'Check LogFormat is different' {

                $MockLogOutput = @{
                        directory         = $MockParameters.LogPath
                        logExtFileFlags   = $MockParameters.LogFlags
                        logFormat         = 'IIS'
                        period            = $MockParameters.LogPeriod
                        truncateSize      = $MockParameters.LogTruncateSize
                        localTimeRollover = $MockParameters.LoglocalTimeRollover
                    }

                $MockWebsite = @{
                    Name                 = 'MockName'
                    PhysicalPath         = 'C:\NonExistent'
                    State                = 'Started'
                    ApplicationPool      = 'MockPool'
                    Bindings             = @{Collection = @($MockWebBinding)}
                    EnabledProtocols     = 'http'
                    ApplicationDefaults  = $MockPreloadAndAutostartProviders
                    LogFile              = $MockLogOutput
                    Count                = 1
                }

                Mock -CommandName Test-Path -MockWith {Return $true}
                Mock -CommandName Get-Website -MockWith {return $MockWebsite}
                Mock -CommandName Test-AuthenticationInfo -MockWith { return $true }

                Mock -ModuleName $DSCHelperModuleName `
                    -CommandName Get-WebConfigurationProperty `
                    -MockWith {return $MockLogOutput.logExtFileFlags }

                $Result = Test-TargetResource `
                            -Ensure $MockParameters.Ensure `
                            -Name $MockParameters.Name `
                            -PhysicalPath $MockParameters.PhysicalPath `
                            -LogFormat 'W3C' `
                            -Verbose:$VerbosePreference

                It 'Should return false' {
                    $result | Should be $false
                }
            }

            Context 'Check LogTargetW3C is different' {

                $MockLogOutput = @{
                        directory         = $MockParameters.LogPath
                        logExtFileFlags   = $MockParameters.LogFlags
                        logFormat         = $MockParameters.LogFormat
                        logTargetW3C      = 'ETW'
                        period            = $MockParameters.LogPeriod
                        truncateSize      = $MockParameters.LogTruncateSize
                        localTimeRollover = $MockParameters.LoglocalTimeRollover
                    }

                $MockWebsite = @{
                    Name                 = 'MockName'
                    PhysicalPath         = 'C:\NonExistent'
                    State                = 'Started'
                    ApplicationPool      = 'MockPool'
                    Bindings             = @{Collection = @($MockWebBinding)}
                    EnabledProtocols     = 'http'
                    ApplicationDefaults  = $MockPreloadAndAutostartProviders
                    LogFile              = $MockLogOutput
                    Count                = 1
                }

                Mock -CommandName Test-Path -MockWith {Return $true}
                Mock -CommandName Get-Website -MockWith {return $MockWebsite}
                Mock -CommandName Test-AuthenticationInfo -MockWith { return $true }

                Mock -CommandName Get-WebConfigurationProperty `
                    -MockWith {return $MockLogOutput.logExtFileFlags }

                $Result = Test-TargetResource `
                            -Ensure $MockParameters.Ensure `
                            -Name $MockParameters.Name `
                            -PhysicalPath $MockParameters.PhysicalPath `
                            -LogTargetW3C 'File,ETW' `
                            -Verbose:$VerbosePreference

                It 'Should return false' {
                    $result | Should be $false
                }
            }

            Context 'Check LogTruncateSize is larger in string comparison' {

                $MockLogOutput = @{
                    directory         = $MockParameters.LogPath
                    logExtFileFlags   = $MockParameters.LogFlags
                    logFormat         = $MockParameters.LogFormat
                    period            = $MockParameters.LogPeriod
                    truncateSize      = '1048576'
                    localTimeRollover = $MockParameters.LoglocalTimeRollover
                }

                Mock -CommandName Test-Path -MockWith { return $true }
                Mock -CommandName Get-Website -MockWith { return $MockWebsite }
                Mock -CommandName Test-AuthenticationInfo -MockWith { return $true }

                Mock -CommandName Get-WebConfigurationProperty `
                    -MockWith { return $MockLogOutput.logExtFileFlags }

                $result = Test-TargetResource `
                            -Ensure $MockParameters.Ensure `
                            -Name $MockParameters.Name `
                            -PhysicalPath $MockParameters.PhysicalPath `
                            -LogTruncateSize '5000000' `
                            -Verbose:$VerbosePreference

                It 'Should return false' {
                    $result | Should be $false
                }
            }

            Context 'Check LogCustomFields is equal' {

                Mock -CommandName Get-Website -MockWith {return $MockWebsite}
                Mock -CommandName Test-AuthenticationInfo -MockWith { return $true }

                Mock -CommandName Get-WebConfigurationProperty `
                    -MockWith { return $mockLogCustomFields[0] } `
                    -ParameterFilter { $Filter -match $MockParameters.LogCustomFields[0].LogFieldName }

                Mock -CommandName Get-WebConfigurationProperty `
                    -MockWith { return $mockLogCustomFields[1] } `
                    -ParameterFilter { $Filter -match $MockParameters.LogCustomFields[1].LogFieldName }

                $Result = Test-TargetResource `
                            -Ensure $MockParameters.Ensure `
                            -Name $MockParameters.Name `
                            -LogCustomFields $MockParameters.LogCustomFields

                It 'Should return true' {
                    $result | Should be $true
                }
            }

            Context 'Check LogCustomFields is different' {

                Mock -CommandName Get-Website -MockWith {return $MockWebsite}
                Mock -CommandName Test-AuthenticationInfo -MockWith { return $true }

                $MockDifferentLogCustomFields = @{
                    LogFieldName = 'DifferentField'
                    SourceName   = 'Accept-Encoding'
                    SourceType   = 'DifferentSourceType'
                }

                Mock -CommandName Get-WebConfigurationProperty `
                    -MockWith {return $MockDifferentLogCustomFields }

                $Result = Test-TargetResource `
                            -Ensure $MockParameters.Ensure `
                            -Name $MockParameters.Name `
                            -LogCustomFields $MockParameters.LogCustomFields

                It 'Should return false' {
                    $result | Should be $false
                }
            }
        }

        Describe "how $DSCResourceName\Set-TargetResource responds to Ensure = 'Present'" {

            $MockAuthenticationInfo = New-CimInstance  `
                                        -ClassName MSFT_xWebApplicationAuthenticationInformation `
                                        -ClientOnly `
                                        -Property @{ Anonymous=$true; Basic=$false; Digest=$false; Windows=$true } `
                                        -Namespace 'root/microsoft/Windows/DesiredStateConfiguration'

            $MockBindingInfo = @(
                New-CimInstance -ClassName MSFT_xWebBindingInformation `
                                -Namespace 'root/microsoft/Windows/DesiredStateConfiguration' `
                                -ClientOnly `
                                -Property @{
                                    Protocol              = 'https'
                                    IPAddress             = '*'
                                    Port                  = 443
                                    HostName              = 'web01.contoso.com'
                                    CertificateThumbprint = '1D3324C6E2F7ABC794C9CB6CA426B8D0F81045CD'
                                    CertificateStoreName  = 'WebHosting'
                                    SslFlags              = 1
                                }
            )

            $MockCimLogCustomFields = @(
                New-CimInstance -ClassName MSFT_xLogCustomFieldInformation `
                    -Namespace 'root/microsoft/Windows/DesiredStateConfiguration' `
                    -Property @{
                        LogFieldName = 'ClientEncoding'
                        SourceName   = 'Accept-Encoding'
                        SourceType   = 'RequestHeader'
                    } `
                    -ClientOnly
            )

            $MockParameters = @{
                Ensure                   = 'Present'
                Name                     = 'MockName'
                SiteId                   = 1234
                PhysicalPath             = 'C:\NonExistent'
                State                    = 'Started'
                ApplicationPool          = 'MockPool'
                BindingInfo              = $MockBindingInfo
                DefaultPage              = @('index.html')
                EnabledProtocols         = 'http'
                Preload                  = $True
                ServiceAutoStartProvider = 'MockAutoStartProvider'
                ServiceAutoStartEnabled  = $True
                ApplicationType          = 'MockApplicationType'
                AuthenticationInfo       = $MockAuthenticationInfo
                LogPath                  = 'C:\MockLogLocation'
                LogFlags                 = 'Date','Time','ClientIP','UserName','ServerIP'
                LogPeriod                = 'Hourly'
                LogTruncateSize          = '2000000'
                LoglocalTimeRollover     = $True
                LogFormat                = 'W3C'
                LogTargetW3C             = 'File,ETW'
                LogCustomFields          = $MockCimLogCustomFields
            }

            $MockWebBinding = @(
                @{
                    bindingInformation   = '*:80:'
                    protocol             = 'http'
                    certificateHash      = ''
                    certificateStoreName = ''
                    sslFlags             = '0'
                }
            )

            $MockPreloadAndAutostartProviders = @(
                @{
                    Preload                  = $True
                    ServiceAutoStartProvider = 'MockServiceAutoStartProvider'
                    ServiceAutoStartEnabled  = $True
                }
            )

            $mockLogCustomFields = @(
                @{
                    LogFieldName = 'LogField1'
                    SourceName   = 'Accept-Encoding'
                    SourceType   = 'RequestHeader'
                }
                @{
                    LogFieldName = 'LogField2'
                    SourceName   = 'Warning'
                    SourceType   = 'ResponseHeader'
                }
            )

            $MockLogOutput =
                @{
                    directory         = '%SystemDrive%\inetpub\logs\LogFiles'
                    logExtFileFlags   = 'Date','Time','ClientIP','UserName','ServerIP','Method','UriStem','UriQuery','HttpStatus','Win32Status','TimeTaken','ServerPort','UserAgent','Referer','HttpSubStatus'
                    logFormat         = 'IIS'
                    period            = 'Daily'
                    LogTargetW3C      = 'ETW'
                    truncateSize      = '1048576'
                    localTimeRollover = 'False'
                    customFields      = @{Collection = $mockLogCustomFields}
                }

            $MockWebsite = @{
                Name                = 'MockName'
                Id                  = 1234
                PhysicalPath        = 'C:\Different'
                State               = 'Stopped'
                ApplicationPool     = 'MockPoolDifferent'
                Bindings            = @{ Collection = @($MockWebBinding) }
                EnabledProtocols    = 'http'
                ApplicationDefaults = @{ Collection = @($MockPreloadAndAutostartProviders) }
                LogFile             = $MockLogOutput
            }

            $MockWebsiteGetItem      = $MockWebsite.Clone()
            $MockWebsiteGetItem.Path = 'WebAdministration::\\SERVERNAME\Sites\MockName'
            $MockWebsiteGetItem      = [PSCustomObject]$MockWebsiteGetItem

            Mock -CommandName Assert-Module -MockWith {}

            Context 'All properties need to be updated and website must be started' {

                Mock -CommandName Add-WebConfiguration

                Mock -CommandName Confirm-UniqueBinding -MockWith {return $true}

                Mock -CommandName Confirm-UniqueServiceAutoStartProviders -MockWith { return $false }

                Mock -CommandName Get-Website -MockWith { return $MockWebsite }

                Mock -CommandName Test-WebsiteBinding -MockWith { return $false }

                Mock -CommandName Start-Website

                Mock -CommandName Get-Item -MockWith { return $MockWebsiteGetItem }

                Mock -CommandName Set-Item

                Mock -CommandName Set-ItemProperty

                Mock -CommandName Set-WebConfiguration

                Mock -ModuleName $DSCHelperModuleName -CommandName Set-Authentication

                Mock -CommandName Update-WebsiteBinding

                Mock -CommandName Update-DefaultPage

                Mock -ModuleName $DSCHelperModuleName `
                     -CommandName Test-AuthenticationEnabled { return $true } `
                     -ParameterFilter { ($Type -eq 'Anonymous') }

                Mock -ModuleName $DSCHelperModuleName `
                     -CommandName Test-AuthenticationEnabled { return $false } `
                     -ParameterFilter { ($Type -in @('Basic','Digest','Windows')) }

                Mock -CommandName Set-WebConfigurationProperty

                Mock -CommandName Test-LogCustomField -MockWith { return $false }

                Set-TargetResource @MockParameters

                It 'Should call all the mocks' {
                    Assert-MockCalled -CommandName Add-WebConfiguration -Exactly 1
                    Assert-MockCalled -CommandName Confirm-UniqueBinding -Exactly 1
                    Assert-MockCalled -CommandName Confirm-UniqueServiceAutoStartProviders -Exactly 1
                    Assert-MockCalled -CommandName Test-WebsiteBinding -Exactly 1
                    Assert-MockCalled -CommandName Update-WebsiteBinding -Exactly 1
                    Assert-MockCalled -CommandName Update-DefaultPage -Exactly 1
                    Assert-MockCalled -CommandName Get-Item -Exactly 3
                    Assert-MockCalled -CommandName Set-Item -Exactly 3
                    Assert-MockCalled -CommandName Set-ItemProperty -Exactly 10
                    Assert-MockCalled -CommandName Start-Website -Exactly 1
                    Assert-MockCalled -CommandName Set-WebConfigurationProperty -Exactly 2
                    Assert-MockCalled -CommandName Test-LogCustomField -Exactly 1

                    Assert-MockCalled `
                        -ModuleName $DSCHelperModuleName `
                        -CommandName Set-Authentication `
                        -Exactly 4

                    Assert-MockCalled `
                        -ModuleName $DSCHelperModuleName `
                        -CommandName Test-AuthenticationEnabled `
                        -Exactly 4
                }
            }

            Context 'Create website without SiteId' {

                Mock -CommandName Confirm-UniqueBinding -MockWith { return $true }

                Mock -CommandName Get-Website

                Mock -CommandName Get-Command -MockWith {
                    return Get-Command -Name New-WebSite
                } -ParameterFilter {
                    $Module -eq 'WebAdministration'
                }

                $MockWebSiteNoSiteId = $MockWebsite.Clone()
                $MockWebSiteNoSiteId.Id = 1
                $MockWebsiteGetItemNew = $MockWebSiteNoSiteId.Clone()
                $MockWebsiteGetItemNew.Path = 'WebAdministration::\\SERVERNAME\Sites\MockName'
                $MockWebsiteGetItemNew = [PSCustomObject]$MockWebsiteGetItemNew

                Mock -CommandName New-Website -MockWith { return $MockWebSiteNoSiteId }

                Mock -CommandName Start-Website

                Mock -CommandName Stop-Website

                Mock -CommandName Get-Item -MockWith { return $MockWebsiteGetItemNew }

                Mock -CommandName Set-Item

                Mock -CommandName Set-ItemProperty

                Mock -CommandName Update-WebsiteBinding

                Mock -CommandName Update-DefaultPage

                Mock -CommandName Test-AuthenticationInfo -MockWith { return $true }

                $MockParametersNew = $MockParameters.Clone()
                $MockParametersNew.Remove('SiteId')

                It 'Should create and start the web site' {
                    Set-TargetResource @MockParametersNew

                    Assert-MockCalled -CommandName New-Website -ParameterFilter { $Id -eq 1 } -Exactly 1
                    Assert-MockCalled -CommandName Start-Website -Exactly 1
                    Assert-MockCalled -CommandName Update-DefaultPage -Exactly 1
                }
            }

            Context 'Create website with SiteId' {

                Mock -CommandName Confirm-UniqueBinding -MockWith { return $true }

                Mock -CommandName Get-Website

                Mock -CommandName Get-Command -MockWith {
                    return Get-Command -Name New-WebSite
                } -ParameterFilter {
                    $Module -eq 'WebAdministration'
                }

                Mock -CommandName New-Website -MockWith { return $MockWebSite }

                Mock -CommandName Start-Website

                Mock -CommandName Stop-Website

                Mock -CommandName Get-Item -MockWith { return $MockWebsiteGetItem }

                Mock -CommandName Set-Item

                Mock -CommandName Set-ItemProperty

                Mock -CommandName Update-WebsiteBinding

                Mock -CommandName Update-DefaultPage

                Mock -CommandName Test-AuthenticationInfo -MockWith { return $true }

                It 'Should create and start the web site' {
                    Set-TargetResource @MockParameters

                    Assert-MockCalled -CommandName New-Website -ParameterFilter { $Id -eq 1234 } -Exactly 1
                    Assert-MockCalled -CommandName Start-Website -Exactly 1
                }
            }

            Context 'Create website with empty physical path' {

                Mock -CommandName Confirm-UniqueBinding -MockWith { return $true }

                Mock -CommandName Get-Website

                Mock -CommandName Get-Command -MockWith {
                    return Get-Command -Name New-WebSite
                } -ParameterFilter {
                    $Module -eq 'WebAdministration'
                }

                Mock -CommandName New-Website -MockWith { return $MockWebsite }

                Mock -CommandName Start-Website

                Mock -CommandName Stop-Website

                Mock -CommandName Get-Item -MockWith { return $MockWebsiteGetItem }

                Mock -CommandName Set-Item

                Mock -CommandName Set-ItemProperty

                Mock -CommandName Update-WebsiteBinding

                Mock -CommandName Update-DefaultPage

                Mock -CommandName Test-AuthenticationInfo -MockWith { return $true }

                $MockParameters = $MockParameters.Clone()
                $MockParameters.PhysicalPath = ''

                It 'Should create and start the web site' {
                    Set-TargetResource @MockParameters

                    Assert-MockCalled -CommandName New-Website -ParameterFilter { $Force -eq $True } -Exactly 1
                    Assert-MockCalled -CommandName Start-Website -Exactly 1
                }
            }

            Context 'Create website with null physical path' {

                Mock -CommandName Confirm-UniqueBinding -MockWith { return $true }

                Mock -CommandName Get-Website

                Mock -CommandName Get-Command -MockWith {
                    return Get-Command -Name New-WebSite
                } -ParameterFilter {
                    $Module -eq 'WebAdministration'
                }

                Mock -CommandName New-Website -MockWith { return $MockWebsite }

                Mock -CommandName Start-Website

                Mock -CommandName Stop-Website

                Mock -CommandName Get-Item -MockWith { return $MockWebsiteGetItem }

                Mock -CommandName Set-Item

                Mock -CommandName Set-ItemProperty

                Mock -CommandName Update-WebsiteBinding

                Mock -CommandName Update-DefaultPage

                Mock -CommandName Test-AuthenticationInfo -MockWith { return $true }

                $MockParameters = $MockParameters.Clone()
                $MockParameters.PhysicalPath = $null

                It 'Should create and start the web site' {
                    Set-TargetResource @MockParameters

                    Assert-MockCalled -CommandName New-Website -ParameterFilter { $Force -eq $True } -Exactly 1
                    Assert-MockCalled -CommandName Start-Website -Exactly 1
                }
            }

            Context 'Existing website cannot be started due to a binding conflict' {

                Mock -CommandName Get-Website -MockWith {return $MockWebsite}
                Mock -CommandName Set-ItemProperty
                Mock -CommandName Add-WebConfiguration
                Mock -CommandName Test-WebsiteBinding -MockWith {return $false}
                Mock -CommandName Update-WebsiteBinding
                Mock -CommandName Update-DefaultPage
                Mock -CommandName Confirm-UniqueBinding -MockWith {return $false}
                Mock -CommandName Confirm-UniqueServiceAutoStartProviders -MockWith {return $true}
                Mock -CommandName Start-Website

                It 'Should throw the correct error' {
                    $ErrorId       = 'WebsiteBindingConflictOnStart'
                    $ErrorCategory = [System.Management.Automation.ErrorCategory]::InvalidResult
                    $ErrorMessage  = $LocalizedData.ErrorWebsiteBindingConflictOnStart -f $MockParameters.Name
                    $Exception     = New-Object -TypeName System.InvalidOperationException `
                                                -ArgumentList $ErrorMessage
                    $ErrorRecord   = New-Object -TypeName System.Management.Automation.ErrorRecord `
                                                -ArgumentList $Exception, $ErrorId, $ErrorCategory, $null

                    {Set-TargetResource @MockParameters} | Should Throw $ErrorRecord
                }
            }

            Context 'Start-Website throws an error' {

                Mock -CommandName Get-Website -MockWith {return $MockWebsite}
                Mock -CommandName Set-ItemProperty
                Mock -CommandName Add-WebConfiguration
                Mock -CommandName Test-WebsiteBinding -MockWith {return $false}
                Mock -CommandName Update-WebsiteBinding
                Mock -CommandName Update-DefaultPage
                Mock -CommandName Confirm-UniqueBinding -MockWith {return $true}
                Mock -CommandName Confirm-UniqueServiceAutoStartProviders -MockWith {return $true}
                Mock -CommandName Start-Website -MockWith {throw}

                It 'Should throw the correct error' {
                    $ErrorId       = 'WebsiteStateFailure'
                    $ErrorCategory = [System.Management.Automation.ErrorCategory]::InvalidOperation
                    $ErrorMessage  = $LocalizedData.ErrorWebsiteStateFailure -f $MockParameters.Name, 'ScriptHalted'
                    $Exception     = New-Object -TypeName System.InvalidOperationException `
                                                -ArgumentList $ErrorMessage
                    $ErrorRecord   = New-Object -TypeName System.Management.Automation.ErrorRecord `
                                                -ArgumentList $Exception, $ErrorId, $ErrorCategory, $null

                    { Set-TargetResource @MockParameters } | Should Throw $ErrorRecord
                }
            }

            Context 'All properties need to be updated and website must be stopped' {

                $MockParameters = $MockParameters.Clone()
                $MockParameters.State = 'Stopped'

                $MockWebsite = $MockWebsite.Clone()
                $MockWebsite.State = 'Started'

                Mock -CommandName Get-Website -MockWith {return $MockWebsite}

                Mock -CommandName Set-ItemProperty

                Mock -CommandName Add-WebConfiguration

                Mock -CommandName Test-WebsiteBinding -MockWith {return $false}

                Mock -CommandName Update-WebsiteBinding

                Mock -CommandName Update-DefaultPage

                Mock -CommandName Get-Item -MockWith { return $MockWebsiteGetItem }

                Mock -CommandName Set-Item

                Mock -ModuleName $DSCHelperModuleName -CommandName Set-Authentication

                Mock -CommandName Stop-Website

                Mock -ModuleName $DSCHelperModuleName `
                    -CommandName Test-AuthenticationEnabled { return $true } `
                    -ParameterFilter { ($Type -eq 'Anonymous') }

                Mock -ModuleName $DSCHelperModuleName `
                    -CommandName Test-AuthenticationEnabled { return $false } `
                    -ParameterFilter { ($Type -in @('Basic','Digest','Windows')) }

                Mock -ModuleName $DSCHelperModuleName `
                    -CommandName Get-WebConfiguration `
                    -ParameterFilter { $filter -eq '/system.applicationHost/serviceAutoStartProviders' }

                Set-TargetResource @MockParameters

                It 'Should call all the mocks' {
                    Assert-MockCalled -CommandName Set-ItemProperty -Exactly 10
                    Assert-MockCalled -CommandName Add-WebConfiguration -Exactly 1
                    Assert-MockCalled -CommandName Test-WebsiteBinding -Exactly 1
                    Assert-MockCalled -CommandName Update-WebsiteBinding -Exactly 1
                    Assert-MockCalled -CommandName Update-DefaultPage -Exactly 1
                    Assert-MockCalled -ModuleName $DSCHelperModuleName -CommandName Set-Authentication -Exactly 4
                    Assert-MockCalled -CommandName Stop-Website -Exactly 1
                }
            }

            Context 'Website does not exist' {

                $MockWebsite = @{
                    Name                     = 'MockName'
                    PhysicalPath             = 'C:\NonExistent'
                    State                    = 'Started'
                    ApplicationPool          = 'MockPool'
                    Bindings                 = @{Collection = @($MockWebBinding)}
                    EnabledProtocols         = 'http'
                    ApplicationDefaults      = @{Collection = @($MockPreloadAndAutostartProviders)}
                    LogFile                  = $MockLogOutput
                }

                $MockWebsiteGetItem = $MockWebsite.Clone()
                $MockWebsiteGetItem.Path = 'WebAdministration::\\SERVERNAME\Sites\MockName'
                $MockWebsiteGetItem = [PSCustomObject]$MockWebsiteGetItem

                Mock -CommandName Get-Website

                Mock -CommandName Get-Command -MockWith {
                    return @{
                        Parameters = @{
                            Name = 'MockName'
                        }
                    }
                }

                Mock -CommandName New-Website -MockWith { return $MockWebsite }

                Mock -CommandName Stop-Website

                Mock -CommandName Test-WebsiteBinding -MockWith { return $false }

                Mock -CommandName Update-WebsiteBinding

                Mock -CommandName Get-Item -MockWith { return $MockWebsiteGetItem }

                Mock -CommandName Set-Item

                Mock -CommandName Set-ItemProperty

                Mock -CommandName Add-WebConfiguration

                Mock -CommandName Update-DefaultPage

                Mock -CommandName Confirm-UniqueBinding -MockWith { return $true }

                Mock -CommandName Confirm-UniqueServiceAutoStartProviders -MockWith { return $false }

                Mock -ModuleName $DSCHelperModuleName -CommandName Set-Authentication

                Mock -CommandName Start-Website

                Mock -ModuleName $DSCHelperModuleName `
                    -CommandName Test-AuthenticationEnabled { return $true } `
                    -ParameterFilter { ($Type -eq 'Anonymous') }

                Mock -ModuleName $DSCHelperModuleName `
                    -CommandName Test-AuthenticationEnabled { return $false } `
                    -ParameterFilter { ($Type -in @('Basic', 'Digest', 'Windows')) }

                Set-TargetResource @MockParameters

                It 'Should call all the mocks' {
                     Assert-MockCalled -CommandName New-Website -Exactly 1
                     Assert-MockCalled -CommandName Stop-Website -Exactly 1
                     Assert-MockCalled -CommandName Test-WebsiteBinding -Exactly 1
                     Assert-MockCalled -CommandName Update-WebsiteBinding -Exactly 1
                     Assert-MockCalled -CommandName Get-Item -Exactly 1
                     Assert-MockCalled -CommandName Set-Item -Exactly 1
                     Assert-MockCalled -CommandName Set-ItemProperty -Exactly 8
                     Assert-MockCalled -CommandName Add-WebConfiguration -Exactly 1
                     Assert-MockCalled -CommandName Update-DefaultPage -Exactly 1
                     Assert-MockCalled -CommandName Confirm-UniqueBinding -Exactly 1
                     Assert-MockCalled -CommandName Confirm-UniqueServiceAutoStartProviders -Exactly 1
                     Assert-MockCalled -ModuleName $DSCHelperModuleName -CommandName Set-Authentication -Exactly 4
                     Assert-MockCalled -CommandName Start-Website -Exactly 1
                }
            }

            Context 'Website has unchanged logging directory' {

                $MockWebsite = @{
                    Name                 = 'MockName'
                    PhysicalPath         = 'C:\NonExistent'
                    State                = 'Started'
                    ApplicationPool      = 'MockPool'
                    Bindings             = @{Collection = @($MockWebBinding)}
                    EnabledProtocols     = 'http'
                    ApplicationDefaults  = $MockPreloadAndAutostartProviders
                    Count                = 1
                    LogFile              = @{
                        directory         = 'C:\MockLogLocation'
                        logExtFileFlags   = 'Date','Time','ClientIP','UserName','ServerIP','Method','UriStem','UriQuery','HttpStatus','Win32Status','TimeTaken','ServerPort','UserAgent','Referer','HttpSubStatus'
                        logFormat         = $MockParameters.LogFormat
                        period            = 'Daily'
                        logTargetW3C      = 'File,ETW'
                        truncateSize      = '1048576'
                        localTimeRollover = 'False'
                    }
                }

                $MockWebsiteGetItem = $MockWebsite.Clone()
                $MockWebsiteGetItem.Path = 'WebAdministration::\\SERVERNAME\Sites\MockName'
                $MockWebsiteGetItem = [PSCustomObject]$MockWebsiteGetItem

                Mock -CommandName Get-Website -MockWith { return $MockWebsite }

                Mock -CommandName Get-Command -MockWith {
                    return @{
                        Parameters = @{
                            Name = 'MockName'
                        }
                    }
                }

                Mock -CommandName Test-WebsiteBinding -MockWith { return $false }

                Mock -CommandName Update-WebsiteBinding

                Mock -CommandName Get-Item -MockWith { return $MockWebsiteGetItem }

                Mock -CommandName Set-Item

                Mock -CommandName Set-ItemProperty

                Mock -CommandName Add-WebConfiguration

                Mock -CommandName Update-DefaultPage

                Mock -CommandName Confirm-UniqueServiceAutoStartProviders -MockWith { return $false }

                Mock -ModuleName $DSCHelperModuleName `
                    -CommandName Set-Authentication

                Mock -ModuleName $DSCHelperModuleName `
                    -CommandName Test-AuthenticationEnabled { return $true } `
                    -ParameterFilter { ($Type -eq 'Anonymous') }

                Mock -ModuleName $DSCHelperModuleName `
                    -CommandName Test-AuthenticationEnabled { return $false } `
                    -ParameterFilter { ($Type -in @('Basic', 'Digest', 'Windows')) }

                Set-TargetResource @MockParameters

                It 'Should call all the mocks' {
                    Assert-MockCalled -CommandName Test-WebsiteBinding -Exactly 1
                    Assert-MockCalled -CommandName Update-WebsiteBinding -Exactly 1
                    Assert-MockCalled -CommandName Get-Item -Exactly 2
                    Assert-MockCalled -CommandName Set-Item -Exactly 2
                    Assert-MockCalled -CommandName Set-ItemProperty -Exactly 6
                    Assert-MockCalled -CommandName Set-ItemProperty -ParameterFilter { $Name -eq 'LogFile.directory' } -Exactly 0
                    Assert-MockCalled -CommandName Add-WebConfiguration -Exactly 1
                    Assert-MockCalled -CommandName Update-DefaultPage -Exactly 1
                    Assert-MockCalled -CommandName Confirm-UniqueServiceAutoStartProviders -Exactly 1
                    Assert-MockCalled -ModuleName $DSCHelperModuleName -CommandName Test-AuthenticationEnabled -Exactly 4
                    Assert-MockCalled -ModuleName $DSCHelperModuleName -CommandName Set-Authentication -Exactly 4
                }
            }

            Context 'Website has changed logging directory' {

                $MockWebsite = @{
                    Name                 = 'MockName'
                    PhysicalPath         = 'C:\NonExistent'
                    State                = 'Started'
                    ApplicationPool      = 'MockPool'
                    Bindings             = @{Collection = @($MockWebBinding)}
                    EnabledProtocols     = 'http'
                    ApplicationDefaults  = $MockPreloadAndAutostartProviders
                    Count                = 1
                    LogFile              = @{
                        directory         = 'C:\Logs\MockLogLocation'
                        logExtFileFlags   = 'Date','Time','ClientIP','UserName','ServerIP','Method','UriStem','UriQuery','HttpStatus','Win32Status','TimeTaken','ServerPort','UserAgent','Referer','HttpSubStatus'
                        logFormat         = $MockParameters.LogFormat
                        period            = 'Daily'
                        logTargetW3C      = 'File,ETW'
                        truncateSize      = '1048576'
                        localTimeRollover = 'False'
                    }
                }

                $MockWebsiteGetItem = $MockWebsite.Clone()
                $MockWebsiteGetItem.Path = 'WebAdministration::\\SERVERNAME\Sites\MockName'
                $MockWebsiteGetItem = [PSCustomObject]$MockWebsiteGetItem

                Mock -CommandName Get-Website -MockWith { return $MockWebsite }

                Mock -CommandName Get-Command -MockWith {
                    return @{
                        Parameters = @{
                            Name = 'MockName'
                        }
                    }
                }

                Mock -CommandName Test-WebsiteBinding -MockWith { return $false }

                Mock -CommandName Update-WebsiteBinding

                Mock -CommandName Get-Item -MockWith { return $MockWebsiteGetItem }

                Mock -CommandName Set-Item

                Mock -CommandName Set-ItemProperty

                Mock -CommandName Add-WebConfiguration

                Mock -CommandName Update-DefaultPage

                Mock -CommandName Confirm-UniqueServiceAutoStartProviders -MockWith { return $false }

                Mock -ModuleName $DSCHelperModuleName -CommandName Set-Authentication

                Mock -ModuleName $DSCHelperModuleName `
                    -CommandName Test-AuthenticationEnabled { return $true } `
                    -ParameterFilter { ($Type -eq 'Anonymous') }

                Mock -ModuleName $DSCHelperModuleName `
                    -CommandName Test-AuthenticationEnabled { return $false } `
                    -ParameterFilter { ($Type -in @('Basic', 'Digest', 'Windows')) }

                Set-TargetResource @MockParameters

                It 'Should call all the mocks' {
                     Assert-MockCalled -CommandName Test-WebsiteBinding -Exactly 1
                     Assert-MockCalled -CommandName Update-WebsiteBinding -Exactly 1
                     Assert-MockCalled -CommandName Get-Item -Exactly 2
                     Assert-MockCalled -CommandName Set-Item -Exactly 2
                     Assert-MockCalled -CommandName Set-ItemProperty -Exactly 7
                     Assert-MockCalled -CommandName Set-ItemProperty -ParameterFilter { $Name -eq 'LogFile.directory' } -Exactly 1
                     Assert-MockCalled -CommandName Add-WebConfiguration -Exactly 1
                     Assert-MockCalled -CommandName Update-DefaultPage -Exactly 1
                     Assert-MockCalled -CommandName Confirm-UniqueServiceAutoStartProviders -Exactly 1
                     Assert-MockCalled -ModuleName $DSCHelperModuleName -CommandName Set-Authentication -Exactly 4
                }
            }

            Context 'New website cannot be started due to a binding conflict' {

                $MockWebsite = @{
                    Name                     = 'MockName'
                    PhysicalPath             = 'C:\NonExistent'
                    State                    = 'Started'
                    ApplicationPool          = 'MockPool'
                    Bindings                 = @{Collection = @($MockWebBinding)}
                    EnabledProtocols         = 'http'
                    Preload                  = $True
                    ServiceAutoStartProvider = 'MockAutoStartProvider'
                    ServiceAutoStartEnabled  = $True
                    ApplicationType          = 'MockApplicationType'
                }

                Mock -CommandName Get-Website

                Mock -CommandName Get-Command -MockWith {
                    return @{
                        Parameters = @{
                            Name = 'MockName'
                        }
                    }
                }

                Mock -CommandName New-Website -MockWith { return $MockWebsite }

                Mock -CommandName Stop-Website

                Mock -CommandName Test-WebsiteBinding -MockWith { return $false }

                Mock -CommandName Update-WebsiteBinding

                Mock -CommandName Set-ItemProperty

                Mock -CommandName Add-WebConfiguration

                Mock -CommandName Update-DefaultPage

                Mock -CommandName Confirm-UniqueBinding -MockWith { return $false }

                Mock -CommandName Confirm-UniqueServiceAutoStartProviders -MockWith { return $true }

                Mock -CommandName Start-Website

                It 'Should throw the correct error' {
                    $ErrorId       = 'WebsiteBindingConflictOnStart'
                    $ErrorCategory = [System.Management.Automation.ErrorCategory]::InvalidResult
                    $ErrorMessage  = $LocalizedData.ErrorWebsiteBindingConflictOnStart -f $MockParameters.Name
                    $Exception     = New-Object -TypeName System.InvalidOperationException `
                                                -ArgumentList $ErrorMessage
                    $ErrorRecord   = New-Object -TypeName System.Management.Automation.ErrorRecord `
                                                -ArgumentList $Exception, $ErrorId, $ErrorCategory, $null

                    { Set-TargetResource @MockParameters } | Should Throw $ErrorRecord
                }
            }

            Context 'New-Website throws an error' {

                Mock -CommandName Get-Website

                Mock -CommandName Get-Command -MockWith {
                    return @{
                        Parameters = @{
                            Name = 'MockName'
                        }
                    }
                }

                Mock -CommandName New-Website -MockWith {throw}

                It 'Should throw the correct error' {
                    $ErrorId       = 'WebsiteCreationFailure'
                    $ErrorCategory = [System.Management.Automation.ErrorCategory]::InvalidOperation
                    $ErrorMessage  = $LocalizedData.ErrorWebsiteCreationFailure -f $MockParameters.Name, 'ScriptHalted'
                    $Exception     = New-Object -TypeName System.InvalidOperationException `
                                                -ArgumentList $ErrorMessage
                    $ErrorRecord   = New-Object -TypeName System.Management.Automation.ErrorRecord `
                                                -ArgumentList $Exception, $ErrorId, $ErrorCategory, $null

                    { Set-TargetResource @MockParameters } | Should Throw $ErrorRecord
                }
            }

            Context 'LogTruncateSize is larger in string comparison' {

                $MockLogOutput = @{
                    directory         = $MockParameters.LogPath
                    logExtFileFlags   = $MockParameters.LogFlags
                    logFormat         = $MockParameters.LogFormat
                    logTargetW3C      = $MockParameters.LogTargetW3C
                    period            = $MockParameters.LogPeriod
                    truncateSize      = '1048576'
                    localTimeRollover = $MockParameters.LoglocalTimeRollover
                }

                Mock -CommandName Test-Path -MockWith { return $true }

                Mock -CommandName Get-Website -MockWith { return $MockWebsite }

                Mock -CommandName Set-ItemProperty -MockWith { }

                Mock -CommandName Test-AuthenticationInfo { return $true }

                Mock -CommandName Get-WebConfigurationProperty `
                    -MockWith { return $MockLogOutput.logExtFileFlags }

                Set-TargetResource `
                    -Ensure $MockParameters.Ensure `
                    -Name $MockParameters.Name `
                    -PhysicalPath $MockParameters.PhysicalPath `
                    -LogTruncateSize '5000000' `
                    -Verbose:$VerbosePreference

                It 'Should call mocks' {
                    Assert-MockCalled -CommandName Set-ItemProperty `
                        -ParameterFilter { $Name -eq 'LogFile.truncateSize' } `
                        -Exactly 1
                }
            }
        }

        Describe "how $DSCResourceName\Set-TargetResource responds to Ensure = 'Absent'" {

            $MockParameters = @{
                Ensure       = 'Absent'
                Name         = 'MockName'
                PhysicalPath = 'C:\NonExistent'
            }

            Mock -CommandName Get-Website -MockWith { return @{Name = $MockParameters.Name} }

            Mock -CommandName Assert-Module -MockWith {}

            It 'Should call Remove-Website' {
                Mock -CommandName Remove-Website

                Set-TargetResource @MockParameters

                Assert-MockCalled -CommandName Get-Website -Exactly 1
                Assert-MockCalled -CommandName Remove-Website -Exactly 1
            }

            It 'Should throw the correct error' {
                Mock -CommandName Remove-Website -MockWith {throw}

                $ErrorId       = 'WebsiteRemovalFailure'
                $ErrorCategory = [System.Management.Automation.ErrorCategory]::InvalidOperation
                $ErrorMessage  = $LocalizedData.ErrorWebsiteRemovalFailure -f $MockParameters.Name, 'ScriptHalted'
                $Exception     = New-Object -TypeName System.InvalidOperationException `
                                            -ArgumentList $ErrorMessage
                $ErrorRecord   = New-Object -TypeName System.Management.Automation.ErrorRecord `
                                            -ArgumentList $Exception, $ErrorId, $ErrorCategory, $null

                {Set-TargetResource @MockParameters} | Should Throw $ErrorRecord
            }
        }

        Describe "$DSCResourceName\Update-DefaultPage" {

            $MockWebsite = @{
                Name               = 'MockName'
                DefaultPage        = 'index.htm'
            }

            Context 'Does not find the default page' {

                Mock -CommandName Get-WebConfiguration -MockWith {
                    return @{value = 'index2.htm'}
                }

                Mock -CommandName Add-WebConfiguration

                It 'Should call Add-WebConfiguration' {
                    Update-DefaultPage -Name $MockWebsite.Name -DefaultPage $MockWebsite.DefaultPage

                    Assert-MockCalled -CommandName Add-WebConfiguration
                }
            }
        }

        Describe "$DSCResourceName\Test-LogCustomField"{

            $MockWebsiteName = 'ContosoSite'

            $MockCimLogCustomFields = @(
                New-CimInstance -ClassName MSFT_xLogCustomFieldInformation `
                                -Namespace 'root/microsoft/Windows/DesiredStateConfiguration' `
                                -ClientOnly `
                                -Property @{
                                    LogFieldName = 'ClientEncoding'
                                    SourceName   = 'Accept-Encoding'
                                    SourceType   = 'RequestHeader'
                                }
            )

            Context 'LogCustomField in desired state'{

                $MockDesiredLogCustomFields = @{
                    LogFieldName = 'ClientEncoding'
                    SourceName   = 'Accept-Encoding'
                    SourceType   = 'RequestHeader'
                }

                Mock -CommandName Get-WebConfigurationProperty `
                    -MockWith { return $MockDesiredLogCustomFields }

                It 'Should return True' {
                    Test-LogCustomField -Site $MockWebsiteName `
                                        -LogCustomField $MockCimLogCustomFields | Should Be $True
                }
            }

            Context 'LogCustomField not in desired state'{

                $MockWrongLogCustomFields = @{
                    LogFieldName = 'ClientEncoding'
                    SourceName   = 'WrongSourceName'
                    SourceType   = 'WrongSourceType'
                }

                Mock -CommandName Get-WebConfigurationProperty `
                    -MockWith { return $MockWrongLogCustomFields }

                It 'Should return False' {
                    Test-LogCustomField -Site $MockWebsiteName `
                                        -LogCustomField $MockCimLogCustomFields | Should Be $False
                }
            }

            Context 'LogCustomField not present'{

                Mock -CommandName Get-WebConfigurationProperty `
                    -MockWith { return $false }

                It 'Should return False' {
                    Test-LogCustomField -Site $MockWebsiteName `
                                        -LogCustomField $MockCimLogCustomFields | Should Be $False
                }
            }
        }

        Describe "$DSCResourceName\Set-LogCustomField"{

            $MockWebsiteName = 'ContosoSite'

            $MockCimLogCustomFields = @(
                New-CimInstance -ClassName MSFT_xLogCustomFieldInformation `
                                -Namespace 'root/microsoft/Windows/DesiredStateConfiguration' `
                                -ClientOnly `
                                -Property @{
                                    LogFieldName = 'ClientEncoding'
                                    SourceName   = 'Accept-Encoding'
                                    SourceType   = 'RequestHeader'
                                }
            )

            Context 'Create new LogCustomField'{

                Mock -CommandName Set-WebConfigurationProperty

                It 'Should not throw an error' {
                    { Set-LogCustomField  -Site $MockWebsiteName -LogCustomField $MockCimLogCustomFields } | Should Not Throw
                }

                It 'Should call should call expected mocks' {
                    Assert-MockCalled -CommandName Set-WebConfigurationProperty -Exactly 2
                }
            }

            Context 'Modify existing LogCustomField'{

                Mock -CommandName Set-WebConfigurationProperty

                It 'Should not throw an error' {
                    { Set-LogCustomField  -Site $MockWebsiteName -LogCustomField $MockCimLogCustomFields } | Should Not Throw
                }

                It 'Should call should call expected mocks' {
                    Assert-MockCalled -CommandName Set-WebConfigurationProperty -Exactly 2
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
