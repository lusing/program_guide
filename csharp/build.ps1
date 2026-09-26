param(
    [switch]$All,
    [string]$Project,
    [switch]$Clean,
    [switch]$Run
)

$projectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $projectRoot

# 跨平台探测 dotnet：优先 DOTNET_EXE 环境变量，其次 PATH 中的 dotnet（Windows/macOS/Linux 通用）
$dotnet = if ($env:DOTNET_EXE) { $env:DOTNET_EXE } else { (Get-Command dotnet -ErrorAction SilentlyContinue).Source }
$examplesDir = Join-Path $projectRoot "examples"
$buildDir = Join-Path $projectRoot "build"
$sep = [IO.Path]::DirectorySeparatorChar
# BaseOutputPath / BaseIntermediateOutputPath 必须以分隔符结尾，否则 MSBuild 把它当文件名前缀
$binRoot = (Join-Path $buildDir "bin") + $sep
$outDir = Join-Path (Join-Path $buildDir "bin") (Join-Path "Debug" "net10.0")

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

# 按构建顺序（=章号顺序）记下产物，供 -Run 逐个执行
$runTargets = @()

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
    $objRoot = (Join-Path (Join-Path $buildDir "obj") $csproj.BaseName) + $sep
    & $dotnet build $csproj.FullName --nologo -v minimal `
        "-p:BaseOutputPath=$binRoot" `
        "-p:BaseIntermediateOutputPath=$objRoot"

    if ($LASTEXITCODE -ne 0) {
        throw "编译失败: $($csproj.FullName)"
    }

    # 产物名=程序集名（示例都没写 AssemblyName，即 csproj 文件名）。
    # 用 dotnet 跑 dll 而不是 apphost：三个平台一致，省掉 Unix 上没有 .exe 后缀、
    # 还得处理执行权限的麻烦。
    $script:runTargets += [pscustomobject]@{
        Name = $projName
        Dll  = Join-Path $outDir "$($csproj.BaseName).dll"
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
    $failed = 0
    foreach ($t in $runTargets) {
        Write-Host "`n[Run] $($t.Name)" -ForegroundColor Cyan
        & $dotnet $t.Dll
        if ($LASTEXITCODE -ne 0) { Write-Host "[FAIL] $($t.Name) 退出码 $LASTEXITCODE" -ForegroundColor Red; $failed++ }
    }
    $runColor = if ($failed -eq 0) { 'Green' } else { 'Red' }
    Write-Host "`n[Run] $($runTargets.Count) 个程序运行完毕，$failed 个失败。" -ForegroundColor $runColor
    exit $failed
}
