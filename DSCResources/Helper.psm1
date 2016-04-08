# Localized messages
data LocalizedData
{
    # culture="en-US"
    ConvertFrom-StringData @'
    RoleNotFound    =   Please ensure that the PowerShell module for role {0} is installed
    ErrorWebsiteTestAutoStartProviderFailure = Desired AutoStartProvider is not valid due to a conflicting Global Property. Ensure that the serviceAutoStartProvider is a unique key.
'@
}

# Internal function to throw terminating error with specified errroCategory, errorId and errorMessage
function New-TerminatingError
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory)]
        [String] $ErrorId,

        [Parameter(Mandatory)]
        [String] $ErrorMessage,

        [Parameter(Mandatory)]
        [System.Management.Automation.ErrorCategory] $ErrorCategory
    )

    $exception = New-Object System.InvalidOperationException $errorMessage
    $errorRecord = New-Object System.Management.Automation.ErrorRecord $exception, $errorId, $errorCategory, $null
    throw $errorRecord
}

# Internal function to assert if the role specific module is installed or not
function Assert-Module
{
    [CmdletBinding()]
    param
    (
        [String] $moduleName = 'WebAdministration'
    )

    if(-not (Get-Module -Name $moduleName -ListAvailable))
    {
        $errorMsg = $($LocalizedData.RoleNotFound) -f $moduleName
        New-TerminatingError -ErrorId 'ModuleNotFound' -ErrorMessage $errorMsg -ErrorCategory ObjectNotFound
    }
}

function Confirm-UniqueServiceAutoStartProviders
{
    <#
    .SYNOPSIS
        Helper function used to validate that the AutoStartProviders is unique to other websites.
        returns False if the AutoStartProviders exist.
    .PARAMETER serviceAutoStartProvider
        Specifies the name of the AutoStartProviders.
    .PARAMETER ExcludeStopped
        Specifies the name of the Application Type for the AutoStartProvider.
    .NOTES
        This tests for the existance of a AutoStartProviders which is globally assigned. As AutoStartProviders
        need to be uniquely named it will check for this and error out if attempting to add a duplicatly named AutoStartProvider.
        Name is passed in to bubble to any error messages during the test.
    #>
    
    [CmdletBinding()]
    [OutputType([Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [String]
        $ServiceAutoStartProvider,

        [Parameter(Mandatory = $true)]
        [String]
        $ApplicationType
    )

$WebSiteAutoStartProviders = (Get-WebConfiguration -filter /system.applicationHost/serviceAutoStartProviders).Collection

$ExistingObject = $WebSiteAutoStartProviders | `
    Where-Object -Property Name -eq -Value $serviceAutoStartProvider | `
    Select-Object Name,Type

$ProposedObject = @(New-Object -TypeName PSObject -Property @{
    name   = $ServiceAutoStartProvider
    type   = $ApplicationType
})

if(-not $ExistingObject)
    {
        return $false
    }

if(-not (Compare-Object -ReferenceObject $ExistingObject -DifferenceObject $ProposedObject -Property name))
    {
        if(Compare-Object -ReferenceObject $ExistingObject -DifferenceObject $ProposedObject -Property type)
            {
                $ErrorMessage = $LocalizedData.ErrorWebsiteTestAutoStartProviderFailure
                New-TerminatingError -ErrorId 'ErrorWebsiteTestAutoStartProviderFailure' -ErrorMessage $ErrorMessage -ErrorCategory 'InvalidResult'
            }
    }

return $true

}

function Get-AuthenticationInfo
{
    <#
    .SYNOPSIS
        Helper function used to validate that the authenticationProperties for an Application.
    .PARAMETER Site
        Specifies the name of the Website.
    .PARAMETER Name
        Specifies the name of the Application.
    #>

    [OutputType([Microsoft.Management.Infrastructure.CimInstance])]
    Param
    (
        [parameter(Mandatory = $true)]
        [String]$Site,

        [parameter(Mandatory = $true)]
        [String]$Name
    )

    $authenticationProperties = @{}
    foreach ($type in @('Anonymous', 'Basic', 'Digest', 'Windows'))
    {
        $authenticationProperties[$type] = [String](Test-AuthenticationEnabled -Site $Site -Name $Name -Type $type)
    }

    return New-CimInstance `
            -ClassName MSFT_xWebApplicationAuthenticationInformation `
            -ClientOnly -Property $authenticationProperties
}

function Get-DefaultAuthenticationInfo
{
    <#
    .SYNOPSIS
        Helper function used to build a default CimInstance for AuthenticationInformation
    #>

    New-CimInstance -ClassName MSFT_xWebApplicationAuthenticationInformation `
        -ClientOnly `
        -Property @{Anonymous='false';Basic='false';Digest='false';Windows='false'}
}

function Get-SslFlags
{
    <#
    .SYNOPSIS
        Helper function used to return the SSLFlags on an Application.
    .PARAMETER Location
        Specifies the path in the IIS: PSDrive to the Application
    #>
    
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory = $true)]
        [String]$Location
    )
    `
    $SslFlags = Get-WebConfiguration `
                    -PSPath IIS:\Sites `
                    -Location $Location `
                    -Filter 'system.webserver/security/access' | `
                    ForEach-Object { $_.sslFlags }

    if ($SslFlags -eq $null) 
        { 
            [String]::Empty($SslFlags)
        } 

    return $SslFlags
}

function Set-Authentication
{
    <#
    .SYNOPSIS
        Helper function used to set authenticationProperties for an Application.
    .PARAMETER Site
        Specifies the name of the Website.
    .PARAMETER Name
        Specifies the name of the Application.
    .PARAMETER Type
        Specifies the type of Authentication, Limited to the set: ('Anonymous','Basic','Digest','Windows').
    .PARAMETER Enabled
        Whether the Authentication is enabled or not.
    #>

    Param
    (
        [parameter(Mandatory = $true)]
        [String]$Site,

        [parameter(Mandatory = $true)]
        [String]$Name,

        [parameter(Mandatory = $true)]
        [ValidateSet('Anonymous','Basic','Digest','Windows')]
        [String]$Type,

        [System.Boolean]$Enabled
    )

    Set-WebConfigurationProperty -Filter /system.WebServer/security/authentication/${Type}Authentication `
        -Name enabled `
        -Value $Enabled `
        -Location "${Site}/${Name}"
}

