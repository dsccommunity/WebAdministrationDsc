$script:dscModuleName = 'xWebAdministration'
$script:dscResourceName = 'MSFT_xIisLogging'

function Invoke-TestSetup
{
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
        -TestType 'Unit'

    Import-Module (Join-Path -Path $PSScriptRoot -ChildPath '..\MockWebAdministrationWindowsFeature.psm1')
}

function Invoke-TestCleanup
{
    Restore-TestEnvironment -TestEnvironment $script:testEnvironment
}

Invoke-TestSetup

try
{
    InModuleScope $script:dscResourceName {

        $MockLogCustomFields = @{
            LogFieldName = 'ClientEncoding'
            SourceName   = 'Accept-Encoding'
            SourceType   = 'RequestHeader'
        }

        $MockCimLogCustomFields = @(
            New-CimInstance -ClassName MSFT_xLogCustomField `
                -Namespace root/microsoft/Windows/DesiredStateConfiguration `
                -Property @{
                    LogFieldName = 'ClientEncoding'
                    SourceName   = 'Accept-Encoding'
                    SourceType   = 'RequestHeader'
                } `
                -ClientOnly
        )

        $MockLogParameters =
        @{
            LogPath              = 'C:\MockLogLocation'
            LogFlags             = 'Date', 'Time', 'ClientIP', 'UserName', 'ServerIP'
            LogPeriod            = 'Hourly'
            LogTruncateSize      = '2097152'
            LoglocalTimeRollover = $true
            LogFormat            = 'W3C'
            LogTargetW3C         = 'File,ETW'
            LogCustomFields      = $MockCimLogCustomFields
        }

        $MockLogOutput =
        @{
            directory         = '%SystemDrive%\inetpub\logs\LogFiles'
            logExtFileFlags   = 'Date,Time,ClientIP,UserName,ServerIP,Method,UriStem,UriQuery,HttpStatus,Win32Status,TimeTaken,ServerPort,UserAgent,Referer,HttpSubStatus'
            logFormat         = 'W3C'
            LogTargetW3C      = 'File,ETW'
            period            = 'Daily'
            truncateSize      = '1048576'
            localTimeRollover = 'False'
            customFields      = @{Collection = @($MockLogCustomFields) }
        }

        $MockLogFlagsAfterSplit = [System.String[]] @('Date', 'Time', 'ClientIP', 'UserName', 'ServerIP', 'Method', 'UriStem', 'UriQuery', 'HttpStatus', 'Win32Status', 'TimeTaken', 'ServerPort', 'UserAgent', 'Referer', 'HttpSubStatus')

        Describe "$script:dscResourceName\Get-TargetResource" {

            Context 'Correct hashtable is returned' {

                Mock -CommandName Get-WebConfiguration `
                    -MockWith { return $MockLogOutput }

                Mock -CommandName Assert-Module -MockWith { }

                Mock -CommandName ConvertTo-CimLogCustomFields `
                    -MockWith { return $MockLogCustomFields }

                $result = Get-TargetResource -LogPath $MockLogParameters.LogPath

                It 'Should call Get-WebConfiguration once' {
                    Assert-MockCalled -CommandName Get-WebConfiguration -Exactly 1
                }

                It 'Should return LogPath' {
                    $result.LogPath | Should Be $MockLogOutput.directory
                }

                It 'Should return LogFlags' {
                    $result.LogFlags | Should Be $MockLogFlagsAfterSplit
                }

                It 'Should return LogFlags as expected array of Strings' {
                    $result.LogFlags -is [System.String[]] | Should -BeTrue
                    $result.LogFlags | Should -HaveCount 15
                    $result.LogFlags | Should -Contain 'Date'
                    $result.LogFlags | Should -Contain 'Time'
                    $result.LogFlags | Should -Contain 'ClientIP'
                    $result.LogFlags | Should -Contain 'UserName'
                    $result.LogFlags | Should -Contain 'ServerIP'
                    $result.LogFlags | Should -Contain 'Method'
                    $result.LogFlags | Should -Contain 'UriStem'
                    $result.LogFlags | Should -Contain 'UriQuery'
                    $result.LogFlags | Should -Contain 'HttpStatus'
                    $result.LogFlags | Should -Contain 'Win32Status'
                    $result.LogFlags | Should -Contain 'TimeTaken'
                    $result.LogFlags | Should -Contain 'ServerPort'
                    $result.LogFlags | Should -Contain 'UserAgent'
                    $result.LogFlags | Should -Contain 'Referer'
                    $result.LogFlags | Should -Contain 'HttpSubStatus'
                }

                It 'Should return LogPeriod' {
                    $result.LogPeriod | Should Be $MockLogOutput.period
                }

                It 'Should return LogTruncateSize' {
                    $result.LogTruncateSize | Should Be $MockLogOutput.truncateSize
                }

                It 'Should return LoglocalTimeRollover' {
                    $result.LoglocalTimeRollover | Should Be $MockLogOutput.localTimeRollover
                }

                It 'Should return LogFormat' {
                    $result.LogFormat | Should Be $MockLogOutput.logFormat
                }

                It 'Should return LogTargetW3C' {
                    $result.LogTargetW3C | Should Be $MockLogOutput.logTargetW3C
                }

                It 'Should return LogCustomFields' {
                    $result.LogCustomFields.LogFieldName | Should Be $MockLogCustomFields.LogFieldName
                    $result.LogCustomFields.SourceName | Should Be $MockLogCustomFields.SourceName
                    $result.LogCustomFields.SourceType | Should Be $MockLogCustomFields.SourceType
                }
            }

        }

        Describe "$script:dscResourceName\Test-TargetResource" {

            Mock -CommandName Assert-Module -MockWith { }

            Context 'All settings are correct' {

                $MockLogOutput =
                @{
                    directory         = $MockLogParameters.LogPath
                    logExtFileFlags   = $MockLogParameters.LogFlags
                    period            = $MockLogParameters.LogPeriod
                    truncateSize      = $MockLogParameters.LogTruncateSize
                    localTimeRollover = $MockLogParameters.LoglocalTimeRollover
                    logFormat         = $MockLogParameters.LogFormat
                    logTargetW3C      = $MockLogParameters.LogTargetW3C
                    customFields      = $MockLogParameters.LogCustomFields
                }

                Mock -CommandName Test-Path -MockWith { return $true }

                Mock -CommandName Get-WebConfiguration `
                    -MockWith { return $MockLogOutput }

                Mock -CommandName Get-WebConfigurationProperty `
                    -MockWith { return $MockLogOutput.logExtFileFlags }

                Mock -CommandName Test-LogCustomField `
                    -MockWith { return $MockLogCustomFields }


                $result = Test-TargetResource @MockLogParameters

                It 'Should return true' {
                    $result | Should be $true
                }

            }

            Context 'All Settings are incorrect' {

                Mock -CommandName Test-Path -MockWith { return $true }

                Mock -CommandName Get-WebConfiguration `
                    -MockWith { return $MockLogOutput }

                Mock -CommandName Get-WebConfigurationProperty `
                    -MockWith { return $MockLogOutput.logExtFileFlags }

                $result = Test-TargetResource @MockLogParameters

                It 'Should return false' {
                    $result | Should be $false
                }

            }

            Context 'Check LogPath should return false' {

                $MockLogOutput =
                @{
                    directory         = '%SystemDrive%\inetpub\logs\LogFiles'
                    logExtFileFlags   = $MockLogParameters.LogFlags
                    period            = $MockLogParameters.LogPeriod
                    truncateSize      = $MockLogParameters.LogTruncateSize
                    localTimeRollover = $MockLogParameters.LoglocalTimeRollover
                    logFormat         = $MockLogParameters.LogFormat
                }

                Mock -CommandName Test-Path -MockWith { return $true }

                Mock -CommandName Get-WebConfiguration `
                    -MockWith { return $MockLogOutput }

                Mock -CommandName Get-WebConfigurationProperty `
                    -MockWith { return $MockLogOutput.logExtFileFlags }

                $result = Test-TargetResource @MockLogParameters

                It 'Should return false' {
                    $result | Should be $false
                }

            }

            Context 'Check LogFlags should return false' {

                $MockLogOutput =
                @{
                    directory         = $MockLogParameters.LogPath
                    logExtFileFlags   = 'Date', 'Time', 'ClientIP', 'UserName', 'ServerIP', 'Method', 'UriStem', 'UriQuery', 'HttpStatus', 'Win32Status', 'TimeTaken', 'ServerPort', 'UserAgent', 'Referer', 'HttpSubStatus'
                    period            = $MockLogParameters.LogPeriod
                    truncateSize      = $MockLogParameters.LogTruncateSize
                    localTimeRollover = $MockLogParameters.LoglocalTimeRollover
                    logFormat         = $MockLogParameters.LogFormat
                }

                Mock -CommandName Test-Path -MockWith { return $true }

                Mock -CommandName Get-WebConfiguration `
                    -MockWith { return $MockLogOutput }

                Mock -CommandName Get-WebConfigurationProperty `
                    -MockWith { return $MockLogOutput.logExtFileFlags }

                $result = Test-TargetResource @MockLogParameters

                It 'Should return false' {
                    $result | Should be $false
                }

            }

            Context 'Check LogPeriod should return false' {

                $MockLogOutput =
                @{
                    directory         = $MockLogParameters.LogPath
                    logExtFileFlags   = $MockLogParameters.LogFlags
                    period            = 'Daily'
                    truncateSize      = $MockLogParameters.LogTruncateSize
                    localTimeRollover = $MockLogParameters.LoglocalTimeRollover
                    logFormat         = $MockLogParameters.LogFormat
                }

                Mock -CommandName Test-Path -MockWith { return $true }

                Mock -CommandName Get-WebConfiguration `
                    -MockWith { return $MockLogOutput }

                Mock -CommandName Get-WebConfigurationProperty `
                    -MockWith { return $MockLogOutput.logExtFileFlags }

                $result = Test-TargetResource @MockLogParameters

                It 'Should return false' {
                    $result | Should be $false
                }

            }

            Context 'Check LogTruncateSize should return false' {

                $MockLogOutput =
                @{
                    directory         = $MockLogParameters.LogPath
                    logExtFileFlags   = $MockLogParameters.LogFlags
                    period            = $MockLogParameters.LogPeriod
                    truncateSize      = '1048576'
                    localTimeRollover = $MockLogParameters.LoglocalTimeRollover
                    logFormat         = $MockLogParameters.LogFormat
                }

                Mock -CommandName Test-Path -MockWith { return $true }

                Mock -CommandName Get-WebConfiguration `
                    -MockWith { return $MockLogOutput }

                Mock -CommandName Get-WebConfigurationProperty `
                    -MockWith { return $MockLogOutput.logExtFileFlags }

                $result = Test-TargetResource @MockLogParameters

                It 'Should return false' {
                    $result | Should be $false
                }

            }

            Context 'Check LogTruncateSize too large for string validation' {
                $MockLogParameters = @{
                    LogPath              = $MockLogParameters.LogPath
                    LogFlags             = $MockLogParameters.LogFlags
                    LogPeriod            = $MockLogParameters.LogPeriod
                    LogTruncateSize      = '536870912'
                    LoglocalTimeRollover = $MockLogParameters.LoglocalTimeRollover
                    LogFormat            = $MockLogParameters.LogFormat
                }

                $MockLogOutput =
                @{
                    directory         = $MockLogParameters.LogPath
                    logExtFileFlags   = $MockLogParameters.LogFlags
                    period            = $MockLogParameters.LogPeriod
                    truncateSize      = '636870912'
                    localTimeRollover = $MockLogParameters.LoglocalTimeRollover
                    logFormat         = $MockLogParameters.LogFormat
                }

                Mock -CommandName Test-Path -MockWith { return $true }

                Mock -CommandName Get-WebConfiguration `
                    -MockWith { return $MockLogOutput }

                Mock -CommandName Get-WebConfigurationProperty `
                    -MockWith { return $MockLogOutput.logExtFileFlags }

                $result = Test-TargetResource @MockLogParameters

                It 'Should return false' {
                    $result | Should be $false
                }

            }

            Context 'Check LoglocalTimeRollover should return false' {

                $MockLogOutput =
                @{
                    directory         = $MockLogParameters.LogPath
                    logExtFileFlags   = $MockLogParameters.LogFlags
                    period            = $MockLogParameters.LogPeriod
                    truncateSize      = $MockLogParameters.LogTruncateSize
                    localTimeRollover = 'False'
                    logFormat         = $MockLogParameters.LogFormat
                }

                Mock -CommandName Test-Path -MockWith { return $true }

                Mock -CommandName Get-WebConfiguration `
                    -MockWith { return $MockLogOutput }

                Mock -CommandName Get-WebConfigurationProperty `
                    -MockWith { return $MockLogOutput.logExtFileFlags }

                $result = Test-TargetResource @MockLogParameters

                It 'Should return false' {
                    $result | Should be $false
                }

            }

            Context 'Check LogFormat should return false' {

                $MockLogOutput =
                @{
                    directory         = $MockLogParameters.LogPath
                    logExtFileFlags   = $MockLogParameters.LogFlags
                    period            = $MockLogParameters.LogPeriod
                    truncateSize      = $MockLogParameters.LogTruncateSize
                    localTimeRollover = $MockLogParameters.LoglocalTimeRollover
                    logFormat         = 'IIS'
                }

                Mock -CommandName Test-Path -MockWith { return $true }

                Mock -CommandName Get-WebConfiguration `
                    -MockWith { return $MockLogOutput }

                Mock -CommandName Get-WebConfigurationProperty `
                    -MockWith { return $MockLogOutput.logExtFileFlags }

                $result = Test-TargetResource @MockLogParameters

                It 'Should return false' {
                    $result | Should be $false
                }

            }

            Context 'Check LogTargetW3C should return false' {

                $MockLogOutput =
                @{
                    directory         = $MockLogParameters.LogPath
                    logExtFileFlags   = $MockLogParameters.LogFlags
                    period            = $MockLogParameters.LogPeriod
                    truncateSize      = $MockLogParameters.LogTruncateSize
                    localTimeRollover = $MockLogParameters.LoglocalTimeRollover
                    logFormat         = $MockLogParameters.LogFormat
                    LogTargetW3C      = 'File'
                }

                Mock -CommandName Test-Path -MockWith { return $true }

                Mock -CommandName Get-WebConfiguration `
                    -MockWith { return $MockLogOutput }

                Mock -CommandName Get-WebConfigurationProperty `
                    -MockWith { return $MockLogOutput.logExtFileFlags }

                $result = Test-TargetResource @MockLogParameters

                It 'Should return false' {
                    $result | Should be $false
                }

            }

            Context 'Check LogCustomFields is equal' {
                #region Mocks for Test-TargetResource
                Mock -CommandName Test-Path -MockWith { return $true }
                Mock -CommandName Get-TargetResource -MockWith { return $MockLogParameters }
                Mock -CommandName Get-WebConfigurationProperty -MockWith { return $MockCimLogCustomFields }
                #endregion

                $result = Test-TargetResource `
                    -LogPath $MockLogParameters.LogPath `
                    -LogCustomFields $MockLogParameters.LogCustomFields

                It 'Should return true' {
                    $result | Should be $true
                }
            }

            Context 'Check LogCustomFields is different' {
                $MockDifferentLogCustomFields = @{
                    LogFieldName = 'DifferentField'
                    SourceName   = 'Accept-Encoding'
                    SourceType   = 'DifferentSourceType'
                }

                #region Mocks for Test-TargetResource
                Mock -CommandName Test-Path -MockWith { return $true }
                Mock -CommandName Get-WebConfiguration -MockWith { return $MockLogOutput }
                Mock -CommandName Get-WebConfigurationProperty -MockWith { return $MockDifferentLogCustomFields }
                #endregion

                $result = Test-TargetResource -LogPath $MockLogParameters.LogPath `
                    -LogCustomFields $MockLogParameters.LogCustomFields


                It 'Should return false' {
                    $result | Should be $false
                }
            }
        }

        Describe "$script:dscResourceName\Set-TargetResource" {

            Mock -CommandName Assert-Module -MockWith { }

            Context 'All Settings are incorrect' {

                $MockLogOutput =
                @{
                    directory         = '%SystemDrive%\inetpub\logs\LogFiles'
                    logExtFileFlags   = 'Date', 'Time', 'ClientIP', 'UserName', 'ServerIP', 'Method', 'UriStem', 'UriQuery', 'HttpStatus', 'Win32Status', 'TimeTaken', 'ServerPort', 'UserAgent', 'Referer', 'HttpSubStatus'
                    logFormat         = 'IIS'
                    logTargetW3C      = 'File'
                    period            = 'Daily'
                    truncateSize      = '1048576'
                    localTimeRollover = 'False'
                }

                Mock -CommandName Test-Path -MockWith { return $true }

                Mock -CommandName Get-WebConfiguration `
                    -MockWith { return $MockLogOutput }

                Mock -CommandName Get-WebConfigurationProperty `
                    -MockWith { return $MockLogOutput.logExtFileFlags }

                Mock -CommandName Set-WebConfigurationProperty

                Set-TargetResource @MockLogParameters

                It 'Should call all the mocks' {
                    Assert-MockCalled -CommandName Set-WebConfigurationProperty -Exactly 10
                }

            }

            Context 'LogPath is incorrect' {

                $MockLogOutput =
                @{
                    directory         = '%SystemDrive%\inetpub\logs\LogFiles'
                    logExtFileFlags   = $MockLogParameters.LogFlags
                    period            = $MockLogParameters.LogPeriod
                    truncateSize      = $MockLogParameters.LogTruncateSize
                    localTimeRollover = $MockLogParameters.LoglocalTimeRollover
                    logFormat         = $MockLogParameters.LogFormat
                    logTargetW3C      = $MockLogParameters.LogTargetW3C
                }

                Mock -CommandName Test-Path -MockWith { return $true }

                Mock -CommandName Get-WebConfiguration `
                    -MockWith { return $MockLogOutput }

                Mock -CommandName Get-WebConfigurationProperty `
                    -MockWith { return $MockLogOutput.logExtFileFlags }

                Mock -CommandName Set-WebConfigurationProperty

                Set-TargetResource @MockLogParameters

                It 'Should call all the mocks' {
                    Assert-MockCalled -CommandName Set-WebConfigurationProperty -Exactly 2
                }

            }

            Context 'LogFlags are incorrect' {

                $MockLogOutput =
                @{
                    directory         = $MockLogParameters.LogPath
                    logExtFileFlags   = 'Date', 'Time', 'ClientIP', 'UserName', 'ServerIP', 'Method', 'UriStem', 'UriQuery', 'HttpStatus', 'Win32Status', 'TimeTaken', 'ServerPort', 'UserAgent', 'Referer', 'HttpSubStatus'
                    period            = $MockLogParameters.LogPeriod
                    truncateSize      = $MockLogParameters.LogTruncateSize
                    localTimeRollover = $MockLogParameters.LoglocalTimeRollover
                    logFormat         = $MockLogParameters.LogFormat
                    logTargetW3C      = $MockLogParameters.LogTargetW3C
                }

                Mock -CommandName Test-Path -MockWith { return $true }

                Mock -CommandName Get-WebConfiguration `
                    -MockWith { return $MockLogOutput }

                Mock -CommandName Get-WebConfigurationProperty `
                    -MockWith { return $MockLogOutput.logExtFileFlags }

                Mock -CommandName Set-WebConfigurationProperty

                Set-TargetResource @MockLogParameters

                It 'Should call all the mocks' {
                    Assert-MockCalled -CommandName Set-WebConfigurationProperty -Exactly 3
                }

            }

            Context 'LogPeriod is incorrect' {

                $MockLogOutput =
                @{
                    directory         = $MockLogParameters.LogPath
                    logExtFileFlags   = $MockLogParameters.LogFlags
                    period            = 'Daily'
                    truncateSize      = $MockLogParameters.LogTruncateSize
                    localTimeRollover = $MockLogParameters.LoglocalTimeRollover
                    logFormat         = $MockLogParameters.LogFormat
                    logTargetW3C      = $MockLogParameters.LogTargetW3C
                }

                Mock -CommandName Test-Path -MockWith { return $true }

                Mock -CommandName Get-WebConfiguration `
                    -MockWith { return $MockLogOutput }

                Mock -CommandName Get-WebConfigurationProperty `
                    -MockWith { return $MockLogOutput.logExtFileFlags }

                Mock -CommandName Set-WebConfigurationProperty

                Set-TargetResource @MockLogParameters

                It 'Should call all the mocks' {
                    Assert-MockCalled -CommandName Set-WebConfigurationProperty -Exactly 2
                }

            }

            Context 'LogTruncateSize is incorrect' {

                $MockLogOutput =
                @{
                    directory         = $MockLogParameters.LogPath
                    logExtFileFlags   = $MockLogParameters.LogFlags
                    period            = $MockLogParameters.LogPeriod
                    truncateSize      = '1048576'
                    localTimeRollover = $MockLogParameters.LoglocalTimeRollover
                    logFormat         = $MockLogParameters.LogFormat
                    logTargetW3C      = $MockLogParameters.LogTargetW3C
                }

                Mock -CommandName Test-Path -MockWith { return $true }

                Mock -CommandName Get-WebConfiguration `
                    -MockWith { return $MockLogOutput }

                Mock -CommandName Get-WebConfigurationProperty `
                    -MockWith { return $MockLogOutput.logExtFileFlags }

                Mock -CommandName Set-WebConfigurationProperty

                Set-TargetResource @MockLogParameters

                It 'Should call all the mocks' {
                    Assert-MockCalled -CommandName Set-WebConfigurationProperty -Exactly 3
                }

            }

            Context 'LogTruncateSize is too large for string comparison' -Verbose {

                $MockLogParameters = @{
                    LogPath              = $MockLogParameters.LogPath
                    LogFlags             = $MockLogParameters.LogFlags
                    LogPeriod            = $MockLogParameters.LogPeriod
                    LogTruncateSize      = '536870912'
                    LoglocalTimeRollover = $MockLogParameters.LoglocalTimeRollover
                    LogFormat            = $MockLogParameters.LogFormat
                    logTargetW3C         = $MockLogParameters.LogTargetW3C
                }
                $MockLogOutput =
                @{
                    directory         = $MockLogParameters.LogPath
                    logExtFileFlags   = $MockLogParameters.LogFlags
                    period            = $MockLogParameters.LogPeriod
                    truncateSize      = '1048576'
                    localTimeRollover = $MockLogParameters.LoglocalTimeRollover
                    logFormat         = $MockLogParameters.LogFormat
                    logTargetW3C      = $MockLogParameters.LogTargetW3C
                }

                Mock -CommandName Test-Path -MockWith { return $true }

                Mock -CommandName Get-WebConfiguration `
                    -MockWith { return $MockLogOutput }

                Mock -CommandName Get-WebConfigurationProperty `
                    -MockWith { return $MockLogOutput.logExtFileFlags }

                Mock -CommandName Set-WebConfigurationProperty

                Set-TargetResource @MockLogParameters

                It 'Should call all the mocks' {
                    Assert-MockCalled -CommandName Set-WebConfigurationProperty -Exactly 2
                }

                It 'Should have the correct LogTruncateSize' {
                    $result.truncateSize | Should Be $MockLogParameter.LogTruncateSize
                }

            }

            Context 'LoglocalTimeRollover is incorrect' {

                $MockLogOutput =
                @{
                    directory         = $MockLogParameters.LogPath
                    logExtFileFlags   = $MockLogParameters.LogFlags
                    period            = $MockLogParameters.LogPeriod
                    truncateSize      = $MockLogParameters.LogTruncateSize
                    localTimeRollover = 'False'
                    logFormat         = $MockLogParameters.LogFormat
                    logTargetW3C      = $MockLogParameters.LogTargetW3C
                }

                Mock -CommandName Test-Path -MockWith { return $true }

                Mock -CommandName Get-WebConfiguration `
                    -MockWith { return $MockLogOutput }

                Mock -CommandName Get-WebConfigurationProperty `
                    -MockWith { return $MockLogOutput.logExtFileFlags }

                Mock -CommandName Set-WebConfigurationProperty

                Set-TargetResource @MockLogParameters

                It 'Should call all the mocks' {
                    Assert-MockCalled -CommandName Set-WebConfigurationProperty -Exactly 2
                }

            }

            Context 'LogFormat is incorrect' {

                $MockLogOutput =
                @{
                    directory         = $MockLogParameters.LogPath
                    logExtFileFlags   = $MockLogParameters.LogFlags
                    period            = $MockLogParameters.LogPeriod
                    truncateSize      = $MockLogParameters.LogTruncateSize
                    localTimeRollover = $MockLogParameters.LoglocalTimeRollover
                    logFormat         = 'IIS'
                    logTargetW3C      = $MockLogParameters.LogTargetW3C
                }

                Mock -CommandName Test-Path -MockWith { return $true }

                Mock -CommandName Get-WebConfiguration `
                    -MockWith { return $MockLogOutput }

                Mock -CommandName Get-WebConfigurationProperty `
                    -MockWith { return $MockLogOutput.logExtFileFlags }

                Mock -CommandName Set-WebConfigurationProperty

                Set-TargetResource @MockLogParameters

                It 'Should call all the mocks' {
                    Assert-MockCalled -CommandName Set-WebConfigurationProperty -Exactly 2
                }

            }

            Context 'LogTargetW3C is incorrect' {

                $MockLogOutput =
                @{
                    directory         = $MockLogParameters.LogPath
                    logExtFileFlags   = $MockLogParameters.LogFlags
                    period            = $MockLogParameters.LogPeriod
                    truncateSize      = $MockLogParameters.LogTruncateSize
                    localTimeRollover = $MockLogParameters.LoglocalTimeRollover
                    logFormat         = $MockLogParameters.logFormat
                    logTargetW3C      = 'File'
                }

                Mock -CommandName Test-Path -MockWith { return $true }

                Mock -CommandName Get-WebConfiguration `
                    -MockWith { return $MockLogOutput }

                Mock -CommandName Get-WebConfigurationProperty `
                    -MockWith { return $MockLogOutput.logExtFileFlags }

                Mock -CommandName Set-WebConfigurationProperty

                Set-TargetResource @MockLogParameters

                It 'Should call all the mocks' {
                    Assert-MockCalled -CommandName Set-WebConfigurationProperty -Exactly 2
                }

            }

        }

        Describe "$script:dscResourceName\ConvertTo-CimLogCustomFields" {
            $MockLogCustomFields = @{
                LogFieldName = 'ClientEncoding'
                SourceName   = 'Accept-Encoding'
                SourceType   = 'RequestHeader'
            }

            Context 'Expected behavior' {
                $Result = ConvertTo-CimLogCustomFields -InputObject $MockLogCustomFields

                It 'Should return the LogFieldName' {
                    $Result.LogFieldName | Should Be $MockLogCustomFields.LogFieldName
                }

                It 'Should return the SourceName' {
                    $Result.SourceName | Should Be $MockLogCustomFields.SourceName
                }

                It 'Should return the LogFieldName' {
                    $Result.SourceType | Should Be $MockLogCustomFields.SourceType
                }
            }
        }

        Describe "$script:dscResourceName\Test-LogCustomField" {
            $MockCimLogCustomFields = @(
                New-CimInstance -ClassName MSFT_xLogCustomField `
                    -Namespace root/microsoft/Windows/DesiredStateConfiguration `
                    -Property @{
                        LogFieldName = 'ClientEncoding'
                        SourceName   = 'Accept-Encoding'
                        SourceType   = 'RequestHeader'
                    } `
                    -ClientOnly
            )

            $MockCimLogCustomFieldsEnsurePresentExplicitly = @(
                New-CimInstance -ClassName MSFT_xLogCustomField `
                    -Namespace root/microsoft/Windows/DesiredStateConfiguration `
                    -Property @{
                        LogFieldName = 'ClientEncoding'
                        SourceName   = 'Accept-Encoding'
                        SourceType   = 'RequestHeader'
                        Ensure       = 'Present'
                    } `
                    -ClientOnly
            )

            $MockCimLogCustomFieldsEnsureAbsent = @(
                New-CimInstance -ClassName MSFT_xLogCustomField `
                    -Namespace root/microsoft/Windows/DesiredStateConfiguration `
                    -Property @{
                        LogFieldName = 'ClientEncoding'
                        SourceName   = 'Accept-Encoding'
                        SourceType   = 'RequestHeader'
                        Ensure       = 'Absent'
                    } `
                    -ClientOnly
            )

            Context 'LogCustomField in desired state' {
                $MockDesiredLogCustomFields = @{
                    LogFieldName = 'ClientEncoding'
                    SourceName   = 'Accept-Encoding'
                    SourceType   = 'RequestHeader'
                }

                Mock -CommandName Get-WebConfigurationProperty -MockWith { return $MockDesiredLogCustomFields }

                It 'Should return True with default Ensure (Present)' {
                    Test-LogCustomField -LogCustomField $MockCimLogCustomFields | Should Be $True
                }

                It 'Should return True with explicit Ensure Present' {
                    Test-LogCustomField -LogCustomField $MockCimLogCustomFieldsEnsurePresentExplicitly | Should Be $True
                }

                It 'Should return True with Ensure Absent and Custom Field Absent' {
                    Mock -CommandName Get-WebConfigurationProperty -MockWith { return $null }
                    Test-LogCustomField -LogCustomField $MockCimLogCustomFieldsEnsureAbsent | Should Be $True
                }
            }

            Context 'LogCustomField not in desired state' {
                $MockWrongLogCustomFields = @{
                    LogFieldName = 'ClientEncoding'
                    SourceName   = 'WrongSourceName'
                    SourceType   = 'WrongSourceType'
                }

                Mock -CommandName Get-WebConfigurationProperty -MockWith { return $MockWrongLogCustomFields }

                It 'Should return False with default Ensure (Present)' {
                    Test-LogCustomField -LogCustomField $MockCimLogCustomFields | Should Be $False
                }

                It 'Should return False with explicit Ensure Present' {
                    Test-LogCustomField -LogCustomField $MockCimLogCustomFieldsEnsurePresentExplicitly | Should Be $False
                }

                It 'Should return False with Ensure Present and Custom Field Absent' {
                    Mock -CommandName Get-WebConfigurationProperty -MockWith { return $null }
                    Test-LogCustomField -LogCustomField $MockCimLogCustomFields | Should Be $False
                }
            }
        }

        Describe "$script:dscResourceName\Compare-LogFlags" {

            Context 'Returns false when LogFlags are incorrect' {

                $MockLogOutput =
                @{
                    directory         = $MockLogParameters.LogPath
                    logExtFileFlags   = @('Date', 'Time', 'ClientIP', 'UserName', 'ServerIP', 'Method', 'UriStem', 'UriQuery', 'HttpStatus', 'Win32Status', 'TimeTaken', 'ServerPort', 'UserAgent', 'Referer', 'HttpSubStatus')
                    logFormat         = 'W3C'
                    period            = $MockLogParameters.LogPeriod
                    truncateSize      = $MockLogParameters.LogTruncateSize
                    localTimeRollover = $MockLogParameters.LoglocalTimeRollover
                }

                Mock -CommandName Get-WebConfigurationProperty `
                    -MockWith { return $MockLogOutput.logExtFileFlags }

                $result = Compare-LogFlags $MockLogParameters.LogFlags

                It 'Should return false' {
                    $result | Should be $false
                }

            }

            Context 'Returns true when LogFlags are correct' {

                $MockLogOutput =
                @{
                    directory         = $MockLogParameters.LogPath
                    logExtFileFlags   = $MockLogParameters.LogFlags
                    logFormat         = 'W3C'
                    period            = $MockLogParameters.LogPeriod
                    truncateSize      = $MockLogParameters.LogTruncateSize
                    localTimeRollover = $MockLogParameters.LoglocalTimeRollover
                }

                Mock -CommandName Get-WebConfigurationProperty `
                    -MockWith { return $MockLogOutput.logExtFileFlags }

                $result = Compare-LogFlags $MockLogParameters.LogFlags

                It 'Should return true' {
                    $result | Should be $true
                }
            }

        }
        Describe "$script:dscResourceName\Set-LogCustomField" {

            $MockCimLogCustomFields = @(
                New-CimInstance -ClassName MSFT_xLogCustomField `
                    -Namespace root/microsoft/Windows/DesiredStateConfiguration `
                    -Property @{
                        LogFieldName = 'ClientEncoding'
                        SourceName   = 'Accept-Encoding'
                        SourceType   = 'RequestHeader'
                    } `
                    -ClientOnly
            )

            $MockCimLogCustomFieldsEnsurePresentExplicitly = @(
                New-CimInstance -ClassName MSFT_xLogCustomField `
                    -Namespace root/microsoft/Windows/DesiredStateConfiguration `
                    -Property @{
                        LogFieldName = 'ClientEncoding'
                        SourceName   = 'Accept-Encoding'
                        SourceType   = 'RequestHeader'
                        Ensure       = 'Present'
                    } `
                    -ClientOnly
            )

            $MockCimLogCustomFieldsEnsureAbsent = @(
                New-CimInstance -ClassName MSFT_xLogCustomField `
                    -Namespace root/microsoft/Windows/DesiredStateConfiguration `
                    -Property @{
                        LogFieldName = 'ClientEncoding'
                        SourceName   = 'Accept-Encoding'
                        SourceType   = 'RequestHeader'
                        Ensure       = 'Absent'
                    } `
                    -ClientOnly
            )

            Context 'Create new LogCustomField' {
                Mock -CommandName Set-WebConfigurationProperty
                Mock -CommandName Remove-WebConfigurationProperty

                It 'Should not throw an error with default Ensure (Present)' {
                    { Set-LogCustomField  -LogCustomField $MockCimLogCustomFields } | Should Not Throw
                }

                It 'Should not throw an error with explicit Ensure Present' {
                    { Set-LogCustomField  -LogCustomField $MockCimLogCustomFieldsEnsurePresentExplicitly } | Should Not Throw
                }

                It 'Should not throw an error with Ensure Absent' {
                    { Set-LogCustomField  -LogCustomField $MockCimLogCustomFieldsEnsureAbsent } | Should Not Throw
                }

                It 'Should call expected mocks' {
                    Assert-MockCalled -CommandName Set-WebConfigurationProperty -Exactly 2
                    Assert-MockCalled -CommandName Remove-WebConfigurationProperty -Exactly 1
                }
            }


            Context 'Modify existing LogCustomField' {
                Mock -CommandName Set-WebConfigurationProperty
                Mock -CommandName Remove-WebConfigurationProperty

                It 'Should not throw an error with default Ensure (Present)' {
                    { Set-LogCustomField  -LogCustomField $MockCimLogCustomFields } | Should Not Throw
                }

                It 'Should not throw an error with explicit Ensure Present' {
                    { Set-LogCustomField  -LogCustomField $MockCimLogCustomFieldsEnsurePresentExplicitly } | Should Not Throw
                }

                It 'Should not throw an error with Ensure Absent' {
                    { Set-LogCustomField  -LogCustomField $MockCimLogCustomFieldsEnsureAbsent } | Should Not Throw
                }

                It 'Should call expected mocks' {
                    Assert-MockCalled -CommandName Set-WebConfigurationProperty -Exactly 2
                    Assert-MockCalled -CommandName Remove-WebConfigurationProperty -Exactly 1
                }
            }
        }
    }
}

finally
{
    Invoke-TestCleanup
}
