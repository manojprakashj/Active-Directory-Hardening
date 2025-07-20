# Function to remove Everyone from Pre-Windows 2000 Compatible Access group
function Remove-EveryoneFromPreWin2KGroup {
    try {
        $group = [ADSI]"WinNT://$env:COMPUTERNAME/Pre-Windows 2000 Compatible Access"
        $group.PSBase.Invoke("Remove", "WinNT://Everyone")
        Write-Host "Successfully removed Everyone from Pre-Windows 2000 Compatible Access group." -ForegroundColor Green
    }
    catch {
        Write-Host "Error removing Everyone from Pre-Windows 2000 Compatible Access group: $_" -ForegroundColor Red
    }
}

# Function to disable anonymous access in Default Domain Controllers Policy
function Disable-AnonymousAccessPolicy {
    try {
        # Path to the policy setting
        $policyPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Network Provider\HardenedPaths"
        
        # Create the key if it doesn't exist
        if (-not (Test-Path $policyPath)) {
            New-Item -Path $policyPath -Force | Out-Null
        }
        
        # Set the value to disable anonymous access
        Set-ItemProperty -Path $policyPath -Name "Everyone" -Value "RequireMutualAuthentication=1,RequireIntegrity=1" -Type String -Force
        
        Write-Host "Successfully disabled 'Network access: Let Everyone permissions apply to anonymous users' in policy." -ForegroundColor Green
        
        # Force group policy update
        gpupdate /force | Out-Null
        Write-Host "Group Policy update forced." -ForegroundColor Green
    }
    catch {
        Write-Host "Error modifying policy: $_" -ForegroundColor Red
    }
}

# Main execution
Write-Host "Starting SMB Null Session remediation..." -ForegroundColor Cyan

# Remove Everyone from Pre-Windows 2000 group
Remove-EveryoneFromPreWin2KGroup

# Disable anonymous access policy
Disable-AnonymousAccessPolicy

Write-Host "Remediation completed. Please verify settings." -ForegroundColor Cyan
