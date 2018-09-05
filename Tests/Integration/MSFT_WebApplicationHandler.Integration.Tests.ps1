$script:DSCModuleName      = 'xWebAdministration'
$script:DSCResourceName    = 'MSFT_WebApplicationHandler'

$script:moduleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)

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

[string]$tempName = "$($script:DSCResourceName)_" + (Get-Date).ToString("yyyyMMdd_HHmmss")

# Using try/finally to always cleanup even if something awful happens.
try
{
    $null = Backup-WebConfiguration -Name $tempName

    $ConfigFile = Join-Path -Path $PSScriptRoot -ChildPath "$($script:DSCResourceName).config.ps1"
    . $ConfigFile

    Describe "$($script:DSCResourceName)_Integration" {

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

                    & "$($script:DSCResourceName)_Addhandler" @configurationParameters

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

                    & "$($script:DSCResourceName)_Removehandler" @configurationParameters

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
}

finally
{
    #region FOOTER

    Restore-WebConfiguration -Name $tempName
    Remove-WebConfigurationBackup -Name $tempName

    Restore-TestEnvironment -TestEnvironment $TestEnvironment

    #endregion
}
