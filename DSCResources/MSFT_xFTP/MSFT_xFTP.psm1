# Load the Helper Module
Import-Module -Name "$PSScriptRoot\..\Helper.psm1"

# Localized messages
data LocalizedData
{
    # culture="en-US"
    ConvertFrom-StringData -StringData @'
        ErrorftpSiteDiscoveryFailure               = Failure to get the requested ftpSite "{0}" information from the target machine.
        ErrorftpSiteCreationFailure                = Failure to successfully create the ftpSite "{0}". Error: "{1}".
        ErrorftpSiteRemovalFailure                 = Failure to successfully remove the ftpSite "{0}". Error: "{1}".
        ErrorftpSiteStateFailure                   = Failure to successfully set the state of the website "{0}". Error: "{1}".
        ErrorServerCertHashFailure                 = No such cert with the hash of "{0}" exists under store "{1}".
        VerboseGetTargetAbsent                     = No ftpSite exists with this name.
        VerboseGetTargetPresent                    = A single ftpSite exists with this name.
        VerboseSetTargetftpSiteCreated             = Successfully created ftpSite "{0}".
        VerboseSetTargetftpSiteRemoved             = Successfully removed ftpSite "{0}".
        VerboseSetTargetUpdatedApplicationPool     = Successfully updated ApplicationPool on ftpSite "{0}".
        VerboseSetTargetAuthenticationInfoUpdated  = Successfully updated AuthenticationInfo on ftpSite "{0}".
        VerboseSetTargetAuthorizationInfoUpdated   = Successfully updated AuthorizationInfo on ftpSite "{0}".
        VerboseSetTargetUpdateLogPath              = LogPath does not match and will be updated on Website "{0}".
        VerboseSetTargetUpdateLogFlags             = LogFlags do not match and will be updated on Website "{0}".
        VerboseSetTargetUpdateLogPeriod            = LogPeriod does not match and will be updated on Website "{0}".
        VerboseSetTargetUpdateLogTruncateSize      = TruncateSize does not match and will be updated on Website "{0}".
        VerboseSetTargetUpdateLoglocalTimeRollover = LoglocalTimeRollover does not match and will be updated on Website "{0}".
        VerboseSetTargetUpdateDirectoryBrowseFlags = DirectoryBrowseFlags do not match and will be updated on Website "{0}".
        VerboseSetTargetUpdatedPhysicalPath        = Successfully updated PhysicalPath on ftpSite "{0}".
        VerboseSetTargetUpdatedState               = Successfully updated State on ftpSite "{0}".
        VerboseSetTargetUpdatedBindingInfo         = Successfully updated BindingInfo on ftpSite "{0}".
        VerboseSetTargetUpdateSslInfo              = Successfully updated SslInfo on ftpSite "{0}".
        VerboseSetTargetUpdateUserIsolation        = Successfully updated UserIsolation on ftpSite "{0}".
        VerboseTestTargetFalseState                = The state of ftpSite "{0}" does not match the desired state.
        VerboseTestTargetFalseApplicationPool      = Application Pool for ftpSite "{0}" does not match the desired state.
        VerboseTestTargetFalsePhysicalPath         = Physical Path of ftpSite "{0}" does not match the desired state.
        VerboseTestTargetFalseAuthenticationInfo   = AuthenticationInfo for ftpSite "{0}" is not in the desired state.
        VerboseTestTargetFalseAuthorizationInfo    = AuthorizationInfo for ftpSite "{0}" is not in the desired state.
        VerboseTestTargetFalseBindingInfo          = BindingInfo for ftpSite "{0}" is not in the desired state.
        VerboseTestTargetFalseSslInfo              = SslInfo for ftpSite "{0}" is not in the desired state.
        VerboseTestTargetFalseLogPath              = LogPath does match desired state on Website "{0}".
        VerboseTestTargetFalseLogFlags             = LogFlags does not match desired state on Website "{0}".
        VerboseTestTargetFalseLogPeriod            = LogPeriod does not match desired state on Website "{0}".
        VerboseTestTargetFalseLogTruncateSize      = LogTruncateSize does not match desired state on Website "{0}".
        VerboseTestTargetFalseLoglocalTimeRollover = LoglocalTimeRollover does not match desired state on Website "{0}".
        VerboseTestTargetFalseDirectoryBrowseFlags = DirectoryBrowseFlags does not match desired state on Website "{0}".
        VerboseTestTargetFalseUserIsolation        = UserIsolation for ftpSite "{0}" is not in the desired state.
        VerboseTestTargetFalseEnsure               = The Ensure state for ftpSite "{0}" does not match the desired state.
        VerboseTestTargetTrueResult                = The target resource is already in the desired state. No action is required.
        VerboseTestTargetFalseResult               = The target resource is not in the desired state.
        VerboseStartWebsite                        = Successfully started ftpSite "{0}".
        VerboseStopWebsite                         = Successfully stopped ftpSite "{0}".
'@
}

<#
.SYNOPSYS
    The Get-TargetResource cmdlet is used to fetch the status of role or ftpSite on the 
    target machine. It gives the ftpSite info of the requested role/feature on the 
    target machine.
