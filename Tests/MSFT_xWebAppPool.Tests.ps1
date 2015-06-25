$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$ModuleName = "MSFT_xWebAppPool"

# Add web server if not already installed
if(!(Get-WindowsFeature web-server).Installed)
{
  Add-WindowsFeature Web-Server -Verbose
}

Import-Module (Join-Path $here -ChildPath "..\DSCResources\$ModuleName\$ModuleName.psm1")

if (! (Get-Module xDSCResourceDesigner))
{
    Import-Module -Name xDSCResourceDesigner
}

if (! (Get-Module WebAdministration))
{
    Import-Module -Name WebAdministration
}

Describe "MSFT_xWebAppPool"{
    InModuleScope $ModuleName {
        $apName = "PesterAppPool"

        It 'Should pass Test-xDscResource Schema Validation' {
            $result = Test-xDscResource MSFT_xWebAppPool
            $result | Should Be $true
        }

        It 'Should create a new App Pool' {           
            $testParams =@{
                Name = $apName
                Ensure = "Present"
            }

            # if the app pool exists, remove it
            if((Get-ChildItem IIS:\apppools).Name.Contains($apName))
            {
                Remove-WebAppPool -Name $apName -ErrorAction Stop
            }
            
            Set-TargetResource @testParams
            (Get-ChildItem IIS:\apppools).Name.Contains($apName) | Should be $true
        }

        It 'Passes test when App Pool does exist'{
            $testParams =@{
                Name = $apName
                Ensure = "Present"
            }

            Mock -ModuleName $ModuleName Get-TargetResource { 
                return @{ 
                    Name = $testParams.Name
                    Ensure = $testParams.Ensure
                }
            }

            Test-TargetResource @testParams | Should be $true
        }

        It 'Fails test when App Pool does not exist'{
            $testParams =@{
                Name = $apName
                Ensure = "Present"
            }

            # if the app pool exists, remove it
            if((Get-ChildItem IIS:\apppools).Name.Contains($apName))
            {
                Remove-WebAppPool -Name $apName -ErrorAction Stop
            }

            Test-TargetResource @testParams | Should be $false
        }
    }
}