param(
    [switch]$All,
    [string]$Project,
    [switch]$Clean
)

$projectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $projectRoot

$go = "G:\scoop\apps\go\current\bin\go.exe"
$examplesDir = Join-Path $projectRoot "examples"
$buildDir = Join-Path $projectRoot "build"

if (-not (Test-Path -LiteralPath $go)) {
    throw "未找到 Go 可执行文件，请检查安装路径：$go"
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

function Invoke-BuildExample {
    param(
        [Parameter(Mandatory = $true)][string]$ExampleDir
    )

    $exampleName = Split-Path -Leaf $ExampleDir
    $mainFile = Join-Path $ExampleDir "main.go"
    if (-not (Test-Path -LiteralPath $mainFile)) {
        throw "示例缺少 main.go: $ExampleDir"
    }

    $output = Join-Path $buildDir ($exampleName + ".exe")

    Write-Host "[Build] $exampleName" -ForegroundColor Cyan
    Set-Location $ExampleDir
    & $go build -o $output .
    if ($LASTEXITCODE -ne 0) {
        throw "编译失败: $ExampleDir"
    }

    Write-Host "[Run] $exampleName" -ForegroundColor DarkCyan
    & $output
    if ($LASTEXITCODE -ne 0) {
        throw "运行失败: $ExampleDir"
    }
}

if ($All) {
    foreach ($entry in $examples) {
        Invoke-BuildExample -ExampleDir $entry.FullName
    }
    Write-Host "[Done] examples 目录全部验证通过。" -ForegroundColor Green
    exit 0
}

if ($Project) {
    $exampleDir = Join-Path $examplesDir $Project
    if (-not (Test-Path -LiteralPath $exampleDir)) {
        throw "找不到示例工程: $exampleDir"
    }

    Invoke-BuildExample -ExampleDir $exampleDir
    Write-Host "[Done] 验证通过: $Project" -ForegroundColor Green
    exit 0
}

Write-Host "用法:" -ForegroundColor Yellow
Write-Host "  .\build.ps1 -All                  编译并验证 examples 下全部示例工程"
Write-Host "  .\build.ps1 -Project <name>       编译并验证单个示例工程（例如 01_hello 或 05_concurrency）"
Write-Host "  .\build.ps1 -Clean                清理 build 目录"
