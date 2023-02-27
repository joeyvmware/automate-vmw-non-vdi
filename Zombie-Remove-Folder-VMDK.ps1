# https://communities.vmware.com/t5/VMware-PowerCLI-Discussions/is-it-possible-to-move-the-Zombie-file-from-specified-path-to/m-p/2954251#M110731
# Initially created by LucD at the above link
# Clear All Variables
Remove-Variable * -ErrorAction SilentlyContinue

# Setup Warnings
$w1 = "Running this script accepts that you are aware VMware is not liable for anything that happens nor will VMware Support help with the intended script or actions following. This script will delete files from the datastore so please have backups! Please test first in a lab if you can."
$WarningPreference = "Continue"
$w1 | Write-Warning

# The beginning of each script I always include how to create the credential file and how to import it for each script I use.
# Save vCenter credentials - Only needs to be ran once to create .cred file.
# $credential = Get-Credential
# $credential | Export-Clixml -path <drive>:\<location>\powershell-local-vcenter.cred
$credential = import-clixml -path <drive>:\<location>\powershell-local-vcenter.cred
$credpass = [PSCredential]::new(0, $credential.Password).GetNetworkCredential().Password
$vc = "vcenter.fqdn.com"
$RVToolsFolder = "<drive>:\<location>\<folder>"
$file = '<drive>:\<location>\<folder>\RVTools_tabvHealth.csv'
# Delete previous file
Remove-Item -path $file -ErrorAction Ignore
# Connect to vCenter with saved creds
connect-viserver -Server $vc -Credential $credential

# Below we will set the vSphere Cluster and Datastores that we want to search.
$Datastores = Get-Datastore # Used to get a list of all the datastores in the connected vCenter


# Automate the collection of vHealth info from RVTools
# If you do not want to automate this part, just use RVTools and Export All to CSV then copy the RVTools_tabvHealth.scv to the folder path in Line 19
Write-Host "Running RVTools to generate the list of VMs and VMDK files that are considered Zombies" -ForegroundColor Green
$env:Path += ";C:\Program Files (x86)\Robware\RVTools"
Set-Location -Path 'C:\Program Files (x86)\Robware\RVTools'
RVTools -s $vc -u $credential.UserName -p $credpass -c Exportvhealth2csv -d $RVToolsFolder -f RVTools_tabvHealth.csv
while (!(Test-path $file)) {Start-Sleep 10}
Write-host "File created, continuing with removing Zombies!" -ForegroundColor Green

# Cleanup leftovers
# This section will do a loop of all the datastores in $datastores
foreach ($driveName in $datastores){

$tgtDriveName = $driveName
$report = @()
$targetDatatstoreName = $driveName
$targetFolderName = 'ZombieVMDK' # Only needed if you are going to move the Move-Item instead of Remove-Item in Line 75
$filter = 
Get-PSDrive -Name $driveName -ErrorAction SilentlyContinue | Remove-PSDrive -Confirm:$False -ErrorAction SilentlyContinue
#Get-PSDrive -Name $tgtDriveName -ErrorAction SilentlyContinue | Remove-PSDrive -Confirm:$False -ErrorAction SilentlyContinue

# Setup target datastore and folder
$tgtds = Get-Datastore -Name $targetDatatstoreName
New-PSDrive -Name $tgtDriveName -PSProvider VimDatastore -Root \ -Location $tgtds > $null
New-Item -Path "$($tgtDriveName):$($targetFolderName)" -ItemType Directory -ErrorAction SilentlyContinue

# Remove whole VM directory if VMX file is detected.
Get-Content -Path $file | 
ConvertFrom-Csv | 
Where-Object {($_.Message -match 'Possibly a Zombie VM!') -and ($_.Name -notmatch 'cp-replica-') -and ($_.Name -notmatch 'appvolumes') -and ($_.Name -notmatch 'contentlib') -and ($_.Name -notmatch 'cp-template-')}|
Group-Object -Property {$_.Name.Split(']')[0].Trimstart('[')} | %{
    Write-Host "Looking at datastore $drivename"
    $ds = Get-Datastore -Name $_.Name
    Try{
        # New-PSDrive -Name $driveName -PSProvider VimDatastore -Root \ -Location $ds > $null -ErrorAction SilentlyContinue
    }
    Catch{
        Write-Host "Could not create PSDrive for $($ds.Name)"
        break
    }
    $_.Group | %{
        $vmdkPath = "$($driveName):/$($_.Name.Split(' ')[1])"
        $vmdkfolder = "$($_.Name.Split(' ').Split('/')[1])"
        $vmfldstrng = $driveName,$vmdkfolder -join ":/"
                if(Test-Path -Path $vmdkPath){
            Write-Host "Deleting VM Folder $($driveName):$($_.Name.Split(' ').Split('/')[1] + '/')"
            Remove-Item -path $vmfldstrng -Recurse -Confirm:$false -ErrorAction SilentlyContinue
          
        }
        else{
            Write-Host "VMX $($vmfldstrng) not found"
        }
    } 
 Remove-PSDrive -Name $driveName -ErrorAction SilentlyContinue
}
}

foreach ($driveName in $datastores){
# Extract zombie VMDK
Get-Content -Path $file | 
ConvertFrom-Csv | 
Where-Object {($_.Message -match 'Possibly a Zombie vmdk file') -and ($_.Name -notmatch 'cp-replica-') -and ($_.Name -notmatch 'appvolumes') -and ($_.Name -notmatch 'contentlib') -and ($_.Name -notmatch 'cp-template-')} |
Group-Object -Property {$_.Name.Split(']')[0].Trimstart('[')} | %{
    Write-Host "Looking at datastore $($_.Name)"
    $ds = Get-Datastore -Name $_.Name
    Try{
        New-PSDrive -Name $driveName -PSProvider VimDatastore -Root \ -Location $ds > $null
    }
    Catch{
        Write-Host "Could not create PSDrive for $($ds.Name)"
        break
    }
    $_.Group | %{
        $vmdkPath = "$($driveName):$($_.Name.Split(' ')[1])"
        if(Test-Path -Path $vmdkPath){
            Write-Host "Deleting VMDK $($_.Name)"
            Remove-Item -Path $vmdkPath
        }
        else{
            Write-Host "VMDK $($vmdkPath) not found"
        }
    }
    Remove-PSDrive -Name $driveName -ErrorAction SilentlyContinue
}
Remove-PSDrive -Name $tgtDriveName -ErrorAction SilentlyContinue
}

