#requires -Version 3 -Modules CimCmdlets
data LocalizedData
{
    # culture="en-US"
    ConvertFrom-StringData -StringData @'
SetTargetResourceInstallwhatIfMessage=Trying to create website "{0}".
SetTargetResourceUnInstallwhatIfMessage=Trying to remove website "{0}".
WebsiteNotFoundError=The requested website "{0}" is not found on the target machine.
WebsiteDiscoveryFailureError=Failure to get the requested website "{0}" information from the target machine.
WebsiteCreationFailureError=Failure to successfully create the website "{0}".
WebsiteRemovalFailureError=Failure to successfully remove the website "{0}".
WebsiteUpdateFailureError=Failure to successfully update the properties for website "{0}".
WebsiteBindingUpdateFailureError=Failure to successfully update the bindings for website "{0}".
WebsiteBindingInputInvalidationError=Desired website bindings not valid for website "{0}".
WebsiteCompareFailureError=Failure to successfully compare properties for website "{0}".
WebBindingCertificateError=Failure to add certificate to web binding. Please make sure that the certificate thumbprint "{0}" is valid.
WebsiteStateFailureError=Failure to successfully set the state of the website {0}.
WebsiteBindingConflictOnStartError = Website "{0}" could not be started due to binding conflict. Ensure that the binding information for this website does not conflict with any existing website's bindings before trying to start it.
'@
}

# The Get-TargetResource cmdlet is used to fetch the status of role or Website on the target machine.
# It gives the Website info of the requested role/feature on the target machine.
function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
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
    if (-not (Get-Module -ListAvailable -Name WebAdministration))
    {
        throw 'Please ensure that WebAdministration module is installed.'
    }

    $Website = Get-Website | Where-Object -FilterScript {$_.Name -eq $Name}

    if ($Website.Count -eq 0) # No Website exists with this name.
    {
        $EnsureResult = 'Absent'
    }
    elseif ($Website.Count -eq 1) # A single Website exists with this name.
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
        $ErrorMessage = $($LocalizedData.WebsiteDiscoveryFailureError) -f ${Name}
        $Exception = New-Object -TypeName System.InvalidOperationException -ArgumentList $ErrorMessage
        $ErrorRecord = New-Object -TypeName System.Management.Automation.ErrorRecord -ArgumentList $Exception, $ErrorId, $ErrorCategory, $null

        $PSCmdlet.ThrowTerminatingError($ErrorRecord)
    }

    # Add all Website properties to the hash table
    return @{
        Name            = $Name
        Ensure          = $EnsureResult
        PhysicalPath    = $Website.PhysicalPath
        State           = $Website.State
        ID              = $Website.ID
        ApplicationPool = $Website.ApplicationPool
        BindingInfo     = $CimBindings
        DefaultPage     = $AllDefaultPages
    }
}


