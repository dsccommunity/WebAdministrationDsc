$script:DSCModuleName   = 'WebAdministrationDsc'
$script:DSCResourceName = 'MSFT_Website'

#region HEADER
$script:moduleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
if ( (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests'))) -or `
     (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1'))) )
{
    & git @('clone','https://github.com/PowerShell/DscResource.Tests.git',(Join-Path -Path $script:moduleRoot -ChildPath '\DSCResource.Tests\'))
}

Import-Module (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1') -Force
$TestEnvironment = Initialize-TestEnvironment `
    -DSCModuleName $script:DSCModuleName `
    -DSCResourceName $script:DSCResourceName `
    -TestType Integration
#endregion

[String] $tempName = "$($script:DSCResourceName)_" + (Get-Date).ToString('yyyyMMdd_HHmmss')

try
{
    # Now that WebAdministrationDsc should be discoverable, load the configuration data
    $ConfigFile = Join-Path -Path $PSScriptRoot -ChildPath "$($script:DSCResourceName).config.ps1"
    . $ConfigFile

    $null = Backup-WebConfiguration -Name $tempName

    $DSCConfig = Import-LocalizedData -BaseDirectory $PSScriptRoot -FileName "$($script:DSCResourceName).config.psd1"

    # Create a SelfSigned Cert
    $SelfSignedCert = (New-SelfSignedCertificate -DnsName $DSCConfig.AllNodes.HTTPSHostname  -CertStoreLocation 'cert:\LocalMachine\My')
    
    #region HelperFunctions

    # Function needed to test AuthenticationInfo
    function Get-AuthenticationInfo ($Type, $Website) {

        (Get-WebConfigurationProperty `
            -Filter /system.WebServer/security/authentication/${Type}Authentication `
            -Name enabled `
            -Location $Website).Value
    }

    #endregion

    Describe "$($script:DSCResourceName)_Present_Started" {
        #region DEFAULT TESTS
        It 'Should compile without throwing' {
            {
                Invoke-Expression -Command "$($script:DSCResourceName)_Present_Started -ConfigurationData `$DSCConfig -OutputPath `$TestEnvironment.WorkingFolder -CertificateThumbprint `$SelfSignedCert.Thumbprint"
                Start-DscConfiguration -Path $TestEnvironment.WorkingFolder -ComputerName localhost -Wait -Verbose -Force
            } | Should not throw
        }

        It 'should be able to call Get-DscConfiguration without throwing' {
            { Get-DscConfiguration -Verbose -ErrorAction Stop } | Should Not throw
        }
        #endregion

        It 'Should Create a Started Website with correct settings' -test {
            
            Invoke-Expression -Command "$($script:DSCResourceName)_Present_Started -ConfigurationData `$DSCConfg  -OutputPath `$TestEnvironment.WorkingFolder -CertificateThumbprint `$SelfSignedCert.Thumbprint"

            # Build results to test
            $Result = Get-Website -Name $DSCConfig.AllNodes.Website
            
            $DefaultPages = Get-WebConfiguration `
                -Filter '//defaultDocument/files/*' `
                -PSPath 'IIS:\Sites\Website' |
                ForEach-Object -Process {Write-Output -InputObject $_.value}

            $ServiceAutoStartProviders = (Get-WebConfiguration -filter /system.applicationHost/serviceAutoStartProviders).Collection

            # Test Website basic settings are correct
            $Result.Name             | Should Be $DSCConfig.AllNodes.Website
            $Result.PhysicalPath     | Should Be $DSCConfig.AllNodes.PhysicalPath
            $Result.State            | Should Be 'Started'
            $Result.ApplicationPool  | Should Be $DSCConfig.AllNodes.ApplicationPool
            $Result.EnabledProtocols | Should Be $DSCConfig.AllNodes.EnabledProtocols
            
            # Test Website AuthenticationInfo are correct
            Get-AuthenticationInfo -Type 'Anonymous' -Website $DSCConfig.AllNodes.Website | Should Be $DSCConfig.AllNodes.AuthenticationInfoAnonymous
            Get-AuthenticationInfo -Type 'Basic' -Website $DSCConfig.AllNodes.Website     | Should Be $DSCConfig.AllNodes.AuthenticationInfoBasic
            Get-AuthenticationInfo -Type 'Digest' -Website $DSCConfig.AllNodes.Website    | Should Be $DSCConfig.AllNodes.AuthenticationInfoDigest
            Get-AuthenticationInfo -Type 'Windows' -Website $DSCConfig.AllNodes.Website   | Should Be $DSCConfig.AllNodes.AuthenticationInfoWindows
            
            # Test Website Application settings
            $Result.ApplicationDefaults.PreloadEnabled           | Should Be $DSCConfig.AllNodes.PreloadEnabled
            $Result.ApplicationDefaults.ServiceAutoStartProvider | Should Be $DSCConfig.AllNodes.ServiceAutoStartProvider
            $Result.ApplicationDefaults.ServiceAutoStartEnabled  | Should Be $DSCConfig.AllNodes.ServiceAutoStartEnabled
            
            # Test the serviceAutoStartProviders are present in IIS config
            $ServiceAutoStartProviders.Name | Should Be $DSCConfig.AllNodes.ServiceAutoStartProvider
            $ServiceAutoStartProviders.Type | Should Be $DSCConfig.AllNodes.ApplicationType

            # Test bindings are correct
            $Result.bindings.Collection.Protocol                | Should Match $DSCConfig.AllNodes.HTTPProtocol
            $Result.bindings.Collection.BindingInformation[0]   | Should Match $DSCConfig.AllNodes.HTTP1Hostname
            $Result.bindings.Collection.BindingInformation[1]   | Should Match $DSCConfig.AllNodes.HTTP2Hostname
            $Result.bindings.Collection.BindingInformation[2]   | Should Match $DSCConfig.AllNodes.HTTPSHostname
            $Result.bindings.Collection.BindingInformation[0]   | Should Match $DSCConfig.AllNodes.HTTPPort
            $Result.bindings.Collection.BindingInformation[1]   | Should Match $DSCConfig.AllNodes.HTTPPort
            $Result.bindings.Collection.BindingInformation[2]   | Should Match $DSCConfig.AllNodes.HTTPSPort
            $Result.bindings.Collection.certificateHash[2]      | Should Be $SelfSignedCert.Thumbprint
            $Result.bindings.Collection.certificateStoreName[2] | Should Be $DSCConfig.AllNodes.CertificateStoreName
            
            #Test DefaultPage is correct
            $DefaultPages[0] | Should Match $DSCConfig.AllNodes.DefaultPage

            }

    }

    Describe "$($script:DSCResourceName)_Present_Stopped" {
        #region DEFAULT TESTS
        It 'Should compile without throwing' {
            {
                Invoke-Expression -Command "$($script:DSCResourceName)_Present_Stopped -ConfigurationData `$DSCConfig -OutputPath `$TestEnvironment.WorkingFolder -CertificateThumbprint `$SelfSignedCert.Thumbprint"
                Start-DscConfiguration -Path $TestEnvironment.WorkingFolder -ComputerName localhost -Wait -Verbose -Force
            } | Should not throw
        }

        It 'should be able to call Get-DscConfiguration without throwing' {
            { Get-DscConfiguration -Verbose -ErrorAction Stop } | Should Not throw
        }
        #endregion
        
        It 'Should Create a Stopped Website with correct settings' -test {
            
            Invoke-Expression -Command "$($script:DSCResourceName)_Present_Stopped -ConfigurationData `$DSCConfg  -OutputPath `$TestEnvironment.WorkingFolder -CertificateThumbprint `$SelfSignedCert.Thumbprint"

            # Build results to test
            $Result = Get-Website -Name $DSCConfig.AllNodes.Website
            
            $DefaultPages = Get-WebConfiguration `
                -Filter '//defaultDocument/files/*' `
                -PSPath 'IIS:\Sites\Website' |
                ForEach-Object -Process {Write-Output -InputObject $_.value}

            $ServiceAutoStartProviders = (Get-WebConfiguration -filter /system.applicationHost/serviceAutoStartProviders).Collection

            # Test Website basic settings are correct
            $Result.Name             | Should Be $DSCConfig.AllNodes.Website
            $Result.PhysicalPath     | Should Be $DSCConfig.AllNodes.PhysicalPath
            $Result.State            | Should Be 'Stopped'
            $Result.ApplicationPool  | Should Be $DSCConfig.AllNodes.ApplicationPool
            $Result.EnabledProtocols | Should Be $DSCConfig.AllNodes.EnabledProtocols
            
            # Test Website AuthenticationInfo are correct
            Get-AuthenticationInfo -Type 'Anonymous' -Website $DSCConfig.AllNodes.Website | Should Be $DSCConfig.AllNodes.AuthenticationInfoAnonymous
            Get-AuthenticationInfo -Type 'Basic' -Website $DSCConfig.AllNodes.Website     | Should Be $DSCConfig.AllNodes.AuthenticationInfoBasic
            Get-AuthenticationInfo -Type 'Digest' -Website $DSCConfig.AllNodes.Website    | Should Be $DSCConfig.AllNodes.AuthenticationInfoDigest
            Get-AuthenticationInfo -Type 'Windows' -Website $DSCConfig.AllNodes.Website   | Should Be $DSCConfig.AllNodes.AuthenticationInfoWindows
            
            # Test Website Application settings
            $Result.ApplicationDefaults.PreloadEnabled           | Should Be $DSCConfig.AllNodes.PreloadEnabled
            $Result.ApplicationDefaults.ServiceAutoStartProvider | Should Be $DSCConfig.AllNodes.ServiceAutoStartProvider
            $Result.ApplicationDefaults.ServiceAutoStartEnabled  | Should Be $DSCConfig.AllNodes.ServiceAutoStartEnabled

            # Test the serviceAutoStartProviders are present in IIS config
            $ServiceAutoStartProviders.Name | Should Be $DSCConfig.AllNodes.ServiceAutoStartProvider
            $ServiceAutoStartProviders.Type | Should Be $DSCConfig.AllNodes.ApplicationType

            # Test bindings are correct
            $Result.bindings.Collection.Protocol                | Should Match $DSCConfig.AllNodes.HTTPProtocol
            $Result.bindings.Collection.BindingInformation[0]   | Should Match $DSCConfig.AllNodes.HTTP1Hostname
            $Result.bindings.Collection.BindingInformation[1]   | Should Match $DSCConfig.AllNodes.HTTP2Hostname
            $Result.bindings.Collection.BindingInformation[2]   | Should Match $DSCConfig.AllNodes.HTTPSHostname
            $Result.bindings.Collection.BindingInformation[0]   | Should Match $DSCConfig.AllNodes.HTTPPort
            $Result.bindings.Collection.BindingInformation[1]   | Should Match $DSCConfig.AllNodes.HTTPPort
            $Result.bindings.Collection.BindingInformation[2]   | Should Match $DSCConfig.AllNodes.HTTPSPort
            $Result.bindings.Collection.certificateHash[2]      | Should Be $SelfSignedCert.Thumbprint
            $Result.bindings.Collection.certificateStoreName[2] | Should Be $DSCConfig.AllNodes.CertificateStoreName
            
            #Test DefaultPage is correct
            $DefaultPages[0] | Should Match $DSCConfig.AllNodes.DefaultPage

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
        
        It 'Should remove the Website' -test {
            
            Invoke-Expression -Command "$($script:DSCResourceName)_Absent -ConfigurationData `$DSCConfg  -OutputPath `$TestEnvironment.WorkingFolder"

            # Build results to test
            $Result = Get-Website -Name $DSCConfig.AllNodes.Website
            
            # Test Website is removed
            $Result | Should BeNullOrEmpty 
            
            }

    }

    Describe 'MSFT_WebBindingInformation' {
        # Directly interacting with Cim classes is not supported by PowerShell DSC
        # it is being done here explicitly for the purpose of testing. Please do not
        # do this in actual resource code
        
        #TODO: Delete or Uncomment - Is this needed? PSScriptAnalyzer says it's never used.
        #$WebBindingInforationClass = (Get-CimClass -Namespace 'root/microsoft/Windows/DesiredStateConfiguration' -ClassName 'MSFT_WebBindingInformation')
        $storeNames = (Get-CimClass -Namespace 'root/microsoft/Windows/DesiredStateConfiguration' -ClassName 'MSFT_WebBindingInformation').CimClassProperties['CertificateStoreName'].Qualifiers['Values'].Value

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
    #region FOOTER
    Restore-WebConfiguration -Name $tempName
    Remove-WebConfigurationBackup -Name $tempName

    Restore-TestEnvironment -TestEnvironment $TestEnvironment
    #endregion
}
