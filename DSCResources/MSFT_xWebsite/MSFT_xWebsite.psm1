#requires -Version 4.0 -Modules CimCmdlets

# Localized messages
data LocalizedData
{
    # culture="en-US"
    ConvertFrom-StringData -StringData @'
    SetTargetResourceInstallWhatIfMessage       = Trying to create website "{0}".
    SetTargetResourceUninstallWhatIfMessage     = Trying to remove website "{0}".
    WebsiteNotFoundError                        = The requested website "{0}" is not found on the target machine.
    WebsiteDiscoveryFailureError                = Failure to get the requested website "{0}" information from the target machine.
    WebsiteCreationFailureError                 = Failure to successfully create the website "{0}".
    WebsiteRemovalFailureError                  = Failure to successfully remove the website "{0}".
    WebsiteUpdateFailureError                   = Failure to successfully update the properties for website "{0}".
    WebsiteBindingUpdateFailureError            = Failure to successfully update the bindings for website "{0}".
    WebsiteBindingInputInvalidationError        = Desired website bindings are not valid for website "{0}".
    WebsiteCompareFailureError                  = Failure to successfully compare properties for website "{0}".
    WebBindingCertificateError                  = Failure to add certificate to web binding. Please make sure that the certificate thumbprint "{0}" is valid.
    WebsiteStateFailureError                    = Failure to successfully set the state of the website "{0}".
    WebsiteBindingConflictOnStartError          = Website "{0}" could not be started due to binding conflict. Ensure that the binding information for this website does not conflict with any existing website's bindings before trying to start it.
    WebBindingInvalidIPAddressError             = Failure to validate the IPAddress property value "{0}".
    WebBindingInvalidPortError                  = Failure to validate the Port property value "{0}". The port number must be a positive integer between 1 and 65535.
    WebBindingMissingBindingInformationError    = The BindingInformation property is required for bindings of type "{0}".
    WebBindingMissingCertificateThumbprintError = The CertificateThumbprint property is required for bindings of type "{0}".
'@
}

