# Load the Helper Module
Import-Module $PSScriptRoot\..\Helper.psm1 -Verbose:$false

data LocalizedData
{
    # culture="en-US"
    ConvertFrom-StringData @'
    AppPoolNotFoundError            =   The requested AppPool "{0}" is not found on the target machine.
    AppPoolDiscoveryFailureError    =   Failure to get the requested AppPool "{0}" information from the target machine.
    AppPoolCreationFailureError     =   Failure to successfully create the AppPool "{0}".
    AppPoolRemovalFailureError      =   Failure to successfully remove the AppPool "{0}".
    AppPoolDiscoveryFailure         =   Multiple AppPools contain the name "{0}". Unable to continue.
    AppPoolCompareFailureError      =   Failure to successfully compare properties for AppPool "{0}".
    AppPoolStateFailureError        =   Failure to successfully set the state of the AppPool {0}.
    SetTargetResourceUnInstallwhatIfMessage   =   Trying to remove AppPool "{0}".
    SetTargetResourceInstallwhatIfMessage     =   Trying to create AppPool "{0}".
    TestEnsureState     =   The Ensure state for AppPool "{0}" does not match the desired state.
    TestStateConfig     =   State of AppPool "{0}" does not match the desired state.
    TestAutoStartConfig     = AutoStart of AppPool "{0}" does not match the desired state.
    TestmanagedRuntimeVersionConfig     =   managedRuntimeVersion of AppPool "{0}" does not match the desired state.
    TestmanagedPipelineModeConfig   =   managedPipelineMode of AppPool "{0}" does not match the desired state.
    TeststartModeConfig     =   startMode of AppPool "{0}" does not match the desired state.
    TestidentityTypeConfig  =   identityType of AppPool "{0}" does not match the desired state.
    TestuserNameConfig  =   userName of AppPool "{0}" does not match the desired state.
    TestPasswordConfig  =   Password of AppPool "{0}" does not match the desired state.
    TestloadUserProfileConfig   =   loadUserProfile of AppPool "{0}" does not match the desired state.
    TestqueueLengthConfig   =   queueLength of AppPool "{0}" does not match the desired state.
    Testenable32BitAppOnWin64Config     =   enable32BitAppOnWin64 of AppPool "{0}" does not match the desired state.
    TestmanagedRuntimeLoaderConfig  =   managedRuntimeLoader of AppPool "{0}" does not match the desired state.
    TestenableConfigurationOverrideConfig   =   enableConfigurationOverride of AppPool "{0}" does not match the desired state.
    TestCLRConfigFileConfig     =   CLRConfigFile of AppPool "{0}" does not match the desired state.
    TestpassAnonymousTokenConfig    =   passAnonymousToken of AppPool "{0}" does not match the desired state.
    TestlogonTypeConfig     =   logonType of AppPool "{0}" does not match the desired state.
    TestmanualGroupMembershipConfig     =   manualGroupMembership of AppPool "{0}" does not match the desired state.
    TestidleTimeoutConfig   =   idleTimeout of AppPool "{0}" does not match the desired state.
    TestmaxProcessesConfig  =   maxProcesses of AppPool "{0}" does not match the desired state.
    TestshutdownTimeLimitConfig     =   shutdownTimeLimit of AppPool "{0}" does not match the desired state.
    TeststartupTimeLimitConfig  =   startupTimeLimit of AppPool "{0}" does not match the desired state.
    TestpingingEnabledConfig    =   pingingEnabled of AppPool "{0}" does not match the desired state.
    TestpingIntervalConfig  =   pingInterval of AppPool "{0}" does not match the desired state.
    TestpingResponseTimeConfig  =   pingResponseTime of AppPool "{0}" does not match the desired state.
    TestdisallowOverlappingRotationConfig   =   disallowOverlappingRotation of AppPool "{0}" does not match the desired state.
    TestdisallowRotationOnConfigChangeConfig    =   disallowRotationOnConfigChange of AppPool "{0}" does not match the desired state.
    TestlogEventOnRecycleConfig     =   logEventOnRecycle of AppPool "{0}" does not match the desired state.
    TestrestartMemoryLimitConfig    =   restartMemoryLimit of AppPool "{0}" does not match the desired state.
    TestrestartPrivateMemoryLimitConfig     =   restartPrivateMemoryLimit of AppPool "{0}" does not match the desired state.
    TestrestartRequestsLimitConfig  =   restartRequestsLimit of AppPool "{0}" does not match the desired state.
    TestrestartTimeLimitConfig  =   restartTimeLimit of AppPool "{0}" does not match the desired state.
    TestloadBalancerCapabilitiesConfig  =   loadBalancerCapabilities of AppPool "{0}" does not match the desired state.
    TestorphanWorkerProcessConfig   =   orphanWorkerProcess of AppPool "{0}" does not match the desired state.
    TestorphanActionExeConfig   =   orphanActionExe of AppPool "{0}" does not match the desired state.
    TestorphanActionParamsConfig    =   orphanActionParams of AppPool "{0}" does not match the desired state.
    TestrapidFailProtectionConfig   =   rapidFailProtection of AppPool "{0}" does not match the desired state.
    TestrapidFailProtectionIntervalConfig   =   rapidFailProtectionInterval of AppPool "{0}" does not match the desired state.
    TestrapidFailProtectionMaxCrashesConfig     =   rapidFailProtectionMaxCrashes of AppPool "{0}" does not match the desired state.
    TestautoShutdownExeConfig   =   autoShutdownExe of AppPool "{0}" does not match the desired state.
    TestautoShutdownParamsConfig    =   autoShutdownParams of AppPool "{0}" does not match the desired state.
    TestcpuLimitConfig  =   cpuLimit of AppPool "{0}" does not match the desired state.
    TestcpuActionConfig     =   cpuAction of AppPool "{0}" does not match the desired state.
    TestcpuResetIntervalConfig  =   cpuResetInterval of AppPool "{0}" does not match the desired state.
    TestcpuSmpAffinitizedConfig     =   cpuSmpAffinitized of AppPool "{0}" does not match the desired state.
    TestcpuSmpProcessorAffinityMaskConfig   =   cpuSmpProcessorAffinityMask of AppPool "{0}" does not match the desired state.
    TestcpuSmpProcessorAffinityMask2Config  =   cpuSmpProcessorAffinityMask2 of AppPool "{0}" does not match the desired state.
'@
}

