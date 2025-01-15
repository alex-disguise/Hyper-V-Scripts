### Full PowerShell Script for Automating Hyper-V Switch and VM Network Adapter VLAN Creation

# Ensure Hyper-V Module is Imported
if (-not (Get-Module -Name Hyper-V)) {
    try {
        Import-Module Hyper-V -ErrorAction Stop
        Write-Host "Hyper-V module imported successfully." -ForegroundColor Green
    } catch {
        Write-Host "Failed to import Hyper-V module. Please ensure Hyper-V is installed." -ForegroundColor Red
        exit
    }
}

# User Input Section
# Prompt for Virtual Switch Name and Network Adapter Name
$virtualSwitchName = Read-Host "Enter the Virtual Switch Name (Default: ExternalSwitch)"
if (-not $virtualSwitchName) { $virtualSwitchName = "ExternalSwitch" }

$networkAdapterName = Read-Host "Enter the Physical Network Adapter Name (Default: Ethernet)"
if (-not $networkAdapterName) { $networkAdapterName = "Ethernet" }

$switchType = "External"

# Predefined VM Network Adapters and VLANs
$adapters = @(
    @{ AdapterName = "VLAN 3 - Control System"; VLAN = 3 },
    @{ AdapterName = "VLAN 4 - DMX"; VLAN = 4 },
    @{ AdapterName = "VLAN 6 - Tracking"; VLAN = 6 },
    @{ AdapterName = "VLAN 7 - Omnical"; VLAN = 7 },
    @{ AdapterName = "VLAN 10 - Internet"; VLAN = 10 },
    @{ AdapterName = "VLAN 11 - Audio"; VLAN = 11 }
)

# Function to Create Virtual Switch if it doesn't exist
function Create-VirtualSwitch {
    param (
        [string]$SwitchName,
        [string]$AdapterName,
        [string]$SwitchType
    )
    
    if (-not (Get-VMSwitch -Name $SwitchName -ErrorAction SilentlyContinue)) {
        Write-Host "Creating Virtual Switch: $SwitchName with Type: $SwitchType on Adapter: $AdapterName" -ForegroundColor Green
        
        switch ($SwitchType.ToLower()) {
            "external" {
                if (Get-NetAdapter -Name $AdapterName -ErrorAction SilentlyContinue) {
                    New-VMSwitch -Name $SwitchName -NetAdapterName $AdapterName -AllowManagementOS $true
                } else {
                    Write-Host "Error: Network Adapter '$AdapterName' not found. Cannot create External switch." -ForegroundColor Red
                    exit
                }
            }
            "internal" {
                New-VMSwitch -Name $SwitchName -SwitchType Internal
            }
            "private" {
                New-VMSwitch -Name $SwitchName -SwitchType Private
            }
            default {
                Write-Host "Invalid switch type specified." -ForegroundColor Red
                exit
            }
        }
    } else {
        Write-Host "Virtual Switch '$SwitchName' already exists." -ForegroundColor Yellow
    }
}

# Function to Create and Configure VM Network Adapters with VLAN
function Configure-VMNetworkAdapterVLAN {
    param (
        [string]$AdapterName,
        [int]$VLANID,
        [string]$SwitchName
    )

    # Create VM Network Adapter
    Write-Host "Creating VM Network Adapter: $AdapterName..." -ForegroundColor Cyan
    Add-VMNetworkAdapter -ManagementOS -Name $AdapterName -SwitchName $SwitchName -ErrorAction SilentlyContinue

    # Assign VLAN ID
    Write-Host "Assigning VLAN ID $VLANID to Adapter $AdapterName..." -ForegroundColor Cyan
    Set-VMNetworkAdapterVlan -ManagementOS -VMNetworkAdapterName $AdapterName -Access -VlanId $VLANID
}

# Execution Section
# Step 1: Create Virtual Switch
Create-VirtualSwitch -SwitchName $virtualSwitchName -AdapterName $networkAdapterName -SwitchType $switchType

# Step 2: Create and Configure VM Network Adapters with VLAN
foreach ($adapter in $adapters) {
    Configure-VMNetworkAdapterVLAN -AdapterName $adapter.AdapterName -VLANID $adapter.VLAN -SwitchName $virtualSwitchName
}

Write-Host "Hyper-V Switch and VM Network Adapter VLAN configuration completed successfully!" -ForegroundColor Green
