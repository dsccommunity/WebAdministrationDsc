# Load the Helper Module
Import-Module -Name "$PSScriptRoot\..\Helper.psm1"

# Localized messages
data LocalizedData {
    # culture="en-US"
    ConvertFrom-StringData -StringData @'
        ErrorAppCmdNonZeroExitCode        = AppCmd.exe has exited with error code "{0}".
        VerboseGetTargetResource          = Get-TargetResource has been run.

        ErrorAppPoolDefaultsNotFound      = Application pool defaults element could not be located.
        VerboseAppPoolDefaultsFound       = Application pool defaults was found.
        VerbosePropertyNotInDesiredState  = The "{0}" property of application pool defaults does not match the desired state.
        VerboseCredentialToBeCleared      = Custom account credentials of application pool defaults need to be cleared because the "identityType" property is not set to "SpecificUser".
        VerboseCredentialToBeIgnored      = The "Credential" property is only valid when the "identityType" property is set to "SpecificUser".
        VerboseResourceInDesiredState     = The target resource is already in the desired state. No action is required.
        VerboseResourceNotInDesiredState  = The target resource is not in the desired state.
        VerboseSetProperty                = Setting the "{0}" property of application pool defaults".
        VerboseClearCredential            = Clearing custom account credentials of application pool defaults because the "identityType" property is not set to "SpecificUser".
        VerboseRestartScheduleValueAdd    = Adding value "{0}" to the "restartSchedule" collection of application pool defaults.
        VerboseRestartScheduleValueRemove = Removing value "{0}" from the "restartSchedule" collection of application pool defaults.
'@
}

# Writable properties except Credential.
data PropertyData {
    @(
        # General
        @{Name = 'autoStart'; Path = 'autoStart'}
        @{Name = 'CLRConfigFile'; Path = 'CLRConfigFile'}
        @{Name = 'enable32BitAppOnWin64'; Path = 'enable32BitAppOnWin64'}
        @{Name = 'enableConfigurationOverride'; Path = 'enableConfigurationOverride'}
        @{Name = 'managedPipelineMode'; Path = 'managedPipelineMode'}
        @{Name = 'managedRuntimeLoader'; Path = 'managedRuntimeLoader'}
        @{Name = 'managedRuntimeVersion'; Path = 'managedRuntimeVersion'}
        @{Name = 'passAnonymousToken'; Path = 'passAnonymousToken'}
        @{Name = 'startMode'; Path = 'startMode'}
        @{Name = 'queueLength'; Path = 'queueLength'}

        # CPU
        @{Name = 'cpuAction'; Path = 'cpu.action'}
        @{Name = 'cpuLimit'; Path = 'cpu.limit'}
        @{Name = 'cpuResetInterval'; Path = 'cpu.resetInterval'}
        @{Name = 'cpuSmpAffinitized'; Path = 'cpu.smpAffinitized'}
        @{Name = 'cpuSmpProcessorAffinityMask'; Path = 'cpu.smpProcessorAffinityMask'}
        @{Name = 'cpuSmpProcessorAffinityMask2'; Path = 'cpu.smpProcessorAffinityMask2'}

        # Process Model
        @{Name = 'identityType'; Path = 'processModel.identityType'}
        @{Name = 'idleTimeout'; Path = 'processModel.idleTimeout'}
        @{Name = 'idleTimeoutAction'; Path = 'processModel.idleTimeoutAction'}
        @{Name = 'loadUserProfile'; Path = 'processModel.loadUserProfile'}
        @{Name = 'logEventOnProcessModel'; Path = 'processModel.logEventOnProcessModel'}
        @{Name = 'logonType'; Path = 'processModel.logonType'}
        @{Name = 'manualGroupMembership'; Path = 'processModel.manualGroupMembership'}
        @{Name = 'maxProcesses'; Path = 'processModel.maxProcesses'}
        @{Name = 'pingingEnabled'; Path = 'processModel.pingingEnabled'}
        @{Name = 'pingInterval'; Path = 'processModel.pingInterval'}
        @{Name = 'pingResponseTime'; Path = 'processModel.pingResponseTime'}
        @{Name = 'setProfileEnvironment'; Path = 'processModel.setProfileEnvironment'}
        @{Name = 'shutdownTimeLimit'; Path = 'processModel.shutdownTimeLimit'}
        @{Name = 'startupTimeLimit'; Path = 'processModel.startupTimeLimit'}

        # Process Orphaning
        @{Name = 'orphanActionExe'; Path = 'failure.orphanActionExe'}
        @{Name = 'orphanActionParams'; Path = 'failure.orphanActionParams'}
        @{Name = 'orphanWorkerProcess'; Path = 'failure.orphanWorkerProcess'}

        # Rapid-Fail Protection
        @{Name = 'loadBalancerCapabilities'; Path = 'failure.loadBalancerCapabilities'}
        @{Name = 'rapidFailProtection'; Path = 'failure.rapidFailProtection'}
        @{Name = 'rapidFailProtectionInterval'; Path = 'failure.rapidFailProtectionInterval'}
        @{Name = 'rapidFailProtectionMaxCrashes'; Path = 'failure.rapidFailProtectionMaxCrashes'}
        @{Name = 'autoShutdownExe'; Path = 'failure.autoShutdownExe'}
        @{Name = 'autoShutdownParams'; Path = 'failure.autoShutdownParams'}

        # Recycling
        @{Name = 'disallowOverlappingRotation'; Path = 'recycling.disallowOverlappingRotation'}
        @{Name = 'disallowRotationOnConfigChange'; Path = 'recycling.disallowRotationOnConfigChange'}
        @{Name = 'logEventOnRecycle'; Path = 'recycling.logEventOnRecycle'}
        @{Name = 'restartMemoryLimit'; Path = 'recycling.periodicRestart.memory'}
        @{Name = 'restartPrivateMemoryLimit'; Path = 'recycling.periodicRestart.privateMemory'}
        @{Name = 'restartRequestsLimit'; Path = 'recycling.periodicRestart.requests'}
        @{Name = 'restartTimeLimit'; Path = 'recycling.periodicRestart.time'}
        @{Name = 'restartSchedule'; Path = 'recycling.periodicRestart.schedule'}
    )
}