# The Get-TargetResource cmdlet is used to fetch the status of role or AppPool on the target machine.
# It gives the AppPool info of the requested role/feature on the target machine.
function Get-TargetResource
{
    [OutputType([Hashtable])]
    param
    (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string] $Name
    )

    Assert-Module

    #$AppPools = & $env:SystemRoot\system32\inetsrv\appcmd.exe list apppool $Name
    $AppPools = Invoke-AppCmd -Arguments list,apppool,$Name

    if ($AppPools.Count -eq 0) # No AppPool exists with this name.
    {
        $ensureResult = 'Absent';
    }
    elseif ($AppPools.Count -eq 1) # A single AppPool exists with this name.
    {
        $ensureResult = 'Present'
        $AppPoolState = Invoke-AppCmd -Arguments list,apppool,$Name,/text:state
        [xml] $PoolConfig = Invoke-AppCmd -Arguments list,apppool,$Name,/config:*

        if ($PoolConfig.add.processModel.userName)
        {
            $AppPoolPassword = $PoolConfig.add.processModel.password | ConvertTo-SecureString -AsPlainText -Force
            $AppPoolCred = New-Object `
                -TypeName System.Management.Automation.PSCredential `
                -ArgumentList $($PoolConfig.add.processModel.userName, $AppPoolPassword)
        }
        else
        {
            $AppPoolCred = $null
        }

    }
    else # Multiple AppPools with the same name exist. This is not supported and is an error
    {
        $errorId = 'AppPoolDiscoveryFailure';
        $errorCategory = [System.Management.Automation.ErrorCategory]::InvalidResult
        $errorMessage = $($LocalizedData.AppPoolDiscoveryFailure) -f ${Name}
        $exception = New-Object System.InvalidOperationException $errorMessage
        $errorRecord = New-Object System.Management.Automation.ErrorRecord $exception, $errorId, $errorCategory, $null

        $PSCmdlet.ThrowTerminatingError($errorRecord);
    }

    # Add all Website properties to the hash table
    return @{
        Name = $Name;
        Ensure = $ensureResult;
        State = $AppPoolState;
        autoStart = $PoolConfig.add.autoStart;
        managedRuntimeVersion = $PoolConfig.add.managedRuntimeVersion;
        managedPipelineMode = $PoolConfig.add.managedPipelineMode;
        startMode = $PoolConfig.add.startMode;
        identityType = $PoolConfig.add.processModel.identityType;
        userName = $PoolConfig.add.processModel.userName;
        password = $AppPoolCred;
        loadUserProfile = $PoolConfig.add.processModel.loadUserProfile;
        queueLength = $PoolConfig.add.queueLength;
        enable32BitAppOnWin64 = $PoolConfig.add.enable32BitAppOnWin64;
        managedRuntimeLoader = $PoolConfig.add.managedRuntimeLoader;
        enableConfigurationOverride = $PoolConfig.add.enableConfigurationOverride;
        CLRConfigFile = $PoolConfig.add.CLRConfigFile;
        passAnonymousToken = $PoolConfig.add.passAnonymousToken;
        logonType = $PoolConfig.add.processModel.logonType;
        manualGroupMembership = $PoolConfig.add.processModel.manualGroupMembership;
        idleTimeout = $PoolConfig.add.processModel.idleTimeout;
        maxProcesses = $PoolConfig.add.processModel.maxProcesses;
        shutdownTimeLimit = $PoolConfig.add.processModel.shutdownTimeLimit;
        startupTimeLimit = $PoolConfig.add.processModel.startupTimeLimit;
        pingingEnabled = $PoolConfig.add.processModel.pingingEnabled;
        pingInterval = $PoolConfig.add.processModel.pingInterval;
        pingResponseTime = $PoolConfig.add.processModel.pingResponseTime;
        disallowOverlappingRotation = $PoolConfig.add.recycling.disallowOverlappingRotation;
        disallowRotationOnConfigChange = $PoolConfig.add.recycling.disallowRotationOnConfigChange;
        logEventOnRecycle = $PoolConfig.add.recycling.logEventOnRecycle;
        restartMemoryLimit = $PoolConfig.add.recycling.periodicRestart.memory;
        restartPrivateMemoryLimit = $PoolConfig.add.recycling.periodicRestart.privateMemory;
        restartRequestsLimit = $PoolConfig.add.recycling.periodicRestart.requests;
        restartTimeLimit = $PoolConfig.add.recycling.periodicRestart.time;
        restartSchedule = $PoolConfig.add.recycling.periodicRestart.schedule;
        loadBalancerCapabilities = $PoolConfig.add.failure.loadBalancerCapabilities;
        orphanWorkerProcess = $PoolConfig.add.failure.orphanWorkerProcess;
        orphanActionExe = $PoolConfig.add.failure.orphanActionExe;
        orphanActionParams = $PoolConfig.add.failure.orphanActionParams;
        rapidFailProtection = $PoolConfig.add.failure.rapidFailProtection;
        rapidFailProtectionInterval = $PoolConfig.add.failure.rapidFailProtectionInterval;
        rapidFailProtectionMaxCrashes = $PoolConfig.add.failure.rapidFailProtectionMaxCrashes;
        autoShutdownExe = $PoolConfig.add.failure.autoShutdownExe;
        autoShutdownParams = $PoolConfig.add.failure.autoShutdownParams;
        cpuLimit = $PoolConfig.add.cpu.limit;
        cpuAction = $PoolConfig.add.cpu.action;
        cpuResetInterval = $PoolConfig.add.cpu.resetInterval;
        cpuSmpAffinitized = $PoolConfig.add.cpu.smpAffinitized;
        cpuSmpProcessorAffinityMask = $PoolConfig.add.cpu.smpProcessorAffinityMask;
        cpuSmpProcessorAffinityMask2 = $PoolConfig.add.cpu.smpProcessorAffinityMask2;
    }
}


