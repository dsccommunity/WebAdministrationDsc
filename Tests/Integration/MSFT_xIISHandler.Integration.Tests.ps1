$Global:DSCModuleName      = 'xWebAdministration'
$Global:DSCResourceName    = 'MSFT_xIISHandler'

#region HEADER
if ( (-not (Test-Path -Path '.\DSCResource.Tests\')) -or `
     (-not (Test-Path -Path '.\DSCResource.Tests\TestHelper.psm1')) )
{
    & git @('clone','https://github.com/PowerShell/DscResource.Tests.git')
}
else
{
    & git @('-C',(Join-Path -Path (Get-Location) -ChildPath '\DSCResource.Tests\'),'pull')
}
Import-Module .\DSCResource.Tests\TestHelper.psm1 -Force
$TestEnvironment = Initialize-TestEnvironment `
    -DSCModuleName $Global:DSCModuleName `
    -DSCResourceName $Global:DSCResourceName `
    -TestType Integration
#endregion

# Using try/finally to always cleanup even if something awful happens.
try
{
    #region Integration Tests
    $ConfigFile = Join-Path -Path $PSScriptRoot -ChildPath "$($Global:DSCResourceName).config.ps1"
    . $ConfigFile

    [string]$tempName = "$($Global:DSCResourceName)_" + (Get-Date).ToString("yyyyMMdd_HHmmss")
    $null = Backup-WebConfiguration -Name $tempName

    Describe "$($Global:DSCResourceName)_Integration" {
        #region DEFAULT TESTS
        It 'Should compile without throwing' {
            {
                Invoke-Expression -Command "$($Global:DSCResourceName)_RemoveHandler -OutputPath `$TestEnvironment.WorkingFolder"
                Start-DscConfiguration -Path $TestEnvironment.WorkingFolder -ComputerName localhost -Wait -Verbose -Force
            } | Should not throw
        }

        It 'should be able to call Get-DscConfiguration without throwing' {
            { Get-DscConfiguration -Verbose -ErrorAction Stop } | Should Not throw
        }
        #endregion

        It 'Add a handler' {
            # webDav is normally not there, and even if the WebDav feature is not installed
            # we can add a handler for it.

            {
                # TRACEVerbHandler is usually there, remove it

                Invoke-Expression -Command "$($Global:DSCResourceName)_AddHandler -OutputPath `$TestEnvironment.WorkingFolder"
                Start-DscConfiguration -Path $TestEnvironment.WorkingFolder -ComputerName localhost -Wait -Verbose -Force
            }  | should not throw

            [string]$filter = "system.webServer/handlers/Add[@Name='WebDAV']"
            ((Get-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST' -filter $filter -Name .) | Measure).Count | should be 1
        }

        It 'StaticFile handler' {
            # StaticFile is usually there, have it present shouldn't change anything.
            {
                Invoke-Expression -Command "$($Global:DSCResourceName)_StaticFileHandler -OutputPath `$TestEnvironment.WorkingFolder"
                Start-DscConfiguration -Path $TestEnvironment.WorkingFolder -ComputerName localhost -Wait -Verbose -Force
            }  | should not throw

            [string]$filter = "system.webServer/handlers/Add[@Name='StaticFile']"
            ((Get-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST' -filter $filter -Name .) | Measure).Count | should be 1
        }
    }
    #endregion
}
finally
{
    #region FOOTER
    Restore-WebConfiguration -Name $tempName
    Remove-WebConfigurationBackup -Name $tempName

    Restore-TestEnvironment -TestEnvironment $TestEnvironment
    #endregion
}
