data LocalizedData
{
    # culture="en-US"
    ConvertFrom-StringData @'
SetTargetResourceInstallwhatIfMessage=Trying to create AppPool "{0}".
SetTargetResourceUnInstallwhatIfMessage=Trying to remove AppPool "{0}".
AppPoolNotFoundError=The requested AppPool "{0}" is not found on the target machine.
AppPoolDiscoveryFailureError=Failure to get the requested AppPool "{0}" information from the target machine.
AppPoolCreationFailureError=Failure to successfully create the AppPool "{0}".
AppPoolRemovalFailureError=Failure to successfully remove the AppPool "{0}".
AppPoolUpdateFailureError=Failure to successfully update the properties for AppPool "{0}".
AppPoolCompareFailureError=Failure to successfully compare properties for AppPool "{0}".
AppPoolStateFailureError=Failure to successfully set the state of the AppPool {0}.
'@
}

# The Get-TargetResource cmdlet is used to fetch the status of role or AppPool on the target machine.
# It gives the AppPool info of the requested role/feature on the target machine.  
function Get-TargetResource 
{
    [OutputType([hashtable])]
    param 
    (   
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Name
    )

        $getTargetResourceResult = $null;

        # Check if WebAdministration module is present for IIS cmdlets
        if(!(Get-Module -ListAvailable -Name WebAdministration))
        {
            Throw "Please ensure that WebAdministration module is installed."
        }

        $AppPools = & $env:SystemRoot\system32\inetsrv\appcmd.exe list apppool $Name

        if ($AppPools.count -eq 0) # No AppPool exists with this name.
        {
            $ensureResult = "Absent";
        }
        elseif ($AppPools.count -eq 1) # A single AppPool exists with this name.
        {
            $ensureResult = "Present"
             $AppPoolState = & $env:SystemRoot\system32\inetsrv\appcmd.exe list apppool $Name /text:state
            [xml] $PoolConfig
            $PoolConfig = & $env:SystemRoot\system32\inetsrv\appcmd.exe list apppool $Name /config:*
            if($PoolConfig.add.processModel.userName){
                $AppPoolPassword = $PoolConfig.add.processModel.password | ConvertTo-SecureString -AsPlainText -Force
                $AppPoolCred = new-object -typename System.Management.Automation.PSCredential -argumentlist $PoolConfig.add.processModel.userName,$AppPoolPassword
            }
            else{
                $AppPoolCred =$null
            }

        }
        else # Multiple AppPools with the same name exist. This is not supported and is an error
        {
            $errorId = "AppPoolDiscoveryFailure"; 
            $errorCategory = [System.Management.Automation.ErrorCategory]::InvalidResult
            $errorMessage = $($LocalizedData.AppPoolUpdateFailureError) -f ${Name} 
            $exception = New-Object System.InvalidOperationException $errorMessage 
            $errorRecord = New-Object System.Management.Automation.ErrorRecord $exception, $errorId, $errorCategory, $null

            $PSCmdlet.ThrowTerminatingError($errorRecord);
        }

        # Add all Website properties to the hash table
        $getTargetResourceResult = @{
                                        Name = $PoolConfig.add.name; 
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
        
        return $getTargetResourceResult;
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

        [string]$userName,

        [System.Management.Automation.PSCredential]
        $Password,

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

        $AppPool = & $env:SystemRoot\system32\inetsrv\appcmd.exe list apppool $Name

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

                $AppPool = & $env:SystemRoot\system32\inetsrv\appcmd.exe list apppool $Name
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
            [xml]$PoolConfig = & $env:SystemRoot\system32\inetsrv\appcmd.exe list apppool $Name /config:*

            #Update autoStart if required
            if($PoolConfig.add.autoStart -ne $autoStart){
                $UpdateNotRequired = $false
                & $env:SystemRoot\system32\inetsrv\appcmd.exe set apppool $Name /autoStart:$autoStart
            }

            #update managedRuntimeVersion if required
            if($PoolConfig.add.managedRuntimeVersion -ne $managedRuntimeVersion){
                $UpdateNotRequired = $false
                & $env:SystemRoot\system32\inetsrv\appcmd.exe set apppool $Name /managedRuntimeVersion:$managedRuntimeVersion
            }
            #update managedPipelineMode if required
            if($PoolConfig.add.managedPipelineMode -ne $managedPipelineMode){
                $UpdateNotRequired = $false
                & $env:SystemRoot\system32\inetsrv\appcmd.exe set apppool $Name /managedPipelineMode:$managedPipelineMode
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
                & $env:SystemRoot\system32\inetsrv\appcmd.exe set apppool $Name /startMode:$startMode
            }
            #update identityType if required
            if($PoolConfig.add.processModel.identityType -ne $identityType){
                $UpdateNotRequired = $false
                & $env:SystemRoot\system32\inetsrv\appcmd.exe set apppool $Name /processModel.identityType:$identityType
            }
            #update userName if required
            if($identityType -eq "SpecificUser" -and $PoolConfig.add.processModel.userName -ne $userName){
                $UpdateNotRequired = $false
                & $env:SystemRoot\system32\inetsrv\appcmd.exe set apppool $Name /processModel.userName:$userName
            }
            #update password if required
            if($identityType -eq "SpecificUser" -and $Password){
                $clearTextPassword = $Password.GetNetworkCredential().Password
                if($clearTextPassword -cne $PoolConfig.add.processModel.password){
                    $UpdateNotRequired = $false
                    & $env:SystemRoot\system32\inetsrv\appcmd.exe set apppool $Name /processModel.password:$clearTextPassword
                }

            }

            #update loadUserProfile if required
            if($PoolConfig.add.processModel.loadUserProfile -ne $loadUserProfile){
                $UpdateNotRequired = $false
                & $env:SystemRoot\system32\inetsrv\appcmd.exe set apppool $Name /processModel.loadUserProfile:$loadUserProfile
            }

            #update queueLength if required
            if($PoolConfig.add.queueLength -ne $queueLength){
                $UpdateNotRequired = $false
                & $env:SystemRoot\system32\inetsrv\appcmd.exe set apppool $Name /queueLength:$queueLength
            }

            #update enable32BitAppOnWin64 if required
            if($PoolConfig.add.enable32BitAppOnWin64 -ne $enable32BitAppOnWin64){
                $UpdateNotRequired = $false
                & $env:SystemRoot\system32\inetsrv\appcmd.exe set apppool $Name /enable32BitAppOnWin64:$enable32BitAppOnWin64
            }
            
            #update managedRuntimeLoader if required
            if($PoolConfig.add.managedRuntimeLoader -ne $managedRuntimeLoader){
                $UpdateNotRequired = $false
                & $env:SystemRoot\system32\inetsrv\appcmd.exe set apppool $Name /managedRuntimeLoader:$managedRuntimeLoader
            }
            
            #update enableConfigurationOverride if required
            if($PoolConfig.add.enableConfigurationOverride -ne $enableConfigurationOverride){
                $UpdateNotRequired = $false
                & $env:SystemRoot\system32\inetsrv\appcmd.exe set apppool $Name /enableConfigurationOverride:$enableConfigurationOverride
            }
            
            #update CLRConfigFile if required
            if($PoolConfig.add.CLRConfigFile -ne $CLRConfigFile){
                $UpdateNotRequired = $false
                & $env:SystemRoot\system32\inetsrv\appcmd.exe set apppool $Name /CLRConfigFile:$CLRConfigFile
            }
            
            #update passAnonymousToken if required
            if($PoolConfig.add.passAnonymousToken -ne $passAnonymousToken){
                $UpdateNotRequired = $false
                & $env:SystemRoot\system32\inetsrv\appcmd.exe set apppool $Name /passAnonymousToken:$passAnonymousToken
            }

            #update logonType if required
            if($PoolConfig.add.processModel.logonType -ne $logonType){
                $UpdateNotRequired = $false
                & $env:SystemRoot\system32\inetsrv\appcmd.exe set apppool $Name /processModel.logonType:$logonType
            }

            #update manualGroupMembership if required
            if($PoolConfig.add.processModel.manualGroupMembership -ne $manualGroupMembership){
                $UpdateNotRequired = $false
                & $env:SystemRoot\system32\inetsrv\appcmd.exe set apppool $Name /processModel.manualGroupMembership:$manualGroupMembership
            }

            #update idleTimeout if required
            if($PoolConfig.add.processModel.idleTimeout -ne $idleTimeout){
                $UpdateNotRequired = $false
                & $env:SystemRoot\system32\inetsrv\appcmd.exe set apppool $Name /processModel.idleTimeout:$idleTimeout
            }

            #update maxProcesses if required
            if($PoolConfig.add.processModel.maxProcesses -ne $maxProcesses){
                $UpdateNotRequired = $false
                & $env:SystemRoot\system32\inetsrv\appcmd.exe set apppool $Name /processModel.maxProcesses:$maxProcesses
            }

            #update shutdownTimeLimit if required
            if($PoolConfig.add.processModel.shutdownTimeLimit -ne $shutdownTimeLimit){
                $UpdateNotRequired = $false
                & $env:SystemRoot\system32\inetsrv\appcmd.exe set apppool $Name /processModel.shutdownTimeLimit:$shutdownTimeLimit
            }

            #update startupTimeLimit if required
            if($PoolConfig.add.processModel.startupTimeLimit -ne $startupTimeLimit){
                $UpdateNotRequired = $false
                & $env:SystemRoot\system32\inetsrv\appcmd.exe set apppool $Name /processModel.startupTimeLimit:$startupTimeLimit
            }

            #update pingingEnabled if required
            if($PoolConfig.add.processModel.pingingEnabled -ne $pingingEnabled){
                $UpdateNotRequired = $false
                & $env:SystemRoot\system32\inetsrv\appcmd.exe set apppool $Name /processModel.pingingEnabled:$pingingEnabled
            }

            #update pingInterval if required
            if($PoolConfig.add.processModel.pingInterval -ne $pingInterval){
                $UpdateNotRequired = $false
                & $env:SystemRoot\system32\inetsrv\appcmd.exe set apppool $Name /processModel.pingInterval:$pingInterval
            }

            #update pingResponseTime if required
            if($PoolConfig.add.processModel.pingResponseTime -ne $pingResponseTime){
                $UpdateNotRequired = $false
                & $env:SystemRoot\system32\inetsrv\appcmd.exe set apppool $Name /processModel.pingResponseTime:$pingResponseTime
            }

            #update disallowOverlappingRotation if required
            if($PoolConfig.add.recycling.disallowOverlappingRotation -ne $disallowOverlappingRotation){
                $UpdateNotRequired = $false
                & $env:SystemRoot\system32\inetsrv\appcmd.exe set apppool $Name /recycling.disallowOverlappingRotation:$disallowOverlappingRotation
            }

            #update disallowRotationOnConfigChange if required
            if($PoolConfig.add.recycling.disallowRotationOnConfigChange -ne $disallowRotationOnConfigChange){
                $UpdateNotRequired = $false
                & $env:SystemRoot\system32\inetsrv\appcmd.exe set apppool $Name /recycling.disallowRotationOnConfigChange:$disallowRotationOnConfigChange
            }

            #update logEventOnRecycle if required
            if($PoolConfig.add.recycling.logEventOnRecycle -ne $logEventOnRecycle){
                $UpdateNotRequired = $false
                & $env:SystemRoot\system32\inetsrv\appcmd.exe set apppool $Name /recycling.logEventOnRecycle:$logEventOnRecycle
            }

            #update restartMemoryLimit if required
            if($PoolConfig.add.recycling.periodicRestart.memory -ne $restartMemoryLimit){
                $UpdateNotRequired = $false
                & $env:SystemRoot\system32\inetsrv\appcmd.exe set apppool $Name /recycling.periodicRestart.memory:$restartMemoryLimit
            }

            #update restartPrivateMemoryLimit if required
            if($PoolConfig.add.recycling.periodicRestart.privateMemory -ne $restartPrivateMemoryLimit){
                $UpdateNotRequired = $false
                & $env:SystemRoot\system32\inetsrv\appcmd.exe set apppool $Name /recycling.periodicRestart.privateMemory:$restartPrivateMemoryLimit
            }

            #update restartRequestsLimit if required
            if($PoolConfig.add.recycling.periodicRestart.requests -ne $restartRequestsLimit){
                $UpdateNotRequired = $false
                & $env:SystemRoot\system32\inetsrv\appcmd.exe set apppool $Name /recycling.periodicRestart.requests:$restartRequestsLimit
            }

            #update restartTimeLimit if required
            if($PoolConfig.add.recycling.periodicRestart.time -ne $restartTimeLimit){
                $UpdateNotRequired = $false
                & $env:SystemRoot\system32\inetsrv\appcmd.exe set apppool $Name /recycling.periodicRestart.time:$restartTimeLimit
            }

            #update restartSchedule if required
            #clear current schedule
            foreach($schTime in $PoolConfig.add.recycling.periodicRestart.schedule.add.value)
            {
                & $env:SystemRoot\system32\inetsrv\appcmd.exe set apppool $Name "/-recycling.periodicRestart.schedule.[value='$schTime']"
            }
            #add desired schedule
            foreach($time in $restartSchedule)
            {
                & $env:SystemRoot\system32\inetsrv\appcmd.exe set apppool $Name "/+recycling.periodicRestart.schedule.[value='$time']"                
            }
            
            #update loadBalancerCapabilities if required
            if($PoolConfig.add.failure.loadBalancerCapabilities -ne $loadBalancerCapabilities){
                $UpdateNotRequired = $false
                & $env:SystemRoot\system32\inetsrv\appcmd.exe set apppool $Name /failure.loadBalancerCapabilities:$loadBalancerCapabilities
            }

            #update orphanWorkerProcess if required
            if($PoolConfig.add.failure.orphanWorkerProcess -ne $orphanWorkerProcess){
                $UpdateNotRequired = $false
                & $env:SystemRoot\system32\inetsrv\appcmd.exe set apppool $Name /failure.orphanWorkerProcess:$orphanWorkerProcess
            }

            #update orphanActionExe if required
            if($PoolConfig.add.failure.orphanActionExe -ne $orphanActionExe){
                $UpdateNotRequired = $false
                & $env:SystemRoot\system32\inetsrv\appcmd.exe set apppool $Name /failure.orphanActionExe:$orphanActionExe
            }

            #update orphanActionParams if required
            if($PoolConfig.add.failure.orphanActionParams -ne $orphanActionParams){
                $UpdateNotRequired = $false
                & $env:SystemRoot\system32\inetsrv\appcmd.exe set apppool $Name /failure.orphanActionParams:$orphanActionParams
            }

            #update rapidFailProtection if required
            if($PoolConfig.add.failure.rapidFailProtection -ne $rapidFailProtection){
                $UpdateNotRequired = $false
                & $env:SystemRoot\system32\inetsrv\appcmd.exe set apppool $Name /failure.rapidFailProtection:$rapidFailProtection
            }

            #update rapidFailProtectionInterval if required
            if($PoolConfig.add.failure.rapidFailProtectionInterval -ne $rapidFailProtectionInterval){
                $UpdateNotRequired = $false
                & $env:SystemRoot\system32\inetsrv\appcmd.exe set apppool $Name /failure.rapidFailProtectionInterval:$rapidFailProtectionInterval
            }

            #update rapidFailProtectionMaxCrashes if required
            if($PoolConfig.add.failure.rapidFailProtectionMaxCrashes -ne $rapidFailProtectionMaxCrashes){
                $UpdateNotRequired = $false
                & $env:SystemRoot\system32\inetsrv\appcmd.exe set apppool $Name /failure.rapidFailProtectionMaxCrashes:$rapidFailProtectionMaxCrashes
            }

            #update autoShutdownExe if required
            if($PoolConfig.add.failure.autoShutdownExe -ne $autoShutdownExe){
                $UpdateNotRequired = $false
                & $env:SystemRoot\system32\inetsrv\appcmd.exe set apppool $Name /failure.autoShutdownExe:$autoShutdownExe
            }

            #update autoShutdownParams if required
            if($PoolConfig.add.failure.autoShutdownParams -ne $autoShutdownParams){
                $UpdateNotRequired = $false
                & $env:SystemRoot\system32\inetsrv\appcmd.exe set apppool $Name /failure.autoShutdownParams:$autoShutdownParams
            }

            #update cpuLimit if required
            if($PoolConfig.add.cpu.limit -ne $cpuLimit){
                $UpdateNotRequired = $false
                & $env:SystemRoot\system32\inetsrv\appcmd.exe set apppool $Name /cpu.limit:$cpuLimit
            }

            #update cpuAction if required
            if($PoolConfig.add.cpu.action -ne $cpuAction){
                $UpdateNotRequired = $false
                & $env:SystemRoot\system32\inetsrv\appcmd.exe set apppool $Name /cpu.action:$cpuAction
            }

            #update cpuResetInterval if required
            if($PoolConfig.add.cpu.resetInterval -ne $cpuResetInterval){
                $UpdateNotRequired = $false
                & $env:SystemRoot\system32\inetsrv\appcmd.exe set apppool $Name /cpu.resetInterval:$cpuResetInterval
            }

            #update cpuSmpAffinitized if required
            if($PoolConfig.add.cpu.smpAffinitized -ne $cpuSmpAffinitized){
                $UpdateNotRequired = $false
                & $env:SystemRoot\system32\inetsrv\appcmd.exe set apppool $Name /cpu.smpAffinitized:$cpuSmpAffinitized
            }

            #update cpuSmpProcessorAffinityMask if required
            if($PoolConfig.add.cpu.smpProcessorAffinityMask -ne $cpuSmpProcessorAffinityMask){
                $UpdateNotRequired = $false
                & $env:SystemRoot\system32\inetsrv\appcmd.exe set apppool $Name /cpu.smpProcessorAffinityMask:$cpuSmpProcessorAffinityMask
            }

            #update cpuSmpProcessorAffinityMask2 if required
            if($PoolConfig.add.cpu.smpProcessorAffinityMask2 -ne $cpuSmpProcessorAffinityMask2){
                $UpdateNotRequired = $false
                & $env:SystemRoot\system32\inetsrv\appcmd.exe set apppool $Name /cpu.smpProcessorAffinityMask2:$cpuSmpProcessorAffinityMask2
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
            $AppPool = & $env:SystemRoot\system32\inetsrv\appcmd.exe list apppool $Name
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

        [string]$userName,

        [System.Management.Automation.PSCredential]
        $Password,

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
 
    $DesiredConfigurationMatch = $true

    # Check if WebAdministration module is present for IIS cmdlets
    if(!(Get-Module -ListAvailable -Name WebAdministration))
    {
        Throw "Please ensure that WebAdministration module is installed."
    }
    
    $AppPool = & $env:SystemRoot\system32\inetsrv\appcmd.exe list apppool $Name
    if($AppPool){
        #get configuration of AppPool
        #[xml] $PoolConfig
        [xml]$PoolConfig = & $env:SystemRoot\system32\inetsrv\appcmd.exe list apppool $Name /config:*
        $AppPoolState = & $env:SystemRoot\system32\inetsrv\appcmd.exe list apppool $Name /text:state
    }
    $Stop = $true

    Do
    {
        #Check Ensure
        if(($Ensure -eq "Present" -and $AppPool -eq $null) -or ($Ensure -eq "Absent" -and $AppPool -ne $null))
        {
            $DesiredConfigurationMatch = $false
            Write-Verbose("The Ensure state for AppPool $Name does not match the desired state.");
            break
        }

        # Only check properties if $AppPool exists
        if ($AppPool -ne $null)
        {
            #Check autoStart
            if($PoolConfig.add.autoStart -ne $autoStart){
                $DesiredConfigurationMatch = $false
                Write-Verbose("autoStart of AppPool $Name does not match the desired state.");
                break
            }

            #Check managedRuntimeVersion 
            if($PoolConfig.add.managedRuntimeVersion -ne $managedRuntimeVersion){
                $DesiredConfigurationMatch = $false
                Write-Verbose("managedRuntimeVersion of AppPool $Name does not match the desired state.");
                break
            }
            
            #Check managedPipelineMode 
            if($PoolConfig.add.managedPipelineMode -ne $managedPipelineMode){
                $DesiredConfigurationMatch = $false
                Write-Verbose("managedPipelineMode of AppPool $Name does not match the desired state.");
                break
            }
            
            #Check state 
            if($AppPoolState -ne $state){
                $DesiredConfigurationMatch = $false
                Write-Verbose("state of AppPool $Name does not match the desired state.");
                break
            }
            
            #Check startMode 
            if($PoolConfig.add.startMode -ne $startMode){
                $DesiredConfigurationMatch = $false
                Write-Verbose("startMode of AppPool $Name does not match the desired state.");
                break
            }
            
            #Check identityType 
            if($PoolConfig.add.processModel.identityType -ne $identityType){
                $DesiredConfigurationMatch = $false
                Write-Verbose("identityType of AppPool $Name does not match the desired state.");
                break
            }
            
            #Check userName 
            if($PoolConfig.add.processModel.userName -ne $userName){
                $DesiredConfigurationMatch = $false
                Write-Verbose("userName of AppPool $Name does not match the desired state.");
                break
            }
            
            #Check password 
            if($identityType -eq "SpecificUser" -and $Password){
                $clearTextPassword = $Password.GetNetworkCredential().Password
                if($clearTextPassword -cne $PoolConfig.add.processModel.password){
                    $DesiredConfigurationMatch = $false
                    Write-Verbose("Password of AppPool $Name does not match the desired state.");
                    break
                }
            }
            
            #Check loadUserProfile 
            if($PoolConfig.add.processModel.loadUserProfile -ne $loadUserProfile){
                $DesiredConfigurationMatch = $false
                Write-Verbose("loadUserProfile of AppPool $Name does not match the desired state.");
                break
            }

            #Check queueLength 
            if($PoolConfig.add.queueLength -ne $queueLength){
               $DesiredConfigurationMatch = $false
                Write-Verbose("queueLength of AppPool $Name does not match the desired state.");
                break
            }

            #Check enable32BitAppOnWin64 
            if($PoolConfig.add.enable32BitAppOnWin64 -ne $enable32BitAppOnWin64){
               $DesiredConfigurationMatch = $false
                Write-Verbose("enable32BitAppOnWin64 of AppPool $Name does not match the desired state.");
                break
            }
            
            #Check managedRuntimeLoader 
            if($PoolConfig.add.managedRuntimeLoader -ne $managedRuntimeLoader){
               $DesiredConfigurationMatch = $false
                Write-Verbose("managedRuntimeLoader of AppPool $Name does not match the desired state.");
                break
            }
            
            #Check enableConfigurationOverride 
            if($PoolConfig.add.enableConfigurationOverride -ne $enableConfigurationOverride){
                $DesiredConfigurationMatch = $false
                Write-Verbose("enableConfigurationOverride of AppPool $Name does not match the desired state.");
                break
            }
            
            #Check CLRConfigFile 
            if($PoolConfig.add.CLRConfigFile -ne $CLRConfigFile){
               $DesiredConfigurationMatch = $false
                Write-Verbose("CLRConfigFile of AppPool $Name does not match the desired state.");
                break
            }
            
            #Check passAnonymousToken 
            if($PoolConfig.add.passAnonymousToken -ne $passAnonymousToken){
                $DesiredConfigurationMatch = $false
                Write-Verbose("passAnonymousToken of AppPool $Name does not match the desired state.");
                break
            }

            #Check logonType 
            if($PoolConfig.add.processModel.logonType -ne $logonType){
                $DesiredConfigurationMatch = $false
                Write-Verbose("logonType of AppPool $Name does not match the desired state.");
                break
            }

            #Check manualGroupMembership 
            if($PoolConfig.add.processModel.manualGroupMembership -ne $manualGroupMembership){
                $DesiredConfigurationMatch = $false
                Write-Verbose("manualGroupMembership of AppPool $Name does not match the desired state.");
                break
            }

            #Check idleTimeout 
            if($PoolConfig.add.processModel.idleTimeout -ne $idleTimeout){
                $DesiredConfigurationMatch = $false
                Write-Verbose("idleTimeout of AppPool $Name does not match the desired state.");
                break
            }

            #Check maxProcesses 
            if($PoolConfig.add.processModel.maxProcesses -ne $maxProcesses){
                $DesiredConfigurationMatch = $false
                Write-Verbose("maxProcesses of AppPool $Name does not match the desired state.");
                break
            }

            #Check shutdownTimeLimit 
            if($PoolConfig.add.processModel.shutdownTimeLimit -ne $shutdownTimeLimit){
               $DesiredConfigurationMatch = $false
                Write-Verbose("shutdownTimeLimit of AppPool $Name does not match the desired state.");
                break
            }

            #Check startupTimeLimit 
            if($PoolConfig.add.processModel.startupTimeLimit -ne $startupTimeLimit){
                $DesiredConfigurationMatch = $false
                Write-Verbose("startupTimeLimit of AppPool $Name does not match the desired state.");
                break
            }

            #Check pingingEnabled 
            if($PoolConfig.add.processModel.pingingEnabled -ne $pingingEnabled){
               $DesiredConfigurationMatch = $false
                Write-Verbose("pingingEnabled of AppPool $Name does not match the desired state.");
                break
            }

            #Check pingInterval 
            if($PoolConfig.add.processModel.pingInterval -ne $pingInterval){
                $DesiredConfigurationMatch = $false
                Write-Verbose("pingInterval of AppPool $Name does not match the desired state.");
                break
            }

            #Check pingResponseTime 
            if($PoolConfig.add.processModel.pingResponseTime -ne $pingResponseTime){
               $DesiredConfigurationMatch = $false
                Write-Verbose("pingResponseTime of AppPool $Name does not match the desired state.");
                break
            }

            #Check disallowOverlappingRotation 
            if($PoolConfig.add.recycling.disallowOverlappingRotation -ne $disallowOverlappingRotation){
                $DesiredConfigurationMatch = $false
                Write-Verbose("disallowOverlappingRotation of AppPool $Name does not match the desired state.");
                break
            }

            #Check disallowRotationOnConfigChange 
            if($PoolConfig.add.recycling.disallowRotationOnConfigChange -ne $disallowRotationOnConfigChange){
                $DesiredConfigurationMatch = $false
                Write-Verbose("disallowRotationOnConfigChange of AppPool $Name does not match the desired state.");
                break
            }

            #Check logEventOnRecycle 
            if($PoolConfig.add.recycling.logEventOnRecycle -ne $logEventOnRecycle){
                $DesiredConfigurationMatch = $false
                Write-Verbose("logEventOnRecycle of AppPool $Name does not match the desired state.");
                break
            }

            #Check restartMemoryLimit 
            if($PoolConfig.add.recycling.periodicRestart.memory -ne $restartMemoryLimit){
               $DesiredConfigurationMatch = $false
                Write-Verbose("restartMemoryLimit of AppPool $Name does not match the desired state.");
                break
            }

            #Check restartPrivateMemoryLimit 
            if($PoolConfig.add.recycling.periodicRestart.privateMemory -ne $restartPrivateMemoryLimit){
                $DesiredConfigurationMatch = $false
                Write-Verbose("restartPrivateMemoryLimit of AppPool $Name does not match the desired state.");
                break
            }

            #Check restartRequestsLimit 
            if($PoolConfig.add.recycling.periodicRestart.requests -ne $restartRequestsLimit){
                $DesiredConfigurationMatch = $false
                Write-Verbose("restartRequestsLimit of AppPool $Name does not match the desired state.");
                break
            }

            #Check restartTimeLimit 
            if($PoolConfig.add.recycling.periodicRestart.time -ne $restartTimeLimit){
                $DesiredConfigurationMatch = $false
                Write-Verbose("restartTimeLimit of AppPool $Name does not match the desired state.");
                break
            }

            #Check restartSchedule
            if(($PoolConfig.add.recycling.periodicRestart.schedule.add.value -ne $null) -and ((Compare-Object $restartSchedule $PoolConfig.add.recycling.periodicRestart.schedule.add.value) -ne $null)){
                $DesiredConfigurationMatch = $false
                Write-Verbose("restartTimeLimit of AppPool $Name does not match the desired state.");
                break
            }
            if(($PoolConfig.add.recycling.periodicRestart.schedule.add.value -eq $null) -and ($restartSchedule -ne $null)){
                $DesiredConfigurationMatch = $false
                Write-Verbose("restartTimeLimit of AppPool $Name does not match the desired state.");
                break
            }

            #Check loadBalancerCapabilities 
            if($PoolConfig.add.failure.loadBalancerCapabilities -ne $loadBalancerCapabilities){
                $DesiredConfigurationMatch = $false
                Write-Verbose("loadBalancerCapabilities of AppPool $Name does not match the desired state.");
                break
            }

            #Check orphanWorkerProcess 
            if($PoolConfig.add.failure.orphanWorkerProcess -ne $orphanWorkerProcess){
               $DesiredConfigurationMatch = $false
                Write-Verbose("orphanWorkerProcess of AppPool $Name does not match the desired state.");
                break
            }

            #Check orphanActionExe 
            if($PoolConfig.add.failure.orphanActionExe -ne $orphanActionExe){
                $DesiredConfigurationMatch = $false
                Write-Verbose("orphanActionExe of AppPool $Name does not match the desired state.");
                break
            }

            #Check orphanActionParams 
            if($PoolConfig.add.failure.orphanActionParams -ne $orphanActionParams){
                $DesiredConfigurationMatch = $false
                Write-Verbose("orphanActionParams of AppPool $Name does not match the desired state.");
                break
            }

            #Check rapidFailProtection 
            if($PoolConfig.add.failure.rapidFailProtection -ne $rapidFailProtection){
                $DesiredConfigurationMatch = $false
                Write-Verbose("rapidFailProtection of AppPool $Name does not match the desired state.");
                break
            }

            #Check rapidFailProtectionInterval 
            if($PoolConfig.add.failure.rapidFailProtectionInterval -ne $rapidFailProtectionInterval){
               $DesiredConfigurationMatch = $false
                Write-Verbose("rapidFailProtectionInterval of AppPool $Name does not match the desired state.");
                break
            }

            #Check rapidFailProtectionMaxCrashes 
            if($PoolConfig.add.failure.rapidFailProtectionMaxCrashes -ne $rapidFailProtectionMaxCrashes){
                $DesiredConfigurationMatch = $false
                Write-Verbose("rapidFailProtectionMaxCrashes of AppPool $Name does not match the desired state.");
                break
            }

            #Check autoShutdownExe 
            if($PoolConfig.add.failure.autoShutdownExe -ne $autoShutdownExe){
               $DesiredConfigurationMatch = $false
                Write-Verbose("autoShutdownExe of AppPool $Name does not match the desired state.");
                break
            }

            #Check autoShutdownParams 
            if($PoolConfig.add.failure.autoShutdownParams -ne $autoShutdownParams){
                $DesiredConfigurationMatch = $false
                Write-Verbose("autoShutdownParams of AppPool $Name does not match the desired state.");
                break
            }

            #Check cpuLimit 
            if($PoolConfig.add.cpu.limit -ne $cpuLimit){
               $DesiredConfigurationMatch = $false
                Write-Verbose("cpuLimit of AppPool $Name does not match the desired state.");
                break
            }

            #Check cpuAction 
            if($PoolConfig.add.cpu.action -ne $cpuAction){
               $DesiredConfigurationMatch = $false
                Write-Verbose("cpuAction of AppPool $Name does not match the desired state.");
                break
            }

            #Check cpuResetInterval 
            if($PoolConfig.add.cpu.resetInterval -ne $cpuResetInterval){
               $DesiredConfigurationMatch = $false
                Write-Verbose("cpuResetInterval of AppPool $Name does not match the desired state.");
                break
            }

            #Check cpuSmpAffinitized 
            if($PoolConfig.add.cpu.smpAffinitized -ne $cpuSmpAffinitized){
                $DesiredConfigurationMatch = $false
                Write-Verbose("cpuSmpAffinitized of AppPool $Name does not match the desired state.");
                break
            }

            #Check cpuSmpProcessorAffinityMask 
            if($PoolConfig.add.cpu.smpProcessorAffinityMask -ne $cpuSmpProcessorAffinityMask){
                $DesiredConfigurationMatch = $false
                Write-Verbose("cpuSmpProcessorAffinityMask of AppPool $Name does not match the desired state.");
                break
            }

            #Check cpuSmpProcessorAffinityMask2 
            if($PoolConfig.add.cpu.smpProcessorAffinityMask2 -ne $cpuSmpProcessorAffinityMask2){
               $DesiredConfigurationMatch = $false
                Write-Verbose("cpuSmpProcessorAffinityMask2 of AppPool $Name does not match the desired state.");
                break
            }

        }

        $Stop = $false
    }
    While($Stop)   

    return $DesiredConfigurationMatch
}
