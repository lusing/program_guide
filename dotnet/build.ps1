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

$projects = Get-ChildItem -LiteralPath $examplesDir -Recurse -Filter "*.csproj" | Sort-Object FullName

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

# 清扫 examples 下游离的 obj/bin（读者直接 dotnet run 会在示例目录生成默认产物，
# 与本脚本的集中 obj 路径冲突，导致 CS0579 重复特性错误）
$strayDirs = Get-ChildItem -LiteralPath $examplesDir -Recurse -Directory -Include obj, bin |
    Where-Object { $_.FullName -notlike "$buildDir*" }
foreach ($stray in $strayDirs) {
    Remove-Item -LiteralPath $stray.FullName -Recurse -Force
}

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
        "-p:BaseIntermediateOutputPath=$buildDir\obj\$($csproj.BaseName)\"

    if ($LASTEXITCODE -ne 0) {
        throw "编译失败: $($csproj.FullName)"
    }
}

if ($All) {
    foreach ($entry in $projects) {
        Invoke-BuildProject -ProjectDir (Split-Path -Parent $entry.FullName)
    }
    Write-Host "[Done] examples 目录全部编译通过。" -ForegroundColor Green
    exit 0
}

if ($Project) {
    $projectDir = Join-Path $examplesDir $Project
    if (-not (Test-Path -LiteralPath $projectDir)) {
        throw "找不到示例工程: $projectDir"
    }
    $csprojs = Get-ChildItem -LiteralPath $projectDir -Recurse -Filter "*.csproj" | Sort-Object FullName
    if ($csprojs.Count -eq 0) {
        throw "示例工程缺少 csproj: $projectDir"
    }
    foreach ($p in $csprojs) {
        Invoke-BuildProject -ProjectDir $p.DirectoryName
    }
    Write-Host "[Done] 编译通过: $Project" -ForegroundColor Green
    exit 0
}

Write-Host "用法:" -ForegroundColor Yellow
Write-Host "  .\build.ps1 -All                  编译 examples 下全部示例工程"
Write-Host "  .\build.ps1 -Project <name>       编译单个示例工程（例如 09_linq）"
Write-Host "  .\build.ps1 -Project 19_portable  嵌套多工程目录会构建其下全部 csproj"
Write-Host "  .\build.ps1 -Clean                清理 build 目录"

