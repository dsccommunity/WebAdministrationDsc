# Localized messages
data LocalizedData
{
    # culture="en-US"
    ConvertFrom-StringData -StringData @'
    ModuleNotFound                                  = Please ensure that the PowerShell module for role {0} is installed.
    ErrorWebsiteNotFound                            = The requested website "{0}" cannot be found on the target machine.
    ErrorWebsiteBindingUpdateFailure                = Failure to successfully update the bindings for website "{0}". Error: "{1}".
    ErrorWebsiteBindingInputInvalidation            = Desired website bindings are not valid for website "{0}".
    ErrorWebsiteCompareFailure                      = Failure to successfully compare properties for website "{0}". Error: "{1}".
    ErrorWebBindingCertificate                      = Failure to add certificate to web binding. Please make sure that the certificate thumbprint "{0}" is valid. Error: "{1}".
    ErrorWebsiteStateFailure                        = Failure to successfully set the state of the website "{0}". Error: "{1}".
    ErrorWebsiteBindingConflictOnStart              = Website "{0}" could not be started due to binding conflict. Ensure that the binding information for this website does not conflict with any existing websites bindings before trying to start it.
    ErrorWebBindingInvalidIPAddress                 = Failure to validate the IPAddress property value "{0}". Error: "{1}".
    ErrorWebBindingInvalidPort                      = Failure to validate the Port property value "{0}". The port number must be a positive integer between 1 and 65535.
    ErrorWebBindingMissingBindingInformation        = The BindingInformation property is required for bindings of type "{0}".
    ErrorWebBindingMissingCertificateThumbprint     = The CertificateThumbprint property is required for bindings of type "{0}".
    ErrorWebBindingMissingSniHostName               = The HostName property is required for use with Server Name Indication.
    ErrorWebsitePreloadFailure                      = Failure to set Preload on Website "{0}". Error: "{1}".
    ErrorWebsiteAutoStartFailure                    = Failure to set AutoStart on Website "{0}". Error: "{1}".
    ErrorWebsiteAutoStartProviderFailure            = Failure to set AutoStartProvider on Website "{0}". Error: "{1}".
    ErrorWebsiteTestAutoStartProviderFailure        = Desired AutoStartProvider is not valid due to a conflicting Global Property. Ensure that the serviceAutoStartProvider is a unique key."
    ErrorWebApplicationTestAutoStartProviderFailure = Desired AutoStartProvider is not valid due to a conflicting Global Property. Ensure that the serviceAutoStartProvider is a unique key.
    VerboseUpdateDefaultPageUpdated                 = Default page for website "{0}" has been updated to "{1}".
    VerboseTestBindingInfoInvalidCatch              = Unable to validate BindingInfo: "{0}".
'@
}

#region internal functions

<#
.SYNOPSIS
    Internal function to throw terminating error with specified errroCategory, 
    errorId and errorMessage
