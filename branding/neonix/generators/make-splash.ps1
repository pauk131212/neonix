#Requires -Version 5.1
# Neonix MONO (personal) вЂ” РїРµС‡Р°С‚Р°СЋС‰РёР№СЃСЏ Р»РѕРі Р·Р°РіСЂСѓР·РєРё, Р·Р°С‚РµРј РіР»РёС‚С‡-Р»РѕРіРѕС‚РёРї Рё РїСЂРѕРіСЂРµСЃСЃ-Р±Р°СЂ.
# Р“РµРЅРµСЂРёСЂСѓРµС‚ assets/line_XX.png, mask.png, cursor.png, box_on/off.png, neonix.script Рё РїСЂРµРІСЊСЋ.
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

$Root   = $PSScriptRoot
$Assets = Join-Path $Root 'assets'
New-Item -ItemType Directory -Force -Path $Assets | Out-Null

function C([string]$hex) { [System.Drawing.ColorTranslator]::FromHtml($hex) }
$Fmt = [System.Drawing.StringFormat]::GenericTypographic

$FontSize = 26
$LineH    = 40

# ---------------------------------------------------------------- content
# РєР°Р¶РґР°СЏ СЃС‚СЂРѕРєР°: С‚РµРєСЃС‚, С†РІРµС‚, РїР°СѓР·Р° РїРѕСЃР»Рµ СЃС‚СЂРѕРєРё (С‚РёРєРѕРІ ~50 Р“С†)
# С‡РµРј В«С‚СЏР¶РµР»РµРµВ» РѕРїРµСЂР°С†РёСЏ вЂ” С‚РµРј РґРѕР»СЊС€Рµ СЃС‚РѕРёС‚ РєСѓСЂСЃРѕСЂ
$lines = @(
    @('[    0.000000] neonix 1.0 mono - Linux 7.0.0-neonix x86_64',    '#BEBEBE', 6),
    @('[    0.412337] systemd[1]: systemd 255.4 running in system mode','#8E8E8E', 5),
    @('[    0.501128] neonix: mounting root filesystem ... ok',        '#E6E6E6', 6),
    @('[    1.204517] systemd[1]: Started Journal Service.',           '#BEBEBE', 5),
    @('neonix:~# systemctl start neonix-core',                         '#FFFFFF', 6),
    @('[    1.904512] neonix: loading neon_core.ko ... ok',            '#E6E6E6', 6),
    @('neonix:~# mount -t squashfs /dev/sr0 /rofs',                    '#FFFFFF', 6),
    @('[    2.330915] neonix: selftest graphics ... pass',             '#DADADA', 6),
    @('neonix:~# systemctl start neonix-session',                      '#FFFFFF', 6),
    @('[    3.221447] neonix: ready to launch',                        '#FFFFFF', 12),
    @('neonix:~#',                                                     '#FFFFFF', 0)
)

$font  = New-Object System.Drawing.Font('Consolas', [float]$FontSize, [System.Drawing.FontStyle]::Regular, [System.Drawing.GraphicsUnit]::Pixel)
$probe = New-Object System.Drawing.Bitmap(1, 1)
$pg    = [System.Drawing.Graphics]::FromImage($probe)
$cwM   = $pg.MeasureString('0000000000', $font, [int]::MaxValue, $Fmt)
$charw = $cwM.Width / 10.0
$pg.Dispose(); $probe.Dispose()

$lens  = @()
$i = 0
foreach ($ln in $lines) {
    $text  = $ln[0]
    $color = $ln[1]
    $file  = 'line_{0:D2}.png' -f $i

    $probe = New-Object System.Drawing.Bitmap(1, 1)
    $pg = [System.Drawing.Graphics]::FromImage($probe)
    $m = $pg.MeasureString($text, $font, [int]::MaxValue, $Fmt)
    $pg.Dispose(); $probe.Dispose()

    $w = [int][Math]::Max(1, [Math]::Ceiling($m.Width) + 4)
    $bmp = New-Object System.Drawing.Bitmap($w, $LineH)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit
    $g.Clear([System.Drawing.Color]::Transparent)
    $brush = New-Object System.Drawing.SolidBrush((C $color))
    $g.DrawString($text, $font, $brush, [float]0, [float]4, $Fmt)
    $brush.Dispose()
    $bmp.Save((Join-Path $Assets $file), [System.Drawing.Imaging.ImageFormat]::Png)
    $g.Dispose(); $bmp.Dispose()

    $lens += $text.Length
    $i++
}
$font.Dispose()

