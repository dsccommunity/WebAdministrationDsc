
$script:dscModuleName   = 'xWebAdministration'
$script:dscResourceName = 'MSFT_xWebConfigKeyValue'

try
{
    Import-Module -Name DscResource.Test -Force
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
    #region Integration Tests
    $configFile = Join-Path -Path $PSScriptRoot -ChildPath "$($script:dscResourceName).config.ps1"
    . $configFile

    $null = Backup-WebConfiguration -Name $tempName

    # Constants for Tests
    $env:xWebConfigKeyValuePsPath = 'IIS:\Sites\Default Web Site'
    $env:xWebConfigKeyValueIntegrationKey = 'xWebAdministration Integration Tests Key'

    Describe "$($script:dscResourceName)_Integration" {
        #region DEFAULT TESTS
        It 'Should compile and apply the MOF without throwing' {
            {
                & "$($script:dscResourceName)_Config" -OutputPath $TestDrive
                Start-DscConfiguration -Path $TestDrive `
                    -ComputerName localhost -Wait -Verbose -Force
            } | Should not throw
        }

        It 'Should be able to call Get-DscConfiguration without throwing' {
            { Get-DscConfiguration -Verbose -ErrorAction Stop } | Should Not throw
        }
        #endregion

        It 'Should update AppSetting "xWebAdministration Integration Tests Key"' {
            {
                # Get the current value
                [string] $originalValue = (Get-WebConfigurationProperty `
                    -PSPath $env:xWebConfigKeyValuePsPath `
                    -Filter "appSettings/add[@key='$($env:xWebConfigKeyValueIntegrationKey)']" `
                    -Name 'value').Value

                $env:xWebConfigKeyValueIntegrationValueUpdated = $originalValue + "-updated"

                Invoke-Expression -Command "$($script:dscResourceName)_AppSetting_Update -OutputPath `$TestDrive"
                Start-DscConfiguration -Path $TestDrive -ComputerName localhost -Wait -Verbose -Force
            } | Should Not throw

            # Compare the updated value
            [string] $changedValue = (Get-WebConfigurationProperty `
                -PSPath $env:xWebConfigKeyValuePsPath `
                -Filter "appSettings/add[@key='$($env:xWebConfigKeyValueIntegrationKey)']" `
                -Name 'value').Value
            $changedValue | Should Be $env:xWebConfigKeyValueIntegrationValueUpdated
        }

        It 'Should remove AppSetting "xWebAdministration Integration Tests Key"' {
            {
                Invoke-Expression -Command "$($script:dscResourceName)_AppSetting_Absent -OutputPath `$TestDrive"
                Start-DscConfiguration -Path $TestDrive -ComputerName localhost -Wait -Verbose -Force
            } | Should Not throw

            [string] $appSetting = (Get-WebConfigurationProperty `
                -PSPath $env:xWebConfigKeyValuePsPath `
                -Filter "appSettings/add[@key='$($env:xWebConfigKeyValueIntegrationKey)']" `
                -Name 'value')
            $appSetting | Should BeNullOrEmpty
        }
    }
    #endregion

}
finally
{
    Restore-WebConfigurationWrapper -Name $tempName

    Remove-WebConfigurationBackup -Name $tempName

    Restore-TestEnvironment -TestEnvironment $script:testEnvironment
}

