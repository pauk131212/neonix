#Requires -Version 5.1
# Creates a clean test VM and attaches the given ISO.
param(
    [Parameter(Mandatory = $true)][string]$IsoPath,
    [string]$VmName = 'Neonix-Test',
    [int]$MemoryMb = 4096,
    [int]$DiskMb = 30720
)

$ErrorActionPreference = 'Stop'

$VBoxManage = Join-Path $env:ProgramFiles 'Oracle\VirtualBox\VBoxManage.exe'
if (-not (Test-Path $VBoxManage)) { throw 'VirtualBox not found.' }
if (-not (Test-Path $IsoPath)) { throw "ISO not found: $IsoPath" }

$BaseFolder = 'C:\distro-work\vm'
$DiskPath   = Join-Path $BaseFolder "$VmName\disk.vdi"

$existing = (& $VBoxManage list vms) -join "`n"
if ($existing -match [regex]::Escape("`"$VmName`"")) {
    Write-Host "VM '$VmName' already exists." -ForegroundColor Yellow
    exit 0
}

$cpus = [math]::Min(4, [int](Get-CimInstance Win32_Processor | Measure-Object NumberOfLogicalProcessors -Sum).Sum)
$cpus = [math]::Max(2, $cpus)

& $VBoxManage createvm --name $VmName --ostype Ubuntu24_LTS_64 --register --basefolder $BaseFolder
& $VBoxManage modifyvm $VmName --memory $MemoryMb --cpus $cpus --vram 128 `
    --graphicscontroller vmsvga --nic1 nat --audio-enabled off --usb-xhci on `
    --boot1 dvd --boot2 disk --boot3 none --boot4 none

& $VBoxManage createmedium disk --filename $DiskPath --size $DiskMb --variant Standard
& $VBoxManage storagectl $VmName --name SATA --add sata --controller IntelAhci --portcount 2
& $VBoxManage storageattach $VmName --storagectl SATA --port 0 --device 0 --type hdd --medium $DiskPath
& $VBoxManage storagectl $VmName --name IDE --add ide
& $VBoxManage storageattach $VmName --storagectl IDE --port 0 --device 0 --type dvddrive --medium $IsoPath

Write-Host "Test VM '$VmName' created with $IsoPath" -ForegroundColor Green
