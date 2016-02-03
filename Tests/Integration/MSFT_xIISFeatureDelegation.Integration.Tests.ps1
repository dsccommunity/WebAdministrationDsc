$global:DSCModuleName = 'xWebAdministration'
$global:DSCResourceName = 'MSFT_xIISFeatureDelegation'

#region HEADER
if ( (-not (Test-Path -Path '.\DSCResource.Tests\')) -or `
     (-not (Test-Path -Path '.\DSCResource.Tests\TestHelper.psm1')) )
{
    & git @('clone','https://github.com/PowerShell/DscResource.Tests.git')
}
else
{
    & git @('-C',(Join-Path -Path (Get-Location) -ChildPath '\DSCResource.Tests\'),'pull')
}
Import-Module .\DSCResource.Tests\TestHelper.psm1 -Force
$TestEnvironment = Initialize-TestEnvironment `
    -DSCModuleName $Global:DSCModuleName `
    -DSCResourceName $Global:DSCResourceName `
    -TestType Integration
#endregion

try
{
    # Now that xWebAdministration should be discoverable load the configuration data
    $ConfigFile = Join-Path -Path $PSScriptRoot -ChildPath "$($Global:DSCResourceName).config.ps1"
    . $ConfigFile

    [string] $tempName = "$($Global:DSCResourceName)_" + (Get-Date).ToString("yyyyMMdd_HHmmss")
    $null = Backup-WebConfiguration -Name $tempName

    Describe "$($Global:DSCResourceName)_Integration" {
        # Allow Feature Delegation
        # for this test we are using the anonymous Authentication feature, which is installed by default, but has Feature Delegation set to denied by default
        if ((Get-WindowsOptionalFeature –Online | Where-Object {$_.FeatureName -eq "IIS-Security" -and $_.State -eq "Enabled"}).Count -eq 1)
        {
            if ((Get-WebConfiguration /system.webserver/security/authentication/anonymousAuthentication iis:\).OverrideModeEffective -eq 'Deny')
            {
                It 'Allow Feature Delegation'{
                    {
                        Invoke-Expression -Command "$($Global:DSCResourceName)_AllowDelegation -OutputPath `$TestEnvironment.WorkingFolder"
                        Start-DscConfiguration -Path $TestEnvironment.WorkingFolder -ComputerName localhost -Wait -Verbose -Force
                    } | Should not throw

                    (Get-WebConfiguration /system.webserver/security/authentication/anonymousAuthentication iis:\).OverrideModeEffective  | Should be 'Allow'
                }
            }
        }

        # It 'Deny Feature Delegation' {
        #     {
        #         # this test doesn't really test the resource if it defaultDocument
        #         # is already Deny (not the default)
        #         # well it doesn't test the Set Method, but does test the Test method
        #         # What if the default document module is not installed?

        #         Invoke-Expression -Command "$($Global:DSCResourceName)_DenyDelegation -OutputPath `$TestEnvironment.WorkingFolder"
        #         Start-DscConfiguration -Path $TestEnvironment.WorkingFolder -ComputerName localhost -Wait -Verbose -Force

        #         # Now lets try to add a new default document on site level, this should fail
        #         # get the first site, it doesn't matter which one, it should fail.
        #         $siteName = (Get-ChildItem iis:\sites | Select -First 1).Name
        #         Add-WebConfigurationProperty `
        #             -PSPath "MACHINE/WEBROOT/APPHOST/$siteName" `
        #             -Filter 'system.webServer/defaultDocument/files' `
        #             -Name '.' `
        #             -Value @{Value = 'pesterpage.cgi'}

        #         # remove it again, should also fail, but if both work we at least cleaned it up,
        #         # it would be better to backup and restore the web.config file.
        #         Remove-WebConfigurationProperty  `
        #             -PSPath "MACHINE/WEBROOT/APPHOST/$siteName" `
        #             -Filter 'system.webServer/defaultDocument/files' `
        #             -Name '.' `
        #             -AtElement @{Value = 'pesterpage.cgi'}
        #     } | Should Not Throw
        # }

        It 'Deny Feature Delegation' -test {
        {
            # this test doesn't really test the resource if it defaultDocument
            # is already Deny (not the default)
            # well it doesn't test the Set Method, but does test the Test method
            # What if the default document module is not installed?

            Invoke-Expression -Command "$($Global:DSCResourceName)_DenyDelegation -OutputPath `$TestEnvironment.WorkingFolder"
            Start-DscConfiguration -Path $TestEnvironment.WorkingFolder -ComputerName localhost -Wait -Verbose -Force

            # Now lets try to add a new default document on site level, this should fail
            # get the first site, it doesn't matter which one, it should fail.
            $siteName = (Get-ChildItem iis:\sites | Select -First 1).Name
            Add-WebConfigurationProperty -pspath "MACHINE/WEBROOT/APPHOST/$siteName"  -filter "system.webServer/defaultDocument/files" -name "." -value @{value='pesterpage.cgi'}

            # remove it again, should also fail, but if both work we at least cleaned it up, it would be better to backup and restore the web.config file.
            Remove-WebConfigurationProperty  -pspath "MACHINE/WEBROOT/APPHOST/$siteName"  -filter "system.webServer/defaultDocument/files" -name "." -AtElement @{value='pesterpage.cgi'} } | should throw
        }

        #region DEFAULT TESTS
        # TODO: This will need to be corrected in a future PR.
        # It 'should be able to call Get-DscConfiguration without throwing' {
        #     { Get-DscConfiguration -Verbose -ErrorAction Stop } | Should Not throw
        # }
        #endregion
    }
}
finally
{
    #region FOOTER
    Restore-WebConfiguration -Name $tempName
    Remove-WebConfigurationBackup -Name $tempName

    Restore-TestEnvironment -TestEnvironment $TestEnvironment
    #endregion
}
