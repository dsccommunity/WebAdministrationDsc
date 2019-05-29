# Load the Helper Module
Import-Module -Name "$PSScriptRoot\..\Helper.psm1"

# Import Localization Strings
$localizedData = Get-LocalizedData `
    -ResourceName 'MSFT_WebVirtualDirectory' `
    -ResourcePath (Split-Path -Parent $Script:MyInvocation.MyCommand.Path)

<#
    .SYNOPSIS
        The Get-TargetResource cmdlet is used to fetch the status of the virtual
        directory in the specific site under specific web application (if specified)
        on the target machine.

    .PARAMETER Site
        Specifies the name of the site.

    .PARAMETER Application
        Specifies the name of the web application.

    .PARAMETER Name
        Specifies the name of the virtual directory.
#>
function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Site,

        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [System.String]
        $Application,

        [Parameter(Mandatory = $true)]
        [System.String]
        $Name
    )

    Assert-Module

    $virtualDirectory = Get-WebVirtualDirectory @PSBoundParameters

    if ($virtualDirectory.Count -eq 1)
    {
        $Ensure = 'Present'
        Write-Verbose -Message ($LocalizedData.VerboseGetTargetPresent -f $Name)
    }
    else
    {
        $Ensure = 'Absent'
        Write-Verbose -Message ($LocalizedData.VerboseGetTargetAbsent -f $Name)
    }

    return @{
        Ensure                    = $Ensure
        Name                      = $Name
        Site                      = $Site
        Application               = $Application
        PhysicalPath              = $virtualDirectory.PhysicalPath
        PhysicalPathAccessAccount = $virtualDirectory.userName
        PhysicalPathAccessPass    = $virtualDirectory.password
    }
}

<#
    .SYNOPSIS
        The Set-TargetResource cmdlet is used to create, delete or configure a virtual
        directory in the specific site under specific web application (if specified)
        on the target machine.

    .PARAMETER Ensure
        Specifies whether the virtual directory should be present.

    .PARAMETER Site
        Specifies the name of the site.

    .PARAMETER Application
        Specifies the name of the web application.

    .PARAMETER Name
        Specifies the name of the virtual directory.

    .PARAMETER PhysicalPath
        Specifies physical folder location for virtual directory.

    .PARAMETER PhysicalPathAccessAccount
        Specifies username for access to the physical path if required.

    .PARAMETER PhysicalPathAccessPass
        Specifies password for access to the physical path if required.
#>
function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [Parameter()]
        [ValidateSet('Present','Absent')]
        [System.String]
        $Ensure = 'Present',

        [Parameter(Mandatory = $true)]
        [System.String]
        $Site,

        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [System.String]
        $Application,

        [Parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $PhysicalPath,

        [Parameter()]
        [System.String]
        $PhysicalPathAccessAccount,

        [Parameter()]
        [System.String]
        $PhysicalPathAccessPass
    )

    Assert-Module

    $Location = "$Site\$Name"
    if ($Application)
    {
        $Location = "$Site\$Application\$Name"
    }

    $virtualDirectory = Get-WebVirtualDirectory -Site $Site `
                                                -Name $Name `
                                                -Application $Application

    if ($Ensure -eq 'Present')
    {
        # Creating virtual directory
        if ($virtualDirectory.count -eq 0)
        {
            if ([bool]([System.Uri]$PhysicalPath).IsUnc)
            {
                # If physical path is provided using Unc syntax run New-WebVirtualDirectory with -Force flag
                $virtualDirectory = New-WebVirtualDirectory -Site $Site `
                                                            -Application $Application `
                                                            -Name $Name `
                                                            -ErrorAction Stop `
                                                            -Force
            }
            else
            {
                # Run New-WebVirtualDirectory without -Force flag to verify that the path exists
                $virtualDirectory = New-WebVirtualDirectory -Site $Site `
                                                            -Application $Application `
                                                            -Name $Name `
                                                            -PhysicalPath $PhysicalPath `
                                                            -ErrorAction Stop
            }

            Write-Verbose -Message ($LocalizedData.VerboseSetTargetCreateVirtualDirectory -f $Name)
        }

        # Update physical path if required
        if ($PSBoundParameters.ContainsKey('PhysicalPath') -and `
            $virtualDirectory.PhysicalPath -ne $PhysicalPath)
        {
            Set-ItemProperty -Path "IIS:\Sites\$Location" `
                             -Name physicalPath `
                             -Value $PhysicalPath `
                             -ErrorAction Stop
            Write-Verbose -Message ($LocalizedData.VerboseSetTargetUpdatePhysicalPath -f $Name)
        }

        # Update physical path access username if required
        if ($PSBoundParameters.ContainsKey('PhysicalPathAccessAccount') -and `
            $virtualDirectory.userName -ne $PhysicalPathAccessAccount)
        {
            Set-ItemProperty -Path "IIS:\Sites\$Location" `
                             -Name userName `
                             -Value $PhysicalPathAccessAccount `
                             -ErrorAction Stop
            Write-Verbose -Message ($LocalizedData.VerboseSetTargetUpdatePhysicalPathAccessAccount `
                             -f $Name)
        }

        # Update physical path access password if required
        if ($PSBoundParameters.ContainsKey('PhysicalPathAccessPass') -and `
            $virtualDirectory.password -ne $PhysicalPathAccessPass)
        {
            Set-ItemProperty -Path "IIS:\Sites\$Location" `
                             -Name password `
                             -Value $PhysicalPathAccessPass `
                             -ErrorAction Stop
            Write-Verbose -Message ($LocalizedData.VerboseSetTargetUpdatePhysicalPathAccessPass `
                             -f $Name)
        }
    }
    else
    {
        # Remove virtual directory
        Remove-Item -Path "IIS:\Sites\$Location" -Recurse -Force -ErrorAction Stop
        Write-Verbose -Message ($LocalizedData.VerboseSetTargetRemoveVirtualDirectory -f $Name)
    }
}