# The Set-TargetResource cmdlet is used to create, delete or configure a website on the target machine.
function Set-TargetResource
{
    [CmdletBinding(SupportsShouldProcess=$true)]
    param
    (
        [ValidateSet("Present", "Absent")]
        [string]$Ensure = "Present",

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Name,

        [ValidateSet("Started","Stopped")]
        [string]$state = "Started",

        [ValidateSet("true","false")]
        [string]$autoStart = "true",

        [ValidateSet("v4.0","v2.0","")]
        [string]$managedRuntimeVersion = "v4.0",

        [ValidateSet("Integrated","Classic")]
        [string]$managedPipelineMode = "Integrated",

        [ValidateSet("AlwaysRunning","OnDemand")]
        [string]$startMode = "OnDemand",

        [ValidateSet("ApplicationPoolIdentity","LocalSystem","LocalService","NetworkService","SpecificUser")]
        [string]$identityType = "ApplicationPoolIdentity",

        [System.Management.Automation.PSCredential] $Credential,

        [ValidateSet("true","false")]
        [string]$loadUserProfile = "true",

        [string]$queueLength = "1000",

        [ValidateSet("true","false")]
        [string]$enable32BitAppOnWin64 = "false",

        [string]$managedRuntimeLoader = "webengine4.dll",

        [ValidateSet("true","false")]
        [string]$enableConfigurationOverride = "true",

        [string]$CLRConfigFile = "",

        [ValidateSet("true","false")]
        [string]$passAnonymousToken = "true",

        [ValidateSet("LogonBatch","LogonService")]
        [string]$logonType = "LogonBatch",

        [ValidateSet("true","false")]
        [string]$manualGroupMembership = "false",

        #Format 00:20:00
        [string]$idleTimeout = "00:20:00",

        [string]$maxProcesses = "1",

        #Format 00:20:00
        [string]$shutdownTimeLimit = "00:01:30",

        #Format 00:20:00
        [string]$startupTimeLimit = "00:01:30",

        [ValidateSet("true","false")]
        [string]$pingingEnabled = "true",

        #Format 00:20:00
        [string]$pingInterval = "00:00:30",

        #Format 00:20:00
        [string]$pingResponseTime = "00:01:30",

        [ValidateSet("true","false")]
        [string]$disallowOverlappingRotation = "false",

        [ValidateSet("true","false")]
        [string]$disallowRotationOnConfigChange = "false",

        #format "Time, Memory, PrivateMemory"
        [string]$logEventOnRecycle = "Time, Memory, PrivateMemory",

        [string]$restartMemoryLimit = "0",

        [string]$restartPrivateMemoryLimit = "0",

        [string]$restartRequestsLimit = "0",

        [string]$restartTimeLimit = "1.05:00:00",

        #Format 00:00:00 24hr clock and must have 00 for seconds
        [string[]]$restartSchedule = @(""),

        [ValidateSet("HttpLevel","TcpLevel")]
        [string]$loadBalancerCapabilities = "HttpLevel",

        [ValidateSet("true","false")]
        [string]$orphanWorkerProcess = "false",

        [string]$orphanActionExe = "",

        [string]$orphanActionParams = "",

        [ValidateSet("true","false")]
        [string]$rapidFailProtection = "true",

        #Format 00:20:00
        [string]$rapidFailProtectionInterval = "00:05:00",

        [string]$rapidFailProtectionMaxCrashes = "5",

        [string]$autoShutdownExe = "",

        [string]$autoShutdownParams = "",

        [string]$cpuLimit = "0",

        [ValidateSet("NoAction","KillW3wp","Throttle","ThrottleUnderLoad")]
        [string]$cpuAction = "NoAction",

        #Format 00:20:00
        [string]$cpuResetInterval = "00:05:00",

        [ValidateSet("true","false")]
        [string]$cpuSmpAffinitized = "false",

        [string]$cpuSmpProcessorAffinityMask = "4294967295",

        [string]$cpuSmpProcessorAffinityMask2 = "4294967295"
    )

    $getTargetResourceResult = $null;

    if($Ensure -eq "Present")
    {
        #Remove Ensure from parameters as it is not needed to create new AppPool
        $Result = $psboundparameters.Remove("Ensure");


        # Check if WebAdministration module is present for IIS cmdlets
        if(!(Get-Module -ListAvailable -Name WebAdministration))
        {
            Throw "Please ensure that WebAdministration module is installed."
        }

        #$AppPool = & $env:SystemRoot\system32\inetsrv\appcmd.exe list apppool $Name
        $AppPool = Invoke-AppCmd -Arguments list,apppool,$Name

        if($AppPool -eq $null) #AppPool doesn't exist so create a new one
        {
            try
            {
                New-WebAppPool $Name
                Wait-Event -Timeout 5
                Stop-WebAppPool $Name

                Write-Verbose("successfully created AppPool $Name")

                #Start site if required
                if($autoStart -eq "true")
                {
                    Start-WebAppPool $Name
                }

                Write-Verbose("successfully started AppPool $Name")

                #$AppPool = & $env:SystemRoot\system32\inetsrv\appcmd.exe list apppool $Name
                $AppPool = Invoke-AppCmd -Arguments list,apppool,$Name
            }
            catch
            {
                $errorId = "AppPoolCreationFailure";
                $errorCategory = [System.Management.Automation.ErrorCategory]::InvalidOperation;
                $errorMessage = $($LocalizedData.FeatureCreationFailureError) -f ${Name} ;
                $exception = New-Object System.InvalidOperationException $errorMessage ;
                $errorRecord = New-Object System.Management.Automation.ErrorRecord $exception, $errorId, $errorCategory, $null

                $PSCmdlet.ThrowTerminatingError($errorRecord);
            }
        }

        if($AppPool -ne $null)
        {
            #update parameters as required

            $UpdateNotRequired = $true

            #get configuration of AppPool
            #[xml] $PoolConfig
            #[xml]$PoolConfig = & $env:SystemRoot\system32\inetsrv\appcmd.exe list apppool $Name /config:*
            [xml]$PoolConfig = Invoke-AppCmd -Arguments list,apppool,$Name,/config:*

            #Update autoStart if required
            if($PoolConfig.add.autoStart -ne $autoStart){
                $UpdateNotRequired = $false
                #& $env:SystemRoot\system32\inetsrv\appcmd.exe set apppool $Name /autoStart:$autoStart
                Invoke-AppCmd -Arguments set,apppool,$Name,/autoStart:$autoStart
            }

            #update managedRuntimeVersion if required
            if($PoolConfig.add.managedRuntimeVersion -ne $managedRuntimeVersion){
                $UpdateNotRequired = $false
                #& $env:SystemRoot\system32\inetsrv\appcmd.exe set apppool $Name /managedRuntimeVersion:$managedRuntimeVersion
                Invoke-AppCmd -Arguments set,apppool,$Name,/managedRuntimeVersion:$managedRuntimeVersion
            }
            #update managedPipelineMode if required
            if($PoolConfig.add.managedPipelineMode -ne $managedPipelineMode){
                $UpdateNotRequired = $false
                #& $env:SystemRoot\system32\inetsrv\appcmd.exe set apppool $Name /managedPipelineMode:$managedPipelineMode
                Invoke-AppCmd -Arguments set,apppool,$Name,/managedPipelineMode:$managedPipelineMode
            }
            #update state if required
            if($AppPoolState -ne $state){
                $UpdateNotRequired = $false
                if($State -eq "Started")
                {
                    start-WebAppPool -Name $Name
                }
                else
                {
                    Stop-WebAppPool -Name $Name
                }
            }
            #update startMode if required
            if($PoolConfig.add.startMode -ne $startMode){
                $UpdateNotRequired = $false
                #& $env:SystemRoot\system32\inetsrv\appcmd.exe set apppool $Name /startMode:$startMode
                Invoke-AppCmd -Arguments set,apppool,$Name,/startMode:$startMode
            }
            #update identityType if required
            if($PoolConfig.add.processModel.identityType -ne $identityType){
                $UpdateNotRequired = $false
                #& $env:SystemRoot\system32\inetsrv\appcmd.exe set apppool $Name /processModel.identityType:$identityType
                Invoke-AppCmd -Arguments set,apppool,$Name,/processModel.identityType:$identityType
            }
            #update userName if required
            if($identityType -eq "SpecificUser" -and $PoolConfig.add.processModel.userName -ne $userName){
                $UpdateNotRequired = $false
                #& $env:SystemRoot\system32\inetsrv\appcmd.exe set apppool $Name /processModel.userName:$userName
                Invoke-AppCmd -Arguments set,apppool,$Name,/processModel.userName:$userName
            }
            #update password if required
            if($identityType -eq "SpecificUser" -and $Password){
                $clearTextPassword = $Password.GetNetworkCredential().Password
                if($clearTextPassword -cne $PoolConfig.add.processModel.password){
                    $UpdateNotRequired = $false
                    #& $env:SystemRoot\system32\inetsrv\appcmd.exe set apppool $Name /processModel.password:$clearTextPassword
                    Invoke-AppCmd -Arguments set,apppool,$Name,/processModel.password:$clearTextPassword
                }

            }

            #update loadUserProfile if required
            if($PoolConfig.add.processModel.loadUserProfile -ne $loadUserProfile){
                $UpdateNotRequired = $false
                #& $env:SystemRoot\system32\inetsrv\appcmd.exe set apppool $Name /processModel.loadUserProfile:$loadUserProfile
                Invoke-AppCmd -Arguments set,apppool,$Name,/processModel.loadUserProfile:$loadUserProfile
            }

            #update queueLength if required
            if($PoolConfig.add.queueLength -ne $queueLength){
                $UpdateNotRequired = $false
                #& $env:SystemRoot\system32\inetsrv\appcmd.exe set apppool $Name /queueLength:$queueLength
                Invoke-AppCmd -Arguments set,apppool,$Name,/queueLength:$queueLength
            }

            #update enable32BitAppOnWin64 if required
            if($PoolConfig.add.enable32BitAppOnWin64 -ne $enable32BitAppOnWin64){
                $UpdateNotRequired = $false
                #& $env:SystemRoot\system32\inetsrv\appcmd.exe set apppool $Name /enable32BitAppOnWin64:$enable32BitAppOnWin64
                Invoke-AppCmd -Arguments set,apppool,$Name,/enable32BitAppOnWin64:$enable32BitAppOnWin64
            }

            #update managedRuntimeLoader if required
            if($PoolConfig.add.managedRuntimeLoader -ne $managedRuntimeLoader){
                $UpdateNotRequired = $false
                #& $env:SystemRoot\system32\inetsrv\appcmd.exe set apppool $Name /managedRuntimeLoader:$managedRuntimeLoader
                Invoke-AppCmd -Arguments set,apppool,$Name,/managedRuntimeLoader:$managedRuntimeLoader
            }

            #update enableConfigurationOverride if required
            if($PoolConfig.add.enableConfigurationOverride -ne $enableConfigurationOverride){
                $UpdateNotRequired = $false
                #& $env:SystemRoot\system32\inetsrv\appcmd.exe set apppool $Name /enableConfigurationOverride:$enableConfigurationOverride
                Invoke-AppCmd -Arguments set,apppool,$Name,/enableConfigurationOverride:$enableConfigurationOverride
            }

            #update CLRConfigFile if required
            if($PoolConfig.add.CLRConfigFile -ne $CLRConfigFile){
                $UpdateNotRequired = $false
                #& $env:SystemRoot\system32\inetsrv\appcmd.exe set apppool $Name /CLRConfigFile:$CLRConfigFile
                Invoke-AppCmd -Arguments set,apppool,$Name,/CLRConfigFile:$CLRConfigFile
            }

            #update passAnonymousToken if required
            if($PoolConfig.add.passAnonymousToken -ne $passAnonymousToken){
                $UpdateNotRequired = $false
                #& $env:SystemRoot\system32\inetsrv\appcmd.exe set apppool $Name /passAnonymousToken:$passAnonymousToken
                Invoke-AppCmd -Arguments set,apppool,$Name,/passAnonymousToken:$passAnonymousToken
            }

            #update logonType if required
            if($PoolConfig.add.processModel.logonType -ne $logonType){
                $UpdateNotRequired = $false
                #& $env:SystemRoot\system32\inetsrv\appcmd.exe set apppool $Name /processModel.logonType:$logonType
                Invoke-AppCmd -Arguments set,apppool,$Name,/processModel.logonType:$logonType
            }

            #update manualGroupMembership if required
            if($PoolConfig.add.processModel.manualGroupMembership -ne $manualGroupMembership){
                $UpdateNotRequired = $false
                #& $env:SystemRoot\system32\inetsrv\appcmd.exe set apppool $Name /processModel.manualGroupMembership:$manualGroupMembership
                Invoke-AppCmd -Arguments set,apppool,$Name,/processModel.manualGroupMembership:$manualGroupMembership
            }

            #update idleTimeout if required
            if($PoolConfig.add.processModel.idleTimeout -ne $idleTimeout){
                $UpdateNotRequired = $false
                #& $env:SystemRoot\system32\inetsrv\appcmd.exe set apppool $Name /processModel.idleTimeout:$idleTimeout
                Invoke-AppCmd -Arguments set,apppool,$Name,/processModel.idleTimeout:$idleTimeout
            }

            #update maxProcesses if required
            if($PoolConfig.add.processModel.maxProcesses -ne $maxProcesses){
                $UpdateNotRequired = $false
                #& $env:SystemRoot\system32\inetsrv\appcmd.exe set apppool $Name /processModel.maxProcesses:$maxProcesses
                Invoke-AppCmd -Arguments set,apppool,$Name,/processModel.maxProcesses:$maxProcesses
            }

            #update shutdownTimeLimit if required
            if($PoolConfig.add.processModel.shutdownTimeLimit -ne $shutdownTimeLimit){
                $UpdateNotRequired = $false
                #& $env:SystemRoot\system32\inetsrv\appcmd.exe set apppool $Name /processModel.shutdownTimeLimit:$shutdownTimeLimit
                Invoke-AppCmd -Arguments set,apppool,$Name,/processModel.shutdownTimeLimit:$shutdownTimeLimit
            }

            #update startupTimeLimit if required
            if($PoolConfig.add.processModel.startupTimeLimit -ne $startupTimeLimit){
                $UpdateNotRequired = $false
                #& $env:SystemRoot\system32\inetsrv\appcmd.exe set apppool $Name /processModel.startupTimeLimit:$startupTimeLimit
                Invoke-AppCmd -Arguments set,apppool,$Name,/processModel.startupTimeLimit:$startupTimeLimit
            }

            #update pingingEnabled if required
            if($PoolConfig.add.processModel.pingingEnabled -ne $pingingEnabled){
                $UpdateNotRequired = $false
                #& $env:SystemRoot\system32\inetsrv\appcmd.exe set apppool $Name /processModel.pingingEnabled:$pingingEnabled
                Invoke-AppCmd -Arguments set,apppool,$Name,/processModel.pingingEnabled:$pingingEnabled
            }

            #update pingInterval if required
            if($PoolConfig.add.processModel.pingInterval -ne $pingInterval){
                $UpdateNotRequired = $false
                #& $env:SystemRoot\system32\inetsrv\appcmd.exe set apppool $Name /processModel.pingInterval:$pingInterval
                Invoke-AppCmd -Arguments set,apppool,$Name,/processModel.pingInterval:$pingInterval
            }

            #update pingResponseTime if required
            if($PoolConfig.add.processModel.pingResponseTime -ne $pingResponseTime){
                $UpdateNotRequired = $false
                #& $env:SystemRoot\system32\inetsrv\appcmd.exe set apppool $Name /processModel.pingResponseTime:$pingResponseTime
                Invoke-AppCmd -Arguments set,apppool,$Name,/processModel.pingResponseTime:$pingResponseTime
            }

            #update disallowOverlappingRotation if required
            if($PoolConfig.add.recycling.disallowOverlappingRotation -ne $disallowOverlappingRotation){
                $UpdateNotRequired = $false
                #& $env:SystemRoot\system32\inetsrv\appcmd.exe set apppool $Name /recycling.disallowOverlappingRotation:$disallowOverlappingRotation
                Invoke-AppCmd -Arguments set,apppool,$Name,/recycling.disallowOverlappingRotation:$disallowOverlappingRotation
            }

            #update disallowRotationOnConfigChange if required
            if($PoolConfig.add.recycling.disallowRotationOnConfigChange -ne $disallowRotationOnConfigChange){
                $UpdateNotRequired = $false
                #& $env:SystemRoot\system32\inetsrv\appcmd.exe set apppool $Name /recycling.disallowRotationOnConfigChange:$disallowRotationOnConfigChange
                Invoke-AppCmd -Arguments set,apppool,$Name,/recycling.disallowRotationOnConfigChange:$disallowRotationOnConfigChange
            }

            #update logEventOnRecycle if required
            if($PoolConfig.add.recycling.logEventOnRecycle -ne $logEventOnRecycle){
                $UpdateNotRequired = $false
                #& $env:SystemRoot\system32\inetsrv\appcmd.exe set apppool $Name /recycling.logEventOnRecycle:$logEventOnRecycle
                Invoke-AppCmd -Arguments set,apppool,$Name,/recycling.logEventOnRecycle:$logEventOnRecycle
            }

            #update restartMemoryLimit if required
            if($PoolConfig.add.recycling.periodicRestart.memory -ne $restartMemoryLimit){
                $UpdateNotRequired = $false
                #& $env:SystemRoot\system32\inetsrv\appcmd.exe set apppool $Name /recycling.periodicRestart.memory:$restartMemoryLimit
                Invoke-AppCmd -Arguments set,apppool,$Name,/recycling.periodicRestart.memory:$restartMemoryLimit
            }

            #update restartPrivateMemoryLimit if required
            if($PoolConfig.add.recycling.periodicRestart.privateMemory -ne $restartPrivateMemoryLimit){
                $UpdateNotRequired = $false
                #& $env:SystemRoot\system32\inetsrv\appcmd.exe set apppool $Name /recycling.periodicRestart.privateMemory:$restartPrivateMemoryLimit
                Invoke-AppCmd -Arguments set,apppool,$Name,/recycling.periodicRestart.privateMemory:$restartPrivateMemoryLimit
            }

            #update restartRequestsLimit if required
            if($PoolConfig.add.recycling.periodicRestart.requests -ne $restartRequestsLimit){
                $UpdateNotRequired = $false
                #& $env:SystemRoot\system32\inetsrv\appcmd.exe set apppool $Name /recycling.periodicRestart.requests:$restartRequestsLimit
                Invoke-AppCmd -Arguments set,apppool,$Name,/recycling.periodicRestart.requests:$restartRequestsLimit
            }

            #update restartTimeLimit if required
            if($PoolConfig.add.recycling.periodicRestart.time -ne $restartTimeLimit){
                $UpdateNotRequired = $false
                #& $env:SystemRoot\system32\inetsrv\appcmd.exe set apppool $Name /recycling.periodicRestart.time:$restartTimeLimit
                Invoke-AppCmd -Arguments set,apppool,$Name,/recycling.periodicRestart.time:$restartTimeLimit
            }

            #update restartSchedule if required
            #clear current schedule
            foreach($schTime in $PoolConfig.add.recycling.periodicRestart.schedule.add.value)
            {
                #& $env:SystemRoot\system32\inetsrv\appcmd.exe set apppool $Name "/-recycling.periodicRestart.schedule.[value='$schTime']"
                Invoke-AppCmd -Arguments set,apppool,$Name,"/-recycling.periodicRestart.schedule.[value='$schTime']"
            }
            #add desired schedule
            foreach($time in $restartSchedule)
            {
                #& $env:SystemRoot\system32\inetsrv\appcmd.exe set apppool $Name "/+recycling.periodicRestart.schedule.[value='$time']"
                Invoke-AppCmd -Arguments set,apppool,$Name,"/+recycling.periodicRestart.schedule.[value='$time']"
            }

            #update loadBalancerCapabilities if required
            if($PoolConfig.add.failure.loadBalancerCapabilities -ne $loadBalancerCapabilities){
                $UpdateNotRequired = $false
                #& $env:SystemRoot\system32\inetsrv\appcmd.exe set apppool $Name /failure.loadBalancerCapabilities:$loadBalancerCapabilities
                Invoke-AppCmd -Arguments set,apppool,$Name,/failure.loadBalancerCapabilities:$loadBalancerCapabilities
            }

            #update orphanWorkerProcess if required
            if($PoolConfig.add.failure.orphanWorkerProcess -ne $orphanWorkerProcess){
                $UpdateNotRequired = $false
                #& $env:SystemRoot\system32\inetsrv\appcmd.exe set apppool $Name /failure.orphanWorkerProcess:$orphanWorkerProcess
                Invoke-AppCmd -Arguments set,apppool,$Name,/failure.orphanWorkerProcess:$orphanWorkerProcess
            }

            #update orphanActionExe if required
            if($PoolConfig.add.failure.orphanActionExe -ne $orphanActionExe){
                $UpdateNotRequired = $false
                #& $env:SystemRoot\system32\inetsrv\appcmd.exe set apppool $Name /failure.orphanActionExe:$orphanActionExe
                Invoke-AppCmd -Arguments set,apppool,$Name,/failure.orphanActionExe:$orphanActionExe
            }

            #update orphanActionParams if required
            if($PoolConfig.add.failure.orphanActionParams -ne $orphanActionParams){
                $UpdateNotRequired = $false
                #& $env:SystemRoot\system32\inetsrv\appcmd.exe set apppool $Name /failure.orphanActionParams:$orphanActionParams
                Invoke-AppCmd -Arguments set,apppool,$Name,/failure.orphanActionParams:$orphanActionParams
            }

            #update rapidFailProtection if required
            if($PoolConfig.add.failure.rapidFailProtection -ne $rapidFailProtection){
                $UpdateNotRequired = $false
                #& $env:SystemRoot\system32\inetsrv\appcmd.exe set apppool $Name /failure.rapidFailProtection:$rapidFailProtection
                Invoke-AppCmd -Arguments set,apppool,$Name,/failure.rapidFailProtection:$rapidFailProtection
            }

            #update rapidFailProtectionInterval if required
            if($PoolConfig.add.failure.rapidFailProtectionInterval -ne $rapidFailProtectionInterval){
                $UpdateNotRequired = $false
                #& $env:SystemRoot\system32\inetsrv\appcmd.exe set apppool $Name /failure.rapidFailProtectionInterval:$rapidFailProtectionInterval
                Invoke-AppCmd -Arguments set,apppool,$Name,/failure.rapidFailProtectionInterval:$rapidFailProtectionInterval
            }

            #update rapidFailProtectionMaxCrashes if required
            if($PoolConfig.add.failure.rapidFailProtectionMaxCrashes -ne $rapidFailProtectionMaxCrashes){
                $UpdateNotRequired = $false
                #& $env:SystemRoot\system32\inetsrv\appcmd.exe set apppool $Name /failure.rapidFailProtectionMaxCrashes:$rapidFailProtectionMaxCrashes
                Invoke-AppCmd -Arguments set,apppool,$Name,/failure.rapidFailProtectionMaxCrashes:$rapidFailProtectionMaxCrashes
            }

            #update autoShutdownExe if required
            if($PoolConfig.add.failure.autoShutdownExe -ne $autoShutdownExe){
                $UpdateNotRequired = $false
                #& $env:SystemRoot\system32\inetsrv\appcmd.exe set apppool $Name /failure.autoShutdownExe:$autoShutdownExe
                Invoke-AppCmd -Arguments set,apppool,$Name,/failure.autoShutdownExe:$autoShutdownExe
            }

            #update autoShutdownParams if required
            if($PoolConfig.add.failure.autoShutdownParams -ne $autoShutdownParams){
                $UpdateNotRequired = $false
                #& $env:SystemRoot\system32\inetsrv\appcmd.exe set apppool $Name /failure.autoShutdownParams:$autoShutdownParams
                Invoke-AppCmd -Arguments set,apppool,$Name,/failure.autoShutdownParams:$autoShutdownParams
            }

            #update cpuLimit if required
            if($PoolConfig.add.cpu.limit -ne $cpuLimit){
                $UpdateNotRequired = $false
                #& $env:SystemRoot\system32\inetsrv\appcmd.exe set apppool $Name /cpu.limit:$cpuLimit
                Invoke-AppCmd -Arguments set,apppool,$Name,/cpu.limit:$cpuLimit
            }

            #update cpuAction if required
            if($PoolConfig.add.cpu.action -ne $cpuAction){
                $UpdateNotRequired = $false
                #& $env:SystemRoot\system32\inetsrv\appcmd.exe set apppool $Name /cpu.action:$cpuAction
                Invoke-AppCmd -Arguments set,apppool,$Name,/cpu.action:$cpuAction
            }

            #update cpuResetInterval if required
            if($PoolConfig.add.cpu.resetInterval -ne $cpuResetInterval){
                $UpdateNotRequired = $false
                #& $env:SystemRoot\system32\inetsrv\appcmd.exe set apppool $Name /cpu.resetInterval:$cpuResetInterval
                Invoke-AppCmd -Arguments set,apppool,$Name,/cpu.resetInterval:$cpuResetInterval
            }

            #update cpuSmpAffinitized if required
            if($PoolConfig.add.cpu.smpAffinitized -ne $cpuSmpAffinitized){
                $UpdateNotRequired = $false
                #& $env:SystemRoot\system32\inetsrv\appcmd.exe set apppool $Name /cpu.smpAffinitized:$cpuSmpAffinitized
                Invoke-AppCmd -Arguments set,apppool,$Name,/cpu.smpAffinitized:$cpuSmpAffinitized
            }

            #update cpuSmpProcessorAffinityMask if required
            if($PoolConfig.add.cpu.smpProcessorAffinityMask -ne $cpuSmpProcessorAffinityMask){
                $UpdateNotRequired = $false
                #& $env:SystemRoot\system32\inetsrv\appcmd.exe set apppool $Name /cpu.smpProcessorAffinityMask:$cpuSmpProcessorAffinityMask
                Invoke-AppCmd -Arguments set,apppool,$Name,/cpu.smpProcessorAffinityMask:$cpuSmpProcessorAffinityMask
            }

            #update cpuSmpProcessorAffinityMask2 if required
            if($PoolConfig.add.cpu.smpProcessorAffinityMask2 -ne $cpuSmpProcessorAffinityMask2){
                $UpdateNotRequired = $false
                #& $env:SystemRoot\system32\inetsrv\appcmd.exe set apppool $Name /cpu.smpProcessorAffinityMask2:$cpuSmpProcessorAffinityMask2
                Invoke-AppCmd -Arguments set,apppool,$Name,/cpu.smpProcessorAffinityMask2:$cpuSmpProcessorAffinityMask2
            }

            if($UpdateNotRequired)
            {
                Write-Verbose("AppPool $Name already exists and properties do not need to be updated.");
            }

        }

    }
    else #Ensure is set to "Absent" so remove website
    {
        try
        {
            #$AppPool = & $env:SystemRoot\system32\inetsrv\appcmd.exe list apppool $Name
            $AppPool = Invoke-AppCmd -Arguments list,apppool,$Name
            if($AppPool -ne $null)
            {
                Stop-WebAppPool $Name
                Remove-WebAppPool $Name

                Write-Verbose("Successfully removed AppPool $Name.")
            }
            else
            {
                Write-Verbose("AppPool $Name does not exist.")
            }
        }
        catch
        {
            $errorId = "AppPoolRemovalFailure";
            $errorCategory = [System.Management.Automation.ErrorCategory]::InvalidOperation;
            $errorMessage = $($LocalizedData.WebsiteRemovalFailureError) -f ${Name} ;
            $exception = New-Object System.InvalidOperationException $errorMessage ;
            $errorRecord = New-Object System.Management.Automation.ErrorRecord $exception, $errorId, $errorCategory, $null

            $PSCmdlet.ThrowTerminatingError($errorRecord);
        }

    }
}


