#requires -Version 4
configuration MSFT_WebVirtualDirectory_Initialize
{
    param
    (
        [Parameter()]
        [ValidateSet('Present','Absent')]
        [System.String]
        $Ensure = 'Present'
    )
    Import-DscResource -ModuleName xWebAdministration

    Node $AllNodes.NodeName
    {
        User MockUser1
        {
            Ensure                   = $Ensure
            UserName                 = $Node.PhysicalPathUserName1
            Password                 = New-Object System.Management.Automation.PSCredential ($Node.PhysicalPathUserName1, `
                                        (ConvertTo-SecureString -String $Node.PhysicalPathPassword1 -AsPlainText -Force))
            Description              = 'User account needed for validation of connection to the physical path'
            PasswordNeverExpires     = $true
            PasswordChangeNotAllowed = $true
        }

        User MockUser2
        {
            Ensure                   = $Ensure
            UserName                 = $Node.PhysicalPathUserName2
            Password                 = New-Object System.Management.Automation.PSCredential ($Node.PhysicalPathUserName2, `
                                        (ConvertTo-SecureString -String $Node.PhysicalPathPassword2 -AsPlainText -Force))
            Description              = 'User account needed for validation of connection to the physical path'
            PasswordNeverExpires     = $true
            PasswordChangeNotAllowed = $true
        }

        File FolderSiteRoot
        {
            Ensure          = $Ensure
            DestinationPath = "$($Node.WebsitePhysicalPath)\$($Node.FolderName)"
            Type            = 'Directory'
            Force           = $true
        }

        Service WWW
        {
            Name  = 'w3svc'
            State = 'Running'
        }

        xWebSite Website
        {
            Ensure          = $Ensure
            Name            = $Node.Website
            PhysicalPath    = $Node.WebsitePhysicalPath
            ApplicationPool = $Node.ApplicationPool
            BindingInfo     = MSFT_xWebBindingInformation
            {
                Protocol  = 'http'
                Port      = $Node.Port
                HostName  = $Node.Hostname
                IPAddress = '*'
            }
            DependsOn       = '[Service]WWW'
        }

        File WebApplicationDirectory
        {
            Ensure          = $Ensure
            DestinationPath = $Node.WebApplicationPhysicalPath
            Type            = 'Directory'
            Force           = $true
        }

        File FolderWebApplication
        {
            Ensure          = $Ensure
            DestinationPath = "$($Node.WebApplicationPhysicalPath)\$($Node.FolderName)"
            Type            = 'Directory'
            Force           = $true
        }

        xWebApplication WebApplication
        {
            Ensure       = $Ensure
            Name         = $Node.WebApplication
            Website      = $Node.Website
            WebAppPool   = $Node.ApplicationPool
            PhysicalPath = $Node.WebApplicationPhysicalPath
            DependsOn    = '[File]WebApplicationDirectory', '[xWebSite]Website'
        }

        1..4 | ForEach-Object {

            File "WebVirtualDirectory$_"
            {
                Ensure          = $Ensure
                DestinationPath = $Node."PhysicalPath$_"
                Type            = 'Directory'
                Force           = $true
            }

            File "FileWebVirtualDirectory$_"
            {
                Ensure          = $Ensure
                DestinationPath = $Node."PhysicalPath$_" + "\file.txt"
                Contents        = 'This is empty file'
            }
        }
    }
}

configuration MSFT_WebVirtualDirectory_Present
{
    Import-DscResource -ModuleName xWebAdministration

    Node $AllNodes.NodeName
    {
        WebVirtualDirectory VD_Site_Root
        {
            Ensure       = 'Present'
            Site         = $Node.Website
            Application  = ''
            Name         = $Node.WebVirtualDirectory
            PhysicalPath = $Node.PhysicalPath1
        }

        WebVirtualDirectory VD_Site
        {
            Ensure                    = 'Present'
            Site                      = $Node.Website
            Application               = ''
            Name                      = "$($Node.FolderName)/$($Node.WebVirtualDirectory)"
            PhysicalPath              = $Node.PhysicalPath2
            PhysicalPathAccessAccount = $Node.PhysicalPathUserName1
            PhysicalPathAccessPass    = $Node.PhysicalPathPassword1
        }

        WebVirtualDirectory VD_APP_Root
        {
            Ensure                    = 'Present'
            Site                      = $Node.Website
            Application               = $Node.WebApplication
            Name                      = $Node.WebVirtualDirectory
            PhysicalPath              = $Node.PhysicalPath3
            PhysicalPathAccessAccount = $Node.PhysicalPathUserName2
            PhysicalPathAccessPass    = $Node.PhysicalPathPassword2
        }

        WebVirtualDirectory VD_APP
        {
            Ensure       = 'Present'
            Site         = $Node.Website
            Application  = $Node.WebApplication
            Name         = "$($Node.FolderName)/$($Node.WebVirtualDirectory)"
            PhysicalPath = $Node.PhysicalPath4
        }
    }
}

configuration MSFT_WebVirtualDirectory_Absent
{
    Import-DscResource -ModuleName xWebAdministration

    Node $AllNodes.NodeName
    {
        WebVirtualDirectory VD_Site_Root
        {
            Ensure      = 'Absent'
            Site        = $Node.Website
            Application = ''
            Name        = $Node.WebVirtualDirectory
        }

        WebVirtualDirectory VD_Site
        {
            Ensure      = 'Absent'
            Site        = $Node.Website
            Application = ''
            Name        = "$($Node.FolderName)/$($Node.WebVirtualDirectory)"
        }

        WebVirtualDirectory VD_APP_Root
        {
            Ensure      = 'Absent'
            Site        = $Node.Website
            Application = $Node.WebApplication
            Name        = $Node.WebVirtualDirectory
        }

        WebVirtualDirectory VD_APP
        {
            Ensure      = 'Absent'
            Site        = $Node.Website
            Application = $Node.WebApplication
            Name        = "$($Node.FolderName)/$($Node.WebVirtualDirectory)"
        }
    }
}
