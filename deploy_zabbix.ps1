
$SOURCE_DIR=split-path -parent $MyInvocation.MyCommand.Definition
$ZABBIX_DIR="C:\Program Files (x86)\Zabbix Agent"

New-Item  -Path $ZABBIX_DIR -Name zabbix_agentd.d -ItemType directory -ErrorAction Ignore
New-Item  -Path $ZABBIX_DIR\scripts\agentd -Name custiw -ItemType directory -ErrorAction Ignore
Copy-Item -Path $SOURCE_DIR\custiw\scripts -Recurse -Destination $ZABBIX_DIR\scripts\agentd\custiw\ -Container -ErrorAction Ignore
Copy-Item -Path $SOURCE_DIR\custiw\zabbix_agentd.conf -Recurse -Destination $ZABBIX_DIR\zabbix_agentd.d\custiw.conf -Container -ErrorAction Ignore
