$script:dscModuleName      = 'xWebAdministration'
$script:dscResourceName    = 'MSFT_WebApplicationHandler'

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

    Describe "$($script:dscResourceName)_AllParameters" {

        #region Test Setup

        New-WebVirtualDirectory -Site 'Default Web Site' -Name $ConfigurationData.AllNodes.VirtualDirectoryName -PhysicalPath $TestDrive

        #endregion

        Context 'When using MSFT_WebApplicationHandler_AddHandler' {

            It 'Should compile and apply the MOF without throwing' {
                {
                    $configurationParameters = @{
                        OutputPath        = $TestDrive
                        ConfigurationData = $ConfigurationData
                    }

                    & "$($script:dscResourceName)_Addhandler" @configurationParameters

                    Start-DscConfiguration -Path $TestDrive -ComputerName localhost -Wait -Verbose -Force
                } | Should -Not -Throw
            }

            It 'Should be able to call Get-DscConfiguration without throwing' {
                {$script:currentConfiguration = Get-DscConfiguration -Verbose -ErrorAction Stop } | Should -Not -Throw
            }

            It 'Should be able to call Test-DscConfiguration and return true' {
                $results = Test-DscConfiguration -Verbose -ErrorAction Stop
                $results | Should -Be $true
            }

            It 'Should have set the resource and all the parameters should match' {
                $resourceCurrentState = $script:currentConfiguration

                $resourceCurrentState.Path                | Should -Be $ConfigurationData.AllNodes.Path
                $resourceCurrentState.Modules             | Should -Be $ConfigurationData.AllNodes.Modules
                $resourceCurrentState.PreCondition        | Should -Be $ConfigurationData.AllNodes.PreCondition
                $resourceCurrentState.Name                | Should -Be $ConfigurationData.AllNodes.Name
                $resourceCurrentState.Type                | Should -Be $ConfigurationData.AllNodes.Type
                $resourceCurrentState.PhysicalHandlerPath | Should -Be $ConfigurationData.AllNodes.PhysicalHandlerPath
                $resourceCurrentState.Verb                | Should -Be $ConfigurationData.AllNodes.Verb
                $resourceCurrentState.RequireAccess       | Should -Be $ConfigurationData.AllNodes.RequireAccess
                $resourceCurrentState.ScriptProcessor     | Should -Be $ConfigurationData.AllNodes.ScriptProcessor
                $resourceCurrentState.ResourceType        | Should -Be $ConfigurationData.AllNodes.ResourceType
                $resourceCurrentState.AllowPathInfo       | Should -Be $ConfigurationData.AllNodes.AllowPathInfo
                $resourceCurrentState.ResponseBufferLimit | Should -Be $ConfigurationData.AllNodes.ResponseBufferLimit
                $resourceCurrentState.Location            | Should -Be "Default Web Site/$($ConfigurationData.AllNodes.VirtualDirectoryName)"
                $resourceCurrentState.Ensure              | Should -Be 'Present'
            }
        }

        Context 'When using MSFT_WebApplicationHandler_RemoveHandler' {
            It 'Should compile and apply the MOF without throwing' {
                {
                    $configurationParameters = @{
                        OutputPath        = $TestDrive
                        ConfigurationData = $ConfigurationData
                    }

                    & "$($script:dscResourceName)_Removehandler" @configurationParameters

                    Start-DscConfiguration -Path $TestDrive -ComputerName localhost -Wait -Verbose -Force
                } | Should -Not -Throw
            }

            It 'Should be able to call Get-DscConfiguration without throwing' {
                {$script:currentConfiguration = Get-DscConfiguration -Verbose -ErrorAction Stop } | Should -Not -Throw
            }

            It 'Should be able to call Test-DscConfiguration and return true' {
                $results = Test-DscConfiguration -Verbose -ErrorAction Stop
                $results | Should -Be $true
            }

            It 'Should remove a handler' {

                $resourceCurrentState = $script:currentConfiguration

                $resourceCurrentState.Ensure              | Should -Be 'Absent'
                $resourceCurrentState.Modules             | Should -BeNullOrEmpty
                $resourceCurrentState.PreCondition        | Should -BeNullOrEmpty
                $resourceCurrentState.Name                | Should -BeNullOrEmpty
                $resourceCurrentState.Type                | Should -BeNullOrEmpty
                $resourceCurrentState.PhysicalHandlerPath | Should -BeNullOrEmpty
                $resourceCurrentState.Verb                | Should -BeNullOrEmpty
                $resourceCurrentState.RequireAccess       | Should -BeNullOrEmpty
                $resourceCurrentState.ScriptProcessor     | Should -BeNullOrEmpty
                $resourceCurrentState.ResourceType        | Should -BeNullOrEmpty
                $resourceCurrentState.AllowPathInfo       | Should -BeNullOrEmpty
                $resourceCurrentState.ResponseBufferLimit | Should -BeNullOrEmpty
                $resourceCurrentState.Location            | Should -Be "Default Web Site/$($ConfigurationData.AllNodes.VirtualDirectoryName)"
                $resourceCurrentState.Path                | Should -Be $ConfigurationData.AllNodes.Path
            }
        }
    }


    Describe "$($script:dscResourceName)_ExcludedOptionalParameters" {

        #region Test Setup

        New-WebVirtualDirectory -Site 'Default Web Site' -Name $ConfigurationData.AllNodes.VirtualDirectoryName -PhysicalPath $TestDrive -Force

        #endregion

        Context 'When using MSFT_WebApplicationHandler_AddHandlerExcludedOptionalParameters' {
            It 'Should compile and apply the MOF without throwing when some optional parameters are excluded' {
                {
                    $configurationParameters = @{
                        OutputPath        = $TestDrive
                        ConfigurationData = $ConfigurationDataExcludedOptionalParameters
                    }

                    & "$($script:dscResourceName)_AddHandlerExcludedOptionalParameters" @configurationParameters

                    Start-DscConfiguration -Path $TestDrive -ComputerName localhost -Wait -Verbose -Force
                } | Should -Not -Throw
            }

            It 'Should be able to call Get-DscConfiguration without throwing' {
                {$script:currentConfiguration = Get-DscConfiguration -Verbose -ErrorAction Stop } | Should -Not -Throw
            }

            It 'Should be able to call Test-DscConfiguration and return true when some optional parameters are excluded' {
                $results = Test-DscConfiguration -Verbose -ErrorAction Stop
                $results | Should -Be $true
            }

            It 'Should have set the resource and all the parameters should match' {
                $resourceCurrentState = $script:currentConfiguration

                $resourceCurrentState.Path                | Should -Be $ConfigurationDataExcludedOptionalParameters.AllNodes.Path
                $resourceCurrentState.Modules             | Should -Be $ConfigurationDataExcludedOptionalParameters.AllNodes.Modules
                $resourceCurrentState.Name                | Should -Be $ConfigurationDataExcludedOptionalParameters.AllNodes.Name
                $resourceCurrentState.Type                | Should -Be $ConfigurationDataExcludedOptionalParameters.AllNodes.Type
                $resourceCurrentState.PhysicalHandlerPath | Should -Be $ConfigurationDataExcludedOptionalParameters.AllNodes.PhysicalHandlerPath
                $resourceCurrentState.Verb                | Should -Be $ConfigurationDataExcludedOptionalParameters.AllNodes.Verb
                $resourceCurrentState.ScriptProcessor     | Should -Be $ConfigurationDataExcludedOptionalParameters.AllNodes.ScriptProcessor
                $resourceCurrentState.Location            | Should -Be "Default Web Site/$($ConfigurationDataExcludedOptionalParameters.AllNodes.VirtualDirectoryName)"
                $resourceCurrentState.Ensure              | Should -Be 'Present'
            }
        }

        Context 'When using MSFT_WebApplicationHandler_RemoveHandlerExcludedOptionalParameters' {
            It 'Should compile and apply the MOF without throwing' {
                {
                    $configurationParameters = @{
                        OutputPath        = $TestDrive
                        ConfigurationData = $ConfigurationDataExcludedOptionalParameters
                    }

                    & "$($script:dscResourceName)_RemoveHandlerExcludedOptionalParameters" @configurationParameters

                    Start-DscConfiguration -Path $TestDrive -ComputerName localhost -Wait -Verbose -Force
                } | Should -Not -Throw
            }

            It 'Should be able to call Get-DscConfiguration without throwing' {
                {$script:currentConfiguration = Get-DscConfiguration -Verbose -ErrorAction Stop } | Should -Not -Throw
            }

            It 'Should be able to call Test-DscConfiguration and return true' {
                $results = Test-DscConfiguration -Verbose -ErrorAction Stop
                $results | Should -Be $true
            }

            It 'Should remove a handler' {

                $resourceCurrentState = $script:currentConfiguration

                $resourceCurrentState.Ensure              | Should -Be 'Absent'
                $resourceCurrentState.Modules             | Should -BeNullOrEmpty
                $resourceCurrentState.Name                | Should -BeNullOrEmpty
                $resourceCurrentState.Type                | Should -BeNullOrEmpty
                $resourceCurrentState.PhysicalHandlerPath | Should -BeNullOrEmpty
                $resourceCurrentState.Verb                | Should -BeNullOrEmpty
                $resourceCurrentState.ScriptProcessor     | Should -BeNullOrEmpty
                $resourceCurrentState.Location            | Should -Be "Default Web Site/$($ConfigurationDataExcludedOptionalParameters.AllNodes.VirtualDirectoryName)"
                $resourceCurrentState.Path                | Should -Be $ConfigurationDataExcludedOptionalParameters.AllNodes.Path
            }
        }
    }
}
finally
{
    Restore-WebConfigurationWrapper -Name $tempName -Verbose

    Remove-WebConfigurationBackup -Name $tempName -Verbose

    Restore-TestEnvironment -TestEnvironment $script:testEnvironment -Verbose
}
