# Load the Helper Module
Import-Module -Name "$PSScriptRoot\..\Helper.psm1"

# Localized messages
data LocalizedData
{
    # culture="en-US"
    ConvertFrom-StringData -StringData @'
        ErrorSMTPDiscoveryFailure              = No SMTP Virutal server found.
        ErrorLogFileDirectoryFailure           = Invalid LogFileDirectory provided.
        ErrorBadMailDirectoryFailure           = Invalid BadMailDirectory provided.
        ErrorIPAddressFailure                  = Invalid IP address(s), please verifiy the IP addresse(s) are valid
        ErrorEmailAddressFailure               = Invalid Email address(s), please verifiy the Email addresse(s) are valid 
        ErrorBindingsPortFailure               = Invalid Port Range, please verifiy the port(s) are valid.
        VerboseTestTargetResource              = SMTPSetting "{0}" is not correct.
        VerboseTestTargetFalseBadMailDirectory = BadMailDirectory is not in the desired state.
        VerboseTestTargetFalseLogFileDirectory = LogFileDirectory is not in the desired state.
        VerboseTestTargetFalseSendNdrTo        = SendNdrTo is not in the desired state.
        VerboseTestTargetFalseServerBindings   = ServerBindings is not in the desired state.
        VerboseSetTargetBadMailDirectory       = Updated SMTP Setting BadMailDirectory.       
        VerboseSetTargetLogFileDirectory       = Updated SMTP Setting LogFileDirectory.
        VerboseSetTargetSendNdrTo              = Updated SMTP Setting SendNdrTo.
        VerboseSetTargetServerBindings         = Updated SMTP Setting ServerBindings.
        VerboseSetTargetResourceUpdated        = Updated SMTPSetting "{0}".
'@
}
<#
    This is an array of all the parameters used by this resource
    It can be used by several of the functions to reduce the amount of code required
    Each element contains 3 properties:
    Name: The parameter name
    Source: The source where the existing parameter can be pulled from
    Type: This is the content type of the paramater (it is either array, string, boolean or blank)
