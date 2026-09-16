<#
.SYNOPSIS
    Launches a WinUI 3 app, screenshots its window, optionally clicks it, screenshots again.

.DESCRIPTION
    Compiling a XAML app proves the markup and projections line up; it says nothing about
    whether the window comes up or whether a Click handler runs. The obvious tool for that is
    UI Automation, but the managed System.Windows.Automation client is UIA2, and WinUI 3
    publishes UIA3 providers only, so a UIA2 client sees nothing but the shell panes. This
    script therefore drives the app the way a user would: bring the window forward, capture
    it, send real mouse input, capture again. Read the two PNGs to judge the result.

.EXAMPLE
    ./ui-smoke.ps1 -Exe ..\..\examples\01-first-app\x64\Debug\MyApp\MyApp.exe `
                   -OutDir ..\..\.smoke\01-first-app
#>
param(
    [Parameter(Mandatory = $true)][string]$Exe,
    [Parameter(Mandatory = $true)][string]$OutDir,
    # Click point, in client coordinates relative to the window centre. The 01-first-app
    # layout is a centred StackPanel with a TextBlock above a Button and Spacing=12, which
    # puts the button centre about 44px below the panel centre.
    [string]$ClickOffset = '0,44',
    # Absolute screen point to click instead of the island-centre computation.
    [string]$ClickAtScreen,
    [int]$StartupSeconds = 8,
    [switch]$NoClick
)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.Windows.Forms

Add-Type -Namespace Win32 -Name Native -MemberDefinition @'
[DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr h, out RECT r);
[DllImport("user32.dll")] public static extern bool GetClientRect(IntPtr h, out RECT r);
[DllImport("user32.dll")] public static extern bool ClientToScreen(IntPtr h, ref POINT p);
[DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr h);
[DllImport("user32.dll")] public static extern bool SetWindowPos(IntPtr h, IntPtr after, int x, int y, int cx, int cy, uint flags);
[DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr h, int cmd);
[DllImport("user32.dll")] public static extern bool SetCursorPos(int x, int y);
[DllImport("user32.dll")] public static extern void mouse_event(uint flags, uint dx, uint dy, uint data, System.UIntPtr extra);
[DllImport("user32.dll")] public static extern bool EnumChildWindows(IntPtr parent, EnumWindowsProc callback, System.IntPtr lParam);
[DllImport("user32.dll")] public static extern int GetClassName(IntPtr h, System.Text.StringBuilder className, int maxCount);
[DllImport("user32.dll")] public static extern bool SetProcessDpiAwarenessContext(IntPtr value);
[DllImport("user32.dll")] public static extern IntPtr GetForegroundWindow();
[DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr hwnd, out uint processId);
[DllImport("user32.dll")] public static extern void keybd_event(byte vk, byte scan, uint flags, System.UIntPtr extra);
[DllImport("user32.dll")] public static extern bool GetCursorPos(out POINT p);
public delegate bool EnumWindowsProc(IntPtr hwnd, System.IntPtr lParam);
public struct RECT { public int Left, Top, Right, Bottom; }
public struct POINT { public int X, Y; }
'@

# Every coordinate below must be in the same space; a DPI-unaware process gets some of
# these virtualized and some physical, which silently skews both captures and clicks.
[Win32.Native]::SetProcessDpiAwarenessContext([IntPtr](-4)) | Out-Null   # PER_MONITOR_AWARE_V2

# A background process has no right to steal the foreground; the Alt press is the documented
# workaround, and without it the click would land on whatever window really owns it.
function Invoke-BringForward([IntPtr]$hwnd) {
    $foreground = [Win32.Native]::GetForegroundWindow()
    $pid_ = [uint32]0
    [Win32.Native]::GetWindowThreadProcessId($foreground, [ref]$pid_) | Out-Null
    if ($pid_ -ne 0) {
        "fg     : pid=$pid_"
        [Win32.Native]::keybd_event(0x12, 0, 0, [UIntPtr]::Zero)          # ALT down
        [Win32.Native]::keybd_event(0x12, 0, 2, [UIntPtr]::Zero)          # ALT up
    }
    $ok = [Win32.Native]::SetForegroundWindow($hwnd)
    "bring  : SetForegroundWindow=$ok"
}

# MainWindowHandle is the outer shadow hwnd; the XAML island lives in a child window, and
# only that child's client area lines up with the XAML layout.
function Get-LargestChild([IntPtr]$parent) {
    $children = New-Object System.Collections.Generic.List[object]
    $callback = [Win32.Native+EnumWindowsProc]{
        param($hwnd, $lParam)
        $rect = New-Object Win32.Native+RECT
        [Win32.Native]::GetWindowRect($hwnd, [ref]$rect) | Out-Null
        $name = New-Object System.Text.StringBuilder 256
        [Win32.Native]::GetClassName($hwnd, $name, 256) | Out-Null
        $list = [System.Runtime.InteropServices.GCHandle]::FromIntPtr($lParam).Target
        $list.Add([pscustomobject]@{
            Hwnd = $hwnd
            Class = $name.ToString()
            Area = ($rect.Right - $rect.Left) * ($rect.Bottom - $rect.Top)
        })
        return $true
    }
    $pin = [System.Runtime.InteropServices.GCHandle]::Alloc($children)
    try {
        [Win32.Native]::EnumChildWindows($parent, $callback, [System.Runtime.InteropServices.GCHandle]::ToIntPtr($pin)) | Out-Null
    }
    finally { $pin.Free() }

    $children | Sort-Object Area -Descending | Select-Object -First 1
}

function Save-WindowShot([IntPtr]$hwnd, [string]$path) {
    $rect = New-Object Win32.Native+RECT
    if (-not [Win32.Native]::GetWindowRect($hwnd, [ref]$rect)) { throw "GetWindowRect failed for $hwnd" }
    $width = $rect.Right - $rect.Left
    $height = $rect.Bottom - $rect.Top
    if ($width -le 0 -or $height -le 0) { throw "window has no area: ${width}x${height}" }

    $bitmap = New-Object System.Drawing.Bitmap($width, $height)
    try {
        $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
        try {
            $graphics.CopyFromScreen($rect.Left, $rect.Top, 0, 0, $bitmap.Size)
        }
        finally { $graphics.Dispose() }
        $bitmap.Save($path, [System.Drawing.Imaging.ImageFormat]::Png)
    }
    finally { $bitmap.Dispose() }
    "shot   : $path (${width}x${height}) origin=($($rect.Left),$($rect.Top))"
}

New-Item -ItemType Directory -Force -Path $OutDir | Out-Null

$proc = Start-Process -FilePath $Exe -PassThru
try {
    Start-Sleep -Seconds $StartupSeconds
    $proc.Refresh()
    if ($proc.HasExited) { throw "process exited during startup with code $($proc.ExitCode)" }
    if ($proc.MainWindowHandle -eq [IntPtr]::Zero) { throw 'process has no main window' }
    "window : [$($proc.MainWindowTitle)] pid=$($proc.Id)"

    Invoke-BringForward $proc.MainWindowHandle
    [Win32.Native]::ShowWindow($proc.MainWindowHandle, 9) | Out-Null   # SW_RESTORE
    # Park the window fully on-screen: a clipped capture would put the "centre" off the panel.
    [Win32.Native]::SetWindowPos($proc.MainWindowHandle, [IntPtr]::Zero, 100, 100, 900, 600, 0x0040) | Out-Null
    Start-Sleep -Milliseconds 800
    Save-WindowShot $proc.MainWindowHandle (Join-Path $OutDir 'before.png')

    if (-not $NoClick) {
        if ($ClickAtScreen) {
            [int[]]$point = $ClickAtScreen.Split(',')
            $x = $point[0]
            $y = $point[1]
            "click  : screen($x,$y) (explicit)"
        }
        else {
            $island = Get-LargestChild $proc.MainWindowHandle
            if (-not $island) { throw 'no child windows: cannot locate the XAML island' }
            "island : class=$($island.Class) area=$($island.Area)"

            $client = New-Object Win32.Native+RECT
            if (-not [Win32.Native]::GetClientRect($island.Hwnd, [ref]$client)) { throw 'GetClientRect failed' }
            $origin = New-Object Win32.Native+POINT
            if (-not [Win32.Native]::ClientToScreen($island.Hwnd, [ref]$origin)) { throw 'ClientToScreen failed' }

            [int[]]$offset = $ClickOffset.Split(',')
            $x = $origin.X + [int]($client.Right / 2) + $offset[0]
            $y = $origin.Y + [int]($client.Bottom / 2) + $offset[1]
            "click  : island($($client.Right)x$($client.Bottom)) -> screen($x,$y)"
        }

        [Win32.Native]::SetCursorPos($x, $y) | Out-Null
        $cursor = New-Object Win32.Native+POINT
        [Win32.Native]::GetCursorPos([ref]$cursor) | Out-Null
        "cursor : ($($cursor.X),$($cursor.Y))"
        Start-Sleep -Milliseconds 300
        [Win32.Native]::mouse_event(0x0002, 0, 0, 0, [UIntPtr]::Zero)   # LEFTDOWN
        [Win32.Native]::mouse_event(0x0004, 0, 0, 0, [UIntPtr]::Zero)   # LEFTUP
        Start-Sleep -Seconds 2
        Save-WindowShot $proc.MainWindowHandle (Join-Path $OutDir 'after.png')
    }
}
finally {
    if (-not $proc.HasExited) { Stop-Process -Id $proc.Id -Force }
}