<#
    .SYNOPSIS
        The Test-TargetResource cmdlet is used to validate if the virtual directory
        is in a desired state. If the state is not correct it will return $false.
        If the state is correct it will return $true

    .PARAMETER Ensure
        Specifies whether the virtual directory should be present.

    .PARAMETER Site
        Specifies the name of the site.

    .PARAMETER Application
        Specifies the name of the web application.

    .PARAMETER Name
        Specifies the name of the virtual directory.

    .PARAMETER PhysicalPath
        Specifies physical folder location for virtual directory.

    .PARAMETER PhysicalPathAccessAccount
        Specifies username for access to the physical path if required.

    .PARAMETER PhysicalPathAccessPass
        Specifies password for access to the physical path if required.
#>
function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter()]
        [ValidateSet('Present','Absent')]
        [System.String]
        $Ensure = 'Present',

        [Parameter(Mandatory = $true)]
        [System.String]
        $Site,

        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [System.String]
        $Application,

        [Parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $PhysicalPath,

        [Parameter()]
        [System.String]
        $PhysicalPathAccessAccount,

        [Parameter()]
        [System.String]
        $PhysicalPathAccessPass
    )

    Assert-Module

    $inDesiredState = $true

    $virtualDirectory = Get-WebVirtualDirectory -Site $Site `
                                                -Application $Application `
                                                -Name $Name
    # Check Ensure
    if (($Ensure -eq 'Present' -and $virtualDirectory.Count -eq 0) -or `
        ($Ensure -eq 'Absent' -and $virtualDirectory.Count -eq 1))
    {
        $inDesiredState = $false
        Write-Verbose -Message ($LocalizedData.VerboseTestTargetFalseEnsure `
                                -f $Name)
    }

    # Only check properties if the virtual directory exists
    if ($Ensure -eq 'Present' -and $virtualDirectory.Count -eq 1)
    {
        # Check physical path
        if ($PSBoundParameters.ContainsKey('PhysicalPath') -and `
            $virtualDirectory.PhysicalPath -ne $PhysicalPath)
        {
            $inDesiredState = $false
            Write-Verbose -Message ($LocalizedData.VerboseTestTargetFalsePhysicalPath `
                                    -f $Name)
        }

        # Check physical path access username if required
        if ($PSBoundParameters.ContainsKey('PhysicalPathAccessAccount') -and `
            $virtualDirectory.userName -ne $PhysicalPathAccessAccount)
        {
            $InDesiredState = $false
            Write-Verbose -Message ($LocalizedData.VerboseTestTargetFalsePhysicalPathAccessAccount `
                                    -f $Name)
        }

        # Check physical path access password if required
        if ($PSBoundParameters.ContainsKey('PhysicalPathAccessPass') -and `
            $virtualDirectory.password -ne $PhysicalPathAccessPass)
        {
            $InDesiredState = $false
            Write-Verbose -Message ($LocalizedData.VerboseTestTargetFalsePhysicalPathAccessPass `
                                    -f $Name)
        }
    }

    if ($inDesiredState -eq $true)
    {
        Write-Verbose -Message ($LocalizedData.VerboseTestTargetTrueResult)
    }
    else
    {
        Write-Verbose -Message ($LocalizedData.VerboseTestTargetFalseResult)
    }

    return $inDesiredState
}

Export-ModuleMember -Function *-TargetResource
