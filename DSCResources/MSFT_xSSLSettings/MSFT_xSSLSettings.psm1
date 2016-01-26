Import-Module $PSScriptRoot\..\Helper.psm1 -Verbose:$false

data LocalizedData
{
    # culture="en-US"
    ConvertFrom-StringData @'
        UnableToFindConfig = Unable to find {0} in AppHost Config
        SettingSSLConfig   = Setting {0} SSL binding to {1}
        SSLBindingsCorrect = SSL Bindings for {0} are correct
        SSLBindingsAbsent  = SSL Bidnings for {0} are Absent
'@
}


function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]
        [string] $Name,

        [parameter(Mandatory = $true)]
        [string[]] $Bindings
    )

    Assert-Module

    $Ensure = 'Absent'
    $Bindings = 'None'

    try
    {
        $params = @{
            PSPath   = 'MACHINE/WEBROOT/APPHOST'
            Location = $Name
            Filter   = 'system.webServer/security/access'
            Name     = 'sslFlags'
        }

        $sslSettings = Get-WebConfigurationProperty @params

        # If SSL is configured at all this will be a string else
        # it'll be a configuration object.
        if ($sslSettings.GetType().FullName -eq 'System.String')
        {
            $Bindings = $sslSettings.Split(',')
            $Ensure = 'Present'
        }
    }
    catch [Exception]
    {
        Write-Verbose -Message ( @( "$($MyInvocation.MyCommand): "
            $($LocalizedData.UnableToFindConfig) -f $Name
        ) -join '')
    }

    return @{
        Name = $Name
        Bindings = $Bindings
        Ensure = $Ensure
    }
}

function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory = $true)]
        [string] $Name,

        [parameter(Mandatory = $true)]
        [string[]] $Bindings,

        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure = "Present"
    )

    Assert-Module

    if ($Ensure -eq 'Absent' -or $Bindings.toLower().Contains('none'))
    {
        $params = @{
            PSPath   = 'MACHINE/WEBROOT/APPHOST'
            Location = $Name
            Filter   = 'system.webServer/security/access'
            Name     = 'sslFlags'
            Value    = ''
        }

        Write-Verbose -Message ( @( "$($MyInvocation.MyCommand): "
            $($LocalizedData.SettingSSLConfig) -f $Name, 'None'
        ) -join '')
        Set-WebConfigurationProperty @params
    }
    else
    {
        $sslBindings = $Bindings -join ','
        $params = @{
            PSPath   = 'MACHINE/WEBROOT/APPHOST'
            Location = $Name
            Filter   = 'system.webServer/security/access'
            Name     = 'sslFlags'
            Value    = $sslBindings
        }

        Write-Verbose -Message ( @( "$($MyInvocation.MyCommand): "
            $($LocalizedData.SettingSSLConfig) -f $Name, $params.Value
        ) -join '')
        Set-WebConfigurationProperty @params
    }
}

function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [parameter(Mandatory = $true)]
        [string] $Name,

        [parameter(Mandatory = $true)]
        [string[]] $Bindings,

        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure = "Present"
    )

    $sslSettings = Get-TargetResource -Name $Name -Bindings $Bindings

    if ($Ensure -eq 'Present' -and $sslSettings.Ensure -eq 'Present')
    {
        $sslComp = Compare-Object -ReferenceObject $Bindings -DifferenceObject $sslSettings.Bindings -PassThru
        if ($sslComp -eq $null)
        {
            Write-Verbose -Message ( @( "$($MyInvocation.MyCommand): "
                $($LocalizedData.SSLBindingsCorrect) -f $Name
            ) -join '')

            return $true;
        }
    }

    if ($Ensure -eq 'Absent' -and $sslSettings.Ensure -eq 'Absent')
    {
        Write-Verbose -Message ( @( "$($MyInvocation.MyCommand): "
            $($LocalizedData.SSLBindingsAbsent) -f $Name
        ) -join '')

        return $true;
    }

    return $false;
}

Export-ModuleMember -Function *-TargetResource
