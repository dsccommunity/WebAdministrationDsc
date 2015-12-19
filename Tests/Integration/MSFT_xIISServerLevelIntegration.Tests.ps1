######################################################################################
# Integration Tests for DSC Resource for IIS Server level defaults
#
# These tests change the IIS server level configuration but roll back the changes at the end
# so they should be save to run.
# Run as an elevated administrator
# At this time, we don't have tests for all changable properties, but it should be easy to add more tests.
######################################################################################

# Check if WebServer is Installed
if (@(Get-WindowsOptionalFeature -Online -FeatureName 'IIS-WebServer' `
    | Where-Object -Property State -eq 'Disabled').Count -gt 0)
{
    if ((Get-CimInstance Win32_OperatingSystem).ProductType -eq 1)
    {
        # Desktop OS
        Enable-WindowsOptionalFeature -Online -FeatureName 'IIS-WebServer'
    }
    else
    {
        # Server OS
        Install-WindowsFeature -IncludeAllSubFeature -IncludeManagementTools -Name 'Web-Server'
    }
}

$DSCModuleName  = 'xWebAdministration'

$moduleRoot = "${env:ProgramFiles}\WindowsPowerShell\Modules\$DSCModuleName"

if(-not (Test-Path -Path $moduleRoot))
{
    $null = New-Item -Path $moduleRoot -ItemType Directory
}
else
{
    # Copy the existing folder out to the temp directory to hold until the end of the run
    # Delete the folder to remove the old files.
    $tempLocation = Join-Path -Path $env:Temp -ChildPath $DSCModuleName
    Copy-Item -Path $moduleRoot -Destination $tempLocation -Recurse -Force
    Remove-Item -Path $moduleRoot -Recurse -Force
    $null = New-Item -Path $moduleRoot -ItemType Directory
}

Copy-Item -Path $PSScriptRoot\..\..\* -Destination $moduleRoot -Recurse -Force -Exclude '.git'

if (Get-Module -Name $DSCModuleName -All)
{
    Get-Module -Name $DSCModuleName -All | Remove-Module
}

Import-Module -Name $(Get-Item -Path (Join-Path $moduleRoot -ChildPath "$DSCModuleName.psd1")) -Force

if (($env:PSModulePath).Split(';') -ccontains $pwd.Path)
{
    $script:tempPath = $env:PSModulePath
    $env:PSModulePath = ($env:PSModulePath -split ';' | Where-Object {$_ -ne $pwd.path}) -join ';'
}


$executionPolicy = Get-ExecutionPolicy
if ($executionPolicy -ne 'Unrestricted')
{
    Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Force
    $rollbackExecution = $true
}

try
{
    # Now that xWebAdministration should be discoverable load the configuration data
    . "$PSScriptRoot\IISServerLevel_Configuration.ps1"

    # create a unique name that we use for our temp files and folders
    [string]$tempName = "xIISServerLevelTests_" + (Get-Date).ToString("yyyyMMdd_HHmmss")
    Backup-WebConfiguration -Name $tempName

    Describe "xIISServerDefaults" {
        function GetSiteValue([string]$path,[string]$name)
        {
            return (Get-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST' -filter "system.applicationHost/sites/$path" -name $name).value
        }

        # before doing our changes, create a backup of the current config
        Backup-WebConfiguration -Name $tempName

        It 'Adding a new MimeType' -test {
        {
            AddMimeType -OutputPath $env:temp\$($tempName)_AddMimeType
            Start-DscConfiguration -Path $env:temp\$($tempName)_AddMimeType -Wait -Verbose -ErrorAction Stop -Force}  | should not throw

            [string]$filter = "system.webServer/staticContent/mimeMap[@fileExtension='.PesterDummy' and @mimeType='text/plain']"
            ((Get-WebConfigurationProperty  -pspath 'MACHINE/WEBROOT/APPHOST' -filter $filter -Name .) | Measure).Count | should be 1
        }

        # Allow Feature Delegation
        # for this test we are using the anonymous Authentication feature, which is installed by default, but has Feature Delegation set to denied by default
        if ((Get-WindowsOptionalFeature –Online | Where {$_.FeatureName -eq "IIS-Security" -and $_.State -eq "Enabled"}).Count -eq 1)
        {
            if ((Get-WebConfiguration /system.webserver/security/authentication/anonymousAuthentication iis:\).OverrideModeEffective -eq 'Deny')
            {
                It 'Allow Feature Delegation' -test {
                {
                    AllowDelegation -OutputPath $env:temp\$($tempName)_AllowDelegation
                    Start-DscConfiguration -Path $env:temp\$($tempName)_AllowDelegation -Wait -Verbose -ErrorAction Stop } | should not throw

                    (Get-WebConfiguration /system.webserver/security/authentication/anonymousAuthentication iis:\).OverrideModeEffective  | Should be 'Allow'
                }
            }
        }

        It 'Deny Feature Delegation' -test {
        {
            # this test doesn't really test the resource if it defaultDocument
            # is already Deny (not the default)
            # well it doesn't test the Set Method, but does test the Test method
            # What if the default document module is not installed?

            DenyDelegation -OutputPath $env:temp\$($tempName)_DenyDelegation
            Start-DscConfiguration -Path $env:temp\$($tempName)_DenyDelegation -Wait -Verbose -ErrorAction Stop

            # Now lets try to add a new default document on site level, this should fail
            # get the first site, it doesn't matter which one, it should fail.
            $siteName = (Get-ChildItem iis:\sites | Select -First 1).Name
            Add-WebConfigurationProperty -pspath "MACHINE/WEBROOT/APPHOST/$siteName"  -filter "system.webServer/defaultDocument/files" -name "." -value @{value='pesterpage.cgi'}

            # remove it again, should also fail, but if both work we at least cleaned it up, it would be better to backup and restore the web.config file.
            Remove-WebConfigurationProperty  -pspath "MACHINE/WEBROOT/APPHOST/$siteName"  -filter "system.webServer/defaultDocument/files" -name "." -AtElement @{value='pesterpage.cgi'} } | should throw
        }

        # Handler Tests
    }
}
finally
{
    # roll back our changes
    Restore-WebConfiguration -Name $tempName
    Remove-WebConfigurationBackup -Name $tempName

    # remove our result variables
    Get-ChildItem env: | Where Name -match "^Pester" | Remove-Item

    # remove the generated MoF files
    Get-ChildItem $env:temp -Filter $tempName* | Remove-item -Recurse

    # Cleanup after the test
    Remove-Item -Path $moduleRoot -Recurse -Force

    if ($rollbackExecution)
    {
        Set-ExecutionPolicy -ExecutionPolicy $executionPolicy -Force
    }

    if ($script:tempPath) {
        $env:PSModulePath = $script:tempPath
    }
}
