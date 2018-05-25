$script:DSCModuleName = 'xWebAdministration'
$script:DSCResourceName = 'MSFT_xIISFeatureDelegation'

#region HEADER
# Integration Test Template Version: 1.2.1
[String] $script:moduleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
if ( (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests'))) -or `
    (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1'))) )
{
    & git @('clone', 'https://github.com/PowerShell/DscResource.Tests.git', (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests'))
}

Import-Module -Name (Join-Path -Path $script:moduleRoot -ChildPath (Join-Path -Path 'DSCResource.Tests' -ChildPath 'TestHelper.psm1')) -Force
$TestEnvironment = Initialize-TestEnvironment `
    -DSCModuleName $script:DSCModuleName `
    -DSCResourceName $script:DSCResourceName `
    -TestType Integration

#endregion

[string] $tempName = "$($script:DSCResourceName)_" + (Get-Date).ToString('yyyyMMdd_HHmmss')

try
{
    #region Integration Tests
    $configFile = Join-Path -Path $PSScriptRoot -ChildPath "$($script:DSCResourceName).config.ps1"
    . $configFile

    $null = Backup-WebConfiguration -Name $tempName

    Describe "$($script:DSCResourceName)_Integration" {
        $startDscConfigurationParameters = @{
            Path         = $TestDrive
            ComputerName = 'localhost'
            Wait         = $true
            Verbose      = $true
            Force        = $true
            ErrorAction  = 'Stop'
        }

        Context 'Allow Feature Delegation'{
            $currentOverrideMode = (Get-WebConfiguration -Filter '/system.web/customErrors' -Pspath iis:\ -Metadata).Metadata.effectiveOverrideMode
            #For this test we want the target section to start at effectiveOverrideMode 'Deny'
            If ( $currentOverrideMode -ne 'Deny')
            {
                Set-WebConfiguration -Filter '/system.web/customErrors' -PsPath 'MACHINE/WEBROOT/APPHOST' -Metadata 'overrideMode' -Value 'Deny'
            }

            It 'Should compile and apply the MOF without throwing' {
                {
                    & "$($script:DSCResourceName)_AllowDelegation" -OutputPath $TestDrive

                    Start-DscConfiguration @startDscConfigurationParameters
                } | Should Not Throw
            }

            It 'Should be set to Allow Feature Delegation'{
                (Get-WebConfiguration -Filter '/system.web/customErrors' -Pspath 'MACHINE/WEBROOT/APPHOST' -Metadata).Metadata.effectiveOverrideMode | Should be 'Allow'
            }

            It 'Should be able to call Get-DscConfiguration without throwing' {
                { Get-DscConfiguration -Verbose -ErrorAction Stop } | Should Not throw
            }

            It 'Should return $True for Test-DscConfiguration' {
                Test-DscConfiguration | Should be $True
            }
        }

        Context 'Deny Feature Delegation'{
            $currentOverrideMode = (Get-WebConfiguration -Filter 'system.webServer/defaultDocument' -Pspath 'MACHINE/WEBROOT/APPHOST' -Metadata).Metadata.effectiveOverrideMode
            #For this test we want the target section to start at effectiveOverrideMode 'Allow'
            If ( $currentOverrideMode -ne 'Allow')
            {
                Set-WebConfiguration -Filter 'system.webServer/defaultDocument' -PsPath 'MACHINE/WEBROOT/APPHOST' -Metadata 'overrideMode' -Value 'Allow'
            }

            $siteName = (Get-ChildItem -Path iis:\sites | Select-Object -First 1).Name
            $testValue = @{Value = 'pesterpage.cgi'}
            $testAddWebConfigurationProperty = @{
                PSPath = "MACHINE/WEBROOT/APPHOST/$siteName"
                Filter = 'system.webServer/defaultDocument/files'
                Name = '.'
            }
            $testRemoveWebConfigurationProperty = $testAddWebConfigurationProperty.Clone()
            $testRemoveWebConfigurationProperty.Add('AtElement', $testValue)
            $testAddWebConfigurationProperty.Add('Value', $testValue)

            It 'Should compile and apply the MOF without throwing' {
                {
                    & "$($script:DSCResourceName)_DenyDelegation" -OutputPath $TestDrive

                    Start-DscConfiguration @startDscConfigurationParameters
                } | Should Not Throw
            }

            It 'Should be able to call Get-DscConfiguration without throwing' {
                { Get-DscConfiguration -Verbose -ErrorAction Stop } | Should Not throw
            }

            It 'Should return $True for Test-DscConfiguration' {
                Test-DscConfiguration | Should be $True
            }

            It 'Should Deny Feature Delegation' {
                { Add-WebConfigurationProperty @testAddWebConfigurationProperty } | Should Throw

                { Remove-WebConfigurationProperty @testRemoveWebConfigurationProperty } | Should Throw
            }
        }
    #endregion
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
