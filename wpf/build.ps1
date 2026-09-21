param(
    [switch]$Clean
)

$projectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$dotnet = "G:\scoop\apps\dotnet-sdk\current\dotnet.exe"
$projects = @(
    (Join-Path $projectRoot "examples\03_hello_wpf\HelloWpfApp.csproj"),
    (Join-Path $projectRoot "examples\05_layout\LayoutDemo.csproj"),
    (Join-Path $projectRoot "examples\06_layout_lab\LayoutLab.csproj"),
    (Join-Path $projectRoot "examples\07_controls_gallery\ControlsGallery.csproj"),
    (Join-Path $projectRoot "examples\08_routed_events\RoutedEvents.csproj"),
    (Join-Path $projectRoot "examples\09_binding\BindingDemo.csproj"),
    (Join-Path $projectRoot "examples\10_binding_advanced\BindingAdvanced.csproj"),
    (Join-Path $projectRoot "examples\11_mvvm\MvvmDemo.csproj"),
    (Join-Path $projectRoot "examples\12_commands\CommandDemo.csproj"),
    (Join-Path $projectRoot "examples\13_styles\StyleDemo.csproj"),
    (Join-Path $projectRoot "examples\14_triggers\TriggersDemo.csproj"),
    (Join-Path $projectRoot "examples\15_templates\TemplatesDemo.csproj"),
    (Join-Path $projectRoot "examples\16_validation\ValidationDemo.csproj"),
    (Join-Path $projectRoot "examples\17_datagrid\DataGridDemo.csproj"),
    (Join-Path $projectRoot "examples\18_treeview\TreeViewDemo.csproj"),
    (Join-Path $projectRoot "examples\19_drawing\DrawingDemo.csproj"),
    (Join-Path $projectRoot "examples\20_animation\AnimationDemo.csproj"),
    (Join-Path $projectRoot "examples\21_async_progress\AsyncProgressDemo.csproj"),
    (Join-Path $projectRoot "examples\22_file_dialogs\FileDialogDemo.csproj"),
    (Join-Path $projectRoot "examples\23_navigation\NavigationDemo.csproj"),
    (Join-Path $projectRoot "examples\25_notepad_plus\NotepadPlus.csproj")
)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host " WPF 编程指南示例构建（21 个项目）" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

if ($Clean) {
    foreach ($project in $projects) {
        if (Test-Path $project) {
            & $dotnet clean $project --nologo -v minimal
        }
    }
    return
}

foreach ($project in $projects) {
    if (-not (Test-Path $project)) {
        Write-Warning "未找到项目: $project"
        continue
    }

    Write-Host "`n[build] $project" -ForegroundColor Yellow
    & $dotnet build $project --nologo -v minimal
    if ($LASTEXITCODE -ne 0) {
        exit $LASTEXITCODE
    }
}

Write-Host "`n所有 WPF 示例已成功编译。" -ForegroundColor Green
