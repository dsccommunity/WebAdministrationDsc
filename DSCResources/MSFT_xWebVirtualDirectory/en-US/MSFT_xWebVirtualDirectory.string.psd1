# culture="en-US"
ConvertFrom-StringData -StringData @'
        VerboseGetTargetResource               = Get-TargetResource has been run.
        VerboseSetTargetPhysicalPath           = Updating physical path for web virtual directory "{0}".
        VerboseSetTargetCreateVirtualDirectory = Creating new Web Virtual Directory "{0}".
        VerboseSetTargetRemoveVirtualDirectory = Removing existing Virtual Directory "{0}".
        VerboseTestTargetFalse                 = Physical path "{0}" for web virtual directory "{1}" does not match desired state.
        VerboseTestTargetTrue                  = Web virtual directory is in required state.
        VerboseTestTargetAbsentTrue            = Web virtual directory "{0}" should be absent and is absent.
'@
