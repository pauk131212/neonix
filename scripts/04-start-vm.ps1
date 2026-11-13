#Requires -Version 5.1
# Запускает ВМ сборщика в графическом режиме.
$ErrorActionPreference = 'Stop'

$VBoxManage = Join-Path $env:ProgramFiles 'Oracle\VirtualBox\VBoxManage.exe'
$VmName     = 'Ubuntu2404-Builder'

& $VBoxManage startvm $VmName --type gui
