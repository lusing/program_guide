# 24_dll_plugin build: two plugin DLLs + host exe, then run host
$exampleDir = $PSScriptRoot
$projectRoot = Split-Path -Parent (Split-Path -Parent $exampleDir)
$buildDir = Join-Path $projectRoot "build"
$vcvars = "G:\Program Files\Microsoft Visual Studio\18\Community\VC\Auxiliary\Build\vcvars64.bat"
$name = "24_dll_plugin"
$common = "/nologo /std:c++20 /EHsc /utf-8 /DUNICODE /D_UNICODE /D_WIN32_WINNT=0x0A00"

New-Item -ItemType Directory -Force -Path $buildDir | Out-Null

function Invoke-Cl([string]$command) {
    $cmd = 'call "{0}" >nul && {1}' -f $vcvars, $command
    & $env:ComSpec /c $cmd
    if ($LASTEXITCODE -ne 0) { throw "build step failed: $command" }
}

Set-Location $exampleDir

# plugin DLLs (bare-minimum C interface)
Invoke-Cl ('cl {0} /c plugin_circle.cpp /Fo:"{1}\{2}_circle.obj"' -f $common, $buildDir, $name)
Invoke-Cl ('link /nologo /MACHINE:X64 /DLL /OUT:"{0}\plugin_circle.dll" "{0}\{1}_circle.obj" kernel32.lib' -f $buildDir, $name)
Invoke-Cl ('cl {0} /c plugin_square.cpp /Fo:"{1}\{2}_square.obj"' -f $common, $buildDir, $name)
Invoke-Cl ('link /nologo /MACHINE:X64 /DLL /OUT:"{0}\plugin_square.dll" "{0}\{1}_square.obj" kernel32.lib' -f $buildDir, $name)
# host
Invoke-Cl ('cl {0} /c main.cpp /Fo:"{1}\{2}_main.obj"' -f $common, $buildDir, $name)
Invoke-Cl ('link /nologo /MACHINE:X64 /SUBSYSTEM:CONSOLE /OUT:"{0}\{1}.exe" "{0}\{1}_main.obj" kernel32.lib user32.lib' -f $buildDir, $name)
# run: host finds plugin DLLs next to itself in build\
& (Join-Path $buildDir "$name.exe")
if ($LASTEXITCODE -ne 0) { throw "host run failed" }
