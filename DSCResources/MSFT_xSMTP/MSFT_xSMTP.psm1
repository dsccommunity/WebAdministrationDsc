#requires -Version 4.0 -Modules CimCmdlets

# Load the Helper Module
Import-Module -Name "$PSScriptRoot\..\Helper.psm1"

# Localized messages
data LocalizedData
{
    # culture="en-US"
    ConvertFrom-StringData -StringData @'
ErrorSMTPDiscoveryFailure = No SMTP Virutal server found.
ErrorLogFileDirectoryFailure = Invalid LogFileDirectory provided.
ErrorBadMailDirectoryFailure  = Invalid BadMailDirectory provided.
IPAddressFailure = Invalid IP address(s), please verifiy the IP addresse(s) are valid
EmailAddressFailure = Invalid Email address(s), please verifiy the Email addresse(s) are valid 
ErrorBindingsPortFailure = Invalid Port Range, please verifiy the port(s) are valid.
VerboseTestTargetFalseAuthFlags = AuthFlags is not in the desired state.
VerboseTestTargetFalseBadMailDirectory = BadMailDirectory is not in the desired state.
VerboseTestTargetFalseConnectionTimeout = ConnectionTimeout is not in the desired state.
VerboseTestTargetFalseEnableReverseDnsLookup = EnableReverseDnsLookup is not in the desired state.
VerboseTestTargetFalseFullyQualifiedDomainName = FullyQualifiedDomainName is not in the desired state.
VerboseTestTargetFalseHopCount = HopCount is not in the desired state.
VerboseTestTargetFalseLogFileDirectory = LogFileDirectory is not in the desired state.
VerboseTestTargetFalseLogFilePeriod = LogFilePeriod is not in the desired state.
VerboseTestTargetFalseLogFileTruncateSize = LogFileTruncateSize is not in the desired state.
VerboseTestTargetFalseLogType = LogType is not in the desired state.
VerboseTestTargetFalseMasqueradeDomain = MasqueradeDomain is not in the desired state.
VerboseTestTargetFalseMaxBatchedMessages = MaxBatchedMessages is not in the desired state.
VerboseTestTargetFalseMaxConnections = MaxConnections is not in the desired state.
VerboseTestTargetFalseMaxMessageSize = MaxMessageSize is not in the desired state.
VerboseTestTargetFalseMaxOutConnections = MaxOutConnections is not in the desired state.
VerboseTestTargetFalseMaxOutConnectionsPerDomain = MaxOutConnectionsPerDomain is not in the desired state.
VerboseTestTargetFalseMaxRecipients = MaxRecipients is not in the desired state.
VerboseTestTargetFalseMaxSessionSize = MaxSessionSize is not in the desired state.
VerboseTestTargetFalseRelayForAuth = RelayForAuth is not in the desired state.
VerboseTestTargetFalseRemoteSmtpPort = RemoteSmtpPort is not in the desired state.
VerboseTestTargetFalseRemoteTimeout = RemoteTimeout is not in the desired state.
VerboseTestTargetFalseSaslLogonDomain = SaslLogonDomain is not in the desired state.
VerboseTestTargetFalseSendNdrTo = SendNdrTo is not in the desired state.
VerboseTestTargetFalseServerBindings = ServerBindings is not in the desired state.
VerboseTestTargetFalseSmartHost = SmartHost is not in the desired state.
VerboseTestTargetFalseSmartHostType = SmartHostType is not in the desired state.
VerboseTestTargetFalseSmtpInboundCommandSupportOptions = SmtpInboundCommandSupportOptions is not in the desired state.
VerboseTestTargetFalseSmtpLocalDelayExpireMinutes = SmtpLocalDelayExpireMinutes is not in the desired state.
VerboseTestTargetFalseSmtpLocalNDRExpireMinutes = SmtpLocalNDRExpireMinutes is not in the desired state.
VerboseTestTargetFalseSmtpRemoteDelayExpireMinutes = SmtpRemoteDelayExpireMinutes is not in the desired state.
VerboseTestTargetFalseSmtpRemoteNDRExpireMinutes = SmtpRemoteNDRExpireMinutes is not in the desired state.
VerboseTestTargetFalseSmtpRemoteProgressiveRetry = SmtpRemoteProgressiveRetry is not in the desired state.
VerboseSetTargetAuthFlags = Updated SMTP Setting AuthFlags.
VerboseSetTargetBadMailDirectory = Updated SMTP Setting BadMailDirectory.
VerboseSetTargetConnectionTimeout = Updated SMTP Setting ConnectionTimeout.
VerboseSetTargetEnableReverseDnsLookup = Updated SMTP Setting EnableReverseDnsLookup.
VerboseSetTargetFullyQualifiedDomainName = Updated SMTP Setting FullyQualifiedDomainName.
VerboseSetTargetHopCount = Updated SMTP Setting HopCount.
VerboseSetTargetLogFileDirectory = Updated SMTP Setting LogFileDirectory.
VerboseSetTargetLogFilePeriod = Updated SMTP Setting LogFilePeriod.
VerboseSetTargetLogFileTruncateSize = Updated SMTP Setting LogFileTruncateSize.
VerboseSetTargetLogType = Updated SMTP Setting LogType.
VerboseSetTargetMasqueradeDomain = Updated SMTP Setting MasqueradeDomain.
VerboseSetTargetMaxBatchedMessages = Updated SMTP Setting MaxBatchedMessages.
VerboseSetTargetMaxConnections = Updated SMTP Setting MaxConnections.
VerboseSetTargetMaxMessageSize = Updated SMTP Setting MaxMessageSize.
VerboseSetTargetMaxOutConnections = Updated SMTP Setting MaxOutConnections.
VerboseSetTargetMaxOutConnectionsPerDomain = Updated SMTP Setting MaxOutConnectionsPerDomain.
VerboseSetTargetMaxRecipients = Updated SMTP Setting MaxRecipients.
VerboseSetTargetMaxSessionSize = Updated SMTP Setting MaxSessionSize.
VerboseSetTargetRelayForAuth = Updated SMTP Setting RelayForAuth.
VerboseSetTargetRemoteSmtpPort = Updated SMTP Setting RemoteSmtpPort.
VerboseSetTargetRemoteTimeout = Updated SMTP Setting RemoteTimeout.
VerboseSetTargetSaslLogonDomain = Updated SMTP Setting SaslLogonDomain.
VerboseSetTargetSendNdrTo = Updated SMTP Setting SendNdrTo.
VerboseSetTargetServerBindings = Updated SMTP Setting ServerBindings.
VerboseSetTargetSmartHost = Updated SMTP Setting SmartHost.
VerboseSetTargetSmartHostType = Updated SMTP Setting SmartHostType.
VerboseSetTargetSmtpInboundCommandSupportOptions = Updated SMTP Setting SmtpInboundCommandSupportOptions.
VerboseSetTargetSmtpLocalDelayExpireMinutes = Updated SMTP Setting SmtpLocalDelayExpireMinutes.
VerboseSetTargetSmtpLocalNDRExpireMinutes = Updated SMTP Setting SmtpLocalNDRExpireMinutes.
VerboseSetTargetSmtpRemoteDelayExpireMinutes = Updated SMTP Setting SmtpRemoteDelayExpireMinutes.
VerboseSetTargetSmtpRemoteNDRExpireMinutes = Updated SMTP Setting SmtpRemoteNDRExpireMinutes.
VerboseSetTargetSmtpRemoteProgressiveRetry = Updated SMTP Setting SmtpRemoteProgressiveRetry.
'@
}

