#Requires -Version 5.1
# Generates Neonix branding PNG assets using System.Drawing.
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

$ProjectRoot = Split-Path $PSScriptRoot -Parent
$OutDir = Join-Path $ProjectRoot 'branding\neonix\assets'
New-Item -ItemType Directory -Force -Path $OutDir | Out-Null

function C([string]$hex) { [System.Drawing.ColorTranslator]::FromHtml($hex) }

function New-Canvas([int]$w, [int]$h, [string]$bg) {
    $bmp = New-Object System.Drawing.Bitmap($w, $h)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit
    $g.Clear((C $bg))
    return @($bmp, $g)
}

function Draw-Grid($g, [int]$w, [int]$h, [string]$color, [int]$step) {
    $pen = New-Object System.Drawing.Pen((C $color), 1)
    for ($x = 0; $x -lt $w; $x += $step) { $g.DrawLine($pen, $x, 0, $x, $h) }
    for ($y = 0; $y -lt $h; $y += $step) { $g.DrawLine($pen, 0, $y, $w, $y) }
    $pen.Dispose()
}

function Draw-Code($g, [string[]]$lines, [int]$x, [int]$y, [int]$step, [int]$size, [int]$alpha) {
    $font = New-Object System.Drawing.Font('Consolas', [float]$size, [System.Drawing.FontStyle]::Regular, [System.Drawing.GraphicsUnit]::Pixel)
    $palette = @('#39FF88', '#00E5FF', '#7FE9FF', '#FF2E88', '#9AAFB8')
    $i = 0
    foreach ($line in $lines) {
        $col = C ($palette[$i % $palette.Count])
        $b = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb($alpha, $col))
        $g.DrawString($line, $font, $b, [float]$x, [float]$y)
        $b.Dispose()
        $y += $step
        $i++
    }
    $font.Dispose()
}

function Draw-Glow($g, [string]$text, $font, [int]$cx, [int]$cy, [string]$color, [string]$glow) {
    $m = $g.MeasureString($text, $font)
    $x = $cx - $m.Width / 2
    $y = $cy - $m.Height / 2
    for ($r = 12; $r -ge 1; $r--) {
        $alpha = [int](90 / $r)
        $b = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb($alpha, (C $glow)))
        $g.DrawString($text, $font, $b, [float]($x - $r), [float]$y)
        $g.DrawString($text, $font, $b, [float]($x + $r), [float]$y)
        $g.DrawString($text, $font, $b, [float]$x, [float]($y - $r))
        $g.DrawString($text, $font, $b, [float]$x, [float]($y + $r))
        $b.Dispose()
    }
    $b = New-Object System.Drawing.SolidBrush((C $color))
    $g.DrawString($text, $font, $b, [float]$x, [float]$y)
    $b.Dispose()
}

function Draw-Brackets($g, [int]$w, [int]$h, [string]$color) {
    $pen = New-Object System.Drawing.Pen((C $color), 2)
    $len = 70; $m = 50
    # top-left
    $g.DrawLine($pen, $m, $m, $m + $len, $m); $g.DrawLine($pen, $m, $m, $m, $m + $len)
    # top-right
    $g.DrawLine($pen, $w - $m, $m, $w - $m - $len, $m); $g.DrawLine($pen, $w - $m, $m, $w - $m, $m + $len)
    # bottom-left
    $g.DrawLine($pen, $m, $h - $m, $m + $len, $h - $m); $g.DrawLine($pen, $m, $h - $m, $m, $h - $m - $len)
    # bottom-right
    $g.DrawLine($pen, $w - $m, $h - $m, $w - $m - $len, $h - $m); $g.DrawLine($pen, $w - $m, $h - $m, $w - $m, $h - $m - $len)
    $pen.Dispose()
}

$code = @(
    '$ neonix --init --profile=cyber',
    '[ ok ] mounted /dev/neon0',
    '[ ok ] loaded module neon_core',
    '> handshake 0x4E 0x45 0x4F 0x4E',
    '[ ok ] network uplink established',
    '> decrypting operator profile',
    '0x1F 0x2A 0x7C 0xFF 0x00 0x7E',
    '[ ok ] graphical.target reached',
    '> welcome, operator'
)

# ---------- background.png (1920x1080) ----------
$canvas = New-Canvas 1920 1080 '#05070A'
$bmp = $canvas[0]; $g = $canvas[1]
Draw-Grid $g 1920 1080 '#0B1A22' 60
Draw-Code $g $code 130 210 46 22 255
Draw-Brackets $g 1920 1080 '#0E4A5A'

