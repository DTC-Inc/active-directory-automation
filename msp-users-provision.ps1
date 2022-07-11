
# Get Domain information
$domainDn = Get-AdDomain | Select -Expand DistinguishedName | Out-String
$domainName = Get-AdDomain | Select -Expand DNSRoot | Out-String
$pathCheck = Get-AdOrganizationalUnit -Filter 'Name -like MSP"' | Select -Expand DistinguishedName
$mspDn = "OU=MSP,$domainDn"

# Set PowerShell variables with data from RMM tool
$adminUserName = "@adminUser@"
$adminPassword = "@adminPassword@" | ConvertTo-SecureString -AsPlainText -Force
$rmmUserName = "@rmmUser@"
$rmmPassword = "@rmmPassword@" | ConvertTo-SecureString -AsPlainText -Force
$backupUserName = "@backupUser@"
$backupPassword = "@backupUserPassword@" | ConvertTo-SecureString -AsPlainText -Force
$serviceGroup = @serviceGroup@
$mspEmail = @mspEmail@


# Set user details and password from RMM tool
$adminUser = @{
    Description = "MSP Admin"
    UserPrincipalName = "@adminUser@" + $domainName
    Name = "MSP Admin"
    SamAccountName = "@adminUser@"
    Surname = "Admin"
    GivenName = "MSP"
    EmailAddress = "@mspEmail@"
    ChangePasswordAtLogon = 0
    CannotChangePassword = 0
    PasswordNeverExpires = 1
    AccountPassword = $adminPassword
    Enabled = 1
    Path = "$mspDn"
}

$rmmUser = @{
    Description = "MSP RMM Service User"
    UserPrincipalName = "@rmmUser@" + $domainName
    SamAccountName = "@rmmUser@"
    EmailAddress = "@mspEmail@"
    ChangePasswordAtLogon = 0
    CannotChangePassword = 1
    PasswordNeverExpires = 1
    AccountPassword = $rmmPassword
    Enabled = 1
    Path = "$mspDn"
}

$backupUser = @{
    Description = "MSP Backup Service User"
    UserPrincipalName = "@backupUserName@" + $domainName
    SamAccountName = "@backupUserName@"
    EmailAddress = "@mspEmail@"
    ChangePasswordAtLogon = 0
    CannotChangePassword = 1
    PasswordNeverExpires = 1
    AccountPassword = $backupPassword
    Enabled = 1
    Path = "$mspDn"
}


# Checking for existing members in AD groups.
$groupMemberCheckDomainAdmins = Get-AdGroupMember -Identity "Domain Admins"
$groupMemberCheckEnterpriseAdmins = Get-AdGroupMember -Identity "Enterprise Admins"
$groupMemberCheckSchemaAdmins = Get-AdGroupMember -Identity "Schema Admins"
$groupMemberCheckAdministrators = Get-AdGroupMember -Idenity "Administrators"

# Checking for existing users
$userCheckAdminUser = Get-AdUser -Filter 'Name -eq "$adminUserName"'
$userCheckRmmUser = Get-AdUser -Filter 'Name -eq "$rmmUserName"'
$userCheckBackupUser = Get-AdUser -Filter 'Name -eq "$backupUserName"'


# OU Check and Actions
if ( $pathCheck -eq $null )
{
    New-AdOrganizationalUnit -Name "MSP" -Path $domainDn
}


# MSP Group Check and Actions
if ( $groupCheck -eq $null )
{
    New-AdGroup -Name "$serviceGroup" -SamAccountName "$serviceGroup" -GroupCategory Security -GroupScope Global -DisplayName "MSP Service Accounts" -Path $mspDn
} else {
    Get-AdGroup -Name "$serviceGroup" | Move-AdObject -TargetPath "$mspDn"
}


# User Checks and Actions
if ( $userCheckAdminUser -eq $null )
{
    New-AdUser $adminUser
} else {
    Get-AdUser -Identity $adminUserName | Move-AdObject -TargetPath "$mspDn"
}

if ( $userCheckRmmUser -notcontains "$rmmUser")
{
    New-AdUser $rmmUser
} else {
    Get-AdUser -Identity $rmmUserName | Move-AdObject -TargetPath "$mspDn"
}

if ( $userCheckBackupUser -notcontains "$backupUser")
{
    New-AdUser $rmmUser
} else {
    Get-AdUser -Identity $backupUserName | Move-AdObject -TargetPath "$mspDn"
}


# Checking for members in the service group
$groupMemberCheckService = Get-AdGroupMember -Identity $serviceGroup



if ( $groupMemberCheckService -notcontains "$backupUserName" )
{
    Add-AdGroupMember -Identity "$serviceGroup" -Members $backupUserName
}

if ( $groupMemberCheckService -notcontains "$rmmUserName")
{
    Add-AdGroupMember -Identity "$serviceGroup" -Members $rmmUserName
}

# Admin checks and actions
if ( $groupMemberCheckDomainAdmins -notcontains "$adminUserName" )
{
    Add-AdGroupMember -Identity "Domain Admins" -Members "$adminUserName"
}

if ( $groupMemberCheckEnterpriseAdmins -notcontains "$adminUserName" )
{
    Add-AdGroupMember -Identity "Enterprise Admins" -Members "$adminUserName"
}

if ( $groupMemberCheckSchemaAdmins -notcontains "$adminUserName" )
{
    Add-AdGroupMember -Identity "SchemaAdmins" -Members "$adminUserName"
}

if ( $groupMemberCheckAdministrators -notcontains $adminUserName )
{
    Add-AdGroupMember -Identity "Administrators" -Members "$adminUserName"
}