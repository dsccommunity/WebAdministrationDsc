# Load the Helper Module
Import-Module -Name "$PSScriptRoot\..\Helper.psm1"

# Localized messages
data LocalizedData
{
    # culture="en-US"
    ConvertFrom-StringData -StringData @'
        VerboseGetTargetPresent = MIMEType is present
        VerboseGetTargetAbsent  = MIMEType is absent
'@
}

function Get-TargetResource
{
    <#
    .SYNOPSIS
        This will return a hashtable of results 
    #>

    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [String] $WebsitePath,

        [Parameter(Mandatory = $true)]
        [ValidateSet('AppSettings')]
        [String] $ConfigSection,

        [Parameter(Mandatory = $true)]
        [String] $Key
    )

    $existingValue = Get-ItemValue -Key $Key `
                                   -IsAttribute $false `
                                   -WebsitePath $WebsitePath `
                                   -ConfigSection $ConfigSection
    if($null -eq $existingValue)
    {
        $existingValue = Get-ItemValue -Key $Key `
                                       -IsAttribute $true `
                                       -WebsitePath $WebsitePath `
                                       -ConfigSection $ConfigSection
    }

    if($existingValue.Length -eq 0)
    {
        Write-Verbose -Message $LocalizedData.VerboseGetTargetAbsent
         return @{
             Ensure = 'Absent'
             Key = $Key
             Value = $existingValue
        }
    }

    Write-Verbose -Message $LocalizedData.VerboseGetTargetPresent
    
    return @{
        Ensure = 'Present'
        Key = $Key
        Value = $existingValue

    }

}


function Set-TargetResource
{
    <#
    .SYNOPSIS
        This will set the desired state
    #>

    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [String] $WebsitePath,

        [Parameter(Mandatory = $true)]
        [ValidateSet('AppSettings')]
        [String] $ConfigSection,

        [ValidateSet('Present','Absent')]
        [String] $Ensure = 'Present',

        [Parameter(Mandatory = $true)]
        [String] $Key,

        [String] $Value,

        [Boolean] $IsAttribute
    )

    if($Ensure -eq 'Present')
    {
        $existingValue = Get-ItemValue -Key $Key `
                                       -IsAttribute $IsAttribute `
                                       -WebsitePath $WebsitePath `
                                       -ConfigSection $ConfigSection

        if((-not($IsAttribute -and `
                ($null -eq $existingValue)) -or `
                ($IsAttribute -and `
            ($existingValue.Length -eq 0))))
        {
            Add-Item -Key $Key `
                     -Value $Value `
                     -IsAttribute $IsAttribute `
                     -WebsitePath $WebsitePath `
                     -ConfigSection $ConfigSection
        }
        else
        {
            $propertyName ='Value'
            if($IsAttribute)
            {
                $propertyName = $Key
            }
            Edit-Item -PropertyName $propertyName `
                      -OldValue $existingValue `
                      -NewValue $Value `
                      -IsAttribute $IsAttribute `
                      -WebsitePath $WebsitePath `
                      -ConfigSection $ConfigSection
        }
    }
    else
    {
        Remove-Item -Key $Key `
                    -IsAttribute $IsAttribute `
                    -WebsitePath $WebsitePath `
                    -ConfigSection $ConfigSection
    }
}

