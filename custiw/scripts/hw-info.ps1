#

[CmdletBinding()]
param (
    [Parameter(Mandatory=$False,ValueFromPipeline=$True,Position=0)][string]$property
);

function Get-HW-Type {
    $output = Get-WmiObject Win32_ComputerSystem -Property Manufacturer |
    	      Select-Object -Property Manufacturer
    if ( $output -imatch "(qemu.*|vmware.*|virtual.*|xen.*|KVM.*)" ) {
        Write-Host "virtual"
    } else {
        Write-Host "physical"
    }
}

function Get-HW-SKU {
    $output = Get-WmiObject -Namespace root\wmi -Class MS_SystemInformation -Property SystemSKU |
    	      Select-Object -ExpandProperty SystemSKU
    if ( $output ) {
        Write-Host $output
    } else {
        Write-Host 'Not Specified'
    }
}

function Get-HW-CPU-Arch {
    Get-WmiObject Win32_OperatingSystem -Property OSArchitecture |
    Select-Object -ExpandProperty OSArchitecture
}

function Get-HW-CPU-Count {
    Get-WmiObject Win32_Processor -Property NumberOfCores |
    Select-Object -ExpandProperty NumberOfCores |
    Measure-Object -sum |
    Select-Object -ExpandProperty Sum
}

function Get-HW-CPU-Model {
    Get-WmiObject Win32_Processor -Property Name |
    Select-Object -first 1 |
    Select-Object -ExpandProperty Name
}

function Get-HW-CPU-Sockets {
    $output = Get-WmiObject Win32_Processor -Property DeviceID
    Write-Host $output.count
}

function Get-HW-CPU-Cores-Per-Socket {
    Get-WmiObject Win32_Processor -Property NumberOfCores |
    Select-Object -ExpandProperty NumberOfCores |
    Sort -Unique |
    Select -First 1
}

function Get-HW-CPU-Threads-Per-Core {
    Get-WmiObject Win32_Processor -Property NumberOfLogicalProcessors |
    Select-Object -ExpandProperty NumberOfLogicalProcessors |
    Sort -Unique |
    Select -First 1
}

function Get-HW-CPU-Vendor {
    Get-WmiObject Win32_Processor -Property Manufacturer |
    Select-Object -ExpandProperty Manufacturer |
    Sort -Unique |
    Select -First 1
}

function Get-HW-Memory {
    Get-WmiObject Win32_ComputerSystem -Property TotalPhysicalMemory |
    Select-Object -ExpandProperty TotalPhysicalMemory
}

function Get-HW-Swap {
    $output = Get-WmiObject Win32_OperatingSystem -Property TotalVirtualMemorySize |
    	      Select-Object -ExpandProperty TotalVirtualMemorySize
    Write-Host ( $output*1024 )
}

function Get-HW-Vendor {
    Get-WmiObject Win32_ComputerSystem -Property Manufacturer |
    Select-Object -ExpandProperty Manufacturer
}

function Get-HW-Serial {
    if ( Get-HW-Vendor -imatch '(Supermicro)' ) {
        $output = Get-WmiObject Win32_BaseBoard -Property SerialNumber |
                  Select-Object -ExpandProperty SerialNumber

    } else {
        $output = Get-WmiObject Win32_BIOS -Property SerialNumber |
    	          Select-Object -ExpandProperty SerialNumber
    }
    if ( $output ) {
       Write-Host $output
    } else {
       Write-Host 'Not Specified'
    }
}

function Get-HW-Model { 
    if ( Get-HW-Vendor -imatch '(Supermicro)' ) {
        Get-WmiObject Win32_BaseBoard -Property Product |
        Select-Object -ExpandProperty Product
    } else {
        Get-WmiObject Win32_ComputerSystem -Property Model |
        Select-Object -ExpandProperty Model
    }
}

function Get-HW-Chassis {
    $output = Get-WmiObject Win32_ComputerSystem -Property  Manufacturer,Model,SystemType |
    	      Select-Object -Property Manufacturer,Model,SystemType
    Write-Host $output.Manufacturer $output.Model $output.SystemType
}

