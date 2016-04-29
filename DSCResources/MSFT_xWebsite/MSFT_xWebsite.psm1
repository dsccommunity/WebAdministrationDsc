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
VerboseSetTargetUpdatedPhysicalPath = Physical Path for website "{0}" has been updated to "{1}".
VerboseSetTargetUpdatedApplicationPool = Application Pool for website "{0}" has been updated to "{1}".
VerboseSetTargetUpdatedBindingInfo = Bindings for website "{0}" have been updated.
VerboseSetTargetUpdatedEnabledProtocols = Enabled Protocols for website "{0}" have been updated to "{1}".
VerboseSetTargetUpdatedState = State for website "{0}" has been updated to "{1}".
VerboseSetTargetWebsiteCreated = Successfully created website "{0}".
VerboseSetTargetWebsiteStarted = Successfully started website "{0}".
VerboseSetTargetWebsiteRemoved = Successfully removed website "{0}".
VerboseTestTargetFalseEnsure = The Ensure state for website "{0}" does not match the desired state.
VerboseTestTargetFalsePhysicalPath = Physical Path of website "{0}" does not match the desired state.
VerboseTestTargetFalseState = The state of website "{0}" does not match the desired state.
VerboseTestTargetFalseApplicationPool = Application Pool for website "{0}" does not match the desired state.
VerboseTestTargetFalseBindingInfo = Bindings for website "{0}" do not match the desired state.
VerboseTestTargetFalseEnabledProtocols = Enabled Protocols for website "{0}" do not match the desired state.
VerboseTestTargetFalseDefaultPage = Default Page for website "{0}" does not match the desired state.
VerboseTestTargetTrueResult = The target resource is already in the desired state. No action is required.
VerboseTestTargetFalseResult = The target resource is not in the desired state.
VerboseConvertToWebBindingIgnoreBindingInformation = BindingInformation is ignored for bindings of type "{0}" in case at least one of the following properties is specified: IPAddress, Port, HostName.
VerboseConvertToWebBindingDefaultPort = Port is not specified. The default "{0}" port "{1}" will be used.
VerboseConvertToWebBindingDefaultCertificateStoreName = CertificateStoreName is not specified. The default value "{0}" will be used.
VerboseTestBindingInfoSameIPAddressPortHostName = BindingInfo contains multiple items with the same IPAddress, Port, and HostName combination.
VerboseTestBindingInfoSamePortDifferentProtocol = BindingInfo contains items that share the same Port but have different Protocols.
VerboseTestBindingInfoSameProtocolBindingInformation = BindingInfo contains multiple items with the same Protocol and BindingInformation combination.
VerboseTestBindingInfoInvalidCatch = Unable to validate BindingInfo: "{0}".
VerboseUpdateDefaultPageUpdated = Default page for website "{0}" has been updated to "{1}".
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
        $Name
    )

    Assert-Module

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
        $ErrorMessage = $LocalizedData.ErrorWebsiteDiscoveryFailure -f $Name
        New-TerminatingError -ErrorId 'WebsiteDiscoveryFailure' -ErrorMessage $ErrorMessage -ErrorCategory 'InvalidResult'
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

    Assert-Module

    $Website = Get-Website | Where-Object -FilterScript {$_.Name -eq $Name}

    if ($Ensure -eq 'Present')
    {
        if ($Website -ne $null)
        {
            # Update Physical Path if required
            if ([string]::IsNullOrEmpty($PhysicalPath) -eq $false -and $Website.PhysicalPath -ne $PhysicalPath)
            {
                Set-ItemProperty -Path "IIS:\Sites\$Name" -Name physicalPath -Value $PhysicalPath -ErrorAction Stop
                Write-Verbose -Message ($LocalizedData.VerboseSetTargetUpdatedPhysicalPath -f $Name, $PhysicalPath)
            }

            # Update Application Pool if required
            if ($PSBoundParameters.ContainsKey('ApplicationPool') -and $Website.ApplicationPool -ne $ApplicationPool)
            {
                Set-ItemProperty -Path "IIS:\Sites\$Name" -Name applicationPool -Value $ApplicationPool -ErrorAction Stop
                Write-Verbose -Message ($LocalizedData.VerboseSetTargetUpdatedApplicationPool -f $Name, $ApplicationPool)
            }

            # Update Bindings if required
            if ($PSBoundParameters.ContainsKey('BindingInfo') -and $BindingInfo -ne $null)
            {
                if (-not (Test-WebsiteBinding -Name $Name -BindingInfo $BindingInfo))
                {
                    Update-WebsiteBinding -Name $Name -BindingInfo $BindingInfo
                    Write-Verbose -Message ($LocalizedData.VerboseSetTargetUpdatedBindingInfo -f $Name)
                }
            }

            # Update Enabled Protocols if required
            if ($PSBoundParameters.ContainsKey('EnabledProtocols') -and $Website.EnabledProtocols -ne $EnabledProtocols)
            {
                Set-ItemProperty -Path "IIS:\Sites\$Name" -Name enabledProtocols -Value $EnabledProtocols -ErrorAction Stop
                Write-Verbose -Message ($LocalizedData.VerboseSetTargetUpdatedEnabledProtocols -f $Name, $EnabledProtocols)
            }

            # Update Default Pages if required
            if ($PSBoundParameters.ContainsKey('DefaultPage') -and $DefaultPage -ne $null)
            {
                Update-DefaultPage -Name $Name -DefaultPage $DefaultPage
            }

            # Update State if required
            if ($PSBoundParameters.ContainsKey('State') -and $Website.State -ne $State)
            {
                if ($State -eq 'Started')
                {
                    # Ensure that there are no other running websites with binding information that will conflict with this website before starting
                    if (-not (Confirm-UniqueBinding -Name $Name -ExcludeStopped))
                    {
                        # Return error and do not start the website
                        $ErrorMessage = $LocalizedData.ErrorWebsiteBindingConflictOnStart -f $Name
                        New-TerminatingError -ErrorId 'WebsiteBindingConflictOnStart' -ErrorMessage $ErrorMessage -ErrorCategory 'InvalidResult'
                    }

                    try
                    {
                        Start-Website -Name $Name -ErrorAction Stop
                    }
                    catch
                    {
                        $ErrorMessage = $LocalizedData.ErrorWebsiteStateFailure -f $Name, $_.Exception.Message
                        New-TerminatingError -ErrorId 'WebsiteStateFailure' -ErrorMessage $ErrorMessage -ErrorCategory 'InvalidOperation'
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
                        $ErrorMessage = $LocalizedData.ErrorWebsiteStateFailure -f $Name, $_.Exception.Message
                        New-TerminatingError -ErrorId 'WebsiteStateFailure' -ErrorMessage $ErrorMessage -ErrorCategory 'InvalidOperation'
                    }
                }

                Write-Verbose -Message ($LocalizedData.VerboseSetTargetUpdatedState -f $Name, $State)
            }
        }
        else # Create website if it does not exist
        {
            if ([string]::IsNullOrEmpty($PhysicalPath)) {
                throw "The PhysicalPath parameter must be provided for a website to be created"
            }

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
                Write-Verbose -Message ($LocalizedData.VerboseSetTargetWebsiteCreated -f $Name)
            }
            catch
            {
                $ErrorMessage = $LocalizedData.ErrorWebsiteCreationFailure -f $Name, $_.Exception.Message
                New-TerminatingError -ErrorId 'WebsiteCreationFailure' -ErrorMessage $ErrorMessage -ErrorCategory 'InvalidOperation'
            }

            Stop-Website -Name $Website.Name -ErrorAction Stop

            # Clear default bindings if new bindings defined and are different
            if ($PSBoundParameters.ContainsKey('BindingInfo') -and $BindingInfo -ne $null)
            {
                if (-not (Test-WebsiteBinding -Name $Name -BindingInfo $BindingInfo))
                {
                    Update-WebsiteBinding -Name $Name -BindingInfo $BindingInfo
                    Write-Verbose -Message ($LocalizedData.VerboseSetTargetUpdatedBindingInfo -f $Name)
                }
            }

            # Update Enabled Protocols if required
            if ($PSBoundParameters.ContainsKey('EnabledProtocols') -and $Website.EnabledProtocols -ne $EnabledProtocols)
            {
                Set-ItemProperty -Path "IIS:\Sites\$Name" -Name enabledProtocols -Value $EnabledProtocols -ErrorAction Stop
                Write-Verbose -Message ($LocalizedData.VerboseSetTargetUpdatedEnabledProtocols -f $Name, $EnabledProtocols)
            }

            # Update Default Pages if required
            if ($PSBoundParameters.ContainsKey('DefaultPage') -and $DefaultPage -ne $null)
            {
                Update-DefaultPage -Name $Name -DefaultPage $DefaultPage
            }

            # Start website if required
            if ($State -eq 'Started')
            {
                # Ensure that there are no other running websites with binding information that will conflict with this website before starting
                if (-not (Confirm-UniqueBinding -Name $Name -ExcludeStopped))
                {
                    # Return error and do not start the website
                    $ErrorMessage = $LocalizedData.ErrorWebsiteBindingConflictOnStart -f $Name
                    New-TerminatingError -ErrorId 'WebsiteBindingConflictOnStart' -ErrorMessage $ErrorMessage -ErrorCategory 'InvalidResult'
                }

                try
                {
                    Start-Website -Name $Name -ErrorAction Stop
                    Write-Verbose -Message ($LocalizedData.VerboseSetTargetWebsiteStarted -f $Name)
                }
                catch
                {
                    $ErrorMessage = $LocalizedData.ErrorWebsiteStateFailure -f $Name, $_.Exception.Message
                    New-TerminatingError -ErrorId 'WebsiteStateFailure' -ErrorMessage $ErrorMessage -ErrorCategory 'InvalidOperation'
                }
            }
        }
    }
    else # Remove website
    {
        try
        {
            Remove-Website -Name $Name -ErrorAction Stop
            Write-Verbose -Message ($LocalizedData.VerboseSetTargetWebsiteRemoved -f $Name)
        }
        catch
        {
            $ErrorMessage = $LocalizedData.ErrorWebsiteRemovalFailure -f $Name, $_.Exception.Message
            New-TerminatingError -ErrorId 'WebsiteRemovalFailure' -ErrorMessage $ErrorMessage -ErrorCategory 'InvalidOperation'
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

    Assert-Module

    $InDesiredState = $true

    $Website = Get-Website | Where-Object -FilterScript {$_.Name -eq $Name}

    # Check Ensure
    if (($Ensure -eq 'Present' -and $Website -eq $null) -or ($Ensure -eq 'Absent' -and $Website -ne $null))
    {
        $InDesiredState = $false
        Write-Verbose -Message ($LocalizedData.VerboseTestTargetFalseEnsure -f $Name)
    }

    # Only check properties if website exists
    if ($Ensure -eq 'Present' -and $Website -ne $null)
    {
        # Check Physical Path property
        if ([string]::IsNullOrEmpty($PhysicalPath) -eq $false -and $Website.PhysicalPath -ne $PhysicalPath)
        {
            $InDesiredState = $false
            Write-Verbose -Message ($LocalizedData.VerboseTestTargetFalsePhysicalPath -f $Name)
        }

        # Check State
        if ($PSBoundParameters.ContainsKey('State') -and $Website.State -ne $State)
        {
            $InDesiredState = $false
            Write-Verbose -Message ($LocalizedData.VerboseTestTargetFalseState -f $Name)
        }

        # Check Application Pool property
        if ($PSBoundParameters.ContainsKey('ApplicationPool') -and $Website.ApplicationPool -ne $ApplicationPool)
        {
            $InDesiredState = $false
            Write-Verbose -Message ($LocalizedData.VerboseTestTargetFalseApplicationPool -f $Name)
        }

        # Check Binding properties
        if ($PSBoundParameters.ContainsKey('BindingInfo') -and $BindingInfo -ne $null)
        {
            if (-not (Test-WebsiteBinding -Name $Name -BindingInfo $BindingInfo))
            {
                $InDesiredState = $false
                Write-Verbose -Message ($LocalizedData.VerboseTestTargetFalseBindingInfo -f $Name)
            }
        }

        # Check Enabled Protocols
        if ($PSBoundParameters.ContainsKey('EnabledProtocols') -and $Website.EnabledProtocols -ne $EnabledProtocols)
        {
            $InDesiredState = $false
            Write-Verbose -Message ($LocalizedData.VerboseTestTargetFalseEnabledProtocols -f $Name)
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
                    Write-Verbose -Message ($LocalizedData.VerboseTestTargetFalseDefaultPage -f $Name)
                }
            }
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

#region Helper Functions

function Confirm-UniqueBinding
{
    <#
    .SYNOPSIS
        Helper function used to validate that the website's binding information is unique to other websites.
        Returns False if at least one of the bindings is already assigned to another website.
    .PARAMETER Name
        Specifies the name of the website.
    .PARAMETER ExcludeStopped
        Omits stopped websites.
    .NOTES
        This function tests standard ('http' and 'https') bindings only.
        It is technically possible to assign identical non-standard bindings (such as 'net.tcp') to different websites.
    #>
    [CmdletBinding()]
    [OutputType([Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $Name,

        [Parameter(Mandatory = $false)]
        [Switch]
        $ExcludeStopped
    )

    $Website = Get-Website | Where-Object -FilterScript {$_.Name -eq $Name}

    if (-not $Website)
    {
        $ErrorMessage = $LocalizedData.ErrorWebsiteNotFound -f $Name
        New-TerminatingError -ErrorId 'WebsiteNotFound' -ErrorMessage $ErrorMessage -ErrorCategory 'InvalidResult'
    }

    $ReferenceObject = @(
        $Website.bindings.Collection |
        Where-Object -FilterScript {$_.protocol -in @('http', 'https')} |
        ConvertTo-WebBinding -Verbose:$false
    )

    if ($ExcludeStopped)
    {
        $OtherWebsiteFilter = {$_.Name -ne $Website.Name -and $_.State -ne 'Stopped'}
    }
    else
    {
        $OtherWebsiteFilter = {$_.Name -ne $Website.Name}
    }

    $DifferenceObject = @(
        Get-Website |
        Where-Object -FilterScript $OtherWebsiteFilter |
        ForEach-Object -Process {$_.bindings.Collection} |
        Where-Object -FilterScript {$_.protocol -in @('http', 'https')} |
        ConvertTo-WebBinding -Verbose:$false
    )

    # Assume that bindings are unique
    $Result = $true

    $CompareSplat = @{
        ReferenceObject  = $ReferenceObject
        DifferenceObject = $DifferenceObject
        Property         = @('protocol', 'bindingInformation')
        ExcludeDifferent = $true
        IncludeEqual     = $true
    }

    if (Compare-Object @CompareSplat)
    {
        $Result = $false
    }

    return $Result
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
                            $IsJoinRequired = $true
                            Write-Verbose -Message ($LocalizedData.VerboseConvertToWebBindingIgnoreBindingInformation -f $Binding.Protocol)
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
                        $IPAddressString = Format-IPAddressString -InputString $Binding.IPAddress -ErrorAction Stop

                        if ([String]::IsNullOrEmpty($Binding.Port))
                        {
                            switch ($Binding.Protocol)
                            {
                                'http'  {$PortNumberString = '80'}
                                'https' {$PortNumberString = '443'}
                            }

                            Write-Verbose -Message ($LocalizedData.VerboseConvertToWebBindingDefaultPort -f $Binding.Protocol, $PortNumberString)
                        }
                        else
                        {
                            if (Test-PortNumber -InputString $Binding.Port)
                            {
                                $PortNumberString = $Binding.Port
                            }
                            else
                            {
                                $ErrorMessage = $LocalizedData.ErrorWebBindingInvalidPort -f $Binding.Port
                                New-TerminatingError -ErrorId 'WebBindingInvalidPort' -ErrorMessage $ErrorMessage -ErrorCategory 'InvalidArgument'
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
                        $ErrorMessage = $LocalizedData.ErrorWebBindingMissingBindingInformation -f $Binding.Protocol
                        New-TerminatingError -ErrorId 'WebBindingMissingBindingInformation' -ErrorMessage $ErrorMessage -ErrorCategory 'InvalidArgument'
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
                        $ErrorMessage = $LocalizedData.ErrorWebBindingMissingCertificateThumbprint -f $Binding.Protocol
                        New-TerminatingError -ErrorId 'WebBindingMissingCertificateThumbprint' -ErrorMessage $ErrorMessage -ErrorCategory 'InvalidArgument'
                    }

                    if ([String]::IsNullOrEmpty($Binding.CertificateStoreName))
                    {
                        $CertificateStoreName = 'MY'
                        Write-Verbose -Message ($LocalizedData.VerboseConvertToWebBindingDefaultCertificateStoreName -f $CertificateStoreName)
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
                    WebAdministration can throw the following exception if there are non-standard bindings (such as 'net.tcp'):
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
            $ErrorMessage = $LocalizedData.ErrorWebBindingInvalidIPAddress -f $InputString, $_.Exception.Message
            New-TerminatingError -ErrorId 'WebBindingInvalidIPAddress' -ErrorMessage $ErrorMessage -ErrorCategory 'InvalidArgument'
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
                $IsValid = $false
                Write-Verbose -Message ($LocalizedData.VerboseTestBindingInfoSameIPAddressPortHostName)
            }

            # A single port cannot be simultaneously specified for bindings with different protocols
            foreach ($GroupByPort in ($StandardBindings | Group-Object -Property Port))
            {
                if (($GroupByPort.Group | Group-Object -Property Protocol).Length -ne 1)
                {
                    $IsValid = $false
                    Write-Verbose -Message ($LocalizedData.VerboseTestBindingInfoSamePortDifferentProtocol)
                    break
                }
            }
        }

        if ($NonStandardBindings.Count -ne 0)
        {
            if (($NonStandardBindings | Group-Object -Property Protocol, BindingInformation) | Where-Object -FilterScript {$_.Count -ne 1})
            {
                $IsValid = $false
                Write-Verbose -Message ($LocalizedData.VerboseTestBindingInfoSameProtocolBindingInformation)
            }
        }
    }
    catch
    {
        $IsValid = $false
        Write-Verbose -Message ($LocalizedData.VerboseTestBindingInfoInvalidCatch -f $_.Exception.Message)
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
        $ErrorMessage = $LocalizedData.ErrorWebsiteBindingInputInvalidation -f $Name
        New-TerminatingError -ErrorId 'WebsiteBindingInputInvalidation' -ErrorMessage $ErrorMessage -ErrorCategory 'InvalidResult'
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
        $ErrorMessage = $LocalizedData.ErrorWebsiteCompareFailure -f $Name, $_.Exception.Message
        New-TerminatingError -ErrorId 'WebsiteCompareFailure' -ErrorMessage $ErrorMessage -ErrorCategory 'InvalidResult'
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
            Write-Verbose -Message ($LocalizedData.VerboseUpdateDefaultPageUpdated -f $Name, $Page)
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
        $ErrorMessage = $LocalizedData.ErrorWebsiteNotFound -f $Name
        New-TerminatingError -ErrorId 'WebsiteNotFound' -ErrorMessage $ErrorMessage -ErrorCategory 'InvalidResult'
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
            $ErrorMessage = $LocalizedData.ErrorWebsiteBindingUpdateFailure -f $Name, $_.Exception.Message
            New-TerminatingError -ErrorId 'WebsiteBindingUpdateFailure' -ErrorMessage $ErrorMessage -ErrorCategory 'InvalidResult'
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
                    $ErrorMessage = $LocalizedData.ErrorWebsiteBindingUpdateFailure -f $Name, $_.Exception.Message
                    New-TerminatingError -ErrorId 'WebsiteBindingUpdateFailure' -ErrorMessage $ErrorMessage -ErrorCategory 'InvalidResult'
                }
            }

            try
            {
                $Binding = Get-WebConfiguration -Filter "$($Website.ItemXPath)/bindings/binding[last()]" -ErrorAction Stop
                $Binding.AddSslCertificate($Properties.certificateHash, $Properties.certificateStoreName)
            }
            catch
            {
                $ErrorMessage = $LocalizedData.ErrorWebBindingCertificate -f $Properties.certificateHash, $_.Exception.Message
                New-TerminatingError -ErrorId 'WebBindingCertificate' -ErrorMessage $ErrorMessage -ErrorCategory 'InvalidOperation'
            }
        }

    }

}

#endregion
