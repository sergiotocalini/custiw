#

[CmdletBinding()]
param (
    [Parameter(Mandatory=$True,ValueFromPipeline=$True,Position=0)][string]$property
);


function Get-OS-Version {
    Get-WmiObject Win32_OperatingSystem | Select-Object -ExpandProperty Caption
}

function Get-OS-ProductID {
    Get-WmiObject Win32_OperatingSystem | Select-Object -ExpandProperty SerialNumber
}

if ($property -eq "version")  {
    Get-OS-Version
} elseif ($property -eq "productid") {
    Get-OS-ProductID
}
