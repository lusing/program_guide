# 27 · 强制转换、记法与宏

**对标**: *Reference* 第11章（Coercions）、第23章（Notations and Macros）。

## 27.1 Coe 与 CoeFun

`Coe` 定义"静默类型转换"；`CoeFun` 让值可以像函数一样被调用：

```lean
structure Celsius where
  deg : Float

structure Fahrenheit where
  deg : Float

instance : Coe Celsius Fahrenheit where
  coe c := { deg := c.deg * 9.0 / 5.0 + 32.0 }

#eval (Celsius.mk 100.0 : Fahrenheit).deg   -- 212.000000

-- CoeFun 的第二个参数决定函数签名；之后 Celsius 值可直接当函数调用：
instance : CoeFun Celsius (fun _ => Float → Float) where
  coe c := fun scale => c.deg * scale

#eval (Celsius.mk 30) 2.0   -- 60.000000
```

> 实践建议：跨单位类型的显式转换函数比隐式 Coe 更安全；Coe 适合 DSL 场景
> （如把 `String` 转 `System.FilePath`）。

## 27.2 notation 与 infixl

```lean
infixl:60 " ⇄ " => fun a b => (a, b)
#eval 3 ⇄ 4   -- (3, 4)

notation "⟦" n "⟧" => Nat.succ n
#eval ⟦3⟧     -- 4
```

优先级数字越大绑定越紧；`infixl` 左结合、`infixr` 右结合、`infix` 无结合。

## 27.3 macro：最轻量的语法扩展

```lean
macro "twice " e:term : term => `(($e) + ($e))
#eval twice (2 + 3)   -- 10
```

宏只做语法到语法的展开，见 20.7 的三层架构说明。若需要访问 elaborator 上下文
（生成 fresh 名字、查询环境），才升级到 `syntax` + `elab`。

> **版本陷阱**：与 20.7 一致——新语法的**关键字部分**只能用常规 ASCII 字符，
> CJK 字符会被 tokenizer 当作标识符字符，`syntax "验证" ...` 无法解析。

---

> 上一章：[26 · 公理与计算](26-axioms-computation.md) ｜ 下一章：[28 · 迭代器](28-iterators.md) ｜ 返回：[README](../README.md)
