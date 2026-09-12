@echo off
setlocal enabledelayedexpansion

echo ============================================================
echo  Verifying all example .asm files (nasm + link.exe)
echo ============================================================

call "G:\Program Files\Microsoft Visual Studio\18\Community\VC\Auxiliary\Build\vcvarsall.bat" x64 >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Failed to initialize MSVC environment
    exit /b 1
)

cd /d g:\code\asm\intel
if not exist build mkdir build

REM --- 生成 msvcrt.lib 导入库(用于 printf), 若不存在 ---
if not exist lib\msvcrt.lib (
    echo Generating msvcrt.lib import library for printf ...
    lib /DEF:lib\msvcrt.def /OUT:lib\msvcrt.lib /MACHINE:X64 >nul 2>&1
    if not exist lib\msvcrt.lib (
        echo [ERROR] Failed to generate msvcrt.lib
        exit /b 1
    )
    echo [OK] Generated lib\msvcrt.lib
)

REM 将 lib 目录加入库搜索路径
set LIB=g:\code\asm\intel\lib;%LIB%

set PASS=0
set FAIL=0

for %%f in (examples\01_data_movement\*.asm examples\02_arithmetic\*.asm) do (
    REM 跳过 test_link.asm (非本任务文件)
    echo %%~nf | findstr /b "test_" >nul && (
        echo Skipping %%~nxf
    ) || (
        echo.
        echo ---------- %%~nxf ----------
        nasm -f win64 "%%f" -o "build\%%~nf.obj" 2>&1
        if errorlevel 1 (
            echo [FAIL] asm error: %%f
            set /a FAIL+=1
        ) else (
            link /subsystem:console /entry:main "build\%%~nf.obj" msvcrt.lib kernel32.lib /out:"build\%%~nf.exe" /nologo 2>&1
            if errorlevel 1 (
                echo [FAIL] link error: %%f
                set /a FAIL+=1
            ) else (
                echo [OK] build success, running:
                "build\%%~nf.exe"
                if errorlevel 1 (
                    echo [FAIL] runtime error: %%f
                    set /a FAIL+=1
                ) else (
                    set /a PASS+=1
                )
            )
        )
    )
)

echo.
echo ============================================================
echo  RESULT: PASS=!PASS!, FAIL=!FAIL!
echo ============================================================
endlocal