#>
function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String] $Name
    )

    Assert-Module

    $ftpSite = Get-Website | Where-Object -FilterScript {$_.Name -eq $Name}

    if ($ftpSite.Count -eq 0)
    {
        Write-Verbose -Message ($LocalizedData.VerboseGetTargetAbsent)
        $ensureResult = 'Absent'
    }

    elseif ($ftpSite.Count -eq 1)
    {
        $authenticationInfo = Get-AuthenticationInfo -Site $Name -IisType 'Ftp'
        $authorizationInfo = Get-AuthorizationInfo -Site $Name
        $sslInfo = Get-SslInfo -Site $Name
        $bindings = @(ConvertTo-CimBinding -InputObject $ftpSite.bindings.Collection)

        Write-Verbose -Message ($LocalizedData.VerboseGetTargetPresent)
        $ensureResult = 'Present'
    }

    else # Multiple ftpSites with the same name exist. This is not supported and is an error
    {
        $errorMessage = $LocalizedData.ErrorftpSiteDiscoveryFailure -f $Name
        New-TerminatingError -ErrorId 'ftpSiteDiscoveryFailure' `
                             -ErrorMessage $errorMessage `
                             -ErrorCategory 'InvalidResult'
    }

    # Add all ftpSite properties to the hash table
    return @{
        Ensure                   = $ensureResult
        Name                     = $Name
        PhysicalPath             = $ftpSite.PhysicalPath
        State                    = $ftpSite.State
        ApplicationPool          = $ftpSite.ApplicationPool
        AuthenticationInfo       = $authenticationInfo
        AuthorizationInfo        = $authorizationInfo
        SslInfo                  = $sslInfo
        BindingInfo              = $bindings
        LogPath                  = $ftpSite.ftpserver.file.directory
        LogFlags                 = [Array]$ftpSite.ftpserver.file.LogExtFileFlags
        LogPeriod                = $ftpSite.ftpserver.file.period
        LogtruncateSize          = $ftpSite.ftpserver.file.truncateSize
        LoglocalTimeRollover     = $ftpSite.ftpserver.file.localTimeRollover
        DirectoryBrowseFlags     = [Array]$ftpSite.ftpServer.directoryBrowse.showFlags
        UserIsolation            = $ftpSite.ftpServer.userIsolation.mode
    }
}

<#
.SYNOPSYS
    The Set-TargetResource cmdlet is used to create, delete or configure a ftpSite on the 
    target machine.