# ---------------------------------------------------------------- mask + cursor + bars
function New-Solid([int]$w, [int]$h, [string]$color, [string]$file) {
    $b = New-Object System.Drawing.Bitmap($w, $h)
    $gg = [System.Drawing.Graphics]::FromImage($b)
    $gg.Clear([System.Drawing.Color]::Transparent)
    $br = New-Object System.Drawing.SolidBrush((C $color))
    $gg.FillRectangle($br, 0, 0, $w, $h)
    $br.Dispose()
    $b.Save((Join-Path $Assets $file), [System.Drawing.Imaging.ImageFormat]::Png)
    $gg.Dispose(); $b.Dispose()
}
New-Solid 8 8 '#000000' 'mask.png'
New-Solid 13 26 '#E8E8E8' 'cursor.png'
New-Solid 200 10 '#F0F0F0' 'box_on.png'
New-Solid 200 10 '#2A2A2A' 'box_off.png'

# ---------------------------------------------------------------- logo ratio (РёР· РіРѕС‚РѕРІРѕРіРѕ logo.png)
$logoImg = [System.Drawing.Image]::FromFile((Join-Path $Assets 'logo.png'))
$logoRatio = $logoImg.Height / $logoImg.Width
$logoImg.Dispose()

# ---------------------------------------------------------------- script
$nl = $lines.Count
$sb = New-Object System.Text.StringBuilder

