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
    [CmdletBinding()]
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
            Write-Verbose -Message ('Restoring web configuration - attempt {0}' -f $retryCount)

            Restore-WebConfiguration -Name $Name

            Write-Verbose -Message ('Successfully restored web configuration' -f $retryCount)

            $backupRestored = $true
        }
        catch [System.IO.IOException], [System.ComponentModel.Win32Exception]
        {
            # On the fifth try, throw an error.
            if ($retryCount -eq 5)
            {
                throw $_
            }

            Write-Verbose -Message ('Failed to restore web configuration. Retrying in 5 seconds. For reference the error message was "{0}".' -f $_)

            $retryCount += 1

            Start-Sleep -Seconds 5
        }
        catch
        {
            throw $_
        }
    } while (-not $backupRestored)

    # Wait a bit for the restore to free resources.
    Start-Sleep -Seconds 10
}

function Reset-DscLcm
{
    [CmdletBinding()]
    param ()

    Write-Verbose -Message 'Resetting DSC LCM.'

    Stop-DscConfiguration -Force -ErrorAction SilentlyContinue
    Remove-DscConfigurationDocument -Stage Current -Force
    Remove-DscConfigurationDocument -Stage Pending -Force
    Remove-DscConfigurationDocument -Stage Previous -Force
}

Export-ModuleMember -Function `
    Restore-WebConfigurationWrapper, `
    Reset-DscLcm
