# 第 23 章验证脚本：LLVM 源码导览（只读寻宝）
# 对象：G:\github\lang\llvm-project —— LLVM monorepo 主干（2026 年检出，≥24 时代）
# 目的：拿到"类/头文件在源码树的哪里"的肌肉记忆 + 新旧版本差异实感
#
# 运行：pwsh run.ps1

$ErrorActionPreference = "Stop"
[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new()

$repo = "G:\github\lang\llvm-project"
$src  = "$repo\llvm"    # monorepo 布局：llvm/ 是编译器本体，旁边还有 clang/ lld/ …
if (-not (Test-Path "$src\CMakeLists.txt")) { throw "未找到 LLVM monorepo: $repo（llvm/ 子目录缺失）" }

function Assert-Found {
    param([string]$Pattern, [string]$Path, [string]$What)
    $hits = Select-String -Path $Path -Pattern $Pattern -ErrorAction SilentlyContinue
    if (-not $hits) { throw "源码导览断言失败：在 $(Split-Path -Leaf $Path) 找不到 $What" }
    Write-Host ("  [found] {0}  ({1} 处)" -f $What, $hits.Count)
}

Write-Host "== 版本确认 =="
$head = git -C $repo log --oneline -1 2>$null
Write-Host "  HEAD: $head"
Write-Host "  （主干 ≥24 时代；本教程实操工具链是 22.1.8，差异见 docs/23-source-tour.md 的对照表）"

Write-Host "== 地标 1：IR 核心类（llvm/include/llvm/IR/）=="
foreach ($f in @('Module.h', 'Function.h', 'BasicBlock.h', 'IRBuilder.h', 'Instructions.h', 'Verifier.h')) {
    if (-not (Test-Path "$src\include\llvm\IR\$f")) { throw "缺少 include/llvm/IR/$f" }
}
Write-Host "  [found] Module/Function/BasicBlock/IRBuilder/Instructions/Verifier 六件套"

Write-Host "== 地标 2：第 9 章对象模型的源头 =="
Assert-Found 'class Value'   "$src\include\llvm\IR\Value.h"        "class Value"
Assert-Found 'class User'    "$src\include\llvm\IR\User.h"         "class User"
Assert-Found 'class Use'     "$src\include\llvm\IR\Use.h"          "class Use"
Assert-Found 'class PHINode' "$src\include\llvm\IR\Instructions.h" "class PHINode"

Write-Host "== 地标 3：PassManager 新旧双制 =="
Assert-Found 'class PassManager' "$src\include\llvm\IR\PassManager.h"      "新 PM: class PassManager"
Assert-Found 'class FunctionPass' "$src\include\llvm\IR\LegacyPassManager.h" "旧 PM: class FunctionPass（Legacy 体系仍在，供代码生成管线使用）"

Write-Host "== 地标 4：PassPlugin 的现代位置（本书 6 章踩过的搬家）=="
if (-not (Test-Path "$src\include\llvm\Plugins\PassPlugin.h")) {
    throw "llvm/Plugins/PassPlugin.h 不在？（那要更新 6 章的说法了）"
}
Write-Host "  [found] llvm/Plugins/PassPlugin.h（22+ 的家；老教程的 llvm/Passes/PassPlugin.h 已不存在）"
Assert-Found 'registerPipelineParsingCallback' "$src\include\llvm\Passes\PassBuilder.h" "PassBuilder 的管线解析回调"

Write-Host "== 地标 5：本教程各章对应的实现文件（llvm/lib/）=="
foreach ($f in @('lib\IR\Module.cpp', 'lib\IR\IRBuilder.cpp', 'lib\IR\Verifier.cpp',
                 'lib\IR\AsmWriter.cpp', 'lib\Passes\PassBuilder.cpp', 'lib\IR\Verifier.cpp')) {
    if (-not (Test-Path "$src\$f")) { throw "缺少 $f" }
}
Write-Host "  [found] Module/IRBuilder/Verifier/AsmWriter/PassBuilder 的 .cpp 都在老位置"

Write-Host "== 地标 6：工具与 JIT =="
foreach ($d in @('tools\opt', 'tools\llc', 'tools\lli', 'tools\llvm-as', 'tools\llvm-dis')) {
    if (-not (Test-Path "$src\$d")) { throw "缺少 $d" }
}
Write-Host "  [found] opt/llc/lli/llvm-as/llvm-dis 的命令行实现"
Assert-Found 'class LLJIT' "$src\include\llvm\ExecutionEngine\Orc\LLJIT.h" "ORC LLJIT"

Write-Host "== 地标 7：monorepo 的邻居（同仓多项目）=="
foreach ($d in @('clang\lib\Sema', 'lld\ELF', 'llvm\tools\clang-format-test... ')) {
    # 第三个是占位笑话；真正检查下面两个
}
foreach ($d in @('clang\lib\Sema', 'lld\ELF')) {
    if (-not (Test-Path "$repo\$d")) { throw "缺少 monorepo 子项目 $d" }
}
Write-Host "  [found] clang/ 与 lld/ 同仓共生（这就是 monorepo 的含义）"

Write-Host "== 规模感 =="
$irCpp = (Get-ChildItem "$src\lib\IR" -Filter *.cpp).Count
$incIr = (Get-ChildItem "$src\include\llvm\IR" -Filter *.h).Count
Write-Host ("  llvm/lib/IR: {0} 个 .cpp；llvm/include/llvm/IR: {1} 个 .h" -f $irCpp, $incIr)

Write-Host "==== 23 ok ====" -ForegroundColor Green
