$NamespaceServerConfiguration = @{
    LdapTimeoutSec               = 45
    SyncIntervalSec              = 5000
    UseFQDN                      = $True
}

Configuration MSFT_DFSDscNamespaceServerConfiguration_Config {
    Import-DscResource -ModuleName DFSDsc
    node localhost {
        DFSDscNamespaceServerConfiguration Integration_Test {
            IsSingleInstance             = 'Yes'
            LdapTimeoutSec               = $NamespaceServerConfiguration.LdapTimeoutSec
            SyncIntervalSec              = $NamespaceServerConfiguration.SyncIntervalSec
            UseFQDN                      = $NamespaceServerConfiguration.UseFQDN
        }
    }
}
