# 第 22 章验证脚本：scoop clang 23 的前端工具链四连
# ① -emit-llvm 产 IR（喂给 MSYS2 的 lli 22 执行——跨版本 IR 互通实证）
# ② -Xclang -ast-dump 看 AST
# ③ clang-format + .clang-format 配置文件
# ④ clang-tidy 基础体检
#
# 运行：pwsh run.ps1   （在 22_clang_tools 目录下）

$ErrorActionPreference = "Stop"
[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new()
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$out = Join-Path (Split-Path -Parent (Split-Path -Parent $here)) "build\22_clang_tools"
New-Item -ItemType Directory -Force $out | Out-Null

# scoop 的 clang 23（MSVC ABI 前端工具集；第 1 章勘察：无 opt/lli/开发库）
$clang23 = "G:\scoop\apps\llvm\current\bin\clang.exe"
$fmt     = "G:\scoop\apps\llvm\current\bin\clang-format.exe"
$tidy    = "G:\scoop\apps\llvm\current\bin\clang-tidy.exe"
foreach ($t in @($clang23, $fmt, $tidy)) {
    if (-not (Test-Path $t)) { throw "未找到 $t（需要 scoop install llvm）" }
}
# MSYS2 的 lli 22：执行 23 生成的 IR
$lli22 = "G:\scoop\apps\msys2\current\ucrt64\bin\lli.exe"

# 实测坑：scoop clang（MSVC 目标）在无 VS 环境变量时找不到 MSVC 头（stdio.h not found）。
# 解法：GNU 目标 + 借 MSYS2 UCRT64 的 C 头文件
$ucinc = "G:\scoop\apps\msys2\current\ucrt64\include"
$commonArgs = @('-target', 'x86_64-pc-windows-gnu', '-isystem', $ucinc)

# ① IR 生成 + 跨版本执行
& $clang23 @commonArgs -S -emit-llvm -O1 "$here\sample.c" -o "$out\sample.ll"
if ($LASTEXITCODE -ne 0) { throw "clang23 -emit-llvm 失败" }
$ll = Get-Content "$out\sample.ll" -Raw
if ($ll -notmatch 'define .*@main') { throw "IR 里没有 main" }
& $lli22 "$out\sample.ll"
if ($LASTEXITCODE -ne 0) { throw "lli 执行 clang23 的 IR 失败" }
Write-Host "[1/4] clang23 产 IR -> lli22 执行：OK"

# ② AST dump（前端视角：翻译前的树）
$ast = & $clang23 @commonArgs -Xclang -ast-dump -fsyntax-only "$here\sample.c" 2>&1
$astText = ($ast | ForEach-Object { "$_" }) -join "`n"
if ($astText -notmatch 'FunctionDecl' -or $astText -notmatch 'ForStmt') {
    throw "AST dump 未包含预期节点"
}
Write-Host "[2/4] -Xclang -ast-dump：OK（FunctionDecl/ForStmt 都在）"

# ③ clang-format：配置文件驱动的重排（在副本上做，源文件保持"丑"）
Copy-Item "$here\ugly.c" "$out\ugly.c" -Force
& $fmt --style=file "$out\ugly.c" -i
if ($LASTEXITCODE -ne 0) { throw "clang-format 失败" }
$formatted = Get-Content "$out\ugly.c" -Raw
if ($formatted -match 'if\(x<0\)\{return') { throw "ugly.c 没有被格式化" }
if ($formatted -notmatch 'return -x;') { throw "格式化结果异常" }
Write-Host "[3/4] clang-format + .clang-format：OK（压缩大括号已被展开）"

# ④ clang-tidy：静态体检（重点在能跑通 + 报告可读，不追求零告警）
# 两个实测坑：a) PowerShell 会吞掉传给原生命令的 "--"，须经 cmd 转交；
#             b) scoop 的 clang-tidy 默认不启用任何检查，须 --checks 显式点名
$tidyCmd = "`"$tidy`" --checks=`"clang-diagnostic-*,readability-*`" `"$here\sample.c`" -- --target=x86_64-w64-windows-gnu -isystem G:/scoop/apps/msys2/current/ucrt64/include"
$tidyOut = cmd /c $tidyCmd 2>&1
if ($LASTEXITCODE -ne 0) { throw "clang-tidy 运行失败" }
Write-Host "[4/4] clang-tidy：OK"

Write-Host "==== 22 ok ====" -ForegroundColor Green




