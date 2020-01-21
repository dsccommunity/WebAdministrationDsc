$script:dscModuleName   = 'xWebAdministration'
$script:dscResourceName = 'MSFT_xSslSettings'

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
    $null = Backup-WebConfiguration -Name $tempName

    # Now that xWebAdministration should be discoverable load the configuration data
    $configFile = Join-Path -Path $PSScriptRoot -ChildPath "$($script:dscResourceName).config.ps1"
    . $configFile

    $DSCConfig = Import-LocalizedData -BaseDirectory $PSScriptRoot -FileName "$($script:dscResourceName).config.psd1"

    #region HelperFunctions

    # Function needed to test SslFlags
    function Get-SslFlags
    {
        [CmdletBinding()]
        param
        (
            [Parameter(Mandatory = $true)]
            [String] $Website

        )

        Get-WebConfiguration `
                -PSPath IIS:\Sites `
                -Location "$Website" `
                -Filter 'system.webserver/security/access' | `
                 ForEach-Object { $_.sslFlags }
    }

    #endregion

    # Create a new website for the SSLSettings

    New-Website -Name $DSCConfig.AllNodes.Website `
        -Id 200 `
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

        It 'Should add SSLBindings to a Website' -test {

            Invoke-Expression -Command "$($script:dscResourceName)_Present -ConfigurationData `$DSCConfg  -OutputPath `$TestDrive"

            # Test SslFlags
            Get-SslFlags -Website $DSCConfig.AllNodes.Website | Should Be $DSCConfig.AllNodes.Bindings

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

        It 'Should remove SSLBindings from a Website' -test {

            Invoke-Expression -Command "$($script:dscResourceName)_Absent -ConfigurationData `$DSCConfg  -OutputPath `$TestDrive"

            # Test SslFlags
            Get-SslFlags -Website $DSCConfig.AllNodes.Website | Should BeNullOrEmpty

            }

    }

}
finally
{
    Restore-WebConfigurationWrapper -Name $tempName -Verbose

    Remove-WebConfigurationBackup -Name $tempName -Verbose

    Restore-TestEnvironment -TestEnvironment $script:testEnvironment -Verbose
}
