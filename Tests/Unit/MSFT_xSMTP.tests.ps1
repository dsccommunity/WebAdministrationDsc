$global:DSCModuleName = 'xWebAdministration'
$global:DSCResourceName = 'MSFT_xSMTP'

#region HEADER
[String] $moduleRoot = Split-Path -Parent -Path (Split-Path -Parent -Path (Split-Path -Parent -Path $Script:MyInvocation.MyCommand.Path))
if ( (-not (Test-Path -Path (Join-Path -Path $moduleRoot -ChildPath 'DSCResource.Tests'))) -or `
(-not (Test-Path -Path (Join-Path -Path $moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1'))) )
{
    & git.exe @('clone', 'https://github.com/PowerShell/DscResource.Tests.git', (Join-Path -Path $moduleRoot -ChildPath '\DSCResource.Tests\'))
}

Import-Module (Join-Path -Path $moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1') -Force
$TestEnvironment = Initialize-TestEnvironment `
    -DSCModuleName $global:DSCModuleName `
    -DSCResourceName $global:DSCResourceName `
    -TestType Unit
#endregion

# Begin Testing

try
{
    #region Pester Tests

    InModuleScope -ModuleName $DSCResourceName -ScriptBlock {
    
            $MockSMTP = @{
                Name       = '1'
                Properties = @{
                    AuthFlags                        = '1'
                    BadMailDirectory                 = '{C:\Inetpub\mailroot\Badmail} '
                    ConnectionTimeout                = '600'
                    EnableReverseDnsLookup           = $false
                    FullyQualifiedDomainName         = 'WIN-A1234567890'
                    HopCount                         = '15'
                    LogFileDirectory                 = 'C:\Windows\System32\LogFiles'
                    LogFilePeriod                    = '1'
                    LogFileTruncateSize              = '20480000'
                    LogType                          = '0'
                    MasqueradeDomain                 = ''
                    MaxBatchedMessages               = ''
                    MaxConnections                   = '2000000000'
                    MaxMessageSize                   = '2097152'
                    MaxOutConnections                = '1000'
                    MaxOutConnectionsPerDomain       = '100'
                    MaxRecipients                    = '100'
                    MaxSessionSize                   = '10485760'
                    RelayForAuth                     = '1'
                    RemoteSmtpPort                   = '25'
                    RemoteTimeout                    = '600'
                    SaslLogonDomain                  = ''
                    SendNdrTo                        = ''
                    ServerBindings                   = ':25:'
                    SmartHost                        = ''
                    SmartHostType                    = '0'
                    SmtpInboundCommandSupportOptions = '7697601'
                    SmtpLocalDelayExpireMinutes      = '720'
                    SmtpLocalNDRExpireMinutes        = '2880'
                    SmtpRemoteDelayExpireMinutes     = '720'
                    SmtpRemoteNDRExpireMinutes       = '2880'
                    SmtpRemoteProgressiveRetry       = '15,30,60,240'
                } 
            }

            $MockParamaters = @{
                Name                             = '1'
                AuthFlags                        = '2'
                BadMailDirectory                 = '{C:\SMTP\Badmail} '
                ConnectionTimeout                = '1200'
                EnableReverseDnsLookup           = $true
                FullyQualifiedDomainName         = 'domain.com'
                HopCount                         = '30'
                LogFileDirectory                 = 'C:\SMTP\LogFiles'
                LogFilePeriod                    = '2'
                LogFileTruncateSize              = '40960000'
                LogType                          = '1'
                MasqueradeDomain                 = 'Mock@domain.com'
                MaxBatchedMessages               = '10'
                MaxConnections                   = '1000000000'
                MaxMessageSize                   = '1024152'
                MaxOutConnections                = '2000'
                MaxOutConnectionsPerDomain       = '200'
                MaxRecipients                    = '200'
                MaxSessionSize                   = '20965760'
                RelayForAuth                     = '2'
                RemoteSmtpPort                   = '26'
                RemoteTimeout                    = '1200'
                SaslLogonDomain                  = 'Mock@domain.com'
                SendNdrTo                        = 'ndr@domain.com'
                ServerBindings                   = @(':25', ':26')
                SmartHost                        = 'smarthost.domain.com'
                SmartHostType                    = '1'
                SmtpInboundCommandSupportOptions = '1234567'
                SmtpLocalDelayExpireMinutes      = '1440'
                SmtpLocalNDRExpireMinutes        = '7220'
                SmtpRemoteDelayExpireMinutes     = '1440'
                SmtpRemoteNDRExpireMinutes       = '7220'
                SmtpRemoteProgressiveRetry       = '30,60,120,480'
            }

        Describe -Name "$global:DSCResourceName\Assert-Module" -Fixture {
            Context -Name 'WebAdminstration module is not installed' -Fixture {
                Mock -ModuleName Helper -CommandName Get-Module -MockWith {
                    return $null
                }

                It -name 'should throw an error' -test {
                    {
                        Assert-Module 
                    } | 
                    Should Throw
                }
            }
        }

        Describe -Name "how $global:DSCResourceName\Get-TargetResource responds" -Fixture {

            Context -Name 'SMTP virtual server does not exist' -Fixture {
                Mock -CommandName Get-SMTPSettings -MockWith {
                    return $null
                }

                $Result = Get-TargetResource -Name '1'
                
                It -name 'should return Name' -test {
                    $Result.Name | Should Be $MockSMTP.Name
                }

                It -name 'should return NullOrEmpty for all other settings' -test {
                    $Result.AuthFlags | Should BeNullOrEmpty
                    $Result.BadMailDirectory | Should BeNullOrEmpty
                    $Result.ConnectionTimeout | Should BeNullOrEmpty
                    $Result.EnableReverseDnsLookup | Should BeNullOrEmpty
                    $Result.FullyQualifiedDomainName | Should BeNullOrEmpty
                    $Result.HopCount | Should BeNullOrEmpty
                    $Result.LogFileDirectory | Should BeNullOrEmpty
                    $Result.LogFilePeriod | Should BeNullOrEmpty
                    $Result.LogFileTruncateSize | Should BeNullOrEmpty
                    $Result.LogType | Should BeNullOrEmpty
                    $Result.MasqueradeDomain | Should BeNullOrEmpty
                    $Result.MaxBatchedMessages | Should BeNullOrEmpty
                    $Result.MaxConnections | Should BeNullOrEmpty
                    $Result.MaxMessageSize | Should BeNullOrEmpty
                    $Result.MaxOutConnections | Should BeNullOrEmpty
                    $Result.MaxOutConnectionsPerDomain | Should BeNullOrEmpty
                    $Result.MaxRecipients | Should BeNullOrEmpty
                    $Result.MaxSessionSize | Should BeNullOrEmpty
                    $Result.RelayForAuth | Should BeNullOrEmpty
                    $Result.RemoteSmtpPort | Should BeNullOrEmpty
                    $Result.RemoteTimeout | Should BeNullOrEmpty
                    $Result.SaslLogonDomain | Should BeNullOrEmpty
                    $Result.SendNdrTo | Should BeNullOrEmpty
                    $Result.ServerBindings | Should BeNullOrEmpty
                    $Result.SmartHost | Should BeNullOrEmpty
                    $Result.SmartHostType | Should BeNullOrEmpty
                    $Result.SmtpInboundCommandSupportOptions | Should BeNullOrEmpty
                    $Result.SmtpLocalDelayExpireMinutes | Should BeNullOrEmpty
                    $Result.SmtpLocalNDRExpireMinutes | Should BeNullOrEmpty
                    $Result.SmtpRemoteDelayExpireMinutes | Should BeNullOrEmpty
                    $Result.SmtpRemoteNDRExpireMinutes | Should BeNullOrEmpty
                    $Result.SmtpRemoteProgressiveRetry | Should BeNullOrEmpty
                }
            }

            Context -Name 'Single SMTP virtual server exists' -Fixture {
                Mock -CommandName Get-SMTPSettings -MockWith {
                    return $MockSMTP
                }

                $Result = Get-TargetResource -Name '1'

                It -name 'should call Get-SMTPSettings once' -test {
                    Assert-MockCalled -CommandName Get-SMTPSettings -Exactly -Times 1
                }
                
                It -name 'should return Name' -test {
                    $Result.Name | Should Be $MockSMTP.Name
                }

                It -name 'should return AuthFlags' -test {
                    $Result.AuthFlags | Should Be $MockSMTP.Properties.AuthFlags
                }

                It -name 'should return BadMailDirectory' -test {
                    $Result.BadMailDirectory | Should Be $MockSMTP.Properties.BadMailDirectory
                }

                It -name 'should return ConnectionTimeout' -test {
                    $Result.ConnectionTimeout | Should Be $MockSMTP.Properties.ConnectionTimeout
                }

                It -name 'should return EnableReverseDnsLookup' -test {
                    $Result.EnableReverseDnsLookup | Should Be $MockSMTP.Properties.EnableReverseDnsLookup
                }

                It -name 'should return FullyQualifiedDomainName' -test {
                    $Result.FullyQualifiedDomainName | Should Be $MockSMTP.Properties.FullyQualifiedDomainName
                }

                It -name 'should return HopCount' -test {
                    $Result.HopCount | Should Be $MockSMTP.Properties.HopCount
                }

                It -name 'should return LogFileDirectory' -test {
                    $Result.LogFileDirectory | Should Be $MockSMTP.Properties.LogFileDirectory
                }

                It -name 'should return LogFilePeriod' -test {
                    $Result.LogFilePeriod | Should Be $MockSMTP.Properties.LogFilePeriod
                }

                It -name 'should return LogFileTruncateSize' -test {
                    $Result.LogFileTruncateSize | Should Be $MockSMTP.Properties.LogFileTruncateSize
                }

                It -name 'should return LogType' -test {
                    $Result.LogType | Should Be $MockSMTP.Properties.LogType
                }

                It -name 'should return MasqueradeDomain' -test {
                    $Result.MasqueradeDomain | Should Be $MockSMTP.Properties.MasqueradeDomain
                }

                It -name 'should return MaxBatchedMessages' -test {
                    $Result.MaxBatchedMessages | Should Be $MockSMTP.Properties.MaxBatchedMessages
                }

                It -name 'should return MaxConnections' -test {
                    $Result.MaxConnections | Should Be $MockSMTP.Properties.MaxConnections
                }

                It -name 'should return MaxMessageSize' -test {
                    $Result.MaxMessageSize | Should Be $MockSMTP.Properties.MaxMessageSize
                }

                It -name 'should return MaxOutConnections' -test {
                    $Result.MaxOutConnections | Should Be $MockSMTP.Properties.MaxOutConnections
                }

                It -name 'should return MaxOutConnectionsPerDomain' -test {
                    $Result.MaxOutConnectionsPerDomain | Should Be $MockSMTP.Properties.MaxOutConnectionsPerDomain
                }

                It -name 'should return MaxRecipients' -test {
                    $Result.MaxRecipients | Should Be $MockSMTP.Properties.MaxRecipients
                }

                It -name 'should return MaxSessionSize' -test {
                    $Result.MaxSessionSize | Should Be $MockSMTP.Properties.MaxSessionSize
                }

                It -name 'should return RelayForAuth' -test {
                    $Result.RelayForAuth | Should Be $MockSMTP.Properties.RelayForAuth
                }

                It -name 'should return RemoteSmtpPort' -test {
                    $Result.RemoteSmtpPort | Should Be $MockSMTP.Properties.RemoteSmtpPort
                }

                It -name 'should return RemoteTimeout' -test {
                    $Result.RemoteTimeout | Should Be $MockSMTP.Properties.RemoteTimeout
                }

                It -name 'should return SaslLogonDomain' -test {
                    $Result.SaslLogonDomain | Should Be $MockSMTP.Properties.SaslLogonDomain
                }

                It -name 'should return SendNdrTo' -test {
                    $Result.SendNdrTo | Should Be $MockSMTP.Properties.SendNdrTo
                }

                It -name 'should return ServerBindings' -test {
                    $Result.ServerBindings | Should Be $MockSMTP.Properties.ServerBindings
                }

                It -name 'should return SmartHost' -test {
                    $Result.SmartHost | Should Be $MockSMTP.Properties.SmartHost
                }

                It -name 'should return SmartHostType' -test {
                    $Result.SmartHostType | Should Be $MockSMTP.Properties.SmartHostType
                }

                It -name 'should return SmtpInboundCommandSupportOptions' -test {
                    $Result.SmtpInboundCommandSupportOptions | Should Be $MockSMTP.Properties.SmtpInboundCommandSupportOptions
                }

                It -name 'should return SmtpLocalDelayExpireMinutes' -test {
                    $Result.SmtpLocalDelayExpireMinutes | Should Be $MockSMTP.Properties.SmtpLocalDelayExpireMinutes
                }
                
                It -name 'should return SmtpLocalNDRExpireMinutes' -test {
                    $Result.SmtpLocalNDRExpireMinutes | Should Be $MockSMTP.Properties.SmtpLocalNDRExpireMinutes
                }
                
                It -name 'should return SmtpRemoteDelayExpireMinutes' -test {
                    $Result.SmtpRemoteDelayExpireMinutes | Should Be $MockSMTP.Properties.SmtpRemoteDelayExpireMinutes
                }

                It -name 'should return SmtpRemoteNDRExpireMinutes' -test {
                    $Result.SmtpRemoteNDRExpireMinutes | Should Be $MockSMTP.Properties.SmtpRemoteNDRExpireMinutes
                }

                It -name 'should return SmtpRemoteProgressiveRetry' -test {
                    $Result.SmtpRemoteProgressiveRetry | Should Be $MockSMTP.Properties.SmtpRemoteProgressiveRetry
                }
            }
        }

        Describe -Name "how $global:DSCResourceName\Test-TargetResource" -Fixture {
        
            Context 'SMTP Server does not exist' {

                Mock -CommandName Get-SMTPSettings

                It 'should throw when SMTP is not found' -test {
                    {
                        Test-TargetResource @MockParamaters 
                    } | 
                    Should Throw
                }
            }

            Context 'All Settings are incorrect' {

                Mock -CommandName Get-SMTPSettings -MockWith {
                    return $MockSMTP
                }

                $Result = Test-TargetResource -Name $MockParamaters.Name @MockParams

                It 'should return False' {
                    $Result[0] | Should Be $false
                }
                
                It 'should return the correct message' {
                    $Result[1] | Should Be $LocalizedData.VerboseTestTargetResource
                }
            }
            
            Context 'Check AuthFlags is different' {

                Mock -CommandName Get-SMTPSettings -MockWith {
                    return $MockSMTP
                }

                $Result = Test-TargetResource -Name $MockParamaters.Name -AuthFlags $MockParamaters.AuthFlags

                It 'should return False' {
                    $Result[0] | Should Be $false
                }

                It 'should return the correct message' {
                    $Result[1] | Should Be $LocalizedData.VerboseTestTargetResource
                }
                
            }

            Context 'Check BadMailDirectory is different' {
            
                Mock -CommandName Test-Path {Return $true}
            
                Mock -CommandName Get-SMTPSettings -MockWith {
                    return $MockSMTP
                }

                $Result = Test-TargetResource -Name $MockParamaters.Name -BadMailDirectory $MockParamaters.BadMailDirectory

                It 'should return False' {
                    $Result[0] | Should Be $false
                }

                It 'should return the correct message' {
                    $Result[1] | Should Be $LocalizedData.VerboseTestTargetFalseBadMailDirectory
                }
            }

            Context 'Check ConnectionTimeout is different' {

                Mock -CommandName Get-SMTPSettings -MockWith {
                    return $MockSMTP
                }

                $Result = Test-TargetResource -Name $MockParamaters.Name -ConnectionTimeout $MockParamaters.ConnectionTimeout

                It 'should return False' {
                    $Result[0] | Should Be $false
                }

                It 'should return the correct message' {
                    $Result[1] | Should Be $LocalizedData.VerboseTestTargetResource
                }

            }

            Context 'Check EnableReverseDnsLookup is different' {

                Mock -CommandName Get-SMTPSettings -MockWith {
                    return $MockSMTP
                }

                $Result = Test-TargetResource -Name $MockParamaters.Name -EnableReverseDnsLookup $MockParamaters.EnableReverseDnsLookup

                It 'should return False' {
                    $Result[0] | Should Be $false
                }
                                
                It 'should return the correct message' {
                    $Result[1] | Should Be $LocalizedData.VerboseTestTargetResource
                }
            }

            Context 'Check FullyQualifiedDomainName is different' {

                Mock -CommandName Get-SMTPSettings -MockWith {
                    return $MockSMTP
                }

                $Result = Test-TargetResource -Name $MockParamaters.Name -FullyQualifiedDomainName $MockParamaters.FullyQualifiedDomainName

                It 'should return False' {
                    $Result[0] | Should Be $false
                }
                                
                It 'should return the correct message' {
                    $Result[1] | Should Be $LocalizedData.VerboseTestTargetResource
                }
            }

            Context 'Check HopCount is different' {

                Mock -CommandName Get-SMTPSettings -MockWith {
                    return $MockSMTP
                }

                $Result = Test-TargetResource -Name $MockParamaters.Name -HopCount $MockParamaters.HopCount

                It 'should return False' {
                    $Result[0] | Should Be $false
                }
                                
                It 'should return the correct message' {
                    $Result[1] | Should Be $LocalizedData.VerboseTestTargetResource
                }
            }

            Context 'Check LogFileDirectory is different' {

                Mock -CommandName Test-Path {Return $true}

                Mock -CommandName Get-SMTPSettings -MockWith {
                    return $MockSMTP
                }

                $Result = Test-TargetResource -Name $MockParamaters.Name -LogFileDirectory $MockParamaters.LogFileDirectory

                It 'should return False' {
                    $Result[0] | Should Be $false
                }
                                
                It 'should return the correct message' {
                    $Result[1] | Should Be $LocalizedData.VerboseTestTargetFalseLogFileDirectory
                }

            }

            Context 'Check LogFilePeriod is different' {

                Mock -CommandName Get-SMTPSettings -MockWith {
                    return $MockSMTP
                }

                $Result = Test-TargetResource -Name $MockParamaters.Name -LogFilePeriod $MockParamaters.LogFilePeriod

                It 'should return False' {
                    $Result[0] | Should Be $false
                }
                                
                It 'should return the correct message' {
                    $Result[1] | Should Be $LocalizedData.VerboseTestTargetResource
                }
            }

            Context 'Check LogFileTruncateSize is different' {

                Mock -CommandName Get-SMTPSettings -MockWith {
                    return $MockSMTP
                }

                $Result = Test-TargetResource -Name $MockParamaters.Name -LogFileTruncateSize $MockParamaters.LogFileTruncateSize

                It 'should return False' {
                    $Result[0] | Should Be $false
                }
                                
                It 'should return the correct message' {
                    $Result[1] | Should Be $LocalizedData.VerboseTestTargetResource
                }
            }

            Context 'Check LogType is different' {

                Mock -CommandName Get-SMTPSettings -MockWith {
                    return $MockSMTP
                }

                $Result = Test-TargetResource -Name $MockParamaters.Name -LogType $MockParamaters.LogType

                It 'should return False' {
                    $Result[0] | Should Be $false
                }
                                
                It 'should return the correct message' {
                    $Result[1] | Should Be $LocalizedData.VerboseTestTargetResource
                }
            }

            Context 'Check MasqueradeDomain is different' {

                Mock -CommandName Get-SMTPSettings -MockWith {
                    return $MockSMTP
                }

                $Result = Test-TargetResource -Name $MockParamaters.Name -MasqueradeDomain $MockParamaters.MasqueradeDomain

                It 'should return False' {
                    $Result[0] | Should Be $false
                }
                                
                It 'should return the correct message' {
                    $Result[1] | Should Be $LocalizedData.VerboseTestTargetResource
                }
            }

            Context 'Check MaxBatchedMessages is different' {

                Mock -CommandName Get-SMTPSettings -MockWith {
                    return $MockSMTP
                }

                $Result = Test-TargetResource -Name $MockParamaters.Name -MaxBatchedMessages $MockParamaters.MaxBatchedMessages

                It 'should return False' {
                    $Result[0] | Should Be $false
                }
                                
                It 'should return the correct message' {
                    $Result[1] | Should Be $LocalizedData.VerboseTestTargetResource
                }
            }

            Context 'Check MaxConnections is different' {

                Mock -CommandName Get-SMTPSettings -MockWith {
                    return $MockSMTP
                }

                $Result = Test-TargetResource -Name $MockParamaters.Name -MaxConnections $MockParamaters.MaxConnections

                It 'should return False' {
                    $Result[0] | Should Be $false
                }
                                
                It 'should return the correct message' {
                    $Result[1] | Should Be $LocalizedData.VerboseTestTargetResource
                }
            }

            Context 'Check MaxMessageSize is different' {

                Mock -CommandName Get-SMTPSettings -MockWith {
                    return $MockSMTP
                }

                $Result = Test-TargetResource -Name $MockParamaters.Name -MaxMessageSize $MockParamaters.MaxMessageSize

                It 'should return False' {
                    $Result[0] | Should Be $false
                }
                                
                It 'should return the correct message' {
                    $Result[1] | Should Be $LocalizedData.VerboseTestTargetResource
                }
            }

            Context 'Check MaxOutConnections is different' {

                Mock -CommandName Get-SMTPSettings -MockWith {
                    return $MockSMTP
                }

                $Result = Test-TargetResource -Name $MockParamaters.Name -MaxOutConnections $MockParamaters.MaxOutConnections

                It 'should return False' {
                    $Result[0] | Should Be $false
                }
                                
                It 'should return the correct message' {
                    $Result[1] | Should Be $LocalizedData.VerboseTestTargetResource
                }
            }

            Context 'Check MaxOutConnectionsPerDomain is different' {

                Mock -CommandName Get-SMTPSettings -MockWith {
                    return $MockSMTP
                }

                $Result = Test-TargetResource -Name $MockParamaters.Name -MaxOutConnectionsPerDomain $MockParamaters.MaxOutConnectionsPerDomain

                It 'should return False' {
                    $Result[0] | Should Be $false
                }
                                
                It 'should return the correct message' {
                    $Result[1] | Should Be $LocalizedData.VerboseTestTargetResource
                }
            }

            Context 'Check MaxRecipients is different' {

                Mock -CommandName Get-SMTPSettings -MockWith {
                    return $MockSMTP
                }

                $Result = Test-TargetResource -Name $MockParamaters.Name -MaxRecipients $MockParamaters.MaxRecipients

                It 'should return False' {
                    $Result[0] | Should Be $false
                }
                                
                It 'should return the correct message' {
                    $Result[1] | Should Be $LocalizedData.VerboseTestTargetResource
                }
            }

            Context 'Check MaxSessionSize is different' {

                Mock -CommandName Get-SMTPSettings -MockWith {
                    return $MockSMTP
                }

                $Result = Test-TargetResource -Name $MockParamaters.Name -MaxSessionSize $MockParamaters.MaxSessionSize

                It 'should return False' {
                    $Result[0] | Should Be $false
                }
                                
                It 'should return the correct message' {
                    $Result[1] | Should Be $LocalizedData.VerboseTestTargetResource
                }
            }

            Context 'Check RelayForAuth is different' {

                Mock -CommandName Get-SMTPSettings -MockWith {
                    return $MockSMTP
                }

                $Result = Test-TargetResource -Name $MockParamaters.Name -RelayForAuth $MockParamaters.RelayForAuth

                It 'should return False' {
                    $Result[0] | Should Be $false
                }
                                
                It 'should return the correct message' {
                    $Result[1] | Should Be $LocalizedData.VerboseTestTargetResource
                }
            }

            Context 'Check RemoteSmtpPort is different' {

                Mock -CommandName Get-SMTPSettings -MockWith {
                    return $MockSMTP
                }

                $Result = Test-TargetResource -Name $MockParamaters.Name -RemoteSmtpPort $MockParamaters.RemoteSmtpPort

                It 'should return False' {
                    $Result[0] | Should Be $false
                }
                                
                It 'should return the correct message' {
                    $Result[1] | Should Be $LocalizedData.VerboseTestTargetResource
                }
            }

            Context 'Check RemoteTimeout is different' {

                Mock -CommandName Get-SMTPSettings -MockWith {
                    return $MockSMTP
                }

                $Result = Test-TargetResource -Name $MockParamaters.Name -RemoteTimeout $MockParamaters.RemoteTimeout

                It 'should return False' {
                    $Result[0] | Should Be $false
                }
                                
                It 'should return the correct message' {
                    $Result[1] | Should Be $LocalizedData.VerboseTestTargetResource
                }
            }

            Context 'Check SaslLogonDomain is different' {

                Mock -CommandName Get-SMTPSettings -MockWith {
                    return $MockSMTP
                }

                $Result = Test-TargetResource -Name $MockParamaters.Name -SaslLogonDomain $MockParamaters.SaslLogonDomain

                It 'should return False' {
                    $Result[0] | Should Be $false
                }
                                
                It 'should return the correct message' {
                    $Result[1] | Should Be $LocalizedData.VerboseTestTargetResource
                }
            }

            Context 'Check SendNdrTo is different' {

                Mock -CommandName Get-SMTPSettings -MockWith {
                    return $MockSMTP
                }

                $Result = Test-TargetResource -Name $MockParamaters.Name -SendNdrTo $MockParamaters.SendNdrTo

                It 'should return False' {
                    $Result[0] | Should Be $false
                }
                                                
                It 'should return the correct message' {
                    $Result[1] | Should Be $LocalizedData.VerboseTestTargetFalseSendNdrTo
                }
            }

            Context 'Check ServerBindings is different' {

                Mock -CommandName Get-SMTPSettings -MockWith {
                    return $MockSMTP
                }

                $Result = Test-TargetResource -Name $MockParamaters.Name -ServerBindings $MockParamaters.ServerBindings

                It 'should return False' {
                    $Result[0] | Should Be $false
                }
                                
                It 'should return the correct message' {
                    $Result[1] | Should Be $LocalizedData.VerboseTestTargetFalseServerBindings
                }

            }

            Context 'Check SmartHost is different' {

                Mock -CommandName Get-SMTPSettings -MockWith {
                    return $MockSMTP
                }

                $Result = Test-TargetResource -Name $MockParamaters.Name -SmartHost $MockParamaters.SmartHost

                It 'should return False' {
                    $Result[0] | Should Be $false
                }
                                
                It 'should return the correct message' {
                    $Result[1] | Should Be $LocalizedData.VerboseTestTargetResource
                }
            }

            Context 'Check SmartHostType is different' {

                Mock -CommandName Get-SMTPSettings -MockWith {
                    return $MockSMTP
                }

                $Result = Test-TargetResource -Name $MockParamaters.Name -SmartHostType $MockParamaters.SmartHostType

                It 'should return False' {
                    $Result[0] | Should Be $false
                }
                                
                It 'should return the correct message' {
                    $Result[1] | Should Be $LocalizedData.VerboseTestTargetResource
                }
            }

            Context 'Check SmtpInboundCommandSupportOptions is different' {

                Mock -CommandName Get-SMTPSettings -MockWith {
                    return $MockSMTP
                }

                $Result = Test-TargetResource -Name $MockParamaters.Name -SmtpInboundCommandSupportOptions $MockParamaters.SmtpInboundCommandSupportOptions


                It 'should return False' {
                    $Result[0] | Should Be $false
                }
                                
                It 'should return the correct message' {
                    $Result[1] | Should Be $LocalizedData.VerboseTestTargetResource
                }
            }

            Context 'Check SmtpLocalDelayExpireMinutes is different' {

                Mock -CommandName Get-SMTPSettings -MockWith {
                    return $MockSMTP
                }

                $Result = Test-TargetResource -Name $MockParamaters.Name -SmtpLocalDelayExpireMinutes $MockParamaters.SmtpLocalDelayExpireMinutes

                It 'should return False' {
                    $Result[0] | Should Be $false
                }
                                
                It 'should return the correct message' {
                    $Result[1] | Should Be $LocalizedData.VerboseTestTargetResource
                }
            }

            Context 'Check SmtpLocalNDRExpireMinutes is different' {

                Mock -CommandName Get-SMTPSettings -MockWith {
                    return $MockSMTP
                }

                $Result = Test-TargetResource -Name $MockParamaters.Name -SmtpLocalNDRExpireMinutes $MockParamaters.SmtpLocalNDRExpireMinutes

                It 'should return False' {
                    $Result[0] | Should Be $false
                }
                                
                It 'should return the correct message' {
                    $Result[1] | Should Be $LocalizedData.VerboseTestTargetResource
                }
            }

            Context 'Check SmtpRemoteDelayExpireMinutes is different' {

                Mock -CommandName Get-SMTPSettings -MockWith {
                    return $MockSMTP
                }

                $Result = Test-TargetResource -Name $MockParamaters.Name -SmtpRemoteDelayExpireMinutes $MockParamaters.SmtpRemoteDelayExpireMinutes

                It 'should return False' {
                    $Result[0] | Should Be $false
                }
                                
                It 'should return the correct message' {
                    $Result[1] | Should Be $LocalizedData.VerboseTestTargetResource
                }
            }

            Context 'Check SmtpRemoteNDRExpireMinutes is different' {

                Mock -CommandName Get-SMTPSettings -MockWith {
                    return $MockSMTP
                }

                $Result = Test-TargetResource -Name $MockParamaters.Name -SmtpRemoteNDRExpireMinutes $MockParamaters.SmtpRemoteNDRExpireMinutes

                It 'should return False' {
                    $Result[0] | Should Be $false
                }
                                
                It 'should return the correct message' {
                    $Result[1] | Should Be $LocalizedData.VerboseTestTargetResource
                }
            }

            Context 'Check SmtpRemoteProgressiveRetry is different' {

                Mock -CommandName Get-SMTPSettings -MockWith {
                    return $MockSMTP
                }

                $Result = Test-TargetResource -Name $MockParamaters.Name -SmtpRemoteProgressiveRetry $MockParamaters.SmtpRemoteProgressiveRetry

                It 'should return False' {
                    $Result[0] | Should Be $false
                }
                                
                It 'should return the correct message' {
                    $Result[1] | Should Be $LocalizedData.VerboseTestTargetResource
                }
            }

        }

        Describe -Name "how $global:DSCResourceName\Set-TargetResource" -Fixture {
        
            Context 'All Settings need to be updated' {

                Mock -CommandName Test-Path {Return $true}

                Mock -CommandName Get-SMTPSettings -MockWith {
                    return $MockSMTP
                }
                
                Mock -CommandName Set-SMTPSettings

                It 'should call expected mocks' {
                    
                    $result  = Set-TargetResource @MockParamaters
                    
                    Assert-MockCalled -CommandName  Set-SMTPSettings -Exactly 32
                }

            }

            Context 'Name exists but needs to be updated' {

                Mock Set-SMTPSettings {}
                Mock -CommandName Set-SMTPSettings -ParameterFilter { $Setting -eq 'Name' -and $Value -eq $MockParameters.Name }

                It 'should call the expected mocks' {
                    $Result = Set-TargetResource -Name $MockParamaters.Name -AuthFlags $MockParamaters.Name

                    Assert-MockCalled -CommandName Set-SMTPSettings -Exactly 0
                    Assert-MockCalled -CommandName Set-SMTPSettings -ParameterFilter { $Setting -eq 'Name' -and $Value -eq $MockParameters.Name } -Exactly 1
                }
            }

            Context 'AuthFlags exists but needs to be updated' {

                Mock Set-SMTPSettings {}
                Mock -CommandName Set-SMTPSettings -ParameterFilter { $Setting -eq 'AuthFlags' -and $Value -eq $MockParameters.AuthFlags }

                It 'should call the expected mocks' {
                    $Result = Set-TargetResource -Name $MockParamaters.Name -AuthFlags $MockParamaters.AuthFlags

                    Assert-MockCalled -CommandName Set-SMTPSettings -Exactly 0
                    Assert-MockCalled -CommandName Set-SMTPSettings -ParameterFilter { $Setting -eq 'AuthFlags' -and $Value -eq $MockParameters.AuthFlags } -Exactly 1
                }
            }

            Context 'BadMailDirectory exists but needs to be updated' {

                Mock Set-SMTPSettings {}
                Mock -CommandName Set-SMTPSettings -ParameterFilter { $Setting -eq 'BadMailDirectory' -and $Value -eq $MockParameters.BadMailDirectory }

                It 'should call the expected mocks' {
                    $Result = Set-TargetResource -Name $MockParamaters.Name -AuthFlags $MockParamaters.BadMailDirectory

                    Assert-MockCalled -CommandName Set-SMTPSettings -Exactly 0
                    Assert-MockCalled -CommandName Set-SMTPSettings -ParameterFilter { $Setting -eq 'BadMailDirectory' -and $Value -eq $MockParameters.BadMailDirectory } -Exactly 1
                }
            }

            Context 'ConnectionTimeou exists but needs to be updated' {

                Mock Set-SMTPSettings {}
                Mock -CommandName Set-SMTPSettings -ParameterFilter { $Setting -eq 'ConnectionTimeou' -and $Value -eq $MockParameters.ConnectionTimeou }

                It 'should call the expected mocks' {
                    $Result = Set-TargetResource -Name $MockParamaters.Name -AuthFlags $MockParamaters.ConnectionTimeou

                    Assert-MockCalled -CommandName Set-SMTPSettings -Exactly 0
                    Assert-MockCalled -CommandName Set-SMTPSettings -ParameterFilter { $Setting -eq 'ConnectionTimeou' -and $Value -eq $MockParameters.ConnectionTimeou } -Exactly 1
                }
            }

            Context 'EnableReverseDnsLookup exists but needs to be updated' {

                Mock Set-SMTPSettings {}
                Mock -CommandName Set-SMTPSettings -ParameterFilter { $Setting -eq 'EnableReverseDnsLookup' -and $Value -eq $MockParameters.EnableReverseDnsLookup }

                It 'should call the expected mocks' {
                    $Result = Set-TargetResource -Name $MockParamaters.Name -AuthFlags $MockParamaters.EnableReverseDnsLookup

                    Assert-MockCalled -CommandName Set-SMTPSettings -Exactly 0
                    Assert-MockCalled -CommandName Set-SMTPSettings -ParameterFilter { $Setting -eq 'EnableReverseDnsLookup' -and $Value -eq $MockParameters.EnableReverseDnsLookup } -Exactly 1
                }
            }

            Context 'FullyQualifiedDomainName exists but needs to be updated' {

                Mock Set-SMTPSettings {}
                Mock -CommandName Set-SMTPSettings -ParameterFilter { $Setting -eq 'FullyQualifiedDomainName' -and $Value -eq $MockParameters.FullyQualifiedDomainName }

                It 'should call the expected mocks' {
                    $Result = Set-TargetResource -Name $MockParamaters.Name -AuthFlags $MockParamaters.FullyQualifiedDomainName

                    Assert-MockCalled -CommandName Set-SMTPSettings -Exactly 0
                    Assert-MockCalled -CommandName Set-SMTPSettings -ParameterFilter { $Setting -eq 'FullyQualifiedDomainName' -and $Value -eq $MockParameters.FullyQualifiedDomainName } -Exactly 1
                }
            }

            Context 'HopCount exists but needs to be updated' {

                Mock Set-SMTPSettings {}
                Mock -CommandName Set-SMTPSettings -ParameterFilter { $Setting -eq 'HopCount' -and $Value -eq $MockParameters.HopCount }

                It 'should call the expected mocks' {
                    $Result = Set-TargetResource -Name $MockParamaters.Name -AuthFlags $MockParamaters.HopCount

                    Assert-MockCalled -CommandName Set-SMTPSettings -Exactly 0
                    Assert-MockCalled -CommandName Set-SMTPSettings -ParameterFilter { $Setting -eq 'HopCount' -and $Value -eq $MockParameters.HopCount } -Exactly 1
                }
            }

            Context 'LogFileDirectory exists but needs to be updated' {

                Mock Set-SMTPSettings {}
                Mock -CommandName Set-SMTPSettings -ParameterFilter { $Setting -eq 'LogFileDirectory' -and $Value -eq $MockParameters.LogFileDirectory }

                It 'should call the expected mocks' {
                    $Result = Set-TargetResource -Name $MockParamaters.Name -AuthFlags $MockParamaters.LogFileDirectory

                    Assert-MockCalled -CommandName Set-SMTPSettings -Exactly 0
                    Assert-MockCalled -CommandName Set-SMTPSettings -ParameterFilter { $Setting -eq 'LogFileDirectory' -and $Value -eq $MockParameters.LogFileDirectory } -Exactly 1
                }
            }

            Context 'LogFilePeriod exists but needs to be updated' {

                Mock Set-SMTPSettings {}
                Mock -CommandName Set-SMTPSettings -ParameterFilter { $Setting -eq 'LogFilePeriod' -and $Value -eq $MockParameters.LogFilePeriod }

                It 'should call the expected mocks' {
                    $Result = Set-TargetResource -Name $MockParamaters.Name -AuthFlags $MockParamaters.LogFilePeriod

                    Assert-MockCalled -CommandName Set-SMTPSettings -Exactly 0
                    Assert-MockCalled -CommandName Set-SMTPSettings -ParameterFilter { $Setting -eq 'LogFilePeriod' -and $Value -eq $MockParameters.LogFilePeriod } -Exactly 1
                }
            }

            Context 'LogFileTruncateSize exists but needs to be updated' {

                Mock Set-SMTPSettings {}
                Mock -CommandName Set-SMTPSettings -ParameterFilter { $Setting -eq 'LogFileTruncateSize' -and $Value -eq $MockParameters.LogFileTruncateSize }

                It 'should call the expected mocks' {
                    $Result = Set-TargetResource -Name $MockParamaters.Name -AuthFlags $MockParamaters.LogFileTruncateSize

                    Assert-MockCalled -CommandName Set-SMTPSettings -Exactly 0
                    Assert-MockCalled -CommandName Set-SMTPSettings -ParameterFilter { $Setting -eq 'LogFileTruncateSize' -and $Value -eq $MockParameters.LogFileTruncateSize } -Exactly 1
                }
            }

            Context 'LogType exists but needs to be updated' {

                Mock Set-SMTPSettings {}
                Mock -CommandName Set-SMTPSettings -ParameterFilter { $Setting -eq 'LogType' -and $Value -eq $MockParameters.LogType }

                It 'should call the expected mocks' {
                    $Result = Set-TargetResource -Name $MockParamaters.Name -AuthFlags $MockParamaters.LogType

                    Assert-MockCalled -CommandName Set-SMTPSettings -Exactly 0
                    Assert-MockCalled -CommandName Set-SMTPSettings -ParameterFilter { $Setting -eq 'LogType' -and $Value -eq $MockParameters.LogType } -Exactly 1
                }
            }

            Context 'MasqueradeDomain exists but needs to be updated' {

                Mock Set-SMTPSettings {}
                Mock -CommandName Set-SMTPSettings -ParameterFilter { $Setting -eq 'MasqueradeDomain' -and $Value -eq $MockParameters.MasqueradeDomain }

                It 'should call the expected mocks' {
                    $Result = Set-TargetResource -Name $MockParamaters.Name -AuthFlags $MockParamaters.MasqueradeDomain

                    Assert-MockCalled -CommandName Set-SMTPSettings -Exactly 0
                    Assert-MockCalled -CommandName Set-SMTPSettings -ParameterFilter { $Setting -eq 'MasqueradeDomain' -and $Value -eq $MockParameters.MasqueradeDomain } -Exactly 1
                }
            }

            Context 'MaxBatchedMessages exists but needs to be updated' {

                Mock Set-SMTPSettings {}
                Mock -CommandName Set-SMTPSettings -ParameterFilter { $Setting -eq 'MaxBatchedMessages' -and $Value -eq $MockParameters.MaxBatchedMessages }

                It 'should call the expected mocks' {
                    $Result = Set-TargetResource -Name $MockParamaters.Name -AuthFlags $MockParamaters.MaxBatchedMessages

                    Assert-MockCalled -CommandName Set-SMTPSettings -Exactly 0
                    Assert-MockCalled -CommandName Set-SMTPSettings -ParameterFilter { $Setting -eq 'MaxBatchedMessages' -and $Value -eq $MockParameters.MaxBatchedMessages } -Exactly 1
                }
            }

            Context 'MaxConnections exists but needs to be updated' {

                Mock Set-SMTPSettings {}
                Mock -CommandName Set-SMTPSettings -ParameterFilter { $Setting -eq 'MaxConnections' -and $Value -eq $MockParameters.MaxConnections }

                It 'should call the expected mocks' {
                    $Result = Set-TargetResource -Name $MockParamaters.Name -AuthFlags $MockParamaters.MaxConnections

                    Assert-MockCalled -CommandName Set-SMTPSettings -Exactly 0
                    Assert-MockCalled -CommandName Set-SMTPSettings -ParameterFilter { $Setting -eq 'MaxConnections' -and $Value -eq $MockParameters.MaxConnections } -Exactly 1
                }
            }

            Context 'MaxMessageSize exists but needs to be updated' {

                Mock Set-SMTPSettings {}
                Mock -CommandName Set-SMTPSettings -ParameterFilter { $Setting -eq 'MaxMessageSize' -and $Value -eq $MockParameters.MaxMessageSize }

                It 'should call the expected mocks' {
                    $Result = Set-TargetResource -Name $MockParamaters.Name -AuthFlags $MockParamaters.MaxMessageSize

                    Assert-MockCalled -CommandName Set-SMTPSettings -Exactly 0
                    Assert-MockCalled -CommandName Set-SMTPSettings -ParameterFilter { $Setting -eq 'MaxMessageSize' -and $Value -eq $MockParameters.MaxMessageSize } -Exactly 1
                }
            }

            Context 'MaxOutConnections exists but needs to be updated' {

                Mock Set-SMTPSettings {}
                Mock -CommandName Set-SMTPSettings -ParameterFilter { $Setting -eq 'MaxOutConnections' -and $Value -eq $MockParameters.MaxOutConnections }

                It 'should call the expected mocks' {
                    $Result = Set-TargetResource -Name $MockParamaters.Name -AuthFlags $MockParamaters.MaxOutConnections

                    Assert-MockCalled -CommandName Set-SMTPSettings -Exactly 0
                    Assert-MockCalled -CommandName Set-SMTPSettings -ParameterFilter { $Setting -eq 'MaxOutConnections' -and $Value -eq $MockParameters.MaxOutConnections } -Exactly 1
                }
            }

            Context 'MaxOutConnectionsPerDomain exists but needs to be updated' {

                Mock Set-SMTPSettings {}
                Mock -CommandName Set-SMTPSettings -ParameterFilter { $Setting -eq 'MaxOutConnectionsPerDomain' -and $Value -eq $MockParameters.MaxOutConnectionsPerDomain }

                It 'should call the expected mocks' {
                    $Result = Set-TargetResource -Name $MockParamaters.Name -AuthFlags $MockParamaters.MaxOutConnectionsPerDomain

                    Assert-MockCalled -CommandName Set-SMTPSettings -Exactly 0
                    Assert-MockCalled -CommandName Set-SMTPSettings -ParameterFilter { $Setting -eq 'MaxOutConnectionsPerDomain' -and $Value -eq $MockParameters.MaxOutConnectionsPerDomain } -Exactly 1
                }
            }

            Context 'MaxRecipients exists but needs to be updated' {

                Mock Set-SMTPSettings {}
                Mock -CommandName Set-SMTPSettings -ParameterFilter { $Setting -eq 'MaxRecipients' -and $Value -eq $MockParameters.MaxRecipients }

                It 'should call the expected mocks' {
                    $Result = Set-TargetResource -Name $MockParamaters.Name -AuthFlags $MockParamaters.MaxRecipients

                    Assert-MockCalled -CommandName Set-SMTPSettings -Exactly 0
                    Assert-MockCalled -CommandName Set-SMTPSettings -ParameterFilter { $Setting -eq 'MaxRecipients' -and $Value -eq $MockParameters.MaxRecipients } -Exactly 1
                }
            }

            Context 'MaxSessionSize exists but needs to be updated' {

                Mock Set-SMTPSettings {}
                Mock -CommandName Set-SMTPSettings -ParameterFilter { $Setting -eq 'MaxSessionSize' -and $Value -eq $MockParameters.MaxSessionSize }

                It 'should call the expected mocks' {
                    $Result = Set-TargetResource -Name $MockParamaters.Name -AuthFlags $MockParamaters.MaxSessionSize

                    Assert-MockCalled -CommandName Set-SMTPSettings -Exactly 0
                    Assert-MockCalled -CommandName Set-SMTPSettings -ParameterFilter { $Setting -eq 'MaxSessionSize' -and $Value -eq $MockParameters.MaxSessionSize } -Exactly 1
                }
            }

            Context 'RelayForAuth exists but needs to be updated' {

                Mock Set-SMTPSettings {}
                Mock -CommandName Set-SMTPSettings -ParameterFilter { $Setting -eq 'RelayForAuth' -and $Value -eq $MockParameters.RelayForAuth }

                It 'should call the expected mocks' {
                    $Result = Set-TargetResource -Name $MockParamaters.Name -AuthFlags $MockParamaters.RelayForAuth

                    Assert-MockCalled -CommandName Set-SMTPSettings -Exactly 0
                    Assert-MockCalled -CommandName Set-SMTPSettings -ParameterFilter { $Setting -eq 'RelayForAuth' -and $Value -eq $MockParameters.RelayForAuth } -Exactly 1
                }
            }

            Context 'RemoteSmtpPort exists but needs to be updated' {

                Mock Set-SMTPSettings {}
                Mock -CommandName Set-SMTPSettings -ParameterFilter { $Setting -eq 'RemoteSmtpPort' -and $Value -eq $MockParameters.RemoteSmtpPort }

                It 'should call the expected mocks' {
                    $Result = Set-TargetResource -Name $MockParamaters.Name -AuthFlags $MockParamaters.RemoteSmtpPort

                    Assert-MockCalled -CommandName Set-SMTPSettings -Exactly 0
                    Assert-MockCalled -CommandName Set-SMTPSettings -ParameterFilter { $Setting -eq 'RemoteSmtpPort' -and $Value -eq $MockParameters.RemoteSmtpPort } -Exactly 1
                }
            }

            Context 'RemoteTimeout exists but needs to be updated' {

                Mock Set-SMTPSettings {}
                Mock -CommandName Set-SMTPSettings -ParameterFilter { $Setting -eq 'RemoteTimeout' -and $Value -eq $MockParameters.RemoteTimeout }

                It 'should call the expected mocks' {
                    $Result = Set-TargetResource -Name $MockParamaters.Name -AuthFlags $MockParamaters.RemoteTimeout

                    Assert-MockCalled -CommandName Set-SMTPSettings -Exactly 0
                    Assert-MockCalled -CommandName Set-SMTPSettings -ParameterFilter { $Setting -eq 'RemoteTimeout' -and $Value -eq $MockParameters.RemoteTimeout } -Exactly 1
                }
            }

            Context 'SaslLogonDomain exists but needs to be updated' {

                Mock Set-SMTPSettings {}
                Mock -CommandName Set-SMTPSettings -ParameterFilter { $Setting -eq 'SaslLogonDomain' -and $Value -eq $MockParameters.SaslLogonDomain }

                It 'should call the expected mocks' {
                    $Result = Set-TargetResource -Name $MockParamaters.Name -AuthFlags $MockParamaters.SaslLogonDomain

                    Assert-MockCalled -CommandName Set-SMTPSettings -Exactly 0
                    Assert-MockCalled -CommandName Set-SMTPSettings -ParameterFilter { $Setting -eq 'SaslLogonDomain' -and $Value -eq $MockParameters.SaslLogonDomain } -Exactly 1
                }
            }

            Context 'SendNdrTo exists but needs to be updated' {

                Mock Set-SMTPSettings {}
                Mock -CommandName Set-SMTPSettings -ParameterFilter { $Setting -eq 'SendNdrTo' -and $Value -eq $MockParameters.SendNdrTo }

                It 'should call the expected mocks' {
                    $Result = Set-TargetResource -Name $MockParamaters.Name -AuthFlags $MockParamaters.SendNdrTo

                    Assert-MockCalled -CommandName Set-SMTPSettings -Exactly 0
                    Assert-MockCalled -CommandName Set-SMTPSettings -ParameterFilter { $Setting -eq 'SendNdrTo' -and $Value -eq $MockParameters.SendNdrTo } -Exactly 1
                }
            }

            Context 'ServerBindings exists but needs to be updated' {

                Mock Set-SMTPSettings {}
                Mock -CommandName Set-SMTPSettings -ParameterFilter { $Setting -eq 'ServerBindings' -and $Value -eq $MockParameters.ServerBindings }

                It 'should call the expected mocks' {
                    $Result = Set-TargetResource -Name $MockParamaters.Name -AuthFlags $MockParamaters.ServerBindings

                    Assert-MockCalled -CommandName Set-SMTPSettings -Exactly 0
                    Assert-MockCalled -CommandName Set-SMTPSettings -ParameterFilter { $Setting -eq 'ServerBindings' -and $Value -eq $MockParameters.ServerBindings } -Exactly 1
                }
            }

            Context 'SmartHost exists but needs to be updated' {

                Mock Set-SMTPSettings {}
                Mock -CommandName Set-SMTPSettings -ParameterFilter { $Setting -eq 'SmartHost' -and $Value -eq $MockParameters.SmartHost }

                It 'should call the expected mocks' {
                    $Result = Set-TargetResource -Name $MockParamaters.Name -AuthFlags $MockParamaters.SmartHost

                    Assert-MockCalled -CommandName Set-SMTPSettings -Exactly 0
                    Assert-MockCalled -CommandName Set-SMTPSettings -ParameterFilter { $Setting -eq 'SmartHost' -and $Value -eq $MockParameters.SmartHost } -Exactly 1
                }
            }

            Context 'SmartHostType exists but needs to be updated' {

                Mock Set-SMTPSettings {}
                Mock -CommandName Set-SMTPSettings -ParameterFilter { $Setting -eq 'SmartHostType' -and $Value -eq $MockParameters.SmartHostType }

                It 'should call the expected mocks' {
                    $Result = Set-TargetResource -Name $MockParamaters.Name -AuthFlags $MockParamaters.SmartHostType

                    Assert-MockCalled -CommandName Set-SMTPSettings -Exactly 0
                    Assert-MockCalled -CommandName Set-SMTPSettings -ParameterFilter { $Setting -eq 'SmartHostType' -and $Value -eq $MockParameters.SmartHostType } -Exactly 1
                }
            }

            Context 'SmtpInboundCommandSupportOptions exists but needs to be updated' {

                Mock Set-SMTPSettings {}
                Mock -CommandName Set-SMTPSettings -ParameterFilter { $Setting -eq 'SmtpInboundCommandSupportOptions' -and $Value -eq $MockParameters.SmtpInboundCommandSupportOptions }

                It 'should call the expected mocks' {
                    $Result = Set-TargetResource -Name $MockParamaters.Name -AuthFlags $MockParamaters.SmtpInboundCommandSupportOptions

                    Assert-MockCalled -CommandName Set-SMTPSettings -Exactly 0
                    Assert-MockCalled -CommandName Set-SMTPSettings -ParameterFilter { $Setting -eq 'SmtpInboundCommandSupportOptions' -and $Value -eq $MockParameters.SmtpInboundCommandSupportOptions } -Exactly 1
                }
            }

            Context 'SmtpLocalDelayExpireMinutes exists but needs to be updated' {

                Mock Set-SMTPSettings {}
                Mock -CommandName Set-SMTPSettings -ParameterFilter { $Setting -eq 'SmtpLocalDelayExpireMinutes' -and $Value -eq $MockParameters.SmtpLocalDelayExpireMinutes }

                It 'should call the expected mocks' {
                    $Result = Set-TargetResource -Name $MockParamaters.Name -AuthFlags $MockParamaters.SmtpLocalDelayExpireMinutes

                    Assert-MockCalled -CommandName Set-SMTPSettings -Exactly 0
                    Assert-MockCalled -CommandName Set-SMTPSettings -ParameterFilter { $Setting -eq 'SmtpLocalDelayExpireMinutes' -and $Value -eq $MockParameters.SmtpLocalDelayExpireMinutes } -Exactly 1
                }
            }

            Context 'SmtpLocalNDRExpireMinutes exists but needs to be updated' {

                Mock Set-SMTPSettings {}
                Mock -CommandName Set-SMTPSettings -ParameterFilter { $Setting -eq 'SmtpLocalNDRExpireMinutes' -and $Value -eq $MockParameters.SmtpLocalNDRExpireMinutes }

                It 'should call the expected mocks' {
                    $Result = Set-TargetResource -Name $MockParamaters.Name -AuthFlags $MockParamaters.SmtpLocalNDRExpireMinutes

                    Assert-MockCalled -CommandName Set-SMTPSettings -Exactly 0
                    Assert-MockCalled -CommandName Set-SMTPSettings -ParameterFilter { $Setting -eq 'SmtpLocalNDRExpireMinutes' -and $Value -eq $MockParameters.SmtpLocalNDRExpireMinutes } -Exactly 1
                }
            }

            Context 'SmtpRemoteDelayExpireMinutes exists but needs to be updated' {

                Mock Set-SMTPSettings {}
                Mock -CommandName Set-SMTPSettings -ParameterFilter { $Setting -eq 'SmtpRemoteDelayExpireMinutes' -and $Value -eq $MockParameters.SmtpRemoteDelayExpireMinutes }

                It 'should call the expected mocks' {
                    $Result = Set-TargetResource -Name $MockParamaters.Name -AuthFlags $MockParamaters.SmtpRemoteDelayExpireMinutes

                    Assert-MockCalled -CommandName Set-SMTPSettings -Exactly 0
                    Assert-MockCalled -CommandName Set-SMTPSettings -ParameterFilter { $Setting -eq 'SmtpRemoteDelayExpireMinutes' -and $Value -eq $MockParameters.SmtpRemoteDelayExpireMinutes } -Exactly 1
                }
            }

            Context 'SmtpRemoteNDRExpireMinutes exists but needs to be updated' {

                Mock Set-SMTPSettings {}
                Mock -CommandName Set-SMTPSettings -ParameterFilter { $Setting -eq 'SmtpRemoteNDRExpireMinutes' -and $Value -eq $MockParameters.SmtpRemoteNDRExpireMinutes }

                It 'should call the expected mocks' {
                    $Result = Set-TargetResource -Name $MockParamaters.Name -AuthFlags $MockParamaters.SmtpRemoteNDRExpireMinutes

                    Assert-MockCalled -CommandName Set-SMTPSettings -Exactly 0
                    Assert-MockCalled -CommandName Set-SMTPSettings -ParameterFilter { $Setting -eq 'SmtpRemoteNDRExpireMinutes' -and $Value -eq $MockParameters.SmtpRemoteNDRExpireMinutes } -Exactly 1
                }
            }

            Context 'SmtpRemoteProgressiveRetry exists but needs to be updated' {

                Mock Set-SMTPSettings {}
                Mock -CommandName Set-SMTPSettings -ParameterFilter { $Setting -eq 'SmtpRemoteProgressiveRetry' -and $Value -eq $MockParameters.SmtpRemoteProgressiveRetry }

                It 'should call the expected mocks' {
                    $Result = Set-TargetResource -Name $MockParamaters.Name -AuthFlags $MockParamaters.SmtpRemoteProgressiveRetry

                    Assert-MockCalled -CommandName Set-SMTPSettings -Exactly 0
                    Assert-MockCalled -CommandName Set-SMTPSettings -ParameterFilter { $Setting -eq 'SmtpRemoteProgressiveRetry' -and $Value -eq $MockParameters.SmtpRemoteProgressiveRetry } -Exactly 1
                }
            }

        }
        
        Describe -Name "$Global:DSCResourceName\Confirm-UnqiueBindings" -Fixture {
            Context 'Returns true when settings match' {

                It 'Returns true when settings match' {

                    Confirm-UnqiueBindings -ExistingBindings ':25:' `
                                           -ProposedBindings @(':25') `
                                           | Should be $true
                    
                }

            }
            
            Context 'Returns false when settings do match' {

                It 'Returns false when settings do match' {
                    
                    Confirm-UnqiueBindings -ExistingBindings ':25:' `
                                           -ProposedBindings @('server:25') `
                                           | Should be $false
                }

            }
        
        }
               
        Describe -Name "$Global:DSCResourceName\Test-EmailAddress" -Fixture {
        
            Context 'Returns true when email address is valid' {

                It 'Returns true when email address is valid' {
                    Test-EmailAddress -Email 'user@domain.com' `
                                      | should be $true
                }

                It 'Throws when email address is not vaild' {

                   { Test-EmailAddress -Email 'user.domain.com' } `
                                       | should Throw
                    
                }
            
            }

        }
        
        Describe -Name "$Global:DSCResourceName\Test-SMTPBindings" -Fixture {
        
            Context 'Returns true when IP and Ports are valid' {

                It 'Returns true when IP address is valid' {
                    Test-SMTPBindings -ServerBindings @('192.168.0.1:25') `
                                      | should be $true
                }

                It 'Throws when IP address is not vaild' {
                    { Test-SMTPBindings -ServerBindings @('300.168.0.1:25') } `
                                        | should Throw
                }

                It 'Returns true when port is valid' {
                    Test-SMTPBindings -ServerBindings @(':25') `
                                      | should be $true
                }

                It 'Throws when Port is not vaild' {
                    { Test-SMTPBindings -ServerBindings @('192.168.0.1:100000') } `
                                        | should Throw
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
