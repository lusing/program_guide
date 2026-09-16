param(
    [switch]$All,
    [string]$Project,
    [switch]$Clean
)

$projectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $projectRoot

# 示例输出含中文：统一 UTF-8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$flutter = "G:\scoop\apps\flutter\current\bin\flutter.bat"
$examplesDir = Join-Path $projectRoot "examples"
$buildDir = Join-Path $projectRoot "build"
# windows 构建抽查名单（其余工程 analyze+test 已足够）
$buildCheck = @('02_hello', '20_notes')

if (-not (Test-Path -LiteralPath $flutter)) {
    throw "未找到 Flutter：$flutter"
}
if (-not (Test-Path -LiteralPath $examplesDir)) {
    throw "找不到 examples 目录: $examplesDir"
}

function Invoke-Flutter {
    param(
        [string]$Label,
        [string[]]$ArgList,
        [string]$WorkDir = $projectRoot
    )
    Write-Host "[$Label] flutter $($ArgList -join ' ') @ $WorkDir" -ForegroundColor Cyan
    Push-Location $WorkDir
    try {
        & $flutter @ArgList
        if ($LASTEXITCODE -ne 0) {
            throw "命令失败（退出码 $LASTEXITCODE）：flutter $($ArgList -join ' ') @ $WorkDir"
        }
    } finally {
        Pop-Location
    }
}

function Invoke-Example {
    param(
        [Parameter(Mandatory = $true)][string]$DirPath,
        [switch]$WithBuild
    )
    Invoke-Flutter 'PubGet' @('pub', 'get') $DirPath
    Invoke-Flutter 'Analyze' @('analyze') $DirPath
    Invoke-Flutter 'Test' @('test') $DirPath
    if ($WithBuild) {
        Invoke-Flutter 'BuildWin' @('build', 'windows', '--debug') $DirPath
    }
}

if ($Clean) {
    $examples = Get-ChildItem -LiteralPath $examplesDir -Directory | Sort-Object Name
    foreach ($entry in $examples) {
        if (Test-Path -LiteralPath (Join-Path $entry.FullName 'pubspec.yaml')) {
            Write-Host "[Clean] $($entry.Name)" -ForegroundColor Yellow
            Push-Location $entry.FullName
            & $flutter clean | Out-Null
            Pop-Location
        }
    }
    if (Test-Path -LiteralPath $buildDir) {
        Remove-Item -LiteralPath $buildDir -Recurse -Force
    }
    Write-Host "[Clean] 已清理全部工程与根 build。" -ForegroundColor Yellow
    exit 0
}

if ($Project) {
    $dir = Join-Path $examplesDir $Project
    if (-not (Test-Path -LiteralPath (Join-Path $dir 'pubspec.yaml'))) {
        throw "找不到示例工程: $dir"
    }
    Invoke-Example -DirPath $dir -WithBuild
    Write-Host "[Done] 验证通过（含 windows 构建）: $Project" -ForegroundColor Green
    exit 0
}

if ($All) {
    $examples = Get-ChildItem -LiteralPath $examplesDir -Directory | Sort-Object Name
    if ($examples.Count -eq 0) {
        throw 'examples 目录下没有示例工程。'
    }
    foreach ($entry in $examples) {
        $name = $entry.Name
        Write-Host "===== $name =====" -ForegroundColor Magenta
        Invoke-Example -DirPath $entry.FullName -WithBuild:($buildCheck -contains $name)
    }
    Write-Host '[Done] 全部工程 analyze+test 通过；抽查工程 windows 构建通过。' -ForegroundColor Green
    exit 0
}

Write-Host '用法:' -ForegroundColor Yellow
Write-Host '  .\build.ps1 -All                全量：逐工程 pub get + analyze + test；02_hello/20_notes 额外 windows 构建（首跑约 10–15 分钟）'
Write-Host '  .\build.ps1 -Project 06_material 单工程全流程（含 windows 构建）'
Write-Host '  .\build.ps1 -Clean               各工程 flutter clean + 清理根 build'
