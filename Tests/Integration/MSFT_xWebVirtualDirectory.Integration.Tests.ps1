$script:DSCModuleName   = 'xWebAdministration'
$script:DSCResourceName = 'MSFT_xWebVirtualDirectory'

#region HEADER

# Integration Test Template Version: 1.1.0
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

[string] $tempName = "$($script:DSCResourceName)_" + (Get-Date).ToString('yyyyMMdd_HHmmss')

try
{
    $null = Backup-WebConfiguration -Name $tempName
    
    # Now that xWebAdministration should be discoverable load the configuration data
    $ConfigFile = Join-Path -Path $PSScriptRoot -ChildPath "$($script:DSCResourceName).config.ps1"
    . $ConfigFile

    $DSCConfig = Import-LocalizedData -BaseDirectory $PSScriptRoot -FileName "$($script:DSCResourceName).config.psd1"

    Describe "$($script:DSCResourceName)_Initialize" {
        Invoke-Expression -Command "$($script:DSCResourceName)_Initialize -ConfigurationData `$DSCConfig -OutputPath `$TestDrive"
        Start-DscConfiguration -Path $TestDrive -ComputerName localhost -Wait -Verbose -Force
    }

    Describe "$($script:DSCResourceName)_Present" {
        #region DEFAULT TESTS
        It 'Should compile without throwing' {
            {
                Invoke-Expression -Command "$($script:DSCResourceName)_Present -ConfigurationData `$DSCConfig -OutputPath `$TestDrive"
                Start-DscConfiguration -Path $TestDrive -ComputerName localhost -Wait -Verbose -Force
            } | Should not throw
        }

        It 'Should be able to call Get-DscConfiguration without throwing' {
            { Get-DscConfiguration -Verbose -ErrorAction Stop } | Should Not throw
        }
        #endregion

        It 'Should create a WebVirtualDirectory with correct settings' -Test {
            Invoke-Expression -Command "$($script:DSCResourceName)_Present -ConfigurationData `$DSCConfig  -OutputPath `$TestDrive"

            # Build results to test
            $result = Get-WebVirtualDirectory -Site $DSCConfig.AllNodes.Website `
                -Application $DSCConfig.AllNodes.WebApplication `
                -Name $DSCConfig.AllNodes.WebVirtualDirectory

            # Test virtual directory settings are correct
            $result.path            | Should Be "/$($DSCConfig.AllNodes.WebVirtualDirectory)"
            $result.physicalPath    | Should Be $DSCConfig.AllNodes.PhysicalPath
        }
    }

    Describe "$($script:DSCResourceName)_Absent" {
        #region DEFAULT TESTS
        It 'Should compile without throwing' {
            {
                Invoke-Expression -Command "$($script:DSCResourceName)_Absent -ConfigurationData `$DSCConfig -OutputPath `$TestDrive"
                Start-DscConfiguration -Path $TestDrive -ComputerName localhost -Wait -Verbose -Force
            } | Should not throw
        }

        It 'Should be able to call Get-DscConfiguration without throwing' {
            { Get-DscConfiguration -Verbose -ErrorAction Stop } | Should Not throw
        }
        #endregion
        
        It 'Should remove the WebVirtualDirectory' -Test {
            Invoke-Expression -Command "$($script:DSCResourceName)_Absent -ConfigurationData `$DSCConfg  -OutputPath `$TestDrive"

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
    #region FOOTER
    Restore-WebConfiguration -Name $tempName
    Remove-WebConfigurationBackup -Name $tempName

    if ((Test-Path -Path $DSCConfig.AllNodes.PhysicalPath)) {
        Remove-Item -Path $DSCConfig.AllNodes.PhysicalPath
    }

    if ((Test-Path -Path $DSCConfig.AllNodes.WebApplicationPhysicalPath)) {
        Remove-Item -Path $DSCConfig.AllNodes.WebApplicationPhysicalPath
    }

    Restore-TestEnvironment -TestEnvironment $TestEnvironment
    #endregion
}
