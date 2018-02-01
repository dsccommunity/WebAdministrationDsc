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
    VerboseGetTargetCheckingTarget         = Checking for the existence of property "{0}" in collection item "{1}/{2}" with key "{3}={4}" using filter "{5}" located at "{6}".
    VerboseGetTargetItemNotFound           = Collection item "{0}/{1}" with key "{2}={3}" has not been found.
    VerboseGetTargetPropertyNotFound       = Property "{0}" has not been found.
    VerboseGetTargetPropertyFound          = Property "{0}" has been found.
    VerboseSetTargetCheckingTarget         = Checking for the existence of property "{0}" in collection item "{1}/{2}" with key "{3}={4}" using filter "{5}" located at "{6}".
    VerboseSetTargetAddItem                = Collection item "{0}/{1}" with key "{2}={3}" does not exist, adding with property "{4}".
    VerboseSetTargetEditItem               = Collection item "{0}/{1}" with key "{2}={3}" exists, editing property "{4}".
    VerboseSetTargetRemoveItem             = Property "{0}" exists, removing property.
    VerboseTestTargetCheckingTarget        = Checking for the existence of property "{0}" in collection item "{1}/{2}" with key "{3}={4}" using filter "{5}" located at "{6}".
    VerboseTestTargetItemNotFound          = Collection item "{0}/{1}" with key "{2}={3}" has not been found.
    VerboseTestTargetPropertyNotFound      = Property "{0}" has not been found.
    VerboseTestTargetPropertyValueNotFound = Property "{0}" has not been found with expected value.
    VerboseTestTargetPropertyFound         = Property "{0}" has been found.
'@
}

<#
.SYNOPSIS
    Gets the current value of the target resource property.

.PARAMETER WebsitePath
    Required. Path to website location (IIS or WebAdministration format).

.PARAMETER Filter
    Required. Filter used to locate property collection to update. Use '.' for root.

.PARAMETER CollectionName
    Required. Name of the property collection to update.

.PARAMETER ItemName
    Required. Name of the property collection item to update.

.PARAMETER ItemKeyName
    Required. Name of the key of the property collection item to update.

.PARAMETER ItemKeyValue
    Required. Value of the key of the property collection item to update.

.PARAMETER ItemPropertyName
    Required. Name of the property of the property collection item to update.
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
        $CollectionName,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $ItemName,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $ItemKeyName,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $ItemKeyValue,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $ItemPropertyName
    )
    process
    {
        # Retrieve the values of the existing property collection item if present.
        Write-Verbose `
            -Message ($LocalizedData.VerboseGetTargetCheckingTarget -f $ItemPropertyName, $CollectionName, $ItemName, $ItemKeyName, $ItemKeyValue, $Filter, $WebsitePath )

        $existingItem = Get-ItemValues `
                            -WebsitePath $WebsitePath `
                            -Filter $Filter `
                            -CollectionName $CollectionName `
                            -ItemName $ItemName `
                            -ItemKeyName $ItemKeyName `
                            -ItemKeyValue $ItemKeyValue
        
        $result = @{
            WebsitePath = $WebsitePath
            Filter = $Filter
            CollectionName = $CollectionName
            ItemName = $ItemName
            ItemKeyName = $ItemKeyName
            ItemKeyValue = $ItemKeyValue
        }

        if ($null -eq $existingItem)
        {
            # Property collection item with specified key was not found.
            Write-Verbose `
                -Message ($LocalizedData.VerboseGetTargetItemNotFound -f $CollectionName, $ItemName, $ItemKeyName, $ItemKeyValue )

            return $result + @{
                Ensure = 'Absent'
                ItemPropertyName = $ItemPropertyName
                ItemPropertyValue = $null
            }
        }
        if ($existingItem.Keys -notcontains $ItemPropertyName)
        {
            # Property collection item with specified key was found, but property was not present.
            Write-Verbose `
                -Message ($LocalizedData.VerboseGetTargetPropertyNotFound -f $ItemPropertyName )

            return $result + @{
                Ensure = 'Absent'
                ItemPropertyName = $ItemPropertyName
                ItemPropertyValue = $null
            }
        }
        # Property collection item with specified key was found.
        Write-Verbose `
            -Message ($LocalizedData.VerboseGetTargetPropertyFound -f $ItemPropertyName )

        return $result + @{
            Ensure = 'Present'
            ItemPropertyName = $ItemPropertyName
            ItemPropertyValue = $existingItem[$ItemPropertyName].ToString()
        }
    }
}

