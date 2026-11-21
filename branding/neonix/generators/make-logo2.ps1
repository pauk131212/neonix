# Чистый логотип: резкие белые буквы без «двойника» + отдельное симметричное свечение.
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

$Root   = $PSScriptRoot
$Assets = Join-Path $Root 'assets'
$Fmt    = [System.Drawing.StringFormat]::GenericTypographic
$text   = 'NEONIX'

$font = New-Object System.Drawing.Font('Consolas', [float]150, [System.Drawing.FontStyle]::Bold, [System.Drawing.GraphicsUnit]::Pixel)

# размеры по метрикам текста
$probe = New-Object System.Drawing.Bitmap(1, 1)
$pg = [System.Drawing.Graphics]::FromImage($probe)
$m = $pg.MeasureString($text, $font, [int]::MaxValue, $Fmt)
$pg.Dispose(); $probe.Dispose()

$W = [int][Math]::Ceiling($m.Width) + 80
$H = [int][Math]::Ceiling($m.Height) + 60
$X = 40; $Y = 30

# --- резкий логотип
$logo = New-Object System.Drawing.Bitmap($W, $H)
$g = [System.Drawing.Graphics]::FromImage($logo)
$g.Clear([System.Drawing.Color]::Transparent)
$g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit
$white = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::White)
$g.DrawString($text, $font, $white, [float]$X, [float]$Y, $Fmt)
$white.Dispose(); $g.Dispose()
$logo.Save((Join-Path $Assets 'logo.png'), [System.Drawing.Imaging.ImageFormat]::Png)

# --- свечение: сильное размытие через downscale 20x + апскейл
$sw = [int][Math]::Max(1, $W / 20); $sh = [int][Math]::Max(1, $H / 20)
$small = New-Object System.Drawing.Bitmap($sw, $sh)
$gs = [System.Drawing.Graphics]::FromImage($small)
$gs.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$gs.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
$gs.Clear([System.Drawing.Color]::Transparent)
$gs.DrawImage($logo, 0, 0, $sw, $sh)
$gs.Dispose()

$glow = New-Object System.Drawing.Bitmap($W, $H)
$gg = [System.Drawing.Graphics]::FromImage($glow)
$gg.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$gg.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
$gg.Clear([System.Drawing.Color]::Transparent)
$gg.DrawImage($small, 0, 0, $W, $H)
$gg.Dispose()
$small.Dispose()
$glow.Save((Join-Path $Assets 'logo_glow.png'), [System.Drawing.Imaging.ImageFormat]::Png)

$glow.Dispose(); $logo.Dispose(); $font.Dispose()
Write-Host "logo.png / logo_glow.png = ${W}x${H}"
