<#
    .SYNOPSIS
        Returns an invalid argument exception object

    .PARAMETER Message
        The message explaining why this error is being thrown

    .PARAMETER ArgumentName
        The name of the invalid argument that is causing this error to be thrown
#>
function Get-InvalidArgumentRecord
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $Message,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $ArgumentName
    )

    $argumentException = New-Object -TypeName 'ArgumentException' -ArgumentList @( $Message,
        $ArgumentName )
    $newObjectParams = @{
        TypeName = 'System.Management.Automation.ErrorRecord'
        ArgumentList = @( $argumentException, $ArgumentName, 'InvalidArgument', $null )
    }
    return New-Object @newObjectParams
}

<#
    .SYNOPSIS
        Returns an invalid operation exception object

    .PARAMETER Message
        The message explaining why this error is being thrown

    .PARAMETER ErrorRecord
        The error record containing the exception that is causing this terminating error
#>
function Get-InvalidOperationRecord
{
    [CmdletBinding()]
    param
    (
        [ValidateNotNullOrEmpty()]
        [String]
        $Message,

        [ValidateNotNull()]
        [System.Management.Automation.ErrorRecord]
        $ErrorRecord
    )

    if ($null -eq $Message)
    {
        $invalidOperationException = New-Object -TypeName 'InvalidOperationException'
    }
    elseif ($null -eq $ErrorRecord)
    {
        $invalidOperationException =
        New-Object -TypeName 'InvalidOperationException' -ArgumentList @( $Message )
    }
    else
    {
        $invalidOperationException =
        New-Object -TypeName 'InvalidOperationException' -ArgumentList @( $Message,
            $ErrorRecord.Exception )
    }

    $newObjectParams = @{
        TypeName = 'System.Management.Automation.ErrorRecord'
        ArgumentList = @( $invalidOperationException.ToString(), 'MachineStateIncorrect',
            'InvalidOperation', $null )
    }
    return New-Object @newObjectParams
}

<#
    .SYNOPSIS
    Some tests require a self-signed certificate to be created. However, the
    New-SelfSignedCertificate cmdlet built into Windows Server 2012 R2 is too
    limited to work for this process.

    Therefore an alternate method of creating self-signed certificates to meet the
    reqirements. A script on Microsoft Script Center can be used for this but must
    be downloaded:
    https://gallery.technet.microsoft.com/scriptcenter/Self-signed-certificate-5920a7c6

    This cmdlet will install the script if it is not available and dot source it.

    .PARAMETER OutputPath
    The path to download the script to. If not provided will default to the current
    users temp folder.

    .OUTPUTS
    The path to the script that was downloaded.
#>
function Install-NewSelfSignedCertificateExScript
{
    [CmdletBinding()]
    [OutputType([String])]
    param
    (
        [Parameter()]
        [String]
        $OutputPath = $env:Temp
    )

    $newSelfSignedCertURL = 'https://gallery.technet.microsoft.com/scriptcenter/Self-signed-certificate-5920a7c6/file/101251/2/New-SelfSignedCertificateEx.zip'
    $newSelfSignedCertZip = Split-Path -Path $newSelfSignedCertURL -Leaf
    $newSelfSignedCertZipPath = Join-Path -Path $OutputPath -ChildPath $newSelfSignedCertZip
    $newSelfSignedCertScriptPath = Join-Path -Path $OutputPath -ChildPath 'New-SelfSignedCertificateEx.ps1'
    if (-not (Test-Path -Path $newSelfSignedCertScriptPath))
    {
        if (Test-Path -Path $newSelfSignedCertZip)
        {
            Remove-Item -Path $newSelfSignedCertZipPath -Force
        }
        Invoke-WebRequest -Uri $newSelfSignedCertURL -OutFile $newSelfSignedCertZipPath
        Add-Type -AssemblyName System.IO.Compression.FileSystem
        [System.IO.Compression.ZipFile]::ExtractToDirectory($newSelfSignedCertZipPath, $OutputPath)
    } # if
    return $newSelfSignedCertScriptPath
} # end function Install-NewSelfSignedCertificateExScript

Export-ModuleMember -Function `
    Install-NewSelfSignedCertificateExScript, `
    Get-InvalidArgumentRecord, `
    Get-InvalidOperationRecord
