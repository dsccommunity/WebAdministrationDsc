$here = Split-Path -Parent $MyInvocation.MyCommand.Path

# should check for the server OS
if($env:APPVEYOR_BUILD_VERSION)
{
  Add-WindowsFeature Web-Server -Verbose
}

Import-Module (Join-Path $here -ChildPath "..\DSCResources\MSFT_xWebsite\MSFT_xWebsite.psm1")

Describe "MSFT_xWebBindingInformation" {
    $storeNames = (Get-CimClass -Namespace "root/microsoft/Windows/DesiredStateConfiguration" -ClassName "MSFT_xWebBindingInformation").CimClassProperties['CertificateStoreName'].Qualifiers['Values'].Value
    foreach ($storeName in $storeNames){
        It "Uses valid credential store: $storeName" {
            (Join-Path -Path Cert:\LocalMachine -ChildPath $storeName) | Should Exist
        }
    }
}
