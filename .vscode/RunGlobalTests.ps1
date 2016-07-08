Import-Module (Join-Path $PSScriptRoot "..\Tests\xWebAdministration.TestHarness.psm1"  -Resolve)

$DscTestsPath = Join-Path $PSScriptRoot "..\DSCResource.Tests" -Resolve
if ((Test-Path $DscTestsPath) -eq $false) {
    throw "Unable to locate DscResource.Tests repo at '$DscTestsPath', common DSC resource tests will not be executed"
}
Import-Module (Join-Path $PSScriptRoot "..\DscResource.Tests\TestHelper.psm1")

Set-Location (Join-Path $PSScriptRoot "..\DscResource.Tests")

Invoke-Pester
