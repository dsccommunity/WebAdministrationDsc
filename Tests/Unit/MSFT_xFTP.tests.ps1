
$script:DSCModuleName   = 'xWebAdministration'
$script:DSCResourceName = 'MSFT_xFTP'
$script:DSCHelplerModuleName = 'Helper'

#region HEADER
[String] $moduleRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $Script:MyInvocation.MyCommand.Path))
if ( (-not (Test-Path -Path (Join-Path -Path $moduleRoot -ChildPath 'DSCResource.Tests'))) -or `
     (-not (Test-Path -Path (Join-Path -Path $moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1'))) )
{
    & git @('clone','https://github.com/PowerShell/DscResource.Tests.git',(Join-Path -Path $moduleRoot -ChildPath '\DSCResource.Tests\'))
}

Import-Module (Join-Path -Path $moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1') -Force
$TestEnvironment = Initialize-TestEnvironment `
    -DSCModuleName $script:DSCModuleName `
    -DSCResourceName $script:DSCResourceName `
    -TestType Unit
#endregion

# Begin Testing
try
{
    #region Pester Tests
    InModuleScope -ModuleName $script:DSCResourceName -ScriptBlock {
        $script:DSCModuleName   = 'xWebAdministration'
        $script:DSCResourceName = 'MSFT_xFTP'
        $script:DSCHelplerModuleName = 'Helper'

        Describe "$script:DSCResourceName\Assert-Module" {
            Context 'WebAdminstration module is not installed' {
                Mock -ModuleName Helper -CommandName Get-Module -MockWith {
                    return $null
                }

                It 'should throw an error' {
                    { Assert-Module } | Should Throw
                }
            }
        }

        Describe "how $script:DSCResourceName\Get-TargetResource responds" {

            $MockLogOutput = @{
                directory         = '%SystemDrive%\inetpub\logs\LogFiles'
                logExtFileFlags   = 'Date,Time,ClientIP,UserName,ServerIP,Method'
                period            = 'Daily'
                truncateSize      = '1048576'
                localTimeRollover = 'False'
            }

            $MockAuthenticationInfo = @(
                New-CimInstance -ClassName MSFT_xFTPAuthenticationInformation `
                    -Namespace root/microsoft/Windows/DesiredStateConfiguration `
                    -Property @{
                        Anonymous = $true
                        Basic     = $false
                    } `
                    -ClientOnly
            )

            $MockAuthorizationInfo = @(
                New-CimInstance -ClassName MSFT_xFTPAuthorizationInformation `
                    -Namespace root/microsoft/Windows/DesiredStateConfiguration `
                    -Property @{
                        accessType  = 'Allow'
                        users       = 'User1'
                        roles       = ''
                        permissions = 'Read'
                    } `
                    -ClientOnly
            )

            $MockBindingInfo = @(
                @{
                    bindingInformation   = '*:21:ftp.server'
                    protocol             = 'ftp'
                }
            )

            $MockSslInfo = @(
                New-CimInstance -ClassName MSFT_xFTPSslInformation `
                    -Namespace root/microsoft/Windows/DesiredStateConfiguration `
                    -Property @{
                        controlChannelPolicy = 'SslAllow'
                        dataChannelPolicy    = 'SslAllow'
                        ssl128               = 'True'
                        serverCertHash       = ''
                        serverCertStoreName  = 'My'
                    } `
                    -ClientOnly
            )

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
            )
            
            $MockWebsite = @{
                Name                 = 'MockFtp'
                PhysicalPath         = 'C:\NonExistent'
                State                = 'Started'
                ApplicationPool      = 'MockFtpPool'
                AuthenticationInfo   = $AuthenticationInfo
                AuthorizationInfo    = $AuthorizationInfo
                SslInfo              = $SslInfo
                Bindings             = @{Collection = @($MockBindingInfo)}
                logfile              = $MockLogOutput
                ftpServer            = $MockFtpServerInfo
                Count                = 1
            }

            Context 'Website does not exist' {
                Mock -CommandName Get-Website

                $Result = Get-TargetResource -Name $MockWebsite.Name

                It 'should return Absent' {
                    $Result.Ensure | Should Be 'Absent'
                }
            }

            Context 'There are multiple webftpsites with the same name' {
                Mock -CommandName Get-Website -MockWith {
                    return @(
                        @{Name = 'MockFtp'}
                        @{Name = 'MockFtp'}
                    )
                }

                It 'should throw the correct error' {
                    $ErrorId = 'FtpSiteDiscoveryFailure'
                    $ErrorCategory = [System.Management.Automation.ErrorCategory]::InvalidResult
                    $ErrorMessage = $LocalizedData.ErrorFtpSiteDiscoveryFailure -f 'MockFtp'
                    $Exception = New-Object `
                        -TypeName System.InvalidOperationException `
                        -ArgumentList $ErrorMessage
                    $ErrorRecord = New-Object `
                        -TypeName System.Management.Automation.ErrorRecord `
                        -ArgumentList $Exception, $ErrorId, $ErrorCategory, $null

                    {Get-TargetResource -Name 'MockFtp'} | Should Throw $ErrorRecord
                }
            }

            Context 'Single website exists' {

                Mock -CommandName Get-Website -MockWith {return $MockWebsite}
                Mock -CommandName Get-AuthenticationInfo { return $MockAuthenticationInfo }
                Mock -CommandName Get-AuthorizationInfo { return $MockAuthorizationInfo }
                Mock -CommandName Get-SslInfo { return $MockSslInfo }

                $Result = Get-TargetResource -Name $MockWebsite.Name

                It 'should call Get-Website once' {
                    Assert-MockCalled -CommandName Get-Website -Exactly 1
                }

                It 'should return Ensure' {
                    $Result.Ensure | Should Be 'Present'
                }

                It 'should return Name' {
                    $Result.Name | Should Be $MockWebsite.Name
                }

                It 'should return PhysicalPath' {
                    $Result.PhysicalPath | Should Be $MockWebsite.PhysicalPath
                }

                It 'should return State' {
                    $Result.State | Should Be $MockWebsite.State
                }

                It 'should return ApplicationPool' {
                    $Result.ApplicationPool | Should Be $MockWebsite.ApplicationPool
                }

                It 'should return AuthenticationInfo' {
                    $Result.AuthenticationInfo.CimInstanceProperties['Anonymous'].Value | Should Be 'true'
                    $Result.AuthenticationInfo.CimInstanceProperties['Basic'].Value     | Should Be 'false'
                }

                It 'should return AuthorizationInfo' {
                    $Result.AuthorizationInfo.users       | Should Be $MockAuthorizationInfo.Users
                    $Result.AuthorizationInfo.roles       | Should BeNullOrEmpty
                    $Result.AuthorizationInfo.accessType  | Should Be $MockAuthorizationInfo.accessType
                    $Result.AuthorizationInfo.permissions | Should Be $MockAuthorizationInfo.permissions
                }

                It 'should return SslInfo' {
                    $Result.SslInfo.controlChannelPolicy | Should Be $MockSslInfo.controlChannelPolicy
                    $Result.SslInfo.dataChannelPolicy    | Should Be $MockSslInfo.dataChannelPolicy
                    $Result.SslInfo.ssl128               | Should Be $MockSslInfo.ssl128
                    $Result.SslInfo.serverCertHash       | Should Be $MockSslInfo.serverCertHash
                    $Result.SslInfo.serverCertStoreName  | Should Be $MockSslInfo.serverCertStoreName
                }

                It 'should return BindingInfo' {
                    $Result.BindingInfo.HostName  | Should Be 'ftp.server'
                    $Result.BindingInfo.Port      | Should Be '21'
                    $Result.BindingInfo.Protocol  | Should Be $MockBindingInfo.protocol
                    $Result.BindingInfo.IPAddress | Should Be '*'
                }

                It 'should return LogPath' {
                    $Result.LogPath | Should Be $MockWebsite.logfile.directory
                }

                It 'should return LogFlags' {
                    $Result.LogFlags | Should Be $MockWebsite.logfile.LogExtFileFlags
                }

                It 'should return LogPeriod' {
                    $Result.LogPeriod | Should Be $MockWebsite.logfile.period
                }

                It 'should return LogtruncateSize' {
                    $Result.LogtruncateSize | Should Be $MockWebsite.logfile.truncateSize
                }

                It 'should return LoglocalTimeRollover' {
                    $Result.LoglocalTimeRollover | Should Be $MockWebsite.logfile.localTimeRollover
                }

                It 'should return DirectoryBrowseFlags' {
                    $Result.DirectoryBrowseFlags | Should Be $MockFtpServerInfo.directoryBrowse.showFlags
                }

                It 'should return UserIsolation' {
                    $Result.UserIsolation | Should Be $MockFtpServerInfo.userIsolation.mode
                }
            }
        }

        Describe "how $script:DSCResourceName\Test-TargetResource responds to Ensure = 'Present'" {

            $MockAuthenticationInfo = New-CimInstance -ClassName MSFT_xFTPAuthenticationInformation `
                    -Namespace root/microsoft/Windows/DesiredStateConfiguration `
                    -Property @{
                        Anonymous = $true
                        Basic     = $false
                    } `
                    -ClientOnly

            $MockAuthorizationInfo = @(
                New-CimInstance -ClassName MSFT_xFTPAuthorizationInformation `
                    -Namespace root/microsoft/Windows/DesiredStateConfiguration `
                    -Property @{
                        accessType  = 'Allow'
                        users       = 'User1'
                        roles       = ''
                        permissions = 'Read'
                    } `
                    -ClientOnly
            )
            
            $MockBindingInfo = @(
                New-CimInstance -ClassName MSFT_xFTPBindingInformation `
                    -Namespace root/microsoft/Windows/DesiredStateConfiguration `
                    -Property @{
                        Protocol = 'ftp'
                        Port     = '21'
                        HostName = 'ftp.server'
                    } `
                    -ClientOnly
            )

            $MockSslInfo = New-CimInstance -ClassName MSFT_xFTPSslInformation `
                    -Namespace root/microsoft/Windows/DesiredStateConfiguration `
                    -Property @{
                        controlChannelPolicy = 'SslAllow'
                        dataChannelPolicy    = 'SslAllow'
                        ssl128               = 'True'
                        serverCertHash       = ''
                        serverCertStoreName  = 'My'
                    } `
                    -ClientOnly
            
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
                            ssl =@(New-Object -TypeName PSObject -Property @{
                                serverCertHash       = 'EF8D5381178A622886A30CBBB46BBA8F4AFAAC97'
                                serverCertStoreName  = 'MY'
                                ssl128               = 'True'
                                controlChannelPolicy = 'SslAllow'
                                dataChannelPolicy    = 'SslAllow'
                            })
                        }
                   }
            )

            $MockParameters = @{
                Ensure               = 'Present'
                Name                 = 'MockFtp'
                PhysicalPath         = 'C:\NonExistent'
                State                = 'Started'
                ApplicationPool      = 'MockFtpPool'
                AuthorizationInfo    = $MockAuthorizationInfo
                BindingInfo          = $MockBindingInfo
                SslInfo              = $MockSslInfo
                LogPath              = '%SystemDrive%\LogFiles'
                LogFlags             = @('Date','Time','ClientIP','UserName','ServerIP','Method')
                LogPeriod            = 'Daily'
                LoglocalTimeRollover = $false
                DirectoryBrowseFlags = 'StyleUnix'
                UserIsolation        = 'StartInUsersDirectory'
            }

            $MockWebsite = @{
                Name                 = 'MockFtp'
                PhysicalPath         = 'C:\NonExistent'
                State                = 'Started'
                ApplicationPool      = 'MockFtpPool'
                AuthenticationInfo   = $AuthenticationInfo
                AuthorizationInfo    = $AuthorizationInfo
                Bindings             = @{Collection = @($MockBindingInfo)}
                logfile              = $MockLogOutput
                ftpServer            = $MockFtpServerInfo
                Count                = 1
            }

            Context 'Website does not exist' {
                Mock -CommandName Get-Website

                $Result = Test-TargetResource `
                            -Ensure $MockParameters.Ensure `
                            -Name $MockParameters.Name

                It 'should return False' {
                    $Result | Should Be $false
                }
            }

            Context 'Check PhysicalPath is different' {
                Mock -CommandName Get-Website -MockWith {return $MockWebsite}

                $Result = Test-TargetResource -Ensure $MockParameters.Ensure `
                            -Name $MockParameters.Name `
                            -PhysicalPath 'C:\Different' 

                It 'should return False' {
                    $Result | Should Be $false
                }
            }

            Context 'Check State is different' {
                Mock -CommandName Get-Website -MockWith {return $MockWebsite}

                $Result = Test-TargetResource -Ensure $MockParameters.Ensure `
                            -Name $MockParameters.Name `
                            -State 'Stopped' 

                It 'should return False' {
                    $Result | Should Be $false
                }
            }

            Context 'Check ApplicationPool is different' {
                Mock -CommandName Get-Website -MockWith {return $MockWebsite}

                $Result = Test-TargetResource -Name $MockParameters.Name `
                            -Ensure $MockParameters.Ensure `
                            -ApplicationPool 'MockPoolDifferent'

                It 'should return False' {
                    $Result | Should Be $false
                }
            }

            Context 'Check AuthenticationInfo is different' {

                Mock -CommandName Get-Website -MockWith {return $MockWebsite}

                Mock -Module Helper -CommandName Get-WebConfigurationProperty { return $false } `
                     -ParameterFilter { $filter -eq '/system.WebServer/security/authentication/AnonymousAuthentication'} `

                Mock -Module Helper -CommandName Get-WebConfigurationProperty { return $false } `
                     -ParameterFilter { $filter -eq '/system.WebServer/security/authentication/BasicAuthentication'} `

                $MockAuthenticationInfo = New-CimInstance `
                                         -ClassName MSFT_xWebAuthenticationInformation `
                                         -ClientOnly `
                                         -Property @{ Anonymous=$true; Basic=$true }

                $Result = Test-TargetResource -Ensure $MockParameters.Ensure `
                                              -Name $MockParameters.Name `
                                              -AuthenticationInfo $MockAuthenticationInfo

                It 'should return False' {
                    $Result | Should Be $false
                }
            }

            Context 'Check BindingInfo is different' {
                Mock -CommandName Get-Website -MockWith {return $MockWebsite}
                Mock -CommandName Test-WebsiteBinding -MockWith {$false}

                $Result = Test-TargetResource -Name $MockParameters.Name `
                                              -Ensure $MockParameters.Ensure `
                                              -BindingInfo $MockBindingInfo 

                It 'should return False' {
                    $Result | Should Be $false
                }
            }

            Context 'Check AuthorizationInfo is different' {
                Mock -CommandName Get-Website -MockWith {return $MockWebsite}
                Mock -CommandName Test-UniqueFTPAuthorization -MockWith {return $false}


                $Result = Test-TargetResource -Ensure $MockParameters.Ensure `
                                              -Name $MockParameters.Name `
                                              -AuthorizationInfo $MockAuthorizationInfo

                It 'should return False' {
                    $Result | Should Be $false
                }
            }

            Context 'Check SslInfo is different' {
                Mock -CommandName Get-Website -MockWith {return $MockWebsite}
                Mock -CommandName Confirm-UniqueSslInfo -MockWith {return $false}

                $Result = Test-TargetResource -Ensure $MockParameters.Ensure `
                                              -Name $MockParameters.Name `
                                              -SslInfo $MockSslInfo

                It 'should return False' {
                    $Result | Should Be $false
                }
            }

            Context 'Check Log Options are different' {
                Mock -CommandName Get-Website -MockWith {return $MockWebsite}

                $Result = Test-TargetResource -Ensure $MockParameters.Ensure `
                                              -Name $MockParameters.Name `
                                              -LogFlags @('Date','Time','ClientIP','UserName','ServerIP') `
                                              -LogPath '%SystemDrive%\DifferentLogFiles' `
                                              -LogPeriod 'Daily' `
                                              -LoglocalTimeRollover $true

                It 'should return False' {
                    $Result | Should Be $false
                }

            }

            Context 'Check DirectoryBrowseFlags is different' {
                Mock -CommandName Get-Website -MockWith {return $MockWebsite}
            
                $Result = Test-TargetResource -Ensure $MockParameters.Ensure `
                                              -Name $MockParameters.Name `
                                              -DirectoryBrowseFlags $MockParameters.DirectoryBrowseFlags

                It 'should return False' {
                    $Result | Should Be $false
                }
            }

            Context 'Check UserIsolation is different' {
                Mock -CommandName Get-Website -MockWith {return $MockWebsite}

                $Result = Test-TargetResource -Ensure $MockParameters.Ensure `
                                              -Name $MockParameters.Name `
                                              -UserIsolation $MockParameters.UserIsolation

                It 'should return False' {
                    $Result | Should Be $false
                }
            }

        }

        Describe "how $script:DSCResourceName\Set-TargetResource responds to Ensure = 'Present'" {

            $MockAuthenticationInfo = New-CimInstance -ClassName MSFT_xFTPAuthenticationInformation `
                    -Namespace root/microsoft/Windows/DesiredStateConfiguration `
                    -Property @{
                        Anonymous = $true
                        Basic     = $false
                    } `
                    -ClientOnly

            $MockAuthorizationInfo = @(
                New-CimInstance -ClassName MSFT_xFTPAuthorizationInformation `
                    -Namespace root/microsoft/Windows/DesiredStateConfiguration `
                    -Property @{
                        accessType  = 'Allow'
                        users       = 'User1'
                        roles       = ''
                        permissions = 'Read'
                    } `
                    -ClientOnly
            )

            $MockBindingInfo = @(
                New-CimInstance -ClassName MSFT_xFTPBindingInformation `
                    -Namespace root/microsoft/Windows/DesiredStateConfiguration `
                    -Property @{
                        Protocol = 'ftp'
                        Port     = '21'
                        HostName = 'ftp.server'
                    } `
                    -ClientOnly
            )

            $MockSslInfo = New-CimInstance -ClassName MSFT_xFTPSslInformation `
                    -Namespace root/microsoft/Windows/DesiredStateConfiguration `
                    -Property @{
                        controlChannelPolicy = 'SslAllow'
                        dataChannelPolicy    = 'SslAllow'
                        ssl128               = 'True'
                        serverCertHash       = 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAA1234567890'
                        serverCertStoreName  = 'My'
                    } `
                    -ClientOnly

            $MockParameters = @{
                Ensure               = 'Present'
                Name                 = 'MockFtp'
                PhysicalPath         = 'C:\NonExistent'
                State                = 'Started'
                ApplicationPool      = 'MockFtpPool'
                AuthenticationInfo   = $MockAuthenticationInfo
                AuthorizationInfo    = $MockAuthorizationInfo
                BindingInfo          = $MockBindingInfo
                SslInfo              = $MockSslInfo
                LogPath              = '%SystemDrive%\LogFiles'
                LogFlags             = @('Date','Time','ClientIP','UserName','ServerIP','Method')
                LogPeriod            = 'Daily'
                LoglocalTimeRollover = $true
                DirectoryBrowseFlags = 'StyleUnix'
                UserIsolation        = 'StartInUsersDirectory'
            }

            $DifferentMockLogOutput = @{
                directory         = '%SystemDrive%\inetpub\logs\LogFiles'
                logExtFileFlags   = 'Date,Time,ClientIP,UserName,ServerIP'
                period            = 'Hourly'
                truncateSize      = '1048576'
                localTimeRollover = 'False'
            }

            $DifferentMockAuthenticationInfo = New-CimInstance -ClassName MSFT_xFTPAuthenticationInformation `
                    -Namespace root/microsoft/Windows/DesiredStateConfiguration `
                    -Property @{
                        Anonymous = $true
                        Basic     = $true
                    } `
                    -ClientOnly

            $DifferentMockAuthorizationInfo = @(
                New-CimInstance -ClassName MSFT_xFTPAuthorizationInformation `
                    -Namespace root/microsoft/Windows/DesiredStateConfiguration `
                    -Property @{
                        accessType  = 'Allow'
                        users       = 'User1'
                        roles       = ''
                        permissions = 'Read'
                    } `
                    -ClientOnly
            )

            $DifferentMockBindingInfo = @(
                New-CimInstance -ClassName MSFT_xFTPBindingInformation `
                    -Namespace root/microsoft/Windows/DesiredStateConfiguration `
                    -Property @{
                        Protocol = 'ftp'
                        Port     = '21'
                        HostName = 'ftp.server'
                    } `
                    -ClientOnly
            )

           $DifferentMockSslInfo = New-CimInstance -ClassName MSFT_xFTPSslInformation `
                    -Namespace root/microsoft/Windows/DesiredStateConfiguration `
                    -Property @{
                        controlChannelPolicy = 'SslAllow'
                        dataChannelPolicy    = 'SslAllow'
                        ssl128               = 'True'
                        serverCertHash       = 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAA1234567890'
                        serverCertStoreName  = 'My'
                    } `
                    -ClientOnly

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
                            ssl =@(New-Object -TypeName PSObject -Property  @{
                                serverCertHash       = 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAA1234567890'
                                serverCertStoreName  = 'MY'
                                ssl128               = 'True'
                                controlChannelPolicy = 'SslAllow'
                                dataChannelPolicy    = 'SslAllow'
                            })
                        }
                   }
            )

            $MockFtpAuthorization = @{
                accessType  = 'Allow'
                users       = ''
                roles       = 'User1'
                permissions = 'Read'
            }

            $MockWebsite = @{
                Name                 = 'MockFtp'
                PhysicalPath         = 'C:\Different'
                State                = ''
                ApplicationPool      = 'DifferentMockFtpPool'
                AuthenticationInfo   = $DifferentAuthenticationInfo
                AuthorizationInfo    = $DifferentAuthorizationInfo
                SslInfo              = $DifferentSslInfo
                Bindings             = @{Collection = @($DifferentMockBindingInfo)}
                logfile              = $DifferentMockLogOutput
                ftpServer            = $DifferentMockFtpServerInfo
                Count                = 1
            }

            Context 'All properties need to be updated and webftpsite must be started' {

                Mock -Module Helper -CommandName Get-WebConfigurationProperty { return $false } `
                     -ParameterFilter { $filter -eq '/system.WebServer/security/authentication/AnonymousAuthentication'} `

                Mock -Module Helper -CommandName Get-WebConfigurationProperty { return $false } `
                     -ParameterFilter { $filter -eq '/system.WebServer/security/authentication/BasicAuthentication'} `

                Mock -CommandName Get-WebConfiguration { return $null } `
                     -ParameterFilter { $filter -eq '/system.ftpServer/security/authorization' }

                Mock -Module Helper -CommandName Set-Authentication
                Mock -CommandName Set-ItemProperty
                Mock -CommandName Get-Website -MockWith {return $MockWebsite}
                Mock -CommandName Start-Website
                Mock -CommandName New-Webftpsite -MockWith {return $MockWebsite}
                Mock -CommandName Set-FTPAuthorization
                Mock -CommandName Update-WebsiteBinding
                Mock -CommandName Set-SslInfo
                Mock -CommandName Confirm-UniqueSslInfo { return $false }

                $Result = Set-TargetResource @MockParameters

                It 'should call all the mocks' {
                    Assert-MockCalled -CommandName Set-ItemProperty -Exactly 9
                    Assert-MockCalled -CommandName Start-Website -Exactly 1
                    Assert-MockCalled -CommandName Set-SslInfo -Exactly 1
                    Assert-MockCalled -CommandName Set-FTPAuthorization -Exactly 1
                    Assert-MockCalled -CommandName Update-WebsiteBinding -Exactly 1
                    Assert-MockCalled -Module Helper -CommandName Set-Authentication -Exactly 2
                }
            }

            Context 'All properties need to be updated and webftpsite must be stopped' {

                $MockParameters = $MockParameters.Clone()
                $MockParameters.State = 'Stopped'

                $MockWebsite = $MockWebsite.Clone()
                $MockWebsite.State = 'Started'

                Mock -Module Helper -CommandName Get-WebConfigurationProperty { return $false } `
                     -ParameterFilter { $filter -eq '/system.WebServer/security/authentication/AnonymousAuthentication'} `

                Mock -Module Helper -CommandName Get-WebConfigurationProperty { return $false } `
                     -ParameterFilter { $filter -eq '/system.WebServer/security/authentication/BasicAuthentication'} `

                Mock -CommandName Get-WebConfiguration { return $null } `
                     -ParameterFilter { $filter -eq '/system.ftpServer/security/authorization' }
                
                Mock -CommandName Set-FTPAuthorization

                Mock -CommandName Get-Website -MockWith {return $MockWebsite}

                Mock -CommandName Set-ItemProperty

                Mock -Module Helper -CommandName Set-Authentication

                Mock -CommandName Stop-Website

                Mock -CommandName New-Webftpsite -MockWith {return $MockWebsite}

                Mock -CommandName Set-FTPAuthorization
                Mock -CommandName Update-WebsiteBinding
                Mock -CommandName Set-SslInfo
                Mock -CommandName Confirm-UniqueSslInfo { return $false }

                $Result = Set-TargetResource @MockParameters

                It 'should call all the mocks' {
                    Assert-MockCalled -CommandName Set-ItemProperty -Exactly 9
                    Assert-MockCalled -CommandName Stop-Website -Exactly 1
                    Assert-MockCalled -CommandName Set-SslInfo -Exactly 1
                    Assert-MockCalled -CommandName Set-FTPAuthorization -Exactly 1
                    Assert-MockCalled -CommandName Update-WebsiteBinding -Exactly 1
                    Assert-MockCalled -Module Helper -CommandName Set-Authentication -Exactly 2
                }
            }

            Context 'webftpsite does not exist' {

                Mock -CommandName Get-Website { return $null }

                Mock -Module Helper -CommandName Get-WebConfigurationProperty { return $false } `
                     -ParameterFilter { $filter -eq '/system.WebServer/security/authentication/AnonymousAuthentication'} `

                Mock -Module Helper -CommandName Get-WebConfigurationProperty { return $false } `
                     -ParameterFilter { $filter -eq '/system.WebServer/security/authentication/BasicAuthentication'} `

                Mock -CommandName Get-WebConfiguration { return $null } `
                     -ParameterFilter { $filter -eq '/system.ftpServer/security/authorization' }

                Mock -CommandName Set-FTPAuthorization

                Mock -Module Helper -CommandName Set-Authentication
                Mock -CommandName Set-ItemProperty
                Mock -CommandName Start-Website
                Mock -CommandName New-Webftpsite -MockWith {return $MockWebsite}
                Mock -CommandName Set-FTPAuthorization
                Mock -CommandName Update-WebsiteBinding
                Mock -CommandName Set-SslInfo
                Mock -CommandName Confirm-UniqueSslInfo { return $false }

                $Result = Set-TargetResource @MockParameters

                It 'should call all the mocks' {
                    Assert-MockCalled -CommandName Set-ItemProperty -Exactly 7
                    Assert-MockCalled -CommandName New-Webftpsite -Exactly 1
                    Assert-MockCalled -CommandName Set-SslInfo -Exactly 1
                    Assert-MockCalled -CommandName Set-FTPAuthorization -Exactly 1
                    Assert-MockCalled -CommandName Update-WebsiteBinding -Exactly 1
                }
            }

            Context 'New-Webftpsite throws an error' {
                Mock -CommandName Get-Website
                Mock -CommandName New-Webftpsite -MockWith {throw}

                It 'should throw the correct error' {
                    $ErrorId = 'ErrorFtpSiteCreationFailure'
                    $ErrorCategory = [System.Management.Automation.ErrorCategory]::InvalidOperation
                    $ErrorMessage = $LocalizedData.ErrorFtpSiteCreationFailure -f $MockParameters.Name, 'ScriptHalted'
                    $Exception = New-Object `
                        -TypeName System.InvalidOperationException `
                        -ArgumentList $ErrorMessage
                    $ErrorRecord = New-Object `
                        -TypeName System.Management.Automation.ErrorRecord `
                        -ArgumentList $Exception, $ErrorId, $ErrorCategory, $null

                    { Set-TargetResource @MockParameters } | Should Throw $ErrorRecord
                }
            }
        }

        Describe "how $script:DSCResourceName\Compare-DirectoryBrowseFlags responds" {
        
            Context 'Returns false when DirectoryBrowseFlags are incorrect' {

                $MockLogOutput = @{
                                directoryBrowse = @{
                                    showFlags = 'LongDate'
                                                   }
                                  }

                $MockWebsite = @{
                    Name                 = 'MockFtp'
                    ftpServer            = $MockLogOutput
                }

                Mock -CommandName Get-WebSite -MockWith { return $MockWebsite }

                $result = Compare-DirectoryBrowseFlags -Name $MockWebsite.Name -DirectoryBrowseflags 'StyleUnix'

                It 'Should return false' {
                    $result | Should be $false
                }

            }

            Context 'Returns true when DirectoryBrowseFlags are correct' {

                $MockLogOutput = @{
                                directoryBrowse = @{
                                    showFlags = 'LongDate'
                                                   }
                                  }

                $MockWebsite = @{
                    Name                 = 'MockFtp'
                    ftpServer              = $MockLogOutput
                }

                Mock -CommandName Get-WebSite -MockWith { return $MockWebsite }

                $result = Compare-DirectoryBrowseFlags -Name $MockWebsite.Name -DirectoryBrowseflags 'LongDate'

                It 'Should return true' {
                    $result | Should be $true
                }

            }

        }

        Describe "how $script:DSCResourceName\Confirm-UniqueFTPAuthorization responds" {

            Context 'Returns false when UniqueFTPAuthorization for a user is incorrect' {
                
                $MockAuthorizationInfo = @(
                New-CimInstance -ClassName MSFT_xFTPAuthorizationInformation `
                    -Namespace root/microsoft/Windows/DesiredStateConfiguration `
                    -Property @{
                        accessType  = 'Allow'
                        users       = 'User1'
                        roles       = ''
                        permissions = 'Read'
                    } `
                    -ClientOnly
                )
                
                Mock -CommandName Get-WebConfiguration { return $null } `
                     -ParameterFilter { $filter -eq '/system.ftpServer/security/authorization' }

                $result = Confirm-UniqueFTPAuthorization -Site 'FTP' -AuthorizationInfo $MockAuthorizationInfo

                It 'Should return false' {
                    $result | Should be $false
                }

            }

            Context 'Returns false when UniqueFTPAuthorization for a group is incorrect' {

                $MockAuthorizationInfo = @(
                New-CimInstance -ClassName MSFT_xFTPAuthorizationInformation `
                    -Namespace root/microsoft/Windows/DesiredStateConfiguration `
                    -Property @{
                        accessType  = 'Allow'
                        users       = 'User1'
                        roles       = ''
                        permissions = 'Read'
                    } `
                    -ClientOnly
                )

                Mock -CommandName Get-WebConfiguration { return $null } `
                     -ParameterFilter { $filter -eq '/system.ftpServer/security/authorization' }

                $result = Confirm-UniqueFTPAuthorization -Site 'FTP' -AuthorizationInfo $MockAuthorizationInfo

                It 'Should return false' {
                    $result | Should be $false
                }

            }

            Context 'Returns true when UniqueFTPAuthorization for a user is correct' {

                $MockAuthorizationInfo = @(
                New-CimInstance -ClassName MSFT_xFTPAuthorizationInformation `
                    -Namespace root/microsoft/Windows/DesiredStateConfiguration `
                    -Property @{
                        accessType  = 'Allow'
                        users       = 'User1'
                        roles       = ''
                        permissions = 'Read'
                    } `
                    -ClientOnly
                )
                
                $MockFtpAuthorization =  @(
                    @{
                        accessType  = 'Allow'
                        users       = 'User1'
                        roles       = ''
                        permissions = 'Read'
                    }
                )

                Mock -CommandName Get-WebConfiguration { return $MockFtpAuthorization } `
                     -ParameterFilter { $filter -eq '/system.ftpServer/security/authorization' }

                $result = Confirm-UniqueFTPAuthorization -Site 'FTP' -AuthorizationInfo $MockAuthorizationInfo

                It 'Should return false' {
                    $result | Should be $false
                }

            }

            Context 'Returns true when UniqueFTPAuthorization for a group is correct' {

                                $MockAuthorizationInfo = @(
                New-CimInstance -ClassName MSFT_xFTPAuthorizationInformation `
                    -Namespace root/microsoft/Windows/DesiredStateConfiguration `
                    -Property @{
                        accessType  = 'Allow'
                        users       = ''
                        roles       = 'Group1'
                        permissions = 'Read'
                    } `
                    -ClientOnly
                )
                
                $MockFtpAuthorization =  @(
                    @{
                        accessType  = 'Allow'
                        users       = ''
                        roles       = 'Group1'
                        permissions = 'Read'
                    }
                )

                Mock -CommandName Get-WebConfiguration { return $MockFtpAuthorization } `
                     -ParameterFilter { $filter -eq '/system.ftpServer/security/authorization' }

                $result = Confirm-UniqueFTPAuthorization -Site 'FTP' -AuthorizationInfo $MockAuthorizationInfo

                It 'Should return false' {
                    $result | Should be $false
                }

            }

        }

        Describe "how $script:DSCResourceName\Confirm-UniqueSslInfo responds" {
        
            Context 'Returns false when Confirm-UniqueSslInfo is incorrect' {

                $MockSslInfo = New-CimInstance -ClassName MSFT_xFTPSslInformation `
                    -Namespace root/microsoft/Windows/DesiredStateConfiguration `
                    -Property @{
                        controlChannelPolicy = 'SslAllow'
                        dataChannelPolicy    = 'SslAllow'
                        ssl128               = 'True'
                        serverCertHash       = 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAA1234567890'
                        serverCertStoreName  = 'My'
                    } `
                    -ClientOnly

                $MockFtpServerInfo = @(
                        @{
                            security = @{
                                ssl =@(New-Object -TypeName PSObject -Property @{
                                    serverCertHash       = ''
                                    serverCertStoreName  = ''
                                    ssl128               = ''
                                    controlChannelPolicy = ''
                                    dataChannelPolicy    = ''
                                })
                            }
                       }
                )

                $MockWebsite = @{
                    Name                 = 'MockFtp'
                    ftpServer            = $MockFtpServerInfo
                }

                Mock -CommandName Get-WebSite -MockWith { return $MockWebsite }

                Mock -CommandName Test-Path {Return $true}

                $result = Confirm-UniqueSslInfo -Name $MockWebsite.Name -SslInfo $MockSslInfo

                It 'Should return false' {
                    $result | Should be $false
                }
            }

            Context 'Returns true when Confirm-UniqueSslInfo is correct' {

                $MockSslInfo = New-CimInstance -ClassName MSFT_xFTPSslInformation `
                    -Namespace root/microsoft/Windows/DesiredStateConfiguration `
                    -Property @{
                        controlChannelPolicy = 'SslAllow'
                        dataChannelPolicy    = 'SslAllow'
                        ssl128               = 'True'
                        serverCertHash       = 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAA1234567890'
                        serverCertStoreName  = 'My'
                    } `
                    -ClientOnly

                $MockFtpServerInfo = @(
                        @{
                            security = @{
                                ssl =@(New-Object -TypeName PSObject -Property @{
                                    controlChannelPolicy = 'SslAllow'
                                    dataChannelPolicy    = 'SslAllow'
                                    ssl128               = 'True'
                                    serverCertHash       = 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAA1234567890'
                                    serverCertStoreName  = 'My'
                                })
                            }
                       }
                )

                $MockWebsite = @{
                    Name                 = 'MockFtp'
                    ftpServer            = $MockFtpServerInfo
                }
                Mock -CommandName Test-Path {Return $true}

                Mock -CommandName Get-WebSite -MockWith { return $MockWebsite }

                $result = Confirm-UniqueSslInfo -Name $MockWebsite.Name -SslInfo $MockSslInfo

                It 'Should return true' {
                    $result | Should be $true
                }
        }

            Context 'Throws when cert does not exist' {

                $MockSslInfo = New-CimInstance -ClassName MSFT_xFTPSslInformation `
                    -Namespace root/microsoft/Windows/DesiredStateConfiguration `
                    -Property @{
                        controlChannelPolicy = 'SslAllow'
                        dataChannelPolicy    = 'SslAllow'
                        ssl128               = 'True'
                        serverCertHash       = 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAA1234567890'
                        serverCertStoreName  = 'My'
                    } `
                    -ClientOnly

                Mock -CommandName Test-Path {Return $false}

                It 'should throw the correct error' {
                   $ErrorId = 'ErrorServerCertHashFailure'
                   $ErrorCategory = [System.Management.Automation.ErrorCategory]::InvalidResult
                   $ErrorMessage = $LocalizedData.ErrorServerCertHashFailure -f $MockSslInfo.serverCertHash, $MockSslInfo.serverCertStoreName
                   $Exception = New-Object `
                       -TypeName System.InvalidOperationException `
                       -ArgumentList $ErrorMessage
                   $ErrorRecord = New-Object `
                       -TypeName System.Management.Automation.ErrorRecord `
                       -ArgumentList $Exception, $ErrorId, $ErrorCategory, $null

                   { Confirm-UniqueSslInfo -Name 'Name' -SslInfo $MockSslInfo } | Should Throw $ErrorRecord
                }
            }
        }
    }

    InModuleScope -ModuleName $script:DSCHelplerModuleName -ScriptBlock {
        $script:DSCModuleName        = 'xWebAdministration'
        $script:DSCResourceName      = 'MSFT_xFTP'
        $script:DSCHelplerModuleName = 'Helper'

        Describe "$script:DSCHelplerModuleName\Confirm-UniqueBinding" {
            $MockParameters = @{
                Name = 'MockSite'
            }

            Context 'Website does not exist' {
                Mock -CommandName Get-Website
                It 'should throw the correct error' {
                    $ErrorId = 'WebsiteNotFound'
                    $ErrorCategory = [System.Management.Automation.ErrorCategory]::InvalidResult
                    $ErrorMessage = $LocalizedData.ErrorWebsiteNotFound -f $MockParameters.Name
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
                                @{ protocol = 'ftp'; bindingInformation = '*:21:' }
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
                                @{ protocol = 'ftp'; bindingInformation = '*:21:' }
                                @{ protocol = 'ftp'; bindingInformation = '*:2121:' }
                            )
                        }
                    }
                    @{
                        Name = 'MockSite2'
                        State = 'Stopped'
                        Bindings = @{
                            Collection = @(
                                @{ protocol = 'ftp'; bindingInformation = '*:2122:' }
                            )
                        }
                    }
                    @{
                        Name = 'MockSite3'
                        State = 'Started'
                        Bindings = @{
                            Collection = @(
                                @{ protocol = 'ftp'; bindingInformation = '*:2123:' }
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
                                @{ protocol = 'ftp'; bindingInformation = '*:21:' }
                                @{ protocol = 'ftp'; bindingInformation = '*:2121:' }
                            )
                        }
                    }
                    @{
                        Name = 'MockSite2'
                        State = 'Started'
                        Bindings = @{
                            Collection = @(
                                @{ protocol = 'ftp'; bindingInformation = '*:21:' }
                            )
                        }
                    }
                    @{
                        Name = 'MockSite3'
                        State = 'Started'
                        Bindings = @{
                            Collection = @(
                                @{ protocol = 'ftp'; bindingInformation = '*:2121:' }
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
                                @{ protocol = 'ftp'; bindingInformation = '*:21:' }
                                @{ protocol = 'ftp'; bindingInformation = '*:2121:' }
                            )
                        }
                    }
                    @{
                        Name = 'MockSite2'
                        State = 'Stopped'
                        Bindings = @{
                            Collection = @(
                                @{ protocol = 'ftp'; bindingInformation = '*:21:' }
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
                                @{ protocol = 'ftp'; bindingInformation = '*:21:' }
                                @{ protocol = 'ftp'; bindingInformation = '*:2121:' }
                            )
                        }
                    }
                    @{
                        Name = 'MockSite2'
                        State = 'Stopped'
                        Bindings = @{
                            Collection = @(
                                @{ protocol = 'ftp';  bindingInformation = '*:21:' }
                            )
                        }
                    }
                    @{
                        Name = 'MockSite3'
                        State = 'Started'
                        Bindings = @{
                            Collection = @(
                                @{ protocol = 'ftp'; bindingInformation = '*:21:' }
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

        Describe "$script:DSCHelplerModuleName\ConvertTo-CimBinding" {
            Context 'IPv4 address is passed and the protocol is ftp' {
                $MockWebBinding = @{
                    bindingInformation = '127.0.0.1:21:MockHostName'
                    protocol           = 'ftp'
                }

                $Result = ConvertTo-CimBinding -InputObject $MockWebBinding

                It 'should return the IPv4 Address' {
                    $Result.IPAddress | Should Be '127.0.0.1'
                }

                It 'should return the Protocol' {
                    $Result.Protocol | Should Be 'ftp'
                }

                It 'should return the HostName' {
                    $Result.HostName | Should Be 'MockHostName'
                }

                It 'should return the Port' {
                    $Result.Port | Should Be '21'
                }
            }

            Context 'IPv6 address is passed and the protocol is ftp' {
                $MockWebBinding =  @{
                    bindingInformation = '[0:0:0:0:0:0:0:1]:21:MockHostName'
                    protocol           = 'ftp'
                }

                $Result = ConvertTo-CimBinding -InputObject $MockWebBinding

                It 'should return the IPv6 Address' {
                    $Result.IPAddress | Should Be '0:0:0:0:0:0:0:1'
                }

                It 'should return the Protocol' {
                    $Result.Protocol | Should Be 'ftp'
                }

                It 'should return the HostName' {
                    $Result.HostName | Should Be 'MockHostName'
                }

                It 'should return the Port' {
                    $Result.Port | Should Be '21'
                }
            }
        }

        Describe "$script:DSCHelplerModuleName\ConvertTo-WebBinding" {
            Context 'Expected behaviour' {
                $MockBindingInfo = @(
                    New-CimInstance `
                    -ClassName MSFT_xWebBindingInformation `
                    -Namespace root/microsoft/Windows/DesiredStateConfiguration `
                    -Property @{
                        Protocol              = 'ftp'
                        BindingInformation    = 'NonsenseString'
                        IPAddress             = '*'
                        Port                  = '21'
                        HostName              = 'ftp01.contoso.com'
                    } -ClientOnly
                )

                $Result = ConvertTo-WebBinding -InputObject $MockBindingInfo

                It 'should return the correct Protocol value' {
                    $Result.protocol | Should Be 'ftp'
                }

                It 'should return the correct BindingInformation value' {
                    $Result.bindingInformation | Should Be '*:21:ftp01.contoso.com'
                }

            }

            Context 'IP address is invalid' {
                $MockBindingInfo = @(
                    New-CimInstance `
                        -ClassName MSFT_xWebBindingInformation `
                        -Namespace root/microsoft/Windows/DesiredStateConfiguration `
                        -Property @{
                            Protocol  = 'ftp'
                            IPAddress = '127.0.0.256'
                        } -ClientOnly
                )

                It 'should throw the correct error' {
                    $ErrorId = 'WebBindingInvalidIPAddress'
                    $ErrorCategory = [System.Management.Automation.ErrorCategory]::InvalidArgument
                    $ErrorMessage = $LocalizedData.ErrorWebBindingInvalidIPAddress -f $MockBindingInfo.IPAddress, 'Exception calling "Parse" with "1" argument(s): "An invalid IP address was specified."'
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
                It 'should set the default FTP port' {
                    $MockBindingInfo = @(
                        New-CimInstance `
                            -ClassName MSFT_xWebBindingInformation `
                            -Namespace root/microsoft/Windows/DesiredStateConfiguration `
                            -ClientOnly `
                            -Property @{
                                Protocol = 'ftp'
                            }
                    )

                    $Result = ConvertTo-WebBinding -InputObject $MockBindingInfo
                    $Result.bindingInformation | Should Be '*:21:'
                }

            }

            Context 'Port is invalid' {
                $MockBindingInfo = @(
                    New-CimInstance `
                    -ClassName MSFT_xWebBindingInformation `
                    -Namespace root/microsoft/Windows/DesiredStateConfiguration `
                    -Property @{
                        Protocol = 'ftp'
                        Port     = 0
                    } -ClientOnly
                )

                It 'should throw the correct error' {
                    $ErrorId = 'WebBindingInvalidPort'
                    $ErrorCategory = [System.Management.Automation.ErrorCategory]::InvalidArgument
                    $ErrorMessage = $LocalizedData.ErrorWebBindingInvalidPort -f $MockBindingInfo.Port
                    $Exception = New-Object `
                        -TypeName System.InvalidOperationException `
                        -ArgumentList $ErrorMessage
                    $ErrorRecord = New-Object `
                        -TypeName System.Management.Automation.ErrorRecord `
                        -ArgumentList $Exception, $ErrorId, $ErrorCategory, $null

                    {ConvertTo-WebBinding -InputObject $MockBindingInfo} | Should Throw $ErrorRecord
                }
            }

            Context 'Protocol is not HTTPS' {
                $MockBindingInfo = @(
                    New-CimInstance -ClassName MSFT_xWebBindingInformation `
                    -Namespace root/microsoft/Windows/DesiredStateConfiguration `
                    -Property @{
                        Protocol              = 'ftp'
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

            Context 'Protocol is neither HTTP, HTTPS or FTP' {
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
                    $ErrorMessage = $LocalizedData.ErrorWebBindingMissingBindingInformation -f $MockBindingInfo.Protocol
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

        Describe "$script:DSCHelplerModuleName\Format-IPAddressString" {
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

        Describe "$script:DSCHelplerModuleName\Get-AuthenticationInfo" {
            $MockWebsite = @{
                Name                 = 'MockName'
                PhysicalPath         = 'C:\NonExistent'
                State                = 'Started'
                ApplicationPool      = 'MockPool'
                Bindings             = @{Collection = @($MockWebBinding)}
                EnabledProtocols     = 'http'
                ApplicationDefaults  = @{Collection = @($MockPreloadAndAutostartProviders)}
                Count                = 1
            }

           Context 'Expected behavior' {
                Mock -Module Helper -CommandName Get-WebConfigurationProperty -MockWith { return 'False'}

                It 'should not throw an error' {
                    { Get-AuthenticationInfo -site $MockWebsite.Name -IisType 'Ftp' } | Should Not Throw
                }

                It 'should call Get-WebConfigurationProperty two times' {
                    Assert-MockCalled -Module Helper -CommandName Get-WebConfigurationProperty -Exactly 2
                }
            }

            Context 'AuthenticationInfo is false' {

                Mock -Module Helper -CommandName Get-WebConfigurationProperty -MockWith { 
                    return @{
                        Value = 'False'
                    }
                }

                It 'should all be false' {
                    $result = Get-AuthenticationInfo -site $MockWebsite.Name -IisType 'Ftp'
                    $result.Anonymous | Should be False
                    $result.Basic | Should be False
                }

                It 'should call Get-WebConfigurationProperty two times' {
                    Assert-MockCalled -Module Helper -CommandName Get-WebConfigurationProperty -Exactly 2
                }
            }

            Context 'AuthenticationInfo is true' {

                Mock -Module Helper -CommandName Get-WebConfigurationProperty -MockWith {
                    return @{
                        Value = 'True'
                    }
                }

                It 'should all be true' {
                    $result = Get-AuthenticationInfo -site $MockWebsite.Name -IisType 'Ftp'
                    $result.Anonymous | Should be True
                    $result.Basic | Should be True
                }

                It 'should call Get-WebConfigurationProperty two times' {
                    Assert-MockCalled -Module Helper  -CommandName Get-WebConfigurationProperty -Exactly 2
                }
            }
        }

        Describe "$script:DSCHelplerModuleName\Get-DefaultAuthenticationInfo" {
            Context 'Expected behavior' {
                It 'should not throw an error' {
                    { Get-DefaultAuthenticationInfo }|
                    Should Not Throw
                }
            }

            Context 'Get-DefaultAuthenticationInfo should produce a false CimInstance' {
                It 'should all be false' {
                    $result = Get-DefaultAuthenticationInfo -IisType 'Ftp'
                    $result.Anonymous | Should be False
                    $result.Basic | Should be False
                }
            }
        }

        Describe "$script:DSCHelplerModuleName\Set-Authentication" {

            Context 'Expected behavior' {
                $MockWebsite = @{
                    Name                 = 'MockName'
                    PhysicalPath         = 'C:\NonExistent'
                    State                = 'Started'
                    ApplicationPool      = 'MockPool'
                    Bindings             = @{Collection = @($MockWebBinding)}
                    EnabledProtocols     = 'http'
                    ApplicationDefaults  = @{Collection = @($MockPreloadAndAutostartProviders)}
                    Count                = 1
                }

                Mock -Module Helper -CommandName Set-WebConfigurationProperty

                It 'should not throw an error' {
                    { Set-Authentication `
                        -Site $MockWebsite.Name `
                        -IisType 'Ftp' `
                        -Type Basic `
                        -Enabled $true } | Should Not Throw
                }

                It 'should call Set-WebConfigurationProperty once' {
                    Assert-MockCalled -Module Helper  -CommandName Set-WebConfigurationProperty -Exactly 1
                }
            }
        }

        Describe "$script:DSCHelplerModuleName\Set-AuthenticationInfo" {
            Context 'Expected behavior' {

                $MockWebsite = @{
                    Name                 = 'MockName'
                    PhysicalPath         = 'C:\NonExistent'
                    State                = 'Started'
                    ApplicationPool      = 'MockPool'
                    Bindings             = @{Collection = @($MockWebBinding)}
                    EnabledProtocols     = 'http'
                    ApplicationDefaults  = @{Collection = @($MockPreloadAndAutostartProviders)}
                    Count                = 1
                }

                Mock -Module Helper -CommandName Set-WebConfigurationProperty

                $AuthenticationInfo = New-CimInstance `
                    -ClassName MSFT_xWebApplicationAuthenticationInformation `
                    -ClientOnly `
                    -Property @{Anonymous=$true;Basic=$false}

                It 'should not throw an error' {
                    { Set-AuthenticationInfo `
                        -Site $MockWebsite.Name `
                        -IisType 'Ftp' `
                        -AuthenticationInfo $AuthenticationInfo } | Should Not Throw
                }

                It 'should call should call expected mocks' {
                        Assert-MockCalled -Module Helper -CommandName Set-WebConfigurationProperty -Exactly 2
                    }
            }
        }

        Describe "$script:DSCHelplerModuleName\Test-AuthenticationEnabled" {
            $MockWebsite = @{
                Name                 = 'MockName'
                PhysicalPath         = 'C:\NonExistent'
                State                = 'Started'
                ApplicationPool      = 'MockPool'
                Bindings             = @{Collection = @($MockWebBinding)}
                EnabledProtocols     = 'http'
                ApplicationDefaults  = @{Collection = @($MockPreloadAndAutostartProviders)}
                Count                = 1
            }

            Context 'Expected behavior' {

                Mock -Module Helper -CommandName Get-WebConfigurationProperty -MockWith {
                    return @{
                        Value = 'False'
                    }
                }

                It 'should not throw an error' {
                    { Test-AuthenticationEnabled `
                        -Site $MockWebsite.Name `
                        -IisType 'Ftp' `
                        -Type 'Basic'} | Should Not Throw
                }

                It 'should call expected mocks' {
                    Assert-MockCalled -Module Helper -CommandName Get-WebConfigurationProperty -Exactly 1
                }
            }

            Context 'AuthenticationInfo is false' {

                Mock -Module Helper -CommandName Get-WebConfigurationProperty -MockWith {
                    return @{
                        Value = 'False'
                    }
                }

                It 'should return false' {
                    Test-AuthenticationEnabled -Site $MockWebsite.Name -IisType 'Ftp' -Type 'Basic' | Should be False
                }

                It 'should call expected mocks' {
                    Assert-MockCalled -Module Helper -CommandName Get-WebConfigurationProperty -Exactly 1
                }
            }

            Context 'AuthenticationInfo is true' {

                Mock -Module Helper -CommandName Get-WebConfigurationProperty -MockWith {
                    return @{
                        Value = 'True'
                    }
                }

                It 'should all be true' {
                    Test-AuthenticationEnabled -Site $MockWebsite.Name -IisType 'Ftp' -Type 'Basic' | Should be True
                }

                It 'should call expected mocks' {
                    Assert-MockCalled -Module Helper -CommandName Get-WebConfigurationProperty -Exactly 1
                }
            }
        }

        Describe "$script:DSCHelplerModuleName\Test-AuthenticationInfo" {

            $MockWebsite = @{
                Name                 = 'MockName'
                PhysicalPath         = 'C:\NonExistent'
                State                = 'Started'
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
                -Property @{ Anonymous=$false; Basic=$true }

            Mock -Module Helper -CommandName Get-WebConfigurationProperty -MockWith {$MockWebConfiguration}

            Context 'Expected behavior' {
                It 'should not throw an error' {
                    { Test-AuthenticationInfo `
                        -Site $MockWebsite.Name `
                        -IisType 'Ftp' `
                        -AuthenticationInfo $AuthenticationInfo } | Should Not Throw
                }

                It 'should call expected mocks' {
                    Assert-MockCalled -Module Helper -CommandName Get-WebConfigurationProperty -Exactly 1
                }
            }

            Context 'Return False when AuthenticationInfo is not correct' {
                Mock -Module Helper -CommandName Get-WebConfigurationProperty -MockWith { $MockWebConfiguration}

                It 'should return false' {
                    Test-AuthenticationInfo -Site $MockWebsite.Name -IisType 'Ftp' -AuthenticationInfo $AuthenticationInfo | Should be False
                }

                It 'should call expected mocks' {
                    Assert-MockCalled -Module Helper -CommandName Get-WebConfigurationProperty -Exactly 1
                }
            }

            Context 'Return True when AuthenticationInfo is correct' {

                $AuthenticationInfo = New-CimInstance `
                    -ClassName MSFT_xWebApplicationAuthenticationInformation `
                    -ClientOnly `
                    -Property @{ Anonymous=$true; Basic=$true}

                Mock -Module Helper -CommandName Get-WebConfigurationProperty -MockWith {  
                    return @{
                        Value = 'True'
                    }
                }

                It 'should return true' {
                    Test-AuthenticationInfo `
                        -Site $MockWebsite.Name `
                        -IisType 'Ftp' `
                        -AuthenticationInfo $AuthenticationInfo | Should be True
                }

                It 'should call expected mocks' {
                    Assert-MockCalled -Module Helper -CommandName Get-WebConfigurationProperty -Exactly 2
                }
            }
        }

        Describe "$script:DSCHelplerModuleName\Test-BindingInfo" {
            Context 'BindingInfo is valid' {
                $MockBindingInfo = @(
                    New-CimInstance `
                        -ClassName MSFT_xWebBindingInformation `
                        -Namespace root/microsoft/Windows/DesiredStateConfiguration `
                        -ClientOnly `
                        -Property @{
                            Protocol              = 'ftp'
                            IPAddress             = '*'
                            Port                  = 21
                            HostName              = ''
                            CertificateThumbprint = ''
                            CertificateStoreName  = ''
                            SslFlags              = 0
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
                            Protocol              = 'ftp'
                            IPAddress             = '*'
                            Port                  = 21
                            HostName              = 'ftp01.contoso.com'
                            CertificateThumbprint = ''
                            CertificateStoreName  = ''
                            SslFlags              = 0
                        }

                    New-CimInstance `
                        -ClassName MSFT_xWebBindingInformation `
                        -Namespace root/microsoft/Windows/DesiredStateConfiguration `
                        -ClientOnly `
                        -Property @{
                            Protocol              = 'ftp'
                            IPAddress             = '*'
                            Port                  = 21
                            HostName              = 'ftp01.contoso.com'
                            CertificateThumbprint = ''
                            CertificateStoreName  = ''
                            SslFlags              = 0
                        }
                )

                It 'should return False' {
                    Test-BindingInfo -BindingInfo $MockBindingInfo | Should Be $false
                }
            }

        }

        Describe "$script:DSCHelplerModuleName\Test-PortNumber" {
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

        Describe "$script:DSCHelplerModuleName\Test-WebsiteBinding" {
            $MockWebBinding = @(
                @{
                    bindingInformation   = '*:21:'
                    protocol             = 'ftp'
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
                        Protocol  = 'ftp'
                        IPAddress = '*'
                        Port      = 21
                        HostName  = ''
                    }
                )

                It 'should throw the correct error' {
                    Mock -CommandName Test-BindingInfo -MockWith {return $false}

                    $ErrorId = 'WebsiteBindingInputInvalidation'
                    $ErrorCategory = [System.Management.Automation.ErrorCategory]::InvalidResult
                    $ErrorMessage = $LocalizedData.ErrorWebsiteBindingInputInvalidation -f $MockWebsite.Name
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
                        Protocol  = 'ftp'
                        IPAddress = '*'
                        Port      = 21
                        HostName  = ''
                    }
                )

                $ErrorId = 'WebsiteCompareFailure'
                $ErrorCategory = [System.Management.Automation.ErrorCategory]::InvalidResult
                $ErrorMessage = $LocalizedData.ErrorWebsiteCompareFailure -f $MockWebsite.Name, 'ScriptHalted'
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
                            Protocol              = 'ftp'
                            IPAddress             = '*'
                            Port                  = 2121
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

            Context 'IPAddress is different' {
                $MockBindingInfo = @(
                    New-CimInstance `
                    -ClassName MSFT_xWebBindingInformation `
                    -Namespace root/microsoft/Windows/DesiredStateConfiguration `
                    -ClientOnly `
                    -Property @{
                        Protocol              = 'ftp'
                        IPAddress             = '127.0.0.1'
                        Port                  = 21
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
                            Protocol              = 'ftp'
                            IPAddress             = '*'
                            Port                  = 21
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

            Context 'Bindings are identical' {
                $MockBindingInfo = @(

                    New-CimInstance `
                        -ClassName MSFT_xWebBindingInformation `
                        -Namespace root/microsoft/Windows/DesiredStateConfiguration `
                        -ClientOnly `
                        -Property @{
                            IPAddress             = '*'
                            Port                  = 21
                            HostName              = ''
                            Protocol              = 'ftp'
                            CertificateThumbprint = ''
                            CertificateStoreName  = ''
                            SslFlags              = 0
                        }
                )

                $MockWebBinding = @(
                    @{
                        bindingInformation   = '*:21:'
                        protocol             = 'ftp'
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
                            Protocol              = 'ftp'
                            IPAddress             = '*'
                            Port                  = 21
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
                            Protocol              = 'ftp'
                            IPAddress             = '*'
                            Port                  = 2121
                            HostName              = ''
                            CertificateThumbprint = ''
                            CertificateStoreName  = ''
                            SslFlags              = 0
                        }
                )

                $MockWebBinding = @(
                    @{
                        bindingInformation   = '*:21:'
                        protocol             = 'ftp'
                        certificateHash      = ''
                        certificateStoreName = ''
                        sslFlags             = '0'
                    }

                    @{
                        bindingInformation   = '*:2122:'
                        protocol             = 'ftp'
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
        }

        Describe "$script:DSCHelplerModuleName\Update-WebsiteBinding" {
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
                        Protocol              = 'ftp'
                        IPAddress             = '*'
                        Port                  = 21
                        HostName              = ''
                        CertificateThumbprint = ''
                        CertificateStoreName  = ''
                        SslFlags              = 0
                    }
            )

            Mock -CommandName Get-WebConfiguration -ParameterFilter {
                $Filter -eq '/system.applicationHost/sites/site'
            } -MockWith { return $MockWebsite } -Verifiable

            Mock -CommandName Clear-WebConfiguration -Verifiable

            Context 'Expected behavior' {
                Mock -CommandName Add-WebConfiguration

                Update-WebsiteBinding -Name $MockWebsite.Name -BindingInfo $MockBindingInfo

                It 'should call all the mocks' {
                    Assert-MockCalled -CommandName Get-WebConfiguration -Exactly 1
                    Assert-MockCalled -CommandName Add-WebConfiguration -Exactly $MockBindingInfo.Count
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
                    $ErrorMessage = $LocalizedData.ErrorWebsiteNotFound -f $MockWebsite.Name
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
                    $ErrorMessage = $LocalizedData.ErrorWebsiteBindingUpdateFailure -f $MockWebsite.Name, 'ScriptHalted'
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
        }
    }
}

    #endregion
finally
{
    #region FOOTER
    Restore-TestEnvironment -TestEnvironment $TestEnvironment
    #endregion
}
