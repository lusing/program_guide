<#
.SYNOPSIS
    按类别构建示例
.DESCRIPTION
    只构建指定类别目录下的 .asm 文件。
    每个文件执行：nasm -f win64 汇编 -> MSVC link.exe 链接 -> 运行 .exe 并显示输出。
.PARAMETER Category
    类别名称（例如 01_data_movement）。
.EXAMPLE
    .\scripts\build_category.ps1 -Category 01_data_movement
#>
param(
    [Parameter(Mandatory = $true, HelpMessage = "类别名称，例如 01_data_movement")]
    [string]$Category
)

# 引入共享逻辑
. (Join-Path $PSScriptRoot "common.ps1")

Ensure-BuildDir

$categoryDir = Join-Path $script:ExamplesDir $Category

# 校验类别目录是否存在
if (-not (Test-Path $categoryDir -PathType Container)) {
    Write-Host "错误: 类别目录不存在: $categoryDir" -ForegroundColor Red
    Write-Host "可用类别:" -ForegroundColor Yellow
    Get-ChildItem -Path $script:ExamplesDir -Directory | ForEach-Object { Write-Host "  $($_.Name)" }
    return
}

Write-Host "开始构建类别: $Category" -ForegroundColor Cyan
Write-Host "扫描目录: $categoryDir" -ForegroundColor DarkGray

# 收集该类别下的 .asm 文件
$asmFiles = Get-ChildItem -Path $categoryDir -Filter *.asm |
    Sort-Object Name

if (-not $asmFiles -or $asmFiles.Count -eq 0) {
    Write-Host "类别 $Category 下未找到任何 .asm 文件。" -ForegroundColor Yellow
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