function Get-TargetResource
{
    <#
    .SYNOPSYS
        The Get-TargetResource cmdlet is used to fetch the status of role or Website on the target machine.
        It gives the Website info of the requested role/feature on the target machine.
    #>
    [CmdletBinding()]
    [OutputType([Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $Name,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $PhysicalPath
    )

    # Check if WebAdministration module is present for IIS cmdlets
    if (-not (Get-Module -Name WebAdministration -ListAvailable))
    {
        throw 'Please ensure that WebAdministration module is installed.'
    }

    $Website = Get-Website | Where-Object -FilterScript {$_.Name -eq $Name}

    if ($Website.Count -eq 0) # No Website exists with this name
    {
        $EnsureResult = 'Absent'
    }
    elseif ($Website.Count -eq 1) # A single Website exists with this name
    {
        $EnsureResult = 'Present'

        $CimBindings = @(ConvertTo-CimBinding -InputObject $Website.bindings.Collection)

        $AllDefaultPages = @(
            Get-WebConfiguration -Filter '//defaultDocument/files/*' -PSPath "IIS:\Sites\$Name" |
            ForEach-Object -Process {Write-Output -InputObject $_.value}
        )
    }
    else # Multiple websites with the same name exist. This is not supported and is an error
    {
        $ErrorId = 'WebsiteDiscoveryFailure'
        $ErrorCategory = [System.Management.Automation.ErrorCategory]::InvalidResult
        $ErrorMessage = $($LocalizedData.WebsiteDiscoveryFailureError) -f $Name
        $Exception = New-Object -TypeName System.InvalidOperationException -ArgumentList $ErrorMessage
        $ErrorRecord = New-Object -TypeName System.Management.Automation.ErrorRecord -ArgumentList $Exception, $ErrorId, $ErrorCategory, $null

        $PSCmdlet.ThrowTerminatingError($ErrorRecord)
    }

    # Add all website properties to the hash table
    return @{
        Ensure           = $EnsureResult
        Name             = $Name
        PhysicalPath     = $Website.PhysicalPath
        State            = $Website.State
        ApplicationPool  = $Website.ApplicationPool
        BindingInfo      = $CimBindings
        DefaultPage      = $AllDefaultPages
        EnabledProtocols = $Website.EnabledProtocols
        Id               = $Website.Id
    }
}

function Set-TargetResource
{
    <#
    .SYNOPSYS
        The Set-TargetResource cmdlet is used to create, delete or configure a website on the target machine.
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    param
    (
        [ValidateSet('Present', 'Absent')]
        [String]
        $Ensure = 'Present',

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $Name,

        [Parameter(Mandatory = $true)]
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
        $EnabledProtocols
    )

    # Check if WebAdministration module is present for IIS cmdlets
    if (-not (Get-Module -Name WebAdministration -ListAvailable))
    {
        throw 'Please ensure that WebAdministration module is installed.'
    }

    $Website = Get-Website | Where-Object -FilterScript {$_.Name -eq $Name}

    if ($Ensure -eq 'Present')
    {
        if ($Website -ne $null)
        {
            # Update Physical Path if required
            if ($Website.PhysicalPath -ne $PhysicalPath)
            {
                Set-ItemProperty -Path "IIS:\Sites\$Name" -Name physicalPath -Value $PhysicalPath -ErrorAction Stop

                Write-Verbose -Message "Physical Path for website '$Name' has been updated to '$PhysicalPath'."
            }

            # Update Application Pool if required
            if ($PSBoundParameters.ContainsKey('ApplicationPool') -and $Website.ApplicationPool -ne $ApplicationPool)
            {
                Set-ItemProperty -Path "IIS:\Sites\$Name" -Name applicationPool -Value $ApplicationPool -ErrorAction Stop

                Write-Verbose -Message "Application Pool for website '$Name' has been updated to '$ApplicationPool'."
            }

            # Update Bindings if required
            if ($PSBoundParameters.ContainsKey('BindingInfo') -and $BindingInfo -ne $null)
            {
                if (-not (Test-WebsiteBinding -Name $Name -BindingInfo $BindingInfo))
                {
                    Update-WebsiteBinding -Name $Name -BindingInfo $BindingInfo

                    Write-Verbose -Message "Bindings for website '$Name' have been updated."
                }
            }

            # Update Enabled Protocols if required
            if ($PSBoundParameters.ContainsKey('EnabledProtocols') -and $Website.EnabledProtocols -ne $EnabledProtocols)
            {
                Set-ItemProperty -Path "IIS:\Sites\$Name" -Name enabledProtocols -Value $EnabledProtocols -ErrorAction Stop

                Write-Verbose -Message "Enabled Protocols for website '$Name' has been updated to '$EnabledProtocols'."
            }

            # Update Default pages if required
            if ($PSBoundParameters.ContainsKey('DefaultPage') -and $DefaultPage -ne $null)
            {
                Update-DefaultPage -Name $Name -DefaultPage $DefaultPage
            }

            # Update State if required
            if ($PSBoundParameters.ContainsKey('State') -and $Website.State -ne $State)
            {
                if ($State -eq 'Started')
                {
                    # Ensure that there are no other websites with binding information that will conflict with this site before starting
                    if (-not (Confirm-UniqueBinding -BindingInfo $BindingInfo -ExcludeSite $Name))
                    {
                        # Return error and do not start Website
                        $ErrorId = 'WebsiteBindingConflictOnStart'
                        $ErrorCategory = [System.Management.Automation.ErrorCategory]::InvalidResult
                        $ErrorMessage = $($LocalizedData.WebsiteBindingConflictOnStartError) -f $Name
                        $Exception = New-Object -TypeName System.InvalidOperationException -ArgumentList $ErrorMessage
                        $ErrorRecord = New-Object -TypeName System.Management.Automation.ErrorRecord -ArgumentList $Exception, $ErrorId, $ErrorCategory, $null

                        $PSCmdlet.ThrowTerminatingError($ErrorRecord)
                    }

                    try
                    {
                        Start-Website -Name $Name -ErrorAction Stop
                    }
                    catch
                    {
                        $ErrorId = 'WebsiteStateFailure'
                        $ErrorCategory = [System.Management.Automation.ErrorCategory]::InvalidOperation
                        $ErrorMessage = $($LocalizedData.WebsiteStateFailureError) -f $Name
                        $ErrorMessage += ' {0}' -f $_.Exception.Message
                        $Exception = New-Object -TypeName System.InvalidOperationException -ArgumentList $ErrorMessage
                        $ErrorRecord = New-Object -TypeName System.Management.Automation.ErrorRecord -ArgumentList $Exception, $ErrorId, $ErrorCategory, $null

                        $PSCmdlet.ThrowTerminatingError($ErrorRecord)
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
                        $ErrorId = 'WebsiteStateFailure'
                        $ErrorCategory = [System.Management.Automation.ErrorCategory]::InvalidOperation
                        $ErrorMessage = $($LocalizedData.WebsiteStateFailureError) -f $Name
                        $ErrorMessage += ' {0}' -f $_.Exception.Message
                        $Exception = New-Object -TypeName System.InvalidOperationException -ArgumentList $ErrorMessage
                        $ErrorRecord = New-Object -TypeName System.Management.Automation.ErrorRecord -ArgumentList $Exception, $ErrorId, $ErrorCategory, $null

                        $PSCmdlet.ThrowTerminatingError($ErrorRecord)
                    }
                }

                Write-Verbose -Message "State for website '$Name' has been updated to '$State'."
            }
        }
        else # Create website if it does not exist
        {
            try
            {
                $PSBoundParameters.GetEnumerator() |
                Where-Object -FilterScript {
                    $_.Key -in (Get-Command -Name New-Website -Module WebAdministration).Parameters.Keys
                } |
                ForEach-Object -Begin {
                    $NewWebsiteSplat = @{}
                } -Process {
                    $NewWebsiteSplat.Add($_.Key, $_.Value)
                }

                # If there are no other websites, specify the Id parameter for the new website.
                # Otherwise an error can occur on systems running Windows Server 2008 R2.
                if (-not (Get-Website))
                {
                    $NewWebsiteSplat.Add('Id', 1)
                }

                $Website = New-Website @NewWebsiteSplat -ErrorAction Stop

                Stop-Website -Name $Website.Name -ErrorAction Stop

                # Clear default bindings if new bindings defined and are different
                if ($PSBoundParameters.ContainsKey('BindingInfo') -and $BindingInfo -ne $null)
                {
                    if (-not (Test-WebsiteBinding -Name $Name -BindingInfo $BindingInfo))
                    {
                        Update-WebsiteBinding -Name $Name -BindingInfo $BindingInfo
                    }
                }

                # Set Enabled Protocols if required
                if ($PSBoundParameters.ContainsKey('EnabledProtocols') -and $Website.EnabledProtocols -ne $EnabledProtocols)
                {
                    Set-ItemProperty -Path "IIS:\Sites\$Name" -Name enabledProtocols -Value $EnabledProtocols -ErrorAction Stop
                }

                # Add Default Pages for the newly created website
                if ($PSBoundParameters.ContainsKey('DefaultPage') -and $DefaultPage -ne $null)
                {
                    Update-DefaultPage -Name $Name -DefaultPage $DefaultPage
                }

                Write-Verbose -Message "Successfully created website '$Name'."

                # Start website if required
                if ($State -eq 'Started')
                {
                    # Ensure that there are no other websites with binding information that will conflict with this site before starting
                    if (-not (Confirm-UniqueBinding -BindingInfo $BindingInfo -ExcludeSite $Name))
                    {
                        # Return error and do not start Website
                        $ErrorId = 'WebsiteBindingConflictOnStart'
                        $ErrorCategory = [System.Management.Automation.ErrorCategory]::InvalidResult
                        $ErrorMessage = $($LocalizedData.WebsiteBindingConflictOnStartError) -f $Name
                        $Exception = New-Object -TypeName System.InvalidOperationException -ArgumentList $ErrorMessage
                        $ErrorRecord = New-Object -TypeName System.Management.Automation.ErrorRecord -ArgumentList $Exception, $ErrorId, $ErrorCategory, $null

                        $PSCmdlet.ThrowTerminatingError($ErrorRecord)
                    }

                    try
                    {
                        Start-Website -Name $Name -ErrorAction Stop

                        Write-Verbose -Message "Successfully started website '$Name'."
                    }
                    catch
                    {
                        $ErrorId = 'WebsiteStateFailure'
                        $ErrorCategory = [System.Management.Automation.ErrorCategory]::InvalidOperation
                        $ErrorMessage = $($LocalizedData.WebsiteStateFailureError) -f $Name
                        $ErrorMessage += ' {0}' -f $_.Exception.Message
                        $Exception = New-Object -TypeName System.InvalidOperationException -ArgumentList $ErrorMessage
                        $ErrorRecord = New-Object -TypeName System.Management.Automation.ErrorRecord -ArgumentList $Exception, $ErrorId, $ErrorCategory, $null

                        $PSCmdlet.ThrowTerminatingError($ErrorRecord)
                    }
                }
            }
            catch
            {
                $ErrorId = 'WebsiteCreationFailure'
                $ErrorCategory = [System.Management.Automation.ErrorCategory]::InvalidOperation
                $ErrorMessage = $($LocalizedData.WebsiteCreationFailureError) -f $Name
                $ErrorMessage += ' {0}' -f $_.Exception.Message
                $Exception = New-Object -TypeName System.InvalidOperationException -ArgumentList $ErrorMessage
                $ErrorRecord = New-Object -TypeName System.Management.Automation.ErrorRecord -ArgumentList $Exception, $ErrorId, $ErrorCategory, $null

                $PSCmdlet.ThrowTerminatingError($ErrorRecord)
            }
        }
    }
    elseif ($Ensure -eq 'Absent') # Remove website
    {
        try
        {
            Remove-Website -Name $Name -ErrorAction Stop

            Write-Verbose -Message "Successfully removed website '$Name'."
        }
        catch
        {
            $ErrorId = 'WebsiteRemovalFailure'
            $ErrorCategory = [System.Management.Automation.ErrorCategory]::InvalidOperation
            $ErrorMessage = $($LocalizedData.WebsiteRemovalFailureError) -f $Name
            $ErrorMessage += ' {0}' -f $_.Exception.Message
            $Exception = New-Object -TypeName System.InvalidOperationException -ArgumentList $ErrorMessage
            $ErrorRecord = New-Object -TypeName System.Management.Automation.ErrorRecord -ArgumentList $Exception, $ErrorId, $ErrorCategory, $null

            $PSCmdlet.ThrowTerminatingError($ErrorRecord)
        }
    }
}

function Test-TargetResource
{
    <#
    .SYNOPSYS
        The Test-TargetResource cmdlet is used to validate if the role or feature is in a state as expected in the instance document.
    #>
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

        [Parameter(Mandatory = $true)]
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
        $EnabledProtocols
    )

    $InDesiredState = $true

    # Check if WebAdministration module is present for IIS cmdlets
    if (-not (Get-Module -Name WebAdministration -ListAvailable))
    {
        throw 'Please ensure that WebAdministration module is installed.'
    }

    $Website = Get-Website | Where-Object -FilterScript {$_.Name -eq $Name}

    # Check Ensure
    if (($Ensure -eq 'Present' -and $Website -eq $null) -or ($Ensure -eq 'Absent' -and $Website -ne $null))
    {
        $InDesiredState = $false
        Write-Verbose -Message "The Ensure state for website '$Name' does not match the desired state."
    }

    # Only check properties if website exists
    if ($Ensure -eq 'Present' -and $Website -ne $null)
    {
        # Check Physical Path property
        if ($Website.PhysicalPath -ne $PhysicalPath)
        {
            $InDesiredState = $false
            Write-Verbose -Message "Physical Path of website '$Name' does not match the desired state."
        }

        # Check State
        if ($PSBoundParameters.ContainsKey('State') -and $Website.State -ne $State)
        {
            $InDesiredState = $false
            Write-Verbose -Message "The state of website '$Name' does not match the desired state."
        }

        # Check Application Pool property
        if ($PSBoundParameters.ContainsKey('ApplicationPool') -and $Website.ApplicationPool -ne $ApplicationPool)
        {
            $InDesiredState = $false
            Write-Verbose -Message "Application Pool for website '$Name' does not match the desired state."
        }

        # Check Binding properties
        if ($PSBoundParameters.ContainsKey('BindingInfo') -and $BindingInfo -ne $null)
        {
            if (-not (Test-WebsiteBinding -Name $Name -BindingInfo $BindingInfo))
            {
                $InDesiredState = $false
                Write-Verbose -Message "Bindings for website '$Name' do not match the desired state."
            }
        }

        # Check Enabled Protocols
        if ($PSBoundParameters.ContainsKey('EnabledProtocols') -and $Website.EnabledProtocols -ne $EnabledProtocols)
        {
            $InDesiredState = $false
            Write-Verbose -Message "Enabled Protocols for website '$Name' does not match the desired state."
        }

        # Check Default Pages
        if ($PSBoundParameters.ContainsKey('DefaultPage') -and $DefaultPage -ne $null)
        {
            $AllDefaultPages = @(
                Get-WebConfiguration -Filter '//defaultDocument/files/*' -PSPath "IIS:\Sites\$Name" |
                ForEach-Object -Process {Write-Output -InputObject $_.value}
            )

            foreach ($Page in $DefaultPage)
            {
                if ($AllDefaultPages -inotcontains $Page)
                {
                    $InDesiredState = $false
                    Write-Verbose -Message "Default Page for website '$Name' does not match the desired state."
                }
            }
        }

    }

    if ($InDesiredState -eq $true)
    {
        Write-Verbose -Message "The target resource is already in the desired state. No action is required."
    }
    else
    {
        Write-Verbose -Message "The target resource is not in the desired state."
    }

    return $InDesiredState
}

#region Helper Functions

function Confirm-UniqueBinding
{
    <#
    .SYNOPSIS
        Helper function used to validate that the desired bindings are unique to all websites.
        Returns False if at least one of the bindings is already assigned to another website.
    .PARAMETER Binding
        Specifies the collection of bindings to check.
    .PARAMETER ExcludeSite
        Specifies the name of the website to exclude from processing.
    #>
    [CmdletBinding()]
    [OutputType([Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [Microsoft.Management.Infrastructure.CimInstance[]]
        $BindingInfo,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [String[]]
        $ExcludeSite
    )

    $IsUnique = $true

    # Test standard (HTTP, HTTPS) bindings only
    $ReferenceObject = @(
        $BindingInfo |
        Where-Object -FilterScript {$_.protocol -in @('http', 'https')} |
        ConvertTo-WebBinding -Verbose:$false
    )

    $DifferenceObject = @(
        Get-Website |
        Where-Object -FilterScript {$_.Name -notin @($ExcludeSite)} |
        ForEach-Object -Process {$_.bindings.Collection} |
        Where-Object -FilterScript {$_.protocol -in @('http', 'https')} |
        ConvertTo-WebBinding -Verbose:$false
    )

    $CompareSplat = @{
        ReferenceObject  = $ReferenceObject
        DifferenceObject = $DifferenceObject
        Property         = @('protocol', 'bindingInformation')
        ExcludeDifferent = $true
        IncludeEqual     = $true
    }

    if (Compare-Object @CompareSplat)
    {
        $IsUnique = $false
    }

    return $IsUnique
}

function ConvertTo-CimBinding
{
    <#
    .SYNOPSIS
        Converts IIS <binding> elements to instances of the MSFT_xWebBindingInformation CIM class.
    #>
    [CmdletBinding()]
    [OutputType([Microsoft.Management.Infrastructure.CimInstance])]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [AllowEmptyCollection()]
        [AllowNull()]
        [Object[]]
        $InputObject
    )
    begin
    {
        $CimClassName = 'MSFT_xWebBindingInformation'
        $CimNamespace = 'root/microsoft/Windows/DesiredStateConfiguration'
    }
    process
    {
        foreach ($Binding in $InputObject)
        {
            [Hashtable]$CimProperties = @{
                Protocol           = [String]$Binding.protocol
                BindingInformation = [String]$Binding.bindingInformation
            }

            if ($Binding.Protocol -in @('http', 'https'))
            {
                if ($Binding.bindingInformation -match '^\[(.*?)\]\:(.*?)\:(.*?)$') # Extract IPv6 address
                {
                    $IPAddress = $Matches[1]
                    $Port      = $Matches[2]
                    $HostName  = $Matches[3]
                }
                else
                {
                    $IPAddress, $Port, $HostName = $Binding.bindingInformation -split '\:'
                }

                if ([String]::IsNullOrEmpty($IPAddress))
                {
                    $IPAddress = '*'
                }

                $CimProperties.Add('IPAddress', [String]$IPAddress)
                $CimProperties.Add('Port',      [UInt16]$Port)
                $CimProperties.Add('HostName',  [String]$HostName)
            }
            else
            {
                $CimProperties.Add('IPAddress', [String]::Empty)
                $CimProperties.Add('Port',      [UInt16]::MinValue)
                $CimProperties.Add('HostName',  [String]::Empty)
            }

            if ([Environment]::OSVersion.Version -ge '6.2')
            {
                $CimProperties.Add('SslFlags', [String]$Binding.sslFlags)
            }

            $CimProperties.Add('CertificateThumbprint', [String]$Binding.certificateHash)
            $CimProperties.Add('CertificateStoreName',  [String]$Binding.certificateStoreName)

            New-CimInstance -ClassName $CimClassName -Namespace $CimNamespace -Property $CimProperties -ClientOnly
        }
    }
}

function ConvertTo-WebBinding
{
    <#
    .SYNOPSIS
        Converts instances of the MSFT_xWebBindingInformation CIM class to the IIS <binding> element representation.
    .LINK
        https://www.iis.net/configreference/system.applicationhost/sites/site/bindings/binding
    #>
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [AllowEmptyCollection()]
        [AllowNull()]
        [Object[]]
        $InputObject
    )
    process
    {
        foreach ($Binding in $InputObject)
        {
            $OutputObject = @{
                protocol = $Binding.Protocol
            }

            if ($Binding -is [Microsoft.Management.Infrastructure.CimInstance])
            {
                if ($Binding.Protocol -in @('http', 'https'))
                {
                    if (-not [String]::IsNullOrEmpty($Binding.BindingInformation))
                    {
                        if (-not [String]::IsNullOrEmpty($Binding.IPAddress) -or
                            -not [String]::IsNullOrEmpty($Binding.Port) -or
                            -not [String]::IsNullOrEmpty($Binding.HostName)
                        )
                        {
                            Write-Verbose -Message ("BindingInformation is ignored for bindings of type '$($Binding.Protocol)'" +
                                " in case at least one of the following properties is specified: IPAddress, Port, HostName.")

                            $IsJoinRequired = $true
                        }
                        else
                        {
                            $IsJoinRequired = $false
                        }
                    }
                    else
                    {
                        $IsJoinRequired = $true
                    }

                    # Construct the bindingInformation attribute
                    if ($IsJoinRequired -eq $true)
                    {
                        try
                        {
                            $IPAddressString = Format-IPAddressString -InputString $Binding.IPAddress -ErrorAction Stop
                        }
                        catch
                        {
                            $ErrorId = 'WebBindingInvalidIPAddressError'
                            $ErrorCategory = [System.Management.Automation.ErrorCategory]::InvalidResult
                            $ErrorMessage = $($LocalizedData.WebBindingInvalidIPAddressError) -f $Binding.IPAddress
                            $ErrorMessage += ' {0}' -f $_.Exception.Message
                            $Exception = New-Object -TypeName System.InvalidOperationException -ArgumentList $ErrorMessage
                            $ErrorRecord = New-Object -TypeName System.Management.Automation.ErrorRecord -ArgumentList $Exception, $ErrorId, $ErrorCategory, $null

                            $PSCmdlet.ThrowTerminatingError($ErrorRecord)
                        }

                        if ([String]::IsNullOrEmpty($Binding.Port))
                        {
                            switch ($Binding.Protocol)
                            {
                                'http'  {$PortNumberString = '80'}
                                'https' {$PortNumberString = '443'}
                            }

                            Write-Verbose -Message "Port is not specified. The default '$($Binding.Protocol)' port '$PortNumberString' will be used."
                        }
                        else
                        {
                            if (Test-PortNumber -InputString $Binding.Port)
                            {
                                $PortNumberString = $Binding.Port
                            }
                            else
                            {
                                $ErrorId = 'WebBindingInvalidPortError'
                                $ErrorCategory = [System.Management.Automation.ErrorCategory]::InvalidResult
                                $ErrorMessage = $($LocalizedData.WebBindingInvalidPortError) -f $Binding.Port
                                $Exception = New-Object -TypeName System.InvalidOperationException -ArgumentList $ErrorMessage
                                $ErrorRecord = New-Object -TypeName System.Management.Automation.ErrorRecord -ArgumentList $Exception, $ErrorId, $ErrorCategory, $null

                                $PSCmdlet.ThrowTerminatingError($ErrorRecord)
                            }
                        }

                        $BindingInformation = $IPAddressString, $PortNumberString, $Binding.HostName -join ':'
                        $OutputObject.Add('bindingInformation', [String]$BindingInformation)
                    }
                    else
                    {
                        $OutputObject.Add('bindingInformation', [String]$Binding.BindingInformation)
                    }
                }
                else
                {
                    if ([String]::IsNullOrEmpty($Binding.BindingInformation))
                    {
                        $ErrorId = 'WebBindingMissingBindingInformation'
                        $ErrorCategory = [System.Management.Automation.ErrorCategory]::InvalidResult
                        $ErrorMessage = $($LocalizedData.WebBindingMissingBindingInformationError) -f $Binding.Protocol
                        $Exception = New-Object -TypeName System.InvalidOperationException -ArgumentList $ErrorMessage
                        $ErrorRecord = New-Object -TypeName System.Management.Automation.ErrorRecord -ArgumentList $Exception, $ErrorId, $ErrorCategory, $null

                        $PSCmdlet.ThrowTerminatingError($ErrorRecord)
                    }
                    else
                    {
                        $OutputObject.Add('bindingInformation', [String]$Binding.BindingInformation)
                    }
                }

                # SSL-related properties
                if ($Binding.Protocol -eq 'https')
                {
                    if ([String]::IsNullOrEmpty($Binding.CertificateThumbprint))
                    {
                        $ErrorId = 'WebBindingMissingCertificateThumbprint'
                        $ErrorCategory = [System.Management.Automation.ErrorCategory]::InvalidResult
                        $ErrorMessage = $($LocalizedData.WebBindingMissingCertificateThumbprintError) -f $Binding.Protocol
                        $Exception = New-Object -TypeName System.InvalidOperationException -ArgumentList $ErrorMessage
                        $ErrorRecord = New-Object -TypeName System.Management.Automation.ErrorRecord -ArgumentList $Exception, $ErrorId, $ErrorCategory, $null

                        $PSCmdlet.ThrowTerminatingError($ErrorRecord)
                    }

                    if ([String]::IsNullOrEmpty($Binding.CertificateStoreName))
                    {
                        $CertificateStoreName = 'MY'

                        Write-Verbose -Message "CertificateStoreName is not specified. The default value '$CertificateStoreName' will be used."
                    }
                    else
                    {
                        $CertificateStoreName = $Binding.CertificateStoreName
                    }

                    $OutputObject.Add('certificateHash',      [String]$Binding.CertificateThumbprint)
                    $OutputObject.Add('certificateStoreName', [String]$CertificateStoreName)

                    if ([Environment]::OSVersion.Version -ge '6.2')
                    {
                        $OutputObject.Add('sslFlags', [Int64]$Binding.SslFlags)
                    }
                }
                else
                {
                    # Ignore SSL-related properties for non-SSL bindings
                    $OutputObject.Add('certificateHash',      [String]::Empty)
                    $OutputObject.Add('certificateStoreName', [String]::Empty)

                    if ([Environment]::OSVersion.Version -ge '6.2')
                    {
                        $OutputObject.Add('sslFlags', [Int64]0)
                    }
                }
            }
            else
            {
                <#
                    WebAdministration can throw the following exception if there are non-standard bindings (e.g. 'net.tcp'):
                    'The data is invalid. (Exception from HRESULT: 0x8007000D)'

                    Steps to reproduce:
                    1) Add 'net.tcp' binding
                    2) Execute {Get-Website | ForEach-Object {$_.bindings.Collection} | Select-Object *}

                    Workaround is to create a new custom object and use dot notation to access binding properties.
                #>

                $OutputObject.Add('bindingInformation',   [String]$Binding.bindingInformation)
                $OutputObject.Add('certificateHash',      [String]$Binding.certificateHash)
                $OutputObject.Add('certificateStoreName', [String]$Binding.certificateStoreName)

                if ([Environment]::OSVersion.Version -ge '6.2')
                {
                    $OutputObject.Add('sslFlags', [Int64]$Binding.sslFlags)
                }
            }

            Write-Output -InputObject ([PSCustomObject]$OutputObject)
        }
    }
}

