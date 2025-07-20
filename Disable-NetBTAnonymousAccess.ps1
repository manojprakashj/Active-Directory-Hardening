# Registry path where NetBT settings are stored
$regPath = "HKLM:\SYSTEM\CurrentControlSet\services\NetBT\Parameters\Interfaces"

try {
    # Get all network interfaces with NetBT configurations
    $interfaces = Get-ChildItem -Path $regPath -ErrorAction Stop

    if ($interfaces) {
        foreach ($interface in $interfaces.PSChildName) {
            $interfacePath = "$regPath\$interface"
            
            # Set NetbiosOptions to 2 (Disable NetBT)
            Set-ItemProperty -Path $interfacePath -Name "NetbiosOptions" -Value 2 -Type DWord -Force
            Write-Output "Successfully disabled NetBT on interface: $interface"
        }
    }
    else {
        Write-Warning "No NetBT interfaces found in registry."
    }
}
catch {
    Write-Error "Failed to modify registry: $_"
    exit 1
}

# Optional: Verify changes
Write-Output "Verifying changes..."
Get-ChildItem -Path $regPath | ForEach-Object {
    $currentValue = Get-ItemProperty -Path $_.PSPath -Name "NetbiosOptions" -ErrorAction SilentlyContinue
    Write-Output "Interface [$($_.PSChildName)] - NetbiosOptions = $($currentValue.NetbiosOptions)"
}
