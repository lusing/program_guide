param(
    [switch]$All,
    [string]$Project,
    [switch]$Clean
)

$projectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $projectRoot

# 跨平台探测 dotnet：优先 DOTNET_EXE 环境变量，其次 PATH 中的 dotnet（Windows/macOS/Linux 通用）
$dotnet = if ($env:DOTNET_EXE) { $env:DOTNET_EXE } else { (Get-Command dotnet -ErrorAction SilentlyContinue).Source }
$examplesDir = Join-Path $projectRoot "examples"
$buildDir = Join-Path $projectRoot "build"
$sep = [IO.Path]::DirectorySeparatorChar
$binRoot = (Join-Path $buildDir "bin") + $sep

if (-not $dotnet -or -not (Test-Path -LiteralPath $dotnet)) {
    throw "未找到 dotnet，请确认已安装 .NET SDK 且 dotnet 在 PATH 中（或设置环境变量 DOTNET_EXE 指向可执行文件）。"
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
    $objRoot = (Join-Path (Join-Path $buildDir "obj") $csproj.BaseName) + $sep
    & $dotnet build $csproj.FullName --nologo -v minimal `
        "-p:BaseOutputPath=$binRoot" `
        "-p:BaseIntermediateOutputPath=$objRoot"

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
Write-Host "  pwsh build.ps1 -All                  编译 examples 下全部示例工程"
Write-Host "  pwsh build.ps1 -Project <name>       编译单个示例工程（例如 09_linq）"
Write-Host "  pwsh build.ps1 -Project 19_portable  嵌套多工程目录会构建其下全部 csproj"
Write-Host "  pwsh build.ps1 -Clean                清理 build 目录"
Write-Host "（Windows PowerShell 下用 .\build.ps1 ...；脚本会自动探测 PATH 中的 dotnet，可用 DOTNET_EXE 覆盖）"

