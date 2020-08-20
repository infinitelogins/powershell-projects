
# Input Variables Related to Office 365
$env:o365AdminUser = 'admin@example.com'
$env:o365AdminPass = "Password123"
$env:firstName = "Testing"
$env:lastName = "User"
$env:o365UserEmail = "testinguser@dundermifflin.com"
$env:groupMember = 'False'
$env:o365LicenseType = 'Business Basic'

# Input Variables Related to IT Glue
$env:APIKey =  "<IT Glue API Key Goes Here>"
$env:userTitle = "Manager of Management"
$env:userStartDate = "Aug 19th, 2020"


# Generate Random Symbol for Password
function Get-RandomCharacters($length, $characters) {
    $random = 1..$length | ForEach-Object { Get-Random -Maximum $characters.length }
    $private:ofs=""
    return [String]$characters[$random]
}
 

# SCRIPT VARIABLES
$APIEndpoint = "https://api.itglue.com"
$o365DisplayName = $env:FirstName + ' ' + $env:LastName
$o365AdminPassEnc = ConvertTo-SecureString $env:o365AdminPass -AsPlainText -Force
$UserCredential = New-Object System.Management.Automation.PSCredential ($env:o365AdminUser, $o365AdminPassEnc)
$contactNotes = "Start Date: " + $env:userStartDate
$userDomain = $env:o365UserEmail.split('@')[1]
$orgID = "No value"
$clientID = "No value"
$randomSymbol += Get-RandomCharacters -length 1 -characters '!$%=?@#+'


# Start notetaking
$outputNotes = "`n`n"
$outputNotes += "-----------------------------" + "`n"
$outputNotes += "`n"
$outputNotes += "-- STEPS PERFORMED--`n"
$outputNotes += "* Created a new user via PowerShell Script: `n"


# Check email to identify client
if ($userDomain -eq "exampleA.com" -or $userDomain -eq "exampleA.net" ) {
	$orgID = "<Insert IT Glue ID>"
	$clientID = "Example A"
	write-host "Configured IT Glue Organization: " $clientID
	}
if ($userDomain -eq "exampleB.com" ) {
	$orgID = "<Insert IT Glue ID>"
	$clientID = "Example B"
	write-host "Configured IT Glue Organization: " $clientID
	}
# Additional clients get added here.


if ($orgID -eq "No value" ) {
	write-host "The script does not recongize that domain and has exited."
	Exit
	}


# CONNECTING TO MICROSOFT ONLINE
Import-Module MSOnline
Connect-MsolService -Credential $UserCredential

# CHECK FOR AVAILABLE LICENSE
if ($env:o365LicenseType -eq 'Business Basic' ) {
	$o365LicenseInfo = Get-MsolAccountSku | Where-Object {$_.AccountSkuId -like "*BUSINESS_ESSENTIALS*"} 
	$liceneCountAvail = $o365LicenseInfo.ConsumedUnits - $o365LicenseInfo.ActiveUnits

	If ($liceneCountAvail -ne 0)  {
		$assignedLicense = $o365LicenseInfo.AccountSkuId
		'Business Basic license will be assigned.'
	}else {
		'There are no Business Basic licenses available'
		Exit
	}
}

if ($env:o365LicenseType -eq 'Business Standard' ) {
	$o365LicenseInfo = Get-MsolAccountSku | Where-Object {$_.AccountSkuId -like "*BUSINESS_PREMIUM*"} 
	$liceneCountAvail = $o365LicenseInfo.ConsumedUnits - $o365LicenseInfo.ActiveUnits

	If ($liceneCountAvail -ne 0)  {
		$assignedLicense = $o365LicenseInfo.AccountSkuId
		'Business Standard license will be assigned.'
	}else {
		'There are no Business Standard licenses available'
		Exit
	}
}

if ($env:o365LicenseType -eq 'Business E3' ) {
	$o365LicenseInfo = Get-MsolAccountSku | Where-Object {$_.AccountSkuId -like "*ENTERPRISEPACK*"} 
	$liceneCountAvail = $o365LicenseInfo.ConsumedUnits - $o365LicenseInfo.ActiveUnits

	If ($liceneCountAvail -ne 0)  {
		$assignedLicense = $o365LicenseInfo.AccountSkuId
		'Business E3 license will be assigned.'
	}else {
		'There are no Business E3 licenses available'
		Exit
	}
}


