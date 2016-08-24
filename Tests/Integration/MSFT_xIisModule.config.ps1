
# Integration Test Config Template Version: 1.0.0

$testParameters = @{
    Path = 'c:\php\php-cgi.exe'
    Name = 'TestModule'
    RequestPath = Join-Path -Path (Get-Location) -ChildPath TestModule
    Verb = @('Verb1','Verb2')
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

