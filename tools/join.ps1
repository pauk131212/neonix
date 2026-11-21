# Собирает ISO из частей релиза и сверяет SHA-256.
#   powershell -ExecutionPolicy Bypass -File join.ps1
# Положи этот файл рядом с neonix-1.1-amd64.iso.part1/2/3.
$ErrorActionPreference = 'Stop'
$out = 'neonix-personal-1.1-amd64.iso'
$expected = '93b2174a1105b6b70718d7c819cf41e1c9eaab08f35c36b513ad21efbfbe6fb5'

$parts = Get-ChildItem -Path $PSScriptRoot -Filter 'neonix-1.1-amd64.iso.part*' | Sort-Object Name
if ($parts.Count -lt 3) { throw "не найдены части (нужно 3 файла neonix-1.1-amd64.iso.partN)" }

$dest = Join-Path $PSScriptRoot $out
if (Test-Path $dest) { Remove-Item $dest -Force }
$fs = [System.IO.File]::Create($dest)
try {
    foreach ($p in $parts) {
        Write-Host ("склеиваю " + $p.Name)
        $src = [System.IO.File]::OpenRead($p.FullName)
        try { $src.CopyTo($fs) } finally { $src.Dispose() }
    }
} finally { $fs.Dispose() }

$hash = (Get-FileHash $dest -Algorithm SHA256).Hash.ToLower()
Write-Host ("размер: " + (Get-Item $dest).Length)
Write-Host ("sha256: " + $hash)
if ($hash -eq $expected) { Write-Host 'OK: хеш совпал' } else { Write-Host 'ОШИБКА: хеш не совпал, перекачай части'; exit 1 }
