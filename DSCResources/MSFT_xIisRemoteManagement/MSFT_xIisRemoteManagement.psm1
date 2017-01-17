# Load the Helper Module
Import-Module -Name ('{0}\..\Helper.psm1' -f $PSScriptRoot)

# Localized messages
data LocalizedData
{
    # culture="en-US"
    ConvertFrom-StringData -StringData @'
        VerboseSetTargetInstallingRemoteManagement = Adding IIS Remote Management Feature.
        VerboseSetTargetEnablingRemoteManagement   = Enabling IIS Remote Management.
        VerboseSetTargetDisablingRemoteManagement  = Disabling IIS Remote Management.
        VerboseSetTargetStoppingRemoteManagement   = Stopping IIS Remote Management.
        VerboseTestTargetState                     = State is not in the desired state.
        VerboseTestTargetEnsure                    = Ensure not in the desired state.
        VerboseGetTargetResult                     = Get-TargetResource has been run.
        ErrorWebServerStateFailure = IIS WebServer is not installed. Please install IIS first.
'@
}

<#
    .SYNOPSYS
    The Get-TargetResource cmdlet is used to fetch the status of role or Website on the target 
    machine. It gives the Website info of the requested role/feature on the target machine.

    .PARAMETER State
    State of the WMSVC. Accepts only 'Started' and 'Stopped'

    .PARAMETER Ensure
    Whether IIS RemoteManagement is installed or not. Accepts only 'Present' and 'Absent'.
#>
function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]
        [ValidateSet('Started','Stopped')]
        [String] $State,

        [parameter(Mandatory = $true)]
        [ValidateSet('Present','Absent')]
        [String] $Ensure
    )

    Assert-Module

    if ((Get-WindowsFeature -Name Web-Server).Installed -ne $true)
    { 
        $errorMessage = $LocalizedData.ErrorWebServerStateFailure -f $_.Exception.Message
        New-TerminatingError -ErrorId 'WebServerStateFailure' `
                             -ErrorMessage $errorMessage `
                             -ErrorCategory 'InvalidOperation'
    }

    $installed = (Get-WindowsFeature -Name Web-Mgmt-Service `
                                     -ErrorAction SilentlyContinue).Installed

    $service = (Get-Service -Name WMSVC `
                            -ErrorAction SilentlyContinue).Status

    if($installed -ne $true)
    {
        $Ensure = 'Absent'
    }
    else
    {
        $Ensure = 'Present'
    }

    if($service -ne 'Running')
    {
        $State = 'Stopped'
    }
    else
    {
        $State = 'Started'
    }

    return @{
        State  = $State
        Ensure = $Ensure
    }

    Write-Verbose -Message ($LocalizedData.VerboseGetTargetResult)
}

<#
    .SYNOPSIS
    The Set-TargetResource cmdlet is used to configure a IIS RemoteManagement on the
    target machine.

    .PARAMETER State
    State of the WMSVC. Accepts only 'Started' and 'Stopped'

    .PARAMETER Ensure
    Whether IIS RemoteManagement is installed or not. Accepts only 'Present' and 'Absent'.
#>
function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory = $true)]
        [ValidateSet('Started','Stopped')]
        [String] $State,

        [parameter(Mandatory = $true)]
        [ValidateSet('Present','Absent')]
        [String] $Ensure
    )

    Assert-Module

    $getState = Get-TargetResource -State $State -Ensure $Ensure
    $service = 'WMSVC'
    $windowsFeature = 'Web-Mgmt-Service'
    $module = 'ServerManager'

    if ($getState.Ensure -ne $Ensure)
    {
        if ($Ensure -eq 'Present')
        {
            Write-Verbose -Message ($LocalizedData.VerboseSetTargetInstallingRemoteManagement)
            Import-Module -Name $module
            Install-WindowsFeature -Name $windowsFeature
        }
        if ($Ensure -eq 'Absent')
        {
            Write-Verbose -Message ($LocalizedData.VerboseSetTargetInstallingRemoteManagement)
            Import-Module -Name $module
            Uninstall-WindowsFeature -Name $windowsFeature
        }
    }

    if ($getState.State -ne $State)
    {
        if ($State -eq 'Started')
        {
            Write-Verbose -Message ($LocalizedData.VerboseSetTargetEnablingRemoteManagement)
            Set-ItemProperty -Path HKLM:\SOFTWARE\Microsoft\WebManagement\Server `
                             -Name EnableRemoteManagement -Value 1
            Set-Service -Name $service `
                        -StartupType Automatic
            Start-Service -Name $service
        }
        if ($State -eq 'Stopped')
        {
            Write-Verbose -Message ($LocalizedData.VerboseSetTargetDisablingRemoteManagement)
            Set-ItemProperty -Path HKLM:\SOFTWARE\Microsoft\WebManagement\Server `
                             -Name EnableRemoteManagement -Value 0
            Set-Service -Name $service `
                        -StartupType Manual
            Stop-Service -Name $service `
                         -Force
        }
    }
}

<#
    .SYNOPSIS
    The Test-TargetResource cmdlet is used to validate if the role or feature is in a state as
    expected in the instance document.

    .PARAMETER State
    State of the WMSVC. Accepts only 'Started' and 'Stopped'

    .PARAMETER Ensure
    Whether IIS RemoteManagement is installed or not. Accepts only 'Present' and 'Absent'.
#>
function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([bool])]
    param
    (
        [parameter(Mandatory = $true)]
        [ValidateSet('Started','Stopped')]
        [String] $State,

        [parameter(Mandatory = $true)]
        [ValidateSet('Present','Absent')]
        [String] $Ensure
    )
    
    Assert-Module

    $getState = Get-TargetResource -State $State -Ensure $Ensure

    if ($getState.State -ne $State)
    {
        Write-Verbose -Message ($LocalizedData.VerboseTestTargetState)
        Return $false
    }
    if ($getState.Ensure -ne $Ensure)
    {
        Write-Verbose -Message ($LocalizedData.VerboseTestTargetEnsure)
        Return $false
    }
    Return $true
}

Export-ModuleMember -Function *-TargetResource
