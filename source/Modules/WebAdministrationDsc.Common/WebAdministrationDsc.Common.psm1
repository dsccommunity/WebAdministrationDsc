<#
    .SYNOPSIS
        Starts a process with a timeout.

    .PARAMETER FilePath
        String containing the path to the executable to start.

    .PARAMETER ArgumentList
        The arguments that should be passed to the executable.

    .PARAMETER Timeout
        The timeout in seconds to wait for the process to finish.

#>
function Start-ProcessWithTimeout
{
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $FilePath,

        [Parameter()]
        [System.String[]]
        $ArgumentList,

        [Parameter(Mandatory = $true)]
        [System.UInt32]
        $Timeout
    )

    $startProcessParameters = @{
        FilePath     = $FilePath
        ArgumentList = $ArgumentList
        PassThru     = $true
        NoNewWindow  = $true
        ErrorAction  = 'Stop'
    }

    $sqlSetupProcess = Start-Process @startProcessParameters

    Write-Verbose -Message ($script:localizedData.StartProcess -f $sqlSetupProcess.Id, $startProcessParameters.FilePath, $Timeout) -Verbose

    Wait-Process -InputObject $sqlSetupProcess -Timeout $Timeout -ErrorAction 'Stop'

    return $sqlSetupProcess.ExitCode
}

<#
    .SYNOPSIS
        This function is used to compare the current and the desired value of a
        property.

    .PARAMETER Values
        This is set to a hash table with the current value (the CurrentValue key)
        and desired value (the DesiredValue key).

    .EXAMPLE
        Test-DscPropertyState -Values @{
            CurrentValue = 'John'
            DesiredValue = 'Alice'
        }
    .EXAMPLE
        Test-DscPropertyState -Values @{
            CurrentValue = 1
            DesiredValue = 2
        }
#>
function Test-DscPropertyState
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.Collections.Hashtable]
        $Values
    )

    $returnValue = $true

    if ($Values.CurrentValue -ne $Values.DesiredValue -or $Values.DesiredValue.GetType().IsArray)
    {
        $desiredType = $Values.DesiredValue.GetType()

        if ($desiredType.IsArray -eq $true)
        {
            if ($Values.CurrentValue -and $Values.DesiredValue)
            {
                $compareObjectParameters = @{
                    ReferenceObject  = $Values.CurrentValue
                    DifferenceObject = $Values.DesiredValue
                }

                $arrayCompare = Compare-Object @compareObjectParameters

                if ($null -ne $arrayCompare)
                {
                    Write-Verbose -Message $script:localizedData.ArrayDoesNotMatch -Verbose

                    $arrayCompare |
                        ForEach-Object -Process {
                            Write-Verbose -Message ($script:localizedData.ArrayValueThatDoesNotMatch -f $_.InputObject, $_.SideIndicator) -Verbose
                        }

                    $returnValue = $false
                }
            }
            else
            {
                $returnValue = $false
            }
        }
        else
        {
            $returnValue = $false

            $supportedTypes = @(
                'String'
                'Int32'
                'UInt32'
                'Int16'
                'UInt16'
                'Single'
                'Boolean'
            )

            if ($desiredType.Name -notin $supportedTypes)
            {
                Write-Warning -Message ($script:localizedData.UnableToCompareType `
                        -f $fieldName, $desiredType.Name)
            }
            else
            {
                Write-Verbose -Message (
                    $script:localizedData.PropertyValueOfTypeDoesNotMatch `
                        -f $desiredType.Name, $Values.CurrentValue, $Values.DesiredValue
                ) -Verbose
            }
        }
    }

    return $returnValue
}

<#
    .SYNOPSIS
        This returns a new MSFT_Credential CIM instance credential object to be
        used when returning credential objects from Get-TargetResource.
        This returns a credential object without the password.

    .PARAMETER Credential
        The PSCredential object to return as a MSFT_Credential CIM instance
        credential object.

    .NOTES
        When returning a PSCredential object from Get-TargetResource, the
        credential object does not contain the username. The object is empty.

        Password UserName PSComputerName
        -------- -------- --------------
                          localhost

        When the MSFT_Credential CIM instance credential object is returned by
        the Get-TargetResource then the credential object contains the values
        provided in the object.

        Password UserName             PSComputerName
        -------- --------             --------------
                 COMPANY\TestAccount  localhost
#>
function New-CimCredentialInstance
{
    [CmdletBinding()]
    [OutputType([Microsoft.Management.Infrastructure.CimInstance])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        $Credential
    )

    $newCimInstanceParameters = @{
        ClassName = 'MSFT_Credential'
        ClientOnly = $true
        Namespace = 'root/microsoft/windows/desiredstateconfiguration'
        Property = @{
            UserName = [System.String] $Credential.UserName
            Password = [System.String] $null
        }
    }

    return New-CimInstance @newCimInstanceParameters
}

<#
    .SYNOPSIS
        This is used to get the current user context when the resource
        script runs.

    .NOTES
        We are putting this in a function so we can mock it with pester
#>
function Get-CurrentUser
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param ()

    return [System.Security.Principal.WindowsIdentity]::GetCurrent()
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
        # The Certificate Path is not valid
        New-InvalidArgumentException `
            -Message ($script:localizedData.CertificatePathError -f $certPath) `
            -ArgumentName 'Store'
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

    Write-Verbose -Message ($script:localizedData.SearchingForCertificateUsingFilters `
        -f $store, $certFilterScript)

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
        Internal function to throw terminating error with specified
        errorCategory, errorId and errorMessage

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
        [String] $ErrorId,

        [Parameter(Mandatory = $true)]
        [String] $ErrorMessage,

        [Parameter(Mandatory = $true)]
        [System.Management.Automation.ErrorCategory] $ErrorCategory
    )

    $exception = New-Object System.InvalidOperationException $ErrorMessage
    $errorRecord = New-Object System.Management.Automation.ErrorRecord `
                       $exception, $ErrorId, $ErrorCategory, $null
    throw $errorRecord
}

<#
    .SYNOPSIS
        Returns the value of a WebConfigurationProperty.

    .PARAMETER WebConfigurationPropertyObject
        Specifies the WebConfigurationProperty to return the value for.

    .NOTES
        This is a helper function because the type are not mocked.
#>
function Get-WebConfigurationPropertyValue
{
    [CmdletBinding()]
    [OutputType([PSObject])]
    param
    (
        [Parameter()]
        [PSObject]
        $WebConfigurationPropertyObject
    )

    if ($WebConfigurationPropertyObject -is [Microsoft.IIS.PowerShell.Framework.ConfigurationAttribute])
    {
        return $WebConfigurationPropertyObject.Value
    } else
    {
        return $WebConfigurationPropertyObject
    }
}

$script:localizedData = Get-LocalizedData -ResourceName 'WebAdministration.Common' -ScriptRoot $PSScriptRoot
