# Get-Pihole
# PRTG Powershell plugin to pull basic counts from pihole. No login needed. 
# Written by: Will McVicker
# Email will.mcvicker@furytech.net
# 
# Instructions
#
# add as custom exe/script advanced to PRTG
# Under paremeters, add -url with the IP
#
# By default, it will assume 127.0.0.1 as IP
# which, obviously, won't work
#

#
# Changelog:
#
# 2020-09-17 1.0.0
# Initial Release

# Commandline Parameters for IP/port/user/pass


param(
[string]$url = "127.0.0.1"
)
$prtgXML = ""

# Verification that the IP is up
if(Test-Connection -BufferSize 32 -Count 1 -ComputerName $url -Quiet)
{
$site = Invoke-WebRequest "$url/admin/api.php?summaryRaw" -usebasicparsing
$site = $site | convertfrom-json

$totalqueries = $site.dns_queries_today
$queriesblocked = $site.ads_blocked_today
$percentblocked = ([math]::round(($queriesblocked / $totalqueries),3)) * 100
$domainsblocked = $site.domains_being_blocked


# Builds the PRTG xml


$prtgXML += "<result>"
$prtgXML += "<channel>Total Queries Today</channel>"
$prtgXML += "<value>$totalqueries</value>"
$prtgXML += "<unit>Custom</unit>"
$prtgXML += "<customunit>Queries</customunit>"
# $prtgXML += "<float>0</float>"
$prtgXML += "</result>"

$prtgXML += "<result>"
$prtgXML += "<channel>Queries Blocked Today</channel>"
$prtgXML += "<value>$queriesblocked</value>"
$prtgXML += "<unit>Custom</unit>"
$prtgXML += "<customunit>Queries</customunit>"
# $prtgXML += "<float>0</float>"
$prtgXML += "</result>"

$prtgXML += "<result>"
$prtgXML += "<channel>Percent Blocked Today</channel>"
$prtgXML += "<value>$percentblocked</value>"
$prtgXML += "<unit>Percent</unit>"
$prtgXML += "<float>1</float>"
$prtgXML += "</result>"

$prtgXML += "<result>"
$prtgXML += "<channel>Domains on Blocklist</channel>"
$prtgXML += "<value>$domainsblocked</value>"
$prtgXML += "<unit>Custom</unit>"
$prtgXML += "<customunit>Blocked</customunit>"
# $prtgXML += "<float>0</float>"
$prtgXML += "</result>"
}
else
{
$prtgXML += "<error>2</error>"
$prtgXML += "<text>System is not responding to ping</text>"
}
echo "<PRTG>"
$prtgXML
echo "</PRTG>"
