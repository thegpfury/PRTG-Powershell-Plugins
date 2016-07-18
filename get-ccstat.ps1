# Get-CCSTAT
# PRTG Powershell plugin to get status of Cablecard and tuner resolver in HDHomeRun PRime 
# Written by: Will McVicker
# Email will.mcvicker@outlook.com
# 
# Instructions
#
# add as custom exe/script advanced to PRTG
# Under paremeters, add -ipaddress with the IP
#
# Example
#
# -ipaddress 192.168.1.25 
#
# Requirement:
# Needs CURL exe to be in C:\curl. That path can be easily updated in script. 
#
# Changelog:
#
# 2016-07-18 1.0.0
# Initial Release

# Commandline Parameters for IP


param(
[string]$ipAddress = "127.0.0.1"
)

function get-status($ip)
{

# Using CURL since invoke-webhost has issues with UTF-8 apparently

$status = C:\curl\curl.exe + -s "http://$ip" | out-string

[regex]$regex = "(?s)<table>.*?</table>"
$tables = $regex.matches($status).groups.value
ForEach($String in $tables){
    $table = $string.split("`n")
    $CurTable = @()
    $CurTable += ($table[1] -replace "</td><td>",",") -replace "</?(td|tr|)>"
    $CurTable += $table[2..($table.count-2)]|ForEach{$_ -replace "</TD><TD>","," -replace "</?T(D|R)>"}
}

$statCA = (($CurTable[0]) -split ",")
$statOOB = (($CurTable[1]) -split ",")
$statCV = (($CurTable[2]) -split ",")
$statTR = (($CurTable[3]) -split ",")

return $statCA, $statOOB, $statCV, $statTR
}

# Quick test to verify that the connection is up

if(Test-Connection -BufferSize 32 -Count 1 -ComputerName $ipAddress -Quiet)
{
echo "<prtg>"

# This block will check on Cablecard CA/OOB/CV status

$statStatus = get-status($ipAddress)
if($statStatus[0][1] -notmatch "success" -or $statStatus[1][1] -notmatch "success" -or $statStatus[2][1] -notmatch "success")
{
echo "<error>1</error>"
echo "<text>Cable Card Issue</text>"
}
else
{
echo "<result>"
echo "<channel>CableCard</channel>"
echo "<value>1</value>"
echo "</result>"
}

# This block verifies status of Tuning Resolver

if($statStatus[3][0] -eq "")
{
echo "<error>1</error>"
echo "<text>Tuner Resolver not Found</text>"
}
elseif($statStatus[3][1] -match "unknown")
{
echo "<error>1</error>"
echo "<text>Tuner Resolver Unknown</text>"
}
elseif($statStatus[3][1] -match "initializing")
{
echo "<error>1</error>"
echo "<text>Tuner Resolver Initializing</text>"
}
else
{
echo "<result>"
echo "<channel>Tuning Resolver</channel>"
echo "<value>1</value>"
echo "</result>"
}
echo "</prtg>"
}

else
{
echo "<prtg>"
echo "<error>2</error>"
echo "<text>Tuner is not responding to ping</text>"
echo "</prtg>"
}