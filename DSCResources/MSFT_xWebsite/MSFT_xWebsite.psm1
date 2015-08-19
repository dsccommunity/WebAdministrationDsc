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
WebBindingCertifcateError=Failure to add certificate to web binding. Please make sure that the certificate thumbprint "{0}" is valid.
WebsiteStateFailureError=Failure to successfully set the state of the website {0}.
WebsiteBindingConflictOnStartError = Website "{0}" could not be started due to binding conflict. Ensure that the binding information for this website does not conflict with any existing website's bindings before trying to start it.
'@
}

# The Get-TargetResource cmdlet is used to fetch the status of role or Website on the target machine.
# It gives the Website info of the requested role/feature on the target machine.
function Get-TargetResource
{
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Name,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$PhysicalPath
    )

    # Check if WebAdministration module is present for IIS cmdlets
    if(!(Get-Module -ListAvailable -Name WebAdministration))
    {
        Throw 'Please ensure that WebAdministration module is installed.'
    }

    $Website = Get-Website | Where-Object -FilterScript {
        $_.Name -eq $Name
    }

    if ($Website.count -eq 0) # No Website exists with this name.
    {
        $ensureResult = 'Absent'
    }
    elseif ($Website.count -eq 1) # A single Website exists with this name.
    {
        $ensureResult = 'Present'

        [PSObject[]] $Bindings
        $Bindings = (Get-ItemProperty -Path IIS:\Sites\$Name -Name Bindings).collection

        $CimBindings = foreach ($binding in $Bindings)
        {
            $BindingObject = Get-WebBindingObject -BindingInfo $binding
            New-CimInstance -ClassName MSFT_xWebBindingInformation -Namespace root/microsoft/Windows/DesiredStateConfiguration -Property @{
                Port                  = [System.UInt16]$BindingObject.Port
                Protocol              = $BindingObject.Protocol
                IPAddress             = $BindingObject.IPaddress
                HostName              = $BindingObject.Hostname
                CertificateThumbprint = $BindingObject.CertificateThumbprint
                CertificateStoreName  = $BindingObject.CertificateStoreName
                SSLFlags              = $BindingObject.SSLFlags
            } -ClientOnly
        }

        $allDefaultPage = @(Get-WebConfiguration //defaultDocument/files/*  -PSPath (Join-Path -Path 'IIS:\sites\' -ChildPath $Name) | ForEach-Object -Process {
                Write-Output -InputObject $_.value
        })
    }
    else # Multiple websites with the same name exist. This is not supported and is an error
    {
        $errorId = 'WebsiteDiscoveryFailure'
        $errorCategory = [System.Management.Automation.ErrorCategory]::InvalidResult
        $errorMessage = $($LocalizedData.WebsiteDiscoveryFailureError) -f ${Name}
        $exception = New-Object -TypeName System.InvalidOperationException -ArgumentList $errorMessage
        $errorRecord = New-Object -TypeName System.Management.Automation.ErrorRecord -ArgumentList $exception, $errorId, $errorCategory, $null

        $PSCmdlet.ThrowTerminatingError($errorRecord)
    }

    # Add all Website properties to the hash table
    return @{
        Name            = $Website.Name
        Ensure          = $ensureResult
        PhysicalPath    = $Website.PhysicalPath
        State           = $Website.State
        ID              = $Website.ID
        ApplicationPool = $Website.ApplicationPool
        BindingInfo     = $CimBindings
        DefaultPage     = $allDefaultPage
    }
}


