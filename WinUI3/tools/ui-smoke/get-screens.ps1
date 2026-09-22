Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.Screen]::AllScreens | ForEach-Object {
    '{0} {1}x{2} primary={3}' -f $_.DeviceName, $_.Bounds.Width, $_.Bounds.Height, $_.Primary
}
