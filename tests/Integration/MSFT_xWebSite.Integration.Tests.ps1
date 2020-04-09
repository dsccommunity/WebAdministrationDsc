$script:dscModuleName   = 'xWebAdministration'
$script:dscResourceName = 'MSFT_xWebSite'

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
    -TestType 'Integration'

Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\TestHelper\CommonTestHelper.psm1') -Force

$tempName = "$($script:dscResourceName)_" + (Get-Date).ToString('yyyyMMdd_HHmmss')

try
{
    # Now that xWebAdministration should be discoverable, load the configuration data
    $configFile = Join-Path -Path $PSScriptRoot -ChildPath "$($script:dscResourceName).config.ps1"
    . $configFile

    $null = Backup-WebConfiguration -Name $tempName

    $dscConfig = Import-LocalizedData -BaseDirectory $PSScriptRoot -FileName "$($script:dscResourceName).config.psd1"

    # Create a SelfSigned Cert
    $selfSignedCert = (New-SelfSignedCertificate -DnsName $dscConfig.AllNodes.HTTPSHostname `
        -CertStoreLocation 'cert:\LocalMachine\My')

    #region HelperFunctions

    # Function needed to test AuthenticationInfo
    function Get-AuthenticationInfo
    {
        [CmdletBinding()]
        param
        (
            [Parameter(Mandatory = $true)]
            [String] $Type,

            [Parameter(Mandatory = $true)]
            [String] $Website
        )

        (Get-WebConfigurationProperty `
            -Filter /system.WebServer/security/authentication/${Type}Authentication `
            -Name enabled `
            -Location $Website).Value
    }

    #endregion

    Describe "$($script:dscResourceName)_Webconfig_Get_Test_Set" {
        #region DEFAULT TESTS
        It 'Should compile without throwing' {
            {
                Invoke-Expression -Command "$($script:dscResourceName)_Webconfig_Get_Test_Set -ConfigurationData `$dscConfig -OutputPath `$TestDrive -CertificateThumbprint `$selfSignedCert.Thumbprint"
                Start-DscConfiguration -Path $TestDrive -ComputerName localhost -Wait -Verbose -Force
            } | Should not throw
        }

        It 'Should be able to call Get-DscConfiguration without throwing' {
            { Get-DscConfiguration -Verbose -ErrorAction Stop } | Should Not throw
        }
        #endregion

        It 'Should be able to call Test-DscConfiguration without throwing' {
            { Test-DscConfiguration -Verbose -ErrorAction Stop } | Should Not throw
        }
    }

    Describe "$($script:dscResourceName)_Present_Started" {
        #region DEFAULT TESTS
        It 'Should compile without throwing' {
            {
                Invoke-Expression -Command "$($script:dscResourceName)_Present_Started -ConfigurationData `$dscConfig -OutputPath `$TestDrive -CertificateThumbprint `$selfSignedCert.Thumbprint"
                Start-DscConfiguration -Path $TestDrive -ComputerName localhost -Wait -Verbose -Force
            } | Should not throw
        }

        It 'Should be able to call Get-DscConfiguration without throwing' {
            { Get-DscConfiguration -Verbose -ErrorAction Stop } | Should Not throw
        }
        #endregion

        It 'Should Create a Started Website with correct settings' -test {

            Invoke-Expression -Command "$($script:dscResourceName)_Present_Started -ConfigurationData `$dscConfig -OutputPath `$TestDrive -CertificateThumbprint `$selfSignedCert.Thumbprint"

            # Build results to test
            $result = Get-Website -Name $dscConfig.AllNodes.Website

            $defultPages = Get-WebConfiguration `
                -Filter '/system.webServer/defaultDocument/files/*' `
                -PSPath 'IIS:\Sites\Website' |
                ForEach-Object -Process {Write-Output -InputObject $_.value}

            $serviceAutoStartProviders = (Get-WebConfiguration -filter /system.applicationHost/serviceAutoStartProviders).Collection

            # Test Website basic settings are correct
            $result.Name             | Should Be $dscConfig.AllNodes.Website
            $result.Id               | Should Be $dscConfig.AllNodes.SiteId
            $result.PhysicalPath     | Should Be $dscConfig.AllNodes.PhysicalPath
            $result.State            | Should Be 'Started'
            $result.ServerAutoStart  | Should Be $true
            $result.ApplicationPool  | Should Be $dscConfig.AllNodes.ApplicationPool
            $result.EnabledProtocols | Should Be $dscConfig.AllNodes.EnabledProtocols

            # Test Website AuthenticationInfo are correct
            Get-AuthenticationInfo -Type 'Anonymous' -Website $dscConfig.AllNodes.Website | Should Be $dscConfig.AllNodes.AuthenticationInfoAnonymous
            Get-AuthenticationInfo -Type 'Basic' -Website $dscConfig.AllNodes.Website     | Should Be $dscConfig.AllNodes.AuthenticationInfoBasic
            Get-AuthenticationInfo -Type 'Digest' -Website $dscConfig.AllNodes.Website    | Should Be $dscConfig.AllNodes.AuthenticationInfoDigest
            Get-AuthenticationInfo -Type 'Windows' -Website $dscConfig.AllNodes.Website   | Should Be $dscConfig.AllNodes.AuthenticationInfoWindows

            # Test Website Application settings
            $result.ApplicationDefaults.PreloadEnabled           | Should Be $dscConfig.AllNodes.PreloadEnabled
            $result.ApplicationDefaults.ServiceAutoStartProvider | Should Be $dscConfig.AllNodes.ServiceAutoStartProvider
            $result.ApplicationDefaults.ServiceAutoStartEnabled  | Should Be $dscConfig.AllNodes.ServiceAutoStartEnabled

            # Test the serviceAutoStartProviders are present in IIS config
            $serviceAutoStartProviders.Name | Should Be $dscConfig.AllNodes.ServiceAutoStartProvider
            $serviceAutoStartProviders.Type | Should Be $dscConfig.AllNodes.ApplicationType

            # Test bindings are correct
            $result.bindings.Collection.Protocol                | Should Match $dscConfig.AllNodes.HTTPProtocol
            $result.bindings.Collection.BindingInformation[0]   | Should Match $dscConfig.AllNodes.HTTP1Hostname
            $result.bindings.Collection.BindingInformation[1]   | Should Match $dscConfig.AllNodes.HTTP2Hostname
            $result.bindings.Collection.BindingInformation[2]   | Should Match $dscConfig.AllNodes.HTTPSHostname
            $result.bindings.Collection.BindingInformation[3]   | Should Match $dscConfig.AllNodes.HTTPSHostname
            $result.bindings.Collection.BindingInformation[0]   | Should Match $dscConfig.AllNodes.HTTPPort
            $result.bindings.Collection.BindingInformation[1]   | Should Match $dscConfig.AllNodes.HTTPPort
            $result.bindings.Collection.BindingInformation[2]   | Should Match $dscConfig.AllNodes.HTTPSPort
            $result.bindings.Collection.certificateHash[2]      | Should Be $selfSignedCert.Thumbprint
            $result.bindings.Collection.certificateStoreName[2] | Should Be $dscConfig.AllNodes.CertificateStoreName
            $result.bindings.Collection.BindingInformation[3]   | Should Match $dscConfig.AllNodes.HTTPSPort2
            $result.bindings.Collection.certificateHash[3]      | Should Be $selfSignedCert.Thumbprint
            $result.bindings.Collection.certificateStoreName[3] | Should Be $dscConfig.AllNodes.CertificateStoreName

            #Test DefaultPage is correct
            $defultPages[0] | Should Match $dscConfig.AllNodes.DefaultPage

            #Test LogTargetW3C is correct
            $result.logFile.LogTargetW3C | Should Be $dscConfig.AllNodes.LogTargetW3C

            #Test LogCustomFields is correct
            $result.logFile.customFields.Collection[0].LogFieldName | Should Be $dscConfig.AllNodes.LogFieldName1
            $result.logFile.customFields.Collection[0].SourceName   | Should Be $dscConfig.AllNodes.SourceName1
            $result.logFile.customFields.Collection[0].SourceType   | Should Be $dscConfig.AllNodes.SourceType1
            $result.logFile.customFields.Collection[1].LogFieldName | Should Be $dscConfig.AllNodes.LogFieldName2
            $result.logFile.customFields.Collection[1].SourceName   | Should Be $dscConfig.AllNodes.SourceName2
            $result.logFile.customFields.Collection[1].SourceType   | Should Be $dscConfig.AllNodes.SourceType2

            #Test LogFlags is correct
            $result.logFile.LogExtFileFlags | Should Be 'Date,Time,ClientIP,UserName,ServerIP'
            $result.logFile.LogFormat       | Should Be $dscConfig.AllNodes.LogFormat
        }

    }

    Describe "$($script:dscResourceName)_Logging_Configured" {
        #region DEFAULT TESTS
        It 'Should compile without throwing' {
            {
                Invoke-Expression -Command "$($script:dscResourceName)_Logging_Configured -ConfigurationData `$dscConfig -OutputPath `$TestDrive -CertificateThumbprint `$selfSignedCert.Thumbprint"
                Start-DscConfiguration -Path $TestDrive -ComputerName localhost -Wait -Verbose -Force
            } | Should not throw
        }

        It 'Should be able to call Get-DscConfiguration without throwing' {
            { Get-DscConfiguration -Verbose -ErrorAction Stop } | Should Not throw
        }
        #endregion

        It 'Should update the enabled LogFlags' -test {

            Invoke-Expression -Command "$($script:dscResourceName)_Logging_Configured -ConfigurationData `$dscConfig -OutputPath `$TestDrive -CertificateThumbprint `$selfSignedCert.Thumbprint"

            # Build results to test
            $result = Get-Website -Name $dscConfig.AllNodes.Website

            # Test Website has updated LogFlags
            $result.logFile.LogExtFileFlags | Should Be 'Date,Time,ClientIP,ServerIP,UserAgent'
            $result.logFile.LogFormat       | Should Be $dscConfig.AllNodes.LogFormat
        }
    }

    Describe "$($script:dscResourceName)_Custom_Logging_Configured" {
        #region DEFAULT TESTS
        It 'Should compile without throwing' {
            {
                Invoke-Expression -Command "$($script:dscResourceName)_Custom_Logging_Configured -ConfigurationData `$dscConfig -OutputPath `$TestDrive -CertificateThumbprint `$selfSignedCert.Thumbprint"
                Start-DscConfiguration -Path $TestDrive -ComputerName localhost -Wait -Verbose -Force
            } | Should not throw
        }

        It 'Should be able to call Get-DscConfiguration without throwing' {
            { Get-DscConfiguration -Verbose -ErrorAction Stop } | Should Not throw
        }
        #endregion

        It 'Should remove all custom log fields' -test {

            Invoke-Expression -Command "$($script:dscResourceName)_Custom_Logging_Configured -ConfigurationData `$dscConfig -OutputPath `$TestDrive -CertificateThumbprint `$selfSignedCert.Thumbprint"

            # Build results to test
            $result = Get-Website -Name $dscConfig.AllNodes.Website

            # Test Website has updated CustomLogFields
            $result.logFile.LogCustomFields | Should -BeNullOrEmpty
        }
    }

    Describe "$($script:dscResourceName)_Present_Stopped" {
        #region DEFAULT TESTS
        It 'Should compile without throwing' {
            {
                Invoke-Expression -Command "$($script:dscResourceName)_Present_Stopped -ConfigurationData `$dscConfig -OutputPath `$TestDrive -CertificateThumbprint `$selfSignedCert.Thumbprint"
                Start-DscConfiguration -Path $TestDrive -ComputerName localhost -Wait -Verbose -Force
            } | Should not throw
        }

        It 'Should be able to call Get-DscConfiguration without throwing' {
            { Get-DscConfiguration -Verbose -ErrorAction Stop } | Should Not throw
        }
        #endregion

        It 'Should Create a Stopped Website with correct settings' -test {

            Invoke-Expression -Command "$($script:dscResourceName)_Present_Stopped -ConfigurationData `$dscConfig -OutputPath `$TestDrive -CertificateThumbprint `$selfSignedCert.Thumbprint"

            # Build results to test
            $result = Get-Website -Name $dscConfig.AllNodes.Website

            $defultPages = Get-WebConfiguration `
                -Filter '/system.webServer/defaultDocument/files/*' `
                -PSPath 'IIS:\Sites\Website' |
                ForEach-Object -Process {Write-Output -InputObject $_.value}

            $serviceAutoStartProviders = (Get-WebConfiguration -filter /system.applicationHost/serviceAutoStartProviders).Collection

            # Test Website basic settings are correct
            $result.Name             | Should Be $dscConfig.AllNodes.Website
            $result.PhysicalPath     | Should Be $dscConfig.AllNodes.PhysicalPath
            $result.Id               | Should Be $dscConfig.AllNodes.SiteId
            $result.State            | Should Be 'Stopped'
            $result.ServerAutoStart  | Should Be $false
            $result.ApplicationPool  | Should Be $dscConfig.AllNodes.ApplicationPool
            $result.EnabledProtocols | Should Be $dscConfig.AllNodes.EnabledProtocols

            # Test Website AuthenticationInfo are correct
            Get-AuthenticationInfo -Type 'Anonymous' -Website $dscConfig.AllNodes.Website | Should Be $dscConfig.AllNodes.AuthenticationInfoAnonymous
            Get-AuthenticationInfo -Type 'Basic' -Website $dscConfig.AllNodes.Website     | Should Be $dscConfig.AllNodes.AuthenticationInfoBasic
            Get-AuthenticationInfo -Type 'Digest' -Website $dscConfig.AllNodes.Website    | Should Be $dscConfig.AllNodes.AuthenticationInfoDigest
            Get-AuthenticationInfo -Type 'Windows' -Website $dscConfig.AllNodes.Website   | Should Be $dscConfig.AllNodes.AuthenticationInfoWindows

            # Test Website Application settings
            $result.ApplicationDefaults.PreloadEnabled           | Should Be $dscConfig.AllNodes.PreloadEnabled
            $result.ApplicationDefaults.ServiceAutoStartProvider | Should Be $dscConfig.AllNodes.ServiceAutoStartProvider
            $result.ApplicationDefaults.ServiceAutoStartEnabled  | Should Be $dscConfig.AllNodes.ServiceAutoStartEnabled

            # Test the serviceAutoStartProviders are present in IIS config
            $serviceAutoStartProviders.Name | Should Be $dscConfig.AllNodes.ServiceAutoStartProvider
            $serviceAutoStartProviders.Type | Should Be $dscConfig.AllNodes.ApplicationType

            # Test bindings are correct
            $result.bindings.Collection.Protocol                | Should Match $dscConfig.AllNodes.HTTPProtocol
            $result.bindings.Collection.BindingInformation[0]   | Should Match $dscConfig.AllNodes.HTTP1Hostname
            $result.bindings.Collection.BindingInformation[1]   | Should Match $dscConfig.AllNodes.HTTP2Hostname
            $result.bindings.Collection.BindingInformation[2]   | Should Match $dscConfig.AllNodes.HTTPSHostname
            $result.bindings.Collection.BindingInformation[3]   | Should Match $dscConfig.AllNodes.HTTPSHostname
            $result.bindings.Collection.BindingInformation[0]   | Should Match $dscConfig.AllNodes.HTTPPort
            $result.bindings.Collection.BindingInformation[1]   | Should Match $dscConfig.AllNodes.HTTPPort
            $result.bindings.Collection.BindingInformation[2]   | Should Match $dscConfig.AllNodes.HTTPSPort
            $result.bindings.Collection.certificateHash[2]      | Should Be $selfSignedCert.Thumbprint
            $result.bindings.Collection.certificateStoreName[2] | Should Be $dscConfig.AllNodes.CertificateStoreName
            $result.bindings.Collection.BindingInformation[3]   | Should Match $dscConfig.AllNodes.HTTPSPort2
            $result.bindings.Collection.certificateHash[3]      | Should Be $selfSignedCert.Thumbprint
            $result.bindings.Collection.certificateStoreName[3] | Should Be $dscConfig.AllNodes.CertificateStoreName

            #Test DefaultPage is correct
            $defultPages[0] | Should Match $dscConfig.AllNodes.DefaultPage

            #Test LogCustomFields is correct
            $result.logFile.customFields.Collection[0].LogFieldName | Should Be $dscConfig.AllNodes.LogFieldName1
            $result.logFile.customFields.Collection[0].SourceName   | Should Be $dscConfig.AllNodes.SourceName1
            $result.logFile.customFields.Collection[0].SourceType   | Should Be $dscConfig.AllNodes.SourceType1
            $result.logFile.customFields.Collection[1].LogFieldName | Should Be $dscConfig.AllNodes.LogFieldName2
            $result.logFile.customFields.Collection[1].SourceName   | Should Be $dscConfig.AllNodes.SourceName2
            $result.logFile.customFields.Collection[1].SourceType   | Should Be $dscConfig.AllNodes.SourceType2
        }

    }

    Describe "$($script:dscResourceName)_Absent" {
        #region DEFAULT TESTS
        It 'Should compile without throwing' {
            {
                Invoke-Expression -Command "$($script:dscResourceName)_Absent -ConfigurationData `$dscConfig -OutputPath `$TestDrive"
                Start-DscConfiguration -Path $TestDrive -ComputerName localhost -Wait -Verbose -Force
            } | Should not throw
        }

        It 'Should be able to call Get-DscConfiguration without throwing' {
            { Get-DscConfiguration -Verbose -ErrorAction Stop } | Should Not throw
        }
        #endregion

        It 'Should remove the Website' -test {

            Invoke-Expression -Command "$($script:dscResourceName)_Absent -ConfigurationData `$dscConfig  -OutputPath `$TestDrive"

            # Build results to test
            $result = Get-Website -Name $dscConfig.AllNodes.Website

            # Test Website is removed
            $result | Should BeNullOrEmpty

            }

    }

    Describe 'MSFT_xWebBindingInformation' {
        # Directly interacting with Cim classes is not supported by PowerShell DSC
        # it is being done here explicitly for the purpose of testing. Please do not
        # do this in actual resource code

        $storeNames = (Get-CimClass -Namespace 'root/microsoft/Windows/DesiredStateConfiguration' -ClassName 'MSFT_xWebBindingInformation').CimClassProperties['CertificateStoreName'].Qualifiers['Values'].Value

        foreach ($storeName in $storeNames)
        {
            It "Uses valid credential store: $storeName" {
                (Join-Path -Path Cert:\LocalMachine -ChildPath $storeName) | Should Exist
            }
        }
    }
}
finally
{
    Restore-WebConfigurationWrapper -Name $tempName -Verbose

    Remove-WebConfigurationBackup -Name $tempName -Verbose

    Remove-Item -PSPath $selfSignedCert.PSPath

    $webConfigPath = Join-Path -Path $dscConfig.AllNodes.PhysicalPath -ChildPath 'web.config'
    if (Test-Path -Path $webConfigPath -PathType Leaf)
    {
        Remove-Item -Path $webConfigPath
    }

    Restore-TestEnvironment -TestEnvironment $script:testEnvironment -Verbose
}
