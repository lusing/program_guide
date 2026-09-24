<#
.SYNOPSIS
    Finds blobs of a target colour in a PNG and prints their bounding boxes/centres.

.DESCRIPTION
    Vision models read the zoom-grid labels unreliably (three rounds, three different
    coordinate mappings), so smoke-test geometry is measured programmatically instead:
    scan the screenshot for pixels within tolerance of a target colour, flood-fill them
    into connected components, and report each blob's centre in source pixel space.
    Accent buttons, the ToggleSwitch thumb and radio rings are all single-colour
    shapes that come out of this exactly.

.EXAMPLE
    ./find-blob.ps1 -Image shot.png -R 0 -G 120 -B 212 -Tolerance 40 -MinW 80 -MaxH 60
    # accent button: wide, short
    ./find-blob.ps1 -Image shot.png -R 138 -G 138 -B 138 -Tolerance 20 -MinW 24 -MaxW 44 -MinH 24 -MaxH 44
    # unselected radio rings: near-square mid-gray blobs
#>
param(
    [Parameter(Mandatory = $true)][string]$Image,
    [Parameter(Mandatory = $true)][int]$R,
    [Parameter(Mandatory = $true)][int]$G,
    [Parameter(Mandatory = $true)][int]$B,
    [int]$Tolerance = 30,
    # Blob bounding-box filters, in pixels; defaults accept everything.
    [int]$MinW = 1, [int]$MaxW = 100000,
    [int]$MinH = 1, [int]$MaxH = 100000,
    # Ignore blobs left/right of these x bounds (e.g. skip the nav pane).
    [int]$XMin = 0, [int]$XMax = 100000,
    [int]$Top = 8
)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

$bmp = [System.Drawing.Image]::FromFile($Image)
try {
    $w = $bmp.Width; $h = $bmp.Height
    $rect = New-Object System.Drawing.Rectangle(0, 0, $w, $h)
    $data = $bmp.LockBits($rect, [System.Drawing.Imaging.ImageLockMode]::ReadOnly,
                          [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $stride = $data.Stride
    $bytes = New-Object byte[] ($stride * $h)
    [System.Runtime.InteropServices.Marshal]::Copy($data.Scan0, $bytes, 0, $bytes.Length)
    $bmp.UnlockBits($data)
}
finally { $bmp.Dispose() }

function Test-Pixel([int]$x, [int]$y) {
    $o = $y * $stride + $x * 4
    return  [Math]::Abs($bytes[$o + 2] - $R) -le $Tolerance -and
            [Math]::Abs($bytes[$o + 1] - $G) -le $Tolerance -and
            [Math]::Abs($bytes[$o + 0] - $B) -le $Tolerance
}

$visited = New-Object 'bool[]' ($w * $h)
$blobs = New-Object System.Collections.Generic.List[object]
for ($y = 0; $y -lt $h; $y++) {
    for ($x = 0; $x -lt $w; $x++) {
        if ($visited[$y * $w + $x] -or -not (Test-Pixel $x $y)) { continue }
        # Flood fill this component; blobs are small so a plain stack is fine.
        $stack = New-Object System.Collections.Generic.Stack[object]
        $stack.Push(@($x, $y)); $visited[$y * $w + $x] = $true
        $minX = $x; $maxX = $x; $minY = $y; $maxY = $y; $area = 0
        while ($stack.Count -gt 0) {
            $p = $stack.Pop(); $px = $p[0]; $py = $p[1]; $area++
            if ($px -lt $minX) { $minX = $px }; if ($px -gt $maxX) { $maxX = $px }
            if ($py -lt $minY) { $minY = $py }; if ($py -gt $maxY) { $maxY = $py }
            foreach ($d in @(@(1, 0), @(-1, 0), @(0, 1), @(0, -1))) {
                $nx = $px + $d[0]; $ny = $py + $d[1]
                if ($nx -lt 0 -or $ny -lt 0 -or $nx -ge $w -or $ny -ge $h) { continue }
                if ($visited[$ny * $w + $nx]) { continue }
                if (Test-Pixel $nx $ny) { $visited[$ny * $w + $nx] = $true; $stack.Push(@($nx, $ny)) }
            }
        }
        $bw = $maxX - $minX + 1; $bh = $maxY - $minY + 1
        $cx = [int](($minX + $maxX) / 2); $cy = [int](($minY + $maxY) / 2)
        if ($bw -lt $MinW -or $bw -gt $MaxW -or $bh -lt $MinH -or $bh -gt $MaxH) { continue }
        if ($cx -lt $XMin -or $cx -gt $XMax) { continue }
        $blobs.Add([pscustomobject]@{
            Centre = "($cx,$cy)"; X = $cx; Y = $cy
            Box = "${bw}x${bh} @($minX,$minY)"; Area = $area
        })
    }
}

$blobs | Sort-Object Area -Descending | Select-Object -First $Top |
    Format-Table Centre, Box, Area -AutoSize | Out-String -Width 120
