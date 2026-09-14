param(
    [switch]$All,
    [string]$File,
    [switch]$Compose,
    [switch]$Jni,
    [switch]$Clean
)

$projectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $projectRoot

$sdkRoot = "G:\android"
$kotlinHome = "G:\scoop\apps\kotlin\current"
$gradleHome = "G:\scoop\apps\gradle\current"
$javaHome = "G:\scoop\apps\openjdk\current"
$examplesDir = Join-Path $projectRoot "examples"
$composeProjectDir = Join-Path $projectRoot "compose_examples"
$jniDir = Join-Path $projectRoot "compose_examples\app\src\main\cpp"
$buildDir = Join-Path $projectRoot "build"
$classRoot = Join-Path $buildDir "classes"

if (-not (Test-Path -LiteralPath $sdkRoot)) {
    throw "未找到 Android SDK 目录: $sdkRoot"
}

if (-not (Test-Path -LiteralPath $kotlinHome)) {
    throw "未找到 Kotlin 目录: $kotlinHome"
}
if (-not (Test-Path -LiteralPath $gradleHome)) {
    throw "未找到 Gradle 目录: $gradleHome"
}
if (-not (Test-Path -LiteralPath $javaHome)) {
    throw "未找到 JDK 目录: $javaHome"
}

$kotlinc = Join-Path $kotlinHome "bin\kotlinc.bat"
$gradle = Join-Path $gradleHome "bin\gradle.bat"
$java = Join-Path $javaHome "bin\java.exe"
if (-not (Test-Path -LiteralPath $kotlinc)) {
    throw "未找到 Kotlin 编译器: $kotlinc"
}
if (-not (Test-Path -LiteralPath $gradle)) {
    throw "未找到 Gradle: $gradle"
}
if (-not (Test-Path -LiteralPath $java)) {
    throw "未找到 Java 可执行文件: $java"
}

$env:JAVA_HOME = $javaHome
$env:ANDROID_SDK_ROOT = $sdkRoot

$platformDirs = Get-ChildItem -LiteralPath (Join-Path $sdkRoot "platforms") -Directory -ErrorAction Stop
$candidates = @()
foreach ($dir in $platformDirs) {
    $jarPath = Join-Path $dir.FullName "android.jar"
    if (-not (Test-Path -LiteralPath $jarPath)) {
        continue
    }

    $api = -1
    if ($dir.Name -match '^android-(\d+)') {
        $api = [int]$Matches[1]
    }

    $candidates += [pscustomobject]@{
        Api = $api
        Jar = $jarPath
    }
}

if ($candidates.Count -eq 0) {
    throw "在 $sdkRoot\platforms 下未找到可用 android.jar。"
}

$androidJar = ($candidates | Sort-Object Api, Jar | Select-Object -Last 1).Jar

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

New-Item -ItemType Directory -Force -Path $classRoot | Out-Null

function Invoke-CompileExampleKotlin {
    param(
        [Parameter(Mandatory = $true)][string]$SourcePath
    )

    $name = [System.IO.Path]::GetFileNameWithoutExtension($SourcePath)
    $displayName = [System.IO.Path]::GetFileName($SourcePath)
    $outDir = Join-Path $classRoot $name
    New-Item -ItemType Directory -Force -Path $outDir | Out-Null

    Write-Host "[Compile] $displayName" -ForegroundColor Cyan
    & $kotlinc `
        "-jvm-target" "1.8" `
        "-classpath" $androidJar `
        "-d" $outDir `
        $SourcePath

    if ($LASTEXITCODE -ne 0) {
        throw "编译失败: $SourcePath"
    }
}

function Invoke-ComposeBuild {
    if (-not (Test-Path -LiteralPath $composeProjectDir)) {
        throw "找不到 Compose 工程目录: $composeProjectDir"
    }
    Write-Host "[Compose] Gradle 编译 Compose 示例" -ForegroundColor Magenta
    & $gradle "-p" $composeProjectDir "--no-daemon" "--warning-mode" "none" "clean" ":app:compileDebugKotlin"
    if ($LASTEXITCODE -ne 0) {
        throw "Compose 示例编译失败。"
    }
}

