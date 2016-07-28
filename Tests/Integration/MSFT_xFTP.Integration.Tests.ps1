$script:DSCModuleName   = 'xWebAdministration'
$script:DSCResourceName = 'MSFT_xFTP'

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
    -TestType Integration
#endregion

[string] $tempName = "$($script:DSCResourceName)_" + (Get-Date).ToString('yyyyMMdd_HHmmss')

try
{
    # Now that xWebAdministration should be discoverable load the configuration data
    $ConfigFile = Join-Path -Path $PSScriptRoot -ChildPath "$($script:DSCResourceName).config.ps1"
    . $ConfigFile

    $null = Backup-WebConfiguration -Name $tempName

    $DSCConfig = Import-LocalizedData -BaseDirectory $PSScriptRoot -FileName "$($script:DSCResourceName).config.psd1"

    # Create a SelfSigned Cert
    $SelfSignedCert = (New-SelfSignedCertificate -DnsName $DSCConfig.AllNodes.BindingInfoHostName  -CertStoreLocation 'cert:\LocalMachine\My')
    
    #region HelperFunctions

    # Function needed to test AuthenticationInfo
    Function Get-AuthenticationInfo ($Type, $Website) {

        (Get-WebConfigurationProperty `
            -Filter /system.WebServer/security/authentication/${Type}Authentication `
            -Name enabled `
            -Location $Website).Value
    }

    function Get-AuthorizationInfo ($Type, $Website) {

        (get-webconfiguration '/system.ftpServer/security/authorization' -Location $Website).Collection.$Type
    }

    function Get-SslInfo ($Type, $Website) {

        (Get-Item -Path IIS:\Sites\${Website}\).ftpServer.security.ssl.${type}

    }

    #endregion

    Describe "$($script:DSCResourceName)_Present" {
        #region DEFAULT TESTS
        It 'Should compile without throwing' {
            {
                Invoke-Expression -Command "$($script:DSCResourceName)_Present -ConfigurationData `$DSCConfig -OutputPath `$TestEnvironment.WorkingFolder -CertificateThumbprint `$SelfSignedCert.Thumbprint"
                Start-DscConfiguration -Path $TestEnvironment.WorkingFolder -ComputerName localhost -Wait -Verbose -Force
            } | Should not throw
        }

        It 'should be able to call Get-DscConfiguration without throwing' {
            { Get-DscConfiguration -Verbose -ErrorAction Stop } | Should Not throw
        }
        #endregion

        It 'Should Create a Started FTP site with correct settings' -test {
            
            Invoke-Expression -Command "$($script:DSCResourceName)_Present -ConfigurationData `$DSCConfg  -OutputPath `$TestEnvironment.WorkingFolder -CertificateThumbprint `$SelfSignedCert.Thumbprint"

            # Build results to test
            $result = Get-Website -Name $DSCConfig.AllNodes.Name

            # Test basic settings are correct
            $result.Name             | Should Be $DSCConfig.AllNodes.Name
            $result.PhysicalPath     | Should Be $DSCConfig.AllNodes.PhysicalPath
            $result.State            | Should Be 'Started'
            $result.ApplicationPool  | Should Be $DSCConfig.AllNodes.ApplicationPool
            
            # Test that AuthenticationInfo is correct
            Get-AuthenticationInfo -Type 'Anonymous' -Website $DSCConfig.AllNodes.Name | Should Be $DSCConfig.AllNodes.AuthenticationInfoAnonymous
            Get-AuthenticationInfo -Type 'Basic' -Website $DSCConfig.AllNodes.Name     | Should Be $DSCConfig.AllNodes.AuthenticationInfoBasic
            
            # Test bindings are correct
            $result.bindings.Collection.Protocol           | Should Be $DSCConfig.AllNodes.BindingInfoProtocol
            $result.bindings.Collection.BindingInformation | Should Match $DSCConfig.AllNodes.BindingInfoPort
            $result.bindings.Collection.BindingInformation | Should Match $DSCConfig.AllNodes.BindingInfoHostName

            # Test that AuthorizationInfo is correct
            $AccessType = Get-AuthorizationInfo -Type AccessType -Website $DSCConfig.AllNodes.Name
            $Roles = Get-AuthorizationInfo -Type Roles -Website $DSCConfig.AllNodes.Name
            $Permissions = Get-AuthorizationInfo -Type Permissions -Website $DSCConfig.AllNodes.Name
            $Users = Get-AuthorizationInfo -Type Users -Website $DSCConfig.AllNodes.Name

            $AccessType[0]  | Should be $DSCConfig.AllNodes.AuthorizationInfoAccessType
            $AccessType[1]  | Should be $DSCConfig.AllNodes.AuthorizationInfoAccessType
            $Roles[0]       | Should BeNullOrEmpty
            $Roles[1]       | Should be $DSCConfig.AllNodes.AuthorizationInfoRoles
            $Permissions[0] | Should be $DSCConfig.AllNodes.AuthorizationInfoPermissions
            $Permissions[1] | Should be $DSCConfig.AllNodes.AuthorizationInfoPermissions
            $Users[0]       | Should be $DSCConfig.AllNodes.AuthorizationInfoUsers
            $Users[1]       | Should BeNullOrEmpty

            # Test SslInfo
            Get-SslInfo -Type controlChannelPolicy -Website $DSCConfig.AllNodes.Name | Should be $DSCConfig.AllNodes.SslInfoControlChannelPolicy
            Get-SslInfo -Type dataChannelPolicy -Website $DSCConfig.AllNodes.Name    | Should be $DSCConfig.AllNodes.SslInfoDataChannelPolicy
            Get-SslInfo -Type ssl128 -Website $DSCConfig.AllNodes.Name               | Should be $DSCConfig.AllNodes.SslInfoRequireSsl128
            Get-SslInfo -Type serverCertHash -Website $DSCConfig.AllNodes.Name       | Should be $SelfSignedCert.Thumbprint
            Get-SslInfo -Type serverCertStoreName -Website $DSCConfig.AllNodes.Name  | Should be $DSCConfig.AllNodes.SslInfoCertificateStoreName

            #Test Log Settings
            $result.ftpserver.logFile.logExtFileFlags   | Should be ($DSCConfig.AllNodes.LogFlags -join ',')
            $result.ftpserver.logFile.directory         | Should be $DSCConfig.AllNodes.LogPath
            $result.ftpserver.logFile.period            | Should be $DSCConfig.AllNodes.LogPeriod
            $result.ftpserver.logFile.localTimeRollover | Should be $DSCConfig.AllNodes.LoglocalTimeRollover

            # Test DirectoryBrowseFlags
            $result.ftpServer.directoryBrowse.showFlags| Should be $DSCConfig.AllNodes.DirectoryBrowseFlags

            #Test UserIsolation
            $result.ftpServer.userIsolation.mode | Should be $DSCConfig.AllNodes.UserIsolation

        }
    }

    Describe "$($script:DSCResourceName)_Absent" {
        #region DEFAULT TESTS
        It 'Should compile without throwing' {
            {
                Invoke-Expression -Command "$($script:DSCResourceName)_Absent -ConfigurationData `$DSCConfig -OutputPath `$TestEnvironment.WorkingFolder"
                Start-DscConfiguration -Path $TestEnvironment.WorkingFolder -ComputerName localhost -Wait -Verbose -Force
            } | Should not throw
        }

        It 'should be able to call Get-DscConfiguration without throwing' {
            { Get-DscConfiguration -Verbose -ErrorAction Stop } | Should Not throw
        }
        #endregion
        
        It 'Should remove the FTP site' -test {
            
            Invoke-Expression -Command "$($script:DSCResourceName)_Absent -ConfigurationData `$DSCConfg  -OutputPath `$TestEnvironment.WorkingFolder"

            # Build results to test
            $result = Get-Website -Name $DSCConfig.AllNodes.Name
            
            # Test FTP Site is removed
            $result | Should BeNullOrEmpty 
            
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
