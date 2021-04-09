function Get-ESXiHardwareHealthSensorInfo {
<#
.SYNOPSIS
	Get detailed ESXi Hadrdware health Information.
#>
    [CmdletBinding()]param(
        # Name pattern of the host for which to get VLAN Healthcheck info (accepts regex patterns)
        [parameter(Mandatory = $true, ParameterSetName = "SearchByHostName")][string]$vmhostName_str,
        # Name pattern of the cluster for whose hosts to get VLAN Healthcheck info (accepts regex patterns)
        [parameter(Mandatory = $true, ParameterSetName = "SearchByCluster", ValueFromPipelineByPropertyName)][Alias("Name")][string]$ClusterName_str
    ) # end param
    
    
    # params for the Get-View expression for getting the View objects
    $hshGetViewParams = @{
        ViewType = "HostSystem"
        Property = "Name", "Runtime.connectionstate","Runtime.HealthSystemRuntime.SystemHealthInfo.NumericSensorInfo","Hardware.SystemInfo.SerialNumber"
    } ## end hashtable
         
    Switch ($PSCmdlet.ParameterSetName) {
        # if host name pattern was provided, filter on it in the Get-View expression
        "SearchByHostName" { $hshGetViewParams["Filter"] = @{"Name" = $vmhostName_str }; break; } # end case
        # if cluster name pattern was provided, set it as the search root for the Get-View expression
        "SearchByCluster" { $hshGetViewParams["SearchRoot"] = (Get-Cluster $ClusterName_str).Id; break; }
    } ## end switch

    Get-View @hshGetViewParams | where { $_.runtime.connectionstate -ne "Disconnected" } | Foreach-Object {
        $viewHost = $_
        $x = 0
        $viewHost.Runtime.HealthSystemRuntime.SystemHealthInfo.NumericSensorInfo | ForEach-Object {
            New-Object PSObject -Property ([ordered]@{
                vmhost            = $viewHost.Name
		SerialNumber      = $viewHost.Hardware.SystemInfo.SerialNumber
                Status            = $viewHost.Runtime.HealthSystemRuntime.SystemHealthInfo.NumericSensorInfo.HealthState.key[$x]
                Name              = $viewhost.Runtime.HealthSystemRuntime.SystemHealthInfo.NumericSensorInfo.Name[$x]
                CurrentReading    = $viewhost.Runtime.HealthSystemRuntime.SystemHealthInfo.NumericSensorInfo.CurrentReading[$x]
                UnitModifier      = $viewhost.Runtime.HealthSystemRuntime.SystemHealthInfo.NumericSensorInfo.UnitModifier[$x]
                BaseUnits         = $viewhost.Runtime.HealthSystemRuntime.SystemHealthInfo.NumericSensorInfo.BaseUnits[$x]
                RateUnits         = $viewhost.Runtime.HealthSystemRuntime.SystemHealthInfo.NumericSensorInfo.RateUnits[$x]
                SensorType        = $viewhost.Runtime.HealthSystemRuntime.SystemHealthInfo.NumericSensorInfo.SensorType[$x] 
                Id                = $viewhost.Runtime.HealthSystemRuntime.SystemHealthInfo.NumericSensorInfo.Id[$x]
                TimeStamp         = $viewhost.Runtime.HealthSystemRuntime.SystemHealthInfo.NumericSensorInfo.TimeStamp[$x]
            }) ## end new-object
            $x++
        } ## end inner foreach-object
    } ## end outer foreach-object
} ## end function