#> 
data ParameterList
{
    @( 
        @{
            Name   = 'AuthFlags'
            Source = '$CurrentSMTP.Properties.AuthFlags'
            Type   = 'String'
        }
        @{
            Name   = 'BadMailDirectory'
            Source = '$CurrentSMTP.Properties.BadMailDirectory'
            Type   = 'String'
        }
        @{
            Name   = 'ConnectionTimeout'
            Source = '$CurrentSMTP.Properties.ConnectionTimeou'
            Type   = 'String'
        }
        @{
            Name   = 'EnableReverseDnsLookup'
            Source = '$CurrentSMTP.Properties.EnableReverseDnsLookup'
            Type   = 'Boolean'
        }
        @{
            Name   = 'FullyQualifiedDomainName'
            Source = '$CurrentSMTP.Properties.FullyQualifiedDomainName'
            Type   = 'String'
        }
        @{
            Name   = 'HopCount'
            Source = '$CurrentSMTP.Properties.HopCount'
            Type   = 'String'
        }
        @{
            Name   = 'LogFileDirectory'
            Source = '$CurrentSMTP.Properties.LogFileDirectory'
            Type   = 'String'
        }
        @{
            Name   = 'LogFilePeriod'
            Source = '$CurrentSMTP.Properties.LogFilePeriod'
            Type   = 'String'
        }
        @{
            Name   = 'LogFileTruncateSize'
            Source = '$CurrentSMTP.Properties.LogFileTruncateSize'
            Type   = 'String'
        }
        @{
            Name   = 'LogType'
            Source = '$CurrentSMTP.Properties.LogType'
            Type   = 'String'
        }
        @{
            Name   = 'MasqueradeDomain'
            Source = '$CurrentSMTP.Properties.MasqueradeDomain'
            Type   = 'String'
        }
        @{
            Name   = 'MaxBatchedMessages'
            Source = '$CurrentSMTP.Properties.MaxBatchedMessages'
            Type   = 'String'
        }
        @{
            Name   = 'MaxConnections'
            Source = '$CurrentSMTP.Properties.MaxConnections'
            Type   = 'String'
        }
        @{
            Name   = 'MaxMessageSize'
            Source = '$CurrentSMTP.Properties.MaxMessageSize'
            Type   = 'String'
        }
        @{
            Name   = 'MaxOutConnections'
            Source = '$CurrentSMTP.Properties.MaxOutConnections'
            Type   = 'String'
        }
        @{
            Name   = 'MaxOutConnectionsPerDomain'
            Source = '$CurrentSMTP.Properties.MaxOutConnectionsPerDomain'
            Type   = 'String'
        }
        @{
            Name   = 'MaxRecipients'
            Source = '$CurrentSMTP.Properties.MaxRecipients'
            Type   = 'String'
        }
        @{
            Name   = 'MaxSessionSize'
            Source = '$CurrentSMTP.Properties.MaxSessionSize'
            Type   = 'String'
        }
        @{
            Name   = 'RelayForAuth'
            Source = '$CurrentSMTP.Properties.RelayForAuth'
            Type   = 'String'
        }
        @{
            Name   = 'RemoteSmtpPort'
            Source = '$CurrentSMTP.Properties.RemoteSmtpPort'
            Type   = 'String'
        }
        @{
            Name   = 'RemoteTimeout'
            Source = '$CurrentSMTP.Properties.RemoteTimeout'
            Type   = 'String'
        }
        @{
            Name   = 'SaslLogonDomain'
            Source = '$CurrentSMTP.Properties.SaslLogonDomain'
            Type   = 'String'
        }
        @{
            Name   = 'SendNdrTo'
            Source = '$CurrentSMTP.Properties.SendNdrTo'
            Type   = 'String'
        }
        @{
            Name   = 'ServerBindings'
            Source = '$CurrentSMTP.Properties.ServerBindings'
            Type   = 'String'
        }
        @{
            Name   = 'SmartHost'
            Source = '$CurrentSMTP.Properties.SmartHost'
            Type   = 'String'
        }
        @{
            Name   = 'SmartHostType'
            Source = '$CurrentSMTP.Properties.SmartHostType'
            Type   = 'String'
        }
        @{
            Name   = 'SmtpInboundCommandSupportOptions'
            Source = '$CurrentSMTP.Properties.SmtpInboundCommandSupportOptions'
            Type   = 'String'
        }
        @{
            Name   = 'SmtpLocalDelayExpireMinutes'
            Source = '$CurrentSMTP.Properties.SmtpLocalDelayExpireMinutes'
            Type   = 'String'
        }
        @{
            Name   = 'SmtpLocalNDRExpireMinutes'
            Source = '$CurrentSMTP.Properties.SmtpLocalNDRExpireMinutes'
            Type   = 'String'
        }
        @{
            Name   = 'SmtpRemoteDelayExpireMinutes'
            Source = '$CurrentSMTP.Properties.SmtpRemoteDelayExpireMinutes'
            Type   = 'String'
        }
        @{
            Name   = 'SmtpRemoteNDRExpireMinutes'
            Source = '$CurrentSMTP.Properties.SmtpRemoteNDRExpireMinutes'
            Type   = 'String'
        }
        @{
            Name   = 'SmtpRemoteProgressiveRetry'
            Source = '$CurrentSMTP.Properties.SmtpRemoteProgressiveRetry'
            Type   = 'String'
        }
    )
}


