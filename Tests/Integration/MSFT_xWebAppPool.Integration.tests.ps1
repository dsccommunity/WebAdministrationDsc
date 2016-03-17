$Global:DSCModuleName   = 'xWebAdministration'
$Global:DSCResourceName = 'MSFT_xWebAppPool'

#region HEADER
[String] $moduleRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $Script:MyInvocation.MyCommand.Path))
if ( (-not (Test-Path -Path (Join-Path -Path $moduleRoot -ChildPath 'DSCResource.Tests'))) -or `
     (-not (Test-Path -Path (Join-Path -Path $moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1'))) )
{
    & git @('clone','https://github.com/PowerShell/DscResource.Tests.git',(Join-Path -Path $moduleRoot -ChildPath '\DSCResource.Tests\'))
}
else
{
    & git @('-C',(Join-Path -Path $moduleRoot -ChildPath '\DSCResource.Tests\'),'pull')
}
Import-Module (Join-Path -Path $moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1') -Force
$TestEnvironment = Initialize-TestEnvironment `
    -DSCModuleName $Global:DSCModuleName `
    -DSCResourceName $Global:DSCResourceName `
    -TestType Integration
#endregion

# Test Setup
if ((Get-Service -Name 'W3SVC').Status -ne 'Running')
{
    Start-Service -Name 'W3SVC'
}

try
{
    # Create configuration backup
    $tempBackupName = "$($Global:DSCResourceName)_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
    Backup-WebConfiguration -Name $tempBackupName | Out-Null

    #region Integration Tests

    $ConfigFile = Join-Path -Path $PSScriptRoot -ChildPath "$($Global:DSCResourceName).config.ps1"
    . $ConfigFile

    Describe "$($Global:DSCResourceName)_Integration" {

        #region Default Tests

        It 'Should be able to compile and apply without throwing' {
            {
                Invoke-Expression -Command ('{0}_Config -OutputPath $TestEnvironment.WorkingFolder -ConfigurationData $ConfigData -ErrorAction Stop' -f $Global:DSCResourceName)
                Start-DscConfiguration -Path $TestEnvironment.WorkingFolder -ComputerName 'localhost' -Force -Wait -Verbose
            } | Should Not Throw
        }

        It 'Should be able to call Get-DscConfiguration without throwing' {
            {
                Get-DscConfiguration -Verbose -ErrorAction Stop
            } | Should Not Throw
        }

        #endregion

        It 'Should have set the resource and all the parameters should match' {

            $Current = Get-DscConfiguration

            foreach ($Parameter in $TestParameters.GetEnumerator())
            {
                Write-Verbose -Message "The $($Parameter.Name) property should be set."

                if ($Parameter.Name -eq 'Credential')
                {
                    $AppPool = Get-WebConfiguration -Filter '/system.applicationHost/applicationPools/add' |
                        Where-Object -FilterScript {$_.name -eq $TestParameters['Name']}

                    $AppPool.processModel.userName | Should Be $TestParameters['Credential'].UserName
                    $AppPool.processModel.password | Should Be $TestParameters['Credential'].GetNetworkCredential().Password
                }
                else
                {
                    $Current."$($Parameter.Name)" | Should Be $TestParameters[$Parameter.Name]
                }
            }

        }

        It 'Actual configuration should match the desired configuration' {
            Test-DscConfiguration -Verbose | Should Be $true
        }

    }

    #endregion
}
finally
{
    #region FOOTER
    Restore-WebConfiguration -Name $tempBackupName
    Remove-WebConfigurationBackup -Name $tempBackupName

    Restore-TestEnvironment -TestEnvironment $TestEnvironment
    #endregion
}
