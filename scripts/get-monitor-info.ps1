Function Get-MonitorInformation
{
    Param
    (
        [Parameter(ParameterSetName = "SimpleFilter")]
        [switch]
        $Active,

        [Parameter(ParameterSetName = "CustomFilter")]
        [string]
        $Filter
    )
    process
    {
        $GetCimInstanceParams = @{
            CimSession = New-CimSession
            ClassName  = "WmiMonitorID"
            Namespace  = "root\wmi"
        }
        if ($PSBoundParameters.ContainsKey("Active"))
        {
            $GetCimInstanceParams.Add("Filter", "Active = $Active")
        }
        elseif (![string]::IsNullOrWhiteSpace($Filter))
        {
            $GetCimInstanceParams.Add("Filter", $Filter)
        }
        Get-CimInstance @GetCimInstanceParams | Select-Object -Property @(
            "Active"
            @{Name = 'Manufacturer';Expression = { [string]::new([char[]]($_.Manufacturername)).Trim("`0") }}
            @{Name = 'Model';       Expression = { [string]::new([char[]]($_.UserFriendlyName)).Trim("`0") }}
            @{Name = 'Serial';      Expression = { [string]::new([char[]]($_.SerialNumberID)).Trim("`0") }}
            "YearOfManufacture"
            "WeekOfManufacture"
            "PSComputerName"
        )
    }
}

Get-MonitorInformation -Active