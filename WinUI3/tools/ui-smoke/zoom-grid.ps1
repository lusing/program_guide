param(
    [Parameter(Mandatory = $true)][string]$Image,
    [Parameter(Mandatory = $true)][string]$Out,
    # Crop window-coordinate region x0,y0,x1,y1, then upscale and draw a labeled grid.
    [int]$X0 = 350, [int]$Y0 = 100, [int]$X1 = 900, [int]$Y1 = 700,
    [double]$Scale = 1.0
)
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$src = [System.Drawing.Image]::FromFile($Image)
$w = $X1 - $X0; $h = $Y1 - $Y0
$bmp = New-Object System.Drawing.Bitmap ([int]($w * $Scale)), ([int]($h * $Scale))
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
$g.DrawImage($src, (New-Object System.Drawing.Rectangle(0, 0, $bmp.Width, $bmp.Height)),
    (New-Object System.Drawing.Rectangle($X0, $Y0, $w, $h)), [System.Drawing.GraphicsUnit]::Pixel)
$pen = New-Object System.Drawing.Pen([System.Drawing.Color]::Red, 1)
$font = New-Object System.Drawing.Font('Consolas', 9)
# Grid every 50 source px; labels show SOURCE window coordinates so readings map 1:1.
for ($x = $X0; $x -le $X1; $x += 50) {
    $px = [int](($x - $X0) * $Scale)
    $g.DrawLine($pen, $px, 0, $px, $bmp.Height)
    if ($x -gt $X0) { $g.DrawString([string]$x, $font, [System.Drawing.Brushes]::Red, $px + 2, 2) }
}
for ($y = $Y0; $y -le $Y1; $y += 50) {
    $py = [int]($y - $Y0) * $Scale
    $g.DrawLine($pen, 0, $py, $bmp.Width, $py)
    if ($y -gt $Y0) { $g.DrawString([string]$y, $font, [System.Drawing.Brushes]::Red, 2, $py + 2) }
}
$bmp.Save($Out)
$g.Dispose(); $bmp.Dispose(); $src.Dispose()
"zoom-grid: $Out"
