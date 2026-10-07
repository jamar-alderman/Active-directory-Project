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

## `users.json` could not be found

**Symptom**

`Get-Content` returned `PathNotFound` when the script attempted to read `users.json`.

**Cause**

The script used a relative path, but the JSON file was not located under the expected name/path from the current working directory.

**Resolution**

I corrected the filename/location so PowerShell could resolve it. The GitHub version of the script now resolves the JSON file relative to the script itself with `$PSScriptRoot`, which is more reliable than depending on the shell's current directory.

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

## What I Learned

The failures helped reinforce several administration concepts:

- Relative file paths depend on execution context unless the script anchors them explicitly.
- PowerShell execution policy affects whether local scripts can run.
- OUs and security groups serve different purposes in Active Directory.
- Successful script execution is not enough; AD changes should be verified afterward with read-only commands.
