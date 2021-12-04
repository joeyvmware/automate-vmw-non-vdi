# https://4sysops.com/archives/powershell-remoting-over-https-with-a-self-signed-ssl-certificate/

# Run this script on Remote/Template VMs to enable Windows Remote Management so we can connect to from a domain attached Powershell host where these templates should not be domain attached per best practices.

$Cert = New-SelfSignedCertificate -CertstoreLocation Cert:\LocalMachine\My -DnsName $env:COMPUTERNAME
mkdir c:\temp
Export-Certificate -Cert $Cert -FilePath C:\temp\$env:COMPUTERNAME
Enable-PSRemoting -SkipNetworkProfileCheck -Force
dir wsman:\localhost\listener
Get-ChildItem WSMan:\Localhost\listener | Where -Property Keys -eq "Transport=HTTP" | Remove-Item -Recurse
Remove-Item -Path WSMan:\Localhost\listener\listener* -Recurse
New-Item -Path WSMan:\LocalHost\Listener -Transport HTTPS -Address * -CertificateThumbPrint $Cert.Thumbprint –Force
New-NetFirewallRule -DisplayName "Windows Remote Management (HTTPS-In)" -Name "Windows Remote Management (HTTPS-In)" -Profile Any -LocalPort 5986 -Protocol TCP
Set-Item WSMan:\localhost\Service\EnableCompatibilityHttpsListener -Value true
Set-NetConnectionProfile -NetworkCategory Private
Disable-NetFirewallRule -DisplayName "Windows Remote Management (HTTP-In)"

# Below commands should be ran on the Client/Host Management that will run all the Powershell scripts that will update these templates.  Below these are my three templates so change to your environment.  
# This is how we will protect the environment by only a host with these template server certs can connect via Powershell.
# Import-Certificate -Filepath "<driveletter>:\<path>\DESKTOP-KPQJPMS" -CertStoreLocation "Cert:\LocalMachine\Root"
# Import-Certificate -Filepath "<driveletter>:\<path>\WIN-1DBMFPA2ND2" -CertStoreLocation "Cert:\LocalMachine\Root"
# Import-Certificate -Filepath "<driveletter>:\<path>\WIN-93OI9TU9IFP" -CertStoreLocation "Cert:\LocalMachine\Root"
