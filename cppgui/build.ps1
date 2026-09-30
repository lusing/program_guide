param(
    [switch]$All,
    [string]$Example,
    [switch]$Clean,
    [switch]$ConfigureOnly,
    [switch]$SkipConfigure,
    [switch]$Verbose
)

# ============================================================
# build.ps1 —— cppgui 教程统一验证入口（Windows/MSVC 版）
#
# 判定标准（与 run-all.sh 对齐）：
#   1. CMake 构建 exit 0
#   2. <exe> --selftest 运行 exit 0（60s 超时保护）
#   3. 运行 stderr 为空
#   4. stdout 含 "==== NN " 且含 " 结束 ===="——或（控制台直写型 UI，
#      如 tvision）sidecar 文件 build/selftest-<name>.txt 含同样标记
#   5. stdout 判定路径连跑两次区间逐字节一致（确定性输出约定）
#
# 用法：
#   pwsh build.ps1 -All                    全部示例
#   pwsh build.ps1 -Example 01_wx_hello    单个示例（不带 .cpp）
#   pwsh build.ps1 -Clean                  清理 build 目录
#   pwsh build.ps1 -ConfigureOnly          只做 CMake 配置
# 依赖：tools/build-wx.ps1 先行产出 build/dep-wx（wx 部分）。
# ============================================================

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $projectRoot
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$buildDir = Join-Path $projectRoot 'build'
$binDir   = Join-Path $buildDir 'bin'

if ($Clean) {
    if (Test-Path -LiteralPath $buildDir) {
        Remove-Item -LiteralPath $buildDir -Recurse -Force
        Write-Host "[Clean] 已清理 build 目录（wx 预构建 dep-wx 一并删除，build-wx.ps1 会重建）。" -ForegroundColor Yellow
    } else {
        Write-Host "[Clean] build 目录不存在。" -ForegroundColor Yellow
    }
    exit 0
}

# ---- vcvars 探测：vswhere 最新优先，回退已知路径 ----
$vcvars = $null
$vswhere = 'C:/Program Files (x86)/Microsoft Visual Studio/Installer/vswhere.exe'
if (Test-Path $vswhere) {
    $paths = @(& $vswhere -latest -property installationPath) + @(& $vswhere -all -property installationPath)
    foreach ($p in $paths) {
        if ($p -and (Test-Path "$p/VC/Auxiliary/Build/vcvars64.bat")) { $vcvars = "$p/VC/Auxiliary/Build/vcvars64.bat"; break }
    }
}
if (-not $vcvars) { $vcvars = 'G:/Program Files/Microsoft Visual Studio/2022/Community/VC/Auxiliary/Build/vcvars64.bat' }
if (-not (Test-Path $vcvars)) { throw "未找到 vcvars64.bat（$vcvars）" }
Write-Host "[env] MSVC: $vcvars" -ForegroundColor DarkGray

# ---- wx 预构建就绪检查 ----
if (-not (Test-Path "$projectRoot/build/dep-wx/lib/cmake/wxWidgets")) {
    Write-Host "[wx] dep-wx 未就绪，调用 tools/build-wx.ps1（首次 10–20 分钟）……" -ForegroundColor Yellow
    & pwsh -NoProfile -File (Join-Path $projectRoot 'tools/build-wx.ps1')
    if ($LASTEXITCODE -ne 0) { throw "wxWidgets 预构建失败" }
}

