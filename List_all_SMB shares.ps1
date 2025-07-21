$smbShares = Get-SmbShare #Get all SMB shares

# Iterate over each share and get its permissions
foreach ($share in $smbShares) {
    Write-Host "Share Name: $($share.Name)"
    Write-Host "Path: $($share.Path)"
    
    # Get the access permissions for the share
    $permissions = Get-SmbShareAccess -Name $share.Name
    
    # Display the permissions
    foreach ($permission in $permissions) {
        Write-Host "  Account: $($permission.AccountName)"
        Write-Host "  Access: $($permission.AccessControlType)"
        Write-Host "  Rights: $($permission.AccessRight)"
        Write-Host ""
    }
    
    Write-Host "----------------------------------------"
}