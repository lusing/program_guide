// 23_dll_math — 隐式链接消费者：像调普通函数一样调 DLL 导出
//
// 对应教程：docs/19-DLL基础.md
// 本示例由 23_dll_math/build.ps1 构建（DLL + 导入库 + 本 exe 四步）
#include "mathlib.h"
#include <stdio.h>
#include <locale.h>

int wmain() {
    _wsetlocale(LC_ALL, L"");
    wprintf(L"Math_Add(20, 22) = %d\n", Math_Add(20, 22));
    wprintf(L"Math_Mul(6, 7)   = %d\n", Math_Mul(6, 7));
    wprintf(L"Math_Version()   = %s\n", Math_Version());
    wprintf(L"（没有 LoadLibrary——加载发生在进程启动，这就是隐式链接）\n");
    return 0;
}
