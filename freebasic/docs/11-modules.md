# 11 · 模块化与命名空间

> 对应示例：`examples/11_modules/`（多文件工程：`main.bas` + 两个模块）

## 11.1 .bi / .bas 分工：FB 的头文件惯例

FB 没有 C 那样的"源文件自动看见所有符号"——**跨模块调用必须先见到声明**。社区惯例（也是 `inc/` 里数百个官方 `.bi` 的做法）：

| 文件 | 内容 | 谁消费 |
|---|---|---|
| `mod_x.bi` | **接口**：`Declare`、`Type`、`#define`、`Namespace` 骨架 | 所有使用方 `#Include` |
| `mod_x.bas` | **实现**：函数体 | 编译时与其他 .bas 一起链接 |

```text
11_modules/
├── mod_counter.bi     接口：Namespace Counter + 四个 Declare
├── mod_counter.bas    实现：模块私有状态 value_ 藏在这里
├── mod_math.bi/bas    第二个模块：纯函数
└── main.bas           主模块：#Include 两个 .bi，用前缀调用
```

**首行自包含守卫**：每个 `.bi` 第一句 `#Include Once "自己.bi"`——别人 `#Include` 两遍也不会重复声明（比 C 的 `#ifndef` 宏守卫优雅）。

## 11.2 Namespace：前缀 + 封装边界

```freebasic
' mod_counter.bi
Namespace Counter
    Declare Function add(v As Integer) As Integer
End Namespace

' mod_counter.bas
Namespace Counter
    Dim As Integer value_ = 0     ' 模块私有状态：别的 .bas 拿不到
    Function add(v As Integer) As Integer
        value_ += v
        Return value_
    End Function
End Namespace
```

`Dim` 在 Namespace 里且不带 `Shared`/`Public` 时是**模块私有**——这正是"实现细节藏进 .bas"的机制。使用方：

```freebasic
#Include Once "mod_counter.bi"
Print Counter.add(5)          ' 5
Using Counter                 ' 就近引入，免前缀（别放在文件头全局 Using）
```

## 11.3 编译多文件工程

```bash
fbc -w all main.bas mod_counter.bas mod_math.bas -x app.exe
```

- **第一个 .bas 是主模块**（入口所在）——传文件顺序有语义！
- 单命令编译**不留中间 .o**（实测）。
- 想分步编译：`fbc -c` 只编译不链接，产出 `.o`，最后一起链。
- 大工程用 `-m main` 显式指定主模块，避免顺序坑。

## 11.4 Visibility 工具箱

| 手段 | 语义 |
|---|---|
| `Namespace X ... End Namespace` | 符号挂前缀 `X.name` |
| `Using X` | 引入前缀（作用域内生效） |
| Namespace 内 `Dim value_` | 模块私有数据 |
| `Dim Shared` | 模块级公共变量（全局可改，慎用） |
| `Public:`/`Private:`（Type 内，12 章） | 成员可见性 |

## 11.5 库形态

- `fbc -lib mod.bas` → 静态库 `.a`，使用方 `#inclib "mod"` 链接。
- `fbc -dll mod.bas` → Windows DLL（20 章配套讲导出与 Declare）。

## 11.6 坑位清单（1.10.1 实测）

1. **多文件命令行里第一个 .bas 是主模块**——顺序错了入口就没了（或用 `-m`）。
2. `.bi` 里只放声明；把函数体放 `.bi` 被多个 .bas 包含 = 重复定义链接错误。
3. `.bi` 首句 `#Include Once "自己.bi"` 做自包含守卫。
4. `Using` 放文件头部会全局污染前缀；放在需要的作用域里。
5. Namespace 内私有状态用 `Dim`（不带 Shared）；`Dim Shared` 是"全局变量"逃生门，能不用就不用。
