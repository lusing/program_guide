param(
    [switch]$All,
    [string]$Project,
    [switch]$Clean,
    [switch]$Run
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
# 注意：不要用 Get-ChildItem -Include——PS 5.1 中与 -LiteralPath/-Recurse 组合时
# -Include 会被忽略，导致匹配到全部目录、把示例源码删光（实测事故）。用 Where-Object 过滤名字。
$strayDirs = Get-ChildItem -LiteralPath $examplesDir -Recurse -Directory |
    Where-Object { ($_.Name -eq "obj" -or $_.Name -eq "bin") -and $_.FullName -notlike "$buildDir*" }
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

# 逐个编译（全部 36 章；单个用 -Project NN_name）
$targets = if ($Project) {
    $dir = Join-Path $examplesDir $Project
    if (-not (Test-Path -LiteralPath $dir)) { throw "找不到示例工程: $Project" }
    @(Split-Path -Parent (Get-ChildItem -LiteralPath $dir -Filter "*.csproj" | Select-Object -First 1).FullName)
} else {
    $projects | ForEach-Object { Split-Path -Parent $_.FullName }
}

foreach ($t in $targets) { Invoke-BuildProject -ProjectDir $t }

Write-Host "[Done] 编译通过。" -ForegroundColor Green

# -Run：运行全部产物（示例都设计为非交互、输出讲解内容），失败退出码即报错
if ($Run) {
    $exeDir = Join-Path $buildDir "bin\Debug\net10.0"
    $exes = Get-ChildItem -LiteralPath $exeDir -Filter "*.exe" | Sort-Object Name
    $failed = 0
    foreach ($exe in $exes) {
        Write-Host "`n[Run] $($exe.BaseName)" -ForegroundColor Cyan
        & $exe.FullName
        if ($LASTEXITCODE -ne 0) { Write-Host "[FAIL] $($exe.BaseName) 退出码 $LASTEXITCODE" -ForegroundColor Red; $failed++ }
    }
    $runColor = if ($failed -eq 0) { 'Green' } else { 'Red' }
    Write-Host "`n[Run] $($exes.Count) 个程序运行完毕，$failed 个失败。" -ForegroundColor $runColor
    exit $failed
}
