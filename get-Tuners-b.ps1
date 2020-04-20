# Get-Tuners
# PRTG Powershell plugin to pull signal strength/quality from SiliconDust HDHomeRun Tuners. Supports both Dual and Prime. 
# Written by: Will McVicker
# Email will.mcvicker@outlook.com
# 
# Instructions
#
# add as custom exe/script advanced to PRTG
# Under paremeters, add -ipaddress with the IP, -numtuners with number of tuners, and -prime 1/0 for wheter or not it is a cablecard tuner
#
# By default, it will assume a cablecard triple tuner (HDHomeRunPrime). For those, you'll just need to have the -ipaddress part
#
# Example for HDHome Run Dual
# 
# -ipaddress 192.168.1.25 -numtuners 2 -prime 0
#
# Requirement:
# Needs CURL exe to be in C:\curl. That path can be easily updated in script. 
#
# Changelog:
#
# 2016-07-18 1.0.0
# Initial Release
# 2020-04-20 1.0.1
# Updated for HDHomeRun Connect as table values were mis-matched

# Commandline Parameters for IP and what kind of tuner

param(
[string]$ipAddress = "127.0.0.1",
[int]$numTuners = 3,
[boolean]$prime=1
)

# This function checks on the status of the cable card
function get-cablecard($ip)
{

# Using CURL since invoke-webhost has issues with UTF-8 apparently
$cablecard = C:\curl\curl.exe + -s "http://$ip/cc.html" | out-string

[regex]$regex = "(?s)<table.*?</table>"
$tables = $regex.matches($cablecard).groups.value
ForEach($String in $tables){
    $table = $string.split("`n")
    $CurTable = @()
    $CurTable += $table[1..($table.count-2)]|ForEach{$_ -replace "</TD><TD>","," -replace "</?T(D|R)>"}
}

$ccStrength= (($CurTable[7]) -split ",") -split "%"
$ccQuality = (($CurTable[8]) -split ",") -split "%"

return $ccStrength, $ccQuality
}

# This function grabs details on the current tuner status
function get-tuner($ip,[int]$tun)
{
$counter = 0
$tunerarray = @()
while($counter -lt $tun)
{

# Curl, because ditto
$tuner = C:\curl\curl.exe + -s "http://$ip/tuners.html?page=tuner$counter" | out-string

[regex]$regex = "(?s)<table.*?</table>"
$tables = $regex.matches($tuner).groups.value
ForEach($String in $tables){
    $table = $string.split("`n")
    $CurTable = @()
    $CurTable += $table[1..($table.count-2)]|ForEach{$_ -replace "</TD><TD>","," -replace "</?T(D|R)>" -replace "none", "0"}
}
$tunerStrength = (($CurTable[5]) -split ",") -split "%"
$tunerQuality = (($CurTable[6]) -split ",") -split "%"
$tunerRate = (($CurTable[9]) -split ",") -split " "

$tunerArray += , ($counter, $tunerStrength[1], $tunerQuality[1], $tunerRate[2])

$counter++
}
return $tunerArray
}

