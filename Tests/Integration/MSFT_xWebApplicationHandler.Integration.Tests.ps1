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
                } | should -Not throw
            }

            It 'Should be able to call Get-DscConfiguration without throwing' {
                { Get-DscConfiguration -Verbose -ErrorAction Stop } | should -Not throw
            }

            It 'Should be able to call Test-DscConfiguration and return true' {
                $results = Test-DscConfiguration -Verbose -ErrorAction Stop
                $results | Should -Be $true
            }

            It 'Should add a handler' {
                $handler = Get-WebConfigurationProperty -pspath $handler.PSPath -filter $filter -Name .

                $handler.Modules             | should -Be $ConfigurationData.AllNodes.Modules
                $handler.Name                | should -Be $ConfigurationData.AllNodes.Name
                $handler.Path                | should -Be $ConfigurationData.AllNodes.Path
                $handler.Verb                | should -Be $ConfigurationData.AllNodes.Verb
                $handler.RequireAccess       | should -Be $ConfigurationData.AllNodes.RequireAccess
                $handler.ScriptProcessor     | should -Be $ConfigurationData.AllNodes.ScriptProcessor
                $handler.ResourceType        | should -Be $ConfigurationData.AllNodes.ResourceType
                $handler.AllowPathInfo       | should -Be $ConfigurationData.AllNodes.AllowPathInfo
                $handler.ResponseBufferLimit | should -Be $ConfigurationData.AllNodes.ResponseBufferLimit
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

                $handler | should be $null
            }
        }
    }
}

finally
{
    Restore-TestEnvironment -TestEnvironment $TestEnvironment
}