[void]$sb.Append(@'
# Neonix MONO вЂ” РїРµС‡Р°С‚Р°СЋС‰РёР№СЃСЏ Р»РѕРі Р·Р°РіСЂСѓР·РєРё, Р·Р°С‚РµРј РіР»РёС‚С‡-Р»РѕРіРѕС‚РёРї Рё РїСЂРѕРіСЂРµСЃСЃ-Р±Р°СЂ.
# Plymouth 24.004.60 (script plugin). РќРёРєР°РєРёС… С‚Р°Р±Р»РёС†/С†РёРєР»РѕРІ вЂ” РІСЃС‘ СЂР°Р·РІС‘СЂРЅСѓС‚Рѕ.

screen_w = Window.GetWidth();
screen_h = Window.GetHeight();

Window.SetBackgroundTopColor(0, 0, 0);
Window.SetBackgroundBottomColor(0, 0, 0);

# РјР°СЃС€С‚Р°Р± РїРѕ РІС‹СЃРѕС‚Рµ СЌРєСЂР°РЅР° (РєР°Рє РєРѕРЅСЃРѕР»СЊРЅС‹Р№ С€СЂРёС„С‚), СЃ Р·Р°С‰РёС‚РѕР№ РїРѕ С€РёСЂРёРЅРµ
k = screen_h / 1080;
if (k > screen_w / 1300) { k = screen_w / 1300; }

x0 = 96 * k;
y0 = 70 * k;
dy = 30 * k;
cw = __CHARW__ * k;

# ---------------- СЃС‚СЂРѕРєРё Р»РѕРіР°
fun mkline(file, idx)
{
  img = Image(file);
  s = Sprite(img.Scale(img.GetWidth() * k, img.GetHeight() * k));
  s.SetX(x0);
  s.SetY(y0 + idx * dy);
  s.SetZ(10);
  s.SetOpacity(0);
  return s;
}

'@)

for ($n = 0; $n -lt $nl; $n++) {
    [void]$sb.Append(('l{0} = mkline("line_{0:D2}.png", {0});' -f $n) + "`n")
}

[void]$sb.Append(@'

# ---------------- Р»РѕРіРѕС‚РёРї (С„Р°Р·Р° 2)
logo_w = screen_w * 0.34;
logo_h = logo_w * LOGRATIO;
logo_x = (screen_w - logo_w) / 2;
logo_y = screen_h * 0.30;

logo = Sprite(Image("logo.png").Scale(logo_w, logo_h));
logo.SetX(logo_x); logo.SetY(logo_y); logo.SetZ(20); logo.SetOpacity(0);

# ровное свечение под логотипом
glow = Sprite(Image("logo_glow.png").Scale(logo_w, logo_h));
glow.SetX(logo_x); glow.SetY(logo_y); glow.SetZ(19); glow.SetOpacity(0);

gl1 = Sprite(Image("logo_g1.png").Scale(logo_w, logo_h));
gl1.SetX(logo_x); gl1.SetY(logo_y); gl1.SetZ(21); gl1.SetOpacity(0);

gl2 = Sprite(Image("logo_g2.png").Scale(logo_w, logo_h));
gl2.SetX(logo_x); gl2.SetY(logo_y); gl2.SetZ(22); gl2.SetOpacity(0);

# ---------------- РїСЂРѕРіСЂРµСЃСЃ-Р±Р°СЂ (РїРѕСЏРІР»СЏРµС‚СЃСЏ РІРјРµСЃС‚Рµ СЃ Р»РѕРіРѕС‚РёРїРѕРј)
bar_w = logo_w * 0.94;
bar_x = (screen_w - bar_w) / 2;
bar_y = logo_y + logo_h + 40 * k;

track = Sprite(Image("box_off.png").Scale(bar_w, 3 * k));
track.SetX(bar_x); track.SetY(bar_y); track.SetZ(5); track.SetOpacity(0);

box_on_img = Image("box_on.png");
fill = Sprite(box_on_img.Scale(1, 3 * k));
fill.SetX(bar_x); fill.SetY(bar_y); fill.SetZ(6); fill.SetOpacity(0);

# ---------------- РјР°СЃРєР° В«РЅРµРґРѕРїРµС‡Р°С‚Р°РЅРЅРѕРіРѕВ» Рё РєСѓСЂСЃРѕСЂ
mask = Sprite(Image("mask.png").Scale(screen_w, dy));
mask.SetX(x0); mask.SetY(y0); mask.SetZ(15); mask.SetOpacity(1);

cur = Sprite(Image("cursor.png").Scale(13 * k, 26 * k));
cur.SetX(x0); cur.SetY(y0); cur.SetZ(16); cur.SetOpacity(0);

# ---------------- СЃРѕСЃС‚РѕСЏРЅРёРµ
tick = 0;
phase = 0;
li = 0;
ci = 0;
per = 0;
wait = 6;
n = 0;
r = 2;
p = 8;
started = 0;
hold = 0;
blink = 0;
fadeop = 1;
logo_op = 0;
burst = 0;
prog = 0;

fun show_line()
{
'@)

for ($n = 0; $n -lt $nl; $n++) {
    [void]$sb.Append(('  if (li == {0}) {{ l{0}.SetOpacity(1); }}' -f $n) + "`n")
}

[void]$sb.Append(@'
}

fun set_line_params()
{
  n = 0; r = 2; p = 6;
'@)

for ($n = 0; $n -lt $nl; $n++) {
    $pause = [int][Math]::Max(6, [Math]::Round($lines[$n][2] * 1.2))
    [void]$sb.Append(('  if (li == {0}) {{ n = {1}; r = 1; p = {2}; }}' -f $n, $lens[$n], $pause) + "`n")
}

[void]$sb.Append(@'
}

fun set_all_opacity(op)
{
'@)

for ($n = 0; $n -lt $nl; $n++) {
    [void]$sb.Append(('  l{0}.SetOpacity(op);' -f $n) + "`n")
}

[void]$sb.Append(@'
  mask.SetOpacity(op);
}

fun refresh_cb()
{
  tick = tick + 1;

  if (phase == 0)
  {
    if (li >= NLINES)
    {
      hold = hold + 1;
      if (hold > 40)
      {
        phase = 1;
        wait = 0;
        cur.SetOpacity(0);
      }
      else
      {
        blink = blink + 1;
        if (blink >= 30) { blink = 0; }
        if (blink < 15) { cur.SetOpacity(1); } else { cur.SetOpacity(0); }
      }
    }
    else
    {
      if (started == 0)
      {
        if (wait > 0)
        {
          wait = wait - 1;
        }
        else
        {
          started = 1;
          ci = 0;
          per = 0;
          show_line();
          set_line_params();
          mask.SetY(y0 + li * dy);
          mask.SetX(x0);
          cur.SetY(y0 + li * dy + 4 * k);
          cur.SetX(x0);
          cur.SetOpacity(1);
        }
      }
      else
      {
        per = per + 1;
        if (per >= r)
        {
          per = 0;
          ci = ci + 1;
          cur.SetX(x0 + ci * cw);
          mask.SetX(x0 + ci * cw);
          if (ci >= n)
          {
            wait = p;
            li = li + 1;
            started = 0;
          }
        }
      }
    }
  }

  if (phase == 1)
  {
    wait = wait + 1;
    if (wait > 10)
    {
      fadeop = fadeop - 0.03;
      if (fadeop <= 0)
      {
        fadeop = 0;
        phase = 2;
        burst = 0;
      }
      set_all_opacity(fadeop);
    }
  }

  if (phase == 2)
  {
    if (logo_op < 1)
    {
      logo_op = logo_op + 0.02;
      if (logo_op > 1) { logo_op = 1; }
      logo.SetOpacity(logo_op);
      track.SetOpacity(logo_op * 0.9);
      fill.SetOpacity(logo_op);
    }

    # ровное свечение + периодический глитч («двоение») поверх логотипа
    glow.SetOpacity(logo_op * 0.7);

    burst = burst + 1;
    if (burst >= 260) { burst = 0; }

    if (burst < 30)
    {
      gl1.SetOpacity(logo_op);
      if (burst < 15) { gl1.SetX(logo_x + 9 * k); } else { gl1.SetX(logo_x - 9 * k); }
      if (burst < 10) { gl2.SetOpacity(logo_op); } else { gl2.SetOpacity(0); }
      if (burst < 6) { logo.SetX(logo_x - 4 * k); } else { logo.SetX(logo_x + 2 * k); }
    }
    else
    {
      gl1.SetOpacity(0);
      gl2.SetOpacity(0);
      logo.SetX(logo_x);
    }

    # полоса сама доезжает до 100% за ~5 с после появления логотипа
    # (progress_cb только увеличивает prog, назад не откатывает)
    if (prog < 1)
    {
      prog = prog + 0.004;
      if (prog > 1) { prog = 1; }
      w = bar_w * prog;
      if (w < 1) { w = 1; }
      fill.SetImage(box_on_img.Scale(w, 3 * k));
    }

    w = bar_w * prog;
    if (w < 1) { w = 1; }
    fill.SetImage(box_on_img.Scale(w, 3 * k));
  }
}

fun progress_cb(duration, progress)
{
  if (progress > prog) { prog = progress; }
  if (phase == 2)
  {
    w = bar_w * progress;
    if (w < 1) { w = 1; }
    fill.SetImage(box_on_img.Scale(w, 3 * k));
  }
}

Plymouth.SetRefreshFunction(refresh_cb);
Plymouth.SetBootProgressFunction(progress_cb);
'@)

$script = $sb.ToString()
$script = $script.Replace('__CHARW__', [string]::Format([System.Globalization.CultureInfo]::InvariantCulture, '{0:0.####}', $charw))
$script = $script.Replace('LOGRATIO', [string]::Format([System.Globalization.CultureInfo]::InvariantCulture, '{0:0.0000}', $logoRatio))
$script = $script.Replace('NLINES', [string]$nl)

$utf8 = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText((Join-Path $Root 'neonix.script'), $script, $utf8)

# ---------------------------------------------------------------- preview: С„РёРЅР°Р»СЊРЅР°СЏ С„Р°Р·Р° (1280x800)
$PW = 1280; $PH = 800
$k = $PW / 1920
$pv = New-Object System.Drawing.Bitmap($PW, $PH)
$pg = [System.Drawing.Graphics]::FromImage($pv)
$pg.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$pg.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$pg.Clear((C '#000000'))

$lw = $PW * 0.34
$lh = $lw * $logoRatio
$ia = New-Object System.Drawing.Imaging.ImageAttributes
$cm = New-Object System.Drawing.Imaging.ColorMatrix
$cm.Matrix33 = 0.7
$ia.SetColorMatrix($cm)
$glowImg = [System.Drawing.Image]::FromFile((Join-Path $Assets 'logo_glow.png'))
$gx = [int](($PW - $lw) / 2); $gy2 = [int]($PH * 0.30)
$pg.DrawImage($glowImg, (New-Object System.Drawing.Rectangle($gx, $gy2, [int]$lw, [int]$lh)), 0, 0, $glowImg.Width, $glowImg.Height, [System.Drawing.GraphicsUnit]::Pixel, $ia)
$glowImg.Dispose()
$lg = [System.Drawing.Image]::FromFile((Join-Path $Assets 'logo.png'))
$pg.DrawImage($lg, [int](($PW - $lw) / 2), [int]($PH * 0.30), [int]$lw, [int]$lh)
$lg.Dispose()

$barW = $lw * 0.94
$barX = ($PW - $barW) / 2
$barY = $PH * 0.30 + $lh + 40 * $k
$b1 = New-Object System.Drawing.SolidBrush((C '#2A2A2A'))
$pg.FillRectangle($b1, [int]$barX, [int]$barY, [int]$barW, 2)
$b1.Dispose()
$b2 = New-Object System.Drawing.SolidBrush((C '#F0F0F0'))
$pg.FillRectangle($b2, [int]$barX, [int]$barY, [int]($barW * 0.62), 2)
$b2.Dispose()
$pv.Save((Join-Path $Root 'preview-logo.png'), [System.Drawing.Imaging.ImageFormat]::Png)
$pg.Dispose(); $pv.Dispose()

# ---------------------------------------------------------------- preview: РїРµС‡Р°С‚СЊ Р»РѕРіР° (1280x800)
$pv = New-Object System.Drawing.Bitmap($PW, $PH)
$pg = [System.Drawing.Graphics]::FromImage($pv)
$pg.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$pg.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$pg.Clear((C '#000000'))

$pf = New-Object System.Drawing.Font('Consolas', [float](26 * $k), [System.Drawing.FontStyle]::Regular, [System.Drawing.GraphicsUnit]::Pixel)
$px0 = 96 * $k
$py0 = 84 * $k
$pdy = 30 * $k
$shown = [Math]::Min(10, $nl)
for ($n = 0; $n -lt [Math]::Min($shown, $nl); $n++) {
    $pb = New-Object System.Drawing.SolidBrush((C $lines[$n][1]))
    $pg.DrawString($lines[$n][0], $pf, $pb, [float]$px0, [float]($py0 + $n * $pdy), $Fmt)
    $pb.Dispose()
}
# РєСѓСЂСЃРѕСЂ РїРѕСЃСЂРµРґРё РїРѕСЃР»РµРґРЅРµР№ РїРѕРєР°Р·Р°РЅРЅРѕР№ СЃС‚СЂРѕРєРё
$lastText = $lines[$shown - 1][0]
$half = [int]($lastText.Length * 0.55)
$cxp = $px0 + $half * ($charw * $k)
$cb = New-Object System.Drawing.SolidBrush((C '#E8E8E8'))
$pg.FillRectangle($cb, [int]$cxp, [int]($py0 + ($shown - 1) * $pdy + 3), [int](8 * $k), [int](17 * $k))
$cb.Dispose()
$pv.Save((Join-Path $Root 'preview-log.png'), [System.Drawing.Imaging.ImageFormat]::Png)
$pg.Dispose(); $pf.Dispose(); $pv.Dispose()

Write-Host ("charw = {0:0.###} px @1920, lines = {1}, script = {2:N0} bytes" -f $charw, $nl, (Get-Item (Join-Path $Root 'neonix.script')).Length)
$reveal = 0
for ($n = 0; $n -lt $nl; $n++) { $reveal += [Math]::Ceiling($lens[$n] / 2) + $lines[$n][2] }
Write-Host ("typing ~ {0:0.0} s at 50 Hz" -f ($reveal / 50.0))

