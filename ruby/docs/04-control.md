# 04 · 控制流

> 对应示例：`examples/04_control/`

Ruby 的控制流有两套分支语法：传统的 `case/when`（幕后是 `===`）与 2.7+ 的 `case/in` 模式匹配（幕后是解构协议）。本章主线：**先吃透 `===` 与真值语义，再上模式匹配**——`in` 的行为都建立在 `when` 讲过的匹配思想上。

## 4.1 if / unless：条件是表达式

```ruby
grade = 85
label = if grade >= 90 then "优"
       elsif grade >= 80 then "良"
       else "不及格"
       end
dry = "晴天" unless false                  # unless = if not
count += 1 while count < 3                 # 后置修饰符：一行流
safe = nilable && nilable.size             # and/or 短路守门
```

```text
---- 4.1 if / unless：条件是表达式 ----
grade=85 → 良
短路守门：nilable && nilable.size → nil
```

`if`/`elsif`/`else` 是表达式，整块有值可直接赋值（02.7 的原则）：

```ruby
grade = 85
label = if grade >= 90 then "优"
       elsif grade >= 80 then "良"
       elsif grade >= 60 then "及格"
       else "不及格"
       end
ok label == "良"
```

`unless` 是 `if not`，**没有 elsif 变体**，也通常不写 else（读起来绕）——「除非……否则」超过一层就该换回 `if`。条件修饰符（后置 `if`/`unless`/`while`）是一行流惯用法：`count += 1 while count < 3` 这样的守卫循环一行搞定。

`&&`/`||` 短路求值是最常用的 nil 守门：左边为假右边根本不求值，`nilable && nilable.size` 安全返回 `nil`。注意 Ruby 的 `and`/`or` 关键字与 `&&`/`||` **优先级不同**（`and`/`or` 极低，低于赋值），控制流守门一律用符号版；`and`/`or` 只在流程编排惯用法（如 `do_something or raise`）里出现。

## 4.2 真值语义：只有 false 和 nil 是假

```ruby
truthy = [0, 0.0, "", [], {}, :sym, true]
truthy.each { |v| ok v, "#{v.inspect} 应为真值" }   # 0 和 "" 都为真！
```

```text
---- 4.2 真值语义：只有 false 和 nil 是假 ----
0、""、[] 在 Ruby 里全为真 —— 与 C/JS/Python 都不同
```

Ruby 的假值表只有两项：`false` 和 `nil`。示例把候选值收进一个数组逐个断言：

```ruby
truthy = [0, 0.0, "", [], {}, :sym, true]
truthy.each { |v| ok v, "#{v.inspect} 应为真值" }   # 0 和 "" 都为真！
ok !false && !nil
```

`0`、`0.0`、`""`、`[]`、`{}` 全为真——与 C（0 为假）、JavaScript（`""`/`0` 为假）、Python（`0`/`""`/空容器为假）都不同。这不是学术问题：从 Python 移植 `if x:` 判空的逻辑，在 Ruby 里空字符串会走「真」分支。判空要用 `.empty?`、`.nil?` 或 `x.nil? || x.empty?`，别用裸真值判断。

真值判断是纯粹的「身份判断」——对象是不是 `false`/`nil` 本身，**不调用任何方法**。这也解释了一个惯用法：`while line = gets`（读不到时 `gets` 返回 `nil`，循环终止）成立，而「读到空行就停」的直觉写法不成立——空行是 `"\n"`，是真值。另有两个便捷谓词：`!x` 与 `x.nil?` 在 `x` 为 `false` 时不同（前者真、后者假），混用前想清楚你要判的是「没有值」还是「假」。

## 4.3 while / until / loop

```ruby
while i <= 10;  sum += i;  i += 1;  end
n += 1 until n >= 5                        # until = while not
count2 = 0
loop do                                    # loop do ... end 无限循环
  count2 += 1
  break if count2 >= 3
end
total = loop do
  break 100                                # break 可以带返回值
end
```

```text
---- 4.3 while / until / loop ----
while 累加 1..10 = 55；loop break 可带值（100）
```

