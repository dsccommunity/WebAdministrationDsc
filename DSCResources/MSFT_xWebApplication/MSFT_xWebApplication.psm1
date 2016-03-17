# Load the Helper Module
Import-Module -Name "$PSScriptRoot\..\Helper.psm1" -Verbose:$false

# Localized messages
data LocalizedData
{
    # culture="en-US"
    ConvertFrom-StringData -StringData @'
ErrorWebAdministrationModuleNotFound = Please ensure that WebAdministration module is installed.
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
        [string]$SSlFlags = '',

        [Microsoft.Management.Infrastructure.CimInstance]
        $AuthenticationInfo,

        [ValidateSet('True','False')]
        [String]
        $PreloadEnabled,
        
        [ValidateSet('True','False')]
        [String]
        $ServiceAutoStartEnabled,

        [String]
        $ServiceAutoStartProvider,
        
        [String]
        $ApplicationType
    )

    CheckDependencies

    $webApplication = Get-WebApplication -Site $Website -Name $Name

    $AuthenticationInfo = Get-AuthenticationInfo -Site $Website -Name $Name

    $SslFlags = (Get-SslFlags -Location "${Website}/${Name}")

    $PhysicalPath = ''
    $Ensure = 'Absent'
    $WebAppPool = ''

    if ($webApplication)
    {
        $PhysicalPath             = $webApplication.PhysicalPath
        $WebAppPool               = $webApplication.applicationPool
        $Authentication           = $AuthenticationInfo
        $SSLSettings              = $SslFlags
        $PreloadEnabled           = $webApplication.preloadEnabled
        $ServiceAutoStartProvider = $webApplication.serviceAutoStartProvider
        $ServiceAutoStartEnabled  = $webApplication.serviceAutoStartEnabled
        $Ensure                   = 'Present'
    }

    $returnValue = @{
        Website                  = $Website
        Name                     = $Name
        WebAppPool               = $WebAppPool
        PhysicalPath             = $PhysicalPath
        Authentication           = $Authentication
        SslFlags                 = $SSLSettings
        PreloadEnabled           = $PreloadEnabled
        ServiceAutoStartProvider = $ServiceAutoStartProvider
        ServiceAutoStartEnabled  = $ServiceAutoStartEnabled
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
        [string]$SSlFlags = '',

        [Microsoft.Management.Infrastructure.CimInstance]
        $AuthenticationInfo,

        [ValidateSet('True','False')]
        [String]
        $PreloadEnabled,
        
        [ValidateSet('True','False')]
        [String]
        $ServiceAutoStartEnabled,

        [String]
        $ServiceAutoStartProvider,
        
        [String]
        $ApplicationType
    )

    CheckDependencies

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
            
            if ($PSBoundParameters.ContainsKey('AuthenticationInfo'))
            {
                Set-AuthenticationInfo -Site $Website -Name $Name -AuthenticationInfo $AuthenticationInfo -ErrorAction Stop
            }

            # Update SslFlags if required
            if ($PSBoundParameters.ContainsKey('SslFlags'))
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

        }
        else
        {
            if ($webApplication.physicalPath -ne $PhysicalPath)
            {
                Write-Verbose "Updating physical path for Web application $Name."
                Set-WebConfigurationProperty -Filter "$($webApplication.ItemXPath)/virtualDirectory[@path='/']" -Name physicalPath -Value $PhysicalPath
            }
            
            if ($webApplication.applicationPool -ne $WebAppPool)
            {
                Write-Verbose "Updating application pool for Web application $Name."
                Set-WebConfigurationProperty -Filter $webApplication.ItemXPath -Name applicationPool -Value $WebAppPool
            }

            if ($PSBoundParameters.ContainsKey('AuthenticationInfo'))
            {
                Set-AuthenticationInfo -Site $Website -Name $Name -AuthenticationInfo $AuthenticationInfo -ErrorAction Stop
            }
            # Update SslFlags if required

            if ($PSBoundParameters.ContainsKey('SslFlags'))
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
        }
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
        [string]$SSlFlags = '',

        [Microsoft.Management.Infrastructure.CimInstance]
        $AuthenticationInfo,

        [ValidateSet('True','False')]
        [String]
        $preloadEnabled,
        
        [ValidateSet('True','False')]
        [String]
        $serviceAutoStartEnabled,

        [String]
        $serviceAutoStartProvider,
        
        [String]
        $ApplicationType
    )

    CheckDependencies

    $webApplication = Get-WebApplication -Site $Website -Name $Name

    $CurrentSslFlags = Get-SslFlags -Location "${Website}/${Name}"

    if ($AuthenticationInfo -eq $null) 
    { 
        $AuthenticationInfo = Get-DefaultAuthenticationInfo 
    }
    
    if ($webApplication.count -eq 0 -and $Ensure -eq 'Present') {
        Write-Verbose "Web application $Name is absent and should not absent."
        return $false
    }
    
    if ($webApplication.count -eq 1 -and $Ensure -eq 'Present') {
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
        if ($CurrentSslFlags -ne $SslFlags)
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
        if($webApplication.preloadEnabled -ne $PreloadEnabled)
        {
            Write-Verbose -Message 'Preload is not in the desired state'
            return $false
        } 
             
        #Check AutoStartEnabled
        if($webApplication.serviceAutoStartEnabled -ne $ServiceAutoStartEnabled)
        {
            Write-Verbose -Message 'Autostart is not in the desired state'
            return $false
        }
        
        #Check AutoStartProviders 
        if($webApplication.serviceAutoStartProvider -ne $ServiceAutoStartProvider)
        {
            if (-not (Confirm-UniqueServiceAutoStartProviders -serviceAutoStartProvider $ServiceAutoStartProvider -ApplicationType $ApplicationType))
            {
                Write-Verbose -Message 'AutoStartProviders are not in the desired state'
                return $false     
            }
        }
    }

    if ($webApplication.count -eq 1 -and $Ensure -eq 'Absent') {
        Write-Verbose "Web application $Name should be absent and is not absent."
        return $false
    }

    return $true
}