# CREATE THE USER
$output = New-MsolUser -DisplayName $o365DisplayName -FirstName $env:FirstName -LastName $env:LastName -UserPrincipalName $env:o365UserEmail -UsageLocation US -LicenseAssignment $assignedLicense -ForceChangePassword $false
$o365UserPass = $randomSymbol + $output.password 
$outputNotes += "- Created user in Office 365: " + $env:o365UserEmail + "`n"
$outputNotes += "- Assigned license in Office 365: " + $assignedLicense + "`n"

# SET THE PASSWORD
Set-MsolUserPassword -UserPrincipalName $env:o365UserEmail -NewPassword $o365UserPass -ForceChangePassword $false


#Grabbing ITGlue Module and installing.
If(Get-Module -ListAvailable -Name "ITGlueAPI") {Import-module ITGlueAPI} Else { install-module ITGlueAPI -Force; import-module ITGlueAPI}

#Settings IT-Glue logon information
Add-ITGlueBaseURI -base_uri $APIEndpoint
Add-ITGlueAPIKey $env:APIKey
  
# Get info on the contact
$itgContact = Get-ITGlueContacts -organization_id $orgID -filter_primary_email $env:o365UserEmail
$itgResourceID = $itgContact.data.id

# Check if contact exists and create if missing
if (!$itgResourceID) { 
    write-host "Contact does not exist in IT Glue. Creating one now." -foregroundColor green
		$itgContactEntry = 
    @{
        type = 'contacts'
        attributes = @{
            "first-name" = $env:firstName
            "last-name" = $env:lastName
			"title" = $env:userTitle
			"contact-type-name" = "End User"
			"notes" = $contactNotes
			"contact-emails" = @(
				@{
					primary = "True"
					value = $env:o365UserEmail
					"label-name" = "Work"
				}
			)
        }
    }
	$itgContactEntry.attributes.add('organization-id', $orgID)
    $output = New-ITGlueContacts -Data $itgContactEntry
	$itgResourceID = $output.data.id
	$outputNotes += "- Created new contact in IT Glue: " + $output.data.attributes.name + "`n"
}

# Configure and create the embedded password	
$NewPWEntry = 
@{
	type          = 'passwords'
	attributes    = @{
		name = "O365"
		username = $env:o365UserEmail
		password = $o365UserPass
		url = "https://login.microsoftonline.com/"
		notes = "Account used for email and Office 365 apps"
	}
}

$NewPWEntry.attributes.add('organization-id', $orgID)
$NewPWEntry.attributes.add('resource-id', $itgResourceID)
$NewPWEntry.attributes.add('resource-type', "Contact")
New-ITGluePasswords -Data $NewPWEntry 
$outputNotes += "- Documented credentials for Office 365 as an embedded password." + "`n"


# CONNECT TO EXCHANGE ONLINE
$Session2 = New-PSSession –ConfigurationName Microsoft.Exchange –ConnectionUri https://outlook.office365.com/powershell-liveid/ -Credential $UserCredential –Authentication Basic -AllowRedirection
Import-PSSession $Session2

# WAIT FOR MAILBOX TO BE AVAILABLE
Do {
  Start-Sleep -seconds 10
  $mailbox = Get-Mailbox -Identity $env:o365UserEmail
  write-host "." -nonewline
}While ($mailbox -eq $null)

# ADJUST CLUTTER  FOCUSEDINBOX  AUDITLOGS
Get-Mailbox -Identity $env:o365UserEmail | Set-Clutter -Enable $false
Get-Mailbox -Identity $env:o365UserEmail | Set-FocusedInbox -FocusedInboxOn $false
Get-Mailbox -ResultSize Unlimited -Identity $env:o365UserEmail | Set-Mailbox -AuditEnabled $true
Get-Mailbox -ResultSize Unlimited -Identity $env:o365UserEmail | Set-Mailbox -AuditOwner @{Add="MailboxLogin","HardDelete","SoftDelete"}
$outputNotes += "- Disabled clutter, focused inbox, and enabled mailbox login auditing in O365." + "`n"

# ADD USER TO GROUPS
  If ($env:groupMember -eq 'True')  {
  Add-DistributionGroupMember -Identity "<Insert Group Name>" -Member $env:o365UserEmail
  $outputNotes += "- Added user to the group" + "`n"
  }

# DISCONNECT SESSIONS
Remove-PSSession $Session2


# Print out notes. 
$outputNotes += "`n"
$outputNotes += "-----------------------------" + "`n"
$outputNotes += "`n"
$outputNotes



