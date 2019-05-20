# Localized messages
data LocalizedData
{
    # culture="en-US"
    ConvertFrom-StringData -StringData @'
        ModuleNotFound                                        = Please ensure that the PowerShell module for role {0} is installed.
        ErrorWebsiteNotFound                                  = The requested website "{0}" cannot be found on the target machine.
        ErrorWebsiteBindingUpdateFailure                      = Failure to successfully update the bindings for website "{0}". Error: "{1}".
        ErrorWebsiteBindingInputInvalidation                  = Desired website bindings are not valid for website "{0}".
        ErrorWebsiteCompareFailure                            = Failure to successfully compare properties for website "{0}". Error: "{1}".
        ErrorWebBindingCertificate                            = Failure to add certificate to web binding. Please make sure that the certificate thumbprint "{0}" is valid. Error: "{1}".
        ErrorWebBindingInvalidCertificateSubject              = The Subject "{0}" provided is not found on this host in store "{1}"
        ErrorWebBindingInvalidIPAddress                       = Failure to validate the IPAddress property value "{0}". Error: "{1}".
        ErrorWebBindingInvalidPort                            = Failure to validate the Port property value "{0}". The port number must be a positive integer between 1 and 65535.
        ErrorWebBindingMissingBindingInformation              = The BindingInformation property is required for bindings of type "{0}".
        ErrorWebBindingMissingCertificateThumbprint           = The CertificateThumbprint property is required for bindings of type "{0}".
        ErrorWebBindingMissingSniHostName                     = The HostName property is required for use with Server Name Indication.
        ErrorWebsiteTestAutoStartProviderFailure              = Desired AutoStartProvider is not valid due to a conflicting Global Property. Ensure that the serviceAutoStartProvider is a unique key."
        VerboseConvertToWebBindingDefaultCertificateStoreName = CertificateStoreName is not specified. The default value "{0}" will be used.
        VerboseConvertToWebBindingDefaultPort                 = Port is not specified. The default "{0}" port "{1}" will be used.
        VerboseConvertToWebBindingIgnoreBindingInformation    = BindingInformation is ignored for bindings of type "{0}" in case at least one of the following properties is specified: IPAddress, Port, HostName.
        VerboseTestBindingInfoInvalidCatch                    = Unable to validate BindingInfo: "{0}".
        VerboseTestBindingInfoSameIPAddressPortHostName       = BindingInfo contains multiple items with the same IPAddress, Port, and HostName combination.
        VerboseTestBindingInfoSamePortDifferentProtocol       = BindingInfo contains items that share the same Port but have different Protocols.
        VerboseTestBindingInfoSameProtocolBindingInformation  = BindingInfo contains multiple items with the same Protocol and BindingInformation combination.
        VerboseUpdateDefaultPageUpdated                       = Default page for website "{0}" has been updated to "{1}".
'@
}

<#
    .SYNOPSIS
        Internal function to throw terminating error with specified
        errroCategory, errorId and errorMessage.

    .PARAMETER ErrorId
        Specifies the Id error message.

    .PARAMETER ErrorMessage
        Specifies full Error Message to be returned.

    .PARAMETER ErrorCategory
        Specifies Error Category.
