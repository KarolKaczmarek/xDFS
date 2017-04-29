$script:ResourceRootPath = Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent)

# Import the xCertificate Resource Module (to import the common modules)
Import-Module -Name (Join-Path -Path $script:ResourceRootPath -ChildPath 'xDFS.psd1')

# Import Localization Strings
$localizedData = Get-LocalizedData `
    -ResourceName 'MSFT_xDFSNamespaceServerConfiguration' `
    -ResourcePath (Split-Path -Parent $Script:MyInvocation.MyCommand.Path)

<#
    This is an array of all the parameters used by this resource
    If the property Restart is true then when this property is updated the service
    Will be restarted.
#>
data parameterList
{
    @(
        @{ Name = 'LdapTimeoutSec';            Type = 'Uint32'  },
        @{ Name = 'SyncIntervalSec';           Type = 'String'  },
        @{ Name = 'UseFQDN';                   Type = 'Uint32'; Restart = $True }
    )
}

function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateSet('Yes')]
        [System.String]
        $IsSingleInstance
    )

    Write-Verbose -Message ( @(
            "$($MyInvocation.MyCommand): "
            $($LocalizedData.GettingNamespaceServerConfigurationMessage)
        ) -join '' )

    # The ComputerName will always be LocalHost unless a good reason can be provided to
    # enable it as a parameter.
    $computerName = 'LocalHost'

    # Get the current DFSN Server Configuration
    $serverConfiguration = Get-DfsnServerConfiguration `
        -ComputerName $computerName `
        -ErrorAction Stop

    # Generate the return object.
    $returnValue = @{
        IsSingleInstance = 'Yes'
    }
    foreach ($parameter in $parameterList)
    {
        $returnValue += @{ $parameter.Name = $serverConfiguration.$($parameter.name) }
    } # foreach

    return $returnValue
} # Get-TargetResource

function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateSet('Yes')]
        [System.String]
        $IsSingleInstance,

        [Parameter()]
        [System.UInt32]
        $LdapTimeoutSec,

        [Parameter()]
        [System.UInt32]
        $SyncIntervalSec,

        [Parameter()]
        [System.Boolean]
        $UseFQDN
    )

    Write-Verbose -Message ( @(
            "$($MyInvocation.MyCommand): "
            $($LocalizedData.SettingNamespaceServerConfigurationMessage)
        ) -join '' )

    # The ComputerName will always be LocalHost unless a good reason can be provided to
    # enable it as a parameter.
    $computerName = 'LocalHost'

    # Get the current DFSN Server Configuration
    $serverConfiguration = Get-DfsnServerConfiguration `
        -ComputerName $computerName `
        -ErrorAction Stop

    # Generate a list of parameters that will need to be changed.
    $changeParameters = @{}
    $restart = $False
    foreach ($parameter in $parameterList)
    {
        $parameterSource = $serverConfiguration.$($parameter.name)
        $parameterNew = (Get-Variable -Name ($parameter.name)).Value
        if ($PSBoundParameters.ContainsKey($parameter.Name) `
            -and ($parameterSource -ne $parameterNew))
        {
            $changeParameters += @{
                $($parameter.name) = $parameterNew
            }
            Write-Verbose -Message ( @(
                "$($MyInvocation.MyCommand): "
                $($LocalizedData.NamespaceServerConfigurationUpdateParameterMessage) `
                    -f $parameter.Name,$parameterNew
                ) -join '' )
            if ($parameter.Restart)
            {
                $restart = $True
            } # if
        } # if
    } # foreach
    if ($changeParameters.Count -gt 0)
    {
        # Update any parameters that were identified as different
        $null = Set-DfsnServerConfiguration `
            -ComputerName $computerName `
            @changeParameters `
            -ErrorAction Stop

        Write-Verbose -Message ( @(
            "$($MyInvocation.MyCommand): "
            $($LocalizedData.NamespaceServerConfigurationUpdatedMessage)
            ) -join '' )

        if ($restart)
        {
            # Restart the DFS Service
            $null = Restart-Service `
                -Name DFS `
                -Force `
                -ErrorAction Stop

            Write-Verbose -Message ( @(
                "$($MyInvocation.MyCommand): "
                $($LocalizedData.NamespaceServerConfigurationServiceRestartedMessage)
                ) -join '' )
        }
    } # if
} # Set-TargetResource

function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateSet('Yes')]
        [System.String]
        $IsSingleInstance,

        [Parameter()]
        [System.UInt32]
        $LdapTimeoutSec,

        [Parameter()]
        [System.UInt32]
        $SyncIntervalSec,

        [Parameter()]
        [System.Boolean]
        $UseFQDN
    )

    Write-Verbose -Message ( @(
            "$($MyInvocation.MyCommand): "
            $($LocalizedData.TestingNamespaceServerConfigurationMessage)
        ) -join '' )

    # The ComputerName will always be LocalHost unless a good reason can be provided to
    # enable it as a parameter.
    $computerName = 'LocalHost'

    # Flag to signal whether settings are correct
    [System.Boolean] $desiredConfigurationMatch = $true

    # Get the current DFSN Server Configuration
    $serverConfiguration = Get-DfsnServerConfiguration `
        -ComputerName $computerName `
        -ErrorAction Stop

    # Check each parameter
    foreach ($parameter in $parameterList)
    {
        $parameterSource = $serverConfiguration.$($parameter.name)
        $parameterNew = (Get-Variable -Name ($parameter.name)).Value
        if ($PSBoundParameters.ContainsKey($parameter.Name) `
            -and ($parameterSource -ne $parameterNew)) {
            Write-Verbose -Message ( @(
                "$($MyInvocation.MyCommand): "
                $($LocalizedData.NamespaceServerConfigurationParameterNeedsUpdateMessage) `
                    -f $parameter.Name,$parameterSource,$parameterNew
                ) -join '' )
            $desiredConfigurationMatch = $false
        } # if
    } # foreach

    return $desiredConfigurationMatch
} # Test-TargetResource

Export-ModuleMember -Function *-TargetResource
