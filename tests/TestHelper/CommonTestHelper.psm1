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

<#
    .SYNOPSIS
        Wrapper for Restore-WebConfiguration to be able to retry on errors.

    .PARAMETER Name
        The name of the backup to restore.

    .NOTES
        - This wrapper is a workaround for the error:

        IOException: The process cannot access the file
        'C:\windows\system32\inetsrv\mbschema.xml' because
        it is being used by another process.

        - Addresses Issue #385: xWebConfigPropertyCollection: Timing issue in integration tests

        IOException: The process cannot access the file
        'C:\windows\system32\inetsrv\config\applicationHost.config'
        because it is being used by another process.
#>
function Restore-WebConfigurationWrapper
{
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Name
    )

    $retryCount = 1
    $backupRestored = $false

    do
    {
        try
        {
            Write-Verbose -Message ('Restoring web configuration - attempt {0}' -f $retryCount) -Verbose

            Restore-WebConfiguration -Name $Name

            Write-Verbose -Message ('Successfully restored web configuration' -f $retryCount) -Verbose

            $backupRestored = $true
        }
        catch [System.IO.IOException]
        {
            # On the fifth try, throw an error.
            if ($retryCount -eq 5)
            {
                throw $_
            }

            Write-Verbose -Message ('Failed to restore web configuration. Retrying in 5 seconds. For reference the error message was "{0}".' -f $_) -Verbose

            $retryCount += 1

            Start-Sleep -Seconds 5
        }
        catch
        {
            throw $_
        }
    } while (-not $backupRestored)
}

Export-ModuleMember -Function @(
    'Install-NewSelfSignedCertificateExScript'
    'Restore-WebConfigurationWrapper'
)
