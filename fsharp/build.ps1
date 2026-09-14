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
    throw "未找到 dotnet.exe，请检查 .NET SDK 安装路径：$dotnet"
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

$projects = Get-ChildItem -LiteralPath $examplesDir -Directory | Sort-Object Name
if ($projects.Count -eq 0) {
    throw "examples 目录下没有示例工程。"
}

New-Item -ItemType Directory -Force -Path $buildDir | Out-Null

function Invoke-BuildProject {
    param(
        [Parameter(Mandatory = $true)][string]$ProjectDir
    )

    $projName = Split-Path -Leaf $ProjectDir
    $fsproj = Get-ChildItem -LiteralPath $ProjectDir -Filter "*.fsproj" | Select-Object -First 1
    if (-not $fsproj) {
        throw "示例工程缺少 .fsproj: $ProjectDir"
    }

    Write-Host "[Build] $projName" -ForegroundColor Cyan
    & $dotnet build $fsproj.FullName --nologo -v minimal -c Release `
        "/p:BaseOutputPath=$buildDir\bin\" `
        "/p:BaseIntermediateOutputPath=$buildDir\obj\"

    if ($LASTEXITCODE -ne 0) {
        throw "编译失败: $($fsproj.FullName)"
    }

    $targetFramework = "net10.0"
    $outputExe = Join-Path $buildDir "bin\Release\$targetFramework\$projName.exe"
    $outputDll = Join-Path $buildDir "bin\Release\$targetFramework\$projName.dll"

    if ($projName -match 'winforms|wpf') {
        Write-Host "[BuildOnly] $projName (GUI 应用，跳过运行，已完成编译验证)" -ForegroundColor DarkCyan
        return
    }

    Write-Host "[Run] $projName" -ForegroundColor DarkCyan
    if (Test-Path -LiteralPath $outputExe) {
        & $outputExe
    }
    elseif (Test-Path -LiteralPath $outputDll) {
        & $dotnet $outputDll
    }
    else {
        throw "未找到生成的可执行文件: $projName"
    }

    if ($LASTEXITCODE -ne 0) {
        throw "运行失败: $($fsproj.FullName)"
    }
}

if ($All) {
    foreach ($entry in $projects) {
        Invoke-BuildProject -ProjectDir $entry.FullName
    }
    Write-Host "[Done] examples 目录全部验证通过。" -ForegroundColor Green
    exit 0
}

if ($Project) {
    $projectDir = Join-Path $examplesDir $Project
    if (-not (Test-Path -LiteralPath $projectDir)) {
        throw "找不到示例工程: $projectDir"
    }
    Invoke-BuildProject -ProjectDir $projectDir
    Write-Host "[Done] 验证通过: $Project" -ForegroundColor Green
    exit 0
}

Write-Host "用法:" -ForegroundColor Yellow
Write-Host "  .\build.ps1 -All                  编译并验证 examples 下全部示例工程（GUI 项目仅构建，不直接运行）"
Write-Host "  .\build.ps1 -Project <name>       编译并验证单个示例工程（例如 03_functions_and_patterns 或 07_winforms）"
Write-Host "  .\build.ps1 -Clean                清理 build 目录"
