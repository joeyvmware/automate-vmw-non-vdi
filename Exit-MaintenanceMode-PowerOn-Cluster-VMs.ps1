# Script to exit Maintenance Mode on vSAN hosts, disable Retreat mode for the cluster VM and then power back on VMs that were collected in a CSV file as running before the shutdown.
# I use this script to bring my home lab environment back up after doing maintenance or shutting down from using Smart Hours to save on power consumption.

# The beginning of each script I always include how to create the credential file and how to import it for each script I use.
# Save vCenter credentials - Only needs to be ran once to create .cred file.
# $credentials = Get-Credential
# $credentials | Export-Clixml -path <driveletter>:\<path>\<filename>.cred
$credentials = import-clixml -path <driveletter>:\<path>\<filename>.cred
$vc = "vcenter.fdqn.whatever"
$cluster = "vSAN-Cluster" # Change to your Host cluster name
$clusterDomain = "config.vcls.clusters.domain-c##.enabled"  # Change the the number within domain-c## to whatever your cluster number is and reference https://docs.vmware.com/en/VMware-vSphere/7.0/com.vmware.vsphere.resmgmt.doc/GUID-F98C3C93-875D-4570-852B-37A38878CE0F.html for help

# Connect to vCenter with saved creds
connect-viserver -Server $vc -Credential $credentials

# Exit hosts from maintenance
# Get Cluster hosts
$vmhosts = Get-Cluster $cluster | Get-VMHost
# Loop through each host
foreach ($vmhost in $vmhosts){
Set-VMhost $vmhost -State Connected
}

# Remove Retreat mode from cluster
Get-AdvancedSetting -Entity $vc -name $clusterDomain | Set-AdvancedSetting -Value True -Confirm:$false
Start-Sleep 180 # Gives vCenter enough time to recreate the VMs for the clustering service.

# Import the night before list of VMs that were automatically powered off
$servers = import-csv <driveletter>:\<path>\$cluster-vms.csv | Select -ExpandProperty name
Start-VM -VM $servers
