param(
    [switch]$All,
    [string]$Example,
    [switch]$Clean
)

$ErrorActionPreference = "Stop"
$projectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $projectRoot

# ---------------------------------------------------------------
# 平台判定。$IsWindows 是 pwsh 的只读自动变量（Windows PowerShell 5.1 里没有），
# 所以不能直接自己定义 $isWindows —— 变量名不区分大小写，会撞上自动变量。
# ---------------------------------------------------------------
$isWin = if (Test-Path Variable:\IsWindows) { [bool]$IsWindows } else { $env:OS -eq 'Windows_NT' }
$exeSuffix = if ($isWin) { ".exe" } else { "" }

# ---------------------------------------------------------------
# 工具链定位：GOBIN 环境变量 > 平台常见安装路径 > PATH 上的 go。
# 原来写死 G:\scoop\apps\go\current，在非 Windows 上必挂。
# ---------------------------------------------------------------
function Resolve-GoExe {
    if ($env:GOBIN -and (Test-Path -LiteralPath $env:GOBIN)) { return $env:GOBIN }
    $candidates = if ($isWin) {
        @("G:\scoop\apps\go\current\bin\go.exe", "C:\Program Files\Go\bin\go.exe")
    } else {
        # macOS 上系统 PATH 里常没有 go：MacPorts 装在 /opt/local，官方包在 /usr/local/go
        @("/opt/local/bin/go", "/opt/local/bin/go-1.27", "/usr/local/go/bin/go")
    }
    foreach ($c in $candidates) {
        if (Test-Path -LiteralPath $c) { return $c }
    }
    $cmd = Get-Command go -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($cmd) { return $cmd.Source }
    return $null
}

$goExe = Resolve-GoExe
if (-not $goExe) { throw "未找到 go。请安装 Go 1.27+，或设置 GOBIN 指向 go 可执行文件。" }

# gofmt 不单独找——它必须和 go 来自同一个 GOROOT，否则版本不一致，
# gofmt 判过的代码可能是另一个版本的标准。
$goRoot = (& $goExe env GOROOT).Trim()
$gofmtExe = Join-Path $goRoot "bin/gofmt$exeSuffix"
if (-not (Test-Path -LiteralPath $gofmtExe)) {
    $gf = Get-Command gofmt -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $gf) { throw "未找到 gofmt（GOROOT=$goRoot）" }
    $gofmtExe = $gf.Source
    Write-Host "[警告] gofmt 不在 GOROOT 里，可能与 go 版本不同步：$gofmtExe" -ForegroundColor Yellow
}

# macOS 上输出被重定向时设置 OutputEncoding 会抛，包一层免得脚本自己先挂
try { [Console]::OutputEncoding = [System.Text.UTF8Encoding]::new() } catch { }

# -race 依赖 cgo，cgo 又依赖 C 编译器（Windows 要 gcc，macOS 要 clang）。
# 没有就退化成不带 -race 跑并提示——总比直接失败好。
$cgoEnabled = (& $goExe env CGO_ENABLED).Trim()
$raceOk = ($cgoEnabled -eq "1")

Write-Host "go    : $goExe ($(& $goExe version))" -ForegroundColor DarkGray
Write-Host "gofmt : $gofmtExe" -ForegroundColor DarkGray
Write-Host "平台  : $(if ($isWin) { 'Windows' } else { '非 Windows' }) / cgo=$cgoEnabled / race=$raceOk" -ForegroundColor DarkGray

$buildDir = Join-Path $projectRoot "build"
$examplesDir = Join-Path $projectRoot "examples"

if ($Clean) {
    if (Test-Path -LiteralPath $buildDir) { Remove-Item -LiteralPath $buildDir -Recurse -Force }
    Write-Host "[Clean] 已清理 build 目录。" -ForegroundColor Yellow
    exit 0
}

New-Item -ItemType Directory -Force -Path $buildDir | Out-Null

function Invoke-Go {
    param([string]$WorkingDir, [string[]]$ArgList)
    Push-Location $WorkingDir
    try {
        & $goExe @ArgList
        if ($LASTEXITCODE -ne 0) { throw "命令失败: go $($ArgList -join ' ') (cwd=$WorkingDir)" }
    } finally { Pop-Location }
}

