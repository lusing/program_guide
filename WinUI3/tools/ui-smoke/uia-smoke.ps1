<#
.SYNOPSIS
    Drives a WinUI 3 app through UI Automation 3 (COM) control patterns.

.DESCRIPTION
    Synthetic mouse input is unreliable against WinUI 3 islands on high-DPI
    monitors (175% here): rendering is fine and nav rows / sliders / switches
    connect, but ButtonBase-derived controls (buttons, radio buttons) ignore
    every injected click, and posting WM_MOUSE* to the DesktopChildSiteBridge
    is ignored too, because the island consumes WM_POINTER input. The managed
    UIA2 client (System.Windows.Automation) can't see WinUI 3 either, and the
    UIA3 ProgID is unregistered - but the COM class itself is fine once the
    interfaces are declared by hand. Two hard-won rules from that exercise:
    every [ComImport] interface needs [InterfaceType(ComInterfaceType.
    InterfaceIsIUnknown)] or calls die with NullReferenceException, and PS
    must never touch an interface-typed value (it degrades to __ComObject and
    refuses to convert back), so all COM lives inside the C# Driver with a
    single Do(verb, name, value) entry point. Vtable order (with placeholder
    slots for everything we never call) comes from UIAutomationClient.h in the
    Windows SDK.

    Step grammar (semicolon-separated "verb:Name"):
        invoke:<name>   InvokePattern       buttons, menu items, nav items
        select:<name>   SelectionItemPattern radios, list items, nav items
        toggle:<name>   TogglePattern        ToggleSwitch, CheckBox
        setvalue:<name>=<text>  ValuePattern  text boxes

.EXAMPLE
    ./uia-smoke.ps1 -Exe app.exe -OutDir out -Steps 'select:Dark'
    ./uia-smoke.ps1 -Exe app.exe -OutDir out -Steps 'select:Notifications;toggle:Notifications'
#>
param(
    [Parameter(Mandatory = $true)][string]$Exe,
    [Parameter(Mandatory = $true)][string]$OutDir,
    [Parameter(Mandatory = $true)][string]$Steps,
    [int]$StartupSeconds = 8,
    [int]$StepDelayMs = 1200
)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;

namespace Uia
{
    [ComImport, InterfaceType(ComInterfaceType.InterfaceIsIUnknown),
     Guid("352ffba8-0973-437c-a61f-f64cafd81df9")]
    public interface IUIAutomationCondition { }

    [ComImport, InterfaceType(ComInterfaceType.InterfaceIsIUnknown),
     Guid("d22108aa-8ac5-49a5-837b-37bbb3d7591e")]
    public interface IUIAutomationElement
    {
        void SetFocus();                                          // slot 1
        void _GetRuntimeId();                                     // slot 2 (unused)
        void FindFirst(int scope, IUIAutomationCondition condition,
                       out IUIAutomationElement found);           // slot 3
        void _FindAll();                                          // slot 4
        void _FindFirstBuildCache();                              // slot 5
        void _FindAllBuildCache();                                // slot 6
        void _BuildUpdatedCache();                                // slot 7
        void _GetCurrentPropertyValue();                          // slot 8
        void _GetCurrentPropertyValueEx();                        // slot 9
        void _GetCachedPropertyValue();                           // slot 10
        void _GetCachedPropertyValueEx();                         // slot 11
        void _GetCurrentPatternAs();                              // slot 12
        void _GetCachedPatternAs();                               // slot 13
        void GetCurrentPattern(int patternId,
            [MarshalAs(UnmanagedType.IUnknown)] out object pattern); // slot 14
        void _GetCachedPattern();                                 // slot 15
        void _GetCachedParent();                                  // slot 16
        void _GetCachedChildren();                                // slot 17
        int CurrentProcessId { get; }                             // slot 18
        int CurrentControlType { get; }                           // slot 19
        string CurrentLocalizedControlType { get; }               // slot 20
        string CurrentName { get; }                               // slot 21
        string CurrentAcceleratorKey { get; }                     // slot 22
        string CurrentAccessKey { get; }                          // slot 23
        int CurrentHasKeyboardFocus { get; }                      // slot 24
        int CurrentIsKeyboardFocusable { get; }                   // slot 25
        int CurrentIsEnabled { get; }                             // slot 26
        string CurrentAutomationId { get; }                       // slot 27
        string CurrentClassName { get; }                          // slot 28
    }

