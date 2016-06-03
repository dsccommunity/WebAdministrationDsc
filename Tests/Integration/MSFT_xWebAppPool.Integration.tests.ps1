#requires -Version 4.0

# Suppressing this rule because the globals are appropriate for tests
[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '')]
param ()

$Global:DSCModuleName   = 'xWebAdministration'
$Global:DSCResourceName = 'MSFT_xWebAppPool'

#region HEADER

[String] $moduleRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $Script:MyInvocation.MyCommand.Path))
$repoSource = (Get-Module -Name $Global:DSCModuleName -ListAvailable)

# If module was obtained from the gallery install test folder from the gallery instead of cloning from git
if (($null -ne $repoSource) -and ($repoSource[0].RepositorySourceLocation.Host -eq 'www.powershellgallery.com'))
{
    if ( -not (Test-Path -Path (Join-Path -Path $moduleRoot -ChildPath 'Tests\DscResourceTestHelper')) )
    {
        $choice = 'y'

        # If user wants to skip prompt - set this environment variale equal to 'true'
        if ($env:getDscTestHelper -ne $true)
        {
            $choice = read-host "In order to run this test you need to install a helper module, continue with installation? (Y/N)"
        }

        if ($choice -eq 'y')
        {
            # Install test folders from gallery
            Save-Module -Name 'DscResourceTestHelper' -Path (Join-Path -Path $moduleRoot -ChildPath 'Tests')
        }

        else 
        {
            Write-Error "Unable to run tests without the required helper module - Exiting test"
            return
        }
        
    }

    $testModuleVer = Get-ChildItem -Path (Join-Path -Path $moduleRoot -ChildPath '\Tests\DscResourceTestHelper')
    Import-Module (Join-Path -Path $moduleRoot -ChildPath "Tests\DscResourceTestHelper\$testModuleVer\TestHelper.psm1") -Force
} 
# Otherwise module was cloned from github
else
{
    # Get common tests and test helpers from gitHub rather than installing them from the gallery
    # This ensures that developers always have access to the most recent DscResource.Tests folder 
    $testHelperPath = (Join-Path -Path $moduleRoot -ChildPath '\Tests\DscResource.Tests\DscResourceTestHelper\TestHelper.psm1')
    if (-not (Test-Path -Path $testHelperPath))
    {
        # Clone test folders from gitHub
        $dscResourceTestsPath = Join-Path -Path $moduleRoot -ChildPath '\Tests\DscResource.Tests'
        & git @('clone','https://github.com/PowerShell/DscResource.Tests.git',$dscResourceTestsPath)
        
        # TODO get rid of this section once we update all other resources and merge the gitDependency branch with the main branch on DscResource.Tests
        Push-Location
        Set-Location $dscResourceTestsPath
        & git checkout gitDependency
        Pop-Location
    }

    Import-Module $testHelperPath -Force
}

$TestEnvironment = Initialize-TestEnvironment `
    -DSCModuleName $Global:DSCModuleName `
    -DSCResourceName $Global:DSCResourceName `
    -TestType Integration
#endregion

# Test Setup
if ((Get-Service -Name 'W3SVC').Status -ne 'Running')
{
    Start-Service -Name 'W3SVC'
}

$tempBackupName = "$($Global:DSCResourceName)_$(Get-Date -Format 'yyyyMMdd_HHmmss')"

# Using try/finally to always cleanup even if something awful happens.

try
{
    # Create configuration backup
    
    Backup-WebConfiguration -Name $tempBackupName | Out-Null

    #region Integration Tests

    $ConfigFile = Join-Path -Path $PSScriptRoot -ChildPath "$($Global:DSCResourceName).config.ps1"
    . $ConfigFile

    Describe "$($Global:DSCResourceName)_Integration" {

        #region Default Tests

        It 'Should be able to compile and apply without throwing' {
            {
                Invoke-Expression -Command (
                    '{0}_Config -OutputPath $TestEnvironment.WorkingFolder -ConfigurationData $ConfigData -ErrorAction Stop' -f
                    $Global:DSCResourceName
                )

                Start-DscConfiguration -Path $TestEnvironment.WorkingFolder -ComputerName localhost -Force -Wait -Verbose
            } | Should Not Throw
        }

        It 'Should be able to call Get-DscConfiguration without throwing' {
            {
                Get-DscConfiguration -Verbose -ErrorAction Stop
            } | Should Not Throw
        }

        #endregion

        It 'Should have set the resource and all the parameters should match' {

            $currentConfiguration = Get-DscConfiguration

            foreach ($parameter in $TestParameters.GetEnumerator())
            {
                Write-Verbose -Message "The $($parameter.Name) property should be set."

                if ($parameter.Name -eq 'Credential')
                {
                    $appPool = Get-WebConfiguration -Filter '/system.applicationHost/applicationPools/add' |
                        Where-Object -FilterScript {$_.name -eq $TestParameters['Name']}

                    $appPool.processModel.userName |
                    Should Be $TestParameters['Credential'].UserName

                    $appPool.processModel.password |
                    Should Be $TestParameters['Credential'].GetNetworkCredential().Password
                }
                else
                {
                    $currentConfiguration."$($parameter.Name)" |
                    Should Be $TestParameters[$parameter.Name]
                }
            }

        }

        It 'Actual configuration should match the desired configuration' {
            Test-DscConfiguration -Verbose | Should Be $true
        }

    }

    #endregion
}
finally
{
    #region FOOTER
    Restore-WebConfiguration -Name $tempBackupName
    Remove-WebConfigurationBackup -Name $tempBackupName

    Restore-TestEnvironment -TestEnvironment $TestEnvironment
    #endregion
}
