# Move inactive accounts after 90 days to Disabled OU's within their own OU (exception built-in OU's go to a root OU called Disabled). Disable them as well.

# Get domain Distinguished Name
$domainDn = Get-ADDomain | Select -ExpandProperty DistinguishedName | Out-String

# Get Built-in OU's
$usersOu = -Join ("CN=Users,",$domainDn)
$computersOu = -Join ("CN=Computers,",$domainDn)

# Get string for OU=Disable,CN=domain,CN=com
$disabledOuRoot = -Join ("OU=Disabled,",$domainDn)

# Create sub OU's called Disabled in all custom OU's
Get-ADOrganizationalUnit -Filter * | Where -Property DistinguishedName -notlike "*Disabled*" | foreach-object { New-ADOrganizationalUnit -Name "Disabled" -Path $_.DistinguishedName }

# Create root Disabled OU
New-ADOrganizationalUnit -Name "Disabled" -Path $domainDn

# Move all inactive for 90 day users into OU where they are currently stored.
Search-ADAccount -UsersOnly -AccountInactive -TimeSpan 90.00:00:00 | Where { ($_.SamAccountName -notlike "*template*") -and ($_.DistinguishedName -notlike "*Disabled*") } | foreach-object -Begin $null -Process { $path = $_.DistinguishedName | Out-String }, { $index =$path.IndexOf(',') }, { $targetPath = -Join ("OU=Disabled",$path.substring($index)) }, { Move-AdObject -TargetPath $targetPath -Identity $_ } -End $null


# Move already disabled users into Disabled OU.
Search-ADAccount -UsersOnly -AccountDisabled | Where { ($_.SamAccountName -notlike "*template*") -and ($_.DistinguishedName -notlike "*Disabled*") } | foreach-object -Begin $null -Process { $path = $_.DistinguishedName | Out-String }, { $index =$path.IndexOf(',') }, { $targetPath = -Join ("OU=Disabled",$path.substring($index)) }, { Move-AdObject -TargetPath $targetPath -Identity $_ } -End $null

# Move inactive users in built-in OU's to root Disabled OU
Search-ADAccount -UsersOnly -AccountInactive -TimeSpan 90.00:00:00 | Where { ($_.SamAccountName -notlike "*template*") -and ($_.DistinguishedName -notlike "*Disabled*") } | foreach-object -Begin $null -Process { Move-AdObject -TargetPath $disabledOuRoot -Identity $_ } -End $null

# Move disabled users in built-in OU's to root Disabled OU
Search-ADAccount -UsersOnly -AccountDisabled -TimeSpan 90.00:00:00 | Where { ($_.SamAccountName -notlike "*template*") -and ($_.DistinguishedName -notlike "*Disabled*") } | foreach-object -Begin $null -Process { Move-AdObject -TargetPath $disabledOuRoot -Identity $_ } -End $null

# Move inactive users in built-in OU's to root Disabled OU
# Search-ADAccount -UsersOnly -AccountInactive -TimeSpan 90.00:00:00 -SearchBase $usersOu | Where { ($_.SamAccountName -notlike "*template*") -and ($_.DistinguishedName # -notlike "*Disabled*") } | foreach-object -Begin $null -Process { Move-AdObject -TargetPath $disabledOuRoot -Identity $_ } -End $null
# **** INACTIVE UNTIL SEARCHBASE IS WORKING WITH VARIABLE
# Move disabled users in built-in OU's to root Disabled OU
# Search-ADAccount -UsersOnly -AccountDisabled -TimeSpan 90.00:00:00 -SearchBase $usersOu | Where { ($_.SamAccountName -notlike "*template*") -and ($_.DistinguishedName # -notlike "*Disabled*") } | foreach-object -Begin $null -Process { Move-AdObject -TargetPath $disabledOuRoot -Identity $_ } -End $null

# Disable inactive users at 90 days in entire directory
Search-ADAccount -UsersOnly -AccountInactive -TimeSpan 90.00:00:00 | Where -Property DistinguishedName -like "*Disabled*" | Disable-ADAccount
Search-ADAccount -UsersOnly -AccountDisabled | Where -Property DistinguishedName -like "*Disabled*" | Disable-ADAccount
