@echo off
call "G:\Program Files\Microsoft Visual Studio\18\Community\VC\Auxiliary\Build\vcvars64.bat"
cd /d g:\code\asm\intel\build

echo --- NASM ---
nasm -f win64 ..\examples\03_logic_bitwise\and_or_xor_not.asm -o and_or_xor_not.obj
echo nasm exit code: %errorlevel%

echo --- LINK ---
link /subsystem:console /entry:main and_or_xor_not.obj ucrt.lib kernel32.lib legacy_stdio_definitions.lib
echo link exit code: %errorlevel%

echo --- RUN ---
and_or_xor_not.exe
echo run exit code: %errorlevel%
