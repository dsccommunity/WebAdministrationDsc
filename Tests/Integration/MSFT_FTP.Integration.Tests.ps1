$script:DSCModuleName   = 'xWebAdministration'
$script:DSCResourceName = 'MSFT_FTP'

#region HEADER
[String] $moduleRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $Script:MyInvocation.MyCommand.Path))
if ( (-not (Test-Path -Path (Join-Path -Path $moduleRoot -ChildPath 'DSCResource.Tests'))) -or `
     (-not (Test-Path -Path (Join-Path -Path $moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1'))) )
{
    & git @('clone','https://github.com/PowerShell/DscResource.Tests.git',(Join-Path -Path $moduleRoot -ChildPath '\DSCResource.Tests\'))
}

Import-Module (Join-Path -Path $moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1') -Force
$TestEnvironment = Initialize-TestEnvironment -DSCModuleName $script:DSCModuleName `
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
    $SelfSignedCert = (New-SelfSignedCertificate -DnsName $DSCConfig.AllNodes.BindingInfoHostName -CertStoreLocation 'cert:\LocalMachine\My')

    # Create a folder if it's absent
    if (-not [bool]([System.Uri]$DSCConfig.AllNodes.PhysicalPath).IsUnc -and `
        -not(Test-Path -Path $DSCConfig.AllNodes.PhysicalPath))
    {
        New-Item -Path $DSCConfig.AllNodes.PhysicalPath -ItemType Directory -Force | Out-Null
    }

    # Create a test user if it's absent
    $mockUser = Get-LocalUser -Name $DSCConfig.AllNodes.PhysicalPathAccessUserName -ErrorAction SilentlyContinue
    if (-not $mockUser)
    {
        $mockUser = New-LocalUser `
                        -Name $DSCConfig.AllNodes.PhysicalPathAccessUserName `
                        -Password (ConvertTo-SecureString -String $DSCConfig.AllNodes.PhysicalPathAccessPassword -AsPlainText -Force) `
                        -AccountNeverExpires:$true `
                        -UserMayNotChangePassword:$true
    }

    #region HelperFunctions

    # Function needed to test AuthenticationInfo
    Function Get-AuthenticationInfo ($Type, $Website)
    {
        (Get-ItemProperty "IIS:\Sites\$Website" -Name ftpServer.security.authentication."${Type}Authentication".enabled).Value
    }

    function Get-AuthorizationInfo ($Website)
    {
        (Get-WebConfiguration -Filter '/system.ftpServer/security/authorization' -Location $Website).Collection
    }

    function Get-SslInfo ($Type, $Website)
    {
        $correctType = switch($Type)
        {
            CertificateThumbprint { 'serverCertHash' }
            CertificateStoreName  { 'serverCertStoreName' }
            RequireSsl128         { 'ssl128' }
            ControlChannelPolicy  { 'controlChannelPolicy' }
            DataChannelPolicy     { 'dataChannelPolicy' }
        }
        (Get-Item -Path IIS:\Sites\${Website}\).ftpServer.security.ssl.${correctType}
    }

    function Get-DataChannelPorts
    {
        Get-WebConfiguration -Filter '/system.ftpServer/firewallSupport'
    }
    #endregion

    Describe "$($script:DSCResourceName)_Present" {
        #region DEFAULT TESTS
        It 'Should compile without throwing' {
            {
                Invoke-Expression -Command "$($script:DSCResourceName)_Present -ConfigurationData `$DSCConfig -OutputPath `$TestDrive -CertificateThumbprint `$SelfSignedCert.Thumbprint"
                Start-DscConfiguration -Path $TestDrive -ComputerName localhost -Wait -Verbose -Force
            } | Should not throw
        }

        It 'should be able to call Get-DscConfiguration without throwing' {
            { Get-DscConfiguration -Verbose -ErrorAction Stop } | Should Not throw
        }

        It 'should return True when calling Test-DscConfiguration' {
            $result = Test-DscConfiguration

            $result | Should -Be $true
        }
        #endregion

        It 'Should Create a Started FTP site with correct settings' -test {
            Invoke-Expression -Command "$($script:DSCResourceName)_Present -ConfigurationData `$DSCConfg  -OutputPath `$TestDrive -CertificateThumbprint `$SelfSignedCert.Thumbprint"

            # Build results to test
            $result = Get-Website -Name $DSCConfig.AllNodes.Name

            # Test basic settings are correct
            $result.Name             | Should -Be $DSCConfig.AllNodes.Name
            $result.PhysicalPath     | Should -Be $DSCConfig.AllNodes.PhysicalPath
            $result.userName         | Should -be $DSCConfig.AllNodes.PhysicalPathAccessUserName
            $result.password         | Should -be $DSCConfig.AllNodes.PhysicalPathAccessPassword
            $result.State            | Should -Be 'Started'
            $result.ApplicationPool  | Should -Be $DSCConfig.AllNodes.ApplicationPool

            # Test that AuthenticationInfo is correct
            Get-AuthenticationInfo -Type 'Anonymous' -Website $DSCConfig.AllNodes.Name | Should -Be $DSCConfig.AllNodes.AuthenticationInfoAnonymous
            Get-AuthenticationInfo -Type 'Basic' -Website $DSCConfig.AllNodes.Name     | Should -Be $DSCConfig.AllNodes.AuthenticationInfoBasic

            # Test bindings are correct
            $result.bindings.Collection.Protocol           | Should -Be $DSCConfig.AllNodes.BindingInfoProtocol
            $result.bindings.Collection.BindingInformation | Should Match $DSCConfig.AllNodes.BindingInfoPort
            $result.bindings.Collection.BindingInformation | Should Match $DSCConfig.AllNodes.BindingInfoHostName

            # Test that AuthorizationInfo is correct
            $Authorization = Get-AuthorizationInfo -Website $DSCConfig.AllNodes.Name

            $Authorization[0].accessType  | Should -Be $DSCConfig.AllNodes.AuthorizationInfoAccessType1
            $Authorization[0].users       | Should -Be $DSCConfig.AllNodes.AuthorizationInfoUsers1
            $Authorization[0].roles       | Should BeNullOrEmpty
            $Authorization[0].permissions | Should -Be $DSCConfig.AllNodes.AuthorizationInfoPermissions1

            $Authorization[1].accessType  | Should -Be $DSCConfig.AllNodes.AuthorizationInfoAccessType1
            $Authorization[1].users       | Should -Be $DSCConfig.AllNodes.AuthorizationInfoUsers2
            $Authorization[1].roles       | Should BeNullOrEmpty
            $Authorization[1].permissions | Should -Be $DSCConfig.AllNodes.AuthorizationInfoPermissions3

            $Authorization[2].accessType  | Should -Be $DSCConfig.AllNodes.AuthorizationInfoAccessType2
            $Authorization[2].users       | Should -Be $DSCConfig.AllNodes.AuthorizationInfoUsers3
            $Authorization[2].roles       | Should BeNullOrEmpty
            $Authorization[2].permissions | Should -Be $DSCConfig.AllNodes.AuthorizationInfoPermissions1

            $Authorization[3].accessType  | Should -Be $DSCConfig.AllNodes.AuthorizationInfoAccessType1
            $Authorization[3].users       | Should BeNullOrEmpty
            $Authorization[3].roles       | Should -Be $DSCConfig.AllNodes.AuthorizationInfoRoles
            $Authorization[3].permissions | Should -Be $DSCConfig.AllNodes.AuthorizationInfoPermissions1

            $Authorization[4].accessType  | Should -Be $DSCConfig.AllNodes.AuthorizationInfoAccessType2
            $Authorization[4].users       | Should BeNullOrEmpty
            $Authorization[4].roles       | Should -Be $DSCConfig.AllNodes.AuthorizationInfoRoles
            $Authorization[4].permissions | Should -Be $DSCConfig.AllNodes.AuthorizationInfoPermissions2

            # Test SslInfo
            Get-SslInfo -Type ControlChannelPolicy -Website $DSCConfig.AllNodes.Name  | Should -Be $DSCConfig.AllNodes.SslInfoControlChannelPolicy
            Get-SslInfo -Type DataChannelPolicy -Website $DSCConfig.AllNodes.Name     | Should -Be $DSCConfig.AllNodes.SslInfoDataChannelPolicy
            Get-SslInfo -Type RequireSsl128 -Website $DSCConfig.AllNodes.Name         | Should -Be $DSCConfig.AllNodes.SslInfoRequireSsl128
            Get-SslInfo -Type CertificateThumbprint -Website $DSCConfig.AllNodes.Name | Should -Be $SelfSignedCert.Thumbprint
            Get-SslInfo -Type CertificateStoreName -Website $DSCConfig.AllNodes.Name  | Should -Be $DSCConfig.AllNodes.SslInfoCertificateStoreName

            # Test firewall support settings
            $result.ftpServer.firewallSupport.externalIp4Address | Should -Be $DSCConfig.AllNodes.FirewallIPaddress
            (Get-DataChannelPorts).lowDataChannelPort            | Should -Be $DSCConfig.AllNodes.StartingDataChannelPort
            (Get-DataChannelPorts).highDataChannelPort           | Should -Be $DSCConfig.AllNodes.EndingDataChannelPort

            # Test messages section
            $result.ftpServer.messages.greetingMessage          | Should -Be $DSCConfig.AllNodes.GreetingMessage
            $result.ftpServer.messages.exitMessage              | Should -Be $DSCConfig.AllNodes.ExitMessage
            $result.ftpServer.messages.bannerMessage            | Should -Be $DSCConfig.AllNodes.BannerMessage
            $result.ftpServer.messages.maxClientsMessage        | Should -Be $DSCConfig.AllNodes.MaxClientsMessage
            $result.ftpServer.messages.suppressDefaultBanner    | Should -Be $DSCConfig.AllNodes.SuppressDefaultBanner
            $result.ftpServer.messages.allowLocalDetailedErrors | Should -Be $DSCConfig.AllNodes.AllowLocalDetailedErrors
            $result.ftpServer.messages.expandVariables          | Should -Be $DSCConfig.AllNodes.ExpandVariablesInMessages

            # Test Log Settings
            $result.ftpServer.logFile.logExtFileFlags.Split(',') | Should -BeIn $DSCConfig.AllNodes.LogFlags
            $result.ftpServer.logFile.directory                  | Should -Be $DSCConfig.AllNodes.LogPath
            $result.ftpServer.logFile.period                     | Should -Be $DSCConfig.AllNodes.LogPeriod
            $result.ftpServer.logFile.localTimeRollover          | Should -Be $DSCConfig.AllNodes.LoglocalTimeRollover

            # Test DirectoryBrowseFlags
            $result.ftpServer.directoryBrowse.showFlags.Split(',') | Should -BeIn $DSCConfig.AllNodes.DirectoryBrowseFlags

            # Test UserIsolation
            $result.ftpServer.userIsolation.mode | Should -Be $DSCConfig.AllNodes.UserIsolation
        }
    }

    Describe "$($script:DSCResourceName)_Absent" {
        #region DEFAULT TESTS
        It 'Should compile without throwing' {
            {
                Invoke-Expression -Command "$($script:DSCResourceName)_Absent -ConfigurationData `$DSCConfig -OutputPath `$TestDrive"
                Start-DscConfiguration -Path $TestDrive -ComputerName localhost -Wait -Verbose -Force
            } | Should not throw
        }

        It 'should be able to call Get-DscConfiguration without throwing' {
            { Get-DscConfiguration -Verbose -ErrorAction Stop } | Should Not throw
        }

        It 'should return True when calling Test-DscConfiguration' {
            $result = Test-DscConfiguration

            $result | Should -Be $true
        }
        #endregion

        It 'Should remove the FTP site' -test {
            Invoke-Expression -Command "$($script:DSCResourceName)_Absent -ConfigurationData `$DSCConfg  -OutputPath `$TestDrive"

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
    Remove-LocalUser -InputObject $mockUser
    Restore-TestEnvironment -TestEnvironment $TestEnvironment
    #endregion
}