<#
.SYNOPSIS
    Sets the value of the target resource property.

.PARAMETER WebsitePath
    Required. Path to website location (IIS or WebAdministration format).

.PARAMETER Filter
    Required. Filter used to locate property collection to update. Use '.' for root.

.PARAMETER CollectionName
    Required. Name of the property collection to update.

.PARAMETER ItemName
    Required. Name of the property collection item to update.

.PARAMETER ItemKeyName
    Required. Name of the key of the property collection item to update.

.PARAMETER ItemKeyValue
    Required. Value of the key of the property collection item to update.

.PARAMETER ItemPropertyName
    Required. Name of the property of the property collection item to update.

.PARAMETER ItemPropertyValue
    Value of the property of the property collection item to update.

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
        $CollectionName,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $ItemName,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $ItemKeyName,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] 
        $ItemKeyValue,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $ItemPropertyName,

        [Parameter()]
        [string]
        $ItemPropertyValue,

        [Parameter()]
        [ValidateSet('Present','Absent')]
        [string]
        $Ensure = 'Present'
    )
    process
    {
        if ($Ensure -eq 'Present')
        {
            # Retrieve the values of the existing property collection item if present.
            Write-Verbose `
                -Message ($LocalizedData.VerboseSetTargetCheckingTarget -f $ItemPropertyName, $CollectionName, $ItemName, $ItemKeyName, $ItemKeyValue, $Filter, $WebsitePath )

            $existingItem = Get-ItemValues `
                                -WebsitePath $WebsitePath `
                                -Filter $Filter `
                                -CollectionName $CollectionName `
                                -ItemName $ItemName `
                                -ItemKeyName $ItemKeyName `
                                -ItemKeyValue $ItemKeyValue

            if (-not($existingItem))
            {
                # Property collection item with specified key was not found.
                Write-Verbose `
                    -Message ($LocalizedData.VerboseSetTargetAddItem -f $CollectionName, $ItemName, $ItemKeyName, $ItemKeyValue, $ItemPropertyName )

                $filter = "$($Filter)/$($CollectionName)"
                # Use Add- in this case to add the element (including the key/value) and also the specified property name/value.
                Add-WebConfigurationProperty `
                    -PSPath $WebsitePath `
                    -Filter $filter `
                    -Name '.' `
                    -Value $(@{$ItemKeyName=$ItemKeyValue;$ItemPropertyName=$ItemPropertyValue})
            }
            else
            {
                # Property collection item with specified key was found.
                Write-Verbose `
                    -Message ($LocalizedData.VerboseSetTargetEditItem -f $CollectionName, $ItemName, $ItemKeyName, $ItemKeyValue, $ItemPropertyName )

                $filter = "$($Filter)/$($CollectionName)/$($ItemName)[@$($ItemKeyName)='$($ItemKeyValue)']"
                # Use Set- in this case to update the specified property of the element with the specified key/value.
                Set-WebConfigurationProperty `
                    -PSPath $WebsitePath `
                    -Filter $filter `
                    -Name $ItemPropertyName `
                    -Value $ItemPropertyValue
            }
        }
        else
        {
            # Remove the specified property from the element with the specified key/value.
            Write-Verbose `
                -Message ($LocalizedData.VerboseSetTargetRemoveItem -f $ItemPropertyName )

            $filter = "$($Filter)/$($CollectionName)"
            Remove-WebConfigurationProperty `
                -PSPath $WebsitePath `
                -Filter $filter `
                -Name '.' `
                -AtElement @{$ItemKeyName=$ItemKeyValue}
        }
    }
}

<#
.SYNOPSIS
    Tests the value of the target resource property.

.PARAMETER WebsitePath
    Required. Path to website location (IIS or WebAdministration format).

.PARAMETER Filter
    Required. Filter used to locate property collection to update. Use '.' for root.

.PARAMETER CollectionName
    Required. Name of the property collection to update.

.PARAMETER ItemName
    Required. Name of the property collection item to update.

.PARAMETER ItemKeyName
    Required. Name of the key of the property collection item to update.

.PARAMETER ItemKeyValue
    Required. Value of the key of the property collection item to update.

.PARAMETER ItemPropertyName
    Required. Name of the property of the property collection item to update.

