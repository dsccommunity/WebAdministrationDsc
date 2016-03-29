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
        $PhysicalPath
    )

    CheckDependencies

    $webApplication = Get-WebApplication -Site $Website -Name $Name

    $PhysicalPath = ''
    $Ensure = 'Absent'
    $WebAppPool = ''

    if ($webApplication.Count -eq 1)
    {
        $PhysicalPath = $webApplication.PhysicalPath
        $WebAppPool = $webApplication.applicationPool
        $Ensure = 'Present'
    }

    $returnValue = @{
        Website = $Website
        Name = $Name
        WebAppPool = $WebAppPool
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
        $Name,

        [parameter(Mandatory = $true)]
        [System.String]
        $WebAppPool,

        [parameter(Mandatory = $true)]
        [System.String]
        $PhysicalPath,

        [ValidateSet('Present','Absent')]
        [System.String]
        $Ensure = 'Present'
    )

    CheckDependencies

    if ($Ensure -eq 'Present')
    {
        $webApplication = Get-WebApplication -Site $Website -Name $Name
        if ($webApplication.count -eq 0)
        {
            Write-Verbose "Creating new Web application $Name."
            New-WebApplication -Site $Website -Name $Name -PhysicalPath $PhysicalPath -ApplicationPool $WebAppPool
        }
        else
        {
            if ($webApplication.physicalPath -ne $PhysicalPath)
            {
                Write-Verbose "Updating physical path for Web application $Name."
                Set-ItemProperty -Path IIS:Sites\$Website\$Name -Name physicalPath -Value $PhysicalPath
            }
            if ($webApplication.applicationPool -ne $ApplicationPool)
            {
                Write-Verbose "Updating physical path for Web application $Name."
                Set-ItemProperty -Path IIS:Sites\$Website\$Name -Name applicationPool -Value $WebAppPool 
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
        $Ensure = 'Present'
    )

    CheckDependencies

    $webApplication = Get-WebApplication -Site $Website -Name $Name

    if ($webApplication.count -eq 1 -and $Ensure -eq 'Present') {
        if ($webApplication.physicalPath -ne $PhysicalPath)
        {
            Write-Verbose "Physical path for web application $Name does not match desired state."
            return $false
        }
        elseif ($webApplication.applicationPool -ne $WebAppPool)
        {
            Write-Verbose "Web application pool for web application $Name does not match desired state."
            return $false
        }
        else
        {
            Write-Verbose 'Web application pool matches desired state.'
            return $true
        }
    }

    if ($webApplication.count -eq 0 -and $Ensure -eq 'Absent') {
        Write-Verbose "Web application $Name should be absent and is absent."
        return $true
    }

    return $false
}

function CheckDependencies
{
    Write-Verbose 'Checking whether WebAdministration is there in the machine or not.'
    # Check if WebAdministration module is present for IIS cmdlets
    if(!(Get-Module -ListAvailable -Name WebAdministration))
    {
        Throw 'Please ensure that WebAdministration module is installed.'
    }
}

Export-ModuleMember -Function *-TargetResource




