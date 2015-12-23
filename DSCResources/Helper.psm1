# Localized messages
data LocalizedData
{
    # culture="en-US"
    ConvertFrom-StringData @'
    RoleNotFound    =   Please ensure that the PowerShell module for role {0} is installed
'@
}

# Internal function to throw terminating error with specified errroCategory, errorId and errorMessage
function New-TerminatingError
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory)]
        [String] $ErrorId,

        [Parameter(Mandatory)]
        [String] $ErrorMessage,

        [Parameter(Mandatory)]
        [System.Management.Automation.ErrorCategory] $ErrorCategory
    )

    $exception = New-Object System.InvalidOperationException $errorMessage
    $errorRecord = New-Object System.Management.Automation.ErrorRecord $exception, $errorId, $errorCategory, $null
    throw $errorRecord
}

# Internal function to assert if the role specific module is installed or not
function Assert-Module
{
    [CmdletBinding()]
    param
    (
        [String] $moduleName = 'WebAdministration'
    )

    if(-not (Get-Module -Name $moduleName -ListAvailable))
    {
        $errorMsg = $($LocalizedData.RoleNotFound) -f $moduleName
        New-TerminatingError -ErrorId 'ModuleNotFound' -ErrorMessage $errorMsg -ErrorCategory ObjectNotFound
    }
}
