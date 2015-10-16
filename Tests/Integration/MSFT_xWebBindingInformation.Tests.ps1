# should check for the server OS
if($env:APPVEYOR_BUILD_VERSION)
{
     Add-WindowsFeature Web-Server -Verbose
}

$DSCModuleName   = 'xWebAdministration'

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

Import-Module -Name $(Get-Item -Path (Join-Path $moduleRoot -ChildPath 'xWebadministration.psd1')) -Force

# Displaying all versions of xWebAdministration to fix #42
if($env:APPVEYOR_BUILD_VERSION) {
    Get-DscResource -Module 'xWebAdministration' | fl
}

# Now that xWebAdministration should be discoverable load the configuration data
. "$PSScriptRoot\WebBindingInformation_Config.ps1"

Describe 'MSFT_xWebBindingInformation' {
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

        WebBindingInfo -OutputPath $env:temp\WebBindingInfo
        Start-DscConfiguration -Path $env:temp\WebBindingInfo -Wait -Verbose -ErrorAction Stop} | should not throw
    }

    # Directly interacting with Cim classes is not supported by PowerShell DSC
    # it is being done here explicitly for the purpose of testing. Please do not
    # do this in actual resource code
    $xWebBindingInforationClass = (Get-CimClass -Namespace 'root/microsoft/Windows/DesiredStateConfiguration' -ClassName 'MSFT_xWebBindingInformation')
    $storeNames = (Get-CimClass -Namespace 'root/microsoft/Windows/DesiredStateConfiguration' -ClassName 'MSFT_xWebBindingInformation').CimClassProperties['CertificateStoreName'].Qualifiers['Values'].Value
    foreach ($storeName in $storeNames){
        It "Uses valid credential store: $storeName" {
            (Join-Path -Path Cert:\LocalMachine -ChildPath $storeName) | Should Exist
        }
    }
}

# Cleanup after the test
Remove-Item -Path $moduleRoot -Recurse -Force
