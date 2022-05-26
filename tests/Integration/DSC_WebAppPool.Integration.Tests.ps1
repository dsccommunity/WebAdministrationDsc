#requires -Version 4.0

$script:dscModuleName   = 'WebAdministrationDsc'
$script:dscResourceName = 'DSC_WebAppPool'

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

# Test Setup
if ((Get-Service -Name 'W3SVC').Status -ne 'Running')
{
    Start-Service -Name 'W3SVC'
}

Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\TestHelper\CommonTestHelper.psm1') -Force

$tempName = "$($script:dscResourceName)_$(Get-Date -Format 'yyyyMMdd_HHmmss')"

try
{
    # Create configuration backup

    Backup-WebConfiguration -Name $tempName | Out-Null

    #region Integration Tests

    $ConfigFile = Join-Path -Path $PSScriptRoot -ChildPath "$($script:dscResourceName).config.ps1"
    . $ConfigFile

    Describe "$($script:dscResourceName)_Integration" {
        #region Default Tests
        It 'Should compile the MOF without throwing' {
            {
                & "$($script:DSCResourceName)_Integration" `
                    -OutputPath $TestDrive
            } | Should -Not -Throw
        }

        It 'Should apply the MOF without throwing' {
            {
                Reset-DscLcm

                Start-DscConfiguration `
                    -Path $TestDrive `
                    -ComputerName localhost `
                    -Wait `
                    -Verbose `
                    -Force `
                    -ErrorAction Stop
            } | Should -Not -Throw
        }

        It 'Should be able to call Get-DscConfiguration without throwing' {
            { Get-DscConfiguration -Verbose -ErrorAction Stop } | Should -Not -Throw
        }

        #endregion

        It 'Should have set the resource and all the parameters should match' {

            $currentConfiguration = Get-DscConfiguration

            foreach ($parameter in $TestParameters.GetEnumerator())
            {
                Write-Verbose -Message "The $($parameter.Name) property should be set."

                if ($parameter.Name -eq 'Credential')
                {
                    $appPool = Get-WebConfiguration -Filter '/system.applicationHost/applicationPools/add' |
                        Where-Object -FilterScript {$_.name -eq $TestParameters['Name']}

                    $appPool.processModel.userName |
                    Should Be $TestParameters['Credential'].UserName

                    $appPool.processModel.password |
                    Should Be $TestParameters['Credential'].GetNetworkCredential().Password
                }
                else
                {
                    $currentConfiguration."$($parameter.Name)" |
                    Should Be $TestParameters[$parameter.Name]
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
    Restore-WebConfigurationWrapper -Name $tempName -Verbose

    Remove-WebConfigurationBackup -Name $tempName -Verbose

    Restore-TestEnvironment -TestEnvironment $script:testEnvironment -Verbose
}