# The Set-TargetResource cmdlet is used to create, delete or configure a website on the target machine.
function Set-TargetResource
{
    [CmdletBinding(SupportsShouldProcess = $true)]
    param
    (
        [ValidateSet('Present', 'Absent')]
        [string]$Ensure = 'Present',

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Name,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$PhysicalPath,

        [ValidateSet('Started', 'Stopped')]
        [string]$State = 'Started',

        [string]$ApplicationPool,

        [Microsoft.Management.Infrastructure.CimInstance[]]$BindingInfo,

        [string[]]$DefaultPage

    )

    $getTargetResourceResult = $null

    if($Ensure -eq 'Present')
    {
        #Remove Ensure from parameters as it is not needed to create new website
        $Result = $psboundparameters.Remove('Ensure')
        #Remove State parameter form website. Will start the website after configuration is complete
        $Result = $psboundparameters.Remove('State')

        #Remove bindings from parameters if they exist
        #Bindings will be added to site using separate cmdlet
        $Result = $psboundparameters.Remove('BindingInfo')

        #Remove default pages from parameters if they exist
        #Default Pages will be added to site using separate cmdlet
        $Result = $psboundparameters.Remove('DefaultPage')

        # Check if WebAdministration module is present for IIS cmdlets
        if(!(Get-Module -ListAvailable -Name WebAdministration))
        {
            Throw 'Please ensure that WebAdministration module is installed.'
        }

        $Website = Get-Website | Where-Object -FilterScript {
            $_.Name -eq $Name
        }

        if($Website -ne $null)
        {
            #update parameters as required

            $UpdateNotRequired = $true

            #Update Physical Path if required
            if(Test-WebsitePath -Name $Name -PhysicalPath $PhysicalPath)
            {
                $UpdateNotRequired = $false
                Set-ItemProperty -Path "IIS:\Sites\$Name" -Name physicalPath -Value $PhysicalPath -ErrorAction Stop

                Write-Verbose -Message ("Physical path for website $Name has been updated to $PhysicalPath")
            }

            #Update Bindings if required
            if ($BindingInfo -ne $null)
            {
                if(Test-WebsiteBindings -Name $Name -BindingInfo $BindingInfo)
                {
                    $UpdateNotRequired = $false
                    #Update Bindings
                    Update-WebsiteBinding -Name $Name -BindingInfo $BindingInfo -ErrorAction Stop

                    Write-Verbose -Message ("Bindings for website $Name have been updated.")
                }
            }

            #Update Application Pool if required
            if(($Website.applicationPool -ne $ApplicationPool) -and ($ApplicationPool -ne ''))
            {
                $UpdateNotRequired = $false
                Set-ItemProperty -Path IIS:\Sites\$Name -Name applicationPool -Value $ApplicationPool -ErrorAction Stop

                Write-Verbose -Message ("Application Pool for website $Name has been updated to $ApplicationPool")
            }

            #Update Default pages if required
            if($DefaultPage -ne $null)
            {
                Update-DefaultPages $Name -DefaultPage $DefaultPage
            }

            #Update State if required
            if($Website.state -ne $State -and $State -ne '')
            {
                $UpdateNotRequired = $false
                if($State -eq 'Started')
                {
                    # Ensure that there are no other websites with binding information that will conflict with this site before starting
                    $existingSites = Get-Website | Where-Object -Property Name -NE -Value $Name

                    foreach($site in $existingSites)
                    {
                        $siteInfo = Get-TargetResource -Name $site.Name -PhysicalPath $site.PhysicalPath

                        foreach ($binding in $BindingInfo)
                        {
                            #Normalize empty IPAddress to "*"
                            if($binding.IPAddress -eq '' -or $binding.IPAddress -eq $null)
                            {
                                $NormalizedIPAddress = '*'
                            }
                            else
                            {
                                $NormalizedIPAddress = $binding.IPAddress
                            }

                            if( !(Confirm-PortIPHostisUnique -Port $binding.Port -IPAddress $NormalizedIPAddress -HostName $binding.HostName -BindingInfo $siteInfo.BindingInfo -UniqueInstances 1))
                            {
                                #return error & Do not start Website
                                $errorId = 'WebsiteBindingConflictOnStart'
                                $errorCategory = [System.Management.Automation.ErrorCategory]::InvalidResult
                                $errorMessage = $($LocalizedData.WebsiteBindingConflictOnStartError) -f ${Name}
                                $exception = New-Object -TypeName System.InvalidOperationException -ArgumentList $errorMessage
                                $errorRecord = New-Object -TypeName System.Management.Automation.ErrorRecord -ArgumentList $exception, $errorId, $errorCategory, $null

                                $PSCmdlet.ThrowTerminatingError($errorRecord)
                            }
                        }
                    }

                    try
                    {
                        Start-Website -Name $Name
                    }
                    catch
                    {
                        $errorId = 'WebsiteStateFailure'
                        $errorCategory = [System.Management.Automation.ErrorCategory]::InvalidOperation
                        $errorMessage = $($LocalizedData.WebsiteStateFailureError) -f ${Name}
                        $errorMessage += $_.Exception.Message
                        $exception = New-Object -TypeName System.InvalidOperationException -ArgumentList $errorMessage
                        $errorRecord = New-Object -TypeName System.Management.Automation.ErrorRecord -ArgumentList $exception, $errorId, $errorCategory, $null

                        $PSCmdlet.ThrowTerminatingError($errorRecord)
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
                        $errorId = 'WebsiteStateFailure'
                        $errorCategory = [System.Management.Automation.ErrorCategory]::InvalidOperation
                        $errorMessage = $($LocalizedData.WebsiteStateFailureError) -f ${Name}
                        $errorMessage += $_.Exception.Message
                        $exception = New-Object -TypeName System.InvalidOperationException -ArgumentList $errorMessage
                        $errorRecord = New-Object -TypeName System.Management.Automation.ErrorRecord -ArgumentList $exception, $errorId, $errorCategory, $null

                        $PSCmdlet.ThrowTerminatingError($errorRecord)
                    }
                }

                Write-Verbose -Message ("State for website $Name has been updated to $State")
            }

            if($UpdateNotRequired)
            {
                Write-Verbose -Message ("Website $Name already exists and properties do not need to be updated.")
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
                    $Website = New-Website @psboundparameters -ID 1
                }
                else
                {
                    $Website = New-Website @psboundparameters
                }
                $Result = Stop-Website $Website.name -ErrorAction Stop

                #Clear default bindings if new bindings defined and are different
                if($BindingInfo -ne $null)
                {
                    if(Test-WebsiteBindings -Name $Name -BindingInfo $BindingInfo)
                    {
                        Update-WebsiteBinding -Name $Name -BindingInfo $BindingInfo
                    }
                }

                #Add Default pages for new created website
                if($DefaultPage -ne $null)
                {
                    Update-DefaultPages -Name $Name -DefaultPage $DefaultPage
                }

                Write-Verbose -Message ("successfully created website $Name")

                #Start site if required
                if($State -eq 'Started')
                {
                    #Wait 1 sec for bindings to take effect
                    #I have found that starting the website results in an error if it happens to quickly
                    Start-Sleep -Seconds 1
                    Start-Website -Name $Name -ErrorAction Stop
                }

                Write-Verbose -Message ("successfully started website $Name")
            }
            catch
            {
                $errorId = 'WebsiteCreationFailure'
                $errorCategory = [System.Management.Automation.ErrorCategory]::InvalidOperation
                $errorMessage = $($LocalizedData.WebsiteCreationFailureError) -f ${Name}
                $errorMessage += $_.Exception.Message
                $exception = New-Object -TypeName System.InvalidOperationException -ArgumentList $errorMessage
                $errorRecord = New-Object -TypeName System.Management.Automation.ErrorRecord -ArgumentList $exception, $errorId, $errorCategory, $null
                $PSCmdlet.ThrowTerminatingError($errorRecord)
            }
        }
    }
    else #Ensure is set to "Absent" so remove website
    {
        try
        {
            $Website = Get-Website | Where-Object -FilterScript {
                $_.Name -eq $Name
            }
            if($Website -ne $null)
            {
                Remove-Website -name $Name
                Write-Verbose -Message ("Successfully removed Website $Name.")
            }
            else
            {
                Write-Verbose -Message ("Website $Name does not exist.")
            }
        }
        catch
        {
            $errorId = 'WebsiteRemovalFailure'
            $errorCategory = [System.Management.Automation.ErrorCategory]::InvalidOperation
            $errorMessage = $($LocalizedData.WebsiteRemovalFailureError) -f ${Name}
            $errorMessage += $_.Exception.Message
            $exception = New-Object -TypeName System.InvalidOperationException -ArgumentList $errorMessage
            $errorRecord = New-Object -TypeName System.Management.Automation.ErrorRecord -ArgumentList $exception, $errorId, $errorCategory, $null

            $PSCmdlet.ThrowTerminatingError($errorRecord)
        }
    }
}


