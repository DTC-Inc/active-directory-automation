$domainDn = Get-AdDomain | Select -Expand DistinguishedName | Out-String
$domainName = Get-AdDomain | Select -Expand DNSRoot | Out-String
$pathCheck = Get-AdOrganizationalUnit -Filter 'Name -like MSP"' | Select -Expand DistinguishedName
$mspDn = "OU=MSP,$domainDn"

$dtcadminUser = "dtcadmin"
$dtcadminPassword = "@dtcadminPassword@" | ConvertTo-SecureString -AsPlainText -Force
$dtcRmmUser = "@dtcRmmUser@"
$dtcRmmPassword = "" | ConvertTo-SecureString -AsPlainText -Force
$dtcBackupUser = "@dtcBackupUser@"
$dtcBackupPassword = "" | ConvertTo-SecureString -AsPlainText -Force

$dtcadminUser = @{
    Description = "MSP Admin DTC Inc."
    UserPrincipalName = "$dtcadminUser" + $domainName
    Name = "DTC Admin"
    SamAccountName = "dtcadmin"
    Surname = "Admin"
    GivenName = "DTC"
    EmailAddress = "helpdesk@dtctoday.com"
    ChangePasswordAtLogon = 0
    CannotChangePassword = 0
    PasswordNeverExpires = 1
    AccountPassword = $dtcadminPassword
    Enabled = 1
    Path = "$mspDn"
}
$dtcRmmUser = @{
    Description = "RMM Service User DTC Inc."
    UserPrincipalName = "dtcautomate@" + $domainName
    SamAccountName = "$dtcRmmUser"
    EmailAddress = "helpdesk@dtctoday.com"
    ChangePasswordAtLogon = 0
    CannotChangePassword = 1
    PasswordNeverExpires = 1
    AccountPassword = $dtcRmmPassword
    Enabled = 1
    Path = "$mspDn"
}

$dtcRmmUser = @{
    Description = "Backup Service User DTC Inc."
    UserPrincipalName = "$dtcBackupUser" + $domainName
    SamAccountName = "$dtcBackupUser"
    EmailAddress = "helpdesk@dtctoday.com"
    ChangePasswordAtLogon = 0
    CannotChangePassword = 1
    PasswordNeverExpires = 1
    AccountPassword = $dtcBackupPassword
    Enabled = 1
    Path = "$mspDn"
}

$dtcadminGroupMemberCheck = Get-AdGroupMember -Identity "Domain Admins"
$groupCheck = Get-AdGroup -Identity dtcsvc
$userCheckDtcAdmin = Get-AdUser -Filter 'Name -eq "dtcadmin"'
$userCheckDtcautomate = Get-AdUser -Filter 'Name -eq "$dtc"'
$userCheckDtcbackup = Get-AdUser -Filter 'Name -eq "dtcabackup"'

if ( $pathCheck -eq $null )
{
    New-AdOrganizationalUnit -Name "MSP" -Path $domainDn
}

if ( $groupCheck -eq $null )
{
    New-AdGroup -Name "dtcsvc" -SamAccountName "dtcsvc" -GroupCategory Security -GroupScope Global -DisplayName "DTC Service Accounts" -Path $mspDn
}

if ( $userCheckDtcadmin -eq $null )
{
    New-AdUser @dtcadminUser
} else {
    Get-AdUser -Identity dtcadmin | Move-AdObject -TargetPath "$mspDn"
}

if ( $userCheckDtcRmm -notcontains "$dtcRmmUser")
{
    
}

$dtcsvcGroupMemberCheck = Get-AdGroupMember -Identity dtcsvc



if ( $dtcadminGroupMemberCheck -notcontains "dtcadmin" )
{
    Add-AdGroupMember -Identity "Domain Admins" -Members dtcadmin
}

