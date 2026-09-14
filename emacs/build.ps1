param(
    [switch]$All,
    [string]$File,
    [switch]$Clean
)

$projectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $projectRoot

$emacs = "G:\scoop\apps\emacs\current\bin\emacs.exe"
$examplesDir = Join-Path $projectRoot "examples"
$buildDir = Join-Path $projectRoot "build"

if (-not (Test-Path -LiteralPath $emacs)) {
    throw "未找到 Emacs 可执行文件，请检查安装路径：$emacs"
}

if ($Clean) {
    if (Test-Path -LiteralPath $buildDir) {
        Remove-Item -LiteralPath $buildDir -Recurse -Force
        Write-Host "[Clean] 已清理 build 目录。" -ForegroundColor Yellow
    } else {
        Write-Host "[Clean] build 目录不存在，无需清理。" -ForegroundColor Yellow
    }
    exit 0
}

if (-not (Test-Path -LiteralPath $examplesDir)) {
    throw "找不到 examples 目录: $examplesDir"
}

New-Item -ItemType Directory -Force -Path $buildDir | Out-Null

function Invoke-EmacsExample {
    param(
        [Parameter(Mandatory = $true)][string]$SourcePath
    )

    $fileName = [System.IO.Path]::GetFileName($SourcePath)
    $copyPath = Join-Path $buildDir $fileName
    $lispPath = $copyPath -replace '\\', '/'
    $elcPath = ($copyPath -replace '\.el$', '.elc')

    Copy-Item -LiteralPath $SourcePath -Destination $copyPath -Force

    Write-Host "[Compile] $fileName" -ForegroundColor Cyan
    & $emacs -Q --batch --eval ('(byte-compile-file "' + $lispPath + '")')
    if ($LASTEXITCODE -ne 0) {
        throw "编译失败: $SourcePath"
    }

    Write-Host "[Load] $fileName" -ForegroundColor DarkCyan
    & $emacs -Q --batch --load $lispPath --eval ('(message "[OK] %s" (file-name-nondirectory "' + $lispPath + '"))')
    if ($LASTEXITCODE -ne 0) {
        throw "加载失败: $SourcePath"
    }

    if (Test-Path -LiteralPath $elcPath) {
        Remove-Item -LiteralPath $elcPath -Force
    }

    if (Test-Path -LiteralPath $copyPath) {
        Remove-Item -LiteralPath $copyPath -Force
    }
}

if ($All) {
    $files = Get-ChildItem -LiteralPath $examplesDir -Filter "*.el" | Sort-Object Name
    if ($files.Count -eq 0) {
        throw "examples 目录下没有 .el 示例文件。"
    }

    foreach ($f in $files) {
        Invoke-EmacsExample -SourcePath $f.FullName
    }

    Write-Host "[Done] examples 目录全部验证通过。" -ForegroundColor Green
    exit 0
}

if ($File) {
    $sourcePath = Join-Path $examplesDir $File
    if (-not (Test-Path -LiteralPath $sourcePath)) {
        throw "找不到示例文件: $sourcePath"
    }

    Invoke-EmacsExample -SourcePath $sourcePath
    Write-Host "[Done] 验证通过: $File" -ForegroundColor Green
    exit 0
}

Write-Host "用法:" -ForegroundColor Yellow
Write-Host "  .\build.ps1 -All           编译并验证 examples 下全部示例"
Write-Host "  .\build.ps1 -File <name>   编译并验证单个示例（如 08_keymaps.el）"
Write-Host "  .\build.ps1 -Clean         清理 build 目录"