# The Test-TargetResource cmdlet is used to validate if the role or feature is in a state as expected in the instance document.
function Test-TargetResource
{
    [OutputType([System.Boolean])]
    param
    (
        [ValidateSet('Present', 'Absent')]
        [string]$Ensure = 'Present',

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Name,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$PhysicalPath,

        [ValidateSet('Started', 'Stopped')]
        [string]$State = 'Started',

        [string]$ApplicationPool,

        [Microsoft.Management.Infrastructure.CimInstance[]]$BindingInfo,

        [string[]]$DefaultPage
    )

    $DesiredConfigurationMatch = $true

    # Check if WebAdministration module is present for IIS cmdlets
    if(!(Get-Module -ListAvailable -Name WebAdministration))
    {
        Throw 'Please ensure that WebAdministration module is installed.'
    }

    $Website = Get-Website -Name $Name
    $Stop = $true

    Do
    {
        #Check Ensure
        if(($Ensure -eq 'Present' -and $Website -eq $null) -or ($Ensure -eq 'Absent' -and $Website -ne $null))
        {
            $DesiredConfigurationMatch = $false
            Write-Verbose -Message ("The Ensure state for website $Name does not match the desired state.")
            break
        }

        # Only check properties if $website exists
        if ($Website -ne $null)
        {
            #Check Physical Path property
            if(Test-WebsitePath -Name $Name -PhysicalPath $PhysicalPath)
            {
                $DesiredConfigurationMatch = $false
                Write-Verbose -Message ("Physical Path of Website $Name does not match the desired state.")
                break
            }

            #Check State
            if($Website.state -ne $State -and $State -ne $null)
            {
                $DesiredConfigurationMatch = $false
                Write-Verbose -Message ("The state of Website $Name does not match the desired state.")
                break
            }

            #Check Application Pool property
            if(($ApplicationPool -ne '') -and ($Website.applicationPool -ne $ApplicationPool))
            {
                $DesiredConfigurationMatch = $false
                Write-Verbose -Message ("Application Pool for Website $Name does not match the desired state.")
                break
            }

            #Check Binding properties
            if($BindingInfo -ne $null)
            {
                if(Test-WebsiteBindings -Name $Name -BindingInfo $BindingInfo)
                {
                    $DesiredConfigurationMatch = $false
                    Write-Verbose -Message ("Bindings for website $Name do not match the desired state.")
                    break
                }
            }
        }

        #Check Default Pages
        if($DefaultPage -ne $null)
        {
            $allDefaultPage = @(Get-WebConfiguration //defaultDocument/files/* -PSPath (Join-Path -Path 'IIS:\sites\' -ChildPath $Name) | ForEach-Object -Process {
                    Write-Output -InputObject $_.value
            })

            $allDefaultPagesPresent = $true

            foreach($page in $DefaultPage)
            {
                if(-not ($allDefaultPage -icontains $page))
                {
                    $DesiredConfigurationMatch = $false
                    Write-Verbose -Message ("Default Page for website $Name do not match the desired state.")
                    $allDefaultPagesPresent = $false
                    break
                }
            }

            if($allDefaultPagesPresent -eq $false)
            {
                # This is to break out from Test
                break
            }
        }


        $Stop = $false
    }
    While($Stop)

    $DesiredConfigurationMatch
}