# Just a quick connection test to make sure it's pingable
if(Test-Connection -BufferSize 32 -Count 1 -ComputerName $ipAddress -Quiet)
{

echo "<prtg>"
if($prime -eq 1)
{

# This block grabs cable card strength/quality

$ccdetails = get-cablecard($ipaddress)
$cablecarddetails = new-object psobject
add-member -inputobject $cablecarddetails -MemberType NoteProperty -name SignalStrength -value $ccdetails[0][1]
add-member -inputobject $cablecarddetails -MemberType NoteProperty -name SignalQuality -value $ccdetails[1][1]

echo "<result>"
echo "<channel>CC Signal Strength</channel>"
echo "<unit>Percent</unit>"
echo "<value>"$cablecarddetails.signalstrength"</value>"
echo "</result>"

echo "<result>"
echo "<channel>CC Signal Quality</channel>"
echo "<unit>Percent</unit>"
echo "<value>"$cablecarddetails.signalquality"</value>"
echo "</result>"
}

# This grabs tuner information

$tunerdetails = new-object psobject
$tdetails = get-tuner $ipaddress $numTuners



add-member -inputobject $tunerdetails -MemberType NoteProperty -name Tuner1SignalStrength -value $tdetails[0][1]
add-member -inputobject $tunerdetails -MemberType NoteProperty -name Tuner1SignalQuality -value $tdetails[0][2]
add-member -inputobject $tunerdetails -MemberType NoteProperty -name Tuner1SignalRate -value $tdetails[0][3]
echo "<result>"
echo "<channel>Tuner 1 Signal Strength</channel>"
echo "<unit>Percent</unit>"
echo "<value>"$tunerdetails.Tuner1SignalStrength"</value>"
echo "</result>"

echo "<result>"
echo "<channel>Tuner 1 Signal Quality</channel>"
echo "<unit>Percent</unit>"
echo "<value>"$tunerdetails.Tuner1SignalQuality"</value>"
echo "</result>"

echo "<result>"
echo "<channel>Tuner 1 Rate</channel>"
echo "<value>"$tunerdetails.Tuner1SignalRate"</value>"
echo "<unit>SpeedNet</unit>"
echo "<speedsize>Megabit</speedsize>"
echo "<float>1</float>"
echo "</result>"


if($numTuners -ge 2)
{
add-member -inputobject $tunerdetails -MemberType NoteProperty -name Tuner2SignalStrength -value $tdetails[1][1]
add-member -inputobject $tunerdetails -MemberType NoteProperty -name Tuner2SignalQuality -value $tdetails[1][2]
add-member -inputobject $tunerdetails -MemberType NoteProperty -name Tuner2SignalRate -value $tdetails[1][3]

echo "<result>"
echo "<channel>Tuner 2 Signal Strength</channel>"
echo "<unit>Percent</unit>"
echo "<value>"$tunerdetails.Tuner2SignalStrength"</value>"
echo "</result>"

echo "<result>"
echo "<channel>Tuner 2 Signal Quality</channel>"
echo "<unit>Percent</unit>"
echo "<value>"$tunerdetails.Tuner2SignalQuality"</value>"
echo "</result>"

echo "<result>"
echo "<channel>Tuner 2 Rate</channel>"
echo "<value>"$tunerdetails.Tuner2SignalRate"</value>"
echo "<float>1</float>"
echo "<unit>SpeedNet</unit>"
echo "<speedsize>Megabit</speedsize>"
echo "</result>"
}

if($numTuners -ge 3)
{
add-member -inputobject $tunerdetails -MemberType NoteProperty -name Tuner3SignalStrength -value $tdetails[2][1]
add-member -inputobject $tunerdetails -MemberType NoteProperty -name Tuner3SignalQuality -value $tdetails[2][2]
add-member -inputobject $tunerdetails -MemberType NoteProperty -name Tuner3SignalRate -value $tdetails[2][3]



echo "<result>"
echo "<channel>Tuner 3 Signal Strength</channel>"
echo "<unit>Percent</unit>"
echo "<value>"$tunerdetails.Tuner3SignalStrength"</value>"
echo "</result>"

echo "<result>"
echo "<channel>Tuner 3 Signal Quality</channel>"
echo "<unit>Percent</unit>"
echo "<value>"$tunerdetails.Tuner3SignalQuality"</value>"
echo "</result>"

echo "<result>"
echo "<channel>Tuner 3 Rate</channel>"
echo "<value>"$tunerdetails.Tuner3SignalRate"</value>"
echo "<float>1</float>"
echo "<unit>SpeedNet</unit>"
echo "<speedsize>Megabit</speedsize>"
echo "</result>"
}


echo "</prtg>"

}

# Return connection error if Tuner isn't pingable
else
{
echo "<prtg>"
echo "<error>2</error>"
echo "<text>Tuner is not responding to ping</text>"
echo "</prtg>"
}