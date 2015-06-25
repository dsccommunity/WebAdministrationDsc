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
        try
        {
            $apName = "PesterAppPool"
            $baseParams =@{
                Name = $apName
                Ensure = "Present"
            }

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

                Test-TargetResource @testParams | Should be $true
            }

            It 'Should set autoStart' {
                $testParams =@{
                    Name = $apName
                    Ensure = "Present"
                    autoStart = "false"
                }

                if(!([xml](& $env:SystemRoot\system32\inetsrv\appcmd.exe list apppool $apName /config:*)).add.autoStart)
                {
                    $testParams.autoStart = "true"
                }

                Set-TargetResource @testParams
                ([xml](& $env:SystemRoot\system32\inetsrv\appcmd.exe list apppool $apName /config:*)).add.autoStart -eq $testParams.autoStart | Should be $true
            }

            It 'Passes autoStart Test when same' {
                $testParams =@{
                    Name = $apName
                    Ensure = "Present"
                    autoStart = "false"
                }

                if(([xml](& $env:SystemRoot\system32\inetsrv\appcmd.exe list apppool $apName /config:*)).add.autoStart -eq "true")
                {
                    $testParams.autoStart = "true"
                }

                Test-TargetResource @testParams | Should be $true
            }

            It 'Fails autoStart Test when different' {
                $testParams =@{
                    Name = $apName
                    Ensure = "Present"
                    autoStart = "false"
                }

                if(([xml](& $env:SystemRoot\system32\inetsrv\appcmd.exe list apppool $apName /config:*)).add.autoStart -eq "false")
                {
                    $testParams.autoStart = "true"
                }

                Test-TargetResource @testParams | Should be $false
            }
            
            Set-TargetResource @baseParams #need to remove after each test set so previous tests don't affect the next tests

            It 'Should set Runtime Version' {
                $testParams =@{
                    Name = $apName
                    Ensure = "Present"
                    managedRuntimeVersion = "v2.0"
                }

                if(([xml](& $env:SystemRoot\system32\inetsrv\appcmd.exe list apppool $apName /config:*)).add.managedRuntimeVersion -eq "v2.0")
                {
                    $testParams.managedRuntimeVersion = "v4.0"
                }

                Set-TargetResource @testParams
                ([xml](& $env:SystemRoot\system32\inetsrv\appcmd.exe list apppool $apName /config:*)).add.managedRuntimeVersion -eq $testParams.managedRuntimeVersion | Should be $true
            }

            It 'Passes Runtime Version Test when same' {
                $testParams =@{
                    Name = $apName
                    Ensure = "Present"
                    managedRuntimeVersion = "v2.0"
                }

                if(([xml](& $env:SystemRoot\system32\inetsrv\appcmd.exe list apppool $apName /config:*)).add.managedRuntimeVersion -eq "v4.0")
                {
                    $testParams.managedRuntimeVersion = "v4.0"
                }

                Test-TargetResource @testParams | Should be $true
            }

            It 'Fails Runtime Version Test when different' {
                $testParams =@{
                    Name = $apName
                    Ensure = "Present"
                    managedRuntimeVersion = "v2.0"
                }

                if(([xml](& $env:SystemRoot\system32\inetsrv\appcmd.exe list apppool $apName /config:*)).add.managedRuntimeVersion -eq "v2.0")
                {
                    $testParams.managedRuntimeVersion = "v4.0"
                }

                Test-TargetResource @testParams | Should be $false
            }
            
            Set-TargetResource @baseParams #need to remove after each test set so previous tests don't affect the next tests
            
            It 'Should set Managed Pipeline Mode Version' {
                $testParams =@{
                    Name = $apName
                    Ensure = "Present"
                    managedPipelineMode = "Classic"
                }

                if(([xml](& $env:SystemRoot\system32\inetsrv\appcmd.exe list apppool $apName /config:*)).add.managedPipelineMode -eq "Classic")
                {
                    $testParams.managedPipelineMode = "Integrated"
                }

                Set-TargetResource @testParams
                ([xml](& $env:SystemRoot\system32\inetsrv\appcmd.exe list apppool $apName /config:*)).add.managedPipelineMode -eq $testParams.managedPipelineMode | Should be $true
            }

            It 'Passes Managed Pipeline Mode  Test when same' {
                $testParams =@{
                    Name = $apName
                    Ensure = "Present"
                    managedPipelineMode = "Classic"
                }

                if(([xml](& $env:SystemRoot\system32\inetsrv\appcmd.exe list apppool $apName /config:*)).add.managedPipelineMode -eq "Integrated")
                {
                    $testParams.managedPipelineMode = "Integrated"
                }

                Test-TargetResource @testParams | Should be $true
            }

            It 'Fails Managed Pipeline Mode Test when different' {
                $testParams =@{
                    Name = $apName
                    Ensure = "Present"
                    managedPipelineMode = "Classic"
                }

                if(([xml](& $env:SystemRoot\system32\inetsrv\appcmd.exe list apppool $apName /config:*)).add.managedPipelineMode -eq "Classic")
                {
                    $testParams.managedPipelineMode = "Integrated"
                }

                Test-TargetResource @testParams | Should be $false
            }
            
            Set-TargetResource @baseParams #need to remove after each test set so previous tests don't affect the next tests

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
        finally
        {
            # if the app pool exists, remove it
            if((Get-ChildItem IIS:\apppools).Name.Contains($apName))
            {
                Remove-WebAppPool -Name $apName -ErrorAction Stop
            }
        }
    }
}
