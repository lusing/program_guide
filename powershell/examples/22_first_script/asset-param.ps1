# asset-param.ps1 —— 被 run.ps1 调用的参数演示脚本
param(
    [string]$Name = 'default',
    [int]$Count = 1
)
"$Name-$Count"
