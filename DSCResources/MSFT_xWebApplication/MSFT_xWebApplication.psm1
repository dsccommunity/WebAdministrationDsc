# Load the Helper Module
Import-Module -Name "$PSScriptRoot\..\Helper.psm1" -Verbose:$false

# Localized messages
data LocalizedData
{
    # culture="en-US"
    ConvertFrom-StringData -StringData @'
ErrorWebsiteTestAutoStartProviderFailure = Desired AutoStartProvider is not valid due to a conflicting Global Property. Ensure that the serviceAutoStartProvider is a unique key.
'@
}

function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $Website,

        [parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [parameter(Mandatory = $true)]
        [System.String]
        $WebAppPool,

        [parameter(Mandatory = $true)]
        [System.String]
        $PhysicalPath,
        
        [ValidateNotNull()]
        [ValidateSet('Ssl','SslNegotiateCert','SslRequireCert')]
        [string[]]$SSlFlags = '',

        [Microsoft.Management.Infrastructure.CimInstance]
        $AuthenticationInfo,

        [Boolean]
        $PreloadEnabled,
        
        [Boolean]
        $ServiceAutoStartEnabled,

        [String]
        $ServiceAutoStartProvider,
        
        [String]
        $ApplicationType
    )

    Assert-Module

    $webApplication = Get-WebApplication -Site $Website -Name $Name
    $AuthenticationInfo = Get-AuthenticationInfo -Site $Website -Name $Name
    $SslFlags = (Get-SslFlags -Location "${Website}/${Name}")

    $Ensure = 'Absent'

    if ($webApplication.Count -eq 1)
    {
        $Ensure = 'Present'
    }

    $returnValue = @{
        Website                  = $Website
        Name                     = $Name
        WebAppPool               = $webApplication.applicationPool
        PhysicalPath             = $webApplication.PhysicalPath
        Authentication           = $AuthenticationInfo
        SSLSettings              = $SslFlags
        PreloadEnabled           = $webApplication.preloadEnabled
        ServiceAutoStartProvider = $webApplication.serviceAutoStartProvider
        ServiceAutoStartEnabled  = $webApplication.serviceAutoStartEnabled
        Ensure                   = $Ensure
    }

    return $returnValue
}

