# RELATED POST OVER AT https://infinitelogins.com/2020/09/03/importing-email-addresses-domains-to-blacklist-in-office-365-using-powershell/

# USE THIS TO IMPORT DOMAINS
$domains = "C:\temp\domains.txt"

$count = 1
foreach ($content in ($total = get-content $domains)){
	$totalcount = $total.count
	Set-HostedContentFilterPolicy -Identity Default –BlockedSenderDomains @{add=$content}
	write-host "Added $count entries of $totalcount : $content"
	$count += 1
}


# USE THIS TO IMPORT EMAIL ADDRESSES
$emails = "C:\temp\emails.txt"

$count = 1
foreach ($content in ($total = get-content $emails)){
	$totalcount = $total.count
	Set-HostedContentFilterPolicy -Identity Default –BlockedSenders @{add=$content}
	write-host "Added $count entries of $totalcount : $content"
	$count += 1
}

