# Load the Helper Module
Import-Module -Name "$PSScriptRoot\..\Helper.psm1"

# Localized messages
data LocalizedData
{
    # culture="en-US"
    ConvertFrom-StringData -StringData @'
        VerboseGetTargetResource                               = Get-TargetResource has been run.
        VerboseSetTargetAbsent                                 = Removing existing Web Application "{0}".
        VerboseSetTargetPresent                                = Creating new Web application "{0}".
        VerboseSetTargetPhysicalPath                           = Updating physical path for Web application "{0}".
        VerboseSetTargetWebAppPool                             = Updating application pool for Web application "{0}".
        VerboseSetTargetSslFlags                               = Updating SslFlags for Web application "{0}".
        VerboseSetTargetAuthenticationInfo                     = Updating AuthenticationInfo for Web application "{0}".
        VerboseSetTargetPreload                                = Updating Preload for Web application "{0}".
        VerboseSetTargetAutostart                              = Updating AutoStart for Web application "{0}".
        VerboseSetTargetIISAutoStartProviders                  = Updating AutoStartProviders for IIS.
        VerboseSetTargetWebApplicationAutoStartProviders       = Updating AutoStartProviders for Web application "{0}".
        VerboseSetTargetEnabledProtocols                       = Updating EnabledProtocols for Web application "{0}".
        VerboseTestTargetFalseAbsent                           = Web application "{0}" is absent and should not absent.
        VerboseTestTargetFalsePresent                          = Web application $Name should be absent and is not absent.
        VerboseTestTargetFalsePhysicalPath                     = Physical path for web application "{0}" does not match desired state.
        VerboseTestTargetFalseWebAppPool                       = Web application pool for web application "{0}" does not match desired state.
        VerboseTestTargetFalseSslFlags                         = SslFlags for web application "{0}" are not in the desired state.
        VerboseTestTargetFalseAuthenticationInfo               = AuthenticationInfo for web application "{0}" is not in the desired state.
        VerboseTestTargetFalsePreload                          = Preload for web application "{0}" is not in the desired state.
        VerboseTestTargetFalseAutostart                        = Autostart for web application "{0}" is not in the desired state.
        VerboseTestTargetFalseIISAutoStartProviders            = AutoStartProviders for IIS are not in the desired state.
        VerboseTestTargetFalseWebApplicationAutoStartProviders = AutoStartProviders for web application "{0}" are not in the desired state.
        VerboseTestTargetFalseEnabledProtocols                 = EnabledProtocols for web application "{0}" are not in the desired state.
'@
}

<#
.SYNOPSIS
    This will return a hashtable of results
#>
function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [String] $Website,

        [Parameter(Mandatory = $true)]
        [String] $Name,

        [Parameter(Mandatory = $true)]
        [String] $WebAppPool,

        [Parameter(Mandatory = $true)]
        [String] $PhysicalPath
    )

    Assert-Module

    $name = Get-WebApplicationNameFixed -Name $Name
    $webApplication = Get-WebApplication -Site $Website -Name $name
    $CimAuthentication = Get-AuthenticationInfo -Site $Website -Application $name -IisType 'Application'
    $CurrentSslFlags = (Get-SslFlags -Location "${Website}/${name}")

    $Ensure = 'Absent'

    if ($webApplication.Count -eq 1)
    {
        $Ensure = 'Present'
    }

    Write-Verbose -Message $LocalizedData.VerboseGetTargetResource

    $returnValue = @{
        Website                  = $Website
        Name                     = $name
        WebAppPool               = $webApplication.applicationPool
        PhysicalPath             = $webApplication.PhysicalPath
        AuthenticationInfo       = $cimAuthentication
        SslFlags                 = [Array]$currentSslFlags
        PreloadEnabled           = $webApplication.preloadEnabled
        ServiceAutoStartProvider = $webApplication.serviceAutoStartProvider
        ServiceAutoStartEnabled  = $webApplication.serviceAutoStartEnabled
        EnabledProtocols         = [Array]$webApplication.EnabledProtocols
        Ensure                   = $Ensure
    }

    return $returnValue

}