function Test-TargetResource
{
    <#
    .SYNOPSIS
        This tests the desired state. If the state is not correct it will return $false.
        If the state is correct it will return $true
    #>
    
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [String] $WebsitePath,

        [Parameter(Mandatory = $true)]
        [ValidateSet('AppSettings')]
        [String] $ConfigSection,

        [ValidateSet('Present','Absent')]
        [String] $Ensure = 'Present',

        [Parameter(Mandatory = $true)]
        [String] $Key,

        [String] $Value,

        [Boolean] $IsAttribute
    )

    if(-not($PSBoundParameters.ContainsKey('IsAttribute')))
    {
        $IsAttribute = $false
    }

    $existingValue = Get-ItemValue -Key $Key `
                                   -IsAttribute $IsAttribute `
                                   -WebsitePath $WebsitePath `
                                   -ConfigSection $ConfigSection
    
    if($Ensure -eq 'Present')
    {
        if(-not($IsAttribute))
        {
            if(($null -eq $existingValue) -or ($existingValue -ne $Value))
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
            if(($existingValue.Length -eq 0) -or ($existingValue -ne $Value))
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
        if(-not($IsAttribute))
        {
            if(($null -eq $existingValue))
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
            if(($existingValue.Length -eq 0))
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

#region HelperFunctions

function Add-Item
{
    [CmdletBinding()]
    param
    
    (
        [String] $Key, 
    
        [String] $Value, 
    
        [Boolean] $IsAttribute, 
    
        [String] $WebsitePath, 
    
        [String] $ConfigSection
    )

    $defaultFilter = $ConfigSection

    $itemCollection = @{key=$Key;Value=$Value}

    if(-not($isAttribute))
    {
        Add-WebConfigurationProperty -Filter $DefaultFilter `
                                     -Name '.' `
                                     -Value $ItemCollection `
                                     -PSPath $WebsitePath
    }
    else
    {
        Set-WebConfigurationProperty -Filter $DefaultFilter `
                                     -PSPath $WebsitePath `
                                     -Name $Key `
                                     -Value $Value `
                                     -WarningAction Stop 
    }
}

function Edit-Item
{
    [CmdletBinding()]
    param
    (
        [String] $PropertyName, 
        
        [String] $OldValue, 
        
        [String] $NewValue, 
        
        [Boolean] $IsAttribute, 
        
        [String] $WebsitePath, 
        
        [String] $ConfigSection
    )

    $defaultFilter = $ConfigSection

    if(-not($IsAttribute))
    {
        $Filter= "$defaultFilter/add[@$propertyName=`'$oldValue`']"

        Set-WebConfigurationProperty -Filter $Filter `
                                     -PSPath $WebsitePath `
                                     -Name $PropertyName `
                                     -Value $NewValue `
                                     -WarningAction Stop
    }

    else
    {
        Set-WebConfigurationProperty -Filter $DefaultFilter `
                                     -PSPath $WebsitePath `
                                     -Name $PropertyName `
                                     -Value $NewValue `
                                     -WarningAction Stop
    }
}

function Remove-Item
{
    <#
    .NOTES
        This is a workaround to ensure if appSettings has no collection and we try to delete 
        the only attribute, the entire node is not deleted.
        If we try removing the only attribute even if there is one collection item, the node 
        is preserved. I am not able to find a way to do this using clear-webconfiguration alone.
    #>
    [CmdletBinding()]
    param
    (
        [String] $Key, 
    
        [Boolean] $IsAttribute, 
    
        [String] $WebsitePath, 
    
        [String] $ConfigSection
    )
    $defaultFilter = $ConfigSection

    if(-not($IsAttribute))
    {
        $Filter = "$defaultFilter/add[@key=`'$Key`']"

        Clear-WebConfiguration -Filter $Filter `
                               -PSPath $WebsitePath `
                               -WarningAction Stop
    }
    else
    {
        $Filter = "$defaultFilter/@$Key"


        Add-Item -Key 'dummyKey' `
                 -Value 'dummyValue' `
                 -IsAttribute $false `
                 -WebsitePath $WebsitePath `
                 -ConfigSection $ConfigSection

        clear-WebConfiguration -Filter $Filter `
                               -PSPath $WebsitePath `
                               -WarningAction Stop

        Remove-Item -Key 'dummyKey' `
                    -IsAttribute $false `
                    -WebsitePath $WebsitePath `
                    -ConfigSection $ConfigSection
    }
}

function Get-ItemValue
{
    [CmdletBinding()]
    param
    (
        [String] $Key, 
    
        [Boolean] $IsAttribute, 
    
        [String] $WebsitePath, 
    
        [String] $ConfigSection
    )
    
    # if not present, $Value.Value will be null
    $defaultFilter = $ConfigSection

    if(-not($IsAttribute))
    {
        $Filter = "$defaultFilter/add[@key=`'$Key`']"

        $Value = Get-WebConfigurationProperty -Filter $Filter `
                                              -Name 'Value' `
                                              -PSPath $WebsitePath
 
    }
    else
    {
        $Value = Get-WebConfigurationProperty -Filter $DefaultFilter `
                                              -Name "$Key" `
                                              -PSPath $WebsitePath
    }
  
    return $Value.Value
}

#endregion

Export-ModuleMember -Function *-TargetResource
