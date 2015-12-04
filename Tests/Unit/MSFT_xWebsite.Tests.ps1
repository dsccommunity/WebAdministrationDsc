$DSCModuleName   = 'xWebAdministration'
$DSCResourceName = 'MSFT_xWebsite'

$Splat = @{
    Path = $PSScriptRoot
    ChildPath = "..\..\DSCResources\$DSCResourceName\$DSCResourceName.psm1"
    Resolve = $true
    ErrorAction = 'Stop'
}
$DSCResourceModuleFile = Get-Item -Path (Join-Path @Splat)

# should check for the server OS
if ($env:APPVEYOR_BUILD_VERSION)
{
    Add-WindowsFeature -Name Web-Server -Verbose
}

if (Get-Module -Name $DSCResourceName)
{
    Remove-Module -Name $DSCResourceName
}

Import-Module -Name $DSCResourceModuleFile.FullName -Force

$ModuleRoot = "${env:ProgramFiles}\WindowsPowerShell\Modules\$DSCModuleName"

if (-not (Test-Path -Path $ModuleRoot -PathType Container))
{
    New-Item -Path $ModuleRoot -ItemType Directory | Out-Null
}

Copy-Item -Path "$PSScriptRoot\..\..\*" -Destination $ModuleRoot -Recurse -Force -Exclude '.git'


