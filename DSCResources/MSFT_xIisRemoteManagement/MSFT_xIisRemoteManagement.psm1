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
        VerboseTestTargetCredential                = Authentication not in the desired state.
        VerboseGetTargetResult                     = Get-TargetResource is being run.
        ErrorWebServerStateFailure                 = IIS WebServer is not installed. Please install IIS first.
        ErrorServiceFailure                        = Failed to set state of the {0} service.
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

    Write-Verbose -Message ($LocalizedData.VerboseGetTargetResult)

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

    $credential = (Get-ItemProperty -Path HKLM:\SOFTWARE\Microsoft\WebManagement\Server `
                                    -Name RequiresWindowsCredentials).RequiresWindowsCredentials

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
        State             = $State
        Ensure            = $Ensure
        WindowsCredential = $credential
    }
}

<#
    .SYNOPSIS
        The Set-TargetResource cmdlet is used to configure a IIS RemoteManagement on the
        target machine.

    .PARAMETER State
        State of the WMSVC. Accepts only 'Started' and 'Stopped'

    .PARAMETER Ensure
        Whether IIS RemoteManagement is installed or not. Accepts only 'Present' and 'Absent'.

    .PARAMETER WindowsCredential
        Whether IIS RemoteManagement is enabled for Windows Credentials only or Windows and
        IIS Credentials. Accepts only $true or $false where $true is Windows only and $false is
        Windows and IIS.
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
        [String] $Ensure,

        [Bool] $WindowsCredential
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
            try
            {
                Start-Service -Name $service
            }
            catch
            {
                $errorMessage = $LocalizedData.ErrorServiceFailure -f $service
                New-TerminatingError -ErrorId 'ServiceFailure' `
                                     -ErrorMessage $errorMessage `
                                     -ErrorCategory 'InvalidOperation'
            }
        }
        if ($State -eq 'Stopped')
        {
            Write-Verbose -Message ($LocalizedData.VerboseSetTargetDisablingRemoteManagement)
            Set-ItemProperty -Path HKLM:\SOFTWARE\Microsoft\WebManagement\Server `
                             -Name EnableRemoteManagement -Value 0
            try
            {
                Set-Service -Name $service `
                        -StartupType Manual
                Stop-Service -Name $service `
                         -Force
            }
            catch
            {
                $errorMessage = $LocalizedData.ErrorServiceFailure -f $service
                New-TerminatingError -ErrorId 'ServiceFailure' `
                                     -ErrorMessage $errorMessage `
                                     -ErrorCategory 'InvalidOperation'
            }
        }
    }
    if ($getState.WindowsCredential -ne [system.convert]::ToInt16($WindowsCredential))
    {
        Set-ItemProperty -Path HKLM:\SOFTWARE\Microsoft\WebManagement\Server `
                         -Name RequiresWindowsCredentials `
                         -Value $WindowsCredential
        try
        {
            Restart-Service -Name $service
        }
        catch
        {
            $errorMessage = $LocalizedData.ErrorServiceFailure -f $service
            New-TerminatingError -ErrorId 'ServiceFailure' `
                                    -ErrorMessage $errorMessage `
                                    -ErrorCategory 'InvalidOperation'
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

    .PARAMETER WindowsCredential
        Whether IIS RemoteManagement is enabled for Windows Credentials only or Windows and
        IIS Credentials. Accepts only $true or $false where $true is Windows only and $false is
        Windows and IIS.
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
        [String] $Ensure,

        [Bool] $WindowsCredential
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
    if ($getState.WindowsCredential -ne [system.convert]::ToInt16($WindowsCredential))
    {
        Write-Verbose -Message ($LocalizedData.VerboseTestTargetCredential)
        Return $false
    }
    Return $true
}

Export-ModuleMember -Function *-TargetResource
