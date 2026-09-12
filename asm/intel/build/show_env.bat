@echo off
call "G:\Program Files\Microsoft Visual Studio\18\Community\VC\Auxiliary\Build\vcvars64.bat" >nul 2>&1
echo LIB=%LIB%
echo.
echo === Search for msvcrt.lib ===
for %%P in ("%LIB:;=";%") do (
  if exist "%%~P\msvcrt.lib" echo Found: %%~P\msvcrt.lib
)
echo.
echo === Search for ucrt.lib ===
for %%P in ("%LIB:;=";%") do (
  if exist "%%~P\ucrt.lib" echo Found: %%~P\ucrt.lib
)
echo.
echo === Search for kernel32.lib ===
for %%P in ("%LIB:;=";%") do (
  if exist "%%~P\kernel32.lib" echo Found: %%~P\kernel32.lib
)