#>
function New-TerminatingError
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory)]
        [String] $ErrorId,

        [Parameter(Mandatory)]
        [String] $ErrorMessage,

        [Parameter(Mandatory)]
        [System.Management.Automation.ErrorCategory] $ErrorCategory
    )

    $Exception = New-Object System.InvalidOperationException $ErrorMessage
    $ErrorRecord = New-Object System.Management.Automation.ErrorRecord `
                    $Exception, $ErrorId, $ErrorCategory, $null
    throw $ErrorRecord
}

<#
.SYNOPSIS
     Internal function to assert if the role specific module is installed or not
#>
function Assert-Module
{
    [CmdletBinding()]
    param
    (
        [String]$ModuleName = 'WebAdministration'
    )

    if(-not(Get-Module -Name $ModuleName -ListAvailable))
    {
        $ErrorMsg = $($LocalizedData.ModuleNotFound) -f $ModuleName
        New-TerminatingError -ErrorId 'ModuleNotFound' `
                             -ErrorMessage $ErrorMsg `
                             -ErrorCategory ObjectNotFound
    }

}

#endregion

#region Authentication Functions

<#
.SYNOPSIS
    Helper function used to validate that the authenticationProperties for an Application.
.PARAMETER Site
    Specifies the name of the Website.
.PARAMETER Name
    Specifies the name of the Application.
#>
function Get-AuthenticationInfo
{
    [CmdletBinding()]
    [OutputType([Microsoft.Management.Infrastructure.CimInstance])]
    param
    (
        [String] $Site,

        [String] $Application,

        [ValidateSet('Website','Application','Ftp')]
        [String] $IisType
    )

    switch($IisType)
    {
        Website
        {
            $authenticationProperties = @{}
            foreach ($type in @('Anonymous', 'Basic', 'Digest', 'Windows'))
            {
                $authenticationProperties[$type] = `
                    [String](Test-AuthenticationEnabled -Site $Site `
                                                        -IisType $IisType `
                                                        -Type $type)
            }

            return New-CimInstance `
                    -ClassName MSFT_xWebAuthenticationInformation `
                    -ClientOnly -Property $authenticationProperties
        }

        Application
        {
            $authenticationProperties = @{}
            foreach ($type in @('Anonymous', 'Basic', 'Digest', 'Windows'))
            {
                $authenticationProperties[$type] = `
                    [String](Test-AuthenticationEnabled -Site $Site `
                                                        -Application $Application `
                                                        -IisType $IisType `
                                                        -Type $type)
            }

            return New-CimInstance `
                    -ClassName MSFT_xWebApplicationAuthenticationInformation `
                    -ClientOnly -Property $authenticationProperties
        }

        Ftp
        {
            $authenticationProperties = @{}
            foreach ($type in @('Anonymous', 'Basic'))
            {
                $authenticationProperties[$type] = `
                    [String](Test-AuthenticationEnabled -Site $Site `
                                                        -IisType $IisType `
                                                        -Type $type)
            }

            return New-CimInstance `
                    -ClassName MSFT_xFtpAuthenticationInformation `
                    -ClientOnly -Property $authenticationProperties
        }
    }
}

<#
.SYNOPSIS
    Helper function used to build a default CimInstance for AuthenticationInformation
#>
function Get-DefaultAuthenticationInfo
{
    [CmdletBinding()]
    param
    (
        [ValidateSet('Website','Application','Ftp')]
        [String] $IisType
    )

    switch($IisType)
    {
        Website
        {
            New-CimInstance -ClassName MSFT_xWebAuthenticationInformation `
                -ClientOnly `
                -Property @{Anonymous=$false;Basic=$false;Digest=$false;Windows=$false}
        }

        Application
        {
            New-CimInstance -ClassName MSFT_xWebApplicationAuthenticationInformation `
                -ClientOnly `
                -Property @{Anonymous=$false;Basic=$false;Digest=$false;Windows=$false}
        }

        Ftp
        {
            New-CimInstance -ClassName MSFT_xFTPAuthenticationInformation `
                -ClientOnly `
                -Property @{Anonymous=$false;Basic=$false}
        }
    }
}

<#
.SYNOPSIS
    Helper function used to set authenticationProperties for an Application.
.PARAMETER Site
    Specifies the name of the Website.
.PARAMETER Name
    Specifies the name of the Application.
.PARAMETER Type
    Specifies the type of Authentication, 
    Limited to the set: ('Anonymous','Basic','Digest','Windows').
.PARAMETER Enabled
    Whether the Authentication is enabled or not.
#>
function Set-Authentication
{
    [CmdletBinding()]
    param
    (
        [String] $Site,

        [String] $Application,

        [ValidateSet('Website','Application','Ftp')]
        [String] $IisType,

        [ValidateSet('Anonymous','Basic','Digest','Windows')]
        [String] $Type,

        [System.Boolean] $Enabled
    )

    switch($IisType)
    {
        {($_ -eq 'Website') -or ($_ -eq 'Ftp')}
        {
            Set-WebConfigurationProperty `
                -Filter /system.WebServer/security/authentication/${Type}Authentication `
                -Name enabled `
                -Value $Enabled `
                -Location "${Site}" 
        }

        Application
        {
            Set-WebConfigurationProperty `
                -Filter /system.WebServer/security/authentication/${Type}Authentication `
                -Name enabled `
                -Value $Enabled `
                -Location "${Site}/${Application}" 
        }
    }
}

<#
.SYNOPSIS
    Helper function used to validate that the authenticationProperties for an Application.
.PARAMETER Site
    Specifies the name of the Website.
.PARAMETER Name
    Specifies the name of the Application.
.PARAMETER AuthenticationInfo
    A CimInstance of what state the AuthenticationInfo should be.
#>
function Set-AuthenticationInfo
{
    [CmdletBinding()]
    param
    (
        [String] $Site,

        [String] $Application,

        [ValidateSet('Website','Application','Ftp')]
        [String ]$IisType,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [Microsoft.Management.Infrastructure.CimInstance] $AuthenticationInfo
    )

    switch($IisType)
    {
        Website
        {
            foreach ($type in @('Anonymous', 'Basic', 'Digest', 'Windows'))
            {
                $enabled = ($AuthenticationInfo.CimInstanceProperties[$type].Value -eq $true)
                Set-Authentication -Site $Site `
                                   -IisType $IisType `
                                   -Type $type `
                                   -Enabled $enabled
            }
        }

        Application
        {
            foreach ($type in @('Anonymous', 'Basic', 'Digest', 'Windows'))
            {
                $enabled = ($AuthenticationInfo.CimInstanceProperties[$type].Value -eq $true)
                Set-Authentication -Site $Site `
                                   -Application $Application `
                                   -IisType $IisType `
                                   -Type $type `
                                   -Enabled $enabled
            }
        }

        Ftp
        {
            foreach ($type in @('Anonymous', 'Basic'))
            {
                $enabled = ($AuthenticationInfo.CimInstanceProperties[$type].Value -eq $true)
                Set-Authentication -Site $Site `
                                   -IisType $IisType `
                                   -Type $type `
                                   -Enabled $enabled
            }
        }
    }
}

<#
.SYNOPSIS
    Helper function used to test the authenticationProperties state for an Application. 
    Will return that value which will either [String]True or [String]False
.PARAMETER Site
    Specifies the name of the Website.
.PARAMETER Name
    Specifies the name of the Application.
.PARAMETER Type
    Specifies the type of Authentication, 
    limited to the set: ('Anonymous','Basic','Digest','Windows').
#>
function Test-AuthenticationEnabled
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [String] $Site,

        [String] $Application,

        [ValidateSet('Website','Application','Ftp')]
        [String] $IisType,

        [ValidateSet('Anonymous','Basic','Digest','Windows')]
        [String] $Type
    )

    switch($IisType)
    {
        {($_ -eq 'Website') -or ($_ -eq 'Ftp')}
        {
            $prop = Get-WebConfigurationProperty `
                    -Filter /system.WebServer/security/authentication/${Type}Authentication `
                    -Name enabled `
                    -Location "${Site}"

            return $prop.Value
        }

        Application
        {
            $prop = Get-WebConfigurationProperty `
                    -Filter /system.WebServer/security/authentication/${Type}Authentication `
                    -Name enabled `
                    -Location "${Site}/${Name}"

            return $prop.Value
        }
    }
}

<#
.SYNOPSIS
    Helper function used to test the authenticationProperties state for an Application. 
    Will return that result which will either [boolean]$True or [boolean]$False for use in 
    Test-TargetResource.
    Uses Test-AuthenticationEnabled to determine this. First incorrect result will break 
    this function out.
.PARAMETER Site
    Specifies the name of the Website.
.PARAMETER Name
    Specifies the name of the Application.
.PARAMETER AuthenticationInfo
    A CimInstance of what state the AuthenticationInfo should be.
#>
function Test-AuthenticationInfo
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [String] $Site,

        [String] $Application,

        [ValidateSet('Website','Application','Ftp')]
        [String] $IisType,

        [ValidateNotNullOrEmpty()] 
        [Microsoft.Management.Infrastructure.CimInstance] $AuthenticationInfo
    )

    switch($IisType)
    {
        Website
        {
            foreach ($type in @('Anonymous', 'Basic', 'Digest', 'Windows'))
            {

            $expected = $AuthenticationInfo.CimInstanceProperties[$type].Value
            $actual = Test-AuthenticationEnabled -Site $Site `
                                                 -IisType $IisType `
                                                 -Type $type
                if ($expected -ne $actual)
                {
                    return $false
                }
            }
            return $true
        }

        Application
        {
            foreach ($type in @('Anonymous', 'Basic', 'Digest', 'Windows'))
            {

            $expected = $AuthenticationInfo.CimInstanceProperties[$type].Value
            $actual = Test-AuthenticationEnabled -Site $Site `
                                                 -Application $Application `
                                                 -IisType $IisType `
                                                 -Type $type
                if ($expected -ne $actual)
                {
                    return $false
                }
            }
            return $true
        }

        Ftp
        {
            foreach ($type in @('Anonymous', 'Basic'))
            {

            $expected = $AuthenticationInfo.CimInstanceProperties[$type].Value
            $actual = Test-AuthenticationEnabled -Site $Site `
                                                 -IisType $IisType `
                                                 -Type $type
                if ($expected -ne $actual)
                {
                    return $false
                }
            }
            return $true
        }
    }
}

