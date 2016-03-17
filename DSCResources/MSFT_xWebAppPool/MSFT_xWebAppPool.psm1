#requires -Version 4.0

# Load the Helper Module
Import-Module -Name "$PSScriptRoot\..\Helper.psm1" -Verbose:$false

# Localized messages
data LocalizedData
{
    # culture="en-US"
    ConvertFrom-StringData -StringData @'
ErrorAppCmdPathNotFound           = AppCmd.exe could not be found at path "{0}".
ErrorNewAppPool                   = Failed to create application pool "{0}". Error: "{1}".
ErrorRemoveAppPool                = Failed to remove application pool "{0}". Error: "{1}".
ErrorStartAppPool                 = Failed to start application pool "{0}". Error: "{1}".
ErrorStopAppPool                  = Failed to stop application pool "{0}". Error: "{1}".
VerboseAppPoolFound               = Application pool "{0}" was found.
VerboseAppPoolNotFound            = Application pool "{0}" was not found.
VerboseEnsureNotInDesiredState    = The "Ensure" state of application pool "{0}" does not match the desired state.
VerbosePropertyNotInDesiredState  = The "{0}" property of application pool "{1}" does not match the desired state.
VerboseCredentialToBeCleared      = Custom account credentials of application pool "{0}" need to be cleared because the "identityType" property is not set to "SpecificUser".
VerboseCredentialToBeIgnored      = The "Credential" property is only valid when the "identityType" property is set to "SpecificUser".
VerboseResourceInDesiredState     = The target resource is already in the desired state. No action is required.
VerboseResourceNotInDesiredState  = The target resource is not in the desired state.
VerboseNewAppPool                 = Creating application pool "{0}".
VerboseRemoveAppPool              = Removing application pool "{0}".
VerboseStartAppPool               = Starting application pool "{0}".
VerboseStopAppPool                = Stopping application pool "{0}".
VerboseSetProperty                = Setting the "{0}" property of application pool "{1}".
VerboseClearCredential            = Clearing custom account credentials of application pool "{0}" because the "identityType" property is not set to "SpecificUser".
VerboseRestartScheduleValueAdd    = Adding value "{0}" to the "restartSchedule" collection of application pool "{1}".
VerboseRestartScheduleValueRemove = Removing value "{0}" from the "restartSchedule" collection of application pool "{1}".
'@
}

