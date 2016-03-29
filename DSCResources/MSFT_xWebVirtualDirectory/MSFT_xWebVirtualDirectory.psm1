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
        $WebApplication,

        [parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [parameter(Mandatory = $true)]
        [System.String]
        $PhysicalPath
    )

    Test-Dependancies

    $virtualDirectory = Get-WebVirtualDirectoryInternal -Site $Website -Name $Name -Application $WebApplication

    $PhysicalPath = ''
    $Ensure = 'Absent'

    if ($virtualDirectory.Count -eq 1)
    {
        $PhysicalPath = $virtualDirectory.PhysicalPath
        $Ensure = 'Present'
    }

    $returnValue = @{
        Name = $Name
        Website = $Website
        WebApplication = $WebApplication
        PhysicalPath = $PhysicalPath
        Ensure = $Ensure
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
        $WebApplication,

        [parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [parameter(Mandatory = $true)]
        [System.String]
        $PhysicalPath,

        [ValidateSet('Present','Absent')]
        [System.String]
        $Ensure = 'Present'
    )

    Test-Dependancies

    if ($Ensure -eq 'Present')
    {
        $virtualDirectory = Get-WebVirtualDirectoryInternal -Site $Website -Name $Name -Application $WebApplication
        if ($virtualDirectory.count -eq 0)
        {
            Write-Verbose "Creating new Web Virtual Directory $Name."
            New-WebVirtualDirectory -Site $Website -Application $WebApplication -Name $Name -PhysicalPath $PhysicalPath
        }
        else
        {
            Write-Verbose "Updating physical path for web virtual directory $Name."
            Set-ItemProperty -Path IIS:Sites\$Website\$WebApplication\$Name -Name physicalPath -Value $PhysicalPath
        }
    }

    if ($Ensure -eq 'Absent')
    {
        Write-Verbose "Removing existing Virtual Directory $Name."
        Remove-WebVirtualDirectory -Site $Website -Application $WebApplication -Name $Name
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
        $WebApplication,

        [parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [parameter(Mandatory = $true)]
        [System.String]
        $PhysicalPath,

        [ValidateSet('Present','Absent')]
        [System.String]
        $Ensure = 'Present'
    )

    Test-Dependancies

    Write-Verbose 'Checking the virtual directories for the website.'
    $virtualDirectory = Get-WebVirtualDirectoryInternal -Site $Website -Name $Name -Application $WebApplication

    if ($virtualDirectory.Count -eq 1 -and $Ensure -eq 'Present')
    {
        if ($virtualDirectory.PhysicalPath -eq $PhysicalPath)
        {
            Write-Verbose 'Web virtual directory is in required state'
            return $true
        }
        else
        {
            Write-Verbose "Physical path $PhysicalPath for web virtual directory $Name does not match desired state."
            return $false
        }
    }

    if ($virtualDirectory.count -eq 0 -and $Ensure -eq 'Absent')
    {
        Write-Verbose "Web virtual directory $Name should be absent and is absent"
        return $true
    }

    return $false
}

function Test-Dependancies
{
    Write-Verbose 'Checking whether WebAdministration is there in the machine or not.'
    # Check if WebAdministration module is present for IIS cmdlets
    if(!(Get-Module -ListAvailable -Name WebAdministration))
    {
        Throw 'Please ensure that WebAdministration module is installed.'
    }
}

function Get-WebVirtualDirectoryInternal
{
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [parameter(Mandatory = $true)]
        [System.String]
        $Site,

        [parameter(Mandatory = $true)]
        [System.String]
        $Application
    )

    if ((Test-ApplicationExists -Site $Site -Application $Application) -ne $true)
    {
        return Get-WebVirtualDirectory -Site $Site -Name $(Get-CompositeName -Name $Name -Application $Application)
    }

    return Get-WebVirtualDirectory -Site $Site -Application $Application -Name $Name
}

function Test-ApplicationExists
{
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $Site,

        [parameter(Mandatory = $true)]
        [System.String]
        $Application
    )

    $WebApplication = Get-WebApplication -Site $Site -Name $Application

    if ($WebApplication.Count -eq 1)
    {
        return $true
    }

    Write-Warning "Specified Web Application $Application does not exist."

    return $false
}

function Get-CompositeName
{
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [parameter(Mandatory = $true)]
        [System.String]
        $Application
    )

    return "$Application/$Name"
}

Export-ModuleMember -Function *-TargetResource