#endregion

#region Log functions

<#
.SYNOPSIS
    Helper function used to validate that the logflags status.
    Returns False if the loglfags do not match and true if they do
.PARAMETER LogFlags
    Specifies flags to check
.PARAMETER Name
    Specifies website to check the flags on
#>
function Compare-LogFlags
{
    [CmdletBinding()]
    [OutputType([Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [String[]]
        [ValidateSet('Date','Time','ClientIP','UserName','SiteName','ComputerName','ServerIP','Method','UriStem','UriQuery','HttpStatus','Win32Status','BytesSent','BytesRecv','TimeTaken','ServerPort','UserAgent','Cookie','Referer','ProtocolVersion','Host','HttpSubStatus')]
        $LogFlags,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $Name

    )

    $CurrentLogFlags = (Get-Website -Name $Name).logfile.logExtFileFlags -split ',' | Sort-Object
    $ProposedLogFlags = $LogFlags -split ',' | Sort-Object

    if (Compare-Object -ReferenceObject $CurrentLogFlags -DifferenceObject $ProposedLogFlags)
    {
        return $false
    }

    return $true

}

#endregion

#region Autostart functions

<#
.SYNOPSIS
    Helper function used to validate that the AutoStartProviders is unique to other websites.
    returns False if the AutoStartProviders exist.
.PARAMETER serviceAutoStartProvider
    Specifies the name of the AutoStartProviders.
.PARAMETER ExcludeStopped
    Specifies the name of the Application Type for the AutoStartProvider.
.NOTES
    This tests for the existance of a AutoStartProviders which is globally assigned. 
    As AutoStartProviders need to be uniquely named it will check for this and error out if 
    attempting to add a duplicatly named AutoStartProvider.
    Name is passed in to bubble to any error messages during the test.
#>
function Confirm-UniqueServiceAutoStartProviders
{
    [CmdletBinding()]
    [OutputType([Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [String]
        $ServiceAutoStartProvider,

        [Parameter(Mandatory = $true)]
        [String]
        $ApplicationType
    )

    $WebSiteASP = (Get-WebConfiguration `
                   -filter /system.applicationHost/serviceAutoStartProviders).Collection

    $ExistingObject = $WebSiteASP | `
        Where-Object -Property Name -eq -Value $serviceAutoStartProvider | `
        Select-Object Name,Type

    $ProposedObject = @(New-Object -TypeName PSObject -Property @{
        name   = $ServiceAutoStartProvider
        type   = $ApplicationType
    })

    if(-not $ExistingObject)
        {
            return $false
        }

    if(-not (Compare-Object -ReferenceObject $ExistingObject `
                            -DifferenceObject $ProposedObject `
                            -Property name))
        {
            if(Compare-Object -ReferenceObject $ExistingObject `
                              -DifferenceObject $ProposedObject `
                              -Property type)
                {
                    $ErrorMessage = $LocalizedData.ErrorWebsiteTestAutoStartProviderFailure
                    New-TerminatingError -ErrorId 'ErrorWebsiteTestAutoStartProviderFailure' `
                                         -ErrorMessage $ErrorMessage `
                                         -ErrorCategory 'InvalidResult'`
                }
        }

    return $true

}

#endregion

#region DefaultPage functions

<#
.SYNOPSIS
    Helper function used to update default pages of website.
#>
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
        Get-WebConfiguration -Filter '//defaultDocument/files/*' `
                             -PSPath "IIS:\Sites\$Name" |
        ForEach-Object -Process {Write-Output -InputObject $_.value}
    )

    foreach ($Page in $DefaultPage)
    {
        if ($AllDefaultPages -inotcontains $Page)
        {
            Add-WebConfiguration -Filter '//defaultDocument/files' `
                                 -PSPath "IIS:\Sites\$Name" `
                                 -Value @{value = $Page}
            Write-Verbose -Message ($LocalizedData.VerboseUpdateDefaultPageUpdated `
                                    -f $Name, $Page)
        }
    }
}

