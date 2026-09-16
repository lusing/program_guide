param(
    [switch]$Clean
)

$projectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$dotnet = "G:\scoop\apps\dotnet-sdk\current\dotnet.exe"
$projects = @(
    (Join-Path $projectRoot "examples\01_hello_wpf\HelloWpfApp.csproj"),
    (Join-Path $projectRoot "examples\02_binding\BindingDemo.csproj"),
    (Join-Path $projectRoot "examples\03_mvvm\MvvmDemo.csproj"),
    (Join-Path $projectRoot "examples\04_layout\LayoutDemo.csproj"),
    (Join-Path $projectRoot "examples\05_styles\StyleDemo.csproj"),
    (Join-Path $projectRoot "examples\06_commands\CommandDemo.csproj"),
    (Join-Path $projectRoot "examples\07_async_progress\AsyncProgressDemo.csproj"),
    (Join-Path $projectRoot "examples\08_file_dialogs\FileDialogDemo.csproj"),
    (Join-Path $projectRoot "examples\09_navigation\NavigationDemo.csproj"),
    (Join-Path $projectRoot "examples\10_notepad_plus\NotepadPlus.csproj")
)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host " WPF 编程指南示例构建" -ForegroundColor Cyan
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
