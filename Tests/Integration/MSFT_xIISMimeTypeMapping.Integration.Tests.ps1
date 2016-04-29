$Global:DSCModuleName      = 'xWebAdministration'
$Global:DSCResourceName    = 'MSFT_xIISMimeTypeMapping'

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
                Invoke-Expression -Command "$($Global:DSCResourceName)_Config -OutputPath `$TestEnvironment.WorkingFolder"
                Start-DscConfiguration -Path $TestEnvironment.WorkingFolder -ComputerName localhost -Wait -Verbose -Force
            } | Should not throw
        }

        It 'should be able to call Get-DscConfiguration without throwing' {
            { Get-DscConfiguration -Verbose -ErrorAction Stop } | Should Not throw
        }
        #endregion

        It 'Adding an existing MimeType' {
            $node = (Get-WebConfigurationProperty -PSPath 'MACHINE/WEBROOT/APPHOST' -Filter "system.webServer/staticContent/mimeMap" -Name .) | Select -First 1

            $env:PesterFileExtension2 = $node.fileExtension
            $env:PesterMimeType2 = $node.mimeType

            {
                Invoke-Expression -Command "$($Global:DSCResourceName)_AddMimeType -OutputPath `$TestEnvironment.WorkingFolder"
                Start-DscConfiguration -Path $TestEnvironment.WorkingFolder -ComputerName localhost -Wait -Verbose -Force
            } | Should not throw

            [string] $filter = "system.webServer/staticContent/mimeMap[@fileExtension='" + $env:PesterFileExtension2 + "' and @mimeType='" + "$env:PesterMimeType2" + "']"
            $expected = ((Get-WebConfigurationProperty  -PSPath 'MACHINE/WEBROOT/APPHOST' -Filter $filter -Name .) | Measure).Count

            $expected | should be 1
        }

        It 'Removing a MimeType' {
            $node = (Get-WebConfigurationProperty  -PSPath 'MACHINE/WEBROOT/APPHOST' -Filter "system.webServer/staticContent/mimeMap" -Name .) | Select -First 1
            $env:PesterFileExtension = $node.fileExtension
            $env:PesterMimeType = $node.mimeType

            {
                Invoke-Expression -Command "$($Global:DSCResourceName)_RemoveMimeType -OutputPath `$TestEnvironment.WorkingFolder"
                Start-DscConfiguration -Path $TestEnvironment.WorkingFolder -ComputerName localhost -Wait -Verbose -Force
            } | Should not throw

            [string] $filter = "system.webServer/staticContent/mimeMap[@fileExtension='" + $env:PesterFileExtension + "' and @mimeType='" + "$env:PesterMimeType" + "']"
            ((Get-WebConfigurationProperty  -PSPath 'MACHINE/WEBROOT/APPHOST' -Filter $filter -Name .) | Measure).Count | should be 0
        }

        It 'Removing a non existing MimeType' {
            {
                Invoke-Expression -Command "$($Global:DSCResourceName)_RemoveDummyMime -OutputPath `$TestEnvironment.WorkingFolder"
                Start-DscConfiguration -Path $TestEnvironment.WorkingFolder -ComputerName localhost -Wait -Verbose -Force
            } | Should not throw
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
