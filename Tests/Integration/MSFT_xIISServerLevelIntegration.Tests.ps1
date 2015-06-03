$here = Split-Path -Parent $MyInvocation.MyCommand.Path

# create a unique name that we use for our temp files and folders
[string]$tempName = "xWebAppPoolDefaultTests_" + (Get-Date).ToString("yyyyMMdd_HHmmss")

Import-Module (Join-Path $here -ChildPath "..\..\DSCResources\MSFT_xWebAppPoolDefaults\MSFT_xWebAppPoolDefaults.psm1")

# some constants
[string]$constPsPath = 'MACHINE/WEBROOT/APPHOST'
[string]$constAPDFilter = "system.applicationHost/applicationPools/applicationPoolDefaults"

Describe "xWebAppPoolDefaults" {
    try
    {

        # before doing our changes, create a backup of the current config        
        Backup-WebConfiguration -Name $tempName

        It 'Changing AppPool Default ManagedRuntimeVersion ' -test {
        {
            # get the current value 
            [string]$originalValue = (Get-WebConfigurationProperty -pspath $constPsPath -filter $constAPDFilter -name managedRuntimeVersion).Value

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
    }
    finally
    {
        # roll back our changes
        Restore-WebConfiguration -Name $tempName
        Remove-WebConfigurationBackup -Name $tempName
                          
        Remove-Item Env:\PesterManagedRuntimeVersion 

        # remove the generated MoF files
        Get-ChildItem $env:temp -Filter $tempName* | Remove-item -Recurse
    }                             
}