#region HelperFunctions

# Helper function used to validate website path
function Test-WebsitePath
{
    param
    (
        [string] $Name,

        [string] $PhysicalPath
    )

    if((Get-ItemProperty -Path "IIS:\Sites\$Name" -Name physicalPath) -ne $PhysicalPath)
    {
        return $true
    }

    return $false
}

# Helper function used to validate website bindings
# Returns true if bindings are valid (ie. port, IPAddress & Hostname combinations are unique).

function Confirm-PortIPHostisUnique
{
    param
    (
        [parameter()]
        [System.UInt16]
        $Port,

        [parameter()]
        [string]
        $IPAddress,

        [parameter()]
        [string]
        $HostName,

        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [Microsoft.Management.Infrastructure.CimInstance[]]
        $BindingInfo,

        [parameter()]
        $UniqueInstances = 0
    )

    foreach ($binding in $BindingInfo)
    {
        if($binding.Port -eq $Port -and [string]$binding.IPAddress -eq $IPAddress -and [string]$binding.HostName -eq $HostName)
        {
            $UniqueInstances += 1
        }
    }

    if($UniqueInstances -gt 1)
    {
        return $false
    }
    else
    {
        return $true
    }
}

# Helper function used to compare website bindings of actual to desired
# Returns true if bindings need to be updated and false if not.
function Test-WebsiteBindings
{
    param
    (
        [parameter()]
        [string]
        $Name,

        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [Microsoft.Management.Infrastructure.CimInstance[]]
        $BindingInfo
    )

    foreach($binding in $BindingInfo)
    {
        # First ensure that desired binding information is valid ie. No duplicate IPAddres, Port, Host name combinations.

        if (!(Confirm-PortIPHostisUnique -Port $binding.Port -IPAddress $binding.IPAddress -HostName $binding.Hostname -BindingInfo $BindingInfo) )
        {
            $errorId = 'WebsiteBindingInputInvalidation'
            $errorCategory = [System.Management.Automation.ErrorCategory]::InvalidResult
            $errorMessage = $($LocalizedData.WebsiteBindingInputInvalidationError) -f ${Name}
            $exception = New-Object -TypeName System.InvalidOperationException -ArgumentList $errorMessage
            $errorRecord = New-Object -TypeName System.Management.Automation.ErrorRecord -ArgumentList $exception, $errorId, $errorCategory, $null

            $PSCmdlet.ThrowTerminatingError($errorRecord)
        }
    }

    # Assume bindings do not need updating
    $BindingNeedsUpdating = $false

    <#
        Currently there is a problem in the LCM where Get-WebBinding short circuts the verbose stream
        Write-Log can be changed to add the -File switch to log to a directory for troubleshooting.
        However it's pretty noisy so it's being left in but commented out.
    #>

    $ActualBindings = Get-WebBinding -Name $Name

    # Format Binding information: Split BindingInfo into individual Properties (IPAddress:Port:HostName)
    $ActualBindingObjects = @()

    foreach ($ActualBinding in $ActualBindings)
    {
        $ActualBindingObjects += Get-WebBindingObject -BindingInfo $ActualBinding
    }

    #Compare Actual Binding info ($FormatActualBindingInfo) to Desired($BindingInfo)
    try
    {
        if($BindingInfo.Count -le $ActualBindingObjects.Count)
        {
            foreach($binding in $BindingInfo)
            {
                $ActualBinding = $ActualBindingObjects | Where-Object -FilterScript {
                    $_.Port -eq $binding.CimInstanceProperties['Port'].Value
                }
                if ($ActualBinding -ne $null)
                {
                    if([string]$ActualBinding.Protocol -ne [string]$binding.CimInstanceProperties['Protocol'].Value)
                    {
                        Write-Log "Protocol is Incorrect" -File
                        $BindingNeedsUpdating = $true
                        break
                    }

                    if([string]$ActualBinding.IPAddress -ne [string]$binding.CimInstanceProperties['IPAddress'].Value)
                    {
                        # Special case where blank IPAddress is saved as "*" in the binding information.
                        if([string]$ActualBinding.IPAddress -eq '*' -AND [string]$binding.CimInstanceProperties['IPAddress'].Value -eq '')
                        {
                            #Do nothing
                        }
                        else
                        {
                            Write-Log "IP Address Incorrect" -File
                            $BindingNeedsUpdating = $true
                            break
                        }
                    }

                    if([string]$ActualBinding.HostName -ne [string]$binding.CimInstanceProperties['HostName'].Value)
                    {
                        Write-Log "HostName is incorrect" -File
                        $BindingNeedsUpdating = $true
                        break
                    }

                    if([string]$ActualBinding.CertificateThumbprint -ne [string]$binding.CimInstanceProperties['CertificateThumbprint'].Value)
                    {
                        Write-Log "CertificateThumbprint is incorrect" -File
                        Write-Log "Actual Binding: $($ActualBinding.CertificateThumbprint )" -File
                        Write-Log "Binding Value: $($binding.CimInstanceProperties['CertificateThumbprint'].Value)" -File
                        $BindingNeedsUpdating = $true
                        break
                    }

                    if(-not [string]::IsNullOrWhiteSpace([string]$ActualBinding.CertificateThumbprint) -and [string]$ActualBinding.CertificateStoreName -ne [string]$binding.CimInstanceProperties['CertificateStoreName'].Value)
                    {
                        Write-Log "Thumbprint is incorrect" -File
                        $BindingNeedsUpdating = $true
                        break
                    }

                    if(-not [string]::IsNullOrWhiteSpace([string]$binding.CimInstanceProperties['SSLFlags'].Value) -and [string]$ActualBinding.SSLFlags -ne [string]$binding.CimInstanceProperties['SSLFlags'].Value)
                    {
                        Write-Log "SSLFlags is incorrect" -File
                        $BindingNeedsUpdating = $true
                        break
                    }
                }
                else
                {
                    Write-Log "No bindings returned" -File
                    $BindingNeedsUpdating = $true
                    break
                }
            }
        }
        else
        {
            Write-Log "Binding Count is incorrect"
            $BindingNeedsUpdating = $true
        }

        return $BindingNeedsUpdating
    }
    catch
    {
        $errorId = 'WebsiteCompareFailure'
        $errorCategory = [System.Management.Automation.ErrorCategory]::InvalidResult
        $errorMessage = $($LocalizedData.WebsiteCompareFailureError) -f ${Name}
        $errorMessage += $_.Exception.Message
        $exception = New-Object -TypeName System.InvalidOperationException -ArgumentList $errorMessage
        $errorRecord = New-Object -TypeName System.Management.Automation.ErrorRecord -ArgumentList $exception, $errorId, $errorCategory, $null

        $PSCmdlet.ThrowTerminatingError($errorRecord)
    }
}

