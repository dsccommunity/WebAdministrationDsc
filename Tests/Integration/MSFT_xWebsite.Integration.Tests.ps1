
$script:DSCModuleName   = 'xWebAdministration'
$script:DSCResourceName = 'MSFT_xWebsite'

#region HEADER
[String] $moduleRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $Script:MyInvocation.MyCommand.Path))
if ( (-not (Test-Path -Path (Join-Path -Path $moduleRoot -ChildPath 'DSCResource.Tests'))) -or `
     (-not (Test-Path -Path (Join-Path -Path $moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1'))) )
{
    & git @('clone','https://github.com/PowerShell/DscResource.Tests.git',(Join-Path -Path $moduleRoot -ChildPath '\DSCResource.Tests\'))
}

Import-Module (Join-Path -Path $moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1') -Force
$TestEnvironment = Initialize-TestEnvironment `
    -DSCModuleName $script:DSCModuleName `
    -DSCResourceName $script:DSCResourceName `
    -TestType Integration
#endregion

[string] $tempName = "$($script:DSCResourceName)_" + (Get-Date).ToString("yyyyMMdd_HHmmss")

try
{
    # Now that xWebAdministration should be discoverable load the configuration data
    $ConfigFile = Join-Path -Path $PSScriptRoot -ChildPath "$($script:DSCResourceName).config.ps1"
    . $ConfigFile

    $null = Backup-WebConfiguration -Name $tempName

    Describe "$($script:DSCResourceName)_Integration" {
        #region DEFAULT TESTS
        It 'Should compile without throwing' {
            {
                Invoke-Expression -Command "$($script:DSCResourceName)_Config -OutputPath `$TestEnvironment.WorkingFolder"
                Start-DscConfiguration -Path $TestEnvironment.WorkingFolder -ComputerName localhost -Wait -Verbose -Force
            } | Should not throw
        }

        It 'should be able to call Get-DscConfiguration without throwing' {
            { Get-DscConfiguration -Verbose -ErrorAction Stop } | Should Not throw
        }
        #endregion
    }

    Describe 'MSFT_xWebBindingInformation' {
        # Directly interacting with Cim classes is not supported by PowerShell DSC
        # it is being done here explicitly for the purpose of testing. Please do not
        # do this in actual resource code
        
        #TODO: Delete or Uncomment - Is this needed? PSScriptAnalyzer says it's never used.
        #$xWebBindingInforationClass = (Get-CimClass -Namespace 'root/microsoft/Windows/DesiredStateConfiguration' -ClassName 'MSFT_xWebBindingInformation')
        $storeNames = (Get-CimClass -Namespace 'root/microsoft/Windows/DesiredStateConfiguration' -ClassName 'MSFT_xWebBindingInformation').CimClassProperties['CertificateStoreName'].Qualifiers['Values'].Value

        foreach ($storeName in $storeNames)
        {
            It "Uses valid credential store: $storeName" {
                (Join-Path -Path Cert:\LocalMachine -ChildPath $storeName) | Should Exist
            }
        }
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
