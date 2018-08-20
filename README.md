# beat_installer
## Filebeat Powershell installer

A Powershell script that downloads and installs Filbeat from Elastic.

### The script does the following operations
  - Remove older Filbeat installations (stops and delete filebeat-service)
  - Download filbeat-zip-archive from Elastic.co
  - Unzip and installs
  - Copys ca-certificate and filebeat.yml from predefined location
  - Changes Logstash-output in filebeat.yml based on enviroment variables
  - If Powershell 3 or older, 7-zip will be downloaded, installed and uninstalled.
  
### Prerequisites

A location for a filebeat.yml
A location for a ca.crt

### To-do
  - Maybe change the way the script alter the logstash-output. Perhaps use paarameters instead of eviroment variables.