# The Set-TargetResource cmdlet is used to create, delete or configure a website on the target machine.
function Set-TargetResource
{
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

        [String]
        $ApplicationPool,

        [Microsoft.Management.Infrastructure.CimInstance[]]
        $BindingInfo,

        [String[]]
        $DefaultPage
    )

    if ($Ensure -eq 'Present')
    {
        #Remove Ensure from parameters as it is not needed to create new website
        $Result = $PSBoundParameters.Remove('Ensure')
        #Remove State parameter form website. Will start the website after configuration is complete
        $Result = $PSBoundParameters.Remove('State')

        #Remove bindings from parameters if they exist
        #Bindings will be added to site using separate cmdlet
        $Result = $PSBoundParameters.Remove('BindingInfo')

        #Remove default pages from parameters if they exist
        #Default Pages will be added to site using separate cmdlet
        $Result = $PSBoundParameters.Remove('DefaultPage')

        # Check if WebAdministration module is present for IIS cmdlets
        if (-not (Get-Module -ListAvailable -Name WebAdministration))
        {
            throw 'Please ensure that WebAdministration module is installed.'
        }

        $Website = Get-Website | Where-Object -FilterScript {$_.Name -eq $Name}

        if ($Website -ne $null)
        {
            #update parameters as required

            $UpdateNotRequired = $true

            #Update Physical Path if required
            if (Test-WebsitePath -Name $Name -PhysicalPath $PhysicalPath)
            {
                $UpdateNotRequired = $false
                Set-ItemProperty -Path "IIS:\Sites\$Name" -Name physicalPath -Value $PhysicalPath -ErrorAction Stop

                Write-Verbose -Message "Physical path for website $Name has been updated to $PhysicalPath"
            }

            #Update Bindings if required
            if ($BindingInfo -ne $null)
            {
                if (Test-WebsiteBinding -Name $Name -BindingInfo $BindingInfo)
                {
                    $UpdateNotRequired = $false
                    #Update Bindings
                    Update-WebsiteBinding -Name $Name -BindingInfo $BindingInfo -ErrorAction Stop

                    Write-Verbose -Message "Bindings for website $Name have been updated"
                }
            }

            #Update Application Pool if required
            if (($Website.applicationPool -ne $ApplicationPool) -and ($ApplicationPool -ne ''))
            {
                $UpdateNotRequired = $false
                Set-ItemProperty -Path "IIS:\Sites\$Name" -Name applicationPool -Value $ApplicationPool -ErrorAction Stop

                Write-Verbose -Message "Application Pool for website $Name has been updated to $ApplicationPool"
            }

            #Update Default pages if required
            if ($DefaultPage -ne $null)
            {
                Update-DefaultPage -Name $Name -DefaultPage $DefaultPage
            }

            #Update State if required
            if ($Website.state -ne $State -and $State -ne '')
            {
                $UpdateNotRequired = $false

                if ($State -eq 'Started')
                {
                    # Ensure that there are no other websites with binding information that will conflict with this site before starting
                    $ExistingSites = Get-Website | Where-Object -FilterScript {$_.Name -ne $Name}

                    foreach ($Site in $ExistingSites)
                    {
                        $SiteInfo = Get-TargetResource -Name $Site.Name -PhysicalPath $Site.PhysicalPath

                        foreach ($Binding in $BindingInfo)
                        {
                            #Normalize empty IPAddress to "*"
                            if ([String]::IsNullOrEmpty($Binding.IPAddress))
                            {
                                $NormalizedIPAddress = '*'
                            }
                            else
                            {
                                $NormalizedIPAddress = $Binding.IPAddress
                            }

                            if (-not (Confirm-UniqueBindingInfo -Port $Binding.Port -IPAddress $NormalizedIPAddress -HostName $Binding.HostName -BindingInfo $SiteInfo.BindingInfo -UniqueInstances 1))
                            {
                                #return error & Do not start Website
                                $ErrorId = 'WebsiteBindingConflictOnStart'
                                $ErrorCategory = [System.Management.Automation.ErrorCategory]::InvalidResult
                                $ErrorMessage = $($LocalizedData.WebsiteBindingConflictOnStartError) -f ${Name}
                                $Exception = New-Object -TypeName System.InvalidOperationException -ArgumentList $ErrorMessage
                                $ErrorRecord = New-Object -TypeName System.Management.Automation.ErrorRecord -ArgumentList $Exception, $ErrorId, $ErrorCategory, $null

                                $PSCmdlet.ThrowTerminatingError($ErrorRecord)
                            }
                        }
                    }

                    try
                    {
                        Start-Website -Name $Name
                    }
                    catch
                    {
                        $ErrorId = 'WebsiteStateFailure'
                        $ErrorCategory = [System.Management.Automation.ErrorCategory]::InvalidOperation
                        $ErrorMessage = $($LocalizedData.WebsiteStateFailureError) -f ${Name}
                        $ErrorMessage += $_.Exception.Message
                        $Exception = New-Object -TypeName System.InvalidOperationException -ArgumentList $ErrorMessage
                        $ErrorRecord = New-Object -TypeName System.Management.Automation.ErrorRecord -ArgumentList $Exception, $ErrorId, $ErrorCategory, $null

                        $PSCmdlet.ThrowTerminatingError($ErrorRecord)
                    }
                }
                else
                {
                    try
                    {
                        Stop-Website -Name $Name
                    }
                    catch
                    {
                        $ErrorId = 'WebsiteStateFailure'
                        $ErrorCategory = [System.Management.Automation.ErrorCategory]::InvalidOperation
                        $ErrorMessage = $($LocalizedData.WebsiteStateFailureError) -f ${Name}
                        $ErrorMessage += $_.Exception.Message
                        $Exception = New-Object -TypeName System.InvalidOperationException -ArgumentList $ErrorMessage
                        $ErrorRecord = New-Object -TypeName System.Management.Automation.ErrorRecord -ArgumentList $Exception, $ErrorId, $ErrorCategory, $null

                        $PSCmdlet.ThrowTerminatingError($ErrorRecord)
                    }
                }

                Write-Verbose -Message "State for website $Name has been updated to $State"
            }

            if ($UpdateNotRequired)
            {
                Write-Verbose -Message "Website $Name already exists and properties do not need to be updated."
            }
        }
        else #Website doesn't exist so create new one
        {
            try
            {
                $Websites = Get-Website

                if ($Websites -eq $null)
                {
                    # We do not have any sites this will cause an exception in 2008R2 if we don't specify an ID
                    $Website = New-Website @PSBoundParameters -Id 1
                }
                else
                {
                    $Website = New-Website @PSBoundParameters
                }

                $Result = Stop-Website -Name $Website.Name -ErrorAction Stop

                #Clear default bindings if new bindings defined and are different
                if ($BindingInfo -ne $null)
                {
                    if (Test-WebsiteBinding -Name $Name -BindingInfo $BindingInfo)
                    {
                        Update-WebsiteBinding -Name $Name -BindingInfo $BindingInfo
                    }
                }

                #Add Default pages for new created website
                if ($DefaultPage -ne $null)
                {
                    Update-DefaultPage -Name $Name -DefaultPage $DefaultPage
                }

                Write-Verbose -Message "successfully created website $Name"

                #Start site if required
                if ($State -eq 'Started')
                {
                    #Wait 1 sec for bindings to take effect
                    #I have found that starting the website results in an error if it happens to quickly
                    Start-Sleep -Seconds 1
                    Start-Website -Name $Name -ErrorAction Stop
                }

                Write-Verbose -Message "successfully started website $Name"
            }
            catch
            {
                $ErrorId = 'WebsiteCreationFailure'
                $ErrorCategory = [System.Management.Automation.ErrorCategory]::InvalidOperation
                $ErrorMessage = $($LocalizedData.WebsiteCreationFailureError) -f ${Name}
                $ErrorMessage += $_.Exception.Message
                $Exception = New-Object -TypeName System.InvalidOperationException -ArgumentList $ErrorMessage
                $ErrorRecord = New-Object -TypeName System.Management.Automation.ErrorRecord -ArgumentList $Exception, $ErrorId, $ErrorCategory, $null
                $PSCmdlet.ThrowTerminatingError($ErrorRecord)
            }
        }
    }
    else #Ensure is set to "Absent" so remove website
    {
        try
        {
            $Website = Get-Website | Where-Object -FilterScript {$_.Name -eq $Name}

            if ($Website -ne $null)
            {
                Remove-Website -Name $Name
                Write-Verbose -Message "Successfully removed Website $Name."
            }
            else
            {
                Write-Verbose -Message "Website $Name does not exist."
            }
        }
        catch
        {
            $ErrorId = 'WebsiteRemovalFailure'
            $ErrorCategory = [System.Management.Automation.ErrorCategory]::InvalidOperation
            $ErrorMessage = $($LocalizedData.WebsiteRemovalFailureError) -f ${Name}
            $ErrorMessage += $_.Exception.Message
            $Exception = New-Object -TypeName System.InvalidOperationException -ArgumentList $ErrorMessage
            $ErrorRecord = New-Object -TypeName System.Management.Automation.ErrorRecord -ArgumentList $Exception, $ErrorId, $ErrorCategory, $null

            $PSCmdlet.ThrowTerminatingError($ErrorRecord)
        }
    }
}


