param(
    [switch]$All,
    [string]$File,
    [switch]$Clean
)

$projectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $projectRoot

$sbcl = "G:\scoop\apps\sbcl\current\sbcl.exe"
$buildDir = Join-Path $projectRoot "build"

if (-not (Test-Path -LiteralPath $sbcl)) {
    throw "未找到 sbcl.exe，请检查 SBCL 安装路径。"
}

if ($Clean) {
    if (Test-Path -LiteralPath $buildDir) {
        Remove-Item -LiteralPath $buildDir -Recurse -Force
    }
    Get-ChildItem -Path $projectRoot -Filter "*.fasl" -File -ErrorAction SilentlyContinue | Remove-Item -Force
    Write-Host "[Clean] 已清理 build 目录与 FASL 产物。" -ForegroundColor Yellow
    exit 0
}

function Invoke-LispCompile {
    param(
        [Parameter(Mandatory = $true)][string]$SourcePath
    )

    $name = [System.IO.Path]::GetFileName($SourcePath)
    $sourceForLisp = $SourcePath -replace "\\", "/"
    $outputPath = Join-Path $buildDir ([System.IO.Path]::GetFileNameWithoutExtension($SourcePath) + ".fasl")
    $outputForLisp = ($outputPath -replace "\\", "/")
    $expr = "(multiple-value-bind (out warn fail) (compile-file `"$sourceForLisp`" :output-file `"$outputForLisp`") (declare (ignore out warn)) (sb-ext:exit :code (if fail 1 0)))"

    Write-Host "[Compile] $name" -ForegroundColor Cyan
    & $sbcl --noinform --non-interactive --eval $expr
    if ($LASTEXITCODE -ne 0) {
        throw "编译失败: $SourcePath"
    }
}

New-Item -ItemType Directory -Force -Path $buildDir | Out-Null

if ($All) {
    $files = Get-ChildItem -Path $projectRoot -Filter "*.lisp" -File | Sort-Object Name
    foreach ($f in $files) {
        Invoke-LispCompile -SourcePath $f.FullName
    }
    Write-Host "[Done] 全部 SBCL 示例编译通过。" -ForegroundColor Green
    exit 0
}

if ($File) {
    $sourcePath = Join-Path $projectRoot $File
    if (-not (Test-Path -LiteralPath $sourcePath)) {
        throw "找不到示例文件: $sourcePath"
    }
    Invoke-LispCompile -SourcePath $sourcePath
    Write-Host "[Done] 编译通过: $File" -ForegroundColor Green
    exit 0
}

Write-Host "用法:" -ForegroundColor Yellow
Write-Host "  .\build.ps1 -All                 编译本目录全部 .lisp 文件"
Write-Host "  .\build.ps1 -File 04-functions.lisp  编译单个示例"
Write-Host "  .\build.ps1 -Clean               清理产物"