# Writable properties except Ensure and Credential
data PropertyList
{
    @(
        # General
        @{Name = 'State';                          Path = 'state'}
        @{Name = 'autoStart';                      Path = 'autoStart'}
        @{Name = 'CLRConfigFile';                  Path = 'CLRConfigFile'}
        @{Name = 'enable32BitAppOnWin64';          Path = 'enable32BitAppOnWin64'}
        @{Name = 'enableConfigurationOverride';    Path = 'enableConfigurationOverride'}
        @{Name = 'managedPipelineMode';            Path = 'managedPipelineMode'}
        @{Name = 'managedRuntimeLoader';           Path = 'managedRuntimeLoader'}
        @{Name = 'managedRuntimeVersion';          Path = 'managedRuntimeVersion'}
        @{Name = 'passAnonymousToken';             Path = 'passAnonymousToken'}
        @{Name = 'startMode';                      Path = 'startMode'}
        @{Name = 'queueLength';                    Path = 'queueLength'}

        # CPU
        @{Name = 'cpuAction';                      Path = 'cpu.action'}
        @{Name = 'cpuLimit';                       Path = 'cpu.limit'}
        @{Name = 'cpuResetInterval';               Path = 'cpu.resetInterval'}
        @{Name = 'cpuSmpAffinitized';              Path = 'cpu.smpAffinitized'}
        @{Name = 'cpuSmpProcessorAffinityMask';    Path = 'cpu.smpProcessorAffinityMask'}
        @{Name = 'cpuSmpProcessorAffinityMask2';   Path = 'cpu.smpProcessorAffinityMask2'}

        # Process Model
        @{Name = 'identityType';                   Path = 'processModel.identityType'}
        @{Name = 'idleTimeout';                    Path = 'processModel.idleTimeout'}
        @{Name = 'idleTimeoutAction';              Path = 'processModel.idleTimeoutAction'}
        @{Name = 'loadUserProfile';                Path = 'processModel.loadUserProfile'}
        @{Name = 'logEventOnProcessModel';         Path = 'processModel.logEventOnProcessModel'}
        @{Name = 'logonType';                      Path = 'processModel.logonType'}
        @{Name = 'manualGroupMembership';          Path = 'processModel.manualGroupMembership'}
        @{Name = 'maxProcesses';                   Path = 'processModel.maxProcesses'}
        @{Name = 'pingingEnabled';                 Path = 'processModel.pingingEnabled'}
        @{Name = 'pingInterval';                   Path = 'processModel.pingInterval'}
        @{Name = 'pingResponseTime';               Path = 'processModel.pingResponseTime'}
        @{Name = 'setProfileEnvironment';          Path = 'processModel.setProfileEnvironment'}
        @{Name = 'shutdownTimeLimit';              Path = 'processModel.shutdownTimeLimit'}
        @{Name = 'startupTimeLimit';               Path = 'processModel.startupTimeLimit'}

        # Process Orphaning
        @{Name = 'orphanActionExe';                Path = 'failure.orphanActionExe'}
        @{Name = 'orphanActionParams';             Path = 'failure.orphanActionParams'}
        @{Name = 'orphanWorkerProcess';            Path = 'failure.orphanWorkerProcess'}

        # Rapid-Fail Protection
        @{Name = 'loadBalancerCapabilities';       Path = 'failure.loadBalancerCapabilities'}
        @{Name = 'rapidFailProtection';            Path = 'failure.rapidFailProtection'}
        @{Name = 'rapidFailProtectionInterval';    Path = 'failure.rapidFailProtectionInterval'}
        @{Name = 'rapidFailProtectionMaxCrashes';  Path = 'failure.rapidFailProtectionMaxCrashes'}
        @{Name = 'autoShutdownExe';                Path = 'failure.autoShutdownExe'}
        @{Name = 'autoShutdownParams';             Path = 'failure.autoShutdownParams'}

        # Recycling
        @{Name = 'disallowOverlappingRotation';    Path = 'recycling.disallowOverlappingRotation'}
        @{Name = 'disallowRotationOnConfigChange'; Path = 'recycling.disallowRotationOnConfigChange'}
        @{Name = 'logEventOnRecycle';              Path = 'recycling.logEventOnRecycle'}
        @{Name = 'restartMemoryLimit';             Path = 'recycling.periodicRestart.memory'}
        @{Name = 'restartPrivateMemoryLimit';      Path = 'recycling.periodicRestart.privateMemory'}
        @{Name = 'restartRequestsLimit';           Path = 'recycling.periodicRestart.requests'}
        @{Name = 'restartTimeLimit';               Path = 'recycling.periodicRestart.time'}
        @{Name = 'restartSchedule';                Path = 'recycling.periodicRestart.schedule'}
    )
}

function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateLength(1, 64)] # The value must contain between 1 and 64 characters.
        [String]
        $Name
    )

    Assert-Module

    $AppPool = Get-WebConfiguration -Filter '/system.applicationHost/applicationPools/add' |
        Where-Object -FilterScript {$_.name -eq $Name}

    if ($AppPool -eq $null)
    {
        Write-Verbose -Message ($LocalizedData['VerboseAppPoolNotFound'] -f $Name)

        $ensureResult = 'Absent'
        $currentCredential = $null
    }
    else
    {
        Write-Verbose -Message ($LocalizedData['VerboseAppPoolFound'] -f $Name)

        $ensureResult = 'Present'

        if ($AppPool.processModel.identityType -eq 'SpecificUser')
        {
            if ([String]::IsNullOrEmpty($AppPool.processModel.userName))
            {
                $currentCredential = $null
            }
            else
            {
                if ([String]::IsNullOrEmpty($AppPool.processModel.password))
                {
                    $currentPassword = New-Object -TypeName SecureString
                }
                else
                {
                    $currentPassword = ConvertTo-SecureString -String $AppPool.processModel.password -AsPlainText -Force
                }

                $currentCredential = New-Object -TypeName PSCredential -ArgumentList $AppPool.processModel.userName, $currentPassword
            }
        }
        else
        {
            $currentCredential = $null
        }
    }

    $returnValue = @{
        Name = $Name
        Ensure = $ensureResult
        Credential = $currentCredential
    }

    $PropertyList.Where(
        {
            $_.Name -notin @('restartSchedule')
        }
    ).ForEach(
        {
            $returnValue.Add($_.Name, (Invoke-Expression -Command ('$AppPool.{0}' -f $_.Path)))
        }
    )

    $returnValue.Add('restartSchedule', @($AppPool.recycling.periodicRestart.schedule.Collection.ForEach('value')))

    return $returnValue
}