# The Test-TargetResource cmdlet is used to validate if the role or feature is in a state as expected in the instance document.
function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
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

        [String]
        $ApplicationPool,

        [Microsoft.Management.Infrastructure.CimInstance[]]
        $BindingInfo,

        [String[]]
        $DefaultPage
    )

    $DesiredConfigurationMatch = $true

    # Check if WebAdministration module is present for IIS cmdlets
    if (-not (Get-Module -ListAvailable -Name WebAdministration))
    {
        throw 'Please ensure that WebAdministration module is installed.'
    }

    $Website = Get-Website | Where-Object -FilterScript {$_.Name -eq $Name}

    #Check Ensure
    if (($Ensure -eq 'Present' -and $Website -eq $null) -or ($Ensure -eq 'Absent' -and $Website -ne $null))
    {
        $DesiredConfigurationMatch = $false
        Write-Verbose -Message "The Ensure state for website $Name does not match the desired state."
    }

    # Only check properties if $Website exists
    if ($Ensure -eq 'Present' -and $Website -ne $null)
    {
        #Check Physical Path property
        if (Test-WebsitePath -Name $Name -PhysicalPath $PhysicalPath)
        {
            $DesiredConfigurationMatch = $false
            Write-Verbose -Message "Physical Path of Website $Name does not match the desired state."
        }

        #Check State
        if ($Website.state -ne $State -and $State -ne $null)
        {
            $DesiredConfigurationMatch = $false
            Write-Verbose -Message "The state of Website $Name does not match the desired state."
        }

        #Check Application Pool property
        if ($Website.applicationPool -ne $ApplicationPool -and $ApplicationPool -ne '')
        {
            $DesiredConfigurationMatch = $false
            Write-Verbose -Message "Application Pool for Website $Name does not match the desired state."
        }

        #Check Binding properties
        if ($BindingInfo -ne $null)
        {
            if (Test-WebsiteBinding -Name $Name -BindingInfo $BindingInfo)
            {
                $DesiredConfigurationMatch = $false
                Write-Verbose -Message "Bindings for website $Name do not match the desired state."
            }
        }

        #Check Default Pages
        if ($DefaultPage -ne $null)
        {
            $AllDefaultPages = @(
                Get-WebConfiguration -Filter '//defaultDocument/files/*' -PSPath "IIS:\Sites\$Name" |
                ForEach-Object -Process {Write-Output -InputObject $_.value}
            )

            foreach ($Page in $DefaultPage)
            {
                if ($AllDefaultPages -inotcontains $Page)
                {
                    $DesiredConfigurationMatch = $false
                    Write-Verbose -Message "Default Page for website $Name does not match the desired state."
                }
            }
        }
    }

    return $DesiredConfigurationMatch
}


