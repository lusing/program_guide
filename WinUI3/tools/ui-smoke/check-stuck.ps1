Get-Process BasicGallery, CollectionsGallery, ShellGallery, CustomGallery, TaskFlow, WindowShellApp, MSBuild, mspdbsrv, cl -ErrorAction SilentlyContinue |
    Select-Object Name, Id, StartTime | Format-Table -AutoSize | Out-String
