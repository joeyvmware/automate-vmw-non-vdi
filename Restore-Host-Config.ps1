# Clear All Variables
Remove-Variable * -ErrorAction SilentlyContinue

# Script to power off VMs on a dedicated host without vCenter access
# Save vCenter credentials - Only needs to be ran once to create .cred file.
# $credential = Get-Credential
# $credential | Export-Clixml -path <DriveLetter>:\scripts\localroostpass.cred
# Import cred file
$credential = import-clixml -path <DriveLetter>:\scripts\localroostpass.cred
$vmhost = "esxhost1.fqdn.wahtever"
$restoreConfig = "<DriveLetter>:\backup\hosts\configBundle-esxhost1.fqdn.wahtever.tgz"

Set-PowerCLIConfiguration -InvalidCertificateAction Ignore -Confirm:$false

# Connect to Host with saved creds
connect-viserver -server $vmhost -Credential $credential

#Restore Host Configuration
Set-VMHost -VMHost $vmHost -State 'Maintenance'
Set-VMHostFirmware -VMHost $vmhost -Restore -SourcePath $restoreConfig -HostUser $credential.username -HostPassword $credential.password