<#
.SYNOPSIS
    This will set the desired state
#>
function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [String] $Website,

        [Parameter(Mandatory = $true)]
        [String] $Name,

        [Parameter(Mandatory = $true)]
        [String] $WebAppPool,

        [Parameter(Mandatory = $true)]
        [String] $PhysicalPath,

        [ValidateSet('Present','Absent')]
        [String] $Ensure = 'Present',

        [AllowEmptyString()]
        [ValidateSet('','Ssl','SslNegotiateCert','SslRequireCert','Ssl128')]
        [String[]]$SslFlags = '',

        [Microsoft.Management.Infrastructure.CimInstance]
        $AuthenticationInfo,

        [Boolean]
        $PreloadEnabled,

        [Boolean]
        $ServiceAutoStartEnabled,

        [String]
        $ServiceAutoStartProvider,

        [String]
        $ApplicationType,

        [ValidateSet('http','https','net.tcp','net.msmq','net.pipe')]
        [String[]] $EnabledProtocols
    )

    Assert-Module

    if ($Ensure -eq 'Present')
    {
            $webApplication = Get-WebApplication -Site $Website -Name $Name

            if ($null -eq $AuthenticationInfo)
            {
                $AuthenticationInfo = Get-DefaultAuthenticationInfo -IisType 'Application'
            }

            if ($webApplication.count -eq 0)
            {
                Write-Verbose -Message ($LocalizedData.VerboseSetTargetPresent -f $Name)
                New-WebApplication -Site $Website -Name $Name `
                                   -PhysicalPath $PhysicalPath `
                                   -ApplicationPool $WebAppPool
                $webApplication = Get-WebApplication -Site $Website -Name $Name
            }

            # Update Physical Path if required
            if (($PSBoundParameters.ContainsKey('PhysicalPath') -and `
                $webApplication.physicalPath -ne $PhysicalPath))
            {
                Write-Verbose -Message ($LocalizedData.VerboseSetTargetPhysicalPath -f $Name)
                #Note: read this before touching the next line of code:
                #      https://github.com/PowerShell/xWebAdministration/issues/222
                Set-WebConfigurationProperty `
                    -Filter "$($webApplication.ItemXPath)/virtualDirectory[@path='/']" `
                    -Name physicalPath `
                    -Value $PhysicalPath
            }

            # Update AppPool if required
            if ($PSBoundParameters.ContainsKey('WebAppPool') -and `
                ($webApplication.applicationPool -ne $WebAppPool))
            {
                Write-Verbose -Message ($LocalizedData.VerboseSetTargetWebAppPool -f $Name)
                #Note: read this before touching the next line of code:
                #      https://github.com/PowerShell/xWebAdministration/issues/222
                Set-WebConfigurationProperty `
                    -Filter $webApplication.ItemXPath `
                    -Name applicationPool `
                    -Value $WebAppPool
            }

            # Update SslFlags if required
            if ($PSBoundParameters.ContainsKey('SslFlags') -and `
                (-not (Test-SslFlags -Location "${Website}/${Name}" -SslFlags $SslFlags)))
            {
                Write-Verbose -Message ($LocalizedData.VerboseSetTargetSslFlags -f $Name)
                $params = @{
                    PSPath   = 'MACHINE/WEBROOT/APPHOST'
                    Location = "${Website}/${Name}"
                    Filter   = 'system.webServer/security/access'
                    Name     = 'sslFlags'
                    Value    = ($sslflags -join ',')
                }
                Set-WebConfigurationProperty @params
            }

            # Set Authentication; if not defined then pass in Default AuthenticationInfo
            if (-not (Test-AuthenticationInfo -Site $Website `
                                               -Application $Name `
                                               -IisType 'Application' `
                                               -AuthenticationInfo $AuthenticationInfo))
            {
                Write-Verbose -Message ($LocalizedData.VerboseSetTargetAuthenticationInfo -f $Name)
                Set-AuthenticationInfo -Site $Website `
                                       -Application $Name `
                                       -IisType 'Application' `
                                       -AuthenticationInfo $AuthenticationInfo `
                                       -ErrorAction Stop `
            }

            # Update Preload if required
            if ($PSBoundParameters.ContainsKey('preloadEnabled') -and `
                $webApplication.preloadEnabled -ne $PreloadEnabled)
            {
                Write-Verbose -Message ($LocalizedData.VerboseSetTargetPreload -f $Name)
                Set-ItemProperty -Path "IIS:\Sites\$Website\$Name" `
                                 -Name preloadEnabled `
                                 -Value $preloadEnabled `
                                 -ErrorAction Stop
            }

            # Update AutoStart if required
            if ($PSBoundParameters.ContainsKey('ServiceAutoStartEnabled') -and `
                $webApplication.serviceAutoStartEnabled -ne $ServiceAutoStartEnabled)
            {
                Write-Verbose -Message ($LocalizedData.VerboseSetTargetAutostart -f $Name)
                Set-ItemProperty -Path "IIS:\Sites\$Website\$Name" `
                                 -Name serviceAutoStartEnabled `
                                 -Value $serviceAutoStartEnabled `
                                 -ErrorAction Stop
            }

            # Update AutoStartProviders if required
            if ($PSBoundParameters.ContainsKey('ServiceAutoStartProvider') -and `
                $webApplication.serviceAutoStartProvider -ne $ServiceAutoStartProvider)
            {
                if (-not (Confirm-UniqueServiceAutoStartProviders `
                            -ServiceAutoStartProvider $ServiceAutoStartProvider `
                            -ApplicationType $ApplicationType))
                {
                    Write-Verbose -Message ($LocalizedData.VerboseSetTargetIISAutoStartProviders)
                    Add-WebConfiguration `
                        -filter /system.applicationHost/serviceAutoStartProviders `
                        -Value @{name=$ServiceAutoStartProvider; type=$ApplicationType} `
                        -ErrorAction Stop
                }
                Write-Verbose -Message `
                    ($LocalizedData.VerboseSetTargetWebApplicationAutoStartProviders -f $Name)
                Set-ItemProperty -Path "IIS:\Sites\$Website\$Name" `
                                 -Name serviceAutoStartProvider `
                                 -Value $ServiceAutoStartProvider `
                                 -ErrorAction Stop
            }

            # Update EnabledProtocols if required
            if ($PSBoundParameters.ContainsKey('EnabledProtocols') -and `
            (-not(Confirm-UniqueEnabledProtocols `
                            -ExistingProtocols $webApplication.EnabledProtocols `
                            -ProposedProtocols $EnabledProtocols )))
            {
                Write-Verbose -Message ($LocalizedData.VerboseSetTargetEnabledProtocols -f $Name)
                # Make input bindings which are an array, into a string
                $stringafiedEnabledProtocols = $EnabledProtocols -join ','
                Set-ItemProperty -Path "IIS:\Sites\$Website\$Name" `
                                 -Name 'enabledProtocols' `
                                 -Value $stringafiedEnabledProtocols `
                                 -ErrorAction Stop
            }
    }

    if ($Ensure -eq 'Absent')
    {
        Write-Verbose -Message ($LocalizedData.VerboseSetTargetAbsent -f $Name)
        Remove-WebApplication -Site $Website -Name $Name
    }
}

<#
.SYNOPSIS
    This tests the desired state. If the state is not correct it will return $false.
    If the state is correct it will return $true
#>
function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [String] $Website,

        [Parameter(Mandatory = $true)]
        [String] $Name,

        [Parameter(Mandatory = $true)]
        [String] $WebAppPool,

        [Parameter(Mandatory = $true)]
        [String] $PhysicalPath,

        [ValidateSet('Present','Absent')]
        [String] $Ensure = 'Present',

        [AllowEmptyString()]
        [ValidateSet('','Ssl','SslNegotiateCert','SslRequireCert','Ssl128')]
        [String[]]$SslFlags = '',

        [Microsoft.Management.Infrastructure.CimInstance]
        $AuthenticationInfo,

        [Boolean]
        $preloadEnabled,

        [Boolean]
        $serviceAutoStartEnabled,

        [String]
        $serviceAutoStartProvider,

        [String]
        $ApplicationType,

        [ValidateSet('http','https','net.tcp','net.msmq','net.pipe')]
        [String[]] $EnabledProtocols
    )

    Assert-Module

    $webApplication = Get-WebApplication -Site $Website -Name $Name

    if ($null -eq $AuthenticationInfo)
    {
        $AuthenticationInfo = Get-DefaultAuthenticationInfo -IisType 'Application'
    }

    if ($webApplication.count -eq 0 -and $Ensure -eq 'Present')
    {
        Write-Verbose -Message ($LocalizedData.VerboseTestTargetFalseAbsent -f $Name)
        return $false
    }

    if ($webApplication.count -eq 1 -and $Ensure -eq 'Absent')
    {
        Write-Verbose -Message ($LocalizedData.VerboseTestTargetFalsePresent -f $Name)
        return $false
    }

    if ($webApplication.count -eq 1 -and $Ensure -eq 'Present')
    {
        #Check Physical Path
        if ($webApplication.physicalPath -ne $PhysicalPath)
        {
            Write-Verbose -Message ($LocalizedData.VerboseTestTargetFalsePhysicalPath -f $Name)
            return $false
        }

        #Check AppPool
        if ($webApplication.applicationPool -ne $WebAppPool)
        {
            Write-Verbose -Message ($LocalizedData.VerboseTestTargetFalseWebAppPool -f $Name)
            return $false
        }

        #Check SslFlags
        if ($PSBoundParameters.ContainsKey('SslFlags') -and `
            (-not (Test-SslFlags -Location "${Website}/${Name}" -SslFlags $SslFlags)))
        {
            Write-Verbose -Message ($LocalizedData.VerboseTestTargetFalseSslFlags -f $Name)
            return $false
        }

        #Check AuthenticationInfo
        if (-not (Test-AuthenticationInfo -Site $Website `
                                           -Application $Name `
                                           -IisType 'Application' `
                                           -AuthenticationInfo $AuthenticationInfo))
        {
            Write-Verbose -Message ($LocalizedData.VerboseTestTargetFalseAuthenticationInfo -f $Name)
            return $false
        }

        #Check Preload
        if ($PSBoundParameters.ContainsKey('preloadEnabled') -and `
            $webApplication.preloadEnabled -ne $PreloadEnabled)
        {
            Write-Verbose -Message ($LocalizedData.VerboseTestTargetFalsePreload -f $Name)
            return $false
        }

        #Check AutoStartEnabled
        if($PSBoundParameters.ContainsKey('ServiceAutoStartEnabled') -and `
            $webApplication.serviceAutoStartEnabled -ne $ServiceAutoStartEnabled)
        {
            Write-Verbose -Message ($LocalizedData.VerboseTestTargetFalseAutostart -f $Name)
            return $false
        }

        #Check AutoStartProviders
        if ($PSBoundParameters.ContainsKey('ServiceAutoStartProvider') -and `
            $webApplication.serviceAutoStartProvider -ne $ServiceAutoStartProvider)
        {
            if (-not (Confirm-UniqueServiceAutoStartProviders `
                        -serviceAutoStartProvider $ServiceAutoStartProvider `
                        -ApplicationType $ApplicationType))
            {
                Write-Verbose -Message ($LocalizedData.VerboseTestTargetFalseIISAutoStartProviders)
                return $false
            }
            Write-Verbose -Message `
                ($LocalizedData.VerboseTestTargetFalseWebApplicationAutoStartProviders -f $Name)
            return $false
        }

        #Update EnabledProtocols if required
        if ($PSBoundParameters.ContainsKey('EnabledProtocols') -and `
            (-not(Confirm-UniqueEnabledProtocols `
                            -ExistingProtocols $webApplication.EnabledProtocols `
                            -ProposedProtocols $EnabledProtocols )))
        {
            Write-Verbose -Message ($LocalizedData.VerboseTestTargetFalseEnabledProtocols `
                                    -f $Name)
            return $false
        }

    }

    return $true

}

<#
.SYNOPSIS
    Helper function used to validate that the EnabledProtocols are unique.
    Returns $false if EnabledProtocols are not unique and $true if they are
.PARAMETER ExistingProtocols
    Specifies existing SMTP bindings
.PARAMETER ProposedProtocols
    Specifies desired SMTP bindings.
.NOTES
    ExistingProtocols is a String whereas ProposedProtocols is an array of Strings
    so we need to do some extra work in comparing them
#>
function Confirm-UniqueEnabledProtocols
{
    [CmdletBinding()]
    [OutputType([Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [String] $ExistingProtocols,

        [Parameter(Mandatory = $true)]
        [String[]] $ProposedProtocols
    )

    $inputToCheck = @()
    foreach ($proposedProtocol in $ProposedProtocols)
    {
        $inputToCheck += $proposedProtocol
    }

    $existingProtocolsToCheck = $existingProtocols -split ','

    $existingToCheck = @()
    foreach ($existingProtocol in $existingProtocolsToCheck)
    {
        $existingToCheck += $existingProtocol.Trim()
    }

    $sortedExistingProtocols = $existingToCheck | Sort-Object -Unique
    $sortedInputProtocols = $inputToCheck | Sort-Object -Unique


    if (Compare-Object -ReferenceObject $sortedExistingProtocols `
                       -DifferenceObject $sortedInputProtocols `
                       -PassThru)
    {
        return $false
    }

    return $true
}

#region Helper Functions

<#
.SYNOPSIS
    Helper function used to return the SSLFlags on an Application.
.PARAMETER Location
    Specifies the path in the IIS: PSDrive to the Application
#>
function Get-SslFlags
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param
    (
        [Parameter(Mandatory = $true)]
        [String] $Location
    )

    $SslFlags = Get-WebConfiguration `
                -PSPath IIS:\Sites `
                -Location $Location `
                -Filter 'system.webserver/security/access' | `
                 ForEach-Object { $_.sslFlags }

    if ($null -eq $SslFlags)
    {
        return [String]::Empty
    }

    return $SslFlags
}

<#
.SYNOPSIS
    Helper function used to test the SSLFlags on an Application.
    Will return $true if they match and $false if they do not.
.PARAMETER SslFlags
    Specifies the SslFlags to Test
.PARAMETER Location
    Specifies the path in the IIS: PSDrive to the Application
#>
function Test-SslFlags
{
    [CmdletBinding()]
    [OutputType([Boolean])]
    param
    (
        [AllowEmptyString()]
        [ValidateSet('','Ssl','SslNegotiateCert','SslRequireCert','Ssl128')]
        [String[]] $SslFlags = '',

        [Parameter(Mandatory = $true)]
        [String] $Location
    )

    $CurrentSslFlags =  Get-SslFlags -Location $Location

    if(Compare-Object -ReferenceObject $CurrentSslFlags `
                        -DifferenceObject $SslFlags)
    {
        return $false
    }

    return $true
}

<#
.SYNOPSIS
    Helper function to replace a backslash with a forward slash in
    the web app names.
.PARAMETER Name
    The web application name
.NOTES
    Backslash is replaced by IIS with a forward slash, for compatibility we do the same.
#>
function Get-WebApplicationNameFixed
{
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [parameter(Mandatory = $true)]
        [System.String] $Name
    )

    $Name -replace '\\', '/'
}

#endregion

Export-ModuleMember -Function *-TargetResource
