$jsonPath = Join-Path $PSScriptRoot "..\data\users.json"
$users = Get-Content $jsonPath -Raw | ConvertFrom-Json

$password = Read-Host "Enter temporary password for new users" -AsSecureString

foreach ($user in $users) {

    $params = @{
        Name                  = "$($user.GivenName) $($user.Surname)"
        GivenName             = $user.GivenName
        Surname               = $user.Surname
        SamAccountName        = $user.SamAccountName
        UserPrincipalName     = "$($user.SamAccountName)@corp.lab"
        Department            = $user.Department
        Path                  = $user.OU
        Enabled               = $user.Enabled
        ChangePasswordAtLogon = $user.ChangePasswordAtLogon
        PasswordNeverExpires  = $user.PasswordNeverExpires
        AccountPassword       = $password
    }

    New-ADUser @params
}
