ConvertFrom-StringData @'
    ErrorPhysicalPathNotSpecifiedOrEmpty            = The PhysicalPath parameter must be provided for a virtual directory "{0}" to be created.
    VerboseGetTargetAbsent                          = No virtual directories exists with the name "{0}".
    VerboseGetTargetPresent                         = Virtual directory with the name "{0}" exists.
    VerboseSetTargetCreateVirtualDirectory          = Successfully created virtual directory "{0}".
    VerboseSetTargetRemoveVirtualDirectory          = Successfully removed virtual directory "{0}".
    VerboseSetTargetUpdatePhysicalPath              = Successfully updated PhysicalPath for the virtual directory "{0}".
    VerboseSetTargetUpdatePhysicalPathAccessPass    = Successfully updated password for physical path access in the virtual directory "{0}".
    VerboseSetTargetUpdatePhysicalPathAccessAccount = Successfully updated username for physical path access in the virtual directory "{0}".
    VerboseTestTargetFalseEnsure                    = Ensure state for the virtual directory "{0}" does not match the desired state.
    VerboseTestTargetFalsePhysicalPath              = Physical Path for the virtual directory "{0}" does not match the desired state.
    VerboseTestTargetFalsePhysicalPathAccessPass    = Password for physical path access in the virtual directory "{0}" does not match the desired state.
    VerboseTestTargetFalsePhysicalPathAccessAccount = Username for physical path access in the virtual directory "{0}" does not match the desired state.
    VerboseTestTargetFalseResult                    = The target resource is not in the desired state.
    VerboseTestTargetTrueResult                     = The target resource is already in the desired state. No action is required.
'@