#>
function New-TerminatingError
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [String]
        $ErrorId,

        [Parameter(Mandatory = $true)]
        [String]
        $ErrorMessage,

        [Parameter(Mandatory = $true)]
        [System.Management.Automation.ErrorCategory]
        $ErrorCategory
    )

    $exception = New-Object System.InvalidOperationException $ErrorMessage
    $errorRecord = New-Object System.Management.Automation.ErrorRecord `
                    $exception, $ErrorId, $ErrorCategory, $null
    throw $errorRecord
}

<#
    .SYNOPSIS
        Internal function to assert if the module exists.

    .PARAMETER ModuleName
        Module to test.
#>
function Assert-Module
{
    [CmdletBinding()]
    param
    (
        [Parameter()]
        [String]
        $ModuleName = 'WebAdministration'
    )

    if(-not(Get-Module -Name $ModuleName -ListAvailable))
    {
        $errorMsg = $($LocalizedData.ModuleNotFound) -f $ModuleName
        New-TerminatingError -ErrorId 'ModuleNotFound' `
                             -ErrorMessage $errorMsg `
                             -ErrorCategory ObjectNotFound
    }
}

<#
    .SYNOPSIS
        Locates one or more certificates using the passed certificate selector parameters.

        If more than one certificate is found matching the selector criteria, they will be
        returned in order of descending expiration date.

    .PARAMETER Thumbprint
        The thumbprint of the certificate to find.

    .PARAMETER FriendlyName
        The friendly name of the certificate to find.

    .PARAMETER Subject
        The subject of the certificate to find.

    .PARAMETER DNSName
        The subject alternative name of the certificate to export must contain these values.

    .PARAMETER Issuer
        The issuer of the certiicate to find.

    .PARAMETER KeyUsage
        The key usage of the certificate to find must contain these values.

    .PARAMETER EnhancedKeyUsage
        The enhanced key usage of the certificate to find must contain these values.

    .PARAMETER Store
        The Windows Certificate Store Name to search for the certificate in.
        Defaults to 'My'.

    .PARAMETER AllowExpired
        Allows expired certificates to be returned.
#>
function Find-Certificate
{
    [CmdletBinding()]
    [OutputType([System.Security.Cryptography.X509Certificates.X509Certificate2[]])]
    param
    (
        [Parameter()]
        [String]
        $Thumbprint,

        [Parameter()]
        [String]
        $FriendlyName,

        [Parameter()]
        [String]
        $Subject,

        [Parameter()]
        [String[]]
        $DNSName,

        [Parameter()]
        [String]
        $Issuer,

        [Parameter()]
        [String[]]
        $KeyUsage,

        [Parameter()]
        [String[]]
        $EnhancedKeyUsage,

        [Parameter()]
        [String]
        $Store = 'My',

        [Parameter()]
        [Boolean]
        $AllowExpired = $false
    )

    $certPath = Join-Path -Path 'Cert:\LocalMachine' -ChildPath $Store

    if (-not (Test-Path -Path $certPath))
    {
        # The Certificte Path is not valid
        New-InvalidArgumentError `
            -ErrorId 'CannotFindCertificatePath' `
            -ErrorMessage ($LocalizedData.CertificatePathError -f $certPath)
    } # if

    # Assemble the filter to use to select the certificate
    $certFilters = @()
    if ($PSBoundParameters.ContainsKey('Thumbprint'))
    {
        $certFilters += @('($_.Thumbprint -eq $Thumbprint)')
    } # if

    if ($PSBoundParameters.ContainsKey('FriendlyName'))
    {
        $certFilters += @('($_.FriendlyName -eq $FriendlyName)')
    } # if

    if ($PSBoundParameters.ContainsKey('Subject'))
    {
        $certFilters += @('(@(Compare-Object `
                            -ReferenceObject (($_.Subject -split ", ").trim()|sort-object) `
                            -DifferenceObject (($subject -split ",").trim()|sort-object)| `
                            Where-Object -Property SideIndicator -eq "=>").Count -eq 0)')
    } # if

    if ($PSBoundParameters.ContainsKey('Issuer'))
    {
        $certFilters += @('($_.Issuer -eq $Issuer)')
    } # if

    if (-not $AllowExpired)
    {
        $certFilters += @('(((Get-Date) -le $_.NotAfter) -and ((Get-Date) -ge $_.NotBefore))')
    } # if

    if ($PSBoundParameters.ContainsKey('DNSName'))
    {
        $certFilters += @('(@(Compare-Object `
                            -ReferenceObject $_.DNSNameList.Unicode `
                            -DifferenceObject $DNSName | `
                            Where-Object -Property SideIndicator -eq "=>").Count -eq 0)')
    } # if

    if ($PSBoundParameters.ContainsKey('KeyUsage'))
    {
        $certFilters += @('(@(Compare-Object `
                            -ReferenceObject ($_.Extensions.KeyUsages -split ", ") `
                            -DifferenceObject $KeyUsage | `
                            Where-Object -Property SideIndicator -eq "=>").Count -eq 0)')
    } # if

    if ($PSBoundParameters.ContainsKey('EnhancedKeyUsage'))
    {
        $certFilters += @('(@(Compare-Object `
                            -ReferenceObject ($_.EnhancedKeyUsageList.FriendlyName) `
                            -DifferenceObject $EnhancedKeyUsage | `
                            Where-Object -Property SideIndicator -eq "=>").Count -eq 0)')
    } # if

    # Join all the filters together
    $certFilterScript = '(' + ($certFilters -join ' -and ') + ')'

    Write-Verbose -Message ($LocalizedData.SearchingForCertificateUsingFilters `
        -f $store,$certFilterScript)

    $certs = Get-ChildItem -Path $certPath |
        Where-Object -FilterScript ([ScriptBlock]::Create($certFilterScript))

    # Sort the certificates
    if ($certs.count -gt 1)
    {
        $certs = $certs | Sort-Object -Descending -Property 'NotAfter'
    } # if

    return $certs
} # end function Find-Certificate

<#
    .SYNOPSIS
        Retrieves the localized string data based on the machine's culture.
        Falls back to en-US strings if the machine's culture is not supported.

    .PARAMETER ResourceName
        The name of the resource as it appears before '.strings.psd1' of the localized string file.

        For example:
            For WindowsOptionalFeature: MSFT_xWindowsOptionalFeature
            For Service: MSFT_xServiceResource
            For Registry: MSFT_xRegistryResource

    .PARAMETER ResourcePath
        The path the resource file is located in.
#>
function Get-LocalizedData
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $ResourceName,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $ResourcePath
    )

    $localizedStringFileLocation = Join-Path -Path $ResourcePath -ChildPath $PSUICulture

    if (-not (Test-Path -Path $localizedStringFileLocation))
    {
        # Fallback to en-US
        $localizedStringFileLocation = Join-Path -Path $ResourcePath -ChildPath 'en-US'
    }

    Import-LocalizedData `
        -BindingVariable 'localizedData' `
        -FileName "$ResourceName.strings.psd1" `
        -BaseDirectory $localizedStringFileLocation

    return $localizedData
}

