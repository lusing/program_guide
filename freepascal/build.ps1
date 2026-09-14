param(
    [switch]$All,
    [string]$File,
    [switch]$Clean
)

$projectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $projectRoot

$compiler = "G:\scoop\apps\freepascal\current\bin\i386-win32\fpc.exe"
$examplesDir = Join-Path $projectRoot "examples"
$buildDir = Join-Path $projectRoot "build"

if (-not (Test-Path -LiteralPath $compiler)) {
    throw "未找到 Free Pascal 编译器，请检查路径：$compiler"
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

if (-not (Test-Path -LiteralPath $examplesDir)) {
    throw "找不到 examples 目录: $examplesDir"
}

New-Item -ItemType Directory -Force -Path $buildDir | Out-Null

function Invoke-FreePascalExample {
    param(
        [Parameter(Mandatory = $true)][string]$SourcePath
    )

    $name = [System.IO.Path]::GetFileNameWithoutExtension($SourcePath)
    $sourceDir = Split-Path -Parent $SourcePath
    $compiledExe = Join-Path $sourceDir ($name + ".exe")
    $compiledObj = Join-Path $sourceDir ($name + ".o")
    $buildExe = Join-Path $buildDir ($name + ".exe")
    $displayName = [System.IO.Path]::GetFileName($SourcePath)

    Get-ChildItem -LiteralPath $sourceDir -Filter ($name + ".exe") -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue
    Get-ChildItem -LiteralPath $sourceDir -Filter ($name + ".o") -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue

    Write-Host "[Compile] $displayName" -ForegroundColor Cyan
    & $compiler -MObjFPC -Sc -O2 $SourcePath
    if ($LASTEXITCODE -ne 0) {
        throw "编译失败: $SourcePath"
    }

    if (-not (Test-Path -LiteralPath $compiledExe)) {
        throw "编译未产出可执行文件: $compiledExe"
    }

    Copy-Item -LiteralPath $compiledExe -Destination $buildExe -Force

    Write-Host "[Run] $displayName" -ForegroundColor DarkCyan
    & $buildExe
    if ($LASTEXITCODE -ne 0) {
        throw "运行失败: $SourcePath"
    }

    if (Test-Path -LiteralPath $compiledExe) { Remove-Item -LiteralPath $compiledExe -Force }
    if (Test-Path -LiteralPath $compiledObj) { Remove-Item -LiteralPath $compiledObj -Force }
    if (Test-Path -LiteralPath (Join-Path $sourceDir 'demo_output.txt')) { Remove-Item -LiteralPath (Join-Path $sourceDir 'demo_output.txt') -Force }
}

if ($All) {
    $files = Get-ChildItem -LiteralPath $examplesDir -Filter "*.pas" | Sort-Object Name
    if ($files.Count -eq 0) {
        throw "examples 目录下没有 .pas 示例文件。"
    }

    foreach ($f in $files) {
        Invoke-FreePascalExample -SourcePath $f.FullName
    }

    $lazarusProjects = @(
        (Join-Path $examplesDir "13_lazarus_gui\LazarusGuiDemo.lpi"),
        (Join-Path $examplesDir "14_lazarus_advanced_controls\AdvancedControlsDemo.lpi"),
        (Join-Path $examplesDir "15_lazarus_menus_dialogs\LazarusMenusDemo.lpi")
    )

    foreach ($lazarusProject in $lazarusProjects) {
        if (Test-Path -LiteralPath $lazarusProject) {
            $projectName = [System.IO.Path]::GetFileName($lazarusProject)
            Write-Host "[Compile] $projectName" -ForegroundColor Cyan
            & "G:\scoop\apps\lazarus\current\lazbuild.exe" $lazarusProject
            if ($LASTEXITCODE -ne 0) {
                throw "Lazarus GUI 项目编译失败: $lazarusProject"
            }
        }
    }

    Write-Host "[Done] examples 目录全部验证通过。" -ForegroundColor Green
    exit 0
}

if ($File) {
    $sourcePath = Join-Path $examplesDir $File

    if (Test-Path -LiteralPath $sourcePath -PathType Container) {
        $guiMap = @{
            "13_lazarus_gui" = (Join-Path $examplesDir "13_lazarus_gui\LazarusGuiDemo.lpi");
            "14_lazarus_advanced_controls" = (Join-Path $examplesDir "14_lazarus_advanced_controls\AdvancedControlsDemo.lpi");
            "15_lazarus_menus_dialogs" = (Join-Path $examplesDir "15_lazarus_menus_dialogs\LazarusMenusDemo.lpi")
        }

        if ($guiMap.ContainsKey($File)) {
            $projectPath = $guiMap[$File]
            $projectName = [System.IO.Path]::GetFileName($projectPath)
            Write-Host "[Compile] $projectName" -ForegroundColor Cyan
            & "G:\scoop\apps\lazarus\current\lazbuild.exe" $projectPath
            if ($LASTEXITCODE -ne 0) {
                throw "Lazarus GUI 项目编译失败: $projectPath"
            }
            Write-Host "[Done] 验证通过: $File" -ForegroundColor Green
            exit 0
        }

        throw "目标不是单个示例文件: $sourcePath"
    }

    if (-not (Test-Path -LiteralPath $sourcePath)) {
        throw "找不到示例文件: $sourcePath"
    }

    Invoke-FreePascalExample -SourcePath $sourcePath
    Write-Host "[Done] 验证通过: $File" -ForegroundColor Green
    exit 0
}

Write-Host "用法:" -ForegroundColor Yellow
Write-Host "  .\build.ps1 -All           编译并运行 examples 下全部示例"
Write-Host "  .\build.ps1 -File <name>   编译并运行单个示例（如 08_arrays.pas）"
Write-Host "  .\build.ps1 -Clean         清理 build 目录"
