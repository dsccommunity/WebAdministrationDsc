$script:DSCModuleName      = 'xWebAdministration'
$script:DSCResourceName    = 'MSFT_xWebApplicationHandler'

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

# Using try/finally to always cleanup even if something awful happens.
try
{
    $ConfigFile = Join-Path -Path $PSScriptRoot -ChildPath "$($script:DSCResourceName).config.ps1"
    . $ConfigFile

    Describe "$($script:DSCResourceName)_Integration" {
        $Name = $ConfigurationData.AllNodes.Name
        $filter = "system.webServer/handlers/Add[@Name='$Name']"

        Context 'When using MSFT_xWebApplicationHandler_AddHandler' {
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
                { Get-DscConfiguration -Verbose -ErrorAction Stop } | Should -Not -Throw
            }

            It 'Should be able to call Test-DscConfiguration and return true' {
                $results = Test-DscConfiguration -Verbose -ErrorAction Stop
                $results | Should -Be $true
            }

            It 'Should add a handler' {
                $handler = Get-WebConfigurationProperty -pspath $handler.PSPath -filter $filter -Name .

                $handler.Modules             | Should -Be $ConfigurationData.AllNodes.Modules
                $handler.Name                | Should -Be $ConfigurationData.AllNodes.Name
                $handler.Path                | Should -Be $ConfigurationData.AllNodes.Path
                $handler.Verb                | Should -Be $ConfigurationData.AllNodes.Verb
                $handler.RequireAccess       | Should -Be $ConfigurationData.AllNodes.RequireAccess
                $handler.ScriptProcessor     | Should -Be $ConfigurationData.AllNodes.ScriptProcessor
                $handler.ResourceType        | Should -Be $ConfigurationData.AllNodes.ResourceType
                $handler.AllowPathInfo       | Should -Be $ConfigurationData.AllNodes.AllowPathInfo
                $handler.ResponseBufferLimit | Should -Be $ConfigurationData.AllNodes.ResponseBufferLimit
            }
        }

        Context 'When using MSFT_xWebApplicationHandler_RemoveHandler' {
            It 'Should remove a handler' {

                $configurationParameters = @{
                    OutputPath        = $TestDrive
                    ConfigurationData = $ConfigurationData
                }

                & "$($script:DSCResourceName)_Removehandler" @configurationParameters

                Start-DscConfiguration -Path $TestDrive -ComputerName localhost -Wait -Verbose -Force
                try
                {
                    $handler = Get-WebConfigurationProperty -pspath $handler.PSPath -filter $filter -Name .
                }
                catch
                {
                    $handler = $null
                }

                $handler | Should be $null
            }
        }
    }
}

finally
{
    Restore-TestEnvironment -TestEnvironment $TestEnvironment
}
