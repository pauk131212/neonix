#Requires -Version 5.1
# Generates animated Neonix boot assets: background, code-rain columns, glitch logo, tagline.
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

$ProjectRoot = Split-Path $PSScriptRoot -Parent
$OutDir = Join-Path $ProjectRoot 'branding\neonix\assets\anim'
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

function Draw-Grid($g, [int]$w, [int]$h) {
    $pen = New-Object System.Drawing.Pen((C '#08121A'), 1)
    for ($x = 0; $x -lt $w; $x += 60) { $g.DrawLine($pen, $x, 0, $x, $h) }
    for ($y = 0; $y -lt $h; $y += 60) { $g.DrawLine($pen, 0, $y, $w, $y) }
    $pen.Dispose()
}

function Draw-Brackets($g, [int]$w, [int]$h) {
    $pen = New-Object System.Drawing.Pen((C '#0A2A33'), 2)
    $len = 70; $m = 50
    $g.DrawLine($pen, $m, $m, $m + $len, $m); $g.DrawLine($pen, $m, $m, $m, $m + $len)
    $g.DrawLine($pen, $w - $m, $m, $w - $m - $len, $m); $g.DrawLine($pen, $w - $m, $m, $w - $m, $m + $len)
    $g.DrawLine($pen, $m, $h - $m, $m + $len, $h - $m); $g.DrawLine($pen, $m, $h - $m, $m, $h - $m - $len)
    $g.DrawLine($pen, $w - $m, $h - $m, $w - $m - $len, $h - $m); $g.DrawLine($pen, $w - $m, $h - $m, $w - $m, $h - $m - $len)
    $pen.Dispose()
}

# ---------- background ----------
$canvas = New-Canvas 1920 1080 '#05070A'
$bmp = $canvas[0]; $g = $canvas[1]
Draw-Grid $g 1920 1080
Draw-Brackets $g 1920 1080
$bmp.Save((Join-Path $OutDir 'bg.png'), [System.Drawing.Imaging.ImageFormat]::Png)
$g.Dispose(); $bmp.Dispose()

# ---------- code rain columns ----------
$chars = '01ABCDEF{}[]<>/=+*#$%&0123456789'
$palette = @('#39FF88', '#00E5FF', '#7FE9FF', '#FF2E88')
$rnd = New-Object System.Random 1337

for ($i = 1; $i -le 8; $i++) {
    $w = 100; $h = 1500
    $col = New-Object System.Drawing.Bitmap($w, $h)
    $cg = [System.Drawing.Graphics]::FromImage($col)
    $cg.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit
    $cg.Clear([System.Drawing.Color]::Transparent)
    $font = New-Object System.Drawing.Font('Consolas', [float]22, [System.Drawing.FontStyle]::Bold, [System.Drawing.GraphicsUnit]::Pixel)
    $color = C ($palette[($i - 1) % $palette.Count])

    for ($y = 0; $y -lt $h; $y += 30) {
        $ch = [string]$chars[$rnd.Next($chars.Length)]
        $ratio = $y / $h
        $alpha = [int](255 * [math]::Pow($ratio, 1.6))
        if ($rnd.Next(100) -lt 18) { $alpha = [int]($alpha * 0.25) }
        if ($alpha -lt 4) { $alpha = 4 }
        $br = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb($alpha, $color))
        $cg.DrawString($ch, $font, $br, [float]10, [float]$y)
        $br.Dispose()
    }

    $col.Save((Join-Path $OutDir ('col_{0:D2}.png' -f $i)), [System.Drawing.Imaging.ImageFormat]::Png)
    $font.Dispose(); $cg.Dispose(); $col.Dispose()
}

# ---------- logo variants ----------
function New-Logo([string]$file, [int]$shift) {
    $b = New-Object System.Drawing.Bitmap(900, 260)
    $lg = [System.Drawing.Graphics]::FromImage($b)
    $lg.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $lg.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit
    $lg.Clear([System.Drawing.Color]::Transparent)
    $f = New-Object System.Drawing.Font('Consolas', [float]120, [System.Drawing.FontStyle]::Bold, [System.Drawing.GraphicsUnit]::Pixel)
    $m = $lg.MeasureString('NEONIX', $f)
    $x = 450 - $m.Width / 2
    $y = 130 - $m.Height / 2

    if ($shift -ne 0) {
        $ghost = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(180, (C '#FF2E88')))
        $lg.DrawString('NEONIX', $f, $ghost, [float]($x + $shift), [float]$y)
        $ghost.Dispose()
        $ghost2 = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(180, (C '#00E5FF')))
        $lg.DrawString('NEONIX', $f, $ghost2, [float]($x - $shift), [float]$y)
        $ghost2.Dispose()
    }

    $main = New-Object System.Drawing.SolidBrush((C '#D8F6FF'))
    $lg.DrawString('NEONIX', $f, $main, [float]$x, [float]$y)
    $main.Dispose()
    $b.Save((Join-Path $OutDir $file), [System.Drawing.Imaging.ImageFormat]::Png)
    $lg.Dispose(); $b.Dispose(); $f.Dispose()
}
New-Logo 'logo.png' 0
New-Logo 'logo_g1.png' 7
New-Logo 'logo_g2.png' 4

# ---------- tagline ----------
$t = New-Object System.Drawing.Bitmap(1000, 90)
$tg = [System.Drawing.Graphics]::FromImage($t)
$tg.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit
$tg.Clear([System.Drawing.Color]::Transparent)
$tf = New-Object System.Drawing.Font('Consolas', [float]26, [System.Drawing.FontStyle]::Bold, [System.Drawing.GraphicsUnit]::Pixel)
$tm = $tg.MeasureString('CODE  //  NEON  //  CONTROL', $tf)
$tb = New-Object System.Drawing.SolidBrush((C '#FF2E88'))
$tg.DrawString('CODE  //  NEON  //  CONTROL', $tf, $tb, [float]((1000 - $tm.Width) / 2), [float]20)
$tb.Dispose()
$t.Save((Join-Path $OutDir 'tagline.png'), [System.Drawing.Imaging.ImageFormat]::Png)
$tg.Dispose(); $t.Dispose(); $tf.Dispose()

# ---------- cursor ----------
$cur = New-Object System.Drawing.Bitmap(12, 24)
$cg2 = [System.Drawing.Graphics]::FromImage($cur)
$cg2.Clear([System.Drawing.Color]::Transparent)
$cb = New-Object System.Drawing.SolidBrush((C '#39FF88'))
$cg2.FillRectangle($cb, 0, 0, 12, 24)
$cb.Dispose()
$cur.Save((Join-Path $OutDir 'cursor.png'), [System.Drawing.Imaging.ImageFormat]::Png)
$cg2.Dispose(); $cur.Dispose()

Write-Host "Animated assets written to $OutDir"
Get-ChildItem $OutDir | Select-Object Name, Length | Format-Table -AutoSize
