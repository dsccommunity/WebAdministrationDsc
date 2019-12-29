$script:dscModuleName   = 'xWebAdministration'
$script:dscResourceName = 'MSFT_xWebApplication'

try
{
    Import-Module -Name DscResource.Test -Force
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
    $null = Backup-WebConfiguration -Name $tempName

    # Now that xWebAdministration should be discoverable load the configuration data
    $ConfigFile = Join-Path -Path $PSScriptRoot -ChildPath "$($script:dscResourceName).config.ps1"
    . $ConfigFile

    $DSCConfig = Import-LocalizedData -BaseDirectory $PSScriptRoot -FileName "$($script:dscResourceName).config.psd1"

    #region HelperFunctions

    # Function needed to test AuthenticationInfo
    function Get-AuthenticationInfo ($Type, $Website, $WebApplication)
    {
        (Get-WebConfigurationProperty `
            -Filter /system.WebServer/security/authentication/${Type}Authentication `
            -Name enabled `
            -Location "${Website}/${WebApplication}").Value
    }

    # Function needed to test SslFlags
    function Get-SslFlags ($Website, $WebApplication)
    {
        Get-WebConfiguration `
                -PSPath IIS:\Sites `
                -Location "${Website}/${WebApplication}" `
                -Filter 'system.webserver/security/access' | `
                 ForEach-Object { $_.sslFlags }
    }

    #endregion

    # Create a new website for the WebApplication

    New-Website -Name $DSCConfig.AllNodes.Website `
        -Id 100 `
        -PhysicalPath $DSCConfig.AllNodes.PhysicalPath `
        -ApplicationPool $DSCConfig.AllNodes.AppPool `
        -SslFlags $DSCConfig.AllNodes.SslFlags `
        -Port $DSCConfig.AllNodes.HTTPSPort `
        -IPAddress '*' `
        -HostHeader $DSCConfig.AllNodes.HTTPSHostname `
        -Ssl `
        -Force `
        -ErrorAction Stop

    Describe "$($script:dscResourceName)_Present" {
        #region DEFAULT TESTS
        It 'Should compile without throwing' {
            {
                Invoke-Expression -Command "$($script:dscResourceName)_Present -ConfigurationData `$DSCConfig -OutputPath `$TestDrive"
                Start-DscConfiguration -Path $TestDrive -ComputerName localhost -Wait -Verbose -Force
            } | Should not throw
        }

        It 'should be able to call Get-DscConfiguration without throwing' {
            { Get-DscConfiguration -Verbose -ErrorAction Stop } | Should Not throw
        }
        #endregion

        It 'Should create a WebApplication with correct settings' -test {

            Invoke-Expression -Command "$($script:dscResourceName)_Present -ConfigurationData `$DSCConfg -OutputPath `$TestDrive"

            # Build results to test
            $Result = Get-WebApplication -Site $DSCConfig.AllNodes.Website -Name $DSCConfig.AllNodes.WebApplication
            $ServiceAutoStartProviders = (Get-WebConfiguration -filter /system.applicationHost/serviceAutoStartProviders).Collection

            # Test WebApplication basic settings are correct
            $Result.Path            | Should Match $DSCConfig.AllNodes.WebApplication
            $Result.PhysicalPath    | Should Be $DSCConfig.AllNodes.PhysicalPath
            $Result.ApplicationPool | Should Be $DSCConfig.AllNodes.ApplicationPool

            # Test Website AuthenticationInfo are correct
            Get-AuthenticationInfo -Type 'Anonymous' -Website $DSCConfig.AllNodes.Website -WebApplication $DSCConfig.AllNodes.WebApplication | Should Be $DSCConfig.AllNodes.AuthenticationInfoAnonymous
            Get-AuthenticationInfo -Type 'Basic' -Website $DSCConfig.AllNodes.Website -WebApplication $DSCConfig.AllNodes.WebApplication     | Should Be $DSCConfig.AllNodes.AuthenticationInfoBasic
            Get-AuthenticationInfo -Type 'Digest' -Website $DSCConfig.AllNodes.Website -WebApplication $DSCConfig.AllNodes.WebApplication    | Should Be $DSCConfig.AllNodes.AuthenticationInfoDigest
            Get-AuthenticationInfo -Type 'Windows' -Website $DSCConfig.AllNodes.Website -WebApplication $DSCConfig.AllNodes.WebApplication   | Should Be $DSCConfig.AllNodes.AuthenticationInfoWindows

            # Test WebApplication settings
            $Result.PreloadEnabled           | Should Be $DSCConfig.AllNodes.PreloadEnabled
            $Result.ServiceAutoStartProvider | Should Be $DSCConfig.AllNodes.ServiceAutoStartProvider
            $Result.ServiceAutoStartEnabled  | Should Be $DSCConfig.AllNodes.ServiceAutoStartEnabled

            # Test the serviceAutoStartProviders are present in IIS config
            $ServiceAutoStartProviders.Name | Should Be $DSCConfig.AllNodes.ServiceAutoStartProvider
            $ServiceAutoStartProviders.Type | Should Be $DSCConfig.AllNodes.ApplicationType

            # Test WebApplication SslFlags
            Get-SslFlags -Website $DSCConfig.AllNodes.Website -WebApplication $DSCConfig.AllNodes.WebApplication | Should Be $DSCConfig.AllNodes.WebApplicationSslFlags

            # Test EnabledProtocols
            $Result.EnabledProtocols | Should Be ($DSCConfig.AllNodes.EnabledProtocols -join ',')

            }

    }

    Describe "$($script:dscResourceName)_Absent" {
        #region DEFAULT TESTS
        It 'Should compile without throwing' {
            {
                Invoke-Expression -Command "$($script:dscResourceName)_Absent -ConfigurationData `$DSCConfig -OutputPath `$TestDrive"
                Start-DscConfiguration -Path $TestDrive -ComputerName localhost -Wait -Verbose -Force
            } | Should not throw
        }

        It 'should be able to call Get-DscConfiguration without throwing' {
            { Get-DscConfiguration -Verbose -ErrorAction Stop } | Should Not throw
        }
        #endregion

        It 'Should remove the WebApplication' -test {
            Invoke-Expression -Command "$($script:dscResourceName)_Absent -ConfigurationData `$DSCConfg  -OutputPath `$TestDrive"

            # Build results to test
            $Result = Get-WebApplication -Site $DSCConfig.AllNodes.Website -Name $DSCConfig.AllNodes.WebApplication

            # Test WebApplication is removed
            $Result | Should BeNullOrEmpty
        }

    }
}
finally
{
    Restore-WebConfigurationWrapper -Name $tempName

    Remove-WebConfigurationBackup -Name $tempName

    Restore-TestEnvironment -TestEnvironment $script:testEnvironment
}