function Update-WebsiteBinding
{
    param
    (
        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Name,

        [parameter()]
        [Microsoft.Management.Infrastructure.CimInstance[]]
        $BindingInfo
    )

    #Need to clear the bindings before we can create new ones
    Clear-ItemProperty -Path IIS:\Sites\$Name -Name bindings -ErrorAction Stop

    foreach($binding in $BindingInfo)
    {
        $Protocol = $binding.CimInstanceProperties['Protocol'].Value
        $IPAddress = $binding.CimInstanceProperties['IPAddress'].Value
        $Port = $binding.CimInstanceProperties['Port'].Value
        $HostHeader = $binding.CimInstanceProperties['HostName'].Value
        $CertificateThumbprint = $binding.CimInstanceProperties['CertificateThumbprint'].Value
        $CertificateStoreName = $binding.CimInstanceProperties['CertificateStoreName'].Value
        $SSLFlags = $binding.CimInstanceProperties['SSLFlags'].Value

        $bindingParams = @{}
        $bindingParams.Add('-Name', $Name)
        $bindingParams.Add('-Port', $Port)

        #Set IP Address parameter
        if($IPAddress -ne $null)
        {
            $bindingParams.Add('-IPAddress', $IPAddress)
        }
        else # Default to any/all IP Addresses
        {
            $bindingParams.Add('-IPAddress', '*')
        }

        #Set protocol parameter
        if($Protocol -ne $null)
        {
            $bindingParams.Add('-Protocol', $Protocol)
        }
        else #Default to Http
        {
            $bindingParams.Add('-Protocol', 'http')
        }

        #Set Host parameter if it exists
        if($HostHeader -ne $null)
        {
            $bindingParams.Add('-HostHeader', $HostHeader)
        }

        if(-not [string]::IsNullOrWhiteSpace($SSLFlags))
        {
            $bindingParams.Add('-SSLFlags', $SSLFlags)
        }

        try
        {
            New-WebBinding @bindingParams -ErrorAction Stop
        }
        catch
        {
            $errorId = 'WebsiteBindingUpdateFailure'
            $errorCategory = [System.Management.Automation.ErrorCategory]::InvalidResult
            $errorMessage = $($LocalizedData.WebsiteBindingUpdateFailureError) -f ${Name}
            $errorMessage += $_.Exception.Message
            $exception = New-Object -TypeName System.InvalidOperationException -ArgumentList $errorMessage
            $errorRecord = New-Object -TypeName System.Management.Automation.ErrorRecord -ArgumentList $exception, $errorId, $errorCategory, $null

            $PSCmdlet.ThrowTerminatingError($errorRecord)
        }

        try
        {
            if ( -not [string]::IsNullOrWhiteSpace($CertificateThumbprint) )
            {
                $NewWebbinding = Get-WebBinding -Name $Name -Port $Port
                $NewWebbinding.AddSslCertificate($CertificateThumbprint, $CertificateStoreName)
            }
        }
        catch
        {
            $errorId = 'WebBindingCertifcateError'
            $errorCategory = [System.Management.Automation.ErrorCategory]::InvalidOperation
            $errorMessage = $($LocalizedData.WebBindingCertifcateError) -f ${CertificateThumbprint}
            $errorMessage += $_.Exception.Message
            $exception = New-Object -TypeName System.InvalidOperationException -ArgumentList $errorMessage
            $errorRecord = New-Object -TypeName System.Management.Automation.ErrorRecord -ArgumentList $exception, $errorId, $errorCategory, $null

            $PSCmdlet.ThrowTerminatingError($errorRecord)
        }
    }
}