#region Authentication Functions

<#
    .SYNOPSIS
        Helper function used to get the authentication properties
        for a Website,FTP Site or Application.

    .PARAMETER Site
        Specifies the name of the Website.

    .PARAMETER Application
        Specifies the name of the Application if IiisType is set to Application.

    .PARAMETER IisType
        Specifies type of the object to get authentication properties for.
        It could be a Website, FTP Site or Application.
#>
function Get-AuthenticationInfo
{
    [CmdletBinding()]
    [OutputType([Microsoft.Management.Infrastructure.CimInstance])]
    param
    (
        [Parameter(Mandatory = $true)]
        [String]
        $Site,

        [Parameter()]
        [String]
        $Application,

        [Parameter(Mandatory = $true)]
        [ValidateSet('Website','Application','Ftp')]
        [String]
        $IisType
    )

    $authAvailable = Get-DefaultAuthenticationInfo -IisType $IisType

    $authenticationProperties = @{}
    foreach ($type in ($authAvailable.CimInstanceProperties.Name | Sort-Object))
    {
        $authenticationProperties[$type] = `
            [Boolean](Test-AuthenticationEnabled @PSBoundParameters -Type $type)
    }

    return New-CimInstance -ClassName $authAvailable.CimClass.CimClassName `
                           -ClientOnly -Property $authenticationProperties `
                           -Namespace 'root/microsoft/Windows/DesiredStateConfiguration'
}

<#
    .SYNOPSIS
        Helper function used to build a default CimInstance of AuthenticationInformation
        for a Website,FTP Site or Application.

    .PARAMETER IisType
        Specifies type of the object to get default authentication properties for.
        It could be a Website, FTP Site or Application.
#>
function Get-DefaultAuthenticationInfo
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateSet('Website','Application','Ftp')]
        [String]
        $IisType
    )

    $cimNamespace = 'root/microsoft/Windows/DesiredStateConfiguration'
    switch($IisType)
    {
        Website
        {
            New-CimInstance -ClassName MSFT_xWebAuthenticationInformation `
                -ClientOnly -Namespace $cimNamespace `
                -Property @{Anonymous=$false;Basic=$false;Digest=$false;Windows=$false}
        }

        Application
        {
            New-CimInstance -ClassName MSFT_xWebApplicationAuthenticationInformation `
                -ClientOnly -Namespace $cimNamespace `
                -Property @{Anonymous=$false;Basic=$false;Digest=$false;Windows=$false}
        }

        Ftp
        {
            New-CimInstance -ClassName MSFT_FTPAuthenticationInformation `
                -ClientOnly -Namespace $cimNamespace `
                -Property @{Anonymous=$false;Basic=$false}
        }
    }
}

<#
    .SYNOPSIS
        Helper function used to set single authentication property
        for a Website,FTP Site or Application.

    .PARAMETER Site
        Specifies the name of the Website.

    .PARAMETER Application
        Specifies the name of the Application.

    .PARAMETER IisType
        Specifies type of the object to set authentication property on.
        It could be a Website, FTP Site or Application.

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
        [Parameter(Mandatory = $true)]
        [String]
        $Site,

        [Parameter()]
        [String]
        $Application,

        [Parameter(Mandatory = $true)]
        [ValidateSet('Website','Application','Ftp')]
        [String]
        $IisType,

        [Parameter(Mandatory = $true)]
        [ValidateSet('Anonymous','Basic','Digest','Windows')]
        [String]
        $Type,

        [Parameter()]
        [System.Boolean]
        $Enabled
    )

    $Location = "${Site}"

    if ($IisType -eq 'Application')
    {
        $Location = "${Site}/${Application}"
    }

    switch ($IisType)
    {
        'Ftp'   { Set-ItemProperty "IIS:\Sites\$Location" `
                    -Name ftpServer.security.authentication.${Type}Authentication.enabled `
                    -Value $Enabled
                }
        default { Set-WebConfigurationProperty `
                    -Filter /system.WebServer/security/authentication/${Type}Authentication `
                    -Name enabled `
                    -Value $Enabled `
                    -Location $Location
                }
    }
}

<#
    .SYNOPSIS
        Helper function used to set the authentication properties
        for a Website,FTP Site or Application.

    .PARAMETER Site
        Specifies the name of the Website.

    .PARAMETER Application
        Specifies the name of the Application.

    .PARAMETER IisType
        Specifies type of the object to set authentication properties for.
        It could be a Website, FTP Site or Application.

    .PARAMETER AuthenticationInfo
        A CimInstance of what state the AuthenticationInfo should be.
#>
function Set-AuthenticationInfo
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [String]
        $Site,

        [Parameter()]
        [String]
        $Application,

        [Parameter(Mandatory = $true)]
        [ValidateSet('Website','Application','Ftp')]
        [String]
        $IisType,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [Microsoft.Management.Infrastructure.CimInstance]
        $AuthenticationInfo
    )

    $Properties = ($AuthenticationInfo.CimInstanceProperties | Where-Object {$null -ne $_.Value}).Name | Sort-Object
    $PSBoundParameters.Remove('AuthenticationInfo') | Out-Null

    foreach ($type in $Properties)
    {
        $enabled = ($AuthenticationInfo.CimInstanceProperties[$type].Value -eq $true)
        Set-Authentication @PSBoundParameters -Type $type -Enabled $enabled
    }
}

<#
    .SYNOPSIS
        Helper function used to test authentication property state.
        Will return that value which will either [String]True or [String]False

    .PARAMETER Site
        Specifies the name of the Website.

    .PARAMETER Application
        Specifies the name of the Application.

    .PARAMETER IisType
        Specifies type of the object to tests authentication property for.
        It could be a Website, FTP Site or Application.

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
        [Parameter(Mandatory = $true)]
        [String]
        $Site,

        [Parameter()]
        [String]
        $Application,

        [Parameter(Mandatory = $true)]
        [ValidateSet('Website','Application','Ftp')]
        [String]
        $IisType,

        [Parameter(Mandatory = $true)]
        [ValidateSet('Anonymous','Basic','Digest','Windows')]
        [String]
        $Type
    )

    $Location = "${Site}"

    if ($IisType -eq 'Application')
    {
        $Location = "${Site}/${Application}"
    }

    $prop = switch ($IisType)
    {
        'Ftp'   { Get-ItemProperty "IIS:\Sites\$Location" `
                    -Name ftpServer.security.authentication.${Type}Authentication.enabled
                }
        default { Get-WebConfigurationProperty `
                    -Filter /system.WebServer/security/authentication/${Type}Authentication `
                    -Name enabled `
                    -Location $Location
                }
    }

    return $prop.Value
}

<#
    .SYNOPSIS
        Helper function used to test the authentication properties state.
        Will return that result which will either [boolean]$True or [boolean]$False for use in
        Test-TargetResource.
        Uses Test-AuthenticationEnabled to determine this. First incorrect result will break
        this function out.

    .PARAMETER Application
        Specifies the name of the Website.

    .PARAMETER Name
        Specifies the name of the Application.

    .PARAMETER IisType
        Specifies type of the object to tests authentication properties for.
        It could be a Website, FTP Site or Application.

    .PARAMETER AuthenticationInfo
        A CimInstance of what state the AuthenticationInfo should be.
#>
function Test-AuthenticationInfo
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [String]
        $Site,

        [Parameter()]
        [String]
        $Application,

        [Parameter(Mandatory = $true)]
        [ValidateSet('Website','Application','Ftp')]
        [String]
        $IisType,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [Microsoft.Management.Infrastructure.CimInstance]
        $AuthenticationInfo
    )

    $Properties = ($AuthenticationInfo.CimInstanceProperties | Where-Object {$null -ne $_.Value}).Name | Sort-Object
    $PSBoundParameters.Remove('AuthenticationInfo') | Out-Null

    foreach ($type in $Properties)
    {
        $expected = $AuthenticationInfo.CimInstanceProperties[$type].Value
        $actual = Test-AuthenticationEnabled @PSBoundParameters -Type $type

        if ($expected -ne $actual)
        {
            return $false
        }
    }

    return $true
}

#endregion

#region Log functions

<#
    .SYNOPSIS
        Helper function used to validate the logflags status.
        Returns False if the loglfags do not match and true if they do.

    .PARAMETER LogFlags
        Specifies flags to check.

    .PARAMETER Name
        Specifies website to check the flags on.

    .PARAMETER FtpSite
        Specifies whether current site is FTP site.
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
        $Name,

        [Parameter()]
        [Switch]
        $FtpSite
    )

    $CurrentLogFlags = switch($FtpSite.IsPresent)
    {
        $true   { (Get-Website -Name $Name).ftpServer.logFile.logExtFileFlags -split ',' | Sort-Object }
        default { (Get-Website -Name $Name).logfile.logExtFileFlags -split ',' | Sort-Object }
    }
    $ProposedLogFlags = $LogFlags -split ',' | Sort-Object

    if (Compare-Object -ReferenceObject $CurrentLogFlags -DifferenceObject $ProposedLogFlags)
    {
        return $false
    }

    return $true
}

<#
    .SYNOPSIS
        Converts IIS custom log field collection to instances of the MSFT_xLogCustomFieldInformation CIM class.
#>
function ConvertTo-CimLogCustomFields
{
    [CmdletBinding()]
    [OutputType([Microsoft.Management.Infrastructure.CimInstance[]])]
    param
    (
        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [AllowNull()]
        [Object[]]
        $InputObject
    )

    $cimClassName = 'MSFT_xLogCustomFieldInformation'
    $cimNamespace = 'root/microsoft/Windows/DesiredStateConfiguration'
    $cimCollection = New-Object -TypeName 'System.Collections.ObjectModel.Collection`1[Microsoft.Management.Infrastructure.CimInstance]'

    foreach ($customField in $InputObject)
    {
        $cimProperties = @{
            LogFieldName = $customField.LogFieldName
            SourceName   = $customField.SourceName
            SourceType   = $customField.SourceType
        }

        $cimCollection += (New-CimInstance -ClassName $cimClassName `
                        -Namespace $cimNamespace `
                        -Property $cimProperties `
                        -ClientOnly)
    }

    return $cimCollection
}

#endregion

#region Autostart functions

<#
    .SYNOPSIS
        Helper function used to validate that the AutoStartProviders is unique to other websites.
        returns False if the AutoStartProviders exist.

    .PARAMETER ServiceAutoStartProvider
        Specifies the name of the AutoStartProviders.

    .PARAMETER ApplicationType
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

        [Parameter()]
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
        $cimNamespace = 'root/microsoft/Windows/DesiredStateConfiguration'
    }
    process
    {
        foreach ($binding in $InputObject)
        {
            [Hashtable]$CimProperties = @{
                Protocol           = [String]$binding.protocol
                BindingInformation = [String]$binding.bindingInformation
            }

            $cimClassName = switch($CimProperties.Protocol)
            {
                'ftp'   { 'MSFT_FTPBindingInformation' }
                default { 'MSFT_xWebBindingInformation' }
            }

            if ($Binding.Protocol -in @('http', 'https', 'ftp'))
            {
                # Extract IPv6 address
                if ($binding.bindingInformation -match '^\[(.*?)\]\:(.*?)\:(.*?)$')
                {
                    $IPAddress = $Matches[1]
                    $Port      = $Matches[2]
                    $HostName  = $Matches[3]
                }
                else
                {
                    $IPAddress, $Port, $HostName = $binding.bindingInformation -split '\:'
                }

                if ([String]::IsNullOrEmpty($IPAddress))
                {
                    $IPAddress = '*'
                }

                $cimProperties.Add('IPAddress', [String]$IPAddress)
                $cimProperties.Add('Port',      [UInt16]$Port)
                $cimProperties.Add('HostName',  [String]$HostName)
            }
            else
            {
                $cimProperties.Add('IPAddress', [String]::Empty)
                $cimProperties.Add('Port',      [UInt16]::MinValue)
                $cimProperties.Add('HostName',  [String]::Empty)
            }

            if ($Binding.Protocol -ne 'ftp')
            {
                if ([Environment]::OSVersion.Version -ge '6.2')
                {
                    $cimProperties.Add('SslFlags', [String]$binding.sslFlags)
                }

                $cimProperties.Add('CertificateThumbprint', [String]$binding.certificateHash)
                $cimProperties.Add('CertificateStoreName',  [String]$binding.certificateStoreName)
            }

            New-CimInstance -ClassName $cimClassName `
                            -Namespace $cimNamespace `
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
        foreach ($binding in $InputObject)
        {
            $outputObject = @{
                protocol = $binding.Protocol
            }

            if ($binding -is [Microsoft.Management.Infrastructure.CimInstance])
            {
                if ($binding.Protocol -in @('http', 'https', 'ftp'))
                {
                    if (-not [String]::IsNullOrEmpty($binding.BindingInformation))
                    {
                        if (-not [String]::IsNullOrEmpty($binding.IPAddress) -or
                            -not [String]::IsNullOrEmpty($binding.Port) -or
                            -not [String]::IsNullOrEmpty($binding.HostName)
                        )
                        {
                            $isJoinRequired = $true
                            Write-Verbose -Message `
                                ($LocalizedData.VerboseConvertToWebBindingIgnoreBindingInformation `
                                -f $binding.Protocol)
                        }
                        else
                        {
                            $isJoinRequired = $false
                        }
                    }
                    else
                    {
                        $isJoinRequired = $true
                    }

                    # Construct the bindingInformation attribute
                    if ($isJoinRequired -eq $true)
                    {
                        $IPAddressString = Format-IPAddressString -InputString $binding.IPAddress `
                                                                   -ErrorAction Stop

                        if ([String]::IsNullOrEmpty($binding.Port))
                        {
                            switch ($binding.Protocol)
                            {
                                'http'  {$portNumberString = '80'}
                                'https' {$portNumberString = '443'}
                                'ftp'   {$portNumberString = '21'}
                            }

                            Write-Verbose -Message `
                                ($LocalizedData.VerboseConvertToWebBindingDefaultPort `
                                -f $binding.Protocol, $portNumberString)
                        }
                        else
                        {
                            if (Test-PortNumber -InputString $binding.Port)
                            {
                                $portNumberString = $binding.Port
                            }
                            else
                            {
                                $errorMessage = $LocalizedData.ErrorWebBindingInvalidPort `
                                                -f $binding.Port
                                New-TerminatingError -ErrorId 'WebBindingInvalidPort' `
                                                     -ErrorMessage $errorMessage `
                                                     -ErrorCategory 'InvalidArgument'
                            }
                        }

                        $bindingInformation = $IPAddressString, `
                                              $portNumberString, `
                                              $binding.HostName -join ':'
                        $outputObject.Add('bindingInformation', [String]$bindingInformation)
                    }
                    else
                    {
                        $outputObject.Add('bindingInformation', [String]$binding.BindingInformation)
                    }
                }
                else
                {
                    if ([String]::IsNullOrEmpty($binding.BindingInformation))
                    {
                        $errorMessage = $LocalizedData.ErrorWebBindingMissingBindingInformation `
                                        -f $binding.Protocol
                        New-TerminatingError -ErrorId 'WebBindingMissingBindingInformation' `
                                             -ErrorMessage $errorMessage `
                                             -ErrorCategory 'InvalidArgument'
                    }
                    else
                    {
                        $outputObject.Add('bindingInformation', [String]$binding.BindingInformation)
                    }
                }

                # SSL-related properties
                if ($binding.Protocol -eq 'https')
                {
                    if ([String]::IsNullOrEmpty($binding.CertificateThumbprint))
                    {
                        If ($Binding.CertificateSubject)
                        {
                            if ($binding.CertificateSubject.substring(0,3) -ne 'CN=')
                            {
                                $binding.CertificateSubject = "CN=$($Binding.CertificateSubject)"
                            }
                            $FindCertificateSplat = @{
                                Subject = $Binding.CertificateSubject
                            }
                        }
                        else
                        {
                            $errorMessage = $LocalizedData.ErrorWebBindingMissingCertificateThumbprint `
                                            -f $binding.Protocol
                            New-TerminatingError -ErrorId 'WebBindingMissingCertificateThumbprint' `
                                                -ErrorMessage $errorMessage `
                                                -ErrorCategory 'InvalidArgument'
                        }
                    }

                    if ([String]::IsNullOrEmpty($binding.CertificateStoreName))
                    {
                        $certificateStoreName = 'MY'
                        Write-Verbose -Message `
                            ($LocalizedData.VerboseConvertToWebBindingDefaultCertificateStoreName `
                            -f $certificateStoreName)
                    }
                    else
                    {
                        $certificateStoreName = $binding.CertificateStoreName
                    }

                    if ($FindCertificateSplat)
                    {
                        $FindCertificateSplat.Add('Store',$CertificateStoreName)
                        $Certificate = Find-Certificate @FindCertificateSplat
                        if ($Certificate)
                        {
                            $certificateHash = $Certificate.Thumbprint
                        }
                        else
                        {
                            $errorMessage = $LocalizedData.ErrorWebBindingInvalidCertificateSubject `
                                            -f $binding.CertificateSubject, $binding.CertificateStoreName
                            New-TerminatingError -ErrorId 'WebBindingInvalidCertificateSubject' `
                                                -ErrorMessage $errorMessage `
                                                -ErrorCategory 'InvalidArgument'
                        }
                    }

                    # Remove the Left-to-Right Mark character
                    if ($certificateHash)
                    {
                        $certificateHash = $certificateHash -replace '^\u200E'
                    }
                    else
                    {
                        $certificateHash = $binding.CertificateThumbprint -replace '^\u200E'
                    }

                    $outputObject.Add('certificateHash',      [String]$certificateHash)
                    $outputObject.Add('certificateStoreName', [String]$certificateStoreName)

                    if ([Environment]::OSVersion.Version -ge '6.2')
                    {
                        $SslFlags = [Int64]$binding.SslFlags

                        if ($SslFlags -in @(1, 3) -and [String]::IsNullOrEmpty($binding.HostName))
                        {
                            $errorMessage = $LocalizedData.ErrorWebBindingMissingSniHostName
                            New-TerminatingError -ErrorId 'WebBindingMissingSniHostName' `
                                                 -ErrorMessage $errorMessage `
                                                 -ErrorCategory 'InvalidArgument'
                        }

                        $outputObject.Add('sslFlags', $SslFlags)
                    }
                }
                elseif ($binding.Protocol -ne 'ftp')
                {
                    # Ignore SSL-related properties for non-SSL bindings
                    $outputObject.Add('certificateHash',      [String]::Empty)
                    $outputObject.Add('certificateStoreName', [String]::Empty)

                    if ([Environment]::OSVersion.Version -ge '6.2')
                    {
                        $outputObject.Add('sslFlags', [Int64]0)
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

                $outputObject.Add('bindingInformation',   [String]$binding.bindingInformation)

                if ($binding.Protocol -ne 'ftp')
                {
                    $outputObject.Add('certificateHash',      [String]$binding.certificateHash)
                    $outputObject.Add('certificateStoreName', [String]$binding.certificateStoreName)

                    if ([Environment]::OSVersion.Version -ge '6.2')
                    {
                        $outputObject.Add('sslFlags', [Int64]$binding.sslFlags)
                    }
                }
            }

            Write-Output -InputObject ([PSCustomObject]$outputObject)
        }
    }
}

<#
    .SYNOPSIS
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
        $outputString = '*'
    }
    else
    {
        $ipAddress = Test-IPAddress $InputString

        switch ($ipAddress.AddressFamily)
        {
            'InterNetwork'
            {
                $outputString = $ipAddress.IPAddressToString
            }
            'InterNetworkV6'
            {
                $outputString = '[{0}]' -f $ipAddress.IPAddressToString
            }
        }
    }

    return $outputString
}

<#
    .SYNOPSIS
        Validates the desired binding information (i.e. no duplicate IP address, port, and
        host name combinations).

    .PARAMETER BindingInfo
        CIM Instances of the binding information.
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

    $isValid = $true

    try
    {
        # Normalize the input (helper functions will perform additional validations)
        $bindings = @(ConvertTo-WebBinding -InputObject $bindingInfo | ConvertTo-CimBinding)
        $standardBindings = @($bindings | `
                                Where-Object -FilterScript {$_.Protocol -in @('http', 'https', 'ftp')})
        $nonStandardBindings = @($bindings | `
                                 Where-Object -FilterScript {$_.Protocol -notin @('http', 'https', 'ftp')})

        if ($standardBindings.Count -ne 0)
        {
            # IP address, port, and host name combination must be unique
            if (($standardBindings | Group-Object -Property IPAddress, Port, HostName) | `
                                     Where-Object -FilterScript {$_.Count -ne 1})
            {
                $isValid = $false
                Write-Verbose -Message `
                    ($LocalizedData.VerboseTestBindingInfoSameIPAddressPortHostName)
            }

            # A single port cannot be simultaneously specified for bindings with different protocols
            foreach ($groupByPort in ($standardBindings | Group-Object -Property Port))
            {
                if (($groupByPort.Group | Group-Object -Property Protocol).Length -ne 1)
                {
                    $isValid = $false
                    Write-Verbose -Message `
                        ($LocalizedData.VerboseTestBindingInfoSamePortDifferentProtocol)
                    break
                }
            }
        }

        if ($nonStandardBindings.Count -ne 0)
        {
            if (($nonStandardBindings | `
                Group-Object -Property Protocol, BindingInformation) | `
                Where-Object -FilterScript {$_.Count -ne 1})
            {
                $isValid = $false
                Write-Verbose -Message `
                    ($LocalizedData.VerboseTestBindingInfoSameProtocolBindingInformation)
            }
        }
    }
    catch
    {
        $isValid = $false
        Write-Verbose -Message ($LocalizedData.VerboseTestBindingInfoInvalidCatch `
                                -f $_.Exception.Message)
    }

    return $isValid
}

<#
    .SYNOPSIS
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
        Validates that an input string represents a valid IP address.
#>
function Test-IPAddress
{
    [CmdletBinding()]
    [OutputType([System.Net.IPAddress])]
    param (
        [Parameter(Mandatory = $true)]
        [System.String]
        $InputString
    )

    try
    {
        $ipAddress = [IPAddress]::Parse($InputString)
    }
    catch
    {
        $errorMessage = $LocalizedData.ErrorWebBindingInvalidIPAddress `
                        -f $InputString, $_.Exception.Message
        New-TerminatingError -ErrorId 'WebBindingInvalidIPAddress' `
                                -ErrorMessage $errorMessage `
                                -ErrorCategory 'InvalidArgument'
    }

    return $ipAddress
}

<#
    .SYNOPSIS
        Helper function used to validate and compare website bindings of current to desired.
        Returns True if bindings do not need to be updated.

    .PARAMETER Name
        Specifies name of the website.

    .PARAMETER BindingInfo
        CIM Instances of the binding information.
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

    $inDesiredState = $true

    <#
        Ensure that desired binding information is valid (i.e. no duplicate IP address, port, and
        host name combinations).
    #>
    if (-not (Test-BindingInfo -BindingInfo $BindingInfo))
    {
        $errorMessage = $LocalizedData.ErrorWebsiteBindingInputInvalidation `
                        -f $Name
        New-TerminatingError -ErrorId 'WebsiteBindingInputInvalidation' `
                             -ErrorMessage $errorMessage `
                             -ErrorCategory 'InvalidResult'
    }

    try
    {
        $website = Get-Website | Where-Object -FilterScript {$_.Name -eq $Name}

        # Normalize binding objects to ensure they have the same representation
        $currentBindings = @(ConvertTo-WebBinding -InputObject $website.bindings.Collection `
                                                   -Verbose:$false)
        $desiredBindings = @(ConvertTo-WebBinding -InputObject $BindingInfo `
                                                  -Verbose:$false)

        $propertiesToCompare = 'protocol', `
                               'bindingInformation', `
                               'certificateHash', `
                               'certificateStoreName'

        <#
            The sslFlags attribute was added in IIS 8.0.
            This check is needed for backwards compatibility with Windows Server 2008 R2.
        #>
        if ([Environment]::OSVersion.Version -ge '6.2')
        {
            $propertiesToCompare += 'sslFlags'
        }

        if (Compare-Object -ReferenceObject $currentBindings `
                           -DifferenceObject $desiredBindings `
                           -Property $propertiesToCompare)
        {
            $inDesiredState = $false
        }
    }
    catch
    {
        $errorMessage = $LocalizedData.ErrorWebsiteCompareFailure `
                         -f $Name, $_.Exception.Message
        New-TerminatingError -ErrorId 'WebsiteCompareFailure' `
                             -ErrorMessage $errorMessage `
                             -ErrorCategory 'InvalidResult'
    }

    return $inDesiredState
}

<#
    .SYNOPSIS
        Updates website bindings.

    .PARAMETER Name
        Specifies name of the website.

    .PARAMETER BindingInfo
        CIM Instances of the binding information.
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

        [Parameter()]
        [Microsoft.Management.Infrastructure.CimInstance[]]
        $BindingInfo
    )

    <#
        Use Get-WebConfiguration instead of Get-Website to retrieve XPath of the target website.
        XPath -Filter is case-sensitive. Use Where-Object to get the target website by name.
    #>
    $website = Get-WebConfiguration -Filter '/system.applicationHost/sites/site' |
        Where-Object -FilterScript {$_.Name -eq $Name}

    if (-not $website)
    {
        $errorMessage = $LocalizedData.ErrorWebsiteNotFound `
                        -f $Name
        New-TerminatingError -ErrorId 'WebsiteNotFound' `
                             -ErrorMessage $errorMessage `
                             -ErrorCategory 'InvalidResult'
    }

    ConvertTo-WebBinding -InputObject $BindingInfo -ErrorAction Stop |
    ForEach-Object -Begin {
        Clear-WebConfiguration -Filter "$($website.ItemXPath)/bindings" -Force -ErrorAction Stop
    } -Process {

        $properties = $_

        try
        {
            Add-WebConfiguration -Filter "$($website.ItemXPath)/bindings" -Value @{
                protocol = $properties.protocol
                bindingInformation = $properties.bindingInformation
            } -Force -ErrorAction Stop
        }
        catch
        {
            $errorMessage = $LocalizedData.ErrorWebsiteBindingUpdateFailure `
                            -f $Name, $_.Exception.Message
            New-TerminatingError -ErrorId 'WebsiteBindingUpdateFailure' `
                                 -ErrorMessage $errorMessage `
                                 -ErrorCategory 'InvalidResult'
        }

        if ($properties.protocol -eq 'https')
        {
            if ([Environment]::OSVersion.Version -ge '6.2')
            {
                try
                {
                    Set-WebConfigurationProperty `
                        -Filter "$($website.ItemXPath)/bindings/binding[last()]" `
                        -Name sslFlags `
                        -Value $properties.sslFlags `
                        -Force `
                        -ErrorAction Stop
                }
                catch
                {
                    $errorMessage = $LocalizedData.ErrorWebsiteBindingUpdateFailure `
                                    -f $Name, $_.Exception.Message
                    New-TerminatingError `
                        -ErrorId 'WebsiteBindingUpdateFailure' `
                        -ErrorMessage $errorMessage `
                        -ErrorCategory 'InvalidResult'
                }
            }

            try
            {
                $binding = Get-WebConfiguration `
                            -Filter "$($website.ItemXPath)/bindings/binding[last()]" `
                            -ErrorAction Stop
                $binding.AddSslCertificate($properties.certificateHash, `
                                           $properties.certificateStoreName)
            }
            catch
            {
                $errorMessage = $LocalizedData.ErrorWebBindingCertificate `
                                -f $properties.certificateHash, $_.Exception.Message
                New-TerminatingError `
                    -ErrorId 'WebBindingCertificate' `
                    -ErrorMessage $errorMessage `
                    -ErrorCategory 'InvalidOperation'
            }
        }
    }
}

#endregion
