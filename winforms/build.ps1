param(
    [switch]$All,                    # 构建全部示例（默认行为）
    [string]$Chapter = "",           # 只构建某一章，如 02_hello / 15_datagrid
    [string]$Lang = "all",           # csharp | fsharp | cpp | all
    [switch]$Clean                   # 清理构建产物目录
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $MyInvocation.MyCommand.Path

# ── 工具链探测 ────────────────────────────────────────────────────────────
# dotnet：优先本教程一贯使用的 scoop 安装，回退 PATH
$dotnet = "G:\scoop\apps\dotnet-sdk\current\dotnet.exe"
if (-not (Test-Path $dotnet)) { $dotnet = (Get-Command dotnet -ErrorAction SilentlyContinue).Source }
if (-not $dotnet) { Write-Error "找不到 dotnet，请安装 .NET 10 SDK"; exit 1 }

# MSBuild：C++/CLI（vcxproj）必须用 VS 的 MSBuild，dotnet build 编不了 C++ 工程。
# 用 vswhere 找带 C++/CLI 组件的实例（本机为 VS 2026 v145，VS 2022 v143 亦可）。
$vswhere = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
$msbuild = $null
if (Test-Path $vswhere) {
    $msbuild = & $vswhere -latest -products * -requires Microsoft.VisualStudio.Component.VC.CLI.Support `
        -find "MSBuild\**\Bin\MSBuild.exe" 2>$null | Select-Object -First 1
}

function Find-Projects([string]$pattern) {
    Get-ChildItem -LiteralPath (Join-Path $root "examples") -Directory |
        Where-Object { $_.Name -match '^\d{2}_|^\d{2}-' -and ($Chapter -eq "" -or $_.Name -eq $Chapter) } |
        ForEach-Object { Get-ChildItem -LiteralPath $_.FullName -Recurse -Filter $pattern -File } |
        Where-Object { $_.FullName -notmatch '\\host\\' }
}

function Find-HostProjects {
    Get-ChildItem -LiteralPath (Join-Path $root "examples") -Directory |
        Where-Object { $_.Name -match '^\d{2}_|^\d{2}-' -and ($Chapter -eq "" -or $_.Name -eq $Chapter) } |
        ForEach-Object { Get-ChildItem -LiteralPath (Join-Path $_.FullName "cpp\host") -Filter *.csproj -File -ErrorAction SilentlyContinue }
}

# ── 清理 ─────────────────────────────────────────────────────────────────
if ($Clean) {
    $dirs = Get-ChildItem -LiteralPath (Join-Path $root "examples") -Directory |
        Where-Object { $_.Name -match '^\d{2}_|^\d{2}-' }
    # 注意：绝不能用 -Include 裸匹配目录名（历史事故，见教程 README），
    # 必须用 Where-Object 精确比对目录名。
    $targets = Get-ChildItem -LiteralPath (Join-Path $root "examples") -Recurse -Directory |
        Where-Object { $_.Name -eq "bin" -or $_.Name -eq "obj" -or $_.Name -eq "x64" }
    foreach ($d in $targets) { Remove-Item -LiteralPath $d.FullName -Recurse -Force -ErrorAction SilentlyContinue }
    Write-Host "已清理 bin/obj/x64 目录（共 $($targets.Count) 个）。" -ForegroundColor Green
    return
}

# ── 构建 ─────────────────────────────────────────────────────────────────
$fail = 0

function Invoke-Build([string]$title, [scriptblock]$action) {
    Write-Host "`n[build] $title" -ForegroundColor Yellow
    & $action
    if ($LASTEXITCODE -ne 0) {
        Write-Host "  失败（exit $LASTEXITCODE）" -ForegroundColor Red
        $script:fail++
    }
}

if ($Lang -eq "all" -or $Lang -eq "csharp") {
    foreach ($p in (Find-Projects *.csproj)) {
        Invoke-Build $p.FullName { & $dotnet build $p.FullName -c Release --nologo -v minimal }.GetNewClosure()
    }
}
if ($Lang -eq "all" -or $Lang -eq "fsharp") {
    foreach ($p in (Find-Projects *.fsproj)) {
        Invoke-Build $p.FullName { & $dotnet build $p.FullName -c Release --nologo -v minimal }.GetNewClosure()
    }
}
if ($Lang -eq "all" -or $Lang -eq "cpp") {
    if (-not $msbuild) {
        Write-Warning "找不到带 C++/CLI 组件的 Visual Studio MSBuild，跳过 C++/CLI 示例（其余语言不受影响）"
    } else {
        # host.csproj 引用同目录上一级的 vcxproj，MSBuild 会把依赖一起编出来
        foreach ($p in (Find-HostProjects)) {
            Invoke-Build "$($p.FullName)（含 vcxproj）" { & $msbuild $p.FullName -restore -p:Configuration=Release -p:Platform=x64 -nologo -v:minimal }.GetNewClosure()
        }
    }
}

Write-Host "`n──────── 构建收尾：$fail 个失败 ────────" -ForegroundColor $(if ($fail -eq 0) { "Green" } else { "Red" })
exit $fail
