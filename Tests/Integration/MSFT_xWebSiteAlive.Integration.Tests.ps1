$script:DSCModuleName   = 'xWebAdministration'
$script:DSCResourceName = 'MSFT_xWebSiteAlive'

#region HEADER
# Integration Test Template Version: 1.1.1
[String] $script:moduleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
if ( (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests'))) -or `
     (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1'))) )
{
    & git @('clone','https://github.com/PowerShell/DscResource.Tests.git',(Join-Path -Path $script:moduleRoot -ChildPath '\DSCResource.Tests\'))
}

Import-Module -Name (Join-Path -Path $script:moduleRoot -ChildPath (Join-Path -Path 'DSCResource.Tests' -ChildPath 'TestHelper.psm1')) -Force
$TestEnvironment = Initialize-TestEnvironment `
    -DSCModuleName $script:DSCModuleName `
    -DSCResourceName $script:DSCResourceName `
    -TestType Integration

#endregion

[string] $tempIisConfigBackupName = "$($script:DSCResourceName)_" + (Get-Date).ToString('yyyyMMdd_HHmmss')
[string] $tempWebSitePhysicalPath = Join-Path $env:SystemDrive 'inetpub\wwwroot\WebsiteForxWebSiteAlive'

# Using try/finally to always cleanup.
try
{
    $null = Backup-WebConfiguration -Name $tempIisConfigBackupName

    $configFile = Join-Path -Path $PSScriptRoot -ChildPath "$($script:DSCResourceName).config.ps1"
    . $configFile

    $configData = @{
        AllNodes = @(
            @{
                NodeName           = 'localhost'
                WebSiteName        = 'WebsiteForxWebSiteAlive'
                PhysicalPath       = $tempWebSitePhysicalPath
                HTTPPort           = 80
                RequestFileName    = 'xWebSiteAliveTest.html'
                RequestFileContent = @'
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<title>IIS Windows Server</title>
</head>
<body>
</body>
</html>
'@
            }
        )
    }

    New-Item -Path $configData.AllNodes.PhysicalPath -ItemType Directory | Out-Null

    New-Website -Name $configData.AllNodes.WebSiteName `
        -PhysicalPath $configData.AllNodes.PhysicalPath `
        -Port $configData.AllNodes.HTTPPort `
        -Force `
        -ErrorAction Stop
    
    # Write without a BOM
    [IO.File]::WriteAllText((Join-Path $configData.AllNodes.PhysicalPath $configData.AllNodes.RequestFileName), $configData.AllNodes.RequestFileContent)

    #region Integration Tests
    
    Describe "$($script:DSCResourceName)_Integration" {
        #region DEFAULT TESTS
        It 'Should compile and apply the MOF without throwing' {
            {
                & "$($script:DSCResourceName)_Config" -OutputPath $TestDrive -ConfigurationData $configData
                Start-DscConfiguration -Path $TestDrive `
                    -ComputerName localhost -Wait -Verbose -Force
            } | Should not throw
        }

        It 'Should be able to call Get-DscConfiguration without throwing' {
            { Get-DscConfiguration -Verbose -ErrorAction Stop } | Should Not throw
        }
        #endregion
    }

    #endregion
}
finally
{
    #region FOOTER
    Restore-WebConfiguration -Name $tempIisConfigBackupName
    Remove-WebConfigurationBackup -Name $tempIisConfigBackupName

    Remove-Item -Path $tempWebSitePhysicalPath -Recurse -Force

    Restore-TestEnvironment -TestEnvironment $TestEnvironment
    #endregion
}
