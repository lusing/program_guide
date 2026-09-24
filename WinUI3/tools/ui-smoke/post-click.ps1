<#
.SYNOPSIS
    Clicks a WinUI 3 control by posting WM_MOUSE* straight to the XAML island.

.DESCRIPTION
    Injected input (SetCursorPos + mouse_event) never reaches ButtonBase-derived
    controls in some WinUI 3 desktop apps on high-DPI monitors: the render is
    consistently scaled, nav rows / sliders / switches connect, but radio rings and
    buttons ignore every injected click. Posting WM_MOUSEMOVE/WM_LBUTTONDOWN/
    WM_LBUTTONUP directly to the DesktopChildSiteBridge hwnd bypasses the injection
    pipeline entirely. Coordinates are WINDOW-relative (same space as ui-smoke
    screenshots); the script converts them to the bridge's client space.

.EXAMPLE
    ./post-click.ps1 -Exe app.exe -OutDir .\out -X 681 -Y 347
#>
param(
    [Parameter(Mandatory = $true)][string]$Exe,
    [Parameter(Mandatory = $true)][string]$OutDir,
    [Parameter(Mandatory = $true)][int]$X,
    [Parameter(Mandatory = $true)][int]$Y,
    [int]$WindowW = 1080,
    [int]$WindowH = 800,
    [int]$StartupSeconds = 8
)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
Add-Type -Namespace Win32 -Name Pc -MemberDefinition @'
[DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr h, out RECT r);
[DllImport("user32.dll")] public static extern int EnumChildWindows(IntPtr parent, EnumWindowsProc cb, System.IntPtr lp);
[DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr h);
[DllImport("user32.dll")] public static extern bool SetWindowPos(IntPtr h, IntPtr after, int x, int y, int cx, int cy, uint flags);
[DllImport("user32.dll", EntryPoint = "PostMessageW", CharSet = CharSet.Unicode)] public static extern bool PostMsg(IntPtr h, uint msg, int wp, int lp);
[DllImport("user32.dll")] public static extern bool SetProcessDpiAwarenessContext(IntPtr value);
public delegate bool EnumWindowsProc(IntPtr hwnd, System.IntPtr lParam);
public struct RECT { public int Left, Top, Right, Bottom; }
'@
[Win32.Pc]::SetProcessDpiAwarenessContext([IntPtr](-4)) | Out-Null

function Get-Bridge([IntPtr]$parent) {
    $kids = New-Object System.Collections.Generic.List[object]
    $cb = [Win32.Pc+EnumWindowsProc]{
        param($hwnd, $lParam)
        $rect = New-Object Win32.Pc+RECT
        [Win32.Pc]::GetWindowRect($hwnd, [ref]$rect) | Out-Null
        $list = [System.Runtime.InteropServices.GCHandle]::FromIntPtr($lParam).Target
        $list.Add([pscustomobject]@{ Hwnd = $hwnd; Area = ($rect.Right - $rect.Left) * ($rect.Bottom - $rect.Top) })
        return $true
    }
    $pin = [System.Runtime.InteropServices.GCHandle]::Alloc($kids)
    try { [Win32.Pc]::EnumChildWindows($parent, $cb, [System.Runtime.InteropServices.GCHandle]::ToIntPtr($pin)) | Out-Null }
    finally { $pin.Free() }
    $kids | Sort-Object Area -Descending | Select-Object -First 1
}

function Save-Shot([IntPtr]$hwnd, [string]$path) {
    $rect = New-Object Win32.Pc+RECT
    [Win32.Pc]::GetWindowRect($hwnd, [ref]$rect) | Out-Null
    $w = $rect.Right - $rect.Left; $h = $rect.Bottom - $rect.Top
    $bmp = New-Object System.Drawing.Bitmap($w, $h)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.CopyFromScreen($rect.Left, $rect.Top, 0, 0, $bmp.Size)
    $g.Dispose(); $bmp.Save($path, [System.Drawing.Imaging.ImageFormat]::Png); $bmp.Dispose()
    "shot   : $path (${w}x${h}) origin=($($rect.Left),$($rect.Top))"
}

New-Item -ItemType Directory -Force -Path $OutDir | Out-Null
$proc = Start-Process -FilePath $Exe -PassThru
try {
    Start-Sleep -Seconds $StartupSeconds
    $proc.Refresh()
    if ($proc.HasExited) { throw "process exited during startup with code $($proc.ExitCode)" }
    if ($proc.MainWindowHandle -eq [IntPtr]::Zero) { throw 'process has no main window' }
    [Win32.Pc]::SetForegroundWindow($proc.MainWindowHandle) | Out-Null
    [Win32.Pc]::SetWindowPos($proc.MainWindowHandle, [IntPtr]::Zero, 100, 100, $WindowW, $WindowH, 0x0040) | Out-Null
    Start-Sleep -Milliseconds 800
    Save-Shot $proc.MainWindowHandle (Join-Path $OutDir 'before.png')

    $bridge = Get-Bridge $proc.MainWindowHandle
    if (-not $bridge) { throw 'no child hwnds: cannot locate the XAML island' }
    $wrect = New-Object Win32.Pc+RECT
    [Win32.Pc]::GetWindowRect($proc.MainWindowHandle, [ref]$wrect) | Out-Null
    $brect = New-Object Win32.Pc+RECT
    [Win32.Pc]::GetWindowRect($bridge.Hwnd, [ref]$brect) | Out-Null
    # WINDOW-relative click point -> screen -> bridge client
    $cx = ($wrect.Left + $X) - $brect.Left
    $cy = ($wrect.Top + $Y) - $brect.Top
    "bridge : hwnd=$($bridge.Hwnd) client point ($cx,$cy)"

    $lp = (([int]$cy -shl 16) -bor ([int]$cx -band 0xFFFF))
    [void][Win32.Pc]::PostMsg($bridge.Hwnd, 0x0200, 0, $lp)    # WM_MOUSEMOVE
    Start-Sleep -Milliseconds 120
    [void][Win32.Pc]::PostMsg($bridge.Hwnd, 0x0201, 0x0001, $lp)   # WM_LBUTTONDOWN (MK_LBUTTON)
    Start-Sleep -Milliseconds 100
    [void][Win32.Pc]::PostMsg($bridge.Hwnd, 0x0202, 0, $lp)    # WM_LBUTTONUP
    Start-Sleep -Milliseconds 900
    Save-Shot $proc.MainWindowHandle (Join-Path $OutDir 'after.png')
}
finally {
    if (-not $proc.HasExited) {
        $null = $proc.CloseMainWindow()
        if (-not $proc.WaitForExit(3000) -and -not $proc.HasExited) {
            Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue
        }
    }
}
