# Active Directory Hardening From Initial Recon
<p align="justify">
Active Directory (AD) is a critical component of enterprise networks, but its default configurations often expose it to security risks. One such risk is unauthenticated enumeration, where attackers can gather sensitive information such as user lists, computer details, group memberships, and even password policies without needing valid credentials.
</p>
<p align="justify">
While this data alone may not grant direct access, it becomes dangerous when combined with techniques like password spraying. Attackers can use valid usernames and the domain’s password policy to craft targeted login attempts, avoiding account lockouts by spacing out attempts. Even more concerning, some organizations store plaintext passwords in AD description fields, providing attackers with an easy path to compromise accounts.
</p>

## Remediating LDAP Anonymous Bind

You can do this manually by opening ADSI Edit, right-clicking on it, selecting Connect To, and then choosing Configuration as the naming context.

![fd15f324-25f7-44c8-b04c-06204b308100](https://github.com/user-attachments/assets/8bfcc60d-c534-479a-9e25-21cabf3c699b)

Next, navigate to CN=Directory Service, under CN=Windows NT, CN=Services, and CN=Configuration in your domain. Then right-click on CN=Directory Service and choose Properties.

![attrb_editor](https://github.com/user-attachments/assets/33721b4f-08d2-4b50-8055-8fcf3fb22afe)

We should also ensure that ANONYMOUS LOGON does not have read access over the Users CN or other objects, including the domain object itself.

![anon_logon_read](https://github.com/user-attachments/assets/d9a6e0ef-da9f-4cd9-8ca9-7b95c8647ada)

This can also be remediated with a single PowerShell script as follows. Please check the ``` LDAP_Anonymous_Bind.ps1 ``` that have been uploaded.

- It first figures out the domain's distinguished name (DN), then builds an LDAP path to the CN=Directory Service within the Configuration partition. It connects using ADSI with read/write access. Next, it clears the dSHeuristics attribute.
- Finally, it removes the GenericRead permission for ANONYMOUS LOGON on the CN=Users container. This helps block unauthenticated users from making anonymous LDAP queries to read user object data.

## Remediating LLMNR/NBT-NS Response Spoofing

![responder-llmnr-netbios-name-server-spoofing](https://github.com/user-attachments/assets/0e5d7b2a-e1b8-4e15-bd75-a7843d237ca8)


LLMNR can be turned off using Group Policy, and the best practice is to create a separate GPO for this purpose instead of modifying the Default Domain Policy. Naming it something like "Disable LLMNR" makes it easier to audit, target specific OUs, roll back if needed, and keeps your baseline domain policy clean.

To do this, start by creating a new GPO:

- In Group Policy Management, right-click on Group Policy Objects and choose New.
- Name the policy Disable LLMNR (or something similar).
- Once created, go to Computer Configuration → Administrative Templates → Network → DNS Client, and set Turn Off Multicast Name Resolution to Enabled.

![create_llmnr_GPO (1)](https://github.com/user-attachments/assets/6c58d998-b670-4edf-8fa8-3657c91373f0)

Next, right-click on the newly created GPO and select Edit. In the Group Policy Management Editor, navigate to:

Computer Configuration → Administrative Templates → Network → DNS Client

![disable_multicast_gpo](https://github.com/user-attachments/assets/6d389d93-c8f4-4b3b-b2b7-d312cd63bc26)

Next, link the GPO to the appropriate OUs. In our lab, both Workstations and Servers are under the OU. Right-click the  OU in Group Policy Management and select “Create a GPO in this domain, and Link it here.” In production, you'd typically link it to more specific OUs like Workstations or Servers. To do that, right-click the desired OU (e.g., Workstations) and choose “Link an existing GPO,” then select Disable LLMNR. Group Policy updates automatically every 90 minutes with a 30-minute offset, or you can force an update using gpupdate /force or the Group Policy Update option in the console.


## SMB Null Session

Fortunately, fixing this issue is straightforward. Start by removing the Everyone group from the Pre-Windows 2000 Compatible Access group—this alone often resolves the problem. As a secondary step, check the Default Domain Controllers Policy in Group Policy to ensure that "Network access: Let Everyone permissions apply to anonymous users" is set to Disabled. To do this, edit the policy and go to:
- Computer Configuration → Windows Settings → Security Settings → Local Policies → Security Options.
- Then change the setting to Disabled.
- Finally run gpupdate to apply the changes.

or run the ``` Remediate-SMBNullSessions.ps1 ``` to automate the process.

## NBT-NS

Unfortunately, unlike LLMNR, there's no dedicated Group Policy setting to disable NBT-NS globally—it has to be done at the host level. While there are ways to streamline this using scripts or deployment tools, it's helpful to first understand the manual process. NBT-NS can be disabled through the Network Connections settings on each machine. To do this, go to Network & Internet Settings, then click Change adapter options. Right-click the active network adapter, choose Properties, and proceed to modify the settings there.

![edit_adapter](https://github.com/user-attachments/assets/c0fd540e-7fc0-4cf0-8d52-603fc3c407c9)

Next, select Internet Protocol Version 4 (TCP/IPv4) and click Properties.

![ethernet_properties](https://github.com/user-attachments/assets/f32efeab-f3a7-4e3f-9364-840e70bc6f7c)

Next, click Advanced and select the WINS tab.

![advanced_tcp_ip](https://github.com/user-attachments/assets/fc3b6d8f-b771-4782-831b-b2ded27ff9c5)

We can select Disable NetBIOS over TCP/IP from here to turn this setting off.

![registry_nbt](https://github.com/user-attachments/assets/85746204-c0c6-44a3-93ae-a1124e880c0c)

Since NBT-NS is controlled via the Registry on each host, manually editing this setting on potentially hundreds of machines isn't practical. Instead, we can automate the process using a PowerShell script deployed through Group Policy as a Startup script. The relevant Registry key is located at:

``` HKLM:\SYSTEM\CurrentControlSet\services\NetBT\Parameters\Interfaces ```

By default, this value is set to 0 (or Default)—as seen in the WINS tab of the network adapter properties. Using a script allows us to update this setting across multiple systems efficiently without needing to touch each one manually.


## Remediating Default MachineAccountQuota

```powershell
Get-ADObject -Identity ((Get-ADDomain).distinguishedname) -Properties ms-DS-MachineAccountQuota
```

After confirming the default value of 10, we can easily change it to 0.

```powershell
Set-ADdomain -Identity manojprakash.local -Replace @{"ms-DS-MachineAccountQuota"="0"} -Verbose
```

Now that we've made the change, we'll recheck it to confirm that non-privileged users can no longer create machine accounts.

```powershell
PS C:\manoj> Get-ADObject -Identity ((Get-ADDomain).distinguishedname) -Properties ms-DS-MachineAccountQuota


DistinguishedName         : DC=manojprakash,DC=local
ms-DS-MachineAccountQuota : 0
Name                      : manojprakash
ObjectClass               : domainDNS
ObjectGUID                : 9a43cedd-d603-799b-a2b0-320b2ee20599
```

## Remediating Open/Writable SMB Shares

First, PowerShell can be utilized to list all SMB shares and their associated permissions.

```powershell
PS C:\manoj> 
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
```

Upon identifying shares with excessive permissions, the ```Grant-SmbShareAccess``` cmdlet can be utilized to modify these permissions.

For example, the Revoke-SmbShareAccess cmdlet should be used to remove permissions for unauthorized users or groups.

```powershell
PS C:\manoj> Revoke-SmbShareAccess -Name "ShareName" -AccountName "Domain\UnauthorizedUser"
```

As for modifying existing permissions, the Set-SmbShareAccess cmdlet should be used.

```powershell
PS C:\manoj>  Grant-SmbShareAccess -Name "ShareName" -AccountName "Domain\User" -AccessRight Read
```

## Conclusion
<p align="justify">
Hardening Active Directory is critical for reducing your attack surface and preventing common initial access techniques. By addressing issues like anonymous LDAP binds, LLMNR/NBT-NS spoofing, SMB null sessions, excessive share permissions, and the default MachineAccountQuota, you significantly improve your domain’s resilience. Always test changes in a lab before production, use automation where possible, and regularly audit your environment to catch regressions. Security is an ongoing process, layered defenses and proactive monitoring are key.
</p>
