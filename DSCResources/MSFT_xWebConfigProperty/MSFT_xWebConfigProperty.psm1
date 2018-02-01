# Examples provided elsewhere.
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSDSCDscExamplesPresent", "")]
# Tests provided elsewhere.
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSDSCDscTestsPresent", "")]
param()

# Localized messages
data LocalizedData
{
    # culture="en-US"
    ConvertFrom-StringData -StringData @'
    VerboseGetTargetCheckingTarget    = Checking for the existence of property "{0}" using filter "{1}" located at "{2}".
    VerboseGetTargetAttributeCheck    = Checking if property "{0}" is an attribute.
    VerboseGetTargetPropertyNotFound  = Property "{0}" has not been found.
    VerboseGetTargetPropertyFound     = Property "{0}" has been found.
    VerboseSetTargetCheckingProperty  = Checking for existence of property "{0}".
    VerboseSetTargetAddItem           = Property "{0}" does not exist, adding property.
    VerboseSetTargetEditItem          = Property "{0}" exists, editing property.
    VerboseSetTargetRemoveItem        = Property "{0}" exists, removing property.
    VerboseTestTargetCheckingTarget   = Checking for the existence of property "{0}" using filter "{1}" located at "{2}".
    VerboseTestTargetPropertyNotFound = Property "{0}" has not been found.
    VerboseTestTargetPropertyWasFound = Property "{0}" has been found.
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
    process
    {
        # Retrieve the value of the existing property if present.
        Write-Verbose `
            -Message ($LocalizedData.VerboseGetTargetCheckingTarget -f $PropertyName, $Filter, $WebsitePath )

        $existingValue = Get-ItemValue `
                            -WebsitePath $WebsitePath `
                            -Filter $Filter `
                            -PropertyName $PropertyName

        if (-not($existingValue))
        {
            # Property was not found.
            Write-Verbose `
                -Message ($LocalizedData.VerboseGetTargetPropertyNotFound -f $PropertyName )

             return @{
                 Ensure = 'Absent'
                 PropertyName = $PropertyName
                 Value = $existingValue
            }
        }

        # Property was found.
        Write-Verbose `
            -Message ($LocalizedData.VerboseGetTargetPropertyFound -f $PropertyName )

        return @{
            Ensure = 'Present'
            PropertyName = $PropertyName
            Value = $existingValue
        }
    }
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
    # ShouldProcess not implemented for custom DSC resource.
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "")]
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
    process
    {
        if ($Ensure -eq 'Present')
        {
            # Property needs to be updated.
            Write-Verbose `
                -Message ($LocalizedData.VerboseSetTargetCheckingProperty -f $PropertyName )

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
    process
    {
        # Retrieve the value of the existing property if present.
        Write-Verbose `
            -Message ($LocalizedData.VerboseTestTargetCheckingTarget -f $PropertyName, $Filter, $WebsitePath )

        $existingValue = Get-ItemValue `
                            -WebsitePath $WebsitePath `
                            -Filter $Filter `
                            -PropertyName $PropertyName

        if ($Ensure -eq 'Present')
        {
            if ( ($null -eq $existingValue) -or ($existingValue.ToString() -ne $Value) )
            {
                # Property was not found or didn't have expected value.
                Write-Verbose `
                    -Message ($LocalizedData.VerboseTestTargetPropertyNotFound -f $PropertyName )

                return $false
            }
        }
        else
        {
            if ( ($null -ne $existingValue) -and ($existingValue.ToString().Length -ne 0 ) )
            {
                # Property was found.
                 Write-Verbose `
                    -Message ($LocalizedData.VerboseTestTargetPropertyWasFound -f $PropertyName )

                return $false
            }
        }

        Write-Verbose `
                -Message ($LocalizedData.VerboseTestTargetPropertyWasFound -f $PropertyName)

        return $true
    }
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
    process
    {
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
}

# endregion

Export-ModuleMember -Function *-TargetResource