#endregion

#region Bindings functions

<#
.SYNOPSIS
    Helper function used to validate that the website's binding information is unique to other 
    websites. Returns False if at least one of the bindings is already assigned to another 
    website.
.PARAMETER Name
    Specifies the name of the website.
.PARAMETER ExcludeStopped
    Omits stopped websites.
.NOTES
    This function tests standard ('http' and 'https') bindings only.
    It is technically possible to assign identical non-standard bindings (such as 'net.tcp') 
    to different websites.
#>
function Confirm-UniqueBinding
{
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
        $ErrorMessage = $LocalizedData.ErrorWebsiteNotFound `
                        -f $Name
        New-TerminatingError -ErrorId 'WebsiteNotFound' `
                             -ErrorMessage $ErrorMessage `
                             -ErrorCategory 'InvalidResult'
    }

    $ReferenceObject = @(
        $Website.bindings.Collection |
        Where-Object -FilterScript {$_.protocol -in @('http', 'https', 'ftp')} |
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
        Where-Object -FilterScript {$_.protocol -in @('http', 'https', 'ftp')} |
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

<#
.SYNOPSIS
    Converts IIS <binding> elements to instances of the MSFT_xWebBindingInformation CIM class.
#>
function ConvertTo-CimBinding
{
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

            if ($Binding.Protocol -in @('http', 'https', 'ftp'))
            {
                # Extract IPv6 address
                if ($Binding.bindingInformation -match '^\[(.*?)\]\:(.*?)\:(.*?)$') 
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

            New-CimInstance -ClassName $CimClassName `
                            -Namespace $CimNamespace `
                            -Property $CimProperties `
                            -ClientOnly
        }
    }
}

