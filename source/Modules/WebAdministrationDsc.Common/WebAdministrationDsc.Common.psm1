$modulePath = Join-Path -Path (Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent) -ChildPath 'Modules'
Import-Module -Name (Join-Path -Path $modulePath -ChildPath 'DscResource.Common')

# Import Localization Strings
$script:localizedData = Get-LocalizedData -DefaultUICulture 'en-US'

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