`while`/`until` 语义与 C 对应（`until` = `while not`）。`loop do ... end` 是无限循环惯用法，靠 `break` 跳出。**`break` 可以带值**：`break 100` 让整个循环表达式的值是 100——循环也是表达式（02.7 的原则再次兑现）。注意 Ruby 没有 C 式的 `do-while`，等价写法是 `loop do ... break unless cond ... end`。

三个无限/条件循环的选位：知道次数用 Range/`times`（11 章）、不知道次数但知道终止条件用 `while`/`until`、根本不设终止条件的（事件循环、读流到 EOF）用 `loop`——`loop` 还有个隐蔽优点：块内 `StopIteration` 会被它静默吞掉转为正常结束，配合外部迭代器（11 章）是官方指定的「读完为止」姿势。

## 4.4 next / break / redo

```ruby
skipped = []
1.upto(5) do |k|
  next if k.odd?                           # 跳过本轮
  skipped << k
end
ok skipped == [2, 4]
```

```text
---- 4.4 next / break / redo ----
next 跳过奇数 → [2, 4]
```

三个控制词：`next` 跳过本轮继续下一轮（相当于 C 的 `continue`——**Ruby 里没有 `continue` 这个词**）；`break` 整个跳出（可带值）；`redo` 重跑本轮且**不再求值条件**——用错了就是死循环，实际代码里几乎只在重试逻辑中出现。示例用 `1.upto(5)` 配 `next if k.odd?` 演示跳过奇数得到 `[2, 4]`。这些词在块里同样有效（14 章细讲块的控制流），但作用域细节不同：块里的 `break` 对「调块的迭代器」意味着什么，要到 14 章才见分晓——现在只要记住循环三兄弟在 `while`/`loop` 里的行为是教科书式的。

## 4.5 case/when：用 === 逐支匹配

```ruby
def classify(x)
  case x
  when 0...60  then "不及格"          # Range 的 === = include?（范围支要放在 Integer 前！）
  when 60..100 then "及格"
  when Integer then "整数"
  when /ru/    then "含 ru 的字符串"  # Regexp 的 === = match?
  when ->(v) { v.respond_to?(:call) } then "可调用"
  else "其他"
  end
end
```

```text
---- 4.5 case/when：用 === 逐支匹配 ----
classify(42)=不及格 classify(90)=及格 classify(10**30)=整数
```

`case/when` 不是相等比较，而是**从上到下逐支调 `when` 对象的 `===`**。常用类型的 `===` 语义：

| when 对象 | `===` 等价于 | 例 |
|---|---|---|
| Range | `include?` | `(0...60) === 42` |
| Class/Module | `is_a?` | `Integer === 10**30` |
| Regexp | `match?` | `/ru/ === "ruby"` |
| lambda/Proc | `call` | `->(v) { v.respond_to?(:call) } === obj` |
| 其他对象 | `==` | `"user" === x` |

所以分支顺序就是语义：**`Range` 支必须放在 `Integer` 支之前**——`42` 也是 Integer，`Integer` 在前会把所有整数截走。示例里 `classify(10**30)` 落到 `Integer` 支（超出 0..100），正是「顺序即语义」的证据；而 `classify(42)` 命中第一支 `0...60`，也印证了范围支在前。`case` 还有无值形式（`case ... when 条件`），等价于一串 `if`，适合布尔条件族的清晰化。

## 4.6 case/in 模式匹配：解构数组与哈希

```ruby
def describe(payload)
  case payload
  in { type: "user", name: String => name }
    "用户 #{name}"
  in { type: "order", id: Integer => id, **rest } if rest.key?(:amount)
    "订单 #{id}，金额 #{rest[:amount]}"
  in [Integer, Integer] => pair
    "坐标 #{pair.inspect}"
  in Integer | Float => num
    "数字 #{num}"
  in nil
    "空"
  else
    "未知负载"
  end
end
```

```text
---- 4.6 case/in 模式匹配：解构数组与哈希 ----
用户 小明
订单 7，金额 99
坐标 [3, 4]
```

