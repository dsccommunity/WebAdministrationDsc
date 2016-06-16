# Load the Helper Module
Import-Module -Name "$PSScriptRoot\..\Helper.psm1" -Verbose:$false

# Localized messages
data LocalizedData
{
    # culture="en-US"
    ConvertFrom-StringData -StringData @'
        UnableToFindConfig         = Unable to find {0} in AppHost Config
        SettingSslConfig           = Setting {0} Ssl binding to {1}
        SslBindingsCorrect         = Ssl Bindings for {0} are correct
        SslBindingsAbsent          = Ssl Bidnings for {0} are Absent
        VerboseGetTargetResource   = Get-TargetResource has been run.
'@
}

function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]
        [String] 
        $Name,

        [parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [ValidateSet('','Ssl','SslNegotiateCert','SslRequireCert','Ssl128')]
        [string[]] 
        $Bindings
    )

    Assert-Module

    $Ensure = 'Absent'

    try
    {
        $params = @{
            PSPath   = 'MACHINE/WEBROOT/APPHOST'
            Location = $Name
            Filter   = 'system.webServer/security/access'
            Name     = 'SslFlags'
        }

        $SslSettings = Get-WebConfigurationProperty @params

        # If Ssl is configured at all this will be a String else
        # it'll be a configuration object.
        if ($SslSettings.GetType().FullName -eq 'System.String')
        {
            $Bindings = $SslSettings.Split(',')
            $Ensure = 'Present'
        }
    }
    catch [Exception]
    {
        Write-Verbose -Message ( @( "$($MyInvocation.MyCommand): "
                $($LocalizedData.UnableToFindConfig) -f $Name
        ) -join '')
    }

    Write-Verbose -Message $LocalizedData.VerboseGetTargetResource
    
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
        [String] 
        $Name,

        [parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [ValidateSet('','Ssl','SslNegotiateCert','SslRequireCert','Ssl128')]
        [string[]] 
        $Bindings,

        [ValidateSet('Present','Absent')]
        [String]
        $Ensure = 'Present'
    )

    Assert-Module

    if ($Ensure -eq 'Absent' -or $Bindings.toLower().Contains('none'))
    {
        $params = @{
            PSPath   = 'MACHINE/WEBROOT/APPHOST'
            Location = $Name
            Filter   = 'system.webServer/security/access'
            Name     = 'SslFlags'
            Value    = ''
        }

        Write-Verbose -Message ( @( "$($MyInvocation.MyCommand): "
                $($LocalizedData.SettingSslConfig) -f $Name, 'None'
        ) -join '')
        Set-WebConfigurationProperty @params
    }
    
    else
    {
        $SslBindings = $Bindings -join ','
        $params = @{
            PSPath   = 'MACHINE/WEBROOT/APPHOST'
            Location = $Name
            Filter   = 'system.webServer/security/access'
            Name     = 'SslFlags'
            Value    = $SslBindings
        }

        Write-Verbose -Message ( @( "$($MyInvocation.MyCommand): "
                $($LocalizedData.SettingSslConfig) -f $Name, $params.Value
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
        [String] 
        $Name,

        [parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [ValidateSet('','Ssl','SslNegotiateCert','SslRequireCert','Ssl128')]
        [string[]] 
        $Bindings,

        [ValidateSet('Present','Absent')]
        [String]
        $Ensure = 'Present'
    )

    $SslSettings = Get-TargetResource -Name $Name -Bindings $Bindings

    if ($Ensure -eq 'Present' -and $SslSettings.Ensure -eq 'Present')
    {
        $SslComp = Compare-Object -ReferenceObject $Bindings `
                                  -DifferenceObject $SslSettings.Bindings `
                                  -PassThru
        if ($null -eq $SslComp)
        {
            Write-Verbose -Message ( @( "$($MyInvocation.MyCommand): "
                    $($LocalizedData.SslBindingsCorrect) -f $Name
            ) -join '')

            return $true;
        }
    }

    if ($Ensure -eq 'Absent' -and $SslSettings.Ensure -eq 'Absent')
    {
        Write-Verbose -Message ( @( "$($MyInvocation.MyCommand): "
                $($LocalizedData.SslBindingsAbsent) -f $Name
        ) -join '')

        return $true;
    }

    return $false;
}

Export-ModuleMember -Function *-TargetResource
