$global:DSCModuleName = 'xWebAdministration'
$global:DSCResourceName = 'MSFT_xWebAppPool'

#region HEADER
if ( (-not (Test-Path -Path '.\DSCResource.Tests\')) -or `
     (-not (Test-Path -Path '.\DSCResource.Tests\TestHelper.psm1')) )
{
    & git @('clone','https://github.com/PowerShell/DscResource.Tests.git')
}
else
{
    & git @('-C',(Join-Path -Path (Get-Location) -ChildPath '\DSCResource.Tests\'),'pull')
}
Import-Module .\DSCResource.Tests\TestHelper.psm1 -Force
$TestEnvironment = Initialize-TestEnvironment `
    -DSCModuleName $Global:DSCModuleName `
    -DSCResourceName $Global:DSCResourceName `
    -TestType Unit
#endregion
try
{
    #region Pester Tests

    # The InModuleScope command allows you to perform white-box unit testing on the internal
    # (non-exported) code of a Script Module.
    InModuleScope $Global:DSCResourceName {
        #region Function Get-TargetResource
        Describe "$($Global:DSCResourceName)\Get-TargetResource" {
            [xml] $PoolCfg = '
            <add name="DefaultAppPool"
                queueLength="1000"
                autoStart="true"
                enable32BitAppOnWin64="false"
                managedRuntimeVersion="v4.0"
                managedRuntimeLoader="webengine4.dll"
                enableConfigurationOverride="true"
                managedPipelineMode="Integrated"
                CLRConfigFile=""
                passAnonymousToken="true"
                startMode="OnDemand">
                <processModel
                    identityType="SpecificUser"
                    userName="username"
                    password="password"
                    loadUserProfile="true"
                    setProfileEnvironment="true"
                    logonType="LogonBatch"
                    manualGroupMembership="false"
                    idleTimeout="00:20:00"
                    idleTimeoutAction="Terminate"
                    maxProcesses="1"
                    shutdownTimeLimit="00:01:30"
                    startupTimeLimit="00:01:30"
                    pingingEnabled="true"
                    pingInterval="00:00:30"
                    pingResponseTime="00:01:30"
                    logEventOnProcessModel="IdleTimeout"/>
                <recycling
                    disallowOverlappingRotation="false"
                    disallowRotationOnConfigChange="false"
                    logEventOnRecycle="Time, Memory, PrivateMemory">
                    <periodicRestart
                        memory="0"
                        privateMemory="0"
                        requests="0"
                        time="1.05:00:00">
                        <schedule>
                            <add value = "00:00:00" />
                            <add value = "01:00:00" />
                        </schedule>
                    </periodicRestart>
                </recycling>
                <failure
                    loadBalancerCapabilities="HttpLevel"
                    orphanWorkerProcess="false"
                    orphanActionExe=""
                    orphanActionParams=""
                    rapidFailProtection="true"
                    rapidFailProtectionInterval="00:05:00"
                    rapidFailProtectionMaxCrashes="5"
                    autoShutdownExe=""
                    autoShutdownParams=""/>
                <cpu limit="0"
                    action="NoAction"
                    resetInterval="00:05:00"
                    smpAffinitized="false"
                    smpProcessorAffinityMask="4294967295"
                    smpProcessorAffinityMask2="4294967295"
                    processorGroup="0"
                    numaNodeAssignment="MostAvailableMemory"
                    numaNodeAffinityMode="Soft" />
            </add>'

            Context 'AppPool is not found' {
                It 'Should return Enusre = "Absent" ' {
                    Mock Assert-Module
                    Mock Invoke-AppCmd
                    $result = Get-TargetResource -Name 'NonExistantPool'
                    $result.Ensure | Should Be 'Absent'
                }
            }
            Context 'Multiple App Pools contain the same name' {
                Mock Assert-Module
                Mock Invoke-AppCmd {return @{Count = 2}}

                $Name = 'MultiplePools'

                $errorId = 'AppPoolDiscoveryFailure';
                $errorCategory = [System.Management.Automation.ErrorCategory]::InvalidResult
                $errorMessage = $($LocalizedData.AppPoolDiscoveryFailure) -f ${Name}
                $exception = New-Object System.InvalidOperationException $errorMessage
                $errorRecord = New-Object System.Management.Automation.ErrorRecord $exception, $errorId, $errorCategory, $null

                It 'should throw the right error record' {
                    { Get-TargetResource -Name $Name } | Should Throw $ErrorRecord
                }
            }
            Context 'App Pool is discovered' {
                Mock Assert-Module
                Mock Invoke-AppCmd {return @{Count = 1}}
                Mock Invoke-AppCmd {return 'Started' } -ParameterFilter {$Arguments.Contains('/text:state')}
                Mock Invoke-AppCmd {return $PoolCfg} -ParameterFilter {$Arguments.Contains('/config:*')}

                $AppPoolPassword = $PoolCfg.add.processModel.password | ConvertTo-SecureString -AsPlainText -Force
                $AppPoolCred = New-Object `
                    -TypeName System.Management.Automation.PSCredential `
                    -ArgumentList $($PoolCfg.add.processModel.userName, $AppPoolPassword)

                $result = Get-TargetResource -Name 'DefaultAppPool'

                It 'Should return the correct values' {
                    $result.Name                                       | Should Be 'DefaultAppPool'
                    $result.Ensure                                     | Should Be 'Present'
                    $result.State                                      | Should Be 'Started'
                    $result.autoStart                                  | Should Be $PoolCfg.add.autoStart
                    $result.managedRuntimeVersion                      | Should Be $PoolCfg.add.managedRuntimeVersion
                    $result.managedPipelineMode                        | Should Be $PoolCfg.add.managedPipelineMode
                    $result.startMode                                  | Should Be $PoolCfg.add.startMode
                    $result.identityType                               | Should Be $PoolCfg.add.processModel.identityType
                    $result.Credential.userName                        | Should Be $PoolCfg.add.processModel.userName
                    $result.Credential.GetNetworkCredential().Password | Should Be $PoolCfg.add.processModel.password
                    $result.loadUserProfile                            | Should Be $PoolCfg.add.processModel.loadUserProfile
                    $result.queueLength                                | Should Be $PoolCfg.add.queueLength
                    $result.enable32BitAppOnWin64                      | Should Be $PoolCfg.add.enable32BitAppOnWin64
                    $result.managedRuntimeLoader                       | Should Be $PoolCfg.add.managedRuntimeLoader
                    $result.enableConfigurationOverride                | Should Be $PoolCfg.add.enableConfigurationOverride
                    $result.CLRConfigFile                              | Should Be $PoolCfg.add.CLRConfigFile
                    $result.passAnonymousToken                         | Should Be $PoolCfg.add.passAnonymousToken
                    $result.logonType                                  | Should Be $PoolCfg.add.processModel.logonType
                    $result.manualGroupMembership                      | Should Be $PoolCfg.add.processModel.manualGroupMembership
                    $result.idleTimeout                                | Should Be $PoolCfg.add.processModel.idleTimeout
                    $result.maxProcesses                               | Should Be $PoolCfg.add.processModel.maxProcesses
                    $result.shutdownTimeLimit                          | Should Be $PoolCfg.add.processModel.shutdownTimeLimit
                    $result.startupTimeLimit                           | Should Be $PoolCfg.add.processModel.startupTimeLimit
                    $result.pingingEnabled                             | Should Be $PoolCfg.add.processModel.pingingEnabled
                    $result.pingInterval                               | Should Be $PoolCfg.add.processModel.pingInterval
                    $result.pingResponseTime                           | Should Be $PoolCfg.add.processModel.pingResponseTime
                    $result.disallowOverlappingRotation                | Should Be $PoolCfg.add.recycling.disallowOverlappingRotation
                    $result.disallowRotationOnConfigChange             | Should Be $PoolCfg.add.recycling.disallowRotationOnConfigChange
                    $result.logEventOnRecycle                          | Should Be $PoolCfg.add.recycling.logEventOnRecycle
                    $result.restartMemoryLimit                         | Should Be $PoolCfg.add.recycling.periodicRestart.memory
                    $result.restartPrivateMemoryLimit                  | Should Be $PoolCfg.add.recycling.periodicRestart.privateMemory
                    $result.restartRequestsLimit                       | Should Be $PoolCfg.add.recycling.periodicRestart.requests
                    $result.restartTimeLimit                           | Should Be $PoolCfg.add.recycling.periodicRestart.time
                    $result.restartSchedule                            | Should Be @($PoolCfg.add.recycling.periodicRestart.schedule.add.value)
                    $result.loadBalancerCapabilities                   | Should Be $PoolCfg.add.failure.loadBalancerCapabilities
                    $result.orphanWorkerProcess                        | Should Be $PoolCfg.add.failure.orphanWorkerProcess
                    $result.orphanActionExe                            | Should Be $PoolCfg.add.failure.orphanActionExe
                    $result.orphanActionParams                         | Should Be $PoolCfg.add.failure.orphanActionParams
                    $result.rapidFailProtection                        | Should Be $PoolCfg.add.failure.rapidFailProtection
                    $result.rapidFailProtectionInterval                | Should Be $PoolCfg.add.failure.rapidFailProtectionInterval
                    $result.rapidFailProtectionMaxCrashes              | Should Be $PoolCfg.add.failure.rapidFailProtectionMaxCrashes
                    $result.autoShutdownExe                            | Should Be $PoolCfg.add.failure.autoShutdownExe
                    $result.autoShutdownParams                         | Should Be $PoolCfg.add.failure.autoShutdownParams
                    $result.cpuLimit                                   | Should Be $PoolCfg.add.cpu.limit
                    $result.cpuAction                                  | Should Be $PoolCfg.add.cpu.action
                    $result.cpuResetInterval                           | Should Be $PoolCfg.add.cpu.resetInterval
                    $result.cpuSmpAffinitized                          | Should Be $PoolCfg.add.cpu.smpAffinitized
                    $result.cpuSmpProcessorAffinityMask                | Should Be $PoolCfg.add.cpu.smpProcessorAffinityMask
                    $result.cpuSmpProcessorAffinityMask2               | Should Be $PoolCfg.add.cpu.smpProcessorAffinityMask2
                }
            }
        }
        #endregion

        #region Function Test-TargetResource
        Describe "$($Global:DSCResourceName)\Test-TargetResource" {
            [xml] $PoolCfg = '
            <add name="DefaultAppPool"
                queueLength="1000"
                autoStart="true"
                enable32BitAppOnWin64="false"
                managedRuntimeVersion="v4.0"
                managedRuntimeLoader="webengine4.dll"
                enableConfigurationOverride="true"
                managedPipelineMode="Integrated"
                CLRConfigFile=""
                passAnonymousToken="true"
                startMode="OnDemand">
                <processModel
                    identityType="ApplicationPoolIdentity"
                    userName=""
                    password=""
                    loadUserProfile="true"
                    setProfileEnvironment="true"
                    logonType="LogonBatch"
                    manualGroupMembership="false"
                    idleTimeout="00:20:00"
                    idleTimeoutAction="Terminate"
                    maxProcesses="1"
                    shutdownTimeLimit="00:01:30"
                    startupTimeLimit="00:01:30"
                    pingingEnabled="true"
                    pingInterval="00:00:30"
                    pingResponseTime="00:01:30"
                    logEventOnProcessModel="IdleTimeout"/>
                <recycling
                    disallowOverlappingRotation="false"
                    disallowRotationOnConfigChange="false"
                    logEventOnRecycle="Time, Memory, PrivateMemory">
                    <periodicRestart
                        memory="0"
                        privateMemory="0"
                        requests="0"
                        time="1.05:00:00">
                        <schedule>
                        </schedule>
                    </periodicRestart>
                </recycling>
                <failure
                    loadBalancerCapabilities="HttpLevel"
                    orphanWorkerProcess="false"
                    orphanActionExe=""
                    orphanActionParams=""
                    rapidFailProtection="true"
                    rapidFailProtectionInterval="00:05:00"
                    rapidFailProtectionMaxCrashes="5"
                    autoShutdownExe=""
                    autoShutdownParams=""/>
                <cpu limit="0"
                    action="NoAction"
                    resetInterval="00:05:00"
                    smpAffinitized="false"
                    smpProcessorAffinityMask="4294967295"
                    smpProcessorAffinityMask2="4294967295"
                    processorGroup="0"
                    numaNodeAssignment="MostAvailableMemory"
                    numaNodeAffinityMode="Soft" />
            </add>'

            $Name = 'DefaultAppPool'

            Context 'App Pool is not Present and is supposed to be' {
                Mock Assert-Module
                Mock Invoke-AppCmd {}
                $result = Test-TargetResource -Name $Name -Verbose 4>&1

                It 'should return the correct verbose message' {
                    $result[0] | Should be $($LocalizedData['TestEnsureState'] -f $Name)
                }
                It 'Should return false' {
                    $result[1] | Should be $false
                }
            }

            Context 'State is not the same' {
                Mock Assert-Module
                Mock Invoke-AppCmd {return @{Count = 1}}
                Mock Invoke-AppCmd {return 'Started' } -ParameterFilter {$Arguments.Contains('/text:state')}
                Mock Invoke-AppCmd {return $PoolCfg} -ParameterFilter {$Arguments.Contains('/config:*')}

                $result = Test-TargetResource -Name $Name -State 'Stopped' -Verbose 4>&1

                It 'should return the correct verbose message' {
                    $result[0] | Should be $($LocalizedData['TestStateConfig'] -f $Name)
                }
                It 'Should return false' {
                    $result[1] | Should be $false
                }
            }

            Context 'autoStart is not the same' {
                Mock Assert-Module
                Mock Invoke-AppCmd {return @{Count = 1}}
                Mock Invoke-AppCmd {return 'Started' } -ParameterFilter {$Arguments.Contains('/text:state')}
                Mock Invoke-AppCmd {return $PoolCfg} -ParameterFilter {$Arguments.Contains('/config:*')}

                $result = Test-TargetResource -Name $Name -autoStart 'false' -Verbose 4>&1

                It 'should return the correct verbose message' {
                    $result[0] | Should be $($LocalizedData['TestautoStartConfig'] -f $Name)
                }
                It 'Should return false' {
                    $result[1] | Should be $false
                }
            }

            Context 'managedRuntimeVersion is not the same' {
                Mock Assert-Module
                Mock Invoke-AppCmd {return @{Count = 1}}
                Mock Invoke-AppCmd {return 'Started' } -ParameterFilter {$Arguments.Contains('/text:state')}
                Mock Invoke-AppCmd {return $PoolCfg} -ParameterFilter {$Arguments.Contains('/config:*')}

                $managedRuntimeVersion = 'v2.0'
                $result = Test-TargetResource -Name $Name -managedRuntimeVersion 'v2.0' -Verbose 4>&1

                It 'should return the correct verbose message' {
                    $result[0] | Should be $($LocalizedData['TestmanagedRuntimeVersionConfig'] -f $Name)
                }
                It 'Should return false' {
                    $result[1] | Should be $false
                }
            }

            Context 'managedPipelineMode is not the same' {
                Mock Assert-Module
                Mock Invoke-AppCmd {return @{Count = 1}}
                Mock Invoke-AppCmd {return 'Started' } -ParameterFilter {$Arguments.Contains('/text:state')}
                Mock Invoke-AppCmd {return $PoolCfg} -ParameterFilter {$Arguments.Contains('/config:*')}

                $managedPipelineMode = 'Classic'
                $result = Test-TargetResource -Name $Name -managedPipelineMode $managedPipelineMode -Verbose 4>&1

                It 'should return the correct verbose message' {
                    $result[0] | Should be $($LocalizedData['TestmanagedPipelineModeConfig'] -f $Name)
                }
                It 'Should return false' {
                    $result[1] | Should be $false
                }
            }

            Context 'startMode is not the same' {
                Mock Assert-Module
                Mock Invoke-AppCmd {return @{Count = 1}}
                Mock Invoke-AppCmd {return 'Started' } -ParameterFilter {$Arguments.Contains('/text:state')}
                Mock Invoke-AppCmd {return $PoolCfg} -ParameterFilter {$Arguments.Contains('/config:*')}

                $startMode = 'AlwaysRunning'
                $result = Test-TargetResource -Name $Name -startMode $startMode -Verbose 4>&1

                It 'should return the correct verbose message' {
                    $result[0] | Should be $($LocalizedData['TeststartModeConfig'] -f $Name)
                }
                It 'Should return false' {
                    $result[1] | Should be $false
                }
            }

            Context 'identityType is not the same' {
                Mock Assert-Module
                Mock Invoke-AppCmd {return @{Count = 1}}
                Mock Invoke-AppCmd {return 'Started' } -ParameterFilter {$Arguments.Contains('/text:state')}
                Mock Invoke-AppCmd {return $PoolCfg} -ParameterFilter {$Arguments.Contains('/config:*')}

                $identityType = 'NetworkService'
                $result = Test-TargetResource -Name $Name -identityType 'NetworkService' -Verbose 4>&1

                It 'should return the correct verbose message' {
                    $result[0] | Should be $($LocalizedData['TestidentityTypeConfig'] -f $Name)
                }
                It 'Should return false' {
                    $result[1] | Should be $false
                }
            }

            Context 'userName is not the same' {
                $UserNameTest = $PoolCfg.Clone()
                $UserNameTest.add.processModel.identityType = 'SpecificUser'
                $UserNameTest.add.processModel.userName = 'username'
                $UserNameTest.add.processModel.password = 'password'

                Mock Assert-Module
                Mock Invoke-AppCmd {return @{Count = 1}}
                Mock Invoke-AppCmd {return 'Started' } -ParameterFilter {$Arguments.Contains('/text:state')}
                Mock Invoke-AppCmd {return $UserNameTest} -ParameterFilter {$Arguments.Contains('/config:*')}

                $AppPoolPassword = 'NotPassword' | ConvertTo-SecureString -AsPlainText -Force
                $AppPoolCred = New-Object `
                    -TypeName System.Management.Automation.PSCredential `
                    -ArgumentList $('NotUserName', $AppPoolPassword)

                $result = Test-TargetResource -Name $Name -IdentityType 'SpecificUser' -Credential $AppPoolCred -Verbose 4>&1

                It 'should return the correct verbose message' {
                    $result[0] | Should be $($LocalizedData['TestuserNameConfig'] -f $Name)
                }
                It 'Should return false' {
                    $result[1] | Should be $false
                }
            }

            Context 'Password is not the same' {
                $UserNameTest = $PoolCfg.Clone()
                $UserNameTest.add.processModel.identityType = 'SpecificUser'
                $UserNameTest.add.processModel.userName = 'username'
                $UserNameTest.add.processModel.password = 'password'
                Mock Assert-Module
                Mock Invoke-AppCmd {return @{Count = 1}}
                Mock Invoke-AppCmd {return 'Started' } -ParameterFilter {$Arguments.Contains('/text:state')}
                Mock Invoke-AppCmd {return $UserNameTest} -ParameterFilter {$Arguments.Contains('/config:*')}

                $AppPoolPassword = 'NotPassword' | ConvertTo-SecureString -AsPlainText -Force
                $AppPoolCred = New-Object `
                    -TypeName System.Management.Automation.PSCredential `
                    -ArgumentList $('username', $AppPoolPassword)

                $result = Test-TargetResource -Name $Name -IdentityType 'SpecificUser' -Credential $AppPoolCred -Verbose 4>&1

                It 'should return the correct verbose message' {
                    $result[0] | Should be $($LocalizedData['TestPasswordConfig'] -f $Name)
                }
                It 'Should return false' {
                    $result[1] | Should be $false
                }
            }

            Context 'LoadUserProfile is not the same' {
                Mock Assert-Module
                Mock Invoke-AppCmd {return @{Count = 1}}
                Mock Invoke-AppCmd {return 'Started' } -ParameterFilter {$Arguments.Contains('/text:state')}
                Mock Invoke-AppCmd {return $PoolCfg} -ParameterFilter {$Arguments.Contains('/config:*')}

                $result = Test-TargetResource -Name $Name -LoadUserProfile 'false' -Verbose 4>&1

                It 'should return the correct verbose message' {
                    $result[0] | Should be $($LocalizedData['TestLoadUserProfileConfig'] -f $Name)
                }
                It 'Should return false' {
                    $result[1] | Should be $false
                }
            }

            Context 'queueLength is not the same' {
                Mock Assert-Module
                Mock Invoke-AppCmd {return @{Count = 1}}
                Mock Invoke-AppCmd {return 'Started' } -ParameterFilter {$Arguments.Contains('/text:state')}
                Mock Invoke-AppCmd {return $PoolCfg} -ParameterFilter {$Arguments.Contains('/config:*')}

                $result = Test-TargetResource -Name $Name -queueLength '1' -Verbose 4>&1

                It 'should return the correct verbose message' {
                    $result[0] | Should be $($LocalizedData['TestqueueLengthConfig'] -f $Name)
                }
                It 'Should return false' {
                    $result[1] | Should be $false
                }
            }

            Context 'enable32BitAppOnWin64 is not the same' {
                Mock Assert-Module
                Mock Invoke-AppCmd {return @{Count = 1}}
                Mock Invoke-AppCmd {return 'Started' } -ParameterFilter {$Arguments.Contains('/text:state')}
                Mock Invoke-AppCmd {return $PoolCfg} -ParameterFilter {$Arguments.Contains('/config:*')}

                $result = Test-TargetResource -Name $Name -enable32BitAppOnWin64 'true' -Verbose 4>&1

                It 'should return the correct verbose message' {
                    $result[0] | Should be $($LocalizedData['Testenable32BitAppOnWin64Config'] -f $Name)
                }
                It 'Should return false' {
                    $result[1] | Should be $false
                }
            }

            Context 'managedRuntimeLoader is not the same' {
                Mock Assert-Module
                Mock Invoke-AppCmd {return @{Count = 1}}
                Mock Invoke-AppCmd {return 'Started' } -ParameterFilter {$Arguments.Contains('/text:state')}
                Mock Invoke-AppCmd {return $PoolCfg} -ParameterFilter {$Arguments.Contains('/config:*')}

                $result = Test-TargetResource -Name $Name -managedRuntimeLoader 'true' -Verbose 4>&1

                It 'should return the correct verbose message' {
                    $result[0] | Should be $($LocalizedData['TestmanagedRuntimeLoaderConfig'] -f $Name)
                }
                It 'Should return false' {
                    $result[1] | Should be $false
                }
            }

            Context 'enableConfigurationOverride is not the same' {
                Mock Assert-Module
                Mock Invoke-AppCmd {return @{Count = 1}}
                Mock Invoke-AppCmd {return 'Started' } -ParameterFilter {$Arguments.Contains('/text:state')}
                Mock Invoke-AppCmd {return $PoolCfg} -ParameterFilter {$Arguments.Contains('/config:*')}

                $result = Test-TargetResource -Name $Name -enableConfigurationOverride 'false' -Verbose 4>&1

                It 'should return the correct verbose message' {
                    $result[0] | Should be $($LocalizedData['TestenableConfigurationOverrideConfig'] -f $Name)
                }
                It 'Should return false' {
                    $result[1] | Should be $false
                }
            }

            Context 'enableConfigurationOverride is not the same' {
                Mock Assert-Module
                Mock Invoke-AppCmd {return @{Count = 1}}
                Mock Invoke-AppCmd {return 'Started' } -ParameterFilter {$Arguments.Contains('/text:state')}
                Mock Invoke-AppCmd {return $PoolCfg} -ParameterFilter {$Arguments.Contains('/config:*')}

                $result = Test-TargetResource -Name $Name -enableConfigurationOverride 'false' -Verbose 4>&1

                It 'should return the correct verbose message' {
                    $result[0] | Should be $($LocalizedData['TestenableConfigurationOverrideConfig'] -f $Name)
                }
                It 'Should return false' {
                    $result[1] | Should be $false
                }
            }

            Context 'CLRConfigFile is not the same' {
                Mock Assert-Module
                Mock Invoke-AppCmd {return @{Count = 1}}
                Mock Invoke-AppCmd {return 'Started' } -ParameterFilter {$Arguments.Contains('/text:state')}
                Mock Invoke-AppCmd {return $PoolCfg} -ParameterFilter {$Arguments.Contains('/config:*')}

                $result = Test-TargetResource -Name $Name -CLRConfigFile 'false' -Verbose 4>&1

                It 'should return the correct verbose message' {
                    $result[0] | Should be $($LocalizedData['testCLRConfigFileConfig'] -f $Name)
                }
                It 'Should return false' {
                    $result[1] | Should be $false
                }
            }

            Context 'passAnonymousToken is not the same' {
                Mock Assert-Module
                Mock Invoke-AppCmd {return @{Count = 1}}
                Mock Invoke-AppCmd {return 'Started' } -ParameterFilter {$Arguments.Contains('/text:state')}
                Mock Invoke-AppCmd {return $PoolCfg} -ParameterFilter {$Arguments.Contains('/config:*')}

                $result = Test-TargetResource -Name $Name -passAnonymousToken 'false' -Verbose 4>&1

                It 'should return the correct verbose message' {
                    $result[0] | Should be $($LocalizedData['testpassAnonymousTokenconfig'] -f $Name)
                }
                It 'Should return false' {
                    $result[1] | Should be $false
                }
            }

            Context 'logonType is not the same' {
                Mock Assert-Module
                Mock Invoke-AppCmd {return @{Count = 1}}
                Mock Invoke-AppCmd {return 'Started' } -ParameterFilter {$Arguments.Contains('/text:state')}
                Mock Invoke-AppCmd {return $PoolCfg} -ParameterFilter {$Arguments.Contains('/config:*')}

                $result = Test-TargetResource -Name $Name -logonType 'LogonService' -Verbose 4>&1

                It 'should return the correct verbose message' {
                    $result[0] | Should be $($LocalizedData['testlogonTypeConfig'] -f $Name)
                }
                It 'Should return false' {
                    $result[1] | Should be $false
                }
            }

            Context 'manualGroupMembership is not the same' {
                Mock Assert-Module
                Mock Invoke-AppCmd {return @{Count = 1}}
                Mock Invoke-AppCmd {return 'Started' } -ParameterFilter {$Arguments.Contains('/text:state')}
                Mock Invoke-AppCmd {return $PoolCfg} -ParameterFilter {$Arguments.Contains('/config:*')}

                $result = Test-TargetResource -Name $Name -manualGroupMembership 'true' -Verbose 4>&1

                It 'should return the correct verbose message' {
                    $result[0] | Should be $($LocalizedData['testmanualGroupMembershipConfig'] -f $Name)
                }
                It 'Should return false' {
                    $result[1] | Should be $false
                }
            }

            Context 'idleTimeout is not the same' {
                Mock Assert-Module
                Mock Invoke-AppCmd {return @{Count = 1}}
                Mock Invoke-AppCmd {return 'Started' } -ParameterFilter {$Arguments.Contains('/text:state')}
                Mock Invoke-AppCmd {return $PoolCfg} -ParameterFilter {$Arguments.Contains('/config:*')}

                $result = Test-TargetResource -Name $Name -idleTimeout '00:10:00' -Verbose 4>&1

                It 'should return the correct verbose message' {
                    $result[0] | Should be $($LocalizedData['testidleTimeoutConfig'] -f $Name)
                }
                It 'Should return false' {
                    $result[1] | Should be $false
                }
            }

            Context 'maxProcesses is not the same' {
                Mock Assert-Module
                Mock Invoke-AppCmd {return @{Count = 1}}
                Mock Invoke-AppCmd {return 'Started' } -ParameterFilter {$Arguments.Contains('/text:state')}
                Mock Invoke-AppCmd {return $PoolCfg} -ParameterFilter {$Arguments.Contains('/config:*')}

                $result = Test-TargetResource -Name $Name -maxProcesses '2' -Verbose 4>&1

                It 'should return the correct verbose message' {
                    $result[0] | Should be $($LocalizedData['testmaxProcessesConfig'] -f $Name)
                }
                It 'Should return false' {
                    $result[1] | Should be $false
                }
            }

            Context 'shutdownTimeLimit is not the same' {
                Mock Assert-Module
                Mock Invoke-AppCmd {return @{Count = 1}}
                Mock Invoke-AppCmd {return 'Started' } -ParameterFilter {$Arguments.Contains('/text:state')}
                Mock Invoke-AppCmd {return $PoolCfg} -ParameterFilter {$Arguments.Contains('/config:*')}

                $result = Test-TargetResource -Name $Name -shutdownTimeLimit '00:02:00' -Verbose 4>&1

                It 'should return the correct verbose message' {
                    $result[0] | Should be $($LocalizedData['testshutdownTimeLimitConfig'] -f $Name)
                }
                It 'Should return false' {
                    $result[1] | Should be $false
                }
            }

            Context 'startupTimeLimit is not the same' {
                Mock Assert-Module
                Mock Invoke-AppCmd {return @{Count = 1}}
                Mock Invoke-AppCmd {return 'Started' } -ParameterFilter {$Arguments.Contains('/text:state')}
                Mock Invoke-AppCmd {return $PoolCfg} -ParameterFilter {$Arguments.Contains('/config:*')}

                $result = Test-TargetResource -Name $Name -startupTimeLimit '00:02:00' -Verbose 4>&1

                It 'should return the correct verbose message' {
                    $result[0] | Should be $($LocalizedData['teststartupTimeLimitConfig'] -f $Name)
                }
                It 'Should return false' {
                    $result[1] | Should be $false
                }
            }

            Context 'pingingEnabled is not the same' {
                Mock Assert-Module
                Mock Invoke-AppCmd {return @{Count = 1}}
                Mock Invoke-AppCmd {return 'Started' } -ParameterFilter {$Arguments.Contains('/text:state')}
                Mock Invoke-AppCmd {return $PoolCfg} -ParameterFilter {$Arguments.Contains('/config:*')}

                $result = Test-TargetResource -Name $Name -pingingEnabled 'false' -Verbose 4>&1

                It 'should return the correct verbose message' {
                    $result[0] | Should be $($LocalizedData['testpingingEnabledConfig'] -f $Name)
                }
                It 'Should return false' {
                    $result[1] | Should be $false
                }
            }

            Context 'pingInterval is not the same' {
                Mock Assert-Module
                Mock Invoke-AppCmd {return @{Count = 1}}
                Mock Invoke-AppCmd {return 'Started' } -ParameterFilter {$Arguments.Contains('/text:state')}
                Mock Invoke-AppCmd {return $PoolCfg} -ParameterFilter {$Arguments.Contains('/config:*')}

                $result = Test-TargetResource -Name $Name -pingInterval '00:01:00' -Verbose 4>&1

                It 'should return the correct verbose message' {
                    $result[0] | Should be $($LocalizedData['testpingIntervalConfig'] -f $Name)
                }
                It 'Should return false' {
                    $result[1] | Should be $false
                }
            }

            Context 'pingResponseTime is not the same' {
                Mock Assert-Module
                Mock Invoke-AppCmd {return @{Count = 1}}
                Mock Invoke-AppCmd {return 'Started' } -ParameterFilter {$Arguments.Contains('/text:state')}
                Mock Invoke-AppCmd {return $PoolCfg} -ParameterFilter {$Arguments.Contains('/config:*')}

                $result = Test-TargetResource -Name $Name -pingResponseTime '00:01:00' -Verbose 4>&1

                It 'should return the correct verbose message' {
                    $result[0] | Should be $($LocalizedData['testpingResponseTimeConfig'] -f $Name)
                }
                It 'Should return false' {
                    $result[1] | Should be $false
                }
            }

            Context 'disallowOverlappingRotation is not the same' {
                Mock Assert-Module
                Mock Invoke-AppCmd {return @{Count = 1}}
                Mock Invoke-AppCmd {return 'Started' } -ParameterFilter {$Arguments.Contains('/text:state')}
                Mock Invoke-AppCmd {return $PoolCfg} -ParameterFilter {$Arguments.Contains('/config:*')}

                $result = Test-TargetResource -Name $Name -disallowOverlappingRotation 'true' -Verbose 4>&1

                It 'should return the correct verbose message' {
                    $result[0] | Should be $($LocalizedData['testdisallowOverlappingRotationConfig'] -f $Name)
                }
                It 'Should return false' {
                    $result[1] | Should be $false
                }
            }

            Context 'disallowRotationOnConfigChange is not the same' {
                Mock Assert-Module
                Mock Invoke-AppCmd {return @{Count = 1}}
                Mock Invoke-AppCmd {return 'Started' } -ParameterFilter {$Arguments.Contains('/text:state')}
                Mock Invoke-AppCmd {return $PoolCfg} -ParameterFilter {$Arguments.Contains('/config:*')}

                $result = Test-TargetResource -Name $Name -disallowRotationOnConfigChange 'true' -Verbose 4>&1

                It 'should return the correct verbose message' {
                    $result[0] | Should be $($LocalizedData['testdisallowRotationOnConfigChangeConfig'] -f $Name)
                }
                It 'Should return false' {
                    $result[1] | Should be $false
                }
            }

            Context 'logEventOnRecycle is not the same' {
                Mock Assert-Module
                Mock Invoke-AppCmd {return @{Count = 1}}
                Mock Invoke-AppCmd {return 'Started' } -ParameterFilter {$Arguments.Contains('/text:state')}
                Mock Invoke-AppCmd {return $PoolCfg} -ParameterFilter {$Arguments.Contains('/config:*')}

                $result = Test-TargetResource -Name $Name -logEventOnRecycle 'Memory, Time, PrivateMemory' -Verbose 4>&1

                It 'should return the correct verbose message' {
                    $result[0] | Should be $($LocalizedData['testlogEventOnRecycleConfig'] -f $name)
                }
                It 'Should return false' {
                    $result[1] | Should be $false
                }
            }

            Context 'restartMemoryLimit is not the same' {
                Mock Assert-Module
                Mock Invoke-AppCmd {return @{Count = 1}}
                Mock Invoke-AppCmd {return 'Started' } -ParameterFilter {$Arguments.Contains('/text:state')}
                Mock Invoke-AppCmd {return $PoolCfg} -ParameterFilter {$Arguments.Contains('/config:*')}

                $result = Test-TargetResource -Name $Name -restartMemoryLimit '1' -Verbose 4>&1

                It 'should return the correct verbose message' {
                    $result[0] | Should be $($LocalizedData['testrestartMemoryLimitConfig'] -f $Name)
                }
                It 'Should return false' {
                    $result[1] | Should be $false
                }
            }

            Context 'restartPrivateMemoryLimit is not the same' {
                Mock Assert-Module
                Mock Invoke-AppCmd {return @{Count = 1}}
                Mock Invoke-AppCmd {return 'Started' } -ParameterFilter {$Arguments.Contains('/text:state')}
                Mock Invoke-AppCmd {return $PoolCfg} -ParameterFilter {$Arguments.Contains('/config:*')}

                $result = Test-TargetResource -Name $Name -restartPrivateMemoryLimit '1' -Verbose 4>&1

                It 'should return the correct verbose message' {
                    $result[0] | Should be $($LocalizedData['testrestartPrivateMemoryLimitConfig'] -f $Name)
                }
                It 'Should return false' {
                    $result[1] | Should be $false
                }
            }

            Context 'restartRequestsLimit is not the same' {
                Mock Assert-Module
                Mock Invoke-AppCmd {return @{Count = 1}}
                Mock Invoke-AppCmd {return 'Started' } -ParameterFilter {$Arguments.Contains('/text:state')}
                Mock Invoke-AppCmd {return $PoolCfg} -ParameterFilter {$Arguments.Contains('/config:*')}

                $result = Test-TargetResource -Name $Name -restartRequestsLimit 'true' -Verbose 4>&1

                It 'should return the correct verbose message' {
                    $result[0] | Should be $($LocalizedData['testrestartRequestsLimitConfig'] -f $Name)
                }
                It 'Should return false' {
                    $result[1] | Should be $false
                }
            }

            Context 'restartTimeLimit is not the same' {
                Mock Assert-Module
                Mock Invoke-AppCmd {return @{Count = 1}}
                Mock Invoke-AppCmd {return 'Started' } -ParameterFilter {$Arguments.Contains('/text:state')}
                Mock Invoke-AppCmd {return $PoolCfg} -ParameterFilter {$Arguments.Contains('/config:*')}

                $result = Test-TargetResource -Name $Name -restartTimeLimit '1.00:00:00' -Verbose 4>&1

                It 'should return the correct verbose message' {
                    $result[0] | Should be $($LocalizedData['testrestartTimeLimitConfig'] -f $Name)
                }
                It 'Should return false' {
                    $result[1] | Should be $false
                }
            }

            Context 'restartSchedule is not the same' {
                Mock Assert-Module
                Mock Invoke-AppCmd {return @{Count = 1}}
                Mock Invoke-AppCmd {return 'Started' } -ParameterFilter {$Arguments.Contains('/text:state')}
                Mock Invoke-AppCmd {return $PoolCfg} -ParameterFilter {$Arguments.Contains('/config:*')}

                $result = Test-TargetResource -Name $Name -restartSchedule @('00:00:00', '01:00:00') -Verbose 4>&1

                It 'should return the correct verbose message' {
                    $result[0] | Should be $($LocalizedData['TestrestartTimeLimitConfig'] -f $Name)
                }
                It 'Should return false' {
                    $result[1] | Should be $false
                }
            }

            Context 'loadBalancerCapabilities is not the same' {
                Mock Assert-Module
                Mock Invoke-AppCmd {return @{Count = 1}}
                Mock Invoke-AppCmd {return 'Started' } -ParameterFilter {$Arguments.Contains('/text:state')}
                Mock Invoke-AppCmd {return $PoolCfg} -ParameterFilter {$Arguments.Contains('/config:*')}

                $result = Test-TargetResource -Name $Name -loadBalancerCapabilities 'TcpLevel' -Verbose 4>&1

                It 'should return the correct verbose message' {
                    $result[0] | Should be $($LocalizedData['testloadBalancerCapabilitiesConfig'] -f $Name)
                }
                It 'Should return false' {
                    $result[1] | Should be $false
                }
            }

            Context 'orphanWorkerProcess is not the same' {
                Mock Assert-Module
                Mock Invoke-AppCmd {return @{Count = 1}}
                Mock Invoke-AppCmd {return 'Started' } -ParameterFilter {$Arguments.Contains('/text:state')}
                Mock Invoke-AppCmd {return $PoolCfg} -ParameterFilter {$Arguments.Contains('/config:*')}

                $result = Test-TargetResource -Name $Name -orphanWorkerProcess 'true' -Verbose 4>&1

                It 'should return the correct verbose message' {
                    $result[0] | Should be $($LocalizedData['testorphanWorkerProcessConfig'] -f $Name)
                }
                It 'Should return false' {
                    $result[1] | Should be $false
                }
            }

            Context 'orphanActionExe is not the same' {
                Mock Assert-Module
                Mock Invoke-AppCmd {return @{Count = 1}}
                Mock Invoke-AppCmd {return 'Started' } -ParameterFilter {$Arguments.Contains('/text:state')}
                Mock Invoke-AppCmd {return $PoolCfg} -ParameterFilter {$Arguments.Contains('/config:*')}

                $result = Test-TargetResource -Name $Name -orphanActionExe 'C:\pathto\some.exe' -Verbose 4>&1

                It 'should return the correct verbose message' {
                    $result[0] | Should be $($LocalizedData['testorphanActionExeConfig'] -f $Name)
                }
                It 'Should return false' {
                    $result[1] | Should be $false
                }
            }

            Context 'orphanActionParams is not the same' {
                Mock Assert-Module
                Mock Invoke-AppCmd {return @{Count = 1}}
                Mock Invoke-AppCmd {return 'Started' } -ParameterFilter {$Arguments.Contains('/text:state')}
                Mock Invoke-AppCmd {return $PoolCfg} -ParameterFilter {$Arguments.Contains('/config:*')}

                $result = Test-TargetResource -Name $Name -orphanActionParams '/some /parameters' -Verbose 4>&1

                It 'should return the correct verbose message' {
                    $result[0] | Should be $($LocalizedData['testorphanActionParamsConfig'] -f $Name)
                }
                It 'Should return false' {
                    $result[1] | Should be $false
                }
            }

            Context 'rapidFailProtection is not the same' {
                Mock Assert-Module
                Mock Invoke-AppCmd {return @{Count = 1}}
                Mock Invoke-AppCmd {return 'Started' } -ParameterFilter {$Arguments.Contains('/text:state')}
                Mock Invoke-AppCmd {return $PoolCfg} -ParameterFilter {$Arguments.Contains('/config:*')}

                $result = Test-TargetResource -Name $Name -rapidFailProtection 'false' -Verbose 4>&1

                It 'should return the correct verbose message' {
                    $result[0] | Should be $($LocalizedData['testrapidFailProtectionConfig'] -f $Name)
                }
                It 'Should return false' {
                    $result[1] | Should be $false
                }
            }

            Context 'rapidFailProtectionInterval is not the same' {
                Mock Assert-Module
                Mock Invoke-AppCmd {return @{Count = 1}}
                Mock Invoke-AppCmd {return 'Started' } -ParameterFilter {$Arguments.Contains('/text:state')}
                Mock Invoke-AppCmd {return $PoolCfg} -ParameterFilter {$Arguments.Contains('/config:*')}

                $result = Test-TargetResource -Name $Name -rapidFailProtectionInterval '00:20:00' -Verbose 4>&1

                It 'should return the correct verbose message' {
                    $result[0] | Should be $($LocalizedData['testrapidFailProtectionIntervalConfig'] -f $Name)
                }
                It 'Should return false' {
                    $result[1] | Should be $false
                }
            }

            Context 'rapidFailProtectionMaxCrashes is not the same' {
                Mock Assert-Module
                Mock Invoke-AppCmd {return @{Count = 1}}
                Mock Invoke-AppCmd {return 'Started' } -ParameterFilter {$Arguments.Contains('/text:state')}
                Mock Invoke-AppCmd {return $PoolCfg} -ParameterFilter {$Arguments.Contains('/config:*')}

                $result = Test-TargetResource -Name $Name -rapidFailProtectionMaxCrashes '1' -Verbose 4>&1

                It 'should return the correct verbose message' {
                    $result[0] | Should be $($LocalizedData['testrapidFailProtectionMaxCrashesConfig'] -f $Name)
                }
                It 'Should return false' {
                    $result[1] | Should be $false
                }
            }

            Context 'autoShutdownExe is not the same' {
                Mock Assert-Module
                Mock Invoke-AppCmd {return @{Count = 1}}
                Mock Invoke-AppCmd {return 'Started' } -ParameterFilter {$Arguments.Contains('/text:state')}
                Mock Invoke-AppCmd {return $PoolCfg} -ParameterFilter {$Arguments.Contains('/config:*')}

                $result = Test-TargetResource -Name $Name -autoShutdownExe 'C:\autoshutdown.exe' -Verbose 4>&1

                It 'should return the correct verbose message' {
                    $result[0] | Should be $($LocalizedData['testautoShutdownExeConfig'] -f $Name)
                }
                It 'Should return false' {
                    $result[1] | Should be $false
                }
            }

            Context 'autoShutdownParams is not the same' {
                Mock Assert-Module
                Mock Invoke-AppCmd {return @{Count = 1}}
                Mock Invoke-AppCmd {return 'Started' } -ParameterFilter {$Arguments.Contains('/text:state')}
                Mock Invoke-AppCmd {return $PoolCfg} -ParameterFilter {$Arguments.Contains('/config:*')}

                $result = Test-TargetResource -Name $Name -autoShutdownParams '/params' -Verbose 4>&1

                It 'should return the correct verbose message' {
                    $result[0] | Should be $($LocalizedData['testautoShutdownParamsConfig'] -f $Name)
                }
                It 'Should return false' {
                    $result[1] | Should be $false
                }
            }

            Context 'cpuLimit is not the same' {
                Mock Assert-Module
                Mock Invoke-AppCmd {return @{Count = 1}}
                Mock Invoke-AppCmd {return 'Started' } -ParameterFilter {$Arguments.Contains('/text:state')}
                Mock Invoke-AppCmd {return $PoolCfg} -ParameterFilter {$Arguments.Contains('/config:*')}

                $result = Test-TargetResource -Name $Name -cpuLimit '1' -Verbose 4>&1

                It 'should return the correct verbose message' {
                    $result[0] | Should be $($LocalizedData['testcpuLimitConfig'] -f $Name)
                }
                It 'Should return false' {
                    $result[1] | Should be $false
                }
            }

            Context 'cpuAction is not the same' {
                Mock Assert-Module
                Mock Invoke-AppCmd {return @{Count = 1}}
                Mock Invoke-AppCmd {return 'Started' } -ParameterFilter {$Arguments.Contains('/text:state')}
                Mock Invoke-AppCmd {return $PoolCfg} -ParameterFilter {$Arguments.Contains('/config:*')}

                $result = Test-TargetResource -Name $Name -cpuAction 'KillW3wp' -Verbose 4>&1

                It 'should return the correct verbose message' {
                    $result[0] | Should be $($LocalizedData['testcpuActionConfig'] -f $Name)
                }
                It 'Should return false' {
                    $result[1] | Should be $false
                }
            }

            Context 'cpuSmpAffinitized is not the same' {
                Mock Assert-Module
                Mock Invoke-AppCmd {return @{Count = 1}}
                Mock Invoke-AppCmd {return 'Started' } -ParameterFilter {$Arguments.Contains('/text:state')}
                Mock Invoke-AppCmd {return $PoolCfg} -ParameterFilter {$Arguments.Contains('/config:*')}

                $result = Test-TargetResource -Name $Name -cpuSmpAffinitized 'true' -Verbose 4>&1

                It 'should return the correct verbose message' {
                    $result[0] | Should be $($LocalizedData['testcpuSmpAffinitizedConfig'] -f $Name)
                }
                It 'Should return false' {
                    $result[1] | Should be $false
                }
            }

            Context 'cpuSmpProcessorAffinityMask is not the same' {
                Mock Assert-Module
                Mock Invoke-AppCmd {return @{Count = 1}}
                Mock Invoke-AppCmd {return 'Started' } -ParameterFilter {$Arguments.Contains('/text:state')}
                Mock Invoke-AppCmd {return $PoolCfg} -ParameterFilter {$Arguments.Contains('/config:*')}

                $result = Test-TargetResource -Name $Name -cpuSmpProcessorAffinityMask '1' -Verbose 4>&1

                It 'should return the correct verbose message' {
                    $result[0] | Should be $($LocalizedData['testcpuSmpProcessorAffinityMaskConfig'] -f $Name)
                }
                It 'Should return false' {
                    $result[1] | Should be $false
                }
            }

            Context 'cpuSmpProcessorAffinityMask2 is not the same' {
                Mock Assert-Module
                Mock Invoke-AppCmd {return @{Count = 1}}
                Mock Invoke-AppCmd {return 'Started' } -ParameterFilter {$Arguments.Contains('/text:state')}
                Mock Invoke-AppCmd {return $PoolCfg} -ParameterFilter {$Arguments.Contains('/config:*')}

                $result = Test-TargetResource -Name $Name -cpuSmpProcessorAffinityMask2 '1' -Verbose 4>&1

                It 'should return the correct verbose message' {
                    $result[0] | Should be $($LocalizedData['testcpuSmpProcessorAffinityMask2Config'] -f $Name)
                }
                It 'Should return false' {
                    $result[1] | Should be $false
                }
            }
        }
        #endregion

        #region Function Set-TargetResource
        Describe "$($Global:DSCResourceName)\Set-TargetResource" {
            [xml] $PoolCfg = '
            <add name="DefaultAppPool"
                queueLength="1000"
                autoStart="true"
                enable32BitAppOnWin64="false"
                managedRuntimeVersion="v4.0"
                managedRuntimeLoader="webengine4.dll"
                enableConfigurationOverride="true"
                managedPipelineMode="Integrated"
                CLRConfigFile=""
                passAnonymousToken="true"
                startMode="OnDemand">
                <processModel
                    identityType="ApplicationPoolIdentity"
                    userName=""
                    password=""
                    loadUserProfile="true"
                    setProfileEnvironment="true"
                    logonType="LogonBatch"
                    manualGroupMembership="false"
                    idleTimeout="00:20:00"
                    idleTimeoutAction="Terminate"
                    maxProcesses="1"
                    shutdownTimeLimit="00:01:30"
                    startupTimeLimit="00:01:30"
                    pingingEnabled="true"
                    pingInterval="00:00:30"
                    pingResponseTime="00:01:30"
                    logEventOnProcessModel="IdleTimeout"/>
                <recycling
                    disallowOverlappingRotation="false"
                    disallowRotationOnConfigChange="false"
                    logEventOnRecycle="Time, Memory, PrivateMemory">
                    <periodicRestart
                        memory="0"
                        privateMemory="0"
                        requests="0"
                        time="1.05:00:00">
                        <schedule>
                        </schedule>
                    </periodicRestart>
                </recycling>
                <failure
                    loadBalancerCapabilities="HttpLevel"
                    orphanWorkerProcess="false"
                    orphanActionExe=""
                    orphanActionParams=""
                    rapidFailProtection="true"
                    rapidFailProtectionInterval="00:05:00"
                    rapidFailProtectionMaxCrashes="5"
                    autoShutdownExe=""
                    autoShutdownParams=""/>
                <cpu limit="0"
                    action="NoAction"
                    resetInterval="00:05:00"
                    smpAffinitized="false"
                    smpProcessorAffinityMask="4294967295"
                    smpProcessorAffinityMask2="4294967295"
                    processorGroup="0"
                    numaNodeAssignment="MostAvailableMemory"
                    numaNodeAffinityMode="Soft" />
            </add>'

            $Name = 'DefaultAppPool'

            Context 'AppPool does not Exist, so Create it' {
                Mock New-WebAppPool -Verifiable
                Mock Stop-WebAppPool -Verifiable
                Mock Start-WebAppPool -Verifiable
                Mock Invoke-AppCmd -Verifiable

                It 'Should call all the mocks' {
                    $result = Set-TargetResource -Name $Name
                    Assert-VerifiableMocks
                }
            }

            Context 'AppPool Exists so modify it' {
                Mock Assert-Module
                Mock Invoke-AppCmd {return $PoolCfg} -ParameterFilter {$Arguments.Contains('set')} -Verifiable
                Mock Invoke-AppCmd {return $PoolCfg} -ParameterFilter {$Arguments.Contains('/config:*')} -Verifiable
                Mock Stop-WebAppPool

                $AppPoolPassword = 'NotPassword' | ConvertTo-SecureString -AsPlainText -Force
                $AppPoolCred = New-Object `
                    -TypeName System.Management.Automation.PSCredential `
                    -ArgumentList $('NotUserName', $AppPoolPassword)

                $params = @{
                    Name   = 'PesterAppPool';
                    Ensure = 'Present';
                    state = 'Stopped';
                    autoStart = 'false';
                    managedRuntimeVersion = 'v2.0';
                    managedPipelineMode = 'Classic';
                    startMode = 'AlwaysRunning';
                    identityType = 'SpecificUser';
                    Credential = $AppPoolCred;
                    loadUserProfile = 'false';
                    queueLength = '10';
                    enable32BitAppOnWin64 = 'true';
                    managedRuntimeLoader = 'somedll.dll';
                    enableConfigurationOverride = 'false';
                    CLRConfigFile = 'CLRConfigFile';
                    passAnonymousToken = 'false';
                    logonType = 'LogonService';
                    manualGroupMembership = 'true';
                    idleTimeout = '00:10:00';
                    maxProcesses = '10';
                    shutdownTimeLimit = '00:10:30';
                    startupTimeLimit = '00:10:30';
                    pingingEnabled = 'false';
                    pingInterval = '00:10:30';
                    pingResponseTime = '00:11:30';
                    disallowOverlappingRotation = 'true';
                    disallowRotationOnConfigChange = 'true';
                    logEventOnRecycle = 'Time, Memory, PrivateMemory, PrivateMemory';
                    restartMemoryLimit = '1';
                    restartPrivateMemoryLimit = '1';
                    restartRequestsLimit = '1';
                    restartTimeLimit = '1.15:00:00';
                    restartSchedule = @('00:00:00','01:00:00');
                    loadBalancerCapabilities = 'TcpLevel';
                    orphanWorkerProcess = 'false';
                    orphanActionExe = 'orphanActionExe.exe';
                    orphanActionParams = '/some params';
                    rapidFailProtection = 'false';
                    rapidFailProtectionInterval = '00:15:00';
                    rapidFailProtectionMaxCrashes = '15';
                    autoShutdownExe = 'autoShutdownExe';
                    autoShutdownParams = '/autoShutdownParams';
                    cpuLimit = '1';
                    cpuAction = 'KillW3wp';
                    cpuResetInterval = '00:15:00';
                    cpuSmpAffinitized = 'true';
                    cpuSmpProcessorAffinityMask = '1';
                    cpuSmpProcessorAffinityMask2 = '2';
                }

                It 'should not throw' {
                    {Set-TargetResource @params} | Should Not Throw
                }

                It 'Should call all the Mocks' {
                    Assert-VerifiableMocks

                    Assert-MockCalled Invoke-AppCmd -ParameterFilter {$Arguments.Contains('set')} -Times 44
                }
            }
        }
        #endregion
    }
    #endregion
}
finally
{
    #region FOOTER
    Restore-TestEnvironment -TestEnvironment $TestEnvironment
    #endregion
}
