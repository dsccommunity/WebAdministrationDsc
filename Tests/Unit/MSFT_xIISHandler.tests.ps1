$DSCModuleName      = 'xWebAdministration'
$DSCResourceName    = 'MSFT_xIISHandler'
$RelativeModulePath = "DSCResources\$DSCResourceName\$DSCResourceName.psm1"

#region HEADER
# Temp Working Folder - always gets remove on completion
$WorkingFolder = Join-Path -Path $env:Temp -ChildPath $DSCResourceName

# Copy to Program Files for WMF 4.0 Compatability as it can only find resources in a few known places.
$moduleRoot = "${env:ProgramFiles}\WindowsPowerShell\Modules\$DSCModuleName"

# If this module already exists in the Modules folder, make a copy of it in
# the temporary folder so that it isn't accidentally used in this test.
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


# Copy the module to be tested into the Module Root
Copy-Item -Path $PSScriptRoot\..\..\* -Destination $moduleRoot -Recurse -Force -Exclude '.git'

# Import the Module
$Splat = @{
    Path = $moduleRoot
    ChildPath = $RelativeModulePath
    Resolve = $true
    ErrorAction = 'Stop'
}
$DSCModuleFile = Get-Item -Path (Join-Path @Splat)

# Remove all copies of the module from memory so an old one is not used.
if (Get-Module -Name $DSCModuleFile.BaseName -All)
{
    Get-Module -Name $DSCModuleFile.BaseName -All | Remove-Module
}

# Import the Module to test.
Import-Module -Name $DSCModuleFile.FullName -Force

<#
  This is to fix a problem in AppVoyer where we have multiple copies of the resource
  in two different folders. This should probably be adjusted to be smarter about how
  it finds the resources.
#>
if (($env:PSModulePath).Split(';') -ccontains $pwd.Path)
{
    $script:tempPath = $env:PSModulePath
    $env:PSModulePath = ($env:PSModulePath -split ';' | Where-Object {$_ -ne $pwd.path}) -join ';'
}

# Preserve and set the execution policy so that the DSC MOF can be created
$executionPolicy = Get-ExecutionPolicy
if ($executionPolicy -ne 'Unrestricted')
{
    Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Force
    $rollbackExecution = $true
}
#endregion

