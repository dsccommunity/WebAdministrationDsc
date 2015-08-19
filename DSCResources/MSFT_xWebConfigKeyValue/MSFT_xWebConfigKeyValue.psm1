function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $WebsitePath,

        [parameter(Mandatory = $true)]
        [ValidateSet('AppSettings')]
        [System.String]
        $ConfigSection,

        [parameter(Mandatory = $true)]
        [String]
        $Key
    )

    $existingvalue = Get-ItemValue -key $Key -isAttribute $false -websitePath $WebsitePath -configSection $ConfigSection
    if($existingvalue -eq $null)
    {
        $existingvalue = Get-ItemValue -key $Key -isAttribute $true -websitePath $WebsitePath -configSection $ConfigSection
    }

    if($existingvalue.Length -eq 0)
    {
         return @{
             Ensure = 'Absent'
             Key = $Key
             Value = $existingvalue
        }
    }

    return @{
        Ensure = 'Present'
        Key = $Key
        Value = $existingvalue
    }
}


function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $WebsitePath,

        [parameter(Mandatory = $true)]
        [ValidateSet('AppSettings')]
        [System.String]
        $ConfigSection,

        [ValidateSet('Present','Absent')]
        [System.String]
        $Ensure = 'Present',

        [parameter(Mandatory = $true)]
        [String]
        $Key,

        [String]
        $Value,

        [System.Boolean]
        $IsAttribute
    )

    if($Ensure -eq 'Present')
    {
        $existingvalue = Get-ItemValue -key $Key -isAttribute $IsAttribute -websitePath $WebsitePath -configSection $ConfigSection

        if((!$IsAttribute -and ($existingvalue -eq $null)) -or ($IsAttribute -and ($existingvalue.Length -eq 0)))
        {
            Add-Item -key $Key -value $Value -isAttribute $IsAttribute -websitePath $WebsitePath -configSection $ConfigSection
        }
        else
        {
            $propertyName ='value'
            if($IsAttribute)
            {
                $propertyName = $Key
            }
            Modify-Item -propertyName $propertyName -oldValue $existingvalue -newValue $Value -isAttribute $IsAttribute -websitePath $WebsitePath -configSection $ConfigSection
        }
    }
    else
    {
        Remove-Item -key $Key -isAttribute $IsAttribute -websitePath $WebsitePath -configSection $ConfigSection
    }
}

function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $WebsitePath,

        [parameter(Mandatory = $true)]
        [ValidateSet('AppSettings')]
        [System.String]
        $ConfigSection,

        [ValidateSet('Present','Absent')]
        [System.String]
        $Ensure = 'Present',

        [parameter(Mandatory = $true)]
        [String]
        $Key,

        [String]
        $Value,

        [System.Boolean]
        $IsAttribute
    )

    if(!$PSBoundParameters.ContainsKey('IsAttribute'))
    {
        $IsAttribute = $false
    }

    $existingvalue = Get-ItemValue -key $Key -isAttribute $IsAttribute -websitePath $WebsitePath -configSection $ConfigSection
    
    if($Ensure -eq 'Present')
    {
        if(!$IsAttribute)
        {
            if(($existingvalue -eq $null) -or ($existingvalue -ne $Value))
            {
                return $false
            }
            else
            {
                return $true
            }
        }
        else
        {
            if(($existingvalue.Length -eq 0) -or ($existingvalue -ne $Value))
            {
                return $false
            }
            else
            {
                return $true
            }
        }
    }
    else
    {
        if(!$IsAttribute)
        {
            if(($existingvalue -eq $null))
            {
                return $true
            }
            else
            {
                return $false
            }
        }
        else
        {
            if(($existingvalue.Length -eq 0))
            {
                return $true
            }
            else
            {
                return $false
            }
        }
    }
}

function Add-item([string]$key, [string]$value, [Boolean]$isAttribute, [string]$websitePath, [string]$configSection)
{

    $defaultFilter = $configSection

    $itemCollection = @{key=$key;value=$value}

    if(!$isAttribute)
    {
        Add-WebConfigurationProperty -filter $defaultFilter -name '.' -value $itemCollection -PSPath $websitePath
    }
    else
    {
        Set-WebConfigurationProperty -filter $defaultFilter -PSPath $websitePath -name $key -value $value -WarningAction Stop 
    }
}

function Modify-Item([string]$propertyName, [string]$oldValue, [string]$newValue, [Boolean]$isAttribute, [string]$websitePath, [string]$configSection)
{
    $defaultFilter = $configSection

    if(!$isAttribute)
    {
        $filter= "$defaultFilter/add[@$propertyName=`'$oldValue`']"

        Set-WebConfigurationProperty -filter $filter -PSPath $websitePath -name $propertyName -value $newValue -WarningAction Stop
    }
    else
    {
        Set-WebConfigurationProperty -Filter $defaultFilter -PSPath $websitePath -name $propertyName -value $newValue -WarningAction Stop
    }
}

function Remove-Item([string]$key, [Boolean]$isAttribute, [string]$websitePath, [string]$configSection)
{
    $defaultFilter = $configSection

    if(!$isAttribute)
    {
        $filter = "$defaultFilter/add[@key=`'$key`']"

        Clear-WebConfiguration -Filter $filter -PSPath $websitePath -WarningAction Stop
    }
    else
    {
        $filter = "$defaultFilter/@$key"

        # this is a workaround to ensure if appSettings has no collection and we try to delete the only attribute, the entire node is not deleted.
        # if we try removing the only attribute even if there is one collection item, the node is preserved. I am not able to find a way to do this
        #using clear-webconfiguration alone.
        Add-item -key 'dummyKey' -value 'dummyValue' -isAttribute $false -websitePath $websitePath -configSection $configSection

        clear-WebConfiguration -filter $filter -PSPath $websitePath -WarningAction Stop

        Remove-Item -key 'dummyKey' -isAttribute $false -websitePath $websitePath -configSection $configSection
    }
}

function Get-ItemValue([string]$key, [Boolean]$isAttribute, [string]$websitePath, [string]$configSection)
{
    # if not present, $value.Value will be null
    $defaultFilter = $configSection

    if(!$isAttribute)
    {
        $filter = "$defaultFilter/add[@key=`'$key`']"

        $value = Get-WebConfigurationProperty -Filter $filter -Name 'value' -PSPath $websitePath
 
    }
    else
    {
        $value = Get-WebConfigurationProperty -filter $defaultFilter -name "$key" -PSPath $websitePath
    }
  
    return $value.Value
}

Export-ModuleMember -Function *-TargetResource