function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateSet('1')]
        [String]
        $Name
    )

    $CurrentSMTP = Get-SMTPSettings -ID $Name
    
    if (-not ($CurrentSMTP))
    {
        return @{
            Name = $Name
        }
    }
    else
    {
        return @{
            Name                             = $Name
            AuthFlags                        = $CurrentSMTP.Properties['AuthFlags']
            BadMailDirectory                 = $CurrentSMTP.Properties['BadMailDirectory']
            ConnectionTimeout                = $CurrentSMTP.Properties['ConnectionTimeout']
            EnableReverseDnsLookup           = $CurrentSMTP.Properties['EnableReverseDnsLookup']
            FullyQualifiedDomainName         = $CurrentSMTP.Properties['FullyQualifiedDomainName']
            HopCount                         = $CurrentSMTP.Properties['HopCount']
            LogFileDirectory                 = $CurrentSMTP.Properties['LogFileDirectory']
            LogFilePeriod                    = $CurrentSMTP.Properties['LogFilePeriod']
            LogFileTruncateSize              = $CurrentSMTP.Properties['LogFileTruncateSize']
            LogType                          = $CurrentSMTP.Properties['LogType']
            MasqueradeDomain                 = $CurrentSMTP.Properties['MasqueradeDomain']
            MaxBatchedMessages               = $CurrentSMTP.Properties['MaxBatchedMessages']
            MaxConnections                   = $CurrentSMTP.Properties['MaxConnections']
            MaxMessageSize                   = $CurrentSMTP.Properties['MaxMessageSize']
            MaxOutConnections                = $CurrentSMTP.Properties['MaxOutConnections']
            MaxOutConnectionsPerDomain       = $CurrentSMTP.Properties['MaxOutConnectionsPerDomain']
            MaxRecipients                    = $CurrentSMTP.Properties['MaxRecipients']
            MaxSessionSize                   = $CurrentSMTP.Properties['MaxSessionSize']
            RelayForAuth                     = $CurrentSMTP.Properties['RelayForAuth']
            RemoteSmtpPort                   = $CurrentSMTP.Properties['RemoteSmtpPort']
            RemoteTimeout                    = $CurrentSMTP.Properties['RemoteTimeout']
            SaslLogonDomain                  = $CurrentSMTP.Properties['SaslLogonDomain']
            SendNdrTo                        = $CurrentSMTP.Properties['SendNdrTo']
            ServerBindings                   = $CurrentSMTP.Properties['ServerBindings']
            SmartHost                        = $CurrentSMTP.Properties['SmartHost']
            SmartHostType                    = $CurrentSMTP.Properties['SmartHostType']
            SmtpInboundCommandSupportOptions = $CurrentSMTP.Properties['SmtpInboundCommandSupportOptions']
            SmtpLocalDelayExpireMinutes      = $CurrentSMTP.Properties['SmtpLocalDelayExpireMinutes']
            SmtpLocalNDRExpireMinutes        = $CurrentSMTP.Properties['SmtpLocalNDRExpireMinutes']
            SmtpRemoteDelayExpireMinutes     = $CurrentSMTP.Properties['SmtpRemoteDelayExpireMinutes']
            SmtpRemoteNDRExpireMinutes       = $CurrentSMTP.Properties['SmtpRemoteNDRExpireMinutes']
            SmtpRemoteProgressiveRetry       = $CurrentSMTP.Properties['SmtpRemoteProgressiveRetry']
        }
    }
}

