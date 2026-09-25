# 第 21 章 · 经典算法

对应示例：`15-algorithms.f90`

这一章不是算法教学，是**用 Fortran 写算法时的语言注意事项**。算法本身都是教科书内容：冒泡/插入/快速/归并排序、递归与迭代二分查找、埃氏筛、`gcd`、汉诺塔、记忆化与迭代斐波那契、Fisher-Yates 洗牌。

### 排序：数组哑元的写法

```fortran
pure subroutine insertion_sort(a)
  integer(int32), intent(inout) :: a(:)
  integer(int32) :: i, j, key
  do i = 2, size(a)
    key = a(i)
    j = i - 1
    do while (j >= 1 .and. a(j) > key)
      a(j + 1) = a(j)
      j = j - 1
    end do
    a(j + 1) = key
  end do
end subroutine
```

### 这里的语言坑：纯函数不能改哑元

快速排序的分区步骤需要改数组，你可能会写：

```fortran
pure function partition(a, lo, hi) result(p)
  integer(int32), intent(inout) :: a(:)     ! 想改
  ...
end function
```

**gfortran 直接拒绝**：纯函数的哑元必须是 `intent(in)` 或 `value`。flang 会放行（更宽松），但这是标准明确禁止的 —— 别依赖。

正确姿势是把分区写成 `pure subroutine`：

```fortran
pure subroutine partition(a, lo, hi, p)
  integer(int32), intent(inout) :: a(:)
  integer(int32), intent(in)    :: lo, hi
  integer(int32), intent(out)   :: p
  ...
end subroutine
```

子程序可以改 `intent(inout)` 哑元，同时保持 `pure`（纯子程序）。这一点很容易忘。

### 递归函数要写 recursive

```fortran
recursive function fib_memo(n, memo) result(r)
  integer, intent(in) :: n
  integer, intent(inout) :: memo(:)
  integer :: r
  if (n <= 2) then
    r = 1
  else if (memo(n) > 0) then
    r = memo(n)
  else
    r = fib_memo(n - 1, memo) + fib_memo(n - 2, memo)
    memo(n) = r
  end if
end function
```

记忆化把指数复杂度打回线性。注意 `memo` 是 `intent(inout)` —— 递归函数可以有 `intent(inout)` 哑元，只要不是 `pure`。

### 洗牌与随机

Fisher-Yates 洗牌需要随机数，而随机数发生器在两个编译器上不同，所以示例 15 的输出被列进了「已知差异」。见第 25 章。

### 二分查找的边界

```fortran
pure function bsearch(a, key) result(pos)
  integer(int32), intent(in) :: a(:), key
  integer(int32) :: pos
  integer(int32) :: lo, hi, mid
  lo = 1; hi = size(a); pos = -1
  do while (lo <= hi)
    mid = (lo + hi) / 2            ! 注意：整数除法，自动向下取整
    if (a(mid) == key) then
      pos = mid
      return
    else if (a(mid) < key) then
      lo = mid + 1
    else
      hi = mid - 1
    end if
  end do
end function
```

`(lo + hi) / 2` 在 Fortran 里不用写 `floor`，整数除法的语义就是截断。但**注意 `lo + hi` 可能溢出**，虽然实践上不可能发生（数组没到 2^30）。

---

上一章：[第 20 章 泛型、重载与 submodule](20-generics.md) ｜ 下一章：[第 22 章 数值计算](22-numeric.md) ｜ 返回：[README](../README.md)
