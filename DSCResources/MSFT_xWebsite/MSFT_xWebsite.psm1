Unable to validate BindingInfo#requires -Version 4.0 -Modules CimCmdlets

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
        ErrorWebBindingInvalidCertificateSubject = The Subject "{0}" provided is not found on this host in store "{1}"
        ErrorWebsitePreloadFailure = Failure to set Preload on Website "{0}". Error: "{1}".
        ErrorWebsiteAutoStartFailure = Failure to set AutoStart on Website "{0}". Error: "{1}".
        ErrorWebsiteAutoStartProviderFailure = Failure to set AutoStartProvider on Website "{0}". Error: "{1}".
        ErrorWebsiteTestAutoStartProviderFailure = Desired AutoStartProvider is not valid due to a conflicting Global Property. Ensure that the serviceAutoStartProvider is a unique key."
        VerboseSetTargetUpdatedSiteId = Site Id for website "{0}" has been updated to "{1}".
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
        VerboseSetTargetUpdateLogTargetW3C = LogTargetW3C is not in the desired state and will be updated on Website "{0}".
        VerboseSetTargetUpdateLogCustomFields = LogCustomFields is not in the desired state and will be updated on Website "{0}"
        VerboseTestTargetFalseEnsure = The Ensure state for website "{0}" does not match the desired state.
        VerboseTestTargetFalseSiteId = Site Id of website "{0}" does not match the desired state.
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
        VerboseTestTargetFalseLogPath = LogPath does not match desired state on Website "{0}".
        VerboseTestTargetFalseLogFlags = LogFlags does not match desired state on Website "{0}".
        VerboseTestTargetFalseLogPeriod = LogPeriod does not match desired state on Website "{0}".
        VerboseTestTargetFalseLogTruncateSize = LogTruncateSize does not match desired state on Website "{0}".
        VerboseTestTargetFalseLoglocalTimeRollover = LoglocalTimeRollover does not match desired state on Website "{0}".
        VerboseTestTargetFalseLogFormat = LogFormat does not match desired state on Website "{0}".
        VerboseTestTargetFalseLogTargetW3C = LogTargetW3C does not match desired state on Website "{0}".
        VerboseTestTargetFalseLogCustomFields = LogCustomFields does not match desired state on Website "{0}".
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
.SYNOPSIS
    The Get-TargetResource cmdlet is used to fetch the status of role or Website on
    the target machine. It gives the Website info of the requested role/feature on the
    target machine.