function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateSet('1')]
        [String]
        $Name,

        [Int]
        $AuthFlags,

        [String]
        $BadMailDirectory,

        [Int] 
        $ConnectionTimeout,

        [Boolean]
        $EnableReverseDnsLookup,

        [String]
        $FullyQualifiedDomainName,

        [Int]
        $HopCount,

        [String]
        $LogFileDirectory,

        [Int] 
        $LogFilePeriod,

        [Int]  
        $LogFileTruncateSize,

        [Int]
        $LogType,

        [String]
        $MasqueradeDomain,

        [Int]
        $MaxBatchedMessages,

        [Int]
        $MaxConnections,

        [Int]
        $MaxMessageSize,

        [Int] 
        $MaxOutConnections,

        [Int]
        $MaxOutConnectionsPerDomain,

        [Int]
        $MaxRecipients,

        [Int]
        $MaxSessionSize,

        [Int]
        $RelayForAuth,

        [Int]
        $RemoteSmtpPort,

        [Int] 
        $RemoteTimeout,

        [String]
        $SaslLogonDomain,

        [String]
        $SendNdrTo,

        [String[]]
        $ServerBindings,

        [String]
        $SmartHost,

        [Int]
        $SmartHostType,

        [Int]
        $SmtpInboundCommandSupportOptions,

        [Int]
        $SmtpLocalDelayExpireMinutes,

        [Int]
        $SmtpLocalNDRExpireMinutes,

        [Int]
        $SmtpRemoteDelayExpireMinutes,

        [Int]
        $SmtpRemoteNDRExpireMinutes,

        [String]
        $SmtpRemoteProgressiveRetry
    )
    
    Assert-Module
    
    $Result = Get-TargetResource -Name $Name

    #Update AuthFlags if required
    if (($PSBoundParameters.ContainsKey('AuthFlags') -and `
    $Result.AuthFlags -ne $AuthFlags))
    {
        Write-Verbose -Message ($LocalizedData.VerboseSetTargetAuthFlags)
        Set-SMTPSettings -Name $Name `
                         -setting 'AuthFlags' `
                         -value $AuthFlags
    }

    #Update BadMailDirectory if required
    if (($PSBoundParameters.ContainsKey('BadMailDirectory') -and `
    $Result.BadMailDirectory -ne $BadMailDirectory))
    {
        if(-not (Test-Path -Path $BadMailDirectory))
        {
            $ErrorMessage = $LocalizedData.ErrorBadMailDirectoryFailure
            New-TerminatingError -ErrorId 'BadMailDirectoryFailure' `
                                 -ErrorMessage $ErrorMessage `
                                 -ErrorCategory 'InvalidResult'
        }
        Write-Verbose -Message ($LocalizedData.VerboseSetTargetBadMailDirectory)
        Set-SMTPSettings -Name $Name `
                         -setting 'BadMailDirectory' `
                         -value $BadMailDirectory
    }

    #Update ConnectionTimeout if required
    if (($PSBoundParameters.ContainsKey('ConnectionTimeout') -and `
    $Result.ConnectionTimeout -ne $ConnectionTimeout))
    {
        Write-Verbose -Message ($LocalizedData.VerboseSetTargetConnectionTimeout)
        Set-SMTPSettings -Name $Name `
                         -setting 'ConnectionTimeout' `
                         -value $ConnectionTimeout
    }

    #Update EnableReverseDnsLookup if required
    if (($PSBoundParameters.ContainsKey('EnableReverseDnsLookup') -and `
    $Result.EnableReverseDnsLookup -ne $EnableReverseDnsLookup))
    {
        Write-Verbose -Message ($LocalizedData.VerboseSetTargetEnableReverseDnsLookup)
        Set-SMTPSettings -Name $Name `
                         -setting 'EnableReverseDnsLookup' `
                         -value $EnableReverseDnsLookup
    }

    #Update FullyQualifiedDomainName if required
    if (($PSBoundParameters.ContainsKey('FullyQualifiedDomainName') -and `
    $Result.FullyQualifiedDomainName -ne $FullyQualifiedDomainName))
    {
        Write-Verbose -Message ($LocalizedData.VerboseSetTargetFullyQualifiedDomainName)
        Set-SMTPSettings -Name $Name `
                         -setting 'FullyQualifiedDomainName' `
                         -value $FullyQualifiedDomainName
    }

    #Update HopCount if required
    if (($PSBoundParameters.ContainsKey('HopCount') -and `
    $Result.HopCount -ne $HopCount))
    {
        Write-Verbose -Message ($LocalizedData.VerboseSetTargetHopCount)
        Set-SMTPSettings -Name $Name `
                         -setting 'HopCount' `
                         -value $HopCount
    }

    #Update LogFileDirectory if required
    if (($PSBoundParameters.ContainsKey('LogFileDirectory') -and `
    $Result.LogFileDirectory -ne $LogFileDirectory))
    {
        if(-not (Test-Path -Path $LogFileDirectory))
        {
            $ErrorMessage = $LocalizedData.ErrorLogFileDirectoryFailure
            New-TerminatingError -ErrorId 'LogFileDirectoryFailure' `
                                 -ErrorMessage $ErrorMessage `
                                 -ErrorCategory 'InvalidResult'
        }
        Write-Verbose -Message ($LocalizedData.VerboseSetTargetLogFileDirectory)
        Set-SMTPSettings -Name $Name `
                         -setting 'LogFileDirectory' `
                         -value $LogFileDirectory
    }

    #Update LogFilePeriod if required
    if (($PSBoundParameters.ContainsKey('LogFilePeriod') -and `
    $Result.LogFilePeriod -ne $LogFilePeriod))
    {
        Write-Verbose -Message ($LocalizedData.VerboseSetTargetLogFilePeriod)
        Set-SMTPSettings -Name $Name `
                         -setting 'LogFilePeriod' `
                         -value $LogFilePeriod
    }

    #Update LogFileTruncateSize if required
    if (($PSBoundParameters.ContainsKey('LogFileTruncateSize') -and `
    $Result.LogFileTruncateSize -ne $LogFileTruncateSize))
    {
        Write-Verbose -Message ($LocalizedData.VerboseSetTargetLogFileTruncateSize)
        Set-SMTPSettings -Name $Name `
                         -setting 'LogFileTruncateSize' `
                         -value $LogFileTruncateSize
    }

    #Update LogType if required
    if (($PSBoundParameters.ContainsKey('LogType') -and `
    $Result.LogType -ne $LogType))
    {
        Write-Verbose -Message ($LocalizedData.VerboseSetTargetLogType)
        Set-SMTPSettings -Name $Name `
                         -setting 'LogType' `
                         -value $LogType
    }

    #Update MasqueradeDomain if required
    if (($PSBoundParameters.ContainsKey('MasqueradeDomain') -and `
    $Result.MasqueradeDomain -ne $MasqueradeDomain))
    {
        Write-Verbose -Message ($LocalizedData.VerboseSetTargetMasqueradeDomain)
        Set-SMTPSettings -Name $Name `
                         -setting 'MasqueradeDomain' `
                         -value $MasqueradeDomain
    }

    #Update MaxBatchedMessages if required
    if (($PSBoundParameters.ContainsKey('MaxBatchedMessages') -and `
    $Result.MaxBatchedMessages -ne $MaxBatchedMessages))
    {
        Write-Verbose -Message ($LocalizedData.VerboseSetTargetMaxBatchedMessages)
        Set-SMTPSettings -Name $Name `
                         -setting 'MaxBatchedMessages' `
                         -value $MaxBatchedMessages
    }

    #Update MaxConnections if required
    if (($PSBoundParameters.ContainsKey('MaxConnections') -and `
    $Result.MaxConnections -ne $MaxConnections))
    {
        Write-Verbose -Message ($LocalizedData.VerboseSetTargetMaxConnections)
        Set-SMTPSettings -Name $Name `
                         -setting 'MaxConnections' `
                         -value $MaxConnections
    }

    #Update MaxMessageSize if required
    if (($PSBoundParameters.ContainsKey('MaxMessageSize') -and `
    $Result.MaxMessageSize -ne $MaxMessageSize))
    {
        Write-Verbose -Message ($LocalizedData.VerboseSetTargetMaxMessageSize)
        Set-SMTPSettings -Name $Name `
                         -setting 'MaxMessageSize' `
                         -value $MaxMessageSize
    }

    #Update MaxOutConnections if required
    if (($PSBoundParameters.ContainsKey('MaxOutConnections') -and `
    $Result.MaxOutConnections -ne $MaxOutConnections))
    {
        Write-Verbose -Message ($LocalizedData.VerboseSetTargetMaxOutConnections)
        Set-SMTPSettings -Name $Name `
                         -setting 'MaxOutConnections' `
                         -value $MaxOutConnections
    }

    #Update MaxOutConnectionsPerDomain if required
    if (($PSBoundParameters.ContainsKey('MaxOutConnectionsPerDomain') -and `
    $Result.MaxOutConnectionsPerDomain -ne $MaxOutConnectionsPerDomain))
    {
        Write-Verbose -Message ($LocalizedData.VerboseSetTargetMaxOutConnectionsPerDomain)
        Set-SMTPSettings -Name $Name `
                         -setting 'MaxOutConnectionsPerDomain' `
                         -value $MaxOutConnectionsPerDomain
    }

    #Update MaxRecipients if required
    if (($PSBoundParameters.ContainsKey('MaxRecipients') -and `
    $Result.MaxRecipients -ne $MaxRecipients))
    {
        Write-Verbose -Message ($LocalizedData.VerboseSetTargetMaxRecipients)
        Set-SMTPSettings -Name $Name `
                         -setting 'MaxRecipients' `
                         -value $MaxRecipients
    }

    #Update MaxSessionSize if required
    if (($PSBoundParameters.ContainsKey('MaxSessionSize') -and `
    $Result.MaxSessionSize -ne $MaxSessionSize))
    {
        Write-Verbose -Message ($LocalizedData.VerboseSetTargetMaxSessionSize)
        Set-SMTPSettings -Name $Name `
                         -setting 'MaxSessionSize' `
                         -value $MaxSessionSize
    }

    #Update RelayForAuth if required
    if (($PSBoundParameters.ContainsKey('RelayForAuth') -and `
    $Result.RelayForAuth -ne $RelayForAuth))
    {
        Write-Verbose -Message ($LocalizedData.VerboseSetTargetRelayForAuth)
        Set-SMTPSettings -Name $Name `
                         -setting 'RelayForAuth' `
                         -value $RelayForAuth
    }

    #Update RemoteSmtpPort if required
    if (($PSBoundParameters.ContainsKey('RemoteSmtpPort') -and `
    $Result.RemoteSmtpPort -ne $RemoteSmtpPort))
    {
        Write-Verbose -Message ($LocalizedData.VerboseSetTargetRemoteSmtpPort)
        Set-SMTPSettings -Name $Name `
                         -setting 'RemoteSmtpPort' `
                         -value $RemoteSmtpPort
    }

    #Update RemoteTimeout if required
    if (($PSBoundParameters.ContainsKey('RemoteTimeout') -and `
    $Result.RemoteTimeout -ne $RemoteTimeout))
    {
        Write-Verbose -Message ($LocalizedData.VerboseSetTargetRemoteTimeout)
        Set-SMTPSettings -Name $Name `
                         -setting 'RemoteTimeout' `
                         -value $RemoteTimeout
    }

    #Update SaslLogonDomain if required
    if (($PSBoundParameters.ContainsKey('SaslLogonDomain') -and `
    $Result.SaslLogonDomain -ne $SaslLogonDomain))
    {
        Write-Verbose -Message ($LocalizedData.VerboseSetTargetSaslLogonDomain)
        Set-SMTPSettings -Name $Name `
                         -setting 'SaslLogonDomain' `
                         -value $SaslLogonDomain
    }

    #Update SendNdrTo if required
    if (($PSBoundParameters.ContainsKey('SendNdrTo') -and `
    $Result.SendNdrTo -ne $SendNdrTo))
    {
        if(-not(Test-EmailAddress -Email $SendNdrTo))
        {
            Write-Verbose -Message ($LocalizedData.VerboseSetTargetSendNdrTo)
            Set-SMTPSettings -Name $Name `
                         -setting 'SendNdrTo' `
                         -value $SendNdrTo
        }
    }

    #Update ServerBindings if required
    if (($PSBoundParameters.ContainsKey('ServerBindings') -and `
    $Result.ServerBindings -ne $ServerBindings))
    {
        Write-Verbose -Message ($LocalizedData.VerboseSetTargetServerBindings)
        # Make input bindings which are an array, into a string
        $StringafiedBindings = $ServerBindings -join ' '
        Set-SMTPSettings -Name $Name `
                         -setting 'ServerBindings' `
                         -value $StringafiedBindings
    }

    #Update SmartHost if required
    if (($PSBoundParameters.ContainsKey('SmartHost') -and `
    $Result.SmartHost -ne $SmartHost))
    {
        Write-Verbose -Message ($LocalizedData.VerboseSetTargetSmartHost)
        Set-SMTPSettings -Name $Name `
                         -setting 'SmartHost' `
                         -value $SmartHost
    }

    #Update SmartHostType if required
    if (($PSBoundParameters.ContainsKey('SmartHostType') -and `
    $Result.SmartHostType -ne $SmartHostType))
    {
        Write-Verbose -Message ($LocalizedData.VerboseSetTargetSmartHostType)
        Set-SMTPSettings -Name $Name `
                         -setting 'SmartHostType' `
                         -value $SmartHostType
    }

    #Update SmtpInboundCommandSupportOptions if required
    if (($PSBoundParameters.ContainsKey('SmtpInboundCommandSupportOptions') -and `
    $Result.SmtpInboundCommandSupportOptions -ne $SmtpInboundCommandSupportOptions))
    {
        Write-Verbose -Message ($LocalizedData.VerboseSetTargetSmtpInboundCommandSupportOptions)
        Set-SMTPSettings -Name $Name `
                         -setting 'SmtpInboundCommandSupportOptions' `
                         -value $SmtpInboundCommandSupportOptions
    }

    #Update SmtpLocalDelayExpireMinutes if required
    if (($PSBoundParameters.ContainsKey('SmtpLocalDelayExpireMinutes') -and `
    $Result.SmtpLocalDelayExpireMinutes -ne $SmtpLocalDelayExpireMinutes))
    {
        Write-Verbose -Message ($LocalizedData.VerboseSetTargetSmtpLocalDelayExpireMinutes)
        Set-SMTPSettings -Name $Name `
                         -setting 'SmtpLocalDelayExpireMinutes' `
                         -value $SmtpLocalDelayExpireMinutes
    }

    #Update SmtpLocalNDRExpireMinutes if required
    if (($PSBoundParameters.ContainsKey('SmtpLocalNDRExpireMinutes') -and `
    $Result.SmtpLocalNDRExpireMinutes -ne $SmtpLocalNDRExpireMinutes))
    {
        Write-Verbose -Message ($LocalizedData.VerboseSetTargetSmtpLocalNDRExpireMinutes)
        Set-SMTPSettings -Name $Name `
                         -setting 'SmtpLocalNDRExpireMinutes' `
                         -value $SmtpLocalNDRExpireMinutes
    }

    #Update SmtpRemoteDelayExpireMinutes if required
    if (($PSBoundParameters.ContainsKey('SmtpRemoteDelayExpireMinutes') -and `
    $Result.SmtpRemoteDelayExpireMinutes -ne $SmtpRemoteDelayExpireMinutes))
    {
        Write-Verbose -Message ($LocalizedData.VerboseSetTargetSmtpRemoteDelayExpireMinutes)
        Set-SMTPSettings -Name $Name `
                         -setting 'SmtpRemoteDelayExpireMinutes' `
                         -value $SmtpRemoteDelayExpireMinutes
    }

    #Update SmtpRemoteNDRExpireMinutes if required
    if (($PSBoundParameters.ContainsKey('SmtpRemoteNDRExpireMinutes') -and `
    $Result.SmtpRemoteNDRExpireMinutes -ne $SmtpRemoteNDRExpireMinutes))
    {
        Write-Verbose -Message ($LocalizedData.VerboseSetTargetSmtpRemoteNDRExpireMinutes)
        Set-SMTPSettings -Name $Name `
                         -setting 'SmtpRemoteNDRExpireMinutes' `
                         -value $SmtpRemoteNDRExpireMinutes
    }

    #Update SmtpRemoteProgressiveRetry if required
    if (($PSBoundParameters.ContainsKey('SmtpRemoteProgressiveRetry') -and `
    $Result.SmtpRemoteProgressiveRetry -ne $SmtpRemoteProgressiveRetry))
    {
        Write-Verbose -Message ($LocalizedData.VerboseSetTargetSmtpRemoteProgressiveRetry)
        Set-SMTPSettings -Name $Name `
                         -setting 'SmtpRemoteProgressiveRetry' `
                         -value $SmtpRemoteProgressiveRetry
    }
}

