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

    CheckDependencies

    $virtualDirectory = GetWebVirtualDirectoryInternal -Site $Website -Name $Name -Application $WebApplication

    $PhysicalPath = ""
    $Ensure = "Absent"

    if ($virtualDirectory.Count -eq 1)
    {
        $PhysicalPath = $virtualDirectory.PhysicalPath
        $Ensure = "Present"
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

        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure = "Present"
    )

    CheckDependencies

    if ($Ensure -eq "Present")
    {
        $virtualDirectory = GetWebVirtualDirectoryInternal -Site $Website -Name $Name -Application $WebApplication
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

    if ($Ensure -eq "Absent")
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

        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure = "Present"
    )

    CheckDependencies

    Write-Verbose "Checking the virtual directories for the website."
    $virtualDirectory = GetWebVirtualDirectoryInternal -Site $Website -Name $Name -Application $WebApplication

    if ($virtualDirectory.count -eq 1 -and $Ensure -eq "Present")
    {
        if ($virtualDirectory.physicalPath -eq $PhysicalPath)
        {
            Write-Verbose "Web virtual directory is in required state"
            return $true
        }
        else
        {
            Write-Verbose "Physical path $PhysicalPath for web virtual directory $Name does not match desired state."
            return $false
        }
    }

    if ($virtualDirectory.count -eq 0 -and $Ensure -eq "Absent")
    {
        Write-Verbose "Web virtual direcotry $Name should be absent and is absent"
        return $true
    }

    return $false
}

function CheckDependencies
{
    Write-Verbose "Checking whether WebAdministration is there in the machine or not."
    # Check if WebAdministration module is present for IIS cmdlets
    if(!(Get-Module -ListAvailable -Name WebAdministration))
    {
        Throw "Please ensure that WebAdministration module is installed."
    }
}

function GetWebVirtualDirectoryInternal
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

    If ((CheckApplicationExists -Site $Site -Application $Application) -ne $true)
    {
        $compositeVirtualDirectoryName = GetCompositeVirtualDirectoryName -Name $Name -Application $Application 
        return Get-WebVirtualDirectory -site $Site -Name $compositeVirtualDirectoryName
    }

    return Get-WebVirtualDirectory -site $Site -Application $Application -Name $Name
}

function CheckApplicationExists
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

    if ($WebApplication.count -eq 1)
    {
        return $true
    }

    Write-Warning "Specified Web Application $Application does not exist."

    return $false
}

function GetCompositeVirtualDirectoryName
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




