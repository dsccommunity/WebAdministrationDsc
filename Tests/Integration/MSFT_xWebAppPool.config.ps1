$rules = @{
    Name                           = 'PesterAppPool'
    Ensure                         = 'Present'
    state                          = 'Stopped'
    autoStart                      = 'false'
    managedRuntimeVersion          = 'v2.0'
    managedPipelineMode            = 'Classic'
    startMode                      = 'AlwaysRunning'
    identityType                   = 'LocalService'
    loadUserProfile                = 'false'
    queueLength                    = '10'
    enable32BitAppOnWin64          = 'true'
    managedRuntimeLoader           = 'somedll.dll'
    enableConfigurationOverride    = 'false'
    CLRConfigFile                  = 'CLRConfigFile'
    passAnonymousToken             = 'false'
    logonType                      = 'LogonService'
    manualGroupMembership          = 'true'
    idleTimeout                    = '00:10:00'
    maxProcesses                   = '10'
    shutdownTimeLimit              = '00:10:30'
    startupTimeLimit               = '00:10:30'
    pingingEnabled                 = 'false'
    pingInterval                   = '00:10:30'
    pingResponseTime               = '00:11:30'
    disallowOverlappingRotation    = 'true'
    disallowRotationOnConfigChange = 'true'
    logEventOnRecycle              = 'Time, Memory, ConfigChange, PrivateMemory'
    restartMemoryLimit             = '1'
    restartPrivateMemoryLimit      = '1'
    restartRequestsLimit           = '1'
    restartTimeLimit               = '1.15:00:00'
    restartSchedule                = @('01:00:00','02:00:00')
    loadBalancerCapabilities       = 'TcpLevel'
    orphanWorkerProcess            = 'false'
    orphanActionExe                = 'orphanActionExe.exe'
    orphanActionParams             = '/someparams'
    rapidFailProtection            = 'false'
    rapidFailProtectionInterval    = '00:15:00'
    rapidFailProtectionMaxCrashes  = '15'
    autoShutdownExe                = 'autoShutdownExe'
    autoShutdownParams             = '/autoShutdownParams'
    cpuLimit                       = '1'
    cpuAction                      = 'KillW3wp'
    cpuResetInterval               = '00:15:00'
    cpuSmpAffinitized              = 'true'
    cpuSmpProcessorAffinityMask    = '1'
    cpuSmpProcessorAffinityMask2   = '2'
}

$ConfigData = @{
    AllNodes = @(
        @{
            NodeName                    = '*'
            PSDscAllowPlainTextPassword = $True
        }
        @{
            NodeName     = 'localhost'
        }
    )
}

configuration MSFT_xWebAppPool_Config
{
    Import-DscResource -ModuleName xWebAdministration

    node $AllNodes.NodeName {
        xWebAppPool TestAppPool
        {
            Name                           = $rules.Name
            Ensure                         = $rules.Ensure
            state                          = $rules.state
            autoStart                      = $rules.autoStart
            managedRuntimeVersion          = $rules.managedRuntimeVersion
            managedPipelineMode            = $rules.managedPipelineMode
            startMode                      = $rules.startMode
            identityType                   = $rules.identityType
            loadUserProfile                = $rules.loadUserProfile
            queueLength                    = $rules.queueLength
            enable32BitAppOnWin64          = $rules.enable32BitAppOnWin64
            managedRuntimeLoader           = $rules.managedRuntimeLoader
            enableConfigurationOverride    = $rules.enableConfigurationOverride
            CLRConfigFile                  = $rules.CLRConfigFile
            passAnonymousToken             = $rules.passAnonymousToken
            logonType                      = $rules.logonType
            manualGroupMembership          = $rules.manualGroupMembership
            idleTimeout                    = $rules.idleTimeout
            maxProcesses                   = $rules.maxProcesses
            shutdownTimeLimit              = $rules.shutdownTimeLimit
            startupTimeLimit               = $rules.startupTimeLimit
            pingingEnabled                 = $rules.pingingEnabled
            pingInterval                   = $rules.pingInterval
            pingResponseTime               = $rules.pingResponseTime
            disallowOverlappingRotation    = $rules.disallowOverlappingRotation
            disallowRotationOnConfigChange = $rules.disallowRotationOnConfigChange
            logEventOnRecycle              = $rules.logEventOnRecycle
            restartMemoryLimit             = $rules.restartMemoryLimit
            restartPrivateMemoryLimit      = $rules.restartPrivateMemoryLimit
            restartRequestsLimit           = $rules.restartRequestsLimit
            restartTimeLimit               = $rules.restartTimeLimit
            restartSchedule                = $rules.restartSchedule
            loadBalancerCapabilities       = $rules.loadBalancerCapabilities
            orphanWorkerProcess            = $rules.orphanWorkerProcess
            orphanActionExe                = $rules.orphanActionExe
            orphanActionParams             = $rules.orphanActionParams
            rapidFailProtection            = $rules.rapidFailProtection
            rapidFailProtectionInterval    = $rules.rapidFailProtectionInterval
            rapidFailProtectionMaxCrashes  = $rules.rapidFailProtectionMaxCrashes
            autoShutdownExe                = $rules.autoShutdownExe
            autoShutdownParams             = $rules.autoShutdownParams
            cpuLimit                       = $rules.cpuLimit
            cpuAction                      = $rules.cpuAction
            cpuResetInterval               = $rules.cpuResetInterval
            cpuSmpAffinitized              = $rules.cpuSmpAffinitized
            cpuSmpProcessorAffinityMask    = $rules.cpuSmpProcessorAffinityMask
            cpuSmpProcessorAffinityMask2   = $rules.cpuSmpProcessorAffinityMask2
        }
    }
}
