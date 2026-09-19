# 23_dll_math build: DLL (+ import lib) then consumer exe (implicit link), then run
# Invoked by root build.ps1 (delegation) or run directly from this directory.
$exampleDir = $PSScriptRoot
$projectRoot = Split-Path -Parent (Split-Path -Parent $exampleDir)
$buildDir = Join-Path $projectRoot "build"
$vcvars = "G:\Program Files\Microsoft Visual Studio\18\Community\VC\Auxiliary\Build\vcvars64.bat"
$name = "23_dll_math"
$common = "/nologo /std:c++20 /EHsc /utf-8 /DUNICODE /D_UNICODE /D_WIN32_WINNT=0x0A00"

New-Item -ItemType Directory -Force -Path $buildDir | Out-Null

function Invoke-Cl([string]$command) {
    $cmd = 'call "{0}" >nul && {1}' -f $vcvars, $command
    & $env:ComSpec /c $cmd
    if ($LASTEXITCODE -ne 0) { throw "build step failed: $command" }
}

Set-Location $exampleDir

# 1) DLL object (MATHLIB_EXPORTS selects dllexport)
Invoke-Cl ('cl {0} /DMATHLIB_EXPORTS /c mathlib.cpp /Fo:"{1}\{2}_mathlib.obj"' -f $common, $buildDir, $name)
# 2) DLL + import library
Invoke-Cl ('link /nologo /MACHINE:X64 /DLL /OUT:"{0}\mathlib.dll" /IMPLIB:"{0}\mathlib.lib" "{0}\{1}_mathlib.obj" kernel32.lib user32.lib' -f $buildDir, $name)
# 3) consumer object
Invoke-Cl ('cl {0} /c main.cpp /Fo:"{1}\{2}_main.obj"' -f $common, $buildDir, $name)
# 4) consumer exe: mathlib.lib on the link line IS implicit linking
Invoke-Cl ('link /nologo /MACHINE:X64 /SUBSYSTEM:CONSOLE /OUT:"{0}\{1}.exe" "{0}\{1}_main.obj" "{0}\mathlib.lib" kernel32.lib' -f $buildDir, $name)
# 5) run: exe finds mathlib.dll in its own directory (DLL search order)
& (Join-Path $buildDir "$name.exe")
if ($LASTEXITCODE -ne 0) { throw "consumer run failed" }
