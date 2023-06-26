$existingVariables = Get-Variable

try {
    #region Starter Vars () - Generic Declarations for this example
    # Save vCenter credentials - Only needs to be ran once to create .cred file.
    $credPath = Read-Host -Prompt "Enter the path to save the vCenter credential file (e.g., C:\scripts\vcsa_admin.cred)"

    # Create the directory if it doesn't exist
    if (-not (Test-Path (Split-Path -Path $credPath))) {
        New-Item -ItemType Directory -Path (Split-Path -Path $credPath) | Out-Null
    }

    $credentials = Get-Credential
    $credentials | Export-Clixml -Path $credPath

    $vCenter = Read-Host -Prompt "Enter the FQDN of your vCenter Server (e.g., vcenter.fqdn.whatever)"
    #endregion

    # Ignore Invalid Certificate warning
    Set-PowerCLIConfiguration -InvalidCertificateAction Ignore -Confirm:$false | Out-Null

    # Connect to vCenter with saved creds
    Connect-VIServer -Server $vCenter -Credential $credentials

    # Get ESXi host configuration
    $configPath = Read-Host -Prompt "Enter the path to save host config export file(s) (e.g., C:\backup\hosts\config)"

    # Create the directory if it doesn't exist
    if (-not (Test-Path $configPath)) {
        New-Item -ItemType Directory -Path $configPath | Out-Null
    }

    Get-VMhost | Get-VMHostFirmware -BackupConfiguration -DestinationPath $configPath

    Write-Host "`nBackup task completed successfully." -ForegroundColor Green
} finally {
    # Remove any new variables
    Get-Variable | Where-Object Name -NotIn $existingVariables.Name | Remove-Variable -ErrorAction SilentlyContinue
}
