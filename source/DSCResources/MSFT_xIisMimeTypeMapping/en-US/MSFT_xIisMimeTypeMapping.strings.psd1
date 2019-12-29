# culture      ="en-US"
ConvertFrom-StringData -StringData @'
    AddingType                = Adding MIMEType '{0}' for extension '{1}'.
    RemovingType              = Removing MIMEType '{0}' for extension '{1}'.
    TypeExists                = MIMEType '{0}' for extension '{1}' is in desired state.
    TypeNotPresent            = MIMEType '{0}' for extension '{1}' is not in desired State.
    VerboseGetTargetPresent   = MIMEType is Present.
    VerboseGetTargetAbsent    = MIMEType is Absent.
'@
