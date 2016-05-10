function Invoke-xWebAdministrationTests() {
    param
    (
        [parameter(Mandatory = $false)] [System.String] $testResultsFile,
        [parameter(Mandatory = $false)] [System.String] $DscTestsPath
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
    if ([string]::IsNullOrEmpty($testResultsFile) -eq $false) {
        $testResultSettings.Add('OutputFormat', 'NUnitXml' )
        $testResultSettings.Add('OutputFile', $testResultsFile)
    }
    Import-Module "$repoDir\xWebAdministration.psd1"
    
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