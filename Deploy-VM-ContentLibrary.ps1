# I leave these process in my scripts so I can create the credential file when needed on new PS host but keep the lines commented out except for import line that is needed.
# The beginning of each script I always include how to create the credential file and how to import it for each script I use.
# Save vCenter credentials - Only needs to be ran once to create .cred file.
# $credentials = Get-Credential
# $credentials | Export-Clixml -path <driveletter>:\<path>\<filename-vcenter>.cred
$credentials = import-clixml -path <driveletter>:\<path>\<filename-vcenter>.cred

# Connect to vCenter with saved creds
connect-viserver -Server jw-vcenter.iamware.net -Credential $credentials

#region Modules Load
Get-Module -Name VMware* -ListAvailable | Import-Module
#endregion

# This is not a completely automated process as I have a menu of which Content Library VM Template to use.  You could hardset that in like I do for my VDI Connection Server builds in the other repo.

#region Starter Vars () - Generic Declarations for this example 
$cluster = Get-Cluster "vSAN-Cluster"   # Set your Host cluster
$resourcepool = "RP-PowerShell-Deploy" # Set your Resouce Pool if you are using those in your environment
$datacenter = $cluster | Get-Datacenter 
$datastore = "vsanDatastore" # Set your Cluster shared datastore
$folder = Get-Folder "PowerShell-Deploy"  # Set your VM folder if you are using those in your environment
$vmSubnet = Get-VDPortgroup -Name "VMs" # Set your network portgroup name
$numCPU = Read-Host -Prmopt 'How many vCPUs?' 
$numRAM = Read-Host -Prompt 'How much RAM?'
$spec = "Windows" # This is the name of the VM Custiomization Profile in vCenter under Profiles and Policies
#endregion

$vmname = Read-Host -Prompt 'Input VM name'
Get-ContentLibraryItem | Select Name
$templatename = Read-Host -Prompt 'Which template'

#spin up the vm from a content library template.
Get-ContentLibraryItem -ItemType "vm-template" -Name $templatename  | New-VM -Name $vmname -resourcePool $resourcepool -location $folder -datastore $datastore -confirm:$false

#assumes a single nic, which as a template should be your standard
Get-NetworkAdapter -VM $vmname | Set-NetworkAdapter -NetworkName $vmSubnet -StartConnected $true -confirm:$false

#set your custimization specification
set-vm $vmname -OSCustomizationSpec $spec -NumCpu $numCPU -MemoryGB $numRAM -confirm:$false

#with no other options left to configure start it up. 
Start-VM $vmname -confirm:$false
