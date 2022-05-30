$script:dscModuleName   = 'WebAdministrationDsc'
$script:dscResourceName = 'DSC_WebApplication'

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

Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\TestHelper\CommonTestHelper.psm1')

$tempName = "$($script:dscResourceName)_" + (Get-Date).ToString('yyyyMMdd_HHmmss')

try
{
    $null = Backup-WebConfiguration -Name $tempName

    # Now that WebAdministrationDsc should be discoverable load the configuration data
    $ConfigFile = Join-Path -Path $PSScriptRoot -ChildPath "$($script:dscResourceName).config.ps1"
    . $ConfigFile

    $configData = Import-LocalizedData -BaseDirectory $PSScriptRoot -FileName "$($script:dscResourceName).config.psd1"

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

    New-Website -Name $configData.AllNodes.Website `
        -Id 100 `
        -PhysicalPath $configData.AllNodes.PhysicalPath `
        -ApplicationPool $configData.AllNodes.AppPool `
        -SslFlags $configData.AllNodes.SslFlags `
        -Port $configData.AllNodes.HTTPSPort `
        -IPAddress '*' `
        -HostHeader $configData.AllNodes.HTTPSHostname `
        -Ssl `
        -Force `
        -ErrorAction Stop

    Describe "$($script:dscResourceName)_Present" {
        #region DEFAULT TESTS
        It 'Should compile the MOF without throwing' {
            {
                & "$($script:DSCResourceName)_Present" `
                    -OutputPath $TestDrive `
                    -ConfigurationData $configData
            } | Should -Not -Throw
        }

        It 'Should apply the MOF without throwing' {
            {
                Reset-DscLcm

                Start-DscConfiguration `
                    -Path $TestDrive `
                    -ComputerName localhost `
                    -Wait `
                    -Verbose `
                    -Force `
                    -ErrorAction Stop
            } | Should -Not -Throw
        }

        <#
            This is throwing, issue created: https://github.com/dsccommunity/xWebAdministration/issues/606
        #>
        # It 'Should be able to call Get-DscConfiguration without throwing' {
        #     { Get-DscConfiguration -Verbose -ErrorAction Stop } | Should -Not -Throw
        # }
        #endregion

        It 'Should create a WebApplication with correct settings' -test {

            Invoke-Expression -Command "$($script:dscResourceName)_Present -ConfigurationData `$DSCConfg -OutputPath `$TestDrive"

            # Build results to test
            $Result = Get-WebApplication -Site $configData.AllNodes.Website -Name $configData.AllNodes.WebApplication
            $ServiceAutoStartProviders = (Get-WebConfiguration -filter /system.applicationHost/serviceAutoStartProviders).Collection

            # Test WebApplication basic settings are correct
            $Result.Path            | Should Match $configData.AllNodes.WebApplication
            $Result.PhysicalPath    | Should Be $configData.AllNodes.PhysicalPath
            $Result.ApplicationPool | Should Be $configData.AllNodes.ApplicationPool

            # Test Website AuthenticationInfo are correct
            Get-AuthenticationInfo -Type 'Anonymous' -Website $configData.AllNodes.Website -WebApplication $configData.AllNodes.WebApplication | Should Be $configData.AllNodes.AuthenticationInfoAnonymous
            Get-AuthenticationInfo -Type 'Basic' -Website $configData.AllNodes.Website -WebApplication $configData.AllNodes.WebApplication     | Should Be $configData.AllNodes.AuthenticationInfoBasic
            Get-AuthenticationInfo -Type 'Digest' -Website $configData.AllNodes.Website -WebApplication $configData.AllNodes.WebApplication    | Should Be $configData.AllNodes.AuthenticationInfoDigest
            Get-AuthenticationInfo -Type 'Windows' -Website $configData.AllNodes.Website -WebApplication $configData.AllNodes.WebApplication   | Should Be $configData.AllNodes.AuthenticationInfoWindows

            # Test WebApplication settings
            $Result.PreloadEnabled           | Should Be $configData.AllNodes.PreloadEnabled
            $Result.ServiceAutoStartProvider | Should Be $configData.AllNodes.ServiceAutoStartProvider
            $Result.ServiceAutoStartEnabled  | Should Be $configData.AllNodes.ServiceAutoStartEnabled

            # Test the serviceAutoStartProviders are present in IIS config
            $ServiceAutoStartProviders.Name | Should Be $configData.AllNodes.ServiceAutoStartProvider
            $ServiceAutoStartProviders.Type | Should Be $configData.AllNodes.ApplicationType

            # Test WebApplication SslFlags
            Get-SslFlags -Website $configData.AllNodes.Website -WebApplication $configData.AllNodes.WebApplication | Should Be $configData.AllNodes.WebApplicationSslFlags

            # Test EnabledProtocols
            $Result.EnabledProtocols | Should Be ($configData.AllNodes.EnabledProtocols -join ',')

            }

    }

    Describe "$($script:dscResourceName)_Absent" {
        #region DEFAULT TESTS
        It 'Should compile the MOF without throwing' {
            {
                & "$($script:DSCResourceName)_Absent" `
                    -OutputPath $TestDrive `
                    -ConfigurationData $configData
            } | Should -Not -Throw
        }

        It 'Should apply the MOF without throwing' {
            {
                Reset-DscLcm

                Start-DscConfiguration `
                    -Path $TestDrive `
                    -ComputerName localhost `
                    -Wait `
                    -Verbose `
                    -Force `
                    -ErrorAction Stop
            } | Should -Not -Throw
        }

        It 'Should be able to call Get-DscConfiguration without throwing' {
            { Get-DscConfiguration -Verbose -ErrorAction Stop } | Should -Not -Throw
        }
        #endregion

        It 'Should remove the WebApplication' -test {
            Invoke-Expression -Command "$($script:dscResourceName)_Absent -ConfigurationData `$DSCConfg  -OutputPath `$TestDrive"

            # Build results to test
            $Result = Get-WebApplication -Site $configData.AllNodes.Website -Name $configData.AllNodes.WebApplication

            # Test WebApplication is removed
            $Result | Should BeNullOrEmpty
        }

    }
}
finally
{
    Restore-WebConfigurationWrapper -Name $tempName -Verbose

    Remove-WebConfigurationBackup -Name $tempName -Verbose

    Restore-TestEnvironment -TestEnvironment $script:testEnvironment -Verbose
}
