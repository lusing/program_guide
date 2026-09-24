<#
.SYNOPSIS
    Clicks a WinUI 3 control by injecting a touch tap at absolute screen pixels.

.DESCRIPTION
    Injected MOUSE input reaches WinUI 3 islands as pointer presses that never
    complete a ButtonBase Click (press demonstrably lands on the right element,
    release gets lost in the island's legacy-to-pointer translation). Touch
    injection walks the real pointer stack - InitializeTouchInjection +
    InjectTouchInput - and ButtonBase must respond to taps, so this is the
    reliable driver of last resort. Coordinates are SCREEN pixels.

.EXAMPLE
    ./touch-click.ps1 -Exe app.exe -OutDir out -X 781 -Y 447
#>
param(
    [Parameter(Mandatory = $true)][string]$Exe,
    [Parameter(Mandatory = $true)][string]$OutDir,
    [Parameter(Mandatory = $true)][int]$X,
    [Parameter(Mandatory = $true)][int]$Y,
    [int]$HoldMs = 120
)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;

namespace TouchInj
{
    [StructLayout(LayoutKind.Sequential)]
    public struct TOUCHINPUT
    {
        public int X;              // 0.01mm units for absolute, or pixels for touch
        public int Y;
        public IntPtr Handle;
        public int Flags;
        public int Mask;
        public uint Time;
        public IntPtr ExtraInfo;
    }

    public static class Native
    {
        [DllImport("user32.dll")] public static extern bool InitializeTouchInjection(uint maxCount, uint feedbackMode);
        [DllImport("user32.dll")] public static extern bool InjectTouchInput(uint count, TOUCHINPUT[] contacts);
        [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr h, out RECT r);
        [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr h);
        [DllImport("user32.dll")] public static extern bool SetProcessDpiAwarenessContext(IntPtr value);
        public struct RECT { public int Left, Top, Right, Bottom; }
    }

    public static class Tap
    {
        // TOUCH_FEEDBACK_DEFAULT = 1; flags: DOWN 0x1, UP 0x2
        public static string Do(IntPtr hwnd, int screenX, int screenY, int holdMs)
        {
            if (!Native.InitializeTouchInjection(2, 1)) { return "InitializeTouchInjection failed"; }
            var input = new TOUCHINPUT[1];
            input[0].X = screenX;
            input[0].Y = screenY;
            input[0].Handle = IntPtr.Zero;
            input[0].Mask = 0;

            input[0].Flags = 0x0001;   // TOUCHEVENTF_DOWN
            if (!Native.InjectTouchInput(1, input)) { return "DOWN failed"; }
            System.Threading.Thread.Sleep(holdMs);
            input[0].Flags = 0x0002;   // TOUCHEVENTF_UP
            if (!Native.InjectTouchInput(1, input)) { return "UP failed"; }
            return "tapped";
        }
    }
}
'@
[TouchInj.Native]::SetProcessDpiAwarenessContext([IntPtr](-4)) | Out-Null

function Save-Shot([IntPtr]$hwnd, [string]$path) {
    $rect = New-Object TouchInj.Native+RECT
    [TouchInj.Native]::GetWindowRect($hwnd, [ref]$rect) | Out-Null
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
    Start-Sleep -Seconds 8
    $proc.Refresh()
    if ($proc.HasExited) { throw "process exited during startup with code $($proc.ExitCode)" }
    if ($proc.MainWindowHandle -eq [IntPtr]::Zero) { throw 'process has no main window' }
    [TouchInj.Native]::SetForegroundWindow($proc.MainWindowHandle) | Out-Null
    Start-Sleep -Milliseconds 600
    Save-Shot $proc.MainWindowHandle (Join-Path $OutDir 'before.png')

    $result = [TouchInj.Tap]::Do($proc.MainWindowHandle, $X, $Y, $HoldMs)
    "tap    : ($X,$Y) -> $result"
    Start-Sleep -Milliseconds 1200
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