function Test-TargetResource
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateSet('1')]
        [String]
        $Name,
        
        [Int]
        $AuthFlags,

        [String]
        $BadMailDirectory,

        [Int] 
        $ConnectionTimeout,

        [Boolean]
        $EnableReverseDnsLookup,

        [String]
        $FullyQualifiedDomainName,

        [Int]
        $HopCount,

        [String]
        $LogFileDirectory,

        [Int] 
        $LogFilePeriod,

        [Int]  
        $LogFileTruncateSize,

        [Int]
        $LogType,

        [String]
        $MasqueradeDomain,

        [Int]
        $MaxBatchedMessages,

        [Int]
        $MaxConnections,

        [Int]
        $MaxMessageSize,

        [Int]
        $MaxOutConnections,

        [Int]
        $MaxOutConnectionsPerDomain,

        [Int]
        $MaxRecipients,

        [Int]
        $MaxSessionSize,

        [Int]
        $RelayForAuth,

        [Int]
        $RemoteSmtpPort,

        [Int]
        $RemoteTimeout,

        [String]
        $SaslLogonDomain,

        [String]
        $SendNdrTo,

        [String[]]
        $ServerBindings,

        [String]
        $SmartHost,

        [Int]
        $SmartHostType,

        [Int]
        $SmtpInboundCommandSupportOptions,

        [Int]
        $SmtpLocalDelayExpireMinutes,

        [Int]
        $SmtpLocalNDRExpireMinutes,

        [Int]
        $SmtpRemoteDelayExpireMinutes,

        [Int]
        $SmtpRemoteNDRExpireMinutes,

        [String]
        $SmtpRemoteProgressiveRetry
    )
    
    Assert-Module
    
    # Throw if SMTP not found
    if (-not (Get-SMTPSettings -ID $Name))
        {
            $ErrorMessage = $LocalizedData.ErrorSMTPDiscoveryFailure
            New-TerminatingError -ErrorId 'SMTPDiscoveryFailure' `
                                 -ErrorMessage $ErrorMessage `
                                 -ErrorCategory 'InvalidResult'
        }
        
    $Result = Get-TargetResource -Name $Name

    #Update AuthFlags if required
    if (($PSBoundParameters.ContainsKey('AuthFlags') -and 
    $Result.AuthFlags -ne $AuthFlags))
    {
        Write-Verbose -Message ($LocalizedData.VerboseTestTargetFalseAuthFlags)
        return $False
    }

    #Update BadMailDirectory if required
    if (($PSBoundParameters.ContainsKey('BadMailDirectory') -and 
    $Result.BadMailDirectory -ne $BadMailDirectory))
    {
        if(-not (Test-Path -Path $BadMailDirectory))
        {
            $ErrorMessage = $LocalizedData.ErrorBadMailDirectoryFailure
            New-TerminatingError -ErrorId 'BadMailDirectoryFailure' `
                                 -ErrorMessage $ErrorMessage `
                                 -ErrorCategory 'InvalidResult'
        }
        Write-Verbose -Message ($LocalizedData.VerboseTestTargetFalseBadMailDirectory)
        return $False
    }

    #Update ConnectionTimeout if required
    if (($PSBoundParameters.ContainsKey('ConnectionTimeout') -and 
    $Result.ConnectionTimeout -ne $ConnectionTimeout))
    {
        Write-Verbose -Message ($LocalizedData.VerboseTestTargetFalseConnectionTimeout)
        return $False
    }

    #Update EnableReverseDnsLookup if required
    if (($PSBoundParameters.ContainsKey('EnableReverseDnsLookup') -and 
    $Result.EnableReverseDnsLookup -ne $EnableReverseDnsLookup))
    {
        Write-Verbose -Message ($LocalizedData.VerboseTestTargetFalseEnableReverseDnsLookup)
        return $False
    }

    #Update FullyQualifiedDomainName if required
    if (($PSBoundParameters.ContainsKey('FullyQualifiedDomainName') -and 
    $Result.FullyQualifiedDomainName -ne $FullyQualifiedDomainName))
    {
        Write-Verbose -Message ($LocalizedData.VerboseTestTargetFalseFullyQualifiedDomainName)
        return $False
    }

    #Update HopCount if required
    if (($PSBoundParameters.ContainsKey('HopCount') -and 
    $Result.HopCount -ne $HopCount))
    {
        Write-Verbose -Message ($LocalizedData.VerboseTestTargetFalseHopCount)
        return $False
    }

    #Update LogFileDirectory if required
    if (($PSBoundParameters.ContainsKey('LogFileDirectory') -and 
    $Result.LogFileDirectory -ne $LogFileDirectory))
    {
        if(-not (Test-Path -Path $LogFileDirectory))
        {
            $ErrorMessage = $LocalizedData.ErrorLogFileDirectoryFailure
            New-TerminatingError -ErrorId 'LogFileDirectoryFailure' `
                                 -ErrorMessage $ErrorMessage `
                                 -ErrorCategory 'InvalidResult'
        }
        Write-Verbose -Message ($LocalizedData.VerboseTestTargetFalseLogFileDirectory)
        return $False
    }

    #Update LogFilePeriod if required
    if (($PSBoundParameters.ContainsKey('LogFilePeriod') -and 
    $Result.LogFilePeriod -ne $LogFilePeriod))
    {
        Write-Verbose -Message ($LocalizedData.VerboseTestTargetFalseLogFilePeriod)
        return $False
    }

    #Update LogFileTruncateSize if required
    if (($PSBoundParameters.ContainsKey('LogFileTruncateSize') -and 
    $Result.LogFileTruncateSize -ne $LogFileTruncateSize))
    {
        Write-Verbose -Message ($LocalizedData.VerboseTestTargetFalseLogFileTruncateSize)
        return $False
    }

    #Update LogType if required
    if (($PSBoundParameters.ContainsKey('LogType') -and 
    $Result.LogType -ne $LogType))
    {
        Write-Verbose -Message ($LocalizedData.VerboseTestTargetFalseLogType)
        return $False
    }

    #Update MasqueradeDomain if required
    if (($PSBoundParameters.ContainsKey('MasqueradeDomain') -and 
    $Result.MasqueradeDomain -ne $MasqueradeDomain))
    {
        Write-Verbose -Message ($LocalizedData.VerboseTestTargetFalseMasqueradeDomain)
        return $False
    }

    #Update MaxBatchedMessages if required
    if (($PSBoundParameters.ContainsKey('MaxBatchedMessages') -and 
    $Result.MaxBatchedMessages -ne $MaxBatchedMessages))
    {
        Write-Verbose -Message ($LocalizedData.VerboseTestTargetFalseMaxBatchedMessages)
        return $False
    }

    #Update MaxConnections if required
    if (($PSBoundParameters.ContainsKey('MaxConnections') -and 
    $Result.MaxConnections -ne $MaxConnections))
    {
        Write-Verbose -Message ($LocalizedData.VerboseTestTargetFalseMaxConnections)
        return $False
    }

    #Update MaxMessageSize if required
    if (($PSBoundParameters.ContainsKey('MaxMessageSize') -and 
    $Result.MaxMessageSize -ne $MaxMessageSize))
    {
        Write-Verbose -Message ($LocalizedData.VerboseTestTargetFalseMaxMessageSize)
        return $False
    }

    #Update MaxOutConnections if required
    if (($PSBoundParameters.ContainsKey('MaxOutConnections') -and 
    $Result.MaxOutConnections -ne $MaxOutConnections))
    {
        Write-Verbose -Message ($LocalizedData.VerboseTestTargetFalseMaxOutConnections)
        return $False
    }

    #Update MaxOutConnectionsPerDomain if required
    if (($PSBoundParameters.ContainsKey('MaxOutConnectionsPerDomain') -and 
    $Result.MaxOutConnectionsPerDomain -ne $MaxOutConnectionsPerDomain))
    {
        Write-Verbose -Message ($LocalizedData.VerboseTestTargetFalseMaxOutConnectionsPerDomain)
        return $False
    }

    #Update MaxRecipients if required
    if (($PSBoundParameters.ContainsKey('MaxRecipients') -and 
    $Result.MaxRecipients -ne $MaxRecipients))
    {
        Write-Verbose -Message ($LocalizedData.VerboseTestTargetFalseMaxRecipients)
        return $False
    }

    #Update MaxSessionSize if required
    if (($PSBoundParameters.ContainsKey('MaxSessionSize') -and 
    $Result.MaxSessionSize -ne $MaxSessionSize))
    {
        Write-Verbose -Message ($LocalizedData.VerboseTestTargetFalseMaxSessionSize)
        return $False
    }

    #Update RelayForAuth if required
    if (($PSBoundParameters.ContainsKey('RelayForAuth') -and 
    $Result.RelayForAuth -ne $RelayForAuth))
    {
        Write-Verbose -Message ($LocalizedData.VerboseTestTargetFalseRelayForAuth)
        return $False
    }

    #Update RemoteSmtpPort if required
    if (($PSBoundParameters.ContainsKey('RemoteSmtpPort') -and 
    $Result.RemoteSmtpPort -ne $RemoteSmtpPort))
    {
        Write-Verbose -Message ($LocalizedData.VerboseTestTargetFalseRemoteSmtpPort)
        return $False
    }

    #Update RemoteTimeout if required
    if (($PSBoundParameters.ContainsKey('RemoteTimeout') -and 
    $Result.RemoteTimeout -ne $RemoteTimeout))
    {
        Write-Verbose -Message ($LocalizedData.VerboseTestTargetFalseRemoteTimeout)
        return $False
    }

    #Update SaslLogonDomain if required
    if (($PSBoundParameters.ContainsKey('SaslLogonDomain') -and 
    $Result.SaslLogonDomain -ne $SaslLogonDomain))
    {
        Write-Verbose -Message ($LocalizedData.VerboseTestTargetFalseSaslLogonDomain)
        return $False
    }

    #Update SendNdrTo if required
    if (($PSBoundParameters.ContainsKey('SendNdrTo') -and 
    $Result.SendNdrTo -ne $SendNdrTo))
    {
        if(-not(Test-EmailAddress -Email $SendNdrTo))
        {
            Write-Verbose -Message ($LocalizedData.VerboseTestTargetFalseSendNdrTo)
            return $False
        }
    }

    #Update ServerBindings if required
    if (($PSBoundParameters.ContainsKey('ServerBindings') -and 
    $Result.ServerBindings -ne $ServerBindings))
    {
        # Test if the desired IP and/or port input is valid
        if (-not (Test-SMTPBindings -ServerBindings $ServerBindings))
        {
            Write-Verbose -Message ($LocalizedData.VerboseTestTargetFalseServerBindings)
            return $False
        }
        
        # Test if the bindings are different
        if (-not(Confirm-UnqiueBindings `
                    -ExistingBindings $Result.ServerBindings `
                    -ProposedBindings $ServerBindings ))
        {
            Write-Verbose -Message ($LocalizedData.VerboseTestTargetFalseServerBindings)
            return $False
        }
    }

    #Update SmartHost if required
    if (($PSBoundParameters.ContainsKey('SmartHost') -and 
    $Result.SmartHost -ne $SmartHost))
    {
        Write-Verbose -Message ($LocalizedData.VerboseTestTargetFalseSmartHost)
        return $False
    }

    #Update SmartHostType if required
    if (($PSBoundParameters.ContainsKey('SmartHostType') -and 
    $Result.SmartHostType -ne $SmartHostType))
    {
        Write-Verbose -Message ($LocalizedData.VerboseTestTargetFalseSmartHostType)
        return $False
    }

    #Update SmtpInboundCommandSupportOptions if required
    if (($PSBoundParameters.ContainsKey('SmtpInboundCommandSupportOptions') -and 
    $Result.SmtpInboundCommandSupportOptions -ne $SmtpInboundCommandSupportOptions))
    {
        Write-Verbose `
            -Message ($LocalizedData.VerboseTestTargetFalseSmtpInboundCommandSupportOptions)
        return $False
    }

    #Update SmtpLocalDelayExpireMinutes if required
    if (($PSBoundParameters.ContainsKey('SmtpLocalDelayExpireMinutes') -and 
    $Result.SmtpLocalDelayExpireMinutes -ne $SmtpLocalDelayExpireMinutes))
    {
        Write-Verbose -Message ($LocalizedData.VerboseTestTargetFalseSmtpLocalDelayExpireMinutes)
        return $False
    }

    #Update SmtpLocalNDRExpireMinutes if required
    if (($PSBoundParameters.ContainsKey('SmtpLocalNDRExpireMinutes') -and 
    $Result.SmtpLocalNDRExpireMinutes -ne $SmtpLocalNDRExpireMinutes))
    {
        Write-Verbose -Message ($LocalizedData.VerboseTestTargetFalseSmtpLocalNDRExpireMinutes)
        return $False
    }

    #Update SmtpRemoteDelayExpireMinutes if required
    if (($PSBoundParameters.ContainsKey('SmtpRemoteDelayExpireMinutes') -and 
    $Result.SmtpRemoteDelayExpireMinutes -ne $SmtpRemoteDelayExpireMinutes))
    {
        Write-Verbose -Message ($LocalizedData.VerboseTestTargetFalseSmtpRemoteDelayExpireMinutes)
        return $False
    }

    #Update SmtpRemoteNDRExpireMinutes if required
    if (($PSBoundParameters.ContainsKey('SmtpRemoteNDRExpireMinutes') -and 
    $Result.SmtpRemoteNDRExpireMinutes -ne $SmtpRemoteNDRExpireMinutes))
    {
        Write-Verbose -Message ($LocalizedData.VerboseTestTargetFalseSmtpRemoteNDRExpireMinutes)
        return $False
    }

    #Update SmtpRemoteProgressiveRetry if required
    if (($PSBoundParameters.ContainsKey('SmtpRemoteProgressiveRetry') -and 
    $Result.SmtpRemoteProgressiveRetry -ne $SmtpRemoteProgressiveRetry))
    {
        Write-Verbose -Message ($LocalizedData.VerboseTestTargetFalseSmtpRemoteProgressiveRetry)
        return $False
    }
    
    return $true
}

#region Helper Functions

Function Confirm-UnqiueBindings
{
    <#
    .SYNOPSIS
        Helper function used to validate that the SMTP's binding information is unique.
        Returns False if bindings are not unique and True if they are
    .PARAMETER ExistingBindings
        Specifies existing SMTP bindings
    .PARAMETER ProposedBindings
        Specifies desired SMTP bindings.
    .NOTES
        The existing bindings are a [String] where are the desired are a [Array] so we 
        need to do some magic to make sure the compare works.
    #>

    [CmdletBinding()]
    [OutputType([Boolean])]
    param
    ( 
        [Parameter(Mandatory = $true)]
        [String]
        $ExistingBindings,
        
        [Parameter(Mandatory = $true)]
        [String[]]
        $ProposedBindings
    )

    $InputToCheck = @()
    foreach ($ProposedBinding in $ProposedBindings)
    { 
        $BindingAddition = $Binding + ':'
        $InputToCheck += $BindingAddition
    }

    $ExistingBindingssToCheck = $ExistingBindings -split '\n'

    $ExistingToCheck = @()
    foreach ($ExistingBinding in $ExistingBindingssToCheck)
    {
        $ExistingToCheck += $ExistingBinding.Trim()
    }

    $SortedExistingBindings = $ExistingToCheck | Sort-Object -Unique
    $SortedInputBindings = $InputToCheck| Sort-Object -Unique


    if (Compare-Object -ReferenceObject $SortedExistingBindings `
                       -DifferenceObject $SortedInputBindings `
                       -PassThru)
    {
        return $false
    }

    return $true
}

Function Get-SMTPSettings
{
    <#
    .SYNOPSIS
        Helper function used to get the SMTP server.
    .PARAMETER ID
        Specifies the ID of the SMTP virtual server. 1 is the default SMTP server.
    .NOTES
        All it does is wrap a [ASDI] call
    #>

    [CmdletBinding()]
    param
    ( 
        [Parameter(Mandatory = $true)]
        [String]
        $ID
    )

    return  [ADSI]"IIS://localhost/smtpsvc/${ID}"
}

Function Set-SMTPSettings
{
    <#
    .SYNOPSIS
        Helper function used to set the SMTP server settings.
    .PARAMETER ID
        Specifies the ID of the SMTP virtual server. 1 is the default SMTP server.
    .PARAMETER Settigng
        Specifies the setting of the SMTP virtual server to be changed.
    .PARAMETER Value
        Specifies the value of the SMTP virtual server setting to be changed.
    .NOTES
        All it does is wrap a [ASDI] call. Also this is used to allow pester to mock this call
    #>

    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [String]
        $Name,
        
        [Parameter(Mandatory = $true)]
        [String]
        $Setting,
        
        [Parameter(Mandatory = $true)]
        [String]
        $Value
    )
    
    $SMTPSite = [ADSI]"IIS://localhost/smtpsvc/${Name}"
    $SMTPSite.Put("$Setting", "$Value")
    $SMTPSite.SetInfo()
}

Function Test-EmailAddress
{
        <#
    .SYNOPSIS
        Tests that an email address is valid when used as input.
    .PARAMETER Email
        Specifies the  desired email address.
    .NOTES
        Simple function which casts an email address to [Net.Mail.MailAddress] to see if it 
        is valid are not. If not valid it will error, if vaild will return True
    #>

    [CmdletBinding()]
    param(
        
        [OutputType([Boolean])]
        [Parameter(Mandatory = $true)]
        [String[]]
        $Email
    )
    
    if($Email)
    {
        if (-not($Email -as [Net.Mail.MailAddress]))
        {
            $ErrorMessage = $LocalizedData.ErrorEmailAddressFailure
            New-TerminatingError -ErrorId 'EmailAddressFailure' `
                                    -ErrorMessage $ErrorMessage `
                                    -ErrorCategory 'InvalidResult'
        }
    }
    
    return $true
}

Function Test-SMTPBindings
{
    <#
        <#
    .SYNOPSIS
        Tests that an server bindings are valid when used as input.
    .PARAMETER ServerBindings
        Specifies the  desired server bindings.
    .NOTES
        Simple function which casts an IP  address to [ipaddress] to see if it 
        is valid are not. If not valid it will error, if vaild will return True.
        Does the same for the port but uses regex to check if valid in the correct
        port range.
    #>

    [CmdletBinding()]
    param(
        
        [OutputType([Boolean])]
        [Parameter(Mandatory = $true)]
        [String[]]
        $ServerBindings
    
    )

    foreach ($Binding in $ServerBindings)

    {
        $IP = ($Binding -split ':')[0]
        $Port = ($Binding -split ':')[1]

        if($IP)
        {
            if (-not($IP -as [ipaddress]))
            {
                $ErrorMessage = $LocalizedData.ErrorIPAddressFailure
                New-TerminatingError -ErrorId 'IPAddressFailure' `
                                     -ErrorMessage $ErrorMessage `
                                     -ErrorCategory 'InvalidResult'
            }
        }

        if($Port)
        {
            if (-not($Port -match `
                    '^(6553[0-5]|655[0-2]\d|65[0-4]\d\d|6[0-4]\d{3}|[1-5]\d{4}|[1-9]\d{0,3}|0)$')
                    )
            {
                $ErrorMessage = $LocalizedData.ErrorBindingsPortFailure
                New-TerminatingError -ErrorId 'BindingsPortFailure' `
                                     -ErrorMessage $ErrorMessage `
                                     -ErrorCategory 'InvalidResult'
            }
        }

        return $true
    }
}

#endregion

Export-ModuleMember -Function *-TargetResource