# Begin Testing
try
{

    #region Pester Tests

    InModuleScope $DSCResourceName {

        #region Function Get-TargetResource
        Describe 'MSFT_xIISHandler\Get-TargetResource' {
            Context 'Ensure = Absent and Handler is not Present' {
                Mock Assert-Module
                Mock Get-Handler

                It 'Should return the right hashtable' {
                    $result = Get-TargetResource -Name 'StaticFile' -Ensure 'Absent'
                    $result.Ensure | Should Be 'Absent'
                    $result.Name   | Should Be 'StaticFile'
                }
            }
            Context 'Ensure = Present and Handler is Present' {
                Mock Assert-Module
                Mock Get-Handler {'Present'}

                It 'Should return the right hashtable' {
                    $result = Get-TargetResource -Name 'StaticFile' -Ensure 'Present'
                    $result.Ensure | Should Be 'Present'
                    $result.Name   | Should Be 'StaticFile'
                }
            }
        }
        #endregion


        #region Function Test-TargetResource
        Describe 'MSFT_xIISHandler\Test-TargetResource' {
            $Name = 'StaticFile'

            Context 'Handler is NULL and Ensure = Present' {
                Mock Assert-Module
                Mock Get-Handler

                $result = Test-TargetResource -Name $Name -Ensure 'Present' -Verbose *>&1
                It 'Should return False' {
                    $result[0] | Should Be $false
                }

                It 'Should not return a verbose message' {
                    $result[1] | Should Be $null
                }
            }

            Context 'Handler is Present and Ensure = Present' {
                Mock Assert-Module
                Mock Get-Handler {'Present'}

                $result = Test-TargetResource -Name $Name -Ensure 'Present' -Verbose *>&1

                It 'Should return the correct verbose message' {
                    $result[0] | Should Be ($LocalizedData.HandlerExists -f $Name)
                }

                It 'Should return False' {
                    $result[1] | Should Be $true
                }
            }

            Context 'Handler is Present and Ensure = Absent' {
                Mock Assert-Module
                Mock Get-Handler {'Present'}

                $result = Test-TargetResource -Name $Name -Ensure 'Absent' -Verbose *>&1
                It 'Should return False' {
                    $result[0] | Should Be $false
                }

                It 'Should not return a verbose message' {
                    $result[1] | Should Be $null
                }
            }

            Context 'Handler is Present and Ensure = Present' {
                Mock Assert-Module
                Mock Get-Handler

                $result = Test-TargetResource -Name $Name -Ensure 'Absent' -Verbose *>&1

                It 'Should return the correct verbose message' {
                    $result[0] | Should Be ($LocalizedData.HandlerNotPresent -f $Name)
                }

                It 'Should return False' {
                    $result[1] | Should Be $true
                }
            }
        }
        #endregion


        #region Function Set-TargetResource
        Describe 'MSFT_xIISHandler\Set-TargetResource' {
            Context 'Ensure = Present and Handler is NOT present' {
                $mockName = 'StaticFile'
                Mock Assert-Module
                Mock Get-Handler
                Mock Add-Handler {} -ParameterFilter {$Name -eq $mockName}

                $message = Set-TargetResource -Name $mockName -Ensure 'Present' -Verbose 4>&1

                It 'Should add the handler' {
                    Assert-MockCalled Add-Handler -ParameterFilter {$Name -eq $mockName}
                }

                It 'Should call the right Verbose Message' {
                    $message | Should Be ($LocalizedData.AddingHandler -f $mockName)
                }
            }

            Context 'Ensure = Absent and Handler IS present' {
                $mockName = 'StaticFile'
                Mock Assert-Module
                Mock Get-Handler {'Present'}
                Mock Remove-WebConfigurationProperty

                $message = Set-TargetResource -Name $mockName -Ensure 'Absent' -Verbose 4>&1

                It 'Should add the handler' {
                    Assert-MockCalled Remove-WebConfigurationProperty
                }

                It 'Should call the right Verbose Message' {
                    $message | Should Be ($LocalizedData.RemovingHandler -f $mockName)
                }
            }
        }
        #endregion

        Describe 'MSFT_xIISHandler\Add-Handler' {
            Context 'Should find all the handlers' {
                foreach ($key in $script:handlers.keys)
                {
                    Mock Add-WebConfigurationProperty {} -ParameterFilter {$Value -and $Value -eq $script:handlers[$key]}

                    Add-Handler -Name $key
                    It "Should find $key in `$script:handler" {
                        Assert-MockCalled Add-WebConfigurationProperty -Exactly 1 -ParameterFilter {$Value -and $Value -eq $script:handlers[$key]}
                    }
                }
            }

            Context 'It should throw when it cannot find the handler' {
                It 'Should throw an error' {
                    $keyName = 'Non-ExistantKey'
                    {Add-Handler -Name $keyName} | Should throw ($LocalizedData.HandlerNotSupported -f $KeyName)
                }
            }
        }

        Describe 'MSFT_xIISHandler\Get-Handler' {
            It 'Should call the mocks' {
                $name = 'StaticFile'
                $mockFilter = "system.webServer/handlers/Add[@Name='" + $name + "']"
                Mock Get-WebConfigurationProperty {} -ParameterFilter {$Filter -and $Filter -eq $mockFilter}
                Get-Handler -Name $Name
                Assert-MockCalled Get-WebConfigurationProperty
            }
        }
    }
    #endregion
}
finally
{
    #region FOOTER
    # Set PSModulePath back to previous settings
    if ($script:tempPath)
    {
        $env:PSModulePath = $script:tempPath;
    }

    # Restore the Execution Policy
    if ($rollbackExecution)
    {
        Set-ExecutionPolicy -ExecutionPolicy $executionPolicy -Force
    }

    # Cleanup Working Folder
    if (Test-Path -Path $WorkingFolder)
    {
        Remove-Item -Path $WorkingFolder -Recurse -Force
    }

    # Clean up after the test completes.
    Remove-Item -Path $moduleRoot -Recurse -Force

    # Restore previous versions, if it exists.
    if ($tempLocation)
    {
        $null = New-Item -Path $moduleRoot -ItemType Directory
        Copy-Item -Path $tempLocation -Destination "${env:ProgramFiles}\WindowsPowerShell\Modules" -Recurse -Force
        Remove-Item -Path $tempLocation -Recurse -Force
    }
    #endregion

    # TODO: Other Optional Cleanup Code Goes Here...
}
