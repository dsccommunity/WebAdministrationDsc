
# Integration Test Config Template Version: 1.0.0

$testParameters = @{
    Path = "C:\Users\localadmin\Documents\php-7.0.10-nts-Win32-VC14-x86\php-cgi.exe"
    Name = 'TestModule'
    RequestPath = '*.php'
    Verb = @('Verb0','Verb1')
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
#C:\Users\localadmin\Documents\php-7.0.10-nts-Win32-VC14-x86\php-cgi.exe
#$env:windir\notepad.exe