function Get-TargetResource
{
    <#
    .SYNOPSIS
        This will return a hashtable of results
    #>

    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateSet('1')]
        [String] $Name
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
            AuthFlags                        = $CurrentSMTP.Properties.AuthFlags
            BadMailDirectory                 = $CurrentSMTP.Properties.BadMailDirectory
            ConnectionTimeout                = $CurrentSMTP.Properties.ConnectionTimeout
            EnableReverseDnsLookup           = $CurrentSMTP.Properties.EnableReverseDnsLookup
            FullyQualifiedDomainName         = $CurrentSMTP.Properties.FullyQualifiedDomainName
            HopCount                         = $CurrentSMTP.Properties.HopCount
            LogFileDirectory                 = $CurrentSMTP.Properties.LogFileDirectory
            LogFilePeriod                    = $CurrentSMTP.Properties.LogFilePeriod
            LogFileTruncateSize              = $CurrentSMTP.Properties.LogFileTruncateSize
            LogType                          = $CurrentSMTP.Properties.LogType
            MasqueradeDomain                 = $CurrentSMTP.Properties.MasqueradeDomain
            MaxBatchedMessages               = $CurrentSMTP.Properties.MaxBatchedMessages
            MaxConnections                   = $CurrentSMTP.Properties.MaxConnections
            MaxMessageSize                   = $CurrentSMTP.Properties.MaxMessageSize
            MaxOutConnections                = $CurrentSMTP.Properties.MaxOutConnections
            MaxOutConnectionsPerDomain       = $CurrentSMTP.Properties.MaxOutConnectionsPerDomain
            MaxRecipients                    = $CurrentSMTP.Properties.MaxRecipients
            MaxSessionSize                   = $CurrentSMTP.Properties.MaxSessionSize
            RelayForAuth                     = $CurrentSMTP.Properties.RelayForAuth
            RemoteSmtpPort                   = $CurrentSMTP.Properties.RemoteSmtpPort
            RemoteTimeout                    = $CurrentSMTP.Properties.RemoteTimeout
            SaslLogonDomain                  = $CurrentSMTP.Properties.SaslLogonDomain
            SendNdrTo                        = $CurrentSMTP.Properties.SendNdrTo
            ServerBindings                   = $CurrentSMTP.Properties.ServerBindings
            SmartHost                        = $CurrentSMTP.Properties.SmartHost
            SmartHostType                    = $CurrentSMTP.Properties.SmartHostType
            SmtpInboundCommandSupportOptions = $CurrentSMTP.Properties.SmtpInboundCommandSupportOptions
            SmtpLocalDelayExpireMinutes      = $CurrentSMTP.Properties.SmtpLocalDelayExpireMinutes
            SmtpLocalNDRExpireMinutes        = $CurrentSMTP.Properties.SmtpLocalNDRExpireMinutes
            SmtpRemoteDelayExpireMinutes     = $CurrentSMTP.Properties.SmtpRemoteDelayExpireMinutes
            SmtpRemoteNDRExpireMinutes       = $CurrentSMTP.Properties.SmtpRemoteNDRExpireMinutes
            SmtpRemoteProgressiveRetry       = $CurrentSMTP.Properties.SmtpRemoteProgressiveRetry
        }
    }
}

function Set-TargetResource
{
    <#
    .SYNOPSIS
        This will set the desired state
    #>

    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [String] $Name,

        [String] $AuthFlags,

        [String] $BadMailDirectory,

        [String] $ConnectionTimeout,

        [Boolean] $EnableReverseDnsLookup,

        [String] $FullyQualifiedDomainName,

        [String]  $HopCount,

        [String] $LogFileDirectory,

        [String] $LogFilePeriod,

        [String] $LogFileTruncateSize,

        [String] $LogType,

        [String] $MasqueradeDomain,

        [String] $MaxBatchedMessages,

        [String] $MaxConnections,

        [String] $MaxMessageSize,

        [String] $MaxOutConnections,

        [String] $MaxOutConnectionsPerDomain,

        [String] $MaxRecipients,

        [String] $MaxSessionSize,

        [String] $RelayForAuth,

        [String] $RemoteSmtpPort,

        [String] $RemoteTimeout,

        [String] $SaslLogonDomain,

        [String] $SendNdrTo,

        [String[]] $ServerBindings,

        [String] $SmartHost,

        [String] $SmartHostType,

        [String] $SmtpInboundCommandSupportOptions,

        [String] $SmtpLocalDelayExpireMinutes,

        [String] $SmtpLocalNDRExpireMinutes,

        [String] $SmtpRemoteDelayExpireMinutes,

        [String] $SmtpRemoteNDRExpireMinutes,

        [String] $SmtpRemoteProgressiveRetry
    )

    Assert-Module
    
    $Result = Get-TargetResource -Name $Name

    # Update Parameters
    foreach ($parameter in $ParameterList.Name)
    {
        if ($PSBoundParameters.ContainsKey($parameter) -and `
            $Result.$parameter -ne $PSBoundParameter.$parameter)
        {
            switch($parameter)
            {
                BadMailDirectory
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
                                     -Setting 'BadMailDirectory' `
                                     -Value $BadMailDirectory
                }

                LogFileDirectory
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
                                        -Setting 'LogFileDirectory' `
                                        -Value $LogFileDirectory
                }

                SendNdrTo
                {
                    if(Test-EmailAddress -Email $SendNdrTo)
                    {
                        Write-Verbose -Message ($LocalizedData.VerboseSetTargetSendNdrTo)
                        Set-SMTPSettings -Name $Name `
                                         -Setting 'SendNdrTo' `
                                         -Value $SendNdrTo
                    }
                }

                ServerBindings
                {
                    if (Test-SMTPBindings -ServerBindings $ServerBindings)
                    {
                        if (-not(Confirm-UnqiueBindings `
                                -ExistingBindings $Result.ServerBindings `
                                -ProposedBindings $ServerBindings ))
                        {
                            Write-Verbose -Message ($LocalizedData.VerboseSetTargetServerBindings)
                            # Make input bindings which are an array, into a string
                            $StringafiedBindings = $ServerBindings -join ' '
                            Set-SMTPSettings -Name $Name `
                                             -Setting 'ServerBindings' `
                                             -Value $StringafiedBindings
                        }
                    }
                }

                Default
                {
                    Write-Verbose -Message ($LocalizedData.VerboseSetTargetResourceUpdated `
                            -f $parameter)
                    Set-SMTPSettings -Name $Name `
                                     -Setting $parameter `
                                     -Value $PSBoundParameters.$parameter
                }
            }
        }
    }
}

