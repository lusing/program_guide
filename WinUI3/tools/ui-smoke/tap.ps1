<#
.SYNOPSIS
    Clicks a WinUI 3 control by injecting a touch tap at window-relative pixels.

.DESCRIPTION
    Injected MOUSE input reaches WinUI 3 islands as pointer presses that never
    complete a ButtonBase Click (the press demonstrably lands on the right
    element - app-side diagnostics see it - but the release gets lost in the
    island's legacy-to-pointer translation; nav rows, ToggleSwitch and Slider
    still work). Touch injection walks the real pointer stack via
    InitializeTouchInjection + InjectTouchInput, and ButtonBase must respond to
    taps, so this is the reliable driver for buttons and radio buttons. The
    first InjectTouchInput after initialization can return false and still
    deliver, so a failure is retried once before giving up.

    Coordinates are WINDOW pixels (same space as ui-smoke screenshots).

.EXAMPLE
    ./tap.ps1 -Exe app.exe -OutDir out -X 681 -Y 347
#>
param(
    [Parameter(Mandatory = $true)][string]$Exe,
    [Parameter(Mandatory = $true)][string]$OutDir,
    # Semicolon-separated taps in window coordinates, e.g. '140,166;681,347'.
    [Parameter(Mandatory = $true)][string]$Taps,
    [int]$WindowW = 1080,
    [int]$WindowH = 800,
    [int]$ParkX = 100,
    [int]$ParkY = 100,
    [int]$HoldMs = 120,
    # Relaunch the whole app until the last frame differs from the first one.
    # Injected input into WinUI 3 islands is launch-lottery on some machines:
    # identical taps land on some launches and vanish on others.
    [int]$Attempts = 5,
    # Text typed after the LAST tap (clicks an input field first), and virtual
    # keys sent after that (e.g. 'down,enter' to pick an AutoSuggestBox item).
    [string]$TypeText,
    [string]$KeysAfter,
    # Taps sent after the keyboard phase, e.g. click a dialog button that
    # only exists once text has been typed.
    [string]$TapsAfter
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
        public int X;
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
        [DllImport("user32.dll")] public static extern IntPtr GetForegroundWindow();
        [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr hwnd, out uint processId);
        [DllImport("user32.dll")] public static extern bool SetWindowPos(IntPtr h, IntPtr after, int x, int y, int cx, int cy, uint flags);
        [DllImport("user32.dll")] public static extern bool SetProcessDpiAwarenessContext(IntPtr value);
        [DllImport("user32.dll")] public static extern void keybd_event(byte vk, byte scan, uint flags, System.UIntPtr extra);
        [DllImport("user32.dll")] public static extern ushort VkKeyScanW(char ch);
        public struct RECT { public int Left, Top, Right, Bottom; }
    }

    public static class Tap
    {
        // TOUCH_FEEDBACK_DEFAULT = 1; flags: DOWN 0x1, UP 0x2
        public static string Do(IntPtr hwnd, int screenX, int screenY, int holdMs)
        {
            if (!Native.InitializeTouchInjection(2, 1)) { return "init failed"; }
            var input = new TOUCHINPUT[1];
            input[0].X = screenX;
            input[0].Y = screenY;
            input[0].Handle = IntPtr.Zero;
            input[0].Mask = 0;

            input[0].Flags = 0x0001;   // TOUCHEVENTF_DOWN
            bool down = Native.InjectTouchInput(1, input);
            System.Threading.Thread.Sleep(holdMs);
            input[0].Flags = 0x0002;   // TOUCHEVENTF_UP
            bool up = Native.InjectTouchInput(1, input);
            // The very first call after initialization may report failure and
            // still deliver; retry the pair once on a reported failure.
            if (!down || !up)
            {
                input[0].Flags = 0x0001;
                Native.InjectTouchInput(1, input);
                System.Threading.Thread.Sleep(holdMs);
                input[0].Flags = 0x0002;
                Native.InjectTouchInput(1, input);
                return "tapped (retried; first reported down=" + down + " up=" + up + ")";
            }
            return "tapped";
        }
    }
}
'@
[TouchInj.Native]::SetProcessDpiAwarenessContext([IntPtr](-4)) | Out-Null

$script:vkMap = @{
    'tab' = 0x09; 'space' = 0x20; 'enter' = 0x0D; 'esc' = 0x1B
    'left' = 0x25; 'up' = 0x26; 'right' = 0x27; 'down' = 0x28
    'shift' = 0x10; 'ctrl' = 0x11; 'alt' = 0x12
}
# Letters a-z for accelerators (ctrl+s etc.); hold the modifier while pressing.
for ($code = [int][char]'a'; $code -le [int][char]'z'; $code++) {
    $script:vkMap[[string][char]$code] = $code - 32
}

