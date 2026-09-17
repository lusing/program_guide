# 12 · 字符串

> 对应示例：`examples/12_strings/`

## 12.1 Char 与编码：length 是码点、sizeof 是字节

```julia
c = '中'                     # Char：单个 Unicode 码点，32 位
Int('A') == 65 && Char(20013) == '中'    # 码点互转
'a' < 'z'                    # 按码点比较
isletter('中') && isdigit('7') && isspace(' ')

s = "abc中文"
length(s)     # 5——码点数
sizeof(s)     # 9——字节数（3×1 + 2×3，UTF-8 编码）
s[1] == 'a' && s[4] == '中'
collect("aé中")              # ['a','é','中']——按码点拆
```

**String 内部是 UTF-8 字节流，下标是字节下标**——`s[i]` 要求第 i 字节恰是码点边界，否则 `StringIndexError`：

```julia
"aé中"[3]        # StringIndexError——第 3 字节是 é 的第二字节
firstindex(s) == 1
lastindex(s) == 7     # 最后一个码点（"文"）的起始字节下标，≠ length
```

**遍历用迭代（`for ch in s` / `collect` / `eachindex`），别用字节下标猜**——这是多字节字符串的第一纪律。

## 12.2 拼接、插值与不可变

```julia
"J" * "ulia"            # * 拼接（+ 是 MethodError，错误信息会直接提示你用 *）
"ab" ^ 3                # "ababab"
"你好，$(name)！"         # 插值：$var 或 $(expr)
string("a", 1, :b)      # "a1b"——string 万能拼接（任何类型转字符串）
```

String **不可变**（`s[1] = 'x'` 非法）；"修改"= 造新串。频繁拼接小串可用 IOBuffer（19 章）或 `join`。

**插值坑（02 章已见，完整版）**：`$var` 后紧跟**全角标点**（`，`！`：`）或**半角 `!`/`?`**（Julia 标识符合法字符！）都会被吞进变量名——`"n = $n，"` 解析错、`"$name!"` 找 `name!`。**统一写 `$(var)`**。

## 12.3 常用函数速查

```julia
uppercase("abc") == "ABC"
strip("  hi  ") == "hi"                 # 两端空白
lstrip("xxhix", 'x') == "hix"           # 单侧 + 指定字符（strip 双端剥！）
lpad("7", 3, '0') == "007"              # 定宽补齐
split("a,b,,c", ',')                    # ["a","b","","c"]——保留空段
split("a  b   c")                       # ["a","b","c"]——默认按空白、去空段
join(["a","b","c"], "-")                # "a-b-c"
replace("a.b.c", "." => "-")            # Pair 语义替换
replace("a1b2", r"\d" => "#")           # 正则替换
occursin("ul", "Julia")                 # 子串判定
startswith("Julia", "Ju") && endswith("Julia", "ia")
findfirst("l", "Julia")                 # 3:3——Range（码点下标）
findall('a', "banana")                  # [2, 4, 6]
reverse("abc中")                         # "中cba"
chop("abcd")                            # "abc"（去尾）
"b" < "banana" < "c"                    # 字典序
```

## 12.4 正则：`r"..."` 字面量

```julia
m = match(r"(\w+)@(\w+)\.\w+", "mail: a@b.com 结尾")
m.match            # "a@b.com"——整体命中
m.captures         # ["a", "b"]——捕获组（未命中组是 nothing）
m[1]               # "a"——按下标取捕获
collect(eachmatch(r"\d+", "a1 bb 22 c333"))   # 全部命中
occursin(r"^\d{3}$", "123")                   # 正则判定
match(r"a.+?c"i, "ABC") !== nothing           # i 旗标忽略大小写；? 非贪婪
replace("a1b2", r"\d+" => "N")                # "aNbN"
```

正则字面量编译一次（比每次构造 `Regex` 快）；`i/s/m` 旗标后缀；转义用 `raw"..."` 原始字符串（`raw"C:\new"` 不转义反斜杠）。

## 12.5 Printf：C 风格格式化

```julia
using Printf
@sprintf("%.3f", π)                    # "3.142"——返回字符串
@sprintf("%8.2f|%-6d|%s", 1.5, 42, "hi")   # "    1.50|42    |hi"
@sprintf("%05d", 42)                   # "00042"
@sprintf("%x", 255)                    # "ff"
@printf("%.1e\n", 12345.0)             # 直接打印 stdout
```

宽度/精度语义与 C 一致；Julia 的 round 五取偶也体现在 `%e`/`%.0f`（`%.0f` of 0.5 → "0"）。

## 12.6 三引号与缩进

```julia
big = """
    整体缩进由结尾三引号所在列决定
        这行相对多缩进
    """
```

公共缩进按**结尾 `"""` 的列**扣除——代码里嵌多行文本不脏。坑：三引号字符串**内容里不能出现裸 `"""`**（提前终结）——引号内容改用 `\"\"\"` 转义或改措辞（实测 ParseError: extra tokens）。

## 12.7 坑位清单

1. **`$var` 后跟全角标点或 `!`/`?`**：变量名吞并/解析错——统一 `$(var)`（12.2、02 章）。
2. **字节下标 vs 码点下标**：多字节字符串里 `s[i]` 可能 StringIndexError；遍历用迭代器，`lastindex` 是最后码点起始字节（≠ length）（12.1 实测）。
3. **`+` 不拼接字符串**：`"a" + "b"` MethodError（错误信息会建议 `*`）；string() 万能但慢于 `*`（12.2）。
4. **三引号里嵌 `"""`**：直接 ParseError——转义或改写（12.6 实测）。
5. **`strip(s, 'x')` 剥两端**：单侧用 lstrip/rstrip——"xxhix" 剥 'x' 得 "hi" 不是 "hix"（12.3 实测）。
6. **`match` 返回 nothing 而非 false**：判定存在用 `!== nothing` 或 `occursin`；`if match(...)` 会因 nothing 非 Bool 报错。
