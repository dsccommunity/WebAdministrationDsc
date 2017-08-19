
$script:DSCModuleName      = 'xWebAdministration'
$script:DSCResourceName    = 'MSFT_xIISMimeTypeMapping'

#region HEADER
$script:moduleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
if ( (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests'))) -or `
     (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1'))) )
{
    & git @('clone','https://github.com/PowerShell/DscResource.Tests.git',(Join-Path -Path $script:moduleRoot -ChildPath '\DSCResource.Tests\'))
}

Import-Module (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1') -Force
$TestEnvironment = Initialize-TestEnvironment `
    -DSCModuleName $script:DSCModuleName `
    -DSCResourceName $script:DSCResourceName `
    -TestType Integration
#endregion

[string]$tempName = "$($script:DSCResourceName)_" + (Get-Date).ToString("yyyyMMdd_HHmmss")

# Using try/finally to always cleanup even if something awful happens.
try
{
    #region Integration Tests

    $null = Backup-WebConfiguration -Name $tempName

    $ConfigFile = Join-Path -Path $PSScriptRoot -ChildPath "$($script:DSCResourceName).config.ps1"
    . $ConfigFile

    Describe "$($script:DSCResourceName)_Integration" {
        #region DEFAULT TESTS
        It 'Should compile without throwing' {
            {
                & "$($script:DSCResourceName)_Config" -OutputPath $TestDrive
                Start-DscConfiguration -Path $TestDrive -ComputerName localhost -Wait -Verbose -Force
            } | Should not throw
        }

        It 'should be able to call Get-DscConfiguration without throwing' {
            { Get-DscConfiguration -Verbose -ErrorAction Stop } | Should Not throw
        }
        #endregion

        It 'Adding an existing MimeType' {
            $node = (Get-WebConfiguration -PSPath 'MACHINE/WEBROOT/APPHOST' -Filter "system.webServer/staticContent/mimeMap") | Select-Object -First 1

            $configData = @{
                AllNodes = @();
                NonNodeData =
                @{
                    PesterFileExtension2 = $node.fileExtension
                    PesterMimeType2      = $node.mimeType
                }
            }

            {
                & "$($script:DSCResourceName)_AddMimeType" -OutputPath $TestDrive -ConfigurationData $configData
                Start-DscConfiguration -Path $TestDrive -ComputerName localhost -Wait -Verbose -Force
            } | Should not throw

            $filter = "system.webServer/staticContent/mimeMap[@fileExtension='{0}' and @mimeType='{1}']" -f `
                $configData.NonNodeData.PesterFileExtension2, $configData.NonNodeData.PesterMimeType2
            $expected = ((Get-WebConfiguration  -PSPath 'MACHINE/WEBROOT/APPHOST' -Filter $filter) | Measure-Object).Count

            $expected | should be 1
        }

        It 'Removing a MimeType' {
            $node = (Get-WebConfiguration  -PSPath 'MACHINE/WEBROOT/APPHOST' -Filter "system.webServer/staticContent/mimeMap") | Select-Object -First 1
            
            $configData = @{
                AllNodes = @();
                NonNodeData =
                @{
                    PesterFileExtension = $node.fileExtension
                    PesterMimeType      = $node.mimeType
                }
            }

            {
                & "$($script:DSCResourceName)_RemoveMimeType" -OutputPath $TestDrive -ConfigurationData $configData
                Start-DscConfiguration -Path $TestDrive -ComputerName localhost -Wait -Verbose -Force
            } | Should not throw

            $filter = "system.webServer/staticContent/mimeMap[@fileExtension='{0}' and @mimeType='{1}']" -f `
                $configData.NonNodeData.PesterFileExtension, $configData.NonNodeData.PesterMimeType
            ((Get-WebConfiguration -PSPath 'MACHINE/WEBROOT/APPHOST' -Filter $filter) | Measure-Object).Count | should be 0
        }

        It 'Removing a non existing MimeType' {
            {
                & "$($script:DSCResourceName)_RemoveDummyMime" -OutputPath $TestDrive
                Start-DscConfiguration -Path $TestDrive -ComputerName localhost -Wait -Verbose -Force
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