    [ComImport, InterfaceType(ComInterfaceType.InterfaceIsIUnknown),
     Guid("30cbe57d-d9d0-452a-ab13-7ac5ac4825ee")]
    public interface IUIAutomation
    {
        void _CompareElements();                                  // slot 1
        void _CompareRuntimeIds();                                // slot 2
        void _GetRootElement();                                   // slot 3
        void ElementFromHandle(IntPtr hwnd, out IUIAutomationElement element); // slot 4
        void _ElementFromPoint();                                 // slot 5
        void _GetFocusedElement();                                // slot 6
        void _GetRootElementBuildCache();                         // slot 7
        void _ElementFromHandleBuildCache();                      // slot 8
        void _ElementFromPointBuildCache();                       // slot 9
        void _GetFocusedElementBuildCache();                      // slot 10
        void _CreateTreeWalker();                                 // slot 11
        void _ControlViewWalker();                                // slot 12
        void _ContentViewWalker();                                // slot 13
        void _RawViewWalker();                                    // slot 14
        void _RawViewCondition();                                 // slot 15
        void _ControlViewCondition();                             // slot 16
        void _ContentViewCondition();                             // slot 17
        void _CreateCacheRequest();                               // slot 18
        void _CreateTrueCondition();                              // slot 19
        void _CreateFalseCondition();                             // slot 20
        void CreatePropertyCondition(int propertyId,
                                     [MarshalAs(UnmanagedType.Struct)] object value,
                                     out IUIAutomationCondition condition); // slot 21
    }

    [ComImport, InterfaceType(ComInterfaceType.InterfaceIsIUnknown),
     Guid("fb377fbe-8ea6-46d5-9c73-6499642d3059")]
    public interface IUIAutomationInvokePattern { void Invoke(); }

    [ComImport, InterfaceType(ComInterfaceType.InterfaceIsIUnknown),
     Guid("a8efa66a-0fda-421a-9194-38021f3578ea")]
    public interface IUIAutomationSelectionItemPattern
    {
        void Select();
        void AddToSelection();
        void RemoveFromSelection();
        int CurrentIsSelected { get; }
    }

    [ComImport, InterfaceType(ComInterfaceType.InterfaceIsIUnknown),
     Guid("94cf8058-9b8d-4ab9-8bfd-4cd0a33c8c70")]
    public interface IUIAutomationTogglePattern
    {
        void Toggle();
        int CurrentToggleState { get; }
        int CachedToggleState { get; }
    }

    [ComImport, InterfaceType(ComInterfaceType.InterfaceIsIUnknown),
     Guid("a94cd8b1-0844-4cd6-9d2d-640537ab39e9")]
    public interface IUIAutomationValuePattern
    {
        void SetValue(string val);
        string CurrentValue { get; }
    }

    [ComImport, Guid("ff48dba4-60ef-4201-aa87-54103eef594e")]
    class CUIAutomationClass { }

    public static class Driver
    {
        const int NameProperty = 30009;
        const int InvokePattern = 10000;
        const int SelectionItemPattern = 10010;
        const int TogglePattern = 10015;
        const int ValuePattern = 10002;
        const int TreeScopeDescendants = 0x4;

        static IUIAutomationElement s_root;

        public static void Init(IntPtr hwnd)
        {
            var uia = (IUIAutomation)new CUIAutomationClass();
            // The WinUI 3 UIA tree hangs off the DesktopChildSiteBridge child
            // hwnd; ElementFromHandle on the outer window yields null.
            uia.ElementFromHandle(hwnd, out s_root);
        }

        static IUIAutomationElement Find(string name)
        {
            var uia = (IUIAutomation)new CUIAutomationClass();
            IUIAutomationCondition cond;
            uia.CreatePropertyCondition(NameProperty, name, out cond);
            IUIAutomationElement el;
            s_root.FindFirst(TreeScopeDescendants, cond, out el);
            return el;
        }

        // Single entry point so PowerShell never sees a COM interface type
        // (they degrade to __ComObject and refuse to convert back).
        public static string Do(string verb, string name, string value)
        {
            var el = Find(name);
            if (el == null) { return "NOT FOUND"; }
            string state = el.CurrentIsEnabled != 0 ? "enabled" : "DISABLED";
            string info = "(" + el.CurrentClassName + ", " + state + ")";

            object p;
            switch (verb)
            {
                case "invoke":
                    el.GetCurrentPattern(InvokePattern, out p);
                    if (p == null) { return "no InvokePattern " + info; }
                    ((IUIAutomationInvokePattern)p).Invoke();
                    return "invoked " + info;
                case "select":
                    el.GetCurrentPattern(SelectionItemPattern, out p);
                    if (p == null) { return "no SelectionItemPattern " + info; }
                    ((IUIAutomationSelectionItemPattern)p).Select();
                    return "selected " + info;
                case "toggle":
                    el.GetCurrentPattern(TogglePattern, out p);
                    if (p == null) { return "no TogglePattern " + info; }
                    ((IUIAutomationTogglePattern)p).Toggle();
                    return "toggled " + info;
                case "setvalue":
                    el.GetCurrentPattern(ValuePattern, out p);
                    if (p == null) { return "no ValuePattern " + info; }
                    ((IUIAutomationValuePattern)p).SetValue(value);
                    return "set '" + value + "' " + info;
                default:
                    return "unknown verb '" + verb + "'";
            }
        }
    }
}
'@