$logoFont = New-Object System.Drawing.Font('Consolas', [float]150, [System.Drawing.FontStyle]::Bold, [System.Drawing.GraphicsUnit]::Pixel)
# magenta ghost
$ghost = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(120, (C '#FF2E88')))
$m = $g.MeasureString('NEONIX', $logoFont)
$g.DrawString('NEONIX', $logoFont, $ghost, [float](960 - $m.Width / 2 + 6), [float](540 - $m.Height / 2 + 4))
$ghost.Dispose()
Draw-Glow $g 'NEONIX' $logoFont 960 540 '#00E5FF' '#00E5FF'

$tagFont = New-Object System.Drawing.Font('Consolas', [float]24, [System.Drawing.FontStyle]::Bold, [System.Drawing.GraphicsUnit]::Pixel)
$tag = 'CODE  //  NEON  //  CONTROL'
$tm = $g.MeasureString($tag, $tagFont)
$tb = New-Object System.Drawing.SolidBrush((C '#FF2E88'))
$g.DrawString($tag, $tagFont, $tb, [float](960 - $tm.Width / 2), [float]720)
$tb.Dispose()

$bmp.Save((Join-Path $OutDir 'background.png'), [System.Drawing.Imaging.ImageFormat]::Png)
$g.Dispose(); $bmp.Dispose(); $logoFont.Dispose(); $tagFont.Dispose()

# ---------- wallpaper.png (dimmer, for desktop) ----------
$canvas = New-Canvas 1920 1080 '#05070A'
$bmp = $canvas[0]; $g = $canvas[1]
Draw-Grid $g 1920 1080 '#08121A' 60
Draw-Code $g $code 130 210 46 22 70
Draw-Brackets $g 1920 1080 '#0A2A33'
$wallFont = New-Object System.Drawing.Font('Consolas', [float]110, [System.Drawing.FontStyle]::Bold, [System.Drawing.GraphicsUnit]::Pixel)
Draw-Glow $g 'NEONIX' $wallFont 960 540 '#0FA8BF' '#00E5FF'
$bmp.Save((Join-Path $OutDir 'wallpaper.png'), [System.Drawing.Imaging.ImageFormat]::Png)
$g.Dispose(); $bmp.Dispose(); $wallFont.Dispose()

# ---------- logo.png (transparent 900x260) ----------
$logo = New-Object System.Drawing.Bitmap(900, 260)
$lg = [System.Drawing.Graphics]::FromImage($logo)
$lg.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$lg.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit
$lg.Clear([System.Drawing.Color]::Transparent)
$f = New-Object System.Drawing.Font('Consolas', [float]120, [System.Drawing.FontStyle]::Bold, [System.Drawing.GraphicsUnit]::Pixel)
$shadow = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(200, (C '#FF2E88')))
$lm = $lg.MeasureString('NEONIX', $f)
$lg.DrawString('NEONIX', $f, $shadow, [float](450 - $lm.Width / 2 + 5), [float](130 - $lm.Height / 2 + 4))
$shadow.Dispose()
$main = New-Object System.Drawing.SolidBrush((C '#7FF0FF'))
$lg.DrawString('NEONIX', $f, $main, [float](450 - $lm.Width / 2), [float](130 - $lm.Height / 2))
$main.Dispose()
$logo.Save((Join-Path $OutDir 'logo.png'), [System.Drawing.Imaging.ImageFormat]::Png)
$lg.Dispose(); $logo.Dispose(); $f.Dispose()

# ---------- progress boxes ----------
function New-Solid([int]$w, [int]$h, [string]$color, [string]$file) {
    $b = New-Object System.Drawing.Bitmap($w, $h)
    $gg = [System.Drawing.Graphics]::FromImage($b)
    $gg.Clear([System.Drawing.Color]::Transparent)
    $br = New-Object System.Drawing.SolidBrush((C $color))
    $gg.FillRectangle($br, 0, 0, $w, $h)
    $br.Dispose()
    $b.Save((Join-Path $OutDir $file), [System.Drawing.Imaging.ImageFormat]::Png)
    $gg.Dispose(); $b.Dispose()
}
New-Solid 40 10 '#39FF88' 'box_on.png'
New-Solid 40 10 '#12242B' 'box_off.png'
New-Solid 12 22 '#39FF88' 'cursor.png'

Write-Host "Assets written to $OutDir"
Get-ChildItem $OutDir | Select-Object Name, Length | Format-Table -AutoSize
