# Clear All Variables
Remove-Variable * -ErrorAction SilentlyContinue

# Save vCenter credentials - Only needs to be ran once to create .cred file.
# $credential = Get-Credential

# Export cred file
# $credential | Export-Clixml -path <DriveLetter>:\scripts\esxi_root.cred

# Import cred file
$credential = import-clixml -path <DriveLetter>:\scripts\esxi_root.cred

#region Started Vars () - Generic Declarations for this example
$vmhost = "esxhost1.fqdn.wahtever"
$restoreConfig = "<DriveLetter>:\backup\hosts\configBundle-$($vmhost).tgz"
#endregion

# Ignore Invalid Certificate warning
Set-PowerCLIConfiguration -InvalidCertificateAction Ignore -Confirm:$false

# Connect to Host with saved creds
connect-viserver -server $vmhost -Credential $credential

#Restore Host Configuration
Set-VMHost -VMHost $vmHost -State 'Maintenance'
Set-VMHostFirmware -VMHost $vmhost -Restore -SourcePath $restoreConfig -HostUser $credential.username -HostPassword $credential.password
