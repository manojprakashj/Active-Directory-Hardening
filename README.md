# Active-Directory-Hardening
If Active Directory isn’t secured, attackers can gather user and computer lists, descriptions, and password policies without logging in. This info helps them launch password spraying attacks using valid usernames and compliant passwords while avoiding account lockouts by spacing out attempts.

## Remediating LDAP Anonymous Bind

You can do this manually by opening ADSI Edit, right-clicking on it, selecting Connect To, and then choosing Configuration as the naming context.

![fd15f324-25f7-44c8-b04c-06204b308100](https://github.com/user-attachments/assets/8bfcc60d-c534-479a-9e25-21cabf3c699b)

Next, navigate to CN=Directory Service, under CN=Windows NT, CN=Services, and CN=Configuration in your domain. Then right-click on CN=Directory Service and choose Properties.

![attrb_editor](https://github.com/user-attachments/assets/33721b4f-08d2-4b50-8055-8fcf3fb22afe)

We should also ensure that ANONYMOUS LOGON does not have read access over the Users CN or other objects, including the domain object itself.

![anon_logon_read](https://github.com/user-attachments/assets/d9a6e0ef-da9f-4cd9-8ca9-7b95c8647ada)

This can also be remediated with a single PowerShell script as follows. Please check the LDAP_Anonymous_Bind.ps1 that have been uploaded.

- It first figures out the domain's distinguished name (DN), then builds an LDAP path to the CN=Directory Service within the Configuration partition. It connects using ADSI with read/write access. Next, it clears the dSHeuristics attribute.
- Finally, it removes the GenericRead permission for ANONYMOUS LOGON on the CN=Users container. This helps block unauthenticated users from making anonymous LDAP queries to read user object data.

## Remediating LLMNR/NBT-NS Response Spoofing

LLMNR can be turned off using Group Policy, and the best practice is to create a separate GPO for this purpose instead of modifying the Default Domain Policy. Naming it something like "Disable LLMNR" makes it easier to audit, target specific OUs, roll back if needed, and keeps your baseline domain policy clean.

To do this, start by creating a new GPO:

- In Group Policy Management, right-click on Group Policy Objects and choose New.
- Name the policy Disable LLMNR (or something similar).
- Once created, go to Computer Configuration → Administrative Templates → Network → DNS Client, and set Turn Off Multicast Name Resolution to Enabled.

![create_llmnr_GPO (1)](https://github.com/user-attachments/assets/6c58d998-b670-4edf-8fa8-3657c91373f0)

Next, right-click on the newly created GPO and select Edit. In the Group Policy Management Editor, navigate to:

Computer Configuration → Administrative Templates → Network → DNS Client

![disable_multicast_gpo](https://github.com/user-attachments/assets/6d389d93-c8f4-4b3b-b2b7-d312cd63bc26)

Next, link the GPO to the appropriate OUs. In our lab, both Workstations and Servers are under the CORP OU. Right-click the CORP OU in Group Policy Management and select “Create a GPO in this domain, and Link it here.” In production, you'd typically link it to more specific OUs like Workstations or Servers. To do that, right-click the desired OU (e.g., Workstations) and choose “Link an existing GPO,” then select Disable LLMNR. Group Policy updates automatically every 90 minutes with a 30-minute offset, or you can force an update using gpupdate /force or the Group Policy Update option in the console.


## SMB Null Session

Fortunately, fixing this issue is straightforward. Start by removing the Everyone group from the Pre-Windows 2000 Compatible Access group—this alone often resolves the problem. As a secondary step, check the Default Domain Controllers Policy in Group Policy to ensure that "Network access: Let Everyone permissions apply to anonymous users" is set to Disabled. To do this, edit the policy and go to:
- Computer Configuration → Windows Settings → Security Settings → Local Policies → Security Options.
- Then change the setting to Disabled.
- Finally run gpupdate to apply the changes.

or run the Remediate-SMBNullSessions.ps1 to automate the process.
