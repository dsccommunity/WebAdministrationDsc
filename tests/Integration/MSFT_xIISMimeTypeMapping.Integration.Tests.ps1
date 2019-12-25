
$script:DSCModuleName   = 'xWebAdministration'
$script:DSCResourceName = 'MSFT_xIISMimeTypeMapping'

#region HEADER
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
#endregion

[string]$tempName = "$($script:DSCResourceName)_" + (Get-Date).ToString("yyyyMMdd_HHmmss")

# Using try/finally to always cleanup even if something awful happens.
try
{
    #region Integration Tests

    $null = Backup-WebConfiguration -Name $tempName

    $ConfigFile = Join-Path -Path $PSScriptRoot -ChildPath "$($script:DSCResourceName).config.ps1"
    . $ConfigFile

    Describe "$($script:DSCResourceName)_Integration Default tests" {

        #region Test Setup
        $tempVirtualDirectoryName = 'Dir01'
        $tempVirtualDirectoryPhysicalPath = Join-Path $TestDrive "inetpub\wwwroot\$tempVirtualDirectoryName"
        $tempVirtualDirectoryIisPath = "IIS:\Sites\WebsiteForxIisMimeTypeMapping\$tempVirtualDirectoryName"

        New-Website -Name 'WebsiteForxIisMimeTypeMapping' `
            -PhysicalPath (Join-Path $TestDrive 'inetpub\wwwroot\') `
            -Force `
            -ErrorAction Stop

        New-Item -Path $tempVirtualDirectoryPhysicalPath -ItemType Directory | Out-Null
        New-WebVirtualDirectory -Site 'WebsiteForxIisMimeTypeMapping' -Name $tempVirtualDirectoryName -PhysicalPath $tempVirtualDirectoryPhysicalPath
        #endregion

        $configData = @{
                AllNodes    = @();
                NonNodeData =
                @{
                    ServerConfigurationPath  = 'IIS:\'
                    VirtualConfigurationPath = $tempVirtualDirectoryIisPath
                    FileExtension            = '.Pester'
                    MimeType                 = 'text/dummy'
                }
            }

        $startDscConfigurationParameters = @{
            Path         = $TestDrive
            ComputerName = 'localhost'
            Wait         = $true
            Verbose      = $true
            Force        = $true
        }

        Context "When Adding a MimeType" {
            It 'Should compile and apply the MOF without throwing' {
                {
                    & "$($script:DSCResourceName)_AddMimeType" -OutputPath $TestDrive -ConfigurationData $configData
                    Start-DscConfiguration @startDscConfigurationParameters
                } | Should Not Throw
            }

            It 'Should be able to call Get-DscConfiguration without throwing' {
                { $script:CurrentConfiguration = Get-DscConfiguration -Verbose -ErrorAction Stop } | Should Not Throw
            }

            It 'Should add a MimeType' {
                $Script:CurrentConfiguration.Ensure    | Should Be 'Present'
                $Script:CurrentConfiguration.Extension | Should Be $configData.NonNodeData.FileExtension
                $Script:CurrentConfiguration.MimeType  | Should Be $configData.NonNodeData.MimeType
            }

            It 'Should return $true when Test-DscConfiguration is run' {
                Test-DscConfiguration -Verbose | Should Be $true
            }
        }

        Context "When Removing a MimeType" {

            It 'Should compile and apply the MOF without throwing' {
                {
                    & "$($script:DSCResourceName)_RemoveMimeType" -OutputPath $TestDrive -ConfigurationData $configData
                    Start-DscConfiguration @startDscConfigurationParameters
                } | Should Not Throw
            }

            It 'Should be able to call Get-DscConfiguration without throwing' {
                { $script:CurrentConfiguration = Get-DscConfiguration -Verbose -ErrorAction Stop } | Should Not Throw
            }

            It 'Should remove MimeType' {
                $Script:CurrentConfiguration.Ensure    | Should Be 'Absent'
                $Script:CurrentConfiguration.Extension | Should Be $configData.NonNodeData.FileExtension
                $Script:CurrentConfiguration.MimeType  | Should Be $configData.NonNodeData.MimeType
            }

            It 'Should return $true when Test-DscConfiguration is run' {
                Test-DscConfiguration -Verbose | Should Be $true
            }
        }

        Context "When Adding a MimeType in a Nested Path" {
            It 'Should compile and apply the MOF without throwing' {
                {
                    & "$($script:DSCResourceName)_AddMimeTypeNestedPath" -OutputPath $TestDrive -ConfigurationData $configData
                    Start-DscConfiguration @startDscConfigurationParameters
                } | Should Not Throw
            }

            It 'Should be able to call Get-DscConfiguration without throwing' {
                { $script:CurrentConfiguration = Get-DscConfiguration -Verbose -ErrorAction Stop } | Should Not Throw
            }

            It 'Should be add a MimeType to a Nested Path' {
                $Script:CurrentConfiguration.ConfigurationPath | Should Be $configData.NonNodeData.VirtualConfigurationPath
                $Script:CurrentConfiguration.Ensure            | Should Be 'Present'
                $Script:CurrentConfiguration.Extension         | Should Be $configData.NonNodeData.FileExtension
                $Script:CurrentConfiguration.MimeType          | Should Be $configData.NonNodeData.MimeType
            }

            It 'Should return $true when Test-DscConfiguration is run' {
                Test-DscConfiguration -Verbose | Should Be $true
            }
        }

        Context "When Removing a MimeType from a Nested Path" {
            It 'Should compile and apply the MOF without throwing' {
                {
                    & "$($script:DSCResourceName)_RemoveMimeTypeNestedPath" -OutputPath $TestDrive -ConfigurationData $configData
                    Start-DscConfiguration @startDscConfigurationParameters
                } | Should Not Throw
            }

            It 'Should be able to call Get-DscConfiguration without throwing' {
                { $script:CurrentConfiguration = Get-DscConfiguration -Verbose -ErrorAction Stop } | Should Not Throw
            }

            It 'Should remove a MimeType from a Nested Path' {
                $Script:CurrentConfiguration.ConfigurationPath | Should Be $configData.NonNodeData.VirtualConfigurationPath
                $Script:CurrentConfiguration.Ensure            | Should Be 'Absent'
                $Script:CurrentConfiguration.Extension         | Should Be $configData.NonNodeData.FileExtension
                $Script:CurrentConfiguration.MimeType          | Should Be $configData.NonNodeData.MimeType
            }

            It 'Should return $true when Test-DscConfiguration is run' {
                Test-DscConfiguration -Verbose | Should Be $true
            }
        }

        Context "When Adding a MimeType at the Server Level" {
            It 'Should compile and apply the MOF without throwing' {
                {
                    & "$($script:DSCResourceName)_AddMimeTypeAtServer" -OutputPath $TestDrive -ConfigurationData $configData
                    Start-DscConfiguration @startDscConfigurationParameters
                } | Should Not Throw
            }

            It 'Should be able to call Get-DscConfiguration without throwing' {
                { $script:CurrentConfiguration = Get-DscConfiguration -Verbose -ErrorAction Stop } | Should Not Throw
            }

            It 'Should Add a MimeType at the Server Level' {
                $Script:CurrentConfiguration.ConfigurationPath | Should Be $configData.NonNodeData.ServerConfigurationPath
                $Script:CurrentConfiguration.Ensure            | Should Be 'Present'
                $Script:CurrentConfiguration.Extension         | Should Be $configData.NonNodeData.FileExtension
                $Script:CurrentConfiguration.MimeType          | Should Be $configData.NonNodeData.MimeType
            }

            It 'Should return $true when Test-DscConfiguration is run' {
                Test-DscConfiguration -Verbose | Should Be $true
            }
        }

        Context "When Removing MimeType at the Server Level" {
            It 'Should compile and apply the MOF without throwing' {
                {
                    & "$($script:DSCResourceName)_RemoveMimeTypeAtServer" -OutputPath $TestDrive -ConfigurationData $configData
                    Start-DscConfiguration @startDscConfigurationParameters
                } | Should Not Throw
            }

            It 'Should be able to call Get-DscConfiguration without throwing' {
                { $script:CurrentConfiguration = Get-DscConfiguration -Verbose -ErrorAction Stop } | Should Not Throw
            }

            It 'Should Remove a MimeType at the Server Level' {
                $Script:CurrentConfiguration.ConfigurationPath | Should Be $configData.NonNodeData.ServerConfigurationPath
                $Script:CurrentConfiguration.Ensure            | Should Be 'Absent'
                $Script:CurrentConfiguration.Extension         | Should Be $configData.NonNodeData.FileExtension
                $Script:CurrentConfiguration.MimeType          | Should Be $configData.NonNodeData.MimeType
            }

            It 'Should return $true when Test-DscConfiguration is run' {
                Test-DscConfiguration -Verbose | Should Be $true
            }
        }
    }
    #endregion
}
finally
{
    #region FOOTER
    Restore-WebConfiguration -Name $tempName
    Remove-WebConfigurationBackup -Name $tempName

    Restore-TestEnvironment -TestEnvironment $TestEnvironment
    #endregion
}
