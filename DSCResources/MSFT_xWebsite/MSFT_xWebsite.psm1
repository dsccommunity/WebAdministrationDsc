#requires -Version 4.0 -Modules CimCmdlets

# Load the Helper Module
Import-Module -Name "$PSScriptRoot\..\Helper.psm1" -Verbose:$false

# Localized messages
data LocalizedData
{
    # culture="en-US"
    ConvertFrom-StringData -StringData @'
ErrorWebsiteNotFound = The requested website "{0}" cannot be found on the target machine.
ErrorWebsiteDiscoveryFailure = Failure to get the requested website "{0}" information from the target machine.
ErrorWebsiteCreationFailure = Failure to successfully create the website "{0}". Error: "{1}".
ErrorWebsiteRemovalFailure = Failure to successfully remove the website "{0}". Error: "{1}".
ErrorWebsiteBindingUpdateFailure = Failure to successfully update the bindings for website "{0}". Error: "{1}".
ErrorWebsiteBindingInputInvalidation = Desired website bindings are not valid for website "{0}".
ErrorWebsiteCompareFailure = Failure to successfully compare properties for website "{0}". Error: "{1}".
ErrorWebBindingCertificate = Failure to add certificate to web binding. Please make sure that the certificate thumbprint "{0}" is valid. Error: "{1}".
ErrorWebsiteStateFailure = Failure to successfully set the state of the website "{0}". Error: "{1}".
ErrorWebsiteBindingConflictOnStart = Website "{0}" could not be started due to binding conflict. Ensure that the binding information for this website does not conflict with any existing website's bindings before trying to start it.
ErrorWebBindingInvalidIPAddress = Failure to validate the IPAddress property value "{0}". Error: "{1}".
ErrorWebBindingInvalidPort = Failure to validate the Port property value "{0}". The port number must be a positive integer between 1 and 65535.
ErrorWebBindingMissingBindingInformation = The BindingInformation property is required for bindings of type "{0}".
ErrorWebBindingMissingCertificateThumbprint = The CertificateThumbprint property is required for bindings of type "{0}".
ErrorWebBindingMissingSniHostName = The HostName property is required for use with Server Name Indication.
ErrorWebsitePreloadFailure = Failure to set Preload on Website "{0}". Error: "{1}".
ErrorWebsiteAutoStartFailure = Failure to set AutoStart on Website "{0}". Error: "{1}".
ErrorWebsiteAutoStartProviderFailure = Failure to set AutoStartProvider on Website "{0}". Error: "{1}".
ErrorWebsiteTestAutoStartProviderFailure = Desired AutoStartProvider is not valid due to a conflicting Global Property. Ensure that the serviceAutoStartProvider is a unique key."
VerboseSetTargetUpdatedPhysicalPath = Physical Path for website "{0}" has been updated to "{1}".
VerboseGetTargetAbsent = No Website exists with this name.
VerboseGetTargetPresent = A single Website exists with this name
VerboseSetTargetUpdatedApplicationPool = Application Pool for website "{0}" has been updated to "{1}".
VerboseSetTargetUpdatedBindingInfo = Bindings for website "{0}" have been updated.
VerboseSetTargetUpdatedEnabledProtocols = Enabled Protocols for website "{0}" have been updated to "{1}".
VerboseSetTargetUpdatedState = State for website "{0}" has been updated to "{1}".
VerboseSetTargetWebsiteCreated = Successfully created website "{0}".
VerboseSetTargetWebsiteStarted = Successfully started website "{0}".
VerboseSetTargetWebsiteRemoved = Successfully removed website "{0}".
VerboseSetTargetAuthenticationInfoUpdated = Successfully updated AuthenticationInfo on website "{0}".
VerboseSetTargetWebsitePreloadUpdated = Successfully updated Preload on website "{0}".
VerboseSetTargetWebsiteAutoStartUpdated = Successfully updated AutoStart on website "{0}".
VerboseSetTargetWebsiteAutoStartProviderUpdated = Successfully updated AutoStartProvider on website "{0}".
VerboseSetTargetIISAutoStartProviderUpdated = Successfully updated AutoStartProvider in IIS.
VerboseSetTargetUpdateLogPath = LogPath does not match and will be updated on Website "{0}".
VerboseSetTargetUpdateLogFlags = LogFlags do not match and will be updated on Website "{0}".
VerboseSetTargetUpdateLogPeriod = LogPeriod does not match and will be updated on Website "{0}".
VerboseSetTargetUpdateLogTruncateSize = TruncateSize does not match and will be updated on Website "{0}".
VerboseSetTargetUpdateLoglocalTimeRollover = LoglocalTimeRollover does not match and will be updated on Website "{0}".
VerboseSetTargetUpdateLogFormat = LogFormat is not in the desired state and will be updated on Website "{0}"
VerboseTestTargetFalseEnsure = The Ensure state for website "{0}" does not match the desired state.
VerboseTestTargetFalsePhysicalPath = Physical Path of website "{0}" does not match the desired state.
VerboseTestTargetFalseState = The state of website "{0}" does not match the desired state.
VerboseTestTargetFalseApplicationPool = Application Pool for website "{0}" does not match the desired state.
VerboseTestTargetFalseBindingInfo = Bindings for website "{0}" do not match the desired state.
VerboseTestTargetFalseEnabledProtocols = Enabled Protocols for website "{0}" do not match the desired state.
VerboseTestTargetFalseDefaultPage = Default Page for website "{0}" does not match the desired state.
VerboseTestTargetTrueResult = The target resource is already in the desired state. No action is required.
VerboseTestTargetFalseResult = The target resource is not in the desired state.
VerboseTestTargetFalsePreload = Preload for website "{0}" do not match the desired state.
VerboseTestTargetFalseAutoStart = AutoStart for website "{0}" do not match the desired state.
VerboseTestTargetFalseAuthenticationInfo = AuthenticationInfo for website "{0}" is not in the desired state.
VerboseTestTargetFalseIISAutoStartProvider = AutoStartProvider for IIS is not in the desired state
VerboseTestTargetFalseWebsiteAutoStartProvider = AutoStartProvider for website "{0}" is not in the desired state
VerboseTestTargetFalseLogPath = LogPath does match desired state on Website "{0}".
VerboseTestTargetFalseLogFlags = LogFlags does not match desired state on Website "{0}".
VerboseTestTargetFalseLogPeriod = LogPeriod does not match desired state on Website "{0}".
VerboseTestTargetFalseLogTruncateSize = LogTruncateSize does not match desired state on Website "{0}".
VerboseTestTargetFalseLoglocalTimeRollover = LoglocalTimeRollover does not match desired state on Website "{0}".
VerboseTestTargetFalseLogFormat = LogFormat does not match desired state on Website "{0}".
VerboseConvertToWebBindingIgnoreBindingInformation = BindingInformation is ignored for bindings of type "{0}" in case at least one of the following properties is specified: IPAddress, Port, HostName.
VerboseConvertToWebBindingDefaultPort = Port is not specified. The default "{0}" port "{1}" will be used.
VerboseConvertToWebBindingDefaultCertificateStoreName = CertificateStoreName is not specified. The default value "{0}" will be used.
VerboseTestBindingInfoSameIPAddressPortHostName = BindingInfo contains multiple items with the same IPAddress, Port, and HostName combination.
VerboseTestBindingInfoSamePortDifferentProtocol = BindingInfo contains items that share the same Port but have different Protocols.
VerboseTestBindingInfoSameProtocolBindingInformation = BindingInfo contains multiple items with the same Protocol and BindingInformation combination.
VerboseTestBindingInfoInvalidCatch = Unable to validate BindingInfo: "{0}".
VerboseUpdateDefaultPageUpdated = Default page for website "{0}" has been updated to "{1}".
WarningLogPeriod = LogTruncateSize has is an input as will overwrite this desired state on Website "{0}".
WarningIncorrectLogFormat = LogFormat is not W3C, as a result LogFlags will not be used on Website "{0}".
'@
}

