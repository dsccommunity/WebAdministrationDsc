
# Integration Test Config Template Version: 1.0.0

$testParameters = @{
    Path = (Join-Path -Path (Get-Location) -ChildPath TestModule)
    Name = 'TestModule'
    RequestPath = 'c:\php\php-cgi.exe'
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

