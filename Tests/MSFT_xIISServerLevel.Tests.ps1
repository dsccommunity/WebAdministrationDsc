$here = Split-Path -Parent $MyInvocation.MyCommand.Path

[string]$backupName = "xWebAppPoolDefaultTests-" + (Get-Date).ToString("yyyyMMdd-HHmmss")

Import-Module (Join-Path $here -ChildPath "..\DSCResources\MSFT_xWebAppPoolDefaults\MSFT_xWebAppPoolDefaults.psm1")

Describe "xWebAppPoolDefaults" {
    It 'Should be able to get xWebAppPoolDefaults' -test {
        # just a good idea.  
        # I thought it might force the classes to register, but it does not.
        $resources = Get-DscResource -Name xWebAppPoolDefaults
        $resources.count | should be 1
    }

    It 'Should compile and run without an error and set a new value' -test {
        {
       
        # get the current value 
        [string]$originalValue = (Get-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST'  -filter "system.applicationHost/applicationPools/applicationPoolDefaults" -name managedRuntimeVersion).Value

        if ($originalValue -eq "v4.0")
        {
            $env:PesterManagedRuntimeVersion =  "v2.0"
        }
        else
        {
            $env:PesterManagedRuntimeVersion =  "v4.0"
        }

        # before doing our change, create a backup of the current config        
        Backup-WebConfiguration -Name $backupName

        configuration foo
        {
            Import-DscResource -ModuleName xWebAdministration

            xWebAppPoolDefaults PoolDefaults
            {
                ApplyTo = "Machine"
                ManagedRuntimeVersion = "$env:PesterManagedRuntimeVersion"
            }
        }

        foo -OutputPath $env:temp\foo
        Start-DscConfiguration -Path $env:temp\foo -Wait -Verbose -ErrorAction Stop} | should not throw
        $changedValue = (Get-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST' -filter "system.applicationHost/applicationPools/applicationPoolDefaults" -name managedRuntimeVersion).Value

        # roll back our changes
        Restore-WebConfiguration -Name $backupName
        Remove-WebConfigurationBackup -Name $backupName
        
        $changedValue | should be $env:PesterManagedRuntimeVersion      
        
        Remove-Item Env:\PesterManagedRuntimeVersion                         
    }   
}