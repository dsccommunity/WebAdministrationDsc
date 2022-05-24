
$script:dscModuleName   = 'xWebAdministration'
$script:dscResourceName = 'MSFT_xWebSite'

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
}

function Invoke-TestCleanup
{
    Restore-TestEnvironment -TestEnvironment $script:testEnvironment
}

Invoke-TestSetup

try
{
    InModuleScope $script:dscResourceName {
        $script:dscResourceName = 'MSFT_xWebSite'

        # Make sure we don't have the original module in memory.
        Remove-Module -Name 'WebAdministration' -ErrorAction SilentlyContinue

        # Load the stubs
        $script:moduleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
        Import-Module (Join-Path -Path $PSScriptRoot -ChildPath '..\MockWebAdministrationWindowsFeature.psm1') -Force

        Describe "how $script:dscResourceName\Get-TargetResource responds" {
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

            $MockAuthenticationInfo = @(
                New-CimInstance -ClassName MSFT_xWebAuthenticationInformation `
                    -Namespace root/microsoft/Windows/DesiredStateConfiguration `
                    -Property @{
                        Anonymous = 'true'
                        Basic     = 'false'
                        Digest    = 'false'
                        Windows   = 'false'
                    } `
                    -ClientOnly
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
                logExtFileFlags   = 'Date,Time,ClientIP,UserName,ServerIP,Method,UriStem,UriQuery,HttpStatus,Win32Status,TimeTaken,ServerPort,UserAgent,Referer,HttpSubStatus'
                logFormat         = $MockParameters.LogFormat
                period            = 'Daily'
                logTargetW3C      = 'File,ETW'
                truncateSize      = '1048576'
                localTimeRollover = 'False'
                customFields      = @{Collection = $mockLogCustomFields}
            }

            $MockWebsite = @{
                Name                 = 'MockName'
                Id                   = 1234
                PhysicalPath         = 'C:\NonExistent'
                State                = 'Started'
                ServerAutoStart      = $true
                ApplicationPool      = 'MockPool'
                Bindings             = @{Collection = @($MockWebBinding)}
                EnabledProtocols     = 'http'
                ApplicationDefaults  = $MockPreloadAndAutostartProviders
                LogFile              = $MockLogOutput
                Count                = 1
            }

            $MockLogFlagsAfterSplit = [System.String[]] @('Date','Time','ClientIP','UserName','ServerIP','Method','UriStem','UriQuery','HttpStatus','Win32Status','TimeTaken','ServerPort','UserAgent','Referer','HttpSubStatus')

            Mock -CommandName Assert-Module -MockWith {}

            Context 'Website does not exist' {
                Mock -CommandName Get-Website

                $Result = Get-TargetResource -Name $MockWebsite.Name

                It 'should return Absent' {
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

                It 'should throw the correct error' {
                    $ErrorId = 'WebsiteDiscoveryFailure'
                    $ErrorCategory = [System.Management.Automation.ErrorCategory]::InvalidResult
                    $ErrorMessage = $script:localizedData.ErrorWebsiteDiscoveryFailure -f 'MockName'
                    $Exception = New-Object `
                        -TypeName System.InvalidOperationException `
                        -ArgumentList $ErrorMessage
                    $ErrorRecord = New-Object `
                        -TypeName System.Management.Automation.ErrorRecord `
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

                Mock -CommandName Get-WebConfigurationProperty `
                    -MockWith {return $MockAuthenticationInfo}

                Mock -CommandName Test-AuthenticationEnabled { return $true } `
                    -ParameterFilter { ($Type -eq 'Anonymous') }

                Mock -CommandName Test-AuthenticationEnabled { return $false } `
                    -ParameterFilter { ($Type -eq 'Basic') }

                Mock -CommandName Test-AuthenticationEnabled { return $false } `
                    -ParameterFilter { ($Type -eq 'Digest') }

                Mock -CommandName Test-AuthenticationEnabled { return $true } `
                    -ParameterFilter { ($Type -eq 'Windows') }

                $Result = Get-TargetResource -Name $MockWebsite.Name

                It 'should call Get-Website once' {
                    Assert-MockCalled -CommandName Get-Website -Exactly 1
                }

                It 'should call Get-WebConfiguration twice' {
                    Assert-MockCalled -CommandName Get-WebConfiguration -Exactly 2
                }

                It 'should return Ensure' {
                    $Result.Ensure | Should Be 'Present'
                }

                It 'should return Name' {
                    $Result.Name | Should Be $MockWebsite.Name
                }

                It 'should return SiteId' {
                    $Result.SiteId | Should Be $MockWebsite.Id
                }

                It 'should return PhysicalPath' {
                    $Result.PhysicalPath | Should Be $MockWebsite.PhysicalPath
                }

                It 'should return State' {
                    $Result.State | Should Be $MockWebsite.State
                }

                It 'should return ServerAutoStart' {
                    $Result.ServerAutoStart | Should Be $MockWebsite.ServerAutoStart
                }

                It 'should return ApplicationPool' {
                    $Result.ApplicationPool | Should Be $MockWebsite.ApplicationPool
                }

                It 'should return BindingInfo' {
                    $Result.BindingInfo.Protocol              | Should Be $MockWebBinding.protocol
                    $Result.BindingInfo.BindingInformation    | Should Be $MockWebBinding.bindingInformation
                    $Result.BindingInfo.IPAddress             | Should Be '*'
                    $Result.BindingInfo.Port                  | Should Be 443
                    $Result.BindingInfo.HostName              | Should Be 'web01.contoso.com'
                    $Result.BindingInfo.CertificateThumbprint | Should Be $MockWebBinding.certificateHash
                    $Result.BindingInfo.CertificateStoreName  | Should Be $MockWebBinding.certificateStoreName
                    $Result.BindingInfo.SslFlags              | Should Be $MockWebBinding.sslFlags
                }

                It 'should return DefaultPage' {
                    $Result.DefaultPage | Should Be 'index.html'
                }

                It 'should return EnabledProtocols' {
                    $Result.EnabledProtocols | Should Be $MockWebsite.EnabledProtocols
                }

                It 'should return AuthenticationInfo' {
                    $Result.AuthenticationInfo.CimInstanceProperties['Anonymous'].Value | Should Be 'true'
                    $Result.AuthenticationInfo.CimInstanceProperties['Basic'].Value     | Should Be 'false'
                    $Result.AuthenticationInfo.CimInstanceProperties['Digest'].Value    | Should Be 'false'
                    $Result.AuthenticationInfo.CimInstanceProperties['Windows'].Value   | Should Be 'true'
                }

                It 'should return Preload' {
                    $Result.PreloadEnabled | Should Be $MockWebsite.ApplicationDefaults.PreloadEnabled
                }

                It 'should return ServiceAutoStartProvider' {
                    $Result.ServiceAutoStartProvider | Should Be $MockWebsite.ApplicationDefaults.ServiceAutoStartProvider
                }

                It 'should return ServiceAutoStartEnabled' {
                    $Result.ServiceAutoStartEnabled | Should Be $MockWebsite.ApplicationDefaults.ServiceAutoStartEnabled
                }

                It 'should return ApplicationType' {
                    $Result.ApplicationType | Should Be $MockPreloadAndAutostartProvider.ApplicationType
                }

                It 'should return correct LogPath' {
                    $Result.LogPath | Should Be $MockWebsite.Logfile.directory
                }

                It 'should return LogFlags' {
                    $Result.LogFlags | Should Be $MockLogFlagsAfterSplit
                }

                It 'should return LogFlags as expected array of Strings' {
                    $Result.LogFlags -is [System.String[]] | Should -BeTrue
                    $Result.LogFlags | Should -HaveCount 15
                    $Result.LogFlags | Should -Contain 'Date'
                    $Result.LogFlags | Should -Contain 'Time'
                    $Result.LogFlags | Should -Contain 'ClientIP'
                    $Result.LogFlags | Should -Contain 'UserName'
                    $Result.LogFlags | Should -Contain 'ServerIP'
                    $Result.LogFlags | Should -Contain 'Method'
                    $Result.LogFlags | Should -Contain 'UriStem'
                    $Result.LogFlags | Should -Contain 'UriQuery'
                    $Result.LogFlags | Should -Contain 'HttpStatus'
                    $Result.LogFlags | Should -Contain 'Win32Status'
                    $Result.LogFlags | Should -Contain 'TimeTaken'
                    $Result.LogFlags | Should -Contain 'ServerPort'
                    $Result.LogFlags | Should -Contain 'UserAgent'
                    $Result.LogFlags | Should -Contain 'Referer'
                    $Result.LogFlags | Should -Contain 'HttpSubStatus'
                }

                It 'should return LogPeriod' {
                    $Result.LogPeriod | Should Be $MockWebsite.Logfile.period
                }

                It 'should return LogTargetW3C' {
                    $Result.TargetW3C | Should Be $MockWebsite.Logfile.TargetW3C
                }

                It 'should return LogTruncateSize' {
                    $Result.LogTruncateSize | Should Be $MockWebsite.Logfile.truncateSize
                }

                It 'should return LoglocalTimeRollover' {
                    $Result.LoglocalTimeRollover | Should Be $MockWebsite.Logfile.localTimeRollover
                }

                It 'should return LogFormat' {
                    $Result.logFormat | Should Be $MockWebsite.Logfile.logFormat
                }

                It 'should return LogCustomFields' {
                    $Result.LogCustomFields[0].LogFieldName | Should Be $mockLogCustomFields[0].LogFieldName
                    $Result.LogCustomFields[0].SourceName   | Should Be $mockLogCustomFields[0].SourceName
                    $Result.LogCustomFields[0].SourceType   | Should Be $mockLogCustomFields[0].SourceType
                    $Result.LogCustomFields[1].LogFieldName | Should Be $mockLogCustomFields[1].LogFieldName
                    $Result.LogCustomFields[1].SourceName   | Should Be $mockLogCustomFields[1].SourceName
                    $Result.LogCustomFields[1].SourceType   | Should Be $mockLogCustomFields[1].SourceType
                }
            }
        }

        Describe "how $script:dscResourceName\Test-TargetResource responds to Ensure = 'Present'" {
            $MockBindingInfo = @(
                New-CimInstance -ClassName MSFT_xWebBindingInformation `
                -Namespace root/microsoft/Windows/DesiredStateConfiguration `
                -Property @{
                    Protocol              = 'https'
                    IPAddress             = '*'
                    Port                  = 443
                    HostName              = 'web01.contoso.com'
                    CertificateThumbprint = '1D3324C6E2F7ABC794C9CB6CA426B8D0F81045CD'
                    CertificateStoreName  = 'WebHosting'
                    SslFlags              = 1
                } -ClientOnly
            )

            $MockCimLogCustomFields = @(
                (New-CimInstance -ClassName MSFT_xLogCustomFieldInformation `
                    -Namespace root/microsoft/Windows/DesiredStateConfiguration `
                    -Property @{
                        LogFieldName = 'LogField1'
                        SourceName   = 'Accept-Encoding'
                        SourceType   = 'RequestHeader'
                    } `
                    -ClientOnly
                ),
                (New-CimInstance -ClassName MSFT_xLogCustomFieldInformation `
                    -Namespace root/microsoft/Windows/DesiredStateConfiguration `
                    -Property @{
                        LogFieldName = 'LogField2'
                        SourceName   = 'Warning'
                        SourceType   = 'ResponseHeader'
                    } `
                    -ClientOnly
                )
            )

            $MockParameters = @{
                Ensure                   = 'Present'
                Name                     = 'MockName'
                PhysicalPath             = 'C:\NonExistent'
                State                    = 'Started'
                ServerAutoStart          = $true
                ApplicationPool          = 'MockPool'
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
                ServerAutoStart      = $true
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

                It 'should return False' {
                    $Result | Should Be $false
                }
            }
            Context 'Check SiteId is different' {
                Mock -CommandName Get-Website -MockWith {$MockWebsite}

                $Result = Test-TargetResource -Ensure $MockParameters.Ensure `
                            -Name $MockParameters.Name `
                            -SiteId 12345 `
                            -Verbose:$VerbosePreference

                It 'should return False' {
                    $Result | Should Be $false
                }
            }

            Context 'Check PhysicalPath is different' {
                Mock -CommandName Get-Website -MockWith {return $MockWebsite}

                $Result = Test-TargetResource -Ensure $MockParameters.Ensure `
                            -Name $MockParameters.Name `
                            -PhysicalPath 'C:\Different' `
                            -Verbose:$VerbosePreference

                It 'should return False' {
                    $Result | Should Be $false
                }
            }

            Context 'Check State is different' {
                Mock -CommandName Get-Website -MockWith {return $MockWebsite}

                $Result = Test-TargetResource -Ensure $MockParameters.Ensure `
                            -Name $MockParameters.Name `
                            -PhysicalPath $MockParameters.PhysicalPath `
                            -State 'Stopped' `
                            -Verbose:$VerbosePreference

                It 'should return False' {
                    $Result | Should Be $false
                }
            }

            Context 'Check ServerAutoStart is different' {
                Mock -CommandName Get-Website -MockWith {return $MockWebsite}

                $Result = Test-TargetResource -Ensure $MockParameters.Ensure `
                            -Name $MockParameters.Name `
                            -PhysicalPath $MockParameters.PhysicalPath `
                            -ServerAutoStart  $false `
                            -Verbose:$VerbosePreference

                It 'should return False' {
                    $Result | Should Be $false
                }
            }

            Context 'Check ApplicationPool is different' {
                Mock -CommandName Get-Website -MockWith {return $MockWebsite}

                $Result = Test-TargetResource -Name $MockParameters.Name `
                            -Ensure $MockParameters.Ensure `
                            -PhysicalPath $MockParameters.PhysicalPath `
                            -ApplicationPool 'MockPoolDifferent' `
                            -Verbose:$VerbosePreference

                It 'should return False' {
                    $Result | Should Be $false
                }
            }

            Context 'Check BindingInfo is different' {
                Mock -CommandName Get-Website -MockWith {return $MockWebsite}
                Mock -CommandName Test-WebsiteBinding -MockWith {return $false}

                $Result = Test-TargetResource -Name $MockParameters.Name `
                            -Ensure $MockParameters.Ensure `
                            -PhysicalPath $MockParameters.PhysicalPath `
                            -BindingInfo $MockParameters.BindingInfo `
                            -Verbose:$VerbosePreference

                It 'should return False' {
                    $Result | Should Be $false
                }
            }

            Context 'Check DefaultPage is different' {
                Mock -CommandName Get-Website -MockWith {return $MockWebsite}
                Mock -CommandName Get-WebConfiguration -MockWith {return @{value = 'MockDifferent.html'}}

                $Result = Test-TargetResource -Name $MockParameters.Name `
                            -Ensure $MockParameters.Ensure `
                            -PhysicalPath $MockParameters.PhysicalPath `
                            -DefaultPage $MockParameters.DefaultPage `
                            -Verbose:$VerbosePreference

                It 'should return False' {
                    $Result | Should Be $false
                }
            }

            Context 'Check EnabledProtocols is different' {
                Mock -CommandName Get-Website -MockWith {return $MockWebsite}

                $Result = Test-TargetResource -Ensure $MockParameters.Ensure `
                            -Name $MockParameters.Name `
                            -PhysicalPath $MockParameters.PhysicalPath `
                            -EnabledProtocols 'https' `
                            -Verbose:$VerbosePreference

                It 'should return False' {
                    $Result | Should Be $false
                }
            }

            Context 'Check AuthenticationInfo is different' {
                Mock -CommandName Get-Website -MockWith {return $MockWebsite}

                Mock Test-AuthenticationEnabled { return $true } `
                    -ParameterFilter { ($Type -eq 'Anonymous') }

                Mock Test-AuthenticationEnabled { return $false } `
                    -ParameterFilter { ($Type -eq 'Basic') }

                Mock Test-AuthenticationEnabled { return $false } `
                    -ParameterFilter { ($Type -eq 'Digest') }

                Mock Test-AuthenticationEnabled { return $false } `
                    -ParameterFilter { ($Type -eq 'Windows') }

                $MockAuthenticationInfo = New-CimInstance `
                                            -ClassName MSFT_xWebAuthenticationInformation `
                                            -ClientOnly `
                                            -Property @{ Anonymous=$true; Basic=$false; Digest=$false; Windows=$true }

                $Result = Test-TargetResource -Ensure $MockParameters.Ensure `
                            -Name $MockParameters.Name `
                            -PhysicalPath $MockParameters.PhysicalPath `
                            -AuthenticationInfo $MockAuthenticationInfo `
                            -Verbose:$VerbosePreference

                It 'should return False' {
                    $Result | Should Be $false
                }
            }

            Context 'Check Preload is different' {
                Mock -CommandName Get-Website -MockWith {return $MockWebsite}

                $Result = Test-TargetResource -Ensure $MockParameters.Ensure `
                          -Name $MockParameters.Name `
                          -PhysicalPath $MockParameters.PhysicalPath `
                          -Preload $False `
                          -Verbose:$VerbosePreference

                It 'should return False' {
                    $Result | Should Be $false
                }
            }

            Context 'Check AutoStartEnabled is different' {
                Mock -CommandName Get-Website -MockWith {return $MockWebsite}

                $Result = Test-TargetResource -Ensure $MockParameters.Ensure `
                            -Name $MockParameters.Name `
                            -PhysicalPath $MockParameters.PhysicalPath `
                            -ServiceAutoStartEnabled $False `
                            -Verbose:$VerbosePreference

                It 'should return False' {
                    $Result | Should Be $false
                }
            }

            Context 'Check AutoStartProvider is different' {
                Mock -CommandName Get-Website -MockWith { return $MockWebsite }

                $result = Test-TargetResource -Ensure $MockParameters.Ensure `
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

                Mock -CommandName Get-WebConfigurationProperty `
                    -MockWith { return $MockLogOutput.logExtFileFlags }

                $result = Test-TargetResource -Ensure $MockParameters.Ensure `
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

                Mock -CommandName Get-WebConfigurationProperty `
                    -MockWith { return $MockLogOutput.logExtFileFlags }

                $result = Test-TargetResource -Ensure $MockParameters.Ensure `
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

                Mock -CommandName Get-WebConfigurationProperty `
                    -MockWith { return $MockLogOutput.logExtFileFlags }

                $result = Test-TargetResource -Ensure $MockParameters.Ensure `
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

                Mock -CommandName Get-WebConfigurationProperty `
                    -MockWith {return $MockLogOutput.logExtFileFlags }

                $Result = Test-TargetResource -Ensure $MockParameters.Ensure `
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

                Mock -CommandName Get-WebConfigurationProperty `
                    -MockWith {return $MockLogOutput.logExtFileFlags }

                $Result = Test-TargetResource -Ensure $MockParameters.Ensure `
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

                Mock -CommandName Get-WebConfigurationProperty `
                    -MockWith {return $MockLogOutput.logExtFileFlags }

                $Result = Test-TargetResource -Ensure $MockParameters.Ensure `
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

                Mock -CommandName Get-WebConfigurationProperty `
                    -MockWith {return $MockLogOutput.logExtFileFlags }

                $Result = Test-TargetResource -Ensure $MockParameters.Ensure `
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
                    ServerAutoStart      = $true
                    ApplicationPool      = 'MockPool'
                    Bindings             = @{Collection = @($MockWebBinding)}
                    EnabledProtocols     = 'http'
                    ApplicationDefaults  = $MockPreloadAndAutostartProviders
                    LogFile              = $MockLogOutput
                    Count                = 1
                }

                Mock -CommandName Test-Path -MockWith {Return $true}

                Mock -CommandName Get-Website -MockWith {return $MockWebsite}

                Mock -CommandName Get-WebConfigurationProperty `
                    -MockWith {return $MockLogOutput.logExtFileFlags }

                $Result = Test-TargetResource -Ensure $MockParameters.Ensure `
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

                Mock -CommandName Get-WebConfigurationProperty `
                    -MockWith {return $MockLogOutput.logExtFileFlags }

                $Result = Test-TargetResource -Ensure $MockParameters.Ensure `
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

                Mock -CommandName Get-WebConfigurationProperty `
                    -MockWith { return $MockLogOutput.logExtFileFlags }

                $result = Test-TargetResource -Ensure $MockParameters.Ensure `
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

                Mock -CommandName Get-WebConfigurationProperty `
                    -MockWith { return $mockLogCustomFields[0] } `
                    -ParameterFilter { $Filter -match $MockParameters.LogCustomFields[0].LogFieldName }

                Mock -CommandName Get-WebConfigurationProperty `
                -MockWith { return $mockLogCustomFields[1] } `
                -ParameterFilter { $Filter -match $MockParameters.LogCustomFields[1].LogFieldName }

                $Result = Test-TargetResource -Ensure $MockParameters.Ensure `
                    -Name $MockParameters.Name `
                    -LogCustomFields $MockParameters.LogCustomFields

                It 'Should return true' {
                    $result | Should be $true
                }
            }

            Context 'Check LogCustomFields is different' {
                Mock -CommandName Get-Website -MockWith {return $MockWebsite}

                $MockDifferentLogCustomFields = @{
                    LogFieldName = 'DifferentField'
                    SourceName   = 'Accept-Encoding'
                    SourceType   = 'DifferentSourceType'
                }

                Mock -CommandName Get-WebConfigurationProperty `
                    -MockWith {return $MockDifferentLogCustomFields }

                $Result = Test-TargetResource -Ensure $MockParameters.Ensure `
                    -Name $MockParameters.Name `
                    -LogCustomFields $MockParameters.LogCustomFields

                It 'Should return false' {
                    $result | Should be $false
                }
            }
        }

        Describe "how $script:dscResourceName\Set-TargetResource responds to Ensure = 'Present'" {
            $MockAuthenticationInfo = New-CimInstance  `
                -ClassName MSFT_xWebApplicationAuthenticationInformation `
                -ClientOnly `
                -Property @{ Anonymous=$true; Basic=$false; Digest=$false; Windows=$true }

            $MockBindingInfo = @(
                New-CimInstance -ClassName MSFT_xWebBindingInformation `
                    -Namespace root/microsoft/Windows/DesiredStateConfiguration `
                    -Property @{
                        Protocol              = 'https'
                        IPAddress             = '*'
                        Port                  = 443
                        HostName              = 'web01.contoso.com'
                        CertificateThumbprint = '1D3324C6E2F7ABC794C9CB6CA426B8D0F81045CD'
                        CertificateStoreName  = 'WebHosting'
                        SslFlags              = 1
                    } -ClientOnly
            )

            $MockCimLogCustomFields = @(
                New-CimInstance -ClassName MSFT_xLogCustomFieldInformation `
                    -Namespace root/microsoft/Windows/DesiredStateConfiguration `
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
                ServerAutoStart          = $true
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
                Name                 = 'MockName'
                Id                   = 1234
                PhysicalPath         = 'C:\Different'
                State                = 'Stopped'
                ServerAutoStart      = $false
                ApplicationPool      = 'MockPoolDifferent'
                Bindings             = @{ Collection = @($MockWebBinding) }
                EnabledProtocols     = 'http'
                ApplicationDefaults  = @{ Collection = @($MockPreloadAndAutostartProviders) }
                LogFile              = $MockLogOutput
            }

            $MockWebsiteGetItem = $MockWebsite.Clone()
            $MockWebsiteGetItem.Path = 'WebAdministration::\\SERVERNAME\Sites\MockName'
            $MockWebsiteGetItem = [PSCustomObject]$MockWebsiteGetItem

            Mock -CommandName Assert-Module -MockWith {}

            Context 'All properties need to be updated and website must be started' {
                Mock -CommandName Add-WebConfiguration

                Mock -CommandName Confirm-UniqueBinding -MockWith { return $true }

                Mock -CommandName Confirm-UniqueServiceAutoStartProviders -MockWith { return $false }

                Mock -CommandName Get-Website -MockWith { return $MockWebsite }

                Mock -CommandName Test-WebsiteBinding -MockWith { return $false }

                Mock -CommandName Start-Website

                Mock -CommandName Get-Item -MockWith { return $MockWebsiteGetItem }

                Mock -CommandName Set-Item

                Mock -CommandName Set-ItemProperty

                Mock -CommandName Set-WebConfiguration

                Mock -CommandName Set-Authentication

                Mock -CommandName Update-WebsiteBinding

                Mock -CommandName Update-DefaultPage

                Mock -CommandName Test-AuthenticationEnabled { return $true } `
                    -ParameterFilter { ($Type -eq 'Anonymous') }

                Mock -CommandName Test-AuthenticationEnabled { return $false } `
                    -ParameterFilter { ($Type -eq 'Basic') }

                Mock -CommandName Test-AuthenticationEnabled { return $false } `
                    -ParameterFilter { ($Type -eq 'Digest') }

                Mock -CommandName Test-AuthenticationEnabled { return $false } `
                    -ParameterFilter { ($Type -eq 'Windows') }

                Mock -CommandName Set-WebConfigurationProperty

                Mock -CommandName Test-LogCustomField -MockWith { return $false }

                Set-TargetResource @MockParameters

                It 'Should call all the mocks' {
                    Assert-MockCalled -CommandName Add-WebConfiguration -Exactly 1
                    Assert-MockCalled -CommandName Confirm-UniqueBinding -Exactly 1
                    Assert-MockCalled -CommandName Confirm-UniqueServiceAutoStartProviders -Exactly 1
                    Assert-MockCalled -CommandName Test-AuthenticationEnabled -Exactly 4
                    Assert-MockCalled -CommandName Test-WebsiteBinding -Exactly 1
                    Assert-MockCalled -CommandName Update-WebsiteBinding -Exactly 1
                    Assert-MockCalled -CommandName Update-DefaultPage -Exactly 1
                    Assert-MockCalled -CommandName Set-Authentication -Exactly 4
                    Assert-MockCalled -CommandName Get-Item -Exactly 2
                    Assert-MockCalled -CommandName Set-Item -Exactly 2
                    Assert-MockCalled -CommandName Set-ItemProperty -Exactly 13
                    Assert-MockCalled -CommandName Start-Website -Exactly 1
                    Assert-MockCalled -CommandName Set-WebConfigurationProperty -Exactly 2
                    Assert-MockCalled -CommandName Test-LogCustomField -Exactly 1
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

                $MockParametersNew = $MockParameters.Clone()
                $MockParametersNew.Remove('SiteId')

                It 'Should create and start the web site' {
                    Set-TargetResource @MockParametersNew
                    Assert-MockCalled -CommandName New-Website -ParameterFilter { $Id -eq 1 } -Exactly 1
                    Assert-MockCalled -CommandName Start-Website -Exactly 1
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

                It 'should throw the correct error' {
                    $ErrorId = 'WebsiteBindingConflictOnStart'
                    $ErrorCategory = [System.Management.Automation.ErrorCategory]::InvalidResult
                    $ErrorMessage = $script:localizedData.ErrorWebsiteBindingConflictOnStart -f $MockParameters.Name
                    $Exception = New-Object `
                        -TypeName System.InvalidOperationException `
                        -ArgumentList $ErrorMessage
                    $ErrorRecord = New-Object `
                        -TypeName System.Management.Automation.ErrorRecord `
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

                It 'should throw the correct error' {
                    $ErrorId = 'WebsiteStateFailure'
                    $ErrorCategory = [System.Management.Automation.ErrorCategory]::InvalidOperation
                    $ErrorMessage = $script:localizedData.ErrorWebsiteStateFailure -f $MockParameters.Name, 'ScriptHalted'
                    $Exception = New-Object `
                        -TypeName System.InvalidOperationException `
                        -ArgumentList $ErrorMessage
                    $ErrorRecord = New-Object `
                        -TypeName System.Management.Automation.ErrorRecord `
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

                Mock -CommandName Set-Authentication

                Mock -CommandName Stop-Website

                Mock -CommandName Test-AuthenticationEnabled { return $true } `
                    -ParameterFilter { ($Type -eq 'Anonymous') }

                Mock -CommandName Test-AuthenticationEnabled { return $false } `
                    -ParameterFilter { ($Type -eq 'Basic') }

                Mock -CommandName Test-AuthenticationEnabled { return $false } `
                    -ParameterFilter { ($Type -eq 'Digest') }

                Mock -CommandName Test-AuthenticationEnabled { return $false } `
                    -ParameterFilter { ($Type -eq 'Windows') }

                Set-TargetResource @MockParameters

                It 'Should call all the mocks' {
                    Assert-MockCalled -CommandName Set-ItemProperty -Exactly 13
                    Assert-MockCalled -CommandName Add-WebConfiguration -Exactly 1
                    Assert-MockCalled -CommandName Test-WebsiteBinding -Exactly 1
                    Assert-MockCalled -CommandName Update-WebsiteBinding -Exactly 1
                    Assert-MockCalled -CommandName Update-DefaultPage -Exactly 1
                    Assert-MockCalled -CommandName Set-Authentication -Exactly 4
                    Assert-MockCalled -CommandName Stop-Website -Exactly 1
                }
            }

            Context 'Website does not exist' {
                $MockWebsite = @{
                    Name                     = 'MockName'
                    PhysicalPath             = 'C:\NonExistent'
                    State                    = 'Started'
                    ServerAutoStart          = $true
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

                Mock -CommandName Set-Authentication

                Mock -CommandName Start-Website

                Mock -CommandName Test-AuthenticationEnabled { return $true } `
                    -ParameterFilter { ($Type -eq 'Anonymous') }

                Mock -CommandName Test-AuthenticationEnabled { return $false } `
                    -ParameterFilter { ($Type -eq 'Basic') }

                Mock -CommandName Test-AuthenticationEnabled { return $false } `
                    -ParameterFilter { ($Type -eq 'Digest') }

                Mock -CommandName Test-AuthenticationEnabled { return $false } `
                    -ParameterFilter { ($Type -eq 'Windows') }

                Set-TargetResource @MockParameters

                It 'Should call all the mocks' {
                     Assert-MockCalled -CommandName New-Website -Exactly 1
                     Assert-MockCalled -CommandName Stop-Website -Exactly 1
                     Assert-MockCalled -CommandName Test-WebsiteBinding -Exactly 1
                     Assert-MockCalled -CommandName Update-WebsiteBinding -Exactly 1
                     Assert-MockCalled -CommandName Get-Item -Exactly 0
                     Assert-MockCalled -CommandName Set-Item -Exactly 0
                     Assert-MockCalled -CommandName Set-ItemProperty -Exactly 10
                     Assert-MockCalled -CommandName Add-WebConfiguration -Exactly 1
                     Assert-MockCalled -CommandName Update-DefaultPage -Exactly 1
                     Assert-MockCalled -CommandName Confirm-UniqueBinding -Exactly 1
                     Assert-MockCalled -CommandName Confirm-UniqueServiceAutoStartProviders -Exactly 1
                     Assert-MockCalled -CommandName Set-Authentication -Exactly 4
                     Assert-MockCalled -CommandName Start-Website -Exactly 1
                }
            }

            Context 'Website has unchanged logging directory' {
                $MockWebsite = @{
                    Name                 = 'MockName'
                    PhysicalPath         = 'C:\NonExistent'
                    State                = 'Started'
                    ServerAutoStart      = $true
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

                Mock -CommandName Set-Authentication

                Mock -CommandName Test-AuthenticationEnabled { return $true } `
                    -ParameterFilter { ($Type -eq 'Anonymous') }

                Mock -CommandName Test-AuthenticationEnabled { return $false } `
                    -ParameterFilter { ($Type -eq 'Basic') }

                Mock -CommandName Test-AuthenticationEnabled { return $false } `
                    -ParameterFilter { ($Type -eq 'Digest') }

                Mock -CommandName Test-AuthenticationEnabled { return $false } `
                    -ParameterFilter { ($Type -eq 'Windows') }

                Set-TargetResource @MockParameters

                It 'Should call all the mocks' {
                     Assert-MockCalled -CommandName Test-WebsiteBinding -Exactly 1
                     Assert-MockCalled -CommandName Update-WebsiteBinding -Exactly 1
                     Assert-MockCalled -CommandName Get-Item -Exactly 1
                     Assert-MockCalled -CommandName Set-Item -Exactly 1
                     Assert-MockCalled -CommandName Set-ItemProperty -Exactly 8
                     Assert-MockCalled -CommandName Set-ItemProperty -ParameterFilter { $Name -eq 'LogFile.directory' } -Exactly 0
                     Assert-MockCalled -CommandName Add-WebConfiguration -Exactly 1
                     Assert-MockCalled -CommandName Update-DefaultPage -Exactly 1
                     Assert-MockCalled -CommandName Confirm-UniqueServiceAutoStartProviders -Exactly 1
                     Assert-MockCalled -CommandName Set-Authentication -Exactly 4
                }
            }

            Context 'Website has changed logging directory' {
                $MockWebsite = @{
                    Name                 = 'MockName'
                    PhysicalPath         = 'C:\NonExistent'
                    State                = 'Started'
                    ServerAutoStart      = $true
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

                Mock -CommandName Set-Authentication

                Mock -CommandName Test-AuthenticationEnabled { return $true } `
                    -ParameterFilter { ($Type -eq 'Anonymous') }

                Mock -CommandName Test-AuthenticationEnabled { return $false } `
                    -ParameterFilter { ($Type -eq 'Basic') }

                Mock -CommandName Test-AuthenticationEnabled { return $false } `
                    -ParameterFilter { ($Type -eq 'Digest') }

                Mock -CommandName Test-AuthenticationEnabled { return $false } `
                    -ParameterFilter { ($Type -eq 'Windows') }

                Set-TargetResource @MockParameters

                It 'Should call all the mocks' {
                     Assert-MockCalled -CommandName Test-WebsiteBinding -Exactly 1
                     Assert-MockCalled -CommandName Update-WebsiteBinding -Exactly 1
                     Assert-MockCalled -CommandName Get-Item -Exactly 1
                     Assert-MockCalled -CommandName Set-Item -Exactly 1
                     Assert-MockCalled -CommandName Set-ItemProperty -Exactly 9
                     Assert-MockCalled -CommandName Set-ItemProperty -ParameterFilter { $Name -eq 'LogFile.directory' } -Exactly 1
                     Assert-MockCalled -CommandName Add-WebConfiguration -Exactly 1
                     Assert-MockCalled -CommandName Update-DefaultPage -Exactly 1
                     Assert-MockCalled -CommandName Confirm-UniqueServiceAutoStartProviders -Exactly 1
                     Assert-MockCalled -CommandName Set-Authentication -Exactly 4
                }
            }

            Context 'New website cannot be started due to a binding conflict' {
                $MockWebsite = @{
                    Name                     = 'MockName'
                    PhysicalPath             = 'C:\NonExistent'
                    State                    = 'Started'
                    ServerAutoStart          = $true
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
                    $ErrorId = 'WebsiteBindingConflictOnStart'
                    $ErrorCategory = [System.Management.Automation.ErrorCategory]::InvalidResult
                    $ErrorMessage = $script:localizedData.ErrorWebsiteBindingConflictOnStart -f $MockParameters.Name
                    $Exception = New-Object -TypeName System.InvalidOperationException `
                        -ArgumentList $ErrorMessage
                    $ErrorRecord = New-Object -TypeName System.Management.Automation.ErrorRecord `
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

                It 'should throw the correct error' {
                    $ErrorId = 'WebsiteCreationFailure'
                    $ErrorCategory = [System.Management.Automation.ErrorCategory]::InvalidOperation
                    $ErrorMessage = $script:localizedData.ErrorWebsiteCreationFailure -f $MockParameters.Name, 'ScriptHalted'
                    $Exception = New-Object `
                        -TypeName System.InvalidOperationException `
                        -ArgumentList $ErrorMessage
                    $ErrorRecord = New-Object `
                        -TypeName System.Management.Automation.ErrorRecord `
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

                Mock -CommandName Get-WebConfigurationProperty `
                    -MockWith { return $MockLogOutput.logExtFileFlags }

                Set-TargetResource -Ensure $MockParameters.Ensure `
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

        Describe "how $script:dscResourceName\Set-TargetResource responds to Ensure = 'Absent'" {
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

                $ErrorId = 'WebsiteRemovalFailure'
                $ErrorCategory = [System.Management.Automation.ErrorCategory]::InvalidOperation
                $ErrorMessage = $script:localizedData.ErrorWebsiteRemovalFailure -f $MockParameters.Name, 'ScriptHalted'
                $Exception = New-Object `
                    -TypeName System.InvalidOperationException `
                    -ArgumentList $ErrorMessage
                $ErrorRecord = New-Object `
                    -TypeName System.Management.Automation.ErrorRecord `
                    -ArgumentList $Exception, $ErrorId, $ErrorCategory, $null

                {Set-TargetResource @MockParameters} | Should Throw $ErrorRecord
            }
        }

        Describe "$script:dscResourceName\Confirm-UniqueBinding" {
            Context 'Returns false when LogFlags are incorrect' {

                $MockLogOutput = @{
                    logExtFileFlags   = 'Date','Time','ClientIP','UserName','ServerIP','Method','UriStem','UriQuery','HttpStatus','Win32Status','TimeTaken','ServerPort','UserAgent','Referer','HttpSubStatus'
                }

                $MockWebsite = @{
                    Name                 = 'MockName'
                    LogFile              = $MockLogOutput
                }

                 Mock -CommandName Get-WebSite `
                    -MockWith { return $MockWebsite }

                $result = Compare-LogFlags -Name 'MockWebsite' -LogFlags 'Date','Time','ClientIP','UserName','ServerIP'

                It 'Should return false' {
                    $result | Should be $false
                }

            }

            Context 'Returns true when LogFlags are correct' {

                $MockLogOutput = @{
                    logExtFileFlags   = 'Date','Time','ClientIP','UserName','ServerIP'
                }

                $MockWebsite = @{
                    Name                 = 'MockName'
                    LogFile              = $MockLogOutput
                }

                 Mock -CommandName Get-WebSite `
                    -MockWith { return $MockWebsite }

                $result = Compare-LogFlags -Name $MockWebsite.Name -LogFlags 'Date','Time','ClientIP','UserName','ServerIP'

                It 'Should return true' {
                    $result | Should be $true
                }

            }

        }

        Describe "$script:dscResourceName\Confirm-UniqueBinding" {
            $MockParameters = @{
                Name = 'MockSite'
            }

            Context 'Website does not exist' {
                Mock -CommandName Get-Website
                It 'should throw the correct error' {
                    $ErrorId = 'WebsiteNotFound'
                    $ErrorCategory = [System.Management.Automation.ErrorCategory]::InvalidResult
                    $ErrorMessage = $script:localizedData.ErrorWebsiteNotFound -f $MockParameters.Name
                    $Exception = New-Object `
                        -TypeName System.InvalidOperationException `
                        -ArgumentList $ErrorMessage
                    $ErrorRecord = New-Object `
                        -TypeName System.Management.Automation.ErrorRecord `
                        -ArgumentList $Exception, $ErrorId, $ErrorCategory, $null

                    { Confirm-UniqueBinding -Name $MockParameters.Name } | Should Throw $ErrorRecord
                }
            }

            Context 'Expected behavior' {
                $GetWebsiteOutput = @(
                    @{
                        Name = $MockParameters.Name
                        State = 'Stopped'
                        Bindings = @{
                            Collection = @(
                                @{ protocol = 'http'; bindingInformation = '*:80:' }
                            )
                        }
                    }
                )

                Mock -CommandName Get-Website -MockWith { return $GetWebsiteOutput }

                It 'should not throw an error' {
                    { Confirm-UniqueBinding -Name $MockParameters.Name } | Should Not Throw
                }

                It 'should call Get-Website twice' {
                    Assert-MockCalled -CommandName Get-Website -Exactly 2
                }
            }

            Context 'Bindings are unique' {
                $GetWebsiteOutput = @(
                    @{
                        Name = $MockParameters.Name
                        State = 'Stopped'
                        Bindings = @{
                            Collection = @(
                                @{ protocol = 'http'; bindingInformation = '*:80:' }
                                @{ protocol = 'http'; bindingInformation = '*:8080:' }
                            )
                        }
                    }
                    @{
                        Name = 'MockSite2'
                        State = 'Stopped'
                        Bindings = @{
                            Collection = @(
                                @{ protocol = 'http'; bindingInformation = '*:81:' }
                            )
                        }
                    }
                    @{
                        Name = 'MockSite3'
                        State = 'Started'
                        Bindings = @{
                            Collection = @(
                                @{ protocol = 'http'; bindingInformation = '*:8081:' }
                            )
                        }
                    }
                )

                Mock -CommandName Get-Website -MockWith {return $GetWebsiteOutput}

                It 'should return True' {
                    Confirm-UniqueBinding -Name $MockParameters.Name | Should Be $true
                }
            }

            Context 'Bindings are not unique' {
                $GetWebsiteOutput = @(
                    @{
                        Name = $MockParameters.Name
                        State = 'Stopped'
                        Bindings = @{
                            Collection = @(
                                @{ protocol = 'http'; bindingInformation = '*:80:' }
                                @{ protocol = 'http'; bindingInformation = '*:8080:' }
                            )
                        }
                    }
                    @{
                        Name = 'MockSite2'
                        State = 'Started'
                        Bindings = @{
                            Collection = @(
                                @{ protocol = 'http'; bindingInformation = '*:80:' }
                            )
                        }
                    }
                    @{
                        Name = 'MockSite3'
                        State = 'Started'
                        Bindings = @{
                            Collection = @(
                                @{ protocol = 'http'; bindingInformation = '*:8080:' }
                            )
                        }
                    }
                )

                Mock -CommandName Get-Website -MockWith {return $GetWebsiteOutput}

                It 'should return False' {
                    Confirm-UniqueBinding -Name $MockParameters.Name | Should Be $false
                }
            }

            Context 'One of the bindings is assigned to another website that is Stopped' {
                $GetWebsiteOutput = @(
                    @{
                        Name = $MockParameters.Name
                        State = 'Stopped'
                        Bindings = @{
                            Collection = @(
                                @{ protocol = 'http'; bindingInformation = '*:80:' }
                                @{ protocol = 'http'; bindingInformation = '*:8080:' }
                            )
                        }
                    }
                    @{
                        Name = 'MockSite2'
                        State = 'Stopped'
                        Bindings = @{
                            Collection = @(
                                @{ protocol = 'http'; bindingInformation = '*:80:' }
                            )
                        }
                    }
                )

                Mock -CommandName Get-Website -MockWith { return $GetWebsiteOutput }

                It 'should return True if stopped websites are excluded' {
                    Confirm-UniqueBinding -Name $MockParameters.Name -ExcludeStopped | Should Be $true
                }

                It 'should return False if stopped websites are not excluded' {
                    Confirm-UniqueBinding -Name $MockParameters.Name | Should Be $false
                }
            }

            Context 'One of the bindings is assigned to another website that is Started' {
                $GetWebsiteOutput = @(
                    @{
                        Name = $MockParameters.Name
                        State = 'Stopped'
                        Bindings = @{
                            Collection = @(
                                @{ protocol = 'http'; bindingInformation = '*:80:' }
                                @{ protocol = 'http'; bindingInformation = '*:8080:' }
                            )
                        }
                    }
                    @{
                        Name = 'MockSite2'
                        State = 'Stopped'
                        Bindings = @{
                            Collection = @(
                                @{ protocol = 'http';  bindingInformation = '*:80:' }
                            )
                        }
                    }
                    @{
                        Name = 'MockSite3'
                        State = 'Started'
                        Bindings = @{
                            Collection = @(
                                @{ protocol = 'http'; bindingInformation = '*:80:' }
                            )
                        }
                    }
                )

                Mock -CommandName Get-Website -MockWith { return $GetWebsiteOutput }

                It 'should return False' {
                    Confirm-UniqueBinding -Name $MockParameters.Name -ExcludeStopped | Should Be $false
                }
            }
        }

        Describe "$script:dscResourceName\Confirm-UniqueServiceAutoStartProviders" {
            $MockParameters = @{
                Name = 'MockServiceAutoStartProvider'
                Type = 'MockApplicationType'
            }

            Context 'Expected behavior' {
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

                Mock -CommandName Get-WebConfiguration -MockWith {return $MockWebConfiguration}

                It 'should not throw an error' {
                    { Confirm-UniqueServiceAutoStartProviders `
                        -ServiceAutoStartProvider $MockParameters.Name `
                        -ApplicationType $MockParameters.Type } | Should Not Throw
                }

                It 'should call Get-WebConfiguration once' {
                    Assert-MockCalled -CommandName Get-WebConfiguration -Exactly 1
                }
            }

            Context 'Conflicting Global Property' {
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

                Mock -CommandName Get-WebConfiguration -MockWith { return $MockWebConfiguration }

                It 'should return Throw' {
                    $ErrorId = 'ServiceAutoStartProviderFailure'
                    $ErrorCategory = [System.Management.Automation.ErrorCategory]::InvalidOperation
                    $ErrorMessage = $script:localizedData.ErrorWebsiteTestAutoStartProviderFailure, 'ScriptHalted'
                    $Exception = New-Object `
                                    -TypeName System.InvalidOperationException `
                                    -ArgumentList $ErrorMessage
                    $ErrorRecord = New-Object `
                                    -TypeName System.Management.Automation.ErrorRecord `
                                    -ArgumentList $Exception, $ErrorId, $ErrorCategory, $null

                    { Confirm-UniqueServiceAutoStartProviders `
                        -ServiceAutoStartProvider $MockParameters.Name `
                        -ApplicationType 'MockApplicationType2'} | Should Throw $ErrorRecord
                }
            }

            Context 'ServiceAutoStartProvider does not exist' {
                $MockWebConfiguration = @(
                    @{
                        Name = ''
                        Type = ''
                    }
                )

                Mock -CommandName Get-WebConfiguration  -MockWith { return $MockWebConfiguration }

                It 'should return False' {
                    Confirm-UniqueServiceAutoStartProviders `
                        -ServiceAutoStartProvider $MockParameters.Name `
                        -ApplicationType $MockParameters.Type | Should Be $false
                }
            }

            Context 'ServiceAutoStartProvider does exist' {
                $MockWebConfiguration = @(
                    @{
                        SectionPath = 'MockSectionPath'
                        PSPath      = 'MockPSPath'
                        Collection  = @(
                            [PSCustomObject] @{
                                Name = 'MockServiceAutoStartProvider' ;
                                Type = 'MockApplicationType'
                            }
                        )
                    }
                )

                Mock -CommandName Get-WebConfiguration -MockWith { return $MockWebConfiguration }

                It 'should return True' {
                    Confirm-UniqueServiceAutoStartProviders `
                        -ServiceAutoStartProvider $MockParameters.Name `
                        -ApplicationType $MockParameters.Type | Should Be $true
                }
            }
        }

        Describe "$script:dscResourceName\ConvertTo-CimBinding" {
            Context 'IPv4 address is passed and the protocol is http' {
                $MockWebBinding = @{
                    bindingInformation = '127.0.0.1:80:MockHostName'
                    protocol           = 'http'
                }

                $Result = ConvertTo-CimBinding -InputObject $MockWebBinding

                It 'should return the IPv4 Address' {
                    $Result.IPAddress | Should Be '127.0.0.1'
                }

                It 'should return the Protocol' {
                    $Result.Protocol | Should Be 'http'
                }

                It 'should return the HostName' {
                    $Result.HostName | Should Be 'MockHostName'
                }

                It 'should return the Port' {
                    $Result.Port | Should Be '80'
                }
            }

            Context 'IPv6 address is passed and the protocol is http' {
                $MockWebBinding =  @{
                    bindingInformation = '[0:0:0:0:0:0:0:1]:80:MockHostName'
                    protocol           = 'http'
                }

                $Result = ConvertTo-CimBinding -InputObject $MockWebBinding

                It 'should return the IPv6 Address' {
                    $Result.IPAddress | Should Be '0:0:0:0:0:0:0:1'
                }

                It 'should return the Protocol' {
                    $Result.Protocol | Should Be 'http'
                }

                It 'should return the HostName' {
                    $Result.HostName | Should Be 'MockHostName'
                }

                It 'should return the Port' {
                    $Result.Port | Should Be '80'
                }
            }

            Context 'IPv4 address with SSL certificate is passed' {
                $MockWebBinding =  @{
                    bindingInformation   = '127.0.0.1:443:MockHostName'
                    protocol             = 'https'
                    certificateHash      = '1D3324C6E2F7ABC794C9CB6CA426B8D0F81045CD'
                    certificateStoreName = 'MY'
                    sslFlags             = '1'
                }

                $Result = ConvertTo-CimBinding -InputObject $MockWebBinding

                It 'should return the IPv4 Address' {
                    $Result.IPAddress | Should Be '127.0.0.1'
                }

                It 'should return the Protocol' {
                    $Result.Protocol | Should Be 'https'
                }

                It 'should return the HostName' {
                    $Result.HostName | Should Be 'MockHostName'
                }

                It 'should return the Port' {
                    $Result.Port | Should Be '443'
                }

                It 'should return the CertificateThumbprint' {
                    $Result.CertificateThumbprint | Should Be '1D3324C6E2F7ABC794C9CB6CA426B8D0F81045CD'
                }

                It 'should return the CertificateStoreName' {
                    $Result.CertificateStoreName | Should Be 'MY'
                }

                It 'should return the SslFlags' {
                    $Result.SslFlags | Should Be '1'
                }
            }

            Context 'IPv6 address with SSL certificate is passed' {
                $MockWebBinding = @{
                    bindingInformation   = '[0:0:0:0:0:0:0:1]:443:MockHostName'
                    protocol             = 'https'
                    certificateHash      = '1D3324C6E2F7ABC794C9CB6CA426B8D0F81045CD'
                    certificateStoreName = 'MY'
                    sslFlags             = '1'
                }

                $Result = ConvertTo-CimBinding -InputObject $MockWebBinding

                It 'should return the IPv6 Address' {
                    $Result.IPAddress | Should Be '0:0:0:0:0:0:0:1'
                }

                It 'should return the Protocol' {
                    $Result.Protocol | Should Be 'https'
                }

                It 'should return the HostName' {
                    $Result.HostName | Should Be 'MockHostName'
                }

                It 'should return the Port' {
                    $Result.Port | Should Be '443'
                }

                It 'should return the CertificateThumbprint' {
                    $Result.CertificateThumbprint | Should Be '1D3324C6E2F7ABC794C9CB6CA426B8D0F81045CD'
                }

                It 'should return the CertificateStoreName' {
                    $Result.CertificateStoreName | Should Be 'MY'
                }

                It 'should return the SslFlags' {
                    $Result.SslFlags | Should Be '1'
                }
            }
        }

        Describe "$script:dscResourceName\ConvertTo-WebBinding" -Tag 'ConvertTo' {
            Context 'Expected behaviour' {
                $MockBindingInfo = @(
                    New-CimInstance `
                    -ClassName MSFT_xWebBindingInformation `
                    -Namespace root/microsoft/Windows/DesiredStateConfiguration `
                    -Property @{
                        Protocol              = 'https'
                        BindingInformation    = 'NonsenseString'
                        IPAddress             = '*'
                        Port                  = 443
                        HostName              = 'web01.contoso.com'
                        CertificateThumbprint = 'C65CE51E20C523DEDCE979B9922A0294602D9D5C'
                        CertificateStoreName  = 'WebHosting'
                        SslFlags              = 1
                    } -ClientOnly
                )

                $Result = ConvertTo-WebBinding -InputObject $MockBindingInfo

                It 'should return the correct Protocol value' {
                    $Result.protocol | Should Be 'https'
                }

                It 'should return the correct BindingInformation value' {
                    $Result.bindingInformation | Should Be '*:443:web01.contoso.com'
                }

                It 'should return the correct CertificateHash value' {
                    $Result.certificateHash | Should Be 'C65CE51E20C523DEDCE979B9922A0294602D9D5C'
                }

                It 'should return the correct CertificateStoreName value' {
                    $Result.certificateStoreName | Should Be 'WebHosting'
                }

                It 'should return the correct SslFlags value' {
                    $Result.sslFlags | Should Be 1
                }
            }

            Context 'IP address is invalid' {
                $MockBindingInfo = @(
                    New-CimInstance `
                        -ClassName MSFT_xWebBindingInformation `
                        -Namespace root/microsoft/Windows/DesiredStateConfiguration `
                        -Property @{
                            Protocol  = 'http'
                            IPAddress = '127.0.0.256'
                        } -ClientOnly
                )

                It 'should throw the correct error' {
                    $ErrorId = 'WebBindingInvalidIPAddress'
                    $ErrorCategory = [System.Management.Automation.ErrorCategory]::InvalidArgument
                    $ErrorMessage = $script:localizedData.ErrorWebBindingInvalidIPAddress -f $MockBindingInfo.IPAddress, 'Exception calling "Parse" with "1" argument(s): "An invalid IP address was specified."'
                    $Exception = New-Object `
                        -TypeName System.InvalidOperationException `
                        -ArgumentList $ErrorMessage
                    $ErrorRecord = New-Object `
                        -TypeName System.Management.Automation.ErrorRecord `
                        -ArgumentList $Exception, $ErrorId, $ErrorCategory, $null

                    { ConvertTo-WebBinding -InputObject $MockBindingInfo } | Should Throw $ErrorRecord
                }
            }

            Context 'Port is not specified' {
                It 'should set the default HTTP port' {
                    $MockBindingInfo = @(
                        New-CimInstance `
                            -ClassName MSFT_xWebBindingInformation `
                            -Namespace root/microsoft/Windows/DesiredStateConfiguration `
                            -ClientOnly `
                            -Property @{
                                Protocol = 'http'
                            }
                    )

                    $Result = ConvertTo-WebBinding -InputObject $MockBindingInfo
                    $Result.bindingInformation | Should Be '*:80:'
                }

                It 'should set the default HTTPS port' {
                    $MockBindingInfo = @(
                        New-CimInstance `
                        -ClassName MSFT_xWebBindingInformation `
                        -Namespace root/microsoft/Windows/DesiredStateConfiguration `
                        -ClientOnly `
                        -Property @{
                            Protocol              = 'https'
                            CertificateThumbprint = 'C65CE51E20C523DEDCE979B9922A0294602D9D5C'
                        }
                    )

                    $Result = ConvertTo-WebBinding -InputObject $MockBindingInfo
                    $Result.bindingInformation | Should Be '*:443:'
                }
            }

            Context 'Port is invalid' {
                $MockBindingInfo = @(
                    New-CimInstance `
                    -ClassName MSFT_xWebBindingInformation `
                    -Namespace root/microsoft/Windows/DesiredStateConfiguration `
                    -Property @{
                        Protocol = 'http'
                        Port     = 0
                    } -ClientOnly
                )

                It 'should throw the correct error' {
                    $ErrorId = 'WebBindingInvalidPort'
                    $ErrorCategory = [System.Management.Automation.ErrorCategory]::InvalidArgument
                    $ErrorMessage = $script:localizedData.ErrorWebBindingInvalidPort -f $MockBindingInfo.Port
                    $Exception = New-Object `
                        -TypeName System.InvalidOperationException `
                        -ArgumentList $ErrorMessage
                    $ErrorRecord = New-Object `
                        -TypeName System.Management.Automation.ErrorRecord `
                        -ArgumentList $Exception, $ErrorId, $ErrorCategory, $null

                    {ConvertTo-WebBinding -InputObject $MockBindingInfo} | Should Throw $ErrorRecord
                }
            }

            Context 'Protocol is HTTPS and CertificateThumbprint contains the Left-to-Right Mark character' {
                $MockThumbprint = 'C65CE51E20C523DEDCE979B9922A0294602D9D5C'

                $AsciiEncoding = [System.Text.Encoding]::ASCII
                $UnicodeEncoding = [System.Text.Encoding]::Unicode

                $AsciiBytes = $AsciiEncoding.GetBytes($MockThumbprint)
                $UnicodeBytes = [System.Text.Encoding]::Convert($AsciiEncoding, $UnicodeEncoding, $AsciiBytes)
                $LrmCharBytes = $UnicodeEncoding.GetBytes([Char]0x200E)

                # Prepend the Left-to-Right Mark character to CertificateThumbprint
                $MockThumbprintWithLrmChar = $UnicodeEncoding.GetString(($LrmCharBytes + $UnicodeBytes))

                $MockBindingInfo = @(
                    New-CimInstance -ClassName MSFT_xWebBindingInformation `
                    -Namespace root/microsoft/Windows/DesiredStateConfiguration `
                    -Property @{
                        Protocol              = 'https'
                        CertificateThumbprint = $MockThumbprintWithLrmChar
                        CertificateStoreName  = 'MY'
                    } -ClientOnly
                )

                It 'Input - CertificateThumbprint should contain the Left-to-Right Mark character' {
                    $MockBindingInfo[0].CertificateThumbprint -match '^\u200E' | Should Be $true
                }

                It 'Output - certificateHash should not contain the Left-to-Right Mark character' {
                    $Result = ConvertTo-WebBinding -InputObject $MockBindingInfo
                    $Result.certificateHash -match '^\u200E' | Should Be $false
                }
            }

            Context 'Protocol is HTTPS and CertificateThumbprint is not specified' {
                $MockBindingInfo = @(
                    New-CimInstance -ClassName MSFT_xWebBindingInformation `
                    -Namespace root/microsoft/Windows/DesiredStateConfiguration `
                    -Property @{
                        Protocol              = 'https'
                        CertificateThumbprint = ''
                    } -ClientOnly
                )

                It 'should throw the correct error' {
                    $ErrorId = 'WebBindingMissingCertificateThumbprint'
                    $ErrorCategory = [System.Management.Automation.ErrorCategory]::InvalidArgument
                    $ErrorMessage = $script:localizedData.ErrorWebBindingMissingCertificateThumbprint -f $MockBindingInfo.Protocol
                    $Exception = New-Object `
                        -TypeName System.InvalidOperationException `
                        -ArgumentList $ErrorMessage
                    $ErrorRecord = New-Object `
                        -TypeName System.Management.Automation.ErrorRecord `
                        -ArgumentList $Exception, $ErrorId, $ErrorCategory, $null
                    { ConvertTo-WebBinding -InputObject $MockBindingInfo } | Should Throw $ErrorRecord
                }
            }

            Context 'Protocol is HTTPS and CertificateSubject is specified' {
                $MockBindingInfo = @(
                    New-CimInstance -ClassName MSFT_xWebBindingInformation `
                    -Namespace root/microsoft/Windows/DesiredStateConfiguration `
                    -Property @{
                        Protocol              = 'https'
                        CertificateSubject    = 'TestCertificate'
                    } -ClientOnly
                )

                Mock Find-Certificate -MockWith {
                    return [PSCustomObject]@{
                        Thumbprint = 'C65CE51E20C523DEDCE979B9922A0294602D9D5C'
                    }
                }

                It 'should not throw an error' {
                   { ConvertTo-WebBinding -InputObject $MockBindingInfo } | Should Not Throw
                }
                It 'should return the correct thumbprint' {
                    $Result = ConvertTo-WebBinding -InputObject $MockBindingInfo
                    $Result.certificateHash | Should Be 'C65CE51E20C523DEDCE979B9922A0294602D9D5C'
                }
                It 'Should call Find-Certificate mock' {
                    Assert-MockCalled -CommandName Find-Certificate -Times 1
                }
            }

            Context 'Protocol is HTTPS and full CN of CertificateSubject is specified' {
                $MockBindingInfo = @(
                    New-CimInstance -ClassName MSFT_xWebBindingInformation `
                    -Namespace root/microsoft/Windows/DesiredStateConfiguration `
                    -Property @{
                        Protocol              = 'https'
                        CertificateSubject    = 'CN=TestCertificate'
                    } -ClientOnly
                )

                Mock Find-Certificate -MockWith {
                    return [PSCustomObject]@{
                        Thumbprint = 'C65CE51E20C523DEDCE979B9922A0294602D9D5C'
                    }
                }

                It 'should not throw an error' {
                   { ConvertTo-WebBinding -InputObject $MockBindingInfo } | Should Not Throw
                }
                It 'should return the correct thumbprint' {
                    $Result = ConvertTo-WebBinding -InputObject $MockBindingInfo
                    $Result.certificateHash | Should Be 'C65CE51E20C523DEDCE979B9922A0294602D9D5C'
                }
                It 'Should call Find-Certificate mock' {
                    Assert-MockCalled -CommandName Find-Certificate -Times 1
                }
            }

            Context 'Protocol is HTTPS and CertificateSubject is specified. Multiple matching certificates' {
                $MockBindingInfo = @(
                    New-CimInstance -ClassName MSFT_xWebBindingInformation `
                    -Namespace root/microsoft/Windows/DesiredStateConfiguration `
                    -Property @{
                        Protocol              = 'https'
                        CertificateSubject    = 'TestCertificate'
                    } -ClientOnly
                )

                Mock Find-Certificate -MockWith {
                    return @(
                        [PSCustomObject]@{
                            Thumbprint = 'C65CE51E20C523DEDCE979B9922A0294602D9D5C'
                        },
                        [PSCustomObject]@{
                            Thumbprint = '28B88504F609F685B9A49C8F0EC49EDA1337CAFE'
                        }
                    )
                }

                It 'should not throw an error' {
                   { ConvertTo-WebBinding -InputObject $MockBindingInfo } | Should Not Throw
                }
                It 'should return the correct thumbprint' {
                    $Result = ConvertTo-WebBinding -InputObject $MockBindingInfo
                    $Result.certificateHash | Should Be 'C65CE51E20C523DEDCE979B9922A0294602D9D5C'
                }
                It 'Should call Find-Certificate mock' {
                    Assert-MockCalled -CommandName Find-Certificate -Times 1
                }
            }

            Context 'Protocol is HTTPS and invalid CertificateSubject is specified' {
                $MockBindingInfo = @(
                    New-CimInstance -ClassName MSFT_xWebBindingInformation `
                    -Namespace root/microsoft/Windows/DesiredStateConfiguration `
                    -Property @{
                        Protocol              = 'https'
                        CertificateSubject    = 'TestCertificate'
                        CertificateStoreName  = 'MY'
                    } -ClientOnly
                )

                Mock Find-Certificate

                It 'should throw the correct error' {
                    $CertificateSubject = "CN=$($MockBindingInfo.CertificateSubject)"
                    $ErrorId = 'WebBindingInvalidCertificateSubject'
                    $ErrorCategory = [System.Management.Automation.ErrorCategory]::InvalidArgument
                    $ErrorMessage = $script:localizedData.ErrorWebBindingInvalidCertificateSubject -f $CertificateSubject, $MockBindingInfo.CertificateStoreName
                    $Exception = New-Object `
                        -TypeName System.InvalidOperationException `
                        -ArgumentList $ErrorMessage
                    $ErrorRecord = New-Object `
                        -TypeName System.Management.Automation.ErrorRecord `
                        -ArgumentList $Exception, $ErrorId, $ErrorCategory, $null
                    { ConvertTo-WebBinding -InputObject $MockBindingInfo } | Should Throw $ErrorRecord
                }
            }

            Context 'Protocol is HTTPS and CertificateStoreName is not specified' {
                $MockBindingInfo = @(
                    New-CimInstance -ClassName MSFT_xWebBindingInformation `
                    -Namespace root/microsoft/Windows/DesiredStateConfiguration `
                    -Property @{
                        Protocol              = 'https'
                        CertificateThumbprint = 'C65CE51E20C523DEDCE979B9922A0294602D9D5C'
                        CertificateStoreName  = ''
                    } -ClientOnly
                )

                It 'should set CertificateStoreName to the default value' {
                    $Result = ConvertTo-WebBinding -InputObject $MockBindingInfo
                    $Result.certificateStoreName | Should Be 'MY'
                }
            }

            Context 'Protocol is HTTPS and HostName is not specified for use with Server Name Indication' {
                $MockBindingInfo = @(
                    New-CimInstance -ClassName MSFT_xWebBindingInformation `
                    -Namespace root/microsoft/Windows/DesiredStateConfiguration `
                    -Property @{
                        Protocol              = 'https'
                        IPAddress             = '*'
                        Port                  = 443
                        HostName              = ''
                        CertificateThumbprint = 'C65CE51E20C523DEDCE979B9922A0294602D9D5C'
                        CertificateStoreName  = 'WebHosting'
                        SslFlags              = 1
                    } -ClientOnly
                )

                It 'should throw the correct error' {
                    $ErrorId = 'WebBindingMissingSniHostName'
                    $ErrorCategory = [System.Management.Automation.ErrorCategory]::InvalidArgument
                    $ErrorMessage = $script:localizedData.ErrorWebBindingMissingSniHostName
                    $Exception = New-Object `
                        -TypeName System.InvalidOperationException `
                        -ArgumentList $ErrorMessage
                    $ErrorRecord = New-Object `
                        -TypeName System.Management.Automation.ErrorRecord `
                        -ArgumentList $Exception, $ErrorId, $ErrorCategory, $null

                    { ConvertTo-WebBinding -InputObject $MockBindingInfo } | Should Throw $ErrorRecord
                }
            }

            Context 'Protocol is not HTTPS' {
                $MockBindingInfo = @(
                    New-CimInstance -ClassName MSFT_xWebBindingInformation `
                    -Namespace root/microsoft/Windows/DesiredStateConfiguration `
                    -Property @{
                        Protocol              = 'http'
                        CertificateThumbprint = 'C65CE51E20C523DEDCE979B9922A0294602D9D5C'
                        CertificateStoreName  = 'WebHosting'
                        SslFlags              = 1
                    } -ClientOnly
                )

                It 'should ignore SSL properties' {
                    $Result = ConvertTo-WebBinding -InputObject $MockBindingInfo
                    $Result.certificateHash      | Should Be ''
                    $Result.certificateStoreName | Should Be ''
                    $Result.sslFlags             | Should Be 0
                }
            }

            Context 'Protocol is neither HTTP nor HTTPS' {
                It 'should throw an error if BindingInformation is not specified' {
                    $MockBindingInfo = @(
                        New-CimInstance -ClassName MSFT_xWebBindingInformation `
                        -Namespace root/microsoft/Windows/DesiredStateConfiguration `
                        -Property @{
                            Protocol           = 'net.tcp'
                            BindingInformation = ''
                        } -ClientOnly
                    )

                    $ErrorId = 'WebBindingMissingBindingInformation'
                    $ErrorCategory = [System.Management.Automation.ErrorCategory]::InvalidArgument
                    $ErrorMessage = $script:localizedData.ErrorWebBindingMissingBindingInformation -f $MockBindingInfo.Protocol
                    $Exception = New-Object `
                        -TypeName System.InvalidOperationException `
                        -ArgumentList $ErrorMessage
                    $ErrorRecord = New-Object `
                        -TypeName System.Management.Automation.ErrorRecord `
                        -ArgumentList $Exception, $ErrorId, $ErrorCategory, $null

                    { ConvertTo-WebBinding -InputObject $MockBindingInfo } | Should Throw $ErrorRecord
                }

                It 'should use BindingInformation and ignore IPAddress, Port, and HostName' {
                    $MockBindingInfo = @(
                        New-CimInstance -ClassName MSFT_xWebBindingInformation `
                        -Namespace root/microsoft/Windows/DesiredStateConfiguration `
                        -Property @{
                            Protocol           = 'net.tcp'
                            BindingInformation = '808:*'
                            IPAddress          = '127.0.0.1'
                            Port               = 80
                            HostName           = 'web01.contoso.com'
                        } -ClientOnly
                    )

                    $Result = ConvertTo-WebBinding -InputObject $MockBindingInfo
                    $Result.BindingInformation | Should Be '808:*'
                }
            }
        }

        Describe "$script:dscResourceName\Format-IPAddressString" {
            Context 'Input value is not valid' {
                It 'should throw an error' {
                    { Format-IPAddressString -InputString 'Invalid' } | Should Throw
                }
            }

            Context 'Input value is valid' {
                It 'should return "*" when input value is null' {
                    Format-IPAddressString -InputString $null | Should Be '*'
                }

                It 'should return "*" when input value is empty' {
                    Format-IPAddressString -InputString '' | Should Be '*'
                }

                It 'should return normalized IPv4 address' {
                    Format-IPAddressString -InputString '192.10' | Should Be '192.0.0.10'
                }

                It 'should return normalized IPv6 address enclosed in square brackets' {
                    Format-IPAddressString `
                        -InputString 'fe80:0000:0000:0000:0202:b3ff:fe1e:8329' | Should Be '[fe80::202:b3ff:fe1e:8329]'
                }
            }
        }

        Describe "$script:dscResourceName\Get-AuthenticationInfo" {
            $MockWebsite = @{
                Name                 = 'MockName'
                PhysicalPath         = 'C:\NonExistent'
                State                = 'Started'
                ServerAutoStart      = $true
                ApplicationPool      = 'MockPool'
                Bindings             = @{Collection = @($MockWebBinding)}
                EnabledProtocols     = 'http'
                ApplicationDefaults  = @{Collection = @($MockPreloadAndAutostartProviders)}
                Count                = 1
            }

           Context 'Expected behavior' {
                Mock -CommandName Get-WebConfigurationProperty -MockWith { return 'False'}

                It 'should not throw an error' {
                    { Get-AuthenticationInfo -site $MockWebsite.Name } | Should Not Throw
                }

                It 'should call Get-WebConfigurationProperty four times' {
                    Assert-MockCalled -CommandName Get-WebConfigurationProperty -Exactly 4
                }
            }

            Context 'AuthenticationInfo is false' {
                $MockWebConfiguration = @(
                    @{
                        Value = $false
                    }
                )

                Mock -CommandName Get-WebConfigurationProperty -MockWith { $MockWebConfiguration }

                It 'should all be false' {
                    $result = Get-AuthenticationInfo -site $MockWebsite.Name
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
                $MockWebConfiguration = @(
                    @{
                        Value = 'True'
                    }
                )

                Mock -CommandName Get-WebConfigurationProperty -MockWith { $MockWebConfiguration }

                It 'should all be true' {
                    $result = Get-AuthenticationInfo -site $MockWebsite.Name
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

        Describe "$script:dscResourceName\Set-Authentication" {
            Context 'Expected behavior' {
                $MockWebsite = @{
                    Name                 = 'MockName'
                    PhysicalPath         = 'C:\NonExistent'
                    State                = 'Started'
                    ServerAutoStart      = $true
                    ApplicationPool      = 'MockPool'
                    Bindings             = @{Collection = @($MockWebBinding)}
                    EnabledProtocols     = 'http'
                    ApplicationDefaults  = @{Collection = @($MockPreloadAndAutostartProviders)}
                    Count                = 1
                }

                Mock -CommandName Set-WebConfigurationProperty

                It 'should not throw an error' {
                    { Set-Authentication `
                        -Site $MockWebsite.Name `
                        -Type Basic `
                        -Enabled $true } | Should Not Throw
                }

                It 'should call Set-WebConfigurationProperty once' {
                    Assert-MockCalled -CommandName Set-WebConfigurationProperty -Exactly 1
                }
            }
        }

        Describe "$script:dscResourceName\Set-AuthenticationInfo" {
            Context 'Expected behavior' {
                $MockWebsite = @{
                    Name                 = 'MockName'
                    PhysicalPath         = 'C:\NonExistent'
                    State                = 'Started'
                    ServerAutoStart      = $true
                    ApplicationPool      = 'MockPool'
                    Bindings             = @{Collection = @($MockWebBinding)}
                    EnabledProtocols     = 'http'
                    ApplicationDefaults  = @{Collection = @($MockPreloadAndAutostartProviders)}
                    Count                = 1
                }

                Mock -CommandName Set-WebConfigurationProperty

                $AuthenticationInfo = New-CimInstance `
                    -ClassName MSFT_xWebApplicationAuthenticationInformation `
                    -ClientOnly `
                    -Property @{Anonymous='true';Basic='false';Digest='false';Windows='false'}

                It 'should not throw an error' {
                    { Set-AuthenticationInfo `
                        -Site $MockWebsite.Name `
                        -AuthenticationInfo $AuthenticationInfo } | Should Not Throw
                }

                It 'should call should call expected mocks' {
                        Assert-MockCalled -CommandName Set-WebConfigurationProperty -Exactly 4
                    }
            }
        }

        Describe "$script:dscResourceName\Test-AuthenticationEnabled" {
            $MockWebsite = @{
                Name                 = 'MockName'
                PhysicalPath         = 'C:\NonExistent'
                State                = 'Started'
                ServerAutoStart      = $true
                ApplicationPool      = 'MockPool'
                Bindings             = @{Collection = @($MockWebBinding)}
                EnabledProtocols     = 'http'
                ApplicationDefaults  = @{Collection = @($MockPreloadAndAutostartProviders)}
                Count                = 1
            }

            Context 'Expected behavior' {
                $MockWebConfiguration = @(
                    @{
                        Value = 'False'
                    }
                )

                Mock -CommandName Get-WebConfigurationProperty -MockWith {$MockWebConfiguration}

                It 'should not throw an error' {
                    { Test-AuthenticationEnabled `
                        -Site $MockWebsite.Name `
                        -Type 'Basic'} | Should Not Throw
                }

                It 'should call expected mocks' {
                    Assert-MockCalled -CommandName Get-WebConfigurationProperty -Exactly 1
                }
            }

            Context 'AuthenticationInfo is false' {
                $MockWebConfiguration = @(
                    @{
                        Value = 'False'
                    }
                )

                Mock -CommandName Get-WebConfigurationProperty -MockWith { $MockWebConfiguration }

                It 'should return false' {
                    Test-AuthenticationEnabled -Site $MockWebsite.Name -Type 'Basic' | Should be False
                }

                It 'should call expected mocks' {
                    Assert-MockCalled -CommandName Get-WebConfigurationProperty -Exactly 1
                }
            }

            Context 'AuthenticationInfo is true' {
                $MockWebConfiguration = @(
                    @{
                        Value = 'True'
                    }
                )

                Mock -CommandName Get-WebConfigurationProperty -MockWith { $MockWebConfiguration}

                It 'should all be true' {
                    Test-AuthenticationEnabled -Site $MockWebsite.Name -Type 'Basic' | Should be True
                }

                It 'should call expected mocks' {
                    Assert-MockCalled -CommandName Get-WebConfigurationProperty -Exactly 1
                }
            }
        }

        Describe "$script:dscResourceName\Test-AuthenticationInfo" {
            Mock -CommandName Get-WebConfigurationProperty -MockWith {$MockWebConfiguration}

            $MockWebsite = @{
                Name                 = 'MockName'
                PhysicalPath         = 'C:\NonExistent'
                State                = 'Started'
                ServerAutoStart      = $true
                ApplicationPool      = 'MockPool'
                Bindings             = @{Collection = @($MockWebBinding)}
                EnabledProtocols     = 'http'
                ApplicationDefaults  = @{Collection = @($MockPreloadAndAutostartProviders)}
                Count                = 1
            }

            $MockWebConfiguration = @(
                @{
                    Value = 'False'
                }
            )

            $AuthenticationInfo = New-CimInstance `
                -ClassName MSFT_xWebApplicationAuthenticationInformation `
                -ClientOnly `
                -Property @{ Anonymous='false'; Basic='true'; Digest='false'; Windows='false' }

            Context 'Expected behavior' {
                It 'should not throw an error' {
                    { Test-AuthenticationInfo `
                        -Site $MockWebsite.Name `
                        -AuthenticationInfo $AuthenticationInfo } | Should Not Throw
                }

                It 'should call expected mocks' {
                    Assert-MockCalled -CommandName Get-WebConfigurationProperty -Exactly 2
                }
            }

            Context 'Return False when AuthenticationInfo is not correct' {
                Mock -CommandName Get-WebConfigurationProperty -MockWith { $MockWebConfiguration}

                It 'should return false' {
                    Test-AuthenticationInfo -Site $MockWebsite.Name -AuthenticationInfo $AuthenticationInfo | Should be False
                }

                It 'should call expected mocks' {
                    Assert-MockCalled -CommandName Get-WebConfigurationProperty -Exactly 2
                }
            }

            Context 'Return True when AuthenticationInfo is correct' {
                $MockWebConfiguration = @(
                    @{
                        Value = 'True'
                    }
                )

                $AuthenticationInfo = New-CimInstance `
                    -ClassName MSFT_xWebApplicationAuthenticationInformation `
                    -ClientOnly `
                    -Property @{ Anonymous='true'; Basic='true'; Digest='true'; Windows='true' }

                Mock -CommandName Get-WebConfigurationProperty -MockWith { $MockWebConfiguration}

                It 'should return true' {
                    Test-AuthenticationInfo `
                        -Site $MockWebsite.Name `
                        -AuthenticationInfo $AuthenticationInfo | Should be True
                }

                It 'should call expected mocks' {
                    Assert-MockCalled -CommandName Get-WebConfigurationProperty -Exactly 4
                }
            }
        }

        Describe "$script:dscResourceName\Test-BindingInfo" {
            Context 'BindingInfo is valid' {
                $MockBindingInfo = @(
                    New-CimInstance `
                        -ClassName MSFT_xWebBindingInformation `
                        -Namespace root/microsoft/Windows/DesiredStateConfiguration `
                        -ClientOnly `
                        -Property @{
                            Protocol              = 'http'
                            IPAddress             = '*'
                            Port                  = 80
                            HostName              = ''
                            CertificateThumbprint = ''
                            CertificateStoreName  = ''
                            SslFlags              = 0
                        }

                    New-CimInstance `
                        -ClassName MSFT_xWebBindingInformation `
                        -Namespace root/microsoft/Windows/DesiredStateConfiguration `
                        -ClientOnly `
                        -Property @{
                            Protocol              = 'https'
                            IPAddress             = '*'
                            Port                  = 443
                            HostName              = 'web01.contoso.com'
                            CertificateThumbprint = 'C65CE51E20C523DEDCE979B9922A0294602D9D5C'
                            CertificateStoreName  = 'WebHosting'
                            SslFlags              = 1
                        }
                )

                It 'should return True' {
                    Test-BindingInfo -BindingInfo $MockBindingInfo | Should Be $true
                }
            }

            Context 'BindingInfo contains multiple items with the same IPAddress, Port, and HostName combination' {
                $MockBindingInfo = @(
                    New-CimInstance `
                        -ClassName MSFT_xWebBindingInformation `
                        -Namespace root/microsoft/Windows/DesiredStateConfiguration `
                        -ClientOnly `
                        -Property @{
                            Protocol              = 'http'
                            IPAddress             = '*'
                            Port                  = 8080
                            HostName              = 'web01.contoso.com'
                            CertificateThumbprint = ''
                            CertificateStoreName  = ''
                            SslFlags              = 0
                        }

                    New-CimInstance `
                        -ClassName MSFT_xWebBindingInformation `
                        -Namespace root/microsoft/Windows/DesiredStateConfiguration `
                        -ClientOnly `
                        -Property @{
                            Protocol              = 'http'
                            IPAddress             = '*'
                            Port                  = 8080
                            HostName              = 'web01.contoso.com'
                            CertificateThumbprint = ''
                            CertificateStoreName  = ''
                            SslFlags              = 0
                        }
                )

                It 'should return False' {
                    Test-BindingInfo -BindingInfo $MockBindingInfo | Should Be $false
                }
            }

            Context 'BindingInfo contains items that share the same Port but have different Protocols' {
                $MockBindingInfo = @(
                    New-CimInstance `
                        -ClassName MSFT_xWebBindingInformation `
                        -Namespace root/microsoft/Windows/DesiredStateConfiguration `
                        -ClientOnly `
                        -Property @{
                            Protocol              = 'http'
                            IPAddress             = '127.0.0.1'
                            Port                  = 8080
                            HostName              = ''
                            CertificateThumbprint = ''
                            CertificateStoreName  = ''
                            SslFlags              = 0
                        }

                    New-CimInstance `
                        -ClassName MSFT_xWebBindingInformation `
                        -Namespace root/microsoft/Windows/DesiredStateConfiguration `
                        -ClientOnly `
                        -Property @{
                            Protocol              = 'https'
                            IPAddress             = '*'
                            Port                  = 8080
                            HostName              = 'web01.contoso.com'
                            CertificateThumbprint = 'C65CE51E20C523DEDCE979B9922A0294602D9D5C'
                            CertificateStoreName  = 'WebHosting'
                            SslFlags              = 1
                        }
                )

                It 'should return False' {
                    Test-BindingInfo -BindingInfo $MockBindingInfo | Should Be $false
                }
            }

            Context 'BindingInfo contains multiple items with the same Protocol and BindingInformation combination' {
                $MockBindingInfo = @(
                    New-CimInstance `
                        -ClassName MSFT_xWebBindingInformation `
                        -Namespace root/microsoft/Windows/DesiredStateConfiguration `
                        -ClientOnly `
                        -Property @{
                            Protocol = 'net.tcp'
                            BindingInformation = '808:*'
                        }

                    New-CimInstance `
                        -ClassName MSFT_xWebBindingInformation `
                        -Namespace root/microsoft/Windows/DesiredStateConfiguration `
                        -ClientOnly `
                        -Property @{
                            Protocol = 'net.tcp'
                            BindingInformation = '808:*'
                        }
                )

                It 'should return False' {
                    Test-BindingInfo -BindingInfo $MockBindingInfo | Should Be $false
                }
            }
        }

        Describe "$script:dscResourceName\Test-PortNumber" {
            Context 'Input value is not valid' {
                It 'should not throw an error' {
                    {Test-PortNumber -InputString 'InvalidString'} | Should Not Throw
                }

                It 'should return False' {
                    Test-PortNumber -InputString 'InvalidString' | Should Be $false
                }

                It 'should return False when input value is null' {
                    Test-PortNumber -InputString $null | Should Be $false
                }

                It 'should return False when input value is empty' {
                    Test-PortNumber -InputString '' | Should Be $false
                }

                It 'should return False when input value is not between 1 and 65535' {
                    Test-PortNumber -InputString '100000' | Should Be $false
                }
            }

            Context 'Input value is valid' {
                It 'should return True' {
                    Test-PortNumber -InputString '443' | Should Be $true
                }
            }
        }

        Describe "$script:dscResourceName\Test-WebsiteBinding" {
            $MockWebBinding = @(
                @{
                    bindingInformation   = '*:80:'
                    protocol             = 'http'
                    certificateHash      = ''
                    certificateStoreName = ''
                    sslFlags             = '0'
                }
            )

            $MockWebsite = @{
                Name     = 'MockName'
                Bindings = @{Collection = @($MockWebBinding)}
            }

            Mock -CommandName Get-WebSite -MockWith {return $MockWebsite}

            Context 'Test-BindingInfo returns False' {
                $MockBindingInfo = @(
                    New-CimInstance `
                    -ClassName MSFT_xWebBindingInformation `
                    -Namespace root/microsoft/Windows/DesiredStateConfiguration `
                    -ClientOnly `
                    -Property @{
                        Protocol  = 'http'
                        IPAddress = '*'
                        Port      = 80
                        HostName  = ''
                    }
                )

                It 'should throw the correct error' {
                    Mock -CommandName Test-BindingInfo -MockWith {return $false}

                    $ErrorId = 'WebsiteBindingInputInvalidation'
                    $ErrorCategory = [System.Management.Automation.ErrorCategory]::InvalidResult
                    $ErrorMessage = $script:localizedData.ErrorWebsiteBindingInputInvalidation -f $MockWebsite.Name
                    $Exception = New-Object `
                        -TypeName System.InvalidOperationException `
                        -ArgumentList $ErrorMessage
                    $ErrorRecord = New-Object `
                        -TypeName System.Management.Automation.ErrorRecord `
                        -ArgumentList $Exception, $ErrorId, $ErrorCategory, $null

                    { Test-WebsiteBinding `
                        -Name $MockWebsite.Name `
                        -BindingInfo $MockBindingInfo } | Should Throw $ErrorRecord
                }
            }

            Context 'Bindings comparison throws an error' {
                $MockBindingInfo = @(
                    New-CimInstance `
                    -ClassName MSFT_xWebBindingInformation `
                    -Namespace root/microsoft/Windows/DesiredStateConfiguration `
                    -ClientOnly `
                    -Property @{
                        Protocol  = 'http'
                        IPAddress = '*'
                        Port      = 80
                        HostName  = ''
                    }
                )

                $ErrorId = 'WebsiteCompareFailure'
                $ErrorCategory = [System.Management.Automation.ErrorCategory]::InvalidResult
                $ErrorMessage = $script:localizedData.ErrorWebsiteCompareFailure -f $MockWebsite.Name, 'ScriptHalted'
                $Exception = New-Object `
                    -TypeName System.InvalidOperationException `
                    -ArgumentList $ErrorMessage
                $ErrorRecord = New-Object `
                    -TypeName System.Management.Automation.ErrorRecord `
                    -ArgumentList $Exception, $ErrorId, $ErrorCategory, $null

                It 'should not return an error' {
                    { Test-WebsiteBinding `
                        -Name $MockWebsite.Name `
                        -BindingInfo $MockBindingInfo} | Should Not Throw $ErrorRecord
                }
            }

            Context 'Port is different' {
                $MockBindingInfo = @(
                    New-CimInstance `
                        -ClassName MSFT_xWebBindingInformation `
                        -Namespace root/microsoft/Windows/DesiredStateConfiguration `
                        -ClientOnly `
                        -Property @{
                            Protocol              = 'http'
                            IPAddress             = '*'
                            Port                  = 8080
                            HostName              = ''
                            CertificateThumbprint = ''
                            CertificateStoreName  = ''
                            SslFlags              = 0
                        }
                )

                It 'should return False' {
                    Test-WebsiteBinding `
                        -Name $MockWebsite.Name `
                        -BindingInfo $MockBindingInfo | Should Be $false
                }
            }

            Context 'Protocol is different' {
                $MockBindingInfo = @(
                    New-CimInstance `
                        -ClassName MSFT_xWebBindingInformation `
                        -Namespace root/microsoft/Windows/DesiredStateConfiguration `
                        -ClientOnly `
                        -Property @{
                            Protocol              = 'https'
                            IPAddress             = '*'
                            Port                  = 80
                            HostName              = ''
                            CertificateThumbprint = '1D3324C6E2F7ABC794C9CB6CA426B8D0F81045CD'
                            CertificateStoreName  = 'WebHosting'
                            SslFlags              = 0
                        }
                )

                It 'should return False' {
                    Test-WebsiteBinding `
                        -Name $MockWebsite.Name `
                        -BindingInfo $MockBindingInfo | Should Be $false
                }
            }

            Context 'IPAddress is different' {
                $MockBindingInfo = @(
                    New-CimInstance `
                    -ClassName MSFT_xWebBindingInformation `
                    -Namespace root/microsoft/Windows/DesiredStateConfiguration `
                    -ClientOnly `
                    -Property @{
                        Protocol              = 'http'
                        IPAddress             = '127.0.0.1'
                        Port                  = 80
                        HostName              = ''
                        CertificateThumbprint = ''
                        CertificateStoreName  = ''
                        SslFlags              = 0
                    }
                )

                It 'should return False' {
                    Test-WebsiteBinding `
                        -Name $MockWebsite.Name `
                        -BindingInfo $MockBindingInfo | Should Be $false
                }
            }

            Context 'HostName is different' {
                $MockBindingInfo = @(
                    New-CimInstance `
                        -ClassName MSFT_xWebBindingInformation `
                        -Namespace root/microsoft/Windows/DesiredStateConfiguration `
                        -ClientOnly `
                        -Property @{
                            Protocol              = 'http'
                            IPAddress             = '*'
                            Port                  = 80
                            HostName              = 'MockHostName'
                            CertificateThumbprint = ''
                            CertificateStoreName  = ''
                            SslFlags              = 0
                        }
                )

                It 'should return False' {
                    Test-WebsiteBinding -Name $MockWebsite.Name -BindingInfo $MockBindingInfo |
                    Should Be $false
                }
            }

            Context 'CertificateThumbprint is different' {
                $MockBindingInfo = @(
                    New-CimInstance `
                        -ClassName MSFT_xWebBindingInformation `
                        -Namespace root/microsoft/Windows/DesiredStateConfiguration `
                        -ClientOnly `
                        -Property @{
                            Protocol              = 'https'
                            IPAddress             = '*'
                            Port                  = 443
                            HostName              = ''
                            CertificateThumbprint = '1D3324C6E2F7ABC794C9CB6CA426B8D0F81045CD'
                            CertificateStoreName  = 'MY'
                            SslFlags              = 0
                        }
                )

                $MockWebBinding = @(
                    @{
                        bindingInformation   = '*:443:'
                        protocol             = 'https'
                        certificateHash      = 'B30F3184A831320382C61EFB0551766321FA88A5'
                        certificateStoreName = 'MY'
                        sslFlags             = '0'
                    }
                )

                $MockWebsite = @{
                    Name     = 'MockSite'
                    Bindings = @{ Collection = @($MockWebBinding) }
                }

                Mock -CommandName Get-WebSite -MockWith {return $MockWebsite}

                It 'should return False' {
                    Test-WebsiteBinding `
                        -Name $MockWebsite.Name `
                        -BindingInfo $MockBindingInfo | Should Be $false
                }
            }

            Context 'CertificateStoreName is different' {
                $MockBindingInfo = @(
                    New-CimInstance `
                        -ClassName MSFT_xWebBindingInformation `
                        -Namespace root/microsoft/Windows/DesiredStateConfiguration `
                        -ClientOnly `
                        -Property @{
                            Protocol              = 'https'
                            IPAddress             = '*'
                            Port                  = 443
                            HostName              = ''
                            CertificateThumbprint = '1D3324C6E2F7ABC794C9CB6CA426B8D0F81045CD'
                            CertificateStoreName  = 'MY'
                            SslFlags              = 0
                        }
                )

                $MockWebBinding = @{
                    bindingInformation   = '*:443:'
                    protocol             = 'https'
                    certificateHash      = '1D3324C6E2F7ABC794C9CB6CA426B8D0F81045CD'
                    certificateStoreName = 'WebHosting'
                    sslFlags             = '0'
                }

                $MockWebsite = @{
                    Name     = 'MockSite'
                    Bindings = @{ Collection = @($MockWebBinding) }
                }

                Mock -CommandName Get-WebSite -MockWith { return $MockWebsite }

                It 'should return False' {
                    Test-WebsiteBinding `
                        -Name $MockWebsite.Name `
                        -BindingInfo $MockBindingInfo | Should Be $false
                }
            }

            Context 'CertificateStoreName is different and no CertificateThumbprint is specified' {
                $MockBindingInfo = @(
                    New-CimInstance `
                        -ClassName MSFT_xWebBindingInformation `
                        -Namespace root/microsoft/Windows/DesiredStateConfiguration `
                        -ClientOnly `
                        -Property @{
                            Protocol              = 'https'
                            IPAddress             = '*'
                            Port                  = 443
                            HostName              = ''
                            CertificateThumbprint = ''
                            CertificateStoreName  = 'MY'
                            SslFlags              = 0
                        }
                )

                $MockWebBinding = @{
                    bindingInformation   = '*:443:'
                    protocol             = 'https'
                    certificateHash      = '1D3324C6E2F7ABC794C9CB6CA426B8D0F81045CD'
                    certificateStoreName = 'WebHosting'
                    sslFlags             = '0'
                }

                $MockWebsite = @{
                    Name     = 'MockSite'
                    Bindings = @{Collection = @($MockWebBinding)}
                }

                Mock -CommandName Get-WebSite -MockWith {return $MockWebsite}

                $ErrorId = 'WebsiteBindingInputInvalidation'
                $ErrorCategory = [System.Management.Automation.ErrorCategory]::InvalidResult
                $ErrorMessage = $script:localizedData.ErrorWebsiteBindingInputInvalidation -f $MockWebsite.Name
                $Exception = New-Object `
                    -TypeName System.InvalidOperationException `
                    -ArgumentList $ErrorMessage
                $ErrorRecord = New-Object `
                    -TypeName System.Management.Automation.ErrorRecord `
                    -ArgumentList $Exception, $ErrorId, $ErrorCategory, $null

                It 'should throw the correct error' {
                    { Test-WebsiteBinding `
                        -Name $MockWebsite.Name `
                        -BindingInfo $MockBindingInfo} | Should Throw $ErrorRecord
                }
            }

            Context 'SslFlags is different' {
                $MockBindingInfo = @(
                    New-CimInstance `
                        -ClassName MSFT_xWebBindingInformation `
                        -Namespace root/microsoft/Windows/DesiredStateConfiguration `
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

                $MockWebBinding = @{
                    bindingInformation   = '*:443:web01.contoso.com'
                    protocol             = 'https'
                    certificateHash      = '1D3324C6E2F7ABC794C9CB6CA426B8D0F81045CD'
                    certificateStoreName = 'WebHosting'
                    sslFlags             = '0'
                }

                $MockWebsite = @{
                    Name     = 'MockSite'
                    Bindings = @{ Collection = @($MockWebBinding) }
                }

                Mock -CommandName Get-WebSite -MockWith {return $MockWebsite}

                It 'should return False' {
                    Test-WebsiteBinding `
                        -Name $MockWebsite.Name `
                        -BindingInfo $MockBindingInfo | Should Be $false
                }
            }

            Context 'Bindings are identical' {
                $MockBindingInfo = @(
                    New-CimInstance `
                        -ClassName MSFT_xWebBindingInformation `
                        -Namespace root/microsoft/Windows/DesiredStateConfiguration `
                        -ClientOnly `
                        -Property @{
                            Protocol              = 'https'
                            Port                  = 443
                            IPAddress             = '*'
                            HostName              = 'web01.contoso.com'
                            CertificateThumbprint = '1D3324C6E2F7ABC794C9CB6CA426B8D0F81045CD'
                            CertificateStoreName  = 'WebHosting'
                            SslFlags              = 1
                        }

                    New-CimInstance `
                        -ClassName MSFT_xWebBindingInformation `
                        -Namespace root/microsoft/Windows/DesiredStateConfiguration `
                        -ClientOnly `
                        -Property @{
                            IPAddress             = '*'
                            Port                  = 8080
                            HostName              = ''
                            Protocol              = 'http'
                            CertificateThumbprint = ''
                            CertificateStoreName  = ''
                            SslFlags              = 0
                        }
                )

                $MockWebBinding = @(
                    @{
                        bindingInformation   = '*:443:web01.contoso.com'
                        protocol             = 'https'
                        certificateHash      = '1D3324C6E2F7ABC794C9CB6CA426B8D0F81045CD'
                        certificateStoreName = 'WebHosting'
                        sslFlags             = '1'
                    }
                    @{
                        bindingInformation   = '*:8080:'
                        protocol             = 'http'
                        certificateHash      = ''
                        certificateStoreName = ''
                        sslFlags             = '0'
                    }
                )

                $MockWebsite = @{
                    Name     = 'MockSite'
                    Bindings = @{Collection = @($MockWebBinding)}
                }

                Mock -CommandName Get-WebSite -MockWith {return $MockWebsite}

                It 'should return True' {
                    Test-WebsiteBinding `
                        -Name $MockWebsite.Name `
                        -BindingInfo $MockBindingInfo | Should Be $true
                }
            }

            Context 'Bindings are different' {
                $MockBindingInfo = @(
                    New-CimInstance `
                        -ClassName MSFT_xWebBindingInformation `
                        -Namespace root/microsoft/Windows/DesiredStateConfiguration `
                        -ClientOnly `
                        -Property @{
                            Protocol              = 'http'
                            IPAddress             = '*'
                            Port                  = 80
                            HostName              = ''
                            CertificateThumbprint = ''
                            CertificateStoreName  = ''
                            SslFlags              = 0
                        }

                    New-CimInstance `
                        -ClassName MSFT_xWebBindingInformation `
                        -Namespace root/microsoft/Windows/DesiredStateConfiguration `
                        -ClientOnly `
                        -Property @{
                            Protocol              = 'http'
                            IPAddress             = '*'
                            Port                  = 8080
                            HostName              = ''
                            CertificateThumbprint = ''
                            CertificateStoreName  = ''
                            SslFlags              = 0
                        }
                )

                $MockWebBinding = @(
                    @{
                        bindingInformation   = '*:80:'
                        protocol             = 'http'
                        certificateHash      = ''
                        certificateStoreName = ''
                        sslFlags             = '0'
                    }

                    @{
                        bindingInformation   = '*:8081:'
                        protocol             = 'http'
                        certificateHash      = ''
                        certificateStoreName = ''
                        sslFlags             = '0'
                    }
                )

                $MockWebsite = @{
                    Name     = 'MockSite'
                    Bindings = @{Collection = @($MockWebBinding)}
                }

                Mock -CommandName Get-Website -MockWith {return $MockWebsite}

                It 'should return False' {
                    Test-WebsiteBinding `
                        -Name $MockWebsite.Name `
                        -BindingInfo $MockBindingInfo | Should Be $false
                }
            }

            Context 'Two bindings with different certificate thumbprints' {
                $MockBindingInfo = @(
                    New-CimInstance `
                        -ClassName MSFT_xWebBindingInformation `
                        -Namespace root/microsoft/Windows/DesiredStateConfiguration `
                        -ClientOnly `
                        -Property @{
                            Protocol              = 'https'
                            IPAddress             = '*'
                            Port                  = 443
                            HostName              = 'mock.website1.com'
                            CertificateThumbprint = '1D3324C6E2F7ABC794C9CB6CA426B8D0F81045CD'
                            CertificateStoreName  = 'WebHosting'
                            SslFlags              = 0
                        }

                    New-CimInstance `
                        -ClassName MSFT_xWebBindingInformation `
                        -Namespace root/microsoft/Windows/DesiredStateConfiguration `
                        -ClientOnly `
                        -Property @{
                            Protocol              = 'https'
                            IPAddress             = '*'
                            Port                  = 443
                            HostName              = 'mock.website2.com'
                            CertificateThumbprint = 'B30F3184A831320382C61EFB0551766321FA88A5'
                            CertificateStoreName  = 'WebHosting'
                            SslFlags              = 0
                        }
                )

                $MockWebBinding = @(
                    @{
                        bindingInformation   = '*:443:mock.website1.com'
                        protocol             = 'https'
                        certificateHash      = '1D3324C6E2F7ABC794C9CB6CA426B8D0F81045CD'
                        certificateStoreName = 'WebHosting'
                        sslFlags             = '0'
                    }

                    @{
                        bindingInformation   = '*:443:mock.website2.com'
                        protocol             = 'https'
                        certificateHash      = 'B30F3184A831320382C61EFB0551766321FA88A5'
                        certificateStoreName = 'WebHosting'
                        sslFlags             = '0'
                    }
                )

                $MockWebsite = @{
                    Name     = 'MockSite'
                    Bindings = @{Collection = @($MockWebBinding)}
                }

                Mock -CommandName Get-Website -MockWith {return $MockWebsite}

                It 'should return True' {
                    Test-WebsiteBinding `
                        -Name $MockWebsite.Name `
                        -BindingInfo $MockBindingInfo | Should Be $true
                }
            }
        }

        Describe "$script:dscResourceName\Update-DefaultPage" {
            $MockWebsite = @{
                Ensure             = 'Present'
                Name               = 'MockName'
                PhysicalPath       = 'C:\NonExistent'
                State              = 'Started'
                ServerAutoStart    = $true
                ApplicationPool    = 'MockPool'
                DefaultPage        = 'index.htm'
            }

            Context 'Does not find the default page' {
                Mock -CommandName Get-WebConfiguration -MockWith {
                    return @{value = 'index2.htm'}
                }

                Mock -CommandName Add-WebConfiguration

                It 'should call Add-WebConfiguration' {
                    $Result = Update-DefaultPage -Name $MockWebsite.Name -DefaultPage $MockWebsite.DefaultPage
                    Assert-MockCalled -CommandName Add-WebConfiguration
                }
            }
        }

        Describe "$script:dscResourceName\Update-WebsiteBinding" {
            $MockWebsite = @{
                Name      = 'MockSite'
                ItemXPath = "/system.applicationHost/sites/site[@name='MockSite']"
            }

            $MockBindingInfo = @(
                New-CimInstance `
                    -ClassName MSFT_xWebBindingInformation `
                    -Namespace root/microsoft/Windows/DesiredStateConfiguration `
                    -ClientOnly `
                    -Property @{
                        Protocol              = 'https'
                        IPAddress             = '*'
                        Port                  = 443
                        HostName              = ''
                        CertificateThumbprint = '5846A1B276328B1A32A30150858F6383C1F30E1F'
                        CertificateStoreName  = 'MY'
                        SslFlags              = 0
                    }
            )

            Mock -CommandName Get-WebConfiguration -ParameterFilter {
                $Filter -eq '/system.applicationHost/sites/site'
            } -MockWith { return $MockWebsite } -Verifiable

            Mock -CommandName Clear-WebConfiguration -Verifiable

            Context 'Expected behavior' {
                Mock -CommandName Add-WebConfiguration
                Mock -CommandName Set-WebConfigurationProperty

                Mock -CommandName Get-WebConfiguration -ParameterFilter {
                    $Filter -eq "$($MockWebsite.ItemXPath)/bindings/binding[last()]"
                } -MockWith {
                    New-Module -AsCustomObject -ScriptBlock {
                        function AddSslCertificate {}
                    }
                } -Verifiable

                Update-WebsiteBinding -Name $MockWebsite.Name -BindingInfo $MockBindingInfo

                It 'Should call all the mocks' {
                    Assert-VerifiableMock
                    Assert-MockCalled -CommandName Add-WebConfiguration -Exactly $MockBindingInfo.Count
                    Assert-MockCalled -CommandName Set-WebConfigurationProperty
                }
            }

            Context 'Website does not exist' {
                Mock -CommandName Get-WebConfiguration -ParameterFilter {
                    $Filter -eq '/system.applicationHost/sites/site'
                } -MockWith {
                    return $null
                }

                It 'should throw the correct error' {
                    $ErrorId = 'WebsiteNotFound'
                    $ErrorCategory = [System.Management.Automation.ErrorCategory]::InvalidResult
                    $ErrorMessage = $script:localizedData.ErrorWebsiteNotFound -f $MockWebsite.Name
                    $Exception = New-Object `
                        -TypeName System.InvalidOperationException `
                        -ArgumentList $ErrorMessage
                    $ErrorRecord = New-Object `
                        -TypeName System.Management.Automation.ErrorRecord `
                        -ArgumentList $Exception, $ErrorId, $ErrorCategory, $null

                    { Update-WebsiteBinding `
                        -Name $MockWebsite.Name `
                        -BindingInfo $MockBindingInfo} | Should Throw $ErrorRecord
                }
            }

            Context 'Error on adding a new binding' {
                Mock -CommandName Add-WebConfiguration -ParameterFilter {
                    $Filter -eq "$($MockWebsite.ItemXPath)/bindings"
                } -MockWith { throw }

                It 'should throw the correct error' {
                    $ErrorId = 'WebsiteBindingUpdateFailure'
                    $ErrorCategory = [System.Management.Automation.ErrorCategory]::InvalidResult
                    $ErrorMessage = $script:localizedData.ErrorWebsiteBindingUpdateFailure -f $MockWebsite.Name, 'ScriptHalted'
                    $Exception = New-Object `
                        -TypeName System.InvalidOperationException `
                        -ArgumentList $ErrorMessage
                    $ErrorRecord = New-Object `
                        -TypeName System.Management.Automation.ErrorRecord `
                        -ArgumentList $Exception, $ErrorId, $ErrorCategory, $null

                    { Update-WebsiteBinding `
                        -Name $MockWebsite.Name `
                        -BindingInfo $MockBindingInfo } | Should Throw $ErrorRecord
                }
            }

            Context 'Error on setting sslFlags attribute' {
                Mock -CommandName Add-WebConfiguration

                Mock -CommandName Set-WebConfigurationProperty -ParameterFilter {
                    $Filter -eq "$($MockWebsite.ItemXPath)/bindings/binding[last()]" -and $Name -eq 'sslFlags'
                } ` -MockWith { throw }

                It 'should throw the correct error' {
                    $ErrorId = 'WebsiteBindingUpdateFailure'
                    $ErrorCategory = [System.Management.Automation.ErrorCategory]::InvalidResult
                    $ErrorMessage = $script:localizedData.ErrorWebsiteBindingUpdateFailure -f $MockWebsite.Name, 'ScriptHalted'
                    $Exception = New-Object `
                        -TypeName System.InvalidOperationException `
                        -ArgumentList $ErrorMessage
                    $ErrorRecord = New-Object `
                        -TypeName System.Management.Automation.ErrorRecord `
                        -ArgumentList $Exception, $ErrorId, $ErrorCategory, $null

                    { Update-WebsiteBinding `
                        -Name $MockWebsite.Name `
                        -BindingInfo $MockBindingInfo } | Should Throw $ErrorRecord
                }
            }

            Context 'Error on adding SSL certificate' {
                Mock -CommandName Add-WebConfiguration

                Mock -CommandName Set-WebConfigurationProperty

                Mock -CommandName Get-WebConfiguration -ParameterFilter {
                    $Filter -eq "$($MockWebsite.ItemXPath)/bindings/binding[last()]"
                } -MockWith {
                    New-Module -AsCustomObject -ScriptBlock {
                        function AddSslCertificate {throw}
                    }
                }

                It 'should throw the correct error' {
                    $ErrorId = 'WebBindingCertificate'
                    $ErrorCategory = [System.Management.Automation.ErrorCategory]::InvalidOperation
                    $ErrorMessage = $script:localizedData.ErrorWebBindingCertificate -f $MockBindingInfo.CertificateThumbprint, 'Exception calling "AddSslCertificate" with "2" argument(s): "ScriptHalted"'
                    $Exception = New-Object -TypeName System.InvalidOperationException -ArgumentList $ErrorMessage
                    $ErrorRecord = New-Object -TypeName System.Management.Automation.ErrorRecord -ArgumentList $Exception, $ErrorId, $ErrorCategory, $null

                    { Update-WebsiteBinding `
                        -Name $MockWebsite.Name `
                        -BindingInfo $MockBindingInfo } | Should Throw $ErrorRecord
                }
            }
        }

        Describe "$script:dscResourceName\ConvertTo-CimLogCustomFields"{
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

            Context 'Expected behavior'{
                $Result = ConvertTo-CimLogCustomFields -InputObject $mockLogCustomFields

                It 'should return the LogFieldName' {
                    $Result[0].LogFieldName | Should Be $mockLogCustomFields[0].LogFieldName
                    $Result[0].LogFieldName | Should Be $mockLogCustomFields[0].LogFieldName
                }

                It 'should return the SourceName' {
                    $Result[0].SourceName | Should Be $mockLogCustomFields[0].SourceName
                    $Result[0].SourceName | Should Be $mockLogCustomFields[0].SourceName
                }

                It 'should return the SourceType' {
                    $Result[0].SourceType | Should Be $mockLogCustomFields[0].SourceType
                    $Result[0].SourceType | Should Be $mockLogCustomFields[0].SourceType
                }
            }
        }

        Describe "$script:dscResourceName\Test-LogCustomField"{
            $MockWebsiteName = 'ContosoSite'

            $MockCimLogCustomFields = @(
                New-CimInstance -ClassName MSFT_xLogCustomFieldInformation `
                    -Namespace root/microsoft/Windows/DesiredStateConfiguration `
                    -Property @{
                        LogFieldName = 'ClientEncoding'
                        SourceName   = 'Accept-Encoding'
                        SourceType   = 'RequestHeader'
                    } `
                    -ClientOnly
            )

            Context 'LogCustomField in desired state'{
                $MockDesiredLogCustomFields = @{
                    LogFieldName = 'ClientEncoding'
                    SourceName   = 'Accept-Encoding'
                    SourceType   = 'RequestHeader'
                }

                Mock -CommandName Get-WebConfigurationProperty -MockWith { return $MockDesiredLogCustomFields }

               It 'should return True' {
                    Test-LogCustomField -Site $MockWebsiteName -LogCustomField $MockCimLogCustomFields | Should Be $True
                }
            }

            Context 'LogCustomField not in desired state'{
                $MockWrongLogCustomFields = @{
                    LogFieldName = 'ClientEncoding'
                    SourceName   = 'WrongSourceName'
                    SourceType   = 'WrongSourceType'
                }

                Mock -CommandName Get-WebConfigurationProperty -MockWith { return $MockWrongLogCustomFields }

                It 'should return False' {
                    Test-LogCustomField -Site $MockWebsiteName -LogCustomField $MockCimLogCustomFields | Should Be $False
                }
            }

            Context 'LogCustomField not present'{
                Mock -CommandName Get-WebConfigurationProperty -MockWith { return $false }

                It 'should return False' {
                    Test-LogCustomField -Site $MockWebsiteName -LogCustomField $MockCimLogCustomFields | Should Be $False
                }
            }

        }

        Describe "$script:dscResourceName\Set-LogCustomField"{
            $MockWebsiteName = 'ContosoSite'

            $MockCimLogCustomFields = @(
                New-CimInstance -ClassName MSFT_xLogCustomFieldInformation `
                    -Namespace root/microsoft/Windows/DesiredStateConfiguration `
                    -Property @{
                        LogFieldName = 'ClientEncoding'
                        SourceName   = 'Accept-Encoding'
                        SourceType   = 'RequestHeader'
                    } `
                    -ClientOnly
            )

            Context 'Create new LogCustomField'{
                Mock -CommandName Set-WebConfigurationProperty

                It 'should not throw an error' {
                    { Set-LogCustomField  -Site $MockWebsiteName -LogCustomField $MockCimLogCustomFields } | Should Not Throw
                }

                It 'should call should call expected mocks' {
                    Assert-MockCalled -CommandName Set-WebConfigurationProperty -Exactly 2
                }
            }

            Context 'Modify existing LogCustomField'{
                Mock -CommandName Set-WebConfigurationProperty

                It 'should not throw an error' {
                    { Set-LogCustomField  -Site $MockWebsiteName -LogCustomField $MockCimLogCustomFields } | Should Not Throw
                }

                It 'should call should call expected mocks' {
                    Assert-MockCalled -CommandName Set-WebConfigurationProperty -Exactly 2
                }
            }
        }
    }
    #endregion
}
finally
{
    Invoke-TestCleanup
}
