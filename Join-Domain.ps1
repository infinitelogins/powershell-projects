
# Env variables
$env:newName = 'EXAMPLE-WS01'
$env:joinDomain = 'True'
$env:domainName = 'ad.domain.local'
$env:daUser = 'domain\administrator'
$env:daPassword = 'Password123'
$env:dnsServer = '192.168.1.0'


# Script variables
$dnsEntry = $env:dnsServer + ',8.8.8.8'

# Start notetaking
$outputNotes = "`n`n-- STEPS PERFORMED--`n"
$outputNotes += "• Configured computer via PowerShell Script:`n"

# Update DNS Settings
$interfaces = get-dnsclient | Where {($_.InterfaceAlias -like "Ethernet*" -or $_.InterfaceAlias -like "Wi-FI")}
Set-DnsClientServerAddress -InterfaceAlias $interfaces.InterfaceAlias -ServerAddresses $dnsEntry
$outputNotes += "Updated DNS settings on' $interfaces.InterfaceAlias 'to' $dnsEntry`n"


# Join to domain
If ($env:joinDomain -eq 'True')
	{
	 try {
		$pass = ConvertTo-SecureString $env:daPassword -AsPlainText -Force
		$cred = New-Object System.Management.Automation.PSCredential -ArgumentList $env:daUser,$pass
		Add-Computer -DomainName $env:domainName -NewName $env:newName -Credential $cred -Force
		$outputNotes += "Renamed computer to' $env:newName`n"
		$outputNotes += "Joined machine to domain:' $env:domainName`n"
		 }
	catch {
		$error[0]|format-list -force  #print more detail reason for failure   
		  }
	}
	
# Print out notes
$outputNotes

# Reboot machine
Restart-Computer -Force
