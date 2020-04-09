#requires -Version 4

configuration MSFT_xWebSite_Present_Started
{
    param(

        [Parameter(Mandatory = $true)]
        [String] $CertificateThumbprint

    )

    Import-DscResource -ModuleName xWebAdministration

    Node $AllNodes.NodeName
    {
        xWebSite Website
        {
            Name = $Node.Website
            SiteId = $Node.SiteId
            Ensure = 'Present'
            ApplicationType = $Node.ApplicationType
            ApplicationPool = $Node.ApplicationPool
            AuthenticationInfo = `
                MSFT_xWebAuthenticationInformation
                {
                    Anonymous = $Node.AuthenticationInfoAnonymous
                    Basic     = $Node.AuthenticationInfoBasic
                    Digest    = $Node.AuthenticationInfoDigest
                    Windows   = $Node.AuthenticationInfoWindows
                }
            BindingInfo = @(
                MSFT_xWebBindingInformation
                {
                    Protocol              = $Node.HTTPProtocol
                    Port                  = $Node.HTTPPort
                    IPAddress             = '*'
                    Hostname              = $Node.HTTP1Hostname
                }
                MSFT_xWebBindingInformation
                {
                    Protocol              = $Node.HTTPProtocol
                    Port                  = $Node.HTTPPort
                    IPAddress             = '*'
                    Hostname              = $Node.HTTP2Hostname
                }
                MSFT_xWebBindingInformation
                {
                    Protocol              = $Node.HTTPSProtocol
                    Port                  = $Node.HTTPSPort
                    IPAddress             = '*'
                    Hostname              = $Node.HTTPSHostname
                    CertificateThumbprint = $CertificateThumbprint
                    CertificateStoreName  = $Node.CertificateStoreName
                    SslFlags              = $Node.SslFlags
                }
                MSFT_xWebBindingInformation
                {
                    Protocol              = $Node.HTTPSProtocol
                    Port                  = $Node.HTTPSPort2
                    IPAddress             = '*'
                    Hostname              = $Node.HTTPSHostname
                    CertificateSubject    = $Node.HTTPSHostname
                    CertificateStoreName  = $Node.CertificateStoreName
                    SslFlags              = $Node.SslFlags
                }
            )
            DefaultPage = $Node.DefaultPage
            EnabledProtocols = $Node.EnabledProtocols
            PhysicalPath = $Node.PhysicalPath
            PreloadEnabled = $Node.PreloadEnabled
            ServiceAutoStartEnabled = $Node.ServiceAutoStartEnabled
            ServiceAutoStartProvider = $Node.ServiceAutoStartProvider
            State = 'Started'
            ServerAutoStart = $true
            LogFlags = $Node.LogFlags1
            LogFormat = $Node.LogFormat
            LogTargetW3C = 'ETW'
            LogCustomFields = @(
                MSFT_xLogCustomFieldInformation
                {
                    LogFieldName = $Node.LogFieldName1
                    SourceName   = $Node.SourceName1
                    SourceType   = $Node.SourceType1
                }
                MSFT_xLogCustomFieldInformation
                {
                    LogFieldName = $Node.LogFieldName2
                    SourceName   = $Node.SourceName2
                    SourceType   = $Node.SourceType2
                }
            )
        }
    }
}

configuration MSFT_xWebSite_Present_Stopped
{
    param(

        [Parameter(Mandatory = $true)]
        [String]$CertificateThumbprint

    )

    Import-DscResource -ModuleName xWebAdministration

    Node $AllNodes.NodeName
    {
        xWebSite Website
        {
            Name = $Node.Website
            Ensure = 'Present'
            ApplicationType = $Node.ApplicationType
            ApplicationPool = $Node.ApplicationPool
            AuthenticationInfo = `
                MSFT_xWebAuthenticationInformation
                {
                    Anonymous = $Node.AuthenticationInfoAnonymous
                    Basic     = $Node.AuthenticationInfoBasic
                    Digest    = $Node.AuthenticationInfoDigest
                    Windows   = $Node.AuthenticationInfoWindows
                }
            BindingInfo = @(
                MSFT_xWebBindingInformation
                {
                    Protocol              = $Node.HTTPProtocol
                    Port                  = $Node.HTTPPort
                    IPAddress             = '*'
                    Hostname              = $Node.HTTP1Hostname
                }
                MSFT_xWebBindingInformation
                {
                    Protocol              = $Node.HTTPProtocol
                    Port                  = $Node.HTTPPort
                    IPAddress             = '*'
                    Hostname              = $Node.HTTP2Hostname
                }
                MSFT_xWebBindingInformation
                {
                    Protocol              = $Node.HTTPSProtocol
                    Port                  = $Node.HTTPSPort
                    IPAddress             = '*'
                    Hostname              = $Node.HTTPSHostname
                    CertificateThumbprint = $CertificateThumbprint
                    CertificateStoreName  = $Node.CertificateStoreName
                    SslFlags              = $Node.SslFlags
                }
                MSFT_xWebBindingInformation
                {
                    Protocol              = $Node.HTTPSProtocol
                    Port                  = $Node.HTTPSPort2
                    IPAddress             = '*'
                    Hostname              = $Node.HTTPSHostname
                    CertificateSubject    = $Node.HTTPSHostname
                    CertificateStoreName  = $Node.CertificateStoreName
                    SslFlags              = $Node.SslFlags
                }
            )
            DefaultPage = $Node.DefaultPage
            EnabledProtocols = $Node.EnabledProtocols
            PhysicalPath = $Node.PhysicalPath
            PreloadEnabled = $Node.PreloadEnabled
            ServiceAutoStartEnabled = $Node.ServiceAutoStartEnabled
            ServiceAutoStartProvider = $Node.ServiceAutoStartProvider
            State = 'Stopped'
            ServerAutoStart = $false
            LogCustomFields = @(
                MSFT_xLogCustomFieldInformation
                {
                    LogFieldName = $Node.LogFieldName1
                    SourceName   = $Node.SourceName1
                    SourceType   = $Node.SourceType1
                }
                MSFT_xLogCustomFieldInformation
                {
                    LogFieldName = $Node.LogFieldName2
                    SourceName   = $Node.SourceName2
                    SourceType   = $Node.SourceType2
                }
            )
        }
    }
}

