$Global:DSCModuleName   = 'xWebAdministration'
$Global:DSCResourceName = 'MSFT_xWebApplication'

#region HEADER
# Integration Test Template Version: 1.1.0
[String] $moduleRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $Script:MyInvocation.MyCommand.Path))
if ( (-not (Test-Path -Path (Join-Path -Path $moduleRoot -ChildPath 'DSCResource.Tests'))) -or `
     (-not (Test-Path -Path (Join-Path -Path $moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1'))) )
{
    & git @('clone','https://github.com/PowerShell/DscResource.Tests.git',(Join-Path -Path $moduleRoot -ChildPath '\DSCResource.Tests\'))
}

Import-Module (Join-Path -Path $moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1') -Force
$TestEnvironment = Initialize-TestEnvironment `
    -DSCModuleName $Global:DSCModuleName `
    -DSCResourceName $Global:DSCResourceName `
    -TestType Integration 
#endregion

[string] $tempName = "$($Global:DSCResourceName)_" + (Get-Date).ToString('yyyyMMdd_HHmmss')

try
{
    # Now that xWebAdministration should be discoverable load the configuration data
    $ConfigFile = Join-Path -Path $PSScriptRoot -ChildPath "$($Global:DSCResourceName).config.ps1"
    . $ConfigFile

    $null = Backup-WebConfiguration -Name $tempName

    $DSCConfig = Import-LocalizedData -BaseDirectory $PSScriptRoot -FileName "$($Global:DSCResourceName).config.psd1"

    Describe "$($Global:DSCResourceName)_Present" {
        #region DEFAULT TESTS
        It 'Should compile without throwing' {
            {
                Invoke-Expression -Command "$($Global:DSCResourceName)_Present -ConfigurationData `$DSCConfig -OutputPath `$TestEnvironment.WorkingFolder"
                Start-DscConfiguration -Path $TestEnvironment.WorkingFolder -ComputerName localhost -Wait -Verbose -Force
            } | Should not throw
        }

        It 'should be able to call Get-DscConfiguration without throwing' {
            { Get-DscConfiguration -Verbose -ErrorAction Stop } | Should Not throw
        }
        #endregion

        It 'Should create a WebApplication with correct settings' -test {
            
            Invoke-Expression -Command "$($Global:DSCResourceName)_Present -ConfigurationData `$DSCConfg  -OutputPath `$TestEnvironment.WorkingFolder"

            # Build Results to test
            $Result = [ADSI]'IIS://localhost/smtpsvc/1'
            
            $Result.Name | Should be $DSCConfig.AllNodes.Name
            $Result.Properties.AuthFlags | Should be Should Be $DSCConfig.AllNodes.AuthFlags
            $Result.Properties.BadMailDirectory | Should be Should Be $DSCConfig.AllNodes.BadMailDirectory
            $Result.Properties.ConnectionTimeout | Should be Should Be $DSCConfig.AllNodes.ConnectionTimeout
            $Result.Properties.EnableReverseDnsLookup | Should be Should Be $DSCConfig.AllNodes.EnableReverseDnsLookup
            $Result.Properties.FullyQualifiedDomainName | Should be Should Be $DSCConfig.AllNodes.FullyQualifiedDomainName
            $Result.Properties.HopCount | Should be Should Be $DSCConfig.AllNodes.HopCount
            $Result.Properties.LogFileDirectory | Should be Should Be $DSCConfig.AllNodes.LogFileDirectory
            $Result.Properties.LogFilePeriod | Should be Should Be $DSCConfig.AllNodes.LogFilePeriod
            $Result.Properties.LogFileTruncateSize | Should be Should Be $DSCConfig.AllNodes.LogFileTruncateSize
            $Result.Properties.LogType | Should be Should Be $DSCConfig.AllNodes.LogType
            $Result.Properties.MasqueradeDomain | Should be Should Be $DSCConfig.AllNodes.MasqueradeDomain
            $Result.Properties.MaxBatchedMessages | Should be Should Be $DSCConfig.AllNodes.MaxBatchedMessages
            $Result.Properties.MaxConnections | Should be Should Be $DSCConfig.AllNodes.MaxConnections
            $Result.Properties.MaxMessageSize | Should be Should Be $DSCConfig.AllNodes.MaxMessageSize
            $Result.Properties.MaxOutConnections | Should be Should Be $DSCConfig.AllNodes.MaxOutConnections
            $Result.Properties.MaxOutConnectionsPerDomain | Should be Should Be $DSCConfig.AllNodes.MaxOutConnectionsPerDomain
            $Result.Properties.MaxRecipients | Should be Should Be $DSCConfig.AllNodes.MaxRecipients
            $Result.Properties.MaxSessionSize | Should be Should Be $DSCConfig.AllNodes.MaxSessionSize
            $Result.Properties.RelayForAuth | Should be Should Be $DSCConfig.AllNodes.RelayForAuth
            $Result.Properties.RemoteSmtpPort | Should be Should Be $DSCConfig.AllNodes.RemoteSmtpPort
            $Result.Properties.RemoteTimeout | Should be Should Be $DSCConfig.AllNodes.RemoteTimeout
            $Result.Properties.SaslLogonDomain | Should be Should Be $DSCConfig.AllNodes.SaslLogonDomain
            $Result.Properties.SendNdrTo | Should be Should Be $DSCConfig.AllNodes.SendNdrTo
            $Result.Properties.ServerBindings | Should be Should Be $DSCConfig.AllNodes.ServerBindings
            $Result.Properties.SmartHost | Should be Should Be $DSCConfig.AllNodes.SmartHost
            $Result.Properties.SmartHostType | Should be Should Be $DSCConfig.AllNodes.SmartHostType
            $Result.Properties.SmtpInboundCommandSupportOptions | Should be Should Be $DSCConfig.AllNodes.SmtpInboundCommandSupportOptions
            $Result.Properties.SmtpLocalDelayExpireMinutes | Should be Should Be $DSCConfig.AllNodes.SmtpLocalDelayExpireMinutes
            $Result.Properties.SmtpLocalNDRExpireMinutes | Should be Should Be $DSCConfig.AllNodes.SmtpLocalNDRExpireMinutes
            $Result.Properties.SmtpRemoteDelayExpireMinutes | Should be Should Be $DSCConfig.AllNodes.SmtpRemoteDelayExpireMinutes
            $Result.Properties.SmtpRemoteNDRExpireMinutes | Should be Should Be $DSCConfig.AllNodes.SmtpRemoteNDRExpireMinutes
            $Result.Properties.SmtpRemoteProgressiveRetry | Should be Should Be $DSCConfig.AllNodes.SmtpRemoteProgressiveRetry
            
        }
    
    }

}
finally
{
    #region FOOTER
    Restore-WebConfiguration -Name $tempName
    Remove-WebConfigurationBackup -Name $tempName

    Restore-TestEnvironment -TestEnvironment $TestEnvironment
    #endregion
}