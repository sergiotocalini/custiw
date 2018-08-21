#

[CmdletBinding()]
param (
    [Parameter(Mandatory=$False,ValueFromPipeline=$True,Position=0)][string]$property
);

function Get-OS-Version {
    Get-WmiObject Win32_OperatingSystem | Select-Object -ExpandProperty Caption
}

function Get-OS-ProductID {
    Get-WmiObject Win32_OperatingSystem | Select-Object -ExpandProperty SerialNumber
}

function Get-OS-Full {
    $win32os_attrs = @('Caption', 'SerialNumber', 'InstallDate', 'LastBootUpTime' )
    $win32os_rdata = Get-WmiObject Win32_OperatingSystem -Property ($win32os_attrs) |
    		     Select-Object -Property ($win32os_attrs)

    $json_raw = [ordered]@{
        family = 'Windows'
        release = $win32os_rdata.Caption
        boottime = $win32os_rdata.LastBootUpTime
        productid = $win32os_rdata.SerialNumber
        installed = $win32os_rdata.InstallDate
	env = "$Env:CO_ENV"
    }
    $json_raw | ConvertTo-Json
}

if ($property -eq "version")  {
    Get-OS-Version
} elseif ($property -eq "productid") {
    Get-OS-ProductID
} else {
    Get-OS-Full
}