function Invoke-JniBuild {
    if (-not (Test-Path -LiteralPath $jniDir)) {
        throw "找不到 JNI 目录: $jniDir"
    }

    $ndkRoot = Join-Path $sdkRoot "ndk\30.0.15729638"
    if (-not (Test-Path -LiteralPath $ndkRoot)) {
        throw "未找到指定 NDK: $ndkRoot"
    }

    $cmakeRoot = Join-Path $sdkRoot "cmake"
    if (-not (Test-Path -LiteralPath $cmakeRoot)) {
        throw "未找到 CMake 目录: $cmakeRoot"
    }
    $cmake = Get-ChildItem -LiteralPath $cmakeRoot -Directory |
        Sort-Object Name |
        Select-Object -Last 1 |
        ForEach-Object { Join-Path $_.FullName "bin\cmake.exe" }
    if (-not $cmake -or -not (Test-Path -LiteralPath $cmake)) {
        throw "未找到可用 CMake 可执行文件。"
    }

    $generator = "Ninja"
    $toolchain = Join-Path $ndkRoot "build\cmake\android.toolchain.cmake"
    $jniBuild = Join-Path $buildDir "jni"
    New-Item -ItemType Directory -Force -Path $jniBuild | Out-Null

    Write-Host "[JNI] Configure" -ForegroundColor DarkYellow
    & $cmake `
        "-G" $generator `
        "-S" $jniDir `
        "-B" $jniBuild `
        "-DANDROID_ABI=arm64-v8a" `
        "-DANDROID_PLATFORM=android-24" `
        "-DCMAKE_TOOLCHAIN_FILE=$toolchain" `
        "-DANDROID_NDK=$ndkRoot"
    if ($LASTEXITCODE -ne 0) {
        throw "JNI CMake 配置失败。"
    }

    Write-Host "[JNI] Build" -ForegroundColor DarkYellow
    & $cmake "--build" $jniBuild
    if ($LASTEXITCODE -ne 0) {
        throw "JNI native 编译失败。"
    }
}

if ($All) {
    $files = Get-ChildItem -LiteralPath $examplesDir -Filter "*.kt" | Sort-Object Name
    if ($files.Count -eq 0) {
        throw "examples 目录下没有 .kt 示例文件。"
    }
    foreach ($f in $files) {
        Invoke-CompileExampleKotlin -SourcePath $f.FullName
    }
    Invoke-ComposeBuild
    Invoke-JniBuild

    Write-Host "[Done] examples 目录全部编译验证通过。" -ForegroundColor Green
    Write-Host "[Info] android.jar: $androidJar" -ForegroundColor DarkGreen
    exit 0
}

if ($File) {
    $sourcePath = Join-Path $examplesDir $File
    if (-not (Test-Path -LiteralPath $sourcePath)) {
        throw "找不到示例文件: $sourcePath"
    }

    Invoke-CompileExampleKotlin -SourcePath $sourcePath
    Write-Host "[Done] 编译验证通过: $File" -ForegroundColor Green
    Write-Host "[Info] android.jar: $androidJar" -ForegroundColor DarkGreen
    exit 0
}

if ($Compose) {
    Invoke-ComposeBuild
    Write-Host "[Done] Compose 示例编译验证通过。" -ForegroundColor Green
    exit 0
}

if ($Jni) {
    Invoke-JniBuild
    Write-Host "[Done] JNI 示例编译验证通过。" -ForegroundColor Green
    exit 0
}

Write-Host "用法:" -ForegroundColor Yellow
Write-Host "  .\build.ps1 -All           编译验证 Kotlin + Compose + JNI 全部示例"
Write-Host "  .\build.ps1 -File <name>   编译验证单个 Kotlin 示例（如 01_hello_activity.kt）"
Write-Host "  .\build.ps1 -Compose       仅编译验证 Compose 示例工程"
Write-Host "  .\build.ps1 -Jni           仅编译验证 JNI 示例"
Write-Host "  .\build.ps1 -Clean         清理 build 目录"
