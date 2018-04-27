$script:DSCModuleName   = 'xWebAdministration'
$script:DSCResourceName = 'MSFT_xWebSiteAlive'

#region HEADER

$script:moduleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
if ( (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests'))) -or `
     (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1'))) )
{
    & git @('clone','https://github.com/PowerShell/DscResource.Tests.git',(Join-Path -Path $script:moduleRoot -ChildPath '\DSCResource.Tests\'))
}

Import-Module -Name (Join-Path -Path $script:moduleRoot -ChildPath (Join-Path -Path 'DSCResource.Tests' -ChildPath 'TestHelper.psm1')) -Force

$TestEnvironment = Initialize-TestEnvironment `
    -DSCModuleName $script:DSCModuleName `
    -DSCResourceName $script:DSCResourceName `
    -TestType Unit

#endregion HEADER

# Begin Testing
try
{
    InModuleScope -ModuleName $script:DSCResourceName -ScriptBlock {

        Describe "$script:DSCResourceName\Get-TargetResource" {
        
            $mockWebBindings = @(
                @{
                    Protocol = 'http'
                    bindingInformation = '*:80:'
                }
            )

            $splat = @{
                WebSiteName = 'Default Web Site'
                RelativeUrl = '/test'
                ValidStatusCodes = 100, 200, 301
                ExpectedContent = @'
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<title>IIS Windows Server</title>
</head>
<body>
</body>
</html>
'@ -replace "`r`n", "`n"  # In the real execution DSC will send `n as line terminators
            }

            Context 'The website is alive' {
                $mockUrlResultOk = @{
                    StatusCode = 200
                    Content    = @'
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<title>IIS Windows Server</title>
</head>
<body>
</body>
</html>
'@
                }

                Mock -CommandName 'Get-WebBinding' -ParameterFilter { $Name -eq $splat.WebSiteName } -MockWith { return $mockWebBindings }

                Mock -CommandName 'Invoke-WebRequest' -MockWith { $mockUrlResultOk }

                $result = Get-TargetResource @splat

                It 'Should return Ensure' {
                    $result.Ensure | Should Be 'Present'
                }

                It 'Should return WebSiteName' {
                    $result.WebSiteName | Should Be $splat.WebSiteName
                }

                It 'Should return RelativeUrl' {
                    $result.RelativeUrl | Should Be $splat.RelativeUrl
                }

                It 'Should return ValidStatusCodes' {
                    $result.ValidStatusCodes | Should Be $splat.ValidStatusCodes
                }

                It 'Should return ExpectedContent' {
                    $result.ExpectedContent | Should Be $splat.ExpectedContent
                }
            }

            Context 'The website is not alive' {
                $mockUrlResultInternalServerError = @{
                    StatusCode = 500
                    Content    = ''
                }

                Mock -CommandName 'Get-WebBinding' -ParameterFilter { $Name -eq $splat.WebSiteName } -MockWith { return $mockWebBindings }

                Mock -CommandName 'Invoke-WebRequest' -MockWith { $mockUrlResultInternalServerError }

                It 'Should throw an error' {
                    { Get-TargetResource @splat } | Should Throw
                }
            }
        }

        Describe "$script:DSCResourceName\Set-TargetResource" {
            It 'Should throw an error' {
                $splat = @{
                    WebSiteName = 'Default Web Site'
                    RelativeUrl = '/'
                }

                { Set-TargetResource @splat } | Should Throw
            }
        }

        Describe "$script:DSCResourceName\Test-TargetResource" {

            $mockUrlResultOk = @{
                StatusCode = 200
                Content    = ''
            }

            Context 'There are multiple websites' {
                $mockWebBindings01 = @(
                    @{
                        Protocol = 'http'
                        bindingInformation = '*:2000:'
                    },
                    @{
                        Protocol = 'https'
                        bindingInformation = '*:3000:'
                    }
                )

                $mockWebBindings02 = @(
                    @{
                        Protocol = 'http'
                        bindingInformation = '*:4000:'
                    },
                    @{
                        Protocol = 'https'
                        bindingInformation = '*:5000:'
                    }
                )

                $mockWebBindings03 = @(
                    @{
                        Protocol = 'http'
                        bindingInformation = '*:6000:'
                    }
                )

                $splatWebsite02 = @{
                    WebSiteName = 'WebSite02'
                    RelativeUrl = '/'
                }

                Mock -CommandName 'Get-WebBinding' -ParameterFilter { $Name -eq 'WebSite01' } -MockWith { return $mockWebBindings01 }

                Mock -CommandName 'Get-WebBinding' -ParameterFilter { $Name -eq $splatWebsite02.WebSiteName } -MockWith { return $mockWebBindings02 }

                Mock -CommandName 'Get-WebBinding' -ParameterFilter { $Name -eq 'WebSite03' } -MockWith { return $mockWebBindings03 }

                Mock -CommandName 'Invoke-WebRequest' -MockWith { $mockUrlResultOk }

                Test-TargetResource @splatWebsite02

                It 'Should request the urls from the correct website' {
                    Assert-MockCalled -CommandName Invoke-WebRequest -Exactly 1 -ParameterFilter { $Uri -eq 'http://localhost:4000/' }
                    Assert-MockCalled -CommandName Invoke-WebRequest -Exactly 1 -ParameterFilter { $Uri -eq 'https://localhost:5000/' }
                }

                It 'Should not request the urls from the undesired websites' {
                    Assert-MockCalled -CommandName Invoke-WebRequest -Exactly 0 -ParameterFilter { $Uri -eq 'http://localhost:2000/' }
                    Assert-MockCalled -CommandName Invoke-WebRequest -Exactly 0 -ParameterFilter { $Uri -eq 'https://localhost:3000/' }
                    Assert-MockCalled -CommandName Invoke-WebRequest -Exactly 0 -ParameterFilter { $Uri -eq 'http://localhost:6000/' }
                }
            }

            Context 'There are multiple website bindings' {
                $mockWebBindings = @(
                    @{
                        Protocol = 'http'
                        bindingInformation = '*:80:'
                    },
                    @{
                        Protocol = 'http'
                        bindingInformation = '*:11000:'
                    },
                    @{
                        Protocol = 'http'
                        bindingInformation = '[::1]:12000:'
                    },
                    @{
                        Protocol = 'https'
                        bindingInformation = '[0:0:0:0:0:ffff:d1ad:35a7]:13000:www.domaintest.com'
                    },
                    @{
                        Protocol = 'net.tcp'
                        bindingInformation = '808:*'
                    }
                )

                $splat = @{
                    WebSiteName = 'Default Web Site'
                    RelativeUrl = '/'
                }

                Mock -CommandName 'Get-WebBinding' -ParameterFilter { $Name -eq $splat.WebSiteName } -MockWith { return $mockWebBindings }

                Mock -CommandName 'Invoke-WebRequest' -MockWith { $mockUrlResultOk }

                Test-TargetResource @splat

                It 'Should request the correct urls' {
                    Assert-MockCalled -CommandName Invoke-WebRequest -Exactly 1 -ParameterFilter { $Uri -eq 'http://localhost:80/' }
                    Assert-MockCalled -CommandName Invoke-WebRequest -Exactly 1 -ParameterFilter { $Uri -eq 'http://localhost:11000/' }
                    Assert-MockCalled -CommandName Invoke-WebRequest -Exactly 1 -ParameterFilter { $Uri -eq 'http://localhost:12000/' }
                    Assert-MockCalled -CommandName Invoke-WebRequest -Exactly 1 -ParameterFilter { $Uri -eq 'https://www.domaintest.com:13000/' }
                }

                It 'Should request only the correct protocols' {
                    Assert-MockCalled -CommandName Invoke-WebRequest -Exactly 0 -ParameterFilter { $Uri.ToString().StartsWith('net.tcp') }
                }
            }

            Context 'There are multiple website bindings and a relative URL is passed' {
                $mockWebBindings = @(
                    @{
                        Protocol = 'http'
                        bindingInformation = '[::1]:11000:'
                    },
                    @{
                        Protocol = 'https'
                        bindingInformation = '[0:0:0:0:0:ffff:d1ad:35a7]:12000:www.domaintest01.com'
                    },
                    @{
                        Protocol = 'net.tcp'
                        bindingInformation = '808:*'
                    },
                    @{
                        Protocol = 'http'
                        bindingInformation = '*:80:www.domaintest02.com'
                    },
                    @{
                        Protocol = 'http'
                        bindingInformation = '*:13000:'
                    }
                )

                $splat = @{
                    WebSiteName = 'Default Web Site'
                    RelativeUrl = '/relative/path/index.html'
                }

                Mock -CommandName 'Get-WebBinding' -ParameterFilter { $Name -eq $splat.WebSiteName } -MockWith { return $mockWebBindings }

                Mock -CommandName 'Invoke-WebRequest' -MockWith { $mockUrlResultOk }

                Test-TargetResource @splat

                It 'Should request the correct urls' {
                    Assert-MockCalled -CommandName Invoke-WebRequest -Exactly 1 -ParameterFilter { $Uri -eq 'http://localhost:11000/relative/path/index.html' }
                    Assert-MockCalled -CommandName Invoke-WebRequest -Exactly 1 -ParameterFilter { $Uri -eq 'https://www.domaintest01.com:12000/relative/path/index.html' }
                    Assert-MockCalled -CommandName Invoke-WebRequest -Exactly 1 -ParameterFilter { $Uri -eq 'http://www.domaintest02.com:80/relative/path/index.html' }
                    Assert-MockCalled -CommandName Invoke-WebRequest -Exactly 1 -ParameterFilter { $Uri -eq 'http://localhost:13000/relative/path/index.html' }
                
                }

                It 'Should request only the correct protocols' {
                    Assert-MockCalled -CommandName Invoke-WebRequest -Exactly 0 -ParameterFilter { $Uri.ToString().StartsWith('net.tcp') }
                }
            }
        
            $mockWebBindings = @(
                @{
                    Protocol = 'http'
                    bindingInformation = '*:21000:'
                }
            )
        
            $splat = @{
                WebSiteName = 'Default Web Site'
                RelativeUrl = '/test'
                ValidStatusCodes = 100, 200, 300
            }

            Context 'A list of valid status codes was passed and the website is alive' {
            
                Mock -CommandName 'Get-WebBinding' -ParameterFilter { $Name -eq $splat.WebSiteName } -MockWith { return $mockWebBindings }

                Mock -CommandName 'Invoke-WebRequest' -ParameterFilter { $Uri -eq 'http://localhost:21000/test' } -MockWith { $mockUrlResultOk }

                It 'Should be true' {
                    Test-TargetResource @splat | Should be $true
                }
            }

            Context 'A list of valid status codes was passed and the website is not alive' {
                $mockUrlResultInternalServerError = @{
                    StatusCode = 500
                    Content    = ''
                }

                Mock -CommandName 'Get-WebBinding' -ParameterFilter { $Name -eq $splat.WebSiteName } -MockWith { return $mockWebBindings }

                Mock -CommandName 'Invoke-WebRequest' -ParameterFilter { $Uri -eq 'http://localhost:21000/test' } -MockWith { $mockUrlResultInternalServerError }

                It 'Should be false' {
                    Test-TargetResource @splat | Should be $false
                }
            }
        
            $splat = @{
                WebSiteName = 'Default Web Site'
                RelativeUrl = '/test'
                ValidStatusCodes = 200
                ExpectedContent = @'
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<title>IIS Windows Server</title>
</head>
<body>
</body>
</html>
'@ -replace "`r`n", "`n"  # In the real execution DSC will send `n as line terminators
            }

            Context 'A expected content was passed and the result match' {

                $mockUrlResultContentMatch = @{
                    StatusCode = 200
                    Content    = @'
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<title>IIS Windows Server</title>
</head>
<body>
</body>
</html>
'@
                }

                Mock -CommandName 'Get-WebBinding' -ParameterFilter { $Name -eq $splat.WebSiteName } -MockWith { return $mockWebBindings }

                Mock -CommandName 'Invoke-WebRequest' -ParameterFilter { $Uri -eq 'http://localhost:21000/test' } -MockWith { $mockUrlResultContentMatch }

                It 'Should be true' {
                    Test-TargetResource @splat | Should be $true
                }
            }

            Context 'A expected content was passed and the result does not match' {

                $mockUrlResultContentDontMatch = @{
                    StatusCode = 200
                    Content    = @'
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<title>IIS Windows Server</title>
</head>
<body> diff
</body>
</html>
'@
                }

                Mock -CommandName 'Get-WebBinding' -ParameterFilter { $Name -eq $splat.WebSiteName } -MockWith { return $mockWebBindings }

                Mock -CommandName 'Invoke-WebRequest' -ParameterFilter { $Uri -eq 'http://localhost:21000/test' } -MockWith { $mockUrlResultContentDontMatch }

                It 'Should be false' {
                    Test-TargetResource @splat | Should be $false
                }
            }

            Context 'A expected content was passed and the website is not alive' {
                $mockUrlResultInternalServerError = @{
                    StatusCode = 500
                    Content    = @'
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<title>IIS Windows Server</title>
</head>
<body>
</body>
</html>
'@
                }

                Mock -CommandName 'Get-WebBinding' -ParameterFilter { $Name -eq $splat.WebSiteName } -MockWith { return $mockWebBindings }

                Mock -CommandName 'Invoke-WebRequest' -ParameterFilter { $Uri -eq 'http://localhost:21000/test' } -MockWith { $mockUrlResultInternalServerError }

                It 'Should be false' {
                    Test-TargetResource @splat | Should be $false
                }
            }
        }
    }
}
finally
{
    Restore-TestEnvironment -TestEnvironment $TestEnvironment
}
