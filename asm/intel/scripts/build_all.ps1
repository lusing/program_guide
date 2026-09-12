<#
.SYNOPSIS
    构建全部示例
.DESCRIPTION
    遍历 examples/ 下所有子目录，对每个 .asm 文件执行：
      nasm -f win64 汇编 -> MSVC link.exe 链接 -> 运行 .exe 并显示输出
    最后统计成功/失败数量。
.EXAMPLE
    .\scripts\build_all.ps1
#>

# 引入共享逻辑
. (Join-Path $PSScriptRoot "common.ps1")

Ensure-BuildDir

Write-Host "开始构建全部示例..." -ForegroundColor Cyan
Write-Host "扫描目录: $script:ExamplesDir" -ForegroundColor DarkGray

# 递归收集所有 .asm 文件，按路径排序保证顺序稳定
$asmFiles = Get-ChildItem -Path $script:ExamplesDir -Recurse -Filter *.asm |
    Sort-Object FullName

if (-not $asmFiles -or $asmFiles.Count -eq 0) {
    Write-Host "未找到任何 .asm 文件，请先在 examples/ 下创建示例。" -ForegroundColor Yellow
    return
}

$success = 0
$fail    = 0
$total   = $asmFiles.Count
$index   = 0

foreach ($file in $asmFiles) {
    $index++
    # 显示进度 [当前/总数] 及相对路径
    $relative = $file.FullName.Substring($script:ProjectRoot.Length).TrimStart('\')
    Write-Host ""
    Write-Host "[$index/$total] $relative" -ForegroundColor Magenta

    $result = Invoke-BuildFile -FilePath $file.FullName
    if ($result) { $success++ } else { $fail++ }
}

Write-BuildSummary -Total $total -Success $success -Fail $fail
