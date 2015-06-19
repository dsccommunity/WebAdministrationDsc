$here = Split-Path -Parent $MyInvocation.MyCommand.Path

# should check for the server OS
if($env:APPVEYOR_BUILD_VERSION)
{
  Add-WindowsFeature Web-Server -Verbose
}

if (! (Get-Module xDSCResourceDesigner))
{
    Import-Module -Name xDSCResourceDesigner
}


Describe 'Schema Validation MSFT_xWebsite' {
    It 'should pass Test-xDscResource' {
        $path = Join-Path -Path $((get-item $here).parent.FullName) -ChildPath 'DSCResources\MSFT_xWebsite'
        $result = Test-xDscResource $path
        $result | Should Be $true
    }

    It 'should pass Test-xDscResource' {
        $path = Join-Path -Path $((get-item $here).parent.FullName) -ChildPath 'DSCResources\MSFT_xWebsite\MSFT_xWebsite.schema.mof'
        $result = Test-xDscSchema $path
        $result | Should Be $true
    }
}

Import-Module (Join-Path $here -ChildPath "..\DSCResources\MSFT_xWebsite\MSFT_xWebsite.psm1")

InModuleScope MSFT_xWebsite {
    Describe "how Test-TargetResource to Ensure = 'Present'" {
        $MockSite = @{
            Ensure          = 'Present'
            Name            = 'MockName'
            PhysicalPath    = 'C:\NonExistant'
            ID              = 1
            State           = 'MockState'
            ApplicationPool = 'MockPool'
        }

        Context 'WebAdminstration is not installed' {
            It 'should throw an error if WebAdministration is not installed' {
                Mock Get-Module -ModuleName $ModuleName { return $null }
                {
                    Test-TargetResource -Name $MockSite.Name -Ensure $MockSite.Ensure -PhysicalPath $MockSite.PhysicalPath
                } | Should Throw
            }
        }

        Context 'Check Ensure is false' {
            It 'should return false' {
                Mock Get-Website {
                    return $null
                }

                $result = Test-TargetResource -Name $MockSite.Name -Ensure $MockSite.Ensure -PhysicalPath $MockSite.PhysicalPath -Verbose:$VerbosePreference

                $result | Should Be $false
            }
        }

        Context 'Check Physical Property is false' {
            Mock Get-Website {
                return $MockSite
            }
            Mock Test-WebsitePath -ModuleName $ModuleName {
                return $true
            }

            $result = Test-TargetResource -Name $MockSite.Name -Ensure $MockSite.Ensure -PhysicalPath $MockSite.PhysicalPath -Verbose:$VerbosePreference

            It 'should return false' {
                $result | Should Be $false
            }
        }

        Context 'Check State is false' {
            Mock Get-Website {
                return $MockSite
            }
            Mock Test-WebsitePath -ModuleName $ModuleName {
                return $false
            }

            $result = Test-TargetResource -Name $MockSite.Name -Ensure $MockSite.Ensure -PhysicalPath $MockSite.PhysicalPath -State 'Started' -Verbose:$VerbosePreference

            It 'should return false' {
                $result | Should Be $false
            }
        }

        Context 'Check Application Pool is false' {
            $MockSite = @{
                Ensure          = 'Present'
                Name            = 'MockName'
                PhysicalPath    = 'C:\NonExistant'
                ID              = 1
                State           = 'Started'
                ApplicationPool = 'MockPool'
            }

            Mock Get-Website {
                return $MockSite
            }
            Mock Test-WebsitePath -ModuleName $ModuleName {
                return $false
            }

            $result = Test-TargetResource -Name $MockSite.Name -Ensure $MockSite.Ensure -PhysicalPath $MockSite.PhysicalPath -State 'Started' -ApplicationPool 'MockPool2' -Verbose:$VerbosePreference

            It 'should return false' {
                $result | Should Be $false
            }
        }

        Context 'Binding Properties is false' {
            $MockSite = @{
                Ensure          = 'Present'
                Name            = 'MockName'
                PhysicalPath    = 'C:\NonExistant'
                ID              = 1
                State           = 'Started'
                ApplicationPool = 'MockPool'
            }

            $BindingObject = @{
                Port                  = 80
                Protocol              = 'http'
                IPAddress             = '127.0.0.1'
                HostName              = 'MockHostName'
                CertificateThumbprint = ''
                CertificateStoreName  = ''
            }

            $MockBinding = New-CimInstance -ClassName MSFT_xWebBindingInformation -Namespace root/microsoft/Windows/DesiredStateConfiguration -Property @{
                Port      = [System.UInt16] $BindingObject.Port
                Protocol  = $BindingObject.Protocol
                IPAddress = $BindingObject.IPaddress
                HostName  = $BindingObject.Hostname
            } -ClientOnly


            Mock Get-Website {
                return $MockSite
            }
            Mock Test-WebsitePath -ModuleName $ModuleName {
                return $true
            }
            Mock Test-WebsiteBindings -ModuleName $ModuleName -Name $Name -BindingInfo $BindingInfo {
                return $false
            }

            $result = Test-TargetResource -Name $MockSite.Name -Ensure $MockSite.Ensure -PhysicalPath $MockSite.PhysicalPath -State 'Started' -ApplicationPool 'MockPool' -BindingInfo $MockBinding -Verbose:$VerbosePreference

            It 'should return false' {
                $result | Should Be $false
            }
        }

        Context 'Default Page is false' {
            $MockSite = @{
                Ensure          = 'Present'
                Name            = 'MockName'
                PhysicalPath    = 'C:\NonExistant'
                ID              = 1
                State           = 'Started'
                ApplicationPool = 'MockPool'
                DefaultPage     = 'something'
            }

            $BindingObject = @{
                Port                  = 80
                Protocol              = 'http'
                IPAddress             = '127.0.0.1'
                HostName              = 'MockHostName'
                CertificateThumbprint = ''
                CertificateStoreName  = ''
            }

            $MockBinding = New-CimInstance -ClassName MSFT_xWebBindingInformation -Namespace root/microsoft/Windows/DesiredStateConfiguration -Property @{
                Port      = [System.UInt16] $BindingObject.Port
                Protocol  = $BindingObject.Protocol
                IPAddress = $BindingObject.IPaddress
                HostName  = $BindingObject.Hostname
            } -ClientOnly


            Mock Get-Website {
                return $MockSite
            }

            Mock Test-WebsitePath {
                return $true
            }

            Mock Test-WebsiteBindings -Name $Name -BindingInfo $BindingInfo {
                return $true
            }

            Mock Get-WebConfiguration {
                return 'Notsomething'
            }

            $result = Test-TargetResource -Name $MockSite.Name -Ensure $MockSite.Ensure -PhysicalPath $MockSite.PhysicalPath -State $MockSite.State -ApplicationPool $MockSite.ApplicationPool -BindingInfo $MockBinding -DefaultPage $MockSite.DefaultPage -Verbose:$VerbosePreference

            It 'should return false' {
                $result | Should Be $false
            }
        }
    }

    Describe "how Get-TargetResource responds to Ensure = 'Present'" {
        $MockSite = @{
            Ensure          = 'Present'
            Name            = 'MockName'
            PhysicalPath    = 'C:\NonExistant'
            ID              = 1
            State           = 'Started'
            ApplicationPool = 'MockPool'
        }

        $BindingObject = @{
            Port                  = 80
            Protocol              = 'http'
            IPAddress             = '127.0.0.1'
            HostName              = 'MockHostName'
            CertificateThumbprint = ''
            CertificateStoreName  = ''
        }

        $MockBinding = New-CimInstance -ClassName MSFT_xWebBindingInformation -Namespace root/microsoft/Windows/DesiredStateConfiguration -Property @{
            Port      = [System.UInt16] $BindingObject.Port
            Protocol  = $BindingObject.Protocol
            IPAddress = $BindingObject.IPaddress
            HostName  = $BindingObject.Hostname
        } -ClientOnly

        Context 'WebAdminstration is not installed' {
            It 'should throw an error if WebAdministration is not installed' {
                Mock Get-Module -ModuleName $ModuleName  { return $null }
                {
                    Get-TargetResource -Name $MockSite.Name -Ensure $MockSite.Ensure -PhysicalPath $MockSite.PhysicalPath
                } | Should Throw
            }
        }

        Context 'No Website exists' {
            Mock Get-Website {
                return $null
            }
            $result = Get-TargetResource -Name 'MockName' -PhysicalPath $MockSite.PhysicalPath

            It 'should return absent' {
                $result.Ensure | Should Be 'Absent'
            }
        }

        Context 'Multiple Websites of the same name exist' {
            Mock Get-Website -ModuleName 'MSFT_xWebsite' {
                return @(
                    [PSCustomObject] @{
                        Name = 'Site1'
                    },
                    [PSCustomObject] @{
                        Name = 'Site1'
                    }
                )
            }

            $errorId = 'WebsiteDiscoveryFailure,Get-TargetResource'
            $errorCategory = [System.Management.Automation.ErrorCategory]::InvalidResult
            $errorMessage = $($LocalizedData.WebsiteDiscoveryFailureError) -f 'Site1'
            $exception = New-Object System.InvalidOperationException $errorMessage
            $errorRecord = New-Object System.Management.Automation.ErrorRecord $exception, $errorId, $errorCategory, $null

            It 'should throw "WebsiteDiscoveryFailure"' {
                { Get-TargetResource -Name 'Site1' -PhysicalPath 'C:\somePath' } | Should Throw $errorRecord
            }
        }

        Context 'Single website exists' {
            $BindingObject = [PSCustomObject] @{
                Protocol  = 'http'
                IPAddress = '127.0.0.1'
                Port      = '80'
                HostName  = 'MockHostName'
            }

            $BindingInfo = [PSCustomObject] @{
                bindingInformation = '127.0.0.1:80:*'
                protocol           = 'http'
            }

            $Website = [PSCustomObject] @{
                Name            = 'MockHostName'
                PhysicalPath    = 'C:\SomePath'
                State           = 'Started'
                ID              = 0
                ApplicationPool = 'Pool'
                Count           = 1
            }

            Mock Get-Website {
                return $Website
            }

            Mock Get-ItemProperty {
                return $BindingInfo
            }

            Mock Get-WebConfiguration {
                return $null
            }

            It 'should not throw' {
                {
                    Get-TargetResource -Name 'MockHostName' -PhysicalPath 'C:\somePath'
                } | Should Not throw
            }

            $result = Get-TargetResource -Name 'MockHostName' -PhysicalPath 'C:\somePath'

            It 'should call Get-Website once' {
                Assert-MockCalled -commandName Get-Website
            }

            It 'should call Get-itemProperty once' {
                Assert-MockCalled -commandName Get-ItemProperty
            }

            It 'should return the name' {
                $result.Name | Should Be 'MockHostName'
            }

            It 'should return the EnsureResult' {
                $result.Ensure | Should Be 'Present'
            }

            It 'should return the PhysicalPath' {
                $result.PhysicalPath | Should Be 'C:\SomePath'
            }

            It 'should return the State' {
                $result.State | Should Be 'Started'
            }

            It 'should return the ID' {
                $result.ID | Should Be 0
            }
        }
    }

    Describe 'how Get-WebBindingObject responds' {
        Context 'IPv6 address is passed and the protocol is http' {
            $BindingInfo = [PSCustomObject] @{
                bindingInformation = '[0:0:0:0:0:0:0:1]:80:MockHostName'
                protocol           = 'http'
            }

            $result = Get-WebBindingObject -BindingInfo $BindingInfo

            It 'should return the IPv6 address' {
                $result.IPaddress | Should be '0:0:0:0:0:0:0:1'
            }

            It 'should return http' {
                $result.Protocol | Should Be 'http'
            }

            It 'should return the hostname' {
                $result.Hostname | Should Be 'MockHostName'
            }

            It 'should return the port' {
                $result.Port | Should Be '80'
            }
        }

        Context 'IPv4 address is passed and the protocol is http' {
            $BindingInfo = [PSCustomObject] @{
                bindingInformation = '127.0.0.1:80:MockHostName'
                protocol           = 'http'
            }

            $result = Get-WebBindingObject -BindingInfo $BindingInfo

            It 'should return the IPv6 address' {
                $result.IPaddress | Should be '127.0.0.1'
            }

            It 'should return http' {
                $result.Protocol | Should Be 'http'
            }

            It 'should return the hostname' {
                $result.Hostname | Should Be 'MockHostName'
            }

            It 'should return the port' {
                $result.Port | Should Be '80'
            }
        }

        Context 'IPv4 SSL Certificate is passed' {
            $BindingInfo = [PSCustomObject] @{
                bindingInformation   = '127.0.0.1:443:MockHostName'
                protocol             = 'https'
                CertificateHash      = '3E09CCC8DFDCB8E3D4A83CFF164CC4754C25E9E5'
                CertificateStoreName = 'My'
            }

            $result = Get-WebBindingObject -BindingInfo $BindingInfo

            It 'should return the IPv6 address' {
                $result.IPaddress | Should be '127.0.0.1'
            }

            It 'should return http' {
                $result.Protocol | Should Be 'https'
            }

            It 'should return the hostname' {
                $result.Hostname | Should Be 'MockHostName'
            }

            It 'should return the port' {
                $result.Port | Should Be '443'
            }

            It 'should return the Hash' {
                $result.CertificateThumbprint | Should Be '3E09CCC8DFDCB8E3D4A83CFF164CC4754C25E9E5'
            }

            It 'should return the store' {
                $result.CertificateStoreName | Should Be 'My'
            }
        }
    }
}