#>
function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [ValidateSet('Present', 'Absent')]
        [String] $Ensure = 'Present',

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String] $Name,

        [ValidateNotNullOrEmpty()]
        [String] $PhysicalPath,

        [ValidateSet('Started', 'Stopped')]
        [String] $State = 'Started',

        # The application pool name must contain between 1 and 64 characters
        [ValidateLength(1, 64)] 
        [String] $ApplicationPool,

        [Microsoft.Management.Infrastructure.CimInstance] $AuthenticationInfo,

        [Microsoft.Management.Infrastructure.CimInstance[]] $AuthorizationInfo,

        [Microsoft.Management.Infrastructure.CimInstance] $SslInfo,

        [Microsoft.Management.Infrastructure.CimInstance[]] $BindingInfo,

        [ValidateSet('Date','Time','ClientIP','UserName','ServerIP','Method','UriStem','UriQuery','HttpStatus','Win32Status','TimeTaken','ServerPort','UserAgent','Referer','HttpSubStatus')]
        [String[]] $LogFlags,

        [String] $LogPath,

        [ValidateSet('Hourly','Daily','Weekly','Monthly','MaxSize')]
        [String] $LogPeriod,

        [ValidateRange('1048576','4294967295')]
        [String] $LogTruncateSize,

        [Boolean] $LoglocalTimeRollover,

        [ValidateSet('StyleUnix','LongDate','DisplayAvailableBytes','DisplayVirtualDirectories')]
        [String[]] $DirectoryBrowseFlags,

        [ValidateSet('None','StartInUsersDirectory','IsolateAllDirectories','IsolateRootDirectoryOnly')]
        [String] $UserIsolation

    )

    Assert-Module

    $ftpSite = Get-Website | Where-Object -FilterScript {$_.Name -eq $Name}

    if ($Ensure -eq 'Present')
    {
        if ($null -ne $ftpSite)
        {
            # Update Physical Path if required
            if ([string]::IsNullOrEmpty($PhysicalPath) -eq $false -and `
                $ftpSite.PhysicalPath -ne $PhysicalPath)
            {
                Set-ItemProperty -Path "IIS:\Sites\$Name" `
                                 -Name physicalPath `
                                 -Value $PhysicalPath `
                                 -ErrorAction Stop
                Write-Verbose -Message ($LocalizedData.VerboseSetTargetUpdatedPhysicalPath `
                                        -f $Name)
            }

            # Update Application Pool if required
            if ($PSBoundParameters.ContainsKey('ApplicationPool') -and `
                $ftpSite.ApplicationPool -ne $ApplicationPool)
            {
                Set-ItemProperty -Path "IIS:\Sites\$Name" `
                                 -Name applicationPool `
                                 -Value $ApplicationPool `
                                 -ErrorAction Stop
                Write-Verbose -Message ($LocalizedData.VerboseSetTargetUpdatedApplicationPool `
                                        -f $Name)
            }

            # Update State if required
            if ($PSBoundParameters.ContainsKey('State') -and `
                $ftpSite.State -ne $State)
            {
                if ($State -eq 'Started')
                {
                    try
                    {
                        Write-Verbose -Message ($LocalizedData.VerboseStartWebsite `
                                        -f $Name)
                        Start-Website -Name $Name -ErrorAction Stop
                    }
                    catch
                    {
                        $errorMessage = $LocalizedData.ErrorftpSiteStateFailure `
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
                        Write-Verbose -Message ($LocalizedData.VerboseStopWebsite `
                                        -f $Name)
                        Stop-Website -Name $Name -ErrorAction Stop
                    }
                    catch
                    {
                        $errorMessage = $LocalizedData.ErrorftpSiteStateFailure `
                                        -f $Name, $_.Exception.Message
                        New-TerminatingError -ErrorId 'WebsiteStateFailure' `
                                             -ErrorMessage $errorMessage `
                                             -ErrorCategory 'InvalidOperation'
                    }
                }

                Write-Verbose -Message ($LocalizedData.VerboseSetTargetUpdatedState `
                                        -f $Name)
            }
            
            <#
                Update Authentication if required; 
                if not defined then pass in DefaultAuthenticationInfo
            #>
            if ($PSBoundParameters.ContainsKey('AuthenticationInfo') -and `
                (-not (Test-AuthenticationInfo -Site $Name `
                                               -IisType 'Ftp' `
                                               -AuthenticationInfo $AuthenticationInfo)))
            {
                Set-AuthenticationInfo -Site $Name `
                                       -IisType 'Ftp' `
                                       -AuthenticationInfo $AuthenticationInfo `
                                       -ErrorAction Stop
                Write-Verbose -Message ($LocalizedData.VerboseSetTargetAuthenticationInfoUpdated `
                                        -f $Name)
            }
            
            $DefaultAuthenticationInfo = Get-DefaultAuthenticationInfo -IisType 'Ftp'
            if ($null -eq $PSBoundParameters.ContainsKey('AuthenticationInfo') -and `
                 (-not (Test-AuthenticationInfo `
                        -Site $Name `
                        -IisType 'Ftp' `
                        -AuthenticationInfo $DefaultAuthenticationInfo)))
            {
                $AuthenticationInfo = Get-DefaultAuthenticationInfo -IisType 'Ftp'
                Write-Verbose -Message ($LocalizedData.VerboseSetTargetAuthenticationInfo `
                                        -f $Name)
                Set-AuthenticationInfo -Site $Name `
                                       -IisType 'Ftp' `
                                       -AuthenticationInfo $DefaultAuthenticationInfo `
                                       -ErrorAction Stop `
            }

            # Update AuthorizationInfo if required
            if ($PSBoundParameters.ContainsKey('AuthorizationInfo') -and `
                (-not (Test-UniqueFTPAuthorization -Site $Name `
                                                   -AuthorizationInfo $AuthorizationInfo)))
            {
                Write-Verbose -Message ($LocalizedData.VerboseSetTargetAuthorizationInfoUpdated `
                                        -f $Name)
                Set-FTPAuthorization -AuthorizationInfo $AuthorizationInfo `
                                     -Site $Name 
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

            # Update SslInfo if required
            if ($PSBoundParameters.ContainsKey('SslInfo') -and `
                (-not (Confirm-UniqueSslInfo -Name $Name -SslInfo $SslInfo)))
            { 
                Write-Verbose -Message ($LocalizedData.VerboseSetTargetUpdateSslInfo `
                                         -f $Name)
                Set-SslInfo -Site $Name -SslInfo $SslInfo
            }

            # Update LogFlags if required
            if ($PSBoundParameters.ContainsKey('LogFlags') -and `
                (-not (Compare-LogFlags -Name $Name -LogFlags $LogFlags)))
            {
                Write-Verbose -Message ($LocalizedData.VerboseSetTargetUpdateLogFlags `
                                        -f $Name)
                Set-ItemProperty -Path "IIS:\Sites\$Name" `
                                 -Name ftpserver.logFile.logExtFileFlags `
                                 -Value ($LogFlags -join ',')
            }

            # Update LogPath if required
            if ($PSBoundParameters.ContainsKey('LogPath') -and `
                ($LogPath -ne $ftpSite.ftpserver.file.directory))
            {

                Write-Verbose -Message ($LocalizedData.VerboseSetTargetUpdateLogPath `
                                        -f $Name)
                Set-ItemProperty -Path "IIS:\Sites\$Name" `
                                 -Name ftpserver.logFile.directory `
                                 -Value $LogPath
            }

            # Update LogPeriod if needed
            if ($PSBoundParameters.ContainsKey('LogPeriod') -and `
                ($LogPeriod -ne $ftpSite.ftpserver.file.LogPeriod))
            {
                if ($PSBoundParameters.ContainsKey('LogTruncateSize'))
                    {
                        Write-Verbose -Message ($LocalizedData.WarningLogPeriod `
                                                -f $Name)
                    }

                Write-Verbose -Message ($LocalizedData.VerboseSetTargetUpdateLogPeriod `
                                        -f $name)
                Set-ItemProperty -Path "IIS:\Sites\$Name" `
                                 -Name ftpserver.logFile.period `
                                 -Value $LogPeriod
            }

            # Update LogPeriod if needed
            if ($PSBoundParameters.ContainsKey('LogPeriod') -and `
                ($LogPeriod -ne $ftpSite.ftpserver.file.period))
            {
                if ($PSBoundParameters.ContainsKey('LogTruncateSize'))
                    {
                        Write-Verbose -Message ($LocalizedData.WarningLogPeriod `
                                                -f $Name)
                    }

                Write-Verbose -Message ($LocalizedData.VerboseSetTargetUpdateLogPeriod `
                                        -f $name)
                Set-ItemProperty -Path "IIS:\Sites\$Name" `
                                 -Name ftpserver.logFile.period `
                                 -Value $LogPeriod
            }

            # Update LogTruncateSize if needed
            if ($PSBoundParameters.ContainsKey('LogTruncateSize') -and `
                ($LogTruncateSize -ne $ftpSite.ftpserver.file.TruncateSize))
            {
                Write-Verbose -Message ($LocalizedData.VerboseSetTargetUpdateLogTruncateSize `
                                        -f $Name)
                Set-ItemProperty -Path "IIS:\Sites\$Name" `
                                 -Name ftpserver.logFile.truncateSize `
                                 -Value $LogTruncateSize
                Set-ItemProperty -Path "IIS:\Sites\$Name" `
                                 -Name ftpserver.logFile.period `
                                 -Value 'MaxSize'
            }

            # Update LoglocalTimeRollover if neeed
            if ($PSBoundParameters.ContainsKey('LoglocalTimeRollover') -and `
                ($LoglocalTimeRollover -ne `
                 ([System.Convert]::ToBoolean($ftpSite.ftpserver.file.localTimeRollover))))
            {
                Write-Verbose -Message ($LocalizedData.VerboseSetTargetUpdateLoglocalTimeRollover `
                                        -f $Name)
                Set-ItemProperty -Path "IIS:\Sites\$Name" `
                                 -Name ftpserver.logFile.localTimeRollover `
                                 -Value $LoglocalTimeRollover
            }

            # Update DirectoryBrowse if required
            if ($PSBoundParameters.ContainsKey('DirectoryBrowseFlags') -and `
                (-not (Compare-DirectoryBrowseFlags -Name $Name `
                                                    -DirectoryBrowseFlags $DirectoryBrowseFlags)))
            {
                Write-Verbose -Message ($LocalizedData.VerboseSetTargetUpdateDirectoryBrowseFlags `
                                        -f $Name)
                Set-ItemProperty -Path "IIS:\Sites\$Name" `
                                 -Name ftpserver.directoryBrowse.showFlags `
                                 -Value ($DirectoryBrowseFlags -join ',')
            }

            # Update UserIsolation if required
            if ($PSBoundParameters.ContainsKey('UserIsolation') -and `
                ($UserIsolation -ne $ftpSite.ftpServer.userIsolation.mode))
            {

                Write-Verbose -Message ($LocalizedData.VerboseSetTargetUpdateUserIsolation `
                                        -f $Name)
                Set-ItemProperty -Path "IIS:\Sites\$Name" `
                                 -Name ftpServer.userIsolation.mode `
                                 -Value $UserIsolation
            }
        }

        else # Create ftpSite if it does not exist
        {
            if ([string]::IsNullOrEmpty($PhysicalPath)) {
                throw 'The PhysicalPath Parameter must be provided for a ftpSite to be created'
            }

            try
            {
                $PSBoundParameters.GetEnumerator() |
                Where-Object -FilterScript {
                    $_.Key -in (Get-Command -Name New-WebftpSite `
                                            -Module WebAdministration).Parameters.Keys
                } |
                ForEach-Object -Begin {
                    $NewftpSiteSplat = @{}
                } -Process {
                    $NewftpSiteSplat.Add($_.Key, $_.Value)
                }

                <# 
                    If there are no other ftpSites, specify the Id Parameter for the new 
                    ftpSite. Otherwise an error can occur on systems running 
                    Windows Server 2008 R2.
                #>
                if (-not (Get-Website))
                {
                    $NewftpSiteSplat.Add('Id', 1)
                }

                # Set default port to FTP:21 else it will be HTTP:80
                if(-not(($PSBoundParameters.ContainsKey('BindingIfo'))))
                {
                    $NewftpSiteSplat.Add('Port', 21)
                }

                $ftpSite = New-WebftpSite @NewftpSiteSplat -ErrorAction Stop
                Write-Verbose -Message ($LocalizedData.VerboseSetTargetftpSiteCreated `
                                        -f $Name)
            }
            catch
            {
                $errorMessage = $LocalizedData.ErrorftpSiteCreationFailure `
                                -f $Name, $_.Exception.Message
                New-TerminatingError -ErrorId 'ftpSiteCreationFailure' `
                                     -ErrorMessage $errorMessage `
                                     -ErrorCategory 'InvalidOperation'
            }

            # Update Application Pool if required
            if ($PSBoundParameters.ContainsKey('ApplicationPool') -and `
                $ftpSite.ApplicationPool -ne $ApplicationPool)
            {
                Set-ItemProperty -Path "IIS:\Sites\$Name" `
                                 -Name applicationPool `
                                 -Value $ApplicationPool `
                                 -ErrorAction Stop
                Write-Verbose -Message ($LocalizedData.VerboseSetTargetUpdatedApplicationPool `
                                        -f $Name, $ApplicationPool)
            }
            
            <#
             Update Authentication if required; 
             if not defined then pass in DefaultAuthenticationInfo
            #>
            if ($PSBoundParameters.ContainsKey('AuthenticationInfo') -and `
                (-not (Test-AuthenticationInfo -Site $Name `
                                               -IisType 'Ftp' `
                                               -AuthenticationInfo $AuthenticationInfo)))
            {
                Set-AuthenticationInfo -Site $Name `
                                       -IisType 'Ftp' `
                                       -AuthenticationInfo $AuthenticationInfo `
                                       -ErrorAction Stop
                Write-Verbose -Message ($LocalizedData.VerboseSetTargetAuthenticationInfoUpdated `
                                        -f $Name)
            }
            
            $DefaultAuthenticationInfo = Get-DefaultAuthenticationInfo -IisType 'Ftp'
            if ($null -eq $PSBoundParameters.ContainsKey('AuthenticationInfo') -and `
                 (-not (Test-AuthenticationInfo `
                        -Site $Name `
                        -IisType 'Ftp' `
                        -AuthenticationInfo $DefaultAuthenticationInfo)))
            {
                $AuthenticationInfo = Get-DefaultAuthenticationInfo -IisType 'Ftp'
                Write-Verbose -Message ($LocalizedData.VerboseSetTargetAuthenticationInfo `
                                        -f $Name)
                Set-AuthenticationInfo -Site $Name `
                                       -IisType 'Ftp' `
                                       -AuthenticationInfo $DefaultAuthenticationInfo `
                                       -ErrorAction Stop `
            }

            # Update AuthorizationInfo if required
            if ($PSBoundParameters.ContainsKey('AuthorizationInfo') -and `
                (-not (Test-UniqueFTPAuthorization -Site $Name `
                                                   -AuthorizationInfo $AuthorizationInfo)))
            {
                Write-Verbose -Message ($LocalizedData.VerboseSetTargetAuthorizationInfoUpdated `
                                            -f $Name)
                Set-FTPAuthorization -AuthorizationInfo $AuthorizationInfo `
                                     -Site $Name 
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

            # Update SslInfo if required
            if ($PSBoundParameters.ContainsKey('SslInfo') -and `
                (-not (Confirm-UniqueSslInfo -Name $Name `
                                             -SslInfo $SslInfo)))
            { 
                Write-Verbose -Message ($LocalizedData.VerboseSetTargetUpdateSslInfo `
                                        -f $name)
                Set-SslInfo -Site $Name -SslInfo $SslInfo
            }

            # Update LogFlags if required
            if ($PSBoundParameters.ContainsKey('LogFlags') -and `
                (-not (Compare-LogFlags -Name $Name `
                                        -LogFlags $LogFlags)))
            {
                Write-Verbose -Message ($LocalizedData.VerboseSetTargetUpdateLogFlags `
                                        -f $Name)
                Set-ItemProperty -Path "IIS:\Sites\$Name" `
                                 -Name ftpserver.logFile.logExtFileFlags `
                                 -Value ($LogFlags -join ',')
            }
            
            # Update LogPath if required
            if ($PSBoundParameters.ContainsKey('LogPath') -and `
                ($LogPath -ne $ftpSite.ftpserver.file.directory))
            {

                Write-Verbose -Message ($LocalizedData.VerboseSetTargetUpdateLogPath `
                                        -f $Name)
                Set-ItemProperty -Path "IIS:\Sites\$Name" `
                                 -Name ftpserver.logFile.directory `
                                 -Value $LogPath
            }

            # Update LogPeriod if needed
            if ($PSBoundParameters.ContainsKey('LogPeriod') -and `
                ($LogPeriod -ne $ftpSite.ftpserver.file.LogPeriod))
            {
                if ($PSBoundParameters.ContainsKey('LogTruncateSize'))
                    {
                        Write-Verbose -Message ($LocalizedData.WarningLogPeriod `
                                                -f $Name)
                    }

                Write-Verbose -Message ($LocalizedData.VerboseSetTargetUpdateLogPeriod `
                                        -f $name)
                Set-ItemProperty -Path "IIS:\Sites\$Name" `
                                 -Name ftpserver.logFile.period `
                                 -Value $LogPeriod
            }

            # Update LogTruncateSize if needed
            if ($PSBoundParameters.ContainsKey('LogTruncateSize') -and `
                ($LogTruncateSize -ne $ftpSite.ftpserver.file.TruncateSize))
            {
                Write-Verbose -Message ($LocalizedData.VerboseSetTargetUpdateLogTruncateSize `
                                        -f $Name)
                Set-ItemProperty -Path "IIS:\Sites\$Name" `
                                 -Name ftpserver.logFile.truncateSize `
                                 -Value $LogTruncateSize
                Set-ItemProperty -Path "IIS:\Sites\$Name" `
                                 -Name ftpserver.logFile.period `
                                 -Value 'MaxSize'
            }

            # Update LoglocalTimeRollover if neeed
            if ($PSBoundParameters.ContainsKey('LoglocalTimeRollover') -and `
                ($LoglocalTimeRollover -ne `
                 ([System.Convert]::ToBoolean($ftpSite.ftpserver.file.LoglocalTimeRollover))))
            {
                Write-Verbose -Message ($LocalizedData.VerboseSetTargetUpdateLoglocalTimeRollover `
                                        -f $Name)
                Set-ItemProperty -Path "IIS:\Sites\$Name" `
                                 -Name ftpserver.logFile.localTimeRollover `
                                 -Value $LoglocalTimeRollover
            }

            # Update DirectoryBrowse if required
            if ($PSBoundParameters.ContainsKey('DirectoryBrowseFlags') -and `
                (-not (Compare-DirectoryBrowseFlags -Name $Name `
                                                    -DirectoryBrowseFlags $DirectoryBrowseFlags)))
            {
                Write-Verbose -Message ($LocalizedData.VerboseSetTargetUpdateDirectoryBrowseFlags `
                                        -f $Name)
                Set-ItemProperty -Path "IIS:\Sites\$Name" `
                                 -Name ftpserver.directoryBrowse.showFlags `
                                 -Value ($DirectoryBrowseFlags -join ',')
            }

            # Update UserIsolation if required
            if ($PSBoundParameters.ContainsKey('UserIsolation') -and `
                ($UserIsolation -ne $ftpSite.ftpServer.userIsolation.mode))
            {

                Write-Verbose -Message ($LocalizedData.VerboseSetTargetUpdateUserIsolation `
                                        -f $Name)
                Set-ItemProperty -Path "IIS:\Sites\$Name" `
                                 -Name ftpServer.userIsolation.mode `
                                 -Value $UserIsolation
            }
        }
    }
    else # Remove ftpSite
    {
        try
        {
            Remove-Website -Name $Name -ErrorAction Stop
            Write-Verbose -Message ($LocalizedData.VerboseSetTargetftpSiteRemoved `
                                    -f $Name)
        }
        catch
        {
            $errorMessage = $LocalizedData.ErrorftpSiteRemovalFailure `
                            -f $Name, $_.Exception.Message
            New-TerminatingError -ErrorId 'ftpSiteRemovalFailure' `
                                 -ErrorMessage $errorMessage `
                                 -ErrorCategory 'InvalidOperation'
        }
    }
}

<#
.SYNOPSYS
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
        [String] $Ensure = 'Present',

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String] $Name,

        [ValidateNotNullOrEmpty()]
        [String] $PhysicalPath,

        [ValidateSet('Started', 'Stopped')]
        [String] $State = 'Started',

        # The application pool name must contain between 1 and 64 characters
        [ValidateLength(1, 64)] 
        [String] $ApplicationPool,

        [Microsoft.Management.Infrastructure.CimInstance] $AuthenticationInfo,

        [Microsoft.Management.Infrastructure.CimInstance[]] $AuthorizationInfo,

        [Microsoft.Management.Infrastructure.CimInstance] $SslInfo,

        [Microsoft.Management.Infrastructure.CimInstance[]] $BindingInfo,

        [ValidateSet('Date','Time','ClientIP','UserName','ServerIP','Method','UriStem','UriQuery','HttpStatus','Win32Status','TimeTaken','ServerPort','UserAgent','Referer','HttpSubStatus')]
        [String[]] $LogFlags,

        [String] $LogPath,

        [ValidateSet('Hourly','Daily','Weekly','Monthly','MaxSize')]
        [String] $LogPeriod,

        [ValidateRange('1048576','4294967295')]
        [String] $LogTruncateSize,

        [Boolean] $LoglocalTimeRollover,

        [ValidateSet('StyleUnix','LongDate','DisplayAvailableBytes','DisplayVirtualDirectories')]
        [String[]] $DirectoryBrowseFlags,

        [ValidateSet('None','StartInUsersDirectory','IsolateAllDirectories','IsolateRootDirectoryOnly')]
        [String] $UserIsolation
    )

    Assert-Module

    $InDesiredState = $true

    $ftpSite = Get-Website | Where-Object -FilterScript {$_.Name -eq $Name}
    
    # Check Ensure
    if (($Ensure -eq 'Present' -and $null -eq $ftpSite) -or `
        ($Ensure -eq 'Absent' -and $null -ne $ftpSite))
    {
        $InDesiredState = $false
        Write-Verbose -Message ($LocalizedData.VerboseTestTargetFalseEnsure `
                                -f $Name)
    }

    # Only check properties if website exists
    if ($Ensure -eq 'Present' -and `
        $null -ne $ftpSite)
    {
        # Check Physical Path property
        if ([string]::IsNullOrEmpty($PhysicalPath) -eq $false -and `
            $ftpSite.PhysicalPath -ne $PhysicalPath)
        {
            $InDesiredState = $false
            Write-Verbose -Message ($LocalizedData.VerboseTestTargetFalsePhysicalPath `
                                    -f $Name)
        }

        # Check State
        if ($PSBoundParameters.ContainsKey('State') -and $ftpSite.State -ne $State)
        {
            $InDesiredState = $false
            Write-Verbose -Message ($LocalizedData.VerboseTestTargetFalseState `
                                    -f $Name)
        }

        # Check Application Pool property
        if ($PSBoundParameters.ContainsKey('ApplicationPool') -and `
            $ftpSite.ApplicationPool -ne $ApplicationPool)
        {
            $InDesiredState = $false
            Write-Verbose -Message ($LocalizedData.VerboseTestTargetFalseApplicationPool `
                                    -f $Name)
        }

        #Check AuthenticationInfo
        if ($PSBoundParameters.ContainsKey('AuthenticationInfo') -and `
            (-not (Test-AuthenticationInfo -Site $Name `
                                           -IisType 'Ftp' `
                                           -AuthenticationInfo $AuthenticationInfo)))
        { 
            $InDesiredState = $false
            Write-Verbose -Message ($LocalizedData.VerboseTestTargetFalseAuthenticationInfo)
        }

        #Check Authorization
        if ($PSBoundParameters.ContainsKey('AuthorizationInfo') -and `
            (-not (Test-UniqueFTPAuthorization -Site $Name `
                                               -AuthorizationInfo $AuthorizationInfo)))
        { 
            $InDesiredState = $false
            Write-Verbose -Message ($LocalizedData.VerboseTestTargetFalseAuthorizationInfo)
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

        #Check SslInfo
        if ($PSBoundParameters.ContainsKey('SslInfo') -and `
            (-not (Confirm-UniqueSslInfo -Name $Name -SslInfo $SslInfo)))
        { 
            $InDesiredState = $false
            Write-Verbose -Message ($LocalizedData.VerboseTestTargetFalseSslInfo)
        }

        # Check LogFlags
        if ($PSBoundParameters.ContainsKey('LogFlags') -and `
            (-not (Compare-LogFlags -Name $Name -LogFlags $LogFlags)))
        {
            Write-Verbose -Message ($LocalizedData.VerboseTestTargetFalseLogFlags -f $Name)
            return $false
        }

        # Check LogPath
        if ($PSBoundParameters.ContainsKey('LogPath') -and `
            ($LogPath -ne $ftpSite.ftpserver.file.directory))
        {
            Write-Verbose -Message ($LocalizedData.VerboseTestTargetFalseLogPath `
                                    -f $Name)
            return $false
        }

        # Check LogPeriod
        if ($PSBoundParameters.ContainsKey('LogPeriod') -and `
            ($LogPeriod -ne $ftpSite.ftpserver.file.Period))
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
            ($LogTruncateSize -ne $ftpSite.ftpserver.file.LogTruncateSize))
        {
            Write-Verbose -Message ($LocalizedData.VerboseTestTargetFalseLogTruncateSize `
                                    -f $Name)
            return $false
        }

        # Check LoglocalTimeRollover
        if ($PSBoundParameters.ContainsKey('LoglocalTimeRollover') -and `
            ($LoglocalTimeRollover -ne `
            ([System.Convert]::ToBoolean($ftpSite.ftpserver.file.localTimeRollover))))
        {
            Write-Verbose -Message ($LocalizedData.VerboseTestTargetFalseLoglocalTimeRollover `
                                    -f $Name)
            return $false
        }

        # Check DirectoryBrowseFlags
        if ($PSBoundParameters.ContainsKey('DirectoryBrowseFlags') -and `
            (-not (Compare-DirectoryBrowseFlags -Name $Name `
                                                -DirectoryBrowseFlags $DirectoryBrowseFlags)))
        {
            Write-Verbose -Message ($LocalizedData.VerboseTestTargetFalseDirectoryBrowseFlags)
            return $false
        }

        # Check UserIsolation
        if ($PSBoundParameters.ContainsKey('UserIsolation') -and `
            ($UserIsolation -ne $ftpSite.ftpServer.userIsolation.mode))
        {

            Write-Verbose -Message ($LocalizedData.VerboseTestTargetFalseUserIsolation `
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

# region Helper Functions

<#
.SYNOPSIS
    Helper function used to validate that the DirectoryBrowse status.
    Returns False if the DirectoryBrowseflags do not match and true if they do
.PARAMETER LogFlags
    Specifies flags to check
.PARAMETER Name
    Specifies website to check the flags on
#>
function Compare-DirectoryBrowseFlags
{

    [CmdletBinding()]
    [OutputType([Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateSet('StyleUnix','LongDate','DisplayAvailableBytes','DisplayVirtualDirectories')]
        [String[]] $DirectoryBrowseflags,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String] $Name

    )

    $CurrentDirectoryBrowseflags = (Get-Website -Name $Name).ftpServer.directoryBrowse.showFlags `
                                    -split ',' | Sort-Object
    $ProposedDirectoryBrowseflags = $DirectoryBrowseflags `
                                    -split ',' | Sort-Object

    if (Compare-Object -ReferenceObject $CurrentDirectoryBrowseflags `
                       -DifferenceObject $ProposedDirectoryBrowseflags)
    {
        return $false
    }

    return $true

}

<#
.SYNOPSIS
    Helper function used to validate that the AuthorizationInfo is unique to other 
    per CimInstance of MSFT_xFTPAuthorizationInformation
.PARAMETER AuthorizationInfo
    Specifies the CIM of the AuthorizationInfo.
.NOTES
    Compare-Object can be a bit weird so the approach to checking is done slightly
    different in this function.
#>
function Confirm-UniqueFTPAuthorization
{
    [CmdletBinding()]
    [OutputType([Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [String] $Site,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [Microsoft.Management.Infrastructure.CimInstance[]] $AuthorizationInfo
    )

    $currentFtpAuthorization = (get-webconfiguration '/system.ftpServer/security/authorization' `
                                -Location $Site).Collection
    $proposedObject = @(New-Object -TypeName PSObject -Property @{
            accessType  = $AuthorizationInfo.accessType
            users       = $AuthorizationInfo.users
            roles       = $AuthorizationInfo.roles
            permissions = $AuthorizationInfo.permissions
            })

    if($AuthorizationInfo.users)
    {
        $existingFtpAuthorization = $currentFtpAuthorization | `
            Where-Object -Property users -eq -Value $AuthorizationInfo.users | `
            Select-Object accessType,users,roles,permissions

        $existingObject = @(New-Object -TypeName PSObject -Property @{
            accessType  = $existingFtpAuthorization.accessType
            users       = $existingFtpAuthorization.users
            roles       = $existingFtpAuthorization.roles
            permissions = $existingFtpAuthorization.permissions
            })

        if(-not $existingObject)
        {
            return $false
        }

        $compare = Compare-Object -ReferenceObject $($existingObject) `
                                  -DifferenceObject $($proposedObject) `
                                  -Property accessType,users,permissions
        
        if($null -ne $compare)
        {
            return $false 
        }

    }

    if($AuthorizationInfo.roles)
    {
        $existingFtpAuthorization = $currentFtpAuthorization | `
            Where-Object -Property roles -eq -Value $AuthorizationInfo.roles | `
            Select-Object accessType,users,roles,permissions

        $existingObject = @(New-Object -TypeName PSObject -Property @{
            accessType  = $existingFtpAuthorization.accessType
            users       = $existingFtpAuthorization.users
            roles       = $existingFtpAuthorization.roles
            permissions = $existingFtpAuthorization.permissions
            })

        if(-not $existingObject)
        {
            return $false
        }

        $compare = Compare-Object -ReferenceObject $($existingObject) `
                                  -DifferenceObject $($proposedObject) `
                                  -Property accessType,roles,permissions
        
        if($null -ne $compare)
        {
            return $false 
        }
    
    }

    return $true

}

<#
.SYNOPSIS
    Helper function used to validate that the SslInfo is unique
.PARMETER Name
    Specifies the name of the ftpSite.
.PARAMETER AuthorizationInfo
    Specifies the CIM of the SslInfo.
#>
function Confirm-UniqueSslInfo
{
    [CmdletBinding()]
    [OutputType([Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [String] $Name,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [Microsoft.Management.Infrastructure.CimInstance] $SslInfo
    )

    $currentSslInfo = ((Get-Website -Name $Name).ftpServer.security.ssl)

    $proposedObject = @(New-Object -TypeName PSObject -Property @{
            controlChannelPolicy = $SslInfo.controlChannelPolicy
            dataChannelPolicy    = $SslInfo.dataChannelPolicy
            ssl128               = $SslInfo.ssl128
            serverCertHash       = $SslInfo.serverCertHash
            serverCertStoreName  = $SslInfo.serverCertStoreName
    })

    $Store = $($SslInfo).serverCertStoreName
    $Hash  = $($SslInfo).serverCertHash

    if(-not(Test-Path -Path Cert:\LocalMachine\${Store}\${Hash}))
    {
        $errorMessage = $LocalizedData.ErrorServerCertHashFailure `
                        -f $SslInfo.serverCertHash,$SslInfo.serverCertStoreName
        New-TerminatingError -ErrorId 'ErrorServerCertHashFailure' `
                             -ErrorMessage $errorMessage `
                             -ErrorCategory 'InvalidResult'
    }

    $existingObject = $currentSslInfo | `
        Select-Object controlChannelPolicy, `
                      dataChannelPolicy, `
                      ssl128, `
                      serverCertHash, `
                      serverCertStoreName

    $compare = Compare-Object -ReferenceObject $existingObject `
                            -DifferenceObject $proposedObject `
                            -Property controlChannelPolicy, `
                                      dataChannelPolicy, `
                                      ssl128, `
                                      serverCertHash, `
                                      serverCertStoreName
        if($null -ne $compare)
        {
            return $false 
        }

    return $true

}

<#
.SYNOPSIS
    Helper function used to get the AuthorizationInfo for use in Get-TargetResource
.PARAMETER Name
    Specifies the name of the FTP Site.
#>
function Get-AuthorizationInfo
{


    [OutputType([Microsoft.Management.Infrastructure.CimInstance])]
    param
    (
        [CmdletBinding()]
        [Parameter(Mandatory = $true)]
        [String] $Site
    )

    $AuthorizationProperties = @{}
    foreach ($type in @( `
                        'accessType', `
                        'users', `
                        'roles', `
                        'permissions'))
    {
        (get-webconfiguration '/system.ftpServer/security/authorization' `
                                -Location $Site).Collection.${type}
    }

    return New-CimInstance `
            -ClassName MSFT_xFTPAuthorizationInformation `
            -ClientOnly -Property $AuthorizationProperties

}

<#
.SYNOPSIS
    Helper function used to get the SslInfo for use in Get-TargetResource
.PARAMETER Name
    Specifies the name of the FTP Site.
#>
function Get-SslInfo
{
    [OutputType([Microsoft.Management.Infrastructure.CimInstance])]
    param
    (
        [CmdletBinding()]
        [Parameter(Mandatory = $true)]
        [String] $Site
    )

    $sslProperties = @{}
    foreach ($type in @( `
                        'controlChannelPolicy', `
                        'dataChannelPolicy', `
                        'ssl128', `
                        'serverCertHash', `
                        'serverCertStoreName'))
    {
        (Get-Item -Path IIS:\Sites\${Name}\).ftpServer.security.ssl.${type}
    }

    return New-CimInstance `
            -ClassName MSFT_xFTPSslInformation `
            -ClientOnly -Property $sslProperties
        

}

<#
.SYNOPSIS
    Helper function used to set the AuthorizationInfo
.PARAMETER AuthorizationInfo
    Specifies the CIM of the AuthorizationInfo.
.PARAMETER Name
    Specifies the name of the FTP Site.
#>
function Set-FTPAuthorization
{
    [CmdletBinding()]
    [OutputType([Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [String] $Site,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [Microsoft.Management.Infrastructure.CimInstance[]] $AuthorizationInfo
    )

    foreach ($Info in $AuthorizationInfo)
    {
        if(-not(Confirm-UniqueFTPAuthorization -Site $Site -AuthorizationInfo $Info))
        {
            Add-WebConfiguration '/system.ftpServer/security/authorization' `
                                -Value @{
                                        accessType  = $Info.accessType;
                                        roles       = $Info.roles;
                                        permissions = $Info.permissions;
                                        users       = $Info.users
                                    } `
                                -PSPath IIS:\ `
                                -Location $Name
        }
    }
}

<#
.SYNOPSIS
    Helper function used to set the SslInfo
.PARAMETER AuthorizationInfo
    Specifies the CIM of the SslInfo.
.PARAMETER Name
    Specifies the name of the FTP Site.
#>
function Set-SslInfo
{


    [CmdletBinding()]
    [OutputType([Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [String] $Site,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [Microsoft.Management.Infrastructure.CimInstance] $SslInfo
    )

    $sslValues = ((($SslInfo) | `
                Get-Member -membertype properties) | `
                Where-Object {$_.Name -ne 'PSComputerName'}).Name

    foreach ($value in $sslValues) 
    {
        switch($value)
        {
            CertificateHash
            {
                $correctValue = 'serverCertHash'
                Set-ItemProperty `
                    -Path "IIS:\Sites\$Name" `
                    -Name "ftpServer.security.ssl.$correctValue" `
                    -Value ($SslInfo.CimInstanceProperties | `
                        Where-Object {$_.Name -eq $value}).Value
            }
            CertificateStoreName
            {
                $correctValue = 'serverCertStoreName'
                Set-ItemProperty `
                    -Path "IIS:\Sites\$Name" `
                    -Name "ftpServer.security.ssl.$correctValue" `
                    -Value ($SslInfo.CimInstanceProperties | `
                        Where-Object {$_.Name -eq $value}).Value
            }
            RequireSsl128
            {
                $correctValue = 'ssl128'
                Set-ItemProperty `
                    -Path "IIS:\Sites\$Name" `
                    -Name "ftpServer.security.ssl.$correctValue" `
                    -Value ($SslInfo.CimInstanceProperties | `
                        Where-Object {$_.Name -eq $value}).Value
            }
            ControlChannelPolicy
            {
                $correctValue = 'controlChannelPolicy'
                Set-ItemProperty `
                    -Path "IIS:\Sites\$Name" `
                    -Name "ftpServer.security.ssl.$correctValue" `
                    -Value ($SslInfo.CimInstanceProperties | `
                        Where-Object {$_.Name -eq $value}).Value
            }
            DataChannelPolicy
            {
                $correctValue = 'dataChannelPolicy'
                Set-ItemProperty `
                    -Path "IIS:\Sites\$Name" `
                    -Name "ftpServer.security.ssl.$correctValue" `
                    -Value ($SslInfo.CimInstanceProperties | `
                        Where-Object {$_.Name -eq $value}).Value
            }
        }
    }
}

<#
.SYNOPSIS
    Helper function used to validate that the AuthorizationInfo is unique overall
.PARAMETER AuthorizationInfo
    Specifies the CIM of the AuthorizationInfo.
#>
function Test-UniqueFTPAuthorization
{
    [CmdletBinding()]
    [OutputType([Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [String] $Site,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [Microsoft.Management.Infrastructure.CimInstance[]] $AuthorizationInfo
    )

    foreach ($Info in $AuthorizationInfo)
    {
        if(-not(Confirm-UniqueFTPAuthorization -Site $Site -AuthorizationInfo $Info))
        {
            return $false
        }
    }

    return $true
}

#endregion

Export-ModuleMember -Function *-TargetResource