<#
.SYNOPSYS
    The Get-TargetResource cmdlet is used to fetch the status of role or Website on the target 
    machine. It gives the Website info of the requested role/feature on the target machine.
#>
function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $Name
    )

    Assert-Module

    $Website = Get-Website | Where-Object -FilterScript {$_.Name -eq $Name}
    
    if ($Website.Count -eq 0)
    {
        Write-Verbose -Message ($LocalizedData.VerboseGetTargetAbsent)
        $EnsureResult = 'Absent'
    }
    elseif ($Website.Count -eq 1)
    {
        Write-Verbose -Message ($LocalizedData.VerboseGetTargetPresent)
        $EnsureResult = 'Present'

        $CimBindings = @(ConvertTo-CimBinding -InputObject $Website.bindings.Collection)

        $AllDefaultPages = @(
            Get-WebConfiguration -Filter '//defaultDocument/files/*' -PSPath "IIS:\Sites\$Name" |
            ForEach-Object -Process {Write-Output -InputObject $_.value}
        )
        $CimAuthentication = Get-AuthenticationInfo -Site $Name -IisType 'Website'
        $WebSiteAutoStartProviders = (Get-WebConfiguration `
            -filter /system.applicationHost/serviceAutoStartProviders).Collection
        $WebConfiguration = $WebSiteAutoStartProviders | `
                                Where-Object -Property Name -eq -Value $ServiceAutoStartProvider | ` 
                                Select-Object Name,Type
    }
    else # Multiple websites with the same name exist. This is not supported and is an error
    {
        $ErrorMessage = $LocalizedData.ErrorWebsiteDiscoveryFailure -f $Name
        New-TerminatingError -ErrorId 'WebsiteDiscoveryFailure' `
                             -ErrorMessage $ErrorMessage `
                             -ErrorCategory 'InvalidResult'
    }

    # Add all website properties to the hash table
    return @{
        Ensure                   = $EnsureResult
        Name                     = $Name
        PhysicalPath             = $Website.PhysicalPath
        State                    = $Website.State
        ApplicationPool          = $Website.ApplicationPool
        BindingInfo              = $CimBindings
        DefaultPage              = $AllDefaultPages
        EnabledProtocols         = $Website.EnabledProtocols
        AuthenticationInfo       = $CimAuthentication
        PreloadEnabled           = $Website.applicationDefaults.preloadEnabled
        ServiceAutoStartProvider = $Website.applicationDefaults.serviceAutoStartProvider
        ServiceAutoStartEnabled  = $Website.applicationDefaults.serviceAutoStartEnabled
        ApplicationType          = $WebConfiguration.Type
        LogPath                  = $Website.logfile.directory
        LogFlags                 = [Array]$Website.logfile.LogExtFileFlags
        LogPeriod                = $Website.logfile.period
        LogtruncateSize          = $Website.logfile.truncateSize
        LoglocalTimeRollover     = $Website.logfile.localTimeRollover
        LogFormat                = $Website.logfile.logFormat
    }
}

<#
.SYNOPSIS
    The Set-TargetResource cmdlet is used to create, delete or configure a website on the
    target machine.
#>
function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [ValidateSet('Present', 'Absent')]
        [String]
        $Ensure = 'Present',

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $Name,

        [ValidateNotNullOrEmpty()]
        [String]
        $PhysicalPath,

        [ValidateSet('Started', 'Stopped')]
        [String]
        $State = 'Started',

        [ValidateLength(1, 64)] # The application pool name must contain between 1 and 64 characters
        [String]
        $ApplicationPool,

        [Microsoft.Management.Infrastructure.CimInstance[]]
        $BindingInfo,

        [String[]]
        $DefaultPage,

        [String]
        $EnabledProtocols,

        [Microsoft.Management.Infrastructure.CimInstance]
        $AuthenticationInfo,

        [Boolean]
        $PreloadEnabled,

        [Boolean]
        $ServiceAutoStartEnabled,

        [String]
        $ServiceAutoStartProvider,

        [String]
        $ApplicationType,

        [String]
        $LogPath,

        [ValidateSet('Date','Time','ClientIP','UserName','SiteName','ComputerName','ServerIP','Method','UriStem','UriQuery','HttpStatus','Win32Status','BytesSent','BytesRecv','TimeTaken','ServerPort','UserAgent','Cookie','Referer','ProtocolVersion','Host','HttpSubStatus')]
        [String[]]
        $LogFlags,

        [ValidateSet('Hourly','Daily','Weekly','Monthly','MaxSize')]
        [String]
        $LogPeriod,

        [ValidateRange('1048576','4294967295')]
        [String]
        $LogTruncateSize,

        [Boolean]
        $LoglocalTimeRollover,

        [ValidateSet('IIS','W3C','NCSA')]
        [String]
        $LogFormat
    )

    Assert-Module

    $Website = Get-Website | Where-Object -FilterScript {$_.Name -eq $Name}

    if ($Ensure -eq 'Present')
    {
        if ($null -ne $Website)
        {
            # Update Physical Path if required
            if ([string]::IsNullOrEmpty($PhysicalPath) -eq $false -and `
                $Website.PhysicalPath -ne $PhysicalPath)
            {
                Set-ItemProperty -Path "IIS:\Sites\$Name" `
                                 -Name physicalPath `
                                 -Value $PhysicalPath `
                                 -ErrorAction Stop
                Write-Verbose -Message ($LocalizedData.VerboseSetTargetUpdatedPhysicalPath `
                                        -f $Name, $PhysicalPath)
            }

            # Update Application Pool if required
            if ($PSBoundParameters.ContainsKey('ApplicationPool') -and `
                $Website.ApplicationPool -ne $ApplicationPool)
            {
                Set-ItemProperty -Path "IIS:\Sites\$Name" `
                                 -Name applicationPool `
                                 -Value $ApplicationPool `
                                 -ErrorAction Stop
                Write-Verbose -Message ($LocalizedData.VerboseSetTargetUpdatedApplicationPool `
                                        -f $Name, $ApplicationPool)
            }

            # Update Bindings if required
            if ($PSBoundParameters.ContainsKey('BindingInfo') -and `
                $null -ne $BindingInfo)
            {
                if (-not (Test-WebsiteBinding -Name $Name `
                                              -BindingInfo $BindingInfo))
                {
                    Update-WebsiteBinding -Name $Name `
                                          -BindingInfo $BindingInfo
                    Write-Verbose -Message ($LocalizedData.VerboseSetTargetUpdatedBindingInfo `
                                            -f $Name)
                }
            }

            # Update Enabled Protocols if required
            if ($PSBoundParameters.ContainsKey('EnabledProtocols') -and `
                $Website.EnabledProtocols -ne $EnabledProtocols)
            {
                Set-ItemProperty -Path "IIS:\Sites\$Name" `
                                 -Name enabledProtocols `
                                 -Value $EnabledProtocols `
                                 -ErrorAction Stop
                Write-Verbose -Message ($LocalizedData.VerboseSetTargetUpdatedEnabledProtocols `
                                        -f $Name, $EnabledProtocols)
            }

            # Update Default Pages if required
            if ($PSBoundParameters.ContainsKey('DefaultPage') -and `
                $null -ne $DefaultPage)
            {
                Update-DefaultPage -Name $Name `
                                   -DefaultPage $DefaultPage
            }

            # Update State if required
            if ($PSBoundParameters.ContainsKey('State') -and `
                $Website.State -ne $State)
            {
                if ($State -eq 'Started')
                {
                    # Ensure that there are no other running websites with binding information that 
                    # will conflict with this website before starting
                    if (-not (Confirm-UniqueBinding -Name $Name `
                                                    -ExcludeStopped))
                    {
                        # Return error and do not start the website
                        $ErrorMessage = $LocalizedData.ErrorWebsiteBindingConflictOnStart `
                                        -f $Name
                        New-TerminatingError -ErrorId 'WebsiteBindingConflictOnStart' `
                                             -ErrorMessage $ErrorMessage `
                                             -ErrorCategory 'InvalidResult'
                    }

                    try
                    {
                        Start-Website -Name $Name -ErrorAction Stop
                    }
                    catch
                    {
                        $ErrorMessage = $LocalizedData.ErrorWebsiteStateFailure `
                                        -f $Name, $_.Exception.Message
                        New-TerminatingError -ErrorId 'WebsiteStateFailure' `
                                             -ErrorMessage $ErrorMessage `
                                             -ErrorCategory 'InvalidOperation'
                    }
                }
                else
                {
                    try
                    {
                        Stop-Website -Name $Name -ErrorAction Stop
                    }
                    catch
                    {
                        $ErrorMessage = $LocalizedData.ErrorWebsiteStateFailure `
                                        -f $Name, $_.Exception.Message
                        New-TerminatingError -ErrorId 'WebsiteStateFailure' `
                                             -ErrorMessage $ErrorMessage `
                                             -ErrorCategory 'InvalidOperation'
                    }
                }

                Write-Verbose -Message ($LocalizedData.VerboseSetTargetUpdatedState `
                                        -f $Name, $State)
            }

            # Set Authentication; if not defined then pass in DefaultAuthenticationInfo
            if ($PSBoundParameters.ContainsKey('AuthenticationInfo') -and `
                (-not (Test-AuthenticationInfo -Site $Name `
                                               -IisType 'Website' `
                                               -AuthenticationInfo $AuthenticationInfo)))
            {
                Write-Verbose -Message ($LocalizedData.VerboseSetTargetAuthenticationInfo -f $Name)
                Set-AuthenticationInfo -Site $Name `
                                       -IisType 'Website' `
                                       -AuthenticationInfo $AuthenticationInfo `
                                       -ErrorAction Stop `
            }

            $DefaultAuthenticationInfo = Get-DefaultAuthenticationInfo -IisType 'Application'
            if($null -eq $PSBoundParameters.ContainsKey('AuthenticationInfo') -and `
                (-not (Test-AuthenticationInfo `
                        -Site $Name `
                        -IisType 'Website' `
                        -AuthenticationInfo $DefaultAuthenticationInfo)))
            {
                $AuthenticationInfo = Get-DefaultAuthenticationInfo -IisType 'Application'
                Write-Verbose -Message ($LocalizedData.VerboseSetTargetAuthenticationInfo `
                                        -f $Name)
                Set-AuthenticationInfo -Site $Name `
                                       -IisType 'Website' `
                                       -AuthenticationInfo $DefaultAuthenticationInfo `
                                       -ErrorAction Stop `
            }
           
            # Update Preload if required
            if ($PSBoundParameters.ContainsKey('preloadEnabled') -and `
                ($Website.applicationDefaults.preloadEnabled -ne $PreloadEnabled))
            {
               Set-ItemProperty -Path "IIS:\Sites\$Name" `
                                -Name applicationDefaults.preloadEnabled `
                                -Value $PreloadEnabled `
                                -ErrorAction Stop
               Write-Verbose -Message ($LocalizedData.VerboseSetTargetWebsitePreloadUpdated `
                                       -f $Name)
            }
            
            # Update AutoStart if required
            if ($PSBoundParameters.ContainsKey('ServiceAutoStartEnabled') -and `
                ($Website.applicationDefaults.ServiceAutoStartEnabled -ne $ServiceAutoStartEnabled))
            {
                Set-ItemProperty -Path "IIS:\Sites\$Name" `
                                 -Name applicationDefaults.serviceAutoStartEnabled `
                                 -Value $ServiceAutoStartEnabled `
                                 -ErrorAction Stop
                Write-Verbose -Message ($LocalizedData.VerboseSetTargetWebsiteAutoStartUpdated `
                                        -f $Name)
            }
            
            # Update AutoStartProviders if required
            if ($PSBoundParameters.ContainsKey('ServiceAutoStartProvider') -and `
               ($Website.applicationDefaults.ServiceAutoStartProvider -ne `
                $ServiceAutoStartProvider))
            {
                if (-not (Confirm-UniqueServiceAutoStartProviders `
                            -ServiceAutoStartProvider $ServiceAutoStartProvider `
                            -ApplicationType $ApplicationType))
                {
                    Add-WebConfiguration -filter /system.applicationHost/serviceAutoStartProviders `
                                         -Value @{
                                            name=$ServiceAutoStartProvider
                                            type=$ApplicationType} `
                                         -ErrorAction Stop
                    Write-Verbose -Message `
                                    ($LocalizedData.VerboseSetTargetIISAutoStartProviderUpdated)
                }
                Set-ItemProperty -Path "IIS:\Sites\$Name" `
                                 -Name applicationDefaults.serviceAutoStartProvider `
                                 -Value $ServiceAutoStartProvider -ErrorAction Stop
                Write-Verbose -Message `
                                ($LocalizedData.VerboseSetTargetWebsiteAutoStartProviderUpdated `
                                -f $Name)
            }

            # Update LogFlags if required
            if ($PSBoundParameters.ContainsKey('LogFlags') -and `
                (-not (Compare-LogFlags -Name $Name -LogFlags $LogFlags)))
            {
                Write-Verbose -Message ($LocalizedData.VerboseSetTargetUpdateLogFlags `
                                        -f $Name)
                Set-ItemProperty -Path "IIS:\Sites\$Name" `
                                 -Name logFile.logFormat `
                                 -Value 'W3C'
                Set-ItemProperty -Path "IIS:\Sites\$Name" `
                                 -Name logFile.logExtFileFlags `
                                 -Value ($LogFlags -join ',')
            }

            # Update LogPath if required
            if ($PSBoundParameters.ContainsKey('LogPath') -and `
                ($LogPath -ne $Website.logfile.LogPath))
            {

                Write-Verbose -Message ($LocalizedData.VerboseSetTargetUpdateLogPath `
                                        -f $Name)
                Set-ItemProperty -Path "IIS:\Sites\$Name" `
                                 -Name logFile.directory `
                                 -Value $LogPath
            }

            # Update LogPeriod if needed
            if ($PSBoundParameters.ContainsKey('LogPeriod') -and `
                ($LogPeriod -ne $Website.logfile.LogPeriod))
            {
                if ($PSBoundParameters.ContainsKey('LogTruncateSize'))
                    {
                        Write-Verbose -Message ($LocalizedData.WarningLogPeriod `
                                                -f $Name)
                    }

                Write-Verbose -Message ($LocalizedData.VerboseSetTargetUpdateLogPeriod)
                Set-ItemProperty -Path "IIS:\Sites\$Name" `
                                 -Name logFile.period `
                                 -Value $LogPeriod
            }

            # Update LogTruncateSize if needed
            if ($PSBoundParameters.ContainsKey('LogTruncateSize') -and `
                ($LogTruncateSize -ne $Website.logfile.LogTruncateSize))
            {
                Write-Verbose -Message ($LocalizedData.VerboseSetTargetUpdateLogTruncateSize `
                                        -f $Name)
                Set-ItemProperty -Path "IIS:\Sites\$Name" `
                                 -Name logFile.truncateSize `
                                 -Value $LogTruncateSize
                Set-ItemProperty -Path "IIS:\Sites\$Name" `
                                 -Name logFile.period `
                                 -Value 'MaxSize'
            }

            # Update LoglocalTimeRollover if neeed
            if ($PSBoundParameters.ContainsKey('LoglocalTimeRollover') -and `
                ($LoglocalTimeRollover -ne `
                 ([System.Convert]::ToBoolean($Website.logfile.LoglocalTimeRollover))))
            {
                Write-Verbose -Message ($LocalizedData.VerboseSetTargetUpdateLoglocalTimeRollover `
                                        -f $Name)
                Set-ItemProperty -Path "IIS:\Sites\$Name" `
                                 -Name logFile.localTimeRollover `
                                 -Value $LoglocalTimeRollover
            }

        }
        else # Create website if it does not exist
        {
            if ([string]::IsNullOrEmpty($PhysicalPath)) {
                throw 'The PhysicalPath Parameter must be provided for a website to be created'
            }

            try
            {
                $PSBoundParameters.GetEnumerator() |
                Where-Object -FilterScript {
                    $_.Key -in (Get-Command -Name New-Website `
                                            -Module WebAdministration).Parameters.Keys
                } |
                ForEach-Object -Begin {
                    $NewWebsiteSplat = @{}
                } -Process {
                    $NewWebsiteSplat.Add($_.Key, $_.Value)
                }

                # If there are no other websites, specify the Id Parameter for the new website.
                # Otherwise an error can occur on systems running Windows Server 2008 R2.
                if (-not (Get-Website))
                {
                    $NewWebsiteSplat.Add('Id', 1)
                }

                $Website = New-Website @NewWebsiteSplat -ErrorAction Stop
                Write-Verbose -Message ($LocalizedData.VerboseSetTargetWebsiteCreated `
                                        -f $Name)
            }
            catch
            {
                $ErrorMessage = $LocalizedData.ErrorWebsiteCreationFailure `
                                -f $Name, $_.Exception.Message
                New-TerminatingError -ErrorId 'WebsiteCreationFailure' `
                                     -ErrorMessage $ErrorMessage `
                                     -ErrorCategory 'InvalidOperation'
            }

            Stop-Website -Name $Website.Name -ErrorAction Stop

            # Clear default bindings if new bindings defined and are different
            if ($PSBoundParameters.ContainsKey('BindingInfo') -and `
                $null -ne $BindingInfo)
            {
                if (-not (Test-WebsiteBinding -Name $Name `
                                              -BindingInfo $BindingInfo))
                {
                    Update-WebsiteBinding -Name $Name -BindingInfo $BindingInfo
                    Write-Verbose -Message ($LocalizedData.VerboseSetTargetUpdatedBindingInfo `
                                            -f $Name)
                }
            }

            # Update Enabled Protocols if required
            if ($PSBoundParameters.ContainsKey('EnabledProtocols') `
                -and $Website.EnabledProtocols `
                -ne $EnabledProtocols)
            {
                Set-ItemProperty -Path "IIS:\Sites\$Name" `
                                 -Name enabledProtocols `
                                 -Value $EnabledProtocols `
                                 -ErrorAction Stop
                Write-Verbose -Message ($LocalizedData.VerboseSetTargetUpdatedEnabledProtocols `
                                        -f $Name, $EnabledProtocols)
            }

            # Update Default Pages if required
            if ($PSBoundParameters.ContainsKey('DefaultPage') -and `
                $null -ne $DefaultPage)
            {
                Update-DefaultPage -Name $Name `
                                   -DefaultPage $DefaultPage
            }

            # Start website if required
            if ($State -eq 'Started')
            {
                # Ensure that there are no other running websites with binding information that
                # will conflict with this website before starting
                if (-not (Confirm-UniqueBinding -Name $Name -ExcludeStopped))
                {
                    # Return error and do not start the website
                    $ErrorMessage = $LocalizedData.ErrorWebsiteBindingConflictOnStart `
                                    -f $Name
                    New-TerminatingError -ErrorId 'WebsiteBindingConflictOnStart' `
                                         -ErrorMessage $ErrorMessage `
                                         -ErrorCategory 'InvalidResult'
                }

                try
                {
                    Start-Website -Name $Name -ErrorAction Stop
                    Write-Verbose -Message ($LocalizedData.VerboseSetTargetWebsiteStarted `
                                            -f $Name)
                }
                catch
                {
                    $ErrorMessage = $LocalizedData.ErrorWebsiteStateFailure `
                                    -f $Name, $_.Exception.Message
                    New-TerminatingError -ErrorId 'WebsiteStateFailure' `
                                         -ErrorMessage $ErrorMessage `
                                         -ErrorCategory 'InvalidOperation'
                }
            }

            # Set Authentication; if not defined then pass in DefaultAuthenticationInfo
            if ($PSBoundParameters.ContainsKey('AuthenticationInfo') -and `
                (-not (Test-AuthenticationInfo -Site $Name `
                                               -IisType 'Website' `
                                               -AuthenticationInfo $AuthenticationInfo)))
            {
                Write-Verbose -Message ($LocalizedData.VerboseSetTargetAuthenticationInfo -f $Name)
                Set-AuthenticationInfo -Site $Name `
                                       -IisType 'Website' `
                                       -AuthenticationInfo $AuthenticationInfo `
                                       -ErrorAction Stop `
            }

            $DefaultAuthenticationInfo = Get-DefaultAuthenticationInfo -IisType 'Application'
            if($null -eq $PSBoundParameters.ContainsKey('AuthenticationInfo') -and `
                (-not (Test-AuthenticationInfo `
                        -Site $Name `
                        -IisType 'Website' `
                        -AuthenticationInfo $DefaultAuthenticationInfo)))
            {
                $AuthenticationInfo = Get-DefaultAuthenticationInfo -IisType 'Application'
                Write-Verbose -Message ($LocalizedData.VerboseSetTargetAuthenticationInfo `
                                        -f $Name)
                Set-AuthenticationInfo -Site $Name `
                                       -IisType 'Website' `
                                       -AuthenticationInfo $DefaultAuthenticationInfo `
                                       -ErrorAction Stop `
            }
           
            # Update Preload if required
            if ($PSBoundParameters.ContainsKey('preloadEnabled') -and `
                ($Website.applicationDefaults.preloadEnabled -ne $PreloadEnabled))
            {
               Set-ItemProperty -Path "IIS:\Sites\$Name" `
                                -Name applicationDefaults.preloadEnabled `
                                -Value $PreloadEnabled `
                                -ErrorAction Stop
               Write-Verbose -Message ($LocalizedData.VerboseSetTargetWebsitePreloadUpdated `
                                       -f $Name)
            }
            
            # Update AutoStart if required
            if ($PSBoundParameters.ContainsKey('ServiceAutoStartEnabled') -and `
                ($Website.applicationDefaults.ServiceAutoStartEnabled -ne $ServiceAutoStartEnabled))
            {
                Set-ItemProperty -Path "IIS:\Sites\$Name" `
                                 -Name applicationDefaults.serviceAutoStartEnabled `
                                 -Value $ServiceAutoStartEnabled `
                                 -ErrorAction Stop
                Write-Verbose -Message ($LocalizedData.VerboseSetTargetWebsiteAutoStartUpdated `
                                        -f $Name)
            }
            
            # Update AutoStartProviders if required
            if ($PSBoundParameters.ContainsKey('ServiceAutoStartProvider') -and `
                ($Website.applicationDefaults.ServiceAutoStartProvider `
                -ne $ServiceAutoStartProvider))
            {
                if (-not (Confirm-UniqueServiceAutoStartProviders `
                            -ServiceAutoStartProvider $ServiceAutoStartProvider `
                            -ApplicationType $ApplicationType))
                {
                    Add-WebConfiguration -filter /system.applicationHost/serviceAutoStartProviders `
                                         -Value @{
                                            name=$ServiceAutoStartProvider; 
                                            type=$ApplicationType
                                          } `
                                         -ErrorAction Stop
                    Write-Verbose -Message `
                                    ($LocalizedData.VerboseSetTargetIISAutoStartProviderUpdated)
                }
                Set-ItemProperty -Path "IIS:\Sites\$Name" `
                                 -Name applicationDefaults.serviceAutoStartProvider `
                                 -Value $ServiceAutoStartProvider -ErrorAction Stop
                Write-Verbose -Message `
                                ($LocalizedData.VerboseSetTargetWebsiteAutoStartProviderUpdated `
                                -f $Name)
            }

            # Update LogFormat if Needed
            if ($PSBoundParameters.ContainsKey('LogFormat') -and `
                ($LogFormat -ne $Website.logfile.LogFormat))
            {
                Write-Verbose -Message ($LocalizedData.VerboseSetTargetUpdateLogFormat -f $Name)
                Set-WebConfigurationProperty '/system.applicationHost/sites/siteDefaults/logfile' `
                    -Name logFormat `
                    -Value $LogFormat
            }

            # Update LogFlags if required
            if ($PSBoundParameters.ContainsKey('LogFlags') -and `
                (-not (Compare-LogFlags -Name $Name -LogFlags $LogFlags)))
            {
                Write-Verbose -Message ($LocalizedData.VerboseSetTargetUpdateLogFlags `
                                        -f $Name)
                Set-ItemProperty -Path "IIS:\Sites\$Name" `
                                 -Name logFile.logFormat `
                                 -Value 'W3C'
                Set-ItemProperty -Path "IIS:\Sites\$Name" `
                                 -Name logFile.logExtFileFlags `
                                 -Value ($LogFlags -join ',')
            }

            # Update LogPath if required
            if ($PSBoundParameters.ContainsKey('LogPath') -and `
                ($LogPath -ne $Website.logfile.LogPath))
            {

                Write-Verbose -Message ($LocalizedData.VerboseSetTargetUpdateLogPath `
                                        -f $Name)
                Set-ItemProperty -Path "IIS:\Sites\$Name" `
                                 -Name logFile.directory `
                                 -Value $LogPath
            }

            # Update LogPeriod if needed
            if ($PSBoundParameters.ContainsKey('LogPeriod') -and `
                ($LogPeriod -ne $Website.logfile.LogPeriod))
            {
                if ($PSBoundParameters.ContainsKey('LogTruncateSize'))
                    {
                        Write-Verbose -Message ($LocalizedData.WarningLogPeriod `
                                                -f $Name)
                    }

                Write-Verbose -Message ($LocalizedData.VerboseSetTargetUpdateLogPeriod)
                Set-ItemProperty -Path "IIS:\Sites\$Name" `
                                 -Name logFile.period `
                                 -Value $LogPeriod
            }

            # Update LogTruncateSize if needed
            if ($PSBoundParameters.ContainsKey('LogTruncateSize') -and `
                ($LogTruncateSize -ne $Website.logfile.LogTruncateSize))
            {
                Write-Verbose -Message ($LocalizedData.VerboseSetTargetUpdateLogTruncateSize `
                                        -f $Name)
                Set-ItemProperty -Path "IIS:\Sites\$Name" `
                                 -Name logFile.truncateSize `
                                 -Value $LogTruncateSize
                Set-ItemProperty -Path "IIS:\Sites\$Name" `
                                 -Name logFile.period `
                                 -Value 'MaxSize'
            }

            # Update LoglocalTimeRollover if neeed
            if ($PSBoundParameters.ContainsKey('LoglocalTimeRollover') -and `
                ($LoglocalTimeRollover -ne `
                 ([System.Convert]::ToBoolean($Website.logfile.LoglocalTimeRollover))))
            {
                Write-Verbose -Message ($LocalizedData.VerboseSetTargetUpdateLoglocalTimeRollover `
                                        -f $Name)
                Set-ItemProperty -Path "IIS:\Sites\$Name" `
                                 -Name logFile.localTimeRollover `
                                 -Value $LoglocalTimeRollover
            }
        }
    }
    else # Remove website
    {
        try
        {
            Remove-Website -Name $Name -ErrorAction Stop
            Write-Verbose -Message ($LocalizedData.VerboseSetTargetWebsiteRemoved `
                                    -f $Name)
        }
        catch
        {
            $ErrorMessage = $LocalizedData.ErrorWebsiteRemovalFailure `
                            -f $Name, $_.Exception.Message
            New-TerminatingError -ErrorId 'WebsiteRemovalFailure' `
                                 -ErrorMessage $ErrorMessage `
                                 -ErrorCategory 'InvalidOperation'
        }
    }
}

<#
.SYNOPSIS
    The Test-TargetResource cmdlet is used to validate if the role or feature is in a state as
    expected in the instance document.
#>
function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([Boolean])]
    param
    (
        [ValidateSet('Present', 'Absent')]
        [String]
        $Ensure = 'Present',

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $Name,

        [String]
        $PhysicalPath,

        [ValidateSet('Started', 'Stopped')]
        [String]
        $State = 'Started',

        [ValidateLength(1, 64)] # The application pool name must contain between 1 and 64 characters
        [String]
        $ApplicationPool,

        [Microsoft.Management.Infrastructure.CimInstance[]]
        $BindingInfo,

        [String[]]
        $DefaultPage,

        [String]
        $EnabledProtocols,

        [Microsoft.Management.Infrastructure.CimInstance]
        $AuthenticationInfo,
        
        [Boolean]
        $PreloadEnabled,
        
        [Boolean]
        $ServiceAutoStartEnabled,

        [String]
        $ServiceAutoStartProvider,
        
        [String]
        $ApplicationType,

        [String]
        $LogPath,

        [ValidateSet('Date','Time','ClientIP','UserName','SiteName','ComputerName','ServerIP','Method','UriStem','UriQuery','HttpStatus','Win32Status','BytesSent','BytesRecv','TimeTaken','ServerPort','UserAgent','Cookie','Referer','ProtocolVersion','Host','HttpSubStatus')]
        [String[]]
        $LogFlags,

        [ValidateSet('Hourly','Daily','Weekly','Monthly','MaxSize')]
        [String]
        $LogPeriod,

        [ValidateRange('1048576','4294967295')]
        [String]
        $LogTruncateSize,

        [Boolean]
        $LoglocalTimeRollover,

        [ValidateSet('IIS','W3C','NCSA')]
        [String]
        $LogFormat
    )

    Assert-Module

    $InDesiredState = $true

    $Website = Get-Website | Where-Object -FilterScript {$_.Name -eq $Name}
    
    # Check Ensure
    if (($Ensure -eq 'Present' -and $null -eq $Website) -or `
        ($Ensure -eq 'Absent' -and $null -ne $Website))
    {
        $InDesiredState = $false
        Write-Verbose -Message ($LocalizedData.VerboseTestTargetFalseEnsure `
                                -f $Name)
    }

    # Only check properties if website exists
    if ($Ensure -eq 'Present' -and `
        $null -ne $Website)
    {
        # Check Physical Path property
        if ([string]::IsNullOrEmpty($PhysicalPath) -eq $false -and `
            $Website.PhysicalPath -ne $PhysicalPath)
        {
            $InDesiredState = $false
            Write-Verbose -Message ($LocalizedData.VerboseTestTargetFalsePhysicalPath `
                                    -f $Name)
        }

        # Check State
        if ($PSBoundParameters.ContainsKey('State') -and $Website.State -ne $State)
        {
            $InDesiredState = $false
            Write-Verbose -Message ($LocalizedData.VerboseTestTargetFalseState `
                                    -f $Name)
        }

        # Check Application Pool property
        if ($PSBoundParameters.ContainsKey('ApplicationPool') -and `
            $Website.ApplicationPool -ne $ApplicationPool)
        {
            $InDesiredState = $false
            Write-Verbose -Message ($LocalizedData.VerboseTestTargetFalseApplicationPool `
                                    -f $Name)
        }

        # Check Binding properties
        if ($PSBoundParameters.ContainsKey('BindingInfo') -and `
            $null -ne $BindingInfo)
        {
            if (-not (Test-WebsiteBinding -Name $Name -BindingInfo $BindingInfo))
            {
                $InDesiredState = $false
                Write-Verbose -Message ($LocalizedData.VerboseTestTargetFalseBindingInfo `
                                        -f $Name)
            }
        }

        # Check Enabled Protocols
        if ($PSBoundParameters.ContainsKey('EnabledProtocols') -and `
            $Website.EnabledProtocols -ne $EnabledProtocols)
        {
            $InDesiredState = $false
            Write-Verbose -Message ($LocalizedData.VerboseTestTargetFalseEnabledProtocols `
                                    -f $Name)
        }

        # Check Default Pages
        if ($PSBoundParameters.ContainsKey('DefaultPage') -and `
            $null -ne $DefaultPage)
        {
            $AllDefaultPages = @(
                Get-WebConfiguration -Filter '//defaultDocument/files/*' `
                                     -PSPath "IIS:\Sites\$Name" |
                ForEach-Object -Process {Write-Output -InputObject $_.value}
            )

            foreach ($Page in $DefaultPage)
            {
                if ($AllDefaultPages -inotcontains $Page)
                {
                    $InDesiredState = $false
                    Write-Verbose -Message ($LocalizedData.VerboseTestTargetFalseDefaultPage `
                                            -f $Name)
                }
            }
        }

        #Check AuthenticationInfo
        if ($PSBoundParameters.ContainsKey('AuthenticationInfo') -and `
            (-not (Test-AuthenticationInfo -Site $Name `
                                           -IisType 'Website' `
                                           -AuthenticationInfo $AuthenticationInfo)))
        { 
            $InDesiredState = $false
            Write-Verbose -Message ($LocalizedData.VerboseTestTargetFalseAuthenticationInfo)
        } 
        
        #Check Preload
        if($PSBoundParameters.ContainsKey('preloadEnabled') -and `
            $Website.applicationDefaults.preloadEnabled -ne $PreloadEnabled)
        {
            $InDesiredState = $false
            Write-Verbose -Message ($LocalizedData.VerboseTestTargetFalsePreload `
                                    -f $Name)
        } 
              
        #Check AutoStartEnabled
        if($PSBoundParameters.ContainsKey('serviceAutoStartEnabled') -and `
            $Website.applicationDefaults.serviceAutoStartEnabled -ne $ServiceAutoStartEnabled)
        {
            $InDesiredState = $false
            Write-Verbose -Message ($LocalizedData.VerboseTestTargetFalseAutoStart `
                                    -f $Name)
        }
        
        #Check AutoStartProviders 
        if($PSBoundParameters.ContainsKey('serviceAutoStartProvider') -and `
            $Website.applicationDefaults.serviceAutoStartProvider -ne $ServiceAutoStartProvider)
        {
            if (-not (Confirm-UniqueServiceAutoStartProviders `
                        -serviceAutoStartProvider $ServiceAutoStartProvider `
                        -ApplicationType $ApplicationType))
            {
                $InDesiredState = $false
                Write-Verbose -Message ($LocalizedData.VerboseSetTargetIISAutoStartProviderUpdated)
            }
        }

        # Check LogFormat
        if ($PSBoundParameters.ContainsKey('LogFormat'))
        {
            # Warn if LogFlags are passed in and Current LogFormat is not W3C
            if ($PSBoundParameters.ContainsKey('LogFlags') -and `
                $LogFormat -ne 'W3C')
            {
                Write-Verbose -Message ($LocalizedData.WarningIncorrectLogFormat `
                                        -f $Name)
            }
            # Warn if LogFlags are passed in and Desired LogFormat is not W3C
            if($PSBoundParameters.ContainsKey('LogFlags') -and `
                $Website.logfile.LogFormat -ne 'W3C')
            {
                Write-Verbose -Message ($LocalizedData.WarningIncorrectLogFormat `
                                        -f $Name)
            }
            # Check Log Format
            if ($LogFormat -ne $Website.logfile.LogFormat)
            {
                Write-Verbose -Message ($LocalizedData.VerboseTestTargetFalseLogFormat `
                                        -f $Name)
                return $false
            }
        }

        # Check LogFlags
        if ($PSBoundParameters.ContainsKey('LogFlags') -and `
            (-not (Compare-LogFlags -Name $Name -LogFlags $LogFlags)))
        {
            Write-Verbose -Message ($LocalizedData.VerboseTestTargetFalseLogFlags)
            return $false
        }

        # Check LogPath
        if ($PSBoundParameters.ContainsKey('LogPath') -and `
            ($LogPath -ne $Website.logfile.LogPath))
        {
            Write-Verbose -Message ($LocalizedData.VerboseTestTargetFalseLogPath `
                                    -f $Name)
            return $false
        }

        # Check LogPeriod
        if ($PSBoundParameters.ContainsKey('LogPeriod') -and `
            ($LogPeriod -ne $Website.logfile.LogPeriod))
        {
            if ($PSBoundParameters.ContainsKey('LogTruncateSize'))
            {
                Write-Verbose -Message ($LocalizedData.WarningLogPeriod `
                                        -f $Name)
            }

            Write-Verbose -Message ($LocalizedData.VerboseTestTargetFalseLogPeriod `
                                    -f $Name)
            return $false
        }

        # Check LogTruncateSize
        if ($PSBoundParameters.ContainsKey('LogTruncateSize') -and `
            ($LogTruncateSize -ne $Website.logfile.LogTruncateSize))
        {
            Write-Verbose -Message ($LocalizedData.VerboseTestTargetFalseLogTruncateSize `
                                    -f $Name)
            return $false
        }

        # Check LoglocalTimeRollover
        if ($PSBoundParameters.ContainsKey('LoglocalTimeRollover') -and `
            ($LoglocalTimeRollover -ne `
            ([System.Convert]::ToBoolean($Website.logfile.LoglocalTimeRollover))))
        {
            Write-Verbose -Message ($LocalizedData.VerboseTestTargetFalseLoglocalTimeRollover `
                                    -f $Name)
            return $false
        }
    }

    if ($InDesiredState -eq $true)
    {
        Write-Verbose -Message ($LocalizedData.VerboseTestTargetTrueResult)
    }
    else
    {
        Write-Verbose -Message ($LocalizedData.VerboseTestTargetFalseResult)
    }

    return $InDesiredState
}

Export-ModuleMember -Function *-TargetResource
