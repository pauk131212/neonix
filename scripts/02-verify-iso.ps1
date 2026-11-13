#Requires -Version 5.1
# Сверяет SHA256 скачанного ISO с официальным SHA256SUMS.
$ErrorActionPreference = 'Stop'

$IsoPath  = 'C:\distro-work\iso\ubuntu-24.04.5.1-desktop-amd64.iso'
$SumsUrl  = 'https://releases.ubuntu.com/24.04/SHA256SUMS'
$IsoName  = Split-Path $IsoPath -Leaf

if (-not (Test-Path $IsoPath)) { throw "ISO не найден: $IsoPath" }

Write-Host 'Загрузка SHA256SUMS...'
$resp = (Invoke-WebRequest -Uri $SumsUrl -UseBasicParsing).Content
if ($resp -is [byte[]]) { $sums = [Text.Encoding]::UTF8.GetString($resp) } else { $sums = [string]$resp }
$line = ($sums -split "`n") | Where-Object { $_ -match [regex]::Escape($IsoName) } | Select-Object -First 1
if (-not $line) { throw "В SHA256SUMS нет строки для $IsoName" }
$expected = ($line -split '\s+')[0].Trim().ToLower()

Write-Host 'Вычисление хеша (может занять минуту)...'
$actual = (Get-FileHash -Path $IsoPath -Algorithm SHA256).Hash.ToLower()

if ($actual -eq $expected) {
    Write-Host "OK: хеш совпадает ($actual)" -ForegroundColor Green
} else {
    Write-Host "ОШИБКА: хеш не совпадает!" -ForegroundColor Red
    Write-Host "  ожидался: $expected"
    Write-Host "  получен:  $actual"
    exit 1
}