#region Helper Functions

# Helper function used to validate website path
function Test-WebsitePath
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [String]
        $Name,

        [Parameter(Mandatory = $true)]
        [String]
        $PhysicalPath
    )

    if ((Get-ItemProperty -Path "IIS:\Sites\$Name" -Name physicalPath) -ne $PhysicalPath)
    {
        $IsDifferent = $true
    }
    else
    {
        $IsDifferent = $false
    }

    return $IsDifferent
}


# Helper function used to validate website bindings
# Returns true if bindings are valid (ie. port, IPAddress & Hostname combinations are unique).

function Confirm-UniqueBindingInfo
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter()]
        [UInt16]
        $Port,

        [Parameter()]
        [String]
        $IPAddress,

        [Parameter()]
        [String]
        $HostName,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [Microsoft.Management.Infrastructure.CimInstance[]]
        $BindingInfo,

        [Parameter()]
        $UniqueInstances = 0
    )

    foreach ($Binding in $BindingInfo)
    {
        if ($Binding.Port -eq $Port -and [String]$Binding.IPAddress -eq $IPAddress -and [String]$Binding.HostName -eq $HostName)
        {
            $UniqueInstances += 1
        }
    }

    if ($UniqueInstances -gt 1)
    {
        return $false
    }
    else
    {
        return $true
    }
}


# Helper function used to convert WebAdministration binding objects to instances of the MSFT_xWebBindingInformation CIM class
function ConvertTo-CimBinding
{
    <#
    .SYNOPSIS
        Converts binding objects to instances of the MSFT_xWebBindingInformation CIM class.
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
        $InputObject |
        ForEach-Object -Process {

            $Binding = $_

            #TODO: Implement support for other binding types: 'ftp', 'msmq.formatname', 'net.msmq', 'net.pipe', 'net.tcp'.
            if ($Binding.Protocol -notin @('http', 'https'))
            {
                Write-Verbose -Message "Protocol '$($Binding.protocol)' is not currently supported. The element will be skipped."
                return
            }

            if ($Binding -is [Microsoft.Management.Infrastructure.CimInstance])
            {
                $CimProperties = @{
                    Port                  = [UInt16]$Binding.Port
                    Protocol              = [String]$Binding.Protocol
                    IPAddress             = [String]$(if ($Binding.IPAddress) {$Binding.IPAddress} else {'*'})
                    HostName              = [String]$Binding.HostName
                    CertificateThumbprint = [String]$Binding.CertificateThumbprint
                    CertificateStoreName  = [String]$Binding.CertificateStoreName
                    SslFlags              = [String][Int32]$Binding.SslFlags
                }
            }
            else
            {
                if ($Binding.bindingInformation -match '^\[(.*?)\]\:(.*?)\:(.*?)$')
                {
                    $IPAddress = $Matches[1]
                    $Port = $Matches[2]
                    $HostName = $Matches[3]
                }
                else
                {
                    $IPAddress, $Port, $HostName = $Binding.bindingInformation -split '\:'
                }

                $CimProperties = @{
                    Port                  = [UInt16]$Port
                    Protocol              = [String]$Binding.Protocol
                    IPAddress             = [String]$(if ($IPAddress) {$IPAddress} else {'*'})
                    HostName              = [String]$HostName
                    CertificateThumbprint = [String]$Binding.certificateHash
                    CertificateStoreName  = [String]$Binding.certificateStoreName
                    SslFlags              = [String][Int32]$Binding.sslFlags
                }
            }

            New-CimInstance -ClassName $CimClassName -Namespace $CimNamespace -Property $CimProperties -ClientOnly

        }
    }
}


