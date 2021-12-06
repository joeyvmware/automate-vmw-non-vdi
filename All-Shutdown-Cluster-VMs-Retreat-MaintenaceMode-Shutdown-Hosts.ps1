# The beginning of each script I always include how to create the credential file and how to import it for each script I use.
# Save vCenter credentials - Only needs to be ran once to create .cred file.
# $credentials = Get-Credential
# $credentials | Export-Clixml -path <driveletter>:\<path>\<filename>.cred
$credentials = import-clixml -path <driveletter>:\<path>\<filename>.cred
$vc = "jw-vcenter.iamware.net"
$cluster = "vSAN-Cluster"
$clusterDomain = "config.vcls.clusters.domain-c##.enabled"  # Change the the number within domain-c## to whatever your cluster number is and reference https://docs.vmware.com/en/VMware-vSphere/7.0/com.vmware.vsphere.resmgmt.doc/GUID-F98C3C93-875D-4570-852B-37A38878CE0F.html for help

# Connect to vCenter with saved creds
connect-viserver -Server $vc -Credential $credential

# Set Retreat Mode to shutdown and remove vCLS VMs on this specific cluster.
New-AdvancedSetting -Entity $vc -name $clusterDomain -Value False -Confirm:$false -Force
Start-Sleep -Seconds 180 # This should given enough time for vCenter to shutdown and remove these VMs.

# Get list of VMs based upon this cluster that are Powered On and save to a CSV file to power back on later, for now we gracefully shutdown those VMs.
$vmservers=get-vm -location (Get-Cluster -Name $cluster) | Where {$_.PowerState -eq "PoweredOn"} 
$vmservers | select Name | export-csv <driveletter>:\<path>\cluster-vms.csv -NoTypeInformation  # I'm using this file to later power on back the same VMs after maintenance in another script
$vmservers | Shutdown-VMGuest -Confirm:$false

# Shutdown any left over VMs that didn't shutdown successfully
$vmservers=get-vm -location (Get-Cluster -Name $cluster) | Where {$_.PowerState -eq "PoweredOn"} 
$vmservers | Stop-VM -Kill -Confirm:$false

# Enter Hosts into maintenance mode with no data migration for vSAN since we are shutting them all down.
# Get Cluster hosts
$vmhosts = Get-Cluster $cluster | Get-VMHost
# Loop through each host
foreach ($vmhost in $vmhosts){
Set-VMhost -State maintenance -Evacuate -vsandatamigrationmode nodatamigration $vmhost
}

# Shutdown hosts so that the Smart Outlets I use can kill the power in a scheduled task by the provider.
foreach ($vmhost in $vmhosts){
Stop-VMHost $vmhost -Confirm:$false}

