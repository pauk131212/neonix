# Обои рабочего стола: градиент + слабое свечение + РЕЗКИЙ логотип (текст в финальном размере).
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

$Root   = $PSScriptRoot
$Assets = Join-Path $Root 'assets'
$Fmt    = [System.Drawing.StringFormat]::GenericTypographic
$text   = 'NEONIX'

$W = 1920; $H = 1080
$wall = New-Object System.Drawing.Bitmap($W, $H)
$wg = [System.Drawing.Graphics]::FromImage($wall)
$wg.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$wg.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit
$wg.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic

# градиент
$rect = New-Object System.Drawing.Rectangle(0, 0, $W, $H)
$lin = New-Object System.Drawing.Drawing2D.LinearGradientBrush($rect, [System.Drawing.ColorTranslator]::FromHtml('#161616'), [System.Drawing.Color]::Black, 90.0)
$wg.FillRectangle($lin, $rect)
$lin.Dispose()

# мягкий радиальный свет (слабый, чтобы не мылил буквы)
$gw = 240; $gh = 135
$glowBmp = New-Object System.Drawing.Bitmap($gw, $gh)
for ($gy = 0; $gy -lt $gh; $gy++) {
    for ($gx = 0; $gx -lt $gw; $gx++) {
        $dx = ($gx - ($gw - 1) / 2) / (($gw - 1) / 2)
        $dy = ($gy - ($gh - 1) / 2) / (($gh - 1) / 2)
        $d = [Math]::Sqrt($dx * $dx + $dy * $dy)
        $v = 1 - $d
        if ($v -lt 0) { $v = 0 }
        $v = $v * $v
        $a = [int](20 * $v)
        $glowBmp.SetPixel($gx, $gy, [System.Drawing.Color]::FromArgb($a, 255, 255, 255))
    }
}
$wg.DrawImage($glowBmp, 0, 0, $W, $H)
$glowBmp.Dispose()

# подбираем кегль так, чтобы ширина надписи была 980 px
$target = 980
$probeFont = New-Object System.Drawing.Font('Consolas', [float]150, [System.Drawing.FontStyle]::Bold, [System.Drawing.GraphicsUnit]::Pixel)
$probe = New-Object System.Drawing.Bitmap(1, 1)
$pg = [System.Drawing.Graphics]::FromImage($probe)
$m150 = $pg.MeasureString($text, $probeFont, [int]::MaxValue, $Fmt)
$pg.Dispose(); $probe.Dispose(); $probeFont.Dispose()

$size = 150 * $target / $m150.Width
$font = New-Object System.Drawing.Font('Consolas', [float]$size, [System.Drawing.FontStyle]::Bold, [System.Drawing.GraphicsUnit]::Pixel)

$probe = New-Object System.Drawing.Bitmap(1, 1)
$pg = [System.Drawing.Graphics]::FromImage($probe)
$m = $pg.MeasureString($text, $font, [int]::MaxValue, $Fmt)
$pg.Dispose(); $probe.Dispose()

$x = ($W - $m.Width) / 2
$y = ($H - $m.Height) / 2

$white = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::White)
$wg.DrawString($text, $font, $white, [float]$x, [float]$y, $Fmt)
$white.Dispose()
$wg.Dispose()
$font.Dispose()
$wall.Save((Join-Path $Assets 'wallpaper.png'), [System.Drawing.Imaging.ImageFormat]::Png)

# кроп 1:1 вокруг надписи — чтобы видеть резкость «вблизи»
$cw = 1100; $ch = 420
$cx = [int](($W - $cw) / 2); $cy = [int](($H - $ch) / 2)
$crop = New-Object System.Drawing.Bitmap($cw, $ch)
$cg = [System.Drawing.Graphics]::FromImage($crop)
$cg.DrawImage($wall, (New-Object System.Drawing.Rectangle(0, 0, $cw, $ch)), (New-Object System.Drawing.Rectangle($cx, $cy, $cw, $ch)), [System.Drawing.GraphicsUnit]::Pixel)
$cg.Dispose()
$crop.Save((Join-Path $Root 'preview-wallpaper-crop.png'), [System.Drawing.Imaging.ImageFormat]::Png)
$crop.Dispose()
$wall.Dispose()

Write-Host ("wallpaper: font {0:0.#}px, text {1:0}x{2:0}, x={3:0}" -f $size, $m.Width, $m.Height, $x)
