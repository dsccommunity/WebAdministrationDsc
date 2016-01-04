function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $Name
    )

    $Ensure = 'Absent'
    $State  = 'Stopped'

    # Check if webadministration module is present or not
    if(!(Get-Module -ListAvailable -Name WebAdministration))
    {
        Throw 'Please ensure that WebAdministration module is installed.'
    }

    # Need to import explicitly to run for IIS:\AppPools
    # Setting verbose to false to avoid seeing all the imported command in
    # DSC configuration verbose messages when configuration is run with -Verbose specified
    Import-Module WebAdministration -Verbose:$false

    $AppPool = Get-Item -Path IIS:\AppPools\* | ? {$_.name -eq $Name}

    if($AppPool -ne $null)
    {
        $Ensure = 'Present'
        $State  = $AppPool.state
    }

    $returnValue = @{
        Name   = $Name
        Ensure = $Ensure
        State  = $State
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
        $Name,

        [ValidateSet('Present','Absent')]
        [System.String]
        $Ensure = 'Present',

        [ValidateSet('Started','Stopped')]
        [System.String]
        $State = 'Started'
    )

    if($Ensure -eq 'Absent')
    {
        Write-Verbose('Removing the Web App Pool')
        Remove-WebAppPool $Name
    }
    else
    {
        $AppPool = Get-TargetResource -Name $Name
        if($AppPool.Ensure -ne 'Present')
        {
            Write-Verbose('Creating the Web App Pool')
            New-WebAppPool $Name
            $AppPool = Get-TargetResource -Name $Name
        }

        if($AppPool.State -ne $State)
        {
            ExecuteRequiredState -Name $Name -State $State
        }
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
        $Name,

        [ValidateSet('Present','Absent')]
        [System.String]
        $Ensure  = 'Present',

        [ValidateSet('Started','Stopped')]
        [System.String]
        $State = 'Started'
    )
    $WebAppPool = Get-TargetResource -Name $Name

    if($Ensure -eq 'Present')
    {
        if($WebAppPool.Ensure -eq $Ensure -and $WebAppPool.State -eq $state)
        {
            return $true
        }
    }
    elseif($WebAppPool.Ensure -eq $Ensure)
    {
        return $true
    }

    return $false
}


function ExecuteRequiredState([string] $Name, [string] $State)
{
    if($State -eq 'Started')
    {
        Write-Verbose('Starting the Web App Pool')
        start-WebAppPool -Name $Name
    }
    else
    {
        Write-Verbose('Stopping the Web App Pool')
        Stop-WebAppPool -Name $Name
    }
}

Export-ModuleMember -Function *-TargetResource