function Set-AuthenticationInfo
{
    <#
    .SYNOPSIS
        Helper function used to validate that the authenticationProperties for an Application.
    .PARAMETER Site
        Specifies the name of the Website.
    .PARAMETER Name
        Specifies the name of the Application.
    .PARAMETER AuthenticationInfo
        A CimInstance of what state the AuthenticationInfo should be.
    #>

    param
    (
        [parameter(Mandatory = $true)]
        [String]$Site,

        [parameter(Mandatory = $true)]
        [String]$Name,

        [parameter()]
        [ValidateNotNullOrEmpty()]
        [Microsoft.Management.Infrastructure.CimInstance]$AuthenticationInfo
    )

    foreach ($type in @('Anonymous', 'Basic', 'Digest', 'Windows'))
    {
        $enabled = ($AuthenticationInfo.CimInstanceProperties[$type].Value -eq $true)
        Set-Authentication -Site $Site -Name $Name -Type $type -Enabled $enabled
    }
}

function Test-AuthenticationEnabled
{
    <#
    .SYNOPSIS
        Helper function used to test the authenticationProperties state for an Application. 
        Will return that value which will either [String]True or [String]False
    .PARAMETER Site
        Specifies the name of the Website.
    .PARAMETER Name
        Specifies the name of the Application.
   .PARAMETER Type
        Specifies the type of Authentication, Limited to the set: ('Anonymous','Basic','Digest','Windows').
    #>

    [OutputType([System.Boolean])]
    Param
    (
        [parameter(Mandatory = $true)]
        [String]$Site,

        [parameter(Mandatory = $true)]
        [String]$Name,

        [parameter(Mandatory = $true)]
        [ValidateSet('Anonymous','Basic','Digest','Windows')]
        [String]$Type
    )


    $prop = Get-WebConfigurationProperty `
        -Filter /system.WebServer/security/authentication/${Type}Authentication `
        -Name enabled `
        -Location "${Site}/${Name}"
    return $prop.Value
}

function Test-AuthenticationInfo
{
    <#
    .SYNOPSIS
        Helper function used to test the authenticationProperties state for an Application. 
        Will return that result which will either [boolean]$True or [boolean]$False for use in Test-TargetResource.
        Uses Test-AuthenticationEnabled to determine this. First incorrect result will break this function out.
    .PARAMETER Site
        Specifies the name of the Website.
    .PARAMETER Name
        Specifies the name of the Application.
    .PARAMETER AuthenticationInfo
        A CimInstance of what state the AuthenticationInfo should be.
    #>

    [OutputType([System.Boolean])]
    param
    (
        [parameter(Mandatory = $true)]
        [String]$Site,

        [parameter(Mandatory = $true)]
        [String]$Name,

        [parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [Microsoft.Management.Infrastructure.CimInstance]$AuthenticationInfo
    )

    $result = $true

    foreach ($type in @('Anonymous', 'Basic', 'Digest', 'Windows'))
    {

        $expected = $AuthenticationInfo.CimInstanceProperties[$type].Value
        $actual = Test-AuthenticationEnabled -Site $Site -Name $Name -Type $type
        if ($expected -ne $actual)
        {
            $result = $false
            break
        }
    }

    return $result
}

function Test-SSLFlags
{
    <#
    .SYNOPSIS
        Helper function used to test the SSLFlags on an Application. 
        Will return $true if they match and $false if they do not.
    .PARAMETER SslFlags
        Specifies the SslFlags to Test
    .PARAMETER Location
        Specifies the path in the IIS: PSDrive to the Application
    #>

    [CmdletBinding()]
    [OutputType([Boolean])]
    param
    (
        [ValidateNotNull()]
        [ValidateSet('Ssl','SslNegotiateCert','SslRequireCert')]
        [String[]]$SslFlags = '',

        [parameter(Mandatory = $true)]
        [String]$Location
    )


$CurrentSslFlags =  Get-SslFlags -Location $Location

if (Compare-Object -ReferenceObject $CurrentSslFlags -DifferenceObject $SslFlags)
    {
        return $false
    }

return $true

}