function Format-IPAddressString
{
    <#
    .SYNOPSYS
        Formats the input IP address string for use in the bindingInformation attribute.
    #>
    [CmdletBinding()]
    [OutputType([String])]
    param
    (
        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [AllowNull()]
        [String]
        $InputString
    )

    if ([String]::IsNullOrEmpty($InputString) -or $InputString -eq '*')
    {
        $OutputString = '*'
    }
    else
    {
        try
        {
            $IPAddress = [IPAddress]::Parse($InputString)

            switch ($IPAddress.AddressFamily)
            {
                'InterNetwork'
                {
                    $OutputString = $IPAddress.IPAddressToString
                }
                'InterNetworkV6'
                {
                    $OutputString = '[{0}]' -f $IPAddress.IPAddressToString
                }
            }
        }
        catch
        {
            throw $_.Exception.Message
        }
    }

    return $OutputString
}

function Test-BindingInfo
{
    <#
    .SYNOPSYS
        Validates the desired binding information (i.e. no duplicate IP address, port, and host name combinations).
    #>
    [CmdletBinding()]
    [OutputType([Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [Microsoft.Management.Infrastructure.CimInstance[]]
        $BindingInfo
    )

    $IsValid = $true

    try
    {
        # Normalize the input (helper functions will perform additional validations)
        $Bindings = @(ConvertTo-WebBinding -InputObject $BindingInfo | ConvertTo-CimBinding)
        $StandardBindings = @($Bindings | Where-Object -FilterScript {$_.Protocol -in @('http', 'https')})
        $NonStandardBindings = @($Bindings | Where-Object -FilterScript {$_.Protocol -notin @('http', 'https')})

        if ($StandardBindings.Count -ne 0)
        {
            # IP address, port, and host name combination must be unique
            if (($StandardBindings | Group-Object -Property IPAddress, Port, HostName) | Where-Object -FilterScript {$_.Count -ne 1})
            {
                Write-Verbose -Message "BindingInfo contains multiple items with the same IPAddress, Port, and HostName combination."
                $IsValid = $false
            }

            # A single port can only be used by a single binding, regardless of the protocol used
            if (($StandardBindings | Group-Object -Property Port) | Where-Object -FilterScript {$_.Count -ne 1})
            {
                Write-Verbose -Message "BindingInfo contains multiple items with the same Port."
                $IsValid = $false
            }
        }

        if ($NonStandardBindings.Count -ne 0)
        {
            if (($NonStandardBindings | Group-Object -Property Protocol, BindingInformation) | Where-Object -FilterScript {$_.Count -ne 1})
            {
                Write-Verbose -Message "BindingInfo contains multiple items with the same Protocol and BindingInformation combination."
                $IsValid = $false
            }
        }
    }
    catch
    {
        Write-Verbose -Message "Unable to validate BindingInfo: '$($_.Exception.Message)'."
        $IsValid = $false
    }

    return $IsValid
}

function Test-PortNumber
{
    <#
    .SYNOPSYS
        Validates that an input string represents a valid port number.
        The port number must be a positive integer between 1 and 65535.
    #>
    [CmdletBinding()]
    [OutputType([Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [AllowNull()]
        [String]
        $InputString
    )

    try
    {
        $IsValid = [UInt16]$InputString -ne 0
    }
    catch
    {
        $IsValid = $false
    }

    return $IsValid
}

function Test-WebsiteBinding
{
    <#
    .SYNOPSIS
        Helper function used to validate and compare website bindings of current to desired.
        Returns True if bindings do not need to be updated.
    #>
    [CmdletBinding()]
    [OutputType([Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $Name,

        [Parameter(Mandatory = $true)]
        [Microsoft.Management.Infrastructure.CimInstance[]]
        $BindingInfo
    )

    $InDesiredState = $true

    # Ensure that desired binding information is valid (i.e. no duplicate IP address, port, and host name combinations).
    if (-not (Test-BindingInfo -BindingInfo $BindingInfo))
    {
        $ErrorId = 'WebsiteBindingInputInvalidation'
        $ErrorCategory = [System.Management.Automation.ErrorCategory]::InvalidResult
        $ErrorMessage = $($LocalizedData.WebsiteBindingInputInvalidationError) -f $Name
        $Exception = New-Object -TypeName System.InvalidOperationException -ArgumentList $ErrorMessage
        $ErrorRecord = New-Object -TypeName System.Management.Automation.ErrorRecord -ArgumentList $Exception, $ErrorId, $ErrorCategory, $null

        $PSCmdlet.ThrowTerminatingError($ErrorRecord)
    }

    try
    {
        $Website = Get-Website | Where-Object -FilterScript {$_.Name -eq $Name}

        # Normalize binding objects to ensure they have the same representation
        $CurrentBindings = @(ConvertTo-WebBinding -InputObject $Website.bindings.Collection -Verbose:$false)
        $DesiredBindings = @(ConvertTo-WebBinding -InputObject $BindingInfo -Verbose:$false)

        $PropertiesToCompare = 'protocol', 'bindingInformation', 'certificateHash', 'certificateStoreName'

        # The sslFlags attribute was added in IIS 8.0.
        # This check is needed for backwards compatibility with Windows Server 2008 R2.
        if ([Environment]::OSVersion.Version -ge '6.2')
        {
            $PropertiesToCompare += 'sslFlags'
        }

        if (Compare-Object -ReferenceObject $CurrentBindings -DifferenceObject $DesiredBindings -Property $PropertiesToCompare)
        {
            $InDesiredState = $false
        }
    }
    catch
    {
        $ErrorId = 'WebsiteCompareFailure'
        $ErrorCategory = [System.Management.Automation.ErrorCategory]::InvalidResult
        $ErrorMessage = $($LocalizedData.WebsiteCompareFailureError) -f $Name
        $ErrorMessage += ' {0}' -f $_.Exception.Message
        $Exception = New-Object -TypeName System.InvalidOperationException -ArgumentList $ErrorMessage
        $ErrorRecord = New-Object -TypeName System.Management.Automation.ErrorRecord -ArgumentList $Exception, $ErrorId, $ErrorCategory, $null

        $PSCmdlet.ThrowTerminatingError($ErrorRecord)
    }

    return $InDesiredState
}

function Update-DefaultPage
{
    <#
    .SYNOPSIS
        Helper function used to update default pages of website.
    #>
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [String]
        $Name,

        [Parameter(Mandatory = $true)]
        [String[]]
        $DefaultPage
    )

    $AllDefaultPages = @(
        Get-WebConfiguration -Filter '//defaultDocument/files/*' -PSPath "IIS:\Sites\$Name" |
        ForEach-Object -Process {Write-Output -InputObject $_.value}
    )

    foreach ($Page in $DefaultPage)
    {
        if ($AllDefaultPages -inotcontains $Page)
        {
            Add-WebConfiguration -Filter '//defaultDocument/files' -PSPath "IIS:\Sites\$Name" -Value @{value = $Page}

            Write-Verbose -Message "Default page for website $Name has been updated to $Page"
        }
    }
}

function Update-WebsiteBinding
{
    <#
    .SYNOPSIS
        Updates website bindings.
    #>
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $Name,

        [Parameter(Mandatory = $false)]
        [Microsoft.Management.Infrastructure.CimInstance[]]
        $BindingInfo
    )

    # Use Get-WebConfiguration instead of Get-Website to retrieve XPath of the target website.
    # XPath -Filter is case-sensitive. Use Where-Object to get the target website by name.
    $Website = Get-WebConfiguration -Filter '/system.applicationHost/sites/site' |
        Where-Object -FilterScript {$_.Name -eq $Name}

    if (-not $Website)
    {
        $ErrorId = 'WebsiteNotFound'
        $ErrorCategory = [System.Management.Automation.ErrorCategory]::InvalidResult
        $ErrorMessage = $($LocalizedData.WebsiteNotFoundError) -f $Name
        $Exception = New-Object -TypeName System.InvalidOperationException -ArgumentList $ErrorMessage
        $ErrorRecord = New-Object -TypeName System.Management.Automation.ErrorRecord -ArgumentList $Exception, $ErrorId, $ErrorCategory, $null

        $PSCmdlet.ThrowTerminatingError($ErrorRecord)
    }

    ConvertTo-WebBinding -InputObject $BindingInfo -ErrorAction Stop |
    ForEach-Object -Begin {

        Clear-WebConfiguration -Filter "$($Website.ItemXPath)/bindings" -Force -ErrorAction Stop

    } -Process {

        $Properties = $_

        try
        {
            Add-WebConfiguration -Filter "$($Website.ItemXPath)/bindings" -Value @{
                protocol = $Properties.protocol
                bindingInformation = $Properties.bindingInformation
            } -Force -ErrorAction Stop
        }
        catch
        {
            $ErrorId = 'WebsiteBindingUpdateFailure'
            $ErrorCategory = [System.Management.Automation.ErrorCategory]::InvalidResult
            $ErrorMessage = $($LocalizedData.WebsiteBindingUpdateFailureError) -f $Name
            $ErrorMessage += ' {0}' -f $_.Exception.Message
            $Exception = New-Object -TypeName System.InvalidOperationException -ArgumentList $ErrorMessage
            $ErrorRecord = New-Object -TypeName System.Management.Automation.ErrorRecord -ArgumentList $Exception, $ErrorId, $ErrorCategory, $null

            $PSCmdlet.ThrowTerminatingError($ErrorRecord)
        }

        if ($Properties.protocol -eq 'https')
        {
            if ([Environment]::OSVersion.Version -ge '6.2')
            {
                try
                {
                    Set-WebConfigurationProperty -Filter "$($Website.ItemXPath)/bindings/binding[last()]" -Name sslFlags -Value $Properties.sslFlags -Force -ErrorAction Stop
                }
                catch
                {
                    $ErrorId = 'WebsiteBindingUpdateFailure'
                    $ErrorCategory = [System.Management.Automation.ErrorCategory]::InvalidResult
                    $ErrorMessage = $($LocalizedData.WebsiteBindingUpdateFailureError) -f $Name
                    $ErrorMessage += ' {0}' -f $_.Exception.Message
                    $Exception = New-Object -TypeName System.InvalidOperationException -ArgumentList $ErrorMessage
                    $ErrorRecord = New-Object -TypeName System.Management.Automation.ErrorRecord -ArgumentList $Exception, $ErrorId, $ErrorCategory, $null

                    $PSCmdlet.ThrowTerminatingError($ErrorRecord)
                }
            }

            try
            {
                $Binding = Get-WebConfiguration -Filter "$($Website.ItemXPath)/bindings/binding[last()]" -ErrorAction Stop
                $Binding.AddSslCertificate($Properties.certificateHash, $Properties.certificateStoreName)
            }
            catch
            {
                $ErrorId = 'WebBindingCertificateError'
                $ErrorCategory = [System.Management.Automation.ErrorCategory]::InvalidOperation
                $ErrorMessage = $($LocalizedData.WebBindingCertificateError) -f $Properties.certificateHash
                $ErrorMessage += ' {0}' -f $_.Exception.Message
                $Exception = New-Object -TypeName System.InvalidOperationException -ArgumentList $ErrorMessage
                $ErrorRecord = New-Object -TypeName System.Management.Automation.ErrorRecord -ArgumentList $Exception, $ErrorId, $ErrorCategory, $null

                $PSCmdlet.ThrowTerminatingError($ErrorRecord)
            }
        }

    }

}

#endregion
