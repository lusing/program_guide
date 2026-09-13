param(
    [switch]$All,
    [string]$Project,
    [switch]$Clean
)

$projectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $projectRoot

$dotnet = "G:\scoop\apps\dotnet-sdk\current\dotnet.exe"
$examplesDir = Join-Path $projectRoot "examples"
$buildDir = Join-Path $projectRoot "build"

if (-not (Test-Path -LiteralPath $dotnet)) {
    throw "未找到 dotnet.exe，请检查 .NET SDK 安装路径。"
}

if (-not (Test-Path -LiteralPath $examplesDir)) {
    throw "找不到 examples 目录: $examplesDir"
}

$projects = Get-ChildItem -LiteralPath $examplesDir -Directory | Sort-Object Name

if ($Clean) {
    if (Test-Path -LiteralPath $buildDir) {
        Remove-Item -LiteralPath $buildDir -Recurse -Force
        Write-Host "[Clean] 已清理 build 目录。" -ForegroundColor Yellow
    } else {
        Write-Host "[Clean] build 目录不存在，无需清理。" -ForegroundColor Yellow
    }
    exit 0
}

if ($projects.Count -eq 0) {
    throw "examples 目录下没有示例工程。"
}

New-Item -ItemType Directory -Force -Path $buildDir | Out-Null

function Invoke-BuildProject {
    param(
        [Parameter(Mandatory = $true)][string]$ProjectDir
    )

    $projName = Split-Path -Leaf $ProjectDir
    $csproj = Get-ChildItem -LiteralPath $ProjectDir -Filter "*.csproj" | Select-Object -First 1
    if (-not $csproj) {
        throw "示例工程缺少 csproj: $ProjectDir"
    }

    Write-Host "[Build] $projName" -ForegroundColor Cyan
    & $dotnet build $csproj.FullName --nologo -v minimal `
        "-p:BaseOutputPath=$buildDir\bin\" `
        "-p:BaseIntermediateOutputPath=$buildDir\obj\"

    if ($LASTEXITCODE -ne 0) {
        throw "编译失败: $($csproj.FullName)"
    }
}

if ($All) {
    foreach ($entry in $projects) {
        Invoke-BuildProject -ProjectDir $entry.FullName
    }
    Write-Host "[Done] examples 目录全部编译通过。" -ForegroundColor Green
    exit 0
}

if ($Project) {
    $projectDir = Join-Path $examplesDir $Project
    if (-not (Test-Path -LiteralPath $projectDir)) {
        throw "找不到示例工程: $projectDir"
    }
    Invoke-BuildProject -ProjectDir $projectDir
    Write-Host "[Done] 编译通过: $Project" -ForegroundColor Green
    exit 0
}

Write-Host "用法:" -ForegroundColor Yellow
Write-Host "  .\build.ps1 -All                  编译 examples 下全部示例工程"
Write-Host "  .\build.ps1 -Project <name>       编译单个示例工程（例如 03_linq_basics）"
Write-Host "  .\build.ps1 -Clean                清理 build 目录"

