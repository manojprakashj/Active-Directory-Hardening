# Active-Directory-Hardening
If Active Directory isn’t secured, attackers can gather user and computer lists, descriptions, and password policies without logging in. This info helps them launch password spraying attacks using valid usernames and compliant passwords while avoiding account lockouts by spacing out attempts.

## Remediating LDAP Anonymous Bind

You can do this manually by opening ADSI Edit, right-clicking on it, selecting Connect To, and then choosing Configuration as the naming context.

![fd15f324-25f7-44c8-b04c-06204b308100](https://github.com/user-attachments/assets/8bfcc60d-c534-479a-9e25-21cabf3c699b)

Next, navigate to CN=Directory Service, under CN=Windows NT, CN=Services, and CN=Configuration in your domain. Then right-click on CN=Directory Service and choose Properties.

![attrb_editor](https://github.com/user-attachments/assets/33721b4f-08d2-4b50-8055-8fcf3fb22afe)

We should also ensure that ANONYMOUS LOGON does not have read access over the Users CN or other objects, including the domain object itself.

![anon_logon_read](https://github.com/user-attachments/assets/d9a6e0ef-da9f-4cd9-8ca9-7b95c8647ada)