<#
.SYNOPSIS
    Converts instances of the MSFT_xWebBindingInformation CIM class to the IIS <binding> 
    element representation.
.LINK
    https://www.iis.net/configreference/system.applicationhost/sites/site/bindings/binding
#>
function ConvertTo-WebBinding
{
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
                if ($Binding.Protocol -in @('http', 'https', 'ftp'))
                {
                    if (-not [String]::IsNullOrEmpty($Binding.BindingInformation))
                    {
                        if (-not [String]::IsNullOrEmpty($Binding.IPAddress) -or
                            -not [String]::IsNullOrEmpty($Binding.Port) -or
                            -not [String]::IsNullOrEmpty($Binding.HostName)
                        )
                        {
                            $IsJoinRequired = $true
                            Write-Verbose -Message `
                                ($LocalizedData.VerboseConvertToWebBindingIgnoreBindingInformation `
                                -f $Binding.Protocol)
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
                        $IPAddressString = Format-IPAddressString -InputString $Binding.IPAddress `
                                                                   -ErrorAction Stop

                        if ([String]::IsNullOrEmpty($Binding.Port))
                        {
                            switch ($Binding.Protocol)
                            {
                                'http'  {$PortNumberString = '80'}
                                'https' {$PortNumberString = '443'}
                                'ftp'   {$PortNumberString = '21'}
                            }

                            Write-Verbose -Message `
                                ($LocalizedData.VerboseConvertToWebBindingDefaultPort `
                                -f $Binding.Protocol, $PortNumberString)
                        }
                        else
                        {
                            if (Test-PortNumber -InputString $Binding.Port)
                            {
                                $PortNumberString = $Binding.Port
                            }
                            else
                            {
                                $ErrorMessage = $LocalizedData.ErrorWebBindingInvalidPort `
                                                -f $Binding.Port
                                New-TerminatingError -ErrorId 'WebBindingInvalidPort' `
                                                     -ErrorMessage $ErrorMessage `
                                                     -ErrorCategory 'InvalidArgument'
                            }
                        }

                        $BindingInformation = $IPAddressString, `
                                              $PortNumberString, `
                                              $Binding.HostName -join ':'
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
                        $ErrorMessage = $LocalizedData.ErrorWebBindingMissingBindingInformation `
                                        -f $Binding.Protocol
                        New-TerminatingError -ErrorId 'WebBindingMissingBindingInformation' `
                                             -ErrorMessage $ErrorMessage `
                                             -ErrorCategory 'InvalidArgument'
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
                        $ErrorMessage = $LocalizedData.ErrorWebBindingMissingCertificateThumbprint `
                                        -f $Binding.Protocol
                        New-TerminatingError -ErrorId 'WebBindingMissingCertificateThumbprint' `
                                             -ErrorMessage $ErrorMessage `
                                             -ErrorCategory 'InvalidArgument'
                    }

                    if ([String]::IsNullOrEmpty($Binding.CertificateStoreName))
                    {
                        $CertificateStoreName = 'MY'
                        Write-Verbose -Message `
                            ($LocalizedData.VerboseConvertToWebBindingDefaultCertificateStoreName `
                            -f $CertificateStoreName)
                    }
                    else
                    {
                        $CertificateStoreName = $Binding.CertificateStoreName
                    }

                    # Remove the Left-to-Right Mark character
                    $CertificateHash = $Binding.CertificateThumbprint -replace '^\u200E'

                    $OutputObject.Add('certificateHash',      [String]$CertificateHash)
                    $OutputObject.Add('certificateStoreName', [String]$CertificateStoreName)

                    if ([Environment]::OSVersion.Version -ge '6.2')
                    {
                        $SslFlags = [Int64]$Binding.SslFlags

                        if ($SslFlags -in @(1, 3) -and [String]::IsNullOrEmpty($Binding.HostName))
                        {
                            $ErrorMessage = $LocalizedData.ErrorWebBindingMissingSniHostName
                            New-TerminatingError -ErrorId 'WebBindingMissingSniHostName' `
                                                 -ErrorMessage $ErrorMessage `
                                                 -ErrorCategory 'InvalidArgument'
                        }

                        $OutputObject.Add('sslFlags', $SslFlags)
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
                    WebAdministration can throw the following exception if there are non-standard 
                    bindings (such as 'net.tcp'): 'The data is invalid. 
                    (Exception from HRESULT: 0x8007000D)'

                    Steps to reproduce:
                    1) Add 'net.tcp' binding
                    2) Execute {Get-Website | `
                                ForEach-Object {$_.bindings.Collection} | `
                                Select-Object *}

                    Workaround is to create a new custom object and use dot notation to
                    access binding properties.
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

