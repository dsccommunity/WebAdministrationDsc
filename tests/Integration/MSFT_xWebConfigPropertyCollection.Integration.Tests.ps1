
$script:dscModuleName = 'xWebAdministration'
$script:dscResourceFriendlyName = 'xWebConfigPropertyCollection'
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
    #region Integration Tests
    $configurationFile = Join-Path -Path $PSScriptRoot -ChildPath "$($script:dscResourceName).config.ps1"
    . $configurationFile

    $null = Backup-WebConfiguration -Name $tempName

    # Constants for Tests
    Describe "$($script:dscResourceName)_Integration" {
        # Create the website we'll use for testing purposes.
        $websiteName = New-Guid
        if (-not(Get-Website -Name $websiteName))
        {
            $websitePhysicalPath = "$($TestDrive)\$($websiteName)"
            New-Item -Path $websitePhysicalPath -ItemType Directory -Force | Out-Null
            New-Website -Name $websiteName -PhysicalPath $websitePhysicalPath | Out-Null
        }

        $configurationData = @{
            AllNodes = @(
                @{
                    NodeName                 = 'localhost'
                    WebsitePath              = "IIS:\Sites\$($websiteName)"
                    Filter                   = '.'
                    CollectionName           = 'appSettings'
                    ItemName                 = 'add'
                    ItemKeyName              = 'key'
                    ItemKeyValue             = $script:dscResourceName
                    ItemPropertyName         = 'value'
                    ItemPropertyValueAdd     = 'ADD'
                    ItemPropertyValueUpdate  = 'UPDATE'
                    IntegerFilter            = 'system.webServer/security/requestFiltering/requestLimits'
                    IntegerCollectionName    = 'headerlimits'
                    IntegerItemKeyName       = 'Header'
                    IntegerItemKeyValue      = 'Content-Type'
                    IntegerItemPropertyName  = 'Sizelimit'
                    IntegerItemPropertyValue = [string](Get-Random -Minimum 11 -Maximum 100)
                }
            )
        }

        $websitePath              = $ConfigurationData.AllNodes.WebsitePath
        $filter                   = $ConfigurationData.AllNodes.Filter
        $collectionName           = $ConfigurationData.AllNodes.CollectionName
        $itemName                 = $ConfigurationData.AllNodes.ItemName
        $itemKeyName              = $ConfigurationData.AllNodes.ItemKeyName
        $itemKeyValue             = $ConfigurationData.AllNodes.ItemKeyValue
        $itemPropertyName         = $ConfigurationData.AllNodes.ItemPropertyName
        $itemPropertyValueAdd     = $ConfigurationData.AllNodes.ItemPropertyValueAdd
        $itemPropertyValueUpdate  = $ConfigurationData.AllNodes.ItemPropertyValueUpdate
        $integerFilter            = $ConfigurationData.AllNodes.IntegerFilter
        $integerCollectionName    = $ConfigurationData.AllNodes.IntegerCollectionName
        $integerItemKeyName       = $ConfigurationData.AllNodes.IntegerItemKeyName
        $integerItemKeyValue      = $ConfigurationData.AllNodes.IntegerItemKeyValue
        $integerItemPropertyName  = $ConfigurationData.AllNodes.IntegerItemPropertyName
        $integerItemPropertyValue = $ConfigurationData.AllNodes.IntegerItemPropertyValue

        $startDscConfigurationParameters = @{
            Path              = $TestDrive
            ComputerName      = 'localhost'
            Wait              = $true
            Verbose           = $true
            Force             = $true
        }

        $filterValue = "$($filter)/$($collectionName)/$($itemName)[@$($itemKeyName)='$($itemKeyValue)']/@$itemPropertyName"
        $integerFilterValue = "$($integerFilter)/$($integerCollectionName)/$($itemName)[@$($integerItemKeyName)='$($integerItemKeyValue)']/@$integerItemPropertyName"

        Context 'When Adding Collection item' {
            It 'Should compile and apply the MOF without throwing' {
                {
                    & "$($script:dscResourceName)_Add" -OutputPath $TestDrive -ConfigurationData $configurationData
                    Start-DscConfiguration @startDscConfigurationParameters
                } | Should -Not -Throw
            }

            It 'Should be able to call Get-DscConfiguration without throwing' {
                { Get-DscConfiguration -Verbose -ErrorAction Stop } | Should -Not -Throw
            }

            It 'Should return $true for Test-DscConfiguration' {
                Test-DscConfiguration | Should Be $true
            }

            It 'Should have the correct value of the configuration property collection item' {
                # Get the new value.
                $value = (Get-WebConfigurationProperty -PSPath $websitePath -Filter $filterValue -Name "." -ErrorAction SilentlyContinue).Value

                $value | Should -Be $itemPropertyValueAdd
            }
        }

        Context 'When Updating Collection item' {
            It 'Should compile and apply the MOF without throwing' {
                {
                    & "$($script:dscResourceName)_Update" -OutputPath $TestDrive -ConfigurationData $configurationData
                    Start-DscConfiguration @startDscConfigurationParameters
                } | Should -Not -Throw
            }

            It 'Should be able to call Get-DscConfiguration without throwing' {
                { Get-DscConfiguration -Verbose -ErrorAction Stop } | Should -Not -Throw
            }

            It 'Should return $true for Test-DscConfiguration' {
                Test-DscConfiguration | Should Be $true
            }

            It 'Should update the configuration property collection item correctly' {
                $value = (Get-WebConfigurationProperty -PSPath $websitePath -Filter $filterValue -Name "." -ErrorAction SilentlyContinue).Value

                $value | Should -Be $itemPropertyValueUpdate
            }
        }

        Context 'When Removing Collection item' {
            It 'Should compile and apply the MOF without throwing' {
                {
                    & "$($script:dscResourceName)_Remove" -OutputPath $TestDrive -ConfigurationData $configurationData
                    Start-DscConfiguration @startDscConfigurationParameters
                } | Should -Not -Throw
            }

            It 'Should be able to call Get-DscConfiguration without throwing' {
                { Get-DscConfiguration -Verbose -ErrorAction Stop } | Should -Not -Throw
            }

            It 'Should return $true for Test-DscConfiguration' {
                Test-DscConfiguration | Should Be $true
            }

            It 'Should remove configuration property' {
                $value = (Get-WebConfigurationProperty -PSPath $websitePath -Filter $filterValue -Name "." -ErrorAction SilentlyContinue).Value

                $value | Should -BeNullOrEmpty
            }
        }

        Context 'When Updating Collection item with integer property value' {
            It 'Should compile and apply the MOF without throwing' {
                {
                    & "$($script:dscResourceName)_Integer" -OutputPath $TestDrive -ConfigurationData $configurationData
                    Start-DscConfiguration @startDscConfigurationParameters
                } | Should -Not -Throw
            }

            It 'Should be able to call Get-DscConfiguration without throwing' {
                { Get-DscConfiguration -Verbose -ErrorAction Stop } | Should -Not -Throw
            }

            It 'Should return $true for Test-DscConfiguration' {
                Test-DscConfiguration | Should Be $true
            }

            It 'Should update the integer property collection item correctly' {
                $integerValue = (Get-WebConfigurationProperty -PSPath $websitePath -Filter $integerFilterValue -Name "." -ErrorAction SilentlyContinue).Value

                $integerValue | Should -Be $integerItemPropertyValue
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
