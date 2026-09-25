# 第 13 章 · 文件与流 I/O

对应示例：`09-files.f90`

### 打开文件：用 newunit

```fortran
integer :: u
open (newunit=u, file='data.txt', status='replace', action='write')
write (u, '(a)') 'hello'
close (u)
```

`newunit=` 让库分配一个**负数**的 unit 号，保证不会和你手动写的 `10`、`20` 撞车。**不要再写 `open(10, ...)` 这种老风格**，尤其是过程里 —— 两次调用撞同一个 unit 是经典 bug。

`status=` 的取值：

| 值 | 含义 |
|---|---|
| `'old'` | 文件必须存在 |
| `'new'` | 文件必须不存在 |
| `'replace'` | 有就覆盖，没有就建 |
| `'scratch'` | 临时文件，`close` 时自动删 |
| `'unknown'` | 默认行为（有则用，无则建） |

`action=`：`'read'` / `'write'` / `'readwrite'`。写清楚能提前捕获「打开方式不对」的错误。

### 四访问模式

| 模式 | 关键字 | 用途 |
|---|---|---|
| 有格式顺序 | `form='formatted'`（默认） | 文本文件 |
| 无格式顺序 | `form='unformatted'` | 二进制，快但不可移植 |
| 流 | `access='stream'` | 二进制，按字节偏移读写 |
| 直接 | `access='direct', recl=N` | 定长记录，可随机访问 |

流访问：

```fortran
open (newunit=u, file='bin.dat', access='stream', form='unformatted', status='replace')
write (u) 42                                  ! 写 4 字节
write (u) [1.0_real64, 2.0_real64]            ! 写 16 字节
close (u)
```

直接访问（随机读写定长记录）：

```fortran
open (newunit=u, file='recs.dat', access='direct', recl=16, status='replace')
write (u, rec=1) 100
write (u, rec=3) 300                          ! 直接跳到第 3 条记录
read (u, rec=2) x                             ! 读第 2 条
close (u)
```

### 用 inquire 问文件的状态

```fortran
logical :: ex, op
integer :: sz
inquire (file='data.txt', exist=ex, opened=op, size=sz)
```

`size=` 只对**已连接**的文件有意义；对没打开的普通文件，`size` 在多数实现里返回 -1 或不修改。示例 09 里演示了这个行为。

### 读写循环的标准写法

```fortran
integer :: ios
character(len=256) :: line
open (newunit=u, file='data.txt', status='old', action='read')
do
  read (u, '(a)', iostat=ios) line
  if (ios /= 0) exit              ! ios < 0 表示文件结束，> 0 表示出错
  write (*, '(a)') trim(line)
end do
close (u)
```

**`iostat=` 是 Fortran 里唯一可靠的「读到了吗」判断方式。** 不要靠「读回来的内容是不是空的」来判断，那在遇到空行时会出错。

---

上一章：[第 12 章 格式化输入](12-formatted-input.md) ｜ 下一章：[第 14 章 过程：子程序、函数与参数传递](14-procedures.md) ｜ 返回：[README](../README.md)
