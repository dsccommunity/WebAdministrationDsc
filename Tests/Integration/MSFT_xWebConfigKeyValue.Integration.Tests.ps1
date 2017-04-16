
$script:DSCModuleName      = 'xWebAdministration'
$script:DSCResourceName    = 'MSFT_xWebConfigKeyValue'

#region HEADER
# Integration Test Template Version: 1.1.1
[String] $script:moduleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
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

# Using try/finally to always cleanup.
try
{
    #region Integration Tests
    $configFile = Join-Path -Path $PSScriptRoot -ChildPath "$($script:DSCResourceName).config.ps1"
    . $configFile

    # Constants for Tests
    $env:xWebConfigKeyValuePsPath = 'IIS:\Sites\Default Web Site'
    $env:xWebConfigKeyValueIntegrationKey = 'xWebAdministration Integration Tests Key'

    Describe "$($script:DSCResourceName)_Integration" {
        #region DEFAULT TESTS
        It 'Should compile and apply the MOF without throwing' {
            {
                & "$($script:DSCResourceName)_Config" -OutputPath $TestDrive
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

                Invoke-Expression -Command "$($script:DSCResourceName)_AppSetting_Update -OutputPath `$TestDrive"
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
                Invoke-Expression -Command "$($script:DSCResourceName)_AppSetting_Absent -OutputPath `$TestDrive"
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
    #region FOOTER

    Restore-TestEnvironment -TestEnvironment $TestEnvironment

    #endregion
}

