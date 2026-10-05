# asset-lib.ps1 —— 函数库演示（被 run.ps1 点源加载）
function Get-LibGreeting {
    param([string]$Who = 'world')
    "hello $Who"
}