InModuleScope -ModuleName $DSCResourceName -ScriptBlock {

    Describe "how MSFT_xWebsite\Test-TargetResource responds to Ensure = 'Present'" {

        $MockSite = @{
            Name            = 'MockName'
            Ensure          = 'Present'
            PhysicalPath    = 'C:\NonExistent'
            ID              = 1
            State           = 'Started'
            ApplicationPool = 'MockPool'
            DefaultPage     = 'MockDefault.htm'
        }

        $MockBindingInfo = New-CimInstance -ClassName MSFT_xWebBindingInformation -Namespace root/microsoft/Windows/DesiredStateConfiguration -Property @{
            Port      = [UInt16]80
            Protocol  = 'http'
            IPAddress = '*'
            HostName  = ''
        } -ClientOnly

        Context 'WebAdminstration module is not installed' {
            It 'should throw an error' {
                Mock Get-Module -ModuleName $ModuleName {return $null}

                {
                    Test-TargetResource -Name $MockSite.Name -Ensure $MockSite.Ensure -PhysicalPath $MockSite.PhysicalPath
                } | Should Throw 'Please ensure that WebAdministration module is installed.'
            }
        }

        Context 'Website does not exist' {
            It 'should return False' {
                Mock Get-Website {
                    return $null
                }

                $Result = Test-TargetResource -Name $MockSite.Name `
                                              -Ensure $MockSite.Ensure `
                                              -PhysicalPath $MockSite.PhysicalPath `
                                              -Verbose:$VerbosePreference

                $Result | Should Be $false
            }
        }

        Context 'Check PhysicalPath is different' {

            Mock Get-Website {
                return $MockSite
            }

            Mock Test-WebsitePath -ModuleName $ModuleName {
                return $true
            }

            $Result = Test-TargetResource -Name $MockSite.Name `
                                          -Ensure $MockSite.Ensure `
                                          -PhysicalPath $MockSite.PhysicalPath `
                                          -Verbose:$VerbosePreference

            It 'should return False' {
                $Result | Should Be $false
            }
        }

        Context 'Check State is different' {

            Mock Get-Website {
                return $MockSite
            }

            Mock Test-WebsitePath -ModuleName $ModuleName {
                return $false
            }

            $Result = Test-TargetResource -Name $MockSite.Name `
                                          -Ensure $MockSite.Ensure `
                                          -PhysicalPath $MockSite.PhysicalPath `
                                          -State 'Stopped' `
                                          -Verbose:$VerbosePreference

            It 'should return False' {
                $Result | Should Be $false
            }
        }

        Context 'Check ApplicationPool is different' {

            Mock Get-Website {
                return $MockSite
            }

            Mock Test-WebsitePath -ModuleName $ModuleName {
                return $false
            }

            $Result = Test-TargetResource -Name $MockSite.Name `
                                          -Ensure $MockSite.Ensure `
                                          -PhysicalPath $MockSite.PhysicalPath `
                                          -State $MockSite.State `
                                          -ApplicationPool 'MockPoolDifferent' `
                                          -Verbose:$VerbosePreference

            It 'should return False' {
                $Result | Should Be $false
            }
        }

        Context 'Check BindingInfo is different' {

            Mock Get-Website {
                return $MockSite
            }

            Mock Test-WebsitePath -ModuleName $ModuleName {
                return $false
            }

            Mock Test-WebsiteBinding -ModuleName $ModuleName -Name $Name -BindingInfo $BindingInfo {
                return $true
            }

            $Result = Test-TargetResource -Name $MockSite.Name `
                                          -Ensure $MockSite.Ensure `
                                          -PhysicalPath $MockSite.PhysicalPath `
                                          -State $MockSite.State `
                                          -ApplicationPool $MockSite.ApplicationPool `
                                          -BindingInfo $MockBindingInfo `
                                          -Verbose:$VerbosePreference

            It 'should return False' {
                $Result | Should Be $false
            }
        }

        Context 'Check DefaultPage is different' {

            Mock Get-Website {
                return $MockSite
            }

            Mock Test-WebsitePath {
                return $false
            }

            Mock Test-WebsiteBinding -ModuleName $ModuleName -Name $Name -BindingInfo $BindingInfo {
                return $false
            }

            Mock Get-WebConfiguration {
                return @{value = 'MockDifferent.htm'}
            }

            $Result = Test-TargetResource -Name $MockSite.Name `
                                          -Ensure $MockSite.Ensure `
                                          -PhysicalPath $MockSite.PhysicalPath `
                                          -State $MockSite.State `
                                          -ApplicationPool $MockSite.ApplicationPool `
                                          -BindingInfo $MockBindingInfo `
                                          -DefaultPage $MockSite.DefaultPage `
                                          -Verbose:$VerbosePreference

            It 'should return False' {
                $Result | Should Be $false
            }
        }
    }

    Describe "how MSFT_xWebsite\Get-TargetResource responds to Ensure = 'Present'" {

        $MockSite = @{
            Name            = 'MockName'
            Ensure          = 'Present'
            PhysicalPath    = 'C:\NonExistent'
            ID              = 1
            State           = 'Started'
            ApplicationPool = 'MockPool'
            DefaultPage     = 'MockDefault.htm'
        }

        $MockBindingInfo = New-CimInstance -ClassName MSFT_xWebBindingInformation -Namespace root/microsoft/Windows/DesiredStateConfiguration -Property @{
            Port      = [UInt16]80
            Protocol  = 'http'
            IPAddress = '*'
            HostName  = ''
        } -ClientOnly

        Context 'WebAdminstration module is not installed' {
            It 'should throw an error' {
                Mock Get-Module -ModuleName $ModuleName {
                    return $null
                }

                {
                    Get-TargetResource -Name $MockSite.Name -PhysicalPath $MockSite.PhysicalPath
                } | Should Throw 'Please ensure that WebAdministration module is installed.'
            }
        }

        Context 'Website does not exist' {
            Mock Get-Website {
                return $null
            }

            $Result = Get-TargetResource -Name $MockSite.Name -PhysicalPath $MockSite.PhysicalPath

            It 'should return Absent' {
                $Result.Ensure | Should Be 'Absent'
            }
        }

        Context 'There are multiple websites with the same name' {
            Mock Get-Website -ModuleName $ModuleName {
                return @(
                    [PSCustomObject]@{
                        Name = 'Site1'
                    },

                    [PSCustomObject]@{
                        Name = 'Site1'
                    }
                )
            }

            $errorId = 'WebsiteDiscoveryFailure'
            $errorCategory = [System.Management.Automation.ErrorCategory]::InvalidResult
            $errorMessage = $($LocalizedData.WebsiteDiscoveryFailureError) -f 'Site1'
            $exception = New-Object -TypeName System.InvalidOperationException -ArgumentList $errorMessage
            $errorRecord = New-Object -TypeName System.Management.Automation.ErrorRecord -ArgumentList $exception, $errorId, $errorCategory, $null

            It 'should throw the correct error' {
                {
                    Get-TargetResource -Name 'Site1' -PhysicalPath 'C:\SomePath'
                } | Should Throw $errorRecord
            }
        }

        Context 'Single website exists' {

            $MockBindingRaw = @{
                bindingInformation   = '*:443:MockHostName'
                protocol             = 'https'
                certificateHash      = '3E09CCC8DFDCB8E3D4A83CFF164CC4754C25E9E5'
                certificateStoreName = 'My'
                sslFlags             = '1'
            }

            $MockSite = @{
                Name            = 'MockName'
                PhysicalPath    = 'C:\NonExistent'
                ID              = 1
                State           = 'Started'
                ApplicationPool = 'MockPool'
                DefaultPage     = 'MockDefault.htm'
                Bindings        = @{Collection = @($MockBindingRaw)}
                Count           = 1
            }

            $MockBindingCustom = @{
                IPAddress             = '*'
                Port                  = 443
                HostName              = 'MockHostName'
                Protocol              = 'https'
                CertificateThumbprint = '3E09CCC8DFDCB8E3D4A83CFF164CC4754C25E9E5'
                CertificateStoreName  = 'My'
                SslFlags              = '1'
            }

            Mock Get-Website {
                return $MockSite
            }

            Mock Get-WebConfiguration {
                return $null
            }

            It 'should not throw an error' {
                {
                    Get-TargetResource -Name $MockSite.Name -PhysicalPath $MockSite.PhysicalPath
                } | Should Not Throw
            }

            $Result = Get-TargetResource -Name $MockSite.Name -PhysicalPath $MockSite.PhysicalPath

            It 'should call Get-Website once' {
                Assert-MockCalled -CommandName Get-Website
            }

            It 'should return the Name' {
                $Result.Name | Should Be $MockSite.Name
            }

            It 'should return the Ensure' {
                $Result.Ensure | Should Be 'Present'
            }

            It 'should return the PhysicalPath' {
                $Result.PhysicalPath | Should Be $MockSite.PhysicalPath
            }

            It 'should return the BindingInfo' {
                $Result.BindingInfo.IPAddress             | Should Be $MockBindingCustom.IPAddress
                $Result.BindingInfo.Port                  | Should Be $MockBindingCustom.Port
                $Result.BindingInfo.HostName              | Should Be $MockBindingCustom.HostName
                $Result.BindingInfo.Protocol              | Should Be $MockBindingCustom.Protocol
                $Result.BindingInfo.CertificateThumbprint | Should Be $MockBindingCustom.CertificateThumbprint
                $Result.BindingInfo.CertificateStoreName  | Should Be $MockBindingCustom.CertificateStoreName
                $Result.BindingInfo.SslFlags              | Should Be $MockBindingCustom.SslFlags
            }

            It 'should return the State' {
                $Result.State | Should Be $MockSite.State
            }

            It 'should return the ID' {
                $Result.ID | Should Be $MockSite.ID
            }
        }
    }

    Describe "how MSFT_xWebsite\Set-TargetResource responds to Ensure = 'Present'" {

        $MockSite = @{
            Ensure          = 'Present'
            Name            = 'MockName'
            PhysicalPath    = 'C:\NonExistent'
            ID              = 1
            State           = 'Stopped'
            ApplicationPool = 'MockPool'
            DefaultPage     = 'index.htm'
        }

        $MockBindingCustom = @{
            Port                  = 80
            Protocol              = 'http'
            IPAddress             = '127.0.0.1'
            HostName              = 'MockHostName'
            CertificateThumbprint = ''
            CertificateStoreName  = ''
        }

        $MockBindingInfo = New-CimInstance -ClassName MSFT_xWebBindingInformation -Namespace root/microsoft/Windows/DesiredStateConfiguration -Property @{
            Port      = [UInt16]$MockBindingCustom.Port
            Protocol  = $MockBindingCustom.Protocol
            IPAddress = $MockBindingCustom.IPAddress
            HostName  = $MockBindingCustom.HostName
        } -ClientOnly

        $MockSite2 = @{
            Ensure          = 'Present'
            Name            = 'MockName2'
            PhysicalPath    = 'C:\NonExistent2'
            ID              = 1
            State           = 'Stopped'
            ApplicationPool = 'MockPool2'
            DefaultPage     = 'index2.htm'
            BindingInfo     =  $MockBindingInfo
        }

        Context 'Everything needs to be updated and website is started' {

            Mock Get-Website {
                return @($MockSite, $MockSite2)
            }
            Mock Start-Website {return $null}
            Mock Test-WebsitePath {return $true}
            Mock Set-ItemProperty {return $null}
            Mock Test-WebsiteBinding {return $true}
            Mock Update-WebsiteBinding {return $null}
            Mock Update-DefaultPage {return $null}
            Mock Confirm-UniqueBindingInfo {return $true}
            Mock Get-TargetResource {return $MockSite2}

            $Result = Set-TargetResource -Ensure 'Present' `
                                         -Name $MockSite.Name `
                                         -PhysicalPath $MockSite.PhysicalPath `
                                         -State 'Started' `
                                         -ApplicationPool 'MockPool2' `
                                         -BindingInfo $MockBindingInfo `
                                         -DefaultPage $MockSite.DefaultPage

            It 'should call all the mocks' {
                Assert-MockCalled -CommandName Test-WebsitePath
                Assert-MockCalled -CommandName Set-ItemProperty -Exactly 2
                Assert-MockCalled -CommandName Update-WebsiteBinding
                Assert-MockCalled -CommandName Update-DefaultPage
                Assert-MockCalled -CommandName Confirm-UniqueBindingInfo
                Assert-MockCalled -CommandName Get-TargetResource
                Assert-MockCalled -CommandName Start-Website   
            }
        }

        Context 'Confirm-UniqueBindingInfo returns False' {

            Mock Get-Website {return @($MockSite, $MockSite2)}
            Mock Start-Website {return $null}
            Mock Test-WebsitePath {return $true}
            Mock Set-ItemProperty {return $null}
            Mock Test-WebsiteBinding { return $true}
            Mock Update-WebsiteBinding {return $null}
            Mock Update-DefaultPage {return $null}
            Mock Confirm-UniqueBindingInfo {return $false}
            Mock Get-TargetResource {return $MockSite2}

            It 'should throw the correct error' {
                $errorId = 'WebsiteBindingConflictOnStart'
                $errorCategory = [System.Management.Automation.ErrorCategory]::InvalidResult
                $errorMessage = $($LocalizedData.WebsiteBindingConflictOnStartError) -f $MockSite.Name
                $exception = New-Object -TypeName System.InvalidOperationException -ArgumentList $errorMessage
                $errorRecord = New-Object -TypeName System.Management.Automation.ErrorRecord -ArgumentList $exception, $errorId, $errorCategory, $null

                {
                    Set-TargetResource -Ensure 'Present' `
                                       -Name $MockSite.Name `
                                       -PhysicalPath $MockSite.PhysicalPath `
                                       -State 'Started' `
                                       -ApplicationPool 'MockPool2' `
                                       -BindingInfo $MockBindingInfo `
                                       -DefaultPage $MockSite.DefaultPage
                } | Should Throw $errorRecord
            }
        }

        Context 'Start-Website throws an error' {
            Mock Get-Website {
                return @($MockSite, $MockSite2)
            }
            Mock Start-Website {return throw}
            Mock Test-WebsitePath {return $true}
            Mock Set-ItemProperty {return $null}
            Mock Test-WebsiteBinding {return $true}
            Mock Update-WebsiteBinding {return $null }
            Mock Update-DefaultPage {return $null}
            Mock Confirm-UniqueBindingInfo {return $true}
            Mock Get-TargetResource {return $MockSite2}

            It 'Should throw the correct error' {
                $errorId = 'WebsiteStateFailure'
                $errorCategory = [System.Management.Automation.ErrorCategory]::InvalidOperation
                $errorMessage = $($LocalizedData.WebsiteStateFailureError) -f $MockSite.Name
                $errorMessage += $_.Exception.Message
                $exception = New-Object -TypeName System.InvalidOperationException -ArgumentList $errorMessage
                $errorRecord = New-Object -TypeName System.Management.Automation.ErrorRecord -ArgumentList $exception, $errorId, $errorCategory, $null

                {
                    Set-TargetResource -Ensure 'Present' `
                                       -Name $MockSite.Name `
                                       -PhysicalPath $MockSite.PhysicalPath `
                                       -State 'Started' `
                                       -ApplicationPool 'MockPool2' `
                                       -BindingInfo $MockBinding `
                                       -DefaultPage $MockSite.DefaultPage
                } | Should Throw $errorRecord
            }
        }

        Context 'Everything needs to be updated and website is stopped' {

            $MockSite = @{
                Ensure          = 'Present'
                Name            = 'MockName'
                PhysicalPath    = 'C:\NonExistent'
                ID              = 1
                State           = 'Started'
                ApplicationPool = 'MockPool'
                DefaultPage     = 'index.htm'
            }

            Mock Get-Website {
                return @($MockSite, $MockSite2)
            }
            Mock Stop-Website {return $null}
            Mock Test-WebsitePath {return $true}
            Mock Set-ItemProperty {return $null}
            Mock Test-WebsiteBinding {return $true}
            Mock Update-WebsiteBinding {return $null}
            Mock Update-DefaultPage {return $null}
            Mock Confirm-UniqueBindingInfo {return $true}

            $Result = Set-TargetResource -Ensure 'Present' `
                                         -Name $MockSite.Name `
                                         -PhysicalPath $MockSite.PhysicalPath `
                                         -State 'Stopped' `
                                         -ApplicationPool 'MockPool2' `
                                         -BindingInfo $MockBindingInfo `
                                         -DefaultPage $MockSite.DefaultPage

            It 'should call all the mocks' {
                Assert-MockCalled -CommandName Test-WebsitePath
                Assert-MockCalled -CommandName Set-ItemProperty -Exactly 2
                Assert-MockCalled -CommandName Update-WebsiteBinding
                Assert-MockCalled -CommandName Update-DefaultPage
                Assert-MockCalled -CommandName Stop-Website 
            }
        }

        Context 'Website does not exist' {
            $MockSite = @{
                Ensure          = 'Present'
                Name            = 'MockName'
                PhysicalPath    = 'C:\NonExistent'
                ID              = 1
                State           = 'Started'
                ApplicationPool = 'MockPool'
                DefaultPage     = 'index.htm'
            }

            Mock Get-Website {
                return $MockSite
            }

            Mock New-Website {return $null}
            Mock Stop-Website {return $null}
            Mock Test-WebsiteBinding {return $true}
            Mock Update-WebsiteBinding {return $null}
            Mock Update-DefaultPage {return $null}
            Mock Start-Website {return $true}
            Mock Get-ItemProperty {return $null}

            $Result = Set-TargetResource -Ensure 'Present' `
                                         -Name 'MockName2' `
                                         -PhysicalPath $MockSite.PhysicalPath `
                                         -State 'Started' `
                                         -ApplicationPool 'MockPool2' `
                                         -BindingInfo $MockBindingInfo `
                                         -DefaultPage $MockSite.DefaultPage

            It 'should call all the mocks' {
                 Assert-MockCalled -CommandName New-Website
                 Assert-MockCalled -CommandName Stop-Website
                 Assert-MockCalled -CommandName Test-WebsiteBinding
                 Assert-MockCalled -CommandName Update-WebsiteBinding
                 Assert-MockCalled -CommandName Update-DefaultPage
                 Assert-MockCalled -CommandName Start-Website
            }
        }

        Context 'Error on website creation' {
            Mock New-Website {
                throw
            }

            It 'should throw the correct error' {
                $errorId = 'WebsiteCreationFailure'
                $errorCategory = [System.Management.Automation.ErrorCategory]::InvalidOperation
                $errorMessage = $($LocalizedData.WebsiteCreationFailureError) -f 'MockName2'
                $errorMessage += $_.Exception.Message
                $exception = New-Object -TypeName System.InvalidOperationException -ArgumentList $errorMessage
                $errorRecord = New-Object -TypeName System.Management.Automation.ErrorRecord -ArgumentList $exception, $errorId, $errorCategory, $null

                {
                    $Result = Set-TargetResource -Ensure 'Present' `
                                                 -Name 'MockName2' `
                                                 -PhysicalPath $MockSite.PhysicalPath `
                                                 -State 'Started' `
                                                 -ApplicationPool 'MockPool2' `
                                                 -BindingInfo $MockBindingInfo `
                                                 -DefaultPage $MockSite.DefaultPage
                } | Should Throw $errorRecord
            }
        }
    }

    Describe "how MSFT_xWebsite\Set-TargetResource responds to Ensure = 'Absent'" {

        It 'should call Remove-Website' {

            $MockSite = @{
                Ensure          = 'Present'
                Name            = 'MockName'
                PhysicalPath    = 'C:\NonExistent'
                ID              = 1
                State           = 'Stopped'
                ApplicationPool = 'MockPool'
                DefaultPage     = 'index.htm'
            }

            $MockBindingCustom = @{
                Port                  = 80
                Protocol              = 'http'
                IPAddress             = '127.0.0.1'
                HostName              = 'MockHostName'
                CertificateThumbprint = ''
                CertificateStoreName  = ''
            }

            $MockBindingInfo = New-CimInstance -ClassName MSFT_xWebBindingInformation -Namespace root/microsoft/Windows/DesiredStateConfiguration `
                -Property @{
                    Port      = [UInt16]$MockBindingCustom.Port
                    Protocol  = $MockBindingCustom.Protocol
                    IPAddress = $MockBindingCustom.IPAddress
                    HostName  = $MockBindingCustom.HostName
                } -ClientOnly

            Mock Get-Website {return $MockSite}
            Mock Remove-Website {return $null}

            $Result = Set-TargetResource -Ensure 'Absent' `
                                         -Name $MockSite.Name `
                                         -PhysicalPath $MockSite.PhysicalPath `
                                         -State 'Started' `
                                         -ApplicationPool 'MockPool2' `
                                         -BindingInfo $MockBindingInfo `
                                         -DefaultPage $MockSite.DefaultPage

            Assert-MockCalled -CommandName Get-Website
            Assert-MockCalled -CommandName Remove-Website
        }

        It 'should throw the correct error' {

            $MockSite = @{
                Ensure          = 'Present'
                Name            = 'MockName'
                PhysicalPath    = 'C:\NonExistent'
                ID              = 1
                State           = 'Stopped'
                ApplicationPool = 'MockPool'
                DefaultPage     = 'index.htm'
            }

            $MockBindingCustom = @{
                Port                  = 80
                Protocol              = 'http'
                IPAddress             = '127.0.0.1'
                HostName              = 'MockHostName'
                CertificateThumbprint = ''
                CertificateStoreName  = ''
            }

            $MockBindingInfo = New-CimInstance -ClassName MSFT_xWebBindingInformation -Namespace root/microsoft/Windows/DesiredStateConfiguration -Property @{
                Port      = [UInt16]$MockBindingCustom.Port
                Protocol  = $MockBindingCustom.Protocol
                IPAddress = $MockBindingCustom.IPAddress
                HostName  = $MockBindingCustom.HostName
            } -ClientOnly

            Mock Get-Website {return $MockSite}
            Mock Remove-Website {throw}

            $errorId = 'WebsiteRemovalFailure'
            $errorCategory = [System.Management.Automation.ErrorCategory]::InvalidOperation
            $errorMessage = $($LocalizedData.WebsiteRemovalFailureError) -f $MockSite.Name
            $errorMessage += $_.Exception.Message
            $exception = New-Object -TypeName System.InvalidOperationException -ArgumentList $errorMessage
            $errorRecord = New-Object -TypeName System.Management.Automation.ErrorRecord -ArgumentList $exception, $errorId, $errorCategory, $null

            {
                Set-TargetResource -Ensure 'Absent' `
                                   -Name $MockSite.Name `
                                   -PhysicalPath $MockSite.PhysicalPath `
                                   -State 'Started' `
                                   -ApplicationPool 'MockPool2' `
                                   -BindingInfo $MockBinding `
                                   -DefaultPage $MockSite.DefaultPage
            } | Should Throw $errorRecord
        }
    }

    Describe 'MSFT_xWebsite\ConvertTo-CimBinding' {

        Context 'IPv4 address is passed and the protocol is http' {

            $MockBindingRaw = @{
                bindingInformation = '127.0.0.1:80:MockHostName'
                protocol           = 'http'
            }

            $Result = ConvertTo-CimBinding -InputObject $MockBindingRaw

            It 'should return the IPv4 Address' {
                $Result.IPAddress | Should Be '127.0.0.1'
            }

            It 'should return the Protocol' {
                $Result.Protocol | Should Be 'http'
            }

            It 'should return the HostName' {
                $Result.HostName | Should Be 'MockHostName'
            }

            It 'should return the Port' {
                $Result.Port | Should Be '80'
            }
        }

        Context 'IPv6 address is passed and the protocol is http' {

            $MockBindingRaw =  @{
                bindingInformation = '[0:0:0:0:0:0:0:1]:80:MockHostName'
                protocol           = 'http'
            }

            $Result = ConvertTo-CimBinding -InputObject $MockBindingRaw

            It 'should return the IPv6 Address' {
                $Result.IPAddress | Should Be '0:0:0:0:0:0:0:1'
            }

            It 'should return the Protocol' {
                $Result.Protocol | Should Be 'http'
            }

            It 'should return the HostName' {
                $Result.HostName | Should Be 'MockHostName'
            }

            It 'should return the Port' {
                $Result.Port | Should Be '80'
            }
        }

        Context 'IPv4 address with SSL certificate is passed' {

            $MockBindingRaw =  @{
                bindingInformation   = '127.0.0.1:443:MockHostName'
                protocol             = 'https'
                certificateHash      = '3E09CCC8DFDCB8E3D4A83CFF164CC4754C25E9E5'
                certificateStoreName = 'My'
                sslFlags             = '1'
            }

            $Result = ConvertTo-CimBinding -InputObject $MockBindingRaw

            It 'should return the IPv4 Address' {
                $Result.IPAddress | Should Be '127.0.0.1'
            }

            It 'should return the Protocol' {
                $Result.Protocol | Should Be 'https'
            }

            It 'should return the HostName' {
                $Result.HostName | Should Be 'MockHostName'
            }

            It 'should return the Port' {
                $Result.Port | Should Be '443'
            }

            It 'should return the CertificateThumbprint' {
                $Result.CertificateThumbprint | Should Be '3E09CCC8DFDCB8E3D4A83CFF164CC4754C25E9E5'
            }

            It 'should return the CertificateStoreName' {
                $Result.CertificateStoreName | Should Be 'My'
            }

            It 'should return the SslFlags' {
                $Result.SslFlags | Should Be '1'
            }
        }

        Context 'IPv6 address with SSL certificate is passed' {

            $MockBindingRaw = @{
                bindingInformation   = '[0:0:0:0:0:0:0:1]:443:MockHostName'
                protocol             = 'https'
                certificateHash      = '3E09CCC8DFDCB8E3D4A83CFF164CC4754C25E9E5'
                certificateStoreName = 'My'
                sslFlags             = '1'
            }

            $Result = ConvertTo-CimBinding -InputObject $MockBindingRaw

            It 'should return the IPv6 Address' {
                $Result.IPAddress | Should Be '0:0:0:0:0:0:0:1'
            }

            It 'should return the Protocol' {
                $Result.Protocol | Should Be 'https'
            }

            It 'should return the HostName' {
                $Result.HostName | Should Be 'MockHostName'
            }

            It 'should return the Port' {
                $Result.Port | Should Be '443'
            }

            It 'should return the CertificateThumbprint' {
                $Result.CertificateThumbprint | Should Be '3E09CCC8DFDCB8E3D4A83CFF164CC4754C25E9E5'
            }

            It 'should return the CertificateStoreName' {
                $Result.CertificateStoreName | Should Be 'My'
            }

            It 'should return the SslFlags' {
                $Result.SslFlags | Should Be '1'
            }
        }

    }

    Describe 'MSFT_xWebsite\Test-WebsitePath' {
        Context 'the path is wrong' {
            It 'Should return True' {
                Mock Get-ItemProperty {
                    return 'C:\WrongPath'
                }

                Test-WebsitePath -Name 'SomeSite' -PhysicalPath 'C:\RightPath' | Should Be $true
            }
        }

        Context 'the path is correct' {
            It 'Should return False if the path does not need to be updated' {
                Mock Get-ItemProperty {
                    return 'C:\RightPath'
                }

                Test-WebsitePath -Name 'SomeSite' -PhysicalPath 'C:\RightPath' | Should Be $false
            }
        }
    }

    Describe 'MSFT_xWebsite\Confirm-UniqueBindingInfo' {
        Context 'bindings are not unique' {
            It 'should return False' {
                $MockBindingCustom = @{
                    Port                  = 80
                    Protocol              = 'http'
                    IPAddress             = '127.0.0.1'
                    HostName              = 'MockHostName'
                    CertificateThumbprint = ''
                    CertificateStoreName  = ''
                }

                $MockBindingInfo = New-CimInstance -ClassName MSFT_xWebBindingInformation -Namespace root/microsoft/Windows/DesiredStateConfiguration -Property @{
                    Port      = [UInt16]$MockBindingCustom.Port
                    Protocol  = $MockBindingCustom.Protocol
                    IPAddress = $MockBindingCustom.IPAddress
                    HostName  = $MockBindingCustom.HostName
                } -ClientOnly

                $BindingArray = @($MockBindingInfo, $MockBindingInfo)

                Confirm-UniqueBindingInfo -Port $MockBindingCustom.Port -IPAddress $MockBindingCustom.IPAddress -HostName $MockBindingCustom.HostName -BindingInfo $BindingArray | Should Be $false
            }
        }

        Context 'bindings are unique' {
            It 'should return True' {
                $MockBindingCustom = @{
                    Port                  = 80
                    Protocol              = 'http'
                    IPAddress             = '127.0.0.1'
                    HostName              = 'MockHostName'
                    CertificateThumbprint = ''
                    CertificateStoreName  = ''
                }

                $MockBindingInfo = New-CimInstance -ClassName MSFT_xWebBindingInformation -Namespace root/microsoft/Windows/DesiredStateConfiguration -Property @{
                    Port      = [UInt16]$MockBindingCustom.Port
                    Protocol  = $MockBindingCustom.Protocol
                    IPAddress = $MockBindingCustom.IPAddress
                    HostName  = $MockBindingCustom.HostName
                } -ClientOnly

                $BindingArray = @($MockBindingInfo)

                Confirm-UniqueBindingInfo -Port $MockBindingCustom.Port -IPAddress $MockBindingCustom.IPAddress -HostName $MockBindingCustom.HostName -BindingInfo $BindingArray | Should Be $true
            }
        }
    }

    Describe 'MSFT_xWebsite\Test-WebsiteBinding' {

        $MockBindingRawToDiff = @{
            bindingInformation   = '*:80:'
            protocol             = 'http'
            certificateHash      = ''
            certificateStoreName = ''
            sslFlags             = '0'
        }

        $MockSite = @{
            Name     = 'MockHostName'
            Bindings = @{Collection = @($MockBindingRawToDiff)}
        }

        Mock Get-WebSite {return $MockSite}

        Context 'Confirm-UniqueBindingInfo returns False' {

            $MockBindingInfo = @(
                New-CimInstance -ClassName MSFT_xWebBindingInformation -Namespace root/microsoft/Windows/DesiredStateConfiguration -Property @{
                    IPAddress             = '*'
                    Port                  = [UInt16]80
                    HostName              = ''
                    Protocol              = 'http'
                    CertificateThumbprint = ''
                    CertificateStoreName  = ''
                    SslFlags              = '0'
                } -ClientOnly
            )

            It 'should throw the correct error' {

                Mock Confirm-UniqueBindingInfo {return $false}

                $errorId = 'WebsiteBindingInputInvalidation'
                $errorCategory = [System.Management.Automation.ErrorCategory]::InvalidResult
                $errorMessage = $($LocalizedData.WebsiteBindingInputInvalidationError) -f $MockSite.Name
                $exception = New-Object -TypeName System.InvalidOperationException -ArgumentList $errorMessage
                $errorRecord = New-Object -TypeName System.Management.Automation.ErrorRecord -ArgumentList $exception, $errorId, $errorCategory, $null

                {
                    Test-WebsiteBinding -Name $MockSite.Name -BindingInfo $MockBindingInfo
                } | Should Throw $errorRecord
            }

        }

        Context 'Bindings comparison throws an error' {

            $MockBindingInfo = @(
                New-CimInstance -ClassName MSFT_xWebBindingInformation -Namespace root/microsoft/Windows/DesiredStateConfiguration -Property @{
                    IPAddress             = '*'
                    Port                  = [UInt16]80
                    HostName              = ''
                    Protocol              = 'http'
                    CertificateThumbprint = ''
                    CertificateStoreName  = ''
                    SslFlags              = '0'
                } -ClientOnly
            )

            $errorId = 'WebsiteCompareFailure'
            $errorCategory = [System.Management.Automation.ErrorCategory]::InvalidResult
            $errorMessage = $($LocalizedData.WebsiteCompareFailureError) -f $MockBindingCustom.HostName
            $errorMessage += $_.Exception.Message
            $exception = New-Object -TypeName System.InvalidOperationException -ArgumentList $errorMessage
            $errorRecord = New-Object -TypeName System.Management.Automation.ErrorRecord -ArgumentList $exception, $errorId, $errorCategory, $null

            It 'should not return an error' {
                {
                    Test-WebsiteBinding -Name $MockSite.Name -BindingInfo $MockBindingInfo
                } | Should Not Throw $errorRecord
            }
        }

        Context 'Port is different' {

            $MockBindingInfo = @(
                New-CimInstance -ClassName MSFT_xWebBindingInformation -Namespace root/microsoft/Windows/DesiredStateConfiguration -Property @{
                    IPAddress             = '*'
                    Port                  = [UInt16]8080
                    HostName              = ''
                    Protocol              = 'http'
                    CertificateThumbprint = ''
                    CertificateStoreName  = ''
                    SslFlags              = '0'
                } -ClientOnly
            )

            It 'should return True' {
                Test-WebsiteBinding -Name $MockSite.Name -BindingInfo $MockBindingInfo | Should Be $true
            }
        }

        Context 'Protocol is different' {

            $MockBindingInfo = @(
                New-CimInstance -ClassName MSFT_xWebBindingInformation -Namespace root/microsoft/Windows/DesiredStateConfiguration -Property @{
                    IPAddress             = '*'
                    Port                  = [UInt16]80
                    HostName              = ''
                    Protocol              = 'https'
                    CertificateThumbprint = ''
                    CertificateStoreName  = ''
                    SslFlags              = '0'
                } -ClientOnly
            )

            It 'should return True' {
                Test-WebsiteBinding -Name $MockSite.Name -BindingInfo $MockBindingInfo | Should Be $true
            }
        }

        Context 'IPAddress is different' {

            $MockBindingInfo = @(
                New-CimInstance -ClassName MSFT_xWebBindingInformation -Namespace root/microsoft/Windows/DesiredStateConfiguration -Property @{
                    IPAddress             = '192.168.1.16'
                    Port                  = [UInt16]80
                    HostName              = ''
                    Protocol              = 'http'
                    CertificateThumbprint = ''
                    CertificateStoreName  = ''
                    SslFlags              = '0'
                } -ClientOnly
            )

            It 'should return True' {
                Test-WebsiteBinding -Name $MockSite.Name -BindingInfo $MockBindingInfo | Should Be $true
            }
        }

        Context 'HostName is different' {

            $MockBindingInfo = @(
                New-CimInstance -ClassName MSFT_xWebBindingInformation -Namespace root/microsoft/Windows/DesiredStateConfiguration -Property @{
                    IPAddress             = '*'
                    Port                  = [UInt16]80
                    HostName              = 'MockHostName'
                    Protocol              = 'http'
                    CertificateThumbprint = ''
                    CertificateStoreName  = ''
                    SslFlags              = '0'
                } -ClientOnly
            )

            It 'should return True' {
                Test-WebsiteBinding -Name $MockSite.Name -BindingInfo $MockBindingInfo | Should Be $true
            }
        }

        Context 'CertificateThumbprint is different' {

            $MockBindingInfo = @(
                New-CimInstance -ClassName MSFT_xWebBindingInformation -Namespace root/microsoft/Windows/DesiredStateConfiguration -Property @{
                    IPAddress             = '*'
                    Port                  = [UInt16]443
                    HostName              = ''
                    Protocol              = 'https'
                    CertificateThumbprint = '1D3324C6E2F7ABC794C9CB6CA426B8D0F81045CD'
                    CertificateStoreName  = 'My'
                    SslFlags              = '0'
                } -ClientOnly
            )

            $MockBindingRawToDiff = @{
                bindingInformation   = '*:443:'
                protocol             = 'https'
                certificateHash      = 'B30F3184A831320382C61EFB0551766321FA88A5'
                certificateStoreName = 'My'
                sslFlags             = '0'
            }

            $MockSite = @{
                Name     = 'MockHostName'
                Bindings = @{Collection = @($MockBindingRawToDiff)}
            }

            Mock Get-WebSite {return $MockSite}

            It 'should return True' {
                Test-WebsiteBinding -Name $MockSite.Name -BindingInfo $MockBindingInfo | Should Be $true
            }
        }

        Context 'CertificateStoreName is different' {

            $MockBindingInfo = @(
                New-CimInstance -ClassName MSFT_xWebBindingInformation -Namespace root/microsoft/Windows/DesiredStateConfiguration -Property @{
                    IPAddress             = '*'
                    Port                  = [UInt16]443
                    HostName              = ''
                    Protocol              = 'https'
                    CertificateThumbprint = '1D3324C6E2F7ABC794C9CB6CA426B8D0F81045CD'
                    CertificateStoreName  = 'My'
                    SslFlags              = '0'
                } -ClientOnly
            )

            $MockBindingRawToDiff = @{
                bindingInformation   = '*:443:'
                protocol             = 'https'
                certificateHash      = '1D3324C6E2F7ABC794C9CB6CA426B8D0F81045CD'
                certificateStoreName = 'WebHosting'
                sslFlags             = '0'
            }

            $MockSite = @{
                Name     = 'MockHostName'
                Bindings = @{Collection = @($MockBindingRawToDiff)}
            }

            Mock Get-WebSite {return $MockSite}

            It 'should return True' {
                Test-WebsiteBinding -Name $MockSite.Name -BindingInfo $MockBindingInfo | Should Be $true
            }
        }

        Context 'CertificateStoreName is different and no CertificateThumbprint is specified' {

            $MockBindingInfo = @(
                New-CimInstance -ClassName MSFT_xWebBindingInformation -Namespace root/microsoft/Windows/DesiredStateConfiguration -Property @{
                    IPAddress             = '*'
                    Port                  = [UInt16]443
                    HostName              = ''
                    Protocol              = 'https'
                    CertificateThumbprint = ''
                    CertificateStoreName  = 'My'
                    SslFlags              = '0'
                } -ClientOnly
            )

            $MockBindingRawToDiff = @{
                bindingInformation   = '*:443:'
                protocol             = 'https'
                certificateHash      = '1D3324C6E2F7ABC794C9CB6CA426B8D0F81045CD'
                certificateStoreName = 'WebHosting'
                sslFlags             = '0'
            }

            $MockSite = @{
                Name     = 'MockHostName'
                Bindings = @{Collection = @($MockBindingRawToDiff)}
            }

            Mock Get-WebSite {return $MockSite}

            $errorId = 'WebsiteBindingInputInvalidation'
            $errorCategory = [System.Management.Automation.ErrorCategory]::InvalidResult
            $errorMessage = $($LocalizedData.WebsiteBindingInputInvalidationError) -f $MockSite.Name
            $exception = New-Object -TypeName System.InvalidOperationException -ArgumentList $errorMessage
            $errorRecord = New-Object -TypeName System.Management.Automation.ErrorRecord -ArgumentList $exception, $errorId, $errorCategory, $null

            It 'should throw the correct error' {
                {
                    Test-WebsiteBinding -Name $MockSite.Name -BindingInfo $MockBindingInfo
                } | Should Throw $errorRecord
            }

        }

        Context 'SslFlags is different' {

            $MockBindingInfo = @(
                New-CimInstance -ClassName MSFT_xWebBindingInformation -Namespace root/microsoft/Windows/DesiredStateConfiguration -Property @{
                    IPAddress             = '*'
                    Port                  = [UInt16]443
                    HostName              = ''
                    Protocol              = 'https'
                    CertificateThumbprint = '1D3324C6E2F7ABC794C9CB6CA426B8D0F81045CD'
                    CertificateStoreName  = 'WebHosting'
                    SslFlags              = '1'
                } -ClientOnly
            )

            $MockBindingRawToDiff = @{
                bindingInformation   = '*:443:'
                protocol             = 'https'
                certificateHash      = '1D3324C6E2F7ABC794C9CB6CA426B8D0F81045CD'
                certificateStoreName = 'WebHosting'
                sslFlags             = '0'
            }

            $MockSite = @{
                Name     = 'MockHostName'
                Bindings = @{Collection = @($MockBindingRawToDiff)}
            }

            Mock Get-WebSite {return $MockSite}

            It 'should return True' {
                Test-WebsiteBinding -Name $MockSite.Name -BindingInfo $MockBindingInfo | Should Be $true
            }

        }

        Context 'Identical collections of bindings' {

            $MockBindingInfo = @(
                New-CimInstance -ClassName MSFT_xWebBindingInformation -Namespace root/microsoft/Windows/DesiredStateConfiguration -Property @{
                    IPAddress             = '*'
                    Port                  = [UInt16]80
                    HostName              = ''
                    Protocol              = 'http'
                    CertificateThumbprint = ''
                    CertificateStoreName  = ''
                    SslFlags              = '0'
                } -ClientOnly;

                New-CimInstance -ClassName MSFT_xWebBindingInformation -Namespace root/microsoft/Windows/DesiredStateConfiguration -Property @{
                    IPAddress             = '*'
                    Port                  = [UInt16]8080
                    HostName              = ''
                    Protocol              = 'http'
                    CertificateThumbprint = ''
                    CertificateStoreName  = ''
                    SslFlags              = '0'
                } -ClientOnly
            )

            $MockBindingRawToDiff = @(
                @{
                    bindingInformation   = '*:80:'
                    protocol             = 'http'
                    certificateHash      = ''
                    certificateStoreName = ''
                    sslFlags             = '0'
                },

                @{
                    bindingInformation   = '*:8080:'
                    protocol             = 'http'
                    certificateHash      = ''
                    certificateStoreName = ''
                    sslFlags             = '0'
                }
            )

            $MockSite = @{
                Name     = 'MockHostName'
                Bindings = @{Collection = @($MockBindingRawToDiff)}
            }

            Mock Get-WebSite {return $MockSite}

            It 'should return False' {
                Test-WebsiteBinding -Name $MockSite.Name -BindingInfo $MockBindingInfo | Should Be $false
            }
        }

        Context 'Different collections of bindings' {

            $MockBindingInfo = @(
                New-CimInstance -ClassName MSFT_xWebBindingInformation -Namespace root/microsoft/Windows/DesiredStateConfiguration -Property @{
                    IPAddress             = '*'
                    Port                  = [UInt16]80
                    HostName              = ''
                    Protocol              = 'http'
                    CertificateThumbprint = ''
                    CertificateStoreName  = ''
                    SslFlags              = '0'
                } -ClientOnly;

                New-CimInstance -ClassName MSFT_xWebBindingInformation -Namespace root/microsoft/Windows/DesiredStateConfiguration -Property @{
                    IPAddress             = '*'
                    Port                  = [UInt16]8080
                    HostName              = ''
                    Protocol              = 'http'
                    CertificateThumbprint = ''
                    CertificateStoreName  = ''
                    SslFlags              = '0'
                } -ClientOnly
            )

            $MockBindingRawToDiff = @(
                @{
                    bindingInformation   = '*:80:'
                    protocol             = 'http'
                    certificateHash      = ''
                    certificateStoreName = ''
                    sslFlags             = '0'
                },

                @{
                    bindingInformation   = '*:8081:'
                    protocol             = 'http'
                    certificateHash      = ''
                    certificateStoreName = ''
                    sslFlags             = '0'
                }
            )

            $MockSite = @{
                Name     = 'MockHostName'
                Bindings = @{Collection = @($MockBindingRawToDiff)}
            }

            Mock Get-WebSite {return $MockSite}

            It 'should return True' {
                Test-WebsiteBinding -Name $MockSite.Name -BindingInfo $MockBindingInfo | Should Be $true
            }

        }

    }

    Describe 'MSFT_xWebsite\Update-WebsiteBinding' {

        $MockSite = @{
            Ensure             = 'Present'
            Name               = 'MockName'
            PhysicalPath       = 'C:\NonExistent'
            ID                 = 1
            State              = 'Started'
            ApplicationPool    = 'MockPool'
        }

        $MockBindingCustom = @{
            Port                  = 443
            Protocol              = 'https'
            IPAddress             = '127.0.0.1'
            HostName              = 'MockHostName'
            CertificateThumbprint = '1234561651481561891481654891651'
            CertificateStoreName  = 'MY'
            SslFlags              = '1'
        }

        $MockBindingInfo = New-CimInstance -ClassName MSFT_xWebBindingInformation -Namespace root/microsoft/Windows/DesiredStateConfiguration -Property @{
            Port      = [UInt16]$MockBindingCustom.Port
            Protocol  = $MockBindingCustom.Protocol
            IPAddress = $MockBindingCustom.IPAddress
            HostName  = $MockBindingCustom.HostName
            SslFlags  = $MockBindingCustom.SslFlags
        } -ClientOnly

        Context 'expected behavior' {
            Mock Clear-ItemProperty {return $null}
            Mock New-WebBinding {
                return @{
                    Name = $Name;
                    Protocol = $Protocol;
                    Port = $Port;
                    IPAddress = $IPAddress;
                    HostHeader = $HostHeader;
                    SslFlags = $SslFlags;
                }
            } -Verifiable

            $Result = Update-WebsiteBinding -Name $MockSite.Name -BindingInfo $MockBindingInfo

            It 'should call all the mocks' {
                Assert-MockCalled -CommandName New-WebBinding
            }

            It 'should use the right name' {
                $Result.Name | Should Be $MockSite.Name
            }

            It 'should use the right protocol' {
                $Result.Protocol | Should Be $MockBindingInfo.Protocol
            }

            It 'should use the right IPAddress' {
                $Result.IPAddress | Should Be $MockBindingInfo.IPAddress
            }

            It 'should use the right HostHeader' {
                $Result.HostHeader | Should Be $MockBindingInfo.HostName
            }

            It 'should use the right SslFlags' {
                $Result.SslFlags | Should Be $MockBindingInfo.SslFlags
            }
        }

        Context 'New-WebBinding throws an error' {
            It 'should throw the right error' {
                $errorId = 'WebsiteBindingUpdateFailure'
                $errorCategory = [System.Management.Automation.ErrorCategory]::InvalidResult
                $errorMessage = $($LocalizedData.WebsiteBindingUpdateFailureError) -f $MockSite.Name
                $errorMessage += $_.Exception.Message
                $exception = New-Object -TypeName System.InvalidOperationException -ArgumentList $errorMessage
                $errorRecord = New-Object -TypeName System.Management.Automation.ErrorRecord -ArgumentList $exception, $errorId, $errorCategory, $null

                Mock Clear-ItemProperty {return $null}
                Mock New-WebBinding {throw}

                {
                    Update-WebsiteBinding -Name $MockSite.Name -BindingInfo $MockBindingInfo
                } | Should Throw $errorRecord
            }
        }

        Context 'Get-WebBinding throws an error' {
            $MockSite = @{
                Ensure          = 'Present'
                Name            = 'MockHostName'
                PhysicalPath    = 'C:\NonExistent'
                ID              = 1
                State           = 'Started'
                ApplicationPool = 'MockPool'
                BindingInformation = '127.0.0.1:80:'
            }

            $MockBindingCustom = @{
                Port                  = 80
                Protocol              = 'http'
                IPAddress             = '127.0.0.1'
                HostName              = 'MockHostName'
                CertificateThumbprint = '1234561651481561891481654891651'
                CertificateStoreName  = 'MY'
            }

            $MockBindingInfo = New-CimInstance -ClassName MSFT_xWebBindingInformation -Namespace root/microsoft/Windows/DesiredStateConfiguration -Property @{
                Port                  = [UInt16]$MockBindingCustom.Port
                Protocol              = $MockBindingCustom.Protocol
                IPAddress             = $MockBindingCustom.IPAddress
                HostName              = $MockBindingCustom.HostName
                CertificateThumbprint = $MockBindingCustom.CertificateThumbprint
                CertificateStoreName  = $MockBindingCustom.CertificateStoreName
            } -ClientOnly

            It 'should throw the right error' {
                $obj = New-Module -AsCustomObject -ScriptBlock {
                    function AddSslCertificate {
                        throw;
                    }
                }
                Mock Clear-ItemProperty {return $null}
                Mock New-WebBinding {return $null}
                Mock Get-WebBinding {return throw}

                $errorId = 'WebBindingCertificateError'
                $errorCategory = [System.Management.Automation.ErrorCategory]::InvalidOperation
                $errorMessage = $($LocalizedData.WebBindingCertificateError) -f $MockBindingCustom.CertificateThumbprint
                $errorMessage += $_.Exception.Message
                $exception = New-Object -TypeName System.InvalidOperationException -ArgumentList $errorMessage
                $errorRecord = New-Object -TypeName System.Management.Automation.ErrorRecord -ArgumentList $exception, $errorId, $errorCategory, $null

                {
                    Update-WebsiteBinding -Name $MockSite.Name -BindingInfo $MockBindingInfo
                } | Should Throw $errorRecord
            }
        }
    }

    Describe 'MSFT_xWebsite\Update-DefaultPage' {

        $MockSite = @{
            Ensure             = 'Present'
            Name               = 'MockName'
            PhysicalPath       = 'C:\NonExistent'
            ID                 = 1
            State              = 'Started'
            ApplicationPool    = 'MockPool'
            DefaultPage        = 'index.htm'
        }

        Context 'Does not find the default page' {
            It 'should call Add-WebConfiguration' {
                Mock Get-WebConfiguration {return @{value = 'index2.htm'}}
                Mock Add-WebConfiguration {return $null}

                $Result = Update-DefaultPage -Name $MockSite.Name -DefaultPage $MockSite.DefaultPage

                Assert-MockCalled -CommandName Add-WebConfiguration
            }
        }
    }

}


# Cleanup after the test
Remove-Item -Path $ModuleRoot -Recurse -Force

