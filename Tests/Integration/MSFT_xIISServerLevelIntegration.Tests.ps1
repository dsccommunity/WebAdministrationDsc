######################################################################################
# Integration Tests for DSC Resource for IIS Server level defaults
#
# These tests change the IIS server level configuration but roll back the changes at the end
# so they should be save to run.
# Run as an elevated administrator
# At this time, we don't have tests for all changable properties, but it should be easy to add more tests.
######################################################################################

# should check for the server OS
if($env:APPVEYOR_BUILD_VERSION)
{
     Add-WindowsFeature Web-Server -Verbose
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

try
{
    # Now that xWebAdministration should be discoverable load the configuration data
    . "$PSScriptRoot\IISServerLevel_Configuration.ps1"

    # create a unique name that we use for our temp files and folders
    [string]$tempName = "xIISServerLevelTests_" + (Get-Date).ToString("yyyyMMdd_HHmmss")

    # some constants
    [string]$constPsPath = 'MACHINE/WEBROOT/APPHOST'
    [string]$constAPDFilter = "system.applicationHost/applicationPools/applicationPoolDefaults"
    [string]$constSiteFilter = "system.applicationHost/sites/"

    Describe "xIISServerDefaults" {
        function GetSiteValue([string]$path,[string]$name)
        {
            return (Get-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST' -filter "system.applicationHost/sites/$path" -name $name).value
        }

        It 'Checking resource: xWebSiteDefaults' -test {
            (Get-DSCResource -name xWebSiteDefaults).count | should be 1
        }
        It 'Checking resource: xWebAppPoolDefaults' -test {
            (Get-DSCResource -name xWebAppPoolDefaults).count | should be 1
        }
        It 'Checking resource: xIisFeatureDelegation' -test {
            (Get-DSCResource -name xIisFeatureDelegation).count | should be 1
        }
        It 'Checking resource: xIisMimeTypeMapping' -test {

            (Get-DSCResource -name xIisMimeTypeMapping).count | should be 1
        }

        # before doing our changes, create a backup of the current config
        Backup-WebConfiguration -Name $tempName

        It 'Changing ManagedRuntimeVersion ' -test {
        {
            # get the current value
            [string]$originalValue = (Get-WebConfigurationProperty -pspath $constPsPath -filter $constAPDFilter -name managedRuntimeVersion)

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

            # define the configuration
            # we need to set the PSModulePath once more to get this to work in AppVevor to find our resources
            [System.Environment]::SetEnvironmentVariable('PSModulePath',$env:PSModulePath,[System.EnvironmentVariableTarget]::Machine)

            # execute the configuration into a temp location
            ManagedRuntimeVersion -OutputPath $env:temp\$($tempName)_ManagedRuntimeVersion
            # run the configuration, it should not throw any errors
            Start-DscConfiguration -Path $env:temp\$($tempName)_ManagedRuntimeVersion -Wait -Verbose -ErrorAction Stop -Force}  | should not throw

            # get the configured value again
            $changedValue = (Get-WebConfigurationProperty -pspath $constPsPath -filter $constAPDFilter -name managedRuntimeVersion).Value

            # compare it to the one we just tried to set.
            $changedValue | should be $env:PesterManagedRuntimeVersion
        }


        It 'Invalid ManagedRuntimeVersion ' -test  {
        {
            InvalidManagedRuntimeVersion -OutputPath $env:temp\$($tempName)_InvalidManagedRuntimeVersion
            Start-DscConfiguration -Path $env:temp\$($tempName)_ManagedRuntimeVersion -Wait  -Verbose -ErrorAction Stop -Force}  | should throw
        }

        It 'Changing IdentityType' -test  {
        {
            # get the current value
            [string]$originalValue = (Get-WebConfigurationProperty -pspath $constPsPath -filter $constAPDFilter/processModel -name identityType)

            if ($originalValue -eq "ApplicationPoolIdentity")
            {
                $env:PesterApplicationPoolIdentity = "LocalService"
            }
            else
            {
                $env:PesterApplicationPoolIdentity = "ApplicationPoolIdentity"
            }

            AppPoolIdentityType -OutputPath $env:temp\$($tempName)_AppPoolIdentityType
            Start-DscConfiguration -Path $env:temp\$($tempName)_AppPoolIdentityType -Wait -Verbose -ErrorAction Stop -Force}  | should not throw
            $changedValue = (Get-WebConfigurationProperty -pspath $constPsPath -filter $constAPDFilter/processModel -name identityType)

            $changedValue | should be $env:PesterApplicationPoolIdentity
        }


        It 'Changing LogFormat' -test {
        {
            # get the current value

            [string]$originalValue = GetSiteValue "logFile" "logFormat"

            if ($originalValue -eq "W3C")
            {
                $env:PesterLogFormat =  "IIS"
            }
            else
            {
                $env:PesterLogFormat =  "W3C"
            }

            LogFormat -OutputPath $env:temp\$($tempName)_LogFormat
            Start-DscConfiguration -Path $env:temp\$($tempName)_LogFormat -Wait -Verbose -ErrorAction Stop -Force}  | should not throw
            $changedValue = GetSiteValue "logFile" "logFormat"

            $changedValue | should be $env:PesterALogFormat
        }

        It 'Changing Default AppPool' -test {
        {
            # get the current value

            [string]$originalValue = GetSiteValue "applicationDefaults" "applicationPool"

            $env:PesterDefaultPool =  "fooBar"

            DefaultPool -OutputPath $env:temp\$($tempName)_LogFormat
            Start-DscConfiguration -Path $env:temp\$($tempName)_LogFormat -Wait -Verbose -ErrorAction Stop -Force}  | should not throw
            $changedValue = GetSiteValue "applicationDefaults" "applicationPool"
            $changedValue | should be $env:PesterDefaultPool
        }

        It 'Changing Default virtualDirectoryDefaults' -test {
        {
            # get the current value

            [string]$originalValue = GetSiteValue "virtualDirectoryDefaults" "allowSubDirConfig"

            if ($originalValue -eq "true")
            {
                $env:PesterVirtualDirectoryDefaults = "false"
            }
            else
            {
                $env:PesterVirtualDirectoryDefaults = "true"
            }

            virtualDirectoryDefaults -OutputPath $env:temp\$($tempName)_LogFormat
            Start-DscConfiguration -Path $env:temp\$($tempName)_LogFormat -Wait -Verbose -ErrorAction Stop -Force}  | should not throw
            $changedValue = GetSiteValue "virtualDirectoryDefaults" "allowSubDirConfig"
            $changedValue | should be $env:PesterVirtualDirectoryDefaults
        }

        It 'Adding a new MimeType' -test {
        {
            AddMimeType -OutputPath $env:temp\$($tempName)_AddMimeType
            Start-DscConfiguration -Path $env:temp\$($tempName)_AddMimeType -Wait -Verbose -ErrorAction Stop -Force}  | should not throw

            [string]$filter = "system.webServer/staticContent/mimeMap[@fileExtension='.PesterDummy' and @mimeType='text/plain']"
            ((Get-WebConfigurationProperty  -pspath 'MACHINE/WEBROOT/APPHOST' -filter $filter -Name .) | Measure).Count | should be 1
        }

        It 'Adding an existing MimeType' -test {
        {
            $node = (Get-WebConfigurationProperty  -pspath 'MACHINE/WEBROOT/APPHOST' -filter "system.webServer/staticContent/mimeMap" -Name .) | Select -First 1
            $env:PesterFileExtension2 = $node.fileExtension
            $env:PesterMimeType2 = $node.mimeType

            AddMimeType2 -OutputPath $env:temp\$($tempName)_AddMimeType2
            Start-DscConfiguration -Path $env:temp\$($tempName)_AddMimeType2 -Wait -Verbose -ErrorAction Stop -Force}  | should not throw

            [string]$filter = "system.webServer/staticContent/mimeMap[@fileExtension='" + $env:PesterFileExtension2 + "' and @mimeType='" + "$env:PesterMimeType2" + "']"
            ((Get-WebConfigurationProperty  -pspath 'MACHINE/WEBROOT/APPHOST' -filter $filter -Name .) | Measure).Count | should be 1
        }

        It 'Removing a MimeType' -test {
        {
            $node = (Get-WebConfigurationProperty  -pspath 'MACHINE/WEBROOT/APPHOST' -filter "system.webServer/staticContent/mimeMap" -Name .) | Select -First 1
            $env:PesterFileExtension = $node.fileExtension
            $env:PesterMimeType = $node.mimeType

            RemoveMimeType -OutputPath $env:temp\$($tempName)_RemoveMimeType
            Start-DscConfiguration -Path $env:temp\$($tempName)_RemoveMimeType -Wait -Verbose -ErrorAction Stop -Force}  | should not throw

            [string]$filter = "system.webServer/staticContent/mimeMap[@fileExtension='" + $env:PesterFileExtension + "' and @mimeType='" + "$env:PesterMimeType" + "']"
            ((Get-WebConfigurationProperty  -pspath 'MACHINE/WEBROOT/APPHOST' -filter $filter -Name .) | Measure).Count | should be 0
        }

        It 'Removing a non existing MimeType' -test {
        {
            RemoveMimeType2 -OutputPath $env:temp\$($tempName)_RemoveMimeType2
            Start-DscConfiguration -Path $env:temp\$($tempName)_RemoveMimeType2 -Wait -Verbose -ErrorAction Stop -Force}  | should not throw
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

        It 'Remove a handler' -test {
        {
            # TRACEVerbHandler is usually there, remove it

            RemoveHandler -OutputPath $env:temp\$($tempName)_RemoveHandler
            Start-DscConfiguration -Path $env:temp\$($tempName)_RemoveHandler -Wait -Verbose -ErrorAction Stop}  | should not throw

            [string]$filter = "system.webServer/handlers/Add[@Name='TRACEVerbHandler']"
            ((Get-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST' -filter $filter -Name .) | Measure).Count | should be 0

        }

        It 'Add a handler' -test {
        {
            # webDav is normally not there, and even if the WebDav feature is not installed
            # we can add a handler for it.

            AddHandler -OutputPath $env:temp\$($tempName)_AddHandler
            Start-DscConfiguration -Path $env:temp\$($tempName)_AddHandler -Wait -Verbose -ErrorAction Stop}  | should not throw

            [string]$filter = "system.webServer/handlers/Add[@Name='WebDAV']"
            ((Get-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST' -filter $filter -Name .) | Measure).Count | should be 1

        }

        It 'StaticFile handler' -test {
        {
            # StaticFile is usually there, have it present shouldn't change anything.

            StaticFileHandler -OutputPath $env:temp\$($tempName)_StaticFileHandler
            Start-DscConfiguration -Path $env:temp\$($tempName)_StaticFileHandler -Wait -Verbose -ErrorAction Stop}  | should not throw

            [string]$filter = "system.webServer/handlers/Add[@Name='StaticFile']"
            ((Get-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST' -filter $filter -Name .) | Measure).Count | should be 1

        }
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

    if ($script:tempPath) {
        $env:PSModulePath = $script:tempPath
    }
}
