######################################################################################
# DSC Resource for IIS Server level http handlers
######################################################################################
# There are a few limitations with this resource:
# It only supports builtin handlers, that come with IIS, not third party ones.
# Removing handlers should be no problem, but all new handlers are added at the
# top of the list, meaning, they are tried first. There is no way of ordering the
# handler list except for removing all and then adding them in the correct order.
######################################################################################
data LocalizedData
{
    # culture="en-US"
    ConvertFrom-StringData @'
NoWebAdministrationModule=Please ensure that WebAdministration module is installed.
AddingHandler=Adding handler '{0}'
RemovingHandler=Removing handler '{0}'
HandlerExists=Handler with name '{0}' already exist
HandlerNotPresent=Handler with name '{0}' is not present as requested
HandlerStatusUnknown=Handler with name '{0}' is in an unknown status
HandlerNotSupported=The handler with name '{0}' is not supported. 
'@
}

######################################################################################
# The Get-TargetResource cmdlet.
######################################################################################
function Get-TargetResource
{
    [OutputType([Hashtable])]
    param
    (        
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [String]$Name,

        [Parameter(Mandatory)]
        [ValidateSet('Present', 'Absent')]
        [string]$Ensure = 'Present'
    )
    
    # Check if WebAdministration module is present for IIS cmdlets
    CheckIISPoshModule

    $handler = GetHandler -name $Name

    if ($handler -eq $null)
    {
        return @{
            Ensure = 'Absent'
            Name = $Name
        }
    }
    else
    {
        return @{
            Ensure = 'Present'
            Name = $Name
        }
    }
}

######################################################################################
# The Set-TargetResource cmdlet.
######################################################################################
function Set-TargetResource
{
    param
    (        
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [String]$Name,

        [Parameter(Mandatory)]
        [ValidateSet('Present', 'Absent')]
        [string]$Ensure = 'Present'
    )

        CheckIISPoshModule

        [string]$psPathRoot = 'MACHINE/WEBROOT/APPHOST'
        [string]$sectionNode = 'system.webServer/handlers'

        $handler = GetHandler -name $Name 

        if ($handler -eq $null -and $Ensure -eq 'Present')
        {
            # add the handler  
            AddHandler -name $Name    
            Write-Verbose($LocalizedData.AddingHandler -f $Name);
        }
        elseif ($handler -ne $null -and $Ensure -eq 'Absent')
        {
            # remove the handler                      
            Remove-WebConfigurationProperty -pspath $psPathRoot -filter $sectionNode -name '.' -AtElement @{name="$Name"}
            Write-Verbose($LocalizedData.RemovingHandler -f $Name);
        }
}

######################################################################################
# The Test-TargetResource cmdlet.
######################################################################################
function Test-TargetResource
{
    [OutputType([System.Boolean])]
    param
    (        
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [String]$Name,

        [Parameter(Mandatory)]
        [ValidateSet('Present', 'Absent')]
        [string]$Ensure = 'Present'
    )

    [bool]$DesiredConfigurationMatch = $true;
    
    CheckIISPoshModule

    $handler = GetHandler -name $Name 

    if (($handler -eq $null -and $Ensure -eq 'Present') -or ($handler -ne $null -and $Ensure -eq 'Absent'))
    {
        $DesiredConfigurationMatch = $false;
    }
    elseif ($handler -ne $null -and $Ensure -eq 'Present')
    {
        # Already there 
        Write-Verbose($LocalizedData.HandlerExists -f $Name);
    }
    elseif ($handler -eq $null -and $Ensure -eq 'Absent')
    {
        # handler not there and shouldn't be there.
        Write-Verbose($LocalizedData.HandlerNotPresent -f $Name);
    }
    else
    {
        $DesiredConfigurationMatch = $false;
        Write-Verbose($LocalizedData.HandlerStatusUnknown -f $Name);
    }
    
    return $DesiredConfigurationMatch
}

Function CheckIISPoshModule
{
    # Check if WebAdministration module is present for IIS cmdlets
    if(!(Get-Module -ListAvailable -Name WebAdministration))
    {
        Throw $LocalizedData.NoWebAdministrationModule
    }
}

Function GetHandler([string]$name)
{
    [string]$filter = "system.webServer/handlers/Add[@Name='" + $name + "']"
    return Get-WebConfigurationProperty  -pspath 'MACHINE/WEBROOT/APPHOST' -filter $filter -Name .
}

