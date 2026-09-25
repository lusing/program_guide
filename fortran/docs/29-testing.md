# 第 29 章 · 错误处理与单元测试

对应示例：`21-errors-testing.f90`

### Fortran 没有异常

这是从 Python/Java 过来最不习惯的地方：**Fortran 标准没有 `try/catch`**。错误处理靠三个机制：

1. **`iostat=` / `stat=` / `iomsg=`** —— 所有 I/O 和分配操作都能拿到状态码
2. **`err=` 标签** —— 跳到错误处理位置
3. **`error stop`** —— 不可恢复时终止，带退出码

### iostat 的正确用法

```fortran
integer :: ios, u
character(len=256) :: iomsg
open (newunit=u, file='nope.txt', status='old', action='read', iostat=ios, iomsg=iomsg)
if (ios /= 0) then
  write (*, '(a,i0)') '打开失败，iostat = ', ios
  write (*, '(a,a)')  '错误信息：', trim(iomsg)
end if
```

**`iomsg` 是编译器给的文字描述**，可能不适用于错误码不匹配的情况；而且不同编译器的文字不同。**不要用它做逻辑判断**，只用来打印给人看。

### stat 与 errmsg

```fortran
allocate (big(1000000000), stat=ios, errmsg=msg)
if (ios /= 0) write (*, '(a,a)') '分配失败：', trim(msg)
```

**`stat` 的具体数值是编译器相关的**：

| 场景 | flang 23 | gfortran 15 |
|---|---|---|
| 重复 allocate | 放行（不报错） | 报错，`stat` ≈ 5014 |
| 其他场景 | 12 | 各不相同 |

所以**只能判 `/= 0`**，绝不能写 `if (ios == 5014)`。示例 21 里把这个差异演示出来了，它也是「已知差异」清单的一员。

### err= 标签（老风格，但有时更简洁）

```fortran
read (u, *, err=100, end=200) x
! 正常路径
goto 300
100 continue
write (*, '(a)') '读取出错'
goto 300
200 continue
write (*, '(a)') '文件结束'
300 continue
```

能用 `iostat` 的地方就**别用 `err=`** —— 标签会把控制流打散。只在非常简单的读循环里偶尔用一下。

### inquire：先问再开

```fortran
logical :: ex
inquire (file='data.txt', exist=ex)
if (.not. ex) then
  write (*, '(a)') '文件不存在'
  stop 1
end if
```

注意 `inquire(size=)` 需要**标量整数**变量，传数组进去编译报错。

### error stop 与退出码

```fortran
if (bad) error stop 3      ! 退出码 3
if (bad) stop 3            ! 也可以，但不会触发清理
```

`error stop` 和 `stop` 的区别：`error stop` 会**刷新所有已连接的单元的缓冲**再退出，`stop` 不保证。写数据的程序一定要用 `error stop`。

**验证退出码需要子进程**。示例 21 的做法：父程序用 `execute_command_line` 启动一个会 `error stop 3` 的子程序，子程序把消息写进临时文件，父程序读出来再删掉。

为什么要绕这一圈？因为如果让子进程直接写 stdout，输出会和父进程的缓冲区交错，**两个编译器给出的交错顺序不一样**，逐字节比对就失败了。写文件 + 父进程读取 + 删除，输出就完全确定了。

（`execute_command_line` 是标准里唯一能起子进程的方式，但它需要一个 shell，可移植性一般。）

### 手写一个断言框架

Fortran 标准库没有测试框架（虽然社区有 `test-drive` 等）。示例 21 里手写了一个够用的：

```fortran
module unittest
  use, intrinsic :: iso_fortran_env, only: real64
  implicit none
  private
  public :: assert_true, assert_false, assert_eq_i, assert_eq_r, assert_close, &
            assert_eq_s, test_summary

  integer :: n_pass = 0, n_fail = 0

contains
  subroutine assert_true(cond, name)
    logical, intent(in) :: cond
    character(len=*), intent(in) :: name
    if (cond) then
      n_pass = n_pass + 1
      write (*, '(a,a)') '  [PASS] ', name
    else
      n_fail = n_fail + 1
      write (*, '(a,a)') '  [FAIL] ', name
    end if
  end subroutine

  subroutine assert_close(got, want, tol, name)
    real(real64), intent(in) :: got, want, tol
    character(len=*), intent(in) :: name
    call assert_true(abs(got - want) <= tol, name)
  end subroutine

  subroutine test_summary()
    write (*, '(a,i0,a,i0)') '通过 ', n_pass, '   失败 ', n_fail
    if (n_fail > 0) error stop 1        ! 让 CI 能感知失败
  end subroutine
end module
```

要点：

- **浮点比较一定要有 `assert_close`**，不能只给 `assert_eq_r`（第 5 章）
- **失败时 `error stop 1`**，这样接入 CI 时退出码能反映结果
- 计数器放在模块里，所以测试代码不需要把状态传来传去

### 被测模块与测试的分离

```fortran
module ratlib
  implicit none
  private
  public :: gcd, simplify
contains
  pure function gcd(a, b) result(g)
    integer, intent(in) :: a, b
    integer :: g, x, y, t
    x = abs(a); y = abs(b)
    do while (y /= 0)
      t = mod(x, y); x = y; y = t
    end do
    g = x
  end function
end module
```

测试程序 `use ratlib` 然后一组断言。**测试放在同一个文件里**（本仓库的示例是单文件自包含的），实际项目里应当分开成 `src/` 和 `test/`。

### 值得遵守的几条

1. **所有 I/O 都带 `iostat=`**，除非是控制台输出。
2. **过程里加 `ok`/`status` 输出参数**，不要靠副作用或全局变量报错。
3. **`error stop` 带非零退出码**，让 shell 能感知。
4. **数值代码必须有「已知答案」的测试**（第 22 章的 LU 事故就是这么发现不了的）。
5. **`-pedantic` 下编译警告为零**，是能持续保持的最实际的纪律。

---

上一章：[第 28 章 调试与查错方法](28-debugging.md) ｜ 下一章：[第 30 章 读程序自测：谜题集](30-quiz.md) ｜ 返回：[README](../README.md)
