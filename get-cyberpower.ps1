# Get-Cyberpower
# PRTG Powershell plugin to pull power usage, and other details from some Cyberpower UPS devices 
# Written by: Will McVicker
# Email will.mcvicker@outlook.com
# 
# Instructions
#
# add as custom exe/script advanced to PRTG
# Under paremeters, add -ipaddress with the IP, -port for port, -user for username, and -pass for password
#
# By default, it will assume 127.0.0.1 as IP address, on the standard port of 3052, with admin/admin as user/pass. 
#
#
# Requirement:
# Needs the cyberpower business agent installed.
#
# Changelog:
#
# 2016-07-25 1.0.0
# Initial Release

# Commandline Parameters for IP/port/user/pass


param(
[string]$ipAddress = "127.0.0.1",
[string]$port = "3052",
[string]$user = "admin",
[string]$pass = "admin"
)
$prtgXML = ""

# Verification that the IP is up
if(Test-Connection -BufferSize 32 -Count 1 -ComputerName $ipAddress -Quiet)
{

### stuff to login. Seems to need a JS with the current UNIX time
$loginURL = "http://$ipAddress`:$port/agent/index"
$powerURL = "http://$ipAddress`:$port/agent/ppbe.js/init_status.js?$unixtime"
$unixtime = [DateTimeOffset]::Now.ToUnixTimeSeconds()

$login = Invoke-WebRequest $loginurl -SessionVariable cyberpower
$loginForm = $login.forms

$loginform.Fields["value(username)"] = $user
$loginform.Fields["value(password)"] = $pass
$loginform.Fields["value(action)"] = "Login"
$loginform.Fields["value(persistentCookie)"] = "true"
$loginform.Fields["value(button)"] = "Login"

# Login

$null = Invoke-WebRequest $loginURL -WebSession $cyberpower -body $loginForm.fields -Method post

# grabs JSON

$powerJSON = invoke-webrequest $powerURL -WebSession $cyberpower 

# cleans up text so it works as JSON

$powerJSON = $powerJSON -replace "var ppbeJsObj=" -replace ";"

# parses JSON

$powerOBJ = $powerJSON | ConvertFrom-Json

# grabs the stuff we need from the JSON

$outputVoltage = $powerOBJ.status.output.voltage
$outputLoad = $powerOBJ.status.output.load
$outputWatt = $powerOBJ.status.output.watt
$outputWarning = $powerOBJ.status.output.outputLoadWarning
$outputState = $powerOBJ.status.output.state

$inputVoltage = $powerOBJ.status.utility.voltage
$inputState = $powerOBJ.status.utility.state

$batteryVoltage = $powerOBJ.status.battery.voltage
$batteryCapacity = $powerOBJ.status.battery.capacity
$batteryStatus = $powerOBJ.status.battery.state
$batteryruntime = ($powerOBJ.status.battery.runtimeHour * 60) + $powerOBJ.status.battery.runtimeMinute

# Builds the PRTG xml


$prtgXML += "<result>"
$prtgXML += "<channel>Input Voltage</channel>"
$prtgXML += "<value>$inputvoltage</value>"
$prtgXML += "<unit>Custom</unit>"
$prtgXML += "<float>1</float>"
$prtgXML += "<customunit>V</custom>"
$prtgXML += "</result>"

$prtgXML += "<result>"
$prtgXML += "<channel>Input Status</channel>"
$prtgXML += "<LimitMinError>0</LimitMinError>"

if($inputstate -ne "Normal")
{
$prtgXML += "<value>0</value>"
}
else
{
$prtgXML += "<value>1</value>"
}
$prtgXML += "</result>"

# Output

$prtgXML += "<result>"
$prtgXML += "<channel>Output Voltage</channel>"
$prtgXML += "<value>$outputvoltage</value>"
$prtgXML += "<unit>Custom</unit>"
$prtgXML += "<float>1</float>"
$prtgXML += "<customunit>V</custom>"
$prtgXML += "</result>"

$prtgXML += "<result>"
$prtgXML += "<channel>Output Load</channel>"
$prtgXML += "<value>$outputload</value>"
$prtgXML += "<unit>Percent</unit>"
$prtgXML += "</result>"

$prtgXML += "<result>"
$prtgXML += "<channel>Output Watt</channel>"
$prtgXML += "<value>$outputwatt</value>"
$prtgXML += "<unit>Custom</unit>"
$prtgXML += "<customunit>W</custom>"
$prtgXML += "</result>"

$prtgXML += "<result>"
$prtgXML += "<channel>Output Status</channel>"
$prtgXML += "<LimitMinError>0</LimitMinError>"

if($Outputstate -ne "Normal")
{
$prtgXML += "<value>0</value>"
}
else
{
$prtgXML += "<value>1</value>"
}
$prtgXML += "</result>"

# Battery

$prtgXML += "<result>"
$prtgXML += "<channel>Battery Voltage</channel>"
$prtgXML += "<value>$batteryvoltage</value>"
$prtgXML += "<unit>Custom</unit>"
$prtgXML += "<float>1</float>"
$prtgXML += "<customunit>V</custom>"
$prtgXML += "</result>"

$prtgXML += "<result>"
$prtgXML += "<channel>Battery Capacity</channel>"
$prtgXML += "<value>$batterycapacity</value>"
$prtgXML += "<unit>Percent</unit>"
$prtgXML += "</result>"

$prtgXML += "<result>"
$prtgXML += "<channel>Battery Runtime</channel>"
$prtgXML += "<value>$batteryruntime</value>"
$prtgXML += "<unit>Custom</unit>"
$prtgXML += "<customunit>min</custom>"
$prtgXML += "</result>"

$prtgXML += "<result>"
$prtgXML += "<channel>Battery Status</channel>"
$prtgXML += "<LimitMinError>0</LimitMinError>"

if($batteryStatus -ne "Normal, Fully Charged")
{
$prtgXML += "<value>0</value>"
}
else
{
$prtgXML += "<value>1</value>"
}
$prtgXML += "</result>"
}
else
{
$prtgXML += "<error>2</error>"
$prtgXML += "<text>System is not responding to ping</text>"
}
echo "<PRTG>"
$prtgXML
echo "</prtg>"