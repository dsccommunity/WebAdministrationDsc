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

    Describe "how MSFT_xWebsite\Get-TargetResource responds" {

        $MockWebBinding = @(
            @{
                bindingInformation   = '*:443:web01.contoso.com'
                protocol             = 'https'
                certificateHash      = '1D3324C6E2F7ABC794C9CB6CA426B8D0F81045CD'
                certificateStoreName = 'WebHosting'
                sslFlags             = '1'
            }
        )

        $MockWebsite = @{
            Name             = 'MockName'
            PhysicalPath     = 'C:\NonExistent'
            State            = 'Started'
            ApplicationPool  = 'MockPool'
            Bindings         = @{Collection = @($MockWebBinding)}
            EnabledProtocols = 'http'
            Id               = 1
            Count            = 1
        }

        Context 'WebAdminstration module is not installed' {

            Mock -CommandName Get-Module

            It 'should throw an error' {
                {Get-TargetResource -Name $MockWebsite.Name -PhysicalPath $MockWebsite.PhysicalPath} |
                Should Throw 'Please ensure that WebAdministration module is installed.'
            }

        }

        Context 'Website does not exist' {

            Mock -CommandName Get-Website

            $Result = Get-TargetResource -Name $MockWebsite.Name -PhysicalPath $MockWebsite.PhysicalPath

            It 'should return Absent' {
                $Result.Ensure | Should Be 'Absent'
            }

        }

        Context 'There are multiple websites with the same name' {

            Mock -CommandName Get-Website -MockWith {
                return @(
                    @{Name = 'MockName'}
                    @{Name = 'MockName'}
                )
            }

            It 'should throw the correct error' {

                $ErrorId = 'WebsiteDiscoveryFailure'
                $ErrorCategory = [System.Management.Automation.ErrorCategory]::InvalidResult
                $ErrorMessage = $($LocalizedData.WebsiteDiscoveryFailureError) -f 'MockName'
                $Exception = New-Object -TypeName System.InvalidOperationException -ArgumentList $ErrorMessage
                $ErrorRecord = New-Object -TypeName System.Management.Automation.ErrorRecord -ArgumentList $Exception, $ErrorId, $ErrorCategory, $null

                {Get-TargetResource -Name 'MockName' -PhysicalPath 'C:\NonExistent'} |
                Should Throw $ErrorRecord

            }

        }

        Context 'Single website exists' {

            Mock -CommandName Get-Website -MockWith {return $MockWebsite}
            Mock -CommandName Get-WebConfiguration -MockWith {return @{value = 'index.html'}}

            $Result = Get-TargetResource -Name $MockWebsite.Name -PhysicalPath $MockWebsite.PhysicalPath

            It 'should call Get-Website once' {
                Assert-MockCalled -CommandName Get-Website -Exactly 1
                Assert-MockCalled -CommandName Get-WebConfiguration -Exactly 1
            }

            It 'should return Ensure' {
                $Result.Ensure | Should Be 'Present'
            }

            It 'should return Name' {
                $Result.Name | Should Be $MockWebsite.Name
            }

            It 'should return PhysicalPath' {
                $Result.PhysicalPath | Should Be $MockWebsite.PhysicalPath
            }

            It 'should return State' {
                $Result.State | Should Be $MockWebsite.State
            }

            It 'should return ApplicationPool' {
                $Result.ApplicationPool | Should Be $MockWebsite.ApplicationPool
            }

            It 'should return BindingInfo' {
                $Result.BindingInfo.Protocol              | Should Be $MockWebBinding.protocol
                $Result.BindingInfo.BindingInformation    | Should Be $MockWebBinding.bindingInformation
                $Result.BindingInfo.IPAddress             | Should Be '*'
                $Result.BindingInfo.Port                  | Should Be 443
                $Result.BindingInfo.HostName              | Should Be 'web01.contoso.com'
                $Result.BindingInfo.CertificateThumbprint | Should Be $MockWebBinding.certificateHash
                $Result.BindingInfo.CertificateStoreName  | Should Be $MockWebBinding.certificateStoreName
                $Result.BindingInfo.SslFlags              | Should Be $MockWebBinding.sslFlags
            }

            It 'should return DefaultPage' {
                $Result.DefaultPage | Should Be 'index.html'
            }

            It 'should return EnabledProtocols' {
                $Result.EnabledProtocols | Should Be $MockWebsite.EnabledProtocols
            }

            It 'should return Id' {
                $Result.Id | Should Be $MockWebsite.Id
            }

        }

    }

    Describe "how MSFT_xWebsite\Test-TargetResource responds to Ensure = 'Present'" {

        $MockBindingInfo = @(
            New-CimInstance -ClassName MSFT_xWebBindingInformation -Namespace root/microsoft/Windows/DesiredStateConfiguration -Property @{
                Protocol              = 'https'
                IPAddress             = '*'
                Port                  = 443
                HostName              = 'web01.contoso.com'
                CertificateThumbprint = '1D3324C6E2F7ABC794C9CB6CA426B8D0F81045CD'
                CertificateStoreName  = 'WebHosting'
                SslFlags              = 1
            } -ClientOnly
        )

        $MockParameters = @{
            Ensure           = 'Present'
            Name             = 'MockName'
            PhysicalPath     = 'C:\NonExistent'
            State            = 'Started'
            ApplicationPool  = 'MockPool'
            BindingInfo      = $MockBindingInfo
            DefaultPage      = @('index.html')
            EnabledProtocols = 'http'
        }

        $MockWebBinding = @(
            @{
                bindingInformation   = '*:443:web01.contoso.com'
                protocol             = 'https'
                certificateHash      = '1D3324C6E2F7ABC794C9CB6CA426B8D0F81045CD'
                certificateStoreName = 'WebHosting'
                sslFlags             = '1'
            }
        )

        $MockWebsite = @{
            Name             = 'MockName'
            PhysicalPath     = 'C:\NonExistent'
            State            = 'Started'
            ApplicationPool  = 'MockPool'
            Bindings         = @{Collection = @($MockWebBinding)}
            EnabledProtocols = 'http'
            Id               = 1
            Count            = 1
        }

        Context 'WebAdminstration module is not installed' {

            Mock -CommandName Get-Module

            It 'should throw an error' {
                {Test-TargetResource -Ensure $MockParameters.Ensure -Name $MockParameters.Name -PhysicalPath $MockParameters.PhysicalPath} |
                Should Throw 'Please ensure that WebAdministration module is installed.'
            }

        }

        Context 'Website does not exist' {

            Mock -CommandName Get-Website

            $Result = Test-TargetResource -Ensure $MockParameters.Ensure -Name $MockParameters.Name -PhysicalPath $MockParameters.PhysicalPath

            It 'should return False' {
                $Result | Should Be $false
            }

        }

        Context 'Check PhysicalPath is different' {

            Mock -CommandName Get-Website -MockWith {return $MockWebsite}

            $Result = Test-TargetResource -Ensure $MockParameters.Ensure `
                                          -Name $MockParameters.Name `
                                          -PhysicalPath 'C:\Different' `
                                          -Verbose:$VerbosePreference

            It 'should return False' {
                $Result | Should Be $false
            }

        }

        Context 'Check State is different' {

            Mock -CommandName Get-Website -MockWith {return $MockWebsite}

            $Result = Test-TargetResource -Ensure $MockParameters.Ensure `
                                          -Name $MockParameters.Name `
                                          -PhysicalPath $MockParameters.PhysicalPath `
                                          -State 'Stopped' `
                                          -Verbose:$VerbosePreference

            It 'should return False' {
                $Result | Should Be $false
            }

        }

        Context 'Check ApplicationPool is different' {

            Mock -CommandName Get-Website -MockWith {return $MockWebsite}

            $Result = Test-TargetResource -Name $MockParameters.Name `
                                          -Ensure $MockParameters.Ensure `
                                          -PhysicalPath $MockParameters.PhysicalPath `
                                          -ApplicationPool 'MockPoolDifferent' `
                                          -Verbose:$VerbosePreference

            It 'should return False' {
                $Result | Should Be $false
            }

        }

        Context 'Check BindingInfo is different' {

            Mock -CommandName Get-Website -MockWith {return $MockWebsite}
            Mock -CommandName Test-WebsiteBinding -MockWith {return $false}

            $Result = Test-TargetResource -Name $MockParameters.Name `
                                          -Ensure $MockParameters.Ensure `
                                          -PhysicalPath $MockParameters.PhysicalPath `
                                          -BindingInfo $MockParameters.BindingInfo `
                                          -Verbose:$VerbosePreference

            It 'should return False' {
                $Result | Should Be $false
            }

        }

        Context 'Check DefaultPage is different' {

            Mock -CommandName Get-Website -MockWith {return $MockWebsite}
            Mock -CommandName Get-WebConfiguration -MockWith {return @{value = 'MockDifferent.html'}}

            $Result = Test-TargetResource -Name $MockParameters.Name `
                                          -Ensure $MockParameters.Ensure `
                                          -PhysicalPath $MockParameters.PhysicalPath `
                                          -DefaultPage $MockParameters.DefaultPage `
                                          -Verbose:$VerbosePreference

            It 'should return False' {
                $Result | Should Be $false
            }

        }

        Context 'Check EnabledProtocols is different' {

            Mock -CommandName Get-Website -MockWith {return $MockWebsite}

            $Result = Test-TargetResource -Ensure $MockParameters.Ensure `
                                          -Name $MockParameters.Name `
                                          -PhysicalPath $MockParameters.PhysicalPath `
                                          -EnabledProtocols 'https' `
                                          -Verbose:$VerbosePreference

            It 'should return False' {
                $Result | Should Be $false
            }

        }

    }

    Describe "how MSFT_xWebsite\Set-TargetResource responds to Ensure = 'Present'" {

        $MockBindingInfo = @(
            New-CimInstance -ClassName MSFT_xWebBindingInformation -Namespace root/microsoft/Windows/DesiredStateConfiguration -Property @{
                Protocol              = 'https'
                IPAddress             = '*'
                Port                  = 443
                HostName              = 'web01.contoso.com'
                CertificateThumbprint = '1D3324C6E2F7ABC794C9CB6CA426B8D0F81045CD'
                CertificateStoreName  = 'WebHosting'
                SslFlags              = 1
            } -ClientOnly
        )

        $MockParameters = @{
            Ensure           = 'Present'
            Name             = 'MockName'
            PhysicalPath     = 'C:\NonExistent'
            State            = 'Started'
            ApplicationPool  = 'MockPool'
            BindingInfo      = $MockBindingInfo
            DefaultPage      = @('index.html')
            EnabledProtocols = 'https'
        }

        $MockWebBinding = @(
            @{
                bindingInformation   = '*:80:'
                protocol             = 'http'
                certificateHash      = ''
                certificateStoreName = ''
                sslFlags             = '0'
            }
        )

        $MockWebsite = @{
            Name             = 'MockName'
            PhysicalPath     = 'C:\Different'
            State            = 'Stopped'
            ApplicationPool  = 'MockPoolDifferent'
            Bindings         = @{Collection = @($MockWebBinding)}
            EnabledProtocols = 'http'
            Id               = 1
        }

        Context 'All properties need to be updated and website must be started' {

            Mock -CommandName Get-Website -MockWith {return $MockWebsite}
            Mock -CommandName Set-ItemProperty
            Mock -CommandName Test-WebsiteBinding -MockWith {return $false}
            Mock -CommandName Update-WebsiteBinding
            Mock -CommandName Update-DefaultPage
            Mock -CommandName Confirm-UniqueBinding -MockWith {return $true}
            Mock -CommandName Start-Website

            $Result = Set-TargetResource @MockParameters

            It 'should call all the mocks' {
                Assert-MockCalled -CommandName Set-ItemProperty -Exactly 3
                Assert-MockCalled -CommandName Test-WebsiteBinding -Exactly 1
                Assert-MockCalled -CommandName Update-WebsiteBinding -Exactly 1
                Assert-MockCalled -CommandName Update-DefaultPage -Exactly 1
                Assert-MockCalled -CommandName Confirm-UniqueBinding -Exactly 1
                Assert-MockCalled -CommandName Start-Website -Exactly 1
            }

        }

        Context 'Existing website cannot be started due to a binding conflict' {

            Mock -CommandName Get-Website -MockWith {return $MockWebsite}
            Mock -CommandName Set-ItemProperty
            Mock -CommandName Test-WebsiteBinding -MockWith {return $false}
            Mock -CommandName Update-WebsiteBinding
            Mock -CommandName Update-DefaultPage
            Mock -CommandName Confirm-UniqueBinding -MockWith {return $false}
            Mock -CommandName Start-Website

            It 'should throw the correct error' {

                $ErrorId = 'WebsiteBindingConflictOnStart'
                $ErrorCategory = [System.Management.Automation.ErrorCategory]::InvalidResult
                $ErrorMessage = $($LocalizedData.WebsiteBindingConflictOnStartError) -f $MockParameters.Name
                $Exception = New-Object -TypeName System.InvalidOperationException -ArgumentList $ErrorMessage
                $ErrorRecord = New-Object -TypeName System.Management.Automation.ErrorRecord -ArgumentList $Exception, $ErrorId, $ErrorCategory, $null

                {Set-TargetResource @MockParameters} |
                Should Throw $ErrorRecord

            }

        }

        Context 'Start-Website throws an error' {

            Mock -CommandName Get-Website -MockWith {return $MockWebsite}
            Mock -CommandName Set-ItemProperty
            Mock -CommandName Test-WebsiteBinding -MockWith {return $false}
            Mock -CommandName Update-WebsiteBinding
            Mock -CommandName Update-DefaultPage
            Mock -CommandName Confirm-UniqueBinding -MockWith {return $true}
            Mock -CommandName Start-Website -MockWith {throw}

            It 'should throw the correct error' {

                $ErrorId = 'WebsiteStateFailure'
                $ErrorCategory = [System.Management.Automation.ErrorCategory]::InvalidOperation
                $ErrorMessage = $($LocalizedData.WebsiteStateFailureError) -f $MockParameters.Name
                $Exception = New-Object -TypeName System.InvalidOperationException -ArgumentList $ErrorMessage
                $ErrorRecord = New-Object -TypeName System.Management.Automation.ErrorRecord -ArgumentList $Exception, $ErrorId, $ErrorCategory, $null

                {Set-TargetResource @MockParameters} |
                Should Throw $ErrorRecord

            }

        }

        Context 'All properties need to be updated and website must be stopped' {

            $MockParameters = $MockParameters.Clone()
            $MockParameters.State = 'Stopped'

            $MockWebsite = $MockWebsite.Clone()
            $MockWebsite.State = 'Started'

            Mock -CommandName Get-Website -MockWith {return $MockWebsite}
            Mock -CommandName Set-ItemProperty
            Mock -CommandName Test-WebsiteBinding -MockWith {return $false}
            Mock -CommandName Update-WebsiteBinding
            Mock -CommandName Update-DefaultPage
            Mock -CommandName Stop-Website

            $Result = Set-TargetResource @MockParameters

            It 'should call all the mocks' {
                Assert-MockCalled -CommandName Set-ItemProperty -Exactly 3
                Assert-MockCalled -CommandName Test-WebsiteBinding -Exactly 1
                Assert-MockCalled -CommandName Update-WebsiteBinding -Exactly 1
                Assert-MockCalled -CommandName Update-DefaultPage -Exactly 1
                Assert-MockCalled -CommandName Stop-Website -Exactly 1
            }

        }

        Context 'Website does not exist' {

            $MockWebsite = @{
                Name             = 'MockName'
                PhysicalPath     = 'C:\NonExistent'
                State            = 'Started'
                ApplicationPool  = 'MockPool'
                Bindings         = @{Collection = @($MockWebBinding)}
                EnabledProtocols = 'http'
                Id               = 1
            }

            Mock -CommandName Get-Website
            Mock -CommandName New-Website -MockWith {return $MockWebsite}
            Mock -CommandName Stop-Website
            Mock -CommandName Test-WebsiteBinding -MockWith {return $false}
            Mock -CommandName Update-WebsiteBinding
            Mock -CommandName Set-ItemProperty
            Mock -CommandName Update-DefaultPage
            Mock -CommandName Confirm-UniqueBinding -MockWith {return $true}
            Mock -CommandName Start-Website

            $Result = Set-TargetResource @MockParameters

            It 'should call all the mocks' {
                 Assert-MockCalled -CommandName New-Website -Exactly 1
                 Assert-MockCalled -CommandName Stop-Website -Exactly 1
                 Assert-MockCalled -CommandName Test-WebsiteBinding -Exactly 1
                 Assert-MockCalled -CommandName Update-WebsiteBinding -Exactly 1
                 Assert-MockCalled -CommandName Set-ItemProperty -Exactly 1
                 Assert-MockCalled -CommandName Update-DefaultPage -Exactly 1
                 Assert-MockCalled -CommandName Confirm-UniqueBinding -Exactly 1
                 Assert-MockCalled -CommandName Start-Website -Exactly 1
            }

        }

        Context 'New website cannot be started due to a binding conflict' {

            $MockWebsite = @{
                Name             = 'MockName'
                PhysicalPath     = 'C:\NonExistent'
                State            = 'Started'
                ApplicationPool  = 'MockPool'
                Bindings         = @{Collection = @($MockWebBinding)}
                EnabledProtocols = 'http'
                Id               = 1
            }

            Mock -CommandName Get-Website
            Mock -CommandName New-Website -MockWith {return $MockWebsite}
            Mock -CommandName Stop-Website
            Mock -CommandName Test-WebsiteBinding -MockWith {return $false}
            Mock -CommandName Update-WebsiteBinding
            Mock -CommandName Set-ItemProperty
            Mock -CommandName Update-DefaultPage
            Mock -CommandName Confirm-UniqueBinding -MockWith {return $false}
            Mock -CommandName Start-Website

            It 'should throw the correct error' {

                $ErrorId = 'WebsiteBindingConflictOnStart'
                $ErrorCategory = [System.Management.Automation.ErrorCategory]::InvalidResult
                $ErrorMessage = $($LocalizedData.WebsiteBindingConflictOnStartError) -f $MockParameters.Name
                $Exception = New-Object -TypeName System.InvalidOperationException -ArgumentList $ErrorMessage
                $ErrorRecord = New-Object -TypeName System.Management.Automation.ErrorRecord -ArgumentList $Exception, $ErrorId, $ErrorCategory, $null

                {Set-TargetResource @MockParameters} |
                Should Throw $ErrorRecord

            }

        }

        Context 'New-Website throws an error' {

            Mock -CommandName Get-Website
            Mock -CommandName New-Website -MockWith {throw}

            It 'should throw the correct error' {

                $ErrorId = 'WebsiteCreationFailure'
                $ErrorCategory = [System.Management.Automation.ErrorCategory]::InvalidOperation
                $ErrorMessage = $($LocalizedData.WebsiteCreationFailureError) -f $MockParameters.Name
                $ErrorMessage += $_.Exception.Message
                $Exception = New-Object -TypeName System.InvalidOperationException -ArgumentList $ErrorMessage
                $ErrorRecord = New-Object -TypeName System.Management.Automation.ErrorRecord -ArgumentList $Exception, $ErrorId, $ErrorCategory, $null

                {Set-TargetResource @MockParameters} |
                Should Throw $ErrorRecord

            }

        }

    }

    Describe "how MSFT_xWebsite\Set-TargetResource responds to Ensure = 'Absent'" {

        $MockParameters = @{
            Ensure       = 'Absent'
            Name         = 'MockName'
            PhysicalPath = 'C:\NonExistent'
        }

        Mock -CommandName Get-Website -MockWith {return @{Name = $MockParameters.Name}}

        It 'should call Remove-Website' {

            Mock -CommandName Remove-Website

            $Result = Set-TargetResource @MockParameters

            Assert-MockCalled -CommandName Get-Website -Exactly 1
            Assert-MockCalled -CommandName Remove-Website -Exactly 1

        }

        It 'should throw the correct error' {

            Mock -CommandName Remove-Website -MockWith {throw}

            $ErrorId = 'WebsiteRemovalFailure'
            $ErrorCategory = [System.Management.Automation.ErrorCategory]::InvalidOperation
            $ErrorMessage = $($LocalizedData.WebsiteRemovalFailureError) -f $MockParameters.Name
            $Exception = New-Object -TypeName System.InvalidOperationException -ArgumentList $ErrorMessage
            $ErrorRecord = New-Object -TypeName System.Management.Automation.ErrorRecord -ArgumentList $Exception, $ErrorId, $ErrorCategory, $null

            {Set-TargetResource @MockParameters} |
            Should Throw $ErrorRecord

        }

    }

    Describe 'MSFT_xWebsite\Confirm-UniqueBinding' {

        $MockWebBinding = @(
            @{
                protocol = 'http'
                bindingInformation = '*:80:web01.contoso.com'
            }

            @{
                protocol = 'http'
                bindingInformation = '*:8080:'
            }
        )

        $MockWebsite = @{
            Name     = 'MockSiteOther'
            Bindings = @{Collection = @($MockWebBinding)}
        }

        Mock -CommandName Get-Website -MockWith {return $MockWebsite}

        Context 'Bindings are not unique' {

            It 'should return False' {

                $MockBindingInfo = @(
                    New-CimInstance -ClassName MSFT_xWebBindingInformation -Namespace root/microsoft/Windows/DesiredStateConfiguration -Property @{
                        Protocol  = 'http'
                        IPAddress = '*'
                        Port      = 80
                        HostName  = 'web01.contoso.com'
                    } -ClientOnly

                    New-CimInstance -ClassName MSFT_xWebBindingInformation -Namespace root/microsoft/Windows/DesiredStateConfiguration -Property @{
                        Protocol  = 'http'
                        IPAddress = '*'
                        Port      = 8080
                        HostName  = ''
                    } -ClientOnly
                )

                Confirm-UniqueBinding -BindingInfo $MockBindingInfo -ExcludeSite 'MockSite' |
                Should Be $false

            }

        }

        Context 'Bindings are unique' {

            It 'should return True' {

                $MockBindingInfo = @(
                    New-CimInstance -ClassName MSFT_xWebBindingInformation -Namespace root/microsoft/Windows/DesiredStateConfiguration -Property @{
                        Protocol  = 'http'
                        IPAddress = '*'
                        Port      = 8090
                        HostName  = ''
                    } -ClientOnly

                    New-CimInstance -ClassName MSFT_xWebBindingInformation -Namespace root/microsoft/Windows/DesiredStateConfiguration -Property @{
                        Protocol  = 'http'
                        IPAddress = '*'
                        Port      = 9090
                        HostName  = ''
                    } -ClientOnly
                )

                Confirm-UniqueBinding -BindingInfo $MockBindingInfo -ExcludeSite 'MockSite' |
                Should Be $true

            }

        }

    }

    Describe 'MSFT_xWebsite\ConvertTo-CimBinding' {

        Context 'IPv4 address is passed and the protocol is http' {

            $MockWebBinding = @{
                bindingInformation = '127.0.0.1:80:MockHostName'
                protocol           = 'http'
            }

            $Result = ConvertTo-CimBinding -InputObject $MockWebBinding

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

            $MockWebBinding =  @{
                bindingInformation = '[0:0:0:0:0:0:0:1]:80:MockHostName'
                protocol           = 'http'
            }

            $Result = ConvertTo-CimBinding -InputObject $MockWebBinding

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

            $MockWebBinding =  @{
                bindingInformation   = '127.0.0.1:443:MockHostName'
                protocol             = 'https'
                certificateHash      = '1D3324C6E2F7ABC794C9CB6CA426B8D0F81045CD'
                certificateStoreName = 'MY'
                sslFlags             = '1'
            }

            $Result = ConvertTo-CimBinding -InputObject $MockWebBinding

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
                $Result.CertificateThumbprint | Should Be '1D3324C6E2F7ABC794C9CB6CA426B8D0F81045CD'
            }

            It 'should return the CertificateStoreName' {
                $Result.CertificateStoreName | Should Be 'MY'
            }

            It 'should return the SslFlags' {
                $Result.SslFlags | Should Be '1'
            }

        }

        Context 'IPv6 address with SSL certificate is passed' {

            $MockWebBinding = @{
                bindingInformation   = '[0:0:0:0:0:0:0:1]:443:MockHostName'
                protocol             = 'https'
                certificateHash      = '1D3324C6E2F7ABC794C9CB6CA426B8D0F81045CD'
                certificateStoreName = 'MY'
                sslFlags             = '1'
            }

            $Result = ConvertTo-CimBinding -InputObject $MockWebBinding

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
                $Result.CertificateThumbprint | Should Be '1D3324C6E2F7ABC794C9CB6CA426B8D0F81045CD'
            }

            It 'should return the CertificateStoreName' {
                $Result.CertificateStoreName | Should Be 'MY'
            }

            It 'should return the SslFlags' {
                $Result.SslFlags | Should Be '1'
            }

        }

    }

    Describe 'MSFT_xWebsite\ConvertTo-WebBinding' {

        Context 'Expected behaviour' {

            $MockBindingInfo = @(
                New-CimInstance -ClassName MSFT_xWebBindingInformation -Namespace root/microsoft/Windows/DesiredStateConfiguration -Property @{
                    Protocol              = 'https'
                    BindingInformation    = 'NonsenseString'
                    IPAddress             = '*'
                    Port                  = 443
                    HostName              = 'web01.contoso.com'
                    CertificateThumbprint = 'C65CE51E20C523DEDCE979B9922A0294602D9D5C'
                    CertificateStoreName  = 'WebHosting'
                    SslFlags              = 1
                } -ClientOnly
            )

            $Result = ConvertTo-WebBinding -InputObject $MockBindingInfo

            It 'should return the correct Protocol value' {
                $Result.protocol | Should Be 'https'
            }

            It 'should return the correct BindingInformation value' {
                $Result.bindingInformation | Should Be '*:443:web01.contoso.com'
            }

            It 'should return the correct CertificateHash value' {
                $Result.certificateHash | Should Be 'C65CE51E20C523DEDCE979B9922A0294602D9D5C'
            }

            It 'should return the correct CertificateStoreName value' {
                $Result.certificateStoreName | Should Be 'WebHosting'
            }

            It 'should return the correct SslFlags value' {
                $Result.sslFlags | Should Be 1
            }

        }

        Context 'IP address is invalid' {

            $MockBindingInfo = @(
                New-CimInstance -ClassName MSFT_xWebBindingInformation -Namespace root/microsoft/Windows/DesiredStateConfiguration -Property @{
                    Protocol  = 'http'
                    IPAddress = '127.0.0.256'
                } -ClientOnly
            )

            It 'should throw the correct error' {

                $ErrorId = 'WebBindingInvalidIPAddress'
                $ErrorCategory = [System.Management.Automation.ErrorCategory]::InvalidResult
                $ErrorMessage = $($LocalizedData.WebBindingInvalidIPAddressError) -f $MockBindingInfo.IPAddress
                $Exception = New-Object -TypeName System.InvalidOperationException -ArgumentList $ErrorMessage
                $ErrorRecord = New-Object -TypeName System.Management.Automation.ErrorRecord -ArgumentList $Exception, $ErrorId, $ErrorCategory, $null

                {ConvertTo-WebBinding -InputObject $MockBindingInfo} |
                Should Throw $ErrorRecord

            }

        }

        Context 'Port is not specified' {

            It 'should set the default HTTP port' {

                $MockBindingInfo = @(
                    New-CimInstance -ClassName MSFT_xWebBindingInformation -Namespace root/microsoft/Windows/DesiredStateConfiguration -Property @{
                        Protocol = 'http'
                    } -ClientOnly
                )

                $Result = ConvertTo-WebBinding -InputObject $MockBindingInfo
                $Result.bindingInformation | Should Be '*:80:'

            }

            It 'should set the default HTTPS port' {

                $MockBindingInfo = @(
                    New-CimInstance -ClassName MSFT_xWebBindingInformation -Namespace root/microsoft/Windows/DesiredStateConfiguration -Property @{
                        Protocol              = 'https'
                        CertificateThumbprint = 'C65CE51E20C523DEDCE979B9922A0294602D9D5C'
                    } -ClientOnly
                )

                $Result = ConvertTo-WebBinding -InputObject $MockBindingInfo
                $Result.bindingInformation | Should Be '*:443:'

            }

        }

        Context 'Port is invalid' {

            $MockBindingInfo = @(
                New-CimInstance -ClassName MSFT_xWebBindingInformation -Namespace root/microsoft/Windows/DesiredStateConfiguration -Property @{
                    Protocol = 'http'
                    Port     = 0
                } -ClientOnly
            )

            It 'should throw the correct error' {

                $ErrorId = 'WebBindingInvalidPort'
                $ErrorCategory = [System.Management.Automation.ErrorCategory]::InvalidResult
                $ErrorMessage = $($LocalizedData.WebBindingInvalidPortError) -f $MockBindingInfo.Port
                $Exception = New-Object -TypeName System.InvalidOperationException -ArgumentList $ErrorMessage
                $ErrorRecord = New-Object -TypeName System.Management.Automation.ErrorRecord -ArgumentList $Exception, $ErrorId, $ErrorCategory, $null

                {ConvertTo-WebBinding -InputObject $MockBindingInfo} |
                Should Throw $ErrorRecord

            }

        }

        Context 'Protocol is HTTPS and CertificateThumbprint is not specified' {

            $MockBindingInfo = @(
                New-CimInstance -ClassName MSFT_xWebBindingInformation -Namespace root/microsoft/Windows/DesiredStateConfiguration -Property @{
                    Protocol              = 'https'
                    CertificateThumbprint = ''
                } -ClientOnly
            )

            It 'should throw the correct error' {

                $ErrorId = 'WebBindingMissingCertificateThumbprint'
                $ErrorCategory = [System.Management.Automation.ErrorCategory]::InvalidResult
                $ErrorMessage = $($LocalizedData.WebBindingMissingCertificateThumbprintError) -f $MockBindingInfo.Protocol
                $Exception = New-Object -TypeName System.InvalidOperationException -ArgumentList $ErrorMessage
                $ErrorRecord = New-Object -TypeName System.Management.Automation.ErrorRecord -ArgumentList $Exception, $ErrorId, $ErrorCategory, $null

                {ConvertTo-WebBinding -InputObject $MockBindingInfo} |
                Should Throw $ErrorRecord

            }

        }

        Context 'Protocol is HTTPS and CertificateStoreName is not specified' {

            $MockBindingInfo = @(
                New-CimInstance -ClassName MSFT_xWebBindingInformation -Namespace root/microsoft/Windows/DesiredStateConfiguration -Property @{
                    Protocol              = 'https'
                    CertificateThumbprint = 'C65CE51E20C523DEDCE979B9922A0294602D9D5C'
                    CertificateStoreName  = ''
                } -ClientOnly
            )

            It 'should set CertificateStoreName to the default value' {

                $Result = ConvertTo-WebBinding -InputObject $MockBindingInfo
                $Result.certificateStoreName | Should Be 'MY'

            }

        }

        Context 'Protocol is not HTTPS' {

            $MockBindingInfo = @(
                New-CimInstance -ClassName MSFT_xWebBindingInformation -Namespace root/microsoft/Windows/DesiredStateConfiguration -Property @{
                    Protocol              = 'http'
                    CertificateThumbprint = 'C65CE51E20C523DEDCE979B9922A0294602D9D5C'
                    CertificateStoreName  = 'WebHosting'
                    SslFlags              = 1
                } -ClientOnly
            )


            It 'should ignore SSL properties' {

                $Result = ConvertTo-WebBinding -InputObject $MockBindingInfo
                $Result.certificateHash      | Should Be ''
                $Result.certificateStoreName | Should Be ''
                $Result.sslFlags             | Should Be 0

            }

        }

        Context 'Protocol is neither HTTP nor HTTPS' {

            It 'should throw an error if BindingInformation is not specified' {

                $MockBindingInfo = @(
                    New-CimInstance -ClassName MSFT_xWebBindingInformation -Namespace root/microsoft/Windows/DesiredStateConfiguration -Property @{
                        Protocol           = 'net.tcp'
                        BindingInformation = ''
                    } -ClientOnly
                )

                $ErrorId = 'WebBindingMissingBindingInformation'
                $ErrorCategory = [System.Management.Automation.ErrorCategory]::InvalidResult
                $ErrorMessage = $($LocalizedData.WebBindingMissingBindingInformationError) -f $MockBindingInfo.Protocol
                $Exception = New-Object -TypeName System.InvalidOperationException -ArgumentList $ErrorMessage
                $ErrorRecord = New-Object -TypeName System.Management.Automation.ErrorRecord -ArgumentList $Exception, $ErrorId, $ErrorCategory, $null

                {ConvertTo-WebBinding -InputObject $MockBindingInfo} |
                Should Throw $ErrorRecord

            }

            It 'should use BindingInformation and ignore IPAddress, Port, and HostName' {

                $MockBindingInfo = @(
                    New-CimInstance -ClassName MSFT_xWebBindingInformation -Namespace root/microsoft/Windows/DesiredStateConfiguration -Property @{
                        Protocol           = 'net.tcp'
                        BindingInformation = '808:*'
                        IPAddress          = '127.0.0.1'
                        Port               = 80
                        HostName           = 'web01.contoso.com'
                    } -ClientOnly
                )

                $Result = ConvertTo-WebBinding -InputObject $MockBindingInfo
                $Result.BindingInformation | Should Be '808:*'

            }

        }

    }

    Describe 'MSFT_xWebsite\Format-IPAddressString' {

        Context 'Input value is not valid' {

            It 'should throw an error' {
                {Format-IPAddressString -InputString 'Invalid'} |
                Should Throw
            }

        }

        Context 'Input value is valid' {

            It 'should return "*" when input value is null' {
                Format-IPAddressString -InputString $null |
                Should Be '*'
            }

            It 'should return "*" when input value is empty' {
                Format-IPAddressString -InputString '' |
                Should Be '*'
            }

            It 'should return normalized IPv4 address' {
                Format-IPAddressString -InputString '192.10' |
                Should Be '192.0.0.10'
            }

            It 'should return normalized IPv6 address enclosed in square brackets' {
                Format-IPAddressString -InputString 'fe80:0000:0000:0000:0202:b3ff:fe1e:8329' |
                Should Be '[fe80::202:b3ff:fe1e:8329]'
            }

        }

    }

    Describe 'MSFT_xWebsite\Test-BindingInfo' {

        Context 'BindingInfo is valid' {

            $MockBindingInfo = @(
                New-CimInstance -ClassName MSFT_xWebBindingInformation -Namespace root/microsoft/Windows/DesiredStateConfiguration -Property @{
                    Protocol              = 'http'
                    IPAddress             = '*'
                    Port                  = 80
                    HostName              = ''
                    CertificateThumbprint = ''
                    CertificateStoreName  = ''
                    SslFlags              = 0
                } -ClientOnly

                New-CimInstance -ClassName MSFT_xWebBindingInformation -Namespace root/microsoft/Windows/DesiredStateConfiguration -Property @{
                    Protocol              = 'https'
                    IPAddress             = '*'
                    Port                  = 443
                    HostName              = 'web01.contoso.com'
                    CertificateThumbprint = 'C65CE51E20C523DEDCE979B9922A0294602D9D5C'
                    CertificateStoreName  = 'WebHosting'
                    SslFlags              = 1
                } -ClientOnly
            )

            It 'should return True' {
                Test-BindingInfo -BindingInfo $MockBindingInfo |
                Should Be $true
            }

        }

        Context 'BindingInfo contains multiple items with the same IPAddress, Port, and HostName combination' {

            $MockBindingInfo = @(
                New-CimInstance -ClassName MSFT_xWebBindingInformation -Namespace root/microsoft/Windows/DesiredStateConfiguration -Property @{
                    Protocol              = 'http'
                    IPAddress             = '*'
                    Port                  = 8080
                    HostName              = 'web01.contoso.com'
                    CertificateThumbprint = ''
                    CertificateStoreName  = ''
                    SslFlags              = 0
                } -ClientOnly

                New-CimInstance -ClassName MSFT_xWebBindingInformation -Namespace root/microsoft/Windows/DesiredStateConfiguration -Property @{
                    Protocol              = 'https'
                    IPAddress             = '*'
                    Port                  = 8080
                    HostName              = 'web01.contoso.com'
                    CertificateThumbprint = 'C65CE51E20C523DEDCE979B9922A0294602D9D5C'
                    CertificateStoreName  = 'WebHosting'
                    SslFlags              = 1
                } -ClientOnly
            )

            It 'should return False' {
                Test-BindingInfo -BindingInfo $MockBindingInfo |
                Should Be $false
            }

        }

        Context 'BindingInfo contains multiple items with the same Port' {

            $MockBindingInfo = @(
                New-CimInstance -ClassName MSFT_xWebBindingInformation -Namespace root/microsoft/Windows/DesiredStateConfiguration -Property @{
                    Protocol              = 'http'
                    IPAddress             = '127.0.0.1'
                    Port                  = 8080
                    HostName              = ''
                    CertificateThumbprint = ''
                    CertificateStoreName  = ''
                    SslFlags              = 0
                } -ClientOnly

                New-CimInstance -ClassName MSFT_xWebBindingInformation -Namespace root/microsoft/Windows/DesiredStateConfiguration -Property @{
                    Protocol              = 'https'
                    IPAddress             = '*'
                    Port                  = 8080
                    HostName              = 'web01.contoso.com'
                    CertificateThumbprint = 'C65CE51E20C523DEDCE979B9922A0294602D9D5C'
                    CertificateStoreName  = 'WebHosting'
                    SslFlags              = 1
                } -ClientOnly
            )

            It 'should return False' {
                Test-BindingInfo -BindingInfo $MockBindingInfo |
                Should Be $false
            }

        }

        Context 'BindingInfo contains multiple items with the same Protocol and BindingInformation combination' {

            $MockBindingInfo = @(
                New-CimInstance -ClassName MSFT_xWebBindingInformation -Namespace root/microsoft/Windows/DesiredStateConfiguration -Property @{
                    Protocol = 'net.tcp'
                    BindingInformation = '808:*'
                } -ClientOnly

                New-CimInstance -ClassName MSFT_xWebBindingInformation -Namespace root/microsoft/Windows/DesiredStateConfiguration -Property @{
                    Protocol = 'net.tcp'
                    BindingInformation = '808:*'
                } -ClientOnly
            )

            It 'should return False' {
                Test-BindingInfo -BindingInfo $MockBindingInfo |
                Should Be $false
            }

        }

    }

    Describe 'MSFT_xWebsite\Test-PortNumber' {

        Context 'Input value is not valid' {

            It 'should not throw an error' {
                {Test-PortNumber -InputString 'InvalidString'} |
                Should Not Throw
            }

            It 'should return False' {
                Test-PortNumber -InputString 'InvalidString' |
                Should Be $false
            }

            It 'should return False when input value is null' {
                Test-PortNumber -InputString $null |
                Should Be $false
            }

            It 'should return False when input value is empty' {
                Test-PortNumber -InputString '' |
                Should Be $false
            }

            It 'should return False when input value is not between 1 and 65535' {
                Test-PortNumber -InputString '100000' |
                Should Be $false
            }

        }

        Context 'Input value is valid' {

            It 'should return True' {
                Test-PortNumber -InputString '443' |
                Should Be $true
            }

        }

    }

    Describe 'MSFT_xWebsite\Test-WebsiteBinding' {

        $MockWebBinding = @(
            @{
                bindingInformation   = '*:80:'
                protocol             = 'http'
                certificateHash      = ''
                certificateStoreName = ''
                sslFlags             = '0'
            }
        )

        $MockWebsite = @{
            Name     = 'MockName'
            Bindings = @{Collection = @($MockWebBinding)}
        }

        Mock -CommandName Get-WebSite -MockWith {return $MockWebsite}

        Context 'Test-BindingInfo returns False' {

            $MockBindingInfo = @(
                New-CimInstance -ClassName MSFT_xWebBindingInformation -Namespace root/microsoft/Windows/DesiredStateConfiguration -Property @{
                    Protocol  = 'http'
                    IPAddress = '*'
                    Port      = 80
                    HostName  = ''
                } -ClientOnly
            )

            It 'should throw the correct error' {

                Mock -CommandName Test-BindingInfo -MockWith {return $false}

                $ErrorId = 'WebsiteBindingInputInvalidation'
                $ErrorCategory = [System.Management.Automation.ErrorCategory]::InvalidResult
                $ErrorMessage = $($LocalizedData.WebsiteBindingInputInvalidationError) -f $MockWebsite.Name
                $Exception = New-Object -TypeName System.InvalidOperationException -ArgumentList $ErrorMessage
                $ErrorRecord = New-Object -TypeName System.Management.Automation.ErrorRecord -ArgumentList $Exception, $ErrorId, $ErrorCategory, $null

                {Test-WebsiteBinding -Name $MockWebsite.Name -BindingInfo $MockBindingInfo} |
                Should Throw $ErrorRecord

            }

        }

        Context 'Bindings comparison throws an error' {

            $MockBindingInfo = @(
                New-CimInstance -ClassName MSFT_xWebBindingInformation -Namespace root/microsoft/Windows/DesiredStateConfiguration -Property @{
                    Protocol  = 'http'
                    IPAddress = '*'
                    Port      = 80
                    HostName  = ''
                } -ClientOnly
            )

            $ErrorId = 'WebsiteCompareFailure'
            $ErrorCategory = [System.Management.Automation.ErrorCategory]::InvalidResult
            $ErrorMessage = $($LocalizedData.WebsiteCompareFailureError) -f $MockWebsite.Name
            $Exception = New-Object -TypeName System.InvalidOperationException -ArgumentList $ErrorMessage
            $ErrorRecord = New-Object -TypeName System.Management.Automation.ErrorRecord -ArgumentList $Exception, $ErrorId, $ErrorCategory, $null

            It 'should not return an error' {
                {Test-WebsiteBinding -Name $MockWebsite.Name -BindingInfo $MockBindingInfo} |
                Should Not Throw $ErrorRecord
            }

        }

        Context 'Port is different' {

            $MockBindingInfo = @(
                New-CimInstance -ClassName MSFT_xWebBindingInformation -Namespace root/microsoft/Windows/DesiredStateConfiguration -Property @{
                    Protocol              = 'http'
                    IPAddress             = '*'
                    Port                  = 8080
                    HostName              = ''
                    CertificateThumbprint = ''
                    CertificateStoreName  = ''
                    SslFlags              = 0
                } -ClientOnly
            )

            It 'should return False' {
                Test-WebsiteBinding -Name $MockWebsite.Name -BindingInfo $MockBindingInfo |
                Should Be $false
            }

        }

        Context 'Protocol is different' {

            $MockBindingInfo = @(
                New-CimInstance -ClassName MSFT_xWebBindingInformation -Namespace root/microsoft/Windows/DesiredStateConfiguration -Property @{
                    Protocol              = 'https'
                    IPAddress             = '*'
                    Port                  = 80
                    HostName              = ''
                    CertificateThumbprint = '1D3324C6E2F7ABC794C9CB6CA426B8D0F81045CD'
                    CertificateStoreName  = 'WebHosting'
                    SslFlags              = 1
                } -ClientOnly
            )

            It 'should return False' {
                Test-WebsiteBinding -Name $MockWebsite.Name -BindingInfo $MockBindingInfo |
                Should Be $false
            }

        }

        Context 'IPAddress is different' {

            $MockBindingInfo = @(
                New-CimInstance -ClassName MSFT_xWebBindingInformation -Namespace root/microsoft/Windows/DesiredStateConfiguration -Property @{
                    Protocol              = 'http'
                    IPAddress             = '127.0.0.1'
                    Port                  = 80
                    HostName              = ''
                    CertificateThumbprint = ''
                    CertificateStoreName  = ''
                    SslFlags              = 0
                } -ClientOnly
            )

            It 'should return False' {
                Test-WebsiteBinding -Name $MockWebsite.Name -BindingInfo $MockBindingInfo |
                Should Be $false
            }

        }

        Context 'HostName is different' {

            $MockBindingInfo = @(
                New-CimInstance -ClassName MSFT_xWebBindingInformation -Namespace root/microsoft/Windows/DesiredStateConfiguration -Property @{
                    Protocol              = 'http'
                    IPAddress             = '*'
                    Port                  = 80
                    HostName              = 'MockHostName'
                    CertificateThumbprint = ''
                    CertificateStoreName  = ''
                    SslFlags              = 0
                } -ClientOnly
            )

            It 'should return False' {
                Test-WebsiteBinding -Name $MockWebsite.Name -BindingInfo $MockBindingInfo |
                Should Be $false
            }

        }

        Context 'CertificateThumbprint is different' {

            $MockBindingInfo = @(
                New-CimInstance -ClassName MSFT_xWebBindingInformation -Namespace root/microsoft/Windows/DesiredStateConfiguration -Property @{
                    Protocol              = 'https'
                    IPAddress             = '*'
                    Port                  = 443
                    HostName              = ''
                    CertificateThumbprint = '1D3324C6E2F7ABC794C9CB6CA426B8D0F81045CD'
                    CertificateStoreName  = 'MY'
                    SslFlags              = 0
                } -ClientOnly
            )

            $MockWebBinding = @(
                @{
                    bindingInformation   = '*:443:'
                    protocol             = 'https'
                    certificateHash      = 'B30F3184A831320382C61EFB0551766321FA88A5'
                    certificateStoreName = 'MY'
                    sslFlags             = '0'
                }
            )

            $MockWebsite = @{
                Name     = 'MockSite'
                Bindings = @{Collection = @($MockWebBinding)}
            }

            Mock -CommandName Get-WebSite -MockWith {return $MockWebsite}

            It 'should return False' {
                Test-WebsiteBinding -Name $MockWebsite.Name -BindingInfo $MockBindingInfo |
                Should Be $false
            }

        }

        Context 'CertificateStoreName is different' {

            $MockBindingInfo = @(
                New-CimInstance -ClassName MSFT_xWebBindingInformation -Namespace root/microsoft/Windows/DesiredStateConfiguration -Property @{
                    Protocol              = 'https'
                    IPAddress             = '*'
                    Port                  = 443
                    HostName              = ''
                    CertificateThumbprint = '1D3324C6E2F7ABC794C9CB6CA426B8D0F81045CD'
                    CertificateStoreName  = 'MY'
                    SslFlags              = 0
                } -ClientOnly
            )

            $MockWebBinding = @{
                bindingInformation   = '*:443:'
                protocol             = 'https'
                certificateHash      = '1D3324C6E2F7ABC794C9CB6CA426B8D0F81045CD'
                certificateStoreName = 'WebHosting'
                sslFlags             = '0'
            }

            $MockWebsite = @{
                Name     = 'MockSite'
                Bindings = @{Collection = @($MockWebBinding)}
            }

            Mock -CommandName Get-WebSite -MockWith {return $MockWebsite}

            It 'should return False' {
                Test-WebsiteBinding -Name $MockWebsite.Name -BindingInfo $MockBindingInfo |
                Should Be $false
            }

        }

        Context 'CertificateStoreName is different and no CertificateThumbprint is specified' {

            $MockBindingInfo = @(
                New-CimInstance -ClassName MSFT_xWebBindingInformation -Namespace root/microsoft/Windows/DesiredStateConfiguration -Property @{
                    Protocol              = 'https'
                    IPAddress             = '*'
                    Port                  = 443
                    HostName              = ''
                    CertificateThumbprint = ''
                    CertificateStoreName  = 'MY'
                    SslFlags              = 0
                } -ClientOnly
            )

            $MockWebBinding = @{
                bindingInformation   = '*:443:'
                protocol             = 'https'
                certificateHash      = '1D3324C6E2F7ABC794C9CB6CA426B8D0F81045CD'
                certificateStoreName = 'WebHosting'
                sslFlags             = '0'
            }

            $MockWebsite = @{
                Name     = 'MockSite'
                Bindings = @{Collection = @($MockWebBinding)}
            }

            Mock -CommandName Get-WebSite -MockWith {return $MockWebsite}

            $ErrorId = 'WebsiteBindingInputInvalidation'
            $ErrorCategory = [System.Management.Automation.ErrorCategory]::InvalidResult
            $ErrorMessage = $($LocalizedData.WebsiteBindingInputInvalidationError) -f $MockWebsite.Name
            $Exception = New-Object -TypeName System.InvalidOperationException -ArgumentList $ErrorMessage
            $ErrorRecord = New-Object -TypeName System.Management.Automation.ErrorRecord -ArgumentList $Exception, $ErrorId, $ErrorCategory, $null

            It 'should throw the correct error' {
                {Test-WebsiteBinding -Name $MockWebsite.Name -BindingInfo $MockBindingInfo} |
                Should Throw $ErrorRecord
            }

        }

        Context 'SslFlags is different' {

            $MockBindingInfo = @(
                New-CimInstance -ClassName MSFT_xWebBindingInformation -Namespace root/microsoft/Windows/DesiredStateConfiguration -Property @{
                    Protocol              = 'https'
                    IPAddress             = '*'
                    Port                  = 443
                    HostName              = ''
                    CertificateThumbprint = '1D3324C6E2F7ABC794C9CB6CA426B8D0F81045CD'
                    CertificateStoreName  = 'WebHosting'
                    SslFlags              = 1
                } -ClientOnly
            )

            $MockWebBinding = @{
                bindingInformation   = '*:443:'
                protocol             = 'https'
                certificateHash      = '1D3324C6E2F7ABC794C9CB6CA426B8D0F81045CD'
                certificateStoreName = 'WebHosting'
                sslFlags             = '0'
            }

            $MockWebsite = @{
                Name     = 'MockSite'
                Bindings = @{Collection = @($MockWebBinding)}
            }

            Mock -CommandName Get-WebSite -MockWith {return $MockWebsite}

            It 'should return False' {
                Test-WebsiteBinding -Name $MockWebsite.Name -BindingInfo $MockBindingInfo |
                Should Be $false
            }

        }

        Context 'Identical collections of bindings' {

            $MockBindingInfo = @(
                New-CimInstance -ClassName MSFT_xWebBindingInformation -Namespace root/microsoft/Windows/DesiredStateConfiguration -Property @{
                    Protocol              = 'https'
                    Port                  = 443
                    IPAddress             = '*'
                    HostName              = 'web01.contoso.com'
                    CertificateThumbprint = '1D3324C6E2F7ABC794C9CB6CA426B8D0F81045CD'
                    CertificateStoreName  = 'WebHosting'
                    SslFlags              = 1
                } -ClientOnly

                New-CimInstance -ClassName MSFT_xWebBindingInformation -Namespace root/microsoft/Windows/DesiredStateConfiguration -Property @{
                    IPAddress             = '*'
                    Port                  = 8080
                    HostName              = ''
                    Protocol              = 'http'
                    CertificateThumbprint = ''
                    CertificateStoreName  = ''
                    SslFlags              = 0
                } -ClientOnly
            )

            $MockWebBinding = @(
                @{
                    bindingInformation   = '*:443:web01.contoso.com'
                    protocol             = 'https'
                    certificateHash      = '1D3324C6E2F7ABC794C9CB6CA426B8D0F81045CD'
                    certificateStoreName = 'WebHosting'
                    sslFlags             = '1'
                }

                @{
                    bindingInformation   = '*:8080:'
                    protocol             = 'http'
                    certificateHash      = ''
                    certificateStoreName = ''
                    sslFlags             = '0'
                }
            )

            $MockWebsite = @{
                Name     = 'MockSite'
                Bindings = @{Collection = @($MockWebBinding)}
            }

            Mock -CommandName Get-WebSite -MockWith {return $MockWebsite}

            It 'should return True' {
                Test-WebsiteBinding -Name $MockWebsite.Name -BindingInfo $MockBindingInfo |
                Should Be $true
            }

        }

        Context 'Different collections of bindings' {

            $MockBindingInfo = @(
                New-CimInstance -ClassName MSFT_xWebBindingInformation -Namespace root/microsoft/Windows/DesiredStateConfiguration -Property @{
                    Protocol              = 'http'
                    IPAddress             = '*'
                    Port                  = 80
                    HostName              = ''
                    CertificateThumbprint = ''
                    CertificateStoreName  = ''
                    SslFlags              = 0
                } -ClientOnly

                New-CimInstance -ClassName MSFT_xWebBindingInformation -Namespace root/microsoft/Windows/DesiredStateConfiguration -Property @{
                    Protocol              = 'http'
                    IPAddress             = '*'
                    Port                  = 8080
                    HostName              = ''
                    CertificateThumbprint = ''
                    CertificateStoreName  = ''
                    SslFlags              = 0
                } -ClientOnly
            )

            $MockWebBinding = @(
                @{
                    bindingInformation   = '*:80:'
                    protocol             = 'http'
                    certificateHash      = ''
                    certificateStoreName = ''
                    sslFlags             = '0'
                }

                @{
                    bindingInformation   = '*:8081:'
                    protocol             = 'http'
                    certificateHash      = ''
                    certificateStoreName = ''
                    sslFlags             = '0'
                }
            )

            $MockWebsite = @{
                Name     = 'MockSite'
                Bindings = @{Collection = @($MockWebBinding)}
            }

            Mock -CommandName Get-Website -MockWith {return $MockWebsite}

            It 'should return False' {
                Test-WebsiteBinding -Name $MockWebsite.Name -BindingInfo $MockBindingInfo |
                Should Be $false
            }

        }

    }

    Describe 'MSFT_xWebsite\Update-DefaultPage' {

        $MockWebsite = @{
            Ensure             = 'Present'
            Name               = 'MockName'
            PhysicalPath       = 'C:\NonExistent'
            State              = 'Started'
            ApplicationPool    = 'MockPool'
            DefaultPage        = 'index.htm'
        }

        Context 'Does not find the default page' {

            Mock -CommandName Get-WebConfiguration -MockWith {
                return @{value = 'index2.htm'}
            }

            Mock -CommandName Add-WebConfiguration

            It 'should call Add-WebConfiguration' {
                $Result = Update-DefaultPage -Name $MockWebsite.Name -DefaultPage $MockWebsite.DefaultPage
                Assert-MockCalled -CommandName Add-WebConfiguration
            }

        }

    }

    Describe 'MSFT_xWebsite\Update-WebsiteBinding' {

        $MockWebsite = @{
            Name      = "MockSite"
            ItemXPath = "/system.applicationHost/sites/site[@name='MockSite']"
        }

        $MockBindingInfo = @(
            New-CimInstance -ClassName MSFT_xWebBindingInformation -Namespace root/microsoft/Windows/DesiredStateConfiguration -Property @{
                Protocol              = 'https'
                IPAddress             = '*'
                Port                  = 443
                HostName              = ''
                CertificateThumbprint = '5846A1B276328B1A32A30150858F6383C1F30E1F'
                CertificateStoreName  = 'MY'
                SslFlags              = 0
            } -ClientOnly
        )

        Mock -CommandName Get-WebConfiguration -ParameterFilter {
            $Filter -eq '/system.applicationHost/sites/site'
        } -MockWith {
            return $MockWebsite
        } -Verifiable

        Mock -CommandName Clear-WebConfiguration -Verifiable

        Context 'Expected behavior' {

            Mock -CommandName Add-WebConfiguration
            Mock -CommandName Set-WebConfigurationProperty

            Mock -CommandName Get-WebConfiguration -ParameterFilter {
                $Filter -eq "$($MockWebsite.ItemXPath)/bindings/binding[last()]"
            } -MockWith {
                New-Module -AsCustomObject -ScriptBlock {
                    function AddSslCertificate {}
                }
            } -Verifiable

            Update-WebsiteBinding -Name $MockWebsite.Name -BindingInfo $MockBindingInfo

            It 'should call all the mocks' {
                Assert-Verifiablemocks
                Assert-MockCalled -CommandName Add-WebConfiguration -Exactly $MockBindingInfo.Count
                Assert-MockCalled -CommandName Set-WebConfigurationProperty
            }

        }

        Context 'Website does not exist' {

            Mock -CommandName Get-WebConfiguration -ParameterFilter {
                $Filter -eq '/system.applicationHost/sites/site'
            } -MockWith {
                return $null
            }

            It 'should throw the correct error' {

                $ErrorId = 'WebsiteNotFound'
                $ErrorCategory = [System.Management.Automation.ErrorCategory]::InvalidResult
                $ErrorMessage = $($LocalizedData.WebsiteNotFoundError) -f $MockWebsite.Name
                $Exception = New-Object -TypeName System.InvalidOperationException -ArgumentList $ErrorMessage
                $ErrorRecord = New-Object -TypeName System.Management.Automation.ErrorRecord -ArgumentList $Exception, $ErrorId, $ErrorCategory, $null

                {Update-WebsiteBinding -Name $MockWebsite.Name -BindingInfo $MockBindingInfo} |
                Should Throw $ErrorRecord

            }

        }

        Context 'Error on adding a new binding' {

            Mock -CommandName Add-WebConfiguration -ParameterFilter {
                $Filter -eq "$($MockWebsite.ItemXPath)/bindings"
            } -MockWith {
                throw
            }

            It 'should throw the correct error' {

                $ErrorId = 'WebsiteBindingUpdateFailure'
                $ErrorCategory = [System.Management.Automation.ErrorCategory]::InvalidResult
                $ErrorMessage = $($LocalizedData.WebsiteBindingUpdateFailureError) -f $MockWebsite.Name
                $Exception = New-Object -TypeName System.InvalidOperationException -ArgumentList $ErrorMessage
                $ErrorRecord = New-Object -TypeName System.Management.Automation.ErrorRecord -ArgumentList $Exception, $ErrorId, $ErrorCategory, $null

                {Update-WebsiteBinding -Name $MockWebsite.Name -BindingInfo $MockBindingInfo} |
                Should Throw $ErrorRecord

            }

        }

        Context 'Error on setting sslFlags attribute' {

            Mock -CommandName Add-WebConfiguration

            Mock -CommandName Set-WebConfigurationProperty -ParameterFilter {
                $Filter -eq "$($MockWebsite.ItemXPath)/bindings/binding[last()]" -and $Name -eq 'sslFlags'
            } -MockWith {
                throw
            }

            It 'should throw the correct error' {

                $ErrorId = 'WebsiteBindingUpdateFailure'
                $ErrorCategory = [System.Management.Automation.ErrorCategory]::InvalidResult
                $ErrorMessage = $($LocalizedData.WebsiteBindingUpdateFailureError) -f $MockWebsite.Name
                $Exception = New-Object -TypeName System.InvalidOperationException -ArgumentList $ErrorMessage
                $ErrorRecord = New-Object -TypeName System.Management.Automation.ErrorRecord -ArgumentList $Exception, $ErrorId, $ErrorCategory, $null

                {Update-WebsiteBinding -Name $MockWebsite.Name -BindingInfo $MockBindingInfo} |
                Should Throw $ErrorRecord
            }

        }

        Context 'Error on adding SSL certificate' {

            Mock -CommandName Add-WebConfiguration
            Mock -CommandName Set-WebConfigurationProperty

            Mock -CommandName Get-WebConfiguration -ParameterFilter {
                $Filter -eq "$($MockWebsite.ItemXPath)/bindings/binding[last()]"
            } -MockWith {
                New-Module -AsCustomObject -ScriptBlock {
                    function AddSslCertificate {throw}
                }
            }

            It 'should throw the correct error' {

                $ErrorId = 'WebBindingCertificateError'
                $ErrorCategory = [System.Management.Automation.ErrorCategory]::InvalidOperation
                $ErrorMessage = $($LocalizedData.WebBindingCertificateError) -f $MockBindingInfo.CertificateThumbprint
                $Exception = New-Object -TypeName System.InvalidOperationException -ArgumentList $ErrorMessage
                $ErrorRecord = New-Object -TypeName System.Management.Automation.ErrorRecord -ArgumentList $Exception, $ErrorId, $ErrorCategory, $null

                {Update-WebsiteBinding -Name $MockWebsite.Name -BindingInfo $MockBindingInfo} |
                Should Throw $ErrorRecord

            }

        }

    }

}

# Cleanup after the test
Remove-Item -Path $ModuleRoot -Recurse -Force