.PARAMETER Name
    Name of the website
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

    $website = Get-Website | Where-Object -FilterScript {$_.Name -eq $Name}

    if ($website.Count -eq 0)
    {
        Write-Verbose -Message ($LocalizedData.VerboseGetTargetAbsent)
        $ensureResult = 'Absent'
    }
    elseif ($website.Count -eq 1)
    {
        Write-Verbose -Message ($LocalizedData.VerboseGetTargetPresent)
        $ensureResult = 'Present'

        $cimBindings = @(ConvertTo-CimBinding -InputObject $website.bindings.Collection)

        $allDefaultPages = @(
            Get-WebConfiguration -Filter '/system.webServer/defaultDocument/files/*' -PSPath "IIS:\Sites\$Name" |
            ForEach-Object -Process {Write-Output -InputObject $_.value}
        )
        $cimAuthentication = Get-AuthenticationInfo -Site $Name -IisType 'Website'
        $websiteAutoStartProviders = (Get-WebConfiguration `
            -filter /system.applicationHost/serviceAutoStartProviders).Collection
        $webConfiguration = $websiteAutoStartProviders | `
                                Where-Object -Property Name -eq -Value $ServiceAutoStartProvider | `
                                Select-Object Name,Type

        [Array] $cimLogCustomFields = ConvertTo-CimLogCustomFields -InputObject $website.logFile.customFields.Collection
    }
    # Multiple websites with the same name exist. This is not supported and is an error
    else
    {
        $errorMessage = $LocalizedData.ErrorWebsiteDiscoveryFailure -f $Name
        New-TerminatingError -ErrorId 'WebsiteDiscoveryFailure' `
                             -ErrorMessage $errorMessage `
                             -ErrorCategory 'InvalidResult'
    }

    # Add all website properties to the hash table
    return @{
        Ensure                   = $ensureResult
        Name                     = $Name
        SiteId                   = $website.id
        PhysicalPath             = $website.PhysicalPath
        State                    = $website.State
        ApplicationPool          = $website.ApplicationPool
        BindingInfo              = $cimBindings
        DefaultPage              = $allDefaultPages
        EnabledProtocols         = $website.EnabledProtocols
        AuthenticationInfo       = $cimAuthentication
        PreloadEnabled           = $website.applicationDefaults.preloadEnabled
        ServiceAutoStartProvider = $website.applicationDefaults.serviceAutoStartProvider
        ServiceAutoStartEnabled  = $website.applicationDefaults.serviceAutoStartEnabled
        ApplicationType          = $webConfiguration.Type
        LogPath                  = $website.logfile.directory
        LogFlags                 = [Array]$website.logfile.LogExtFileFlags
        LogPeriod                = $website.logfile.period
        LogtruncateSize          = $website.logfile.truncateSize
        LoglocalTimeRollover     = $website.logfile.localTimeRollover
        LogFormat                = $website.logfile.logFormat
        LogTargetW3C             = $website.logfile.logTargetW3C
        LogCustomFields          = $cimLogCustomFields
    }
}

<#
.SYNOPSIS
    The Set-TargetResource cmdlet is used to create, delete or configure a website on the
    target machine.

.PARAMETER SiteId
    Optional. Specifies the IIS site Id for the web site.

.PARAMETER PhysicalPath
    Specifies the physical path of the web site. Don't set this if the site will be deployed by an external tool that updates the path.
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

        # To avoid confusion we use SiteId instead of just Id
        [Parameter()]
        [UInt32]
        $SiteId,

        [String]
        $PhysicalPath,

        [ValidateSet('Started', 'Stopped')]
        [String]
        $State = 'Started',

        # The application pool name must contain between 1 and 64 characters
        [ValidateLength(1, 64)]
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

        [ValidateScript({
            ([ValidateRange(1048576, 4294967295)] $valueAsUInt64 = [UInt64]::Parse($_))
        })]
        [String]
        $LogTruncateSize,

        [Boolean]
        $LoglocalTimeRollover,

        [ValidateSet('IIS','W3C','NCSA')]
        [String]
        $LogFormat,

        [ValidateSet('File','ETW','File,ETW')]
        [String]
        $LogTargetW3C,

        [Microsoft.Management.Infrastructure.CimInstance[]]
        $LogCustomFields
    )

    Assert-Module

    $website = Get-Website | Where-Object -FilterScript {$_.Name -eq $Name}

    if ($Ensure -eq 'Present')
    {
        if ($null -ne $website)
        {
            # Update Site Id if required
            # Note: Set-ItemProperty is case sensitive. only works with id, not Id or ID
            if ($SiteId -gt 0 -and `
                $website.Id -ne $SiteId)
            {
                Set-ItemProperty -Path "IIS:\Sites\$Name" `
                    -Name id `
                    -Value $SiteId `
                    -ErrorAction Stop
                Write-Verbose -Message ($LocalizedData.VerboseSetTargetUpdatedSiteId `
                    -f $Name, $SiteId)
            }

            # Update Physical Path if required
            if ([String]::IsNullOrEmpty($PhysicalPath) -eq $false -and `
                $website.PhysicalPath -ne $PhysicalPath)
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
                $website.ApplicationPool -ne $ApplicationPool)
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
                $website.EnabledProtocols -ne $EnabledProtocols)
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
                $website.State -ne $State)
            {
                if ($State -eq 'Started')
                {
                    # Ensure that there are no other running websites with binding information that
                    # will conflict with this website before starting
                    if (-not (Confirm-UniqueBinding -Name $Name -ExcludeStopped))
                    {
                        # Return error and do not start the website
                        $errorMessage = $LocalizedData.ErrorWebsiteBindingConflictOnStart `
                                        -f $Name
                        New-TerminatingError -ErrorId 'WebsiteBindingConflictOnStart' `
                                             -ErrorMessage $errorMessage `
                                             -ErrorCategory 'InvalidResult'
                    }

                    try
                    {
                        Start-Website -Name $Name -ErrorAction Stop
                    }
                    catch
                    {
                        $errorMessage = $LocalizedData.ErrorWebsiteStateFailure `
                                        -f $Name, $_.Exception.Message
                        New-TerminatingError -ErrorId 'WebsiteStateFailure' `
                                             -ErrorMessage $errorMessage `
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
                        $errorMessage = $LocalizedData.ErrorWebsiteStateFailure `
                                        -f $Name, $_.Exception.Message
                        New-TerminatingError -ErrorId 'WebsiteStateFailure' `
                                             -ErrorMessage $errorMessage `
                                             -ErrorCategory 'InvalidOperation'
                    }
                }

                Write-Verbose -Message ($LocalizedData.VerboseSetTargetUpdatedState `
                                        -f $Name, $State)
            }
        }
        # Create website if it does not exist
        else
        {
            try
            {
                $PSBoundParameters.GetEnumerator() | Where-Object -FilterScript {
                    $_.Key -in (Get-Command -Name New-Website `
                                            -Module WebAdministration).Parameters.Keys
                } | ForEach-Object -Begin {
                        $newWebsiteSplat = @{}
                } -Process {
                    $newWebsiteSplat.Add($_.Key, $_.Value)
                }

                # New-WebSite has Id parameter instead of SiteId, so it's getting mapped to Id
                if ($PSBoundParameters.ContainsKey('SiteId')) {
                    $newWebsiteSplat.Add('Id', $SiteId)
                } elseif (-not (Get-WebSite)) {
                    # If there are no other websites and SiteId is missing, specify the Id Parameter for the new website.
                    # Otherwise an error can occur on systems running Windows Server 2008 R2.
                    $newWebsiteSplat.Add('Id', 1)
                }

                if ([String]::IsNullOrEmpty($PhysicalPath)) {
                    # If no physical path is provided run New-Website with -Force flag
                    $website = New-Website @newWebsiteSplat -ErrorAction Stop -Force
                } else {
                    # If physical path is provided don't run New-Website with -Force flag to verify that the path exists
                    $website = New-Website @newWebsiteSplat -ErrorAction Stop
                }

                Write-Verbose -Message ($LocalizedData.VerboseSetTargetWebsiteCreated `
                                        -f $Name)
            }
            catch
            {
                $errorMessage = $LocalizedData.ErrorWebsiteCreationFailure `
                                -f $Name, $_.Exception.Message
                New-TerminatingError -ErrorId 'WebsiteCreationFailure' `
                                     -ErrorMessage $errorMessage `
                                     -ErrorCategory 'InvalidOperation'
            }

            Stop-Website -Name $website.Name -ErrorAction Stop

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
                -and $website.EnabledProtocols `
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
                    $errorMessage = $LocalizedData.ErrorWebsiteBindingConflictOnStart `
                                    -f $Name
                    New-TerminatingError -ErrorId 'WebsiteBindingConflictOnStart' `
                                         -ErrorMessage $errorMessage `
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
                    $errorMessage = $LocalizedData.ErrorWebsiteStateFailure `
                                    -f $Name, $_.Exception.Message
                    New-TerminatingError -ErrorId 'WebsiteStateFailure' `
                                         -ErrorMessage $errorMessage `
                                         -ErrorCategory 'InvalidOperation'
                }
            }
        }

        # Set Authentication; if not defined then pass in DefaultAuthenticationInfo
        $DefaultAuthenticationInfo = Get-DefaultAuthenticationInfo -IisType 'Website'
        if ($PSBoundParameters.ContainsKey('AuthenticationInfo') -and `
        (-not (Test-AuthenticationInfo -Site $Name `
                                        -IisType 'Website' `
                                        -AuthenticationInfo $AuthenticationInfo)))
        {
            Set-AuthenticationInfo -Site $Name `
                                    -IisType 'Website' `
                                    -AuthenticationInfo $AuthenticationInfo `
                                    -ErrorAction Stop
            Write-Verbose -Message ($LocalizedData.VerboseSetTargetAuthenticationInfoUpdated `
                                    -f $Name)
        }
        elseif($null -eq $PSBoundParameters.ContainsKey('AuthenticationInfo') -and `
        (-not (Test-AuthenticationInfo -Site $Name `
                                        -IisType 'Website' `
                                        -AuthenticationInfo $DefaultAuthenticationInfo)))
        {
            Set-AuthenticationInfo -Site $Name `
                                    -IisType 'Website' `
                                    -AuthenticationInfo $DefaultAuthenticationInfo `
                                    -ErrorAction Stop
            Write-Verbose -Message ($LocalizedData.VerboseSetTargetAuthenticationInfoUpdated `
                                -f $Name)
        }

        # Update Preload if required
        if ($PSBoundParameters.ContainsKey('preloadEnabled') -and `
            ($website.applicationDefaults.preloadEnabled -ne $PreloadEnabled))
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
            ($website.applicationDefaults.ServiceAutoStartEnabled -ne $ServiceAutoStartEnabled))
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
            ($website.applicationDefaults.ServiceAutoStartProvider `
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
            ($LogFormat -ne $website.logfile.LogFormat))
        {
            Write-Verbose -Message ($LocalizedData.VerboseSetTargetUpdateLogFormat -f $Name)

            # In Windows Server 2008 R2, Set-ItemProperty only accepts index values to the LogFile.LogFormat property
            $site = Get-Item "IIS:\Sites\$Name"
            $site.LogFile.LogFormat = $LogFormat
            $site | Set-Item
        }

        # Update LogTargetW3C if Needed
        if ($PSBoundParameters.ContainsKey('LogTargetW3C') `
            -and $website.logfile.LogTargetW3C `
            -ne $LogTargetW3C)
        {
            Set-ItemProperty -Path "IIS:\Sites\$Name" `
                                -Name logfile.logTargetW3C `
                                -Value $LogTargetW3C `
                                -ErrorAction Stop
            Write-Verbose -Message ($LocalizedData.VerboseSetTargetUpdateLogTargetW3C `
                                    -f $Name, $LogTargetW3C)
        }

        # Update LogFlags if required
        if ($PSBoundParameters.ContainsKey('LogFlags') -and `
            (-not (Compare-LogFlags -Name $Name -LogFlags $LogFlags)))
        {
            Write-Verbose -Message ($LocalizedData.VerboseSetTargetUpdateLogFlags `
                                    -f $Name)

            # Set-ItemProperty has no effect with the LogFile.LogExtFileFlags property
            $site = Get-Item "IIS:\Sites\$Name"
            $site.LogFile.LogFormat = 'W3C'
            $site.LogFile.LogExtFileFlags = $LogFlags -join ','
            $site | Set-Item
        }

        # Update LogPath if required
        if ($PSBoundParameters.ContainsKey('LogPath') -and `
            ($LogPath -ne $website.logfile.directory))
        {
            Write-Verbose -Message ($LocalizedData.VerboseSetTargetUpdateLogPath `
                                    -f $Name)
            Set-ItemProperty -Path "IIS:\Sites\$Name" `
                -Name LogFile.directory -value $LogPath
        }

        # Update LogPeriod if needed
        if ($PSBoundParameters.ContainsKey('LogPeriod') -and `
            ($LogPeriod -ne $website.logfile.period))
        {
            if ($PSBoundParameters.ContainsKey('LogTruncateSize'))
                {
                    Write-Verbose -Message ($LocalizedData.WarningLogPeriod `
                                            -f $Name)
                }

            Write-Verbose -Message ($LocalizedData.VerboseSetTargetUpdateLogPeriod)

            # In Windows Server 2008 R2, Set-ItemProperty only accepts index values to the LogFile.Period property
            $site = Get-Item "IIS:\Sites\$Name"
            $site.LogFile.Period = $LogPeriod
            $site | Set-Item
        }

        # Update LogTruncateSize if needed
        if ($PSBoundParameters.ContainsKey('LogTruncateSize') -and `
            ($LogTruncateSize -ne $website.logfile.LogTruncateSize))
        {
            Write-Verbose -Message ($LocalizedData.VerboseSetTargetUpdateLogTruncateSize `
                                    -f $Name)
            Set-ItemProperty -Path "IIS:\Sites\$Name" `
                -Name LogFile.truncateSize -Value $LogTruncateSize
            Set-ItemProperty -Path "IIS:\Sites\$Name" `
                -Name LogFile.period -Value 'MaxSize'
        }

        # Update LoglocalTimeRollover if needed
        if ($PSBoundParameters.ContainsKey('LoglocalTimeRollover') -and `
            ($LoglocalTimeRollover -ne `
                ([System.Convert]::ToBoolean($website.logfile.LocalTimeRollover))))
        {
            Write-Verbose -Message ($LocalizedData.VerboseSetTargetUpdateLoglocalTimeRollover `
                                    -f $Name)
            Set-ItemProperty -Path "IIS:\Sites\$Name" `
                -Name LogFile.localTimeRollover -Value $LoglocalTimeRollover
        }

        # Update LogCustomFields if needed
        if ($PSBoundParameters.ContainsKey('LogCustomFields') -and `
        (-not (Test-LogCustomField -Site $Name -LogCustomField $LogCustomFields)))
        {
            Write-Verbose -Message ($LocalizedData.VerboseSetTargetUpdateLogCustomFields `
                                    -f $Name)
            Set-LogCustomField -Site $Name -LogCustomField $LogCustomFields
        }
    }
    # Remove website
    else
    {
        try
        {
            Remove-Website -Name $Name -ErrorAction Stop
            Write-Verbose -Message ($LocalizedData.VerboseSetTargetWebsiteRemoved `
                                    -f $Name)
        }
        catch
        {
            $errorMessage = $LocalizedData.ErrorWebsiteRemovalFailure `
                            -f $Name, $_.Exception.Message
            New-TerminatingError -ErrorId 'WebsiteRemovalFailure' `
                                 -ErrorMessage $errorMessage `
                                 -ErrorCategory 'InvalidOperation'
        }
    }
}