# The Test-TargetResource cmdlet is used to validate if the role or feature is in a state as expected in the instance document.
function Test-TargetResource
{
    [OutputType([bool])]
    param
    (
        [ValidateSet("Present", "Absent")]
        [string] $Ensure = "Present",

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string] $Name,

        [ValidateSet("Started","Stopped")]
        [string] $state = "Started",

        [ValidateSet("true","false")]
        [string] $autoStart = "true",

        [ValidateSet("v4.0","v2.0","")]
        [string] $managedRuntimeVersion = "v4.0",

        [ValidateSet("Integrated","Classic")]
        [string] $managedPipelineMode = "Integrated",

        [ValidateSet("AlwaysRunning","OnDemand")]
        [string] $startMode = "OnDemand",

        [ValidateSet("ApplicationPoolIdentity","LocalSystem","LocalService","NetworkService","SpecificUser")]
        [string] $identityType = "ApplicationPoolIdentity",

        [System.Management.Automation.PSCredential] $Credential,

        [ValidateSet("true","false")]
        [string] $loadUserProfile = "true",

        [string] $queueLength = "1000",

        [ValidateSet("true","false")]
        [string] $enable32BitAppOnWin64 = "false",

        [string] $managedRuntimeLoader = "webengine4.dll",

        [ValidateSet("true","false")]
        [string] $enableConfigurationOverride = "true",

        [string] $CLRConfigFile = "",

        [ValidateSet("true","false")]
        [string] $passAnonymousToken = "true",

        [ValidateSet("LogonBatch","LogonService")]
        [string] $logonType = "LogonBatch",

        [ValidateSet("true","false")]
        [string] $manualGroupMembership = "false",

        #Format 00:20:00
        [string] $idleTimeout = "00:20:00",

        [string] $maxProcesses = "1",

        #Format 00:20:00
        [string] $shutdownTimeLimit = "00:01:30",

        #Format 00:20:00
        [string] $startupTimeLimit = "00:01:30",

        [ValidateSet("true","false")]
        [string] $pingingEnabled = "true",

        #Format 00:20:00
        [string] $pingInterval = "00:00:30",

        #Format 00:20:00
        [string] $pingResponseTime = "00:01:30",

        [ValidateSet("true","false")]
        [string] $disallowOverlappingRotation = "false",

        [ValidateSet("true","false")]
        [string] $disallowRotationOnConfigChange = "false",

        #format "Time, Memory, PrivateMemory"
        [string] $logEventOnRecycle = "Time, Memory, PrivateMemory",

        [string] $restartMemoryLimit = "0",

        [string] $restartPrivateMemoryLimit = "0",

        [string] $restartRequestsLimit = "0",

        [string] $restartTimeLimit = "1.05:00:00",

        #Format 00:00:00 24hr clock and must have 00 for seconds
        [string[]] $restartSchedule = @(""),

        [ValidateSet("HttpLevel","TcpLevel")]
        [string] $loadBalancerCapabilities = "HttpLevel",

        [ValidateSet("true","false")]
        [string] $orphanWorkerProcess = "false",

        [string] $orphanActionExe = "",

        [string] $orphanActionParams = "",

        [ValidateSet("true","false")]
        [string] $rapidFailProtection = "true",

        #Format 00:20:00
        [string] $rapidFailProtectionInterval = "00:05:00",

        [string] $rapidFailProtectionMaxCrashes = "5",

        [string] $autoShutdownExe = "",

        [string] $autoShutdownParams = "",

        [string] $cpuLimit = "0",

        [ValidateSet("NoAction","KillW3wp","Throttle","ThrottleUnderLoad")]
        [string] $cpuAction = "NoAction",

        #Format 00:20:00
        [string] $cpuResetInterval = "00:05:00",

        [ValidateSet("true","false")]
        [string] $cpuSmpAffinitized = "false",

        [string] $cpuSmpProcessorAffinityMask = "4294967295",

        [string] $cpuSmpProcessorAffinityMask2 = "4294967295"
    )

    $DesiredConfigurationMatch = $true

    Assert-Module

    $AppPool = Invoke-AppCmd -Arguments list,apppool,$Name
    if ($AppPool)
    {
        [xml] $PoolConfig = Invoke-AppCmd -Arguments  list,apppool,$Name,/config:*
        $AppPoolState = Invoke-AppCmd -Arguments  list,apppool,$Name,/text:state
    }

    $Stop = $true

    Do
    {
        #Check Ensure
        if (($Ensure -eq 'Present' -and $AppPool -eq $null) -or ($Ensure -eq 'Absent' -and $AppPool -ne $null))
        {
            $DesiredConfigurationMatch = $false
            Write-Verbose -Message $($LocalizedData['TestEnsureState'] -f $Name)
            break
        }

        # Only check properties if $AppPool exists
        if ($AppPool -ne $null)
        {
            # Check state
            if ($AppPoolState -ne $State)
            {
                $DesiredConfigurationMatch = $false
                Write-Verbose -Message $($LocalizedData['TestStateConfig'] -f $Name)
                break
            }

            # Check autoStart
            if ($PoolConfig.add.autoStart -ne $autoStart)
            {
                $DesiredConfigurationMatch = $false
                Write-Verbose -Message $($LocalizedData['TestAutoStartConfig'] -f $Name)
                break
            }

            # Check managedRuntimeVersion
            if ($PoolConfig.add.managedRuntimeVersion -ne $managedRuntimeVersion)
            {
                $DesiredConfigurationMatch = $false
                Write-Verbose -Message $($LocalizedData['TestmanagedRuntimeVersionConfig'] -f $Name)
                break
            }

            # Check managedPipelineMode
            if ($PoolConfig.add.managedPipelineMode -ne $managedPipelineMode)
            {
                $DesiredConfigurationMatch = $false
                Write-Verbose -Message $($LocalizedData['TestmanagedPipelineModeConfig'] -f $Name)
                break
            }

            # Check startMode
            if ($PoolConfig.add.startMode -ne $startMode)
            {
                $DesiredConfigurationMatch = $false
                Write-Verbose -Message $($LocalizedData['TeststartModeConfig'] -f $Name)
                break
            }

            # Check identityType
            if ($PoolConfig.add.processModel.identityType -ne $identityType)
            {
                $DesiredConfigurationMatch = $false
                Write-Verbose -Message $($LocalizedData['TestidentityTypeConfig'] -f $Name)
                break
            }

            # Check userName
            if ($PoolConfig.add.processModel.userName -ne $Credential.UserName)
            {
                $DesiredConfigurationMatch = $false
                Write-Verbose -Message $($LocalizedData['TestuserNameConfig'] -f $Name)
                break
            }

            # Check password
            if ($identityType -eq "SpecificUser" -and $Credential)
            {
                $clearTextPassword = $Credential.GetNetworkCredential().Password
                if ($clearTextPassword -cne $PoolConfig.add.processModel.password)
                {
                    $DesiredConfigurationMatch = $false
                    Write-Verbose -Message $($LocalizedData['TestPasswordConfig'] -f $Name)
                    break
                }
            }

            #Check loadUserProfile
            if($PoolConfig.add.processModel.loadUserProfile -ne $loadUserProfile){
                $DesiredConfigurationMatch = $false
                Write-Verbose -Message $($LocalizedData.loadUserProfile -f $loadUserProfile)
                break
            }

            #Check queueLength
            if($PoolConfig.add.queueLength -ne $queueLength){
               $DesiredConfigurationMatch = $false
                Write-Verbose -Message $($LocalizedData.queueLength -f $queueLength)
                break
            }

            #Check enable32BitAppOnWin64
            if($PoolConfig.add.enable32BitAppOnWin64 -ne $enable32BitAppOnWin64){
               $DesiredConfigurationMatch = $false
                Write-Verbose -Message $($LocalizedData.enable32BitAppOnWin64 -f $enable32BitAppOnWin64)
                break
            }

            #Check managedRuntimeLoader
            if($PoolConfig.add.managedRuntimeLoader -ne $managedRuntimeLoader){
               $DesiredConfigurationMatch = $false
                Write-Verbose -Message $($LocalizedData.managedRuntimeLoader -f $managedRuntimeLoader)
                break
            }

            #Check enableConfigurationOverride
            if($PoolConfig.add.enableConfigurationOverride -ne $enableConfigurationOverride){
                $DesiredConfigurationMatch = $false
                Write-Verbose -Message $($LocalizedData.enableConfigurationOverride -f $enableConfigurationOverride)
                break
            }

            #Check CLRConfigFile
            if($PoolConfig.add.CLRConfigFile -ne $CLRConfigFile){
               $DesiredConfigurationMatch = $false
                Write-Verbose -Message $($LocalizedData.CLRConfigFile -f $CLRConfigFile)
                break
            }

            #Check passAnonymousToken
            if($PoolConfig.add.passAnonymousToken -ne $passAnonymousToken){
                $DesiredConfigurationMatch = $false
                Write-Verbose -Message $($LocalizedData.passAnonymousToken -f $passAnonymousToken)
                break
            }

            #Check logonType
            if($PoolConfig.add.processModel.logonType -ne $logonType){
                $DesiredConfigurationMatch = $false
                Write-Verbose -Message $($LocalizedData.logonType -f $logonType)
                break
            }

            #Check manualGroupMembership
            if($PoolConfig.add.processModel.manualGroupMembership -ne $manualGroupMembership){
                $DesiredConfigurationMatch = $false
                Write-Verbose -Message $($LocalizedData.manualGroupMembership -f $manualGroupMembership)
                break
            }

            #Check idleTimeout
            if($PoolConfig.add.processModel.idleTimeout -ne $idleTimeout){
                $DesiredConfigurationMatch = $false
                Write-Verbose -Message $($LocalizedData.idleTimeout -f $idleTimeout)
                break
            }

            #Check maxProcesses
            if($PoolConfig.add.processModel.maxProcesses -ne $maxProcesses){
                $DesiredConfigurationMatch = $false
                Write-Verbose -Message $($LocalizedData.maxProcesses -f $maxProcesses)
                break
            }

            #Check shutdownTimeLimit
            if($PoolConfig.add.processModel.shutdownTimeLimit -ne $shutdownTimeLimit){
               $DesiredConfigurationMatch = $false
                Write-Verbose -Message $($LocalizedData.shutdownTimeLimit -f $shutdownTimeLimit)
                break
            }

            #Check startupTimeLimit
            if($PoolConfig.add.processModel.startupTimeLimit -ne $startupTimeLimit){
                $DesiredConfigurationMatch = $false
                Write-Verbose -Message $($LocalizedData.startupTimeLimit -f $startupTimeLimit)
                break
            }

            #Check pingingEnabled
            if($PoolConfig.add.processModel.pingingEnabled -ne $pingingEnabled){
               $DesiredConfigurationMatch = $false
                Write-Verbose -Message $($LocalizedData.pingingEnabled -f $pingingEnabled)
                break
            }

            #Check pingInterval
            if($PoolConfig.add.processModel.pingInterval -ne $pingInterval){
                $DesiredConfigurationMatch = $false
                Write-Verbose -Message $($LocalizedData.pingInterval -f $pingInterval)
                break
            }

            #Check pingResponseTime
            if($PoolConfig.add.processModel.pingResponseTime -ne $pingResponseTime){
               $DesiredConfigurationMatch = $false
                Write-Verbose -Message $($LocalizedData.pingResponseTime -f $pingResponseTime)
                break
            }

            #Check disallowOverlappingRotation
            if($PoolConfig.add.recycling.disallowOverlappingRotation -ne $disallowOverlappingRotation){
                $DesiredConfigurationMatch = $false
                Write-Verbose -Message $($LocalizedData.disallowOverlappingRotation -f $disallowOverlappingRotation)
                break
            }

            #Check disallowRotationOnConfigChange
            if($PoolConfig.add.recycling.disallowRotationOnConfigChange -ne $disallowRotationOnConfigChange){
                $DesiredConfigurationMatch = $false
                Write-Verbose -Message $($LocalizedData.disallowRotationOnConfigChange -f $disallowRotationOnConfigChange)
                break
            }

            #Check logEventOnRecycle
            if($PoolConfig.add.recycling.logEventOnRecycle -ne $logEventOnRecycle){
                $DesiredConfigurationMatch = $false
                Write-Verbose -Message $($LocalizedData.logEventOnRecycle -f $logEventOnRecycle)
                break
            }

            #Check restartMemoryLimit
            if($PoolConfig.add.recycling.periodicRestart.memory -ne $restartMemoryLimit){
               $DesiredConfigurationMatch = $false
                Write-Verbose -Message $($LocalizedData.restartMemoryLimit -f $restartMemoryLimit)
                break
            }

            #Check restartPrivateMemoryLimit
            if($PoolConfig.add.recycling.periodicRestart.privateMemory -ne $restartPrivateMemoryLimit){
                $DesiredConfigurationMatch = $false
                Write-Verbose -Message $($LocalizedData.restartPrivateMemoryLimit -f $restartPrivateMemoryLimit)
                break
            }

            #Check restartRequestsLimit
            if($PoolConfig.add.recycling.periodicRestart.requests -ne $restartRequestsLimit){
                $DesiredConfigurationMatch = $false
                Write-Verbose -Message $($LocalizedData.restartRequestsLimit -f $restartRequestsLimit)
                break
            }

            #Check restartTimeLimit
            if($PoolConfig.add.recycling.periodicRestart.time -ne $restartTimeLimit){
                $DesiredConfigurationMatch = $false
                Write-Verbose -Message $($LocalizedData.restartTimeLimit -f $restartTimeLimit)
                break
            }

            #Check restartSchedule
            if(($PoolConfig.add.recycling.periodicRestart.schedule.add.value -ne $null) -and ((Compare-Object $restartSchedule $PoolConfig.add.recycling.periodicRestart.schedule.add.value) -ne $null)){
                $DesiredConfigurationMatch = $false
                Write-Verbose -Message $($LocalizedData.restartTimeLimit -f $restartTimeLimit)
                break
            }
            if(($PoolConfig.add.recycling.periodicRestart.schedule.add.value -eq $null) -and ($restartSchedule -ne $null)){
                $DesiredConfigurationMatch = $false
                Write-Verbose -Message $($LocalizedData.restartTimeLimit -f $restartTimeLimit)
                break
            }

            #Check loadBalancerCapabilities
            if($PoolConfig.add.failure.loadBalancerCapabilities -ne $loadBalancerCapabilities){
                $DesiredConfigurationMatch = $false
                Write-Verbose -Message $($LocalizedData.loadBalancerCapabilities -f $loadBalancerCapabilities)
                break
            }

            #Check orphanWorkerProcess
            if($PoolConfig.add.failure.orphanWorkerProcess -ne $orphanWorkerProcess){
               $DesiredConfigurationMatch = $false
                Write-Verbose -Message $($LocalizedData.orphanWorkerProcess -f $orphanWorkerProcess)
                break
            }

            #Check orphanActionExe
            if($PoolConfig.add.failure.orphanActionExe -ne $orphanActionExe){
                $DesiredConfigurationMatch = $false
                Write-Verbose -Message $($LocalizedData.orphanActionExe -f $orphanActionExe)
                break
            }

            #Check orphanActionParams
            if($PoolConfig.add.failure.orphanActionParams -ne $orphanActionParams){
                $DesiredConfigurationMatch = $false
                Write-Verbose -Message $($LocalizedData.orphanActionParams -f $orphanActionParams)
                break
            }

            #Check rapidFailProtection
            if($PoolConfig.add.failure.rapidFailProtection -ne $rapidFailProtection){
                $DesiredConfigurationMatch = $false
                Write-Verbose -Message $($LocalizedData.rapidFailProtection -f $rapidFailProtection)
                break
            }

            #Check rapidFailProtectionInterval
            if($PoolConfig.add.failure.rapidFailProtectionInterval -ne $rapidFailProtectionInterval){
               $DesiredConfigurationMatch = $false
                Write-Verbose -Message $($LocalizedData.rapidFailProtectionInterval -f $rapidFailProtectionInterval)
                break
            }

            #Check rapidFailProtectionMaxCrashes
            if($PoolConfig.add.failure.rapidFailProtectionMaxCrashes -ne $rapidFailProtectionMaxCrashes){
                $DesiredConfigurationMatch = $false
                Write-Verbose -Message $($LocalizedData.rapidFailProtectionMaxCrashes -f $rapidFailProtectionMaxCrashes)
                break
            }

            #Check autoShutdownExe
            if($PoolConfig.add.failure.autoShutdownExe -ne $autoShutdownExe){
               $DesiredConfigurationMatch = $false
                Write-Verbose -Message $($LocalizedData.autoShutdownExe -f $autoShutdownExe)
                break
            }

            #Check autoShutdownParams
            if($PoolConfig.add.failure.autoShutdownParams -ne $autoShutdownParams){
                $DesiredConfigurationMatch = $false
                Write-Verbose -Message $($LocalizedData.autoShutdownParams -f $autoShutdownParams)
                break
            }

            #Check cpuLimit
            if($PoolConfig.add.cpu.limit -ne $cpuLimit){
               $DesiredConfigurationMatch = $false
                Write-Verbose -Message $($LocalizedData.cpuLimit -f $cpuLimit)
                break
            }

            #Check cpuAction
            if($PoolConfig.add.cpu.action -ne $cpuAction){
               $DesiredConfigurationMatch = $false
                Write-Verbose -Message $($LocalizedData.cpuAction -f $cpuAction)
                break
            }

            #Check cpuResetInterval
            if($PoolConfig.add.cpu.resetInterval -ne $cpuResetInterval){
               $DesiredConfigurationMatch = $false
                Write-Verbose -Message $($LocalizedData.cpuResetInterval -f $cpuResetInterval)
                break
            }

            #Check cpuSmpAffinitized
            if($PoolConfig.add.cpu.smpAffinitized -ne $cpuSmpAffinitized){
                $DesiredConfigurationMatch = $false
                Write-Verbose -Message $($LocalizedData.cpuSmpAffinitized -f $cpuSmpAffinitized)
                break
            }

            #Check cpuSmpProcessorAffinityMask
            if($PoolConfig.add.cpu.smpProcessorAffinityMask -ne $cpuSmpProcessorAffinityMask){
                $DesiredConfigurationMatch = $false
                Write-Verbose -Message $($LocalizedData.cpuSmpProcessorAffinityMask -f $cpuSmpProcessorAffinityMask)
                break
            }

            #Check cpuSmpProcessorAffinityMask2
            if($PoolConfig.add.cpu.smpProcessorAffinityMask2 -ne $cpuSmpProcessorAffinityMask2){
               $DesiredConfigurationMatch = $false
                Write-Verbose -Message $($LocalizedData.cpuSmpProcessorAffinityMask2 -f $cpuSmpProcessorAffinityMask2)
                break
            }
        }

        $Stop = $false
    }
    While($Stop)

    return $DesiredConfigurationMatch
}

function Invoke-AppCmd
{
    param
    (
        [string[]] $Arguments,
        [string] $Path = "$env:SystemRoot\system32\inetsrv\appcmd.exe"
    )

    if (Test-Path $Path)
    {
        & $Path $Arguments
    }
    else
    {
        throw "$Path does not exist"
    }
}
