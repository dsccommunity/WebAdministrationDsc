$global:DSCModuleName = 'xWebAdministration'
$global:DSCResourceName = 'MSFT_xIisLogging'

# Unit Test Template Version: 1.1.0
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
    -TestType Unit 
#endregion HEADER

# Begin Testing
try
{
    #region Pester Tests

    InModuleScope $DSCResourceName {
        
        $MockLogParameters =
            @{
                LogPath              = 'C:\MockLogLocation'
                LogFlags             = 'Date','Time','ClientIP','UserName','ServerIP'
                LogPeriod            = 'Hourly'
                LogTruncateSize      = '2097152'
                LoglocalTimeRollover = $True
                LogFormat            = 'W3C'

            }
                
        $MockLogOutput = 
            @{
                directory         = '%SystemDrive%\inetpub\logs\LogFiles'
                logExtFileFlags   = 'Date','Time','ClientIP','UserName','ServerIP','Method','UriStem','UriQuery','HttpStatus','Win32Status','TimeTaken','ServerPort','UserAgent','Referer','HttpSubStatus'
                logFormat         = 'W3C'
                period            = 'Daily'
                truncateSize      = '1048576'
                localTimeRollover = 'False'
            }       

        Describe "$Global:DSCResourceName\Assert-Module" {
           
            Context 'WebAdminstration module is not installed' {
                Mock -ModuleName Helper -CommandName Get-Module -MockWith {
                    return $null
                }

                It 'should throw an error' {
                    { Assert-Module } | 
                    Should Throw
 
                }
 
            }
  
        }
        
        Describe "$global:DSCResourceName\Get-TargetResource" {
            Context 'Correct hashtable is returned' {
                
                Mock -CommandName Get-WebConfiguration `
                    -MockWith {return $MockLogOutput} 
                    
                $result = Get-TargetResource -LogPath $MockLogParameters.LogPath
               
                It 'should call Get-WebConfiguration once' {
                    Assert-MockCalled -CommandName Get-WebConfiguration -Exactly 1
                }
                
                It 'should return LogPath' {
                    $Result.LogPath | Should Be $MockLogOutput.directory
                }
                
                It 'should return LogFlags' {
                    $Result.LogFlags | Should Be $MockLogOutput.logExtFileFlags
                }

                It 'should return LogPeriod' {
                    $Result.LogPeriod | Should Be $MockLogOutput.period
                }

                It 'should return LogTruncateSize' {
                    $Result.LogTruncateSize | Should Be $MockLogOutput.truncateSize
                }

                It 'should return LoglocalTimeRollover' {
                    $Result.LoglocalTimeRollover | Should Be $MockLogOutput.localTimeRollover
                }
                
                It 'should return LogFormat' {
                    $Result.LogFormat | Should Be $MockLogOutput.logFormat
                }
                
            }
        
        }

        Describe "$global:DSCResourceName\Test-TargetResource" { 
            Context 'All settings are correct'{

                $MockLogOutput = 
                    @{
                        directory         = $MockLogParameters.LogPath
                        logExtFileFlags   = $MockLogParameters.LogFlags
                        period            = $MockLogParameters.LogPeriod     
                        truncateSize      = $MockLogParameters.LogTruncateSize
                        localTimeRollover = $MockLogParameters.LoglocalTimeRollover
                        logFormat         = $MockLogParameters.LogFormat
                    }
                

                Mock -CommandName Test-Path -MockWith {Return $true}
            
                Mock -CommandName Get-WebConfiguration `
                    -MockWith {return $MockLogOutput}
                
                Mock -CommandName Get-WebConfigurationProperty `
                    -MockWith {return $MockLogOutput.logExtFileFlags }
                
                $result = Test-TargetResource @MockLogParameters

                It 'Should return true' { 
                    $result | Should be $true
                }
                      
            }
            
            Context 'All Settings are incorrect' {
            
                Mock -CommandName Test-Path -MockWith {Return $true}
            
                Mock -CommandName Get-WebConfiguration `
                    -MockWith {return $MockLogOutput} 

                Mock -CommandName Get-WebConfigurationProperty `
                    -MockWith {return $MockLogOutput.logExtFileFlags }
                
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
                
            
                Mock -CommandName Test-Path -MockWith {Return $true}
            
                Mock -CommandName Get-WebConfiguration `
                    -MockWith {return $MockLogOutput}

                Mock -CommandName Get-WebConfigurationProperty `
                    -MockWith {return $MockLogOutput.logExtFileFlags }
                
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
                           
                Mock -CommandName Test-Path -MockWith {Return $true}
            
                Mock -CommandName Get-WebConfiguration `
                    -MockWith {return $MockLogOutput}
                
                Mock -CommandName Get-WebConfigurationProperty `
                    -MockWith {return $MockLogOutput.logExtFileFlags }
                
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
                            
                Mock -CommandName Test-Path -MockWith {Return $true}
            
                Mock -CommandName Get-WebConfiguration `
                    -MockWith {return $MockLogOutput}
                
                Mock -CommandName Get-WebConfigurationProperty `
                    -MockWith {return $MockLogOutput.logExtFileFlags }
                
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
            
                Mock -CommandName Test-Path -MockWith {Return $true}
            
                Mock -CommandName Get-WebConfiguration `
                    -MockWith {return $MockLogOutput}
                                
                Mock -CommandName Get-WebConfigurationProperty `
                    -MockWith {return $MockLogOutput.logExtFileFlags }
                
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
            
                Mock -CommandName Test-Path -MockWith {Return $true}
            
                Mock -CommandName Get-WebConfiguration `
                    -MockWith {return $MockLogOutput}
                                
                Mock -CommandName Get-WebConfigurationProperty `
                    -MockWith {return $MockLogOutput.logExtFileFlags }
                
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
            
                Mock -CommandName Test-Path -MockWith {Return $true}
            
                Mock -CommandName Get-WebConfiguration `
                    -MockWith {return $MockLogOutput}
                                
                Mock -CommandName Get-WebConfigurationProperty `
                    -MockWith {return $MockLogOutput.logExtFileFlags }
                
                $result = Test-TargetResource @MockLogParameters

                It 'Should return false' { 
                    $result | Should be $false
                }

            }
       
        }

        Describe "$global:DSCResourceName\Set-TargetResource" {
        
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

                Mock -CommandName Test-Path -MockWith {Return $true}
            
                Mock -CommandName Get-WebConfiguration `
                    -MockWith {return $MockLogOutput} 

                Mock -CommandName Get-WebConfigurationProperty `
                    -MockWith {return $MockLogOutput.logExtFileFlags} 
                
                Mock -CommandName Set-WebConfigurationProperty
                
                $result = Set-TargetResource @MockLogParameters

                It 'should call all the mocks' {
                     Assert-MockCalled -CommandName Set-WebConfigurationProperty -Exactly 8
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
            
                Mock -CommandName Test-Path -MockWith {Return $true}
            
                Mock -CommandName Get-WebConfiguration `
                    -MockWith {return $MockLogOutput}
                
                Mock -CommandName Get-WebConfigurationProperty `
                    -MockWith {return $MockLogOutput.logExtFileFlags }

                Mock -CommandName Set-WebConfigurationProperty
                
                $result = Set-TargetResource @MockLogParameters

                It 'should call all the mocks' {
                     Assert-MockCalled -CommandName Set-WebConfigurationProperty -Exactly 1
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
            
                Mock -CommandName Test-Path -MockWith {Return $true}
            
                Mock -CommandName Get-WebConfiguration `
                    -MockWith {return $MockLogOutput}
                
                Mock -CommandName Get-WebConfigurationProperty `
                    -MockWith {return $MockLogOutput.logExtFileFlags }
                
                Mock -CommandName Set-WebConfigurationProperty
                
                $result = Set-TargetResource @MockLogParameters

                It 'should call all the mocks' {
                     Assert-MockCalled -CommandName Set-WebConfigurationProperty -Exactly 2
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
                            
                Mock -CommandName Test-Path -MockWith {Return $true}
            
                Mock -CommandName Get-WebConfiguration `
                    -MockWith {return $MockLogOutput}

                Mock -CommandName Get-WebConfigurationProperty `
                    -MockWith {return $MockLogOutput.logExtFileFlags }
                
                Mock -CommandName Set-WebConfigurationProperty
                
                $result = Set-TargetResource @MockLogParameters

                It 'should call all the mocks' {
                     Assert-MockCalled -CommandName Set-WebConfigurationProperty -Exactly 1
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
            
                Mock -CommandName Test-Path -MockWith {Return $true}
            
                Mock -CommandName Get-WebConfiguration `
                    -MockWith {return $MockLogOutput}

                Mock -CommandName Get-WebConfigurationProperty `
                    -MockWith {return $MockLogOutput.logExtFileFlags }
                
                Mock -CommandName Set-WebConfigurationProperty
                
                $result = Set-TargetResource @MockLogParameters

                It 'should call all the mocks' {
                     Assert-MockCalled -CommandName Set-WebConfigurationProperty -Exactly 2
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
            
                Mock -CommandName Test-Path -MockWith {Return $true}
            
                Mock -CommandName Get-WebConfiguration `
                    -MockWith {return $MockLogOutput}
                
                Mock -CommandName Get-WebConfigurationProperty `
                    -MockWith {return $MockLogOutput.logExtFileFlags }
                
                Mock -CommandName Set-WebConfigurationProperty
                
                $result = Set-TargetResource @MockLogParameters

                It 'should call all the mocks' {
                     Assert-MockCalled -CommandName Set-WebConfigurationProperty -Exactly 1
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
            
                Mock -CommandName Test-Path -MockWith {Return $true}
            
                Mock -CommandName Get-WebConfiguration `
                    -MockWith {return $MockLogOutput}
                
                Mock -CommandName Get-WebConfigurationProperty `
                    -MockWith {return $MockLogOutput.logExtFileFlags }
                
                Mock -CommandName Set-WebConfigurationProperty
                
                $result = Set-TargetResource @MockLogParameters

                It 'should call all the mocks' {
                     Assert-MockCalled -CommandName Set-WebConfigurationProperty -Exactly 1
                }

            }
        
        }

        Describe "$Global:DSCResourceName\Compare-LogFlags" {
         
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
                    -MockWith {return $MockLogOutput.logExtFileFlags }
                
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
                    -MockWith {return $MockLogOutput.logExtFileFlags }
                
                $result = Compare-LogFlags $MockLogParameters.LogFlags

                It 'Should return true' { 
                    $result | Should be $true
                }        
         
            }
         
         }
    
     }

    #endregion
}

finally
{
    #region FOOTER
    Restore-TestEnvironment -TestEnvironment $TestEnvironment
    #endregion
}
