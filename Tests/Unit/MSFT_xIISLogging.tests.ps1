$global:DSCModuleName = 'xWebAdministration'
$global:DSCResourceName = 'MSFT_xIisLogging'

#region HEADER
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
#endregion

# Begin Testing
try
{
    #region Pester Tests

    InModuleScope $DSCResourceName {
        
        $MockLogParameters =
            @{
                LogPath  = 'C:\MockLogLocation'
                LogFlags = @('Date','Time','ClientIP','UserName','ServerIP')
            }
                
        $MockLogOutput = 
            @{
                LogPath  = @([PSCustomObject]@{Value = '%SystemDrive%\inetpub\logs\LogFiles'})
                LogFlags = 'Date','Time','ClientIP','UserName','ServerIP','Method','UriStem','UriQuery','TimeTaken','HttpStatus','Win32Status','ServerPort','UserAgent','HttpSubStatus','Referer'
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
                
                Mock -CommandName Get-WebConfigurationProperty `
                    -ParameterFilter {$filter -eq '/system.applicationHost/sites/siteDefaults'} `
                    -MockWith {return $MockLogOutput.LogPath} 
                
                Mock -CommandName Get-WebConfigurationProperty `
                    -ParameterFilter {$filter -eq '/system.Applicationhost/Sites/SiteDefaults/logfile'} `
                    -MockWith {return $MockLogOutput.LogFlags}
                    
                $result = Get-TargetResource -LogPath $MockLogOutput.LogPath.Value
                
                It 'should return correct LogPath' {
                    $Result.LogPath | Should Be $MockLogOutput.LogPath.Value
                }
                
                It 'should return correct LogFlags' {
                    $Result.LogFlags | Should Be $MockLogOutput.LogFlags
                }
                
            }
        
        }

        Describe "$global:DSCResourceName\Test-TargetResource" { 
            Context 'All settings are correct'{

                $MockLogOutput = 
                    @{
                        LogPath  = @([PSCustomObject]@{Value = 'C:\MockLogLocation'})
                        LogFlags = 'Date','Time','ClientIP','UserName','ServerIP'
                    }
                

                Mock -CommandName Test-Path -MockWith {Return $true}
            
                Mock -CommandName Get-WebConfigurationProperty `
                    -ParameterFilter {$filter -eq '/system.applicationHost/sites/siteDefaults'} `
                    -MockWith {return $MockLogOutput.LogPath} 
                
                Mock -CommandName Get-WebConfigurationProperty `
                    -ParameterFilter {$filter -eq '/system.Applicationhost/Sites/SiteDefaults/logfile'} `
                    -MockWith {return $MockLogOutput.LogFlags}
                
                $result = Test-TargetResource @MockLogParameters

                It 'Should return true' { 
                    $result | Should be $true
                }
                      
            }
            Context 'All Settings are incorrect' {
            
                Mock -CommandName Test-Path -MockWith {Return $true}
            
                Mock -CommandName Get-WebConfigurationProperty `
                    -ParameterFilter {$filter -eq '/system.applicationHost/sites/siteDefaults'} `
                    -MockWith {return $MockLogOutput.LogPath} 
                
                Mock -CommandName Get-WebConfigurationProperty `
                    -ParameterFilter {$filter -eq '/system.Applicationhost/Sites/SiteDefaults/logfile'} `
                    -MockWith {return $MockLogOutput.LogFlags}
                
                $result = Test-TargetResource @MockLogParameters
                
                It 'Should return false' { 
                    $result | Should be $false
                }

            }

            Context 'Path does not exist' {

             $MockLogOutput = 
                    @{
                        LogPath  = @([PSCustomObject]@{Value = 'C:\MockLogLocation2'})
                        LogFlags = 'Date','Time','ClientIP','UserName','ServerIP'
                    }
                    
                Mock -CommandName Test-Path -MockWith {Return $false}
            
                Mock -CommandName Get-WebConfigurationProperty `
                    -ParameterFilter {$filter -eq '/system.applicationHost/sites/siteDefaults'} `
                    -MockWith {return $MockLogOutput.LogPath} 
                
                Mock -CommandName Get-WebConfigurationProperty `
                    -ParameterFilter {$filter -eq '/system.Applicationhost/Sites/SiteDefaults/logfile'} `
                    -MockWith {return $MockLogOutput.LogFlags}

                $ErrorId = 'ErrorWebsiteLogPath'
                $ErrorCategory = [System.Management.Automation.ErrorCategory]::InvalidResult
                $ErrorMessage = $LocalizedData.ErrorWebsiteLogPath
                $Exception = New-Object -TypeName System.InvalidOperationException -ArgumentList $ErrorMessage
                $ErrorRecord = New-Object -TypeName System.Management.Automation.ErrorRecord -ArgumentList $Exception, $ErrorId, $ErrorCategory, $null
               
                It 'Should throw when path does not exist' { 
                   { Test-TargetResource @MockLogParameters } | 
                   Should Throw $ErrorRecord
                }
            
            }

            Context 'LogPath is incorrect' {

                $MockLogOutput =
                    @{
                        LogPath  = @([PSCustomObject]@{Value = 'C:\MockLogLocation2'})
                        LogFlags = 'Date','Time','ClientIP','UserName','ServerIP'
                    }
                
            
                Mock -CommandName Test-Path -MockWith {Return $true}
            
                Mock -CommandName Get-WebConfigurationProperty `
                    -ParameterFilter {$filter -eq '/system.applicationHost/sites/siteDefaults'} `
                    -MockWith {return $MockLogOutput.LogPath} 
                
                Mock -CommandName Get-WebConfigurationProperty `
                    -ParameterFilter {$filter -eq '/system.Applicationhost/Sites/SiteDefaults/logfile'} `
                    -MockWith {return $MockLogOutput.LogFlags}
                
                $result = Test-TargetResource @MockLogParameters

                It 'Should return false' { 
                    $result | Should be $false
                }
            
            }

            Context 'LogFlags are incorrect' {

                $MockLogOutput = 
                    @{
                        LogPath  = @([PSCustomObject]@{Value = 'C:\MockLogLocation'})
                        LogFlags = 'Date','Time','ClientIP','UserName'
                    }
                
            
                Mock -CommandName Test-Path -MockWith {Return $true}
            
                Mock -CommandName Get-WebConfigurationProperty `
                    -ParameterFilter {$filter -eq '/system.applicationHost/sites/siteDefaults'} `
                    -MockWith {return $MockLogOutput.LogPath} 
                
                Mock -CommandName Get-WebConfigurationProperty `
                    -ParameterFilter {$filter -eq '/system.Applicationhost/Sites/SiteDefaults/logfile'} `
                    -MockWith {return $MockLogOutput.LogFlags}
                
                $result = Test-TargetResource @MockLogParameters

                It 'Should return false' { 
                    $result | Should be $false
                }

            }
       
        }

        Describe "$global:DSCResourceName\Set-TargetResource" {
        
            Context 'All Settings are incorrect' {
            
                Mock -CommandName Test-Path -MockWith {Return $true}
            
                Mock -CommandName Get-WebConfigurationProperty `
                    -ParameterFilter {$filter -eq '/system.applicationHost/sites/siteDefaults'} `
                    -MockWith {return $MockLogOutput.LogPath} 
                
                Mock -CommandName Get-WebConfigurationProperty `
                    -ParameterFilter {$filter -eq '/system.Applicationhost/Sites/SiteDefaults/logfile'} `
                    -MockWith {return $MockLogOutput.LogFlags}

                Mock -CommandName Set-WebConfigurationProperty
                
                $result = Set-TargetResource @MockLogParameters

                It 'should call all the mocks' {
                     Assert-MockCalled -CommandName Set-WebConfigurationProperty -Exactly 2
                     }

            }

             Context 'LogPath is incorrect' {

                $MockLogOutput = 
                    @{
                        LogPath  = @([PSCustomObject]@{Value = 'C:\MockLogLocation2'})
                        LogFlags = 'Date','Time','ClientIP','UserName','ServerIP'
                    }
                
            
                Mock -CommandName Test-Path -MockWith {Return $true}
            
                Mock -CommandName Get-WebConfigurationProperty `
                    -ParameterFilter {$filter -eq '/system.applicationHost/sites/siteDefaults'} `
                    -MockWith {return $MockLogOutput.LogPath} 
                
                Mock -CommandName Get-WebConfigurationProperty `
                    -ParameterFilter {$filter -eq '/system.Applicationhost/Sites/SiteDefaults/logfile'} `
                    -MockWith {return $MockLogOutput.LogFlags}

                Mock -CommandName Set-WebConfigurationProperty
                
                $result = Set-TargetResource @MockLogParameters

                It 'should call all the mocks' {
                     Assert-MockCalled -CommandName Set-WebConfigurationProperty -Exactly 1
                     }
            
            }

            Context 'LogFlags are incorrect' {

                $MockLogOutput = 
                    @{
                        LogPath  = @([PSCustomObject]@{Value = 'C:\MockLogLocation'})
                        LogFlags = 'Date','Time','ClientIP','UserName'
                    }
                
            
                Mock -CommandName Test-Path -MockWith {Return $true}
            
                Mock -CommandName Get-WebConfigurationProperty `
                    -ParameterFilter {$filter -eq '/system.applicationHost/sites/siteDefaults'} `
                    -MockWith {return $MockLogOutput.LogPath} 
                
                Mock -CommandName Get-WebConfigurationProperty `
                    -ParameterFilter {$filter -eq '/system.Applicationhost/Sites/SiteDefaults/logfile'} `
                    -MockWith {return $MockLogOutput.LogFlags}
                
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
                        LogPath  = @([PSCustomObject]@{Value = 'C:\MockLogLocation'})
                        LogFlags = 'Date','Time','ClientIP','UserName'
                    }

                Mock -CommandName Get-WebConfigurationProperty `
                    -ParameterFilter {$filter -eq '/system.Applicationhost/Sites/SiteDefaults/logfile'} `
                    -MockWith {return $MockLogOutput.LogFlags}
                
                $result = Compare-LogFlags $MockLogParameters.LogFlags

                It 'Should return false' { 
                    $result | Should be $false
                }
         
            }

            Context 'Returns true when LogFlags are correct' {

                 $MockLogParameters = @{
                    LogPath  = @([PSCustomObject]@{Value = '%SystemDrive%\inetpub\logs\LogFiles'})
                    LogFlags = 'Date','Time','ClientIP','UserName','ServerIP','Method','UriStem','UriQuery','TimeTaken','HttpStatus','Win32Status','ServerPort','UserAgent','HttpSubStatus','Referer'
                }
                                        
                Mock -CommandName Get-WebConfigurationProperty `
                    -ParameterFilter {$filter -eq '/system.Applicationhost/Sites/SiteDefaults/logfile'} `
                    -MockWith {return $MockLogOutput.LogFlags}
                
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