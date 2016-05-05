# Localized messages
data LocalizedData
{
    # culture="en-US"
    ConvertFrom-StringData @'
    ModuleNotFound = Please ensure that the PowerShell module for role {0} is installed.
'@
}

# Internal function to throw terminating error with specified errroCategory, errorId and errorMessage
function New-TerminatingError
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory)]
        [String]$ErrorId,

        [Parameter(Mandatory)]
        [String]$ErrorMessage,

        [Parameter(Mandatory)]
        [System.Management.Automation.ErrorCategory]$ErrorCategory
    )

    $Exception = New-Object System.InvalidOperationException $ErrorMessage
    $ErrorRecord = New-Object System.Management.Automation.ErrorRecord $Exception, $ErrorId, $ErrorCategory, $null
    throw $ErrorRecord
}

# Internal function to assert if the role specific module is installed or not
function Assert-Module
{
    [CmdletBinding()]
    param
    (
        [String]$ModuleName = 'WebAdministration'
    )

    if(-not(Get-Module -Name $ModuleName -ListAvailable))
    {
        $ErrorMsg = $($LocalizedData.ModuleNotFound) -f $ModuleName
        New-TerminatingError -ErrorId 'ModuleNotFound' -ErrorMessage $ErrorMsg -ErrorCategory ObjectNotFound
    }

}
