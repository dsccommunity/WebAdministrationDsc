
$script:DSCModuleName = 'xWebAdministration'
$script:DSCResourceName = 'MSFT_xWebConfigProperty'

#region HEADER
$script:moduleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
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

Import-Module (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1') -Force
# Ensure the WebAdministration module is imported into the current session!
Import-Module WebAdministration -Force

$TestEnvironment = Initialize-TestEnvironment `
    -DSCModuleName $script:DSCModuleName `
    -DSCResourceName $script:DSCResourceName `
    -TestType Integration
#endregion

# Using try/finally to always cleanup.
try
{
    #region Integration Tests
    $configFile = Join-Path -Path $PSScriptRoot -ChildPath "$($script:DSCResourceName).config.ps1"
    . $configFile

    # Constants for Tests
    $websiteName = New-Guid
    $env:xWebConfigPropertyWebsitePath  = "IIS:\Sites\$($websiteName)"
    $env:xWebConfigPropertyFilter       = 'system.webServer/directoryBrowse'
    $env:xWebConfigPropertyPropertyName = 'enabled'

    Describe "$($script:DSCResourceName)_Integration" {
        # Ensure the WinRM service required by DSC is running.
        Get-Service -Name 'WinRM' | Where-Object { $_.Status -ne 'Running' } | Start-Service

        # Create the website we'll use for testing purposes.
        if (-not(Get-Website -Name $websiteName))
        {
            $websitePhysicalPath = "$($TestDrive)\$($websiteName)"
            New-Item -Path $websitePhysicalPath -ItemType Directory -Force | Out-Null
            New-Website -Name $websiteName -PhysicalPath $websitePhysicalPath | Out-Null
        }

        # Get the current value & either default or set it to the opposite of what it is already.
        $value = (Get-WebConfigurationProperty -PSPath $($env:xWebConfigPropertyWebsitePath) -Filter $($env:xWebConfigPropertyFilter) -Name $($env:xWebConfigPropertyPropertyName)).Value
        if ($null -ne $value)
        {
            $env:xWebConfigPropertyPropertyValueAdd = -not([bool]$value)
        }
        else
        {
            $env:xWebConfigPropertyPropertyValueAdd = $false
        }

        It 'Should compile and apply the MOF without throwing' {
            {
                Invoke-Expression -Command "$($script:DSCResourceName)_Add -OutputPath `$TestDrive"
                #& "$($script:DSCResourceName)_Add" -OutputPath $TestDrive
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

        It 'Should have the correct value of the configuration property' {
            # Get the new value.
            [string] $value = (Get-WebConfigurationProperty -PSPath $env:xWebConfigPropertyWebsitePath -Filter $env:xWebConfigPropertyFilter -Name $env:xWebConfigPropertyPropertyName).Value

            $value | Should -Be $env:xWebConfigPropertyPropertyValueAdd
        }

        It 'Should update the configuration property correctly' {
            {
                # Get the current value set it to the opposite of what it is already.
                $value = (Get-WebConfigurationProperty -PSPath $($env:xWebConfigPropertyWebsitePath) -Filter $($env:xWebConfigPropertyFilter) -Name $($env:xWebConfigPropertyPropertyName)).Value
                if ($null -ne $value)
                {
                    $env:xWebConfigPropertyPropertyValueUpdate = -not([bool]$value)
                }

                Invoke-Expression -Command "$($script:DSCResourceName)_Update -OutputPath `$TestDrive"
                Start-DscConfiguration -Path $TestDrive -ComputerName localhost -Wait -Verbose -Force
            } `
            | Should -Not -Throw

            # Get the new value.
            [string] $value = (Get-WebConfigurationProperty -PSPath $env:xWebConfigPropertyWebsitePath -Filter $env:xWebConfigPropertyFilter -Name $env:xWebConfigPropertyPropertyName).Value

            $value | Should -Be $env:xWebConfigPropertyPropertyValueUpdate
        }

        It 'Should remove configuration property' {
            {
                Invoke-Expression -Command "$($script:DSCResourceName)_Remove -OutputPath `$TestDrive"
                Start-DscConfiguration -Path $TestDrive -ComputerName localhost -Wait -Verbose -Force
            } `
            | Should -Not -Throw

            # Get the value.
            # Because configuration properties can be inherited (& I'm not aware of a reliable way to determine if the value returned is inherited or set explicitly),
            # we instead read the config file as XML directly & attempt to locate the property under test.

            $value = ([xml] ((Get-WebConfigFile -PSPath $env:xWebConfigPropertyWebsitePath) | Get-Content)).SelectSingleNode("//$($env:xWebConfigPropertyFilter)/@$($env:xWebConfigPropertyPropertyName)")

            $value | Should -Be $null
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
    if (Get-Module -Name 'MockWebAdministrationWindowsFeature')
    {
        Write-Information 'Removing MockWebAdministrationWindowsFeature module...'
        Remove-Module -Name 'MockWebAdministrationWindowsFeature'
    }
    $mocks = (Get-ChildItem Function:) | Where-Object { $_.Source -eq 'MockWebAdministrationWindowsFeature' }
    if ($mocks)
    {
        Write-Information 'Removing MockWebAdministrationWindowsFeature functions...'
        $mocks | Remove-Item
    }

    #region FOOTER
    Restore-TestEnvironment -TestEnvironment $TestEnvironment
    #endregion
}

