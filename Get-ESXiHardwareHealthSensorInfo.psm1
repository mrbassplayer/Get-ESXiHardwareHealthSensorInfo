function Get-ESXiHardwareHealthSensorInfo {
    <#
    .SYNOPSIS
            Gets Hardware Health of Dell ESXi hosts.
    
    .DESCRIPTION
            This is a quick way to check on the hardware health across ESXi hosts.
            The output will also contain the hosts' Service Tag, PSNT if VXRail, and a link which can be copied and pasted into a browser, expediting the opening of a support ticket with Dell.
    
    .PARAMETER VMHostName_str
            Name pattern of the host for which to get VLAN Healthcheck info (accepts regex patterns)
    
    .PARAMETER ClusterName_str
            Name pattern of the cluster for whose hosts to get VLAN Healthcheck info (accepts regex patterns)
            
    .EXAMPLE 
    Get-ESXiHardwareHealth -vmhostName_str . 
            This will dump out all sensor information for all hosts connected to all vCenters for which the user is authenticated.

    .EXAMPLE 
    Get-ESXiHardwareHealth -vmhostName_str . | Where {$_.status -eq "Green"}| sort id,vmhost | ft * -AutoSize
            This will return any sensors showing a status of "Green" for all hosts.
    
    .EXAMPLE 
    Get-ESXiHardwareHealth -vmhostName_str . | Where {$_.status -eq "Yellow"}| sort id,vmhost | ft * -AutoSize
            This will return any sensors showing a status of "Yellow" for all hosts.
    
    .EXAMPLE 
    Get-ESXiHardwareHealth -vmhostName_str . | Where {$_.status -eq "Red"}| sort id,vmhost | ft * -AutoSize
            This will return any sensors showing a status of "Red" for all hosts.
    
    .EXAMPLE 
    Get-ESXiHardwareHealth -vmhostName_str . | Where {$_.status -eq "Unknown"}| sort id,vmhost | ft * -AutoSize
            This will return any sensors showing a status of "Unknown" for all hosts.

    .NOTES
            PowerCLI must be installed.
            Must be connected to at least one vCenter or ESXi host.
#>
    [CmdletBinding()]param(
        # Name pattern of the host for which to get Hardware Health info (accepts regex patterns)
        [parameter(Mandatory = $true, ParameterSetName = "SearchByHostName")][string]$VMHostName_str,
        # Name pattern of the cluster for whose hosts to get Hardware Health info (accepts regex patterns)
        [parameter(Mandatory = $true, ParameterSetName = "SearchByCluster", ValueFromPipelineByPropertyName)][Alias("Name")][string]$ClusterName_str
    ) # end param
    
    
    # params for the Get-View expression for getting only the View objects which are needed.
    $hshGetViewParams = @{
        ViewType = "HostSystem"
        Property = "Name","Runtime.connectionstate","Runtime.HealthSystemRuntime.SystemHealthInfo.NumericSensorInfo","Summary.Hardware.OtherIdentifyingInfo","Datastore","Hardware.SystemInfo.Vendor","Hardware.SystemInfo.Model"
    } ## end hashtable
         
    Switch ($PSCmdlet.ParameterSetName) {
        # if host name pattern was provided, filter on it in the Get-View expression
        "SearchByHostName" { $hshGetViewParams["Filter"] = @{"Name" = $vmhostName_str }; break; } # end case
        # if cluster name pattern was provided, set it as the search root for the Get-View expression
        "SearchByCluster" { $hshGetViewParams["SearchRoot"] = (Get-Cluster $ClusterName_str).Id; break; }
    } ## end switch

    Get-View @hshGetViewParams | where { $_.runtime.connectionstate -ne "Disconnected" } | Foreach-Object {
        $viewHost = $_
        if ($viewhost.Hardware.SystemInfo.Model -match "VxRail") {
	    $PSNT = (get-view -id $($viewhost.Datastore[1].Type + "-" + $viewhost.Datastore[1].Value) | select -ExpandProperty name ).substring(0,14)
        } else { $PSNT = $null}
	$x = 0
        $viewHost.Runtime.HealthSystemRuntime.SystemHealthInfo.NumericSensorInfo | ForEach-Object {
            New-Object PSObject -Property ([ordered]@{
                VMHost          = $viewHost.Name
                Vendor          = $viewHost.Hardware.SystemInfo.Vendor
                Model           = $viewHost.Hardware.SystemInfo.Model
                ServiceTag      = $viewHost.Summary.Hardware.OtherIdentifyingInfo[1].identifierValue
		VXRailID        = $PSNT
                Status          = $viewHost.Runtime.HealthSystemRuntime.SystemHealthInfo.NumericSensorInfo.HealthState.key[$x]
                SensorName      = $viewhost.Runtime.HealthSystemRuntime.SystemHealthInfo.NumericSensorInfo.Name[$x]
                CurrentReading  = $viewhost.Runtime.HealthSystemRuntime.SystemHealthInfo.NumericSensorInfo.CurrentReading[$x]
                UnitModifier    = $viewhost.Runtime.HealthSystemRuntime.SystemHealthInfo.NumericSensorInfo.UnitModifier[$x]
                BaseUnits       = $viewhost.Runtime.HealthSystemRuntime.SystemHealthInfo.NumericSensorInfo.BaseUnits[$x]
                RateUnits       = $viewhost.Runtime.HealthSystemRuntime.SystemHealthInfo.NumericSensorInfo.RateUnits[$x]
                SensorType      = $viewhost.Runtime.HealthSystemRuntime.SystemHealthInfo.NumericSensorInfo.SensorType[$x] 
                Id              = $viewhost.Runtime.HealthSystemRuntime.SystemHealthInfo.NumericSensorInfo.Id[$x]
                TimeStamp       = $viewhost.Runtime.HealthSystemRuntime.SystemHealthInfo.NumericSensorInfo.TimeStamp[$x]
                HostSupportPage = "https://www.dell.com/support/home/en-us/product-support/servicetag/"+$viewHost.Summary.Hardware.OtherIdentifyingInfo[1].identifierValue
                
            }) ## end new-object
            $x++
        } ## end foreach-object
    } ## end foreach-object
} ## end function