function Test-TargetResource
{
    <#
    .SYNOPSIS
        This test the desired state. If the state is not correct it will return $false.
        If the state is correct it will return $true
    #>

    [CmdletBinding()]
    [OutputType([Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [String] $Name,

        [String] $AuthFlags,

        [String] $BadMailDirectory,

        [String] $ConnectionTimeout,

        [Boolean] $EnableReverseDnsLookup,

        [String] $FullyQualifiedDomainName,

        [String]  $HopCount,

        [String] $LogFileDirectory,

        [String] $LogFilePeriod,

        [String] $LogFileTruncateSize,

        [String] $LogType,

        [String] $MasqueradeDomain,

        [String] $MaxBatchedMessages,

        [String] $MaxConnections,

        [String] $MaxMessageSize,

        [String] $MaxOutConnections,

        [String] $MaxOutConnectionsPerDomain,

        [String] $MaxRecipients,

        [String] $MaxSessionSize,

        [String] $RelayForAuth,

        [String] $RemoteSmtpPort,

        [String] $RemoteTimeout,

        [String] $SaslLogonDomain,

        [String] $SendNdrTo,

        [String[]] $ServerBindings,

        [String] $SmartHost,

        [String] $SmartHostType,

        [String] $SmtpInboundCommandSupportOptions,

        [String] $SmtpLocalDelayExpireMinutes,

        [String] $SmtpLocalNDRExpireMinutes,

        [String] $SmtpRemoteDelayExpireMinutes,

        [String] $SmtpRemoteNDRExpireMinutes,

        [String] $SmtpRemoteProgressiveRetry
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

    foreach ($parameter in $ParameterList.Name)
    {
        if ($PSBoundParameters.ContainsKey($parameter) -and `
            $Result.$parameter -ne $PSBoundParameter.$parameter)
        {
            switch($parameter)
            {
                BadMailDirectory
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

                LogFileDirectory
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

                SendNdrTo
                {
                    if(Test-EmailAddress -Email $SendNdrTo)
                    {
                        Write-Verbose -Message ($LocalizedData.VerboseTestTargetFalseSendNdrTo)
                        return $False
                    }
                }

                ServerBindings
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

                Default
                {
                    Write-Verbose -Message ($LocalizedData.VerboseTestTargetResource `
                                    -f $parameter)
                    return $False
                }
            }
        }
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
        [String] $ExistingBindings,
        
        [Parameter(Mandatory = $true)]
        [String[]]  $ProposedBindings
    )

    $InputToCheck = @()
    foreach($ProposedBinding in $ProposedBindings)
    { 
        $BindingAddition = $ProposedBinding + ':'
        $InputToCheck += $BindingAddition
    }

    $ExistingBindingsToCheck = $ExistingBindings -split '\n'

    $ExistingToCheck = @()
    foreach($ExistingBinding in $ExistingBindingsToCheck)
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
        [String] $ID
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
    .PARAMETER Setting
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
        [String] $Name,
        
        [Parameter(Mandatory = $true)]
        [String] $Setting,
        
        [Parameter(Mandatory = $true)]
        [String] $Value
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
    param
    (
        [OutputType([Boolean])]
        [Parameter(Mandatory = $true)]
        [String] $Email
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
    [OutputType([Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [String[]] $ServerBindings
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
    }
    
    return $true
}

#endregion

Export-ModuleMember -Function *-TargetResource
