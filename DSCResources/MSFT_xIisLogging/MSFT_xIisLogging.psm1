#requires -Version 4.0 -Modules CimCmdlets

# Load the Helper Module
Import-Module -Name "$PSScriptRoot\..\Helper.psm1" -Verbose:$false

# Localized messages
data LocalizedData
{
    # culture="en-US"
    ConvertFrom-StringData -StringData @'
VerboseSetTargetAbsent = LogPath does not match and will be updated.
VerboseSetTargetAbsent = LogFlags do not match and will be updated.
VerboseTestTargetFalseLogPath = LogPath does match desired state.
VerboseTestTargetFalseLogFlags = LogFlags do not match desired state.
ErrorWebsiteLogPath = LogPath specifed does not exist.
'@
}

function Get-TargetResource
{
	[CmdletBinding()]
	[OutputType([System.Collections.Hashtable])]
	param
	(
		[Parameter(Mandatory = $true)]
		[System.String]
		$LogPath

	)

        $CurrentLogPath = (Get-WebConfigurationProperty -filter '/system.applicationHost/sites/siteDefaults' -name logfile.directory).Value
        $CurrentLogFlags = Get-WebConfigurationProperty '/system.Applicationhost/Sites/SiteDefaults/logfile' -Name LogExtFileFlags

        return @{
            LogPath   = $CurrentLogPath
            LogFlags  = $CurrentLogFlags
        }

}

function Set-TargetResource
{
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $true)]
		[System.String]
		$LogPath,

		[Parameter()]
		[System.String]
        [ValidateSet('Date','Time','ClientIP','UserName','SiteName','ComputerName','ServerIP','Method','UriStem','UriQuery','HttpStatus','Win32Status','BytesSent','BytesRecv','TimeTaken','ServerPort','UserAgent','Cookie','Referer','ProtocolVersion','Host','HttpSubStatus')]
		$LogFlags
	)
    
    $CurrentPath = Get-TargetResource -LogPath $LogPath

    if ($LogPath -ne $CurrentPath.LogPath) 
        {
            Write-Verbose -Message ($LocalizedData.VerboseSetTargetUpdateLogPath)
            Set-WebConfigurationProperty '/system.applicationHost/sites/siteDefaults' -name logfile.directory -value $LogPath
        }
    if (Compare-LogFlags -LogFlags $LogFlags)  
        {
            Write-Verbose -Message ($LocalizedData.VerboseSetTargetUpdateLogFlags)
            Set-WebConfigurationProperty '/system.Applicationhost/Sites/SiteDefaults/logfile' -Name LogExtFileFlags -Value $LogFlags
        }

}

function Test-TargetResource
{
	[CmdletBinding()]
	[OutputType([System.Boolean])]
	param
	(
		[Parameter(Mandatory = $true)]
		[System.String]
		$LogPath,

		[Parameter()]
		[System.String]
        [ValidateSet('Date','Time','ClientIP','UserName','SiteName','ComputerName','ServerIP','Method','UriStem','UriQuery','HttpStatus','Win32Status','BytesSent','BytesRecv','TimeTaken','ServerPort','UserAgent','Cookie','Referer','ProtocolVersion','Host','HttpSubStatus')]
		$LogFlags
	)

        $CurrentPath = Get-TargetResource -LogPath $LogPath

        if (-not (Test-path $LogPath))
        {
            $ErrorMessage = $LocalizedData.ErrorWebsiteLogPath -f $Name, $_.Exception.Message
            New-TerminatingError -ErrorId 'LogPathFailure' -ErrorMessage $ErrorMessage -ErrorCategory 'InvalidOperation'
        }
        if ($LogPath -ne $CurrentPath.Path) 
        { 
            Write-Verbose -Message ($LocalizedData.VerboseTestTargetFalseLogPath -f $Name, $State)
            return $False 
        }
        if (Compare-LogFlags -LogFlags $LogFlags)
        {
            Write-Verbose -Message ($LocalizedData.VerboseTestTargetFalseLogFlags -f $Name, $State)
            return $False
        }
        
        return $true

}

#region Helper Functions

Function Compare-LogFlags
{

    param
	(
        [Parameter()]
        [System.String]
        [ValidateSet('Date','Time','ClientIP','UserName','SiteName','ComputerName','ServerIP','Method','UriStem','UriQuery','HttpStatus','Win32Status','BytesSent','BytesRecv','TimeTaken','ServerPort','UserAgent','Cookie','Referer','ProtocolVersion','Host','HttpSubStatus')]
        $LogFlags
    )

    $CurrentLogFlags = (Get-WebConfigurationProperty '/system.Applicationhost/Sites/SiteDefaults/logfile' -Name LogExtFileFlags) -split ',' | Sort-Object
    $ProposedLogFlags = $LogFlags -split ',' | Sort-Object

    if (Compare-Object -ReferenceObject $CurrentLogFlags -DifferenceObject $ProposedLogFlags)
    {
        return $false
    }
    
    return $true

}

#endregion

Export-ModuleMember -Function *-TargetResource

    