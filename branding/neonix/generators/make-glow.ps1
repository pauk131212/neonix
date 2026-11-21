# Генерирует assets/logo_glow.png — симметричное мягкое свечение из logo.png (без сдвигов).
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

$Root   = $PSScriptRoot
$Assets = Join-Path $Root 'assets'
$src    = Join-Path $Assets 'logo.png'

$img = [System.Drawing.Image]::FromFile($src)
$W = $img.Width; $H = $img.Height

# 1) уменьшаем в 10 раз (сглаживание), 2) возвращаем размер — получаем размытие
$sw = [int][Math]::Max(1, $W / 10); $sh = [int][Math]::Max(1, $H / 10)
$small = New-Object System.Drawing.Bitmap($sw, $sh)
$gs = [System.Drawing.Graphics]::FromImage($small)
$gs.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$gs.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
$gs.Clear([System.Drawing.Color]::Transparent)
$gs.DrawImage($img, 0, 0, $sw, $sh)
$gs.Dispose()

$glow = New-Object System.Drawing.Bitmap($W, $H)
$gg = [System.Drawing.Graphics]::FromImage($glow)
$gg.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$gg.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
$gg.Clear([System.Drawing.Color]::Transparent)
$gg.DrawImage($small, 0, 0, $W, $H)
$gg.Dispose()
$small.Dispose()

# чуть приглушаем альфу, чтобы это было именно свечение, а не второй логотип
for ($y = 0; $y -lt $H; $y++) {
    for ($x = 0; $x -lt $W; $x++) {
        $p = $glow.GetPixel($x, $y)
        if ($p.A -gt 0) {
            $a = [int]($p.A * 0.75)
            $glow.SetPixel($x, $y, [System.Drawing.Color]::FromArgb($a, 255, 255, 255))
        }
    }
}

$glow.Save((Join-Path $Assets 'logo_glow.png'), [System.Drawing.Imaging.ImageFormat]::Png)
$glow.Dispose()
$img.Dispose()
Write-Host "logo_glow.png = ${W}x${H}"
