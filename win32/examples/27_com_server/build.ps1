# 27_com_server build: COM DLL (calcdll.dll) + consumer exe, run full chain
$exampleDir = $PSScriptRoot
$projectRoot = Split-Path -Parent (Split-Path -Parent $exampleDir)
$buildDir = Join-Path $projectRoot "build"
$vcvars = "G:\Program Files\Microsoft Visual Studio\18\Community\VC\Auxiliary\Build\vcvars64.bat"
$name = "27_com_server"
$common = "/nologo /std:c++20 /EHsc /utf-8 /DUNICODE /D_UNICODE /D_WIN32_WINNT=0x0A00"

New-Item -ItemType Directory -Force -Path $buildDir | Out-Null

function Invoke-Cl([string]$command) {
    $cmd = 'call "{0}" >nul && {1}' -f $vcvars, $command
    & $env:ComSpec /c $cmd
    if ($LASTEXITCODE -ne 0) { throw "build step failed: $command" }
}

Set-Location $exampleDir

# 1) COM server DLL (exports DllGetClassObject / DllRegisterServer / ...)
Invoke-Cl ('cl {0} /c server.cpp /Fo:"{1}\{2}_server.obj"' -f $common, $buildDir, $name)
Invoke-Cl ('link /nologo /MACHINE:X64 /DLL /OUT:"{0}\calcdll.dll" /EXPORT:DllGetClassObject /EXPORT:DllCanUnloadNow /EXPORT:DllRegisterServer /EXPORT:DllUnregisterServer "{0}\{1}_server.obj" kernel32.lib user32.lib ole32.lib advapi32.lib' -f $buildDir, $name)
# 2) consumer exe
Invoke-Cl ('cl {0} /c main.cpp /Fo:"{1}\{2}_main.obj"' -f $common, $buildDir, $name)
Invoke-Cl ('link /nologo /MACHINE:X64 /SUBSYSTEM:CONSOLE /OUT:"{0}\{1}.exe" "{0}\{1}_main.obj" ole32.lib advapi32.lib' -f $buildDir, $name)
# 3) run full chain: register -> create -> use -> unregister (HKCU only, no admin)
& (Join-Path $buildDir "$name.exe")
if ($LASTEXITCODE -ne 0) { throw "com chain failed" }
