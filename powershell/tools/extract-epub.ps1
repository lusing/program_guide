# extract-epub.ps1 — 把参考书 epub 提取为 materials/book/chNN.txt
# 映射规则：EPUB/N.xhtml = 第 N+1 章（N 从 0 起），ch01..ch28 对应原书 28 章。
# 仅需 pwsh 运行（一次性取材，可复现）。
[CmdletBinding()]
param([string]$Epub = 'G:\book\计算机\powershell\Windows PowerShell实战指南（第3版）.epub')

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.IO.Compression.FileSystem
$outDir = Join-Path $PSScriptRoot '..\materials\book'
New-Item -ItemType Directory -Force -Path $outDir | Out-Null

$zip = [System.IO.Compression.ZipFile]::OpenRead($Epub)
try {
    foreach ($entry in $zip.Entries) {
        if ($entry.FullName -notmatch '^EPUB/(\d+)\.xhtml$') { continue }
        $n = [int]$Matches[1] + 1                      # N.xhtml = 第 N+1 章
        $reader = New-Object System.IO.StreamReader($entry.Open(), [System.Text.Encoding]::UTF8)
        $t = $reader.ReadToEnd()
        $reader.Close()
        $t = $t -replace '<(pre|div|h[1-6]|p|li|tr)[^>]*>', "`n" -replace '<[^>]+>', ''
        $t = [System.Net.WebUtility]::HtmlDecode($t) -replace "`r", '' -replace "`n{3,}", "`n`n"
        $outFile = Join-Path $outDir ('ch{0:d2}.txt' -f $n)
        [System.IO.File]::WriteAllText($outFile, $t)
        Write-Host ("{0}  {1} 字符" -f (Split-Path $outFile -Leaf), $t.Length)
    }
}
finally { $zip.Dispose() }
