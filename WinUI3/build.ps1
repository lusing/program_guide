param(
    [switch]$Clean
)

$projectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$samplesRoot = Join-Path $projectRoot "cpp_examples"
$outRoot = Join-Path $projectRoot "build\cpp_obj"
$vcVars = "G:\Program Files\Microsoft Visual Studio\18\Community\VC\Auxiliary\Build\vcvars64.bat"

$sources = @(
    (Join-Path $samplesRoot "01_hello_event\hello_event.cpp"),
    (Join-Path $samplesRoot "02_mvvm_command\mvvm_command.cpp"),
    (Join-Path $samplesRoot "03_navigation_state\navigation_state.cpp"),
    (Join-Path $samplesRoot "04_async_dispatch\async_dispatch.cpp"),
    (Join-Path $samplesRoot "05_resource_dictionary\resource_dictionary.cpp"),
    (Join-Path $samplesRoot "06_collection_binding\collection_binding.cpp"),
    (Join-Path $samplesRoot "07_dependency_injection\dependency_injection.cpp"),
    (Join-Path $samplesRoot "08_lifecycle_events\lifecycle_events.cpp"),
    (Join-Path $samplesRoot "09_button_control\button_control.cpp"),
    (Join-Path $samplesRoot "10_textbox_control\textbox_control.cpp"),
    (Join-Path $samplesRoot "11_checkbox_radio_control\checkbox_radio_control.cpp"),
    (Join-Path $samplesRoot "12_combobox_listview_control\combobox_listview_control.cpp"),
    (Join-Path $samplesRoot "13_slider_toggle_control\slider_toggle_control.cpp"),
    (Join-Path $samplesRoot "14_dialog_navigation_control\dialog_navigation_control.cpp"),
    (Join-Path $samplesRoot "15_complete_task_app\task_app.cpp"),
    (Join-Path $samplesRoot "16_os_integration\os_integration.cpp")
)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host " WinUI3 C++ 示例编译验证" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

if (-not (Test-Path $vcVars)) {
    throw "未找到 vcvars64.bat: $vcVars"
}

if ($Clean) {
    if (Test-Path $outRoot) {
        Remove-Item -Recurse -Force $outRoot
        Write-Host "已清理: $outRoot" -ForegroundColor Yellow
    }
    return
}

New-Item -ItemType Directory -Path $outRoot -Force | Out-Null

foreach ($source in $sources) {
    if (-not (Test-Path $source)) {
        throw "未找到源码文件: $source"
    }

    $name = [System.IO.Path]::GetFileNameWithoutExtension($source)
    $obj = Join-Path $outRoot "$name.obj"

    Write-Host "`n[compile] $source" -ForegroundColor Yellow
    $cmd = "call `"$vcVars`" >nul 2>nul && cl /nologo /std:c++20 /EHsc /W4 /c `"$source`" /Fo`"$obj`""
    & $env:ComSpec /c $cmd
    if ($LASTEXITCODE -ne 0) {
        exit $LASTEXITCODE
    }
}

Write-Host "`n所有 WinUI3 C++ 示例已通过编译验证。" -ForegroundColor Green
