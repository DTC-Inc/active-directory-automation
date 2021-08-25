$domainDn = Get-ADDomain | Select -ExpandProperty DistinguishedName | Out-String
$disabledOuRoot = -Join ("OU=Disabled,",$domainDn)

Get-ADOrganizationalUnit -Filter * | Where -Property DistinguishedName -notlike "*Disabled*" | foreach-object { New-ADOrganizationalUnit -Name "Disabled" -Path $_.DistinguishedName }

New-ADOrganizationalUnit -Name "Disabled" -Path $domainDn

Search-ADAccount -UsersOnly -AccountInactive -TimeSpan 90.00:00:00 | Where { ($_.SamAccountName -notlike "*template*") -and ($_.DistinguishedName -notlike "*Disabled*") } | foreach-object -Begin $null -Process { $path = $_.DistinguishedName | Out-String }, { $index =$path.IndexOf(',') }, { $targetPath = -Join ("OU=Disabled",$path.substring($index)) }, { Move-AdObject -TargetPath $targetPath -Identity $_ } -End $null



Search-ADAccount -UsersOnly -AccountDisabled | Where { ($_.SamAccountName -notlike "*template*") -and ($_.DistinguishedName -notlike "*Disabled*") } | foreach-object -Begin $null -Process { $path = $_.DistinguishedName | Out-String }, { $index =$path.IndexOf(',') }, { $targetPath = -Join ("OU=Disabled",$path.substring($index)) }, { Move-AdObject -TargetPath $targetPath -Identity $_ } -End $null

Search-ADAccount -UsersOnly -AccountInactive -TimeSpan 90.00:00:00 | Where { ($_.SamAccountName -notlike "*template*") -and ($_.DistinguishedName -notlike "*Disabled*") } | foreach-object -Begin $null -Process { Move-AdObject -TargetPath $disabledOuRoot -Identity $_ } -End $null

Search-ADAccount -UsersOnly -AccountInactive -TimeSpan 90.00:00:00 | Where -Property DistinguishedName -like "*Disabled*" | Disable-ADAccount
Search-ADAccount -UsersOnly -AccountDisabled | Where -Property DistinguishedName -like "*Disabled*" | Disable-ADAccount
