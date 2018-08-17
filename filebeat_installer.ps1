################################################
#
# Filebeat installation script
# - Downloads Filebeat from Elastic
# - Downloads CA and filebeat.yml from a given location
# - Changes settings in filebeat.yml based on enviroment variables
#
# Written by Jesper Green
#
###############################################

### Setting all variables

$installFolder = $env:ProgramFiles + "\filebeat"
$oldInstallFolder = $env:ProgramFiles + "\filebeat_old"
$filebeatVersion = "filebeat-6.2.4-windows-x86_64"
$beat_down = "https://artifacts.elastic.co/downloads/beats/filebeat/"+$filebeatVersion+".zip"
$zip = $env:TEMP+$filebeatVersion+".zip"
$tmp_zip_folder = $env:TEMP+"\filebeat"
$extractedFiles = $tmp_zip_folder+"\"+$filebeatVersion+"\*.*"
$ymlFile = $installFolder+"\filebeat.yml"
$tmpYmlFile = $env:TEMP+"\filebeat.yml"
$ymlDownload = "https://path_to_default_filebeat_yml"
$caDownload = "https://path_to_ca"
$tmpCaFile = $env:TEMP+"\ca.crt"
$caFile = $installFolder+"\ca.crt"

### Stop and delete Filebeat service
if (Get-Service filebeat -ErrorAction SilentlyContinue) {
  $service = Get-WmiObject -Class Win32_Service -Filter "name='filebeat'"
  $service.StopService()
  Start-Sleep -s 1
  $service.delete()
}

#Wait for service to release files and folders
Start-Sleep -s 3

### Remove previous installation but keep a copy
if((Test-Path -Path $installFolder)){
    if((Test-Path -Path $oldInstallFolder)){
	Remove-Item -Path $oldInstallFolder -recurse
	}
	Rename-Item -Path $installFolder -NewName $oldInstallFolder
} 

# Create new installation folder
New-Item -ItemType directory -Path $installFolder

### Download Filebeat installation from Elastic.co. To download different version, change variable $filebeatVersion
# Begin by cleaning temp-folder from previous installations
if((Test-Path -Path $tmp_zip_folder)){
    Remove-Item -Path $tmp_zip_folder -recurse
	}

# Download file
(New-Object System.Net.WebClient).DownloadFile($beat_down, $zip)

# Unzip files to filebeat folder
Add-Type -assembly "system.io.compression.filesystem"
[io.compression.zipfile]::ExtractToDirectory($zip, $tmp_zip_folder)

# Copy extracted files to installation folder
Copy-Item $extractedFiles -Destination $installFolder -Recurse

### Download the yml file (to change source, edit var $ymlDownload)
(New-Object System.Net.WebClient).DownloadFile($ymlDownload, $tmpYmlFile)
Copy-Item $tmpYymlFile -Destination $ymlFile -Force

### Download the CA-cert (to change source, edit $caDownload)
(New-Object System.Net.WebClient).DownloadFile($caDownload, $tmpCaFile)
Copy-Item $tmpCaFile -Destination $caFile -Force

### Change Logstash output based on userdnsdomain
$Settings = ""
if ($env:USERDNSDOMAIN -like dev1.enviroment.com" ) {
   $Settings = "logstash1.dev1.enviroment.com:5044`",`"logstash2.dev1.enviroment.com:5044"
}
if ($env:USERDNSDOMAIN -like "dev2.enviroment.com" ) {
   $Settings = "logstash.dev2.enviroment.com:5044"
}
if ($env:USERDNSDOMAIN -like "dev3.enviroment.com" ) {
   $Settings = "logstash.dev3.enviroment.com:5044"
}
if ($env:USERDNSDOMAIN -like "dev41.enviroment.com" -or ($env:USERDNSDOMAIN -like "dev42.enviroment.com") -or ($env:USERDNSDOMAIN -like "dev43.enviroment.com")) {
   $Settings = "logstash.dev4.enviroment.com:5044"
}
if ($env:USERDNSDOMAIN -like "dev51.enviroment.com" -or ($env:USERDNSDOMAIN -like "dev52.enviroment.com") -or ($env:USERDNSDOMAIN -like "dev53.enviroment.com")) {
   $Settings = "logstash.dev5.enviroment.com:5044"
}
If (!($Settings)) {
    $Settings = "logstash1.prod.enviroment.com:5044`",`"logstash2.prod.enviroment.com:5044"
}

(Get-Content $ymlFile).Replace("XXXXXX",$Settings) | Set-Content $ymlFile -ErrorAction SilentlyContinue

### Create new service
New-Service -name filebeat `
  -displayName filebeat `
  -binaryPathName "`"$installFolder\\filebeat.exe`" -c `"$installFolder\\filebeat.yml`" -path.home `"$installFolder`" -path.data `"C:\\ProgramData\\filebeat`""

Start-Sleep -s 3

### Start service
if (Get-Service filebeat -ErrorAction SilentlyContinue) {
  $newService = Get-WmiObject -Class Win32_Service -Filter "name='filebeat'"
  $newService.StartService()
}