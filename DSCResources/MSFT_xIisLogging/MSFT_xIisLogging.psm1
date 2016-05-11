#requires -Version 4.0 -Modules CimCmdlets

# Load the Helper Module
Import-Module -Name "$PSScriptRoot\..\Helper.psm1" -Verbose:$false

# Localized messages
data LocalizedData
{
    # culture="en-US"
    ConvertFrom-StringData -StringData @'

'@
}

function Get-TargetResource
{
	[CmdletBinding()]
	[OutputType([System.Collections.Hashtable])]
	param
	(
		[parameter(Mandatory = $true)]
		[System.String]
		$LogPath

	)
        Write-Verbose -Message 'Checking Current Log Path'
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
		[parameter(Mandatory = $true)]
		[System.String]
		$LogPath,

		[parameter()]
		[System.String]
		$LogFlags
	)
    
    $CurrentPath = Get-TargetResource -LogPath $LogPath

    if ($LogPath -ne $CurrentPath.LogPath) 
        {
            Write-Verbose -Message 'Setting Log Path'
            Set-WebConfigurationProperty '/system.applicationHost/sites/siteDefaults' -name logfile.directory -value $LogPath
        }
    if (Compare-LogFlags -LogFlags $LogFlags)  
        {
            Set-WebConfigurationProperty '/system.Applicationhost/Sites/SiteDefaults/logfile' -Name LogExtFileFlags -Value $LogFlags
        }
    Write-Verbose 'Done'
}


function Test-TargetResource
{
	[CmdletBinding()]
	[OutputType([System.Boolean])]
	param
	(
		[parameter(Mandatory = $true)]
		[System.String]
		$LogPath,

		[parameter()]
		[System.String]
		$LogFlags
	)

        $CurrentPath = Get-TargetResource -LogPath $LogPath

        if (-not (Test-path $LogPath))
        {
            Write-Verbose -Message 'Logfile Path does not exist'
        }
        if ($LogPath -ne $CurrentPath.Path) 
        { 
            Write-Verbose -Message 'LogPath Does Not Match'
            Return $False 
        }
        if (Compare-LogFlags -LogFlags $LogFlags)
        {
            Return $False
        }
        Return $true
}

#region Helper Functions

Function Compare-LogFlags
{

    param
	(
        [parameter()]
        [System.String]
        $LogFlags
    )

    $CurrentLogFlags = (Get-WebConfigurationProperty '/system.Applicationhost/Sites/SiteDefaults/logfile' -Name LogExtFileFlags) -split ',' | Sort-Object
    $ProposedLogFlags = $LogFlags -split ',' | Sort-Object

    if (Compare-Object -ReferenceObject $CurrentLogFlags -DifferenceObject $ProposedLogFlags)
    {
        Return $false
    }
    Return $true

}

#endregion

Export-ModuleMember -Function *-TargetResource

    