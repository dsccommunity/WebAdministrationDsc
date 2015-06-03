######################################################################################
# Integration Tests for DSC Resource for IIS Server level Application Ppol Defaults
# 
# These tests change the IIS server level configuration but roll back the changes at the end
# so they should be save to run.
# Run as an elevated administrator 
# 
######################################################################################

$here = Split-Path -Parent $MyInvocation.MyCommand.Path

# create a unique name that we use for our temp files and folders
[string]$tempName = "xWebAppPoolDefaultTests_" + (Get-Date).ToString("yyyyMMdd_HHmmss")

Import-Module (Join-Path $here -ChildPath "..\..\DSCResources\MSFT_xWebAppPoolDefaults\MSFT_xWebAppPoolDefaults.psm1")
Import-Module (Join-Path $here -ChildPath "..\..\DSCResources\MSFT_xWebAppPoolDefaults\MSFT_xWebSitelDefaults.psm1")

# some constants
[string]$constPsPath = 'MACHINE/WEBROOT/APPHOST'
[string]$constAPDFilter = "system.applicationHost/applicationPools/applicationPoolDefaults"

Describe "xIISServerDefaults" {
    try
    {
        # before doing our changes, create a backup of the current config        
        Backup-WebConfiguration -Name $tempName

        It 'Changing ManagedRuntimeVersion ' -test {
        {
            # get the current value 
            [string]$originalValue = (Get-WebConfigurationProperty -pspath $constPsPath -filter $constAPDFilter -name managedRuntimeVersion)

            if ($originalValue -eq "v4.0")
            {
                $env:PesterManagedRuntimeVersion =  "v2.0"
            }
            else
            {
                $env:PesterManagedRuntimeVersion =  "v4.0"
            }

            configuration ManagedRuntimeVersion
            {
                Import-DscResource -ModuleName xWebAdministration

                xWebAppPoolDefaults PoolDefaults
                {
                    ApplyTo = "Machine"
                    ManagedRuntimeVersion = "$env:PesterManagedRuntimeVersion"
                }
            }

            ManagedRuntimeVersion -OutputPath $env:temp\$($tempName)_ManagedRuntimeVersion
            Start-DscConfiguration -Path $env:temp\$($tempName)_ManagedRuntimeVersion -Wait -ErrorAction Stop} | should not throw
            $changedValue = (Get-WebConfigurationProperty -pspath $constPsPath -filter $constAPDFilter -name managedRuntimeVersion).Value

            $changedValue | should be $env:PesterManagedRuntimeVersion 
        }

        
        It 'Invalid ManagedRuntimeVersion ' -test {
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

        It 'Changing IdentityType' -test {
        {

            # get the current value 
            [string]$originalValue = (Get-WebConfigurationProperty -pspath $constPsPath -filter $constAPDFilter/processModel -name identityType)

            if ($originalValue -eq "ApplicationPoolIdentity")
            {
                $env:PesterApplicationPoolIdentity =  "LocalService"
            }
            else
            {
                $env:PesterApplicationPoolIdentity =  "ApplicationPoolIdentity"
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
    }
    finally
    {
        # roll back our changes
        Restore-WebConfiguration -Name $tempName
        Remove-WebConfigurationBackup -Name $tempName
                          
        Remove-Item Env:\PesterManagedRuntimeVersion
        Remove-Item Env:\PesterApplicationPoolIdentity 

        # remove the generated MoF files
        Get-ChildItem $env:temp -Filter $tempName* | Remove-item -Recurse
    }                             
}