function Invoke-TypeKeys([string]$text, [string]$keys) {
    if ($text) {
        foreach ($ch in $text.ToCharArray()) {
            $vk = [TouchInj.Native]::VkKeyScanW($ch)
            if ($vk -eq 0) { continue }
            $code = $vk -band 0xFF
            $shift = ((($vk -shr 8) -band 0xFF) -band 1) -eq 1
            if ($shift) { [TouchInj.Native]::keybd_event(0x10, 0, 0, [UIntPtr]::Zero) }
            [TouchInj.Native]::keybd_event($code, 0, 0, [UIntPtr]::Zero)
            [TouchInj.Native]::keybd_event($code, 0, 2, [UIntPtr]::Zero)
            if ($shift) { [TouchInj.Native]::keybd_event(0x10, 0, 2, [UIntPtr]::Zero) }
            Start-Sleep -Milliseconds 60
        }
        "typed  : '$text'"
    }
    foreach ($token in ($keys.Split(',') | Where-Object { $_.Trim() })) {
        $name = $token.Trim().ToLowerInvariant()
        if (-not $vkMap.ContainsKey($name)) { "key    : unknown '$name'"; continue }
        $code = $vkMap[$name]
        [TouchInj.Native]::keybd_event($code, 0, 0, [UIntPtr]::Zero)
        [TouchInj.Native]::keybd_event($code, 0, 2, [UIntPtr]::Zero)
        "key    : $name"
        Start-Sleep -Milliseconds 300
    }
    Start-Sleep -Milliseconds 500
}

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

function Get-FileMd5([string]$path) {
    if (-not (Test-Path $path)) { return '' }
    (Get-FileHash $path -Algorithm MD5).Hash
}

for ($attempt = 1; $attempt -le $Attempts; $attempt++) {
    $proc = Start-Process -FilePath $Exe -PassThru
    try {
        Start-Sleep -Seconds 8
        $proc.Refresh()
        if ($proc.HasExited) { throw "process exited during startup with code $($proc.ExitCode)" }
        if ($proc.MainWindowHandle -eq [IntPtr]::Zero) { throw 'process has no main window' }
        # A background process cannot steal the foreground; the ALT press is the
        # documented workaround (same trick as ui-smoke.ps1). Without it the
        # typed keys land in whatever window really owns the foreground and the
        # taps hit whatever window is on top at that point.
        $foreground = [TouchInj.Native]::GetForegroundWindow()
        $fgpid = [uint32]0
        [TouchInj.Native]::GetWindowThreadProcessId($foreground, [ref]$fgpid) | Out-Null
        if ($fgpid -ne 0 -and $fgpid -ne $proc.Id) {
            [TouchInj.Native]::keybd_event(0x12, 0, 0, [UIntPtr]::Zero)    # ALT down
            [TouchInj.Native]::keybd_event(0x12, 0, 2, [UIntPtr]::Zero)    # ALT up
        }
        $ok = [TouchInj.Native]::SetForegroundWindow($proc.MainWindowHandle)
        "fg     : pid=$fgpid -> ours=$($proc.Id) SetForegroundWindow=$ok"
        # DO NOT move or resize the window at all: any SetWindowPos after the XAML
        # island settles corrupts its input transform (rendering stays correct,
        # hit-testing lands elsewhere, every tap misses). The window stays at its
        # cascade position and taps are computed from the live window rect.
        Start-Sleep -Milliseconds 800
        $beforePath = Join-Path $OutDir 'before.png'
        Save-Shot $proc.MainWindowHandle $beforePath

        $wrect = New-Object TouchInj.Native+RECT
        [TouchInj.Native]::GetWindowRect($proc.MainWindowHandle, [ref]$wrect) | Out-Null

        $seq = @($Taps.Split(';') | Where-Object { $_.Trim() })
        for ($i = 0; $i -lt $seq.Count; $i++) {
            [int[]]$c = $seq[$i].Split(',')
            $result = [TouchInj.Tap]::Do($proc.MainWindowHandle, $wrect.Left + $c[0], $wrect.Top + $c[1], $HoldMs)
            "tap    : [$($i+1)] window($($c[0]),$($c[1])) -> $result"
            Start-Sleep -Milliseconds 1100
            Save-Shot $proc.MainWindowHandle (Join-Path $OutDir ("tap-{0}.png" -f ($i + 1)))
        }

        $shot = $seq.Count
        if ($TypeText -or $KeysAfter) {
            Invoke-TypeKeys $TypeText $KeysAfter
            $shot += 1
            Save-Shot $proc.MainWindowHandle (Join-Path $OutDir ("tap-{0}.png" -f $shot))
        }
        if ($TapsAfter) {
            $wrect = New-Object TouchInj.Native+RECT
            [TouchInj.Native]::GetWindowRect($proc.MainWindowHandle, [ref]$wrect) | Out-Null
            $after = @($TapsAfter.Split(';') | Where-Object { $_.Trim() })
            for ($i = 0; $i -lt $after.Count; $i++) {
                [int[]]$c = $after[$i].Split(',')
                $result = [TouchInj.Tap]::Do($proc.MainWindowHandle, $wrect.Left + $c[0], $wrect.Top + $c[1], $HoldMs)
                "tap    : [after $($i+1)] window($($c[0]),$($c[1])) -> $result"
                Start-Sleep -Milliseconds 1100
                $shot += 1
                Save-Shot $proc.MainWindowHandle (Join-Path $OutDir ("tap-{0}.png" -f $shot))
            }
        }

        $first = Get-FileMd5 $beforePath
        $last = Get-FileMd5 (Join-Path $OutDir ("tap-{0}.png" -f $shot))
        if ($first -ne $last) {
            "result : attempt $attempt changed the window (evidence captured)"
            return
        }
        "result : attempt $attempt was a no-op launch; retrying"
    }
    finally {
        if (-not $proc.HasExited) {
            $null = $proc.CloseMainWindow()
            if (-not $proc.WaitForExit(3000) -and -not $proc.HasExited) {
                Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue
            }
        }
    }
}
throw "no attempt out of $Attempts produced a visible change"