function Set-TargetResource
{
    [CmdletBinding(SupportsShouldProcess = $true)]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateLength(1, 64)] # The value must contain between 1 and 64 characters.
        [String]
        $Name,

        [ValidateSet('Present', 'Absent')]
        [String]
        $Ensure = 'Present',

        [ValidateSet('Started', 'Stopped')]
        [String]
        $State,

        [Boolean]
        $autoStart,

        [String]
        $CLRConfigFile,

        [Boolean]
        $enable32BitAppOnWin64,

        [Boolean]
        $enableConfigurationOverride,

        [ValidateSet('Integrated', 'Classic')]
        [String]
        $managedPipelineMode,

        [String]
        $managedRuntimeLoader,

        [ValidateSet('v4.0', 'v2.0', '')]
        [String]
        $managedRuntimeVersion,

        [Boolean]
        $passAnonymousToken,

        [ValidateSet('OnDemand', 'AlwaysRunning')]
        [String]
        $startMode,

        [ValidateRange(10, 65535)] # The value must be a valid integer between 10 and 65535.
        [UInt32]
        $queueLength,

        [ValidateSet('NoAction', 'KillW3wp', 'Throttle', 'ThrottleUnderLoad')]
        [String]
        $cpuAction,

        [ValidateRange(0, 100)] # The value must be a valid integer between 0 and 100.
        [UInt32]
        $cpuLimit,

        [ValidateScript({([ValidateRange(0, 1440)]$ValueInMinutes = [TimeSpan]::Parse($_).TotalMinutes)})] # The valid range (in minutes) is 0 to 1440.
        [String]
        $cpuResetInterval,

        [Boolean]
        $cpuSmpAffinitized,

        [UInt32]
        $cpuSmpProcessorAffinityMask,

        [UInt32]
        $cpuSmpProcessorAffinityMask2,

        [ValidateSet('ApplicationPoolIdentity', 'LocalService', 'LocalSystem', 'NetworkService', 'SpecificUser')]
        [String]
        $identityType,

        [System.Management.Automation.PSCredential]
        $Credential,

        [ValidateScript({([ValidateRange(0, 43200)]$ValueInMinutes = [TimeSpan]::Parse($_).TotalMinutes)})] # The valid range (in minutes) is 0 to 43200.
        [String]
        $idleTimeout,

        [ValidateSet('Terminate', 'Suspend')]
        [String]
        $idleTimeoutAction,

        [Boolean]
        $loadUserProfile,

        [String]
        $logEventOnProcessModel,

        [ValidateSet('LogonBatch', 'LogonService')]
        [String]
        $logonType,

        [Boolean]
        $manualGroupMembership,

        [UInt32]
        $maxProcesses,

        [Boolean]
        $pingingEnabled,

        [ValidateScript({([ValidateRange(1, 4294967)]$ValueInSeconds = [TimeSpan]::Parse($_).TotalSeconds)})] # The valid range (in seconds) is 1 to 4294967.
        [String]
        $pingInterval,

        [ValidateScript({([ValidateRange(1, 4294967)]$ValueInSeconds = [TimeSpan]::Parse($_).TotalSeconds)})] # The valid range (in seconds) is 1 to 4294967.
        [String]
        $pingResponseTime,

        [Boolean]
        $setProfileEnvironment,

        [ValidateScript({([ValidateRange(1, 4294967)]$ValueInSeconds = [TimeSpan]::Parse($_).TotalSeconds)})] # The valid range (in seconds) is 1 to 4294967.
        [String]
        $shutdownTimeLimit,

        [ValidateScript({([ValidateRange(1, 4294967)]$ValueInSeconds = [TimeSpan]::Parse($_).TotalSeconds)})] # The valid range (in seconds) is 1 to 4294967.
        [String]
        $startupTimeLimit,

        [String]
        $orphanActionExe,

        [String]
        $orphanActionParams,

        [Boolean]
        $orphanWorkerProcess,

        [ValidateSet('HttpLevel', 'TcpLevel')]
        [String]
        $loadBalancerCapabilities,

        [Boolean]
        $rapidFailProtection = $true,

        [ValidateScript({([ValidateRange(1, 144000)]$ValueInMinutes = [TimeSpan]::Parse($_).TotalMinutes)})] # The valid range (in minutes) is 1 to 144000.
        [String]
        $rapidFailProtectionInterval,

        [UInt32]
        $rapidFailProtectionMaxCrashes,

        [String]
        $autoShutdownExe,

        [String]
        $autoShutdownParams,

        [Boolean]
        $disallowOverlappingRotation,

        [Boolean]
        $disallowRotationOnConfigChange,

        [String]
        $logEventOnRecycle,

        [UInt32]
        $restartMemoryLimit,

        [UInt32]
        $restartPrivateMemoryLimit,

        [UInt32]
        $restartRequestsLimit,

        [ValidateScript({([ValidateRange(0, 432000)]$ValueInMinutes = [TimeSpan]::Parse($_).TotalMinutes)})] # The valid range (in minutes) is 0 to 432000.
        [String]
        $restartTimeLimit,

        # Allow empty strings, so a single empty string '' can be used to ensure all the values are removed.
        # The parameter is not added to $PSBoundParameters if its value is $null or is an empty array @() (DSC-specific behavior).
        # TimeSpan values must be between 00:00:00 and 23:59:59 seconds inclusive, with a granularity of 60 seconds.
        [ValidateScript({($_ -eq '') -or ([ValidateRange(0, 86399)]$ValueInSeconds = [TimeSpan]::Parse($_).TotalSeconds)})]
        [String[]]
        $restartSchedule
    )

    Assert-Module

    $AppPool = Get-WebConfiguration -Filter '/system.applicationHost/applicationPools/add' |
        Where-Object -FilterScript {$_.name -eq $Name}

    if ($Ensure -eq 'Present')
    {
        # Create Application Pool
        if ($AppPool -eq $null)
        {
            Write-Verbose -Message ($LocalizedData['VerboseAppPoolNotFound'] -f $Name)

            try
            {
                Write-Verbose -Message ($LocalizedData['VerboseNewAppPool'] -f $Name)
                $AppPool = New-WebAppPool -Name $Name -ErrorAction Stop
                Start-Sleep -Seconds 5
            }
            catch
            {
                $errorMessage = $LocalizedData['ErrorNewAppPool'] -f $Name, $_.Exception.Message
                New-TerminatingError -ErrorId 'ErrorNewAppPool' -ErrorMessage $errorMessage -ErrorCategory 'InvalidOperation'
            }
        }

        # Set Application Pool Properties
        if ($AppPool -ne $null)
        {
            Write-Verbose -Message ($LocalizedData['VerboseAppPoolFound'] -f $Name)

            $PropertyList.Where(
                {
                    ($_.Name -in $PSBoundParameters.Keys) -and
                    ($_.Name -notin @('State', 'restartSchedule'))
                }
            ).ForEach(
                {
                    $propertyName = $_.Name
                    $propertyPath = $_.Path

                    if ($PSBoundParameters[$propertyName] -ne (Invoke-Expression -Command ('$AppPool.{0}' -f $propertyPath)))
                    {
                        Write-Verbose -Message ($LocalizedData['VerboseSetProperty'] -f $propertyName, $Name)
                        Invoke-AppCmd -ArgumentList 'set', 'apppool', $Name, ('/{0}:{1}' -f $propertyPath, $PSBoundParameters[$propertyName])
                    }
                }
            )

            if ($PSBoundParameters.ContainsKey('Credential'))
            {
                if ($PSBoundParameters['identityType'] -eq 'SpecificUser')
                {
                    if ($AppPool.processModel.userName -ne $Credential.UserName)
                    {
                        Write-Verbose -Message ($LocalizedData['VerboseSetProperty'] -f 'Credential (userName)', $Name)
                        Invoke-AppCmd -ArgumentList 'set', 'apppool', $Name, ('/processModel.userName:{0}' -f $Credential.UserName)
                    }

                    $clearTextPassword = $Credential.GetNetworkCredential().Password

                    if ($AppPool.processModel.password -cne $clearTextPassword)
                    {
                        Write-Verbose -Message ($LocalizedData['VerboseSetProperty'] -f 'Credential (password)', $Name)
                        Invoke-AppCmd -ArgumentList 'set', 'apppool', $Name, ('/processModel.password:{0}' -f $clearTextPassword)
                    }
                }
                else
                {
                    Write-Verbose -Message ($LocalizedData['VerboseCredentialToBeIgnored'])
                }
            }

            # Ensure the userName and password are cleared in case identityType is not set to SpecificUser
            if (
                (
                    ($AppPool.processModel.identityType -ne 'SpecificUser') -and
                    ($PSBoundParameters['identityType'] -ne 'SpecificUser')
                ) -and
                (
                    (-not [String]::IsNullOrEmpty($AppPool.processModel.userName)) -or
                    (-not [String]::IsNullOrEmpty($AppPool.processModel.password))
                )
            )
            {
                Write-Verbose -Message ($LocalizedData['VerboseClearCredential'])
                Invoke-AppCmd -ArgumentList 'set', 'apppool', $Name, '/processModel.userName:'
                Invoke-AppCmd -ArgumentList 'set', 'apppool', $Name, '/processModel.password:'
            }

            if ($PSBoundParameters.ContainsKey('restartSchedule'))
            {
                if ($restartSchedule.Contains(''))
                {
                    # Omit empty strings. They are only needed to support removal of all values from the collection.
                    $restartSchedule = [String[]]@($restartSchedule.Where({$_ -ne ''}))
                }

                $restartScheduleCurrent = [String[]]@($AppPool.recycling.periodicRestart.schedule.Collection.ForEach('value'))

                Compare-Object -ReferenceObject @($restartSchedule | Select-Object -Unique) -DifferenceObject @($restartScheduleCurrent) |
                ForEach-Object -Process {

                    if ($_.SideIndicator -eq '<=') # Add value
                    {
                        Write-Verbose -Message ($LocalizedData['VerboseRestartScheduleValueAdd'] -f $_.InputObject, $Name)
                        Invoke-AppCmd -ArgumentList 'set', 'apppool', $Name, ("/+recycling.periodicRestart.schedule.[value='{0}']" -f $_.InputObject)
                    }
                    elseif ($_.SideIndicator -eq '=>') # Remove value
                    {
                        Write-Verbose -Message ($LocalizedData['VerboseRestartScheduleValueRemove'] -f $_.InputObject, $Name)
                        Invoke-AppCmd -ArgumentList 'set', 'apppool', $Name, ("/-recycling.periodicRestart.schedule.[value='{0}']" -f $_.InputObject)
                    }

                }
            }

            if ($PSBoundParameters.ContainsKey('State') -and $AppPool.state -ne $State)
            {
                if ($State -eq 'Started')
                {
                    try
                    {
                        Write-Verbose -Message ($LocalizedData['VerboseStartAppPool'] -f $Name)
                        Start-WebAppPool -Name $Name -ErrorAction Stop
                    }
                    catch
                    {
                        $errorMessage = $LocalizedData['ErrorStartAppPool'] -f $Name, $_.Exception.Message
                        New-TerminatingError -ErrorId 'ErrorStartAppPool' -ErrorMessage $errorMessage -ErrorCategory 'InvalidOperation'
                    }
                }
                else
                {
                    try
                    {
                        Write-Verbose -Message ($LocalizedData['VerboseStopAppPool'] -f $Name)
                        Stop-WebAppPool -Name $Name -ErrorAction Stop
                    }
                    catch
                    {
                        $errorMessage = $LocalizedData['ErrorStopAppPool'] -f $Name, $_.Exception.Message
                        New-TerminatingError -ErrorId 'ErrorStopAppPool' -ErrorMessage $errorMessage -ErrorCategory 'InvalidOperation'
                    }
                }
            }
        }
    }
    else
    {
        # Remove Application Pool
        if ($AppPool -ne $null)
        {
            Write-Verbose -Message ($LocalizedData['VerboseAppPoolFound'] -f $Name)

            if ($AppPool.state -eq 'Started')
            {
                try
                {
                    Write-Verbose -Message ($LocalizedData['VerboseStopAppPool'] -f $Name)
                    Stop-WebAppPool -Name $Name -ErrorAction Stop
                }
                catch
                {
                    $errorMessage = $LocalizedData['ErrorStopAppPool'] -f $Name, $_.Exception.Message
                    New-TerminatingError -ErrorId 'ErrorStopAppPool' -ErrorMessage $errorMessage -ErrorCategory 'InvalidOperation'
                }
            }

            try
            {
                Write-Verbose -Message ($LocalizedData['VerboseRemoveAppPool'] -f $Name)
                Remove-WebAppPool -Name $Name -ErrorAction Stop
            }
            catch
            {
                $errorMessage = $LocalizedData['ErrorRemoveAppPool'] -f $Name, $_.Exception.Message
                New-TerminatingError -ErrorId 'ErrorRemoveAppPool' -ErrorMessage $errorMessage -ErrorCategory 'InvalidOperation'
            }
        }
        else
        {
            Write-Verbose -Message ($LocalizedData['VerboseAppPoolNotFound'] -f $Name)
        }
    }
}

