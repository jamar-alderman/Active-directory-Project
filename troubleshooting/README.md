# Troubleshooting Notes

This section documents issues encountered while building the Active Directory lab and how they were resolved.

## PowerShell script blocked by execution policy

**Symptom**

Running the provisioning script returned an error stating that the `.ps1` file was not digitally signed and could not be loaded under the current execution policy.

**Resolution**

For the lab session, I used a process-scoped bypass:

```powershell
Set-ExecutionPolicy -Scope Process Bypass
```

Using `-Scope Process` limits the change to the current PowerShell process rather than permanently changing the machine-wide policy.

## `New-ADUser: Directory object not found`

**Symptom**

The JSON parsed successfully, but each `New-ADUser` operation failed with `Directory object not found`.

**Investigation**

The user records contained distinguished names such as:

```text
OU=IT,DC=corp,DC=lab
OU=HR,DC=corp,DC=lab
OU=Helpdesk,DC=corp,DC=lab
OU=Finance,DC=corp,DC=lab
```

The named departments existed as security groups, but not as Organizational Units.

**Root cause**

`New-ADUser -Path` expects a valid AD container/OU distinguished name. A security group cannot be used as the destination path for a user object.

**Resolution**

I created the IT, HR, Helpdesk, and Finance OUs in Active Directory Users and Computers and reran the provisioning script. The script then completed without errors.

**Verification**

```powershell
Get-ADUser -Filter * |
Select-Object Name,SamAccountName,DistinguishedName
```

The output confirmed that all five test users were created in the intended OUs.

## Client could ping the domain controller but could not join the domain

**Symptom**

The Windows client could successfully ping the domain controller, but joining `corp.lab` failed.

**Likely cause**

The client was using the wrong DNS server. Active Directory clients must be able to resolve the domain and AD service records through the domain controller's DNS service. Pointing the client to a home router or public DNS server can allow normal internet name resolution while still preventing domain discovery.

**Resolution**

I corrected the client's DNS configuration so it pointed to the domain controller instead of the home router/public DNS.

For this lab, the domain controller DNS address is:

```text
192.168.110.10
```

**Verification**

Useful checks include:

```powershell
ipconfig /all
nslookup corp.lab
nslookup _ldap._tcp.dc._msdcs.corp.lab
```

After the client could resolve the AD domain and service records through the DC, the domain join succeeded.

## User existed in Active Directory but could not log in

**Symptom**

The user account existed in Active Directory, but the client could not log in with the domain account.

**Possible causes checked**

- Account disabled
- Account expired
- Incorrect password
- `ChangePasswordAtLogon` requirement
- Client or user not actually attempting domain authentication

**Root cause**

The affected account was disabled in Active Directory.

**Resolution**

I opened Active Directory Users and Computers, located the user account, and enabled it.

**Verification**

After enabling the account, the user was able to authenticate successfully with the domain account.

A PowerShell check can also be used to confirm the account state:

```powershell
Get-ADUser -Identity <username> -Properties Enabled |
Select-Object Name,SamAccountName,Enabled
```

## What I Learned

The failures helped reinforce several administration concepts:

- PowerShell execution policy affects whether local scripts can run.
- OUs and security groups serve different purposes in Active Directory.
- Active Directory depends heavily on DNS for domain discovery and service location.
- A client being able to ping a domain controller does not prove that domain services can be located.
- User authentication problems can come from the account state itself, not just passwords or connectivity.
- Successful script execution is not enough; AD changes should be verified afterward with read-only commands.