<#
.SYNOPSYS
    Formats the input IP address string for use in the bindingInformation attribute.
#>
function Format-IPAddressString
{

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
            $ErrorMessage = $LocalizedData.ErrorWebBindingInvalidIPAddress `
                            -f $InputString, $_.Exception.Message
            New-TerminatingError -ErrorId 'WebBindingInvalidIPAddress' `
                                 -ErrorMessage $ErrorMessage `
                                 -ErrorCategory 'InvalidArgument'
        }
    }

    return $OutputString
}

<#
.SYNOPSYS
    Validates the desired binding information (i.e. no duplicate IP address, port, and 
    host name combinations).
#>
function Test-BindingInfo
{
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
        $StandardBindings = @($Bindings | `
                                Where-Object -FilterScript {$_.Protocol -in @('http', 'https')})
        $NonStandardBindings = @($Bindings | `
                                 Where-Object -FilterScript {$_.Protocol -notin @('http', 'https')})

        if ($StandardBindings.Count -ne 0)
        {
            # IP address, port, and host name combination must be unique
            if (($StandardBindings | Group-Object -Property IPAddress, Port, HostName) | `
                                     Where-Object -FilterScript {$_.Count -ne 1})
            {
                $IsValid = $false
                Write-Verbose -Message `
                    ($LocalizedData.VerboseTestBindingInfoSameIPAddressPortHostName)
            }

            # A single port cannot be simultaneously specified for bindings with different protocols
            foreach ($GroupByPort in ($StandardBindings | Group-Object -Property Port))
            {
                if (($GroupByPort.Group | Group-Object -Property Protocol).Length -ne 1)
                {
                    $IsValid = $false
                    Write-Verbose -Message `
                        ($LocalizedData.VerboseTestBindingInfoSamePortDifferentProtocol)
                    break
                }
            }
        }

        if ($NonStandardBindings.Count -ne 0)
        {
            if (($NonStandardBindings | `
                Group-Object -Property Protocol, BindingInformation) | `
                Where-Object -FilterScript {$_.Count -ne 1})
            {
                $IsValid = $false
                Write-Verbose -Message `
                    ($LocalizedData.VerboseTestBindingInfoSameProtocolBindingInformation)
            }
        }
    }
    catch
    {
        $IsValid = $false
        Write-Verbose -Message ($LocalizedData.VerboseTestBindingInfoInvalidCatch `
                                -f $_.Exception.Message)
    }

    return $IsValid
}

