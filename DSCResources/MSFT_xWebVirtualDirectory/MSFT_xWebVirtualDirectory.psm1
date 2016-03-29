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
        [AllowEmptyString()]
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

    $virtualDirectory = Get-WebVirtualDirectory -Site $Website -Name $Name -Application $WebApplication

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
        [AllowEmptyString()]
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
        $virtualDirectory = Get-WebVirtualDirectory -Site $Website -Name $Name -Application $WebApplication
        if ($virtualDirectory.count -eq 0)
        {
            Write-Verbose "Creating new Web Virtual Directory $Name."
            New-WebVirtualDirectory -Site $Website -Application $WebApplication -Name $Name -PhysicalPath $PhysicalPath
        }
        else
        {
            Write-Verbose "Updating physical path for web virtual directory $Name."

            if ($WebApplication.Length -gt 0)
            {
                $ItemPath = "IIS:Sites\$Website\$WebApplication\$Name"
            }
            else
            {
                $ItemPath = "IIS:Sites\$Website\$Name"
            }

            Set-ItemProperty -Path $ItemPath -Name physicalPath -Value $PhysicalPath
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
        [AllowEmptyString()]
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
    $virtualDirectory = Get-WebVirtualDirectory -Site $Website -Name $Name -Application $WebApplication

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

Export-ModuleMember -Function *-TargetResource