Function AddHandler([string]$name)
{
    # using a dictionary of PSObjects, each holding all the information about one handler
    $handlers = New-Object 'System.Collections.Generic.Dictionary[string,object]'
    # these properties are always the same on all supported versions of Windows 
    $handlers.Add('ASPClassic',(New-Object PSObject -Property @{name='ASPClassic';path='*.asp';verb='GET,HEAD,POST';modules='IsapiModule';scriptProcessor='%windir%\system32\inetsrv\asp.dll';resourceType='File'}))
    $handlers.Add('aspq-Integrated-4.0',(New-Object PSObject -Property @{name='aspq-Integrated-4.0';path='*.aspq';verb='GET,HEAD,POST,DEBUG';type='System.Web.HttpForbiddenHandler';preCondition='integratedMode,runtimeVersionv4.0'}))
    $handlers.Add('aspq-ISAPI-4.0_32bit',(New-Object PSObject -Property @{name='aspq-ISAPI-4.0_32bit';path='*.aspq';verb='*';modules='IsapiModule';scriptProcessor='%windir%\Microsoft.NET\Framework\v4.0.30319\aspnet_isapi.dll';preCondition='classicMode,runtimeVersionv4.0,bitness32';responseBufferLimit='0'}))
    $handlers.Add('aspq-ISAPI-4.0_64bit',(New-Object PSObject -Property @{name='aspq-ISAPI-4.0_64bit';path='*.aspq';verb='*';modules='IsapiModule';scriptProcessor='%windir%\Microsoft.NET\Framework64\v4.0.30319\aspnet_isapi.dll';preCondition='classicMode,runtimeVersionv4.0,bitness64';responseBufferLimit='0'}))
    $handlers.Add('AssemblyResourceLoader-Integrated-4.0',(New-Object PSObject -Property @{name='AssemblyResourceLoader-Integrated-4.0';path='WebResource.axd';verb='GET,DEBUG';type='System.Web.Handlers.AssemblyResourceLoader';preCondition='integratedMode,runtimeVersionv4.0'}))
    $handlers.Add('AssemblyResourceLoader-Integrated',(New-Object PSObject -Property @{name='AssemblyResourceLoader-Integrated';path='WebResource.axd';verb='GET,DEBUG';type='System.Web.Handlers.AssemblyResourceLoader';preCondition='integratedMode'}))
    $handlers.Add('AXD-ISAPI-2.0-64',(New-Object PSObject -Property @{name='AXD-ISAPI-2.0-64';path='*.axd';verb='GET,HEAD,POST,DEBUG';modules='IsapiModule';scriptProcessor='%windir%\Microsoft.NET\Framework64\v2.0.50727\aspnet_isapi.dll';preCondition='classicMode,runtimeVersionv2.0,bitness64';responseBufferLimit='0'}))
    $handlers.Add('AXD-ISAPI-2.0',(New-Object PSObject -Property @{name='AXD-ISAPI-2.0';path='*.axd';verb='GET,HEAD,POST,DEBUG';modules='IsapiModule';scriptProcessor='%windir%\Microsoft.NET\Framework\v2.0.50727\aspnet_isapi.dll';preCondition='classicMode,runtimeVersionv2.0,bitness32';responseBufferLimit='0'}))
    $handlers.Add('AXD-ISAPI-4.0_32bit',(New-Object PSObject -Property @{name='AXD-ISAPI-4.0_32bit';path='*.axd';verb='GET,HEAD,POST,DEBUG';modules='IsapiModule';scriptProcessor='%windir%\Microsoft.NET\Framework\v4.0.30319\aspnet_isapi.dll';preCondition='classicMode,runtimeVersionv4.0,bitness32';responseBufferLimit='0'}))
    $handlers.Add('AXD-ISAPI-4.0_64bit',(New-Object PSObject -Property @{name='AXD-ISAPI-4.0_64bit';path='*.axd';verb='GET,HEAD,POST,DEBUG';modules='IsapiModule';scriptProcessor='%windir%\Microsoft.NET\Framework64\v4.0.30319\aspnet_isapi.dll';preCondition='classicMode,runtimeVersionv4.0,bitness64';responseBufferLimit='0'}))
    $handlers.Add('CGI-exe',(New-Object PSObject -Property @{name='CGI-exe';path='*.exe';verb='*';modules='CgiModule';resourceType='File';requireAccess='Execute';allowPathInfo='true'}))
    $handlers.Add('ClientLoggingHandler',(New-Object PSObject -Property @{name='ClientLoggingHandler';path='*.log';verb='POST';modules='ClientLoggingHandler';resourceType='Unspecified';requireAccess='None'}))
    $handlers.Add('cshtm-Integrated-4.0',(New-Object PSObject -Property @{name='cshtm-Integrated-4.0';path='*.cshtm';verb='GET,HEAD,POST,DEBUG';type='System.Web.HttpForbiddenHandler';preCondition='integratedMode,runtimeVersionv4.0'}))
    $handlers.Add('cshtm-ISAPI-4.0_32bit',(New-Object PSObject -Property @{name='cshtm-ISAPI-4.0_32bit';path='*.cshtm';verb='GET,HEAD,POST,DEBUG';modules='IsapiModule';scriptProcessor='%windir%\Microsoft.NET\Framework\v4.0.30319\aspnet_isapi.dll';preCondition='classicMode,runtimeVersionv4.0,bitness32';responseBufferLimit='0'}))
    $handlers.Add('cshtm-ISAPI-4.0_64bit',(New-Object PSObject -Property @{name='cshtm-ISAPI-4.0_64bit';path='*.cshtm';verb='GET,HEAD,POST,DEBUG';modules='IsapiModule';scriptProcessor='%windir%\Microsoft.NET\Framework64\v4.0.30319\aspnet_isapi.dll';preCondition='classicMode,runtimeVersionv4.0,bitness64';responseBufferLimit='0'}))
    $handlers.Add('cshtml-Integrated-4.0',(New-Object PSObject -Property @{name='cshtml-Integrated-4.0';path='*.cshtml';verb='GET,HEAD,POST,DEBUG';type='System.Web.HttpForbiddenHandler';preCondition='integratedMode,runtimeVersionv4.0'}))
    $handlers.Add('cshtml-ISAPI-4.0_32bit',(New-Object PSObject -Property @{name='cshtml-ISAPI-4.0_32bit';path='*.cshtml';verb='GET,HEAD,POST,DEBUG';modules='IsapiModule';scriptProcessor='%windir%\Microsoft.NET\Framework\v4.0.30319\aspnet_isapi.dll';preCondition='classicMode,runtimeVersionv4.0,bitness32';responseBufferLimit='0'}))
    $handlers.Add('cshtml-ISAPI-4.0_64bit',(New-Object PSObject -Property @{name='cshtml-ISAPI-4.0_64bit';path='*.cshtml';verb='GET,HEAD,POST,DEBUG';modules='IsapiModule';scriptProcessor='%windir%\Microsoft.NET\Framework64\v4.0.30319\aspnet_isapi.dll';preCondition='classicMode,runtimeVersionv4.0,bitness64';responseBufferLimit='0'}))
    $handlers.Add('ExtensionlessUrlHandler-Integrated-4.0',(New-Object PSObject -Property @{name='ExtensionlessUrlHandler-Integrated-4.0';path='*.';verb='GET,HEAD,POST,DEBUG';type='System.Web.Handlers.TransferRequestHandler';preCondition='integratedMode,runtimeVersionv4.0';responseBufferLimit='0'}))
    $handlers.Add('ExtensionlessUrlHandler-ISAPI-4.0_32bit',(New-Object PSObject -Property @{name='ExtensionlessUrlHandler-ISAPI-4.0_32bit';path='*.';verb='GET,HEAD,POST,DEBUG';modules='IsapiModule';scriptProcessor='%windir%\Microsoft.NET\Framework\v4.0.30319\aspnet_isapi.dll';preCondition='classicMode,runtimeVersionv4.0,bitness32';responseBufferLimit='0'}))
    $handlers.Add('ExtensionlessUrlHandler-ISAPI-4.0_64bit',(New-Object PSObject -Property @{name='ExtensionlessUrlHandler-ISAPI-4.0_64bit';path='*.';verb='GET,HEAD,POST,DEBUG';modules='IsapiModule';scriptProcessor='%windir%\Microsoft.NET\Framework64\v4.0.30319\aspnet_isapi.dll';preCondition='classicMode,runtimeVersionv4.0,bitness64';responseBufferLimit='0'}))
    $handlers.Add('HttpRemotingHandlerFactory-rem-Integrated-4.0',(New-Object PSObject -Property @{name='HttpRemotingHandlerFactory-rem-Integrated-4.0';path='*.rem';verb='GET,HEAD,POST,DEBUG';type='System.Runtime.Remoting.Channels.Http.HttpRemotingHandlerFactory,;System.Runtime.Remoting,;Version=4.0.0.0,;Culture=neutral,;PublicKeyToken=b77a5c561934e089';preCondition='integratedMode,runtimeVersionv4.0'}))
    $handlers.Add('HttpRemotingHandlerFactory-rem-Integrated',(New-Object PSObject -Property @{name='HttpRemotingHandlerFactory-rem-Integrated';path='*.rem';verb='GET,HEAD,POST,DEBUG';type='System.Runtime.Remoting.Channels.Http.HttpRemotingHandlerFactory,;System.Runtime.Remoting,;Version=2.0.0.0,;Culture=neutral,;PublicKeyToken=b77a5c561934e089';preCondition='integratedMode,runtimeVersionv2.0'}))
    $handlers.Add('HttpRemotingHandlerFactory-rem-ISAPI-2.0-64',(New-Object PSObject -Property @{name='HttpRemotingHandlerFactory-rem-ISAPI-2.0-64';path='*.rem';verb='GET,HEAD,POST,DEBUG';modules='IsapiModule';scriptProcessor='%windir%\Microsoft.NET\Framework64\v2.0.50727\aspnet_isapi.dll';preCondition='classicMode,runtimeVersionv2.0,bitness64';responseBufferLimit='0'}))
    $handlers.Add('HttpRemotingHandlerFactory-rem-ISAPI-2.0',(New-Object PSObject -Property @{name='HttpRemotingHandlerFactory-rem-ISAPI-2.0';path='*.rem';verb='GET,HEAD,POST,DEBUG';modules='IsapiModule';scriptProcessor='%windir%\Microsoft.NET\Framework\v2.0.50727\aspnet_isapi.dll';preCondition='classicMode,runtimeVersionv2.0,bitness32';responseBufferLimit='0'}))
    $handlers.Add('HttpRemotingHandlerFactory-rem-ISAPI-4.0_32bit',(New-Object PSObject -Property @{name='HttpRemotingHandlerFactory-rem-ISAPI-4.0_32bit';path='*.rem';verb='GET,HEAD,POST,DEBUG';modules='IsapiModule';scriptProcessor='%windir%\Microsoft.NET\Framework\v4.0.30319\aspnet_isapi.dll';preCondition='classicMode,runtimeVersionv4.0,bitness32';responseBufferLimit='0'}))
    $handlers.Add('HttpRemotingHandlerFactory-rem-ISAPI-4.0_64bit',(New-Object PSObject -Property @{name='HttpRemotingHandlerFactory-rem-ISAPI-4.0_64bit';path='*.rem';verb='GET,HEAD,POST,DEBUG';modules='IsapiModule';scriptProcessor='%windir%\Microsoft.NET\Framework64\v4.0.30319\aspnet_isapi.dll';preCondition='classicMode,runtimeVersionv4.0,bitness64';responseBufferLimit='0'}))
    $handlers.Add('HttpRemotingHandlerFactory-soap-Integrated-4.0',(New-Object PSObject -Property @{name='HttpRemotingHandlerFactory-soap-Integrated-4.0';path='*.soap';verb='GET,HEAD,POST,DEBUG';type='System.Runtime.Remoting.Channels.Http.HttpRemotingHandlerFactory,;System.Runtime.Remoting,;Version=4.0.0.0,;Culture=neutral,;PublicKeyToken=b77a5c561934e089';preCondition='integratedMode,runtimeVersionv4.0'}))
    $handlers.Add('HttpRemotingHandlerFactory-soap-Integrated',(New-Object PSObject -Property @{name='HttpRemotingHandlerFactory-soap-Integrated';path='*.soap';verb='GET,HEAD,POST,DEBUG';type='System.Runtime.Remoting.Channels.Http.HttpRemotingHandlerFactory,;System.Runtime.Remoting,;Version=2.0.0.0,;Culture=neutral,;PublicKeyToken=b77a5c561934e089';preCondition='integratedMode,runtimeVersionv2.0'}))
    $handlers.Add('HttpRemotingHandlerFactory-soap-ISAPI-2.0-64',(New-Object PSObject -Property @{name='HttpRemotingHandlerFactory-soap-ISAPI-2.0-64';path='*.soap';verb='GET,HEAD,POST,DEBUG';modules='IsapiModule';scriptProcessor='%windir%\Microsoft.NET\Framework64\v2.0.50727\aspnet_isapi.dll';preCondition='classicMode,runtimeVersionv2.0,bitness64';responseBufferLimit='0'}))
    $handlers.Add('HttpRemotingHandlerFactory-soap-ISAPI-2.0',(New-Object PSObject -Property @{name='HttpRemotingHandlerFactory-soap-ISAPI-2.0';path='*.soap';verb='GET,HEAD,POST,DEBUG';modules='IsapiModule';scriptProcessor='%windir%\Microsoft.NET\Framework\v2.0.50727\aspnet_isapi.dll';preCondition='classicMode,runtimeVersionv2.0,bitness32';responseBufferLimit='0'}))
    $handlers.Add('HttpRemotingHandlerFactory-soap-ISAPI-4.0_32bit',(New-Object PSObject -Property @{name='HttpRemotingHandlerFactory-soap-ISAPI-4.0_32bit';path='*.soap';verb='GET,HEAD,POST,DEBUG';modules='IsapiModule';scriptProcessor='%windir%\Microsoft.NET\Framework\v4.0.30319\aspnet_isapi.dll';preCondition='classicMode,runtimeVersionv4.0,bitness32';responseBufferLimit='0'}))
    $handlers.Add('HttpRemotingHandlerFactory-soap-ISAPI-4.0_64bit',(New-Object PSObject -Property @{name='HttpRemotingHandlerFactory-soap-ISAPI-4.0_64bit';path='*.soap';verb='GET,HEAD,POST,DEBUG';modules='IsapiModule';scriptProcessor='%windir%\Microsoft.NET\Framework64\v4.0.30319\aspnet_isapi.dll';preCondition='classicMode,runtimeVersionv4.0,bitness64';responseBufferLimit='0'}))
    $handlers.Add('ISAPI-dll',(New-Object PSObject -Property @{name='ISAPI-dll';path='*.dll';verb='*';modules='IsapiModule';resourceType='File';requireAccess='Execute';allowPathInfo='true'}))
    $handlers.Add('OPTIONSVerbHandler',(New-Object PSObject -Property @{name='OPTIONSVerbHandler';path='*';verb='OPTIONS';modules='ProtocolSupportModule';requireAccess='None'}))
    $handlers.Add('PageHandlerFactory-Integrated-4.0',(New-Object PSObject -Property @{name='PageHandlerFactory-Integrated-4.0';path='*.aspx';verb='GET,HEAD,POST,DEBUG';type='System.Web.UI.PageHandlerFactory';preCondition='integratedMode,runtimeVersionv4.0'}))
    $handlers.Add('PageHandlerFactory-Integrated',(New-Object PSObject -Property @{name='PageHandlerFactory-Integrated';path='*.aspx';verb='GET,HEAD,POST,DEBUG';type='System.Web.UI.PageHandlerFactory';preCondition='integratedMode'}))
    $handlers.Add('PageHandlerFactory-ISAPI-2.0-64',(New-Object PSObject -Property @{name='PageHandlerFactory-ISAPI-2.0-64';path='*.aspx';verb='GET,HEAD,POST,DEBUG';modules='IsapiModule';scriptProcessor='%windir%\Microsoft.NET\Framework64\v2.0.50727\aspnet_isapi.dll';preCondition='classicMode,runtimeVersionv2.0,bitness64';responseBufferLimit='0'}))
    $handlers.Add('PageHandlerFactory-ISAPI-2.0',(New-Object PSObject -Property @{name='PageHandlerFactory-ISAPI-2.0';path='*.aspx';verb='GET,HEAD,POST,DEBUG';modules='IsapiModule';scriptProcessor='%windir%\Microsoft.NET\Framework\v2.0.50727\aspnet_isapi.dll';preCondition='classicMode,runtimeVersionv2.0,bitness32';responseBufferLimit='0'}))
    $handlers.Add('PageHandlerFactory-ISAPI-4.0_32bit',(New-Object PSObject -Property @{name='PageHandlerFactory-ISAPI-4.0_32bit';path='*.aspx';verb='GET,HEAD,POST,DEBUG';modules='IsapiModule';scriptProcessor='%windir%\Microsoft.NET\Framework\v4.0.30319\aspnet_isapi.dll';preCondition='classicMode,runtimeVersionv4.0,bitness32';responseBufferLimit='0'}))
    $handlers.Add('PageHandlerFactory-ISAPI-4.0_64bit',(New-Object PSObject -Property @{name='PageHandlerFactory-ISAPI-4.0_64bit';path='*.aspx';verb='GET,HEAD,POST,DEBUG';modules='IsapiModule';scriptProcessor='%windir%\Microsoft.NET\Framework64\v4.0.30319\aspnet_isapi.dll';preCondition='classicMode,runtimeVersionv4.0,bitness64';responseBufferLimit='0'}))
    $handlers.Add('rules-Integrated-4.0',(New-Object PSObject -Property @{name='rules-Integrated-4.0';path='*.rules';verb='*';type='System.ServiceModel.Activation.ServiceHttpHandlerFactory,;System.ServiceModel.Activation,;Version=4.0.0.0,;Culture=neutral,;PublicKeyToken=31bf3856ad364e35';preCondition='integratedMode,runtimeVersionv4.0'}))
    $handlers.Add('rules-ISAPI-4.0_32bit',(New-Object PSObject -Property @{name='rules-ISAPI-4.0_32bit';path='*.rules';verb='*';modules='IsapiModule';scriptProcessor='%windir%\Microsoft.NET\Framework\v4.0.30319\aspnet_isapi.dll';preCondition='classicMode,runtimeVersionv4.0,bitness32';responseBufferLimit='0'}))
    $handlers.Add('rules-ISAPI-4.0_64bit',(New-Object PSObject -Property @{name='rules-ISAPI-4.0_64bit';path='*.rules';verb='*';modules='IsapiModule';scriptProcessor='%windir%\Microsoft.NET\Framework64\v4.0.30319\aspnet_isapi.dll';preCondition='classicMode,runtimeVersionv4.0,bitness64';responseBufferLimit='0'}))
    $handlers.Add('ScriptHandlerFactoryAppServices-Integrated-4.0',(New-Object PSObject -Property @{name='ScriptHandlerFactoryAppServices-Integrated-4.0';path='*_AppService.axd';verb='*';type='System.Web.Script.Services.ScriptHandlerFactory,;System.Web.Extensions,;Version=4.0.0.0,;Culture=neutral,;PublicKeyToken=31BF3856AD364E35';preCondition='integratedMode,runtimeVersionv4.0'}))
    $handlers.Add('ScriptResourceIntegrated-4.0',(New-Object PSObject -Property @{name='ScriptResourceIntegrated-4.0';path='*ScriptResource.axd';verb='GET,HEAD';type='System.Web.Handlers.ScriptResourceHandler,;System.Web.Extensions,;Version=4.0.0.0,;Culture=neutral,;PublicKeyToken=31BF3856AD364E35';preCondition='integratedMode,runtimeVersionv4.0'}))
    $handlers.Add('SecurityCertificate',(New-Object PSObject -Property @{name='SecurityCertificate';path='*.cer';verb='GET,HEAD,POST';modules='IsapiModule';scriptProcessor='%windir%\system32\inetsrv\asp.dll';resourceType='File'}))
    $handlers.Add('SimpleHandlerFactory-Integrated-4.0',(New-Object PSObject -Property @{name='SimpleHandlerFactory-Integrated-4.0';path='*.ashx';verb='GET,HEAD,POST,DEBUG';type='System.Web.UI.SimpleHandlerFactory';preCondition='integratedMode,runtimeVersionv4.0'}))
    $handlers.Add('SimpleHandlerFactory-Integrated',(New-Object PSObject -Property @{name='SimpleHandlerFactory-Integrated';path='*.ashx';verb='GET,HEAD,POST,DEBUG';type='System.Web.UI.SimpleHandlerFactory';preCondition='integratedMode'}))
    $handlers.Add('SimpleHandlerFactory-ISAPI-2.0-64',(New-Object PSObject -Property @{name='SimpleHandlerFactory-ISAPI-2.0-64';path='*.ashx';verb='GET,HEAD,POST,DEBUG';modules='IsapiModule';scriptProcessor='%windir%\Microsoft.NET\Framework64\v2.0.50727\aspnet_isapi.dll';preCondition='classicMode,runtimeVersionv2.0,bitness64';responseBufferLimit='0'}))
    $handlers.Add('SimpleHandlerFactory-ISAPI-2.0',(New-Object PSObject -Property @{name='SimpleHandlerFactory-ISAPI-2.0';path='*.ashx';verb='GET,HEAD,POST,DEBUG';modules='IsapiModule';scriptProcessor='%windir%\Microsoft.NET\Framework\v2.0.50727\aspnet_isapi.dll';preCondition='classicMode,runtimeVersionv2.0,bitness32';responseBufferLimit='0'}))
    $handlers.Add('SimpleHandlerFactory-ISAPI-4.0_32bit',(New-Object PSObject -Property @{name='SimpleHandlerFactory-ISAPI-4.0_32bit';path='*.ashx';verb='GET,HEAD,POST,DEBUG';modules='IsapiModule';scriptProcessor='%windir%\Microsoft.NET\Framework\v4.0.30319\aspnet_isapi.dll';preCondition='classicMode,runtimeVersionv4.0,bitness32';responseBufferLimit='0'}))
    $handlers.Add('SimpleHandlerFactory-ISAPI-4.0_64bit',(New-Object PSObject -Property @{name='SimpleHandlerFactory-ISAPI-4.0_64bit';path='*.ashx';verb='GET,HEAD,POST,DEBUG';modules='IsapiModule';scriptProcessor='%windir%\Microsoft.NET\Framework64\v4.0.30319\aspnet_isapi.dll';preCondition='classicMode,runtimeVersionv4.0,bitness64';responseBufferLimit='0'}))
    $handlers.Add('SSINC-shtm',(New-Object PSObject -Property @{name='SSINC-shtm';path='*.shtm';verb='GET,HEAD,POST';modules='ServerSideIncludeModule';resourceType='File'}))
    $handlers.Add('SSINC-shtml',(New-Object PSObject -Property @{name='SSINC-shtml';path='*.shtml';verb='GET,HEAD,POST';modules='ServerSideIncludeModule';resourceType='File'}))
    $handlers.Add('SSINC-stm',(New-Object PSObject -Property @{name='SSINC-stm';path='*.stm';verb='GET,HEAD,POST';modules='ServerSideIncludeModule';resourceType='File'}))
    $handlers.Add('StaticFile',(New-Object PSObject -Property @{name='StaticFile';path='*';verb='*';modules='StaticFileModule,DefaultDocumentModule,DirectoryListingModule';resourceType='Either';requireAccess='Read'}))
    $handlers.Add('svc-Integrated-4.0',(New-Object PSObject -Property @{name='svc-Integrated-4.0';path='*.svc';verb='*';type='System.ServiceModel.Activation.ServiceHttpHandlerFactory,;System.ServiceModel.Activation,;Version=4.0.0.0,;Culture=neutral,;PublicKeyToken=31bf3856ad364e35';preCondition='integratedMode,runtimeVersionv4.0'}))
    $handlers.Add('svc-ISAPI-4.0_32bit',(New-Object PSObject -Property @{name='svc-ISAPI-4.0_32bit';path='*.svc';verb='*';modules='IsapiModule';scriptProcessor='%windir%\Microsoft.NET\Framework\v4.0.30319\aspnet_isapi.dll';preCondition='classicMode,runtimeVersionv4.0,bitness32';responseBufferLimit='0'}))
    $handlers.Add('svc-ISAPI-4.0_64bit',(New-Object PSObject -Property @{name='svc-ISAPI-4.0_64bit';path='*.svc';verb='*';modules='IsapiModule';scriptProcessor='%windir%\Microsoft.NET\Framework64\v4.0.30319\aspnet_isapi.dll';preCondition='classicMode,runtimeVersionv4.0,bitness64';responseBufferLimit='0'}))
    $handlers.Add('TraceHandler-Integrated-4.0',(New-Object PSObject -Property @{name='TraceHandler-Integrated-4.0';path='trace.axd';verb='GET,HEAD,POST,DEBUG';type='System.Web.Handlers.TraceHandler';preCondition='integratedMode,runtimeVersionv4.0'}))
    $handlers.Add('TraceHandler-Integrated',(New-Object PSObject -Property @{name='TraceHandler-Integrated';path='trace.axd';verb='GET,HEAD,POST,DEBUG';type='System.Web.Handlers.TraceHandler';preCondition='integratedMode'}))
    $handlers.Add('TRACEVerbHandler',(New-Object PSObject -Property @{name='TRACEVerbHandler';path='*';verb='TRACE';modules='ProtocolSupportModule';requireAccess='None'}))
    $handlers.Add('vbhtm-Integrated-4.0',(New-Object PSObject -Property @{name='vbhtm-Integrated-4.0';path='*.vbhtm';verb='GET,HEAD,POST,DEBUG';type='System.Web.HttpForbiddenHandler';preCondition='integratedMode,runtimeVersionv4.0'}))
    $handlers.Add('vbhtm-ISAPI-4.0_32bit',(New-Object PSObject -Property @{name='vbhtm-ISAPI-4.0_32bit';path='*.vbhtm';verb='GET,HEAD,POST,DEBUG';modules='IsapiModule';scriptProcessor='%windir%\Microsoft.NET\Framework\v4.0.30319\aspnet_isapi.dll';preCondition='classicMode,runtimeVersionv4.0,bitness32';responseBufferLimit='0'}))
    $handlers.Add('vbhtm-ISAPI-4.0_64bit',(New-Object PSObject -Property @{name='vbhtm-ISAPI-4.0_64bit';path='*.vbhtm';verb='GET,HEAD,POST,DEBUG';modules='IsapiModule';scriptProcessor='%windir%\Microsoft.NET\Framework64\v4.0.30319\aspnet_isapi.dll';preCondition='classicMode,runtimeVersionv4.0,bitness64';responseBufferLimit='0'}))
    $handlers.Add('vbhtml-Integrated-4.0',(New-Object PSObject -Property @{name='vbhtml-Integrated-4.0';path='*.vbhtml';verb='GET,HEAD,POST,DEBUG';type='System.Web.HttpForbiddenHandler';preCondition='integratedMode,runtimeVersionv4.0'}))
    $handlers.Add('vbhtml-ISAPI-4.0_32bit',(New-Object PSObject -Property @{name='vbhtml-ISAPI-4.0_32bit';path='*.vbhtml';verb='GET,HEAD,POST,DEBUG';modules='IsapiModule';scriptProcessor='%windir%\Microsoft.NET\Framework\v4.0.30319\aspnet_isapi.dll';preCondition='classicMode,runtimeVersionv4.0,bitness32';responseBufferLimit='0'}))
    $handlers.Add('vbhtml-ISAPI-4.0_64bit',(New-Object PSObject -Property @{name='vbhtml-ISAPI-4.0_64bit';path='*.vbhtml';verb='GET,HEAD,POST,DEBUG';modules='IsapiModule';scriptProcessor='%windir%\Microsoft.NET\Framework64\v4.0.30319\aspnet_isapi.dll';preCondition='classicMode,runtimeVersionv4.0,bitness64';responseBufferLimit='0'}))
    $handlers.Add('WebAdminHandler-Integrated-4.0',(New-Object PSObject -Property @{name='WebAdminHandler-Integrated-4.0';path='WebAdmin.axd';verb='GET,DEBUG';type='System.Web.Handlers.WebAdminHandler';preCondition='integratedMode,runtimeVersionv4.0'}))
    $handlers.Add('WebAdminHandler-Integrated',(New-Object PSObject -Property @{name='WebAdminHandler-Integrated';path='WebAdmin.axd';verb='GET,DEBUG';type='System.Web.Handlers.WebAdminHandler';preCondition='integratedMode'}))
    $handlers.Add('WebDAV',(New-Object PSObject -Property @{name='WebDAV';path='*';verb='PROPFIND,PROPPATCH,MKCOL,PUT,COPY,DELETE,MOVE,LOCK,UNLOCK';modules='WebDAVModule';resourceType='Unspecified';requireAccess='None'}))
    $handlers.Add('WebServiceHandlerFactory-Integrated-4.0',(New-Object PSObject -Property @{name='WebServiceHandlerFactory-Integrated-4.0';path='*.asmx';verb='GET,HEAD,POST,DEBUG';type='System.Web.Script.Services.ScriptHandlerFactory,;System.Web.Extensions,;Version=4.0.0.0,;Culture=neutral,;PublicKeyToken=31bf3856ad364e35';preCondition='integratedMode,runtimeVersionv4.0'}))
    $handlers.Add('WebServiceHandlerFactory-Integrated',(New-Object PSObject -Property @{name='WebServiceHandlerFactory-Integrated';path='*.asmx';verb='GET,HEAD,POST,DEBUG';type='System.Web.Services.Protocols.WebServiceHandlerFactory,;System.Web.Services,;Version=2.0.0.0,;Culture=neutral,;PublicKeyToken=b03f5f7f11d50a3a';preCondition='integratedMode,runtimeVersionv2.0'}))
    $handlers.Add('WebServiceHandlerFactory-ISAPI-2.0-64',(New-Object PSObject -Property @{name='WebServiceHandlerFactory-ISAPI-2.0-64';path='*.asmx';verb='GET,HEAD,POST,DEBUG';modules='IsapiModule';scriptProcessor='%windir%\Microsoft.NET\Framework64\v2.0.50727\aspnet_isapi.dll';preCondition='classicMode,runtimeVersionv2.0,bitness64';responseBufferLimit='0'}))
    $handlers.Add('WebServiceHandlerFactory-ISAPI-2.0',(New-Object PSObject -Property @{name='WebServiceHandlerFactory-ISAPI-2.0';path='*.asmx';verb='GET,HEAD,POST,DEBUG';modules='IsapiModule';scriptProcessor='%windir%\Microsoft.NET\Framework\v2.0.50727\aspnet_isapi.dll';preCondition='classicMode,runtimeVersionv2.0,bitness32';responseBufferLimit='0'}))
    $handlers.Add('WebServiceHandlerFactory-ISAPI-4.0_32bit',(New-Object PSObject -Property @{name='WebServiceHandlerFactory-ISAPI-4.0_32bit';path='*.asmx';verb='GET,HEAD,POST,DEBUG';modules='IsapiModule';scriptProcessor='%windir%\Microsoft.NET\Framework\v4.0.30319\aspnet_isapi.dll';preCondition='classicMode,runtimeVersionv4.0,bitness32';responseBufferLimit='0'}))
    $handlers.Add('WebServiceHandlerFactory-ISAPI-4.0_64bit',(New-Object PSObject -Property @{name='WebServiceHandlerFactory-ISAPI-4.0_64bit';path='*.asmx';verb='GET,HEAD,POST,DEBUG';modules='IsapiModule';scriptProcessor='%windir%\Microsoft.NET\Framework64\v4.0.30319\aspnet_isapi.dll';preCondition='classicMode,runtimeVersionv4.0,bitness64';responseBufferLimit='0'}))
    $handlers.Add('xamlx-Integrated-4.0',(New-Object PSObject -Property @{name='xamlx-Integrated-4.0';path='*.xamlx';verb='GET,HEAD,POST,DEBUG';type='System.Xaml.Hosting.XamlHttpHandlerFactory,;System.Xaml.Hosting,;Version=4.0.0.0,;Culture=neutral,;PublicKeyToken=31bf3856ad364e35';preCondition='integratedMode,runtimeVersionv4.0'}))
    $handlers.Add('xamlx-ISAPI-4.0_32bit',(New-Object PSObject -Property @{name='xamlx-ISAPI-4.0_32bit';path='*.xamlx';verb='GET,HEAD,POST,DEBUG';modules='IsapiModule';scriptProcessor='%windir%\Microsoft.NET\Framework\v4.0.30319\aspnet_isapi.dll';preCondition='classicMode,runtimeVersionv4.0,bitness32';responseBufferLimit='0'}))
    $handlers.Add('xamlx-ISAPI-4.0_64bit',(New-Object PSObject -Property @{name='xamlx-ISAPI-4.0_64bit';path='*.xamlx';verb='GET,HEAD,POST,DEBUG';modules='IsapiModule';scriptProcessor='%windir%\Microsoft.NET\Framework64\v4.0.30319\aspnet_isapi.dll';preCondition='classicMode,runtimeVersionv4.0,bitness64';responseBufferLimit='0'}))
    $handlers.Add('xoml-Integrated-4.0',(New-Object PSObject -Property @{name='xoml-Integrated-4.0';path='*.xoml';verb='*';type='System.ServiceModel.Activation.ServiceHttpHandlerFactory,;System.ServiceModel.Activation,;Version=4.0.0.0,;Culture=neutral,;PublicKeyToken=31bf3856ad364e35';preCondition='integratedMode,runtimeVersionv4.0'}))
    $handlers.Add('xoml-ISAPI-4.0_32bit',(New-Object PSObject -Property @{name='xoml-ISAPI-4.0_32bit';path='*.xoml';verb='*';modules='IsapiModule';scriptProcessor='%windir%\Microsoft.NET\Framework\v4.0.30319\aspnet_isapi.dll';preCondition='classicMode,runtimeVersionv4.0,bitness32';responseBufferLimit='0'}))
    $handlers.Add('xoml-ISAPI-4.0_64bit',(New-Object PSObject -Property @{name='xoml-ISAPI-4.0_64bit';path='*.xoml';verb='*';modules='IsapiModule';scriptProcessor='%windir%\Microsoft.NET\Framework64\v4.0.30319\aspnet_isapi.dll';preCondition='classicMode,runtimeVersionv4.0,bitness64';responseBufferLimit='0'}))

    # check whether our dictionary has an item with the specified key
    if ($handlers.ContainsKey($name))
    {
        # add the new handler
        Add-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST' -filter 'system.webServer/handlers' -name '.' -value $handlers[$name]
    }
    else
    {
        Throw ($LocalizedData.HandlerNotSupported -f $Name);
    }
}

#  FUNCTIONS TO BE EXPORTED 
Export-ModuleMember -Function *-TargetResource
