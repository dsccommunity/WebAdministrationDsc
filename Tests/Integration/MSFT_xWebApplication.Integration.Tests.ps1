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

Install-Module -Name 'xWebAdministration' -Force

# Using try/finally to always cleanup even if something awful happens.
try
{
    $ConfigFile = Join-Path -Path $PSScriptRoot -ChildPath "$($script:DSCResourceName).config.ps1"
    . $ConfigFile

    Describe "$($script:DSCResourceName)_Integration" {
        $Name = $ConfigurationData.AllNodes.Name
        $filter = "system.webServer/handlers/Add[@Name='$Name']"

        It 'Should compile and apply the MOF without throwing' {
            {
                $configurationParameters = @{
                    OutputPath        = $TestDrive
                    ConfigurationData = $ConfigurationData
                }

                & "$($script:DSCResourceName)_Addhandler" @configurationParameters

                Start-DscConfiguration -Path $TestDrive -ComputerName localhost -Wait -Verbose -Force
            } | should not throw
        }

        It 'should be able to call Get-DscConfiguration without throwing' {
            { Get-DscConfiguration -Verbose -ErrorAction Stop } | should Not throw
        }

        It 'should be able to call Test-DscConfiguration and return true' {
            $results = Test-DscConfiguration -Verbose -ErrorAction Stop
            $results | Should Be $true
        }

        It 'should add a handler' {
            $handler = Get-WebConfigurationProperty -pspath $handler.PSPath -filter $filter -Name .

            $handler.Modules             | should be $ConfigurationData.AllNodes.Modules
            $handler.Name                | should be $ConfigurationData.AllNodes.Name
            $handler.Path                | should be $ConfigurationData.AllNodes.Path
            $handler.Verb                | should be $ConfigurationData.AllNodes.Verb
            $handler.RequireAccess       | should be $ConfigurationData.AllNodes.RequireAccess
            $handler.ScriptProcessor     | should be $ConfigurationData.AllNodes.ScriptProcessor
            $handler.ResourceType        | should be $ConfigurationData.AllNodes.ResourceType
            $handler.AllowPathInfo       | should be $ConfigurationData.AllNodes.AllowPathInfo
            $handler.ResponseBufferLimit | should be $ConfigurationData.AllNodes.ResponseBufferLimit
        }

        It 'should remove a handler' {

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

finally
{
    Uninstall-Module -Name 'xWebAdministration'
    Restore-TestEnvironment -TestEnvironment $TestEnvironment
}
