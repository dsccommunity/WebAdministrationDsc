
# Integration Test Config Template Version: 1.0.0
configuration MSFT_xIisModule_Present {

    Import-DscResource -ModuleName 'xWebAdministration'
    
    Node Localhost {

        xIisModule Integration_Test {
            Path = 'c:\php\php-cgi.exe'
            Name = 'TestModule'
            RequestPath = Join-Path -Path (Get-Location) -ChildPath TestModule
            Verb = @('Verb1','Verb2')
            Ensure = 'Present'
        }
    }
}

