param(
    [switch]$All,
    [string]$File,
    [switch]$Clean
)

$projectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $projectRoot

$zigExe = $null
$zigCandidates = Get-ChildItem -LiteralPath "G:\scoop\apps\zig" -Recurse -Filter zig.exe -ErrorAction SilentlyContinue |
    Sort-Object FullName
foreach ($candidate in $zigCandidates) {
    if (Test-Path -LiteralPath $candidate.FullName) {
        $zigExe = $candidate.FullName
        break
    }
}
if (-not $zigExe) {
    throw "未找到 zig.exe，请检查 G:\scoop\apps\zig 安装。"
}

$buildDir = Join-Path $projectRoot "build"
$examplesDir = Join-Path $projectRoot "examples"

if ($Clean) {
    if (Test-Path -LiteralPath $buildDir) {
        Remove-Item -LiteralPath $buildDir -Recurse -Force
        Write-Host "[Clean] 已清理 build 目录。" -ForegroundColor Yellow
    } else {
        Write-Host "[Clean] build 目录不存在，无需清理。" -ForegroundColor Yellow
    }
    exit 0
}

New-Item -ItemType Directory -Force -Path $buildDir | Out-Null

function Invoke-Compile {
    param(
        [Parameter(Mandatory = $true)][string]$SourcePath
    )

    $baseName = [System.IO.Path]::GetFileNameWithoutExtension($SourcePath)
    Write-Host "[Compile] $([System.IO.Path]::GetRelativePath($projectRoot, $SourcePath))" -ForegroundColor Cyan
    $sourceDir = Split-Path -Parent $SourcePath
    Push-Location $sourceDir
    try {
        & $zigExe build-exe ([System.IO.Path]::GetFileName($SourcePath)) -O Debug
    }
    finally {
        Pop-Location
    }
    if ($LASTEXITCODE -ne 0) {
        throw "编译失败: $SourcePath"
    }

    $generatedExe = Join-Path $sourceDir ($baseName + ".exe")
    $generatedPdb = Join-Path $sourceDir ($baseName + ".pdb")
    if (Test-Path -LiteralPath $generatedExe) {
        Move-Item -LiteralPath $generatedExe -Destination (Join-Path $buildDir ($baseName + ".exe")) -Force
    }
    if (Test-Path -LiteralPath $generatedPdb) {
        Move-Item -LiteralPath $generatedPdb -Destination (Join-Path $buildDir ($baseName + ".pdb")) -Force
    }
}

if ($All) {
    $targets = @(
        "环境搭建\\012_环境搭建_第一个程序.zig",
        "基础语法\\015_基础语法_变量声明.zig",
        "控制流\\021_控制流_if_语句.zig",
        "控制流\\022_控制流_switch_语句.zig",
        "函数\\025_函数_基本函数.zig"
    )
    $files = foreach ($rel in $targets) { Get-Item -LiteralPath (Join-Path $examplesDir $rel) }
    foreach ($fileInfo in $files) {
        Invoke-Compile -SourcePath $fileInfo.FullName
    }
    Write-Host "[Done] Zig 示例编译验证完成。" -ForegroundColor Green
    exit 0
}

if ($File) {
    $source = Join-Path $examplesDir $File
    if (-not (Test-Path -LiteralPath $source)) {
        throw "找不到示例文件: $source"
    }
    Invoke-Compile -SourcePath $source
    Write-Host "[Done] 编译通过: $File" -ForegroundColor Green
    exit 0
}

Write-Host "用法:" -ForegroundColor Yellow
Write-Host "  .\build.ps1 -All             编译 examples 下全部 Zig 示例"
Write-Host "  .\build.ps1 -File <path>     编译单个示例，相对 examples 目录"
Write-Host "  .\build.ps1 -Clean           清理 build 目录"
