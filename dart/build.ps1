param(
    [switch]$All,
    [switch]$Test,
    [string]$File,
    [string]$Project,
    [switch]$Clean
)

$projectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $projectRoot

# 示例输出含中文：统一 UTF-8，避免默认编码乱码
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# Dart 可执行文件：优先 scoop 安装路径，回退 PATH 中的 dart
$dartExe = "G:\scoop\apps\dart\current\bin\dart.exe"
if (-not (Test-Path -LiteralPath $dartExe)) {
    $candidates = Get-ChildItem -LiteralPath "G:\scoop\apps\dart" -Directory -ErrorAction SilentlyContinue |
        Sort-Object Name -Descending |
        ForEach-Object { Join-Path $_.FullName "bin\dart.exe" } |
        Where-Object { Test-Path -LiteralPath $_ }
    if ($candidates) {
        $dartExe = @($candidates)[0]
    } else {
        $pathDart = Get-Command dart -ErrorAction SilentlyContinue
        if ($pathDart) {
            $dartExe = $pathDart.Source
        } else {
            throw "未找到 Dart 可执行文件，请确认 dart 在 PATH 中或检查 G:\scoop\apps\dart 安装。"
        }
    }
}

$examplesDir = Join-Path $projectRoot "examples"
$buildDir = Join-Path $projectRoot "build"
$nestedPackages = @('19_testing', '20_todo')

function Invoke-Dart {
    param(
        [string]$Label,
        [string[]]$ArgList,
        [string]$WorkDir = $projectRoot
    )
    Write-Host "[$Label] dart $($ArgList -join ' ')" -ForegroundColor Cyan
    Push-Location $WorkDir
    try {
        & $script:dartExe @ArgList
        if ($LASTEXITCODE -ne 0) {
            throw "命令失败（退出码 $LASTEXITCODE）：dart $($ArgList -join ' ') @ $WorkDir"
        }
    } finally {
        Pop-Location
    }
}

if ($Clean) {
    foreach ($dir in @($projectRoot) + ($nestedPackages | ForEach-Object { Join-Path $examplesDir $_ })) {
        $tool = Join-Path $dir '.dart_tool'
        if (Test-Path -LiteralPath $tool) {
            Remove-Item -LiteralPath $tool -Recurse -Force
        }
    }
    if (Test-Path -LiteralPath $buildDir) {
        Remove-Item -LiteralPath $buildDir -Recurse -Force
    }
    Write-Host "[Clean] 已清理 build 与 .dart_tool。" -ForegroundColor Yellow
    exit 0
}

if (-not (Test-Path -LiteralPath $examplesDir)) {
    throw "找不到 examples 目录: $examplesDir（Task 3 起创建）"
}

# 根包依赖
Invoke-Dart 'PubGet' @('pub', 'get')

if ($Test -and -not $All -and -not $File -and -not $Project) {
    Invoke-Dart 'Analyze' @('analyze')
    Invoke-Dart 'Test' @('test')
    Write-Host "[Done] 根包 analyze + test 通过。" -ForegroundColor Green
    exit 0
}

if ($File) {
    $source = Join-Path $examplesDir $File
    if (-not (Test-Path -LiteralPath $source)) {
        throw "找不到示例文件: $source"
    }
    Invoke-Dart 'Run' @('run', "examples/$File")
    exit 0
}

function Invoke-Nested {
    param([string]$Name)
    $dir = Join-Path $examplesDir $Name
    Invoke-Dart 'PubGet' @('pub', 'get') $dir
    Invoke-Dart 'Analyze' @('analyze') $dir
    Invoke-Dart 'Test' @('test') $dir
}

function Invoke-TodoDemo {
    New-Item -ItemType Directory -Force -Path $buildDir | Out-Null
    $demo = Join-Path $buildDir 'todo-demo.json'
    if (Test-Path -LiteralPath $demo) {
        Remove-Item -LiteralPath $demo -Force
    }
    $todoDir = Join-Path $examplesDir '20_todo'
    foreach ($line in @(
            @('-f', $demo, 'add', '买牛奶'),
            @('-f', $demo, 'add', '写周报'),
            @('-f', $demo, 'add', '修剪草坪'),
            @('-f', $demo, 'list'),
            @('-f', $demo, 'done', '2'),
            @('-f', $demo, 'list', '--all'),
            @('-f', $demo, 'remove', '3'),
            @('-f', $demo, 'list', '--all')
        )) {
        Invoke-Dart 'TodoDemo' (@('run', 'bin/todo.dart') + $line) $todoDir
    }
}

if ($Project) {
    $dir = Join-Path $examplesDir $Project
    if (-not (Test-Path -LiteralPath $dir)) {
        throw "找不到示例目录: $dir"
    }
    if (Test-Path -LiteralPath (Join-Path $dir 'pubspec.yaml')) {
        Invoke-Nested $Project
        if ($Project -eq '20_todo') {
            Invoke-TodoDemo
        }
    } else {
        # 单文件示例：-Project 06_collections 等价 -File 06_collections.dart
        Invoke-Dart 'Run' @('run', "examples/$Project.dart")
    }
    exit 0
}

if ($All) {
    Invoke-Dart 'Analyze' @('analyze')

    $files = Get-ChildItem -LiteralPath $examplesDir -Filter '*.dart' | Sort-Object Name
    if ($files.Count -eq 0) {
        throw 'examples 目录下没有单文件示例。'
    }
    foreach ($f in $files) {
        Invoke-Dart 'Run' @('run', "examples/$($f.Name)")
    }

    New-Item -ItemType Directory -Force -Path $buildDir | Out-Null
    $aotOut = if ($IsWindows -or $env:OS -eq 'Windows_NT') { 'build/02_hello.exe' } else { 'build/02_hello' }
    Invoke-Dart 'AOT' @('compile', 'exe', 'examples/02_hello.dart', '-o', $aotOut)

    foreach ($name in $nestedPackages) {
        Invoke-Nested $name
    }
    Invoke-TodoDemo

    Invoke-Dart 'Test' @('test')
    Write-Host '[Done] 全部示例运行、AOT 编译、嵌套包测试、根测试通过。' -ForegroundColor Green
    exit 0
}

Write-Host '用法:' -ForegroundColor Yellow
Write-Host '  .\build.ps1 -All                       全量验证：analyze + 运行全部示例 + AOT + 嵌套包测试 + 根测试'
Write-Host '  .\build.ps1 -File 06_collections.dart  运行单个示例'
Write-Host '  .\build.ps1 -Project 20_todo           验证嵌套包（19_testing 同理）'
Write-Host '  .\build.ps1 -Project 06_collections    运行单个单文件示例'
Write-Host '  .\build.ps1 -Test                      根包 analyze + test'
Write-Host '  .\build.ps1 -Clean                     清理 build 与 .dart_tool'
