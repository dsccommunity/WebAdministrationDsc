$script:dscModuleName = 'xWebAdministration'
$script:dscResourceName = 'MSFT_xIISLogging'

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

$tempName = "$($script:dscResourceName)_" + (Get-Date).ToString("yyyyMMdd_HHmmss")

try
{
    $configFile = Join-Path -Path $PSScriptRoot -ChildPath "$($script:dscResourceName).config.ps1"
    . $configFile

    $null = Backup-WebConfiguration -Name $tempName

    Describe "$($script:dscResourceName)_Rollover" {
        #region DEFAULT TESTS
        It 'Should compile without throwing' {
            {
                Invoke-Expression -Command "$($script:dscResourceName)_Rollover -OutputPath `$TestDrive"
                Start-DscConfiguration -Path $TestDrive -ComputerName localhost -Wait -Verbose -Force
            } | Should not throw
        }

        It 'should be able to call Get-DscConfiguration without throwing' {
            { Get-DscConfiguration -Verbose -ErrorAction Stop } | Should Not throw
        }
        #endregion

        It 'Changing Logging Rollover Settings ' -test {

            Invoke-Expression -Command "$($script:dscResourceName)_Rollover -OutputPath `$TestDrive"
            Start-DscConfiguration -Path $TestDrive -ComputerName localhost -Wait -Verbose -Force

            $currentLogSettings = Get-WebConfiguration -filter '/system.applicationHost/sites/siteDefaults/Logfile'

            $currentLogSettings.directory | Should Be 'C:\IISLogFiles'
            $currentLogSettings.logExtFileFlags | Should Be 'Date,Time,ClientIP,UserName,ServerIP'
            $currentLogSettings.logformat | Should Be 'W3C'
            $currentLogSettings.logTargetW3C | Should Be 'File,ETW'
            $currentLogSettings.period | Should Be 'Hourly'
            $currentLogSettings.localTimeRollover | Should Be 'True'
            $currentLogSettings.customFields.Collection[0].LogFieldName | Should Be 'ClientEncoding'
            $currentLogSettings.customFields.Collection[0].SourceName | Should Be 'Accept-Encoding'
            $currentLogSettings.customFields.Collection[0].SourceType | Should Be 'RequestHeader'
            $currentLogSettings.customFields.Collection[1].LogFieldName | Should Be 'X-Powered-By'
            $currentLogSettings.customFields.Collection[1].SourceName | Should Be 'ASP.NET'
            $currentLogSettings.customFields.Collection[1].SourceType | Should Be 'ResponseHeader'
       }
    }

    Describe "$($script:dscResourceName)_Truncate" {
        #region DEFAULT TESTS
        It 'Should compile without throwing' {
            {
                Invoke-Expression -Command "$($script:dscResourceName)_Truncate -OutputPath `$TestDrive"
                Start-DscConfiguration -Path $TestDrive -ComputerName localhost -Wait -Verbose -Force
            } | Should not throw
        }

        It 'should be able to call Get-DscConfiguration without throwing' {
            { Get-DscConfiguration -Verbose -ErrorAction Stop } | Should Not throw
        }
        #endregion
        It 'Changing Logging Truncate Settings ' -test {

            Invoke-Expression -Command "$($script:dscResourceName)_Truncate -OutputPath `$TestDrive"
            Start-DscConfiguration -Path $TestDrive -ComputerName localhost -Wait -Verbose -Force

            $currentLogSettings = Get-WebConfiguration -filter '/system.applicationHost/sites/siteDefaults/Logfile'

            $currentLogSettings.directory | Should Be 'C:\IISLogFiles'
            $currentLogSettings.logExtFileFlags | Should Be 'Date,Time,ClientIP,UserName,ServerIP'
            $currentLogSettings.logformat | Should Be 'W3C'
            $currentLogSettings.logTargetW3C | Should Be 'File,ETW'
            $currentLogSettings.TruncateSize | Should Be '2097152'
            $currentLogSettings.localTimeRollover | Should Be 'True'
            $currentLogSettings.customFields.Collection[0].LogFieldName | Should Be 'ClientEncoding'
            $currentLogSettings.customFields.Collection[0].SourceName | Should Be 'Accept-Encoding'
            $currentLogSettings.customFields.Collection[0].SourceType | Should Be 'RequestHeader'
            $currentLogSettings.customFields.Collection[1].LogFieldName | Should Be 'X-Powered-By'
            $currentLogSettings.customFields.Collection[1].SourceName | Should Be 'ASP.NET'
            $currentLogSettings.customFields.Collection[1].SourceType | Should Be 'ResponseHeader'
        }
    }

    Describe "$($script:dscResourceName)_LogFlags" {
        #region DEFAULT TESTS
        It 'Should compile without throwing' {
            {
                Invoke-Expression -Command "$($script:dscResourceName)_LogFlags -OutputPath `$TestDrive"
                Start-DscConfiguration -Path $TestDrive -ComputerName localhost -Wait -Verbose -Force
            } | Should not throw
        }

        It 'should be able to call Get-DscConfiguration without throwing' {
            { Get-DscConfiguration -Verbose -ErrorAction Stop } | Should Not throw
        }
        #endregion
        It 'Changing enabled LogFlags ' -test {

            Invoke-Expression -Command "$($script:dscResourceName)_LogFlags -OutputPath `$TestDrive"
            Start-DscConfiguration -Path $TestDrive -ComputerName localhost -Wait -Verbose -Force

            $currentLogSettings = Get-WebConfiguration -filter '/system.applicationHost/sites/siteDefaults/Logfile'

            $currentLogSettings.directory | Should Be 'C:\IISLogFiles'
            $currentLogSettings.logExtFileFlags | Should Be 'Date,Time,ClientIP,ServerIP,UserAgent'
            $currentLogSettings.logformat | Should Be 'W3C'
            $currentLogSettings.logTargetW3C | Should Be 'File,ETW'
            $currentLogSettings.TruncateSize | Should Be '2097152'
            $currentLogSettings.localTimeRollover | Should Be 'True'
            $currentLogSettings.customFields.Collection[0].LogFieldName | Should Be 'ClientEncoding'
            $currentLogSettings.customFields.Collection[0].SourceName | Should Be 'Accept-Encoding'
            $currentLogSettings.customFields.Collection[0].SourceType | Should Be 'RequestHeader'
            $currentLogSettings.customFields.Collection[1].LogFieldName | Should Be 'X-Powered-By'
            $currentLogSettings.customFields.Collection[1].SourceName | Should Be 'ASP.NET'
            $currentLogSettings.customFields.Collection[1].SourceType | Should Be 'ResponseHeader'
        }
    }

    Describe "$($script:dscResourceName)_LogCustomFields" {
        #region DEFAULT TESTS
        It 'Should compile without throwing' {
            {
                Invoke-Expression -Command "$($script:dscResourceName)_LogCustomFields -OutputPath `$TestDrive"
                Start-DscConfiguration -Path $TestDrive -ComputerName localhost -Wait -Verbose -Force
            } | Should not throw
        }

        It 'should be able to call Get-DscConfiguration without throwing' {
            { Get-DscConfiguration -Verbose -ErrorAction Stop } | Should Not throw
        }
        #endregion
        It 'Should remove all custom log fields' -test {

            Invoke-Expression -Command "$($script:dscResourceName)_LogCustomFields -OutputPath `$TestDrive"
            Start-DscConfiguration -Path $TestDrive -ComputerName localhost -Wait -Verbose -Force

            $currentLogSettings = Get-WebConfiguration -filter '/system.applicationHost/sites/siteDefaults/Logfile'

            $currentLogSettings.directory | Should Be 'C:\IISLogFiles'
            $currentLogSettings.logExtFileFlags | Should Be 'Date,Time,ClientIP,ServerIP,UserAgent'
            $currentLogSettings.logformat | Should Be 'W3C'
            $currentLogSettings.logTargetW3C | Should Be 'File,ETW'
            $currentLogSettings.TruncateSize | Should Be '2097152'
            $currentLogSettings.localTimeRollover | Should Be 'True'
            $currentLogSettings.customFields.Collection | Should -BeNullOrEmpty
        }
    }
}
finally
{
    Restore-WebConfigurationWrapper -Name $tempName -Verbose

    Remove-WebConfigurationBackup -Name $tempName -Verbose

    Restore-TestEnvironment -TestEnvironment $script:testEnvironment -Verbose
}