function Get-HW-Full {
    $mssysin_attrs = @('SystemSKU')
    $mssysin_rdata = Get-WmiObject -Namespace root\wmi -Class MS_SystemInformation -Property ($mssysin_attrs) |
    		     Select-Object -Property ($mssysin_attrs)

    $osystem_attrs = @('OSArchitecture', 'TotalVirtualMemorySize')
    $osystem_rdata = Get-WmiObject Win32_OperatingSystem -Property ($osystem_attrs) |
    		     Select-Object -Property ($osystem_attrs)

    $wiprocs_attrs = @('Manufacturer', 'NumberOfCores', 'NumberOfLogicalProcessors', 'Name')
    $wiprocs_rdata = Get-WmiObject Win32_Processor -Property ($wiprocs_attrs) |
    		     Select-Object -Property ($wiprocs_attrs)

    $winbios_attrs = @('SerialNumber')
    $winbios_rdata = Get-WmiObject Win32_BIOS -Property ($winbios_attrs) |
    		     Select-Object -Property ($winbios_attrs)
    $csystem_attrs = @('Manufacturer', 'Model', 'SystemType', 'TotalPhysicalMemory')
    $csystem_rdata = Get-WmiObject Win32_ComputerSystem -Property ($csystem_attrs) |
           	     Select-Object -Property ($csystem_attrs)
    if ( $csystem_rdata.Manufacturer -imatch '(Supermicro)' ) {
        $data = Get-WmiObject Win32_BaseBoard -Property Product,SerialNumber
        $csystem_rdata.Model = $data.Product
        $winbios_rdata.SerialNumber = $data.SerialNumber
    }

    $devices_attrs = @('Name', 'Size', 'SerialNumber', 'Model', 'InterfaceType')
    $devices_rdata = Get-WmiObject Win32_DiskDrive -Property ($devices_attrs) |
    		     Select-Object -Property ($devices_attrs)

    $json_raw = [ordered]@{
        blockdevices = @()
        chassis = "{0} {1} {2} {3}" -f $csystem_rdata.Manufacturer, $csystem_rdata.Model, $winbios_rdata.SerialNumber, $csystem_rdata.SystemType
        cpu_arch = $osystem_rdata.OSArchitecture
        cpu_cores_per_socket = $wiprocs_rdata.NumberOfCores |
			       Sort -Unique |
			       Select -First 1
        cpu_count = $wiprocs_rdata.NumberOfCores |
		    Measure-Object -sum |
		    Select-Object -ExpandProperty Sum
        cpu_model = $wiprocs_rdata.Name |
		    Select-Object -first 1
        cpu_sockets = $wiprocs_rdata.Name.count
        cpu_threads_per_core = $wiprocs_rdata.NumberOfLogicalProcessors |
			       Sort -Unique |
			       Select -First 1
        cpu_vendor = $wiprocs_rdata.Manufacturer |
		     Sort -Unique |
		     Select -First 1
        memory = $csystem_rdata.TotalPhysicalMemory
        memory_swap = ($osystem_rdata.TotalVirtualMemorySize*1024)
        model = $csystem_rdata.Model
        serial = ''
        sku = $mssysin_attrs.SystemSKU
        type = ''
        vendor = $csystem_rdata.Manufacturer
    }
    if ( $csystem_rdata.Manufacturer -imatch "(qemu.*|vmware.*|virtual.*|xen.*|KVM.*)" ) {
       $json_raw.type = "virtual"
    } else {
       $json_raw.type = "physical"
    }
    if ( $mssysin_attrs.SystemSKU ){
       $json_raw.sku = $mssysin_attrs.SystemSKU
    } else {
       $json_raw.sku = 'Not Specified'
    }
    if ( $winbios_rdata.SerialNumber ) {
       $json_raw.serial = $winbios_rdata.SerialNumber
    } else {
       $json_raw.serial = 'Not Specified'
    }
    foreach ( $device in $devices_rdata ) {
       $data = [ordered]@{
           model = $device.Model
           name = $device.Name
           serial = $device.SerialNumber
           size = $device.Size.ToString()
           vendor = $device.InterfaceType
       }
       $json_raw.blockdevices += $data
    }
    $json_raw | ConvertTo-Json
}

if ( $property -eq "chassis" ) {
    Get-HW-Chassis
} elseif ( $property -eq "vendor" ) {
    Get-HW-Vendor
} elseif ( $property -eq "model" ) {
    Get-HW-Model
} elseif ( $property -eq "serial" ) {
    Get-HW-Serial
} elseif ( $property -eq "cpu_arch" ) {
    Get-HW-CPU-Arch
} elseif ( $property -eq "cpu_count" ) {
    Get-HW-CPU-Count
} elseif ( $property -eq "cpu_model" ) {
    Get-HW-CPU-Model
} elseif ( $property -eq "cpu_sockets" ) {
    Get-HW-CPU-Sockets
} elseif ( $property -eq "cpu_vendor" ) {
    Get-HW-CPU-Vendor
} elseif ( $property -eq "cpu_cores_per_socket" ) {
    Get-HW-CPU-Cores-Per-Socket
} elseif ( $property -eq "cpu_threads_per_core" ) {
    Get-HW-CPU-Threads-Per-Core
} elseif ( $property -eq "type" ) {
    Get-HW-Type
} elseif ( $property -eq "sku" ) {
    Get-HW-SKU
} elseif ( $property -eq "memory" ) {
    Get-HW-Memory
} elseif ( $property -eq "memory_swap" ) {
    Get-HW-Swap
} else {
    Get-HW-Full
}

#end of script~