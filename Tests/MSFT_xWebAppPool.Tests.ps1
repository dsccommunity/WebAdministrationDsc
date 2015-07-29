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
            
            It 'Should set Start Mode' {
                $testParams =@{
                    Name = $apName
                    Ensure = "Present"
                    startMode = "OnDemand"
                }

                if(([xml](& $env:SystemRoot\system32\inetsrv\appcmd.exe list apppool $apName /config:*)).add.startMode -eq "OnDemand")
                {
                    $testParams.startMode = "AlwaysRunning"
                }

                Set-TargetResource @testParams
                ([xml](& $env:SystemRoot\system32\inetsrv\appcmd.exe list apppool $apName /config:*)).add.startMode -eq $testParams.startMode | Should be $true
            }

            It 'Passes Start Mode Test when same' {
                $testParams =@{
                    Name = $apName
                    Ensure = "Present"
                    startMode = "OnDemand"
                }

                if(([xml](& $env:SystemRoot\system32\inetsrv\appcmd.exe list apppool $apName /config:*)).add.startMode -eq "AlwaysRunning")
                {
                    $testParams.startMode = "AlwaysRunning"
                }

                Test-TargetResource @testParams | Should be $true
            }

            It 'Fails Start Mode Test when different' {
                $testParams =@{
                    Name = $apName
                    Ensure = "Present"
                    startMode = "OnDemand"
                }

                if(([xml](& $env:SystemRoot\system32\inetsrv\appcmd.exe list apppool $apName /config:*)).add.startMode -eq "OnDemand")
                {
                    $testParams.startMode = "AlwaysRunning"
                }

                Test-TargetResource @testParams | Should be $false
            }
            
            Set-TargetResource @baseParams #need to remove after each test set so previous tests don't affect the next tests
            
            It 'Should set Identity Type' {
                $testParams =@{
                    Name = $apName
                    Ensure = "Present"
                    identityType = "LocalSystem"
                }

                if(([xml](& $env:SystemRoot\system32\inetsrv\appcmd.exe list apppool $apName /config:*)).add.processModel.identityType -eq "LocalSystem")
                {
                    $testParams.identityType = "ApplicationPoolIdentity"
                }

                Set-TargetResource @testParams
                ([xml](& $env:SystemRoot\system32\inetsrv\appcmd.exe list apppool $apName /config:*)).add.processModel.identityType -eq $testParams.identityType | Should be $true
            }

            It 'Passes Identity Type Test when same' {
                $testParams =@{
                    Name = $apName
                    Ensure = "Present"
                    identityType = "LocalSystem"
                }

                if(([xml](& $env:SystemRoot\system32\inetsrv\appcmd.exe list apppool $apName /config:*)).add.processModel.identityType -eq "ApplicationPoolIdentity")
                {
                    $testParams.identityType = "ApplicationPoolIdentity"
                }

                Test-TargetResource @testParams | Should be $true
            }

            It 'Fails Identity Type Test when different' {
                $testParams =@{
                    Name = $apName
                    Ensure = "Present"
                    identityType = "LocalSystem"
                }

                if(([xml](& $env:SystemRoot\system32\inetsrv\appcmd.exe list apppool $apName /config:*)).add.processModel.identityType -eq "LocalSystem")
                {
                    $testParams.identityType = "ApplicationPoolIdentity"
                }

                Test-TargetResource @testParams | Should be $false
            }
            
            Set-TargetResource @baseParams #need to remove after each test set so previous tests don't affect the next tests
            
            It 'Should set Load User Profile' {
                $testParams =@{
                    Name = $apName
                    Ensure = "Present"
                    loadUserProfile = "false"
                }

                if(([xml](& $env:SystemRoot\system32\inetsrv\appcmd.exe list apppool $apName /config:*)).add.processModel.loadUserProfile -eq "false")
                {
                    $testParams.loadUserProfile = "true"
                }

                Set-TargetResource @testParams
                ([xml](& $env:SystemRoot\system32\inetsrv\appcmd.exe list apppool $apName /config:*)).add.processModel.loadUserProfile -eq $testParams.loadUserProfile | Should be $true
            }

            It 'Passes Load User Profile Test when same' {
                $testParams =@{
                    Name = $apName
                    Ensure = "Present"
                    loadUserProfile = "false"
                }

                if(([xml](& $env:SystemRoot\system32\inetsrv\appcmd.exe list apppool $apName /config:*)).add.processModel.loadUserProfile -eq "true")
                {
                    $testParams.loadUserProfile = "true"
                }

                Test-TargetResource @testParams | Should be $true
            }

            It 'Fails Load User Profile Test when different' {
                $testParams =@{
                    Name = $apName
                    Ensure = "Present"
                    loadUserProfile = "false"
                }

                if(([xml](& $env:SystemRoot\system32\inetsrv\appcmd.exe list apppool $apName /config:*)).add.processModel.loadUserProfile -eq "false")
                {
                    $testParams.loadUserProfile = "true"
                }

                Test-TargetResource @testParams | Should be $false
            }

            Set-TargetResource @baseParams #need to remove after each test set so previous tests don't affect the next tests
            
            It 'Should set Queue Length' {
                $testParams =@{
                    Name = $apName
                    Ensure = "Present"
                    queueLength = "2000"
                }

                if(([xml](& $env:SystemRoot\system32\inetsrv\appcmd.exe list apppool $apName /config:*)).add.queueLength -eq "2000")
                {
                    $testParams.loadUserProfile = "1000"
                }

                Set-TargetResource @testParams
                ([xml](& $env:SystemRoot\system32\inetsrv\appcmd.exe list apppool $apName /config:*)).add.queueLength -eq $testParams.queueLength | Should be $true
            }

            It 'Passes Queue Length Test when same' {
                $testParams =@{
                    Name = $apName
                    Ensure = "Present"
                    queueLength = "2000"
                }

                if(([xml](& $env:SystemRoot\system32\inetsrv\appcmd.exe list apppool $apName /config:*)).add.queueLength -eq "1000")
                {
                    $testParams.queueLength = "1000"
                }

                Test-TargetResource @testParams | Should be $true
            }

            It 'Fails Queue Length Test when different' {
                $testParams =@{
                    Name = $apName
                    Ensure = "Present"
                    queueLength = "2000"
                }

                if(([xml](& $env:SystemRoot\system32\inetsrv\appcmd.exe list apppool $apName /config:*)).add.queueLength -eq "2000")
                {
                    $testParams.queueLength = "1000"
                }

                Test-TargetResource @testParams | Should be $false
            }

            Set-TargetResource @baseParams #need to remove after each test set so previous tests don't affect the next tests
            
            It 'Should set Enable 32bit' {
                $testParams =@{
                    Name = $apName
                    Ensure = "Present"
                    enable32BitAppOnWin64 = "true"
                }

                if(([xml](& $env:SystemRoot\system32\inetsrv\appcmd.exe list apppool $apName /config:*)).add.enable32BitAppOnWin64 -eq "true")
                {
                    $testParams.enable32BitAppOnWin64 = "false"
                }

                Set-TargetResource @testParams
                ([xml](& $env:SystemRoot\system32\inetsrv\appcmd.exe list apppool $apName /config:*)).add.enable32BitAppOnWin64 -eq $testParams.enable32BitAppOnWin64 | Should be $true
            }

            It 'Passes Enable 32bit Test when same' {
                $testParams =@{
                    Name = $apName
                    Ensure = "Present"
                    enable32BitAppOnWin64 = "true"
                }

                if(([xml](& $env:SystemRoot\system32\inetsrv\appcmd.exe list apppool $apName /config:*)).add.enable32BitAppOnWin64 -eq "false")
                {
                    $testParams.enable32BitAppOnWin64 = "false"
                }

                Test-TargetResource @testParams | Should be $true
            }

            It 'Fails Enable 32bit Test when different' {
                $testParams =@{
                    Name = $apName
                    Ensure = "Present"
                    enable32BitAppOnWin64 = "true"
                }

                if(([xml](& $env:SystemRoot\system32\inetsrv\appcmd.exe list apppool $apName /config:*)).add.enable32BitAppOnWin64 -eq "true")
                {
                    $testParams.enable32BitAppOnWin64 = "false"
                }

                Test-TargetResource @testParams | Should be $false
            }

            Set-TargetResource @baseParams #need to remove after each test set so previous tests don't affect the next tests
            
            It 'Should set Config Override' {
                $testParams =@{
                    Name = $apName
                    Ensure = "Present"
                    enableConfigurationOverride = "true"
                }

                if(([xml](& $env:SystemRoot\system32\inetsrv\appcmd.exe list apppool $apName /config:*)).add.enableConfigurationOverride -eq "true")
                {
                    $testParams.enableConfigurationOverride = "false"
                }

                Set-TargetResource @testParams
                ([xml](& $env:SystemRoot\system32\inetsrv\appcmd.exe list apppool $apName /config:*)).add.enableConfigurationOverride -eq $testParams.enableConfigurationOverride | Should be $true
            }

            It 'Passes Config Override Test when same' {
                $testParams =@{
                    Name = $apName
                    Ensure = "Present"
                    enableConfigurationOverride = "true"
                }

                if(([xml](& $env:SystemRoot\system32\inetsrv\appcmd.exe list apppool $apName /config:*)).add.enableConfigurationOverride -eq "false")
                {
                    $testParams.enableConfigurationOverride = "false"
                }

                Test-TargetResource @testParams | Should be $true
            }

            It 'Fails Config Override Test when different' {
                $testParams =@{
                    Name = $apName
                    Ensure = "Present"
                    enableConfigurationOverride = "true"
                }

                if(([xml](& $env:SystemRoot\system32\inetsrv\appcmd.exe list apppool $apName /config:*)).add.enableConfigurationOverride -eq "true")
                {
                    $testParams.enableConfigurationOverride = "false"
                }

                Test-TargetResource @testParams | Should be $false
            }

            Set-TargetResource @baseParams #need to remove after each test set so previous tests don't affect the next tests
            
            It 'Should set Pass Anon Token' {
                $testParams =@{
                    Name = $apName
                    Ensure = "Present"
                    passAnonymousToken = "true"
                }

                if(([xml](& $env:SystemRoot\system32\inetsrv\appcmd.exe list apppool $apName /config:*)).add.passAnonymousToken -eq "true")
                {
                    $testParams.passAnonymousToken = "false"
                }

                Set-TargetResource @testParams
                ([xml](& $env:SystemRoot\system32\inetsrv\appcmd.exe list apppool $apName /config:*)).add.passAnonymousToken -eq $testParams.passAnonymousToken | Should be $true
            }

            It 'Passes Pass Anon Token Test when same' {
                $testParams =@{
                    Name = $apName
                    Ensure = "Present"
                    passAnonymousToken = "true"
                }

                if(([xml](& $env:SystemRoot\system32\inetsrv\appcmd.exe list apppool $apName /config:*)).add.passAnonymousToken -eq "false")
                {
                    $testParams.passAnonymousToken = "false"
                }

                Test-TargetResource @testParams | Should be $true
            }

            It 'Fails Pass Anon Token Test when different' {
                $testParams =@{
                    Name = $apName
                    Ensure = "Present"
                    passAnonymousToken = "true"
                }

                if(([xml](& $env:SystemRoot\system32\inetsrv\appcmd.exe list apppool $apName /config:*)).add.passAnonymousToken -eq "true")
                {
                    $testParams.passAnonymousToken = "false"
                }

                Test-TargetResource @testParams | Should be $false
            }

            Set-TargetResource @baseParams #need to remove after each test set so previous tests don't affect the next tests
            
            It 'Should set Logon Type' {
                $testParams =@{
                    Name = $apName
                    Ensure = "Present"
                    logonType = "LogonService"
                }

                if(([xml](& $env:SystemRoot\system32\inetsrv\appcmd.exe list apppool $apName /config:*)).add.processModel.logonType -eq "LogonService")
                {
                    $testParams.logonType = "LogonBatch"
                }

                Set-TargetResource @testParams
                ([xml](& $env:SystemRoot\system32\inetsrv\appcmd.exe list apppool $apName /config:*)).add.processModel.logonType -eq $testParams.logonType | Should be $true
            }

            It 'Passes Logon Type Test when same' {
                $testParams =@{
                    Name = $apName
                    Ensure = "Present"
                    logonType = "LogonService"
                }

                if(([xml](& $env:SystemRoot\system32\inetsrv\appcmd.exe list apppool $apName /config:*)).add.processModel.logonType -eq "LogonBatch")
                {
                    $testParams.logonType = "LogonBatch"
                }

                Test-TargetResource @testParams | Should be $true
            }

            It 'Fails Logon Type Test when different' {
                $testParams =@{
                    Name = $apName
                    Ensure = "Present"
                    logonType = "LogonService"
                }

                if(([xml](& $env:SystemRoot\system32\inetsrv\appcmd.exe list apppool $apName /config:*)).add.processModel.logonType -eq "LogonService")
                {
                    $testParams.logonType = "LogonBatch"
                }

                Test-TargetResource @testParams | Should be $false
            }

            Set-TargetResource @baseParams #need to remove after each test set so previous tests don't affect the next tests
            
            It 'Should set Manual Group Membership' {
                $testParams =@{
                    Name = $apName
                    Ensure = "Present"
                    manualGroupMembership = "true"
                }

                if(([xml](& $env:SystemRoot\system32\inetsrv\appcmd.exe list apppool $apName /config:*)).add.processModel.manualGroupMembership -eq "true")
                {
                    $testParams.manualGroupMembership = "false"
                }

                Set-TargetResource @testParams
                ([xml](& $env:SystemRoot\system32\inetsrv\appcmd.exe list apppool $apName /config:*)).add.processModel.manualGroupMembership -eq $testParams.manualGroupMembership | Should be $true
            }

            It 'Passes Manual Group Membership Test when same' {
                $testParams =@{
                    Name = $apName
                    Ensure = "Present"
                    manualGroupMembership = "true"
                }

                if(([xml](& $env:SystemRoot\system32\inetsrv\appcmd.exe list apppool $apName /config:*)).add.processModel.manualGroupMembership -eq "false")
                {
                    $testParams.manualGroupMembership = "false"
                }

                Test-TargetResource @testParams | Should be $true
            }

            It 'Fails Manual Group Membership Test when different' {
                $testParams =@{
                    Name = $apName
                    Ensure = "Present"
                    manualGroupMembership = "true"
                }

                if(([xml](& $env:SystemRoot\system32\inetsrv\appcmd.exe list apppool $apName /config:*)).add.processModel.manualGroupMembership -eq "true")
                {
                    $testParams.manualGroupMembership = "false"
                }

                Test-TargetResource @testParams | Should be $false
            }

            Set-TargetResource @baseParams #need to remove after each test set so previous tests don't affect the next tests
            
            It 'Should set Idle Timeout' {
                $testParams =@{
                    Name = $apName
                    Ensure = "Present"
                    idleTimeout = "00:25:00"
                }

                if(([xml](& $env:SystemRoot\system32\inetsrv\appcmd.exe list apppool $apName /config:*)).add.processModel.idleTimeout -eq "00:25:00")
                {
                    $testParams.idleTimeout = "00:20:00"
                }

                Set-TargetResource @testParams
                ([xml](& $env:SystemRoot\system32\inetsrv\appcmd.exe list apppool $apName /config:*)).add.processModel.idleTimeout -eq $testParams.idleTimeout | Should be $true
            }

            It 'Passes Idle Timeout Test when same' {
                $testParams =@{
                    Name = $apName
                    Ensure = "Present"
                    idleTimeout = "00:25:00"
                }

                if(([xml](& $env:SystemRoot\system32\inetsrv\appcmd.exe list apppool $apName /config:*)).add.processModel.idleTimeout -eq "00:20:00")
                {
                    $testParams.idleTimeout = "00:20:00"
                }

                Test-TargetResource @testParams | Should be $true
            }

            It 'Fails Idle Timeout Test when different' {
                $testParams =@{
                    Name = $apName
                    Ensure = "Present"
                    idleTimeout = "00:25:00"
                }

                if(([xml](& $env:SystemRoot\system32\inetsrv\appcmd.exe list apppool $apName /config:*)).add.processModel.idleTimeout -eq "00:25:00")
                {
                    $testParams.idleTimeout = "00:20:00"
                }

                Test-TargetResource @testParams | Should be $false
            }

            Set-TargetResource @baseParams #need to remove after each test set so previous tests don't affect the next tests
            
            It 'Should set Max Processes' {
                $testParams =@{
                    Name = $apName
                    Ensure = "Present"
                    maxProcesses = "2"
                }

                if(([xml](& $env:SystemRoot\system32\inetsrv\appcmd.exe list apppool $apName /config:*)).add.processModel.maxProcesses -eq "2")
                {
                    $testParams.maxProcesses = "1"
                }

                Set-TargetResource @testParams
                ([xml](& $env:SystemRoot\system32\inetsrv\appcmd.exe list apppool $apName /config:*)).add.processModel.maxProcesses -eq $testParams.maxProcesses | Should be $true
            }

            It 'Passes Max Processes Test when same' {
                $testParams =@{
                    Name = $apName
                    Ensure = "Present"
                    maxProcesses = "2"
                }

                if(([xml](& $env:SystemRoot\system32\inetsrv\appcmd.exe list apppool $apName /config:*)).add.processModel.maxProcesses -eq "1")
                {
                    $testParams.maxProcesses = "1"
                }

                Test-TargetResource @testParams | Should be $true
            }

            It 'Fails Max Processes Test when different' {
                $testParams =@{
                    Name = $apName
                    Ensure = "Present"
                    maxProcesses = "2"
                }

                if(([xml](& $env:SystemRoot\system32\inetsrv\appcmd.exe list apppool $apName /config:*)).add.processModel.maxProcesses -eq "2")
                {
                    $testParams.maxProcesses = "1"
                }

                Test-TargetResource @testParams | Should be $false
            }

            Set-TargetResource @baseParams #need to remove after each test set so previous tests don't affect the next tests
            
            It 'Should set Shutdown Time Limit' {
                $testParams =@{
                    Name = $apName
                    Ensure = "Present"
                    shutdownTimeLimit = "00:02:30"
                }

                if(([xml](& $env:SystemRoot\system32\inetsrv\appcmd.exe list apppool $apName /config:*)).add.processModel.shutdownTimeLimit -eq "00:02:30")
                {
                    $testParams.shutdownTimeLimit = "00:01:30"
                }

                Set-TargetResource @testParams
                ([xml](& $env:SystemRoot\system32\inetsrv\appcmd.exe list apppool $apName /config:*)).add.processModel.shutdownTimeLimit -eq $testParams.shutdownTimeLimit | Should be $true
            }

            It 'Passes Shutdown Time Limit Test when same' {
                $testParams =@{
                    Name = $apName
                    Ensure = "Present"
                    shutdownTimeLimit = "00:02:30"
                }

                if(([xml](& $env:SystemRoot\system32\inetsrv\appcmd.exe list apppool $apName /config:*)).add.processModel.shutdownTimeLimit -eq "00:01:30")
                {
                    $testParams.shutdownTimeLimit = "00:01:30"
                }

                Test-TargetResource @testParams | Should be $true
            }

            It 'Fails Shutdown Time Limit Test when different' {
                $testParams =@{
                    Name = $apName
                    Ensure = "Present"
                    shutdownTimeLimit = "00:02:30"
                }

                if(([xml](& $env:SystemRoot\system32\inetsrv\appcmd.exe list apppool $apName /config:*)).add.processModel.shutdownTimeLimit -eq "00:02:30")
                {
                    $testParams.shutdownTimeLimit = "00:01:30"
                }

                Test-TargetResource @testParams | Should be $false
            }

            Set-TargetResource @baseParams #need to remove after each test set so previous tests don't affect the next tests
            
            It 'Should set Startup Time Limit' {
                $testParams =@{
                    Name = $apName
                    Ensure = "Present"
                    startupTimeLimit = "00:02:30"
                }

                if(([xml](& $env:SystemRoot\system32\inetsrv\appcmd.exe list apppool $apName /config:*)).add.processModel.startupTimeLimit -eq "00:02:30")
                {
                    $testParams.startupTimeLimit = "00:01:30"
                }

                Set-TargetResource @testParams
                ([xml](& $env:SystemRoot\system32\inetsrv\appcmd.exe list apppool $apName /config:*)).add.processModel.startupTimeLimit -eq $testParams.startupTimeLimit | Should be $true
            }

            It 'Passes Startup Time Limit Test when same' {
                $testParams =@{
                    Name = $apName
                    Ensure = "Present"
                    startupTimeLimit = "00:02:30"
                }

                if(([xml](& $env:SystemRoot\system32\inetsrv\appcmd.exe list apppool $apName /config:*)).add.processModel.startupTimeLimit -eq "00:01:30")
                {
                    $testParams.startupTimeLimit = "00:01:30"
                }

                Test-TargetResource @testParams | Should be $true
            }

            It 'Fails Startup Time Limit Test when different' {
                $testParams =@{
                    Name = $apName
                    Ensure = "Present"
                    startupTimeLimit = "00:02:30"
                }

                if(([xml](& $env:SystemRoot\system32\inetsrv\appcmd.exe list apppool $apName /config:*)).add.processModel.startupTimeLimit -eq "00:02:30")
                {
                    $testParams.startupTimeLimit = "00:01:30"
                }

                Test-TargetResource @testParams | Should be $false
            }

            Set-TargetResource @baseParams #need to remove after each test set so previous tests don't affect the next tests
            
            It 'Should set Ping Interval' {
                $testParams =@{
                    Name = $apName
                    Ensure = "Present"
                    pingInterval = "00:02:30"
                }

                if(([xml](& $env:SystemRoot\system32\inetsrv\appcmd.exe list apppool $apName /config:*)).add.processModel.pingInterval -eq "00:02:30")
                {
                    $testParams.pingInterval = "00:01:30"
                }

                Set-TargetResource @testParams
                ([xml](& $env:SystemRoot\system32\inetsrv\appcmd.exe list apppool $apName /config:*)).add.processModel.pingInterval -eq $testParams.pingInterval | Should be $true
            }

            It 'Passes Ping Interval Test when same' {
                $testParams =@{
                    Name = $apName
                    Ensure = "Present"
                    pingInterval = "00:02:30"
                }

                if(([xml](& $env:SystemRoot\system32\inetsrv\appcmd.exe list apppool $apName /config:*)).add.processModel.pingInterval -eq "00:01:30")
                {
                    $testParams.pingInterval = "00:01:30"
                }

                Test-TargetResource @testParams | Should be $true
            }

            It 'Fails Ping Interval Test when different' {
                $testParams =@{
                    Name = $apName
                    Ensure = "Present"
                    pingInterval = "00:02:30"
                }

                if(([xml](& $env:SystemRoot\system32\inetsrv\appcmd.exe list apppool $apName /config:*)).add.processModel.pingInterval -eq "00:02:30")
                {
                    $testParams.pingInterval = "00:01:30"
                }

                Test-TargetResource @testParams | Should be $false
            }

            Set-TargetResource @baseParams #need to remove after each test set so previous tests don't affect the next tests
            
            It 'Should set Ping Response Time' {
                $testParams =@{
                    Name = $apName
                    Ensure = "Present"
                    pingResponseTime = "00:02:30"
                }

                if(([xml](& $env:SystemRoot\system32\inetsrv\appcmd.exe list apppool $apName /config:*)).add.processModel.pingResponseTime -eq "00:02:30")
                {
                    $testParams.pingResponseTime = "00:01:30"
                }

                Set-TargetResource @testParams
                ([xml](& $env:SystemRoot\system32\inetsrv\appcmd.exe list apppool $apName /config:*)).add.processModel.pingResponseTime -eq $testParams.pingResponseTime | Should be $true
            }

            It 'Passes Ping Response Time Test when same' {
                $testParams =@{
                    Name = $apName
                    Ensure = "Present"
                    pingResponseTime = "00:02:30"
                }

                if(([xml](& $env:SystemRoot\system32\inetsrv\appcmd.exe list apppool $apName /config:*)).add.processModel.pingResponseTime -eq "00:01:30")
                {
                    $testParams.pingResponseTime = "00:01:30"
                }

                Test-TargetResource @testParams | Should be $true
            }

            It 'Fails Ping Response Time Test when different' {
                $testParams =@{
                    Name = $apName
                    Ensure = "Present"
                    pingResponseTime = "00:02:30"
                }

                if(([xml](& $env:SystemRoot\system32\inetsrv\appcmd.exe list apppool $apName /config:*)).add.processModel.pingResponseTime -eq "00:02:30")
                {
                    $testParams.pingResponseTime = "00:01:30"
                }

                Test-TargetResource @testParams | Should be $false
            }

            Set-TargetResource @baseParams #need to remove after each test set so previous tests don't affect the next tests
            
            It 'Should set Ping Enabled' {
                $testParams =@{
                    Name = $apName
                    Ensure = "Present"
                    pingingEnabled = "false"
                }

                if(([xml](& $env:SystemRoot\system32\inetsrv\appcmd.exe list apppool $apName /config:*)).add.processModel.pingingEnabled -eq "false")
                {
                    $testParams.pingingEnabled = "true"
                }

                Set-TargetResource @testParams
                ([xml](& $env:SystemRoot\system32\inetsrv\appcmd.exe list apppool $apName /config:*)).add.processModel.pingingEnabled -eq $testParams.pingingEnabled | Should be $true
            }

            It 'Passes Ping Enabled Test when same' {
                $testParams =@{
                    Name = $apName
                    Ensure = "Present"
                    pingingEnabled = "false"
                }

                if(([xml](& $env:SystemRoot\system32\inetsrv\appcmd.exe list apppool $apName /config:*)).add.processModel.pingingEnabled -eq "true")
                {
                    $testParams.pingingEnabled = "true"
                }

                Test-TargetResource @testParams | Should be $true
            }

            It 'Fails Ping Enabled Test when different' {
                $testParams =@{
                    Name = $apName
                    Ensure = "Present"
                    pingingEnabled = "false"
                }

                if(([xml](& $env:SystemRoot\system32\inetsrv\appcmd.exe list apppool $apName /config:*)).add.processModel.pingingEnabled -eq "false")
                {
                    $testParams.pingingEnabled = "true"
                }

                Test-TargetResource @testParams | Should be $false
            }

            Set-TargetResource @baseParams #need to remove after each test set so previous tests don't affect the next tests
            
            It 'Should set Disallow Overlapping Rotation' {
                $testParams =@{
                    Name = $apName
                    Ensure = "Present"
                    disallowOverlappingRotation = "false"
                }

                if(([xml](& $env:SystemRoot\system32\inetsrv\appcmd.exe list apppool $apName /config:*)).add.recycling.disallowOverlappingRotation -eq "false")
                {
                    $testParams.disallowOverlappingRotation = "true"
                }

                Set-TargetResource @testParams
                ([xml](& $env:SystemRoot\system32\inetsrv\appcmd.exe list apppool $apName /config:*)).add.recycling.disallowOverlappingRotation -eq $testParams.disallowOverlappingRotation | Should be $true
            }

            It 'Passes Disallow Overlapping Rotation Test when same' {
                $testParams =@{
                    Name = $apName
                    Ensure = "Present"
                    disallowOverlappingRotation = "false"
                }

                if(([xml](& $env:SystemRoot\system32\inetsrv\appcmd.exe list apppool $apName /config:*)).add.recycling.disallowOverlappingRotation -eq "true")
                {
                    $testParams.disallowOverlappingRotation = "true"
                }

                Test-TargetResource @testParams | Should be $true
            }

            It 'Fails Disallow Overlapping Rotation Test when different' {
                $testParams =@{
                    Name = $apName
                    Ensure = "Present"
                    disallowOverlappingRotation = "false"
                }

                if(([xml](& $env:SystemRoot\system32\inetsrv\appcmd.exe list apppool $apName /config:*)).add.recycling.disallowOverlappingRotation -eq "false")
                {
                    $testParams.disallowOverlappingRotation = "true"
                }

                Test-TargetResource @testParams | Should be $false
            }

            Set-TargetResource @baseParams #need to remove after each test set so previous tests don't affect the next tests
            
            It 'Should set Disallow Rotation On Config Change' {
                $testParams =@{
                    Name = $apName
                    Ensure = "Present"
                    disallowRotationOnConfigChange = "false"
                }

                if(([xml](& $env:SystemRoot\system32\inetsrv\appcmd.exe list apppool $apName /config:*)).add.recycling.disallowRotationOnConfigChange -eq "false")
                {
                    $testParams.disallowRotationOnConfigChange = "true"
                }

                Set-TargetResource @testParams
                ([xml](& $env:SystemRoot\system32\inetsrv\appcmd.exe list apppool $apName /config:*)).add.recycling.disallowRotationOnConfigChange -eq $testParams.disallowRotationOnConfigChange | Should be $true
            }

            It 'Passes Disallow Rotation On Config Change Test when same' {
                $testParams =@{
                    Name = $apName
                    Ensure = "Present"
                    disallowRotationOnConfigChange = "false"
                }

                if(([xml](& $env:SystemRoot\system32\inetsrv\appcmd.exe list apppool $apName /config:*)).add.recycling.disallowRotationOnConfigChange -eq "true")
                {
                    $testParams.disallowRotationOnConfigChange = "true"
                }

                Test-TargetResource @testParams | Should be $true
            }

            It 'Fails Disallow Rotation On Config Change Test when different' {
                $testParams =@{
                    Name = $apName
                    Ensure = "Present"
                    disallowRotationOnConfigChange = "false"
                }

                if(([xml](& $env:SystemRoot\system32\inetsrv\appcmd.exe list apppool $apName /config:*)).add.recycling.disallowRotationOnConfigChange -eq "false")
                {
                    $testParams.disallowRotationOnConfigChange = "true"
                }

                Test-TargetResource @testParams | Should be $false
            }

            Set-TargetResource @baseParams #need to remove after each test set so previous tests don't affect the next tests
            
            It 'Should set Log Event On Recycle' {
                $testParams =@{
                    Name = $apName
                    Ensure = "Present"
                    logEventOnRecycle = "Time, Memory"
                }

                if(([xml](& $env:SystemRoot\system32\inetsrv\appcmd.exe list apppool $apName /config:*)).add.recycling.logEventOnRecycle -eq "Time, Memory")
                {
                    $testParams.logEventOnRecycle = "Time, Memory, PrivateMemory"
                }

                Set-TargetResource @testParams
                ([xml](& $env:SystemRoot\system32\inetsrv\appcmd.exe list apppool $apName /config:*)).add.recycling.logEventOnRecycle -eq $testParams.logEventOnRecycle | Should be $true
            }

            It 'Passes Log Event On Recycle Test when same' {
                $testParams =@{
                    Name = $apName
                    Ensure = "Present"
                    logEventOnRecycle = "Time, Memory"
                }

                if(([xml](& $env:SystemRoot\system32\inetsrv\appcmd.exe list apppool $apName /config:*)).add.recycling.logEventOnRecycle -eq "Time, Memory, PrivateMemory")
                {
                    $testParams.logEventOnRecycle = "Time, Memory, PrivateMemory"
                }

                Test-TargetResource @testParams | Should be $true
            }

            It 'Fails Log Event On Recycle Test when different' {
                $testParams =@{
                    Name = $apName
                    Ensure = "Present"
                    logEventOnRecycle = "Time, Memory"
                }

                if(([xml](& $env:SystemRoot\system32\inetsrv\appcmd.exe list apppool $apName /config:*)).add.recycling.logEventOnRecycle -eq "Time, Memory")
                {
                    $testParams.logEventOnRecycle = "Time, Memory, PrivateMemory"
                }

                Test-TargetResource @testParams | Should be $false
            }

            Set-TargetResource @baseParams #need to remove after each test set so previous tests don't affect the next tests
            
            It 'Should set Restart Mem Limit' {
                $testParams =@{
                    Name = $apName
                    Ensure = "Present"
                    restartMemoryLimit = "1"
                }

                if(([xml](& $env:SystemRoot\system32\inetsrv\appcmd.exe list apppool $apName /config:*)).add.recycling.periodicRestart.memory -eq "1")
                {
                    $testParams.restartMemoryLimit = "0"
                }

                Set-TargetResource @testParams
                ([xml](& $env:SystemRoot\system32\inetsrv\appcmd.exe list apppool $apName /config:*)).add.recycling.periodicRestart.memory -eq $testParams.restartMemoryLimit | Should be $true
            }

            It 'Passes Restart Mem Limit Test when same' {
                $testParams =@{
                    Name = $apName
                    Ensure = "Present"
                    restartMemoryLimit = "1"
                }

                if(([xml](& $env:SystemRoot\system32\inetsrv\appcmd.exe list apppool $apName /config:*)).add.recycling.periodicRestart.memory -eq "0")
                {
                    $testParams.restartMemoryLimit = "0"
                }

                Test-TargetResource @testParams | Should be $true
            }

            It 'Fails Restart Mem Limit Test when different' {
                $testParams =@{
                    Name = $apName
                    Ensure = "Present"
                    restartMemoryLimit = "1"
                }

                if(([xml](& $env:SystemRoot\system32\inetsrv\appcmd.exe list apppool $apName /config:*)).add.recycling.periodicRestart.memory -eq "1")
                {
                    $testParams.restartMemoryLimit = "0"
                }

                Test-TargetResource @testParams | Should be $false
            }

            Set-TargetResource @baseParams #need to remove after each test set so previous tests don't affect the next tests
            
            It 'Should set Restart Private Mem Limit' {
                $testParams =@{
                    Name = $apName
                    Ensure = "Present"
                    restartPrivateMemoryLimit = "1"
                }

                if(([xml](& $env:SystemRoot\system32\inetsrv\appcmd.exe list apppool $apName /config:*)).add.recycling.periodicRestart.privateMemory -eq "1")
                {
                    $testParams.restartPrivateMemoryLimit = "0"
                }

                Set-TargetResource @testParams
                ([xml](& $env:SystemRoot\system32\inetsrv\appcmd.exe list apppool $apName /config:*)).add.recycling.periodicRestart.privateMemory -eq $testParams.restartPrivateMemoryLimit | Should be $true
            }

            It 'Passes Restart Private Mem Limit Test when same' {
                $testParams =@{
                    Name = $apName
                    Ensure = "Present"
                    restartPrivateMemoryLimit = "1"
                }

                if(([xml](& $env:SystemRoot\system32\inetsrv\appcmd.exe list apppool $apName /config:*)).add.recycling.periodicRestart.privateMemory -eq "0")
                {
                    $testParams.restartPrivateMemoryLimit = "0"
                }

                Test-TargetResource @testParams | Should be $true
            }

            It 'Fails Restart Private Mem Limit Test when different' {
                $testParams =@{
                    Name = $apName
                    Ensure = "Present"
                    restartPrivateMemoryLimit = "1"
                }

                if(([xml](& $env:SystemRoot\system32\inetsrv\appcmd.exe list apppool $apName /config:*)).add.recycling.periodicRestart.privateMemory -eq "1")
                {
                    $testParams.restartPrivateMemoryLimit = "0"
                }

                Test-TargetResource @testParams | Should be $false
            }

            Set-TargetResource @baseParams #need to remove after each test set so previous tests don't affect the next tests
            
            It 'Should set Restart Requests Limit' {
                $testParams =@{
                    Name = $apName
                    Ensure = "Present"
                    restartRequestsLimit = "1"
                }

                if(([xml](& $env:SystemRoot\system32\inetsrv\appcmd.exe list apppool $apName /config:*)).add.recycling.periodicRestart.requests -eq "1")
                {
                    $testParams.restartRequestsLimit = "0"
                }

                Set-TargetResource @testParams
                ([xml](& $env:SystemRoot\system32\inetsrv\appcmd.exe list apppool $apName /config:*)).add.recycling.periodicRestart.requests -eq $testParams.restartRequestsLimit | Should be $true
            }

            It 'Passes Restart Requests Limit Test when same' {
                $testParams =@{
                    Name = $apName
                    Ensure = "Present"
                    restartRequestsLimit = "1"
                }

                if(([xml](& $env:SystemRoot\system32\inetsrv\appcmd.exe list apppool $apName /config:*)).add.recycling.periodicRestart.requests -eq "0")
                {
                    $testParams.restartRequestsLimit = "0"
                }

                Test-TargetResource @testParams | Should be $true
            }

            It 'Fails Restart Requests Limit Test when different' {
                $testParams =@{
                    Name = $apName
                    Ensure = "Present"
                    restartRequestsLimit = "1"
                }

                if(([xml](& $env:SystemRoot\system32\inetsrv\appcmd.exe list apppool $apName /config:*)).add.recycling.periodicRestart.requests -eq "1")
                {
                    $testParams.restartRequestsLimit = "0"
                }

                Test-TargetResource @testParams | Should be $false
            }

            Set-TargetResource @baseParams #need to remove after each test set so previous tests don't affect the next tests
            
            It 'Should set Restart Time Limit' {
                $testParams =@{
                    Name = $apName
                    Ensure = "Present"
                    restartTimeLimit = "2.05:00:00"
                }

                if(([xml](& $env:SystemRoot\system32\inetsrv\appcmd.exe list apppool $apName /config:*)).add.recycling.periodicRestart.time -eq "2.05:00:00")
                {
                    $testParams.restartTimeLimit = "1.05:00:00"
                }

                Set-TargetResource @testParams
                ([xml](& $env:SystemRoot\system32\inetsrv\appcmd.exe list apppool $apName /config:*)).add.recycling.periodicRestart.time -eq $testParams.restartTimeLimit | Should be $true
            }

            It 'Passes Restart Time Limit Test when same' {
                $testParams =@{
                    Name = $apName
                    Ensure = "Present"
                    restartTimeLimit = "2.05:00:00"
                }

                if(([xml](& $env:SystemRoot\system32\inetsrv\appcmd.exe list apppool $apName /config:*)).add.recycling.periodicRestart.time -eq "1.05:00:00")
                {
                    $testParams.restartTimeLimit = "1.05:00:00"
                }

                Test-TargetResource @testParams | Should be $true
            }

            It 'Fails Restart Time Limit Test when different' {
                $testParams =@{
                    Name = $apName
                    Ensure = "Present"
                    restartTimeLimit = "2.05:00:00"
                }

                if(([xml](& $env:SystemRoot\system32\inetsrv\appcmd.exe list apppool $apName /config:*)).add.recycling.periodicRestart.time -eq "2.05:00:00")
                {
                    $testParams.restartTimeLimit = "1.05:00:00"
                }

                Test-TargetResource @testParams | Should be $false
            }

            Set-TargetResource @baseParams #need to remove after each test set so previous tests don't affect the next tests
            
            It 'Should set Restart Schedule' {
                $testParams =@{
                    Name = $apName
                    Ensure = "Present"
                    restartSchedule = "18:30:00"
                }

                if(([xml](& $env:SystemRoot\system32\inetsrv\appcmd.exe list apppool $apName /config:*)).add.recycling.periodicRestart.schedule.add.value -eq "18:30:00")
                {
                    $testParams.restartSchedule = "10:30:00"
                }

                Set-TargetResource @testParams
                ([xml](& $env:SystemRoot\system32\inetsrv\appcmd.exe list apppool $apName /config:*)).add.recycling.periodicRestart.schedule.add.value -eq $testParams.restartSchedule | Should be $true
            }

            It 'Passes Restart Schedule Test when same' {
                $testParams =@{
                    Name = $apName
                    Ensure = "Present"
                    restartSchedule = "18:30:00"
                }

                if(([xml](& $env:SystemRoot\system32\inetsrv\appcmd.exe list apppool $apName /config:*)).add.recycling.periodicRestart.schedule.add.value -eq "10:30:00")
                {
                    $testParams.restartSchedule = "10:30:00"
                }

                Test-TargetResource @testParams | Should be $true
            }

            It 'Fails Restart Schedule Test when different' {
                $testParams =@{
                    Name = $apName
                    Ensure = "Present"
                    restartSchedule = "18:30:00"
                }

                if(([xml](& $env:SystemRoot\system32\inetsrv\appcmd.exe list apppool $apName /config:*)).add.recycling.periodicRestart.schedule.add.value -eq "18:30:00")
                {
                    $testParams.restartSchedule = "10:30:00"
                }

                Test-TargetResource @testParams | Should be $false
            }

            Set-TargetResource @baseParams #need to remove after each test set so previous tests don't affect the next tests
            
            It 'Should set Load Balancer Capabilities' {
                $testParams =@{
                    Name = $apName
                    Ensure = "Present"
                    loadBalancerCapabilities = "TcpLevel"
                }

                if(([xml](& $env:SystemRoot\system32\inetsrv\appcmd.exe list apppool $apName /config:*)).add.failure.loadBalancerCapabilities -eq "TcpLevel")
                {
                    $testParams.loadBalancerCapabilities = "HttpLevel"
                }

                Set-TargetResource @testParams
                ([xml](& $env:SystemRoot\system32\inetsrv\appcmd.exe list apppool $apName /config:*)).add.failure.loadBalancerCapabilities -eq $testParams.loadBalancerCapabilities | Should be $true
            }

            It 'Passes Load Balancer Capabilities Test when same' {
                $testParams =@{
                    Name = $apName
                    Ensure = "Present"
                    loadBalancerCapabilities = "TcpLevel"
                }

                if(([xml](& $env:SystemRoot\system32\inetsrv\appcmd.exe list apppool $apName /config:*)).add.failure.loadBalancerCapabilities -eq "HttpLevel")
                {
                    $testParams.loadBalancerCapabilities = "HttpLevel"
                }

                Test-TargetResource @testParams | Should be $true
            }

            It 'Fails Load Balancer Capabilities Test when different' {
                $testParams =@{
                    Name = $apName
                    Ensure = "Present"
                    loadBalancerCapabilities = "TcpLevel"
                }

                if(([xml](& $env:SystemRoot\system32\inetsrv\appcmd.exe list apppool $apName /config:*)).add.failure.loadBalancerCapabilities -eq "TcpLevel")
                {
                    $testParams.loadBalancerCapabilities = "HttpLevel"
                }

                Test-TargetResource @testParams | Should be $false
            }

            Set-TargetResource @baseParams #need to remove after each test set so previous tests don't affect the next tests
            
            It 'Should set Orphan Worker Process' {
                $testParams =@{
                    Name = $apName
                    Ensure = "Present"
                    orphanWorkerProcess = "true"
                }

                if(([xml](& $env:SystemRoot\system32\inetsrv\appcmd.exe list apppool $apName /config:*)).add.failure.orphanWorkerProcess -eq "true")
                {
                    $testParams.orphanWorkerProcess = "false"
                }

                Set-TargetResource @testParams
                ([xml](& $env:SystemRoot\system32\inetsrv\appcmd.exe list apppool $apName /config:*)).add.failure.orphanWorkerProcess -eq $testParams.orphanWorkerProcess | Should be $true
            }

            It 'Passes Orphan Worker Process Test when same' {
                $testParams =@{
                    Name = $apName
                    Ensure = "Present"
                    orphanWorkerProcess = "true"
                }

                if(([xml](& $env:SystemRoot\system32\inetsrv\appcmd.exe list apppool $apName /config:*)).add.failure.orphanWorkerProcess -eq "false")
                {
                    $testParams.orphanWorkerProcess = "false"
                }

                Test-TargetResource @testParams | Should be $true
            }

            It 'Fails Orphan Worker Process Test when different' {
                $testParams =@{
                    Name = $apName
                    Ensure = "Present"
                    orphanWorkerProcess = "true"
                }

                if(([xml](& $env:SystemRoot\system32\inetsrv\appcmd.exe list apppool $apName /config:*)).add.failure.orphanWorkerProcess -eq "true")
                {
                    $testParams.orphanWorkerProcess = "false"
                }

                Test-TargetResource @testParams | Should be $false
            }

            Set-TargetResource @baseParams #need to remove after each test set so previous tests don't affect the next tests
            
            It 'Should set Orphan Action Exe' {
                $testParams =@{
                    Name = $apName
                    Ensure = "Present"
                    orphanActionExe = "test.exe"
                }

                if(([xml](& $env:SystemRoot\system32\inetsrv\appcmd.exe list apppool $apName /config:*)).add.failure.orphanActionExe -eq "test.exe")
                {
                    $testParams.orphanActionExe = "test1.exe"
                }

                Set-TargetResource @testParams
                ([xml](& $env:SystemRoot\system32\inetsrv\appcmd.exe list apppool $apName /config:*)).add.failure.orphanActionExe -eq $testParams.orphanActionExe | Should be $true
            }

            It 'Passes Orphan Action Exe Test when same' {
                $testParams =@{
                    Name = $apName
                    Ensure = "Present"
                    orphanActionExe = "test.exe"
                }

                if(([xml](& $env:SystemRoot\system32\inetsrv\appcmd.exe list apppool $apName /config:*)).add.failure.orphanActionExe -eq "test1.exe")
                {
                    $testParams.orphanActionExe = "test1.exe"
                }

                Test-TargetResource @testParams | Should be $true
            }

            It 'Fails Orphan Action Exe Test when different' {
                $testParams =@{
                    Name = $apName
                    Ensure = "Present"
                    orphanActionExe = "test.exe"
                }

                if(([xml](& $env:SystemRoot\system32\inetsrv\appcmd.exe list apppool $apName /config:*)).add.failure.orphanActionExe -eq "test.exe")
                {
                    $testParams.orphanActionExe = "test1.exe"
                }

                Test-TargetResource @testParams | Should be $false
            }

            Set-TargetResource @baseParams #need to remove after each test set so previous tests don't affect the next tests
            
            It 'Should set Orphan Action Params' {
                $testParams =@{
                    Name = $apName
                    Ensure = "Present"
                    orphanActionParams = "test.exe"
                }

                if(([xml](& $env:SystemRoot\system32\inetsrv\appcmd.exe list apppool $apName /config:*)).add.failure.orphanActionParams -eq "test.exe")
                {
                    $testParams.orphanActionParams = "test1.exe"
                }

                Set-TargetResource @testParams
                ([xml](& $env:SystemRoot\system32\inetsrv\appcmd.exe list apppool $apName /config:*)).add.failure.orphanActionParams -eq $testParams.orphanActionParams | Should be $true
            }

            It 'Passes Orphan Action Params Test when same' {
                $testParams =@{
                    Name = $apName
                    Ensure = "Present"
                    orphanActionParams = "test.exe"
                }

                if(([xml](& $env:SystemRoot\system32\inetsrv\appcmd.exe list apppool $apName /config:*)).add.failure.orphanActionParams -eq "test1.exe")
                {
                    $testParams.orphanActionParams = "test1.exe"
                }

                Test-TargetResource @testParams | Should be $true
            }

            It 'Fails Orphan Action Params Test when different' {
                $testParams =@{
                    Name = $apName
                    Ensure = "Present"
                    orphanActionParams = "test.exe"
                }

                if(([xml](& $env:SystemRoot\system32\inetsrv\appcmd.exe list apppool $apName /config:*)).add.failure.orphanActionParams -eq "test.exe")
                {
                    $testParams.orphanActionParams = "test1.exe"
                }

                Test-TargetResource @testParams | Should be $false
            }

            Set-TargetResource @baseParams #need to remove after each test set so previous tests don't affect the next tests
            
            It 'Should set Rapid Fail Protection' {
                $testParams =@{
                    Name = $apName
                    Ensure = "Present"
                    rapidFailProtection = "true"
                }

                if(([xml](& $env:SystemRoot\system32\inetsrv\appcmd.exe list apppool $apName /config:*)).add.failure.rapidFailProtection -eq "true")
                {
                    $testParams.rapidFailProtection = "false"
                }

                Set-TargetResource @testParams
                ([xml](& $env:SystemRoot\system32\inetsrv\appcmd.exe list apppool $apName /config:*)).add.failure.rapidFailProtection -eq $testParams.rapidFailProtection | Should be $true
            }

            It 'Passes Rapid Fail Protection Test when same' {
                $testParams =@{
                    Name = $apName
                    Ensure = "Present"
                    rapidFailProtection = "true"
                }

                if(([xml](& $env:SystemRoot\system32\inetsrv\appcmd.exe list apppool $apName /config:*)).add.failure.rapidFailProtection -eq "false")
                {
                    $testParams.rapidFailProtection = "false"
                }

                Test-TargetResource @testParams | Should be $true
            }

            It 'Fails Rapid Fail Protection Test when different' {
                $testParams =@{
                    Name = $apName
                    Ensure = "Present"
                    rapidFailProtection = "true"
                }

                if(([xml](& $env:SystemRoot\system32\inetsrv\appcmd.exe list apppool $apName /config:*)).add.failure.rapidFailProtection -eq "true")
                {
                    $testParams.rapidFailProtection = "false"
                }

                Test-TargetResource @testParams | Should be $false
            }

            Set-TargetResource @baseParams #need to remove after each test set so previous tests don't affect the next tests
            
            It 'Should set Rapid Fail Protection Interval' {
                $testParams =@{
                    Name = $apName
                    Ensure = "Present"
                    rapidFailProtectionInterval = "00:15:00"
                }

                if(([xml](& $env:SystemRoot\system32\inetsrv\appcmd.exe list apppool $apName /config:*)).add.failure.rapidFailProtectionInterval -eq "00:15:00")
                {
                    $testParams.rapidFailProtectionInterval = "00:05:00"
                }

                Set-TargetResource @testParams
                ([xml](& $env:SystemRoot\system32\inetsrv\appcmd.exe list apppool $apName /config:*)).add.failure.rapidFailProtectionInterval -eq $testParams.rapidFailProtectionInterval | Should be $true
            }

            It 'Passes Rapid Fail Protection Interval Test when same' {
                $testParams =@{
                    Name = $apName
                    Ensure = "Present"
                    rapidFailProtectionInterval = "00:15:00"
                }

                if(([xml](& $env:SystemRoot\system32\inetsrv\appcmd.exe list apppool $apName /config:*)).add.failure.rapidFailProtectionInterval -eq "00:05:00")
                {
                    $testParams.rapidFailProtectionInterval = "00:05:00"
                }

                Test-TargetResource @testParams | Should be $true
            }

            It 'Fails Rapid Fail Protection Interval Test when different' {
                $testParams =@{
                    Name = $apName
                    Ensure = "Present"
                    rapidFailProtectionInterval = "00:15:00"
                }

                if(([xml](& $env:SystemRoot\system32\inetsrv\appcmd.exe list apppool $apName /config:*)).add.failure.rapidFailProtectionInterval -eq "00:15:00")
                {
                    $testParams.rapidFailProtectionInterval = "00:05:00"
                }

                Test-TargetResource @testParams | Should be $false
            }

            Set-TargetResource @baseParams #need to remove after each test set so previous tests don't affect the next tests
            
            It 'Should set Rapid Fail Protection Max Crashes' {
                $testParams =@{
                    Name = $apName
                    Ensure = "Present"
                    rapidFailProtectionMaxCrashes = "15"
                }

                if(([xml](& $env:SystemRoot\system32\inetsrv\appcmd.exe list apppool $apName /config:*)).add.failure.rapidFailProtectionMaxCrashes -eq "15")
                {
                    $testParams.rapidFailProtectionMaxCrashes = "05"
                }

                Set-TargetResource @testParams
                ([xml](& $env:SystemRoot\system32\inetsrv\appcmd.exe list apppool $apName /config:*)).add.failure.rapidFailProtectionMaxCrashes -eq $testParams.rapidFailProtectionMaxCrashes | Should be $true
            }

            It 'Passes Rapid Fail Protection Interval Max Crashes when same' {
                $testParams =@{
                    Name = $apName
                    Ensure = "Present"
                    rapidFailProtectionMaxCrashes = "15"
                }

                if(([xml](& $env:SystemRoot\system32\inetsrv\appcmd.exe list apppool $apName /config:*)).add.failure.rapidFailProtectionMaxCrashes -eq "05")
                {
                    $testParams.rapidFailProtectionMaxCrashes = "05"
                }

                Test-TargetResource @testParams | Should be $true
            }

            It 'Fails Rapid Fail Protection Max Crashes Test when different' {
                $testParams =@{
                    Name = $apName
                    Ensure = "Present"
                    rapidFailProtectionMaxCrashes = "15"
                }

                if(([xml](& $env:SystemRoot\system32\inetsrv\appcmd.exe list apppool $apName /config:*)).add.failure.rapidFailProtectionMaxCrashes -eq "15")
                {
                    $testParams.rapidFailProtectionMaxCrashes = "05"
                }

                Test-TargetResource @testParams | Should be $false
            }

            Set-TargetResource @baseParams #need to remove after each test set so previous tests don't affect the next tests
            
            It 'Should set Auto Shutdown Exe' {
                $testParams =@{
                    Name = $apName
                    Ensure = "Present"
                    autoShutdownExe = "test.exe"
                }

                if(([xml](& $env:SystemRoot\system32\inetsrv\appcmd.exe list apppool $apName /config:*)).add.failure.autoShutdownExe -eq "test.exe")
                {
                    $testParams.autoShutdownExe = "test1.exe"
                }

                Set-TargetResource @testParams
                ([xml](& $env:SystemRoot\system32\inetsrv\appcmd.exe list apppool $apName /config:*)).add.failure.autoShutdownExe -eq $testParams.autoShutdownExe | Should be $true
            }

            It 'Passes Auto Shutdown Exe Test when same' {
                $testParams =@{
                    Name = $apName
                    Ensure = "Present"
                    autoShutdownExe = "test.exe"
                }

                if(([xml](& $env:SystemRoot\system32\inetsrv\appcmd.exe list apppool $apName /config:*)).add.failure.autoShutdownExe -eq "test1.exe")
                {
                    $testParams.autoShutdownExe = "test1.exe"
                }

                Test-TargetResource @testParams | Should be $true
            }

            It 'Fails Auto Shutdown Exe Test when different' {
                $testParams =@{
                    Name = $apName
                    Ensure = "Present"
                    autoShutdownExe = "test.exe"
                }

                if(([xml](& $env:SystemRoot\system32\inetsrv\appcmd.exe list apppool $apName /config:*)).add.failure.autoShutdownExe -eq "test.exe")
                {
                    $testParams.autoShutdownExe = "test1.exe"
                }

                Test-TargetResource @testParams | Should be $false
            }

            Set-TargetResource @baseParams #need to remove after each test set so previous tests don't affect the next tests
            
            It 'Should set Auto Shutdown Params' {
                $testParams =@{
                    Name = $apName
                    Ensure = "Present"
                    autoShutdownParams = "test.exe"
                }

                if(([xml](& $env:SystemRoot\system32\inetsrv\appcmd.exe list apppool $apName /config:*)).add.failure.autoShutdownParams -eq "test.exe")
                {
                    $testParams.autoShutdownParams = "test1.exe"
                }

                Set-TargetResource @testParams
                ([xml](& $env:SystemRoot\system32\inetsrv\appcmd.exe list apppool $apName /config:*)).add.failure.autoShutdownParams -eq $testParams.autoShutdownParams | Should be $true
            }

            It 'Passes Auto Shutdown Params Test when same' {
                $testParams =@{
                    Name = $apName
                    Ensure = "Present"
                    autoShutdownParams = "test.exe"
                }

                if(([xml](& $env:SystemRoot\system32\inetsrv\appcmd.exe list apppool $apName /config:*)).add.failure.autoShutdownParams -eq "test1.exe")
                {
                    $testParams.autoShutdownParams = "test1.exe"
                }

                Test-TargetResource @testParams | Should be $true
            }

            It 'Fails Auto Shutdown Params Test when different' {
                $testParams =@{
                    Name = $apName
                    Ensure = "Present"
                    autoShutdownParams = "test.exe"
                }

                if(([xml](& $env:SystemRoot\system32\inetsrv\appcmd.exe list apppool $apName /config:*)).add.failure.autoShutdownParams -eq "test.exe")
                {
                    $testParams.autoShutdownParams = "test1.exe"
                }

                Test-TargetResource @testParams | Should be $false
            }

            Set-TargetResource @baseParams #need to remove after each test set so previous tests don't affect the next tests
            
            It 'Should set CPU Limit' {
                $testParams =@{
                    Name = $apName
                    Ensure = "Present"
                    cpuLimit = "1"
                }

                if(([xml](& $env:SystemRoot\system32\inetsrv\appcmd.exe list apppool $apName /config:*)).add.cpu.limit -eq "1")
                {
                    $testParams.cpuLimit = "0"
                }

                Set-TargetResource @testParams
                ([xml](& $env:SystemRoot\system32\inetsrv\appcmd.exe list apppool $apName /config:*)).add.cpu.limit -eq $testParams.cpuLimit | Should be $true
            }

            It 'Passes CPU Limit Test when same' {
                $testParams =@{
                    Name = $apName
                    Ensure = "Present"
                    cpuLimit = "1"
                }

                if(([xml](& $env:SystemRoot\system32\inetsrv\appcmd.exe list apppool $apName /config:*)).add.cpu.limit -eq "0")
                {
                    $testParams.cpuLimit = "0"
                }

                Test-TargetResource @testParams | Should be $true
            }

            It 'Fails CPU Limit Test when different' {
                $testParams =@{
                    Name = $apName
                    Ensure = "Present"
                    cpuLimit = "1"
                }

                if(([xml](& $env:SystemRoot\system32\inetsrv\appcmd.exe list apppool $apName /config:*)).add.cpu.limit -eq "1")
                {
                    $testParams.cpuLimit = "0"
                }

                Test-TargetResource @testParams | Should be $false
            }

            Set-TargetResource @baseParams #need to remove after each test set so previous tests don't affect the next tests
            
            It 'Should set CPU Action' {
                $testParams =@{
                    Name = $apName
                    Ensure = "Present"
                    cpuAction = "Throttle"
                }

                if(([xml](& $env:SystemRoot\system32\inetsrv\appcmd.exe list apppool $apName /config:*)).add.cpu.action -eq "Throttle")
                {
                    $testParams.cpuAction = "NoAction"
                }

                Set-TargetResource @testParams
                ([xml](& $env:SystemRoot\system32\inetsrv\appcmd.exe list apppool $apName /config:*)).add.cpu.action -eq $testParams.cpuAction | Should be $true
            }

            It 'Passes CPU Action Test when same' {
                $testParams =@{
                    Name = $apName
                    Ensure = "Present"
                    cpuAction = "Throttle"
                }

                if(([xml](& $env:SystemRoot\system32\inetsrv\appcmd.exe list apppool $apName /config:*)).add.cpu.action -eq "NoAction")
                {
                    $testParams.cpuAction = "NoAction"
                }

                Test-TargetResource @testParams | Should be $true
            }

            It 'Fails CPU Action Test when different' {
                $testParams =@{
                    Name = $apName
                    Ensure = "Present"
                    cpuAction = "Throttle"
                }

                if(([xml](& $env:SystemRoot\system32\inetsrv\appcmd.exe list apppool $apName /config:*)).add.cpu.action -eq "Throttle")
                {
                    $testParams.cpuAction = "NoAction"
                }

                Test-TargetResource @testParams | Should be $false
            }

            Set-TargetResource @baseParams #need to remove after each test set so previous tests don't affect the next tests
            
            It 'Should set CPU Reset Interval' {
                $testParams =@{
                    Name = $apName
                    Ensure = "Present"
                    cpuResetInterval = "00:15:00"
                }

                if(([xml](& $env:SystemRoot\system32\inetsrv\appcmd.exe list apppool $apName /config:*)).add.cpu.resetInterval -eq "00:15:00")
                {
                    $testParams.cpuResetInterval = "00:05:00"
                }

                Set-TargetResource @testParams
                ([xml](& $env:SystemRoot\system32\inetsrv\appcmd.exe list apppool $apName /config:*)).add.cpu.resetInterval -eq $testParams.cpuResetInterval | Should be $true
            }

            It 'Passes CPU Reset Interval Test when same' {
                $testParams =@{
                    Name = $apName
                    Ensure = "Present"
                    cpuResetInterval = "00:15:00"
                }

                if(([xml](& $env:SystemRoot\system32\inetsrv\appcmd.exe list apppool $apName /config:*)).add.cpu.resetInterval -eq "00:05:00")
                {
                    $testParams.cpuResetInterval = "00:05:00"
                }

                Test-TargetResource @testParams | Should be $true
            }

            It 'Fails CPU Reset Interval Test when different' {
                $testParams =@{
                    Name = $apName
                    Ensure = "Present"
                    cpuResetInterval = "00:15:00"
                }

                if(([xml](& $env:SystemRoot\system32\inetsrv\appcmd.exe list apppool $apName /config:*)).add.cpu.resetInterval -eq "00:15:00")
                {
                    $testParams.cpuResetInterval = "00:05:00"
                }

                Test-TargetResource @testParams | Should be $false
            }

            Set-TargetResource @baseParams #need to remove after each test set so previous tests don't affect the next tests
            
            It 'Should set CPU Smp Affinitized' {
                $testParams =@{
                    Name = $apName
                    Ensure = "Present"
                    cpuSmpAffinitized = "true"
                }

                if(([xml](& $env:SystemRoot\system32\inetsrv\appcmd.exe list apppool $apName /config:*)).add.cpu.smpAffinitized -eq "true")
                {
                    $testParams.cpuSmpAffinitized = "false"
                }

                Set-TargetResource @testParams
                ([xml](& $env:SystemRoot\system32\inetsrv\appcmd.exe list apppool $apName /config:*)).add.cpu.smpAffinitized -eq $testParams.cpuSmpAffinitized | Should be $true
            }

            It 'Passes CPU Smp Affinitized Test when same' {
                $testParams =@{
                    Name = $apName
                    Ensure = "Present"
                    cpuSmpAffinitized = "true"
                }

                if(([xml](& $env:SystemRoot\system32\inetsrv\appcmd.exe list apppool $apName /config:*)).add.cpu.smpAffinitized -eq "false")
                {
                    $testParams.cpuSmpAffinitized = "false"
                }

                Test-TargetResource @testParams | Should be $true
            }

            It 'Fails CPU Smp Affinitized Test when different' {
                $testParams =@{
                    Name = $apName
                    Ensure = "Present"
                    cpuSmpAffinitized = "true"
                }

                if(([xml](& $env:SystemRoot\system32\inetsrv\appcmd.exe list apppool $apName /config:*)).add.cpu.smpAffinitized -eq "true")
                {
                    $testParams.cpuSmpAffinitized = "false"
                }

                Test-TargetResource @testParams | Should be $false
            }

            Set-TargetResource @baseParams #need to remove after each test set so previous tests don't affect the next tests
            
            It 'Should set CPU Smp Processor Affinity Mask' {
                $testParams =@{
                    Name = $apName
                    Ensure = "Present"
                    cpuSmpProcessorAffinityMask = "4294967294"
                }

                if(([xml](& $env:SystemRoot\system32\inetsrv\appcmd.exe list apppool $apName /config:*)).add.cpu.smpProcessorAffinityMask -eq "4294967294")
                {
                    $testParams.cpuSmpProcessorAffinityMask = "4294967295"
                }

                Set-TargetResource @testParams
                ([xml](& $env:SystemRoot\system32\inetsrv\appcmd.exe list apppool $apName /config:*)).add.cpu.smpProcessorAffinityMask -eq $testParams.cpuSmpProcessorAffinityMask | Should be $true
            }

            It 'Passes CPU Smp Processor Affinity Mask Test when same' {
                $testParams =@{
                    Name = $apName
                    Ensure = "Present"
                    cpuSmpProcessorAffinityMask = "4294967294"
                }

                if(([xml](& $env:SystemRoot\system32\inetsrv\appcmd.exe list apppool $apName /config:*)).add.cpu.smpProcessorAffinityMask -eq "4294967295")
                {
                    $testParams.cpuSmpProcessorAffinityMask = "4294967295"
                }

                Test-TargetResource @testParams | Should be $true
            }

            It 'Fails CPU Smp Processor Affinity Mask Test when different' {
                $testParams =@{
                    Name = $apName
                    Ensure = "Present"
                    cpuSmpProcessorAffinityMask = "4294967294"
                }

                if(([xml](& $env:SystemRoot\system32\inetsrv\appcmd.exe list apppool $apName /config:*)).add.cpu.smpProcessorAffinityMask -eq "4294967294")
                {
                    $testParams.cpuSmpProcessorAffinityMask = "4294967295"
                }

                Test-TargetResource @testParams | Should be $false
            }

            Set-TargetResource @baseParams #need to remove after each test set so previous tests don't affect the next tests
            
            It 'Should set CPU Smp Processor Affinity Mask 2' {
                $testParams =@{
                    Name = $apName
                    Ensure = "Present"
                    cpuSmpProcessorAffinityMask2 = "4294967294"
                }

                if(([xml](& $env:SystemRoot\system32\inetsrv\appcmd.exe list apppool $apName /config:*)).add.cpu.smpProcessorAffinityMask2 -eq "4294967294")
                {
                    $testParams.cpuSmpProcessorAffinityMask2 = "4294967295"
                }

                Set-TargetResource @testParams
                ([xml](& $env:SystemRoot\system32\inetsrv\appcmd.exe list apppool $apName /config:*)).add.cpu.smpProcessorAffinityMask2 -eq $testParams.cpuSmpProcessorAffinityMask2 | Should be $true
            }

            It 'Passes CPU Smp Processor Affinity Mask 2 Test when same' {
                $testParams =@{
                    Name = $apName
                    Ensure = "Present"
                    cpuSmpProcessorAffinityMask2 = "4294967294"
                }

                if(([xml](& $env:SystemRoot\system32\inetsrv\appcmd.exe list apppool $apName /config:*)).add.cpu.smpProcessorAffinityMask2 -eq "4294967295")
                {
                    $testParams.cpuSmpProcessorAffinityMask2 = "4294967295"
                }

                Test-TargetResource @testParams | Should be $true
            }

            It 'Fails CPU Smp Processor Affinity Mask 2 Test when different' {
                $testParams =@{
                    Name = $apName
                    Ensure = "Present"
                    cpuSmpProcessorAffinityMask2 = "4294967294"
                }

                if(([xml](& $env:SystemRoot\system32\inetsrv\appcmd.exe list apppool $apName /config:*)).add.cpu.smpProcessorAffinityMask2 -eq "4294967294")
                {
                    $testParams.cpuSmpProcessorAffinityMask2 = "4294967295"
                }

                Test-TargetResource @testParams | Should be $false
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
