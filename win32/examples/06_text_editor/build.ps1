$ErrorActionPreference = 'Stop'

$vcRoot = 'G:\Program Files\Microsoft Visual Studio\18\Community\VC'
$windowsSdkRoot = 'C:\Program Files (x86)\Windows Kits\10'

$msvcVersion = (Get-ChildItem -Path (Join-Path $vcRoot 'Tools\MSVC') -Directory | Sort-Object Name -Descending | Select-Object -First 1).FullName
$clPath = Join-Path $msvcVersion 'bin\Hostx64\x64\cl.exe'
$libDir = Join-Path $msvcVersion 'lib\x64'
$includeDir = Join-Path $msvcVersion 'include'

$windowsSdkVersion = (Get-ChildItem -Path (Join-Path $windowsSdkRoot 'Lib') -Directory | Sort-Object Name -Descending | Select-Object -First 1).Name
$windowsIncludeDir = Join-Path $windowsSdkRoot "Include\$windowsSdkVersion\um"
$windowsSharedDir = Join-Path $windowsSdkRoot "Include\$windowsSdkVersion\shared"
$ucrtIncludeDir = Join-Path $windowsSdkRoot "Include\$windowsSdkVersion\ucrt"
$windowsLibDir = Join-Path $windowsSdkRoot "Lib\$windowsSdkVersion\um\x64"
$ucrtLibDir = Join-Path $windowsSdkRoot "Lib\$windowsSdkVersion\ucrt\x64"

$buildDir = Join-Path $PSScriptRoot 'build'
New-Item -ItemType Directory -Force -Path $buildDir | Out-Null

& $clPath /nologo /EHsc /DUNICODE /D_UNICODE /I"$includeDir" /I"$windowsIncludeDir" /I"$windowsSharedDir" /I"$ucrtIncludeDir" /Fo"$buildDir\" /Fe"$buildDir\06_text_editor.exe" "$PSScriptRoot\main.cpp" /link /MACHINE:X64 /SUBSYSTEM:WINDOWS /LIBPATH:"$libDir" /LIBPATH:"$windowsLibDir" /LIBPATH:"$ucrtLibDir" user32.lib gdi32.lib shell32.lib kernel32.lib comctl32.lib

if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
Write-Host 'Build succeeded: ' "$buildDir\06_text_editor.exe"