# Helper function used to compare website bindings of actual to desired
# Returns true if bindings need to be updated and false if not.
function Test-WebsiteBinding
{
    <#
    .SYNOPSIS
        Helper function used to validate and compare website bindings of current to desired.
        Returns True if bindings need to be updated and False if not.
    #>
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $Name,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [Microsoft.Management.Infrastructure.CimInstance[]]
        $BindingInfo
    )

    foreach ($Binding in $BindingInfo)
    {
        # First ensure that desired binding information is valid (i.e. no duplicate IPAddress, Port, HostName combinations).
        if (
            (-not (Confirm-UniqueBindingInfo -Port $Binding.Port -IPAddress $Binding.IPAddress -HostName $Binding.HostName -BindingInfo $BindingInfo)) -or
            ($Binding.CertificateThumbprint -eq '' -and $Binding.CertificateStoreName -ne '') -or
            ($Binding.CertificateThumbprint -ne '' -and $Binding.CertificateStoreName -eq '')
        )
        {
            $ErrorId = 'WebsiteBindingInputInvalidation'
            $ErrorCategory = [System.Management.Automation.ErrorCategory]::InvalidResult
            $ErrorMessage = $($LocalizedData.WebsiteBindingInputInvalidationError) -f ${Name}
            $Exception = New-Object -TypeName System.InvalidOperationException -ArgumentList $ErrorMessage
            $ErrorRecord = New-Object -TypeName System.Management.Automation.ErrorRecord -ArgumentList $Exception, $ErrorId, $ErrorCategory, $null

            $PSCmdlet.ThrowTerminatingError($ErrorRecord)
        }
    }

    # Assume bindings do not need to be updated
    $IsUpdateRequired = $false

    try
    {
        $Website = Get-Website | Where-Object -FilterScript {$_.Name -eq $Name}

        if ($Website.bindings.Collection | Where-Object -FilterScript {$_.protocol -notin @('http', 'https')})
        {
            Write-Verbose -Message "Website '$Name' has bindings of unsupported types."
            $IsUpdateRequired = $true
        }

        $CurrentCimBindings = @(ConvertTo-CimBinding -InputObject $Website.bindings.Collection)

        # Normalize $BindingInfo to ensure its objects have the same full set of properties as $CurrentCimBindings
        $DesiredCimBindings = @(ConvertTo-CimBinding -InputObject $BindingInfo)

        $PropertiesToCompare = 'Port', 'Protocol', 'IPAddress', 'HostName', 'CertificateThumbprint', 'CertificateStoreName'

        # The sslFlags attribute was added in IIS 8.0.
        # This check is needed for backwards compatibility with Windows Server 2008 R2.
        if ([Environment]::OSVersion.Version -ge '6.2')
        {
            $PropertiesToCompare += 'SslFlags'
        }

        if (Compare-Object -ReferenceObject $DesiredCimBindings -DifferenceObject $CurrentCimBindings -Property $PropertiesToCompare)
        {
            $IsUpdateRequired = $true
        }
    }
    catch
    {
        $ErrorId = 'WebsiteCompareFailure'
        $ErrorCategory = [System.Management.Automation.ErrorCategory]::InvalidResult
        $ErrorMessage = $($LocalizedData.WebsiteCompareFailureError) -f ${Name}
        $ErrorMessage += $_.Exception.Message
        $Exception = New-Object -TypeName System.InvalidOperationException -ArgumentList $ErrorMessage
        $ErrorRecord = New-Object -TypeName System.Management.Automation.ErrorRecord -ArgumentList $Exception, $ErrorId, $ErrorCategory, $null

        $PSCmdlet.ThrowTerminatingError($ErrorRecord)
    }

    return $IsUpdateRequired
}


