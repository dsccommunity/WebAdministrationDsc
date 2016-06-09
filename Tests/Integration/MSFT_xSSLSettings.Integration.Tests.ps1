$Global:DSCModuleName   = 'xWebAdministration'
$Global:DSCResourceName = 'MSFT_xSSLSettings'

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
    $null = Backup-WebConfiguration -Name $tempName
    
    # Now that xWebAdministration should be discoverable load the configuration data
    $ConfigFile = Join-Path -Path $PSScriptRoot -ChildPath "$($Global:DSCResourceName).config.ps1"
    . $ConfigFile

    $DSCConfig = Import-LocalizedData -BaseDirectory $PSScriptRoot -FileName "$($Global:DSCResourceName).config.psd1"

    #region HelperFunctions

    # Function needed to test SslFlags
    Function Get-SslFlags ($Website) { 
        
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

        It 'Should add SSLBindings to a Website' -test {
            
            Invoke-Expression -Command "$($Global:DSCResourceName)_Present -ConfigurationData `$DSCConfg  -OutputPath `$TestEnvironment.WorkingFolder"
           
            # Test SslFlags
            Get-SslFlags -Website $DSCConfig.AllNodes.Website | Should Be $DSCConfig.AllNodes.Bindings
            
            }

    }

    Describe "$($Global:DSCResourceName)_Absent" {
        #region DEFAULT TESTS
        It 'Should compile without throwing' {
            {
                Invoke-Expression -Command "$($Global:DSCResourceName)_Absent -ConfigurationData `$DSCConfig -OutputPath `$TestEnvironment.WorkingFolder"
                Start-DscConfiguration -Path $TestEnvironment.WorkingFolder -ComputerName localhost -Wait -Verbose -Force
            } | Should not throw
        }

        It 'should be able to call Get-DscConfiguration without throwing' {
            { Get-DscConfiguration -Verbose -ErrorAction Stop } | Should Not throw
        }
        #endregion
        
        It 'Should remove SSLBindings from a Website' -test {
            
            Invoke-Expression -Command "$($Global:DSCResourceName)_Absent -ConfigurationData `$DSCConfg  -OutputPath `$TestEnvironment.WorkingFolder"

            # Test SslFlags
            Get-SslFlags -Website $DSCConfig.AllNodes.Website | Should BeNullOrEmpty
            
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
