$script:DSCModuleName = 'xWebAdministration'
$script:DSCResourceName = 'MSFT_xIisLogging'

# Unit Test Template Version: 1.1.0
$script:moduleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
if ( (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests'))) -or `
     (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1'))) )
{
    & git @('clone','https://github.com/PowerShell/DscResource.Tests.git',(Join-Path -Path $script:moduleRoot -ChildPath '\DSCResource.Tests\'))
}

Import-Module (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1') -Force

Import-Module (Join-Path -Path $script:moduleRoot -ChildPath 'Tests\MockWebAdministrationWindowsFeature.psm1')

$TestEnvironment = Initialize-TestEnvironment `
    -DSCModuleName $script:DSCModuleName `
    -DSCResourceName $script:DSCResourceName `
    -TestType Unit
#endregion HEADER

# Begin Testing
try
{
    #region Pester Tests

    InModuleScope $script:DSCResourceName {

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
            LogFlags             = 'Date','Time','ClientIP','UserName','ServerIP'
            LogPeriod            = 'Hourly'
            LogTruncateSize      = '2097152'
            LoglocalTimeRollover = $true
            LogFormat            = 'W3C'
            LogCustomFields      = $MockCimLogCustomFields
        }

        $MockLogOutput =
            @{
                directory         = '%SystemDrive%\inetpub\logs\LogFiles'
                logExtFileFlags   = 'Date','Time','ClientIP','UserName','ServerIP','Method','UriStem','UriQuery','HttpStatus','Win32Status','TimeTaken','ServerPort','UserAgent','Referer','HttpSubStatus'
                logFormat         = 'W3C'
                period            = 'Daily'
                truncateSize      = '1048576'
                localTimeRollover = 'False'
                customFields      = @{Collection = @($MockLogCustomFields)}
            }

        Describe "$script:DSCResourceName\Assert-Module" {

            Context 'WebAdminstration module is not installed' {
                Mock -ModuleName Helper -CommandName Get-Module -MockWith {
                    return $null
                }

                It 'Should throw an error' {
                    { Assert-Module } |
                    Should Throw

                }

            }

        }

        Describe "$script:DSCResourceName\Get-TargetResource" {

            Context 'Correct hashtable is returned' {

                Mock -CommandName Get-WebConfiguration `
                    -MockWith { return $MockLogOutput }

                Mock -CommandName Assert-Module -MockWith {}

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
                    $result.LogFlags | Should Be $MockLogOutput.logExtFileFlags
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

                It 'Should return LogCustomFields' {
                    $result.LogCustomFields.LogFieldName | Should Be $MockLogCustomFields.LogFieldName
                    $result.LogCustomFields.SourceName   | Should Be $MockLogCustomFields.SourceName
                    $result.LogCustomFields.SourceType   | Should Be $MockLogCustomFields.SourceType
                }
            }

        }

        Describe "$script:DSCResourceName\Test-TargetResource" {

            Mock -CommandName Assert-Module -MockWith {}

            Context 'All settings are correct'{

                $MockLogOutput =
                @{
                    directory         = $MockLogParameters.LogPath
                    logExtFileFlags   = $MockLogParameters.LogFlags
                    period            = $MockLogParameters.LogPeriod
                    truncateSize      = $MockLogParameters.LogTruncateSize
                    localTimeRollover = $MockLogParameters.LoglocalTimeRollover
                    logFormat         = $MockLogParameters.LogFormat
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
                        logExtFileFlags   = 'Date','Time','ClientIP','UserName','ServerIP','Method','UriStem','UriQuery','HttpStatus','Win32Status','TimeTaken','ServerPort','UserAgent','Referer','HttpSubStatus'
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

        Describe "$script:DSCResourceName\Set-TargetResource" {

            Mock -CommandName Assert-Module -MockWith {}

            Context 'All Settings are incorrect' {

                $MockLogOutput =
                    @{
                        directory         = '%SystemDrive%\inetpub\logs\LogFiles'
                        logExtFileFlags   = 'Date','Time','ClientIP','UserName','ServerIP','Method','UriStem','UriQuery','HttpStatus','Win32Status','TimeTaken','ServerPort','UserAgent','Referer','HttpSubStatus'
                        logFormat         = 'IIS'
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
                     Assert-MockCalled -CommandName Set-WebConfigurationProperty -Exactly 9
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
                        logExtFileFlags   = 'Date','Time','ClientIP','UserName','ServerIP','Method','UriStem','UriQuery','HttpStatus','Win32Status','TimeTaken','ServerPort','UserAgent','Referer','HttpSubStatus'
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
                }
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

    Describe "$script:DSCResourceName\ConvertTo-CimLogCustomFields"{
            $MockLogCustomFields = @{
                LogFieldName = 'ClientEncoding'
                SourceName   = 'Accept-Encoding'
                SourceType   = 'RequestHeader'
            }

             Context 'Expected behavior'{
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

    Describe "$script:DSCResourceName\Test-LogCustomField" {
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

            Context 'LogCustomField in desired state' {
                $MockDesiredLogCustomFields = @{
                    LogFieldName = 'ClientEncoding'
                    SourceName   = 'Accept-Encoding'
                    SourceType   = 'RequestHeader'
                }

                Mock -CommandName Get-WebConfigurationProperty -MockWith { return $MockDesiredLogCustomFields }

                It 'Should return True' {
                    Test-LogCustomField -LogCustomField $MockCimLogCustomFields | Should Be $True
                }
            }

            Context 'LogCustomField not in desired state' {
                $MockWrongLogCustomFields = @{
                    LogFieldName = 'ClientEncoding'
                    SourceName   = 'WrongSourceName'
                    SourceType   = 'WrongSourceType'
                }

                Mock -CommandName Get-WebConfigurationProperty -MockWith { return $MockWrongLogCustomFields }

                It 'Should return False' {
                    Test-LogCustomField -LogCustomField $MockCimLogCustomFields | Should Be $False
                }
            }

            Context 'LogCustomField not present'{
                Mock -CommandName Get-WebConfigurationProperty -MockWith { return $false }

                It 'Should return False' {
                    Test-LogCustomField -LogCustomField $MockCimLogCustomFields | Should Be $False
                }
            }
        }

        Describe "$script:DSCResourceName\Compare-LogFlags" {

            Context 'Returns false when LogFlags are incorrect' {

                $MockLogOutput =
                    @{
                        directory         = $MockLogParameters.LogPath
                        logExtFileFlags   = @('Date','Time','ClientIP','UserName','ServerIP','Method','UriStem','UriQuery','HttpStatus','Win32Status','TimeTaken','ServerPort','UserAgent','Referer','HttpSubStatus')
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
    Describe "$script:DSCResourceName\Set-LogCustomField" {

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

            Context 'Create new LogCustomField' {
                Mock -CommandName Set-WebConfigurationProperty

                It 'Should not throw an error' {
                    { Set-LogCustomField  -LogCustomField $MockCimLogCustomFields } | Should Not Throw
                }

                It 'Should call should call expected mocks' {
                    Assert-MockCalled -CommandName Set-WebConfigurationProperty -Exactly 1
                }
            }


            Context 'Modify existing LogCustomField' {
                Mock -CommandName Set-WebConfigurationProperty

                It 'Should not throw an error' {
                    { Set-LogCustomField -LogCustomField $MockCimLogCustomFields } | Should Not Throw
                }

                It 'Should call should call expected mocks' {
                    Assert-MockCalled -CommandName Set-WebConfigurationProperty -Exactly 1
                }
            }
        }
    }

    #endregion
}

finally
{
    Restore-TestEnvironment -TestEnvironment $TestEnvironment
}
