# Load the Helper Module
Import-Module -Name "$PSScriptRoot\..\Helper.psm1"

# Localized messages
data LocalizedData
{
    # culture="en-US"
    ConvertFrom-StringData -StringData @'
        UnableToFindConfig         = Unable to find {0} in AppHost Config.
        SettingsslConfig           = Setting {0} ssl binding to {1}.
        sslBindingsCorrect         = ssl Bindings for {0} are correct.
        sslBindingsAbsent          = ssl Bidnings for {0} are absent.
        VerboseGetTargetResource   = Get-TargetResource has been run.
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
        [String] $Name,

        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [ValidateSet('','Ssl','SslNegotiateCert','SslRequireCert','Ssl128')]
        [String[]] $Bindings
    )

    Assert-Module

    $Ensure = 'Absent'

    try
    {
        $params = @{
            PSPath   = 'MACHINE/WEBROOT/APPHOST'
            Location = $Name
            Filter   = 'system.webServer/security/access'
            Name     = 'sslFlags'
        }

        $sslSettings = Get-WebConfigurationProperty @params

        # If ssl is configured at all this will be a String else
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

    Write-Verbose -Message $LocalizedData.VerboseGetTargetResource
    
    return @{
        Name = $Name
        Bindings = $Bindings
        Ensure = $Ensure
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
        [String] $Name,

        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [ValidateSet('','Ssl','SslNegotiateCert','SslRequireCert','Ssl128')]
        [String[]] $Bindings,

        [ValidateSet('Present','Absent')]
        [String] $Ensure = 'Present'
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
                $($LocalizedData.SettingsslConfig) -f $Name, 'None'
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
                $($LocalizedData.SettingsslConfig) -f $Name, $params.Value
        ) -join '')
        Set-WebConfigurationProperty @params
    }
}

function Test-TargetResource
{
    <#
    .SYNOPSIS
        This test the desired state. If the state is not correct it will return $false.
        If the state is correct it will return $true
    #>

    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [String] $Name,

        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [ValidateSet('','Ssl','SslNegotiateCert','SslRequireCert','Ssl128')]
        [String[]] $Bindings,

        [ValidateSet('Present','Absent')]
        [String] $Ensure = 'Present'
    )

    $sslSettings = Get-TargetResource -Name $Name -Bindings $Bindings

    if ($Ensure -eq 'Present' -and $sslSettings.Ensure -eq 'Present')
    {
        $sslComp = Compare-Object -ReferenceObject $Bindings `
                                  -DifferenceObject $sslSettings.Bindings `
                                  -PassThru
        if ($null -eq $sslComp)
        {
            Write-Verbose -Message ( @( "$($MyInvocation.MyCommand): "
                    $($LocalizedData.sslBindingsCorrect) -f $Name
            ) -join '')

            return $true;
        }
    }

    if ($Ensure -eq 'Absent' -and $sslSettings.Ensure -eq 'Absent')
    {
        Write-Verbose -Message ( @( "$($MyInvocation.MyCommand): "
                $($LocalizedData.sslBindingsAbsent) -f $Name
        ) -join '')

        return $true;
    }

    return $false;
}

Export-ModuleMember -Function *-TargetResource
