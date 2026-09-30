param(
    # 只拼文件名带该前缀的截图（如 0/1/2 或 02_e）；缺省=除 _contact-sheet 外全部
    [string]$Prefix = "",
    [int]$Cols = 3,
    [int]$CellW = 460,
    [int]$LabelH = 28
)
# 把 build/gui-shots/*.png 拼成带文件名标签的网格总览图（供人工/AI 快速核验）
$ErrorActionPreference = "Stop"
$projectRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$shotsDir = Join-Path $projectRoot "build\gui-shots"
Add-Type -AssemblyName System.Drawing

$files = Get-ChildItem $shotsDir -Filter "$Prefix*.png" |
    Where-Object { $_.BaseName -notlike "_*" } | Sort-Object Name
$rows = [Math]::Ceiling($files.Count / $Cols)

# 先量每行的最大高度（缩放后）
$imgs = @()
foreach ($f in $files) {
    $img = [System.Drawing.Bitmap]::FromFile($f.FullName)
    $scale = $CellW / $img.Width
    $imgs += [pscustomobject]@{ File = $f; Bmp = $img; TH = [int]($img.Height * $scale) }
}
$rowH = @()
for ($r = 0; $r -lt $rows; $r++) {
    $h = 0
    for ($c = 0; $c -lt $Cols; $c++) {
        $i = $r * $Cols + $c
        if ($i -lt $imgs.Count) { $h = [Math]::Max($h, $imgs[$i].TH) }
    }
    $rowH += $h + $LabelH
}
$totalW = $CellW * $Cols
$totalH = ($rowH | Measure-Object -Sum).Sum

$sheet = [System.Drawing.Bitmap]::new($totalW, $totalH)
$g = [System.Drawing.Graphics]::FromImage($sheet)
$g.Clear([System.Drawing.Color]::FromArgb(40, 40, 44))
$g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$labelFont = [System.Drawing.Font]::new("Consolas", 11, [System.Drawing.FontStyle]::Regular)
$labelBrush = [System.Drawing.Brushes]::Yellow

$y = 0
for ($r = 0; $r -lt $rows; $r++) {
    for ($c = 0; $c -lt $Cols; $c++) {
        $i = $r * $Cols + $c
        if ($i -ge $imgs.Count) { continue }
        $x = $c * $CellW
        $g.DrawString($imgs[$i].File.BaseName, $labelFont, $labelBrush, $x + 4, $y + 4)
        $th = $imgs[$i].TH
        $g.DrawImage($imgs[$i].Bmp, $x, ($y + $LabelH), $CellW, $th)
    }
    $y += $rowH[$r]
}
$g.Dispose()

$suffix = if ($Prefix) { "-$Prefix" } else { "" }
$out = Join-Path $shotsDir "_contact-sheet$suffix.png"
$sheet.Save($out, [System.Drawing.Imaging.ImageFormat]::Png)
$sheet.Dispose()
$imgs | ForEach-Object { $_.Bmp.Dispose() }
Write-Host "总览图：$out ($totalW x $totalH)"