function Test-TargetResource
{
    [OutputType([Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateLength(1, 64)] # The value must contain between 1 and 64 characters.
        [String]
        $Name,

        [ValidateSet('Present', 'Absent')]
        [String]
        $Ensure = 'Present',

        [ValidateSet('Started', 'Stopped')]
        [String]
        $State,

        [Boolean]
        $autoStart,

        [String]
        $CLRConfigFile,

        [Boolean]
        $enable32BitAppOnWin64,

        [Boolean]
        $enableConfigurationOverride,

        [ValidateSet('Integrated', 'Classic')]
        [String]
        $managedPipelineMode,

        [String]
        $managedRuntimeLoader,

        [ValidateSet('v4.0', 'v2.0', '')]
        [String]
        $managedRuntimeVersion,

        [Boolean]
        $passAnonymousToken,

        [ValidateSet('OnDemand', 'AlwaysRunning')]
        [String]
        $startMode,

        [ValidateRange(10, 65535)] # The value must be a valid integer between 10 and 65535.
        [UInt32]
        $queueLength,

        [ValidateSet('NoAction', 'KillW3wp', 'Throttle', 'ThrottleUnderLoad')]
        [String]
        $cpuAction,

        [ValidateRange(0, 100)] # The value must be a valid integer between 0 and 100.
        [UInt32]
        $cpuLimit,

        [ValidateScript({([ValidateRange(0, 1440)]$ValueInMinutes = [TimeSpan]::Parse($_).TotalMinutes)})] # The valid range (in minutes) is 0 to 1440.
        [String]
        $cpuResetInterval,

        [Boolean]
        $cpuSmpAffinitized,

        [UInt32]
        $cpuSmpProcessorAffinityMask,

        [UInt32]
        $cpuSmpProcessorAffinityMask2,

        [ValidateSet('ApplicationPoolIdentity', 'LocalService', 'LocalSystem', 'NetworkService', 'SpecificUser')]
        [String]
        $identityType,

        [System.Management.Automation.PSCredential]
        $Credential,

        [ValidateScript({([ValidateRange(0, 43200)]$ValueInMinutes = [TimeSpan]::Parse($_).TotalMinutes)})] # The valid range (in minutes) is 0 to 43200.
        [String]
        $idleTimeout,

        [ValidateSet('Terminate', 'Suspend')]
        [String]
        $idleTimeoutAction,

        [Boolean]
        $loadUserProfile,

        [String]
        $logEventOnProcessModel,

        [ValidateSet('LogonBatch', 'LogonService')]
        [String]
        $logonType,

        [Boolean]
        $manualGroupMembership,

        [UInt32]
        $maxProcesses,

        [Boolean]
        $pingingEnabled,

        [ValidateScript({([ValidateRange(1, 4294967)]$ValueInSeconds = [TimeSpan]::Parse($_).TotalSeconds)})] # The valid range (in seconds) is 1 to 4294967.
        [String]
        $pingInterval,

        [ValidateScript({([ValidateRange(1, 4294967)]$ValueInSeconds = [TimeSpan]::Parse($_).TotalSeconds)})] # The valid range (in seconds) is 1 to 4294967.
        [String]
        $pingResponseTime,

        [Boolean]
        $setProfileEnvironment,

        [ValidateScript({([ValidateRange(1, 4294967)]$ValueInSeconds = [TimeSpan]::Parse($_).TotalSeconds)})] # The valid range (in seconds) is 1 to 4294967.
        [String]
        $shutdownTimeLimit,

        [ValidateScript({([ValidateRange(1, 4294967)]$ValueInSeconds = [TimeSpan]::Parse($_).TotalSeconds)})] # The valid range (in seconds) is 1 to 4294967.
        [String]
        $startupTimeLimit,

        [String]
        $orphanActionExe,

        [String]
        $orphanActionParams,

        [Boolean]
        $orphanWorkerProcess,

        [ValidateSet('HttpLevel', 'TcpLevel')]
        [String]
        $loadBalancerCapabilities,

        [Boolean]
        $rapidFailProtection = $true,

        [ValidateScript({([ValidateRange(1, 144000)]$ValueInMinutes = [TimeSpan]::Parse($_).TotalMinutes)})] # The valid range (in minutes) is 1 to 144000.
        [String]
        $rapidFailProtectionInterval,

        [UInt32]
        $rapidFailProtectionMaxCrashes,

        [String]
        $autoShutdownExe,

        [String]
        $autoShutdownParams,

        [Boolean]
        $disallowOverlappingRotation,

        [Boolean]
        $disallowRotationOnConfigChange,

        [String]
        $logEventOnRecycle,

        [UInt32]
        $restartMemoryLimit,

        [UInt32]
        $restartPrivateMemoryLimit,

        [UInt32]
        $restartRequestsLimit,

        [ValidateScript({([ValidateRange(0, 432000)]$ValueInMinutes = [TimeSpan]::Parse($_).TotalMinutes)})] # The valid range (in minutes) is 0 to 432000.
        [String]
        $restartTimeLimit,

        # Allow empty strings, so a single empty string '' can be used to ensure all the values are removed.
        # The parameter is not added to $PSBoundParameters if its value is $null or is an empty array @() (DSC-specific behavior).
        # TimeSpan values must be between 00:00:00 and 23:59:59 seconds inclusive, with a granularity of 60 seconds.
        [ValidateScript({($_ -eq '') -or ([ValidateRange(0, 86399)]$ValueInSeconds = [TimeSpan]::Parse($_).TotalSeconds)})]
        [String[]]
        $restartSchedule
    )

    Assert-Module

    $inDesiredState = $true

    $AppPool = Get-WebConfiguration -Filter '/system.applicationHost/applicationPools/add' |
        Where-Object -FilterScript {$_.name -eq $Name}

    if (
        ($Ensure -eq 'Absent' -and $AppPool -ne $null) -or
        ($Ensure -eq 'Present' -and $AppPool -eq $null)
    )
    {
        $inDesiredState = $false

        if ($AppPool -ne $null)
        {
            Write-Verbose -Message ($LocalizedData['VerboseAppPoolFound'] -f $Name)
        }
        else
        {
            Write-Verbose -Message ($LocalizedData['VerboseAppPoolNotFound'] -f $Name)
        }

        Write-Verbose -Message ($LocalizedData['VerboseEnsureNotInDesiredState'] -f $Name)
    }

    if ($Ensure -eq 'Present' -and $AppPool -ne $null)
    {
        Write-Verbose -Message ($LocalizedData['VerboseAppPoolFound'] -f $Name)

        $PropertyList.Where(
            {
                ($_.Name -in $PSBoundParameters.Keys) -and
                ($_.Name -notin @('restartSchedule'))
            }
        ).ForEach(
            {
                $propertyName = $_.Name
                $propertyPath = $_.Path

                if ($PSBoundParameters[$propertyName] -ne (Invoke-Expression -Command ('$AppPool.{0}' -f $propertyPath)))
                {
                    $inDesiredState = $false
                    Write-Verbose -Message ($LocalizedData['VerbosePropertyNotInDesiredState'] -f $propertyName, $Name)
                }
            }
        )

        if ($PSBoundParameters.ContainsKey('Credential'))
        {
            if ($PSBoundParameters['identityType'] -eq 'SpecificUser')
            {
                if ($AppPool.processModel.userName -ne $Credential.UserName)
                {
                    $inDesiredState = $false
                    Write-Verbose -Message ($LocalizedData['VerbosePropertyNotInDesiredState'] -f 'Credential (userName)', $Name)
                }

                $clearTextPassword = $Credential.GetNetworkCredential().Password

                if ($AppPool.processModel.password -cne $clearTextPassword)
                {
                    $inDesiredState = $false
                    Write-Verbose -Message ($LocalizedData['VerbosePropertyNotInDesiredState'] -f 'Credential (password)', $Name)
                }
            }
            else
            {
                Write-Verbose -Message ($LocalizedData['VerboseCredentialToBeIgnored'])
            }
        }

        # Ensure the userName and password are cleared in case identityType is not set to SpecificUser
        if (
            (
                ($AppPool.processModel.identityType -ne 'SpecificUser') -and
                ($PSBoundParameters['identityType'] -ne 'SpecificUser')
            ) -and
            (
                (-not [String]::IsNullOrEmpty($AppPool.processModel.userName)) -or
                (-not [String]::IsNullOrEmpty($AppPool.processModel.password))
            )
        )
        {
            $inDesiredState = $false
            Write-Verbose -Message ($LocalizedData['VerboseCredentialToBeCleared'])
        }

        if ($PSBoundParameters.ContainsKey('restartSchedule'))
        {
            if ($restartSchedule.Contains(''))
            {
                # Omit empty strings. They are allowed to support removal of all values from the 'schedule' collection.
                $restartSchedule = [String[]]@($restartSchedule.Where({$_ -ne ''}))
            }

            $restartScheduleCurrent = [String[]]@($AppPool.recycling.periodicRestart.schedule.Collection.ForEach('value'))

            if (Compare-Object -ReferenceObject @($restartSchedule | Select-Object -Unique) -DifferenceObject @($restartScheduleCurrent))
            {
                $inDesiredState = $false
                Write-Verbose -Message ($LocalizedData['VerbosePropertyNotInDesiredState'] -f 'restartSchedule', $Name)
            }
        }
    }

    if ($inDesiredState -eq $true)
    {
        Write-Verbose -Message ($LocalizedData['VerboseResourceInDesiredState'])
    }
    else
    {
        Write-Verbose -Message ($LocalizedData['VerboseResourceNotInDesiredState'])
    }

    return $inDesiredState
}

#region Helper Functions

function Invoke-AppCmd
{
    param
    (
        [String[]]
        $ArgumentList,

        [String]
        $Path = "$env:SystemRoot\System32\inetsrv\appcmd.exe"
    )

    if (Test-Path -Path $Path -PathType Leaf)
    {
        & $Path $ArgumentList
    }
    else
    {
        $errorMessage = $LocalizedData['ErrorAppCmdPathNotFound'] -f $Path
        New-TerminatingError -ErrorId 'ErrorAppCmdPathNotFound' -ErrorMessage $errorMessage -ErrorCategory 'ObjectNotFound'
    }
}

#endregion Helper Functions
