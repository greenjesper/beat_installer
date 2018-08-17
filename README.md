# beat_installer
## Filebeat Powershell installer

A Powershell script that downloads and installs Filbeat from Elastic.

### The script does the following operations
  - Remove older Filbeat installations (stops and delete filebeat-service)
  - Download filbeat-zip-archive from Elastic.co
  - Unzip and installs
  - Copys ca-certificate and filebeat.yml from som location
  - Changes Logstash-output in filebeat.yml based on enviroment variables
  
### Prerequisites

Currently only works on Powershell 4 and later (maybe version 3) due to som issues with unzipping files (https://stackoverflow.com/questions/37814037/how-to-unzip-a-zip-file-with-powershell-version-2-0)
A location for a filebeat.yml
A location for a ca.crt

### To-do
 - Add support for Powershell 2
 - Maybe change the way the script alter the logstash-output. Perhaps use paarameters instead of eviroment variables.
