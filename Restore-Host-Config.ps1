$existingVariables = Get-Variable

try {
    #region Starter Vars () - Generic Declarations for this example
    # Save ESXi credentials - Only needs to be ran once to create .cred file.
    $credPath = Read-Host -Prompt "Enter the path to save the ESXi credential file (e.g., C:\scripts\localrootpasswd.cred)"

    # Create the directory if it doesn't exist
    if (-not (Test-Path (Split-Path -Path $credPath))) {
        New-Item -ItemType Directory -Path (Split-Path -Path $credPath) | Out-Null
    }

    $credentials = Get-Credential
    $credentials | Export-Clixml -Path $credPath
    
    # Path to saved config exports
    $configPath = Read-Host -Prompt "Enter the path to the saved host config export file(s) (e.g., C:\backup\hosts\config)"

    $vmHost = Read-Host -Prompt "Enter the FQDN of the ESXi server you want to restore (e.g., esxhost1.fqdn.whatever)"

    $restoreConfig = Join-Path -Path $configPath -ChildPath "configBundle-$vmHost.tgz"
    #endregion

    # Ignore Invalid Certificate warning
    Set-PowerCLIConfiguration -InvalidCertificateAction Ignore -Confirm:$false | Out-Null

    # Connect to ESXi host with saved creds
    Connect-VIServer -Server $vmHost -Credential $credentials

    # Enter maintenance mode on the ESXi host
    $esxi = Get-VMHost -Name $vmHost
    if ($esxi.ConnectionState -ne "Maintenance") {
        # Place the host in maintenance mode
        Set-VMHost -VMHost $vmHost -State 'Maintenance' -Confirm:$false
    }

    # Restore Host Configuration from backup
    Set-VMHostFirmware -VMHost $vmHost -Restore -SourcePath $restoreConfig -HostUser $credentials.username -HostPassword $credentials.GetNetworkCredential().Password -ErrorAction SilentlyContinue

    Write-Host "`nRestore task completed successfully." -ForegroundColor Green
} finally {
    # Remove any new variables
    Get-Variable | Where-Object Name -NotIn $existingVariables.Name | Remove-Variable -ErrorAction SilentlyContinue
}
