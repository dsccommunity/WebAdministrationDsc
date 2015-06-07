﻿######################################################################################
# Integration Tests for DSC Resource for IIS Server level defaults
# 
# These tests change the IIS server level configuration but roll back the changes at the end
# so they should be save to run.
# Run as an elevated administrator 
# At this time, we don't have tests for all changable properties, but it should be easy to add more tests.
######################################################################################

$here = Split-Path -Parent $MyInvocation.MyCommand.Path

# create a unique name that we use for our temp files and folders
[string]$tempName = "xWebAppPoolDefaultTests_" + (Get-Date).ToString("yyyyMMdd_HHmmss")

# Import should happen automatically, but here's how to do it manually:
# Import-Module (Join-Path $here -ChildPath "..\..\DSCResources\MSFT_xWebAppPoolDefaults\MSFT_xWebAppPoolDefaults.psm1")
# Import-Module (Join-Path $here -ChildPath "..\..\DSCResources\MSFT_xWebSiteDefaults\MSFT_xWebSiteDefaults.psm1")

# some constants
[string]$constPsPath = 'MACHINE/WEBROOT/APPHOST'
[string]$constAPDFilter = "system.applicationHost/applicationPools/applicationPoolDefaults"
[string]$constSiteFilter = "system.applicationHost/sites/"

