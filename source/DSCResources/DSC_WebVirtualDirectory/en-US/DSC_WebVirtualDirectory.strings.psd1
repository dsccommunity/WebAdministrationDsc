# culture      ="en-US"
ConvertFrom-StringData -StringData @'
    VerboseGetTargetResource               = Get-TargetResource has been run.
    VerboseSetTargetPhysicalPath           = Updating PhysicalPath for Web Virtual Directory '{0}'.
    VerboseSetTargetCredential             = Updating Credential for Web Virtual Directory '{0}'.
    VerboseSetTargetCreateVirtualDirectory = Creating new Web Virtual Directory '{0}'.
    VerboseSetTargetRemoveVirtualDirectory = Removing existing Virtual Directory '{0}'.
    VerboseTestTargetPhysicalPathFalse     = Physical path '{0}' for Web Virtual Directory '{1}' is not in desired state.
    VerboseTestTargetCredentialFalse       = Credential '{0}' for Web Virtual Directory '{1}' is not in desired state.
    VerboseTestTargetTrue                  = Web Virtual Directory is in desired state.
    VerboseTestTargetAbsentTrue            = Web Virtual Directory '{0}' should be Absent and is Absent.
'@
