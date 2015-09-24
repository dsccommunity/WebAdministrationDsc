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

    $ManagedRuntimeVersion = Get-ItemProperty IIS:\AppPools\$Name managedRuntimeVersion.Value
    $IdentityType = Get-ItemProperty IIS:\AppPools\$Name processModel.identityType

    $returnValue = @{
        Name   = $Name
        Ensure = $Ensure
        State  = $State
        ManagedRuntimeVersion = $ManagedRuntimeVersion
        IdentityType = $IdentityType
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
        $State = "Started",
                
        [ValidateSet("", "v2.0","v4.0")]
        [string]
        $ManagedRuntimeVersion,

        [ValidateSet("ApplicationPoolIdentity","LocalService","LocalSystem","NetworkService")]
        [string]
        $IdentityType
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

        if($ManagedRuntimeVersion -and $AppPool.ManagedRuntimeVersion -ne $ManagedRuntimeVersion)
        {
            Write-Verbose("Setting managedRuntimeVersion to $ManagedRuntimeVersion")
            Set-ItemProperty IIS:\AppPools\$Name managedRuntimeVersion $ManagedRuntimeVersion
    }

        if($IdentityType -and $AppPool.ManagedRuntimeVersion -ne $IdentityType)
        {
            Write-Verbose("Setting processModel.IdentityType to $IdentityType")
            
            $propertyData = Get-ItemProperty IIS:\AppPools\$Name processModel
            $propertyData.IdentityType = $IdentityType
            Set-ItemProperty IIS:\AppPools\$Name processModel $propertyData
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
        $State = "Started",

        [ValidateSet("", "v2.0","v4.0")]
        [System.String]
        $ManagedRuntimeVersion,

        [ValidateSet("ApplicationPoolIdentity","LocalService","LocalSystem","NetworkService")]
        [System.String]
        $IdentityType    
    )

    $WebAppPool = Get-TargetResource -Name $Name

    if($Ensure -eq 'Present')
    {
        if($WebAppPool.Ensure -eq $Ensure -and $WebAppPool.State -eq $state `
            -and (!$ManagedRuntimeVersion -or $WebAppPool.ManagedRuntimeVersion -eq $ManagedRuntimeVersion) `
            -and (!$IdentityType -or $WebAppPool.IdentityType -eq $IdentityType))
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


