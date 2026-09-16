# Build the winmd-probe tool and smoke-test it against the local NuGet cache.
#
#   .\build.ps1              build + smoke test
#   .\build.ps1 -Configuration Debug
param(
    [string]$Configuration = "Release"
)

$ErrorActionPreference = "Stop"
$here = Split-Path -Parent $MyInvocation.MyCommand.Path

$dotnet = (Get-Command dotnet.exe -ErrorAction SilentlyContinue).Source
if (-not $dotnet) {
    foreach ($candidate in @(
        "D:\scoop\apps\dotnet-sdk\current\dotnet.exe",
        "C:\Program Files\dotnet\dotnet.exe")) {
        if (Test-Path $candidate) { $dotnet = $candidate; break }
    }
}
if (-not $dotnet) { throw "dotnet.exe not found - install the .NET SDK" }

Write-Host "using dotnet: $dotnet"
& $dotnet build (Join-Path $here "winmd-probe.csproj") -c $Configuration --nologo
if ($LASTEXITCODE -ne 0) { throw "build failed ($LASTEXITCODE)" }

$dll = Join-Path $here "bin\$Configuration\net8.0\winmd-probe.dll"
Write-Host "`n--- smoke test: find INotifyPropertyChanged across the NuGet cache"
& $dotnet $dll --find "Xaml.Data.INotifyPropertyChanged"
Write-Host "`n--- smoke test: dump the WASDK FileOpenPicker surface"
$picker = Get-ChildItem "$HOME\.nuget\packages\microsoft.windowsappsdk.foundation" -Recurse -Filter "Microsoft.Windows.Storage.Pickers.winmd" -ErrorAction SilentlyContinue |
    Select-Object -First 1
if ($picker) {
    & $dotnet $dll $picker.FullName "Microsoft.Windows.Storage.Pickers.FileOpenPicker"
} else {
    Write-Warning "Windows App SDK not in the NuGet cache - run a WinUI 3 build once to populate it"
}
Write-Host "`nOK: $dll"
