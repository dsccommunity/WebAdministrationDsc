<#
    .SYNOPSIS
        An example of configuring the application pool default settings.
    .DESCRIPTION
        This examples show how to use xWebAppPoolDefaults for configuring the application pool default settings.
        The resource is currently limited to configuring the managed runtime version and the identity used for the application pools.
#>
Configuration Sample_xWebAppPoolDefaults
{
    param
    (
        # Target nodes to apply the configuration
        [string[]]$NodeName = 'localhost'
    )

    # Import the module that defines custom resources
    Import-DscResource -Module xWebAdministration, PSDesiredStateConfiguration

    Node $NodeName
    {
        # Configures the application pool defaults.
        xWebAppPoolDefaults PoolDefaults
        {
            ApplyTo                        = 'Machine'
            autoStart                      = $true
            CLRConfigFile                  = ''
            enable32BitAppOnWin64          = $false
            enableConfigurationOverride    = $true
            managedPipelineMode            = 'Integrated'
            managedRuntimeLoader           = 'webengine4.dll'
            managedRuntimeVersion          = 'v4.0'
            passAnonymousToken             = $true
            startMode                      = 'OnDemand'
            queueLength                    = 1000
            cpuAction                      = 'NoAction'
            cpuLimit                       = 90000
            cpuResetInterval               = (New-TimeSpan -Minutes 5).ToString()
            cpuSmpAffinitized              = $false
            cpuSmpProcessorAffinityMask    = 4294967295
            cpuSmpProcessorAffinityMask2   = 4294967295
            identityType                   = 'ApplicationPoolIdentity'
            idleTimeout                    = (New-TimeSpan -Minutes 20).ToString()
            idleTimeoutAction              = 'Terminate'
            loadUserProfile                = $true
            logEventOnProcessModel         = 'IdleTimeout'
            logonType                      = 'LogonBatch'
            manualGroupMembership          = $false
            maxProcesses                   = 1
            pingingEnabled                 = $true
            pingInterval                   = (New-TimeSpan -Seconds 30).ToString()
            pingResponseTime               = (New-TimeSpan -Seconds 90).ToString()
            setProfileEnvironment          = $false
            shutdownTimeLimit              = (New-TimeSpan -Seconds 90).ToString()
            startupTimeLimit               = (New-TimeSpan -Seconds 90).ToString()
            orphanActionExe                = ''
            orphanActionParams             = ''
            orphanWorkerProcess            = $false
            loadBalancerCapabilities       = 'HttpLevel'
            rapidFailProtection            = $true
            rapidFailProtectionInterval    = (New-TimeSpan -Minutes 5).ToString()
            rapidFailProtectionMaxCrashes  = 5
            autoShutdownExe                = ''
            autoShutdownParams             = ''
            disallowOverlappingRotation    = $false
            disallowRotationOnConfigChange = $false
            logEventOnRecycle              = 'Time,Requests,Schedule,Memory,IsapiUnhealthy,OnDemand,ConfigChange,PrivateMemory'
            restartMemoryLimit             = 0
            restartPrivateMemoryLimit      = 0
            restartRequestsLimit           = 0
            restartTimeLimit               = (New-TimeSpan -Minutes 1440).ToString()
            restartSchedule                = @('00:00:00', '08:00:00', '16:00:00')
        }

        
    }
}