function Invoke-Native {
    param([string]$ExePath, [string]$WorkingDir, [string[]]$RunArgs = @())
    Push-Location $WorkingDir
    try {
        & $ExePath @RunArgs
        if ($LASTEXITCODE -ne 0) { throw "运行失败(退出码 $LASTEXITCODE): $ExePath $($RunArgs -join ' ')" }
    } finally { Pop-Location }
}

# gofmt -l 列出“待格式化”的文件；gofmt 退出码恒为 0，必须看输出是否为空。
# Get-Content -Raw 读空文件返回 $null，所以这里 $pending 可能是 $null 或字符串数组。
function Test-Gofmt {
    param([string]$Dir)
    Push-Location $Dir
    try {
        $pending = & $gofmtExe -l .
        if ($pending) { throw "gofmt 未通过（以下文件需格式化）: $($pending -join ', ')" }
    } finally { Pop-Location }
}

# 普通示例四层验证：gofmt 检查 → vet → test → build 到 build/ 并运行
# Race 开关（16/17/18 并发章）用竞态检测器跑测试（需要 cgo + C 编译器）
function Test-PlainExample {
    param([string]$Dir, [switch]$Race)
    $name = Split-Path -Leaf $Dir
    Write-Host "`n[Example] $name" -ForegroundColor Cyan
    Test-Gofmt $Dir
    Invoke-Go $Dir @("vet", ".")
    if ($Race -and $raceOk) {
        Invoke-Go $Dir @("test", "-race", ".")
    } else {
        Invoke-Go $Dir @("test", ".")
    }
    $exe = Join-Path $buildDir "$name$exeSuffix"
    Invoke-Go $Dir @("build", "-o", $exe, ".")
    Invoke-Native $exe $Dir
}

# go.mod 工程（14_module/24_minigrep）：自有 go.mod，多包布局
# 四层：gofmt 检查 → vet ./... → test ./... → build 指定目标并运行
function Test-ProjectExample {
    param([string]$Dir, [string]$BuildTarget, [string[]]$RunArgs = @())
    $name = Split-Path -Leaf $Dir
    Write-Host "`n[Example] $name (go.mod 工程)" -ForegroundColor Cyan
    Test-Gofmt $Dir
    Invoke-Go $Dir @("vet", "./...")
    Invoke-Go $Dir @("test", "./...")
    $exe = Join-Path $buildDir "$name$exeSuffix"
    Invoke-Go $Dir (@("build", "-o", $exe) + $BuildTarget)
    Invoke-Native -ExePath $exe -WorkingDir $Dir -RunArgs $RunArgs
}

function Test-One {
    param([string]$Dir)
    switch (Split-Path -Leaf $Dir) {
        "14_module" { Test-ProjectExample $Dir "./cmd/app" }
        "24_minigrep" { Test-ProjectExample $Dir "." @("func", "main.go") }
        "16_goroutines" { Test-PlainExample $Dir -Race }
        "17_channels" { Test-PlainExample $Dir -Race }
        "18_sync" { Test-PlainExample $Dir -Race }
        default { Test-PlainExample $Dir }
    }
}

if ($Example) {
    $dir = Join-Path $examplesDir $Example
    if (-not (Test-Path -LiteralPath $dir)) { throw "找不到示例目录: $dir" }
    Test-One $dir
    Write-Host "`n[Done] $Example 验证通过。" -ForegroundColor Green
    exit 0
}

if ($All) {
    Get-ChildItem -LiteralPath $examplesDir -Directory | Sort-Object Name | ForEach-Object {
        Test-One $_.FullName
    }
    if (-not $raceOk) {
        Write-Host "`n[注意] cgo 不可用，16/17/18 未启用 -race（装上 C 编译器后自动启用）。" -ForegroundColor Yellow
    }
    Write-Host "`n[Done] 全部示例四层验证通过。" -ForegroundColor Green
    exit 0
}

Write-Host "用法:" -ForegroundColor Yellow
Write-Host "  .\build.ps1 -All                    验证 examples 下全部示例"
Write-Host "  .\build.ps1 -Example 12_collections  验证单个示例"
Write-Host "  .\build.ps1 -Clean                 清理 build 目录"
