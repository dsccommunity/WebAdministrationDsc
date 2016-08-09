function Invoke-WebAdministrationDscTests() {
    param
    (
        [Parameter(Mandatory = $false)]
        [System.String] $TestResultsFile,
        
        [Parameter(Mandatory = $false)]
        [System.String] $DscTestsPath
    )

    Write-Verbose 'Commencing xWebAdministration unit tests'

    $repoDir = Join-Path $PSScriptRoot '..' -Resolve

    $testCoverageFiles = @()
    Get-ChildItem "$repoDir\DSCResources\**\*.psm1" -Recurse | ForEach-Object { 
        if ($_.FullName -notlike '*\DSCResource.Tests\*') {
            $testCoverageFiles += $_.FullName    
        }
    }

    $testResultSettings = @{ }
    if ([String]::IsNullOrEmpty($TestResultsFile) -eq $false) {
        $testResultSettings.Add('OutputFormat', 'NUnitXml' )
        $testResultSettings.Add('OutputFile', $TestResultsFile)
    }
    
    Import-Module "$repoDir\WebAdministrationDsc.psd1"
    
    $versionsToTest = (Get-ChildItem (Join-Path $repoDir '\Tests\Unit\')).Name
    
    $testsToRun = @()
    $versionsToTest | ForEach-Object {
        $testsToRun += @(@{
                'Path' = "$repoDir\Tests\Unit\$_"
        })
    }
    
    if ($PSBoundParameters.ContainsKey('DscTestsPath') -eq $true) {
        $testsToRun += @{
            'Path' = $DscTestsPath
        }
    }

    $results = Invoke-Pester -Script $testsToRun -CodeCoverage $testCoverageFiles -PassThru @testResultSettings

    return $results

}

function Enable-Rdp
{
    #Enable SSL3
    [Net.ServicePointManager]::SecurityProtocol = 'Tls12'

    # get current IP
    $ip = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object {$_.InterfaceAlias -like '*ethernet*'}).IPAddress
    $port = 3389

    if($ip.StartsWith('192.168.') -or $ip.StartsWith('10.240.')) 
    {
        #new environment - behind NAT
        $port = 33800 + $ip.split('.')[3]
        $password = [Microsoft.Win32.Registry]::GetValue("HKEY_LOCAL_MACHINE\Software\Microsoft\Windows NT\CurrentVersion\Winlogon", "DefaultPassword", '')
    }
    else
    {
        # generate password
        $randomObj = New-Object System.Random
        $password = [string]::Empty
        1..12 | ForEach { $password = $password + [char]$randomObj.next(33,126) }

        # change password
        $objUser = [ADSI]("WinNT://$($env:computername)/appveyor")
        $objUser.SetPassword($password)
    }

    # get external IP
    $wc = (New-Object Net.WebClient)
    $wc.Headers.Add("User-Agent", "AppVeyor")
    $ip = $wc.DownloadString('https://www.appveyor.com/tools/my-ip.aspx').Trim()

    # allow RDP on firewall
    Enable-NetFirewallRule -DisplayName 'Remote Desktop - User Mode (TCP-in)'

    # place "lock" file
    $path = "$($env:USERPROFILE)\Desktop\Delete me to continue build.txt"
    Set-Content -Path $path -Value ''

    Write-Warning 'To connect this build worker via RDP:'
    Write-Warning "Server: $ip`:$port"
    Write-Warning 'Username: appveyor'
    Write-Warning "Password: $password"
    Write-Warning "There is 'Delete me to continue build.txt' file has been created on Desktop - delete it to continue the build."

    while($true) { if (-not (Test-Path $path)) { break; } else { Start-Sleep -Seconds 1 } }
}
