param(
    [switch]$All,
    [string]$File,
    [switch]$Clean
)

$projectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $projectRoot

$examplesDir = Join-Path $projectRoot "examples"
$buildDir = Join-Path $projectRoot "build"

$ocamlcCandidates = @(
    "/usr/local/bin/ocamlc",
    "/opt/local/bin/ocamlc",
    "/usr/bin/ocamlc"
)

$ocamlc = $ocamlcCandidates | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1
if (-not $ocamlc) {
    throw "未找到 ocamlc，请检查 OCaml 安装路径。候选路径：$($ocamlcCandidates -join ', ')"
}

Write-Host "[Info] 使用编译器: $ocamlc" -ForegroundColor Gray

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

function Invoke-CompileFile {
    param(
        [Parameter(Mandatory = $true)][string]$SourcePath
    )

    $fileName = [System.IO.Path]::GetFileName($SourcePath)
    $baseName = [System.IO.Path]::GetFileNameWithoutExtension($SourcePath)
    $outputPath = Join-Path $buildDir $baseName

    Write-Host "[Compile] $fileName" -ForegroundColor Cyan

    & $ocamlc -o $outputPath $SourcePath
    if ($LASTEXITCODE -ne 0) {
        throw "编译失败: $fileName"
    }

    Write-Host "[OK]      $fileName -> build/$baseName" -ForegroundColor Green
}

if ($All) {
    $files = Get-ChildItem -LiteralPath $examplesDir -Filter "*.ml" | Sort-Object Name
    if ($files.Count -eq 0) {
        throw "examples 目录下没有 .ml 示例文件。"
    }

    $pass = 0
    $fail = 0
    $failedFiles = @()

    foreach ($f in $files) {
        try {
            Invoke-CompileFile -SourcePath $f.FullName
            $pass++
        } catch {
            Write-Host "[FAIL]    $($f.Name): $_" -ForegroundColor Red
            $fail++
            $failedFiles += $f.Name
        }
    }

    Write-Host ""
    Write-Host "[Done] 总计 $($files.Count) 个文件：通过 $pass，失败 $fail。" -ForegroundColor $(if ($fail -eq 0) { "Green" } else { "Red" })

    if ($failedFiles.Count -gt 0) {
        Write-Host "失败文件: $($failedFiles -join ', ')" -ForegroundColor Red
        exit 1
    }

    exit 0
}

if ($File) {
    # 支持只写编号，自动补全前缀和后缀
    if ($File -match '^\d+$') {
        $padded = $File.PadLeft(2, '0')
        $matches = Get-ChildItem -LiteralPath $examplesDir -Filter "${padded}_*.ml" | Sort-Object Name
        if ($matches.Count -eq 0) {
            throw "找不到编号为 $File 的示例文件。"
        }
        $sourcePath = $matches[0].FullName
    } else {
        if (-not $File.EndsWith('.ml')) {
            $File = $File + '.ml'
        }
        $sourcePath = Join-Path $examplesDir $File
        if (-not (Test-Path -LiteralPath $sourcePath)) {
            throw "找不到示例文件: $sourcePath"
        }
    }

    Invoke-CompileFile -SourcePath $sourcePath
    Write-Host "[Done] 编译通过: $([System.IO.Path]::GetFileName($sourcePath))" -ForegroundColor Green
    exit 0
}

Write-Host "用法:" -ForegroundColor Yellow
Write-Host "  .\build.ps1 -All            编译 examples 下全部示例"
Write-Host "  .\build.ps1 -File <name.ml> 编译单个示例（只写编号也可以，如 01）"
Write-Host "  .\build.ps1 -Clean          清理 build 目录"
