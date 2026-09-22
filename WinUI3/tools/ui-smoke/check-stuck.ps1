Get-Process BasicGallery, MSBuild -ErrorAction SilentlyContinue |
    Select-Object Name, Id, StartTime | Format-Table -AutoSize | Out-String
if (Test-Path 'G:\code\guide\WinUI3\.smoke\07-controls-basic\autosuggest') {
    Get-ChildItem 'G:\code\guide\WinUI3\.smoke\07-controls-basic\autosuggest' |
        Select-Object Name, Length, LastWriteTime | Format-Table -AutoSize | Out-String
}