<#
.SYNOPSIS
    The Test-TargetResource cmdlet is used to validate if the role or feature is in a state as
    expected in the instance document.

.PARAMETER SiteId
    Optional. Specifies the IIS site Id for the web site.

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

        [Parameter()]
        [UInt32]
        $SiteId,

        [String]
        $PhysicalPath,

        [ValidateSet('Started', 'Stopped')]
        [String]
        $State = 'Started',

        # The application pool name must contain between 1 and 64 characters
        [ValidateLength(1, 64)]
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

        [ValidateScript({
            ([ValidateRange(1048576, 4294967295)] $valueAsUInt64 = [UInt64]::Parse($_))
        })]
        [String]
        $LogTruncateSize,

        [Boolean]
        $LoglocalTimeRollover,

        [ValidateSet('IIS','W3C','NCSA')]
        [String]
        $LogFormat,

        [ValidateSet('File','ETW','File,ETW')]
        [String]
        $LogTargetW3C,

        [Microsoft.Management.Infrastructure.CimInstance[]]
        $LogCustomFields
    )

    Assert-Module

    $inDesiredState = $true

    $website = Get-Website | Where-Object -FilterScript {$_.Name -eq $Name}

    # Check Ensure
    if (($Ensure -eq 'Present' -and $null -eq $website) -or `
        ($Ensure -eq 'Absent' -and $null -ne $website))
    {
        $inDesiredState = $false
        Write-Verbose -Message ($LocalizedData.VerboseTestTargetFalseEnsure `
                                -f $Name)
    }

    # Only check properties if website exists
    if ($Ensure -eq 'Present' -and `
        $null -ne $website)
    {
        # Check Site Id property.
        if ($SiteId -gt 0 -and $website.Id -ne $SiteId)
        {
            $inDesiredState = $false
            Write-Verbose -Message ($LocalizedData.VerboseTestTargetFalseSiteId -f $Name)
        }

        # Check Physical Path property
        if ([String]::IsNullOrEmpty($PhysicalPath) -eq $false -and `
            $website.PhysicalPath -ne $PhysicalPath)
        {
            $inDesiredState = $false
            Write-Verbose -Message ($LocalizedData.VerboseTestTargetFalsePhysicalPath `
                                    -f $Name)
        }

        # Check State
        if ($PSBoundParameters.ContainsKey('State') -and $website.State -ne $State)
        {
            $inDesiredState = $false
            Write-Verbose -Message ($LocalizedData.VerboseTestTargetFalseState `
                                    -f $Name)
        }

        # Check Application Pool property
        if ($PSBoundParameters.ContainsKey('ApplicationPool') -and `
            $website.ApplicationPool -ne $ApplicationPool)
        {
            $inDesiredState = $false
            Write-Verbose -Message ($LocalizedData.VerboseTestTargetFalseApplicationPool `
                                    -f $Name)
        }

        # Check Binding properties
        if ($PSBoundParameters.ContainsKey('BindingInfo') -and `
            $null -ne $BindingInfo)
        {
            if (-not (Test-WebsiteBinding -Name $Name -BindingInfo $BindingInfo))
            {
                $inDesiredState = $false
                Write-Verbose -Message ($LocalizedData.VerboseTestTargetFalseBindingInfo `
                                        -f $Name)
            }
        }

        # Check Enabled Protocols
        if ($PSBoundParameters.ContainsKey('EnabledProtocols') -and `
            $website.EnabledProtocols -ne $EnabledProtocols)
        {
            $inDesiredState = $false
            Write-Verbose -Message ($LocalizedData.VerboseTestTargetFalseEnabledProtocols `
                                    -f $Name)
        }

        # Check Default Pages
        if ($PSBoundParameters.ContainsKey('DefaultPage') -and `
            $null -ne $DefaultPage)
        {
            $allDefaultPages = @(
                Get-WebConfiguration -Filter '/system.webServer/defaultDocument/files/*' `
                                     -PSPath "IIS:\Sites\$Name" |
                ForEach-Object -Process { Write-Output -InputObject $_.value }
            )

            foreach ($page in $DefaultPage)
            {
                if ($allDefaultPages -inotcontains $page)
                {
                    $inDesiredState = $false
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
            $inDesiredState = $false
            Write-Verbose -Message ($LocalizedData.VerboseTestTargetFalseAuthenticationInfo)
        }

        #Check Preload
        if($PSBoundParameters.ContainsKey('preloadEnabled') -and `
            $website.applicationDefaults.preloadEnabled -ne $PreloadEnabled)
        {
            $inDesiredState = $false
            Write-Verbose -Message ($LocalizedData.VerboseTestTargetFalsePreload `
                                    -f $Name)
        }

        #Check AutoStartEnabled
        if($PSBoundParameters.ContainsKey('serviceAutoStartEnabled') -and `
            $website.applicationDefaults.serviceAutoStartEnabled -ne $ServiceAutoStartEnabled)
        {
            $inDesiredState = $false
            Write-Verbose -Message ($LocalizedData.VerboseTestTargetFalseAutoStart `
                                    -f $Name)
        }

        #Check AutoStartProviders
        if($PSBoundParameters.ContainsKey('serviceAutoStartProvider') -and `
            $website.applicationDefaults.serviceAutoStartProvider -ne $ServiceAutoStartProvider)
        {
            if (-not (Confirm-UniqueServiceAutoStartProviders `
                        -serviceAutoStartProvider $ServiceAutoStartProvider `
                        -ApplicationType $ApplicationType))
            {
                $inDesiredState = $false
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
                $website.logfile.LogFormat -ne 'W3C')
            {
                Write-Verbose -Message ($LocalizedData.WarningIncorrectLogFormat `
                                        -f $Name)
            }

            # Check Log Format
            if ($LogFormat -ne $website.logfile.LogFormat)
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
            ($LogPath -ne $website.logfile.directory))
        {
            Write-Verbose -Message ($LocalizedData.VerboseTestTargetFalseLogPath `
                                    -f $Name)
            return $false
        }

        # Check LogPeriod
        if ($PSBoundParameters.ContainsKey('LogPeriod') -and `
            ($LogPeriod -ne $website.logfile.period))
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
            ($LogTruncateSize -ne $website.logfile.LogTruncateSize))
        {
            Write-Verbose -Message ($LocalizedData.VerboseTestTargetFalseLogTruncateSize `
                                    -f $Name)
            return $false
        }

        # Check LoglocalTimeRollover
        if ($PSBoundParameters.ContainsKey('LoglocalTimeRollover') -and `
            ($LoglocalTimeRollover -ne `
            ([System.Convert]::ToBoolean($website.logfile.LocalTimeRollover))))
        {
            Write-Verbose -Message ($LocalizedData.VerboseTestTargetFalseLoglocalTimeRollover `
                                    -f $Name)
            return $false
        }

        # Check LogTargetW3C
        if ($PSBoundParameters.ContainsKey('LogTargetW3C') -and `
            ($LogTargetW3C -ne $website.logfile.LogTargetW3C))
        {
            Write-Verbose -Message ($LocalizedData.VerboseTestTargetFalseLogTargetW3C `
                                    -f $Name)
            return $false
        }

        # Check LogCustomFields if needed
        if ($PSBoundParameters.ContainsKey('LogCustomFields') -and `
            (-not (Test-LogCustomField -Site $Name -LogCustomField $LogCustomFields)))
        {
            Write-Verbose -Message ($LocalizedData.VerboseTestTargetUpdateLogCustomFields `
                                    -f $Name)
            return $false
        }
    }

    if ($inDesiredState -eq $true)
    {
        Write-Verbose -Message ($LocalizedData.VerboseTestTargetTrueResult)
    }
    else
    {
        Write-Verbose -Message ($LocalizedData.VerboseTestTargetFalseResult)
    }

    return $inDesiredState
}

Export-ModuleMember -Function *-TargetResource
