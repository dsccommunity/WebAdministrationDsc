# Suppressing this rule because the globals are appropriate for tests
[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '')]
param ()

$Global:DSCModuleName      = 'xWebAdministration'
$Global:DSCResourceName    = 'MSFT_xWebAppPoolDefaults'

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

[string] $tempName = "$($Global:DSCResourceName)_" + (Get-Date).ToString("yyyyMMdd_HHmmss")

# Using try/finally to always cleanup even if something awful happens.
try
{
    #region Integration Tests

    # some constants
    [string]$constPsPath = 'MACHINE/WEBROOT/APPHOST'
    [string]$constAPDFilter = "system.applicationHost/applicationPools/applicationPoolDefaults"
    [string]$constSiteFilter = "system.applicationHost/sites/"

    $ConfigFile = Join-Path -Path $PSScriptRoot -ChildPath "$($Global:DSCResourceName).config.ps1"
    . $ConfigFile

    $null = Backup-WebConfiguration -Name $tempName

    function Get-SiteValue([string]$path,[string]$name)
    {
        return (Get-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST' -filter "system.applicationHost/sites/$path" -name $name).value
    }

    Describe "$($Global:DSCResourceName)_Integration" {
        #region DEFAULT TESTS
        It 'Should compile without throwing' {
            {
                Invoke-Expression -Command "$($Global:DSCResourceName)_Config -OutputPath `$TestEnvironment.WorkingFolder"
                Start-DscConfiguration -Path $TestEnvironment.WorkingFolder -ComputerName localhost -Wait -Verbose -Force
            } | Should not throw
        }

        It 'should be able to call Get-DscConfiguration without throwing' {
            { Get-DscConfiguration -Verbose -ErrorAction Stop } | Should Not throw
        }
        #endregion

        It 'Changing ManagedRuntimeVersion' {
            {
                # get the current value
                [string] $originalValue = (Get-WebConfigurationProperty -pspath $constPsPath -filter $constAPDFilter -name managedRuntimeVersion)

                # We are using environment variables here, because a inline PowerShell variable was empty after executing  Start-DscConfiguration

                # change the value to something else
                if ($originalValue -eq "v4.0")
                {
                    $env:PesterManagedRuntimeVersion =  "v2.0"
                }
                else
                {
                    $env:PesterManagedRuntimeVersion =  "v4.0"
                }

                Invoke-Expression -Command "$($Global:DSCResourceName)_ManagedRuntimeVersion -OutputPath `$TestEnvironment.WorkingFolder"
                Start-DscConfiguration -Path $TestEnvironment.WorkingFolder -ComputerName localhost -Wait -Verbose -Force
            }  | should not throw

            # get the configured value again
            $changedValue = (Get-WebConfigurationProperty -pspath $constPsPath -filter $constAPDFilter -name managedRuntimeVersion).Value

            # compare it to the one we just tried to set.
            $changedValue | should be $env:PesterManagedRuntimeVersion
        }

        It 'Changing IdentityType' {
            # get the current value
            [string] $originalValue = (Get-WebConfigurationProperty `
                -PSPath $constPsPath `
                -Filter $constAPDFilter/processModel `
                -Name identityType)

            if ($originalValue -eq 'ApplicationPoolIdentity')
            {
                $env:PesterApplicationPoolIdentity = 'LocalService'
            }
            else
            {
                $env:PesterApplicationPoolIdentity = 'ApplicationPoolIdentity'
            }

            # Compile the MOF File
            {
                Invoke-Expression -Command "$($Global:DSCResourceName)_AppPoolIdentityType -OutputPath `$TestEnvironment.WorkingFolder"
                Start-DscConfiguration -Path $TestEnvironment.WorkingFolder -ComputerName localhost -Wait -Verbose -Force
            } | Should not throw

            $changedValue = (Get-WebConfigurationProperty -PSPath $constPsPath -Filter $constAPDFilter/processModel -Name identityType)

            $changedValue | Should Be $env:PesterApplicationPoolIdentity
        }


        It 'Changing LogFormat' {
            [string] $originalValue = Get-SiteValue "logFile" "logFormat"

            if ($originalValue -eq 'W3C')
            {
                $env:PesterLogFormat =  'IIS'
            }
            else
            {
                $env:PesterLogFormat =  'W3C'
            }

            # Compile the MOF File
            {
                Invoke-Expression -Command "$($Global:DSCResourceName)_LogFormat -OutputPath `$TestEnvironment.WorkingFolder"
                Start-DscConfiguration -Path $TestEnvironment.WorkingFolder -ComputerName localhost -Wait -Verbose -Force
            } | Should not throw

            $changedValue = Get-SiteValue "logFile" "logFormat"

            $changedValue | Should Be $env:PesterALogFormat
        }

        It 'Changing Default AppPool' {
            # get the current value

            [string] $originalValue = Get-SiteValue "applicationDefaults" "applicationPool"

            $env:PesterDefaultPool =  "fooBar"
            # Compile the MOF File
            {
                Invoke-Expression -Command "$($Global:DSCResourceName)_DefaultPool -OutputPath `$TestEnvironment.WorkingFolder"
                Start-DscConfiguration -Path $TestEnvironment.WorkingFolder -ComputerName localhost -Wait -Verbose -Force
            } | Should not throw

            $changedValue = Get-SiteValue "applicationDefaults" "applicationPool"
            $changedValue | should be $env:PesterDefaultPool
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