.PARAMETER ItemPropertyValue
    Value of the property of the property collection item to update.

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
        $CollectionName,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $ItemName,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $ItemKeyName,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $ItemKeyValue,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $ItemPropertyName,

        [Parameter()]
        [string]
        $ItemPropertyValue,

        [Parameter()]
        [ValidateSet('Present','Absent')]
        [string]
        $Ensure = 'Present'
    )
    process
    {
        # Retrieve the values of the existing property collection item if present.
        Write-Verbose `
            -Message ($LocalizedData.VerboseTestTargetCheckingTarget -f $ItemPropertyName, $CollectionName, $ItemName, $ItemKeyName, $ItemKeyValue, $Filter, $WebsitePath )

        $existingItem = Get-ItemValues `
                            -WebsitePath $WebsitePath `
                            -Filter $Filter `
                            -CollectionName $CollectionName `
                            -ItemName $ItemName `
                            -ItemKeyName $ItemKeyName `
                            -ItemKeyValue $ItemKeyValue

        if ($Ensure -eq 'Present')
        {
            if ($null -eq $existingItem)
            {
                # Property collection item with specified key was not found.
                Write-Verbose `
                   -Message ($LocalizedData.VerboseTestTargetItemNotFound -f $CollectionName, $ItemName, $ItemKeyName, $ItemKeyValue )

                return $false
            }
            if ($existingItem.Keys -notcontains $ItemPropertyName)
            {
                # Property collection item with specified key was found, but property was not present.
                Write-Verbose `
                   -Message ($LocalizedData.VerboseTestTargetPropertyNotFound -f $ItemPropertyName )

                return $false
            }
            if ($existingItem[$ItemPropertyName].ToString() -ne $ItemPropertyValue)
            {
                # Property collection item with specified key was found, but property did not have expected value.
                Write-Verbose `
                   -Message ($LocalizedData.VerboseTestTargetPropertyValueNotFound -f $ItemPropertyName )

                return $false
            }
            # Property collection item with specified key was found & had expected value.
            Write-Verbose `
                -Message ($LocalizedData.VerboseTestTargetPropertyFound -f $ItemPropertyName )

            return $true
        }
        else
        {
            if ( ($null -ne $existingItem) -and ($existingItem.Keys -contains $ItemPropertyName) )
            {
                # Property collection item with specified key was found & property was present.
                Write-Verbose `
                   -Message ($LocalizedData.VerboseTestTargetPropertyFound -f $ItemPropertyName )

                return $false
            }
            # Property collection item with specified key was either not found or property was not present.
            Write-Verbose `
                -Message ($LocalizedData.VerboseTestTargetPropertyNotFound -f $ItemPropertyName )

            return $true
        }
    }
}

# region Helper Functions

<#
.SYNOPSIS
    Gets the current values of the property collection item.

.PARAMETER WebsitePath
    Required. Path to website location (IIS or WebAdministration format).

.PARAMETER Filter
    Required. Filter used to locate property collection to retrieve. Use '.' for root.

.PARAMETER CollectionName
    Required. Name of the property collection to retrieve.

.PARAMETER ItemName
    Required. Name of the property collection item to retrieve.

.PARAMETER ItemKeyName
    Required. Name of the key of the property collection item to retrieve.

.PARAMETER ItemKeyValue
    Required. Value of the key of the property collection item to retrieve.
#>
function Get-ItemValues
{
    # Evaluated, choose not to.
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseSingularNouns", "")]
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
        $CollectionName,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $ItemName,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] 
        $ItemKeyName,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $ItemKeyValue
    )
    process
    {
        # Construct the complete filter we'll use to locate the collection item with the specified key/value in the property collection, then retrieve it if we can.
        $filter = "$($Filter)/$($CollectionName)/$($ItemName)[@$($ItemKeyName)='$($ItemKeyValue)']"

        $item = Get-WebConfigurationProperty `
                    -PSPath $WebsitePath `
                    -Filter $filter `
                    -Name "." `
                    -ErrorAction SilentlyContinue

        if ($item)
        {
            # If the property collection item exists, construct & return a hashtable containing the current values of all non-key properties.
            $result = @{}
            $item.Attributes.ForEach({ if ($_.Name -ne $ItemKeyName) { $result.Add($_.Name, $_.Value) } })
            return $result
        }
        return $null
    }
}

# endregion

Export-ModuleMember -Function *-TargetResource
