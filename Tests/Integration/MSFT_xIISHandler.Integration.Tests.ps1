
$script:DSCModuleName      = 'xWebAdministration'
$script:DSCResourceName    = 'MSFT_xIISHandler'

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
    -DSCModuleName $script:DSCModuleName `
    -DSCResourceName $script:DSCResourceName `
    -TestType Integration
#endregion

[string]$tempName = "$($script:DSCResourceName)_" + (Get-Date).ToString("yyyyMMdd_HHmmss")

# Using try/finally to always cleanup even if something awful happens.
try
{
    #region Integration Tests
    $ConfigFile = Join-Path -Path $PSScriptRoot -ChildPath "$($script:DSCResourceName).config.ps1"
    . $ConfigFile

    $null = Backup-WebConfiguration -Name $tempName

    Describe "$($script:DSCResourceName)_Integration" {
        #region DEFAULT TESTS
        It 'Should compile without throwing' {
            {
                Invoke-Expression -Command "$($script:DSCResourceName)_RemoveHandler -OutputPath `$TestEnvironment.WorkingFolder"
                Start-DscConfiguration -Path $TestEnvironment.WorkingFolder -ComputerName localhost -Wait -Verbose -Force
            } | Should not throw
        }

        It 'should be able to call Get-DscConfiguration without throwing' {
            { Get-DscConfiguration -Verbose -ErrorAction Stop } | Should Not throw
        }
        #endregion

        It 'Add a handler' {
            # webDav is normally not there, and even if the WebDav feature is not installed
            # we can add a handler for it.

            {
                # TRACEVerbHandler is usually there, remove it

                Invoke-Expression -Command "$($script:DSCResourceName)_AddHandler -OutputPath `$TestEnvironment.WorkingFolder"
                Start-DscConfiguration -Path $TestEnvironment.WorkingFolder -ComputerName localhost -Wait -Verbose -Force
            }  | should not throw

            [string]$filter = "system.webServer/handlers/Add[@Name='WebDAV']"
            ((Get-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST' -filter $filter -Name .) | Measure-Object).Count | should be 1
        }

        It 'StaticFile handler' {
            # StaticFile is usually there, have it present shouldn't change anything.
            {
                Invoke-Expression -Command "$($script:DSCResourceName)_StaticFileHandler -OutputPath `$TestEnvironment.WorkingFolder"
                Start-DscConfiguration -Path $TestEnvironment.WorkingFolder -ComputerName localhost -Wait -Verbose -Force
            }  | should not throw

            [string]$filter = "system.webServer/handlers/Add[@Name='StaticFile']"
            ((Get-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST' -filter $filter -Name .) | Measure-Object).Count | should be 1
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
