
$script:dscModuleName      = 'xWebAdministration'
$script:dscResourceName    = 'MSFT_xWebAppPoolDefaults'

try
{
    Import-Module -Name DscResource.Test -Force -ErrorAction 'Stop'
}
catch [System.IO.FileNotFoundException]
{
    throw 'DscResource.Test module dependency not found. Please run ".\build.ps1 -Tasks build" first.'
}

$script:testEnvironment = Initialize-TestEnvironment `
    -DSCModuleName $script:dscModuleName `
    -DSCResourceName $script:dscResourceName `
    -ResourceType 'Mof' `
    -TestType 'Integration'

Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\TestHelper\CommonTestHelper.psm1') -Force

$tempName = "$($script:dscResourceName)_" + (Get-Date).ToString("yyyyMMdd_HHmmss")

try
{
    # some constants
    [string]$constPsPath = 'MACHINE/WEBROOT/APPHOST'
    [string]$constAPDFilter = 'system.applicationHost/applicationPools/applicationPoolDefaults'
    [string]$constSiteFilter = 'system.applicationHost/sites/'

    $ConfigFile = Join-Path -Path $PSScriptRoot -ChildPath "$($script:dscResourceName).config.ps1"
    . $ConfigFile

    $null = Backup-WebConfiguration -Name $tempName

    function Get-SiteValue([string]$path,[string]$name)
    {
        return (Get-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST' -filter "system.applicationHost/sites/$path" -name $name).value
    }

    Describe "$($script:dscResourceName)_Integration" {
        It 'Should compile without throwing' {
            {
                Invoke-Expression -Command "$($script:dscResourceName)_Config -OutputPath `$TestDrive"
                Start-DscConfiguration -Path $TestDrive -ComputerName localhost -Wait -Verbose -Force
            } | Should not throw
        }

        It 'Should be able to call Get-DscConfiguration without throwing' {
            { Get-DscConfiguration -Verbose -ErrorAction Stop } | Should Not throw
        }

        It 'Changing ManagedRuntimeVersion' {
            {
                # get the current value
                [string] $originalValue = (Get-WebConfigurationProperty -pspath $constPsPath -filter $constAPDFilter -name managedRuntimeVersion)

                # We are using environment variables here, because a inline PowerShell variable was empty after executing  Start-DscConfiguration

                # change the value to something else
                if ($originalValue -eq 'v4.0')
                {
                    $env:PesterManagedRuntimeVersion =  'v2.0'
                }
                else
                {
                    $env:PesterManagedRuntimeVersion =  'v4.0'
                }

                Invoke-Expression -Command "$($script:dscResourceName)_ManagedRuntimeVersion -OutputPath `$TestDrive"
                Start-DscConfiguration -Path $TestDrive -ComputerName localhost -Wait -Verbose -Force
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
                Invoke-Expression -Command "$($script:dscResourceName)_AppPoolIdentityType -OutputPath `$TestDrive"
                Start-DscConfiguration -Path $TestDrive -ComputerName localhost -Wait -Verbose -Force
            } | Should not throw

            $changedValue = (Get-WebConfigurationProperty -PSPath $constPsPath -Filter $constAPDFilter/processModel -Name identityType)

            $changedValue | Should Be $env:PesterApplicationPoolIdentity
        }


        It 'Changing LogFormat' {
            [string] $originalValue = Get-SiteValue 'logFile' 'logFormat'

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
                Invoke-Expression -Command "$($script:dscResourceName)_LogFormat -OutputPath `$TestDrive"
                Start-DscConfiguration -Path $TestDrive -ComputerName localhost -Wait -Verbose -Force
            } | Should not throw

            $changedValue = Get-SiteValue 'logFile' 'logFormat'

            $changedValue | Should Be $env:PesterALogFormat
        }

        It 'Changing Default AppPool' {
            # get the current value

            [string] $originalValue = Get-SiteValue 'applicationDefaults' 'applicationPool'

            $env:PesterDefaultPool =  'DefaultAppPool'
            # Compile the MOF File
            {
                Invoke-Expression -Command "$($script:dscResourceName)_DefaultPool -OutputPath `$TestDrive"
                Start-DscConfiguration -Path $TestDrive -ComputerName localhost -Wait -Verbose -Force
            } | Should not throw

            $changedValue = Get-SiteValue 'applicationDefaults' 'applicationPool'
            $changedValue | should be $env:PesterDefaultPool
        }

    }
}
finally
{
    Restore-WebConfigurationWrapper -Name $tempName -Verbose

    Remove-WebConfigurationBackup -Name $tempName -Verbose

    Restore-TestEnvironment -TestEnvironment $script:testEnvironment -Verbose
}
