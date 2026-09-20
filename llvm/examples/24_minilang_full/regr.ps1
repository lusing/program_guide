# MiniLang v1.0 回归套件：四种执行路径行为一致性
#   ① run（JIT -O2）  ② run0（JIT 无优化）  ③ ir→lli  ④ obj→clang 链接→exe
# 判定：全部输出 regression 的期望十行数值 + 退出码 0
# 运行：pwsh regr.ps1（依赖 build\24_minilang_full\minilang.exe 已就位）

$ErrorActionPreference = "Stop"
[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new()
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$buildRoot = Join-Path (Split-Path -Parent (Split-Path -Parent $here)) "build\24_minilang_full"
$mini = Join-Path $buildRoot "minilang.exe"
if (-not (Test-Path $mini)) { throw "先构建: $mini 不存在" }

$uc = "G:\scoop\apps\msys2\current\ucrt64\bin"
$env:PATH = "$uc;" + $env:PATH
$lli = "$uc\lli.exe"
$clang = "$uc\clang.exe"

$expected = @(
    '55\.0+', '5050\.0+', '720\.0+', '42\.0+', '1024\.0+',
    '1\.0+', '0\.0+', '1\.0+', '0\.0+', '0\.0+'
)

function Check-Output {
    param([string]$Name, [string]$Text)
    foreach ($e in $expected) {
        if ($Text -notmatch $e) { throw "$Name 输出缺少预期值 $e`n---`n$Text" }
    }
    # `=>` 回显行是 JIT 模式特有的，ir/exe 模式没有——只按值断言
    Write-Host "  [ok] $Name" -ForegroundColor Green
}

Write-Host "== MiniLang v1.0 回归 =="
$src = "$here\regression.mini"

$t1 = (& $mini run $src 2>&1 | ForEach-Object { "$_" }) -join "`n"
Check-Output "run (JIT -O2)" $t1

$t2 = (& $mini run0 $src 2>&1 | ForEach-Object { "$_" }) -join "`n"
Check-Output "run0 (JIT 无优化)" $t2

& $mini ir $src "$buildRoot\regression.ll" | Out-Null
if ($LASTEXITCODE -ne 0) { throw "ir 模式失败" }
$t3 = (& $lli "$buildRoot\regression.ll" 2>&1 | ForEach-Object { "$_" }) -join "`n"
Check-Output "ir -> lli" $t3

& $mini obj $src "$buildRoot\regression.o"
if ($LASTEXITCODE -ne 0) { throw "obj 模式失败" }
& $clang "$buildRoot\regression.o" -o "$buildRoot\regression.exe"
if ($LASTEXITCODE -ne 0) { throw "链接失败" }
$t4 = (& "$buildRoot\regression.exe" 2>&1 | ForEach-Object { "$_" }) -join "`n"
Check-Output "obj -> exe" $t4

# 曼德博：只验 run 模式能画满一行 #（第 1 行应是纯 #）
$m = (& $mini run "$here\mandel.mini" 2>&1 | ForEach-Object { "$_" }) -join "`n"
if ($m -notmatch '^(#+|=>)') { throw "曼德博首行异常`n$m" }
Write-Host "  [ok] mandelbrot (run)" -ForegroundColor Green

# ast/stats 冒烟
$null = & $mini ast $src
if ($LASTEXITCODE -ne 0) { throw "ast 模式失败" }
Write-Host "  [ok] ast" -ForegroundColor Green
$s = (& $mini stats $src 2>&1 | ForEach-Object { "$_" }) -join "`n"
if ($s -notmatch 'ml-stats: fib') { throw "stats 输出异常" }
Write-Host "  [ok] stats" -ForegroundColor Green

Write-Host "==== 24 ok ====" -ForegroundColor Green
