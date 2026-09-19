# 29_winrt_modern build: only extras = cppwinrt headers + WindowsApp.lib
$exampleDir = $PSScriptRoot
$projectRoot = Split-Path -Parent (Split-Path -Parent $exampleDir)
$buildDir = Join-Path $projectRoot "build"
$vcvars = "G:\Program Files\Microsoft Visual Studio\18\Community\VC\Auxiliary\Build\vcvars64.bat"
$sdkRoot = "C:\Program Files (x86)\Windows Kits\10\Include"
$name = "29_winrt_modern"
$common = "/nologo /std:c++20 /EHsc /utf-8 /DUNICODE /D_UNICODE /D_WIN32_WINNT=0x0A00"

# find newest SDK that actually has cppwinrt headers
$cppwinrt = $null
Get-ChildItem -Path $sdkRoot -Directory | Sort-Object Name -Descending | ForEach-Object {
    if (-not $cppwinrt) {
        $candidate = Join-Path $_.FullName "cppwinrt"
        if (Test-Path (Join-Path $candidate "winrt")) { $cppwinrt = $candidate }
    }
}
if (-not $cppwinrt) { throw "cppwinrt headers not found under $sdkRoot" }
Write-Host "[Info] cppwinrt: $cppwinrt"

New-Item -ItemType Directory -Force -Path $buildDir | Out-Null

function Invoke-Cl([string]$command) {
    $cmd = 'call "{0}" >nul && {1}' -f $vcvars, $command
    & $env:ComSpec /c $cmd
    if ($LASTEXITCODE -ne 0) { throw "build step failed: $command" }
}

Set-Location $exampleDir

Invoke-Cl ('cl {0} /I "{1}" /c main.cpp /Fo:"{2}\{3}_main.obj"' -f $common, $cppwinrt, $buildDir, $name)
Invoke-Cl ('link /nologo /MACHINE:X64 /SUBSYSTEM:CONSOLE /OUT:"{0}\{1}.exe" "{0}\{1}_main.obj" WindowsApp.lib' -f $buildDir, $name)
& (Join-Path $buildDir "$name.exe")
if ($LASTEXITCODE -ne 0) { throw "run failed" }
