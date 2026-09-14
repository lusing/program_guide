param(
    [switch]$All,
    [string]$Project,
    [switch]$Clean
)

$projectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $projectRoot

$renpy = "G:\scoop\apps\renpy\current\renpy.exe"
$examplesDir = Join-Path $projectRoot "examples"
$buildDir = Join-Path $projectRoot "build"

if (-not (Test-Path -LiteralPath $renpy)) {
    throw "未找到 Ren'Py 可执行文件，请检查安装路径：$renpy"
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

function Invoke-CompileProject {
    param(
        [Parameter(Mandatory = $true)][string]$ExampleDir
    )

    $exampleName = Split-Path -Leaf $ExampleDir
    $scriptFile = Join-Path $ExampleDir "game\script.rpy"

    if (-not (Test-Path -LiteralPath $scriptFile)) {
        throw "示例缺少 game/script.rpy: $ExampleDir"
    }

    Write-Host "[Compile] $exampleName" -ForegroundColor Cyan
    & $renpy $ExampleDir compile

    if ($LASTEXITCODE -ne 0) {
        throw "编译失败: $ExampleDir"
    }
}

if ($All) {
    foreach ($entry in $examples) {
        Invoke-CompileProject -ExampleDir $entry.FullName
    }
    Write-Host "[Done] examples 目录全部验证通过。" -ForegroundColor Green
    exit 0
}

if ($Project) {
    $exampleDir = Join-Path $examplesDir $Project
    if (-not (Test-Path -LiteralPath $exampleDir)) {
        throw "找不到示例工程: $exampleDir"
    }

    Invoke-CompileProject -ExampleDir $exampleDir
    Write-Host "[Done] 验证通过: $Project" -ForegroundColor Green
    exit 0
}

Write-Host "用法:" -ForegroundColor Yellow
Write-Host "  .\build.ps1 -All                  编译并验证 examples 下全部示例工程"
Write-Host "  .\build.ps1 -Project <name>       编译并验证单个示例工程（例如 01_hello 或 04_dialogue_and_choices）"
Write-Host "  .\build.ps1 -Clean                清理 build 目录"