Add-Type -Namespace Win32 -Name Us -MemberDefinition @'
[DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr h, out RECT r);
[DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr h);
[DllImport("user32.dll")] public static extern bool SetProcessDpiAwarenessContext(IntPtr value);
[DllImport("user32.dll")] public static extern int EnumChildWindows(IntPtr parent, EnumWindowsProc cb, System.IntPtr lp);
public delegate bool EnumWindowsProc(IntPtr hwnd, System.IntPtr lParam);
public struct RECT { public int Left, Top, Right, Bottom; }
'@
[Win32.Us]::SetProcessDpiAwarenessContext([IntPtr](-4)) | Out-Null

function Get-Bridge([IntPtr]$parent) {
    $kids = New-Object System.Collections.Generic.List[object]
    $cb = [Win32.Us+EnumWindowsProc]{
        param($hwnd, $lParam)
        $rect = New-Object Win32.Us+RECT
        [Win32.Us]::GetWindowRect($hwnd, [ref]$rect) | Out-Null
        $list = [System.Runtime.InteropServices.GCHandle]::FromIntPtr($lParam).Target
        $list.Add([pscustomobject]@{ Hwnd = $hwnd; Area = ($rect.Right - $rect.Left) * ($rect.Bottom - $rect.Top) })
        return $true
    }
    $pin = [System.Runtime.InteropServices.GCHandle]::Alloc($kids)
    try { [Win32.Us]::EnumChildWindows($parent, $cb, [System.Runtime.InteropServices.GCHandle]::ToIntPtr($pin)) | Out-Null }
    finally { $pin.Free() }
    ($kids | Sort-Object Area -Descending | Select-Object -First 1).Hwnd
}

function Save-Shot([IntPtr]$hwnd, [string]$path) {
    $rect = New-Object Win32.Us+RECT
    [Win32.Us]::GetWindowRect($hwnd, [ref]$rect) | Out-Null
    $w = $rect.Right - $rect.Left; $h = $rect.Bottom - $rect.Top
    $bmp = New-Object System.Drawing.Bitmap($w, $h)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.CopyFromScreen($rect.Left, $rect.Top, 0, 0, $bmp.Size)
    $g.Dispose(); $bmp.Save($path, [System.Drawing.Imaging.ImageFormat]::Png); $bmp.Dispose()
    "shot   : $path (${w}x${h})"
}

New-Item -ItemType Directory -Force -Path $OutDir | Out-Null
$proc = Start-Process -FilePath $Exe -PassThru
try {
    Start-Sleep -Seconds $StartupSeconds
    $proc.Refresh()
    if ($proc.HasExited) { throw "process exited during startup with code $($proc.ExitCode)" }
    if ($proc.MainWindowHandle -eq [IntPtr]::Zero) { throw 'process has no main window' }
    [Win32.Us]::SetForegroundWindow($proc.MainWindowHandle) | Out-Null
    Start-Sleep -Milliseconds 500
    Save-Shot $proc.MainWindowHandle (Join-Path $OutDir 'before.png')

    $bridge = Get-Bridge $proc.MainWindowHandle
    if (-not $bridge) { throw 'no child hwnds: cannot locate the XAML island' }
    [Uia.Driver]::Init($bridge)
    "uia    : root ready (bridge hwnd=$bridge)"

    $seq = @($Steps.Split(';') | Where-Object { $_.Trim() })
    for ($i = 0; $i -lt $seq.Count; $i++) {
        $step = $seq[$i].Trim()
        $verb, $arg = $step.Split(':', 2)
        $value = $null
        if ($verb -eq 'setvalue' -and $arg -like '*=*') { $parts = $arg -split '=', 2; $arg = $parts[0]; $value = $parts[1] }

        $result = [Uia.Driver]::Do($verb, $arg, $value)
        "step   : [$($i+1)] $($verb):'$arg' -> $result"
        Start-Sleep -Milliseconds $StepDelayMs
        Save-Shot $proc.MainWindowHandle (Join-Path $OutDir ("step-{0}.png" -f ($i + 1)))
    }
}
finally {
    if (-not $proc.HasExited) {
        $null = $proc.CloseMainWindow()
        if (-not $proc.WaitForExit(3000) -and -not $proc.HasExited) {
            Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue
        }
    }
}
