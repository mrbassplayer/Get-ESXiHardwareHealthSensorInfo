# Get-ESXiHardwareHealthSensorInfo
PowerCLI cmdlet which pulls the Hardware Sensor Information.

This cmdlet is a rewrite of the code posted here by Wintel Rocks.

https://techibee.com/powershell/powershell-get-vm-host-hardware-sensors-information-using-powercli/2970

I rewrote the process for which the code gathers the host(s) information which I learned from this post by Matt Boren.

https://www.vnugglets.com/2014/07/get-vmhost-fc-hba-wwn-info-most-quickly.html

This code runs in about a fifth of the time. Mainly because of Matt's technique of not using "Get-VMhost" and going straight to "Get-View"
