# Localized messages
data LocalizedData
{
    # culture="en-US"
    ConvertFrom-StringData -StringData @'
    VerboseTargetCheckingTarget       = Checking for the existence of property "{0}" using filter "{1}" located at "{2}".
    VerboseTargetPropertyNotFound     = Property "{0}" has not been found.
    VerboseTargetPropertyFound        = Property "{0}" has been found.
    VerboseSetTargetEditItem          = Ensuring property "{0}" is set.
    VerboseSetTargetRemoveItem        = Property "{0}" exists, removing property.
'@
}

<#
.SYNOPSIS
    Gets the current value of the target resource property.

.PARAMETER WebsitePath
    Required. Path to website location (IIS or WebAdministration format).

.PARAMETER Filter
    Required. Filter used to locate property to update.

.PARAMETER PropertyName
    Required. Name of the property to update.
#>
function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $WebsitePath,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Filter,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $PropertyName
    )
    # Retrieve the value of the existing property if present.
    Write-Verbose `
        -Message ($LocalizedData.VerboseTargetCheckingTarget -f $PropertyName, $Filter, $WebsitePath )

    $existingValue = Get-ItemValue `
                        -WebsitePath $WebsitePath `
                        -Filter $Filter `
                        -PropertyName $PropertyName

    $result = @{
        WebsitePath = $WebsitePath
        Filter = $Filter
        PropertyName = $PropertyName
        Ensure = 'Present'
        Value = $existingValue
    }

    if (-not($existingValue))
    {
        # Property was not found.
        Write-Verbose `
            -Message ($LocalizedData.VerboseTargetPropertyNotFound -f $PropertyName )

        $result.Ensure = 'Absent'
    }
    else
    {
        # Property was found.
        Write-Verbose `
            -Message ($LocalizedData.VerboseTargetPropertyFound -f $PropertyName )
    }

    return $result
}

<#
.SYNOPSIS
    Sets the value of the target resource property.

.PARAMETER WebsitePath
    Required. Path to website location (IIS or WebAdministration format).

.PARAMETER Filter
    Required. Filter used to locate property to update.

.PARAMETER PropertyName
    Required. Name of the property to update.

.PARAMETER Value
    Value of the property to update.

.PARAMETER Ensure
    Present or Absent. Defaults to Present.
#>
function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $WebsitePath,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Filter,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $PropertyName,

        [Parameter()]
        [string]
        $Value,

        [Parameter()]
        [ValidateSet('Present','Absent')]
        [string]
        $Ensure = 'Present'
    )
    if ($Ensure -eq 'Present')
    {
        # Property needs to be updated.
        Write-Verbose `
            -Message ($LocalizedData.VerboseSetTargetEditItem -f $PropertyName )

        Set-WebConfigurationProperty `
            -Filter $Filter `
            -PSPath $WebsitePath `
            -Name $PropertyName `
            -Value $Value `
            -WarningAction Stop
    }
    else
    {
        # Property needs to be removed.
        Write-Verbose `
            -Message ($LocalizedData.VerboseSetTargetRemoveItem -f $PropertyName )

        Clear-WebConfiguration `
                -Filter "$($Filter)/@$($PropertyName)" `
                -PSPath $WebsitePath `
                -WarningAction Stop
    }
}

<#
.SYNOPSIS
    Tests the value of the target resource property.

.PARAMETER WebsitePath
    Required. Path to website location (IIS or WebAdministration format).

.PARAMETER Filter
    Required. Filter used to locate property to update.

.PARAMETER PropertyName
    Required. Name of the property to update.

.PARAMETER Value
    Value of the property to update.

.PARAMETER Ensure
    Present or Absent. Defaults to Present.
#>
function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $WebsitePath,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Filter,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $PropertyName,

        [Parameter()]
        [string]
        $Value,

        [Parameter()]
        [ValidateSet('Present','Absent')]
        [string]
        $Ensure = 'Present'
    )
    # Retrieve the value of the existing property if present.
    Write-Verbose `
        -Message ($LocalizedData.VerboseTargetCheckingTarget -f $PropertyName, $Filter, $WebsitePath )

    $targetResource = Get-TargetResource `
                        -WebsitePath $WebsitePath `
                        -Filter $Filter `
                        -PropertyName $PropertyName

    if ($Ensure -eq 'Present')
    {
        if ( ($null -eq $targetResource.Value) -or ($targetResource.Value.ToString() -ne $Value) )
        {
            # Property was not found or didn't have expected value.
            Write-Verbose `
                -Message ($LocalizedData.VerboseTargetPropertyNotFound -f $PropertyName )

            return $false
        }
    }
    else
    {
        if ( ($null -ne $targetResource.Value) -and ($targetResource.Value.ToString().Length -ne 0 ) )
        {
            # Property was found.
                Write-Verbose `
                -Message ($LocalizedData.VerboseTargetPropertyWasFound -f $PropertyName )

            return $false
        }
    }

    Write-Verbose `
            -Message ($LocalizedData.VerboseTargetPropertyWasFound -f $PropertyName)

    return $true
}

# region Helper Functions

<#
.SYNOPSIS
    Gets the current value of the property.

.PARAMETER WebsitePath
    Required. Path to website location (IIS or WebAdministration format).

.PARAMETER Filter
    Required. Filter used to locate property to retrieve.

.PARAMETER PropertyName
    Required. Name of the property to retrieve.
#>
function Get-ItemValue
{
    [CmdletBinding()]
    [OutputType([System.Object])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $WebsitePath,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Filter,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $PropertyName
    )
    # Retrieve the value of the specified property if present.
    $value = Get-WebConfigurationProperty `
                -PSPath $WebsitePath `
                -Filter $Filter `
                -Name $PropertyName

    # Return the value of the property if located.
    if ($value -is [Microsoft.IIs.PowerShell.Framework.ConfigurationAttribute])
    {
        return $value.Value
    }
    return $value
}

# endregion

Export-ModuleMember -Function *-TargetResource
