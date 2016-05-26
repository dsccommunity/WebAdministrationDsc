$Global:DSCModuleName = 'xWebAdministration'
$Global:DSCResourceName = 'MSFT_xIISLogging'

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

[string]$tempName = "$($Global:DSCResourceName)_" + (Get-Date).ToString("yyyyMMdd_HHmmss")


try {
    $ConfigFile = Join-Path -Path $PSScriptRoot -ChildPath "$($Global:DSCResourceName).config.ps1"
    . $ConfigFile

    $null = Backup-WebConfiguration -Name $tempName

    Describe "$($Global:DSCResourceName)_Rollover" {
        #region DEFAULT TESTS
        It 'Should compile without throwing' {
            {
                Invoke-Expression -Command "$($Global:DSCResourceName)_Rollover -OutputPath `$TestEnvironment.WorkingFolder"
                Start-DscConfiguration -Path $TestEnvironment.WorkingFolder -ComputerName localhost -Wait -Verbose -Force
            } | Should not throw
        }

        It 'should be able to call Get-DscConfiguration without throwing' {
            { Get-DscConfiguration -Verbose -ErrorAction Stop } | Should Not throw
        }
        #endregion

        It 'Changing Loggging Rollover Settings ' -test {

            Invoke-Expression -Command "$($Global:DSCResourceName)_Rollover -OutputPath `$TestEnvironment.WorkingFolder"
            Start-DscConfiguration -Path $TestEnvironment.WorkingFolder -ComputerName localhost -Wait -Verbose -Force
            
            $CurrentLogSettings = Get-WebConfiguration -filter '/system.applicationHost/sites/siteDefaults/Logfile'
               
            $CurrentLogSettings.directory | Should Be 'C:\IISLogFiles'
            $CurrentLogSettings.logExtFileFlags | Should Be 'Date,Time,ClientIP,UserName,ServerIP'
            $CurrentLogSettings.logformat | Should Be 'W3C'
            $CurrentLogSettings.period | Should Be 'Hourly'
            $CurrentLogSettings.localTimeRollover | Should Be 'True'
            $CurrentLogSettings.logformat | Should be 'W3C'
        }
    }    
    
    Describe "$($Global:DSCResourceName)_Truncate" {
        #region DEFAULT TESTS
        It 'Should compile without throwing' {
            {
                Invoke-Expression -Command "$($Global:DSCResourceName)_Truncate -OutputPath `$TestEnvironment.WorkingFolder"
                Start-DscConfiguration -Path $TestEnvironment.WorkingFolder -ComputerName localhost -Wait -Verbose -Force
            } | Should not throw
        }

        It 'should be able to call Get-DscConfiguration without throwing' {
            { Get-DscConfiguration -Verbose -ErrorAction Stop } | Should Not throw
        }
        #endregion
        It 'Changing Loggging Truncate Settings ' -test {

            Invoke-Expression -Command "$($Global:DSCResourceName)_Truncate -OutputPath `$TestEnvironment.WorkingFolder"
            Start-DscConfiguration -Path $TestEnvironment.WorkingFolder -ComputerName localhost -Wait -Verbose -Force
            
            $CurrentLogSettings = Get-WebConfiguration -filter '/system.applicationHost/sites/siteDefaults/Logfile'
               
            $CurrentLogSettings.directory | Should Be 'C:\IISLogFiles'
            $CurrentLogSettings.logExtFileFlags | Should Be 'Date,Time,ClientIP,UserName,ServerIP'
            $CurrentLogSettings.logformat | Should Be 'W3C'
            $CurrentLogSettings.TruncateSize | Should Be '2097152'
            $CurrentLogSettings.localTimeRollover | Should Be 'True'
            $CurrentLogSettings.logformat | Should be 'W3C'    
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
