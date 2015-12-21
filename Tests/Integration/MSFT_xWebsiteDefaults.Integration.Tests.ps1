$Global:DSCModuleName = 'xWebAdministration'
$Global:DSCResourceName = 'MSFT_xWebsiteDefaults'

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


try {
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

        It 'Changing Default virtualDirectoryDefaults' -test {
            function GetSiteValue([string]$path,[string]$name)
            {
                return (Get-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST' -filter "system.applicationHost/sites/$path" -name $name).value
            }

            # get the current value

            [string] $originalValue = (Get-WebConfigurationProperty `
                -PSPath 'MACHINE/WEBROOT/APPHOST' `
                -Filter 'system.applicationHost/sites/virtualDirectoryDefaults' `
                -Name 'allowSubDirConfig').Value

            Invoke-Expression -Command "$($Global:DSCResourceName)_Config -OutputPath `$TestEnvironment.WorkingFolder"
            Start-DscConfiguration -Path $TestEnvironment.WorkingFolder -ComputerName localhost -Wait -Verbose -Force

            $changedValue = (Get-WebConfigurationProperty -PSPath 'MACHINE/WEBROOT/APPHOST' -filter "system.applicationHost/sites/virtualDirectoryDefaults" -name 'allowSubDirConfig').Value
            $changedValue | should be $env:PesterVirtualDirectoryDefaults
        }
    }
}
finally
{
    #region FOOTER
    Restore-WebConfiguration -Name $tempName
    Remove-WebConfigurationBackup -Name $tempName

    Restore-TestEnvironment -TestEnvironment $TestEnvironment
    #endregion
}
