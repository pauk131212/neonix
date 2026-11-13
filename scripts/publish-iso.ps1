# Публикация готового ISO в GitHub Releases.
#
#   powershell -ExecutionPolicy Bypass -File .\scripts\publish-iso.ps1
#
# GitHub не принимает файлы больше 2 ГБ, поэтому ISO режется на части
# по 1.9 ГБ, к ним добавляется SHA256SUMS.txt, и всё это уходит в релиз.
# Скрипт нужно запускать из папки проекта (там уже настроен git-remote).

param(
    [string]$Iso      = 'C:\distro-work\out\neonix-1.0-amd64.iso',
    [string]$Tag      = 'v1.0',
    [string]$Title    = 'Neonix 1.0',
    [int]$PartMB      = 1900
)

$ErrorActionPreference = 'Stop'
Set-Location (Split-Path $PSScriptRoot -Parent)

if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
    throw 'GitHub CLI (gh) не установлен. Сначала запустите publish-repo.ps1.'
}
if (-not (Test-Path $Iso)) { throw "Нет файла: $Iso" }

$isoSize = (Get-Item $Iso).Length
Write-Host ("ISO: {0} ({1:N0} байт)" -f (Split-Path $Iso -Leaf), $isoSize)

# --- 1. Режем на части -------------------------------------------------
Get-ChildItem "$Iso.part*" -ErrorAction SilentlyContinue | Remove-Item -Force

$partSize = [int64]$PartMB * 1MB
$buffer   = New-Object byte[] (4MB)
$parts    = @()
$stream   = [System.IO.File]::OpenRead($Iso)
try {
    $index = 1
    while ($stream.Position -lt $stream.Length) {
        $partPath = '{0}.part{1:D2}' -f $Iso, $index
        $out = [System.IO.File]::Create($partPath)
        try {
            $left = [Math]::Min($partSize, $stream.Length - $stream.Position)
            while ($left -gt 0) {
                $toRead = [int][Math]::Min([int64]$buffer.Length, $left)
                $read   = $stream.Read($buffer, 0, $toRead)
                if ($read -le 0) { break }
                $out.Write($buffer, 0, $read)
                $left -= $read
            }
        } finally { $out.Close() }

        $parts += $partPath
        $mb = (Get-Item $partPath).Length / 1MB
        Write-Host ("  часть {0:D2}: {1:N0} МБ" -f $index, $mb)
        $index++
    }
} finally { $stream.Close() }

# --- 2. Контрольная сумма ---------------------------------------------
Write-Host 'Считаю SHA256 (может занять минуту)...'
$hash = (Get-FileHash -Path $Iso -Algorithm SHA256).Hash.ToLower()
$sums = Join-Path (Split-Path $Iso) 'SHA256SUMS.txt'
"{0}  {1}" -f $hash, (Split-Path $Iso -Leaf) | Set-Content -Path $sums -Encoding ascii
Write-Host "SHA256: $hash"

# --- 3. Релиз ----------------------------------------------------------
$notes = @"
Neonix 1.0 — кибер-ремикс Ubuntu 24.04 LTS на XFCE.
Загрузочная заставка: падающий код, логотип NEONIX, прогресс.

GitHub не принимает файлы больше 2 ГБ, поэтому ISO разделён на части.

Собрать обратно:
  Windows:  copy /b neonix-1.0-amd64.iso.part01+neonix-1.0-amd64.iso.part02+neonix-1.0-amd64.iso.part03+neonix-1.0-amd64.iso.part04 neonix-1.0-amd64.iso
  Linux:    cat neonix-1.0-amd64.iso.part* > neonix-1.0-amd64.iso

Проверить SHA256:
  Linux:    sha256sum -c SHA256SUMS.txt
  Windows:  Get-FileHash .\neonix-1.0-amd64.iso -Algorithm SHA256
"@

$assets = $parts + $sums

# gh пишет прогресс в stderr — при ErrorActionPreference=Stop это исключение,
# поэтому на время загрузки глушим его и проверяем код возврата вручную.
$old = $ErrorActionPreference
$ErrorActionPreference = 'Continue'
gh release create $Tag $assets --title $Title --notes $notes
$code = $LASTEXITCODE
if ($code -eq 0) {
    gh release view $Tag --json url --jq .url
}
$ErrorActionPreference = $old

if ($code -ne 0) { throw "gh release create завершился с ошибкой (код $code)." }

Write-Host ''
Write-Host 'Готово.'
