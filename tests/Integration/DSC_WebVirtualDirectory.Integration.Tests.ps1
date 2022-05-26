$script:dscModuleName   = 'WebAdministrationDsc'
$script:dscResourceName = 'DSC_WebVirtualDirectory'

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
    $null = Backup-WebConfiguration -Name $tempName

    # Now that WebAdministrationDsc should be discoverable load the configuration data
    $ConfigFile = Join-Path -Path $PSScriptRoot -ChildPath "$($script:dscResourceName).config.ps1"
    . $ConfigFile

    $dscConfig = Import-LocalizedData -BaseDirectory $PSScriptRoot -FileName "$($script:dscResourceName).config.psd1"

    Describe "$($script:dscResourceName)_Initialize" {
        Invoke-Expression -Command "$($script:dscResourceName)_Initialize -ConfigurationData `$DSCConfig -OutputPath `$TestDrive"
        Start-DscConfiguration -Path $TestDrive -ComputerName localhost -Wait -Verbose -Force
    }

    Describe "$($script:dscResourceName)_Present" {
        #region DEFAULT TESTS
        It 'Should compile the MOF without throwing' {
            {
                & "$($script:DSCResourceName)_Present" `
                    -OutputPath $TestDrive `
                    -ConfigurationData $dscConfig `
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

        It 'Should create a WebVirtualDirectory with correct settings' -Test {
            & "$($script:DSCResourceName)_Present" `
            -OutputPath $TestDrive `
            -ConfigurationData $dscConfig

        Reset-DscLcm

        Start-DscConfiguration `
            -Path $TestDrive `
            -ComputerName localhost `
            -Wait `
            -Verbose `
            -Force `
            -ErrorAction Stop

            # Build results to test
            $result = Get-WebVirtualDirectory -Site $DSCConfig.AllNodes.Website `
                -Application $DSCConfig.AllNodes.WebApplication `
                -Name $DSCConfig.AllNodes.WebVirtualDirectory

            # Test virtual directory settings are correct
            $result.path            | Should Be "/$($DSCConfig.AllNodes.WebVirtualDirectory)"
            $result.physicalPath    | Should Be $DSCConfig.AllNodes.PhysicalPath
        }
    }

    Describe "$($script:dscResourceName)_Absent" {
        #region DEFAULT TESTS
        It 'Should compile the MOF without throwing' {
            {
                & "$($script:DSCResourceName)_Absent" `
                    -OutputPath $TestDrive `
                    -ConfigurationData $dscConfig
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

        It 'Should remove the WebVirtualDirectory' -Test {
            & "$($script:DSCResourceName)_Absent" `
                    -OutputPath $TestDrive `
                    -ConfigurationData $dscConfig

            Reset-DscLcm

            Start-DscConfiguration `
                -Path $TestDrive `
                -ComputerName localhost `
                -Wait `
                -Verbose `
                -Force `
                -ErrorAction Stop

            # Build results to test
            $result = Get-WebVirtualDirectory -Site $DSCConfig.AllNodes.Website `
                -Application $DSCConfig.AllNodes.WebApplication `
                -Name $DSCConfig.AllNodes.WebVirtualDirectory

            # Test virtual directory is removed
            $result | Should BeNullOrEmpty
        }
    }

}
finally
{
    Restore-WebConfigurationWrapper -Name $tempName -Verbose

    Remove-WebConfigurationBackup -Name $tempName -Verbose

    if ((Test-Path -Path $DSCConfig.AllNodes.PhysicalPath)) {
        Remove-Item -Path $DSCConfig.AllNodes.PhysicalPath
    }

    if ((Test-Path -Path $DSCConfig.AllNodes.WebApplicationPhysicalPath)) {
        Remove-Item -Path $DSCConfig.AllNodes.WebApplicationPhysicalPath
    }

    Restore-TestEnvironment -TestEnvironment $script:testEnvironment -Verbose
}
