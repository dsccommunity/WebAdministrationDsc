#requires -Version 4.0

# Suppressing this rule because IIS requires PlainText for one of the functions used in this test
[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingConvertToSecureStringWithPlainText', '')]
param ()

$script:DSCModuleName   = 'xWebAdministration'
$script:DSCResourceName = 'MSFT_xWebAppPoolDefaults'

#region HEADER
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
#endregion

# Begin Testing
try
{
    #region Pester Tests

    InModuleScope $script:DSCResourceName {

        Describe "$($script:DSCResourceName)\Get-TargetResource" {

            Mock Assert-Module

            Context 'Application pool defaults' {

                $mockAppPoolDefaults = @{
                    autoStart = $true
                    CLRConfigFile = ''
                    enable32BitAppOnWin64 = $false
                    enableConfigurationOverride = $true
                    managedPipelineMode = 'Integrated'
                    managedRuntimeLoader = 'webengine4.dll'
                    managedRuntimeVersion = 'v4.0'
                    passAnonymousToken = $true
                    startMode = 'OnDemand'
                    queueLength = 1000
                    cpu = @{
                        action = 'NoAction'
                        limit = 0
                        resetInterval = '00:05:00'
                        smpAffinitized = $false
                        smpProcessorAffinityMask = 4294967295
                        smpProcessorAffinityMask2 = 4294967295
                    }
                    processModel = @{
                        identityType = 'SpecificUser'
                        idleTimeout = '00:20:00'
                        idleTimeoutAction = 'Terminate'
                        loadUserProfile = $true
                        logEventOnProcessModel = 'IdleTimeout'
                        logonType = 'LogonBatch'
                        manualGroupMembership = $false
                        maxProcesses = 1
                        password = 'P@$$w0rd'
                        pingingEnabled = $true
                        pingInterval = '00:00:30'
                        pingResponseTime = '00:01:30'
                        setProfileEnvironment = $false
                        shutdownTimeLimit = '00:01:30'
                        startupTimeLimit = '00:01:30'
                        userName = 'CONTOSO\JDoe'
                    }
                    failure = @{
                        orphanActionExe = ''
                        orphanActionParams = ''
                        orphanWorkerProcess = $false
                        loadBalancerCapabilities = 'HttpLevel'
                        rapidFailProtection = $true
                        rapidFailProtectionInterval = '00:05:00'
                        rapidFailProtectionMaxCrashes = 5
                        autoShutdownExe = ''
                        autoShutdownParams = ''
                    }
                    recycling = @{
                        disallowOverlappingRotation = $false
                        disallowRotationOnConfigChange = $false
                        logEventOnRecycle = 'Time,Requests,Schedule,Memory,IsapiUnhealthy,OnDemand,ConfigChange,PrivateMemory'
                        periodicRestart = @{
                            memory = 0
                            privateMemory = 0
                            requests = 0
                            time = '1.05:00:00'
                            schedule = @{
                                Collection = @(
                                    @{value = '04:00:00'}
                                    @{value = '08:00:00'}
                                )
                            }
                        }
                    }
                }

                Mock Get-AppPoolDefault -MockWith {$mockAppPoolDefaults}

                $result = Get-TargetResource -ApplyTo 'Machine'

                It 'Should return the autoStart property' {
                    $result.autoStart | Should Be $mockAppPoolDefaults.autoStart
                }

                It 'Should return the CLRConfigFile property' {
                    $result.CLRConfigFile | Should Be $mockAppPoolDefaults.CLRConfigFile
                }

                It 'Should return the enable32BitAppOnWin64 property' {
                    $result.enable32BitAppOnWin64 | Should Be $mockAppPoolDefaults.enable32BitAppOnWin64
                }

                It 'Should return the enableConfigurationOverride property' {
                    $result.enableConfigurationOverride | Should Be $mockAppPoolDefaults.enableConfigurationOverride
                }

                It 'Should return the managedPipelineMode property' {
                    $result.managedPipelineMode | Should Be $mockAppPoolDefaults.managedPipelineMode
                }

                It 'Should return the managedRuntimeLoader property' {
                    $result.managedRuntimeLoader | Should Be $mockAppPoolDefaults.managedRuntimeLoader
                }

                It 'Should return the managedRuntimeVersion property' {
                    $result.managedRuntimeVersion | Should Be $mockAppPoolDefaults.managedRuntimeVersion
                }

                It 'Should return the passAnonymousToken property' {
                    $result.passAnonymousToken | Should Be $mockAppPoolDefaults.passAnonymousToken
                }

                It 'Should return the startMode property' {
                    $result.startMode | Should Be $mockAppPoolDefaults.startMode
                }

                It 'Should return the queueLength property' {
                    $result.queueLength | Should Be $mockAppPoolDefaults.queueLength
                }

                It 'Should return the cpuAction property' {
                    $result.cpuAction | Should Be $mockAppPoolDefaults.cpu.action
                }

                It 'Should return the cpuLimit property' {
                    $result.cpuLimit | Should Be $mockAppPoolDefaults.cpu.limit
                }

                It 'Should return the cpuResetInterval property' {
                    $result.cpuResetInterval | Should Be $mockAppPoolDefaults.cpu.resetInterval
                }

                It 'Should return the cpuSmpAffinitized property' {
                    $result.cpuSmpAffinitized | Should Be $mockAppPoolDefaults.cpu.smpAffinitized
                }

                It 'Should return the cpuSmpProcessorAffinityMask property' {
                    $result.cpuSmpProcessorAffinityMask | Should Be $mockAppPoolDefaults.cpu.smpProcessorAffinityMask
                }

                It 'Should return the cpuSmpProcessorAffinityMask2 property' {
                    $result.cpuSmpProcessorAffinityMask2 | Should Be $mockAppPoolDefaults.cpu.smpProcessorAffinityMask2
                }

                It 'Should return the identityType property' {
                    $result.identityType | Should Be $mockAppPoolDefaults.processModel.identityType
                }

                It 'Should return the Credential (userName) property' {
                    # Get-DscConfiguration returns MSFT_Credential with empty UserName
                    $result.Credential.userName | Should Be $mockAppPoolDefaults.processModel.userName
                }

                It 'Should return the Credential (password) property' {
                    # Get-DscConfiguration returns MSFT_Credential with empty Password
                    $result.Credential.Password | Should Be $mockAppPoolDefaults.processModel.password
                }

                It 'Should return the idleTimeout property' {
                    $result.idleTimeout | Should Be $mockAppPoolDefaults.processModel.idleTimeout
                }

                It 'Should return the idleTimeoutAction property' {
                    $result.idleTimeoutAction | Should Be $mockAppPoolDefaults.processModel.idleTimeoutAction
                }

                It 'Should return the loadUserProfile property' {
                    $result.loadUserProfile | Should Be $mockAppPoolDefaults.processModel.loadUserProfile
                }

                It 'Should return the logonType property' {
                    $result.logonType | Should Be $mockAppPoolDefaults.processModel.logonType
                }

                It 'Should return the logEventOnProcessModel property' {
                    $result.logEventOnProcessModel | Should Be $mockAppPoolDefaults.processModel.logEventOnProcessModel
                }

                It 'Should return the manualGroupMembership property' {
                    $result.manualGroupMembership | Should Be $mockAppPoolDefaults.processModel.manualGroupMembership
                }

                It 'Should return the maxProcesses property' {
                    $result.maxProcesses | Should Be $mockAppPoolDefaults.processModel.maxProcesses
                }

                It 'Should return the pingingEnabled property' {
                    $result.pingingEnabled | Should Be $mockAppPoolDefaults.processModel.pingingEnabled
                }

                It 'Should return the pingInterval property' {
                    $result.pingInterval | Should Be $mockAppPoolDefaults.processModel.pingInterval
                }

                It 'Should return the pingResponseTime property' {
                    $result.pingResponseTime | Should Be $mockAppPoolDefaults.processModel.pingResponseTime
                }

                It 'Should return the setProfileEnvironment property' {
                    $result.setProfileEnvironment | Should Be $mockAppPoolDefaults.processModel.setProfileEnvironment
                }

                It 'Should return the shutdownTimeLimit property' {
                    $result.shutdownTimeLimit | Should Be $mockAppPoolDefaults.processModel.shutdownTimeLimit
                }

                It 'Should return the startupTimeLimit property' {
                    $result.startupTimeLimit | Should Be $mockAppPoolDefaults.processModel.startupTimeLimit
                }

                It 'Should return the orphanActionExe property' {
                    $result.orphanActionExe | Should Be $mockAppPoolDefaults.failure.orphanActionExe
                }

                It 'Should return the orphanActionParams property' {
                    $result.orphanActionParams | Should Be $mockAppPoolDefaults.failure.orphanActionParams
                }

                It 'Should return the orphanWorkerProcess property' {
                    $result.orphanWorkerProcess | Should Be $mockAppPoolDefaults.failure.orphanWorkerProcess
                }

                It 'Should return the loadBalancerCapabilities property' {
                    $result.loadBalancerCapabilities | Should Be $mockAppPoolDefaults.failure.loadBalancerCapabilities
                }

                It 'Should return the rapidFailProtection property' {
                    $result.rapidFailProtection | Should Be $mockAppPoolDefaults.failure.rapidFailProtection
                }

                It 'Should return the rapidFailProtectionInterval property' {
                    $result.rapidFailProtectionInterval | Should Be $mockAppPoolDefaults.failure.rapidFailProtectionInterval
                }

                It 'Should return the rapidFailProtectionMaxCrashes property' {
                    $result.rapidFailProtectionMaxCrashes | Should Be $mockAppPoolDefaults.failure.rapidFailProtectionMaxCrashes
                }

                It 'Should return the autoShutdownExe property' {
                    $result.autoShutdownExe | Should Be $mockAppPoolDefaults.failure.autoShutdownExe
                }

                It 'Should return the autoShutdownParams property' {
                    $result.autoShutdownParams | Should Be $mockAppPoolDefaults.failure.autoShutdownParams
                }

                It 'Should return the disallowOverlappingRotation property' {
                    $result.disallowOverlappingRotation | Should Be $mockAppPoolDefaults.recycling.disallowOverlappingRotation
                }

                It 'Should return the disallowRotationOnConfigChange property' {
                    $result.disallowRotationOnConfigChange | Should Be $mockAppPoolDefaults.recycling.disallowRotationOnConfigChange
                }

                It 'Should return the logEventOnRecycle property' {
                    $result.logEventOnRecycle | Should Be $mockAppPoolDefaults.recycling.logEventOnRecycle
                }

                It 'Should return the restartMemoryLimit property' {
                    $result.restartMemoryLimit | Should Be $mockAppPoolDefaults.recycling.periodicRestart.memory
                }

                It 'Should return the restartPrivateMemoryLimit property' {
                    $result.restartPrivateMemoryLimit | Should Be $mockAppPoolDefaults.recycling.periodicRestart.privateMemory
                }

                It 'Should return the restartRequestsLimit property' {
                    $result.restartRequestsLimit | Should Be $mockAppPoolDefaults.recycling.periodicRestart.requests
                }

                It 'Should return the restartTimeLimit property' {
                    $result.restartTimeLimit | Should Be $mockAppPoolDefaults.recycling.periodicRestart.time
                }

                It 'Should return the restartSchedule property' {

                    $restartScheduleValues = [String[]]@(
                        @($mockAppPoolDefaults.recycling.periodicRestart.schedule.Collection).ForEach('value')
                    )

                    $compareSplat = @{
                        ReferenceObject = [String[]]@($result.restartSchedule)
                        DifferenceObject = $restartScheduleValues
                        ExcludeDifferent = $true
                        IncludeEqual = $true
                    }

                    $compareResult = Compare-Object @compareSplat

                    $compareResult.Count -eq $restartScheduleValues.Count | Should Be $true

                }

            }

        }

        Describe "how '$($script:DSCResourceName)\Test-TargetResource' responds" {

            Mock Assert-Module
            
            Context 'Test target resource with no property specified' {

                $mockAppPoolDefaults = @{
                }

                Mock Get-AppPoolDefault -MockWith {$mockAppPoolDefaults}

                It 'Should return True' {
                    Test-TargetResource -ApplyTo 'Machine' |
                    Should Be $true
                }

            }

            Context 'All the properties match the desired state' {

                $mockAppPoolDefaults = @{
                    autoStart = $true
                    CLRConfigFile = ''
                    enable32BitAppOnWin64 = $false
                    enableConfigurationOverride = $true
                    managedPipelineMode = 'Integrated'
                    managedRuntimeLoader = 'webengine4.dll'
                    managedRuntimeVersion = 'v4.0'
                    passAnonymousToken = $true
                    startMode = 'OnDemand'
                    queueLength = 1000
                    cpu = @{
                        action = 'NoAction'
                        limit = 0
                        resetInterval = '00:05:00'
                        smpAffinitized = $false
                        smpProcessorAffinityMask = 4294967295
                        smpProcessorAffinityMask2 = 4294967295
                    }
                    processModel = @{
                        identityType = 'SpecificUser'
                        idleTimeout = '00:20:00'
                        idleTimeoutAction = 'Terminate'
                        loadUserProfile = $true
                        logEventOnProcessModel = 'IdleTimeout'
                        logonType = 'LogonBatch'
                        manualGroupMembership = $false
                        maxProcesses = 1
                        password = 'P@$$w0rD'
                        pingingEnabled = $true
                        pingInterval = '00:00:30'
                        pingResponseTime = '00:01:30'
                        setProfileEnvironment = $false
                        shutdownTimeLimit = '00:01:30'
                        startupTimeLimit = '00:01:30'
                        userName = 'CONTOSO\JDoe'
                    }
                    failure = @{
                        orphanActionExe = ''
                        orphanActionParams = ''
                        orphanWorkerProcess = $false
                        loadBalancerCapabilities = 'HttpLevel'
                        rapidFailProtection = $true
                        rapidFailProtectionInterval = '00:05:00'
                        rapidFailProtectionMaxCrashes = 5
                        autoShutdownExe = ''
                        autoShutdownParams = ''
                    }
                    recycling = @{
                        disallowOverlappingRotation = $false
                        disallowRotationOnConfigChange = $false
                        logEventOnRecycle = 'Time,Requests,Schedule,Memory,IsapiUnhealthy,OnDemand,ConfigChange,PrivateMemory'
                        periodicRestart = @{
                            memory = 0
                            privateMemory = 0
                            requests = 0
                            time = '1.05:00:00'
                            schedule = @{
                                Collection = @(
                                    @{value = '04:00:00'}
                                    @{value = '08:00:00'}
                                )
                            }
                        }
                    }
                }

                Mock Get-AppPoolDefault -MockWith {$mockAppPoolDefaults}

                $mockUserName = $mockAppPoolDefaults.processModel.userName
                $mockPassword = $mockAppPoolDefaults.processModel.password | ConvertTo-SecureString -AsPlainText -Force
                $mockCredential = New-Object -TypeName PSCredential -ArgumentList $mockUserName, $mockPassword

                $mockRestartSchedule = [String[]]@(
                    @($mockAppPoolDefaults.recycling.periodicRestart.schedule.Collection).ForEach('value')
                )

                $testParamsSplat = @{
                    autoStart = $mockAppPoolDefaults.autoStart
                    CLRConfigFile = $mockAppPoolDefaults.CLRConfigFile
                    enable32BitAppOnWin64 = $mockAppPoolDefaults.enable32BitAppOnWin64
                    enableConfigurationOverride = $mockAppPoolDefaults.enableConfigurationOverride
                    managedPipelineMode = $mockAppPoolDefaults.managedPipelineMode
                    managedRuntimeLoader = $mockAppPoolDefaults.managedRuntimeLoader
                    managedRuntimeVersion = $mockAppPoolDefaults.managedRuntimeVersion
                    passAnonymousToken = $mockAppPoolDefaults.passAnonymousToken
                    startMode = $mockAppPoolDefaults.startMode
                    queueLength = $mockAppPoolDefaults.queueLength
                    cpuAction = $mockAppPoolDefaults.cpu.action
                    cpuLimit = $mockAppPoolDefaults.cpu.limit
                    cpuResetInterval = $mockAppPoolDefaults.cpu.resetInterval
                    cpuSmpAffinitized = $mockAppPoolDefaults.cpu.smpAffinitized
                    cpuSmpProcessorAffinityMask = $mockAppPoolDefaults.cpu.smpProcessorAffinityMask
                    cpuSmpProcessorAffinityMask2 = $mockAppPoolDefaults.cpu.smpProcessorAffinityMask2
                    identityType = $mockAppPoolDefaults.processModel.identityType
                    Credential = $mockCredential
                    idleTimeout = $mockAppPoolDefaults.processModel.idleTimeout
                    idleTimeoutAction = $mockAppPoolDefaults.processModel.idleTimeoutAction
                    loadUserProfile = $mockAppPoolDefaults.processModel.loadUserProfile
                    logEventOnProcessModel = $mockAppPoolDefaults.processModel.logEventOnProcessModel
                    logonType = $mockAppPoolDefaults.processModel.logonType
                    manualGroupMembership = $mockAppPoolDefaults.processModel.manualGroupMembership
                    maxProcesses = $mockAppPoolDefaults.processModel.maxProcesses
                    pingingEnabled = $mockAppPoolDefaults.processModel.pingingEnabled
                    pingInterval = $mockAppPoolDefaults.processModel.pingInterval
                    pingResponseTime = $mockAppPoolDefaults.processModel.pingResponseTime
                    setProfileEnvironment = $mockAppPoolDefaults.processModel.setProfileEnvironment
                    shutdownTimeLimit = $mockAppPoolDefaults.processModel.shutdownTimeLimit
                    startupTimeLimit = $mockAppPoolDefaults.processModel.startupTimeLimit
                    orphanActionExe = $mockAppPoolDefaults.failure.orphanActionExe
                    orphanActionParams = $mockAppPoolDefaults.failure.orphanActionParams
                    orphanWorkerProcess = $mockAppPoolDefaults.failure.orphanWorkerProcess
                    loadBalancerCapabilities = $mockAppPoolDefaults.failure.loadBalancerCapabilities
                    rapidFailProtection = $mockAppPoolDefaults.failure.rapidFailProtection
                    rapidFailProtectionInterval = $mockAppPoolDefaults.failure.rapidFailProtectionInterval
                    rapidFailProtectionMaxCrashes = $mockAppPoolDefaults.failure.rapidFailProtectionMaxCrashes
                    autoShutdownExe = $mockAppPoolDefaults.failure.autoShutdownExe
                    autoShutdownParams = $mockAppPoolDefaults.failure.autoShutdownParams
                    disallowOverlappingRotation = $mockAppPoolDefaults.recycling.disallowOverlappingRotation
                    disallowRotationOnConfigChange = $mockAppPoolDefaults.recycling.disallowRotationOnConfigChange
                    logEventOnRecycle = $mockAppPoolDefaults.recycling.logEventOnRecycle
                    restartMemoryLimit = $mockAppPoolDefaults.recycling.periodicRestart.memory
                    restartPrivateMemoryLimit = $mockAppPoolDefaults.recycling.periodicRestart.privateMemory
                    restartRequestsLimit = $mockAppPoolDefaults.recycling.periodicRestart.requests
                    restartTimeLimit = $mockAppPoolDefaults.recycling.periodicRestart.time
                    restartSchedule = $mockRestartSchedule
                }

                It 'Should return True' {
                    Test-TargetResource -ApplyTo Machine @testParamsSplat |
                    Should Be $true
                }

            }

            Context 'Test the autoStart property' {

                $mockAppPoolDefaults = @{
                    autoStart = $true
                }

                Mock Get-AppPoolDefault -MockWith {$mockAppPoolDefaults}

                It 'Should return True when the property matches the desired state' {
                    Test-TargetResource -ApplyTo Machine -autoStart $true |
                    Should Be $true
                }

                It 'Should return False when the property does not match the desired state' {
                    Test-TargetResource -ApplyTo Machine -autoStart $false |
                    Should Be $false
                }

            }

            Context 'Test the CLRConfigFile property' {

                $mockAppPoolDefaults = @{
                    CLRConfigFile = ''
                }

                Mock Get-AppPoolDefault -MockWith {$mockAppPoolDefaults}

                It 'Should return True when the property matches the desired state' {
                    Test-TargetResource -ApplyTo Machine -CLRConfigFile '' |
                    Should Be $true
                }

                It 'Should return False when the property does not match the desired state' {
                    Test-TargetResource -ApplyTo Machine -CLRConfigFile 'C:\inetpub\temp\aspnet.config' |
                    Should Be $false
                }

            }

            Context 'Test the enable32BitAppOnWin64 property' {

                $mockAppPoolDefaults = @{
                    enable32BitAppOnWin64 = $false
                }

                Mock Get-AppPoolDefault -MockWith {$mockAppPoolDefaults}

                It 'Should return True when the property matches the desired state' {
                    Test-TargetResource -ApplyTo Machine -enable32BitAppOnWin64 $false |
                    Should Be $true
                }

                It 'Should return False when the property does not match the desired state' {
                    Test-TargetResource -ApplyTo Machine -enable32BitAppOnWin64 $true |
                    Should Be $false
                }

            }

            Context 'Test the enableConfigurationOverride property' {

                $mockAppPoolDefaults = @{
                    enableConfigurationOverride = $true
                }

                Mock Get-AppPoolDefault -MockWith {$mockAppPoolDefaults}

                It 'Should return True when the property matches the desired state' {
                    Test-TargetResource -ApplyTo Machine -enableConfigurationOverride $true |
                    Should Be $true
                }

                It 'Should return False when the property does not match the desired state' {
                    Test-TargetResource -ApplyTo Machine -enableConfigurationOverride $false |
                    Should Be $false
                }

            }

            Context 'Test the managedPipelineMode property' {

                $mockAppPoolDefaults = @{
                    managedPipelineMode = 'Integrated'
                }

                Mock Get-AppPoolDefault -MockWith {$mockAppPoolDefaults}

                It 'Should return True when the property matches the desired state' {
                    Test-TargetResource -ApplyTo Machine -managedPipelineMode 'Integrated' |
                    Should Be $true
                }

                It 'Should return False when the property does not match the desired state' {
                    Test-TargetResource -ApplyTo Machine -managedPipelineMode 'Classic' |
                    Should Be $false
                }

            }

            Context 'Test the managedRuntimeLoader property' {

                $mockAppPoolDefaults = @{
                    managedRuntimeLoader = 'webengine4.dll'
                }

                Mock Get-AppPoolDefault -MockWith {$mockAppPoolDefaults}

                It 'Should return True when the property matches the desired state' {
                    Test-TargetResource -ApplyTo Machine -managedRuntimeLoader 'webengine4.dll' |
                    Should Be $true
                }

                It 'Should return False when the property does not match the desired state' {
                    Test-TargetResource -ApplyTo Machine -managedRuntimeLoader '' |
                    Should Be $false
                }

            }

            Context 'Test the managedRuntimeVersion property' {

                $mockAppPoolDefaults = @{
                    managedRuntimeVersion = 'v4.0'
                }

                Mock Get-AppPoolDefault -MockWith {$mockAppPoolDefaults}

                It 'Should return True when the property matches the desired state' {
                    Test-TargetResource -ApplyTo Machine -managedRuntimeVersion 'v4.0' |
                    Should Be $true
                }

                It 'Should return False when the property does not match the desired state' {
                    Test-TargetResource -ApplyTo Machine -managedRuntimeVersion 'v2.0' |
                    Should Be $false
                }

            }

            Context 'Test the passAnonymousToken property' {

                $mockAppPoolDefaults = @{
                    passAnonymousToken = $true
                }

                Mock Get-AppPoolDefault -MockWith {$mockAppPoolDefaults}

                It 'Should return True when the property matches the desired state' {
                    Test-TargetResource -ApplyTo Machine -passAnonymousToken $true |
                    Should Be $true
                }

                It 'Should return False when the property does not match the desired state' {
                    Test-TargetResource -ApplyTo Machine -passAnonymousToken $false |
                    Should Be $false
                }

            }

            Context 'Test the startMode property' {

                $mockAppPoolDefaults = @{
                    startMode = 'OnDemand'
                }

                Mock Get-AppPoolDefault -MockWith {$mockAppPoolDefaults}

                It 'Should return True when the property matches the desired state' {
                    Test-TargetResource -ApplyTo Machine -startMode 'OnDemand' |
                    Should Be $true
                }

                It 'Should return False when the property does not match the desired state' {
                    Test-TargetResource -ApplyTo Machine -startMode 'AlwaysRunning' |
                    Should Be $false
                }

            }

            Context 'Test the queueLength property' {

                $mockAppPoolDefaults = @{
                    queueLength = 1000
                }

                Mock Get-AppPoolDefault -MockWith {$mockAppPoolDefaults}

                It 'Should return True when the property matches the desired state' {
                    Test-TargetResource -ApplyTo Machine -queueLength 1000 |
                    Should Be $true
                }

                It 'Should return False when the property does not match the desired state' {
                    Test-TargetResource -ApplyTo Machine -queueLength 2000 |
                    Should Be $false
                }

            }

            Context 'Test the cpuAction property' {

                $mockAppPoolDefaults = @{
                    cpu = @{
                        action = 'NoAction'
                    }
                }

                Mock Get-AppPoolDefault -MockWith {$mockAppPoolDefaults}

                It 'Should return True when the property matches the desired state' {
                    Test-TargetResource -ApplyTo Machine -cpuAction 'NoAction' |
                    Should Be $true
                }

                It 'Should return False when the property does not match the desired state' {
                    Test-TargetResource -ApplyTo Machine -cpuAction 'KillW3wp' |
                    Should Be $false
                }

            }

            Context 'Test the cpuLimit property' {

                $mockAppPoolDefaults = @{
                    cpu = @{
                        limit = 0
                    }
                }

                Mock Get-AppPoolDefault -MockWith {$mockAppPoolDefaults}

                It 'Should return True when the property matches the desired state' {
                    Test-TargetResource -ApplyTo Machine -cpuLimit 0 |
                    Should Be $true
                }

                It 'Should return False when the property does not match the desired state' {
                    Test-TargetResource -ApplyTo Machine -cpuLimit 90000 |
                    Should Be $false
                }

            }

            Context 'Test the cpuResetInterval property' {

                $mockAppPoolDefaults = @{
                    cpu = @{
                        resetInterval = '00:05:00'
                    }
                }

                Mock Get-AppPoolDefault -MockWith {$mockAppPoolDefaults}

                It 'Should return True when the property matches the desired state' {
                    Test-TargetResource -ApplyTo Machine -cpuResetInterval '00:05:00' |
                    Should Be $true
                }

                It 'Should return False when the property does not match the desired state' {
                    Test-TargetResource -ApplyTo Machine -cpuResetInterval '00:10:00' |
                    Should Be $false
                }

            }

            Context 'Test the cpuSmpAffinitized property' {

                $mockAppPoolDefaults = @{
                    cpu = @{
                        smpAffinitized = $false
                    }
                }

                Mock Get-AppPoolDefault -MockWith {$mockAppPoolDefaults}

                It 'Should return True when the property matches the desired state' {
                    Test-TargetResource -ApplyTo Machine -cpuSmpAffinitized $false |
                    Should Be $true
                }

                It 'Should return False when the property does not match the desired state' {
                    Test-TargetResource -ApplyTo Machine -cpuSmpAffinitized $true |
                    Should Be $false
                }

            }

            Context 'Test the cpuSmpProcessorAffinityMask property' {

                $mockAppPoolDefaults = @{
                    cpu = @{
                        smpProcessorAffinityMask = 4294967295
                    }
                }

                Mock Get-AppPoolDefault -MockWith {$mockAppPoolDefaults}

                It 'Should return True when the property matches the desired state' {
                    Test-TargetResource -ApplyTo Machine -cpuSmpProcessorAffinityMask 4294967295 |
                    Should Be $true
                }

                It 'Should return False when the property does not match the desired state' {
                    Test-TargetResource -ApplyTo Machine -cpuSmpProcessorAffinityMask 1 |
                    Should Be $false
                }

            }

            Context 'Test the cpuSmpProcessorAffinityMask2 property' {

                $mockAppPoolDefaults = @{
                    cpu = @{
                        smpProcessorAffinityMask2 = 4294967295
                    }
                }

                Mock Get-AppPoolDefault -MockWith {$mockAppPoolDefaults}

                It 'Should return True when the property matches the desired state' {
                    Test-TargetResource -ApplyTo Machine -cpuSmpProcessorAffinityMask2 4294967295 |
                    Should Be $true
                }

                It 'Should return False when the property does not match the desired state' {
                    Test-TargetResource -ApplyTo Machine -cpuSmpProcessorAffinityMask2 1 |
                    Should Be $false
                }

            }

            Context 'Test the identityType property' {

                $mockAppPoolDefaults = @{
                    processModel = @{
                        identityType = 'ApplicationPoolIdentity'
                    }
                }

                Mock Get-AppPoolDefault -MockWith {$mockAppPoolDefaults}

                It 'Should return True when the property matches the desired state' {
                    Test-TargetResource -ApplyTo Machine -identityType 'ApplicationPoolIdentity' |
                    Should Be $true
                }

                It 'Should return False when the property does not match the desired state' {
                    Test-TargetResource -ApplyTo Machine -identityType 'NetworkService' |
                    Should Be $false
                }

            }

            Context 'Test the Credential property' {

                $mockAppPoolDefaults = @{
                    processModel = @{
                        identityType = 'SpecificUser'
                        password = '1q2w3e4r'
                        userName = 'CONTOSO\JDoe'
                    }
                }

                Mock Get-AppPoolDefault -MockWith {$mockAppPoolDefaults}

                It 'Should return True when both the userName and the password properties match the desired state' {

                    $mockUserName = $mockAppPoolDefaults.processModel.userName
                    $mockPassword = $mockAppPoolDefaults.processModel.password | ConvertTo-SecureString -AsPlainText -Force
                    $mockCredential = New-Object -TypeName PSCredential -ArgumentList $mockUserName, $mockPassword

                    Test-TargetResource -ApplyTo Machine -identityType 'SpecificUser' -Credential $mockCredential |
                    Should Be $true

                }

                It 'Should return False when the userName property does not match the desired state' {

                    $mockUserName = 'CONTOSO\GFawkes'
                    $mockPassword = $mockAppPoolDefaults.processModel.password | ConvertTo-SecureString -AsPlainText -Force
                    $mockCredential = New-Object -TypeName PSCredential -ArgumentList $mockUserName, $mockPassword

                    Test-TargetResource -ApplyTo Machine -identityType 'SpecificUser' -Credential $mockCredential |
                    Should Be $false

                }

                It 'Should return False when the password property does not match the desired state' {

                    $mockUserName = $mockAppPoolDefaults.processModel.userName
                    $mockPassword = '5t6y7u8i' | ConvertTo-SecureString -AsPlainText -Force
                    $mockCredential = New-Object -TypeName PSCredential -ArgumentList $mockUserName, $mockPassword

                    Test-TargetResource -ApplyTo Machine -identityType 'SpecificUser' -Credential $mockCredential |
                    Should Be $false

                }

            }

            Context 'Test the idleTimeout property' {

                $mockAppPoolDefaults = @{
                    processModel = @{
                        idleTimeout = '00:20:00'
                    }
                }

                Mock Get-AppPoolDefault -MockWith {$mockAppPoolDefaults}

                It 'Should return True when the property matches the desired state' {
                    Test-TargetResource -ApplyTo Machine -idleTimeout '00:20:00' |
                    Should Be $true
                }

                It 'Should return False when the property does not match the desired state' {
                    Test-TargetResource -ApplyTo Machine -idleTimeout '00:15:00' |
                    Should Be $false
                }

            }

            Context 'Test the idleTimeoutAction property' {

                $mockAppPoolDefaults = @{
                    processModel = @{
                        idleTimeoutAction = 'Terminate'
                    }
                }

                Mock Get-AppPoolDefault -MockWith {$mockAppPoolDefaults}

                It 'Should return True when the property matches the desired state' {
                    Test-TargetResource -ApplyTo Machine -idleTimeoutAction 'Terminate' |
                    Should Be $true
                }

                It 'Should return False when the property does not match the desired state' {
                    Test-TargetResource -ApplyTo Machine -idleTimeoutAction 'Suspend' |
                    Should Be $false
                }

            }

            Context 'Test the loadUserProfile property' {

                $mockAppPoolDefaults = @{
                    processModel = @{
                        loadUserProfile = $true
                    }
                }

                Mock Get-AppPoolDefault -MockWith {$mockAppPoolDefaults}

                It 'Should return True when the property matches the desired state' {
                    Test-TargetResource -ApplyTo Machine -loadUserProfile $true |
                    Should Be $true
                }

                It 'Should return False when the property does not match the desired state' {
                    Test-TargetResource -ApplyTo Machine -loadUserProfile $false |
                    Should Be $false
                }

            }

            Context 'Test the logEventOnProcessModel property' {

                $mockAppPoolDefaults = @{
                    processModel = @{
                        logEventOnProcessModel = 'IdleTimeout'
                    }
                }

                Mock Get-AppPoolDefault -MockWith {$mockAppPoolDefaults}

                It 'Should return True when the property matches the desired state' {
                    Test-TargetResource -ApplyTo Machine -logEventOnProcessModel 'IdleTimeout' |
                    Should Be $true
                }

                It 'Should return False when the property does not match the desired state' {
                    Test-TargetResource -ApplyTo Machine -logEventOnProcessModel '' |
                    Should Be $false
                }

            }

            Context 'Test the logonType property' {

                $mockAppPoolDefaults = @{
                    processModel = @{
                        logonType = 'LogonBatch'
                    }
                }

                Mock Get-AppPoolDefault -MockWith {$mockAppPoolDefaults}

                It 'Should return True when the property matches the desired state' {
                    Test-TargetResource -ApplyTo Machine -logonType 'LogonBatch' |
                    Should Be $true
                }

                It 'Should return False when the property does not match the desired state' {
                    Test-TargetResource -ApplyTo Machine -logonType 'LogonService' |
                    Should Be $false
                }

            }

            Context 'Test the manualGroupMembership property' {

                $mockAppPoolDefaults = @{
                    processModel = @{
                        manualGroupMembership = $false
                    }
                }

                Mock Get-AppPoolDefault -MockWith {$mockAppPoolDefaults}

                It 'Should return True when the property matches the desired state' {
                    Test-TargetResource -ApplyTo Machine -manualGroupMembership $false |
                    Should Be $true
                }

                It 'Should return False when the property does not match the desired state' {
                    Test-TargetResource -ApplyTo Machine -manualGroupMembership $true |
                    Should Be $false
                }

            }

            Context 'Test the maxProcesses property' {

                $mockAppPoolDefaults = @{
                    processModel = @{
                        maxProcesses = 1
                    }
                }

                Mock Get-AppPoolDefault -MockWith {$mockAppPoolDefaults}

                It 'Should return True when the property matches the desired state' {
                    Test-TargetResource -ApplyTo Machine -maxProcesses 1 |
                    Should Be $true
                }

                It 'Should return False when the property does not match the desired state' {
                    Test-TargetResource -ApplyTo Machine -maxProcesses 2 |
                    Should Be $false
                }

            }

            Context 'Test the pingingEnabled property' {

                $mockAppPoolDefaults = @{
                    processModel = @{
                        pingingEnabled = $true
                    }
                }

                Mock Get-AppPoolDefault -MockWith {$mockAppPoolDefaults}

                It 'Should return True when the property matches the desired state' {
                    Test-TargetResource -ApplyTo Machine -pingingEnabled $true |
                    Should Be $true
                }

                It 'Should return False when the property does not match the desired state' {
                    Test-TargetResource -ApplyTo Machine -pingingEnabled $false |
                    Should Be $false
                }

            }

            Context 'Test the pingInterval property' {

                $mockAppPoolDefaults = @{
                    processModel = @{
                        pingInterval = '00:00:30'
                    }
                }

                Mock Get-AppPoolDefault -MockWith {$mockAppPoolDefaults}

                It 'Should return True when the property matches the desired state' {
                    Test-TargetResource -ApplyTo Machine -pingInterval '00:00:30' |
                    Should Be $true
                }

                It 'Should return False when the property does not match the desired state' {
                    Test-TargetResource -ApplyTo Machine -pingInterval '00:01:00' |
                    Should Be $false
                }

            }

            Context 'Test the pingResponseTime property' {

                $mockAppPoolDefaults = @{
                    processModel = @{
                        pingResponseTime = '00:01:30'
                    }
                }

                Mock Get-AppPoolDefault -MockWith {$mockAppPoolDefaults}

                It 'Should return True when the property matches the desired state' {
                    Test-TargetResource -ApplyTo Machine -pingResponseTime '00:01:30' |
                    Should Be $true
                }

                It 'Should return False when the property does not match the desired state' {
                    Test-TargetResource -ApplyTo Machine -pingResponseTime '00:02:00' |
                    Should Be $false
                }

            }

            Context 'Test the setProfileEnvironment property' {

                $mockAppPoolDefaults = @{
                    processModel = @{
                        setProfileEnvironment = $false
                    }
                }

                Mock Get-AppPoolDefault -MockWith {$mockAppPoolDefaults}

                It 'Should return True when the property matches the desired state' {
                    Test-TargetResource -ApplyTo Machine -setProfileEnvironment $false |
                    Should Be $true
                }

                It 'Should return False when the property does not match the desired state' {
                    Test-TargetResource -ApplyTo Machine -setProfileEnvironment $true |
                    Should Be $false
                }

            }

            Context 'Test the shutdownTimeLimit property' {

                $mockAppPoolDefaults = @{
                    processModel = @{
                        shutdownTimeLimit = '00:01:30'
                    }
                }

                Mock Get-AppPoolDefault -MockWith {$mockAppPoolDefaults}

                It 'Should return True when the property matches the desired state' {
                    Test-TargetResource -ApplyTo Machine -shutdownTimeLimit '00:01:30' |
                    Should Be $true
                }

                It 'Should return False when the property does not match the desired state' {
                    Test-TargetResource -ApplyTo Machine -shutdownTimeLimit '00:02:00' |
                    Should Be $false
                }

            }

            Context 'Test the startupTimeLimit property' {

                $mockAppPoolDefaults = @{
                    processModel = @{
                        startupTimeLimit = '00:01:30'
                    }
                }

                Mock Get-AppPoolDefault -MockWith {$mockAppPoolDefaults}

                It 'Should return True when the property matches the desired state' {
                    Test-TargetResource -ApplyTo Machine -startupTimeLimit '00:01:30' |
                    Should Be $true
                }

                It 'Should return False when the property does not match the desired state' {
                    Test-TargetResource -ApplyTo Machine -startupTimeLimit '00:02:00' |
                    Should Be $false
                }

            }

            Context 'Test the orphanActionExe property' {

                $mockAppPoolDefaults = @{
                    failure = @{
                        orphanActionExe = ''
                    }
                }

                Mock Get-AppPoolDefault -MockWith {$mockAppPoolDefaults}

                It 'Should return True when the property matches the desired state' {
                    Test-TargetResource -ApplyTo Machine -orphanActionExe '' |
                    Should Be $true
                }

                It 'Should return False when the property does not match the desired state' {
                    Test-TargetResource -ApplyTo Machine -orphanActionExe 'C:\inetpub\temp\orphanAction.exe' |
                    Should Be $false
                }

            }

            Context 'Test the orphanActionParams property' {

                $mockAppPoolDefaults = @{
                    failure = @{
                        orphanActionParams = ''
                    }
                }

                Mock Get-AppPoolDefault -MockWith {$mockAppPoolDefaults}

                It 'Should return True when the property matches the desired state' {
                    Test-TargetResource -ApplyTo Machine -orphanActionParams '' |
                    Should Be $true
                }

                It 'Should return False when the property does not match the desired state' {
                    Test-TargetResource -ApplyTo Machine -orphanActionParams '/orphanActionParam1' |
                    Should Be $false
                }

            }

            Context 'Test the orphanWorkerProcess property' {

                $mockAppPoolDefaults = @{
                    failure = @{
                        orphanWorkerProcess = $false
                    }
                }

                Mock Get-AppPoolDefault -MockWith {$mockAppPoolDefaults}

                It 'Should return True when the property matches the desired state' {
                    Test-TargetResource -ApplyTo Machine -orphanWorkerProcess $false |
                    Should Be $true
                }

                It 'Should return False when the property does not match the desired state' {
                    Test-TargetResource -ApplyTo Machine -orphanWorkerProcess $true |
                    Should Be $false
                }

            }

            Context 'Test the loadBalancerCapabilities property' {

                $mockAppPoolDefaults = @{
                    failure = @{
                        loadBalancerCapabilities = 'HttpLevel'
                    }
                }

                Mock Get-AppPoolDefault -MockWith {$mockAppPoolDefaults}

                It 'Should return True when the property matches the desired state' {
                    Test-TargetResource -ApplyTo Machine -loadBalancerCapabilities 'HttpLevel' |
                    Should Be $true
                }

                It 'Should return False when the property does not match the desired state' {
                    Test-TargetResource -ApplyTo Machine -loadBalancerCapabilities 'TcpLevel' |
                    Should Be $false
                }

            }

            Context 'Test the rapidFailProtection property' {

                $mockAppPoolDefaults = @{
                    failure = @{
                        rapidFailProtection = $true
                    }
                }

                Mock Get-AppPoolDefault -MockWith {$mockAppPoolDefaults}

                It 'Should return True when the property matches the desired state' {
                    Test-TargetResource -ApplyTo Machine -rapidFailProtection $true |
                    Should Be $true
                }

                It 'Should return False when the property does not match the desired state' {
                    Test-TargetResource -ApplyTo Machine -rapidFailProtection $false |
                    Should Be $false
                }

            }

            Context 'Test the rapidFailProtectionInterval property' {

                $mockAppPoolDefaults = @{
                    failure = @{
                        rapidFailProtectionInterval = '00:05:00'
                    }
                }

                Mock Get-AppPoolDefault -MockWith {$mockAppPoolDefaults}

                It 'Should return True when the property matches the desired state' {
                    Test-TargetResource -ApplyTo Machine -rapidFailProtectionInterval '00:05:00' |
                    Should Be $true
                }

                It 'Should return False when the property does not match the desired state' {
                    Test-TargetResource -ApplyTo Machine -rapidFailProtectionInterval '00:10:00' |
                    Should Be $false
                }

            }

            Context 'Test the rapidFailProtectionMaxCrashes property' {

                $mockAppPoolDefaults = @{
                    failure = @{
                        rapidFailProtectionMaxCrashes = 5
                    }
                }

                Mock Get-AppPoolDefault -MockWith {$mockAppPoolDefaults}

                It 'Should return True when the property matches the desired state' {
                    Test-TargetResource -ApplyTo Machine -rapidFailProtectionMaxCrashes 5 |
                    Should Be $true
                }

                It 'Should return False when the property does not match the desired state' {
                    Test-TargetResource -ApplyTo Machine -rapidFailProtectionMaxCrashes 10 |
                    Should Be $false
                }

            }

            Context 'Test the autoShutdownExe property' {

                $mockAppPoolDefaults = @{
                    failure = @{
                        autoShutdownExe = ''
                    }
                }

                Mock Get-AppPoolDefault -MockWith {$mockAppPoolDefaults}

                It 'Should return True when the property matches the desired state' {
                    Test-TargetResource -ApplyTo Machine -autoShutdownExe '' |
                    Should Be $true
                }

                It 'Should return False when the property does not match the desired state' {
                    Test-TargetResource -ApplyTo Machine -autoShutdownExe 'C:\inetpub\temp\autoShutdown.exe' |
                    Should Be $false
                }

            }

            Context 'Test the autoShutdownParams property' {

                $mockAppPoolDefaults = @{
                    failure = @{
                        autoShutdownParams = ''
                    }
                }

                Mock Get-AppPoolDefault -MockWith {$mockAppPoolDefaults}

                It 'Should return True when the property matches the desired state' {
                    Test-TargetResource -ApplyTo Machine -autoShutdownParams '' |
                    Should Be $true
                }

                It 'Should return False when the property does not match the desired state' {
                    Test-TargetResource -ApplyTo Machine -autoShutdownParams '/autoShutdownParam1' |
                    Should Be $false
                }

            }

            Context 'Test the disallowOverlappingRotation property' {

                $mockAppPoolDefaults = @{
                    recycling = @{
                        disallowOverlappingRotation = $false
                    }
                }

                Mock Get-AppPoolDefault -MockWith {$mockAppPoolDefaults}

                It 'Should return True when the property matches the desired state' {
                    Test-TargetResource -ApplyTo Machine -disallowOverlappingRotation $false |
                    Should Be $true
                }

                It 'Should return False when the property does not match the desired state' {
                    Test-TargetResource -ApplyTo Machine -disallowOverlappingRotation $true |
                    Should Be $false
                }

            }

            Context 'Test the disallowRotationOnConfigChange property' {

                $mockAppPoolDefaults = @{
                    recycling = @{
                        disallowRotationOnConfigChange = $false
                    }
                }

                Mock Get-AppPoolDefault -MockWith {$mockAppPoolDefaults}

                It 'Should return True when the property matches the desired state' {
                    Test-TargetResource -ApplyTo Machine -disallowRotationOnConfigChange $false |
                    Should Be $true
                }

                It 'Should return False when the property does not match the desired state' {
                    Test-TargetResource -ApplyTo Machine -disallowRotationOnConfigChange $true |
                    Should Be $false
                }

            }

            Context 'Test the logEventOnRecycle property' {

                $mockAppPoolDefaults = @{
                    recycling = @{
                        logEventOnRecycle = 'Time,Requests,Schedule,Memory,IsapiUnhealthy,OnDemand,ConfigChange,PrivateMemory'
                    }
                }

                Mock Get-AppPoolDefault -MockWith {$mockAppPoolDefaults}

                It 'Should return True when the property matches the desired state' {
                    Test-TargetResource -ApplyTo Machine -logEventOnRecycle 'Time,Requests,Schedule,Memory,IsapiUnhealthy,OnDemand,ConfigChange,PrivateMemory' |
                    Should Be $true
                }

                It 'Should return False when the property does not match the desired state' {
                    Test-TargetResource -ApplyTo Machine -logEventOnRecycle 'Time,Memory,PrivateMemory' |
                    Should Be $false
                }

            }

            Context 'Test the restartMemoryLimit property' {

                $mockAppPoolDefaults = @{
                    recycling = @{
                        periodicRestart = @{
                            memory = 0
                        }
                    }
                }

                Mock Get-AppPoolDefault -MockWith {$mockAppPoolDefaults}

                It 'Should return True when the property matches the desired state' {
                    Test-TargetResource -ApplyTo Machine -restartMemoryLimit 0 |
                    Should Be $true
                }

                It 'Should return False when the property does not match the desired state' {
                    Test-TargetResource -ApplyTo Machine -restartMemoryLimit 1048576 |
                    Should Be $false
                }

            }

            Context 'Test the restartPrivateMemoryLimit property' {

                $mockAppPoolDefaults = @{
                    recycling = @{
                        periodicRestart = @{
                            privateMemory = 0
                        }
                    }
                }

                Mock Get-AppPoolDefault -MockWith {$mockAppPoolDefaults}

                It 'Should return True when the property matches the desired state' {
                    Test-TargetResource -ApplyTo Machine -restartPrivateMemoryLimit 0 |
                    Should Be $true
                }

                It 'Should return False when the property does not match the desired state' {
                    Test-TargetResource -ApplyTo Machine -restartPrivateMemoryLimit 1048576 |
                    Should Be $false
                }

            }

            Context 'Test the restartRequestsLimit property' {

                $mockAppPoolDefaults = @{
                    recycling = @{
                        periodicRestart = @{
                            requests = 0
                        }
                    }
                }

                Mock Get-AppPoolDefault -MockWith {$mockAppPoolDefaults}

                It 'Should return True when the property matches the desired state' {
                    Test-TargetResource -ApplyTo Machine -restartRequestsLimit 0 |
                    Should Be $true
                }

                It 'Should return False when the property does not match the desired state' {
                    Test-TargetResource -ApplyTo Machine -restartRequestsLimit 1000 |
                    Should Be $false
                }

            }

            Context 'Test the restartTimeLimit property' {

                $mockAppPoolDefaults = @{
                    recycling = @{
                        periodicRestart = @{
                            time = '1.05:00:00'
                        }
                    }
                }

                Mock Get-AppPoolDefault -MockWith {$mockAppPoolDefaults}

                It 'Should return True when the property matches the desired state' {
                    Test-TargetResource -ApplyTo Machine -restartTimeLimit '1.05:00:00' |
                    Should Be $true
                }

                It 'Should return False when the property does not match the desired state' {
                    Test-TargetResource -ApplyTo Machine -restartTimeLimit '2.10:00:00' |
                    Should Be $false
                }

            }

            Context 'Test the restartSchedule property' {

                $mockAppPoolDefaults = @{
                    recycling = @{
                        periodicRestart = @{
                            schedule = @{
                                Collection = @(
                                    @{value = '04:00:00'}
                                    @{value = '08:00:00'}
                                )
                            }
                        }
                    }
                }

                Mock Get-AppPoolDefault -MockWith {$mockAppPoolDefaults}

                It 'Should return True when the property matches the desired state' {
                    Test-TargetResource -ApplyTo Machine -restartSchedule @('04:00:00', '08:00:00') |
                    Should Be $true
                }

                It 'Should return False when the property does not match the desired state' {
                    Test-TargetResource -ApplyTo Machine -restartSchedule @('') |
                    Should Be $false
                }

            }

        }

        Describe "how '$($script:DSCResourceName)\Set-TargetResource' responds" {

            Mock -CommandName Assert-Module -MockWith {}

            Context 'All the properties need to be set' {

                $mockAppPoolDefaults = @{
                    autoStart = $true
                    CLRConfigFile = ''
                    enable32BitAppOnWin64 = $false
                    enableConfigurationOverride = $true
                    managedPipelineMode = 'Integrated'
                    managedRuntimeLoader = 'webengine4.dll'
                    managedRuntimeVersion = 'v4.0'
                    passAnonymousToken = $true
                    startMode = 'OnDemand'
                    queueLength = 1000
                    cpu = @{
                        action = 'NoAction'
                        limit = 0
                        resetInterval = '00:05:00'
                        smpAffinitized = $false
                        smpProcessorAffinityMask = 4294967295
                        smpProcessorAffinityMask2 = 4294967295
                    }
                    processModel = @{
                        identityType = 'ApplicationPoolIdentity'
                        idleTimeout = '00:20:00'
                        idleTimeoutAction = 'Terminate'
                        loadUserProfile = $true
                        logEventOnProcessModel = 'IdleTimeout'
                        logonType = 'LogonBatch'
                        manualGroupMembership = $false
                        maxProcesses = 1
                        password = ''
                        pingingEnabled = $true
                        pingInterval = '00:00:30'
                        pingResponseTime = '00:01:30'
                        setProfileEnvironment = $false
                        shutdownTimeLimit = '00:01:30'
                        startupTimeLimit = '00:01:30'
                        userName = ''
                    }
                    failure = @{
                        orphanActionExe = ''
                        orphanActionParams = ''
                        orphanWorkerProcess = $false
                        loadBalancerCapabilities = 'HttpLevel'
                        rapidFailProtection = $true
                        rapidFailProtectionInterval = '00:05:00'
                        rapidFailProtectionMaxCrashes = 5
                        autoShutdownExe = ''
                        autoShutdownParams = ''
                    }
                    recycling = @{
                        disallowOverlappingRotation = $false
                        disallowRotationOnConfigChange = $false
                        logEventOnRecycle = 'Time,Requests,Schedule,Memory,IsapiUnhealthy,OnDemand,ConfigChange,PrivateMemory'
                        periodicRestart = @{
                            memory = 0
                            privateMemory = 0
                            requests = 0
                            time = '1.05:00:00'
                            schedule = @{
                                Collection = @(
                                    @{value = '02:00:00'}
                                    @{value = '04:00:00'}
                                )
                            }
                        }
                    }
                }

                Mock Get-AppPoolDefault -MockWith {$mockAppPoolDefaults}

                $mockUserName = 'CONTOSO\GFawkes'
                $mockPassword = '5t6y7u8i' | ConvertTo-SecureString -AsPlainText -Force
                $mockCredential = New-Object -TypeName PSCredential -ArgumentList $mockUserName, $mockPassword

                $setParamsSplat = @{
                    autoStart = $false
                    CLRConfigFile = 'C:\inetpub\temp\aspnet.config'
                    enable32BitAppOnWin64 = $true
                    enableConfigurationOverride = $false
                    managedPipelineMode = 'Classic'
                    managedRuntimeLoader = ''
                    managedRuntimeVersion = 'v2.0'
                    passAnonymousToken = $false
                    startMode = 'AlwaysRunning'
                    queueLength = 2000
                    cpuAction = 'KillW3wp'
                    cpuLimit = 90000
                    cpuResetInterval = '00:10:00'
                    cpuSmpAffinitized = $true
                    cpuSmpProcessorAffinityMask = 1
                    cpuSmpProcessorAffinityMask2 = 1
                    identityType = 'SpecificUser'
                    Credential = $mockCredential
                    idleTimeout = '00:15:00'
                    idleTimeoutAction = 'Suspend'
                    loadUserProfile = $false
                    logEventOnProcessModel = ''
                    logonType = 'LogonService'
                    manualGroupMembership = $true
                    maxProcesses = 2
                    pingingEnabled = $false
                    pingInterval = '00:01:00'
                    pingResponseTime = '00:02:00'
                    setProfileEnvironment = $true
                    shutdownTimeLimit = '00:02:00'
                    startupTimeLimit = '00:02:00'
                    orphanActionExe = 'C:\inetpub\temp\orphanAction.exe'
                    orphanActionParams = '/orphanActionParam1'
                    orphanWorkerProcess = $true
                    loadBalancerCapabilities = 'TcpLevel'
                    rapidFailProtection = $false
                    rapidFailProtectionInterval = '00:10:00'
                    rapidFailProtectionMaxCrashes = 10
                    autoShutdownExe = 'C:\inetpub\temp\autoShutdown.exe'
                    autoShutdownParams = '/autoShutdownParam1'
                    disallowOverlappingRotation = $true
                    disallowRotationOnConfigChange = $true
                    logEventOnRecycle = 'Time,Memory,PrivateMemory'
                    restartMemoryLimit = 1048576
                    restartPrivateMemoryLimit = 1048576
                    restartRequestsLimit = 1000
                    restartTimeLimit = '2.10:00:00'
                    restartSchedule = @('06:00:00', '08:00:00')
                }

                Mock Invoke-AppCmd

                Set-TargetResource -ApplyTo Machine @setParamsSplat

                It 'Should call all the mocks' {
                    Assert-MockCalled Invoke-AppCmd -Exactly 52
                }

            }

            Context 'The autoStart property needs to be set' {

                $mockAppPoolDefaults = @{
                    autoStart = $true
                }

                Mock Get-AppPoolDefault -MockWith {$mockAppPoolDefaults}

                $setParamsSplat = @{
                    autoStart = $false
                }

                Mock Invoke-AppCmd -ParameterFilter {$ArgumentList[-1] -eq '/applicationPoolDefaults.autoStart:False'}

                Set-TargetResource -ApplyTo Machine @setParamsSplat

                It 'Should call Invoke-AppCmd' {
                    Assert-MockCalled Invoke-AppCmd -Exactly 1
                }

            }

            Context 'The CLRConfigFile property needs to be set' {

                $mockAppPoolDefaults = @{
                    CLRConfigFile = ''
                }

                Mock Get-AppPoolDefault -MockWith {$mockAppPoolDefaults}

                $setParamsSplat = @{
                    CLRConfigFile = 'C:\inetpub\temp\aspnet.config'
                }

                Mock Invoke-AppCmd -ParameterFilter {$ArgumentList[-1] -eq '/applicationPoolDefaults.CLRConfigFile:C:\inetpub\temp\aspnet.config'}

                Set-TargetResource -ApplyTo Machine @setParamsSplat

                It 'Should call Invoke-AppCmd' {
                    Assert-MockCalled Invoke-AppCmd -Exactly 1
                }

            }

            Context 'The enable32BitAppOnWin64 property needs to be set' {

                $mockAppPoolDefaults = @{
                    enable32BitAppOnWin64 = $false
                }

                Mock Get-AppPoolDefault -MockWith {$mockAppPoolDefaults}

                $setParamsSplat = @{
                    enable32BitAppOnWin64 = $true
                }

                Mock Invoke-AppCmd -ParameterFilter {$ArgumentList[-1] -eq '/applicationPoolDefaults.enable32BitAppOnWin64:True'}

                Set-TargetResource -ApplyTo Machine @setParamsSplat

                It 'Should call Invoke-AppCmd' {
                    Assert-MockCalled Invoke-AppCmd -Exactly 1
                }

            }

            Context 'The enableConfigurationOverride property needs to be set' {

                $mockAppPoolDefaults = @{
                    enableConfigurationOverride = $true
                }

                Mock Get-AppPoolDefault -MockWith {$mockAppPoolDefaults}

                $setParamsSplat = @{
                    enableConfigurationOverride = $false
                }

                Mock Invoke-AppCmd -ParameterFilter {$ArgumentList[-1] -eq '/applicationPoolDefaults.enableConfigurationOverride:False'}

                Set-TargetResource -ApplyTo Machine @setParamsSplat

                It 'Should call Invoke-AppCmd' {
                    Assert-MockCalled Invoke-AppCmd -Exactly 1
                }

            }

            Context 'The managedPipelineMode property needs to be set' {

                $mockAppPoolDefaults = @{
                    managedPipelineMode = 'Integrated'
                }

                Mock Get-AppPoolDefault -MockWith {$mockAppPoolDefaults}

                $setParamsSplat = @{
                    managedPipelineMode = 'Classic'
                }

                Mock Invoke-AppCmd -ParameterFilter {$ArgumentList[-1] -eq '/applicationPoolDefaults.managedPipelineMode:Classic'}

                Set-TargetResource -ApplyTo Machine @setParamsSplat

                It 'Should call Invoke-AppCmd' {
                    Assert-MockCalled Invoke-AppCmd -Exactly 1
                }

            }

            Context 'The managedRuntimeLoader property needs to be set' {

                $mockAppPoolDefaults = @{
                    managedRuntimeLoader = 'webengine4.dll'
                }

                Mock Get-AppPoolDefault -MockWith {$mockAppPoolDefaults}

                $setParamsSplat = @{
                    managedRuntimeLoader = ''
                }

                Mock Invoke-AppCmd -ParameterFilter {$ArgumentList[-1] -eq '/applicationPoolDefaults.managedRuntimeLoader:'}

                Set-TargetResource -ApplyTo Machine @setParamsSplat

                It 'Should call Invoke-AppCmd' {
                    Assert-MockCalled Invoke-AppCmd -Exactly 1
                }

            }

            Context 'The managedRuntimeVersion property needs to be set' {

                $mockAppPoolDefaults = @{
                    managedRuntimeVersion = 'v4.0'
                }

                Mock Get-AppPoolDefault -MockWith {$mockAppPoolDefaults}

                $setParamsSplat = @{
                    managedRuntimeVersion = 'v2.0'
                }

                Mock Invoke-AppCmd -ParameterFilter {$ArgumentList[-1] -eq '/applicationPoolDefaults.managedRuntimeVersion:v2.0'}

                Set-TargetResource -ApplyTo Machine @setParamsSplat

                It 'Should call Invoke-AppCmd' {
                    Assert-MockCalled Invoke-AppCmd -Exactly 1
                }

            }

            Context 'The passAnonymousToken property needs to be set' {

                $mockAppPoolDefaults = @{
                    passAnonymousToken = $true
                }

                Mock Get-AppPoolDefault -MockWith {$mockAppPoolDefaults}

                $setParamsSplat = @{
                    passAnonymousToken = $false
                }

                Mock Invoke-AppCmd -ParameterFilter {$ArgumentList[-1] -eq '/applicationPoolDefaults.passAnonymousToken:False'}

                Set-TargetResource -ApplyTo Machine @setParamsSplat

                It 'Should call Invoke-AppCmd' {
                    Assert-MockCalled Invoke-AppCmd -Exactly 1
                }

            }

            Context 'The startMode property needs to be set' {

                $mockAppPoolDefaults = @{
                    startMode = 'OnDemand'
                }

                Mock Get-AppPoolDefault -MockWith {$mockAppPoolDefaults}

                $setParamsSplat = @{
                    startMode = 'AlwaysRunning'
                }

                Mock Invoke-AppCmd -ParameterFilter {$ArgumentList[-1] -eq '/applicationPoolDefaults.startMode:AlwaysRunning'}

                Set-TargetResource -ApplyTo Machine @setParamsSplat

                It 'Should call Invoke-AppCmd' {
                    Assert-MockCalled Invoke-AppCmd -Exactly 1
                }

            }

            Context 'The queueLength property needs to be set' {

                $mockAppPoolDefaults = @{
                    queueLength = 1000
                }

                Mock Get-AppPoolDefault -MockWith {$mockAppPoolDefaults}

                $setParamsSplat = @{
                    queueLength = 2000
                }

                Mock Invoke-AppCmd -ParameterFilter {$ArgumentList[-1] -eq '/applicationPoolDefaults.queueLength:2000'}

                Set-TargetResource -ApplyTo Machine @setParamsSplat

                It 'Should call Invoke-AppCmd' {
                    Assert-MockCalled Invoke-AppCmd -Exactly 1
                }

            }

            Context 'The cpuAction property needs to be set' {

                $mockAppPoolDefaults = @{
                    cpu = @{
                        action = 'NoAction'
                    }
                }

                Mock Get-AppPoolDefault -MockWith {$mockAppPoolDefaults}

                $setParamsSplat = @{
                    cpuAction = 'KillW3wp'
                }

                Mock Invoke-AppCmd -ParameterFilter {$ArgumentList[-1] -eq '/applicationPoolDefaults.cpu.action:KillW3wp'}

                Set-TargetResource -ApplyTo Machine @setParamsSplat

                It 'Should call Invoke-AppCmd' {
                    Assert-MockCalled Invoke-AppCmd -Exactly 1
                }

            }

            Context 'The cpuLimit property needs to be set' {

                $mockAppPoolDefaults = @{
                    cpu = @{
                        limit = 0
                    }
                }

                Mock Get-AppPoolDefault -MockWith {$mockAppPoolDefaults}

                $setParamsSplat = @{
                    cpuLimit = 90000
                }

                Mock Invoke-AppCmd -ParameterFilter {$ArgumentList[-1] -eq '/applicationPoolDefaults.cpu.limit:90000'}

                Set-TargetResource -ApplyTo Machine @setParamsSplat

                It 'Should call Invoke-AppCmd' {
                    Assert-MockCalled Invoke-AppCmd -Exactly 1
                }

            }

            Context 'The cpuResetInterval property needs to be set' {

                $mockAppPoolDefaults = @{
                    cpu = @{
                        resetInterval = '00:05:00'
                    }
                }

                Mock Get-AppPoolDefault -MockWith {$mockAppPoolDefaults}

                $setParamsSplat = @{
                    cpuResetInterval = '00:10:00'
                }

                Mock Invoke-AppCmd -ParameterFilter {$ArgumentList[-1] -eq '/applicationPoolDefaults.cpu.resetInterval:00:10:00'}

                Set-TargetResource -ApplyTo Machine @setParamsSplat

                It 'Should call Invoke-AppCmd' {
                    Assert-MockCalled Invoke-AppCmd -Exactly 1
                }

            }

            Context 'The cpuSmpAffinitized property needs to be set' {

                $mockAppPoolDefaults = @{
                    cpu = @{
                        smpAffinitized = $false
                    }
                }

                Mock Get-AppPoolDefault -MockWith {$mockAppPoolDefaults}

                $setParamsSplat = @{
                    cpuSmpAffinitized = $true
                }

                Mock Invoke-AppCmd -ParameterFilter {$ArgumentList[-1] -eq '/applicationPoolDefaults.cpu.smpAffinitized:True'}

                Set-TargetResource -ApplyTo Machine @setParamsSplat

                It 'Should call Invoke-AppCmd' {
                    Assert-MockCalled Invoke-AppCmd -Exactly 1
                }

            }

            Context 'The cpuSmpProcessorAffinityMask property needs to be set' {

                $mockAppPoolDefaults = @{
                    cpu = @{
                        smpProcessorAffinityMask = 4294967295
                    }
                }

                Mock Get-AppPoolDefault -MockWith {$mockAppPoolDefaults}

                $setParamsSplat = @{
                    cpuSmpProcessorAffinityMask = 1
                }

                Mock Invoke-AppCmd -ParameterFilter {$ArgumentList[-1] -eq '/applicationPoolDefaults.cpu.smpProcessorAffinityMask:1'}

                Set-TargetResource -ApplyTo Machine @setParamsSplat

                It 'Should call Invoke-AppCmd' {
                    Assert-MockCalled Invoke-AppCmd -Exactly 1
                }

            }

            Context 'The cpuSmpProcessorAffinityMask2 property needs to be set' {

                $mockAppPoolDefaults = @{
                    cpu = @{
                        smpProcessorAffinityMask2 = 4294967295
                    }
                }

                Mock Get-AppPoolDefault -MockWith {$mockAppPoolDefaults}

                $setParamsSplat = @{
                    cpuSmpProcessorAffinityMask2 = 1
                }

                Mock Invoke-AppCmd -ParameterFilter {$ArgumentList[-1] -eq '/applicationPoolDefaults.cpu.smpProcessorAffinityMask2:1'}

                Set-TargetResource -ApplyTo Machine @setParamsSplat

                It 'Should call Invoke-AppCmd' {
                    Assert-MockCalled Invoke-AppCmd -Exactly 1
                }

            }

            Context 'The identityType property needs to be set' {

                $mockAppPoolDefaults = @{
                    processModel = @{
                        identityType = 'ApplicationPoolIdentity'
                    }
                }

                Mock Get-AppPoolDefault -MockWith {$mockAppPoolDefaults}

                $setParamsSplat = @{
                    identityType = 'SpecificUser'
                }

                Mock Invoke-AppCmd -ParameterFilter {$ArgumentList[-1] -eq '/applicationPoolDefaults.processModel.identityType:SpecificUser'}

                Set-TargetResource -ApplyTo Machine @setParamsSplat

                It 'Should call Invoke-AppCmd' {
                    Assert-MockCalled Invoke-AppCmd -Exactly 1
                }

            }

            Context 'The idleTimeout property needs to be set' {

                $mockAppPoolDefaults = @{
                    processModel = @{
                        idleTimeout = '00:20:00'
                    }
                }

                Mock Get-AppPoolDefault -MockWith {$mockAppPoolDefaults}

                $setParamsSplat = @{
                    idleTimeout = '00:15:00'
                }

                Mock Invoke-AppCmd -ParameterFilter {$ArgumentList[-1] -eq '/applicationPoolDefaults.processModel.idleTimeout:00:15:00'}

                Set-TargetResource -ApplyTo Machine @setParamsSplat

                It 'Should call Invoke-AppCmd' {
                    Assert-MockCalled Invoke-AppCmd -Exactly 1
                }

            }

            Context 'The idleTimeoutAction property needs to be set' {

                $mockAppPoolDefaults = @{
                    processModel = @{
                        idleTimeoutAction = 'Terminate'
                    }
                }

                Mock Get-AppPoolDefault -MockWith {$mockAppPoolDefaults}

                $setParamsSplat = @{
                    idleTimeoutAction = 'Suspend'
                }

                Mock Invoke-AppCmd -ParameterFilter {$ArgumentList[-1] -eq '/applicationPoolDefaults.processModel.idleTimeoutAction:Suspend'}

                Set-TargetResource -ApplyTo Machine @setParamsSplat

                It 'Should call Invoke-AppCmd' {
                    Assert-MockCalled Invoke-AppCmd -Exactly 1
                }

            }

            Context 'The loadUserProfile property needs to be set' {

                $mockAppPoolDefaults = @{
                    processModel = @{
                        loadUserProfile = $true
                    }
                }

                Mock Get-AppPoolDefault -MockWith {$mockAppPoolDefaults}

                $setParamsSplat = @{
                    loadUserProfile = $false
                }

                Mock Invoke-AppCmd -ParameterFilter {$ArgumentList[-1] -eq '/applicationPoolDefaults.processModel.loadUserProfile:False'}

                Set-TargetResource -ApplyTo Machine @setParamsSplat

                It 'Should call Invoke-AppCmd' {
                    Assert-MockCalled Invoke-AppCmd -Exactly 1
                }

            }

            Context 'The logEventOnProcessModel property needs to be set' {

                $mockAppPoolDefaults = @{
                    processModel = @{
                        logEventOnProcessModel = 'IdleTimeout'
                    }
                }

                Mock Get-AppPoolDefault -MockWith {$mockAppPoolDefaults}

                $setParamsSplat = @{
                    logEventOnProcessModel = ''
                }

                Mock Invoke-AppCmd -ParameterFilter {$ArgumentList[-1] -eq '/applicationPoolDefaults.processModel.logEventOnProcessModel:'}

                Set-TargetResource -ApplyTo Machine @setParamsSplat

                It 'Should call Invoke-AppCmd' {
                    Assert-MockCalled Invoke-AppCmd -Exactly 1
                }

            }

            Context 'The logonType property needs to be set' {

                $mockAppPoolDefaults = @{
                    processModel = @{
                        logonType = 'LogonBatch'
                    }
                }

                Mock Get-AppPoolDefault -MockWith {$mockAppPoolDefaults}

                $setParamsSplat = @{
                    logonType = 'LogonService'
                }

                Mock Invoke-AppCmd -ParameterFilter {$ArgumentList[-1] -eq '/applicationPoolDefaults.processModel.logonType:LogonService'}

                Set-TargetResource -ApplyTo Machine @setParamsSplat

                It 'Should call Invoke-AppCmd' {
                    Assert-MockCalled Invoke-AppCmd -Exactly 1
                }

            }

            Context 'The manualGroupMembership property needs to be set' {

                $mockAppPoolDefaults = @{
                    processModel = @{
                        manualGroupMembership = $false
                    }
                }

                Mock Get-AppPoolDefault -MockWith {$mockAppPoolDefaults}

                $setParamsSplat = @{
                    manualGroupMembership = $true
                }

                Mock Invoke-AppCmd -ParameterFilter {$ArgumentList[-1] -eq '/applicationPoolDefaults.processModel.manualGroupMembership:True'}

                Set-TargetResource -ApplyTo Machine @setParamsSplat

                It 'Should call Invoke-AppCmd' {
                    Assert-MockCalled Invoke-AppCmd -Exactly 1
                }

            }

            Context 'The maxProcesses property needs to be set' {

                $mockAppPoolDefaults = @{
                    processModel = @{
                        maxProcesses = 1
                    }
                }

                Mock Get-AppPoolDefault -MockWith {$mockAppPoolDefaults}

                $setParamsSplat = @{
                    maxProcesses = 2
                }

                Mock Invoke-AppCmd -ParameterFilter {$ArgumentList[-1] -eq '/applicationPoolDefaults.processModel.maxProcesses:2'}

                Set-TargetResource -ApplyTo Machine @setParamsSplat

                It 'Should call Invoke-AppCmd' {
                    Assert-MockCalled Invoke-AppCmd -Exactly 1
                }

            }

            Context 'The pingingEnabled property needs to be set' {

                $mockAppPoolDefaults = @{
                    processModel = @{
                        pingingEnabled = $true
                    }
                }

                Mock Get-AppPoolDefault -MockWith {$mockAppPoolDefaults}

                $setParamsSplat = @{
                    pingingEnabled = $false
                }

                Mock Invoke-AppCmd -ParameterFilter {$ArgumentList[-1] -eq '/applicationPoolDefaults.processModel.pingingEnabled:False'}

                Set-TargetResource -ApplyTo Machine @setParamsSplat

                It 'Should call Invoke-AppCmd' {
                    Assert-MockCalled Invoke-AppCmd -Exactly 1
                }

            }

            Context 'The pingInterval property needs to be set' {

                $mockAppPoolDefaults = @{
                    processModel = @{
                        pingInterval = '00:00:30'
                    }
                }

                Mock Get-AppPoolDefault -MockWith {$mockAppPoolDefaults}

                $setParamsSplat = @{
                    pingInterval = '00:01:00'
                }

                Mock Invoke-AppCmd -ParameterFilter {$ArgumentList[-1] -eq '/applicationPoolDefaults.processModel.pingInterval:00:01:00'}

                Set-TargetResource -ApplyTo Machine @setParamsSplat

                It 'Should call Invoke-AppCmd' {
                    Assert-MockCalled Invoke-AppCmd -Exactly 1
                }

            }

            Context 'The pingResponseTime property needs to be set' {

                $mockAppPoolDefaults = @{
                    processModel = @{
                        pingResponseTime = '00:01:30'
                    }
                }

                Mock Get-AppPoolDefault -MockWith {$mockAppPoolDefaults}

                $setParamsSplat = @{
                    pingResponseTime = '00:02:00'
                }

                Mock Invoke-AppCmd -ParameterFilter {$ArgumentList[-1] -eq '/applicationPoolDefaults.processModel.pingResponseTime:00:02:00'}

                Set-TargetResource -ApplyTo Machine @setParamsSplat

                It 'Should call Invoke-AppCmd' {
                    Assert-MockCalled Invoke-AppCmd -Exactly 1
                }

            }

            Context 'The setProfileEnvironment property needs to be set' {

                $mockAppPoolDefaults = @{
                    processModel = @{
                        setProfileEnvironment = $false
                    }
                }

                Mock Get-AppPoolDefault -MockWith {$mockAppPoolDefaults}

                $setParamsSplat = @{
                    setProfileEnvironment = $true
                }

                Mock Invoke-AppCmd -ParameterFilter {$ArgumentList[-1] -eq '/applicationPoolDefaults.processModel.setProfileEnvironment:True'}

                Set-TargetResource -ApplyTo Machine @setParamsSplat

                It 'Should call Invoke-AppCmd' {
                    Assert-MockCalled Invoke-AppCmd -Exactly 1
                }

            }

            Context 'The shutdownTimeLimit property needs to be set' {

                $mockAppPoolDefaults = @{
                    processModel = @{
                        shutdownTimeLimit = '00:01:30'
                    }
                }

                Mock Get-AppPoolDefault -MockWith {$mockAppPoolDefaults}

                $setParamsSplat = @{
                    shutdownTimeLimit = '00:02:00'
                }

                Mock Invoke-AppCmd -ParameterFilter {$ArgumentList[-1] -eq '/applicationPoolDefaults.processModel.shutdownTimeLimit:00:02:00'}

                Set-TargetResource -ApplyTo Machine @setParamsSplat

                It 'Should call Invoke-AppCmd' {
                    Assert-MockCalled Invoke-AppCmd -Exactly 1
                }

            }

            Context 'The startupTimeLimit property needs to be set' {

                $mockAppPoolDefaults = @{
                    processModel = @{
                        startupTimeLimit = '00:01:30'
                    }
                }

                Mock Get-AppPoolDefault -MockWith {$mockAppPoolDefaults}

                $setParamsSplat = @{
                    startupTimeLimit = '00:02:00'
                }

                Mock Invoke-AppCmd -ParameterFilter {$ArgumentList[-1] -eq '/applicationPoolDefaults.processModel.startupTimeLimit:00:02:00'}

                Set-TargetResource -ApplyTo Machine @setParamsSplat

                It 'Should call Invoke-AppCmd' {
                    Assert-MockCalled Invoke-AppCmd -Exactly 1
                }

            }

            Context 'The orphanActionExe property needs to be set' {

                $mockAppPoolDefaults = @{
                    failure = @{
                        orphanActionExe = ''
                    }
                }

                Mock Get-AppPoolDefault -MockWith {$mockAppPoolDefaults}

                $setParamsSplat = @{
                    orphanActionExe = 'C:\inetpub\temp\orphanAction.exe'
                }

                Mock Invoke-AppCmd -ParameterFilter {$ArgumentList[-1] -eq '/applicationPoolDefaults.failure.orphanActionExe:C:\inetpub\temp\orphanAction.exe'}

                Set-TargetResource -ApplyTo Machine @setParamsSplat

                It 'Should call Invoke-AppCmd' {
                    Assert-MockCalled Invoke-AppCmd -Exactly 1
                }

            }

            Context 'The orphanActionParams property needs to be set' {

                $mockAppPoolDefaults = @{
                    failure = @{
                        orphanActionParams = ''
                    }
                }

                Mock Get-AppPoolDefault -MockWith {$mockAppPoolDefaults}

                $setParamsSplat = @{
                    orphanActionParams = '/orphanActionParam1'
                }

                Mock Invoke-AppCmd -ParameterFilter {$ArgumentList[-1] -eq '/applicationPoolDefaults.failure.orphanActionParams:/orphanActionParam1'}

                Set-TargetResource -ApplyTo Machine @setParamsSplat

                It 'Should call Invoke-AppCmd' {
                    Assert-MockCalled Invoke-AppCmd -Exactly 1
                }

            }

            Context 'The orphanWorkerProcess property needs to be set' {

                $mockAppPoolDefaults = @{
                    failure = @{
                        orphanWorkerProcess = $false
                    }
                }

                Mock Get-AppPoolDefault -MockWith {$mockAppPoolDefaults}

                $setParamsSplat = @{
                    orphanWorkerProcess = $true
                }

                Mock Invoke-AppCmd -ParameterFilter {$ArgumentList[-1] -eq '/applicationPoolDefaults.failure.orphanWorkerProcess:True'}

                Set-TargetResource -ApplyTo Machine @setParamsSplat

                It 'Should call Invoke-AppCmd' {
                    Assert-MockCalled Invoke-AppCmd -Exactly 1
                }

            }

            Context 'The loadBalancerCapabilities property needs to be set' {

                $mockAppPoolDefaults = @{
                    failure = @{
                        loadBalancerCapabilities = 'HttpLevel'
                    }
                }

                Mock Get-AppPoolDefault -MockWith {$mockAppPoolDefaults}

                $setParamsSplat = @{
                    loadBalancerCapabilities = 'TcpLevel'
                }

                Mock Invoke-AppCmd -ParameterFilter {$ArgumentList[-1] -eq '/applicationPoolDefaults.failure.loadBalancerCapabilities:TcpLevel'}

                Set-TargetResource -ApplyTo Machine @setParamsSplat

                It 'Should call Invoke-AppCmd' {
                    Assert-MockCalled Invoke-AppCmd -Exactly 1
                }

            }

            Context 'The rapidFailProtection property needs to be set' {

                $mockAppPoolDefaults = @{
                    failure = @{
                        rapidFailProtection = $true
                    }
                }

                Mock Get-AppPoolDefault -MockWith {$mockAppPoolDefaults}

                $setParamsSplat = @{
                    rapidFailProtection = $false
                }

                Mock Invoke-AppCmd -ParameterFilter {$ArgumentList[-1] -eq '/applicationPoolDefaults.failure.rapidFailProtection:False'}

                Set-TargetResource -ApplyTo Machine @setParamsSplat

                It 'Should call Invoke-AppCmd' {
                    Assert-MockCalled Invoke-AppCmd -Exactly 1
                }

            }

            Context 'The rapidFailProtectionInterval property needs to be set' {

                $mockAppPoolDefaults = @{
                    failure = @{
                        rapidFailProtectionInterval = '00:05:00'
                    }
                }

                Mock Get-AppPoolDefault -MockWith {$mockAppPoolDefaults}

                $setParamsSplat = @{
                    rapidFailProtectionInterval = '00:10:00'
                }

                Mock Invoke-AppCmd -ParameterFilter {$ArgumentList[-1] -eq '/applicationPoolDefaults.failure.rapidFailProtectionInterval:00:10:00'}

                Set-TargetResource -ApplyTo Machine @setParamsSplat

                It 'Should call Invoke-AppCmd' {
                    Assert-MockCalled Invoke-AppCmd -Exactly 1
                }

            }

            Context 'The rapidFailProtectionMaxCrashes property needs to be set' {

                $mockAppPoolDefaults = @{
                    failure = @{
                        rapidFailProtectionMaxCrashes = 5
                    }
                }

                Mock Get-AppPoolDefault -MockWith {$mockAppPoolDefaults}

                $setParamsSplat = @{
                    rapidFailProtectionMaxCrashes = 10
                }

                Mock Invoke-AppCmd -ParameterFilter {$ArgumentList[-1] -eq '/applicationPoolDefaults.failure.rapidFailProtectionMaxCrashes:10'}

                Set-TargetResource -ApplyTo Machine @setParamsSplat

                It 'Should call Invoke-AppCmd' {
                    Assert-MockCalled Invoke-AppCmd -Exactly 1
                }

            }

            Context 'The autoShutdownExe property needs to be set' {

                $mockAppPoolDefaults = @{
                    failure = @{
                        autoShutdownExe = ''
                    }
                }

                Mock Get-AppPoolDefault -MockWith {$mockAppPoolDefaults}

                $setParamsSplat = @{
                    autoShutdownExe = 'C:\inetpub\temp\autoShutdown.exe'
                }

                Mock Invoke-AppCmd -ParameterFilter {$ArgumentList[-1] -eq '/applicationPoolDefaults.failure.autoShutdownExe:C:\inetpub\temp\autoShutdown.exe'}

                Set-TargetResource -ApplyTo Machine @setParamsSplat

                It 'Should call Invoke-AppCmd' {
                    Assert-MockCalled Invoke-AppCmd -Exactly 1
                }

            }

            Context 'The autoShutdownParams property needs to be set' {

                $mockAppPoolDefaults = @{
                    failure = @{
                        autoShutdownParams = ''
                    }

                }

                Mock Get-AppPoolDefault -MockWith {$mockAppPoolDefaults}

                $setParamsSplat = @{
                    autoShutdownParams = '/autoShutdownParam1'
                }

                Mock Invoke-AppCmd -ParameterFilter {$ArgumentList[-1] -eq '/applicationPoolDefaults.failure.autoShutdownParams:/autoShutdownParam1'}

                Set-TargetResource -ApplyTo Machine @setParamsSplat

                It 'Should call Invoke-AppCmd' {
                    Assert-MockCalled Invoke-AppCmd -Exactly 1
                }

            }

            Context 'The disallowOverlappingRotation property needs to be set' {

                $mockAppPoolDefaults = @{
                    recycling = @{
                        disallowOverlappingRotation = $false
                    }
                }

                Mock Get-AppPoolDefault -MockWith {$mockAppPoolDefaults}

                $setParamsSplat = @{
                    disallowOverlappingRotation = $true
                }

                Mock Invoke-AppCmd -ParameterFilter {$ArgumentList[-1] -eq '/applicationPoolDefaults.recycling.disallowOverlappingRotation:True'}

                Set-TargetResource -ApplyTo Machine @setParamsSplat

                It 'Should call Invoke-AppCmd' {
                    Assert-MockCalled Invoke-AppCmd -Exactly 1
                }

            }

            Context 'The disallowRotationOnConfigChange property needs to be set' {

                $mockAppPoolDefaults = @{
                    recycling = @{
                        disallowRotationOnConfigChange = $false
                    }
                }

                Mock Get-AppPoolDefault -MockWith {$mockAppPoolDefaults}

                $setParamsSplat = @{
                    disallowRotationOnConfigChange = $true
                }

                Mock Invoke-AppCmd -ParameterFilter {$ArgumentList[-1] -eq '/applicationPoolDefaults.recycling.disallowRotationOnConfigChange:True'}

                Set-TargetResource -ApplyTo Machine @setParamsSplat

                It 'Should call Invoke-AppCmd' {
                    Assert-MockCalled Invoke-AppCmd -Exactly 1
                }

            }

            Context 'The logEventOnRecycle property needs to be set' {

                $mockAppPoolDefaults = @{
                    recycling = @{
                        logEventOnRecycle = 'Time,Requests,Schedule,Memory,IsapiUnhealthy,OnDemand,ConfigChange,PrivateMemory'
                    }
                }

                Mock Get-AppPoolDefault -MockWith {$mockAppPoolDefaults}

                $setParamsSplat = @{
                    logEventOnRecycle = 'Time,Memory,PrivateMemory'
                }

                Mock Invoke-AppCmd -ParameterFilter {$ArgumentList[-1] -eq '/applicationPoolDefaults.recycling.logEventOnRecycle:Time,Memory,PrivateMemory'}

                Set-TargetResource -ApplyTo Machine @setParamsSplat

                It 'Should call Invoke-AppCmd' {
                    Assert-MockCalled Invoke-AppCmd -Exactly 1
                }

            }

            Context 'The restartMemoryLimit property needs to be set' {

                $mockAppPoolDefaults = @{
                    recycling = @{
                        periodicRestart = @{
                            memory = 0
                        }
                    }
                }

                Mock Get-AppPoolDefault -MockWith {$mockAppPoolDefaults}

                $setParamsSplat = @{
                    restartMemoryLimit = 1048576
                }

                Mock Invoke-AppCmd -ParameterFilter {$ArgumentList[-1] -eq '/applicationPoolDefaults.recycling.periodicRestart.memory:1048576'}

                Set-TargetResource -ApplyTo Machine @setParamsSplat

                It 'Should call Invoke-AppCmd' {
                    Assert-MockCalled Invoke-AppCmd -Exactly 1
                }

            }

            Context 'The restartPrivateMemoryLimit property needs to be set' {

                $mockAppPoolDefaults = @{
                    recycling = @{
                        periodicRestart = @{
                            privateMemory = 0
                        }
                    }
                }

                Mock Get-AppPoolDefault -MockWith {$mockAppPoolDefaults}

                $setParamsSplat = @{
                    restartPrivateMemoryLimit = 1048576
                }

                Mock Invoke-AppCmd -ParameterFilter {$ArgumentList[-1] -eq '/applicationPoolDefaults.recycling.periodicRestart.privateMemory:1048576'}

                Set-TargetResource -ApplyTo Machine @setParamsSplat

                It 'Should call Invoke-AppCmd' {
                    Assert-MockCalled Invoke-AppCmd -Exactly 1
                }

            }

            Context 'The restartRequestsLimit property needs to be set' {

                $mockAppPoolDefaults = @{
                    recycling = @{
                        periodicRestart = @{
                            requests = 0
                        }
                    }
                }

                Mock Get-AppPoolDefault -MockWith {$mockAppPoolDefaults}

                $setParamsSplat = @{
                    restartRequestsLimit = 1000
                }

                Mock Invoke-AppCmd -ParameterFilter {$ArgumentList[-1] -eq '/applicationPoolDefaults.recycling.periodicRestart.requests:1000'}

                Set-TargetResource -ApplyTo Machine @setParamsSplat

                It 'Should call Invoke-AppCmd' {
                    Assert-MockCalled Invoke-AppCmd -Exactly 1
                }

            }

            Context 'The restartTimeLimit property needs to be set' {

                $mockAppPoolDefaults = @{
                    recycling = @{
                        periodicRestart = @{
                            time = '1.05:00:00'
                        }
                    }
                }

                Mock Get-AppPoolDefault -MockWith {$mockAppPoolDefaults}

                $setParamsSplat = @{
                    restartTimeLimit = '2.10:00:00'
                }

                Mock Invoke-AppCmd -ParameterFilter {$ArgumentList[-1] -eq '/applicationPoolDefaults.recycling.periodicRestart.time:2.10:00:00'}

                Set-TargetResource -ApplyTo Machine @setParamsSplat

                It 'Should call Invoke-AppCmd' {
                    Assert-MockCalled Invoke-AppCmd -Exactly 1
                }

            }

            Context 'The restartSchedule property needs to be set' {

                $mockAppPoolDefaults = @{
                    recycling = @{
                        periodicRestart = @{
                            schedule = @{
                                Collection = @(
                                    @{value = '04:00:00'}
                                )
                            }
                        }
                    }
                }

                Mock Get-AppPoolDefault -MockWith {$mockAppPoolDefaults}

                $setParamsSplat = @{
                    restartSchedule = @('08:00:00')
                }

                Mock Invoke-AppCmd -ParameterFilter {$ArgumentList[-1] -eq "/-applicationPoolDefaults.recycling.periodicRestart.schedule.[value='04:00:00']"}
                Mock Invoke-AppCmd -ParameterFilter {$ArgumentList[-1] -eq "/+applicationPoolDefaults.recycling.periodicRestart.schedule.[value='08:00:00']"}

                Set-TargetResource -ApplyTo Machine @setParamsSplat

                It 'Should call Invoke-AppCmd' {
                    Assert-MockCalled Invoke-AppCmd -ParameterFilter {$ArgumentList[-1] -eq "/-applicationPoolDefaults.recycling.periodicRestart.schedule.[value='04:00:00']"} -Exactly 1
                    Assert-MockCalled Invoke-AppCmd -ParameterFilter {$ArgumentList[-1] -eq "/+applicationPoolDefaults.recycling.periodicRestart.schedule.[value='08:00:00']"} -Exactly 1
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
