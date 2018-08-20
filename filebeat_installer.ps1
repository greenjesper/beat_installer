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

#$VerbosePreference="Continue"

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
$ymlDownload = "https://path.to.yml/filebeat.yml"
$caDownload = "https://oath.to.ca/ca.crt"
$tmpCaFile = $env:TEMP+"\ca.crt"
$caFile = $installFolder+"\ca.crt"
$sevenzip_installer = "http://www.7-zip.org/a/7z1801-x64.msi"
$sevenzip_temp = $env:TEMP+"\7zip_installer.msi"

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

if ($PSVersionTable.PSVersion.Major -le 3) {
 Write-Output("Old Powershell, must install 7-zip")
 if (!(Test-Path "C:\Program Files\7-Zip")) {
	Write-Output(" Getting 7-Zip")
    (New-Object System.Net.WebClient).DownloadFile($sevenzip_installer, $sevenzip_temp)
    msiexec.exe /i "C:\Windows\Temp\7zip_installer.msi" /qb
    Start-Sleep -s 20
    Write-Output("7-zip installed...unzipping file...")
    Start-Process -Wait -FilePath "C:\Program Files\7-Zip\7z.exe" -ArgumentList "x `"$zip`"  -o`"$tmp_zip_folder`""
    Write-Output("File unzipped using 7-zip")
                                                                    
}
}
else {
Write-Output("New Powershell :)")
# Unzip files using bulilt in functions (on Powershell 4 and newer)to filebeat folder
Write-Output("Unzipping file...")
Add-Type -assembly "system.io.compression.filesystem"
[io.compression.zipfile]::ExtractToDirectory($zip, $tmp_zip_folder)
Write-Output("File unzipped")
}


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
if ($env:USERDNSDOMAIN -like "dev1.enviroment.com" ) {
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
Write-Output("Create service")
New-Service -name filebeat `
  -displayName filebeat `
  -binaryPathName "`"$installFolder\\filebeat.exe`" -c `"$installFolder\\filebeat.yml`" -path.home `"$installFolder`" -path.data `"C:\\ProgramData\\filebeat`""

Start-Sleep -s 3

### Start service
Write-Output("Start service")
if (Get-Service filebeat -ErrorAction SilentlyContinue) {
  $newService = Get-WmiObject -Class Win32_Service -Filter "name='filebeat'"
  $newService.StartService()
}

### Clean up time!!!
Write-Output("Clean up")
if((Test-Path -Path $sevenzip_temp)){
Write-Output("Remove 7-zip, if just installed")
msiexec.exe /x "C:\Windows\Temp\7zip_installer.msi" /qb
}