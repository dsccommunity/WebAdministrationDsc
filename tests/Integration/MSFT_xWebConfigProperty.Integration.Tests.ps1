$script:dscModuleName = 'xWebAdministration'
$script:dscResourceName = "MSFT_xWebConfigProperty"

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

$tempName = "$($script:dscResourceName)_" + (Get-Date).ToString('yyyyMMdd_HHmmss')

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
            Write-Verbose -Message ('Removing website that was used for testing' -f $retryCount) -Verbose
            Remove-Website -Name $websiteName
            Remove-Item -Path $websitePhysicalPath -Force -Recurse
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
