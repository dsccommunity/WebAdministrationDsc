Import-Module (Join-Path $PSScriptRoot "..\Tests\xWebAdministration.TestHarness.psm1"  -Resolve)

$DscTestsPath = Join-Path $PSScriptRoot "..\Tests\Unit" -Resolve
if ((Test-Path $DscTestsPath) -eq $false) {
    Write-Warning "Unable to locate DscResource.Tests repo at '$DscTestsPath', common DSC resource tests will not be executed"
    Invoke-xWebAdministrationTests
} else {
    Invoke-xWebAdministrationTests -DscTestsPath $DscTestsPath
}
