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

    $PhysicalPath = ''
    $Ensure = 'Absent'
    $WebAppPool = ''

    if ($webApplication)
    {
        $PhysicalPath             = $webApplication.PhysicalPath
        $WebAppPool               = $webApplication.applicationPool
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
        Ensure                   = $Ensure
        PreloadEnabled           = $PreloadEnabled
        ServiceAutoStartProvider = $ServiceAutoStartProvider
        ServiceAutoStartEnabled  = $ServiceAutoStartEnabled
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
        if ($webApplication.count -eq 0)
        {
            Write-Verbose "Creating new Web application $Name."
            New-WebApplication -Site $Website -Name $Name -PhysicalPath $PhysicalPath -ApplicationPool $WebAppPool
            # Update Preload if required
            if ($preloadEnabled)
            {
                Set-ItemProperty -Path "IIS:\Sites\$Website\$Name" -Name preloadEnabled -Value $preloadEnabled -ErrorAction Stop
            }
                
            # Update AutoStart if required
            if ($ServiceAutoStartEnabled)
            {
                Set-ItemProperty -Path "IIS:\Sites\$Website\$Name" -Name serviceAutoStartEnabled -Value $serviceAutoStartEnabled -ErrorAction Stop
            }
                
            # Update AutoStartProviders if required
            if ($ServiceAutoStartProvider -and $ApplicationType)
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
            # Update Preload if required
            if ($webApplication.preloadEnabled -ne $PreloadEnabled)
            {
               Set-ItemProperty -Path "IIS:\Sites\$Website\$Name" -Name preloadEnabled -Value $PreloadEnabled -ErrorAction Stop
            }
            
            # Update AutoStart if required
            if ($webApplication.serviceAutoStartEnabled -ne $ServiceAutoStartEnabled)
            {
                Set-ItemProperty -Path "IIS:\Sites\$Website\$Name" -Name serviceAutoStartEnabled -Value $ServiceAutoStartEnabled -ErrorAction Stop
            }

            # Update AutoStartProviders if required
            if ($ServiceAutoStartProvider -and $ApplicationType)
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
        Throw 'Please ensure that WebAdministration module is installed.'
    }
}

function Confirm-UniqueServiceAutoStartProviders
{
    <#
    .SYNOPSIS
        Helper function used to validate that the AutoStartProviders is unique to other websites.
        Returns False if the AutoStartProviders exist.
;    .PARAMETER serviceAutoStartProvider
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
        $serviceAutoStartProvider,

        [Parameter(Mandatory = $true)]
        [String]
        $ApplicationType
    )

$WebSiteAutoStartProviders = (Get-WebConfiguration -filter /system.applicationHost/serviceAutoStartProviders).Collection

$ExistingObject = $WebSiteAutoStartProviders |  Where-Object -Property Name -eq -Value $serviceAutoStartProvider | Select-Object Name,Type

$ProposedObject = @(New-Object -TypeName PSObject -Property @{
                                                                name   = $serviceAutoStartProvider
                                                                type   = $ApplicationType
                                                             })

$Result = $true

if (-Not $ExistingObject)
    {
        $Result = $false
        return $Result
    }

if (-Not (Compare-Object -ReferenceObject $ExistingObject -DifferenceObject $ProposedObject -Property name))
    {
        if(Compare-Object -ReferenceObject $ExistingObject -DifferenceObject $ProposedObject -Property type)
        {
        throw 'Desired AutoStartProvider is not valid due to a conflicting Global Property. Ensure that the serviceAutoStartProvider is a unique key.'
        }
    }

return $Result

}

#endregion

Export-ModuleMember -Function *-TargetResource




