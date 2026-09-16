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

# 清扫 examples 下游离的 obj/bin（读者直接 dotnet run 会在示例目录生成默认产物，
# 与本脚本的集中重定向路径冲突，导致重复生成特性等错误）
$strayDirs = Get-ChildItem -LiteralPath $examplesDir -Recurse -Directory -Include obj, bin |
    Where-Object { $_.FullName -notlike "$buildDir*" }
foreach ($stray in $strayDirs) {
    Remove-Item -LiteralPath $stray.FullName -Recurse -Force
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

$projects = Get-ChildItem -LiteralPath $examplesDir -Recurse -Filter "*.fsproj" | Sort-Object FullName
if ($projects.Count -eq 0) {
    throw "examples 目录下没有示例工程。"
}

New-Item -ItemType Directory -Force -Path $buildDir | Out-Null

function Invoke-Project {
    param([Parameter(Mandatory = $true)][System.IO.FileInfo]$Fsproj)

    $name = $Fsproj.BaseName
    $raw = Get-Content -LiteralPath $Fsproj.FullName -Raw
    $isGui = $raw -match 'net10\.0-windows'
    $isTest = $raw -match 'Microsoft\.NET\.Test\.Sdk'

    # 测试工程不经重定向构建：BaseIntermediateOutputPath 等全局属性会传播到
    # ProjectReference 引用的工程，两边 restore 会互相覆盖 assets 文件；
    # 直接 dotnet test（自建默认 obj/bin，下次脚本运行时被清扫回收）
    if ($isTest) {
        Write-Host "[Test] $name" -ForegroundColor Magenta
        & $dotnet test $Fsproj.FullName --nologo -v minimal
        if ($LASTEXITCODE -ne 0) {
            throw "测试未通过: $name"
        }
        return
    }

    Write-Host "[Build] $name" -ForegroundColor Cyan
    & $dotnet build $Fsproj.FullName --nologo -v minimal -c Release `
        "-p:BaseOutputPath=$buildDir\bin\" `
        "-p:BaseIntermediateOutputPath=$buildDir\obj\$name\"
    if ($LASTEXITCODE -ne 0) {
        throw "编译失败: $($Fsproj.FullName)"
    }

    if ($isGui) {
        Write-Host "[BuildOnly] $name（GUI 工程，跳过运行）" -ForegroundColor DarkCyan
        return
    }

    $exe = Join-Path $buildDir "bin\Release\net10.0\$name.exe"
    $dll = Join-Path $buildDir "bin\Release\net10.0\$name.dll"

    if ($name -eq 'Todo') {
        $demoSequence = @(
            @('reset'),
            @('add', 'learn F#'),
            @('add', 'write tutorial'),
            @('show'),
            @('done', '2'),
            @('show'),
            @('remove', '1'),
            @('show')
        )
        foreach ($args_ in $demoSequence) {
            Write-Host "[Run] Todo $($args_ -join ' ')" -ForegroundColor DarkCyan
            & $exe @args_
            if ($LASTEXITCODE -ne 0) {
                throw "运行失败: Todo $($args_ -join ' ')"
            }
        }
        return
    }

    Write-Host "[Run] $name" -ForegroundColor DarkCyan
    if (Test-Path -LiteralPath $exe) {
        & $exe
    } elseif (Test-Path -LiteralPath $dll) {
        & $dotnet $dll
    } else {
        throw "未找到生成的可执行文件: $name"
    }
    if ($LASTEXITCODE -ne 0) {
        throw "运行失败: $name"
    }
}

if ($All) {
    foreach ($entry in $projects) {
        Invoke-Project -Fsproj $entry
    }
    Write-Host "[Done] examples 目录全部验证通过。" -ForegroundColor Green
    exit 0
}

if ($Project) {
    $projectDir = Join-Path $examplesDir $Project
    if (-not (Test-Path -LiteralPath $projectDir)) {
        throw "找不到示例工程: $projectDir"
    }
    $fsprojs = Get-ChildItem -LiteralPath $projectDir -Recurse -Filter "*.fsproj" | Sort-Object FullName
    if ($fsprojs.Count -eq 0) {
        throw "示例工程缺少 fsproj: $projectDir"
    }
    foreach ($p in $fsprojs) {
        Invoke-Project -Fsproj $p
    }
    Write-Host "[Done] 验证通过: $Project" -ForegroundColor Green
    exit 0
}

Write-Host "用法:" -ForegroundColor Yellow
Write-Host "  .\build.ps1 -All                  编译并验证 examples 下全部示例工程（GUI 仅构建，测试工程跑 dotnet test）"
Write-Host "  .\build.ps1 -Project <name>       编译并验证单个示例目录（例如 06_collections；嵌套目录构建其下全部 fsproj）"
Write-Host "  .\build.ps1 -Clean                清理 build 目录"
