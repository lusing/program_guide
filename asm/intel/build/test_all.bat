@echo off
call "G:\Program Files\Microsoft Visual Studio\18\Community\VC\Auxiliary\Build\vcvars64.bat"
cd /d g:\code\asm\intel\build

echo ===== and_or_xor_not =====
nasm -f win64 ..\examples\03_logic_bitwise\and_or_xor_not.asm -o and_or_xor_not.obj
link /subsystem:console /entry:main and_or_xor_not.obj ucrt.lib kernel32.lib legacy_stdio_definitions.lib
and_or_xor_not.exe

echo.
echo ===== shifts =====
nasm -f win64 ..\examples\03_logic_bitwise\shifts.asm -o shifts.obj
link /subsystem:console /entry:main shifts.obj ucrt.lib kernel32.lib legacy_stdio_definitions.lib
shifts.exe

echo.
echo ===== bit_test =====
nasm -f win64 ..\examples\03_logic_bitwise\bit_test.asm -o bit_test.obj
link /subsystem:console /entry:main bit_test.obj ucrt.lib kernel32.lib legacy_stdio_definitions.lib
bit_test.exe

echo.
echo ===== bit_scan =====
nasm -f win64 ..\examples\03_logic_bitwise\bit_scan.asm -o bit_scan.obj
link /subsystem:console /entry:main bit_scan.obj ucrt.lib kernel32.lib legacy_stdio_definitions.lib
bit_scan.exe

echo.
echo ===== cmp =====
nasm -f win64 ..\examples\04_comparison\cmp.asm -o cmp.obj
link /subsystem:console /entry:main cmp.obj ucrt.lib kernel32.lib legacy_stdio_definitions.lib
cmp.exe

echo.
echo ===== test =====
nasm -f win64 ..\examples\04_comparison\test.asm -o test.obj
link /subsystem:console /entry:main test.obj ucrt.lib kernel32.lib legacy_stdio_definitions.lib
test.exe