function Get-WebBindingObject
{
    param
    (
        $BindingInfo
    )

    #First split properties by ']:'. This will get IPv6 address split from port and host name
    $Split = $BindingInfo.BindingInformation.split('[]')
    if($Split.count -gt 1)
    {
        $IPAddress = $Split.item(1)
        $Port = $Split.item(2).split(':').item(1)
        $HostName = $Split.item(2).split(':').item(2)
    }
    else
    {
        $SplitProps = $BindingInfo.BindingInformation.split(':')
        $IPAddress = $SplitProps.item(0)
        $Port = $SplitProps.item(1)
        $HostName = $SplitProps.item(2)
    }

    return New-Object -TypeName PSObject -Property @{
        Protocol              = $BindingInfo.protocol
        IPAddress             = $IPAddress
        Port                  = $Port
        HostName              = $HostName
        CertificateThumbprint = $BindingInfo.CertificateHash
        CertificateStoreName  = $BindingInfo.CertificateStoreName
        sslFlags              = $BindingInfo.sslFlags
    }
}

# Helper function used to Update default pages of website
function Update-DefaultPages
{
    param
   (
        [string] $Name,

        [string[]] $DefaultPage
    )

    $allDefaultPage = @(Get-WebConfiguration //defaultDocument/files/* -PSPath (Join-Path -Path 'IIS:\sites\' -ChildPath $Name) | ForEach-Object -Process {
        Write-Output -InputObject $_.value
    })

    foreach($page in $DefaultPage)
    {
        if(-not ($allDefaultPage -icontains $page))
        {
            Write-Verbose -Message ("Deafult page for website $Name has been updated to $page")
            Add-WebConfiguration //defaultDocument/files -PSPath (Join-Path -Path 'IIS:\sites\' -ChildPath $Name) -Value @{
                value = $page
            }
        }
    }
}

function Write-Log
{
    param
    (
        [parameter(Position=1)]
        [string]
        $Message,

        [switch] $File
    )

    $filename = "$env:tmp\xWebSite.log"

    Write-Verbose -Verbose -Message $message

    if ($File)
    {
        $date = Get-Date
        "${date}: $message" | Out-File -Append -FilePath $filename
    }
}

#endregion
