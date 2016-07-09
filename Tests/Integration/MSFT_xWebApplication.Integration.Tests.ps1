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
    $null = Backup-WebConfiguration -Name $tempName
    
    # Now that xWebAdministration should be discoverable load the configuration data
    $ConfigFile = Join-Path -Path $PSScriptRoot -ChildPath "$($Global:DSCResourceName).config.ps1"
    . $ConfigFile

    $DSCConfig = Import-LocalizedData -BaseDirectory $PSScriptRoot -FileName "$($Global:DSCResourceName).config.psd1"

    #region HelperFunctions

    # Function needed to test AuthenticationInfo
    Function Get-AuthenticationInfo ($Type, $Website, $WebApplication) 
    {
        (Get-WebConfigurationProperty `
            -Filter /system.WebServer/security/authentication/${Type}Authentication `
            -Name enabled `
            -Location "${Website}/${WebApplication}").Value
    }

    # Function needed to test SslFlags
    Function Get-SslFlags ($Website, $WebApplication) 
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
        
        It 'Should remove the WebApplication' -test {
            
            Invoke-Expression -Command "$($Global:DSCResourceName)_Absent -ConfigurationData `$DSCConfg  -OutputPath `$TestEnvironment.WorkingFolder"

            # Build results to test
            $Result = Get-WebApplication -Site $DSCConfig.AllNodes.Website -Name $DSCConfig.AllNodes.WebApplication
            
            # Test WebApplication is removed
            $Result | Should BeNullOrEmpty 
            
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
