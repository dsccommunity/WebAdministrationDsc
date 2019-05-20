$script:DSCModuleName       = 'xWebAdministration'
$script:DSCResourceName     = 'MSFT_xFTP'
$script:DSCHelperModuleName = 'Helper'

#region HEADER
$script:moduleRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $Script:MyInvocation.MyCommand.Path))
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
        $script:DSCResourceName     = 'MSFT_xFTP'
        $script:DSCHelperModuleName = 'Helper'

        Describe "how $DSCResourceName\Get-TargetResource responds" {

            $MockLogOutput = @{
                directory         = '%SystemDrive%\inetpub\logs\LogFiles'
                logExtFileFlags   = ('Date','Time','ClientIP','UserName','ServerIP','Method')
                period            = 'Daily'
                truncateSize      = '1048576'
                localTimeRollover = 'False'
            }

            $MockAuthenticationInfo = @(
                New-CimInstance -ClassName MSFT_xFTPAuthenticationInformation `
                                -Namespace 'root/microsoft/Windows/DesiredStateConfiguration' `
                                -ClientOnly `
                                -Property @{
                                    Anonymous = $true
                                    Basic     = $false
                                }
            )

            $MockAuthorizationInfo = @(
                New-CimInstance -ClassName MSFT_xFTPAuthorizationInformation `
                                -Namespace 'root/microsoft/Windows/DesiredStateConfiguration' `
                                -ClientOnly `
                                -Property @{
                                    accessType  = 'Allow'
                                    users       = 'User1'
                                    roles       = ''
                                    permissions = 'Read'
                                }
            )

            $MockBindingInfo = @(
                @{
                    bindingInformation = '*:21:ftp.server'
                    protocol           = 'ftp'
                }
            )

            $MockSslInfo = @(
                New-CimInstance -ClassName MSFT_xFTPSslInformation `
                                -Namespace 'root/microsoft/Windows/DesiredStateConfiguration' `
                                -ClientOnly `
                                -Property @{
                                    ControlChannelPolicy  = 'SslAllow'
                                    DataChannelPolicy     = 'SslAllow'
                                    RequireSsl128         = 'True'
                                    CertificateThumbprint = ''
                                    CertificateStoreName  = 'My'
                                }
            )

            $MockDefaultFirewallSupport = @{
                lowDataChannelPort  = 0
                highDataChannelPort = 0
            }

            $MockMessageOutput = @{
                greetingMessage          = 'Greetings, %UserName%!'
                exitMessage              = 'Bye, %UserName%!'
                bannerMessage            = "%UserName%, you've been watched.."
                maxClientsMessage        = 'Sorry, %UserName%, try to connect again in an hour.'
                suppressDefaultBanner    = $true
                allowLocalDetailedErrors = $false
                expandVariables          = $true
            }

            $MockFtpServerInfo = @(
                @{
                    userIsolation = @{
                        mode = 'IsolateAllDirectories'
                    }
                }
                @{
                    directoryBrowse = @{
                        showFlags = 'LongDate'
                    }
                }
                @{
                    firewallSupport = @{
                        externalIp4Address = 10.0.0.10
                    }
                }
                @{
                    messages = $MockMessageOutput
                }
                @{
                    logFile = $MockLogOutput
                }
            )

            $MockWebsite = @{
                Name                   = 'MockFtp'
                PhysicalPath           = 'C:\NonExistent'
                userName               = ''
                password               = ''
                State                  = 'Started'
                ApplicationPool        = 'MockFtpPool'
                AuthenticationInfo     = $MockAuthenticationInfo
                AuthorizationInfo      = $MockAuthorizationInfo
                SslInfo                = $MockSslInfo
                Bindings               = @{Collection = @($MockBindingInfo)}
                ftpServer              = $MockFtpServerInfo
                Count                  = 1
            }

            Context 'Website does not exist' {

                Mock -CommandName Get-WebConfiguration
                Mock -CommandName Get-Website

                $Result = Get-TargetResource -Name $MockWebsite.Name

                It 'Should return Absent' {
                    $Result.Ensure | Should Be 'Absent'
                }
            }

            Context 'There are multiple webftpsites with the same name' {

                Mock -CommandName Get-WebConfiguration
                Mock -CommandName Get-Website -MockWith {
                    return @(
                        @{Name = 'MockFtp'}
                        @{Name = 'MockFtp'}
                    )
                }

                It 'Should throw the correct error' {
                    $ErrorId       = 'FtpSiteDiscoveryFailure'
                    $ErrorCategory = [System.Management.Automation.ErrorCategory]::InvalidResult
                    $ErrorMessage  = $LocalizedData.ErrorFtpSiteDiscoveryFailure -f 'MockFtp'
                    $Exception     = New-Object -TypeName System.InvalidOperationException `
                                                -ArgumentList $ErrorMessage
                    $ErrorRecord   = New-Object -TypeName System.Management.Automation.ErrorRecord `
                                                -ArgumentList $Exception, $ErrorId, $ErrorCategory, $null

                    {Get-TargetResource -Name 'MockFtp'} | Should Throw $ErrorRecord
                }
            }

            Context 'Single website exists' {

                Mock -CommandName Get-Website -MockWith {return $MockWebsite}
                Mock -CommandName Get-AuthenticationInfo { return $MockAuthenticationInfo }
                Mock -CommandName Get-AuthorizationInfo { return $MockAuthorizationInfo }
                Mock -CommandName Get-SslInfo { return $MockSslInfo }
                Mock -CommandName Get-WebConfiguration `
                     -ParameterFilter { $Filter -eq '/system.ftpServer/firewallSupport' } `
                     -MockWith { return $MockDefaultFirewallSupport }

                $Result = Get-TargetResource -Name $MockWebsite.Name

                It 'Should call Get-Website once' {
                    Assert-MockCalled -CommandName Get-Website -Exactly 1
                }

                It 'Should return Ensure' {
                    $Result.Ensure | Should Be 'Present'
                }

                It 'Should return Name' {
                    $Result.Name | Should Be $MockWebsite.Name
                }

                It 'Should return PhysicalPath' {
                    $Result.PhysicalPath | Should Be $MockWebsite.PhysicalPath
                }

                It 'Should return PhysicalPathCredential' {
                    $Result.PhysicalPathCredential.UserName | Should BeNullOrEmpty
                    $Result.PhysicalPathCredential.Password | Should BeNullOrEmpty
                }

                It 'Should return State' {
                    $Result.State | Should Be $MockWebsite.State
                }

                It 'Should return ApplicationPool' {
                    $Result.ApplicationPool | Should Be $MockWebsite.ApplicationPool
                }

                It 'Should return AuthenticationInfo' {
                    $Result.AuthenticationInfo.CimInstanceProperties['Anonymous'].Value | Should Be $true
                    $Result.AuthenticationInfo.CimInstanceProperties['Basic'].Value     | Should Be $false
                }

                It 'Should return AuthorizationInfo' {
                    $Result.AuthorizationInfo.users       | Should Be $MockAuthorizationInfo.Users
                    $Result.AuthorizationInfo.roles       | Should BeNullOrEmpty
                    $Result.AuthorizationInfo.accessType  | Should Be $MockAuthorizationInfo.accessType
                    $Result.AuthorizationInfo.permissions | Should Be $MockAuthorizationInfo.permissions
                }

                It 'Should return SslInfo' {
                    $Result.SslInfo.ControlChannelPolicy  | Should Be $MockSslInfo.ControlChannelPolicy
                    $Result.SslInfo.DataChannelPolicy     | Should Be $MockSslInfo.DataChannelPolicy
                    $Result.SslInfo.RequireSsl128         | Should Be $MockSslInfo.RequireSsl128
                    $Result.SslInfo.CertificateThumbprint | Should Be $MockSslInfo.CertificateThumbprint
                    $Result.SslInfo.CertificateStoreName  | Should Be $MockSslInfo.CertificateStoreName
                }

                It 'Should return BindingInfo' {
                    $Result.BindingInfo.HostName  | Should Be 'ftp.server'
                    $Result.BindingInfo.Port      | Should Be '21'
                    $Result.BindingInfo.Protocol  | Should Be $MockBindingInfo.protocol
                    $Result.BindingInfo.IPAddress | Should Be '*'
                }

                It 'Should return FirewallIPAddress' {
                    $Result.FirewallIPAddress | Should -Be $MockFtpServerInfo.ftpServer.firewallSupport.externalIp4Address
                }

                It 'Should return StartingDataChannelPort' {
                    $Result.StartingDataChannelPort | Should -Be $MockDefaultFirewallSupport.lowDataChannelPort
                }

                It 'Should return EndingDataChannelPort' {
                    $Result.EndingDataChannelPort | Should -Be $MockDefaultFirewallSupport.highDataChannelPort
                }

                It 'Should return GreetingMessage' {
                    $Result.GreetingMessage | Should -Be $MockMessageOutput.greetingMessage
                }

                It 'Should return ExitMessage' {
                    $Result.ExitMessage | Should -Be $MockMessageOutput.exitMessage
                }

                It 'Should return BannerMessage' {
                    $Result.BannerMessage | Should -Be $MockMessageOutput.bannerMessage
                }

                It 'Should return MaxClientsMessage' {
                    $Result.MaxClientsMessage | Should -Be $MockMessageOutput.maxClientsMessage
                }

                It 'Should return SuppressDefaultBanner' {
                    $Result.SuppressDefaultBanner | Should -Be $MockMessageOutput.suppressDefaultBanner
                }

                It 'Should return AllowLocalDetailedErrors' {
                    $Result.AllowLocalDetailedErrors | Should -Be $MockMessageOutput.allowLocalDetailedErrors
                }

                It 'Should return ExpandVariablesInMessages' {
                    $Result.ExpandVariablesInMessages | Should -Be $MockMessageOutput.expandVariables
                }

                It 'Should return LogPath' {
                    $Result.LogPath | Should Be $MockWebsite.ftpServer.logFile.directory
                }

                It 'Should return LogFlags' {
                    $Result.LogFlags | Should -BeIn $MockWebsite.ftpServer.logFile.LogExtFileFlags
                }

                It 'Should return LogPeriod' {
                    $Result.LogPeriod | Should Be $MockWebsite.ftpServer.logFile.period
                }

                It 'Should return LogtruncateSize' {
                    $Result.LogtruncateSize | Should Be $MockWebsite.ftpServer.logFile.truncateSize
                }

                It 'Should return LoglocalTimeRollover' {
                    $Result.LoglocalTimeRollover | Should Be $MockWebsite.ftpServer.logFile.localTimeRollover
                }

                It 'Should return DirectoryBrowseFlags' {
                    $Result.DirectoryBrowseFlags | Should Be $MockFtpServerInfo.directoryBrowse.showFlags
                }

                It 'Should return UserIsolation' {
                    $Result.UserIsolation | Should Be $MockFtpServerInfo.userIsolation.mode
                }
            }
        }

        Describe "how $DSCResourceName\Test-TargetResource responds to Ensure = 'Absent'" {

            $MockWebsite = 'Ftp'

            Mock -CommandName Assert-Module -MockWith {}

            Context 'Ftp site does not exist' {

                Mock -CommandName Get-Website -MockWith {
                    return $null
                }

                It 'Should return True' {
                    $Result = Test-TargetResource -Ensure 'Absent' -Name $MockWebsite
                    $Result | Should Be $true
                }
            }

            Context 'Ftp site exists' {

                Mock -CommandName Get-Website -MockWith {
                    return @{ Name = $MockWebsite }
                }

                It 'Should return False' {
                    $Result = Test-TargetResource -Ensure 'Absent' -Name $MockWebsite
                    $Result | Should Be $false
                }
            }
        }

        Describe "how $DSCResourceName\Test-TargetResource responds to Ensure = 'Present'" {

            $MockAuthenticationInfo = New-CimInstance `
                                        -ClassName MSFT_xFTPAuthenticationInformation `
                                        -Namespace 'root/microsoft/Windows/DesiredStateConfiguration' `
                                        -ClientOnly `
                                        -Property @{
                                            Anonymous = $true
                                            Basic     = $false
                                        }

            $MockAuthorizationInfo = @(
                New-CimInstance -ClassName MSFT_xFTPAuthorizationInformation `
                                -Namespace 'root/microsoft/Windows/DesiredStateConfiguration' `
                                -ClientOnly `
                                -Property @{
                                    accessType  = 'Allow'
                                    users       = 'User1'
                                    roles       = ''
                                    permissions = 'Read'
                                }
            )

            $MockBindingInfo = @(
                New-CimInstance -ClassName MSFT_xFTPBindingInformation `
                                -Namespace 'root/microsoft/Windows/DesiredStateConfiguration' `
                                -ClientOnly `
                                -Property @{
                                    Protocol = 'ftp'
                                    Port     = '21'
                                    HostName = 'ftp.server'
                                }
            )

            $MockSslInfo = New-CimInstance `
                                -ClassName MSFT_xFTPSslInformation `
                                -Namespace 'root/microsoft/Windows/DesiredStateConfiguration' `
                                -ClientOnly `
                                -Property @{
                                    controlChannelPolicy = 'SslAllow'
                                    dataChannelPolicy    = 'SslAllow'
                                    ssl128               = 'True'
                                    serverCertHash       = ''
                                    serverCertStoreName  = 'My'
                                }

            $MockLogOutput = @{
                directory         = '%SystemDrive%\inetpub\logs\LogFiles'
                logExtFileFlags   = 'Date,Time,ClientIP,UserName,ServerIP,Method'
                period            = 'Daily'
                truncateSize      = '1048576'
                localTimeRollover = 'False'
            }

            $MockMessageOutput = @{
                greetingMessage          = 'Greetings, %UserName%!'
                exitMessage              = 'Bye, %UserName%!'
                bannerMessage            = "%UserName%, you've been watched.."
                maxClientsMessage        = 'Sorry, %UserName%, try to connect again in an hour.'
                suppressDefaultBanner    = $true
                allowLocalDetailedErrors = $false
                expandVariables          = $true
            }

            $MockFtpServerInfo = @(
                @{
                    userIsolation = @{
                        mode = 'IsolateAllDirectories'
                    }
                }
                @{
                    directoryBrowse = @{
                        showFlags = 'LongDate'
                    }
                }
                @{
                    security = @{
                        ssl = @(
                            New-Object -TypeName PSObject -Property @{
                                serverCertHash       = 'EF8D5381178A622886A30CBBB46BBA8F4AFAAC97'
                                serverCertStoreName  = 'MY'
                                ssl128               = 'True'
                                controlChannelPolicy = 'SslAllow'
                                dataChannelPolicy    = 'SslAllow'
                            }
                        )
                    }
                }
                @{
                    firewallSupport = @{
                        externalIp4Address = '10.0.0.10'
                    }
                }
                @{
                    messages = $MockMessageOutput
                }
                @{
                    logfile = $MockLogOutput
                }
            )

            $MockDefaultFirewallSupport = @{
                lowDataChannelPort  = 0
                highDataChannelPort = 0
            }

            $MockCredential = New-Object System.Management.Automation.PSCredential ('MockUser', `
                                    (ConvertTo-SecureString -String 'MockPassword' -AsPlainText -Force))

            $MockParameters = @{
                Ensure                    = 'Present'
                Name                      = 'MockFtp'
                PhysicalPath              = 'C:\NonExistent'
                PhysicalPathCredential    = $MockCredential
                State                     = 'Stopped'
                ApplicationPool           = 'MockFtpPool'
                AuthorizationInfo         = $MockAuthorizationInfo
                BindingInfo               = $MockBindingInfo
                SslInfo                   = $MockSslInfo
                FirewallIPAddress         = '192.168.0.20'
                StartingDataChannelPort   = 10550
                EndingDataChannelPort     = 10600
                GreetingMessage           = 'Mock hello'
                ExitMessage               = 'Mock exit'
                BannerMessage             = 'Mock banner'
                MaxClientsMessage         = 'Mock message max client'
                SuppressDefaultBanner     = $false
                AllowLocalDetailedErrors  = $true
                ExpandVariablesInMessages = $false
                LogPath                   = '%SystemDrive%\DifferentLogFiles'
                LogFlags                  = @('Date','Time','ClientIP','UserName','ServerIP')
                LogPeriod                 = 'Hourly'
                LogTruncateSize           = '2048570'
                LoglocalTimeRollover      = $true
                DirectoryBrowseFlags      = 'StyleUnix'
                UserIsolation             = 'StartInUsersDirectory'
            }

            $MockWebsite = @{
                Name               = 'MockFtp'
                PhysicalPath       = 'C:\Different'
                userName           = ''
                password           = ''
                State              = 'Started'
                ApplicationPool    = 'MockPoolDifferent'
                AuthenticationInfo = $MockAuthenticationInfo
                AuthorizationInfo  = $MockAuthorizationInfo
                Bindings           = @{Collection = @($MockBindingInfo)}
                ftpServer          = $MockFtpServerInfo
                Count              = 1
            }

            Mock -CommandName Get-Website -MockWith {return $MockWebsite}

            Context 'Website does not exist' {

                Mock -CommandName Get-Website

                $Result = Test-TargetResource -Ensure $MockParameters.Ensure `
                                              -Name $MockParameters.Name

                It 'Should return False' {
                    $Result | Should Be $false
                }
            }

            Context 'Check PhysicalPath is different' {

                Mock -CommandName Get-WebConfiguration
                Mock -CommandName Test-AuthenticationInfo -MockWith {return $true}

                $Result = Test-TargetResource -Ensure $MockParameters.Ensure `
                                              -Name $MockParameters.Name `
                                              -PhysicalPath $MockParameters.PhysicalPath

                It 'Should return False' {
                    $Result | Should Be $false
                }
            }

            Context 'Check PhysicalPathCredential is different' {

                Mock -CommandName Get-WebConfiguration
                Mock -CommandName Test-AuthenticationInfo -MockWith {return $true}
                Mock -ModuleName $DSCHelperModuleName `
                    -CommandName Get-Website `
                    -MockWith {return $MockWebsite}

                $Result = Test-TargetResource -Ensure $MockParameters.Ensure `
                                              -Name $MockParameters.Name `
                                              -PhysicalPathCredential $MockParameters.PhysicalPathCredential

                It 'Should return False' {
                    $Result | Should Be $false
                }
            }

            Context 'Check State is different' {

                Mock -CommandName Get-WebConfiguration
                Mock -CommandName Get-Website -MockWith {return $MockWebsite}
                Mock -CommandName Test-AuthenticationInfo -MockWith {return $true}

                $Result = Test-TargetResource -Ensure $MockParameters.Ensure `
                                              -Name $MockParameters.Name `
                                              -State $MockParameters.State

                It 'Should return False' {
                    $Result | Should Be $false
                }
            }

            Context 'Check ApplicationPool is different' {

                Mock -CommandName Get-WebConfiguration
                Mock -CommandName Get-Website -MockWith {return $MockWebsite}
                Mock -CommandName Test-AuthenticationInfo -MockWith {return $true}

                $Result = Test-TargetResource -Name $MockParameters.Name `
                                              -Ensure $MockParameters.Ensure `
                                              -ApplicationPool $MockParameters.ApplicationPool

                It 'Should return False' {
                    $Result | Should Be $false
                }
            }

            Context 'Check AuthenticationInfo is different' {

                Mock -CommandName Get-WebConfiguration

                Mock -ModuleName $DSCHelperModuleName `
                     -CommandName Get-ItemProperty `
                     -MockWith { return @{ Value = $false } } `
                     -ParameterFilter { $Name -eq 'ftpServer.security.authentication.AnonymousAuthentication.enabled'}

                Mock -ModuleName $DSCHelperModuleName `
                     -CommandName Get-ItemProperty `
                     -MockWith { return @{ Value = $false } } `
                     -ParameterFilter { $Name -eq 'ftpServer.security.authentication.BasicAuthentication.enabled' }

                $MockAuthenticationInfo = New-CimInstance -ClassName MSFT_xWebAuthenticationInformation `
                                                          -ClientOnly `
                                                          -Property @{ Anonymous=$true; Basic=$true } `
                                                          -Namespace 'root/microsoft/Windows/DesiredStateConfiguration'

                $Result = Test-TargetResource -Ensure $MockParameters.Ensure `
                                              -Name $MockParameters.Name `
                                              -AuthenticationInfo $MockAuthenticationInfo

                It 'Should return False' {
                    $Result | Should Be $false
                }
            }

            Context 'Check AuthenticationInfo is different from default' {

                Mock -CommandName Get-WebConfiguration

                Mock -ModuleName $DSCHelperModuleName `
                     -CommandName Get-ItemProperty `
                     -MockWith { return @{ Value = $true } } `
                     -ParameterFilter { $Name -eq 'ftpServer.security.authentication.AnonymousAuthentication.enabled'}

                Mock -ModuleName $DSCHelperModuleName `
                     -CommandName Get-ItemProperty `
                     -MockWith { return @{ Value = $false } } `
                     -ParameterFilter { $Name -eq 'ftpServer.security.authentication.BasicAuthentication.enabled' }

                $Result = Test-TargetResource -Ensure $MockParameters.Ensure `
                                              -Name $MockParameters.Name

                It 'Should return False' {
                    $Result | Should Be $false
                }
            }

            Context 'Check BindingInfo is different' {

                Mock -CommandName Get-WebConfiguration
                Mock -CommandName Test-WebsiteBinding -MockWith {$false}
                Mock -CommandName Test-AuthenticationInfo -MockWith {return $true}

                $Result = Test-TargetResource -Name $MockParameters.Name `
                                              -Ensure $MockParameters.Ensure `
                                              -BindingInfo $MockBindingInfo

                It 'Should return False' {
                    $Result | Should Be $false
                }
            }

            Context 'Check AuthorizationInfo is different' {

                Mock -CommandName Get-WebConfiguration
                Mock -CommandName Test-AuthorizationInfo -MockWith {return $false}
                Mock -CommandName Test-AuthenticationInfo -MockWith {return $true}

                $Result = Test-TargetResource -Ensure $MockParameters.Ensure `
                                              -Name $MockParameters.Name `
                                              -AuthorizationInfo $MockAuthorizationInfo

                It 'Should return False' {
                    $Result | Should Be $false
                }
            }

            Context 'Check SslInfo is different' {

                Mock -CommandName Get-WebConfiguration
                Mock -CommandName Confirm-UniqueSslInfo -MockWith {return $false}
                Mock -CommandName Test-AuthenticationInfo -MockWith {return $true}

                $Result = Test-TargetResource -Ensure $MockParameters.Ensure `
                                              -Name $MockParameters.Name `
                                              -SslInfo $MockSslInfo

                It 'Should return False' {
                    $Result | Should Be $false
                }
            }

            Context 'Check FirewallIPAddress is different' {

                Mock -CommandName Get-WebConfiguration
                Mock -CommandName Test-AuthenticationInfo -MockWith {return $true}

                $Result = Test-TargetResource -Ensure $MockParameters.Ensure `
                                              -Name $MockParameters.Name `
                                              -FirewallIPAddress $MockParameters.FirewallIPAddress

                It 'Should return False' {
                    $Result | Should Be $false
                }
            }

            Context 'Check StartingDataChannelPort is different' {

                Mock -CommandName Test-AuthenticationInfo -MockWith {return $true}
                Mock -CommandName Get-WebConfiguration `
                     -ParameterFilter { $Filter -eq '/system.ftpServer/firewallSupport' } `
                     -MockWith { return $MockDefaultFirewallSupport }

                $Result = Test-TargetResource -Ensure $MockParameters.Ensure `
                                              -Name $MockParameters.Name `
                                              -StartingDataChannelPort $MockParameters.StartingDataChannelPort

                It 'Should return False' {
                    $Result | Should Be $false
                }
            }

            Context 'Check EndingDataChannelPort is different' {

                Mock -CommandName Test-AuthenticationInfo -MockWith {return $true}
                Mock -CommandName Get-WebConfiguration `
                     -ParameterFilter { $Filter -eq '/system.ftpServer/firewallSupport' } `
                     -MockWith { return $MockDefaultFirewallSupport }

                $Result = Test-TargetResource -Ensure $MockParameters.Ensure `
                                              -Name $MockParameters.Name `
                                              -EndingDataChannelPort $MockParameters.EndingDataChannelPort

                It 'Should return False' {
                    $Result | Should Be $false
                }
            }

            Context 'Check GreetingMessage is different' {

                Mock -CommandName Get-WebConfiguration
                Mock -CommandName Get-Website -MockWith {return $MockWebsite}
                Mock -CommandName Test-AuthenticationInfo -MockWith {return $true}

                $Result = Test-TargetResource -Name $MockParameters.Name `
                                              -Ensure $MockParameters.Ensure `
                                              -GreetingMessage $MockParameters.GreetingMessage

                It 'Should return False' {
                    $Result | Should Be $false
                }
            }

            Context 'Check ExitMessage is different' {

                Mock -CommandName Get-WebConfiguration
                Mock -CommandName Get-Website -MockWith {return $MockWebsite}
                Mock -CommandName Test-AuthenticationInfo -MockWith {return $true}

                $Result = Test-TargetResource -Name $MockParameters.Name `
                                              -Ensure $MockParameters.Ensure `
                                              -ExitMessage $MockParameters.ExitMessage

                It 'Should return False' {
                    $Result | Should Be $false
                }
            }

            Context 'Check BannerMessage is different' {

                Mock -CommandName Get-WebConfiguration
                Mock -CommandName Get-Website -MockWith {return $MockWebsite}
                Mock -CommandName Test-AuthenticationInfo -MockWith {return $true}

                $Result = Test-TargetResource -Name $MockParameters.Name `
                                              -Ensure $MockParameters.Ensure `
                                              -BannerMessage $MockParameters.BannerMessage

                It 'Should return False' {
                    $Result | Should Be $false
                }
            }

            Context 'Check MaxClientsMessage is different' {

                Mock -CommandName Get-WebConfiguration
                Mock -CommandName Get-Website -MockWith {return $MockWebsite}
                Mock -CommandName Test-AuthenticationInfo -MockWith {return $true}

                $Result = Test-TargetResource -Name $MockParameters.Name `
                                              -Ensure $MockParameters.Ensure `
                                              -MaxClientsMessage $MockParameters.MaxClientsMessage

                It 'Should return False' {
                    $Result | Should Be $false
                }
            }

            Context 'Check SuppressDefaultBanner is different' {

                Mock -CommandName Get-WebConfiguration
                Mock -CommandName Get-Website -MockWith {return $MockWebsite}
                Mock -CommandName Test-AuthenticationInfo -MockWith {return $true}

                $Result = Test-TargetResource -Name $MockParameters.Name `
                                              -Ensure $MockParameters.Ensure `
                                              -SuppressDefaultBanner $MockParameters.SuppressDefaultBanner

                It 'Should return False' {
                    $Result | Should Be $false
                }
            }

            Context 'Check AllowLocalDetailedErrors is different' {

                Mock -CommandName Get-WebConfiguration
                Mock -CommandName Get-Website -MockWith {return $MockWebsite}
                Mock -CommandName Test-AuthenticationInfo -MockWith {return $true}

                $Result = Test-TargetResource -Name $MockParameters.Name `
                                              -Ensure $MockParameters.Ensure `
                                              -AllowLocalDetailedErrors $MockParameters.AllowLocalDetailedErrors

                It 'Should return False' {
                    $Result | Should Be $false
                }
            }

            Context 'Check ExpandVariablesInMessages is different' {

                Mock -CommandName Get-WebConfiguration
                Mock -CommandName Get-Website -MockWith {return $MockWebsite}
                Mock -CommandName Test-AuthenticationInfo -MockWith {return $true}

                $Result = Test-TargetResource -Name $MockParameters.Name `
                                              -Ensure $MockParameters.Ensure `
                                              -ExpandVariablesInMessages $MockParameters.ExpandVariablesInMessages

                It 'Should return False' {
                    $Result | Should Be $false
                }
            }

            Context 'Check LogPath is different' {

                Mock -CommandName Get-WebConfiguration
                Mock -CommandName Test-AuthenticationInfo -MockWith {return $true}
                Mock -ModuleName $DSCHelperModuleName `
                     -CommandName Get-Website `
                     -MockWith {return $MockWebsite}

                $Result = Test-TargetResource -Ensure $MockParameters.Ensure `
                                              -Name $MockParameters.Name `
                                              -LogPath $MockParameters.LogPath

                It 'Should return False' {
                    $Result | Should Be $false
                }
            }

            Context 'Check LogFlags is different' {

                Mock -CommandName Get-WebConfiguration
                Mock -CommandName Test-AuthenticationInfo -MockWith {return $true}
                Mock -ModuleName $DSCHelperModuleName `
                     -CommandName Get-Website `
                     -MockWith {return $MockWebsite}

                $Result = Test-TargetResource -Ensure $MockParameters.Ensure `
                                              -Name $MockParameters.Name `
                                              -LogFlags $MockParameters.LogFlags

                It 'Should return False' {
                    $Result | Should Be $false
                }
            }

            Context 'Check LogPeriod is different' {

                Mock -CommandName Get-WebConfiguration
                Mock -CommandName Test-AuthenticationInfo -MockWith {return $true}
                Mock -ModuleName $DSCHelperModuleName `
                     -CommandName Get-Website `
                     -MockWith {return $MockWebsite}

                $Result = Test-TargetResource -Ensure $MockParameters.Ensure `
                                              -Name $MockParameters.Name `
                                              -LogPeriod $MockParameters.LogPeriod

                It 'Should return False' {
                    $Result | Should Be $false
                }
            }

            Context 'Check if LogPeriod is ignored with LogTruncateSize set' {

                Mock -CommandName Get-WebConfiguration
                Mock -CommandName Test-AuthenticationInfo -MockWith {return $true}
                Mock -ModuleName $DSCHelperModuleName `
                     -CommandName Get-Website `
                     -MockWith {return $MockWebsite}

                $Result = Test-TargetResource -Ensure $MockParameters.Ensure `
                                              -Name $MockParameters.Name `
                                              -LogPeriod $MockParameters.LogPeriod `
                                              -LogTruncateSize 1048576

                It 'Should return True' {
                    $Result | Should Be $true
                }
            }

            Context 'Check LogTruncateSize is different' {

                Mock -CommandName Get-WebConfiguration
                Mock -CommandName Test-AuthenticationInfo -MockWith {return $true}
                Mock -ModuleName $DSCHelperModuleName `
                     -CommandName Get-Website `
                     -MockWith {return $MockWebsite}

                $Result = Test-TargetResource -Ensure $MockParameters.Ensure `
                                              -Name $MockParameters.Name `
                                              -LogTruncateSize $MockParameters.LogTruncateSize

                It 'Should return False' {
                    $Result | Should Be $false
                }
            }

            Context 'Check LoglocalTimeRollover is different' {

                Mock -CommandName Get-WebConfiguration
                Mock -CommandName Test-AuthenticationInfo -MockWith {return $true}
                Mock -ModuleName $DSCHelperModuleName `
                     -CommandName Get-Website `
                     -MockWith {return $MockWebsite}

                $Result = Test-TargetResource -Ensure $MockParameters.Ensure `
                                              -Name $MockParameters.Name `
                                              -LoglocalTimeRollover $MockParameters.LoglocalTimeRollover

                It 'Should return False' {
                    $Result | Should Be $false
                }
            }

            Context 'Check DirectoryBrowseFlags is different' {

                Mock -CommandName Get-WebConfiguration
                Mock -CommandName Test-AuthenticationInfo -MockWith {return $true}

                $Result = Test-TargetResource -Ensure $MockParameters.Ensure `
                                              -Name $MockParameters.Name `
                                              -DirectoryBrowseFlags $MockParameters.DirectoryBrowseFlags

                It 'Should return False' {
                    $Result | Should Be $false
                }
            }

            Context 'Check UserIsolation is different' {

                Mock -CommandName Get-WebConfiguration
                Mock -CommandName Test-AuthenticationInfo -MockWith {return $true}

                $Result = Test-TargetResource -Ensure $MockParameters.Ensure `
                                              -Name $MockParameters.Name `
                                              -UserIsolation $MockParameters.UserIsolation

                It 'Should return False' {
                    $Result | Should Be $false
                }
            }
        }

        Describe "how $DSCResourceName\Set-TargetResource responds to Ensure = 'Present'" {

            $MockAuthenticationInfo = New-CimInstance `
                                            -ClassName MSFT_xFTPAuthenticationInformation `
                                            -Namespace 'root/microsoft/Windows/DesiredStateConfiguration' `
                                            -ClientOnly `
                                            -Property @{
                                                Anonymous = $true
                                                Basic     = $false
                                            }

            $MockAuthorizationInfo = @(
                New-CimInstance -ClassName MSFT_xFTPAuthorizationInformation `
                                -Namespace 'root/microsoft/Windows/DesiredStateConfiguration' `
                                -ClientOnly `
                                -Property @{
                                    accessType  = 'Allow'
                                    users       = 'User1'
                                    roles       = ''
                                    permissions = 'Read'
                                }
            )

            $MockBindingInfo = @(
                New-CimInstance -ClassName MSFT_xFTPBindingInformation `
                                -Namespace 'root/microsoft/Windows/DesiredStateConfiguration' `
                                -ClientOnly `
                                -Property @{
                                    Protocol = 'ftp'
                                    Port     = '21'
                                    HostName = 'ftp.server'
                                }
            )

            $MockSslInfo = New-CimInstance `
                                -ClassName MSFT_xFTPSslInformation `
                                -Namespace 'root/microsoft/Windows/DesiredStateConfiguration' `
                                -ClientOnly `
                                -Property @{
                                    controlChannelPolicy = 'SslAllow'
                                    dataChannelPolicy    = 'SslAllow'
                                    ssl128               = 'True'
                                    serverCertHash       = 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAA1234567890'
                                    serverCertStoreName  = 'My'
                                }

            $MockCredential = New-Object System.Management.Automation.PSCredential ('MockUser', `
                                (ConvertTo-SecureString -String 'MockPassword' -AsPlainText -Force))

            $MockParameters = @{
                Ensure                    = 'Present'
                Name                      = 'MockFtp'
                PhysicalPath              = 'C:\NonExistent'
                PhysicalPathCredential    = $MockCredential
                State                     = 'Started'
                ApplicationPool           = 'MockFtpPool'
                AuthenticationInfo        = $MockAuthenticationInfo
                AuthorizationInfo         = $MockAuthorizationInfo
                BindingInfo               = $MockBindingInfo
                SslInfo                   = $MockSslInfo
                FirewallIPAddress         = ''
                StartingDataChannelPort   = 0
                EndingDataChannelPort     = 0
                GreetingMessage           = 'Mock hello'
                ExitMessage               = 'Mock exit'
                BannerMessage             = 'Mock banner'
                MaxClientsMessage         = 'Mock message max client'
                SuppressDefaultBanner     = $false
                AllowLocalDetailedErrors  = $true
                ExpandVariablesInMessages = $false
                LogPath                   = '%SystemDrive%\LogFiles'
                LogFlags                  = @('Date','Time','ClientIP','UserName','ServerIP','Method')
                LogPeriod                 = 'Daily'
                LoglocalTimeRollover      = $true
                DirectoryBrowseFlags      = 'StyleUnix'
                UserIsolation             = 'StartInUsersDirectory'
            }

            $DifferentMockLogOutput = @{
                directory         = '%SystemDrive%\inetpub\logs\LogFiles'
                logExtFileFlags   = 'Date,Time,ClientIP,UserName,ServerIP'
                period            = 'Hourly'
                truncateSize      = '1048576'
                localTimeRollover = 'False'
            }

            $DifferentMockAuthenticationInfo = New-CimInstance `
                                                    -ClassName MSFT_xFTPAuthenticationInformation `
                                                    -Namespace 'root/microsoft/Windows/DesiredStateConfiguration' `
                                                    -ClientOnly `
                                                    -Property @{
                                                        Anonymous = $true
                                                        Basic     = $true
                                                    }

            $DifferentMockAuthorizationInfo = @(
                New-CimInstance -ClassName MSFT_xFTPAuthorizationInformation `
                                -Namespace 'root/microsoft/Windows/DesiredStateConfiguration' `
                                -ClientOnly `
                                -Property @{
                                    accessType  = 'Allow'
                                    users       = 'User1'
                                    roles       = ''
                                    permissions = 'Read'
                                }
            )

            $DifferentMockBindingInfo = @(
                New-CimInstance -ClassName MSFT_xFTPBindingInformation `
                                -Namespace 'root/microsoft/Windows/DesiredStateConfiguration' `
                                -ClientOnly `
                                -Property @{
                                    Protocol = 'ftp'
                                    Port     = '21'
                                    HostName = 'ftp.server'
                                }
            )

            $DifferentMockSslInfo = New-CimInstance `
                                        -ClassName MSFT_xFTPSslInformation `
                                        -Namespace 'root/microsoft/Windows/DesiredStateConfiguration' `
                                        -ClientOnly `
                                        -Property @{
                                            controlChannelPolicy = 'SslAllow'
                                            dataChannelPolicy    = 'SslAllow'
                                            ssl128               = 'True'
                                            serverCertHash       = 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAA1234567890'
                                            serverCertStoreName  = 'My'
                                        }

            $MockMessageOutput = @{
                greetingMessage          = 'Greetings, %UserName%!'
                exitMessage              = 'Bye, %UserName%!'
                bannerMessage            = "%UserName%, you've been watched.."
                maxClientsMessage        = 'Sorry, %UserName%, try to connect again in an hour.'
                suppressDefaultBanner    = $true
                allowLocalDetailedErrors = $false
                expandVariables          = $true
            }

            $DifferentMockFtpServerInfo = @(
                @{
                    userIsolation = @{
                        mode = 'IsolateAllDirectories'
                    }
                }
                @{
                    directoryBrowse = @{
                        showFlags = 'LongDate'
                    }
                }
                @{
                    security = @{
                        ssl = @(
                            New-Object -TypeName PSObject -Property  @{
                                serverCertHash       = 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAA1234567890'
                                serverCertStoreName  = 'MY'
                                ssl128               = 'True'
                                controlChannelPolicy = 'SslAllow'
                                dataChannelPolicy    = 'SslAllow'
                            }
                        )
                    }
                }
                @{
                    firewallSupport = @{
                        externalIp4Address = 10.0.0.10
                    }
                }
                @{
                    messages = $MockMessageOutput
                }
                @{
                    logfile = $DifferentMockLogOutput
                }
            )

            $MockDefaultFirewallSupport = @{
                lowDataChannelPort  = 10500
                highDataChannelPort = 10600
            }

            $MockFtpAuthorization = @{
                accessType  = 'Allow'
                users       = ''
                roles       = 'User1'
                permissions = 'Read'
            }

            $MockWebsite = @{
                Name               = 'MockFtp'
                PhysicalPath       = 'C:\Different'
                userName           = ''
                password           = ''
                State              = ''
                ApplicationPool    = 'DifferentMockFtpPool'
                AuthenticationInfo = $DifferentMockAuthenticationInfo
                AuthorizationInfo  = $DifferentMockAuthorizationInfo
                SslInfo            = $DifferentMockSslInfo
                Bindings           = @{Collection = @($DifferentMockBindingInfo)}
                ftpServer          = $DifferentMockFtpServerInfo
                Count              = 1
            }

            Context 'All properties need to be updated and webftpsite must be started' {

                Mock -ModuleName $DSCHelperModuleName `
                     -CommandName Get-ItemProperty `
                     -MockWith { return @{ Value = $false } } `
                     -ParameterFilter { $Name -eq 'ftpServer.security.authentication.AnonymousAuthentication.enabled' }

                Mock -ModuleName $DSCHelperModuleName `
                     -CommandName Get-ItemProperty `
                     -MockWith { return @{ Value = $false } } `
                     -ParameterFilter { $Name -eq 'ftpServer.security.authentication.BasicAuthentication.enabled' }

                Mock -CommandName Get-WebConfiguration `
                     -MockWith { return $null } `
                     -ParameterFilter { $filter -eq '/system.ftpServer/security/authorization' }

                Mock -CommandName Get-WebConfiguration `
                     -MockWith { return $MockDefaultFirewallSupport } `
                     -ParameterFilter { $Filter -eq '/system.ftpServer/firewallSupport' }

                Mock -ModuleName $DSCHelperModuleName -CommandName Set-Authentication
                Mock -ModuleName $DSCHelperModuleName -CommandName Get-Website -MockWith {return $MockWebsite}
                Mock -CommandName Update-AccessCredential
                Mock -CommandName Set-WebConfigurationProperty
                Mock -CommandName Set-ItemProperty
                Mock -CommandName Get-Website -MockWith {return $MockWebsite}
                Mock -CommandName Start-Website
                Mock -CommandName New-Webftpsite -MockWith {return $MockWebsite}
                Mock -CommandName Set-FTPAuthorization
                Mock -CommandName Update-WebsiteBinding
                Mock -CommandName Set-SslInfo
                Mock -CommandName Confirm-UniqueSslInfo { return $false }

                Set-TargetResource @MockParameters

                It 'Should call all the mocks' {
                    Assert-MockCalled -CommandName Set-ItemProperty -Exactly 16
                    Assert-MockCalled -CommandName Start-Website -Exactly 1
                    Assert-MockCalled -CommandName Set-SslInfo -Exactly 1
                    Assert-MockCalled -CommandName Set-FTPAuthorization -Exactly 1
                    Assert-MockCalled -CommandName Set-WebConfigurationProperty -Exactly 2
                    Assert-MockCalled -CommandName Update-AccessCredential -Exactly 1
                    Assert-MockCalled -ModuleName $DSCHelperModuleName `
                                      -CommandName Get-Website -Exactly 3
                    Assert-MockCalled -CommandName Update-WebsiteBinding -Exactly 1
                    Assert-MockCalled -ModuleName $DSCHelperModuleName `
                                      -CommandName Set-Authentication -Exactly 2
                }
            }

            Context 'All properties need to be updated and webftpsite must be stopped' {

                $MockParameters       = $MockParameters.Clone()
                $MockParameters.State = 'Stopped'

                $MockWebsite       = $MockWebsite.Clone()
                $MockWebsite.State = 'Started'

                Mock -ModuleName $DSCHelperModuleName `
                     -CommandName Get-ItemProperty `
                     -MockWith { return @{ Value = $false } } `
                     -ParameterFilter { $Name -eq 'ftpServer.security.authentication.AnonymousAuthentication.enabled' }

                Mock -ModuleName $DSCHelperModuleName `
                     -CommandName Get-ItemProperty `
                     -MockWith { return @{ Value = $false } } `
                     -ParameterFilter { $Name -eq 'ftpServer.security.authentication.BasicAuthentication.enabled' }

                Mock -CommandName Get-WebConfiguration `
                     -MockWith { return $null } `
                     -ParameterFilter { $filter -eq '/system.ftpServer/security/authorization' }

                Mock -CommandName Get-WebConfiguration `
                     -MockWith { return $MockDefaultFirewallSupport } `
                     -ParameterFilter { $Filter -eq '/system.ftpServer/firewallSupport' }

                Mock -CommandName Set-FTPAuthorization
                Mock -CommandName Get-Website -MockWith {return $MockWebsite}
                Mock -ModuleName $DSCHelperModuleName -CommandName Get-Website -MockWith {return $MockWebsite}
                Mock -CommandName Set-ItemProperty
                Mock -CommandName Set-WebConfigurationProperty
                Mock -ModuleName $DSCHelperModuleName -CommandName Set-Authentication
                Mock -CommandName Stop-Website
                Mock -CommandName New-Webftpsite -MockWith {return $MockWebsite}
                Mock -CommandName Set-FTPAuthorization
                Mock -CommandName Update-WebsiteBinding
                Mock -CommandName Update-AccessCredential
                Mock -CommandName Set-SslInfo
                Mock -CommandName Confirm-UniqueSslInfo { return $false }

                Set-TargetResource @MockParameters

                It 'Should call all the mocks' {
                    Assert-MockCalled -CommandName Set-ItemProperty -Exactly 16
                    Assert-MockCalled -CommandName Set-WebConfigurationProperty -Exactly 2
                    Assert-MockCalled -CommandName Update-AccessCredential -Exactly 1
                    Assert-MockCalled -CommandName Stop-Website -Exactly 1
                    Assert-MockCalled -CommandName Set-SslInfo -Exactly 1
                    Assert-MockCalled -CommandName Set-FTPAuthorization -Exactly 1
                    Assert-MockCalled -CommandName Update-WebsiteBinding -Exactly 1
                    Assert-MockCalled -ModuleName $DSCHelperModuleName `
                                      -CommandName Set-Authentication -Exactly 2
                }
            }

            Context 'webftpsite does not exist' {

                Mock -ModuleName $DSCHelperModuleName `
                     -CommandName Get-ItemProperty `
                     -MockWith { return @{ Value = $false } } `
                     -ParameterFilter { $Name -eq 'ftpServer.security.authentication.AnonymousAuthentication.enabled' }

                Mock -ModuleName $DSCHelperModuleName `
                     -CommandName Get-ItemProperty `
                     -MockWith { return @{ Value = $false } } `
                     -ParameterFilter { $Name -eq 'ftpServer.security.authentication.BasicAuthentication.enabled' }

                Mock -CommandName Get-WebConfiguration `
                     -MockWith { return $null } `
                     -ParameterFilter { $filter -eq '/system.ftpServer/security/authorization' }

                Mock -CommandName Get-WebConfiguration `
                     -MockWith { return $MockDefaultFirewallSupport } `
                     -ParameterFilter { $Filter -eq '/system.ftpServer/firewallSupport' }

                Mock -CommandName Get-Website { return $null }
                Mock -ModuleName $DSCHelperModuleName -CommandName Get-Website -MockWith {return $null}
                Mock -CommandName Update-AccessCredential
                Mock -CommandName Set-FTPAuthorization
                Mock -ModuleName $DSCHelperModuleName -CommandName Set-Authentication
                Mock -CommandName Set-ItemProperty
                Mock -CommandName Set-WebConfigurationProperty
                Mock -CommandName Start-Website
                Mock -CommandName New-Webftpsite -MockWith {return $MockWebsite}
                Mock -CommandName Set-FTPAuthorization
                Mock -CommandName Update-WebsiteBinding
                Mock -CommandName Set-SslInfo
                Mock -CommandName Confirm-UniqueSslInfo { return $false }

                Set-TargetResource @MockParameters

                It 'Should call all the mocks' {
                    Assert-MockCalled -CommandName Set-ItemProperty -Exactly 16
                    Assert-MockCalled -CommandName Set-WebConfigurationProperty -Exactly 2
                    Assert-MockCalled -CommandName New-Webftpsite -Exactly 1
                    Assert-MockCalled -CommandName Set-SslInfo -Exactly 1
                    Assert-MockCalled -CommandName Set-FTPAuthorization -Exactly 1
                    Assert-MockCalled -CommandName Update-WebsiteBinding -Exactly 1
                    Assert-MockCalled -CommandName Update-AccessCredential -Exactly 1
                }
            }

            Context 'New-Webftpsite throws an error' {

                Mock -CommandName Get-Website
                Mock -CommandName Get-WebConfiguration
                Mock -CommandName New-Webftpsite -MockWith {throw}

                It 'Should throw the correct error' {
                    $ErrorId       = 'ErrorFtpSiteCreationFailure'
                    $ErrorCategory = [System.Management.Automation.ErrorCategory]::InvalidOperation
                    $ErrorMessage  = $LocalizedData.ErrorFtpSiteCreationFailure -f $MockParameters.Name, 'ScriptHalted'
                    $Exception     = New-Object -TypeName System.InvalidOperationException `
                                                -ArgumentList $ErrorMessage
                    $ErrorRecord   = New-Object -TypeName System.Management.Automation.ErrorRecord `
                                                -ArgumentList $Exception, $ErrorId, $ErrorCategory, $null

                    { Set-TargetResource @MockParameters } | Should Throw $ErrorRecord
                }
            }
        }

        Describe "how $DSCResourceName\Compare-DirectoryBrowseFlags responds" {

            Context 'Returns False when DirectoryBrowseFlags are incorrect' {

                $MockLogOutput = @{
                    directoryBrowse = @{
                        showFlags = 'LongDate'
                    }
                }

                $MockWebsite = @{
                    Name      = 'MockFtp'
                    ftpServer = $MockLogOutput
                }

                Mock -CommandName Get-WebSite -MockWith { return $MockWebsite }

                $result = Compare-DirectoryBrowseFlags -Site $MockWebsite.Name -DirectoryBrowseflags 'StyleUnix'

                It 'Should return False' {
                    $result | Should be $false
                }
            }

            Context 'Returns True when DirectoryBrowseFlags are correct' {

                $MockLogOutput = @{
                    directoryBrowse = @{
                        showFlags = 'LongDate'
                    }
                }

                $MockWebsite = @{
                    Name      = 'MockFtp'
                    ftpServer = $MockLogOutput
                }

                Mock -CommandName Get-WebSite -MockWith { return $MockWebsite }

                $result = Compare-DirectoryBrowseFlags -Site $MockWebsite.Name -DirectoryBrowseflags 'LongDate'

                It 'Should return True' {
                    $result | Should be $true
                }
            }
        }

        Describe "how $DSCResourceName\Confirm-UniqueFTPAuthorization responds" {

            $MockCurrentFtpAuthorizationInfo =  @(
                [PSCustomObject]@{
                    accessType  = 'Allow'
                    users       = 'User1'
                    roles       = ''
                    permissions = 'Read'
                }
                [PSCustomObject]@{
                    accessType  = 'Deny'
                    users       = 'User1'
                    roles       = ''
                    permissions = 'Write'
                }
                [PSCustomObject]@{
                    accessType  = 'Allow'
                    users       = ''
                    roles       = 'Group2'
                    permissions = 'Read'
                }
                [PSCustomObject]@{
                    accessType  = 'Deny'
                    users       = ''
                    roles       = 'Group2'
                    permissions = 'Write'
                }
            )

            $MockUserAuthorizationInfo = New-CimInstance `
                                            -ClassName MSFT_xFTPAuthorizationInformation `
                                            -Namespace 'root/microsoft/Windows/DesiredStateConfiguration' `
                                            -ClientOnly `
                                            -Property @{
                                                accessType  = 'Deny'
                                                users       = 'User1'
                                                roles       = ''
                                                permissions = 'Write'
                                            }

            $MockGroupAuthorizationInfo = New-CimInstance `
                                            -ClassName MSFT_xFTPAuthorizationInformation `
                                            -Namespace 'root/microsoft/Windows/DesiredStateConfiguration' `
                                            -ClientOnly `
                                            -Property @{
                                                accessType  = 'Deny'
                                                users       = ''
                                                roles       = 'Group2'
                                                permissions = 'Write'
                                            }

            Context 'Returns True when UniqueFTPAuthorization for a user is correct' {

                $result = Confirm-UniqueFTPAuthorization -CurrentAuthorizationCollection $MockCurrentFtpAuthorizationInfo `
                                                         -Authorization $MockUserAuthorizationInfo `
                                                         -Property users

                It 'Should return True' {
                    $result | Should be $true
                }
            }

            Context 'Returns True when UniqueFTPAuthorization for a group is correct' {

                $result = Confirm-UniqueFTPAuthorization -CurrentAuthorizationCollection $MockCurrentFtpAuthorizationInfo `
                                                         -Authorization $MockGroupAuthorizationInfo `
                                                         -Property roles

                It 'Should return True' {
                    $result | Should be $true
                }
            }

            Context 'Returns False when UniqueFTPAuthorization for a user is incorrect' {

                $contextMockUserAuthorizationInfo            = $MockUserAuthorizationInfo.Clone()
                $contextMockUserAuthorizationInfo.accessType = 'Allow'

                $result = Confirm-UniqueFTPAuthorization -CurrentAuthorizationCollection $MockCurrentFtpAuthorizationInfo `
                                                         -Authorization $contextMockUserAuthorizationInfo `
                                                         -Property users

                It 'Should return False' {
                    $result | Should be $false
                }
            }

            Context 'Returns False when UniqueFTPAuthorization for a group is incorrect' {

                $contextMockGroupAuthorizationInfo            = $MockGroupAuthorizationInfo.Clone()
                $contextMockGroupAuthorizationInfo.accessType = 'Allow'

                $result = Confirm-UniqueFTPAuthorization -CurrentAuthorizationCollection $MockCurrentFtpAuthorizationInfo `
                                                         -Authorization $contextMockGroupAuthorizationInfo `
                                                         -Property roles

                It 'Should return False' {
                    $result | Should be $false
                }
            }
        }

        Describe "how $DSCResourceName\Confirm-UniqueSslInfo responds" {

            $MockSslInfo = New-CimInstance `
                                    -ClassName MSFT_xFTPSslInformation `
                                    -Namespace 'root/microsoft/Windows/DesiredStateConfiguration' `
                                    -ClientOnly `
                                    -Property @{
                                        ControlChannelPolicy  = 'SslAllow'
                                        DataChannelPolicy     = 'SslAllow'
                                        RequireSsl128         = $true
                                        CertificateThumbprint = 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAA1234567890'
                                        CertificateStoreName  = 'My'
                                    }

            $MockSslInfoSingle = New-CimInstance `
                                    -ClassName MSFT_xFTPSslInformation `
                                    -Namespace 'root/microsoft/Windows/DesiredStateConfiguration' `
                                    -ClientOnly `
                                    -Property @{
                                        RequireSsl128 = $true
                                    }

            Context 'Returns False when Confirm-UniqueSslInfo is incorrect' {

                $MockFtpServerInfo = @(
                    @{
                        security = @{
                            ssl = @(
                                New-Object -TypeName PSObject -Property @{
                                    serverCertHash       = ''
                                    serverCertStoreName  = ''
                                    ssl128               = $false
                                    controlChannelPolicy = ''
                                    dataChannelPolicy    = ''
                                }
                            )
                        }
                    }
                )

                $MockWebsite = @{
                    Name      = 'MockFtp'
                    ftpServer = $MockFtpServerInfo
                }

                Mock -CommandName Get-WebSite -MockWith { return $MockWebsite }
                Mock -CommandName Test-Path {Return $true}

                $result = Confirm-UniqueSslInfo -Site $MockWebsite.Name -SslInfo $MockSslInfo

                It 'Should return False' {
                    $result | Should be $false
                }
            }

            Context 'Returns True when Confirm-UniqueSslInfo is correct' {

                $MockFtpServerInfo = @(
                    @{
                        security = @{
                            ssl = @(
                                New-Object -TypeName PSObject -Property @{
                                    controlChannelPolicy = 'SslAllow'
                                    dataChannelPolicy    = 'SslAllow'
                                    ssl128               = $true
                                    serverCertHash       = 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAA1234567890'
                                    serverCertStoreName  = 'My'
                                }
                            )
                        }
                    }
                )

                $MockWebsite = @{
                    Name      = 'MockFtp'
                    ftpServer = $MockFtpServerInfo
                }

                Mock -CommandName Test-Path {Return $true}
                Mock -CommandName Get-WebSite -MockWith { return $MockWebsite }

                $result = Confirm-UniqueSslInfo -Site $MockWebsite.Name -SslInfo $MockSslInfo

                It 'Should return True' {
                    $result | Should be $true
                }
            }

            Context 'Returns False when Confirm-UniqueSslInfo is incorrect for single property' {

                $MockFtpServerInfo = @(
                    @{
                        security = @{
                            ssl = @(
                                New-Object -TypeName PSObject -Property @{
                                    serverCertHash       = ''
                                    serverCertStoreName  = ''
                                    ssl128               = $false
                                    controlChannelPolicy = ''
                                    dataChannelPolicy    = ''
                                }
                            )
                        }
                    }
                )

                $MockWebsite = @{
                    Name      = 'MockFtp'
                    ftpServer = $MockFtpServerInfo
                }

                Mock -CommandName Get-WebSite -MockWith { return $MockWebsite }
                Mock -CommandName Test-Path {return $true}

                $result = Confirm-UniqueSslInfo -Site $MockWebsite.Name -SslInfo $MockSslInfoSingle

                It 'Should return False' {
                    $result | Should be $false
                }
            }

            Context 'Returns True when Confirm-UniqueSslInfo is correct for single property' {

                $MockFtpServerInfo = @(
                    @{
                        security = @{
                            ssl = @(
                                New-Object -TypeName PSObject -Property @{
                                    controlChannelPolicy = 'SslAllow'
                                    dataChannelPolicy    = 'SslAllow'
                                    ssl128               = $true
                                    serverCertHash       = 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAA1234567890'
                                    serverCertStoreName  = 'My'
                                }
                            )
                        }
                    }
                )

                $MockWebsite = @{
                    Name      = 'MockFtp'
                    ftpServer = $MockFtpServerInfo
                }

                Mock -CommandName Test-Path {return $true}
                Mock -CommandName Get-WebSite -MockWith { return $MockWebsite }

                $result = Confirm-UniqueSslInfo -Site $MockWebsite.Name -SslInfo $MockSslInfoSingle

                It 'Should return True' {
                    $result | Should be $true
                }
            }

            Context 'Throws when cert does not exist' {

                Mock -CommandName Test-Path {Return $false}

                Mock -CommandName Get-WebSite -MockWith { return $MockWebsite }

                It 'Should throw the correct error' {
                    $ErrorId       = 'ErrorServerCertHashFailure'
                    $ErrorCategory = [System.Management.Automation.ErrorCategory]::InvalidResult
                    $ErrorMessage  = $LocalizedData.ErrorServerCertHashFailure -f $MockSslInfo.CertificateThumbprint, $MockSslInfo.CertificateStoreName
                    $Exception     = New-Object -TypeName System.InvalidOperationException `
                                                -ArgumentList $ErrorMessage
                    $ErrorRecord   = New-Object -TypeName System.Management.Automation.ErrorRecord `
                                                -ArgumentList $Exception, $ErrorId, $ErrorCategory, $null

                    { Confirm-UniqueSslInfo -Site 'Name' -SslInfo $MockSslInfo } | Should Throw $ErrorRecord
                }
            }
        }

        Describe "how $DSCResourceName\Get-SslInfo responds" {

            $MockFtpServerInfo = @{
                ftpServer = @{
                    security = @{
                        ssl = (
                            New-Object -TypeName PSObject -Property @{
                                controlChannelPolicy = 'SslAllow'
                                dataChannelPolicy    = 'SslAllow'
                                ssl128               = $true
                                serverCertHash       = 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAA1234567890'
                                serverCertStoreName  = 'My'
                            }
                        )
                    }
                }
            }

            $MockFtpSite = 'MockFtp'

            Context 'Expected behavior' {

                Mock -CommandName Get-Item -MockWith { return $null }

                It 'Should not throw an error' {
                    { Get-SslInfo -Site $MockFtpSite }|
                    Should Not Throw
                }

                It 'Should call Get-Item 5 times' {
                    Assert-MockCalled -CommandName Get-Item -Exactly 5
                }
            }

            Context 'Returns empty values' {

                Mock -CommandName Get-Item -MockWith { return $null }

                $result = Get-SslInfo -Site $MockFtpSite

                It 'Should contain 5 properties' {
                    $result.CimInstanceProperties.Count | Should Be 5
                }

                It 'Should have all the properties set to empty value' {
                    $result.ControlChannelPolicy  | Should BeNullOrEmpty
                    $result.DataChannelPolicy     | Should BeNullOrEmpty
                    $result.RequireSsl128         | Should Be $false
                    $result.CertificateThumbprint | Should BeNullOrEmpty
                    $result.CertificateStoreName  | Should BeNullOrEmpty
                }

                It 'Should call Get-Item 5 times' {
                    Assert-MockCalled -CommandName Get-Item -Exactly 5
                }
            }

            Context 'Returns proper values' {

                Mock -CommandName Get-Item -MockWith { return $MockFtpServerInfo }

                $result = Get-SslInfo -Site $MockFtpSite

                It 'Should contain 5 properties' {
                    $result.CimInstanceProperties.Count | Should Be 5
                }

                It 'Should have all the properties set' {
                    $result.ControlChannelPolicy  | Should Be 'SslAllow'
                    $result.DataChannelPolicy     | Should Be 'SslAllow'
                    $result.RequireSsl128         | Should Be $true
                    $result.CertificateThumbprint | Should Be 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAA1234567890'
                    $result.CertificateStoreName  | Should Be 'My'
                }

                It 'Should call Get-Item 5 times' {
                    Assert-MockCalled -CommandName Get-Item -Exactly 5
                }
            }
        }

        Describe "how $DSCResourceName\Get-AuthorizationInfo responds" {

            $MockFtpServerInfo = @{
                Collection = @(
                    New-Object -TypeName PSObject -Property @{
                        accessType  = 'Allow'
                        users       = 'MockUser1,MockUser2'
                        roles       = 'MockGroup'
                        permissions = 'Read,Write'
                    }
                    New-Object -TypeName PSObject -Property @{
                        accessType  = 'Deny'
                        users       = 'MockUser3'
                        roles       = 'MockGroup2'
                        permissions = 'Write'
                    }
                )
            }

            $MockFtpSite = 'MockFtp'

            Context 'Expected behavior' {

                Mock -CommandName Get-WebConfiguration -MockWith { return $null }

                It 'Should not throw an error' {
                    { Get-AuthorizationInfo -Site $MockFtpSite }|
                    Should Not Throw
                }

                It 'Should call Get-WebConfiguration 4 times' {
                    Assert-MockCalled -CommandName Get-WebConfiguration -Exactly 1
                }

                It 'Should return nothing' {
                    Get-AuthorizationInfo -Site $MockFtpSite | Should BeNullOrEmpty
                }
            }

            Context 'Returns proper values' {

                Mock -CommandName Get-WebConfiguration -MockWith { return $MockFtpServerInfo }

                $result = Get-AuthorizationInfo -Site $MockFtpSite

                It 'Should contain 4 properties' {
                    $result[0].CimInstanceProperties.Count | Should Be 4
                    $result[1].CimInstanceProperties.Count | Should Be 4
                }

                It 'Should have all the properties set' {
                    $result[0].accessType  | Should Be 'Allow'
                    $result[0].users       | Should Be 'MockUser1,MockUser2'
                    $result[0].roles       | Should Be 'MockGroup'
                    $result[0].permissions | Should Be 'Read,Write'

                    $result[1].accessType  | Should Be 'Deny'
                    $result[1].users       | Should Be 'MockUser3'
                    $result[1].roles       | Should Be 'MockGroup2'
                    $result[1].permissions | Should Be 'Write'
                }

                It 'Should call Get-WebConfiguration once' {
                    Assert-MockCalled -CommandName Get-WebConfiguration -Exactly 1
                }
            }
        }

        Describe "how $DSCResourceName\Set-SslInfo responds" {

            $MockSslInfo = New-CimInstance `
                                -ClassName MSFT_xFTPSslInformation `
                                -Namespace 'root/microsoft/Windows/DesiredStateConfiguration' `
                                -ClientOnly `
                                -Property @{
                                    ControlChannelPolicy  = 'SslAllow'
                                    DataChannelPolicy     = 'SslAllow'
                                    RequireSsl128         = $true
                                    CertificateThumbprint = 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAA1234567890'
                                    CertificateStoreName  = 'My'
                                }

            $MockSslInfoSingle = New-CimInstance `
                                    -ClassName MSFT_xFTPSslInformation `
                                    -Namespace 'root/microsoft/Windows/DesiredStateConfiguration' `
                                    -ClientOnly `
                                    -Property @{
                                        RequireSsl128  = ''
                                    }

            $MockFtpSite = 'MockFtp'

            Mock -CommandName Set-ItemProperty

            Context "Expected behavior" {

                It 'Should not throw an error' {
                    { Set-SslInfo -Site $MockFtpSite -SslInfo $MockSslInfo }|
                    Should Not Throw
                }

                It 'Should call Set-ItemProperty 5 times' {
                    Assert-MockCalled -CommandName Set-ItemProperty -Exactly 5
                }
            }

            Context "Update single property" {

                Set-SslInfo -Site $MockFtpSite -SslInfo $MockSslInfoSingle

                It 'Should call Set-ItemProperty once' {
                    Assert-MockCalled -CommandName Set-ItemProperty -Exactly 1
                }
            }
        }

        Describe "how $DSCResourceName\Set-FTPAuthorization responds" {

            $MockFtpSiteName = 'FTP'

            $MockAuthorizationInfo = @(
                New-CimInstance -ClassName MSFT_xFTPAuthorizationInformation `
                                -Namespace 'root/microsoft/Windows/DesiredStateConfiguration' `
                                -ClientOnly `
                                -Property @{
                                    accessType  = 'Allow'
                                    users       = 'User1'
                                    roles       = 'Group1'
                                    permissions = 'Read'
                                }
                New-CimInstance -ClassName MSFT_xFTPAuthorizationInformation `
                                -Namespace 'root/microsoft/Windows/DesiredStateConfiguration' `
                                -ClientOnly `
                                -Property @{
                                    accessType  = 'Deny'
                                    users       = 'User2'
                                    roles       = 'Group2'
                                    permissions = 'Write'
                                }
            )

            Context "Expected behavior" {

                Mock -CommandName Clear-WebConfiguration
                Mock -CommandName Add-WebConfiguration

                It 'Should not throw an error' {
                    { Set-FTPAuthorization -Site $MockFtpSiteName -AuthorizationInfo $MockAuthorizationInfo }|
                    Should Not Throw
                }

                It 'Should call expected mocks' {
                    Assert-MockCalled -CommandName Clear-WebConfiguration -Exactly 1
                    Assert-MockCalled -CommandName Add-WebConfiguration -Exactly 2
                }
            }
        }

        Describe "how $DSCResourceName\Test-AuthorizationInfo responds" {

            $MockFtpSiteName = 'FTP'

            $MockAuthorizationInfo = @(
                New-CimInstance -ClassName MSFT_xFTPAuthorizationInformation `
                                -Namespace 'root/microsoft/Windows/DesiredStateConfiguration' `
                                -ClientOnly `
                                -Property @{
                                    accessType  = 'Allow'
                                    users       = 'User1'
                                    roles       = ''
                                    permissions = 'Read'
                                }
                New-CimInstance -ClassName MSFT_xFTPAuthorizationInformation `
                                -Namespace 'root/microsoft/Windows/DesiredStateConfiguration' `
                                -ClientOnly `
                                -Property @{
                                    accessType  = 'Deny'
                                    users       = 'User1'
                                    roles       = ''
                                    permissions = 'Write'
                                }
                New-CimInstance -ClassName MSFT_xFTPAuthorizationInformation `
                                -Namespace 'root/microsoft/Windows/DesiredStateConfiguration' `
                                -ClientOnly `
                                -Property @{
                                    accessType  = 'Allow'
                                    users       = ''
                                    roles       = 'Group2'
                                    permissions = 'Read'
                                }
                New-CimInstance -ClassName MSFT_xFTPAuthorizationInformation `
                                -Namespace 'root/microsoft/Windows/DesiredStateConfiguration' `
                                -ClientOnly `
                                -Property @{
                                    accessType  = 'Deny'
                                    users       = ''
                                    roles       = 'Group2'
                                    permissions = 'Write'
                                }
            )

            $MockFtpAuthorizationOutput =  @{
                Collection = @(
                    [PSCustomObject]@{
                        accessType  = 'Deny'
                        users       = 'User1'
                        roles       = ''
                        permissions = 'Write'
                    }
                    [PSCustomObject]@{
                        accessType  = 'Allow'
                        users       = 'User1'
                        roles       = ''
                        permissions = 'Read'
                    }
                    [PSCustomObject]@{
                        accessType  = 'Deny'
                        users       = ''
                        roles       = 'Group2'
                        permissions = 'Write'
                    }
                    [PSCustomObject]@{
                        accessType  = 'Allow'
                        users       = ''
                        roles       = 'Group2'
                        permissions = 'Read'
                    }
                )
            }

            Mock -CommandName Get-WebConfiguration -MockWith { return $MockFtpAuthorizationOutput }

            Context "Expected behavior" {

                It 'Should not throw an error' {
                    { Test-AuthorizationInfo -Site $MockFtpSiteName `
                                             -AuthorizationInfo $MockAuthorizationInfo}|
                    Should Not Throw
                }

                It 'Should call Get-WebConfiguration once' {
                    Assert-MockCalled -CommandName Get-WebConfiguration -Exactly 1
                }
            }

            Context 'Returns True when AuthorizationInfo is identical' {

                $result = Test-AuthorizationInfo -Site $MockFtpSiteName `
                                                 -AuthorizationInfo $MockAuthorizationInfo

                It 'Should return True' {
                    $result | Should be $true
                }

                It 'Should call Get-WebConfiguration once' {
                    Assert-MockCalled -CommandName Get-WebConfiguration -Exactly 1
                }
            }

            Context 'Returns False when AuthorizationInfo is different in count' {

                $contextMockAuthorizationInfo  = @()
                $contextMockAuthorizationInfo += $MockAuthorizationInfo[0].Clone()

                Mock -CommandName Confirm-UniqueFTPAuthorization

                $result = Test-AuthorizationInfo -Site $MockFtpSiteName -AuthorizationInfo $contextMockAuthorizationInfo

                It 'Should return False' {
                    $result | Should be $false
                }

                It 'Should call expected mocks' {
                    Assert-MockCalled -CommandName Get-WebConfiguration -Exactly 1
                    Assert-MockCalled -CommandName Confirm-UniqueFTPAuthorization -Exactly 0
                }
            }

            Context 'Returns False when AuthorizationInfo is different' {

                $contextMockAuthorizationInfo                = @()
                $contextMockAuthorizationInfo               += $MockAuthorizationInfo[0].Clone()
                $contextMockAuthorizationInfo               += $MockAuthorizationInfo[1].Clone()
                $contextMockAuthorizationInfo               += $MockAuthorizationInfo[2].Clone()
                $contextMockAuthorizationInfo               += $MockAuthorizationInfo[3].Clone()
                $contextMockAuthorizationInfo[2].permissions = 'Read,Write'

                $result = Test-AuthorizationInfo -Site $MockFtpSiteName -AuthorizationInfo $contextMockAuthorizationInfo

                It 'Should return False' {
                    $result | Should be $false
                }

                It 'Should call Get-WebConfiguration once' {
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