function Update-WebsiteBinding
{
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

    #Need to clear the bindings before we can create new ones
    Clear-ItemProperty -Path "IIS:\Sites\$Name" -Name bindings -ErrorAction Stop

    #Need to clear $UseHostheader flag for multiple ssl bindings per site
    $UseHostHeader = $false

    foreach ($Binding in $BindingInfo)
    {
        $Protocol = $Binding.CimInstanceProperties['Protocol'].Value
        $IPAddress = $Binding.CimInstanceProperties['IPAddress'].Value
        $Port = $Binding.CimInstanceProperties['Port'].Value
        $HostHeader = $Binding.CimInstanceProperties['HostName'].Value
        $CertificateThumbprint = $Binding.CimInstanceProperties['CertificateThumbprint'].Value
        $CertificateStoreName = $Binding.CimInstanceProperties['CertificateStoreName'].Value
        $SslFlags = $Binding.CimInstanceProperties['SslFlags'].Value

        $BindingParams = @{}
        $BindingParams.Add('Name', $Name)
        $BindingParams.Add('Port', $Port)

        #Set IP Address parameter
        if ($IPAddress -ne $null)
        {
            $BindingParams.Add('IPAddress', $IPAddress)
        }
        else # Default to any/all IP Addresses
        {
            $BindingParams.Add('IPAddress', '*')
        }

        #Set protocol parameter
        if ($Protocol -ne $null)
        {
            $BindingParams.Add('Protocol', $Protocol)
        }
        else #Default to HTTP
        {
            $BindingParams.Add('Protocol', 'http')
        }

        #Set Host parameter if it exists
        if ($HostHeader -ne $null)
        {
            $BindingParams.Add('HostHeader', $HostHeader)
            $UseHostHeader = $true
        }

        if ([Environment]::OSVersion.Version -ge '6.2' -and -not [String]::IsNullOrEmpty($SslFlags))
        {
            $BindingParams.Add('SslFlags', $SslFlags)
        }

        try
        {
            New-WebBinding @BindingParams -ErrorAction Stop
        }
        catch
        {
            $ErrorId = 'WebsiteBindingUpdateFailure'
            $ErrorCategory = [System.Management.Automation.ErrorCategory]::InvalidResult
            $ErrorMessage = $($LocalizedData.WebsiteBindingUpdateFailureError) -f ${Name}
            $ErrorMessage += $_.Exception.Message
            $Exception = New-Object -TypeName System.InvalidOperationException -ArgumentList $ErrorMessage
            $ErrorRecord = New-Object -TypeName System.Management.Automation.ErrorRecord -ArgumentList $Exception, $ErrorId, $ErrorCategory, $null

            $PSCmdlet.ThrowTerminatingError($ErrorRecord)
        }

        try
        {
            if (-not [String]::IsNullOrEmpty($CertificateThumbprint))
            {
                # Modify the last added binding
                if ($UseHostHeader -eq $true)
                {
                    $NewWebBinding = Get-WebBinding -Name $Name -Port $Port -HostHeader $HostHeader | Select-Object -Last 1
                    $NewWebBinding.AddSslCertificate($CertificateThumbprint, $CertificateStoreName)
                }
                else
                {
                    $NewWebBinding = Get-WebBinding -Name $Name -Port $Port | Select-Object -Last 1
                    $NewWebBinding.AddSslCertificate($CertificateThumbprint, $CertificateStoreName)
                }
            }
        }
        catch
        {
            $ErrorId = 'WebBindingCertificateError'
            $ErrorCategory = [System.Management.Automation.ErrorCategory]::InvalidOperation
            $ErrorMessage = $($LocalizedData.WebBindingCertificateError) -f ${CertificateThumbprint}
            $ErrorMessage += $_.Exception.Message
            $Exception = New-Object -TypeName System.InvalidOperationException -ArgumentList $ErrorMessage
            $ErrorRecord = New-Object -TypeName System.Management.Automation.ErrorRecord -ArgumentList $Exception, $ErrorId, $ErrorCategory, $null

            $PSCmdlet.ThrowTerminatingError($ErrorRecord)
        }
    }
}


# Helper function used to Update default pages of website
function Update-DefaultPage
{
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

            if ($? -eq $true)
            {
                Write-Verbose -Message "Default page for website $Name has been updated to $Page"
            }
        }
    }
}


#endregion