function Get-TargetResource {
    <#
    .SYNOPSIS
        This will return a hashtable of results 
    #>

    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateSet('Machine')]
        [System.String]
        $ApplyTo
    )

    Assert-Module

    Write-Verbose -Message $LocalizedData.VerboseGetTargetResource

    # XPath -Filter is case-sensitive. Use Where-Object to get the target application pool by name.
    $appPool = Get-AppPoolDefault

    $cimCredential = $null
    if ($appPool.processModel.identityType -eq 'SpecificUser') {
        $cimCredential = New-CimInstance -ClientOnly `
            -ClassName MSFT_Credential `
            -Namespace root/microsoft/windows/DesiredStateConfiguration `
            -Property @{
            UserName = [String]$appPool.processModel.userName
            Password = [String]$appPool.processModel.password
        }
    }
    

    $returnValue = @{
        Credential = $cimCredential
    }

    $PropertyData.Where(
        {
            $_.Name -ne 'restartSchedule'
        }
    ).ForEach(
        {
            $property = Get-Property -Object $appPool -PropertyName $_.Path
            $returnValue.Add($_.Name, $property)
        }
    )

    $restartScheduleCurrent = [String[]]@(
        @($appPool.recycling.periodicRestart.schedule.Collection).ForEach('value')
    )

    $returnValue.Add('restartSchedule', $restartScheduleCurrent)

    return $returnValue
}

function Set-TargetResource {
    <#
    .SYNOPSIS
        This will set the desired state
    #>

    [CmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSDSCUseVerboseMessageInDSCResource", "")]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateSet('Machine')]
        [System.String]
        $ApplyTo,

        [Parameter()]
        [ValidateSet('', 'v2.0', 'v4.0')]
        [System.String]
        $ManagedRuntimeVersion,


        [Boolean] $autoStart,

        [String] $CLRConfigFile,

        [Boolean] $enable32BitAppOnWin64,

        [Boolean] $enableConfigurationOverride,

        [ValidateSet('Integrated', 'Classic')]
        [String] $managedPipelineMode,

        [String] $managedRuntimeLoader,

        [Boolean] $passAnonymousToken,

        [ValidateSet('OnDemand', 'AlwaysRunning')]
        [String] $startMode,

        [ValidateRange(10, 65535)]
        [UInt32] $queueLength,

        [ValidateSet('NoAction', 'KillW3wp', 'Throttle', 'ThrottleUnderLoad')]
        [String] $cpuAction,

        [ValidateRange(0, 100000)]
        [UInt32] $cpuLimit,

        [ValidateScript( {
                ([ValidateRange(0, 1440)]$valueInMinutes = [TimeSpan]::Parse($_).TotalMinutes); $?
            })]
        [String] $cpuResetInterval,

        [Boolean] $cpuSmpAffinitized,

        [UInt32] $cpuSmpProcessorAffinityMask,

        [UInt32] $cpuSmpProcessorAffinityMask2,

        [ValidateSet(
            'ApplicationPoolIdentity', 'LocalService', 'LocalSystem',
            'NetworkService', 'SpecificUser'
        )]
        [String] $identityType,

        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()] 
        $Credential,

        [ValidateScript( {
                ([ValidateRange(0, 43200)]$valueInMinutes = [TimeSpan]::Parse($_).TotalMinutes); $?
            })]
        [String] $idleTimeout,

        [ValidateSet('Terminate', 'Suspend')]
        [String] $idleTimeoutAction,

        [Boolean] $loadUserProfile,

        [String] $logEventOnProcessModel,

        [ValidateSet('LogonBatch', 'LogonService')]
        [String] $logonType,

        [Boolean] $manualGroupMembership,

        [ValidateRange(0, 2147483647)]
        [UInt32] $maxProcesses,

        [Boolean] $pingingEnabled,

        [ValidateScript( {
                ([ValidateRange(1, 4294967)]$valueInSeconds = [TimeSpan]::Parse($_).TotalSeconds); $?
            })]
        [String] $pingInterval,

        [ValidateScript( {
                ([ValidateRange(1, 4294967)]$valueInSeconds = [TimeSpan]::Parse($_).TotalSeconds); $?
            })]
        [String] $pingResponseTime,

        [Boolean] $setProfileEnvironment,

        [ValidateScript( {
                ([ValidateRange(1, 4294967)]$valueInSeconds = [TimeSpan]::Parse($_).TotalSeconds); $?
            })]
        [String] $shutdownTimeLimit,

        [ValidateScript( {
                ([ValidateRange(1, 4294967)]$valueInSeconds = [TimeSpan]::Parse($_).TotalSeconds); $?
            })]
        [String] $startupTimeLimit,

        [String] $orphanActionExe,

        [String] $orphanActionParams,

        [Boolean] $orphanWorkerProcess,

        [ValidateSet('HttpLevel', 'TcpLevel')]
        [String] $loadBalancerCapabilities,

        [Boolean] $rapidFailProtection,

        [ValidateScript( {
                ([ValidateRange(1, 144000)]$valueInMinutes = [TimeSpan]::Parse($_).TotalMinutes); $?
            })]
        [String] $rapidFailProtectionInterval,

        [ValidateRange(0, 2147483647)]
        [UInt32] $rapidFailProtectionMaxCrashes,

        [String] $autoShutdownExe,

        [String] $autoShutdownParams,

        [Boolean] $disallowOverlappingRotation,

        [Boolean] $disallowRotationOnConfigChange,

        [String] $logEventOnRecycle,

        [UInt32] $restartMemoryLimit,

        [UInt32] $restartPrivateMemoryLimit,

        [UInt32] $restartRequestsLimit,

        [ValidateScript( {
                ([ValidateRange(0, 432000)]$valueInMinutes = [TimeSpan]::Parse($_).TotalMinutes); $?
            })]
        [String] $restartTimeLimit,

        [ValidateScript( {
                ($_ -eq '') -or
                (& {
                        ([ValidateRange(0, 86399)]$valueInSeconds = [TimeSpan]::Parse($_).TotalSeconds); $?
                    })
            })]
        [String[]] $restartSchedule
    )

    Assert-Module
    
    $appPool = Get-AppPoolDefault

    # Set Application Pool Properties

    $PropertyData.Where(
        {
            ($_.Name -in $PSBoundParameters.Keys) -and
            ($_.Name -notin @('restartSchedule'))
        }
    ).ForEach(
        {
            $propertyName = $_.Name
            $propertyPath = $_.Path
            $property = Get-Property -Object $appPool -PropertyName $propertyPath

            if ( 
                $PSBoundParameters[$propertyName] -ne $property
            ) {
                Write-Verbose -Message (
                    $LocalizedData['VerboseSetProperty'] -f $propertyName
                )
                
                Invoke-AppCmd -ArgumentList (
                    '/{0}:{1}' -f "applicationPoolDefaults.$($propertyPath)", $PSBoundParameters[$propertyName]
                )
            }
        }
    )

    if ($PSBoundParameters.ContainsKey('Credential')) {
        if ($PSBoundParameters['identityType'] -eq 'SpecificUser') {
            if ($appPool.processModel.userName -ne $Credential.UserName) {
                Write-Verbose -Message (
                    $LocalizedData['VerboseSetProperty'] -f 'Credential (userName)'
                )

                Invoke-AppCmd -ArgumentList (
                    '/applicationPoolDefaults.processModel.userName:{0}' -f $Credential.UserName
                )
            }

            $clearTextPassword = $Credential.GetNetworkCredential().Password

            if ($appPool.processModel.password -cne $clearTextPassword) {
                Write-Verbose -Message (
                    $LocalizedData['VerboseSetProperty'] -f 'Credential (password)'
                )

                Invoke-AppCmd -ArgumentList (
                    '/applicationPoolDefaults.processModel.password:{0}' -f $clearTextPassword
                )
            }
        }
        else {
            Write-Verbose -Message ($LocalizedData['VerboseCredentialToBeIgnored'])
        }
    }

    # Ensure userName and password are cleared if identityType isn't set to SpecificUser.
    if (
        (
            (
                ($PSBoundParameters.ContainsKey('identityType') -eq $true) -and
                ($PSBoundParameters['identityType'] -ne 'SpecificUser')
            ) -or
            (
                ($PSBoundParameters.ContainsKey('identityType') -eq $false) -and
                ($appPool.processModel.identityType -ne 'SpecificUser')
            )
        ) -and
        (
            ([String]::IsNullOrEmpty($appPool.processModel.userName) -eq $false) -or
            ([String]::IsNullOrEmpty($appPool.processModel.password) -eq $false)
        )
    ) {
        Write-Verbose -Message ($LocalizedData['VerboseClearCredential'])

        Invoke-AppCmd -ArgumentList '/applicationPoolDefaults.processModel.userName:'
        Invoke-AppCmd -ArgumentList '/applicationPoolDefaults.processModel.password:'
    }

    if ($PSBoundParameters.ContainsKey('restartSchedule')) {
        # Normalize the restartSchedule array values.
        $restartScheduleDesired = [String[]]@(
            $restartSchedule.Where(
                {
                    $_ -ne ''
                }
            ).ForEach(
                {
                    [TimeSpan]::Parse($_).ToString('hh\:mm\:ss')
                }
            ) |
                Select-Object -Unique
        )

        $restartScheduleCurrent = [String[]]@(
            @($appPool.recycling.periodicRestart.schedule.Collection).ForEach('value')
        )

        Compare-Object -ReferenceObject $restartScheduleDesired `
            -DifferenceObject $restartScheduleCurrent |
            ForEach-Object -Process {

            # Add value
            if ($_.SideIndicator -eq '<=') {
                Write-Verbose -Message (
                    $LocalizedData['VerboseRestartScheduleValueAdd'] -f
                    $_.InputObject
                )

                Invoke-AppCmd -ArgumentList (
                    "/+applicationPoolDefaults.recycling.periodicRestart.schedule.[value='{0}']" -f $_.InputObject
                )
            }
            # Remove value
            else {
                Write-Verbose -Message (
                    $LocalizedData['VerboseRestartScheduleValueRemove'] -f
                    $_.InputObject
                )

                Invoke-AppCmd -ArgumentList (
                    "/-applicationPoolDefaults.recycling.periodicRestart.schedule.[value='{0}']" -f $_.InputObject
                )
            }

        }
    }
    
}

