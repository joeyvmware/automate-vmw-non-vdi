# This script is to check and if not started, start the VMware vSphere Profile-Driven Storage Service so that the vSphere Cluster Services appliances
# can be deployed on any host within a cluster. If not started, it will fill the task pane with failure tasks.
# 
# Clear All Variables
Remove-Variable * -ErrorAction SilentlyContinue

# The beginning of each script I always include how to create the credential file and how to import it for each script I use.
# Save vCenter credentials - Only needs to be ran once to create .cred file.
# $credential = Get-Credential
# $credential | Export-Clixml -path <drivelocation>:\<folder>\adminlocal-vcenter.cred
$credential = import-clixml -path <drivelocation>:\<folder>\adminlocal-vcenter.cred
$vc = "vcenter.fqdn"
$ServiceName = "sps"

# Connect to vCenter with saved creds
Connect-CIsServer -Server $vc -User $credential.UserName -Password $credential.Password

# Run VAMI commands
Get-VAMIService $ServiceName

$arrService = Get-VAMIService -Name $ServiceName


# Check if $serviceName is started, if not start
if ($arrService.State -ne 'Started'){
$ServiceStarted = $false}
Else{$ServiceStarted = $true}

while ($ServiceStarted -ne $true){
Start-VAMIService $ServiceName
write-host $arrService.status
write-host 'Service started'
Start-Sleep -seconds 60
$arrService = Get-VAMIService -Name $ServiceName #Why is this line needed?
if ($arrService.State -eq 'Started'){
$ServiceStarted = $true}
}

write-host '$ServiceName has started, disconnecting and exiting..'

Disconnect-CisServer -Server $vc -Confirm:$false
