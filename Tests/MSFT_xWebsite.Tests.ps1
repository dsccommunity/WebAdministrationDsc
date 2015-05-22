<# 
.summary
    Test suite for MSFT_xDhcpServerOption.psm1
    These tests require RSAT on client.
    On 8.1 it's found here: http://www.microsoft.com/en-us/download/confirmation.aspx?id=39296&6B49FDFB-8E5B-4B07-BC31-15695C5A2143=1
#>
[CmdletBinding()]
param()

$global:WebsiteCertificateTest=$true
Import-Module $PSScriptRoot\..\DSCResources\MSFT_xWebsite\MSFT_xWebsite.psm1

$ErrorActionPreference = 'stop'
Set-StrictMode -Version latest

$personalCert = Get-PfxCertificate $PSScriptRoot\personal.pfx
$webhostCert = Get-PfxCertificate $PSScriptRoot\webhosting.pfx

$testsitePhyicalPath = "C:\inetpub\test"

# should check for the server OS
if($env:APPVEYOR_BUILD_VERSION)
{
    Add-WindowsFeature Web-Server -verbose
}

function Suite.BeforeAll {
    # Remove any leftovers from previous test runs
    Suite.AfterAll
}

function Suite.AfterAll {
    Remove-Module MSFT_xWebsite
    $global:WebsiteCertificateTest=$null
    $personalCertPath = (Join-Path Cert:\LocalMachine\Personal\ -ChildPath $personalCert.Thumbprint)
    $webhostCertPath = (Join-Path Cert:\LocalMachine\WebHosting\ -ChildPath $personalCert.Thumbprint)
    if (Test-Path $personalCertPath){
        Remove-Item $personalCertPath
    }
    if (Test-Path $webhostCertPath){
        Remove-Item $webhostCertPath
    }
}

try
{
    Describe 'Validate-ResourceProperties' {
        AfterEach {
            Remove-Website -Name "TestWebSite"
            if (Test-Path $testsitePhyicalPath) {
                Remove-Item $testsitePhyicalPath
            }
        }
        It 'Binds to the correct web hosting certificate' {
            if (-Not (Test-Path $testsitePhyicalPath)){
                New-Item $testsitePhyicalPath -ItemType Directory
            }
            Import-PfxCertificate -FilePath $PSScriptRoot\webhosting.pfx -CertStoreLocation Cert:\LocalMachine\WebHosting
            $testSite = @{
                        "Name" = "TestWebSite";
                        "Ensure" = "Present";
                        "State" = "Started";
                        "PhysicalPath" = $testsitePhyicalPath;
                        "ApplicationPool" = "DefaultAppPool";
                        "BindingInfo" = @(New-CimInstance -ClassName MSFT_xWebBindingInformation -Namespace root/microsoft/Windows/DesiredStateConfiguration -Property @{
                                            Protocol = "https";
                                            IPAddress = "*";
                                            Port = 11443;
                                            HostName = "localhost";
                                            CertificateThumbprint = $webhostCert.Thumbprint;
                                            CertificateStoreName = "WebHosting"} -ClientOnly);
                        "DefaultPage" = "index.htm"
                        }
            Set-TargetResource @testSite -Debug

            Test-TargetResource @testSite | Should Be "True"
        }
        It 'Binds to the correct personal certificate' {
            if (-Not (Test-Path $testsitePhyicalPath)){
                New-Item $testsitePhyicalPath -ItemType Directory
            }
            Import-PfxCertificate -FilePath $PSScriptRoot\personal.pfx -CertStoreLocation Cert:\LocalMachine\Personal
            $testSite = @{
                        "Name" = "TestWebSite";
                        "Ensure" = "Present";
                        "State" = "Started";
                        "PhysicalPath" = $testsitePhyicalPath;
                        "ApplicationPool" = "DefaultAppPool";
                        "BindingInfo" = @(New-CimInstance -ClassName MSFT_xWebBindingInformation -Namespace root/microsoft/Windows/DesiredStateConfiguration -Property @{
                                            Protocol = "https";
                                            IPAddress = "*";
                                            Port = 11443;
                                            HostName = "localhost";
                                            CertificateThumbprint = $personalCert.Thumbprint;
                                            CertificateStoreName = "Personal"} -ClientOnly);
                        "DefaultPage" = "index.htm"
                        }
            Set-TargetResource @testSite

            Test-TargetResource @testSite | Should Be "True"
        }
    }


}
finally
{
    Suite.AfterAll
}


