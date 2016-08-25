
# Integration Test Config Template Version: 1.0.0

$testParameters = @{
    Path = "$env:windir\notepad.exe"
    Name = 'TestModule'
    RequestPath = '*.php'
    Verb = @('Verb1','Verb2')
    EndPointSetup = $true
}

configuration MSFT_xIisModule_Present {

    Import-DscResource -ModuleName 'xWebAdministration'
    
    Node Localhost {

        xIisModule Integration_Test {
            Path = $testParameters.Path
            Name = $testParameters.Name
            RequestPath = $testParameters.RequestPath
            Verb = $testParameters.Verb
            Ensure = 'Present'
        }
    }
}

