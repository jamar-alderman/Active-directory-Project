# Active Directory Infrastructure Lab

Windows Server 2025 lab focused on building and administering a small on-premises Active Directory environment, automating user provisioning with PowerShell and JSON, and documenting the troubleshooting required to make the environment work.

## Why I Built This

I built this lab to learn how core Windows infrastructure services work together instead of only creating users manually in Active Directory Users and Computers. The goal is to understand Active Directory, DNS, DHCP, organizational units, security groups, Windows clients, and PowerShell automation as one environment.

## Lab Environment

| Component | Configuration |
| --- | --- |
| Domain | `corp.lab` |
| Domain Controller | Windows Server 2025 |
| AD-LAB network | `192.168.110.0/24` |
| Domain Controller IP | `192.168.110.10/24` |
| DNS | Windows DNS on `192.168.110.10` |
| DHCP scope | `192.168.110.50-192.168.110.200` |
| Virtualization | KVM / libvirt |
| Client OS | Windows 11 |

## What I Built

### Active Directory Domain Services

- Created the `corp.lab` forest and domain.
- Promoted Windows Server 2025 to a domain controller.
- Created departmental OUs for IT, HR, Helpdesk, and Finance.
- Created security groups separately from OUs to reinforce the difference between object organization and access control.

### DNS

- Configured the domain controller as the DNS server for the domain.
- Created and verified the `corp.lab` forward lookup zone.
- Created the `192.168.110` reverse lookup zone.
- Created and verified the PTR record for the domain controller.
- Verified Active Directory LDAP SRV records with `nslookup`.
- Prevented the separate Internet-facing/NAT adapter from registering its address in AD DNS.

### DHCP

- Installed and configured Windows DHCP Server.
- Created a scope for `192.168.110.50-192.168.110.200`.
- Configured clients to receive the domain DNS server and domain name through DHCP.

### PowerShell + JSON User Provisioning

User account data is stored in JSON and read by PowerShell with:

```powershell
$users = Get-Content .\users.json -Raw | ConvertFrom-Json
```

The provisioning script loops through each JSON object, builds a parameter hashtable, and passes it to `New-ADUser` with PowerShell splatting.

```powershell
New-ADUser @params
```

The workflow provisions:

- Given name and surname
- `SamAccountName`
- User principal name
- Department
- OU placement
- Enabled state
- Temporary password
- Change-password-at-logon setting
- Password-never-expires setting

See [`powershell/usercreate.ps1`](powershell/usercreate.ps1) and [`data/users.json`](data/users.json).

## Verification

After provisioning, I verified the accounts with:

```powershell
Get-ADUser -Filter * |
Select-Object Name,SamAccountName,DistinguishedName
```

This confirmed that all five test users were created and placed in the correct OUs.

Additional verification:

```powershell
Get-ADUser -Filter * -Properties Department |
Select-Object Name,SamAccountName,Department
```

## Troubleshooting

The most useful part of the lab was fixing issues instead of only following the successful path.

### PowerShell execution policy blocked the script

**Symptom:** PowerShell refused to run the `.ps1` file because it was not digitally signed.

**Fix:** Used a process-scoped execution-policy bypass for the lab session rather than permanently weakening the machine policy.

```powershell
Set-ExecutionPolicy -Scope Process Bypass
```

### Script could not find `users.json`

**Symptom:** `Get-Content` returned `PathNotFound`.

**Cause:** The script used a relative path, but the JSON file name/location did not match what the script expected.

**Fix:** Renamed/moved the JSON file so it was in the script's working directory with the expected filename.

### `New-ADUser: Directory object not found`

**Symptom:** The script parsed the JSON successfully but failed when creating each user.

**Cause:** The JSON contained paths such as `OU=IT,DC=corp,DC=lab`, but IT, HR, Helpdesk, and Finance existed as security groups rather than Organizational Units.

**Fix:** Created the actual OUs and reran the same provisioning script successfully.

This reinforced that:

- OUs are containers used to organize AD objects and apply/delegate policy.
- Security groups are used to assign access and permissions.

See [`troubleshooting/README.md`](troubleshooting/README.md) for the break/fix notes.

## Current Status

Completed so far:

- Windows Server 2025 domain controller
- AD DS
- DNS
- DHCP
- Forward and reverse DNS verification
- Departmental OUs
- Security groups
- JSON-driven PowerShell user provisioning
- Successful creation and verification of five AD users

## Next Steps

- Join a Windows 11 client to `corp.lab`
- Verify DHCP, DNS, and domain authentication from the client
- Log in with one of the provisioned domain users
- Build and test Group Policy Objects
- Add security-group membership automation
- Create file shares and apply NTFS/share permissions through groups
- Document intentional break/fix scenarios such as bad DNS, account lockout, and GPO failures

## Skills Demonstrated

Active Directory, Windows Server 2025, DNS, DHCP, PowerShell, JSON, identity administration, KVM/libvirt, user provisioning, troubleshooting, and verification.