# ---- CMake 配置（幂等：缓存存在时秒过，失败残留的半截缓存也能自愈） ----
if (-not $SkipConfigure) {
    Write-Host "[cmake] configure --preset msvc-x64" -ForegroundColor Cyan
    & cmd /d /s /c "call `"$vcvars`" && cmake --preset msvc-x64"
    if ($LASTEXITCODE -ne 0) { throw "CMake 配置失败" }
    Set-Location $projectRoot
}
if ($ConfigureOnly) { Write-Host "[Done] 仅配置完成。" -ForegroundColor Green; exit 0 }

# ---- 收集目标 ----
function Get-ExampleNames {
    Get-ChildItem -LiteralPath (Join-Path $projectRoot 'examples') -Filter '*.cpp' |
        ForEach-Object { $_.BaseName } | Sort-Object
}
if ($All) { $targets = Get-ExampleNames }
elseif ($Example) { $targets = @($Example) }
else {
    Write-Host "用法:" -ForegroundColor Yellow
    Write-Host "  .\build.ps1 -All                  构建并 selftest 全部示例"
    Write-Host "  .\build.ps1 -Example <NN_name>    单个示例（不带 .cpp）"
    Write-Host "  .\build.ps1 -ConfigureOnly        只做 CMake 配置"
    Write-Host "  .\build.ps1 -Clean                清理 build 目录"
    exit 0
}

# ---- 构建 ----
Write-Host "[cmake] build: $($targets -join ', ')" -ForegroundColor Cyan
$targetArgs = ($targets | ForEach-Object { '--target', $_ })
& cmd /d /s /c "call `"$vcvars`" && cmake --build --preset msvc-x64 $($targetArgs -join ' ')"
if ($LASTEXITCODE -ne 0) { throw "构建失败（exit $LASTEXITCODE）" }
Set-Location $projectRoot

# ---- selftest 运行与判定 ----
function Invoke-Selftest {
    param([Parameter(Mandatory)][string]$Name)
    $exe = Join-Path $binDir "$Name.exe"
    if (-not (Test-Path $exe)) { throw "产物不存在: $exe" }

    $sidecar = Join-Path $buildDir "selftest-$Name.txt"
    if (Test-Path $sidecar) { Remove-Item $sidecar -Force }

    $runs = @()
    for ($i = 1; $i -le 2; $i++) {
        $psi = [System.Diagnostics.ProcessStartInfo]::new()
        $psi.FileName = $exe
        $psi.Arguments = '--selftest'
        $psi.WorkingDirectory = $buildDir
        $psi.UseShellExecute = $false
        $psi.RedirectStandardOutput = $true
        $psi.RedirectStandardError = $true
        # 【坑】TUI 框架（FTXUI 等）启动时会改控制台代码页；.NET 管道读取
        # 默认按"当前控制台 CP"解码——同批第二跑就变 UTF-8，两跑必然不一致。
        # 显式钉死管道编码，输出按字节忠实回读。
        $psi.StandardOutputEncoding = [System.Text.Encoding]::UTF8
        $psi.StandardErrorEncoding = [System.Text.Encoding]::UTF8
        $p = [System.Diagnostics.Process]::Start($psi)
        $outTask = $p.StandardOutput.ReadToEndAsync()
        $errTask = $p.StandardError.ReadToEndAsync()
        if (-not $p.WaitForExit(60000)) {
            $p.Kill($true)
            throw "selftest 超时（60s）——程序未自动退出"
        }
        $out = $outTask.Result
        $err = $errTask.Result
        if ($p.ExitCode -ne 0) { throw "selftest 退出码 $($p.ExitCode)（stderr: $($err.Trim())）" }
        if ($err -and $err.Trim().Length -gt 0) { throw "selftest stderr 非空: $($err.Trim())" }
        $markerOk = ($out -match '==== \d+ ') -and ($out -match ' 结束 ====')
        if (-not $markerOk -and (Test-Path $sidecar)) {
            $side = Get-Content -LiteralPath $sidecar -Raw -ErrorAction SilentlyContinue
            $markerOk = ($side -match '==== \d+ ') -and ($side -match ' 结束 ====')
        }
        if (-not $markerOk) { throw "stdout 与 sidecar 均未见结束标记" }
        $runs += $out
    }
    if (($runs[0] -replace '\r', '') -ne (($runs[1]) -replace '\r', '')) {
        [System.IO.File]::WriteAllText((Join-Path $buildDir "selftest-dbg-$Name-1.txt"), $runs[0], [System.Text.Encoding]::UTF8)
        [System.IO.File]::WriteAllText((Join-Path $buildDir "selftest-dbg-$Name-2.txt"), $runs[1], [System.Text.Encoding]::UTF8)
        throw "两次运行 stdout 不一致（输出含非确定性内容；现场存 selftest-dbg-$Name-*.txt）"
    }
    return $runs[0]
}

$script:pass = 0; $script:fail = 0; $script:failed = @()
foreach ($t in $targets) {
    try {
        $out = Invoke-Selftest -Name $t
        Write-Host "  [通过] $t" -ForegroundColor Green
        if ($Verbose) {
            $out -split "`r?`n" | Where-Object { $_ } | ForEach-Object { Write-Host "  | $_" -ForegroundColor DarkGray }
        }
        $script:pass++
    } catch {
        Write-Host "  [失败] $t : $($_.Exception.Message)" -ForegroundColor Red
        $script:fail++; $script:failed += $t
    }
}

Write-Host ""
Write-Host "======================================"
Write-Host " 通过 $script:pass  失败 $script:fail  （示例总数 $($script:pass + $script:fail)）"
if ($script:fail -gt 0) { Write-Host " 失败项: $($script:failed -join ', ')" -ForegroundColor Red }
Write-Host "======================================"
if ($script:fail -gt 0) { exit 1 }

# ---- 文档机器核查（tools/check_docs.py 存在时自动追加） ----
$check = Join-Path $projectRoot 'tools/check_docs.py'
if ($All -and (Test-Path $check)) {
    & python $check
    if ($LASTEXITCODE -ne 0) { exit 1 }
}
Write-Host "[Done] 全部通过。" -ForegroundColor Green
exit 0
