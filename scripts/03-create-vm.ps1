#Requires -Version 5.1
# Создаёт ВМ для сборки дистрибутива (Ubuntu 24.04 + Cubic).
$ErrorActionPreference = 'Stop'

$VBoxManage = Join-Path $env:ProgramFiles 'Oracle\VirtualBox\VBoxManage.exe'
if (-not (Test-Path $VBoxManage)) { throw 'VirtualBox не найден. Установите: winget install Oracle.VirtualBox' }

$VmName     = 'Ubuntu2404-Builder'
$BaseFolder = 'C:\distro-work\vm'
$IsoPath    = 'C:\distro-work\iso\ubuntu-24.04.5.1-desktop-amd64.iso'
$DiskPath   = Join-Path $BaseFolder "$VmName\disk.vdi"
$SharePath  = 'C:\distro-work'

if (-not (Test-Path $IsoPath)) { throw "ISO не найден: $IsoPath (сначала 01-download-iso.ps1)" }

$existing = (& $VBoxManage list vms) -join "`n"
if ($existing -match [regex]::Escape("`"$VmName`"")) {
    Write-Host "ВМ '$VmName' уже существует — выходим." -ForegroundColor Yellow
    exit 0
}

# Память: половина ОЗУ хоста, но не меньше 4 ГБ и не больше 8 ГБ
$totalMb = [int]((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1MB)
$ramMb   = [math]::Min(8192, [math]::Max(4096, [int]($totalMb / 2)))
$cpus    = [math]::Min(4, [int](Get-CimInstance Win32_Processor | Measure-Object NumberOfLogicalProcessors -Sum).Sum)
$cpus    = [math]::Max(2, $cpus)

Write-Host "Создание ВМ: RAM ${ramMb} МБ, CPU $cpus, диск 40 ГБ"

& $VBoxManage createvm --name $VmName --ostype Ubuntu24_LTS_64 --register --basefolder $BaseFolder

& $VBoxManage modifyvm $VmName `
    --memory $ramMb --cpus $cpus --vram 128 `
    --graphicscontroller vmsvga --accelerate-3d off `
    --nic1 nat --audio-enabled off --usb-xhci on `
    --clipboard-mode bidirectional --draganddrop bidirectional `
    --boot1 dvd --boot2 disk --boot3 none --boot4 none

& $VBoxManage createmedium disk --filename $DiskPath --size 40960 --variant Standard

& $VBoxManage storagectl $VmName --name SATA --add sata --controller IntelAhci --portcount 2
& $VBoxManage storageattach $VmName --storagectl SATA --port 0 --device 0 --type hdd --medium $DiskPath

& $VBoxManage storagectl $VmName --name IDE --add ide
& $VBoxManage storageattach $VmName --storagectl IDE --port 0 --device 0 --type dvddrive --medium $IsoPath

& $VBoxManage sharedfolder add $VmName --name work --hostpath $SharePath --automount

Write-Host "Готово: ВМ '$VmName' создана." -ForegroundColor Green
Write-Host "Общая папка: $SharePath -> /media/sf_work"
