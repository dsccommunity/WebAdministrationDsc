# Check if WebServer is Installed
if (@(Get-WindowsOptionalFeature -Online -FeatureName 'IIS-WebServer' `
    | Where-Object -Property State -eq 'Disabled').Count -gt 0)
{
    if ((Get-CimInstance Win32_OperatingSystem).ProductType -eq 1)
    {
        # Desktop OS
        Enable-WindowsOptionalFeature -Online -FeatureName 'IIS-WebServer'
    }
    else
    {
        # Server OS
        Install-WindowsFeature -IncludeAllSubFeature -IncludeManagementTools -Name 'Web-Server'
    }
}

$DSCModuleName  = 'xWebAdministration'

$moduleRoot = "${env:ProgramFiles}\WindowsPowerShell\Modules\$DSCModuleName"

[xml]$global:PoolCfg = '<add name="DefaultAppPool" queueLength="1000" autoStart="true" enable32BitAppOnWin64="false" managedRuntimeVersion="v4.0" managedRuntimeLoader="webengine4.dll" enableConfigurationOverride="true" managedPipelineMode="Integrated" CLRConfigFile="" passAnonymousToken="true" startMode="OnDemand"><processModel identityType="ApplicationPoolIdentity" userName="" password="" loadUserProfile="true" setProfileEnvironment="true" logonType="LogonBatch" manualGroupMembership="false" idleTimeout="00:20:00" idleTimeoutAction="Terminate" maxProcesses="1" shutdownTimeLimit="00:01:30" startupTimeLimit="00:01:30" pingingEnabled="true" pingInterval="00:00:30" pingResponseTime="00:01:30" logEventOnProcessModel="IdleTimeout" /><recycling disallowOverlappingRotation="false" disallowRotationOnConfigChange="false" logEventOnRecycle="Time, Memory, PrivateMemory"><periodicRestart memory="0" privateMemory="0" requests="0" time="1.05:00:00"><schedule></schedule></periodicRestart></recycling><failure loadBalancerCapabilities="HttpLevel" orphanWorkerProcess="false" orphanActionExe="" orphanActionParams="" rapidFailProtection="true" rapidFailProtectionInterval="00:05:00" rapidFailProtectionMaxCrashes="5" autoShutdownExe="" autoShutdownParams="" /><cpu limit="0" action="NoAction" resetInterval="00:05:00" smpAffinitized="false" smpProcessorAffinityMask="4294967295" smpProcessorAffinityMask2="4294967295" processorGroup="0" numaNodeAssignment="MostAvailableMemory" numaNodeAffinityMode="Soft" /></add>'

if(-not (Test-Path -Path $moduleRoot))
{
    $null = New-Item -Path $moduleRoot -ItemType Directory
}
else
{
    # Copy the existing folder out to the temp directory to hold until the end of the run
    # Delete the folder to remove the old files.
    $tempLocation = Join-Path -Path $env:Temp -ChildPath $DSCModuleName
    Copy-Item -Path $moduleRoot -Destination $tempLocation -Recurse -Force
    Remove-Item -Path $moduleRoot -Recurse -Force
    $null = New-Item -Path $moduleRoot -ItemType Directory
}

Copy-Item -Path $PSScriptRoot\..\..\* -Destination $moduleRoot -Recurse -Force -Exclude '.git'

if (Get-Module -Name $DSCModuleName -All)
{
    Get-Module -Name $DSCModuleName -All | Remove-Module
}

Import-Module -Name $(Get-Item -Path (Join-Path $moduleRoot -ChildPath "$DSCModuleName.psd1")) -Force

if (($env:PSModulePath).Split(';') -ccontains $pwd.Path)
{
    $script:tempPath = $env:PSModulePath
    $env:PSModulePath = ($env:PSModulePath -split ';' | Where-Object {$_ -ne $pwd.path}) -join ';'
}


$executionPolicy = Get-ExecutionPolicy
if ($executionPolicy -ne 'Unrestricted')
{
    Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Force
    $rollbackExecution = $true
}

$ModuleName = "MSFT_xWebAppPool"

Import-Module (Join-Path $moduleRoot -ChildPath "DSCResources\$ModuleName\$ModuleName.psm1")

Describe "MSFT_xWebAppPool"{
    InModuleScope $ModuleName {
        Function TestTargetResourceSame
        {
            <#

            .SYNOPSIS
            Runs Test-TargetResource on $option so that when $option has the same value as the current setting, $true is returned.

            .DESCRIPTION
            Runs Test-TargetResource on $option so that when $option has the same value as the current setting, $true is returned.

            .PARAMETER option 
            should be the name of the option as defined in xWebAppPool.psm1

            .PARAMETER appcmdVal
            The location that would be used to get this value via appcmd.

            .EXAMPLE
            TestTargetResourceSame "autoStart" "add.autoStart"

            #>
            [OutputType([bool])]
            Param($option,$appcmdVal)
            $testParams =@{
                Name = "DefaultAppPool"
                Ensure = "Present"
            }

            $arrVal = $appcmdVal.Split(".")             
            $val = $global:PoolCfg.GetElementsByTagName($arrVal[$arrVal.length-2]) | Select -ExpandProperty $arrVal[$arrVal.length-1]
            $testParams.Add($option, $val)
            Mock Invoke-AppCmd {return $global:PoolCfg.OuterXml}
            Mock Invoke-AppCmdState {return "Started"}
            Test-TargetResource @testParams
            Return 
        }

        Function TestTargetResourceDiff
        {
            <#

            .SYNOPSIS
            Runs Test-TargetResource on $option so that when $option has a different value as the current setting, $false is returned.

            .DESCRIPTION
            Runs Test-TargetResource on $option so that when $option has a different value as the current setting, $false is returned.

            .PARAMETER option 
            should be the name of the option as defined in xWebAppPool.psm1

            .PARAMETER appcmdVal
            The location that would be used to get this value via appcmd.
            
            .PARAMETER value1
            A valid value that $option can be set to.  Must be different than value2

            .PARAMETER value2
            A valid value that $option can be set to.  Must be different than value1

            .EXAMPLE
            TestTargetResourceDiff "autoStart" "add.autoStart" "true" "false"

            #>
            [OutputType([bool])]
            Param($option,$appcmdVal,$value1,$value2)
            $testParams =@{
                Name = "DefaultAppPool"
                Ensure = "Present"
            }

            $arrVal = $appcmdVal.Split(".")             
            $curVal = $global:PoolCfg.GetElementsByTagName($arrVal[$arrVal.length-2]) | Select -ExpandProperty $arrVal[$arrVal.length-1]
            if($curVal -eq $value1)
            {
              $testParams.Add($option,$value2)
            }
            else
            {
              $testParams.Add($option,$value1)
            }
            
            Mock Invoke-AppCmd {return $global:PoolCfg}
            Mock Invoke-AppCmdState {return "Started"}
            Test-TargetResource @testParams
            Return 
        }

        Function SetTargetResource
        {
            <#

            .SYNOPSIS
            Runs Set-TargetResource on $option and then verifies that option was changed to the desired value.  Returns $true if option was changed.

            .DESCRIPTION
            Runs Set-TargetResource on $option and then verifies that option was changed to the desired value.  Returns $true if option was changed.

            .PARAMETER option 
            should be the name of the option as defined in xWebAppPool.psm1

            .PARAMETER appcmdVal
            The location that would be used to get this value via appcmd.
            
            .PARAMETER value1
            A valid value that $option can be set to.  Must be different than value2

            .PARAMETER value2
            A valid value that $option can be set to.  Must be different than value1

            .EXAMPLE
            SetTargetResource "autoStart" "add.autoStart" "true" "false"

            #>
            [OutputType([bool])]
            Param($option,$appcmdVal,$value1,$value2)
            $testParams =@{
                Name = "DefaultAppPool"
                Ensure = "Present"
            }
            $curVal = Invoke-Expression "(([xml](& $env:SystemRoot\system32\inetsrv\appcmd.exe list apppool 'DefaultAppPool' /config:*)).$($appcmdVal))"
            if($curVal -ne $value1)
            {
                $testParams.Add($option,$value1)
                Set-TargetResource @testParams | Out-Null #So we only return the value of Test-TargetResource below
                $curVal = Invoke-Expression "(([xml](& $env:SystemRoot\system32\inetsrv\appcmd.exe list apppool 'DefaultAppPool' /config:*)).$($appcmdVal))"
                $value1 -eq $curVal
            }
            else
            {
                $testParams.Add($option,$value2)
                Set-TargetResource @testParams | Out-Null #So we only return the value of Test-TargetResource below
                $curVal = Invoke-Expression "(([xml](& $env:SystemRoot\system32\inetsrv\appcmd.exe list apppool 'DefaultAppPool' /config:*)).$($appcmdVal))"
                $value2 -eq $curVal
            }

            Return 
        }

        try
        {
            $baseParams =@{
                Name = "DefaultAppPool"
                Ensure = "Present"
            }

            It 'DefaultAppPool should exist' {           
                (Get-ChildItem IIS:\apppools).Name.Contains("DefaultAppPool") | Should be $true
            }

            Context 'Test-TargetResource' {
                
                It 'Passes autoStart Test when same' {
                    
                    TestTargetResourceSame "autoStart" "add.autoStart" | Should be $true
                }

                It 'Fails autoStart Test when different' {
                    
                    TestTargetResourceDiff "autoStart" "add.autoStart" "true" "false"| Should be $false
                }

                It 'Passes Runtime Version Test when same' {
                  
                    TestTargetResourceSame "managedRuntimeVersion" "add.managedRuntimeVersion"  | Should be $true
                }

                It 'Fails Runtime Version Test when different' {
                  
                    TestTargetResourceDiff "managedRuntimeVersion" "add.managedRuntimeVersion" "v4.0" "v2.0" | Should be $false
                }

                It 'Passes Managed Pipeline Mode Test when same' {
                  
                    TestTargetResourceSame "managedPipelineMode" "add.managedPipelineMode" | Should be $true
                }

                It 'Fails Managed Pipeline Mode Test when different' {
                  
                    TestTargetResourceDiff "managedPipelineMode" "add.managedPipelineMode" "Integrated" "Classic"| Should be $false
                }

                It 'Passes Start Mode Test when same' {
                  
                    TestTargetResourceSame "startMode" "add.startMode" | Should be $true
                }

                It 'Fails Start Mode Test when different' {
                  
                    TestTargetResourceDiff "startMode" "add.startMode" "AlwaysRunning" "OnDemand" | Should be $false
                }

                It 'Passes Identity Type Test when same' {
                  
                    TestTargetResourceSame "identityType" "add.processModel.identityType" | Should be $true
                }

                It 'Fails Identity Type Test when different' {
                  
                    TestTargetResourceDiff "identityType" "add.processModel.identityType" "ApplicationPoolIdentity" "LocalSystem" | Should be $false
                }

                It 'Passes Load User Profile Test when same' {
                  
                    TestTargetResourceSame "loadUserProfile" "add.processModel.loadUserProfile" | Should be $true
                }

                It 'Fails Load User Profile Test when different' {
                  
                    TestTargetResourceDiff "loadUserProfile" "add.processModel.loadUserProfile" "true" "false" | Should be $false
                }

                It 'Passes Queue Length Test when same' {
                  
                    TestTargetResourceSame "queueLength" "add.queueLength" | Should be $true
                }

                It 'Fails Queue Length Test when different' {
                  
                    TestTargetResourceDiff "queueLength" "add.queueLength" "2000" "1000" | Should be $false
                }

                It 'Passes Enable 32bit Test when same' {
                  
                    TestTargetResourceSame "enable32BitAppOnWin64" "add.enable32BitAppOnWin64" | Should be $true
                }

                It 'Fails Enable 32bit Test when different' {
                  
                    TestTargetResourceDiff "enable32BitAppOnWin64" "add.enable32BitAppOnWin64" "true" "false" | Should be $false
                }

                It 'Passes Config Override Test when same' {
                  
                    TestTargetResourceSame "enableConfigurationOverride" "add.enableConfigurationOverride" | Should be $true
                }

                It 'Fails Config Override Test when different' {
                  
                    TestTargetResourceDiff "enableConfigurationOverride" "add.enableConfigurationOverride" "true" "false" | Should be $false
                }

                It 'Passes Pass Anon Token Test when same' {
                  
                    TestTargetResourceSame "passAnonymousToken" "add.passAnonymousToken" | Should be $true
                }

                It 'Fails Pass Anon Token Test when different' {
                  
                    TestTargetResourceDiff "passAnonymousToken" "add.passAnonymousToken" "true" "false" | Should be $false
                }

                It 'Passes Logon Type Test when same' {
                  
                    TestTargetResourceSame "logonType" "add.processModel.logonType" | Should be $true
                }

                It 'Fails Logon Type Test when different' {
                  
                    TestTargetResourceDiff "logonType" "add.processModel.logonType" "LogonService" "LogonBatch" | Should be $false
                }

                It 'Passes Manual Group Membership Test when same' {
                  
                    TestTargetResourceSame "manualGroupMembership" "add.processModel.manualGroupMembership" | Should be $true
                }

                It 'Fails Manual Group Membership Test when different' {
                  
                    TestTargetResourceDiff "manualGroupMembership" "add.processModel.manualGroupMembership" "true" "false" | Should be $false
                }

                It 'Passes Idle Timeout Test when same' {
                  
                    TestTargetResourceSame "idleTimeout" "add.processModel.idleTimeout" | Should be $true
                }

                It 'Fails Idle Timeout Test when different' {
                  
                    TestTargetResourceDiff "idleTimeout" "add.processModel.idleTimeout" "00:25:00" "00:20:00" | Should be $false
                }

                It 'Passes Max Processes Test when same' {
                  
                    TestTargetResourceSame "maxProcesses" "add.processModel.maxProcesses" | Should be $true
                }

                It 'Fails Max Processes Test when different' {
                  
                    TestTargetResourceDiff "maxProcesses" "add.processModel.maxProcesses" "2" "1" | Should be $false
                }

                It 'Passes Shutdown Time Limit Test when same' {
                  
                    TestTargetResourceSame "shutdownTimeLimit" "add.processModel.shutdownTimeLimit" | Should be $true
                }

                It 'Fails Shutdown Time Limit Test when different' {
                  
                    TestTargetResourceDiff "shutdownTimeLimit" "add.processModel.shutdownTimeLimit" "00:02:30" "00:01:30" | Should be $false
                }

                It 'Passes Startup Time Limit Test when same' {
                  
                    TestTargetResourceSame "startupTimeLimit" "add.processModel.startupTimeLimit" | Should be $true
                }

                It 'Fails Startup Time Limit Test when different' {
                  
                    TestTargetResourceDiff "startupTimeLimit" "add.processModel.startupTimeLimit" "00:02:30" "00:01:30" | Should be $false
                }

                It 'Passes Ping Interval Test when same' {
                  
                    TestTargetResourceSame "pingInterval" "add.processModel.pingInterval" | Should be $true
                }

                It 'Fails Ping Interval Test when different' {
                  
                    TestTargetResourceDiff "pingInterval" "add.processModel.pingInterval" "00:02:30" "00:01:30" | Should be $false
                }

                It 'Passes Ping Response Test when same' {
                  
                    TestTargetResourceSame "pingResponseTime" "add.processModel.pingResponseTime" | Should be $true
                }

                It 'Fails Ping Response Test when different' {
                  
                    TestTargetResourceDiff "pingResponseTime" "add.processModel.pingResponseTime" "00:02:30" "00:01:30" | Should be $false
                }

                It 'Passes Ping Enabled Test when same' {
                  
                    TestTargetResourceSame "pingingEnabled" "add.processModel.pingingEnabled" | Should be $true
                }

                It 'Fails Ping Enabled Test when different' {
                  
                    TestTargetResourceDiff "pingingEnabled" "add.processModel.pingingEnabled" "true" "false" | Should be $false
                }

                It 'Passes Disallow Overlapping Rotation Test when same' {
                  
                    TestTargetResourceSame "disallowOverlappingRotation" "add.recycling.disallowOverlappingRotation" | Should be $true
                }

                It 'Fails Disallow Overlapping Rotation Test when different' {
                  
                    TestTargetResourceDiff "disallowOverlappingRotation" "add.recycling.disallowOverlappingRotation" "true" "false" | Should be $false
                }

                It 'Passes Disallow Rotation On Config Change Test when same' {
                  
                    TestTargetResourceSame "disallowRotationOnConfigChange" "add.recycling.disallowRotationOnConfigChange" | Should be $true
                }

                It 'Fails Disallow Rotation On Config Change Test when different' {
                  
                    TestTargetResourceDiff "disallowRotationOnConfigChange" "add.recycling.disallowRotationOnConfigChange" "true" "false" | Should be $false
                }

                It 'Passes Log Event On Recycle Test when same' {
                  
                    TestTargetResourceSame "logEventOnRecycle" "add.recycling.logEventOnRecycle" | Should be $true
                }

                It 'Fails Log Event On Recycle Test when different' {
                  
                    TestTargetResourceDiff "logEventOnRecycle" "add.recycling.logEventOnRecycle" "Time, Memory" "Time, Memory, PrivateMemory" | Should be $false
                }

                It 'Passes Restart Mem Limit Test when same' {
                  
                    TestTargetResourceSame "restartMemoryLimit" "add.recycling.periodicRestart.memory" | Should be $true
                }

                It 'Fails Restart Mem Limit Test when different' {
                  
                    TestTargetResourceDiff "restartMemoryLimit" "add.recycling.periodicRestart.memory" "0" "1" | Should be $false
                }

                It 'Passes Restart Private Mem Limit Test when same' {
                  
                    TestTargetResourceSame "restartPrivateMemoryLimit" "add.recycling.periodicRestart.privateMemory" | Should be $true
                }

                It 'Fails Restart Private Mem Limit Test when different' {
                  
                    TestTargetResourceDiff "restartPrivateMemoryLimit" "add.recycling.periodicRestart.privateMemory" "0" "1" | Should be $false
                }

                It 'Passes Restart Requests Limit Test when same' {
                  
                    TestTargetResourceSame "restartRequestsLimit" "add.recycling.periodicRestart.requests" | Should be $true
                }

                It 'Fails Restart Requests Limit Test when different' {
                  
                    TestTargetResourceDiff "restartRequestsLimit" "add.recycling.periodicRestart.requests" "0" "1" | Should be $false
                }

                It 'Passes Restart Time Limit Test when same' {
                  
                    TestTargetResourceSame "restartTimeLimit" "add.recycling.periodicRestart.time" | Should be $true
                }

                It 'Fails Restart Time Limit Test when different' {
                  
                    TestTargetResourceDiff "restartTimeLimit" "add.recycling.periodicRestart.time" "2.05:00:00" "1.05:00:00" | Should be $false
                }

                It 'Passes Restart Schedule Test when same' {
                  
                    TestTargetResourceSame "restartSchedule" "add.recycling.periodicRestart.schedule.add.value" | Should be $true
                }

                It 'Fails Restart Schedule Test when different' {
                  
                    TestTargetResourceDiff "restartSchedule" "add.recycling.periodicRestart.schedule.add.value" "18:30:00" "10:30:00" | Should be $false
                }

                It 'Passes Load Balancer Capabilities Test when same' {
                  
                    TestTargetResourceSame "loadBalancerCapabilities" "add.failure.loadBalancerCapabilities" | Should be $true
                }

                It 'Fails Load Balancer Capabilities Test when different' {
                  
                    TestTargetResourceDiff "loadBalancerCapabilities" "add.failure.loadBalancerCapabilities" "HttpLevel" "TcpLevel" | Should be $false
                }

                It 'Passes Orphan Worker Process Test when same' {
                  
                    TestTargetResourceSame "orphanWorkerProcess" "add.failure.orphanWorkerProcess" | Should be $true
                }

                It 'Fails Orphan Worker Process Test when different' {
                  
                    TestTargetResourceDiff "orphanWorkerProcess" "add.failure.orphanWorkerProcess" "true" "false" | Should be $false
                }

                It 'Passes Orphan Action Exe Test when same' {
                  
                    TestTargetResourceSame "orphanActionExe" "add.failure.orphanActionExe" | Should be $true
                }

                It 'Fails Orphan Action Exe Test when different' {
                  
                    TestTargetResourceDiff "orphanActionExe" "add.failure.orphanActionExe" "test.exe" "test1.exe" | Should be $false
                }

                It 'Passes Orphan Action Params Test when same' {
                  
                    TestTargetResourceSame "orphanActionParams" "add.failure.orphanActionParams" | Should be $true
                }

                It 'Fails Orphan Action Params Test when different' {
                  
                    TestTargetResourceDiff "orphanActionParams" "add.failure.orphanActionParams" "test.exe" "test1.exe" | Should be $false
                }

                It 'Passes Rapid Fail Protection Test when same' {
                  
                    TestTargetResourceSame "rapidFailProtection" "add.failure.rapidFailProtection" | Should be $true
                }

                It 'Fails Rapid Fail Protection Test when different' {
                  
                    TestTargetResourceDiff "rapidFailProtection" "add.failure.rapidFailProtection" "true" "false" | Should be $false
                }

                It 'Passes Rapid Fail Protection Interval Test when same' {
                  
                    TestTargetResourceSame "rapidFailProtectionInterval" "add.failure.rapidFailProtectionInterval" | Should be $true
                }

                It 'Fails Rapid Fail Protection Interval Test when different' {
                  
                    TestTargetResourceDiff "rapidFailProtectionInterval" "add.failure.rapidFailProtectionInterval" "00:15:00" "00:05:00" | Should be $false
                }

                It 'Passes Rapid Fail Protection Interval Max Crashes Test when same' {
                  
                    TestTargetResourceSame "rapidFailProtectionMaxCrashes" "add.failure.rapidFailProtectionMaxCrashes" | Should be $true
                }

                It 'Fails Rapid Fail Protection Interval Max Crashes Test when different' {
                  
                    TestTargetResourceDiff "rapidFailProtectionMaxCrashes" "add.failure.rapidFailProtectionMaxCrashes" "15:00" "05" | Should be $false
                }

                It 'Passes Auto Shutdown Exe Test when same' {
                  
                    TestTargetResourceSame "autoShutdownExe" "add.failure.autoShutdownExe" | Should be $true
                }

                It 'Fails Auto Shutdown Exe Test when different' {
                  
                    TestTargetResourceDiff "autoShutdownExe" "add.failure.autoShutdownExe" "test.exe" "test1.exe" | Should be $false
                }

                It 'Passes Auto Shutdown Params Test when same' {
                  
                    TestTargetResourceSame "autoShutdownParams" "add.failure.autoShutdownParams" | Should be $true
                }

                It 'Fails Auto Shutdown Params Test when different' {
                  
                    TestTargetResourceDiff "autoShutdownParams" "add.failure.autoShutdownParams" "test.exe" "test1.exe" | Should be $false
                }

                It 'Passes CPU Limit Test when same' {
                  
                    TestTargetResourceSame "cpuLimit" "add.cpu.limit" | Should be $true
                }

                It 'Fails CPU Limit Test Test when different' {
                  
                    TestTargetResourceDiff "cpuLimit" "add.cpu.limit" "1" "0" | Should be $false
                }

                It 'Passes CPU Action Test when same' {
                  
                    TestTargetResourceSame "cpuAction" "add.cpu.action" | Should be $true
                }

                It 'Fails CPU Action Test when different' {
                  
                    TestTargetResourceDiff "cpuAction" "add.cpu.action" "Throttle" "NoAction" | Should be $false
                }

                It 'Passes CPU Reset Interval Test when same' {
                  
                    TestTargetResourceSame "cpuResetInterval" "add.cpu.resetInterval" | Should be $true
                }

                It 'Fails CPU Reset Interval Test when different' {
                  
                    TestTargetResourceDiff "cpuResetInterval" "add.cpu.resetInterval" "00:15:00" "00:05:00" | Should be $false
                }

                It 'Passes CPU Smp Affinitized Test when same' {
                  
                    TestTargetResourceSame "cpuSmpAffinitized" "add.cpu.smpAffinitized" | Should be $true
                }

                It 'Fails CPU Smp Affinitized Test when different' {
                  
                    TestTargetResourceDiff "cpuSmpAffinitized" "add.cpu.smpAffinitized" "true" "false" | Should be $false
                }

                It 'Passes CPU Smp Processor Affinity Mask Test when same' {
                  
                    TestTargetResourceSame "cpuSmpProcessorAffinityMask" "add.cpu.smpProcessorAffinityMask" | Should be $true
                }

                It 'Fails CPU Smp Processor Affinity Mask Test when different' {
                  
                    TestTargetResourceDiff "cpuSmpProcessorAffinityMask" "add.cpu.smpProcessorAffinityMask" "4294967294" "4294967295" | Should be $false
                }

                It 'Passes CPU Smp Processor Affinity Mask 2 Test when same' {
                  
                    TestTargetResourceSame "cpuSmpProcessorAffinityMask2" "add.cpu.smpProcessorAffinityMask2" | Should be $true
                }

                It 'Fails CPU Smp Processor Affinity Mask 2 Test when different' {
                  
                    TestTargetResourceDiff "cpuSmpProcessorAffinityMask2" "add.cpu.smpProcessorAffinityMask2" "4294967294" "4294967295" | Should be $false
                }
            }
            
<#            Context 'Set-TargetResource' {
                It 'Should set autoStart Test ' {
                    
                    SetTargetResource "autoStart" "add.autoStart" "true" "false"| Should be $true
                }
                
                It 'Should set Runtime Version Test ' {
                  
                    SetTargetResource "managedRuntimeVersion" "add.managedRuntimeVersion" "v4.0" "v2.0" | Should be $true
                }
                
                It 'Should set Managed Pipeline Mode Test ' {
                  
                    SetTargetResource "managedPipelineMode" "add.managedPipelineMode" "Integrated" "Classic"| Should be $true
                }
                
                It 'Should set Start Mode Test ' {
                  
                    SetTargetResource "startMode" "add.startMode" "AlwaysRunning" "OnDemand" | Should be $true
                }
                
                It 'Should set Identity Type Test ' {
                  
                    SetTargetResource "identityType" "add.processModel.identityType" "ApplicationPoolIdentity" "LocalSystem" | Should be $true
                }
                
                It 'Should set Load User Profile Test ' {
                  
                    SetTargetResource "loadUserProfile" "add.processModel.loadUserProfile" "true" "false" | Should be $true
                }
                
                It 'Should set Queue Length Test ' {
                  
                    SetTargetResource "queueLength" "add.queueLength" "2000" "1000" | Should be $true
                }
                
                It 'Should set Enable 32bit Test ' {
                  
                    SetTargetResource "enable32BitAppOnWin64" "add.enable32BitAppOnWin64" "true" "false" | Should be $true
                }
                
                It 'Should set Config Override Test ' {
                  
                    SetTargetResource "enableConfigurationOverride" "add.enableConfigurationOverride" "true" "false" | Should be $true
                }
                
                It 'Should set Pass Anon Token Test ' {
                  
                    SetTargetResource "passAnonymousToken" "add.passAnonymousToken" "true" "false" | Should be $true
                }
                
                It 'Should set Logon Type Test ' {
                  
                    SetTargetResource "logonType" "add.processModel.logonType" "LogonService" "LogonBatch" | Should be $true
                }
                
                It 'Should set Manual Group Membership Test ' {
                  
                    SetTargetResource "manualGroupMembership" "add.processModel.manualGroupMembership" "true" "false" | Should be $true
                }
                
                It 'Should set Idle Timeout Test ' {
                  
                    SetTargetResource "idleTimeout" "add.processModel.idleTimeout" "00:25:00" "00:20:00" | Should be $true
                }
                
                It 'Should set Max Processes Test ' {
                  
                    SetTargetResource "maxProcesses" "add.processModel.maxProcesses" "2" "1" | Should be $true
                }
                
                It 'Should set Shutdown Time Limit Test ' {
                  
                    SetTargetResource "shutdownTimeLimit" "add.processModel.shutdownTimeLimit" "00:02:30" "00:01:30" | Should be $true
                }
                
                It 'Should set Startup Time Limit Test ' {
                  
                    SetTargetResource "startupTimeLimit" "add.processModel.startupTimeLimit" "00:02:30" "00:01:30" | Should be $true
                }
                
                It 'Should set Ping Interval Test ' {
                  
                    SetTargetResource "pingInterval" "add.processModel.pingInterval" "00:02:30" "00:01:30" | Should be $true
                }
                
                It 'Should set Ping Response Test ' {
                  
                    SetTargetResource "pingResponseTime" "add.processModel.pingResponseTime" "00:02:30" "00:01:30" | Should be $true
                }
                
                It 'Should set Ping Enabled Test ' {
                  
                    SetTargetResource "pingingEnabled" "add.processModel.pingingEnabled" "true" "false" | Should be $true
                }
                
                It 'Should set Disallow Overlapping Rotation Test ' {
                  
                    SetTargetResource "disallowOverlappingRotation" "add.recycling.disallowOverlappingRotation" "true" "false" | Should be $true
                }
                
                It 'Should set Disallow Rotation On Config Change Test ' {
                  
                    SetTargetResource "disallowRotationOnConfigChange" "add.recycling.disallowRotationOnConfigChange" "true" "false" | Should be $true
                }
                
                It 'Should set Log Event On Recycle Test ' {
                  
                    SetTargetResource "logEventOnRecycle" "add.recycling.logEventOnRecycle" "Time, Memory" "Time, Memory, PrivateMemory" | Should be $true
                }
                
                It 'Should set Restart Mem Limit Test ' {
                  
                    SetTargetResource "restartMemoryLimit" "add.recycling.periodicRestart.memory" "0" "1" | Should be $true
                }
                
                It 'Should set Restart Private Mem Limit Test ' {
                  
                    SetTargetResource "restartPrivateMemoryLimit" "add.recycling.periodicRestart.privateMemory" "0" "1" | Should be $true
                }
                
                It 'Should set Restart Requests Limit Test ' {
                  
                    SetTargetResource "restartRequestsLimit" "add.recycling.periodicRestart.requests" "0" "1" | Should be $true
                }
                
                It 'Should set Restart Time Limit Test ' {
                  
                    SetTargetResource "restartTimeLimit" "add.recycling.periodicRestart.time" "2.05:00:00" "1.05:00:00" | Should be $true
                }
                
                It 'Should set Restart Schedule Test ' {
                  
                    SetTargetResource "restartSchedule" "add.recycling.periodicRestart.schedule.add.value" "18:30:00" "10:30:00" | Should be $true
                }
                
                It 'Should set Load Balancer Capabilities Test ' {
                  
                    SetTargetResource "loadBalancerCapabilities" "add.failure.loadBalancerCapabilities" "HttpLevel" "TcpLevel" | Should be $true
                }
                
                It 'Should set Orphan Worker Process Test ' {
                  
                    SetTargetResource "orphanWorkerProcess" "add.failure.orphanWorkerProcess" "true" "false" | Should be $true
                }
                
                It 'Should set Orphan Action Exe Test ' {
                  
                    SetTargetResource "orphanActionExe" "add.failure.orphanActionExe" "test.exe" "test1.exe" | Should be $true
                }
                
                It 'Should set Orphan Action Params Test ' {
                  
                    SetTargetResource "orphanActionParams" "add.failure.orphanActionParams" "test.exe" "test1.exe" | Should be $true
                }
                
                It 'Should set Rapid Fail Protection Test ' {
                  
                    SetTargetResource "rapidFailProtection" "add.failure.rapidFailProtection" "true" "false" | Should be $true
                }
                
                It 'Should set Rapid Fail Protection Interval Test ' {
                  
                    SetTargetResource "rapidFailProtectionInterval" "add.failure.rapidFailProtectionInterval" "00:15:00" "00:05:00" | Should be $true
                }
                
                It 'Should set Rapid Fail Protection Interval Max Crashes Test ' {
                  
                    SetTargetResource "rapidFailProtectionMaxCrashes" "add.failure.rapidFailProtectionMaxCrashes" "15" "05" | Should be $true
                }
                
                It 'Should set Auto Shutdown Exe Test ' {
                  
                    SetTargetResource "autoShutdownExe" "add.failure.autoShutdownExe" "test.exe" "test1.exe" | Should be $true
                }
                
                It 'Should set Auto Shutdown Params Test ' {
                  
                    SetTargetResource "autoShutdownParams" "add.failure.autoShutdownParams" "test.exe" "test1.exe" | Should be $true
                }
                
                It 'Should set CPU Limit Test Test ' {
                  
                    SetTargetResource "cpuLimit" "add.cpu.limit" "1" "0" | Should be $true
                }
                
                It 'Should set CPU Action Test ' {
                  
                    SetTargetResource "cpuAction" "add.cpu.action" "Throttle" "NoAction" | Should be $true
                }
                
                It 'Should set CPU Reset Interval Test ' {
                  
                    SetTargetResource "cpuResetInterval" "add.cpu.resetInterval" "00:15:00" "00:05:00" | Should be $true
                }
                
                It 'Should set CPU Smp Affinitized Test ' {
                  
                    SetTargetResource "cpuSmpAffinitized" "add.cpu.smpAffinitized" "true" "false" | Should be $true
                }
                
                It 'Should set CPU Smp Processor Affinity Mask Test ' {
                  
                    SetTargetResource "cpuSmpProcessorAffinityMask" "add.cpu.smpProcessorAffinityMask" "4294967294" "4294967295" | Should be $true
                }
                
                It 'Should set CPU Smp Processor Affinity Mask 2 Test ' {
                  
                    SetTargetResource "cpuSmpProcessorAffinityMask2" "add.cpu.smpProcessorAffinityMask2" "4294967294" "4294967295" | Should be $true
                }
            }
#>
        }
        finally
        {            
            if ($rollbackExecution)
            {
                Set-ExecutionPolicy -ExecutionPolicy $executionPolicy -Force
            }

            if ($script:tempPath) {
                $env:PSModulePath = $script:tempPath
            }
        }        
    }
}
