#Requires -Version 5.1
# Скачивает ISO Ubuntu 24.04 с поддержкой докачки.
$ErrorActionPreference = 'Stop'

$IsoUrl  = 'https://releases.ubuntu.com/24.04/ubuntu-24.04.5.1-desktop-amd64.iso'
$IsoDir  = 'C:\distro-work\iso'
$IsoPath = Join-Path $IsoDir 'ubuntu-24.04.5.1-desktop-amd64.iso'

New-Item -ItemType Directory -Force -Path $IsoDir | Out-Null

Write-Host "Скачивание: $IsoUrl"
Write-Host "Куда:       $IsoPath"

# -C - продолжает недокачанный файл, --retry переживает обрывы
& curl.exe -L -C - --retry 5 --retry-delay 5 --retry-all-errors `
    -o $IsoPath $IsoUrl

if ($LASTEXITCODE -ne 0) { throw "curl завершился с кодом $LASTEXITCODE" }

$size = (Get-Item $IsoPath).Length
Write-Host ("Готово. Размер: {0:N0} байт ({1:N2} ГБ)" -f $size, ($size / 1GB))
