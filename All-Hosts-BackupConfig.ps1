# Clear All Variables
Remove-Variable * -ErrorAction SilentlyContinue

# The beginning of each script I always include how to create the credential file and how to import it for each script I use.
# Save vCenter credentials - Only needs to be ran once to create .cred file.
# $credentials = Get-Credential
# $credentials | Export-Clixml -path <DriveLetter>:\scripts\<localrootpass>.cred
$credentials = import-clixml -path <DriveLetter>:\scripts\<localrootpass>.cred

#region Starter Vars () - Generic Declarations for this example 
$vc = "vcenter.fdqn.whatever"

# Connect to vCenter with saved creds
connect-viserver -Server $vc -Credential $credentials

# Get ESXi host configuration
Get-VMhost | Get-VMHostFirmware -BackupConfiguration -DestinationPath <DriveLetter>:\backup\Hosts
