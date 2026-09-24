"""Drives a WinUI 3 app through UI Automation 3 (COM) control patterns.

Synthetic mouse input is unreliable against WinUI 3 islands on high-DPI
monitors (175% here): rendering is fine and nav rows / sliders / switches
connect, but ButtonBase-derived controls (buttons, radio buttons) ignore
every injected click, and posting WM_MOUSE* to the DesktopChildSiteBridge is
ignored too, because the island consumes WM_POINTER input. The managed UIA2
client (System.Windows.Automation) can't see WinUI 3, the UIA3 ProgID is not
registered, and hand-written .NET ComImport interop trips over VARIANT
marshaling. comtypes generates full bindings from the UIAutomationClient
typelib, which works.

The WinUI 3 UIA tree hangs off the DesktopChildSiteBridge child hwnd, not
the outer window (whose only provider is the shell); ElementFromHandle on the
outer window returns null, so the bridge is located first.

Step grammar (semicolon-separated "verb:Name"):
    invoke:<name>            InvokePattern        buttons, nav items
    select:<name>            SelectionItemPattern radios, list items
    toggle:<name>            TogglePattern        ToggleSwitch, CheckBox
    setvalue:<name>=<text>   ValuePattern         text boxes

Example:
    python uia-smoke.py --exe app.exe --out out --steps "select:Dark"
"""
import argparse
import ctypes
import ctypes.wintypes as wt
import os
import subprocess
import sys
import time

import comtypes.client
from comtypes import COMError
# Generate the comtypes bindings from the typelib embedded in UIAutomationCore.dll
# on first use (cached under comtypes/gen afterwards).
comtypes.client.GetModule('UIAutomationCore.dll')
from comtypes.gen.UIAutomationClient import (
    CUIAutomation,
    IUIAutomation,
    IUIAutomationInvokePattern,
    IUIAutomationSelectionItemPattern,
    IUIAutomationTogglePattern,
    IUIAutomationValuePattern,
    UIA_NamePropertyId,
    UIA_InvokePatternId,
    UIA_SelectionItemPatternId,
    UIA_TogglePatternId,
    UIA_ValuePatternId,
    TreeScope_Descendants,
)

user32 = ctypes.windll.user32


def retry_uia(fn, tries=6, wait=0.5):
    """UIA calls into a busy window get RPC_E_CALL_REJECTED; retry politely."""
    last = None
    for _ in range(tries):
        try:
            return fn()
        except COMError as err:
            last = err
            if err.hresult != -2147418113:  # RPC_E_CALL_REJECTED
                raise
            time.sleep(wait)
    raise last


def find_main_window(pid, timeout_s):
    """Poll for the visible top-level window of the process."""
    result = []
    enum_proc = ctypes.WINFUNCTYPE(
        ctypes.c_bool, wt.HWND, wt.LPARAM)

    def callback(hwnd, _):
        if not user32.IsWindowVisible(hwnd):
            return True
        window_pid = wt.DWORD()
        user32.GetWindowThreadProcessId(hwnd, ctypes.byref(window_pid))
        if window_pid.value == pid:
            result.append(hwnd)
            return False
        return True

    deadline = time.time() + timeout_s
    while time.time() < deadline:
        result.clear()
        user32.EnumWindows(enum_proc(callback), 0)
        if result:
            return result[0]
        time.sleep(0.5)
    return 0


def get_window_rect(hwnd):
    rect = wt.RECT()
    user32.GetWindowRect(hwnd, ctypes.byref(rect))
    return rect


def find_bridge(parent):
    """Largest child hwnd = the DesktopChildSiteBridge hosting the XAML tree."""
    kids = []
    enum_proc = ctypes.WINFUNCTYPE(ctypes.c_bool, wt.HWND, wt.LPARAM)

    def callback(hwnd, _):
        rect = wt.RECT()
        user32.GetWindowRect(hwnd, ctypes.byref(rect))
        kids.append((hwnd, (rect.right - rect.left) * (rect.bottom - rect.top)))
        return True

    user32.EnumChildWindows(parent, enum_proc(callback), 0)
    if not kids:
        return 0
    return max(kids, key=lambda k: k[1])[0]


def save_shot(hwnd, path):
    from PIL import ImageGrab
    rect = get_window_rect(hwnd)
    img = ImageGrab.grab(bbox=(rect.left, rect.top, rect.right, rect.bottom), all_screens=True)
    img.save(path)
    print(f"shot   : {path} ({rect.right - rect.left}x{rect.bottom - rect.top})")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--exe", required=True)
    parser.add_argument("--out", required=True)
    parser.add_argument("--steps", required=True)
    parser.add_argument("--startup", type=float, default=8.0)
    parser.add_argument("--delay", type=float, default=1.2)
    args = parser.parse_args()

    os.makedirs(args.out, exist_ok=True)

    proc = subprocess.Popen([args.exe])
    try:
        hwnd = find_main_window(proc.pid, args.startup)
        if not hwnd:
            raise SystemExit("no main window")
        user32.SetForegroundWindow(hwnd)
        time.sleep(0.5)
        save_shot(hwnd, os.path.join(args.out, "before.png"))

        bridge = find_bridge(hwnd)
        if not bridge:
            raise SystemExit("no XAML island child hwnd")

        uia = comtypes.client.CreateObject(CUIAutomation, interface=IUIAutomation)
        root = uia.ElementFromHandle(bridge)
        if not root:
            raise SystemExit("UIA: ElementFromHandle(bridge) returned nothing")

        verbs = {
            "invoke": (UIA_InvokePatternId, IUIAutomationInvokePattern, "Invoke", 0),
            "select": (UIA_SelectionItemPatternId, IUIAutomationSelectionItemPattern, "Select", 0),
            "toggle": (UIA_TogglePatternId, IUIAutomationTogglePattern, "Toggle", 0),
            "setvalue": (UIA_ValuePatternId, IUIAutomationValuePattern, "SetValue", 1),
        }

        for i, step in enumerate(s for s in args.steps.split(";") if s.strip()):
            step = step.strip()
            verb, _, arg = step.partition(":")
            value = None
            if verb == "setvalue" and "=" in arg:
                arg, _, value = arg.partition("=")

            cond = uia.CreatePropertyCondition(UIA_NamePropertyId, arg)
            el = retry_uia(lambda: root.FindFirst(TreeScope_Descendants, cond))
            if not el:
                print(f"step   : [{i+1}] {verb}:'{arg}' NOT FOUND")
                continue

            state = "enabled" if el.CurrentIsEnabled else "DISABLED"
            info = f"({el.CurrentClassName}, {state})"

            if verb not in verbs:
                print(f"step   : [{i+1}] {verb}:'{arg}' unknown verb {info}")
                continue

            pid_, iface, method, arity = verbs[verb]
            unknown = el.GetCurrentPattern(pid_)
            if not unknown:
                print(f"step   : [{i+1}] {verb}:'{arg}' no pattern {info}")
                continue
            pattern = unknown.QueryInterface(iface)
            if arity == 0:
                getattr(pattern, method)()
                print(f"step   : [{i+1}] {verb}:'{arg}' -> {verb} OK {info}")
            else:
                getattr(pattern, method)(value)
                print(f"step   : [{i+1}] {verb}:'{arg}'='{value}' -> OK {info}")

            time.sleep(args.delay)
            save_shot(hwnd, os.path.join(args.out, f"step-{i+1}.png"))
    finally:
        if proc.poll() is None:
            proc.terminate()


if __name__ == "__main__":
    main()