<#
.SYNOPSYS
    Validates that an input string represents a valid port number.
    The port number must be a positive integer between 1 and 65535.
#>
function Test-PortNumber
{
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

<#
.SYNOPSIS
    Helper function used to validate and compare website bindings of current to desired.
    Returns True if bindings do not need to be updated.
#>
function Test-WebsiteBinding
{
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

    # Ensure that desired binding information is valid (i.e. no duplicate IP address, port, and 
    # host name combinations).
    if (-not (Test-BindingInfo -BindingInfo $BindingInfo))
    {
        $ErrorMessage = $LocalizedData.ErrorWebsiteBindingInputInvalidation `
                        -f $Name
        New-TerminatingError -ErrorId 'WebsiteBindingInputInvalidation' `
                             -ErrorMessage $ErrorMessage `
                             -ErrorCategory 'InvalidResult'
    }

    try
    {
        $Website = Get-Website | Where-Object -FilterScript {$_.Name -eq $Name}

        # Normalize binding objects to ensure they have the same representation
        $CurrentBindings = @(ConvertTo-WebBinding -InputObject $Website.bindings.Collection `
                                                   -Verbose:$false)
        $DesiredBindings = @(ConvertTo-WebBinding -InputObject $BindingInfo `
                                                  -Verbose:$false)

        $PropertiesToCompare = 'protocol', `
                               'bindingInformation', `
                               'certificateHash', `
                               'certificateStoreName'

        # The sslFlags attribute was added in IIS 8.0.
        # This check is needed for backwards compatibility with Windows Server 2008 R2.
        if ([Environment]::OSVersion.Version -ge '6.2')
        {
            $PropertiesToCompare += 'sslFlags'
        }

        if (Compare-Object -ReferenceObject $CurrentBindings `
                           -DifferenceObject $DesiredBindings `
                           -Property $PropertiesToCompare)
        {
            $InDesiredState = $false
        }
    }
    catch
    {
        $ErrorMessage = $LocalizedData.ErrorWebsiteCompareFailure `
                         -f $Name, $_.Exception.Message
        New-TerminatingError -ErrorId 'WebsiteCompareFailure' `
                             -ErrorMessage $ErrorMessage `
                             -ErrorCategory 'InvalidResult'
    }

    return $InDesiredState
}

<#
    .SYNOPSIS
        Updates website bindings.
    #>
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

    # Use Get-WebConfiguration instead of Get-Website to retrieve XPath of the target website.
    # XPath -Filter is case-sensitive. Use Where-Object to get the target website by name.
    $WebSite = Get-WebConfiguration -Filter '/system.applicationHost/sites/site' |
        Where-Object -FilterScript {$_.Name -eq $Name}

    if (-not $WebSite)
    {
        $ErrorMessage = $LocalizedData.ErrorWebsiteNotFound `
                        -f $Name
        New-TerminatingError -ErrorId 'WebsiteNotFound' `
                             -ErrorMessage $ErrorMessage `
                             -ErrorCategory 'InvalidResult'
    }

    ConvertTo-WebBinding -InputObject $BindingInfo -ErrorAction Stop |
    ForEach-Object -Begin {

        Clear-WebConfiguration -Filter "$($WebSite.ItemXPath)/bindings" -Force -ErrorAction Stop

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
            $ErrorMessage = $LocalizedData.ErrorWebsiteBindingUpdateFailure `
                            -f $Name, $_.Exception.Message
            New-TerminatingError -ErrorId 'WebsiteBindingUpdateFailure' `
                                 -ErrorMessage $ErrorMessage `
                                 -ErrorCategory 'InvalidResult'
        }

        if ($Properties.protocol -eq 'https')
        {
            if ([Environment]::OSVersion.Version -ge '6.2')
            {
                try
                {
                    Set-WebConfigurationProperty `
                        -Filter "$($Website.ItemXPath)/bindings/binding[last()]" `
                        -Name sslFlags `
                        -Value $Properties.sslFlags `
                        -Force `
                        -ErrorAction Stop
                }
                catch
                {
                    $ErrorMessage = $LocalizedData.ErrorWebsiteBindingUpdateFailure `
                                    -f $Name, $_.Exception.Message
                    New-TerminatingError `
                        -ErrorId 'WebsiteBindingUpdateFailure' `
                        -ErrorMessage $ErrorMessage `
                        -ErrorCategory 'InvalidResult'
                }
            }

            try
            {
                $Binding = Get-WebConfiguration `
                            -Filter "$($Website.ItemXPath)/bindings/binding[last()]" `
                            -ErrorAction Stop
                $Binding.AddSslCertificate($Properties.certificateHash, `
                                           $Properties.certificateStoreName)
            }
            catch
            {
                $ErrorMessage = $LocalizedData.ErrorWebBindingCertificate `
                                -f $Properties.certificateHash, $_.Exception.Message
                New-TerminatingError `
                    -ErrorId 'WebBindingCertificate' `
                    -ErrorMessage $ErrorMessage `
                    -ErrorCategory 'InvalidOperation'
            }
        }

    }

}

#endregion
