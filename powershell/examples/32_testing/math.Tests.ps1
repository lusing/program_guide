# math.Tests.ps1 —— Pester 现代语法测试（v5/v6）
BeforeAll {
    . (Join-Path $PSScriptRoot 'math.ps1')
}

Describe 'Get-TutDouble' {
    It '正常翻倍' {
        Get-TutDouble -Value 21 | Should -Be 42
    }
    It '零值边界' {
        Get-TutDouble -Value 0 | Should -Be 0
    }
    It '类型合同' {
        Get-TutDouble -Value 5 | Should -BeOfType [int]
    }
    It '缺参应抛错（Mandatory）' {
        { Get-TutDouble } | Should -Throw
    }
    It '非数字应抛错（类型转换失败）' {
        { Get-TutDouble -Value 'zzz' } | Should -Throw
    }
}
