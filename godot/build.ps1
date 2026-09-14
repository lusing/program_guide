param(
    [switch]$All,
    [string]$Project,
    [switch]$Clean
)

$projectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $projectRoot

$godot = "G:\scoop\apps\godot\current\godot.console.exe"
$examplesDir = Join-Path $projectRoot "examples"
$buildDir = Join-Path $projectRoot "build"

if (-not (Test-Path -LiteralPath $godot)) {
    throw "未找到 Godot 可执行文件，请检查安装路径：$godot"
}

if (-not (Test-Path -LiteralPath $examplesDir)) {
    throw "找不到 examples 目录: $examplesDir"
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

$examples = Get-ChildItem -LiteralPath $examplesDir -Directory | Sort-Object Name
if ($examples.Count -eq 0) {
    throw "examples 目录下没有示例工程。"
}

New-Item -ItemType Directory -Force -Path $buildDir | Out-Null

function Invoke-ExampleProject {
    param(
        [Parameter(Mandatory = $true)][string]$ExampleDir
    )

    $exampleName = Split-Path -Leaf $ExampleDir
    $projectFile = Join-Path $ExampleDir "project.godot"
    $mainScript = Join-Path $ExampleDir "main.gd"

    if (-not (Test-Path -LiteralPath $projectFile)) {
        throw "示例缺少 project.godot: $ExampleDir"
    }

    if (-not (Test-Path -LiteralPath $mainScript)) {
        throw "示例缺少 main.gd: $ExampleDir"
    }

    Write-Host "[Run] $exampleName" -ForegroundColor Cyan
    & $godot --headless --path $ExampleDir --script $mainScript

    if ($LASTEXITCODE -ne 0) {
        throw "运行失败: $ExampleDir"
    }
}

if ($All) {
    foreach ($entry in $examples) {
        Invoke-ExampleProject -ExampleDir $entry.FullName
    }
    Write-Host "[Done] examples 目录全部验证通过。" -ForegroundColor Green
    exit 0
}

if ($Project) {
    $exampleDir = Join-Path $examplesDir $Project
    if (-not (Test-Path -LiteralPath $exampleDir)) {
        throw "找不到示例目录: $exampleDir"
    }

    Invoke-ExampleProject -ExampleDir $exampleDir
    Write-Host "[Done] 验证通过: $Project" -ForegroundColor Green
    exit 0
}

Write-Host "用法:" -ForegroundColor Yellow
Write-Host "  .\build.ps1 -All                  运行 examples 下全部示例"
Write-Host "  .\build.ps1 -Project <name>       运行单个示例（例如 01_hello 或 04_signals）"
Write-Host "  .\build.ps1 -Clean                清理 build 目录"
