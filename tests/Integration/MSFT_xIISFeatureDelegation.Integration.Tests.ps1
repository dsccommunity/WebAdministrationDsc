$script:dscModuleName = 'xWebAdministration'
$script:dscResourceName = 'MSFT_xIISFeatureDelegation'

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

$tempName = "$($script:dscResourceName)_" + (Get-Date).ToString('yyyyMMdd_HHmmss')

try
{
    #region Integration Tests
    $configFile = Join-Path -Path $PSScriptRoot -ChildPath "$($script:dscResourceName).config.ps1"
    . $configFile

    $null = Backup-WebConfiguration -Name $tempName

    Describe "$($script:dscResourceName)_Integration" {
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
            $configurationName = "$($script:dscResourceName)_AllowDelegation"
            #For this test we want the target section to start at effectiveOverrideMode 'Deny'
            If ( $currentOverrideMode -ne 'Deny')
            {
                Set-WebConfiguration -Filter '/system.web/customErrors' -PsPath 'MACHINE/WEBROOT/APPHOST' -Metadata 'overrideMode' -Value 'Deny'
            }

            It 'Should compile and apply the MOF without throwing' {
                {
                    & $configurationName -OutputPath $TestDrive

                    Start-DscConfiguration @startDscConfigurationParameters
                } | Should Not Throw
            }

            It 'Should be set to Allow Feature Delegation'{
                (Get-WebConfiguration -Filter '/system.web/customErrors' -Pspath 'MACHINE/WEBROOT/APPHOST' -Metadata).Metadata.effectiveOverrideMode | Should Be 'Allow'
            }

            It 'Should be able to call Get-DscConfiguration without throwing' {
                { $script:currentConfiguration = Get-DscConfiguration -Verbose -ErrorAction Stop } | Should Not throw
            }

            It 'Should return $true for Test-DscConfiguration' {
                Test-DscConfiguration | Should Be $true
            }

            It 'Should have set the resource and all the parameters should match' {
                $resourceCurrentState = $script:currentConfiguration | Where-Object -FilterScript {
                    $_.ConfigurationName -eq $configurationName
                } | Where-Object -FilterScript {
                    $_.ResourceId -eq '[xIisFeatureDelegation]AllowDelegation'
                }

                $resourceCurrentState.Filter       | Should Be '/system.web/customErrors'
                $resourceCurrentState.OverrideMode | Should Be 'Allow'
                $resourceCurrentState.Path         | Should Be 'MACHINE/WEBROOT/APPHOST'
            }
        }

        Context 'Deny Feature Delegation'{
            $currentOverrideMode = (Get-WebConfiguration -Filter 'system.webServer/defaultDocument' -Pspath 'MACHINE/WEBROOT/APPHOST' -Metadata).Metadata.effectiveOverrideMode
            $configurationName = "$($script:dscResourceName)_DenyDelegation"
            #For this test we want the target section to start at effectiveOverrideMode 'Allow'
            If ( $currentOverrideMode -ne 'Allow')
            {
                Set-WebConfiguration -Filter 'system.webServer/defaultDocument' -PsPath 'MACHINE/WEBROOT/APPHOST' -Metadata 'overrideMode' -Value 'Allow'
            }

            $siteName = (Get-ChildItem -Path iis:\sites | Select-Object -First 1).Name
            $testAddWebConfigurationProperty = @{
                PSPath = "MACHINE/WEBROOT/APPHOST/$siteName"
                Filter = 'system.webServer/defaultDocument/files'
                Name   = '.'
                Value  = 'pesterpage.cgi'
            }

            It 'Should compile and apply the MOF without throwing' {
                {
                    & $configurationName -OutputPath $TestDrive

                    Start-DscConfiguration @startDscConfigurationParameters
                } | Should Not Throw
            }

            It 'Should be able to call Get-DscConfiguration without throwing' {
                { $script:currentConfiguration = Get-DscConfiguration -Verbose -ErrorAction Stop } | Should Not throw
            }

            It 'Should return $true for Test-DscConfiguration' {
                Test-DscConfiguration | Should Be $true
            }

            It 'Should Deny Feature Delegation' {
                { Add-WebConfigurationProperty @testAddWebConfigurationProperty } | Should Throw
            }

            It 'Should have set the resource and all the parameters should match' {
                $resourceCurrentState = $script:currentConfiguration | Where-Object -FilterScript {
                    $_.ConfigurationName -eq $configurationName
                } | Where-Object -FilterScript {
                    $_.ResourceId -eq '[xIisFeatureDelegation]DenyDelegation'
                }

                $resourceCurrentState.Filter       | Should Be '/system.webServer/defaultDocument'
                $resourceCurrentState.OverrideMode | Should Be 'Deny'
                $resourceCurrentState.Path         | Should Be 'MACHINE/WEBROOT/APPHOST'
            }
        }
    #endregion
    }
}
finally
{
    Restore-WebConfigurationWrapper -Name $tempName

    Remove-WebConfigurationBackup -Name $tempName

    Restore-TestEnvironment -TestEnvironment $script:testEnvironment
}
