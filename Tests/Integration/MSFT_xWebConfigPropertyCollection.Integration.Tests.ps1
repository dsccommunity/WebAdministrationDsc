
$script:dscModuleName = 'xWebAdministration'
$script:dscResourceFriendlyName = 'xWebConfigPropertyCollection'
$script:dscResourceName = "MSFT_$($script:dscResourceFriendlyName)"

#region HEADER
# Integration Test Template Version: 1.3.0
[String] $script:moduleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
if ( (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests'))) -or `
      (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1'))) )
{
    if (Test-Path -Path (Join-Path -Path $moduleRoot -ChildPath 'DSCResource.Tests.zip'))
    {
        Expand-Archive -Path (Join-Path -Path $moduleRoot -ChildPath 'DSCResource.Tests.zip') -DestinationPath (Join-Path -Path $moduleRoot -ChildPath 'DSCResource.Tests') -Force
    }
    else
    {
        & git @('clone','https://github.com/PowerShell/DscResource.Tests.git',(Join-Path -Path $moduleRoot -ChildPath '\DSCResource.Tests\'))
    }
}

Import-Module -Name (Join-Path -Path $script:moduleRoot -ChildPath (Join-Path -Path 'DSCResource.Tests' -ChildPath 'TestHelper.psm1')) -Force
# Ensure the WebAdministration module is imported into the current session!
Import-Module WebAdministration -Force
$TestEnvironment = Initialize-TestEnvironment `
    -DSCModuleName $script:dscModuleName `
    -DSCResourceName $script:dscResourceName `
    -TestType Integration
#endregion

[string] $tempName = "$($script:dscResourceName)_" + (Get-Date).ToString('yyyyMMdd_HHmmss')

# Using try/finally to always cleanup.
try
{
    #region Integration Tests
    $configurationFile = Join-Path -Path $PSScriptRoot -ChildPath "$($script:dscResourceName).config.ps1"
    . $configurationFile

    $null = Backup-WebConfiguration -Name $tempName

    # Constants for Tests
    $websiteName = New-Guid
    $env:xWebConfigPropertyCollectionWebsitePath      = "IIS:\Sites\$($websiteName)"
    $env:xWebConfigPropertyCollectionFilter           = '.'
    $env:xWebConfigPropertyCollectionCollectionName   = 'appSettings'
    $env:xWebConfigPropertyCollectionItemName         = 'add'
    $env:xWebConfigPropertyCollectionItemKeyName      = 'key'
    $env:xWebConfigPropertyCollectionItemKeyValue     = $script:dscResourceName
    $env:xWebConfigPropertyCollectionItemPropertyName = 'value'

    Describe "$($script:dscResourceName)_Integration" {
        # Ensure the WinRM service required by DSC is running.
        Get-Service -Name 'WinRM' | Where-Object { $_.Status -ne 'Running' } | Start-Service

        # Create the website we'll use for testing purposes.
        if (-not(Get-Website -Name $websiteName))
        {
            $websitePhysicalPath = "$($TestDrive)\$($websiteName)"
            New-Item -Path $websitePhysicalPath -ItemType Directory -Force | Out-Null
            New-Website -Name $websiteName -PhysicalPath $websitePhysicalPath | Out-Null
        }

        $filter = "$($env:xWebConfigPropertyCollectionFilter)/$($env:xWebConfigPropertyCollectionCollectionName)/$($env:xWebConfigPropertyCollectionItemName)[@$($env:xWebConfigPropertyCollectionItemKeyName)='$($env:xWebConfigPropertyCollectionItemKeyValue)']/@value"

        It 'Should compile and apply the MOF without throwing' {
            {
                $env:xWebConfigPropertyCollectionItemPropertyValueAdd = 'ADD'

                Invoke-Expression -Command "$($script:dscResourceName)_Add -OutputPath `$TestDrive"
                Start-DscConfiguration -Path $TestDrive -ComputerName localhost -Wait -Verbose -Force
            } `
            | Should -Not -Throw
        }

        It 'Should be able to call Get-DscConfiguration without throwing' {
            {
                Get-DscConfiguration -Verbose -ErrorAction Stop
            } `
            | Should -Not -Throw
        }

        It 'Should have the correct value of the configuration property collection item' {
            # Get the new value.
            [string] $value = (Get-WebConfigurationProperty -PSPath $env:xWebConfigPropertyCollectionWebsitePath -Filter $filter -Name "." -ErrorAction SilentlyContinue).Value

            $value | Should -Be $env:xWebConfigPropertyCollectionItemPropertyValueAdd
        }

        It 'Should update the configuration property collection item correctly' {
            {
                $env:xWebConfigPropertyCollectionItemPropertyValueUpdate = 'UPDATE'

                Invoke-Expression -Command "$($script:dscResourceName)_Update -OutputPath `$TestDrive"
                Start-DscConfiguration -Path $TestDrive -ComputerName localhost -Wait -Verbose -Force
            } `
            | Should -Not -Throw

            # Get the new value.
            [string] $value = (Get-WebConfigurationProperty -PSPath $env:xWebConfigPropertyCollectionWebsitePath -Filter $filter -Name "." -ErrorAction SilentlyContinue).Value

            $value | Should -Be $env:xWebConfigPropertyCollectionItemPropertyValueUpdate
        }

        It 'Should remove configuration property' {
            {
                Invoke-Expression -Command "$($script:dscResourceName)_Remove -OutputPath `$TestDrive"
                Start-DscConfiguration -Path $TestDrive -ComputerName localhost -Wait -Verbose -Force
            } `
            | Should -Not -Throw

            # Get the value.
            [string] $value = (Get-WebConfigurationProperty -PSPath $env:xWebConfigPropertyCollectionWebsitePath -Filter $filter -Name "." -ErrorAction SilentlyContinue).Value

            $value | Should -BeNullOrEmpty
        }

        # Remove the website we created for testing purposes.
        if (Get-Website -Name $websiteName)
        {
            Remove-Website -Name $websiteName
            Remove-Item -Path $websitePhysicalPath -Force -Recurse
        }
    }
    #endregion
}
finally
{
    #region FOOTER
    Restore-WebConfiguration -Name $tempName
    Remove-WebConfigurationBackup -Name $tempName

    Restore-TestEnvironment -TestEnvironment $TestEnvironment
    #endregion
}