Describe "xIISServerDefaults" {

    Function GetSiteValue([string]$path,[string]$name)
    {
        return (Get-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST' -filter "system.applicationHost/sites/$path" -name $name).value
    } 


    try
    {
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
            configuration ManagedRuntimeVersion
            {
                Import-DscResource -ModuleName xWebAdministration

                xWebAppPoolDefaults PoolDefaults
                {
                    ApplyTo = "Machine"
                    ManagedRuntimeVersion = "$env:PesterManagedRuntimeVersion"
                }
            }

            # execute the configuration into a temp location
            ManagedRuntimeVersion -OutputPath $env:temp\$($tempName)_ManagedRuntimeVersion
            # run the configuration, it should not throw any errors
            Start-DscConfiguration -Path $env:temp\$($tempName)_ManagedRuntimeVersion -Wait -ErrorAction Stop} | should not throw
            # get the configured value again
            $changedValue = (Get-WebConfigurationProperty -pspath $constPsPath -filter $constAPDFilter -name managedRuntimeVersion).Value
            # compare it to the one we just tried to set.
            $changedValue | should be $env:PesterManagedRuntimeVersion 
        }

        
        It 'Invalid ManagedRuntimeVersion ' -test  {
        {
            configuration InvalidManagedRuntimeVersion
            {
                Import-DscResource -ModuleName xWebAdministration

                xWebAppPoolDefaults PoolDefaults
                {
                    ApplyTo = "Machine"
                    ManagedRuntimeVersion = "v1.5"
                }
            }

            InvalidManagedRuntimeVersion -OutputPath $env:temp\$($tempName)_InvalidManagedRuntimeVersion
            Start-DscConfiguration -Path $env:temp\$($tempName)_ManagedRuntimeVersion -Wait -ErrorAction Stop} | should throw
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

            configuration AppPoolIdentityType
            {
                Import-DscResource -ModuleName xWebAdministration

                xWebAppPoolDefaults PoolDefaults
                {
                    ApplyTo = "Machine"
                    IdentityType = "$env:PesterApplicationPoolIdentity"
                }
            }

            AppPoolIdentityType -OutputPath $env:temp\$($tempName)_AppPoolIdentityType
            Start-DscConfiguration -Path $env:temp\$($tempName)_AppPoolIdentityType -Wait -ErrorAction Stop} | should not throw
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

            configuration LogFormat
            {
                Import-DscResource -ModuleName xWebAdministration

                xWebSiteDefaults LogFormat
                {
                    ApplyTo = "Machine"
                    LogFormat = "$env:PesterLogFormat"
                }
            }

            LogFormat -OutputPath $env:temp\$($tempName)_LogFormat
            Start-DscConfiguration -Path $env:temp\$($tempName)_LogFormat -Wait -ErrorAction Stop} | should not throw
            $changedValue = GetSiteValue "logFile" "logFormat"

            $changedValue | should be $env:PesterALogFormat 
        }

        It 'Changing Default AppPool' -test {
        {

            # get the current value 

            [string]$originalValue = GetSiteValue "applicationDefaults" "applicationPool"

            $env:PesterDefaultPool =  "fooBar"

            configuration DefaultPool
            {
                Import-DscResource -ModuleName xWebAdministration

                xWebSiteDefaults DefaultPool
                {
                    ApplyTo = "Machine"
                    DefaultApplicationPool = "$env:PesterDefaultPool"
                }
            }

            DefaultPool -OutputPath $env:temp\$($tempName)_LogFormat
            Start-DscConfiguration -Path $env:temp\$($tempName)_LogFormat -Wait -ErrorAction Stop} | should not throw
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
            

            configuration virtualDirectoryDefaults
            {
                Import-DscResource -ModuleName xWebAdministration

                xWebSiteDefaults virtualDirectoryDefaults
                {
                    ApplyTo = "Machine"
                    AllowSubDirConfig = "$env:PesterVirtualDirectoryDefaults"
                }
            }

            virtualDirectoryDefaults -OutputPath $env:temp\$($tempName)_LogFormat
            Start-DscConfiguration -Path $env:temp\$($tempName)_LogFormat -Wait -ErrorAction Stop} | should not throw
            $changedValue = GetSiteValue "virtualDirectoryDefaults" "allowSubDirConfig"
            $changedValue | should be $env:PesterVirtualDirectoryDefaults 
        }    
        
        It 'Adding a new MimeType' -test {
        {           
            configuration AddMimeType
            {
                Import-DscResource -ModuleName xWebAdministration

                xIIsMimeTypeMapping AddMimeType
                {
                    Extension = ".PesterDummy"
                    MimeType = "text/plain"
                    Ensure = "Present"
                }
            }

            AddMimeType -OutputPath $env:temp\$($tempName)_AddMimeType
            Start-DscConfiguration -Path $env:temp\$($tempName)_AddMimeType -Wait -ErrorAction Stop} | should not throw

            [string]$filter = "system.webServer/staticContent/mimeMap[@fileExtension='.PesterDummy' and @mimeType='text/plain']"
            ((Get-WebConfigurationProperty  -pspath 'MACHINE/WEBROOT/APPHOST' -filter $filter -Name .) | Measure).Count | should be 1        
        }              

        It 'Adding an existing MimeType' -test {
        {           
            $node = (Get-WebConfigurationProperty  -pspath 'MACHINE/WEBROOT/APPHOST' -filter "system.webServer/staticContent/mimeMap" -Name .) | Select -First 1
            $env:PesterFileExtension2 = $node.fileExtension
            $env:PesterMimeType2 = $node.mimeType
            
            configuration AddMimeType2
            {
                Import-DscResource -ModuleName xWebAdministration

                xIIsMimeTypeMapping AddMimeType2
                {
                    Extension = $env:PesterFileExtension2 
                    MimeType = "$env:PesterMimeType2"
                    Ensure = "Present"
                }
            }

            AddMimeType2 -OutputPath $env:temp\$($tempName)_AddMimeType2
            Start-DscConfiguration -Path $env:temp\$($tempName)_AddMimeType2 -Wait -ErrorAction Stop} | should not throw

            [string]$filter = "system.webServer/staticContent/mimeMap[@fileExtension='" + $env:PesterFileExtension2 + "' and @mimeType='" + "$env:PesterMimeType2" + "']"
            ((Get-WebConfigurationProperty  -pspath 'MACHINE/WEBROOT/APPHOST' -filter $filter -Name .) | Measure).Count | should be 1      
        } 

        It 'Removing a MimeType' -test {
        {
            $node = (Get-WebConfigurationProperty  -pspath 'MACHINE/WEBROOT/APPHOST' -filter "system.webServer/staticContent/mimeMap" -Name .) | Select -First 1
            $env:PesterFileExtension = $node.fileExtension
            $env:PesterMimeType = $node.mimeType
            
            configuration RemoveMimeType
            {
                Import-DscResource -ModuleName xWebAdministration

                xIIsMimeTypeMapping RemoveMimeType
                {
                    Extension = $env:PesterFileExtension 
                    MimeType = "$env:PesterMimeType"
                    Ensure = "Absent"
                }
            }

            RemoveMimeType -OutputPath $env:temp\$($tempName)_RemoveMimeType
            Start-DscConfiguration -Path $env:temp\$($tempName)_RemoveMimeType -Wait -ErrorAction Stop} | should not throw

            [string]$filter = "system.webServer/staticContent/mimeMap[@fileExtension='" + $env:PesterFileExtension + "' and @mimeType='" + "$env:PesterMimeType" + "']"
            ((Get-WebConfigurationProperty  -pspath 'MACHINE/WEBROOT/APPHOST' -filter $filter -Name .) | Measure).Count | should be 0
        }

        It 'Removing a non existing MimeType' -test {
        {           
            configuration RemoveMimeType2
            {
                Import-DscResource -ModuleName xWebAdministration

                xIIsMimeTypeMapping RemoveMimeType2
                {
                    Extension = ".PesterDummy2"
                    MimeType = "text/dummy"
                    Ensure = "Absent"
                }
            }

            RemoveMimeType2 -OutputPath $env:temp\$($tempName)_RemoveMimeType2
            Start-DscConfiguration -Path $env:temp\$($tempName)_RemoveMimeType2 -Wait -ErrorAction Stop} | should not throw
        }
        
       
                    
        # Allow Feature Delegation

        # for this test we are using the anonymous Authentication feature, which is installed by default, but has Feature Delegation set to denied by default
        if ((Get-WindowsOptionalFeature –Online | Where {$_.FeatureName -eq "IIS-Security" -and $_.State -eq "Enabled"}).Count -eq 1)
        {
            if ((get-webconfiguration /system.webserver/security/authentication/anonymousAuthentication iis:\).OverrideModeEffective -eq 'Deny')
            {
                It 'Allow Feature Delegation' -test {
                {
                    configuration AllowDelegation
                    {
                        Import-DscResource -ModuleName xWebAdministration

                        xIisFeatureDelegation AllowDelegation
                        {
                            SectionName = "security/authentication/anonymousAuthentication"
                            OverrideMode = "Allow"
                        }
                    }
                        
                    AllowDelegation -OutputPath $env:temp\$($tempName)_AllowDelegation
                    Start-DscConfiguration -Path $env:temp\$($tempName)_AllowDelegation -Wait -ErrorAction Stop } | should not throw

                    (get-webconfiguration /system.webserver/security/authentication/anonymousAuthentication iis:\).OverrideModeEffective  | Should be 'Allow'
                } 
            }
        }        
            
        It 'Deny Feature Delegation' -test {
        {
            # this test doesn't really test the resource if it defaultDocument is already Deny (not the default)
            # well it doesn't test the Set Method, but does test the Test method
            # What if the default document module is not installed?

            configuration DenyDelegation
            {
                Import-DscResource -ModuleName xWebAdministration

                xIisFeatureDelegation DenyDelegation
                {
                    SectionName = "defaultDocument"
                    OverrideMode = "Deny"
                }
            }

            DenyDelegation -OutputPath $env:temp\$($tempName)_DenyDelegation
            Start-DscConfiguration -Path $env:temp\$($tempName)_DenyDelegation -Wait -ErrorAction Stop
            # now lets try to add a new default document on site level, this should fail
            # get the first site, it doesn't matter it should fail.
            $siteName = (Get-ChildItem iis:\sites | Select -First 1).Name
            Add-WebConfigurationProperty -pspath "MACHINE/WEBROOT/APPHOST/$siteName"  -filter "system.webServer/defaultDocument/files" -name "." -value @{value='pesterpage.cgi'} 
            # remove it again, should also fail, but if both work we at least cleaned it up, it would be better to backup and restore the web.config file.           
            Remove-WebConfigurationProperty  -pspath "MACHINE/WEBROOT/APPHOST/$siteName"  -filter "system.webServer/defaultDocument/files" -name "." -AtElement @{value='pesterpage.cgi'} } | should throw 
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
    }                               
}