function Test-TargetResource {
    <#
    .SYNOPSIS
        This tests the desired state. If the state is not correct it will return $false.
        If the state is correct it will return $true
    #>
    
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSDSCUseVerboseMessageInDSCResource", "")]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateSet('Machine')]
        [System.String]
        $ApplyTo,

        [Parameter()]
        [ValidateSet('', 'v2.0', 'v4.0')]
        [System.String]
        $ManagedRuntimeVersion,

        [Boolean] $autoStart,

        [String] $CLRConfigFile,

        [Boolean] $enable32BitAppOnWin64,

        [Boolean] $enableConfigurationOverride,

        [ValidateSet('Integrated', 'Classic')]
        [String] $managedPipelineMode,

        [String] $managedRuntimeLoader,

        [Boolean] $passAnonymousToken,

        [ValidateSet('OnDemand', 'AlwaysRunning')]
        [String] $startMode,

        [ValidateRange(10, 65535)]
        [UInt32] $queueLength,

        [ValidateSet('NoAction', 'KillW3wp', 'Throttle', 'ThrottleUnderLoad')]
        [String] $cpuAction,

        [ValidateRange(0, 100000)]
        [UInt32] $cpuLimit,

        [ValidateScript( {
                ([ValidateRange(0, 1440)]$valueInMinutes = [TimeSpan]::Parse($_).TotalMinutes); $?
            })]
        [String] $cpuResetInterval,

        [Boolean] $cpuSmpAffinitized,

        [UInt32] $cpuSmpProcessorAffinityMask,

        [UInt32] $cpuSmpProcessorAffinityMask2,

        [ValidateSet(
            'ApplicationPoolIdentity', 'LocalService', 'LocalSystem',
            'NetworkService', 'SpecificUser'
        )]
        [String] $identityType,

        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credential,

        [ValidateScript( {
                ([ValidateRange(0, 43200)]$valueInMinutes = [TimeSpan]::Parse($_).TotalMinutes); $?
            })]
        [String] $idleTimeout,

        [ValidateSet('Terminate', 'Suspend')]
        [String] $idleTimeoutAction,

        [Boolean] $loadUserProfile,

        [String] $logEventOnProcessModel,

        [ValidateSet('LogonBatch', 'LogonService')]
        [String] $logonType,

        [Boolean] $manualGroupMembership,

        [ValidateRange(0, 2147483647)]
        [UInt32] $maxProcesses,

        [Boolean] $pingingEnabled,

        [ValidateScript( {
                ([ValidateRange(1, 4294967)]$valueInSeconds = [TimeSpan]::Parse($_).TotalSeconds); $?
            })]
        [String] $pingInterval,

        [ValidateScript( {
                ([ValidateRange(1, 4294967)]$valueInSeconds = [TimeSpan]::Parse($_).TotalSeconds); $?
            })]
        [String] $pingResponseTime,

        [Boolean] $setProfileEnvironment,

        [ValidateScript( {
                ([ValidateRange(1, 4294967)]$valueInSeconds = [TimeSpan]::Parse($_).TotalSeconds); $?
            })]
        [String] $shutdownTimeLimit,

        [ValidateScript( {
                ([ValidateRange(1, 4294967)]$valueInSeconds = [TimeSpan]::Parse($_).TotalSeconds); $?
            })]
        [String] $startupTimeLimit,

        [String] $orphanActionExe,

        [String] $orphanActionParams,

        [Boolean] $orphanWorkerProcess,

        [ValidateSet('HttpLevel', 'TcpLevel')]
        [String] $loadBalancerCapabilities,

        [Boolean] $rapidFailProtection,

        [ValidateScript( {
                ([ValidateRange(1, 144000)]$valueInMinutes = [TimeSpan]::Parse($_).TotalMinutes); $?
            })]
        [String] $rapidFailProtectionInterval,

        [ValidateRange(0, 2147483647)]
        [UInt32] $rapidFailProtectionMaxCrashes,

        [String] $autoShutdownExe,

        [String] $autoShutdownParams,

        [Boolean] $disallowOverlappingRotation,

        [Boolean] $disallowRotationOnConfigChange,

        [String] $logEventOnRecycle,

        [UInt32] $restartMemoryLimit,

        [UInt32] $restartPrivateMemoryLimit,

        [UInt32] $restartRequestsLimit,

        [ValidateScript( {
                ([ValidateRange(0, 432000)]$valueInMinutes = [TimeSpan]::Parse($_).TotalMinutes); $?
            })]
        [String] $restartTimeLimit,

        [ValidateScript( {
                ($_ -eq '') -or
                (& {
                        ([ValidateRange(0, 86399)]$valueInSeconds = [TimeSpan]::Parse($_).TotalSeconds); $?
                    })
            })]
        [String[]] $restartSchedule
    )

    Assert-Module

    $inDesiredState = $true

    $appPool = Get-AppPoolDefault
            
    $PropertyData.Where(
        {
            ($_.Name -in $PSBoundParameters.Keys) -and
            ($_.Name -ne 'restartSchedule')
        }
    ).ForEach(
        {
            $propertyName = $_.Name
            $propertyPath = $_.Path
            $property = Get-Property -Object $appPool -PropertyName $propertyPath

            if (
                $PSBoundParameters[$propertyName] -ne $property
            ) {
                Write-Verbose -Message (
                    $LocalizedData['VerbosePropertyNotInDesiredState'] -f $propertyName
                )

                $inDesiredState = $false
            }
        }
    )

        
    if ($PSBoundParameters.ContainsKey('Credential')) {
        if ($PSBoundParameters['identityType'] -eq 'SpecificUser') {
            if ($appPool.processModel.userName -ne $Credential.UserName) {
                Write-Verbose -Message (
                    $LocalizedData['VerbosePropertyNotInDesiredState'] -f
                    'Credential (userName)'
                )

                $inDesiredState = $false
            }

            $clearTextPassword = $Credential.GetNetworkCredential().Password

            if ($appPool.processModel.password -cne $clearTextPassword) {
                Write-Verbose -Message (
                    $LocalizedData['VerbosePropertyNotInDesiredState'] -f
                    'Credential (password)'
                )

                $inDesiredState = $false
            }
        }
        else {
            Write-Verbose -Message ($LocalizedData['VerboseCredentialToBeIgnored'])
        }
    }

    # Ensure userName and password are cleared if identityType isn't set to SpecificUser.
    if (
        (
            (
                ($PSBoundParameters.ContainsKey('identityType') -eq $true) -and
                ($PSBoundParameters['identityType'] -ne 'SpecificUser')
            ) -or
            (
                ($PSBoundParameters.ContainsKey('identityType') -eq $false) -and
                ($appPool.processModel.identityType -ne 'SpecificUser')
            )
        ) -and
        (
            ([String]::IsNullOrEmpty($appPool.processModel.userName) -eq $false) -or
            ([String]::IsNullOrEmpty($appPool.processModel.password) -eq $false)
        )
    ) {
        Write-Verbose -Message ($LocalizedData['VerboseCredentialToBeCleared'])

        $inDesiredState = $false
    }

    if ($PSBoundParameters.ContainsKey('restartSchedule')) {
        # Normalize the restartSchedule array values.
        $restartScheduleDesired = [String[]]@(
            $restartSchedule.Where(
                {
                    $_ -ne ''
                }
            ).ForEach(
                {
                    [TimeSpan]::Parse($_).ToString('hh\:mm\:ss')
                }
            ) |
                Select-Object -Unique
        )

        $restartScheduleCurrent = [String[]]@(
            @($appPool.recycling.periodicRestart.schedule.Collection).ForEach('value')
        )

        if (
            Compare-Object -ReferenceObject $restartScheduleDesired `
                -DifferenceObject $restartScheduleCurrent
        ) {
            Write-Verbose -Message (
                $LocalizedData['VerbosePropertyNotInDesiredState'] -f 'restartSchedule'
            )

            $inDesiredState = $false
        }
    }
    

    if ($inDesiredState -eq $true) {
        Write-Verbose -Message ($LocalizedData['VerboseResourceInDesiredState'])
    }
    else {
        Write-Verbose -Message ($LocalizedData['VerboseResourceNotInDesiredState'])
    }

    return $inDesiredState    
}

#region Helper Functions


function Get-Property {
    param 
    (
        [object] $Object,
        [string] $PropertyName)

    $parts = $PropertyName.Split('.')
    $firstPart = $parts[0]

    $value = $Object.$firstPart
    if ($parts.Count -gt 1) {
        $newParts = @()
        1..($parts.Count - 1) | ForEach-Object {
            $newParts += $parts[$_]
        }

        $newName = ($newParts -join '.')
        return Get-Property -Object $value -PropertyName $newName
    }
    else {
        return $value
    }
} 

<#
    .SYNOPSIS
        Runs appcmd.exe - if there's an error then the application will terminate
        
    .PARAMETER ArgumentList
        Optional list of string arguments to be passed into appcmd.exe    

#>
function Invoke-AppCmd {
    [CmdletBinding()]
    param
    (
        [String[]] $ArgumentList
    )

    <# 
            This is a local preference for the function which will terminate
            the program if there's an error invoking appcmd.exe
    #>
    $ErrorActionPreference = 'Stop'

    $appcmdFilePath = "$env:SystemRoot\System32\inetsrv\appcmd.exe"
    $allArguments = @("set", "config", "-section:system.applicationHost/applicationPools") + $ArgumentList + ("/commit:apphost")
    
    # Write-Verbose -Message "calling $($appcmdFilePath) $($allArguments)"
    $appcmdResult = $(& $appcmdFilePath $allArguments)
    Write-Verbose -Message $($appcmdResult).ToString()

    if ($LASTEXITCODE -ne 0) {
        $errorMessage = $LocalizedData['ErrorAppCmdNonZeroExitCode'] -f $LASTEXITCODE

        New-TerminatingError -ErrorId 'ErrorAppCmdNonZeroExitCode' `
            -ErrorMessage $errorMessage `
            -ErrorCategory 'InvalidResult'
    }
}


function Get-AppPoolDefault {
    # XPath -Filter is case-sensitive. Use Where-Object to get the target application pool by name.
    $appPool = Get-WebConfiguration `
        -PSPath 'MACHINE/WEBROOT/APPHOST' `
        -Filter '/system.applicationHost/applicationPools/applicationPoolDefaults' 


    if ($null -eq $appPool) {
        New-TerminatingError -ErrorId 'ErrorAppPoolDefaultsNotFound' `
            -ErrorMessage  $LocalizedData['ErrorAppPoolDefaultsNotFound'] `
            -ErrorCategory 'InvalidResult'
    }

    Write-Verbose -Message ($LocalizedData['VerboseAppPoolDefaultsFound'])

    return $appPool
}

#endregion

Export-ModuleMember -Function *-TargetResource
