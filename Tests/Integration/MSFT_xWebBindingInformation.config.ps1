configuration WebBindingInfo
{
    Import-DscResource -ModuleName xWebAdministration

    xWebsite WebBindingInfo
    {
        Name = 'foobar'
        Ensure = 'absent'
        PhysicalPath = "$env:temp\WebBindingInfo"
    }
}