configuration MSFT_xWebSite_Absent
{
    Import-DscResource -ModuleName xWebAdministration

    Node $AllNodes.NodeName
    {
        xWebSite Website
        {
            Name = $Node.Website
            Ensure = 'Absent'
        }
    }
}

configuration MSFT_xWebSite_Webconfig_Get_Test_Set
{
    param(

        [Parameter(Mandatory = $true)]
        [String] $CertificateThumbprint

    )

    Import-DscResource -ModuleName PSDesiredStateConfiguration
    Import-DscResource -ModuleName xWebAdministration

    Node $AllNodes.NodeName
    {
        File WebConfig {
            Ensure = 'Present'
            DestinationPath = Join-Path -Path $Node.PhysicalPath -ChildPath 'web.config'
            Type = 'File'
            Contents = '<?xml version="1.0" encoding="utf-8"?>
            <configuration>
                <system.codedom>
                    <compilers>
                        <compiler language="c#;cs;csharp" extension=".cs" type="Microsoft.CodeDom.Providers.DotNetCompilerPlatform.CSharpCodeProvider, Microsoft.CodeDom.Providers.DotNetCompilerPlatform, Version=1.0.8.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35" warningLevel="4" compilerOptions="/langversion:default /nowarn:1659;1699;1701" />
                        <compiler language="vb;vbs;visualbasic;vbscript" extension=".vb" type="Microsoft.CodeDom.Providers.DotNetCompilerPlatform.VBCodeProvider, Microsoft.CodeDom.Providers.DotNetCompilerPlatform, Version=1.0.8.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35" warningLevel="4" compilerOptions="/langversion:default /nowarn:41008 /define:_MYTYPE=\&quot;Web\&quot; /optionInfer+" />
                    </compilers>
                </system.codedom>

                <system.web>
                    <clientTarget>
                        <add alias="uplevel" userAgent="Mozilla/5.0 (compatible; MSIE 6.0; Windows NT 5.1)"/>
                        <add alias="downlevel" userAgent="Generic Downlevel"/>
                    </clientTarget>
                </system.web>
            </configuration>'
        }

        xWebSite Website
        {
            DependsOn = '[File]WebConfig'
            Name = $Node.Website
            Ensure = 'Present'
            ApplicationType = $Node.ApplicationType
            ApplicationPool = $Node.ApplicationPool
            AuthenticationInfo = `
                MSFT_xWebAuthenticationInformation
                {
                    Anonymous = $Node.AuthenticationInfoAnonymous
                    Basic     = $Node.AuthenticationInfoBasic
                    Digest    = $Node.AuthenticationInfoDigest
                    Windows   = $Node.AuthenticationInfoWindows
                }
            BindingInfo = @(
                MSFT_xWebBindingInformation
                {
                    Protocol              = $Node.HTTPProtocol
                    Port                  = $Node.HTTPPort
                    IPAddress             = '*'
                    Hostname              = $Node.HTTP1Hostname
                }
                MSFT_xWebBindingInformation
                {
                    Protocol              = $Node.HTTPProtocol
                    Port                  = $Node.HTTPPort
                    IPAddress             = '*'
                    Hostname              = $Node.HTTP2Hostname
                }
                MSFT_xWebBindingInformation
                {
                    Protocol              = $Node.HTTPSProtocol
                    Port                  = $Node.HTTPSPort
                    IPAddress             = '*'
                    Hostname              = $Node.HTTPSHostname
                    CertificateThumbprint = $CertificateThumbprint
                    CertificateStoreName  = $Node.CertificateStoreName
                    SslFlags              = $Node.SslFlags
                }
                MSFT_xWebBindingInformation
                {
                    Protocol              = $Node.HTTPSProtocol
                    Port                  = $Node.HTTPSPort2
                    IPAddress             = '*'
                    Hostname              = $Node.HTTPSHostname
                    CertificateSubject    = $Node.HTTPSHostname
                    CertificateStoreName  = $Node.CertificateStoreName
                    SslFlags              = $Node.SslFlags
                }
            )
            DefaultPage = $Node.DefaultPage
            EnabledProtocols = $Node.EnabledProtocols
            PhysicalPath = $Node.PhysicalPath
            PreloadEnabled = $Node.PreloadEnabled
            ServiceAutoStartEnabled = $Node.ServiceAutoStartEnabled
            ServiceAutoStartProvider = $Node.ServiceAutoStartProvider
            State = 'Started'
            LogFlags = $Node.LogFlags1
            LogFormat = $Node.LogFormat
            LogCustomFields = @(
                MSFT_xLogCustomFieldInformation
                {
                    LogFieldName = $Node.LogFieldName1
                    SourceName   = $Node.SourceName1
                    SourceType   = $Node.SourceType1
                }
                MSFT_xLogCustomFieldInformation
                {
                    LogFieldName = $Node.LogFieldName2
                    SourceName   = $Node.SourceName2
                    SourceType   = $Node.SourceType2
                }
            )
        }
    }
}

configuration MSFT_xWebSite_Logging_Configured
{
    param(

        [Parameter(Mandatory = $true)]
        [String] $CertificateThumbprint

    )

    Import-DscResource -ModuleName xWebAdministration

    Node $AllNodes.NodeName
    {
        xWebSite Website
        {
            Name      = $Node.Website
            LogFlags  = $Node.LogFlags2
            LogFormat = $Node.LogFormat
        }
    }
}

configuration MSFT_xWebSite_Custom_Logging_Configured
{
    param(

        [Parameter(Mandatory = $true)]
        [String] $CertificateThumbprint

    )

    Import-DscResource -ModuleName xWebAdministration

    Node $AllNodes.NodeName
    {
        xWebSite Website
        {
            Name      = $Node.Website
            LogFlags  = $Node.LogFlags2
            LogFormat = $Node.LogFormat
            LogCustomFields = @(
                MSFT_xLogCustomFieldInformation
                {
                    LogFieldName = $Node.LogFieldName1
                    SourceName   = $Node.SourceName1
                    SourceType   = $Node.SourceType1
                    Ensure       = 'Absent'
                }
                MSFT_xLogCustomFieldInformation
                {
                    LogFieldName = $Node.LogFieldName2
                    SourceName   = $Node.SourceName2
                    SourceType   = $Node.SourceType2
                    Ensure       = 'Absent'
                }
            )
        }
    }
}
