# build-wx.ps1 —— wxWidgets 静态库一次性预构建（cppgui 教程依赖）
# 用法：pwsh cppgui/tools/build-wx.ps1 [-Force]
#   产物：cppgui/build/dep-wx/（lib/*.lib + lib/cmake/wxWidgets/），不入库，可重复调用复用
# 耗时：首次约 10–20 分钟（MSVC x64 Release，Ninja）；已就绪时秒退。
param([switch]$Force)

$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$wxSrc   = if ($env:CPPGUI_WX_DIR) { $env:CPPGUI_WX_DIR } else { 'G:/github/cpp/wxWidgets' }
$prefix  = (Resolve-Path "$PSScriptRoot/..").Path + '\build\dep-wx'
$buildDir = (Resolve-Path "$PSScriptRoot/..").Path + '\build\wx-build'

if (-not (Test-Path "$wxSrc/CMakeLists.txt")) {
    Write-Host "[build-wx] 找不到 wxWidgets 源码：$wxSrc（可用环境变量 CPPGUI_WX_DIR 覆盖）" -ForegroundColor Red
    exit 1
}

if (@(Get-ChildItem "$prefix/lib/cmake" -Directory -Filter 'wxWidgets*' -ErrorAction SilentlyContinue).Count -gt 0 -and -not $Force) {
    $libs = @(Get-ChildItem "$prefix/lib" -Filter *.lib -Recurse).Count
    Write-Host "[build-wx] 已就绪：$prefix（$libs 个 .lib）——如需重建加 -Force"
    exit 0
}

# --- 定位 vcvars64：vswhere 最新版优先，回退已知路径 ---
$vswhere = 'C:/Program Files (x86)/Microsoft Visual Studio/Installer/vswhere.exe'
$vcvars = $null
if (Test-Path $vswhere) {
    foreach ($p in & $vswhere -latest -property installationPath,
                          (& $vswhere -all -property installationPath)) {
        if ($p -and (Test-Path "$p/VC/Auxiliary/Build/vcvars64.bat")) {
            $vcvars = "$p/VC/Auxiliary/Build/vcvars64.bat"; break
        }
    }
}
if (-not $vcvars) { $vcvars = 'G:/Program Files/Microsoft Visual Studio/2022/Community/VC/Auxiliary/Build/vcvars64.bat' }
if (-not (Test-Path $vcvars)) {
    Write-Host "[build-wx] 找不到 vcvars64.bat（$vcvars）" -ForegroundColor Red
    exit 1
}
Write-Host "[build-wx] MSVC 环境：$vcvars"
Write-Host "[build-wx] 源码：$wxSrc"
Write-Host "[build-wx] 安装前缀：$prefix"
Write-Host "[build-wx] 首次构建预计 10–20 分钟，开始……"

$sw = [System.Diagnostics.Stopwatch]::StartNew()
$cmd = "call `"$vcvars`" && cmake -S `"$wxSrc`" -B `"$buildDir`" -G Ninja" +
       " -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=`"$prefix`" -DwxBUILD_SHARED=OFF" +
       " -DwxUSE_STC=OFF" +
       " && cmake --build `"$buildDir`" --target install"
& cmd /d /s /c $cmd
if ($LASTEXITCODE -ne 0) {
    Write-Host "[build-wx] 构建失败（exit $LASTEXITCODE）" -ForegroundColor Red
    exit $LASTEXITCODE
}
$sw.Stop()

if (@(Get-ChildItem "$prefix/lib/cmake" -Directory -Filter 'wxWidgets*' -ErrorAction SilentlyContinue).Count -eq 0) {
    Write-Host "[build-wx] 安装完成但缺 wxWidgetsConfig.cmake，请检查 $prefix" -ForegroundColor Red
    exit 1
}
$libs = @(Get-ChildItem "$prefix/lib" -Filter *.lib -Recurse).Count
Write-Host ("[build-wx] 完成：{0} 个 .lib 装入 {1}（耗时 {2:mm\分ss\秒}）" -f $libs, $prefix, $sw.Elapsed)
exit 0