function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $Website,

        [parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [parameter(Mandatory = $true)]
        [System.String]
        $WebAppPool,

        [parameter(Mandatory = $true)]
        [System.String]
        $PhysicalPath,

        [ValidateSet('Present','Absent')]
        [System.String]
        $Ensure = 'Present',

        [ValidateNotNull()]
        [ValidateSet('Ssl','SslNegotiateCert','SslRequireCert')]
        [string[]]$SSlFlags = '',

        [Microsoft.Management.Infrastructure.CimInstance]
        $AuthenticationInfo,

        [Boolean]
        $PreloadEnabled,
        
        [Boolean]
        $ServiceAutoStartEnabled,

        [String]
        $ServiceAutoStartProvider,
        
        [String]
        $ApplicationType
    )

    Assert-Module

    if ($Ensure -eq 'Present')
    {
            $webApplication = Get-WebApplication -Site $Website -Name $Name
 
            if ($AuthenticationInfo -eq $null)
            {
                $AuthenticationInfo = Get-DefaultAuthenticationInfo
            }
 
            if ($webApplication.count -eq 0)
            {
                Write-Verbose "Creating new Web application $Name."
                New-WebApplication -Site $Website -Name $Name -PhysicalPath $PhysicalPath -ApplicationPool $WebAppPool
            }
     
            # Update SslFlags if required
            if ($PSBoundParameters.ContainsKey('SslFlags') -and -not(Test-SslFlags -Location $location -SslFlags $SslFlags))
            {
                Set-WebConfiguration -Location "${Website}/${Name}" -Filter 'system.webserver/security/access' -Value $SSlFlags
            }
     
            # Update Preload if required
            if ($PSBoundParameters.ContainsKey('preloadEnabled') -and $webApplication.preloadEnabled -ne $PreloadEnabled)
            {
                Set-ItemProperty -Path "IIS:\Sites\$Website\$Name" -Name preloadEnabled -Value $preloadEnabled -ErrorAction Stop
            }

            # Update AutoStart if required
            if ($PSBoundParameters.ContainsKey('ServiceAutoStartEnabled') -and $webApplication.serviceAutoStartEnabled -ne $ServiceAutoStartEnabled)
            {
                Set-ItemProperty -Path "IIS:\Sites\$Website\$Name" -Name serviceAutoStartEnabled -Value $serviceAutoStartEnabled -ErrorAction Stop
            }

            # Update AutoStartProviders if required
            if ($PSBoundParameters.ContainsKey('ServiceAutoStartProvider') -and $webApplication.serviceAutoStartProvider -ne $ServiceAutoStartProvider)
            {
                if (-not (Confirm-UniqueServiceAutoStartProviders -ServiceAutoStartProvider $ServiceAutoStartProvider -ApplicationType $ApplicationType))
                    {
                        Set-ItemProperty -Path "IIS:\Sites\$Website\$Name" -Name serviceAutoStartProvider -Value $ServiceAutoStartProvider -ErrorAction Stop
                        Add-WebConfiguration -filter /system.applicationHost/serviceAutoStartProviders -Value @{name=$ServiceAutoStartProvider; type=$ApplicationType} -ErrorAction Stop
                    }
            }
            # Set Authentication; if not defined then pass in DefaultAuthenticationInfo
            Set-AuthenticationInfo -Site $Website -Name $Name -AuthenticationInfo $AuthenticationInfo -ErrorAction Stop
    }

    if ($Ensure -eq 'Absent')
    {
        Write-Verbose "Removing existing Web Application $Name."
        Remove-WebApplication -Site $Website -Name $Name
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
        $Website,

        [parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [parameter(Mandatory = $true)]
        [System.String]
        $WebAppPool,

        [parameter(Mandatory = $true)]
        [System.String]
        $PhysicalPath,

        [ValidateSet('Present','Absent')]
        [System.String]
        $Ensure = 'Present',

        [ValidateNotNull()]
        [ValidateSet('Ssl','SslNegotiateCert','SslRequireCert')]
        [string[]]$SSlFlags = '',

        [Microsoft.Management.Infrastructure.CimInstance]
        $AuthenticationInfo,

        [Boolean]
        $preloadEnabled,
        
        [Boolean]
        $serviceAutoStartEnabled,

        [String]
        $serviceAutoStartProvider,
        
        [String]
        $ApplicationType
    )

    Assert-Module

    $webApplication = Get-WebApplication -Site $Website -Name $Name

    $CurrentSslFlags = Get-SslFlags -Location "${Website}/${Name}"

    if ($AuthenticationInfo -eq $null) 
    { 
        $AuthenticationInfo = Get-DefaultAuthenticationInfo 
    }
    
    if ($webApplication.count -eq 0 -and $Ensure -eq 'Present') 
    {
        Write-Verbose "Web application $Name is absent and should not absent."
        return $false
    }

    if ($webApplication.count -eq 1 -and $Ensure -eq 'Absent') 
    {
        Write-Verbose "Web application $Name should be absent and is not absent."
        return $false
    }
    
    if ($webApplication.count -eq 1 -and $Ensure -eq 'Present') 
    {
        if ($webApplication.physicalPath -ne $PhysicalPath)
        {
            Write-Verbose "Physical path for web application $Name does not match desired state."
            return $false
        }
        if ($webApplication.applicationPool -ne $WebAppPool)
        {
            Write-Verbose "Web application pool for web application $Name does not match desired state."
            return $false
        }
        
        #Check SslFlags
        if ($PSBoundParameters.ContainsKey('SslFlags') -and -not(Test-SslFlags -Location $location -SslFlags $SslFlags))
        {
            Write-Verbose -Message 'SslFlags are not in the desired state'
            return $false
        }

        #Check AuthenticationInfo
        if (Test-AuthenticationInfo -Site $Website -Name $Name -AuthenticationInfo $AuthenticationInfo) 
        { 
            Write-Verbose -Message 'AuthenticationInfo is not in the desired state'
            return $false
        }       
        
        #Check Preload
        if ($PSBoundParameters.ContainsKey('preloadEnabled') -and $webApplication.preloadEnabled -ne $PreloadEnabled)
        {
            Write-Verbose -Message 'Preload is not in the desired state'
            return $false
        } 
             
        #Check AutoStartEnabled
        if($PSBoundParameters.ContainsKey('ServiceAutoStartEnabled') -and $webApplication.serviceAutoStartEnabled -ne $ServiceAutoStartEnabled)
        {
            Write-Verbose -Message 'Autostart is not in the desired state'
            return $false
        }
        
        #Check AutoStartProviders 
        if ($PSBoundParameters.ContainsKey('ServiceAutoStartProvider') -and $webApplication.serviceAutoStartProvider -ne $ServiceAutoStartProvider)
        {
            if (-not (Confirm-UniqueServiceAutoStartProviders -serviceAutoStartProvider $ServiceAutoStartProvider -ApplicationType $ApplicationType))
            {
                Write-Verbose -Message 'AutoStartProviders are not in the desired state'
                return $false     
            }
        }
    }

    return $true
}

Export-ModuleMember -Function *-TargetResource




