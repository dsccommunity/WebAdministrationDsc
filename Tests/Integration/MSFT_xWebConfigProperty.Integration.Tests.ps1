$script:dscModuleName = 'xWebAdministration'
$script:dscResourceFriendlyName = 'xWebConfigProperty'
$script:dscResourceName = "MSFT_$($script:dscResourceFriendlyName)"

#region HEADER
# Integration Test Template Version: 1.3.0
[String] $script:moduleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
if ( (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests'))) -or `
    (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1'))) )
{
    & git @('clone', 'https://github.com/PowerShell/DscResource.Tests.git', (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests'))
}

Import-Module -Name (Join-Path -Path $script:moduleRoot -ChildPath (Join-Path -Path 'DSCResource.Tests' -ChildPath 'TestHelper.psm1')) -Force
# Ensure the WebAdministration module is imported into the current session!
Import-Module WebAdministration -Force
$TestEnvironment = Initialize-TestEnvironment `
    -DSCModuleName $script:dscModuleName `
    -DSCResourceName $script:dscResourceName `
    -TestType Integration
#endregion

[string] $tempName = "$($script:dscResourceName)_" + (Get-Date).ToString('yyyyMMdd_HHmmss')

# Using try/finally to always cleanup.
try
{
    $configurationFile = Join-Path -Path $PSScriptRoot -ChildPath "$($script:dscResourceName).config.ps1"
    . $configurationFile

    $null = Backup-WebConfiguration -Name $tempName

    #region Integration Tests
    Describe "$($script:dscResourceName)_Integration" {
        # Create the website we'll use for testing purposes.
        $websiteName = New-Guid
        if (-not(Get-Website -Name $websiteName))
        {
            $websitePhysicalPath = "$($TestDrive)\$($websiteName)"
            New-Item -Path $websitePhysicalPath -ItemType Directory -Force | Out-Null
            New-Website -Name $websiteName -PhysicalPath $websitePhysicalPath | Out-Null
        }

        $ConfigurationData = @{
            AllNodes = @(
                @{
                    NodeName             = 'localhost'
                    WebsitePath          = "IIS:\Sites\$($websiteName)"
                    Filter               = 'system.webServer/directoryBrowse'
                    PropertyName         = 'enabled'
                    AddValue             = $true
                    UpdateValue          = $false
                    IntegerFilter        = '/SYSTEM.WEB/TRACE'
                    IntergerPropertyName = 'requestLimit'
                    IntegerValue         = [string](Get-Random -Minimum 11 -Maximum 1000)
                }
            )
        }

        $startDscConfigurationParameters = @{
            Path              = $TestDrive
            ComputerName      = 'localhost'
            Wait              = $true
            Verbose           = $true
            Force             = $true
        }

        $websitePath          = $ConfigurationData.AllNodes.WebsitePath
        $filter               = $ConfigurationData.AllNodes.Filter
        $propertyName         = $ConfigurationData.AllNodes.PropertyName
        $addValue             = $ConfigurationData.AllNodes.AddValue
        $updateValue          = $ConfigurationData.AllNodes.UpdateValue
        $integerFilter        = $ConfigurationData.AllNodes.IntegerFilter
        $intergerPropertyName = $ConfigurationData.AllNodes.IntergerPropertyName
        $integerValue         = $ConfigurationData.AllNodes.IntegerValue

        Context 'When Adding Property' {
            It 'Should compile and apply the MOF without throwing' {
                {
                    & "$($script:dscResourceName)_Add" -OutputPath $TestDrive -ConfigurationData $ConfigurationData
                    Start-DscConfiguration @startDscConfigurationParameters
                } | Should -Not -Throw
            }

            It 'Should be able to call Get-DscConfiguration without throwing' {
                { Get-DscConfiguration -Verbose -ErrorAction Stop } | Should -Not -Throw
            }

            It 'Should return $true for Test-DscConfiguration' {
                Test-DscConfiguration | Should Be $true
            }

            It 'Should have the correct value of the configuration property' {
                $value = (Get-WebConfigurationProperty -PSPath $websitePath -Filter $filter -Name $propertyName).Value

                $value | Should -Be $addValue
            }
        }

        Context 'When Updating a Property' {
            It 'Should compile and apply the MOF without throwing' {
                {
                    & "$($script:dscResourceName)_Update" -OutputPath $TestDrive -ConfigurationData $ConfigurationData
                    Start-DscConfiguration @startDscConfigurationParameters
                } | Should -Not -Throw
            }

            It 'Should update the configuration property correctly' {
                $value = (Get-WebConfigurationProperty -PSPath $websitePath -Filter $filter -Name $propertyName).Value

                $value | Should -Be $updateValue
            }

            It 'Should be able to call Get-DscConfiguration without throwing' {
                { Get-DscConfiguration -Verbose -ErrorAction Stop } | Should -Not -Throw
            }

            It 'Should return $true for Test-DscConfiguration' {
                Test-DscConfiguration | Should Be $true
            }
        }

        Context 'When Removing a Property' {
            It 'Should compile and apply the MOF without throwing' {
                {
                    & "$($script:dscResourceName)_Remove" -OutputPath $TestDrive -ConfigurationData $ConfigurationData
                    Start-DscConfiguration @startDscConfigurationParameters
                } | Should -Not -Throw
            }

            It 'Should remove configuration property' {
                # Get the value.
                # Because configuration properties can be inherited (& I'm not aware of a reliable way to determine if the value returned is inherited or set explicitly),
                # we instead read the config file as XML directly & attempt to locate the property under test.

                $value = ([xml] ((Get-WebConfigFile -PSPath $websitePath) | Get-Content)).SelectSingleNode("//$($filter)/@$($propertyName)")
                $value | Should -Be $null
            }

            It 'Should be able to call Get-DscConfiguration without throwing' {
                { Get-DscConfiguration -Verbose -ErrorAction Stop } | Should -Not -Throw
            }

            It 'Should return $true for Test-DscConfiguration' {
                Test-DscConfiguration | Should Be $true
            }
        }

        Context 'When Updating a Integer Property' {
            It 'Should compile and apply the MOF without throwing' {
                {
                    & "$($script:dscResourceName)_Integer" -OutputPath $TestDrive -ConfigurationData $ConfigurationData
                    Start-DscConfiguration @startDscConfigurationParameters
                } | Should -Not -Throw
            }

            It 'Should be able to call Get-DscConfiguration without throwing' {
                { Get-DscConfiguration -Verbose -ErrorAction Stop } | Should -Not -Throw
            }

            It 'Should update the configuration integer property correctly' {
                [string] $value = (Get-WebConfigurationProperty -PSPath $websitePath -Filter $integerFilter -Name $intergerPropertyName).Value

                $value | Should -Be $integerValue
            }

            It 'Should return $true for Test-DscConfiguration' {
                Test-DscConfiguration | Should Be $true
            }
        }

        # Remove the website we created for testing purposes.
        if (Get-Website -Name $websiteName)
        {
            Remove-Website -Name $websiteName
            Remove-Item -Path $websitePhysicalPath -Force -Recurse
        }
    }
    #endregion
}
finally
{
    #region FOOTER
    Restore-TestEnvironment -TestEnvironment $TestEnvironment

    # Addresses Issue #385: xWebConfigPropertyCollection: Timing issue in integration tests
    Start-Sleep -Seconds 4

    Restore-WebConfiguration -Name $tempName
    Remove-WebConfigurationBackup -Name $tempName
    #endregion
}