#region Helper Functions

function CheckDependencies
{
    Write-Verbose 'Checking whether WebAdministration is there in the machine or not.'
    # Check if WebAdministration module is present for IIS cmdlets
    if(!(Get-Module -ListAvailable -Name WebAdministration))
    {
        $ErrorMessage = $LocalizedData.ErrorWebAdministrationModuleNotFound
        New-TerminatingError -ErrorId 'ErrorWebAdministrationModuleNotFound' -ErrorMessage $ErrorMessage -ErrorCategory 'InvalidResult'
    }
}

function Confirm-UniqueServiceAutoStartProviders
{
    <#
    .SYNOPSIS
        Helper function used to validate that the AutoStartProviders is unique to other websites.
        Returns False if the AutoStartProviders exist.
    .PARAMETER serviceAutoStartProvider
        Specifies the name of the AutoStartProviders.
    .PARAMETER ExcludeStopped
        Specifies the name of the Application Type for the AutoStartProvider.
    .NOTES
        This tests for the existance of a AutoStartProviders which is globally assigned. As AutoStartProviders
        need to be uniquely named it will check for this and error out if attempting to add a duplicatly named AutoStartProvider.
        Name is passed in to bubble to any error messages during the test.
    #>
    
    [CmdletBinding()]
    [OutputType([Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [String]
        $ServiceAutoStartProvider,

        [Parameter(Mandatory = $true)]
        [String]
        $ApplicationType
    )

$WebSiteAutoStartProviders = (Get-WebConfiguration -filter /system.applicationHost/serviceAutoStartProviders).Collection

$ExistingObject = $WebSiteAutoStartProviders |  Where-Object -Property Name -eq -Value $serviceAutoStartProvider | Select-Object Name,Type

$ProposedObject = @(New-Object -TypeName PSObject -Property @{
                                                                name   = $ServiceAutoStartProvider
                                                                type   = $ApplicationType
                                                             })

$Result = $true

if(-not $ExistingObject)
    {
        $Result = $false
        return $Result
    }

if(-not (Compare-Object -ReferenceObject $ExistingObject -DifferenceObject $ProposedObject -Property name))
    {
        if(Compare-Object -ReferenceObject $ExistingObject -DifferenceObject $ProposedObject -Property type)
        {
        $ErrorMessage = $LocalizedData.ErrorWebsiteTestAutoStartProviderFailure
        New-TerminatingError -ErrorId 'ErrorWebsiteTestAutoStartProviderFailure' -ErrorMessage $ErrorMessage -ErrorCategory 'InvalidResult'
        }
    }

return $Result

}

function Confirm-UniqueSASP
{
    <#
    .SYNOPSIS
        Helper function used to validate that the AutoStartProviders is unique to other websites.
        Returns False if the AutoStartProviders exist.
    .PARAMETER serviceAutoStartProvider
        Specifies the name of the AutoStartProviders.
    .PARAMETER ExcludeStopped
        Specifies the name of the Application Type for the AutoStartProvider.
    .NOTES
        This tests for the existance of a AutoStartProviders which is globally assigned. As AutoStartProviders
        need to be uniquely named it will check for this and error out if attempting to add a duplicatly named AutoStartProvider.
        Name is passed in to bubble to any error messages during the test.
    #>
    
    [CmdletBinding()]
    [OutputType([Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [String]
        $ServiceAutoStartProvider,

        [Parameter(Mandatory = $true)]
        [String]
        $ApplicationType
    )

$WebSiteAutoStartProviders = (Get-WebConfiguration -filter /system.applicationHost/serviceAutoStartProviders).Collection

$ExistingObject = $WebSiteAutoStartProviders |  Where-Object -Property Name -eq -Value $serviceAutoStartProvider | Select-Object Name,Type

$ProposedObject = @(New-Object -TypeName PSObject -Property @{
                                                                name   = $ServiceAutoStartProvider
                                                                type   = $ApplicationType
                                                             })

$Result = $true

if(-not $ExistingObject)
    {
        $Result = $false
        return $Result
    }

if(-not (Compare-Object -ReferenceObject $ExistingObject -DifferenceObject $ProposedObject -Property name))
    {
        if(Compare-Object -ReferenceObject $ExistingObject -DifferenceObject $ProposedObject -Property type)
        {
        $ErrorMessage = $LocalizedData.ErrorWebsiteTestAutoStartProviderFailure
        New-TerminatingError -ErrorId 'ErrorWebsiteTestAutoStartProviderFailure' -ErrorMessage $ErrorMessage -ErrorCategory 'InvalidResult'
        }
    }

return $Result

}

function Get-AuthenticationInfo
{
    <#
    .SYNOPSIS
        Helper function used to validate that the authenticationProperties for an Application.
    .PARAMETER Site
        Specifies the name of the Website.
    .PARAMETER Name
        Specifies the name of the Application.
    #>

    [OutputType([Microsoft.Management.Infrastructure.CimInstance])]
    Param
    (
        [parameter(Mandatory = $true)]
        [System.String]$Site,

        [parameter(Mandatory = $true)]
        [System.String]$Name
    )

    $authenticationProperties = @{}
    foreach ($type in @('Anonymous', 'Basic', 'Digest', 'Windows'))
    {
        $authenticationProperties[$type] = [string](Test-AuthenticationEnabled -Site $Site -Name $Name -Type $type)
    }

    return New-CimInstance -ClassName MSFT_xWebApplicationAuthenticationInformation -ClientOnly -Property $authenticationProperties
}

function Get-DefaultAuthenticationInfo
{
    <#
    .SYNOPSIS
        Helper function used to build a default CimInstance for AuthenticationInformation
    #>

    New-CimInstance -ClassName MSFT_xWebApplicationAuthenticationInformation `
        -ClientOnly `
        -Property @{Anonymous='false';Basic='false';Digest='false';Windows='false'}
}

function Get-SslFlags
{
    <#
    .SYNOPSIS
        Helper function used to return the SSLFlags on an Application.
    .PARAMETER Location
        Specifies the path in the IIS: PSDrive to the Application
    #>
    
    [CmdletBinding()]
    param
    (
        [System.String]$Location
    )

    $SslFlags = Get-WebConfiguration -PSPath IIS:\Sites -Location $Location -Filter 'system.webserver/security/access' | ForEach-Object { $_.sslFlags }
    $SslFlags = if ($SslFlags -eq $null) 
        { 
            '' 
        } 
        else 
        { 
            $SslFlags 
        }

    return $SslFlags
}

function Set-Authentication
{
    <#
    .SYNOPSIS
        Helper function used to set authenticationProperties for an Application.
    .PARAMETER Site
        Specifies the name of the Website.
    .PARAMETER Name
        Specifies the name of the Application.
    .PARAMETER Type
        Specifies the type of Authentication, Limited to the set: ('Anonymous','Basic','Digest','Windows').
    .PARAMETER Enabled
        Whether the Authentication is enabled or not.
    #>

    Param
    (
        [parameter(Mandatory = $true)]
        [System.String]$Site,

        [parameter(Mandatory = $true)]
        [System.String]$Name,

        [parameter(Mandatory = $true)]
        [ValidateSet('Anonymous','Basic','Digest','Windows')]
        [System.String]$Type,

        [System.Boolean]$Enabled
    )

    Set-WebConfigurationProperty -Filter /system.WebServer/security/authentication/${Type}Authentication `
        -Name enabled `
        -Value $Enabled `
        -Location "${Site}/${Name}"
}

function Set-AuthenticationInfo
{
    <#
    .SYNOPSIS
        Helper function used to validate that the authenticationProperties for an Application.
    .PARAMETER Site
        Specifies the name of the Website.
    .PARAMETER Name
        Specifies the name of the Application.
    .PARAMETER AuthenticationInfo
        A CimInstance of what state the AuthenticationInfo should be.
    #>

    param
    (
        [parameter(Mandatory = $true)]
        [System.String]$Site,

        [parameter(Mandatory = $true)]
        [System.String]$Name,

        [parameter()]
        [ValidateNotNullOrEmpty()]
        [Microsoft.Management.Infrastructure.CimInstance]$AuthenticationInfo
    )

    foreach ($type in @('Anonymous', 'Basic', 'Digest', 'Windows'))
    {
        $enabled = ($AuthenticationInfo.CimInstanceProperties[$type].Value -eq $true)
        Set-Authentication -Site $Site -Name $Name -Type $type -Enabled $enabled
    }
}

function Test-AuthenticationEnabled
{
    <#
    .SYNOPSIS
        Helper function used to test the authenticationProperties state for an Application. 
        Will return that value which will either [string]True or [String]False
    .PARAMETER Site
        Specifies the name of the Website.
    .PARAMETER Name
        Specifies the name of the Application.
   .PARAMETER Type
        Specifies the type of Authentication, Limited to the set: ('Anonymous','Basic','Digest','Windows').
    #>

    [OutputType([System.Boolean])]
    Param
    (
        [parameter(Mandatory = $true)]
        [System.String]$Site,

        [parameter(Mandatory = $true)]
        [System.String]$Name,

        [parameter(Mandatory = $true)]
        [ValidateSet('Anonymous','Basic','Digest','Windows')]
        [System.String]$Type
    )


    $prop = Get-WebConfigurationProperty `
        -Filter /system.WebServer/security/authentication/${Type}Authentication `
        -Name enabled `
        -Location "${Site}/${Name}"
    return $prop.Value
}

function Test-AuthenticationInfo
{
    <#
    .SYNOPSIS
        Helper function used to test the authenticationProperties state for an Application. 
        Will return that result which will either [boolean]$True or [boolean]$False for use in Test-TargetResource.
        Uses Test-AuthenticationEnabled to determine this. First incorrect result will break this function out.
    .PARAMETER Site
        Specifies the name of the Website.
    .PARAMETER Name
        Specifies the name of the Application.
    .PARAMETER AuthenticationInfo
        A CimInstance of what state the AuthenticationInfo should be.
    #>

    [OutputType([System.Boolean])]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]$Site,

        [parameter(Mandatory = $true)]
        [System.String]$Name,

        [parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [Microsoft.Management.Infrastructure.CimInstance]$AuthenticationInfo
    )

    $result = $true

    foreach ($type in @('Anonymous', 'Basic', 'Digest', 'Windows'))
    {

        $expected = $AuthenticationInfo.CimInstanceProperties[$type].Value
        $actual = Test-AuthenticationEnabled -Site $Site -Name $Name -Type $type
        if ($expected -ne $actual)
        {
            $result = $false
            break
        }
    }

    return $result
}

#endregion

Export-ModuleMember -Function *-TargetResource




