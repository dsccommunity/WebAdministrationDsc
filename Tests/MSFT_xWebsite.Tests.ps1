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

    It 'should pass Test-xDscSchema' {
        $path = Join-Path -Path $((get-item $here).parent.FullName) -ChildPath 'DSCResources\MSFT_xWebsite\MSFT_xWebsite.schema.mof'
        $result = Test-xDscSchema $path
        $result | Should Be $true
    }
}

if (Get-Module MSFT_xWebsite)
{
    Remove-Module MSFT_xWebsite
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
                } | Should Throw 'Please ensure that WebAdministration module is installed.'
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
                    Get-TargetResource -Name $MockSite.Name -PhysicalPath $MockSite.PhysicalPath
                } | Should Throw 'Please ensure that WebAdministration module is installed.'
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
                Protocol  = 'https'
                IPAddress = '127.0.0.1'
                Port      = 443
                HostName  = 'MockHostName'
            }

            $BindingInfo = [PSCustomObject] @{
                bindingInformation = '127.0.0.1:443:MockHostName'
                protocol           = 'https'
                SslFlags           = 1
                CertificateHash = '3E09CCC8DFDCB8E3D4A83CFF164CC4754C25E9E5'
                CertificateStoreName  = 'My'
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
                return @{
                    collection = $BindingInfo
                }
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

            It 'should return the correct bindings' {
                $result.BindingInfo.Port                  | Should Be $BindingObject.Port
                $result.BindingInfo.Protocol              | Should Be $BindingInfo.Protocol
                $result.BindingInfo.IPAddress             | Should Be $BindingObject.IPAddress
                $result.BindingInfo.HostName              | Should Be $BindingObject.HostName
                $result.BindingInfo.CertificateThumbprint | Should Be $BindingInfo.Certificatehash
                $result.BindingInfo.CertificateStoreName  | Should Be $BindingInfo.CertificateStoreName
                $result.BindingInfo.SSLFlags              | Should Be $BindingInfo.SSLFlags
            }

            It 'should return the State' {
                $result.State | Should Be 'Started'
            }

            It 'should return the ID' {
                $result.ID | Should Be 0
            }
        }
    }

    Describe "how Set-TargetResource responds to Ensure = 'Present'" {
        $MockSite = @{
            Ensure          = 'Present'
            Name            = 'MockName'
            PhysicalPath    = 'C:\NonExistant'
            ID              = 1
            State           = 'Stopped'
            ApplicationPool = 'MockPool'
            DefaultPage = 'index.htm'
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


        $MockSite2 = @{
            Ensure          = 'Present'
            Name            = 'MockName2'
            PhysicalPath    = 'C:\NonExistant2'
            ID              = 1
            State           = 'Stopped'
            ApplicationPool = 'MockPool2'
            DefaultPage     = 'index.htm'
            BindingInfo     =  $MockBinding
        }

        Context 'Everything needs to be updated and application is started' {
            Mock Get-Website {
                return @($MockSite, $MockSite2)
            }
            Mock Start-Website {return $null}

            Mock Test-WebsitePath { return $true }
            Mock Set-ItemProperty { return $null }
            Mock Test-WebsiteBindings { return $true }
            Mock Update-WebsiteBinding { return $null }
            Mock Update-DefaultPages { return $null }
            Mock Confirm-PortIPHostisUnique { return $true }
            Mock Get-TargetResource { return $MockSite2 }

            $result = Set-TargetResource -Ensure 'Present' -Name $MockSite.Name -PhysicalPath $MockSite.PhysicalPath -State 'Started' -ApplicationPool 'MockPool2' -BindingInfo $MockBinding -DefaultPage $MockSite.DefaultPage

            It 'should call all the mocks' {
                Assert-MockCalled Test-WebsitePath
                Assert-MockCalled Set-ItemProperty 2
                Assert-MockCalled Update-WebsiteBinding
                Assert-MockCalled Update-DefaultPages
                Assert-MockCalled Confirm-PortIPHostisUnique
                Assert-MockCalled Get-TargetResource
                Assert-MockCalled Start-Website
            }
        }

        Context 'Confirm-PortIPHostisUnique returns false' {
            Mock Get-Website { return @($MockSite, $MockSite2) }
            Mock Start-Website {return $null}
            Mock Test-WebsitePath { return $true }
            Mock Set-ItemProperty { return $null }
            Mock Test-WebsiteBindings { return $true }
            Mock Update-WebsiteBinding { return $null }
            Mock Update-DefaultPages { return $null }
            Mock Confirm-PortIPHostisUnique { return $false }
            Mock Get-TargetResource { return $MockSite2 }

            It 'should throw the right error' {
                $errorId = 'WebsiteBindingConflictOnStart'
                $errorCategory = [System.Management.Automation.ErrorCategory]::InvalidResult
                $errorMessage = $($LocalizedData.WebsiteBindingConflictOnStartError) -f $MockSite.Name
                $exception = New-Object -TypeName System.InvalidOperationException -ArgumentList $errorMessage
                $errorRecord = New-Object -TypeName System.Management.Automation.ErrorRecord -ArgumentList $exception, $errorId, $errorCategory, $null

                { Set-TargetResource -Ensure 'Present' -Name $MockSite.Name -PhysicalPath $MockSite.PhysicalPath -State 'Started' -ApplicationPool 'MockPool2' -BindingInfo $MockBinding -DefaultPage $MockSite.DefaultPage } | should throw $errorRecord
            }
        }

        Context 'Start-Website throws an error' {
            Mock Get-Website {
                return @($MockSite, $MockSite2)
            }
            Mock Start-Website {return throw}

            Mock Test-WebsitePath { return $true }
            Mock Set-ItemProperty { return $null }
            Mock Test-WebsiteBindings { return $true }
            Mock Update-WebsiteBinding { return $null }
            Mock Update-DefaultPages { return $null }
            Mock Confirm-PortIPHostisUnique { return $true }
            Mock Get-TargetResource { return $MockSite2 }

            It 'Should throw the correct error' {

                $errorId = 'WebsiteStateFailure'
                $errorCategory = [System.Management.Automation.ErrorCategory]::InvalidOperation
                $errorMessage = $($LocalizedData.WebsiteStateFailureError) -f $MockSite.Name
                $errorMessage += $_.Exception.Message
                $exception = New-Object -TypeName System.InvalidOperationException -ArgumentList $errorMessage
                $errorRecord = New-Object -TypeName System.Management.Automation.ErrorRecord -ArgumentList $exception, $errorId, $errorCategory, $null

                { Set-TargetResource -Ensure 'Present' -Name $MockSite.Name -PhysicalPath $MockSite.PhysicalPath -State 'Started' -ApplicationPool 'MockPool2' -BindingInfo $MockBinding -DefaultPage $MockSite.DefaultPage } | should throw $errorRecord
            }
        }

        Context 'Everything needs to be updated and application is stopped' {
            $MockSite = @{
                Ensure          = 'Present'
                Name            = 'MockName'
                PhysicalPath    = 'C:\NonExistant'
                ID              = 1
                State           = 'Started'
                ApplicationPool = 'MockPool'
                DefaultPage = 'index.htm'
            }

            Mock Get-Website {
                return @($MockSite, $MockSite2)
            }
            Mock Stop-Website {return $null}

            Mock Test-WebsitePath { return $true }
            Mock Set-ItemProperty { return $null }
            Mock Test-WebsiteBindings { return $true }
            Mock Update-WebsiteBinding { return $null }
            Mock Update-DefaultPages { return $null }
            Mock Confirm-PortIPHostisUnique { return $true }

            $result = Set-TargetResource -Ensure 'Present' -Name $MockSite.Name -PhysicalPath $MockSite.PhysicalPath -State 'Stopped' -ApplicationPool 'MockPool2' -BindingInfo $MockBinding -DefaultPage $MockSite.DefaultPage

            It 'should call all the mocks' {
                Assert-MockCalled Test-WebsitePath
                Assert-MockCalled Set-ItemProperty 2
                Assert-MockCalled Update-WebsiteBinding
                Assert-MockCalled Update-DefaultPages
                Assert-MockCalled Stop-Website
            }
        }

        Context 'Website does not exist' {
            $MockSite = @{
                Ensure          = 'Present'
                Name            = 'MockName'
                PhysicalPath    = 'C:\NonExistant'
                ID              = 1
                State           = 'Started'
                ApplicationPool = 'MockPool'
                DefaultPage = 'index.htm'
            }

            Mock Get-Website {
                return $MockSite
            }

            Mock New-Website { return $null }
            Mock Stop-Website { return $null }
            Mock Test-WebsiteBindings { return $true }
            Mock Update-WebsiteBinding { return $null }
            Mock Update-DefaultPages { return $null }
            Mock Start-Website { return $true }
            Mock Get-ItemProperty { return $null }

            $result = Set-TargetResource -Ensure 'Present' -Name 'MockName2' -PhysicalPath $MockSite.PhysicalPath -State 'Started' -ApplicationPool 'MockPool2' -BindingInfo $MockBinding -DefaultPage $MockSite.DefaultPage

            It 'should call all the mocks' {
                 Assert-MockCalled New-Website
                 Assert-MockCalled Stop-Website
                 Assert-MockCalled Test-WebsiteBindings
                 Assert-MockCalled Update-WebsiteBinding
                 Assert-MockCalled Update-DefaultPages
                 Assert-MockCalled Start-Website
            }
        }

        Context 'Error in non-existant site' {
            Mock New-Website {throw;}
            It 'Should throw the correct error' {
                $errorId = 'WebsiteCreationFailure'
                $errorCategory = [System.Management.Automation.ErrorCategory]::InvalidOperation
                $errorMessage = $($LocalizedData.WebsiteCreationFailureError) -f 'MockName2'
                $errorMessage += $_.Exception.Message
                $exception = New-Object -TypeName System.InvalidOperationException -ArgumentList $errorMessage
                $errorRecord = New-Object -TypeName System.Management.Automation.ErrorRecord -ArgumentList $exception, $errorId, $errorCategory, $null

                {$result = Set-TargetResource -Ensure 'Present' -Name 'MockName2' -PhysicalPath $MockSite.PhysicalPath -State 'Started' -ApplicationPool 'MockPool2' -BindingInfo $MockBinding -DefaultPage $MockSite.DefaultPage } | Should throw $errorRecord
            }
        }
    }

    Describe "how Set-TargetResource responds to Ensure = 'Absent'" {
        It 'should call Remove-Website' {
            $MockSite = @{
                Ensure          = 'Present'
                Name            = 'MockName'
                PhysicalPath    = 'C:\NonExistant'
                ID              = 1
                State           = 'Stopped'
                ApplicationPool = 'MockPool'
                DefaultPage = 'index.htm'
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

            Mock Get-Website {return $MockSite}
            Mock Remove-Website {return $null}

            $result = Set-TargetResource -Ensure 'Absent' -Name $MockSite.Name -PhysicalPath $MockSite.PhysicalPath -State 'Started' -ApplicationPool 'MockPool2' -BindingInfo $MockBinding -DefaultPage $MockSite.DefaultPage

            Assert-MockCalled Get-Website
            Assert-MockCalled Remove-Website
        }

        It 'should throw the right error' {
            $MockSite = @{
                Ensure          = 'Present'
                Name            = 'MockName'
                PhysicalPath    = 'C:\NonExistant'
                ID              = 1
                State           = 'Stopped'
                ApplicationPool = 'MockPool'
                DefaultPage = 'index.htm'
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

            Mock Get-Website {return $MockSite}
            Mock Remove-Website {throw }

            $errorId = 'WebsiteRemovalFailure'
            $errorCategory = [System.Management.Automation.ErrorCategory]::InvalidOperation
            $errorMessage = $($LocalizedData.WebsiteRemovalFailureError) -f $MockSite.Name
            $errorMessage += $_.Exception.Message
            $exception = New-Object -TypeName System.InvalidOperationException -ArgumentList $errorMessage
            $errorRecord = New-Object -TypeName System.Management.Automation.ErrorRecord -ArgumentList $exception, $errorId, $errorCategory, $null

            { Set-TargetResource -Ensure 'Absent' -Name $MockSite.Name -PhysicalPath $MockSite.PhysicalPath -State 'Started' -ApplicationPool 'MockPool2' -BindingInfo $MockBinding -DefaultPage $MockSite.DefaultPage } | should throw $errorRecord
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
                bindingInformation     = '127.0.0.1:443:MockHostName'
                protocol               = 'https'
                CertificateHash  = '3E09CCC8DFDCB8E3D4A83CFF164CC4754C25E9E5'
                CertificateStoreName   = 'My'
                SSLFlags               = '1'
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

            It 'should return the SSLFlags' {
                $result.SSLFlags | Should Be '1'
            }
        }

        Context 'IPv6 SSL Certificate is passed' {
            $BindingInfo = [PSCustomObject] @{
                bindingInformation    = '[0:0:0:0:0:0:0:1]:443:MockHostName'
                protocol              = 'https'
                CertificateHash = '3E09CCC8DFDCB8E3D4A83CFF164CC4754C25E9E5'
                CertificateStoreName  = 'My'
                SSLFlags              = '1'
            }

            $result = Get-WebBindingObject -BindingInfo $BindingInfo

            It 'should return the IPv6 address' {
                $result.IPaddress | Should be '0:0:0:0:0:0:0:1'
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

            It 'should return the SSLFlags' {
                $result.SSLFlags | Should Be '1'
            }
        }
    }

    Describe 'Test-WebsitePath' {
        Context 'the path is wrong' {
            It 'Should return true' {
                Mock Get-ItemProperty {
                    return 'C:\WrongPath'
                }
                Test-WebsitePath -Name 'SomeSite' -PhysicalPath 'C:\RightPath' | Should be $true
            }
        }

        Context 'the path is correct' {
            It 'Should return false if the path does not need to be updated' {
                Mock Get-ItemProperty {
                    return 'C:\RightPath'
                }
                Test-WebsitePath -Name 'SomeSite' -PhysicalPath 'C:\RightPath' | Should be $false
            }
        }
    }

    Describe 'Confirm-PortIPHostisUnique' {
        Context 'bindings are not unique' {
            It 'should return false' {
                $BindingObject = @{
                    Port                  = 80
                    Protocol              = 'http'
                    IPAddress             = '127.0.0.1'
                    HostName              = 'MockHostName'
                    CertificateThumbprint = ''
                    CertificateStoreName  = ''
                }

                $bindingArray = @()
                $mockBinding = New-CimInstance -ClassName MSFT_xWebBindingInformation -Namespace root/microsoft/Windows/DesiredStateConfiguration -Property @{
                    Port      = [System.UInt16] $BindingObject.Port
                    Protocol  = $BindingObject.Protocol
                    IPAddress = $BindingObject.IPaddress
                    HostName  = $BindingObject.Hostname
                } -ClientOnly

                $bindingArray += $MockBinding, $MockBinding

                Confirm-PortIPHostisUnique -Port $BindingObject.Port -IPAddress $BindingObject.IPAddress -HostName $BindingObject.Hostname -BindingInfo $bindingArray | should be $false
            }
        }

        Context 'bindings are unique' {
            It 'should return true' {
                $BindingObject = @{
                    Port                  = 80
                    Protocol              = 'http'
                    IPAddress             = '127.0.0.1'
                    HostName              = 'MockHostName'
                    CertificateThumbprint = ''
                    CertificateStoreName  = ''
                }

                $mockBinding = New-CimInstance -ClassName MSFT_xWebBindingInformation -Namespace root/microsoft/Windows/DesiredStateConfiguration -Property @{
                    Port      = [System.UInt16] $BindingObject.Port
                    Protocol  = $BindingObject.Protocol
                    IPAddress = $BindingObject.IPaddress
                    HostName  = $BindingObject.Hostname
                } -ClientOnly

                $bindingArray = $MockBinding

                Confirm-PortIPHostisUnique -Port $BindingObject.Port -IPAddress $BindingObject.IPAddress -HostName $BindingObject.Hostname -BindingInfo $bindingArray | should be $true
            }
        }
    }

    Describe 'Test-WebsiteBindings' {
        $MockSite = @{
            Ensure          = 'Present'
            Name            = 'MockHostName'
            PhysicalPath    = 'C:\NonExistant'
            ID              = 1
            State           = 'Started'
            ApplicationPool = 'MockPool'
            BindingInformation = '127.0.0.1:80:'
        }

        $BindingObject = @{
            Port                  = 80
            Protocol              = 'http'
            IPAddress             = '127.0.0.1'
            HostName              = 'MockHostName'
            CertificateThumbprint = ''
            CertificateStoreName  = ''
            SSLFlags              = 0
        }

        $mockBinding = New-CimInstance -ClassName MSFT_xWebBindingInformation -Namespace root/microsoft/Windows/DesiredStateConfiguration -Property @{
            Port      = [System.UInt16] $BindingObject.Port
            Protocol  = $BindingObject.Protocol
            IPAddress = $BindingObject.IPaddress
            HostName  = $BindingObject.Hostname
            SSLFlags  = $BindingObject.SSLFlags
        } -ClientOnly

        Context 'Confirm-PortIPHostisUnique returns false' {
            It 'should throw an error' {
                Mock Confirm-PortIPHostisUnique {return $false}

                $errorId = 'WebsiteBindingInputInvalidation'
                $errorCategory = [System.Management.Automation.ErrorCategory]::InvalidResult
                $errorMessage = $($LocalizedData.WebsiteBindingInputInvalidationError) -f $BindingObject.Hostname
                $exception = New-Object -TypeName System.InvalidOperationException -ArgumentList $errorMessage
                $errorRecord = New-Object -TypeName System.Management.Automation.ErrorRecord -ArgumentList $exception, $errorId, $errorCategory, $null

                {Test-WebsiteBindings -Name $BindingObject.hostname -BindingInfo $mockBinding } | Should throw $errorRecord
            }
        }

        Context 'Comparing bindings throws an error' {

            $badBindingObject = @{
                Port                  = 80
                Protocol              = 'http'
                IPAddress             = '127.0.0.1'
                HostName              = 'MockHostName'
                CertificateThumbprint = ''
                CertificateStoreName  = ''
            }

            Mock Confirm-PortIPHostisUnique {return $true}
            Mock Get-WebBinding {return $BindingObject}
            Mock Get-Website {return $MockSite}
            Mock Get-WebBindingObject { return $MockBinding }

            $errorId = 'WebsiteCompareFailure'
            $errorCategory = [System.Management.Automation.ErrorCategory]::InvalidResult
            $errorMessage = $($LocalizedData.WebsiteCompareFailureError) -f $BindingObject.Hostname
            $errorMessage += $_.Exception.Message
            $exception = New-Object -TypeName System.InvalidOperationException -ArgumentList $errorMessage
            $errorRecord = New-Object -TypeName System.Management.Automation.ErrorRecord -ArgumentList $exception, $errorId, $errorCategory, $null

            It 'should return an error' {
                {Test-WebsiteBindings -Name $BindingObject.hostname -BindingInfo $badBindingObject } | Should not throw $errorRecord # currently broken
            }
        }

        Context 'Port is incorrect' {
            $badBindingObject = @{
                Port                  = 81
                Protocol              = 'http'
                IPAddress             = '127.0.0.1'
                HostName              = 'MockHostName'
                CertificateThumbprint = ''
                CertificateStoreName  = ''
            }

            Mock Confirm-PortIPHostisUnique {return $true}
            Mock Get-WebBinding {return $BindingObject}
            Mock Get-Website {return $MockSite}
            Mock Get-WebBindingObject { return $badBindingObject }

            It 'should return true' {
                Test-WebsiteBindings -Name $BindingObject.hostname -BindingInfo $MockBinding | Should be $true
            }
        }

        Context 'Protocol is incorrect' {
            $badBindingObject = @{
                Port                  = 80
                Protocol              = 'https'
                IPAddress             = '127.0.0.1'
                HostName              = 'MockHostName'
                CertificateThumbprint = ''
                CertificateStoreName  = ''
            }

            Mock Confirm-PortIPHostisUnique {return $true}
            Mock Get-WebBinding {return $BindingObject}
            Mock Get-Website {return $MockSite}
            Mock Get-WebBindingObject { return $badBindingObject }

            It 'should return true' {
                Test-WebsiteBindings -Name $BindingObject.hostname -BindingInfo $MockBinding | Should be $true
            }
        }

        Context 'IPAddress is incorrect' {
            $badBindingObject = @{
                Port                  = 80
                Protocol              = 'http'
                IPAddress             = '127.0.0.2'
                HostName              = 'MockHostName'
                CertificateThumbprint = ''
                CertificateStoreName  = ''
            }

            Mock Confirm-PortIPHostisUnique {return $true}
            Mock Get-WebBinding {return $BindingObject}
            Mock Get-Website {return $MockSite}
            Mock Get-WebBindingObject { return $badBindingObject }

            It 'should return true' {
                Test-WebsiteBindings -Name $BindingObject.hostname -BindingInfo $MockBinding | Should be $true
            }
        }

        Context 'IPAddress is *' {
            $BindingObjectIP = @{
                Port                  = 80
                Protocol              = 'http'
                IPAddress             = ''
                HostName              = 'MockHostName'
                CertificateThumbprint = ''
                CertificateStoreName  = ''
                SSLFlags              = 0
            }

            $mockBindingIP = New-CimInstance -ClassName MSFT_xWebBindingInformation -Namespace root/microsoft/Windows/DesiredStateConfiguration -Property @{
                Port      = [System.UInt16] $BindingObjectIP.Port
                Protocol  = $BindingObjectIP.Protocol
                IPAddress = $BindingObjectIP.IPaddress
                HostName  = $BindingObjectIP.Hostname
            } -ClientOnly

            $badBindingObject = @{
                Port                  = 80
                Protocol              = 'http'
                IPAddress             = '*'
                HostName              = 'MockHostName'
                CertificateThumbprint = ''
                CertificateStoreName  = ''
            }

            Mock Confirm-PortIPHostisUnique {return $true}
            Mock Get-WebBinding {return $BindingObjectIP }
            Mock Get-Website {return $MockSite}
            Mock Get-WebBindingObject { return $badBindingObject }

            It 'should return false' {
                Test-WebsiteBindings -Name $BindingObjectIP.hostname -BindingInfo $mockBindingIP | Should be $false
            }
        }

        Context 'Hostname is incorrect' {
            $badBindingObject = @{
                Port                  = 80
                Protocol              = 'http'
                IPAddress             = '127.0.0.1'
                HostName              = 'MockHostName2'
                CertificateThumbprint = ''
                CertificateStoreName  = ''
            }

            Mock Confirm-PortIPHostisUnique {return $true}
            Mock Get-WebBinding {return $BindingObject}
            Mock Get-Website {return $MockSite}
            Mock Get-WebBindingObject { return $badBindingObject }

            It 'should return true' {
                Test-WebsiteBindings -Name $BindingObject.hostname -BindingInfo $MockBinding | Should be $true
            }
        }

        Context 'CertificateThumbprint is incorrect' {
            $badBindingObject = @{
                Port                  = 80
                Protocol              = 'http'
                IPAddress             = '127.0.0.1'
                HostName              = 'MockHostName'
                CertificateThumbprint = '1234560215616'
                CertificateStoreName  = ''
            }

            Mock Confirm-PortIPHostisUnique {return $true}
            Mock Get-WebBinding {return $BindingObject}
            Mock Get-Website {return $MockSite}
            Mock Get-WebBindingObject { return $badBindingObject }

            It 'should return true' {
                Test-WebsiteBindings -Name $BindingObject.hostname -BindingInfo $MockBinding | Should be $true
            }
        }

        Context 'CertificateStoreName is incorrect' {
            $badBindingObject = @{
                Port                  = 80
                Protocol              = 'http'
                IPAddress             = '127.0.0.1'
                HostName              = 'MockHostName'
                CertificateThumbprint = '1234560215616'
                CertificateStoreName  = 'WebHosting'
            }

            Mock Confirm-PortIPHostisUnique {return $true}
            Mock Get-WebBinding {return $BindingObject}
            Mock Get-Website {return $MockSite}
            Mock Get-WebBindingObject { return $badBindingObject }

            It 'should return true' {
                Test-WebsiteBindings -Name $BindingObject.hostname -BindingInfo $MockBinding | Should be $true
            }
        }

        Context 'CertificateStoreName is incorrect and no thumbrpint is specified' {
            $badBindingObject = @{
                Port                  = 80
                Protocol              = 'http'
                IPAddress             = '127.0.0.1'
                HostName              = 'MockHostName'
                CertificateThumbprint = ''
                CertificateStoreName  = 'WebHosting'
                SSLFlags = 0
            }

            Mock Confirm-PortIPHostisUnique {return $true}
            Mock Get-WebBinding {return $BindingObject}
            Mock Get-Website {return $MockSite}
            Mock Get-WebBindingObject { return $badBindingObject }

            It 'should return false' {
                Test-WebsiteBindings -Name $BindingObject.hostname -BindingInfo $MockBinding | Should be $false
            }
        }

        Context 'SSLFlags is incorrect' {
            $badBindingObject = @{
                Port                  = 80
                Protocol              = 'http'
                IPAddress             = '127.0.0.1'
                HostName              = 'MockHostName'
                CertificateThumbprint = ''
                CertificateStoreName  = ''
                SSLFlags              = 1
            }

            Mock Confirm-PortIPHostisUnique {return $true}
            Mock Get-WebBinding {return $BindingObject}
            Mock Get-Website {return $MockSite}
            Mock Get-WebBindingObject { return $badBindingObject }

            It 'should return true' {
                Test-WebsiteBindings -Name $BindingObject.hostname -BindingInfo $MockBinding | Should be $true
            }
        }

        Context 'Everything is the same' {
            $badBindingObject = @{
                Port                  = 80
                Protocol              = 'http'
                IPAddress             = '127.0.0.1'
                HostName              = 'MockHostName'
                CertificateThumbprint = ''
                CertificateStoreName  = ''
                SSLFlags              = 0
            }

            Mock Confirm-PortIPHostisUnique {return $true}
            Mock Get-WebBinding {return $BindingObject}
            Mock Get-Website {return $MockSite}
            Mock Get-WebBindingObject { return $badBindingObject }

            It 'should return false' {
                Test-WebsiteBindings -Name $BindingObject.hostname -BindingInfo $MockBinding | Should be $false
            }
        }
    }

    Describe 'Update-WebsiteBinding' {
        $MockSite = @{
            Ensure          = 'Present'
            Name            = 'MockHostName'
            PhysicalPath    = 'C:\NonExistant'
            ID              = 1
            State           = 'Started'
            ApplicationPool = 'MockPool'
            BindingInformation = '127.0.0.1:443:'
        }

        $BindingObject = @{
            Port                  = 443
            Protocol              = 'https'
            IPAddress             = '127.0.0.1'
            HostName              = 'MockHostName'
            CertificateThumbprint = '1234561651481561891481654891651'
            CertificateStoreName  = 'MY'
            SSLFlags              = 1
        }

        $mockBinding = New-CimInstance -ClassName MSFT_xWebBindingInformation -Namespace root/microsoft/Windows/DesiredStateConfiguration -Property @{
            Port      = [System.UInt16] $BindingObject.Port
            Protocol  = $BindingObject.Protocol
            IPAddress = $BindingObject.IPaddress
            HostName  = $BindingObject.Hostname
            SSLFlags  = $BindingObject.SSLFlags
        } -ClientOnly

        Context 'expected behavior' {
            Mock Clear-ItemProperty { return $null }
            Mock New-WebBinding { return @{
                    Name = $Name;
                    Protocol = $Protocol;
                    Port = $Port;
                    IPaddress = $IPaddress;
                    Hostheader = $Hostheader;
                    SslFlags = $SslFlags;
                }
            } -Verifiable

            $result = Update-WebsiteBinding -Name $MockSite.Name -BindingInfo $mockBinding
            It 'should call all the mocks' {
                Assert-MockCalled New-WebBinding
            }

            It 'should use the right name' {
                $result.Name | Should be $MockSite.Name
            }

            It 'should use the right protocol' {
                $result.Protocol | Should be $mockBinding.Protocol
            }

            It 'should use the right IPaddress' {
                $result.IPaddress | Should be $mockBinding.IPaddress
            }

            It 'should use the right Hostheader' {
                $result.Hostheader | Should be $mockBinding.HostName
            }

            It 'should use the right SSLFlags' {
                $result.SslFlags | Should be $mockBinding.SslFlags
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

                Mock Clear-ItemProperty { return $null }
                Mock New-WebBinding { throw}

                { Update-WebsiteBinding -Name $MockSite.Name -BindingInfo $mockBinding } | should throw $errorRecord
            }
        }

        Context 'Get-WebBinding throws an error' {
            $MockSite = @{
                Ensure          = 'Present'
                Name            = 'MockHostName'
                PhysicalPath    = 'C:\NonExistant'
                ID              = 1
                State           = 'Started'
                ApplicationPool = 'MockPool'
                BindingInformation = '127.0.0.1:80:'
            }

            $BindingObject = @{
                Port                  = 80
                Protocol              = 'http'
                IPAddress             = '127.0.0.1'
                HostName              = 'MockHostName'
                CertificateThumbprint = '1234561651481561891481654891651'
                CertificateStoreName  = 'MY'
            }

            $mockBinding = New-CimInstance -ClassName MSFT_xWebBindingInformation -Namespace root/microsoft/Windows/DesiredStateConfiguration -Property @{
                Port      = [System.UInt16] $BindingObject.Port
                Protocol  = $BindingObject.Protocol
                IPAddress = $BindingObject.IPaddress
                HostName  = $BindingObject.Hostname
                CertificateThumbprint  = $BindingObject.CertificateThumbprint
                CertificateStoreName  = $BindingObject.CertificateStoreName
            } -ClientOnly

            It 'should throw the right error' {
                $obj = New-Module -AsCustomObject -ScriptBlock {
                    function AddSslCertificate {
                        throw;
                    }
                }
                Mock Clear-ItemProperty { return $null }
                Mock New-WebBinding { return $null }
                Mock Get-WebBinding { return throw; }

                $errorId = 'WebBindingCertifcateError'
                $errorCategory = [System.Management.Automation.ErrorCategory]::InvalidOperation
                $errorMessage = $($LocalizedData.WebBindingCertifcateError) -f $BindingObject.CertificateThumbprint
                $errorMessage += $_.Exception.Message
                $exception = New-Object -TypeName System.InvalidOperationException -ArgumentList $errorMessage
                $errorRecord = New-Object -TypeName System.Management.Automation.ErrorRecord -ArgumentList $exception, $errorId, $errorCategory, $null

                { Update-WebsiteBinding -Name $MockSite.Name -BindingInfo $mockBinding } | should throw $errorRecord
            }
        }
    }

    Describe 'Update-DefaultPages' {
        Context 'Does not find the default page' {
            It 'should call Add-WebConfiguration' {
                Mock Get-WebConfiguration { return 'index.htm' }
                Mock Add-WebConfiguration { return $null }
                $result = Update-DefaultPages -Name 'Default Web Site' -DefaultPage 'index2.htm'
                Assert-MockCalled -commandName Add-WebConfiguration
            }
        }
    }
}
