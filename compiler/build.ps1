#!/usr/bin/env pwsh
# 静态分析教程统一构建入口；全部工具链在 scoop MSYS2 UCRT64 内
$ErrorActionPreference = 'Stop'
$root = 'G:\code\guide\compiler'
$filter = ($args | ForEach-Object { "'$_'" }) -join ' '
& G:\scoop\apps\msys2\current\usr\bash.exe -lc "cd '$root' && ./run-all.sh $filter"
