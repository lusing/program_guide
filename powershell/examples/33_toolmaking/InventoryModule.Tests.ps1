# InventoryModule.Tests.ps1 —— 收官项目的模块测试（Pester v5/v6 语法）
BeforeAll {
    . (Join-Path $PSScriptRoot 'InventoryModule.psm1')
}

Describe 'Get-InvMachineInfo' {
    It '管道输入产出对象（含 Machine/Drive/FreeRatio/Low）' {
        $r = @('localhost') | Get-InvMachineInfo
        ($r | Measure-Object).Count | Should -BeGreaterThan 0
        $r[0].Machine | Should -Be 'localhost'
        $r[0].PSObject.Properties['FreeRatio'] | Should -Not -BeNullOrEmpty
        $r[0].PSObject.Properties['Low'] | Should -Not -BeNullOrEmpty
    }
    It '极端阈值 100 使全部标记 Low' {
        $r = 'localhost' | Get-InvMachineInfo -MinFreePct 100
        @($r | Where-Object Low).Count | Should -Be @($r).Count
    }
    It '阈值 1 下几乎不标记 Low' {
        $r = 'localhost' | Get-InvMachineInfo -MinFreePct 1
        @($r | Where-Object Low).Count | Should -Be 0
    }
}

Describe 'Export-InvReport' {
    It 'CSV 导出往返行数守恒' {
        $src = 'localhost' | Get-InvMachineInfo
        $csvPath = Join-Path $TESTDRIVE 'inv.csv'
        $src | Export-InvReport -Path $csvPath -Format Csv
        @(Import-Csv -Path $csvPath).Count | Should -Be @($src).Count
    }
    It 'Json 导出可读回' {
        $src = 'localhost' | Get-InvMachineInfo
        $jsonPath = Join-Path $TESTDRIVE 'inv.json'
        $src | Export-InvReport -Path $jsonPath -Format Json
        (Get-Content $jsonPath -Raw | ConvertFrom-Json).Count | Should -Be @($src).Count
    }
    It '-WhatIf 不落盘' {
        $src = 'localhost' | Get-InvMachineInfo
        $ghost = Join-Path $TESTDRIVE 'ghost.csv'
        $src | Export-InvReport -Path $ghost -WhatIf
        Test-Path $ghost | Should -BeFalse
    }
}