`case/in` 是 2.7 引入、3.0 转正的**模式匹配**：不只是判断，还顺手解构绑定。示例里的 `describe` 一口气覆盖了五种模式形态：`{ type: "user", name: String => name }`（字面量匹配 + 类型约束 + `=>` 绑定变量）、`y:` 无值形式直接绑定到变量 `y`、`**rest` 收集剩余键、尾部 `if guard` 条件、`Integer | Float` 或模式、数组位置模式 `[Integer, Integer]`。它与 `when` 的本质区别：`when` 匹配失败静默走下一支，`in` 全部失配时**抛 `NoMatchingPatternError`**，不静默——用 `else` 兜底是防御性写法。示例末尾专门演示了这一点：`case 1` 配 `in String` 直接炸进 rescue。

实测坑：**`case/in` 不能写成单行**——`case 1 in String then :s end` 是语法错误，`in` 之前必须换行；而 `case/when` 的单行形式（`case 5 when Integer then "整数" end`，见 2.7）反而合法。两者别混。这条是 4.0.7 + Prism 的实测事实，旧资料按 `when` 的习惯写 `in` 会直接解析失败。模式匹配在 6.5 节还会出现（`Data` 的解构协议），11/24 章也有实战——它值得一次学透。

## 4.7 for 与块循环的作用域差异

```ruby
for k in [1, 2, 3]
  last = k                     # for 不开新作用域，k 泄漏到外层
end
[1, 2, 3].each do |m|
  last = m                     # 块的循环变量只在块内
end
```

```text
---- 4.7 for 与块循环的作用域差异 ----
for 循环变量泄漏到外层（k=3）；块的循环变量只在块内 —— 生产代码几乎都用 each
```

`for k in ...` 语法上存在，但它**不开新作用域**：循环变量 `k` 在循环结束后仍然活着，直接污染外层。`.each` 块的循环变量只在块内。示例末尾的 `defined?(k)` 返回 `"local-variable"`、`defined?(m)` 返回 `nil`——一行探针坐实两种作用域规则的差别。生产代码里 `for` 几乎绝迹，理由就是这条作用域规则——认得它即可，写循环用 `each`/`upto`/`times`（11 章的 Enumerable 才是主角）。

## 4.8 坑位清单

1. **只有 `false` 和 `nil` 为假**：`0`、`""`、`[]` 全为真，判空必须显式 `.empty?`/`.nil?`，Python 的 `if x:` 直译必错（4.2）。
2. **`case/in` 不能单行**：`in` 前必须换行，`case 1 in String then :s end` 语法错误；`case/when` 单行反而合法——两条语法别记反（4.6/2.7）。
3. **`case/when` 的 Range 支要放在 Integer 支前**：`===` 逐支匹配按顺序，`Integer` 在前会把 `42` 截走、永远轮不到范围支（4.5）。
4. **模式匹配失配抛 `NoMatchingPatternError`**：`in` 分支不像 `when` 那样静默掉过，没有 `else` 兜底就直接炸（4.6）。
5. **Ruby 没有 `continue`**：跳过本轮写 `next`；`redo` 重跑本轮且不重估条件，易死循环（4.4）。
6. **`unless` 不带 elsif**：`if not` 的替身，多分支还硬用 unless 是自找难读（4.1）。
7. **`break 100` 带出循环值**：忘了循环是表达式，会写出「先给临时变量赋值再 break」的 C 风格冗余（4.3）。
8. **`for` 的循环变量泄漏**：`for k in ...` 后 `k` 还活着，作用域规则与 `each` 不同——生产代码用 `each`（4.7）。
9. **`&&`/`||` 与 `and`/`or` 优先级不同**：`and`/`or` 优先级极低，与赋值混用会出反直觉结果，控制流守门一律用符号版（4.1）。
10. **`1.upto(5)` 上界包含**：`1.upto(5)` 跑 1..5 五次；要排除上界用 Range `1...5` 或 `times`——含不含端点两条 API 轨道要分清（4.4/4.5）。
11. **后置修饰符不宜叠用**：`a = 1 if b unless c` 这类「修饰符叠修饰符」解析顺序反直觉，一律拆行或改用块形式（4.1）。
12. **短路守门左边要 «真值安全»**：`nilable && nilable.size` 依赖左边为假时右边不求值；若左边可能是 `false` 而你想区分「false」与「nil」，`&&` 链返回的 `false` 会掩盖差异——守门写法要先想清楚假值到底是什么（4.1/4.2）。

---

**上一章**：[03 · 数值类型](03-numbers.md) | **下一章**：[05 · 方法](05-methods.md)
