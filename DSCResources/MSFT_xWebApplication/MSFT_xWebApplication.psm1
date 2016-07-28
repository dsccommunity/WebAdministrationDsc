# Load the Helper Module
Import-Module -Name "$PSScriptRoot\..\Helper.psm1"

# Localized messages
data LocalizedData
{
    # culture="en-US"
    ConvertFrom-StringData -StringData @'
        ErrorWebApplicationTestAutoStartProviderFailure        = Desired AutoStartProvider is not valid due to a conflicting Global Property. Ensure that the serviceAutoStartProvider is a unique key.
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
        VerboseTestTargetFalseAbsent                           = Web application "{0}" is absent and should not absent.
        VerboseTestTargetFalsePresent                          = Web application $Name should be absent and is not absent.
        VerboseTestTargetFalsePhysicalPath                     = Physical path for web application "{0}" does not match desired state.
        VerboseTestTargetFalseWebAppPool                       = Web application pool for web application "{0}" does not match desired state.
        VerboseTestTargetFalseSslFlags                         = SslFlags for web application "{0}" are not in the desired state.
        VerboseTestTargetFalseAuthenticationInfo               = AuthenticationInfo for web application "{0}" is not in the desired state.
        VerboseTestTargetFalsePreload                          = Preload for web application "{0}" is not in the desired state.
        VerboseTestTargetFalseAutostart                        = Autostart for web application "{0}" is not in the desired state.
        VerboseTestTargetFalseAutoStartProviders               = AutoStartProviders for web application "{0}" are not in the desired state.
        VerboseTestTargetFalseIISAutoStartProviders            = AutoStartProviders for IIS are not in the desired state.
        VerboseTestTargetFalseWebApplicationAutoStartProviders = AutoStartProviders for web application "{0}" are not in the desired state.
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
    $CimAuthentication = Get-AuthenticationInfo -Site $Website -Application $name
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
        AuthenticationInfo       = $CimAuthentication
        SslFlags                 = @($CurrentSslFlags)
        PreloadEnabled           = $webApplication.preloadEnabled
        ServiceAutoStartProvider = $webApplication.serviceAutoStartProvider
        ServiceAutoStartEnabled  = $webApplication.serviceAutoStartEnabled
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
        [String[]] $SslFlags = '',

        [Microsoft.Management.Infrastructure.CimInstance] $AuthenticationInfo,

        [Boolean] $PreloadEnabled,
        
        [Boolean] $ServiceAutoStartEnabled,

        [String] $ServiceAutoStartProvider,
        
        [String] $ApplicationType
    )

    Assert-Module
    
    $Name = Get-WebApplicationNameFixed $Name

    if ($Ensure -eq 'Present')
    {
            $webApplication = Get-WebApplication -Site $Website -Name $Name

            if ($AuthenticationInfo -eq $null)
            {
                $AuthenticationInfo = Get-DefaultAuthenticationInfo
            }
 
            if ($webApplication.count -eq 0)
            {
                Write-Verbose -Message ($LocalizedData.VerboseSetTargetPresent -f $Name)
                New-WebApplication -Site $Website -Name $Name `
                                   -PhysicalPath $PhysicalPath `
                                   -ApplicationPool $WebAppPool
            }

            #Update Physical Path if required
            if (($PSBoundParameters.ContainsKey('PhysicalPath') -and `
                $webApplication.physicalPath -ne $PhysicalPath))
            {
                Write-Verbose -Message ($LocalizedData.VerboseSetTargetPhysicalPath -f $Name)
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
                Set-WebConfigurationProperty `
                    -Filter "$($webApplication.ItemXPath)/virtualDirectory[@path='/']" `
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
                    Value    = [string]$sslflags
                }
                Set-WebConfigurationProperty @params
            }

            # Set Authentication; if not defined then pass in DefaultAuthenticationInfo
            if ($PSBoundParameters.ContainsKey('AuthenticationInfo') -and `
                (-not (Test-AuthenticationInfo -Site $Website `
                                               -Application $Name `
                                               -IisType 'Application' `
                                               -AuthenticationInfo $AuthenticationInfo)))
            {
                Write-Verbose -Message ($LocalizedData.VerboseSetTargetAuthenticationInfo -f $Name)
                Set-AuthenticationInfo -Site $Website `
                                       -Application $Name `
                                       -IisType 'Application' `
                                       -AuthenticationInfo $AuthenticationInfo `
                                       -ErrorAction Stop `
            }
            $DefaultAuthenticationInfo = Get-DefaultAuthenticationInfo -IisType 'Application'
            if($null -eq $PSBoundParameters.ContainsKey('AuthenticationInfo') -and `
                (-not (Test-AuthenticationInfo `
                        -Site $Website `
                        -Application $Name `
                        -IisType 'Application' `
                        -AuthenticationInfo $DefaultAuthenticationInfo)))
            {
                $AuthenticationInfo = Get-DefaultAuthenticationInfo -IisType 'Application'
                Write-Verbose -Message ($LocalizedData.VerboseSetTargetAuthenticationInfo `
                                        -f $Name)
                Set-AuthenticationInfo -Site $Website `
                                        -Application $Name `
                                        -IisType 'Application' `
                                        -AuthenticationInfo $DefaultAuthenticationInfo `
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

        [Microsoft.Management.Infrastructure.CimInstance] $AuthenticationInfo,

        [Boolean] $PreloadEnabled,
        
        [Boolean] $ServiceAutoStartEnabled,

        [String] $ServiceAutoStartProvider,
        
        [String] $ApplicationType
    )

    Assert-Module
    
    $Name = Get-WebApplicationNameFixed $Name
    $webApplication = Get-WebApplication -Site $Website -Name $Name
    $CurrentSslFlags = Get-SslFlags -Location "${Website}/${Name}"

    if ($AuthenticationInfo -eq $null) 
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
        if ($PSBoundParameters.ContainsKey('AuthenticationInfo') -and `
            (-not (Test-AuthenticationInfo -Site $Website `
                                           -Application $Name `
                                           -IisType 'Application' `
                                           -AuthenticationInfo $AuthenticationInfo)))
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

    }

    return $true
    
}

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
            [String]::Empty
        } 

    return $SslFlags
    
}

#region Helper Functions

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
    Back slash is replaced by iis with a forward slash. for compatibility we do the same
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
