
$script:dscModuleName = 'xWebAdministration'
$script:dscResourceName = 'MSFT_xWebSiteDefaults'

try
{
    Import-Module -Name DscResource.Test -Force -ErrorAction 'Stop'
}
catch [System.IO.FileNotFoundException]
{
    throw 'DscResource.Test module dependency not found. Please run ".\build.ps1 -Tasks build" first.'
}

$script:testEnvironment = Initialize-TestEnvironment `
    -DSCModuleName $script:dscModuleName `
    -DSCResourceName $script:dscResourceName `
    -ResourceType 'Mof' `
    -TestType 'Integration'

Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\TestHelper\CommonTestHelper.psm1') -Force

$tempName = "$($script:dscResourceName)_" + (Get-Date).ToString("yyyyMMdd_HHmmss")

try
{
    $null = Backup-WebConfiguration -Name $tempName

    $ConfigFile = Join-Path -Path $PSScriptRoot -ChildPath "$($script:dscResourceName).config.ps1"
    . $ConfigFile

    Describe "$($script:dscResourceName)_Integration" {
        #region DEFAULT TESTS
        It 'Should compile without throwing' {
            {
                Invoke-Expression -Command "$($script:dscResourceName)_Config -OutputPath `$TestDrive"
                Start-DscConfiguration -Path $TestDrive -ComputerName localhost -Wait -Verbose -Force
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

            Invoke-Expression -Command "$($script:dscResourceName)_Config -OutputPath `$TestDrive"
            Start-DscConfiguration -Path $TestDrive -ComputerName localhost -Wait -Verbose -Force

            $changedValue = (Get-WebConfigurationProperty -PSPath 'MACHINE/WEBROOT/APPHOST' -filter 'system.applicationHost/sites/virtualDirectoryDefaults' -name 'allowSubDirConfig').Value
            $changedValue | should be $env:PesterVirtualDirectoryDefaults
        }
    }
}
finally
{
    Restore-WebConfigurationWrapper -Name $tempName -Verbose

    Remove-WebConfigurationBackup -Name $tempName -Verbose

    Restore-TestEnvironment -TestEnvironment $script:testEnvironment -Verbose
}
