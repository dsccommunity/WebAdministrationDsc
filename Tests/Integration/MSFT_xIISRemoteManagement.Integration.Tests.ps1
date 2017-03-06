$script:DSCModuleName = 'xWebAdministration'
$script:DSCResourceName = 'MSFT_xIISRemoteManagement'

#region HEADER

# Integration Test Template Version: 1.1.0
[String] $moduleRoot = Split-Path -Parent -Path (Split-Path -Parent -Path (Split-Path -Parent -Path $Script:MyInvocation.MyCommand.Path))
if ( (-not (Test-Path -Path (Join-Path -Path $moduleRoot -ChildPath 'DSCResource.Tests'))) -or `
(-not (Test-Path -Path (Join-Path -Path $moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1'))) )
{
    & git.exe @('clone', 'https://github.com/PowerShell/DscResource.Tests.git', (Join-Path -Path $moduleRoot -ChildPath '\DSCResource.Tests\'))
}

Import-Module (Join-Path -Path $moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1') -Force
$TestEnvironment = Initialize-TestEnvironment `
                    -DSCModuleName $script:DSCModuleName `
                    -DSCResourceName $script:DSCResourceName `
                    -TestType Integration

#endregion

[string]$tempName = "$($script:DSCResourceName)_" + (Get-Date).ToString('yyyyMMdd_HHmmss')


try 
{
    $ConfigFile = Join-Path -Path $PSScriptRoot -ChildPath "$($script:DSCResourceName).config.ps1"
    . $ConfigFile

    $null = Backup-WebConfiguration -Name $tempName

    Describe -Name "$($script:DSCResourceName)_Enabled" -Fixture {
        #region DEFAULT TESTS
        It -name 'Should compile without throwing' -test {
            {
                Invoke-Expression -Command "$($script:DSCResourceName)_Enabled -OutputPath `$TestDrive"
                Start-DscConfiguration -Path $TestDrive -ComputerName localhost -Wait -Verbose -Force
            } | Should not throw
        }

        It -name 'should be able to call Get-DscConfiguration without throwing' -test {
            {
                Get-DscConfiguration -Verbose -ErrorAction Stop 
            } | Should Not throw
        }
        #endregion

        It -name 'Enabling IISRemoteManagment' -test {
            Invoke-Expression -Command "$($script:DSCResourceName)_Enabled -OutputPath `$TestDrive"
            Start-DscConfiguration -Path $TestDrive -ComputerName localhost -Wait -Verbose -Force
            
            $webMgmtService = (Get-WindowsFeature -Name Web-Mgmt-Service `
                                                  -ErrorAction SilentlyContinue).Installed

            $service = (Get-Service -Name WMSVC `
                                    -ErrorAction SilentlyContinue).Status

            $windowsCredential = (Get-ItemProperty -Path HKLM:\SOFTWARE\Microsoft\WebManagement\Server `
                                    -Name RequiresWindowsCredentials).RequiresWindowsCredentials

            $webMgmtService    | Should Be $true
            $service           | Should Be 'Running'
            $windowsCredential | Should be '1'
        }
    }    
    
    Describe -Name "$($script:DSCResourceName)_Disabled" -Fixture {
        #region DEFAULT TESTS
        It -name 'Should compile without throwing' -test {
            {
                Invoke-Expression -Command "$($script:DSCResourceName)_Disabled -OutputPath `$TestDrive"
                Start-DscConfiguration -Path $TestDrive -ComputerName localhost -Wait -Verbose -Force
            } | Should not throw
        }

        It -name 'should be able to call Get-DscConfiguration without throwing' -test {
            {
                Get-DscConfiguration -Verbose -ErrorAction Stop 
            } | Should Not throw
        }
        #endregion
        It -name 'Disabling IISRemoteManagment' -test {
            Invoke-Expression -Command "$($script:DSCResourceName)_Disabled -OutputPath `$TestDrive"
            Start-DscConfiguration -Path $TestDrive -ComputerName localhost -Wait -Verbose -Force
            
            $webMgmtService = (Get-WindowsFeature -Name Web-Mgmt-Service `
                                                  -ErrorAction SilentlyContinue).Installed

            $service = (Get-Service -Name WMSVC `
                                    -ErrorAction SilentlyContinue).Status
               
            $webMgmtService | Should Be $false
            $service        | Should Be 'Stopped'
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
