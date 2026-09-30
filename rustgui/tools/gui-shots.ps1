param(
    # 要截图的示例目录名列表；默认全部
    [string[]]$Names,
    # 每个窗口启动后等待的毫秒数
    [int]$WaitMs = 2000
)

# 真窗口人工验证辅助：逐个启动示例（不带 --selftest，开真窗口），
# 前置 + 取窗口矩形 + 截屏存 build/gui-shots/NN.png，然后关闭。
# 用法：pwsh -File tools/gui-shots.ps1            全部 22 个
#       pwsh -File tools/gui-shots.ps1 02_egui_hello  只截一个

$ErrorActionPreference = "Stop"
$projectRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Set-Location $projectRoot
try { [Console]::OutputEncoding = [System.Text.UTF8Encoding]::new() } catch { }

Add-Type -AssemblyName System.Drawing
Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
public static class GuiShotWin32 {
    [DllImport("user32.dll")] public static extern bool SetProcessDPIAware();
    [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr hWnd);
    [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr hWnd, out RECT rect);
    [StructLayout(LayoutKind.Sequential)]
    public struct RECT { public int Left, Top, Right, Bottom; }
}
"@
[void][GuiShotWin32]::SetProcessDPIAware()  # 让坐标与像素一致（高 DPI 下不糊不偏）

$shotsDir = Join-Path $projectRoot "build\gui-shots"
New-Item -ItemType Directory -Force $shotsDir | Out-Null

if (-not $Names) {
    $Names = Get-ChildItem "examples" -Directory | Sort-Object Name | Select-Object -ExpandProperty Name
}

$summary = @()
foreach ($name in $Names) {
    $pkg = $name -replace '^\d+_?', ''
    $exe = Join-Path $projectRoot "target\debug\$pkg.exe"
    if (-not (Test-Path -LiteralPath $exe)) {
        $summary += "$name MISSING_EXE"
        continue
    }

    $p = Start-Process -FilePath $exe -WorkingDirectory $projectRoot -PassThru

    # 先等渲染稳定，再取主窗口句柄——太早取会抓到框架启动期的
    # 临时小窗（实测 200ms 时拿到 24x24 的占位窗，三框架皆有此现象）
    Start-Sleep -Milliseconds $WaitMs
    $handle = [IntPtr]::Zero
    $deadline = [DateTime]::Now.AddSeconds(6)
    while ([DateTime]::Now -lt $deadline) {
        $p.Refresh()
        if ($p.HasExited) { break }
        if ($p.MainWindowHandle -ne 0) { $handle = $p.MainWindowHandle; break }
        Start-Sleep -Milliseconds 200
    }

    if ($handle -eq [IntPtr]::Zero) {
        $summary += "$name NO_WINDOW"
        if (-not $p.HasExited) { Stop-Process -Id $p.Id -Force -ErrorAction SilentlyContinue }
        continue
    }

    [void][GuiShotWin32]::SetForegroundWindow($handle)
    Start-Sleep -Milliseconds 300

    $r = New-Object GuiShotWin32+RECT
    [void][GuiShotWin32]::GetWindowRect($handle, [ref]$r)
    $w = $r.Right - $r.Left
    $h = $r.Bottom - $r.Top
    if ($w -le 0 -or $h -le 0) {
        $summary += "$name BAD_RECT ${w}x${h}"
        Stop-Process -Id $p.Id -Force -ErrorAction SilentlyContinue
        continue
    }

    $bmp = [System.Drawing.Bitmap]::new($w, $h)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.CopyFromScreen($r.Left, $r.Top, 0, 0, [System.Drawing.Size]::new($w, $h))
    $g.Dispose()
    $out = Join-Path $shotsDir "$name.png"
    $bmp.Save($out, [System.Drawing.Imaging.ImageFormat]::Png)
    $bmp.Dispose()
    Stop-Process -Id $p.Id -Force -ErrorAction SilentlyContinue
    $summary += "$name OK ${w}x${h}"
}

$summary | ForEach-Object { Write-Host $_ }
$okCount = ($summary | Where-Object { $_ -match ' OK ' }).Count
Write-Host "`n[Summary] 截图成功 $okCount / $($Names.Count)（产物 build/gui-shots/）"
exit ($(if ($okCount -eq $Names.Count) { 0 } else { 1 }))
