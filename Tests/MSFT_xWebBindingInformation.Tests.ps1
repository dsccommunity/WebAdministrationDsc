$here = Split-Path -Parent $MyInvocation.MyCommand.Path

# should check for the server OS
if($env:APPVEYOR_BUILD_VERSION)
{
  Add-WindowsFeature Web-Server -Verbose
}

Import-Module (Join-Path $here -ChildPath "..\DSCResources\MSFT_xWebsite\MSFT_xWebsite.psm1")

Describe "MSFT_xWebBindingInformation" {
    It 'Should be able to get xWebsite' -test {
        # just a good idea.  
        # I thought it might force the classes to register, but it does not.
        $resources = Get-DscResource -Name xWebsite
        $resources.count | should be 1
    }

    It 'Should compile and run without throwing' -test {
        {
        # Force Cim Classes to register
        # Update the system environment path so that LCM will load the module
        # Requires WMF 5
        [System.Environment]::SetEnvironmentVariable('PSModulePath',$env:PSModulePath,[System.EnvironmentVariableTarget]::Machine)
        configuration foo
        {
            Import-DscResource -ModuleName xWebAdministration

            xWebsite foo
            {
                Name = 'foobar'
                Ensure = 'absent'
                PhysicalPath = "$env:temp\foo"
            }
        }

        foo -OutputPath $env:temp\foo
        Start-DscConfiguration -Path $env:temp\foo -Wait -Verbose -ErrorAction Stop} | should not throw
    }
    
    # Directly interacting with Cim classes is not supported by PowerShell DSC
    # it is being done here explicitly for the purpose of testing. Please do not
    # do this in actual resource code
    $xWebBindingInforationClass = (Get-CimClass -Namespace "root/microsoft/Windows/DesiredStateConfiguration" -ClassName "MSFT_xWebBindingInformation")
    $storeNames = (Get-CimClass -Namespace "root/microsoft/Windows/DesiredStateConfiguration" -ClassName "MSFT_xWebBindingInformation").CimClassProperties['CertificateStoreName'].Qualifiers['Values'].Value
    foreach ($storeName in $storeNames){
        It "Uses valid credential store: $storeName" {
            (Join-Path -Path Cert:\LocalMachine -ChildPath $storeName) | Should Exist
        }
    }
}
