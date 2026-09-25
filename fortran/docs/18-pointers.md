# 第 18 章 · 指针与可分配变量

对应示例：`14-pointers.f90`

Fortran 的指针和 C 的指针**不是一回事**，先把这个搞清楚：

| | 可分配变量 `allocatable` | 指针 `pointer` |
|---|---|---|
| 语义 | 值语义 | 引用/别名语义 |
| `b = a` | **深拷贝**，b 是独立副本 | 让 b 也指向 a 的目标（浅） |
| 能指向已有变量 | 不能 | 能（配 `target`） |
| 改 b 影响 a | 不会 | 会 |
| 内存泄漏 | `deallocate` 即可 | 容易漏，需要主动 `nullify` |
| 推荐度 | **默认用它** | 只在需要时才用 |

### 值语义 vs 别名

```fortran
real(real64), allocatable :: a(:), b(:)
allocate (a(3))
a = [1.0_real64, 2.0_real64, 3.0_real64]
b = a                    ! 深拷贝
b(1) = 99.0_real64       ! a 不受影响

real(real64), pointer :: p(:), q(:)
real(real64), target :: t(3) = [1.0_real64, 2.0_real64, 3.0_real64]
p => t                   ! p 指向 t
q => p                   ! q 也指向 t
q(1) = 99.0_real64       ! t 被改了
```

**默认选 `allocatable`。** 只有下面这些场合才需要 `pointer`：

- 指向**已有变量**（比如函数想返回数组的某一段）
- 再造数据结构（链表、树）—— 因为需要引用语义
- 想在两个名字之间共享同一块内存

### target 与 associated

```fortran
real(real64), target :: x = 1.0_real64
real(real64), pointer :: px
px => x
if (associated(px)) write (*, '(a)') 'px 有目标'
if (associated(px, x)) write (*, '(a)') 'px 指向 x'
nullify(px)                                  ! 断开
```

**只有被声明为 `target` 的变量才能被指针指向。** 这是编译器能优化矩阵运算的关键 —— 没有 `target` 声明的变量，编译器可以放心假设「没有别人在背后改它」。

### 指针切片

```fortran
real(real64), pointer :: mid(:)
real(real64), target :: arr(10)
mid => arr(4:7)              ! 指向中间一段，改 mid 就是改 arr
```

Pointer slicing 是 `pointer` 相对 `allocatable` 的一个真实优势。`allocatable` 做不到这个（虽然有 `pointer` 分量可以绕）。

### 用指针造链表

```fortran
type :: node
  integer :: val = 0
  type(node), pointer :: next => null()
end type

type(node), pointer :: head => null()
```

注意 `=> null()` 的默认初始化 —— **不写它，未赋值分量的指针状态是未定义的**，`associated` 会返回垃圾值。

链表在 Fortran 里能用，但性能一般（每个节点都是一次分散的 `allocate`）。数值场景下，用「数组 + 整数索引当链」的方式通常快得多：

```fortran
integer :: next(:)      ! next(i) 是节点 i 的后继下标，0 表示结束
```

### move_alloc 与指针的对比

```fortran
! allocatable 版：O(1)，且自动管理生命周期
call move_alloc(tmp, big)

! pointer 版：也能 O(1)，但你得自己管释放
big_p => tmp
nullify(tmp)
```

能用 `move_alloc` 就别用指针 —— 前者会在必要时自动 `deallocate`，不会泄漏。

### 一个真实教训

示例 14 里演示了同一段逻辑用 `allocatable` 和用 `pointer` 写出来的差别。指针版的代码更长、更容易漏内存，而功能完全一样。**在 Fortran 里，指针是最后手段，不是默认选择。**

---

上一章：[第 17 章 面向对象与多态](17-oop.md) ｜ 下一章：[第 19 章 老特性考古 II：DATA、语句函数与 alternate return](19-obsolescent.md) ｜ 返回：[README](../README.md)
