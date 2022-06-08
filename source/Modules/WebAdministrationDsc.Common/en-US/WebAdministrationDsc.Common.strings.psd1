# Localized resources for helper module WebAdministrationDsc.Common.

ConvertFrom-StringData @'
    ArrayDoesNotMatch                   = One or more values in an array does not match the desired state. Details of the changes are below. (WACOMMON0004)
    ArrayValueThatDoesNotMatch          = {0} - {1} (WACOMMON0005)
    PropertyValueOfTypeDoesNotMatch     = {0} value does not match. Current value is '{1}', but expected the value '{2}'. (WACOMMON0006)
    UnableToCompareType                 = Unable to compare the type {0} as it is not handled by the Test-DscPropertyState cmdlet. (WACOMMON0007)
    StartProcess                        = Started the process with id {0} using the path '{1}', and with a timeout value of {2} seconds. (WACOMMON0009)
    CertificatePathError                = Certificate Path '{0}' is not valid. (WACOMMON0010)
    SearchingForCertificateUsingFilters = Looking for certificate in Store '{0}' using filter '{1}'. (WACOMMON0011)
'@
