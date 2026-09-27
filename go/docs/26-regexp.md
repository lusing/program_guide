# 26 · 正则表达式：regexp

> 对应示例：`examples/26_regexp/`。24 章的 minigrep 已经用过它查模式——这里把 API 面补全。

## 26.1 先立规矩：RE2 引擎，没有回溯

Go 的 regexp 是 **RE2 语法**（来自 Google 的 RE2 项目）：**不支持反向引用 `\1`、不支持环视 `(?=...)` `(?!...)`**，换来的是**线性时间保证**——构造再邪恶的输入也不会像 PCRE 那样指数回溯拖死服务（ReDoS 攻击在 Go 这里天然免疫）。

要"环视"的效果，就用普通匹配 + Go 代码判断；要"引用前文"，捕获分组拿出来在代码里比。

```go
re := regexp.MustCompile(`^\d{4}-\d{2}-\d{2}$`) // 编译失败直接 panic：模式写死在代码里的场合
re2, err := regexp.Compile(dynamicPattern)     // 模式来自用户输入/配置：必须 Compile + 处理 err
```

`MustCompile` 用于**写死在源码里的模式**（写错了就该在第一次跑起来时炸掉）；运行时拼出来的模式用 `Compile`。

## 26.2 匹配与查找

```go
re := regexp.MustCompile(`go\w+`)

re.MatchString("gopher")             // true——只回答在不在
re.Match([]byte(...))                // 字节版

re.FindString("go go golang")        // "go"——第一个匹配
re.FindAllString("go go golang", -1) // [go go golang]——-1 全要，n 限个数
re.FindStringIndex("a go here")      // [2 4]——[起,止) 字节下标
re.FindStringSubindex(s)             // 每个分组的 [起,止) 都给
```

**没有 FindStringAll**——家族命名规律：`Find` 打头，`All` 居中表示"全部"，`String` 居中/居尾表示"吃 string 返回 string"（默认版本吃 `[]byte`）。`FindAllString(s, n)` 的 n 是**上限**：`-1` 才是全量，`0` 是空。

## 26.3 子匹配与命名分组

```go
logRe := regexp.MustCompile(`^(?P<time>\S+) (?P<level>\w+) (?P<msg>.*)$`)

m := logRe.FindStringSubmatch("2026-09-27 INFO 服务启动")
// m[0] = 整个匹配；m[1..] 按左括号顺序对应各分组
// 数组版只能按下标取，命名分组配 SubexpIndex 按名取：

i := logRe.SubexpIndex("level")
m[i]                                 // "INFO"

for i, name := range logRe.SubexpNames() { ... } // 下标 → 名字（0 号是整个匹配，名字为空）
```

命名字面量是 `(?P<name>...)`——**P 是 PCRE 血统的写法，Go 原样沿用**（不支持 Python 的 `(?P=name)` 反向引用）。

## 26.4 替换

```go
re := regexp.MustCompile(`(\w+)@(\w+)\.com`)

re.ReplaceAllString(s, "$1 at $2")       // $1/$2 引用分组；$name 引用命名分组
re.ReplaceAllLiteralString(s, "$1")      // 不展开 $：字面替换
re.ReplaceAllStringFunc(s, func(m string) string {  // 每个匹配交给函数
    return strings.ToUpper(m)
})
```

坑在 **`$` 的展开规则**：替换串里的 `$1x` 会被当成分组 `1x`（不存在 → 空串）——分组后要紧跟字面量就写 `${1}x`。要替换的字面量本身带 `$`，用 `ReplaceAllLiteralString` 或先把 `$` 写成 `$$`。

**动态拼模式前先消毒**：`regexp.QuoteMeta(userInput)` 把用户输入里的元字符全部转义成普通字符——拿用户串当"字面量搜索词"时必做，否则 `a.b(` 直接编译失败或行为不对。

## 26.5 切分与其他

```go
regexp.MustCompile(`[,;]\s*`).Split("a, b;c", -1)  // [a b c]
regexp.QuoteMeta("a.b*c")                          // a\.b\*c
regexp.MatchString(`^\d+$`, "123")                 // 一次性便捷函数（内部每次都编译，热路径别用）
```

大小写、多行这些"修饰符"写在模式**开头**：`(?i)` 忽略大小写、`(?m)` 多行（`^$` 匹配行首行尾）、`(?s)` 单行（`.` 吃换行）。贪婪切换：默认贪婪（最长），`.*?` 惰性（最短）；`(?U)` 整体反转贪婪语义。

## 26.6 速查

| 需求 | 写法 |
|---|---|
| 写死的模式 | `MustCompile`（错即 panic） |
| 动态模式 | `Compile` + err |
| 全部匹配 | `FindAllString(s, -1)` |
| 提取字段 | `FindStringSubmatch` + `SubexpIndex` |
| 模板替换 | `ReplaceAllString(s, "${1}x")` |
| 大小写不敏感 | 模式前缀 `(?i)` |
| 用户词当字面量 | `QuoteMeta` 先转义 |

## 26.7 坑位清单

1. **找环视/反向引用**：RE2 没有——重构为普通匹配 + 代码判断，别从 PCRE 直接搬。
2. **`FindAllString(s, 0)`**：返回空——全量是 `-1`。
3. **替换串 `$1x` 变空**：分组名贪婪吃掉 x——写 `${1}x`。
4. **循环里 MatchString(模式, s)**：便捷函数每次编译——模式提出来 `MustCompile` 一次。
5. **用户输入直接拼进模式**：`.` `(` 会被当元字符——`QuoteMeta` 转义。
6. **命名分组写 `(?<name>...)`**：Go 只认 `(?P<name>...)`（.NET/JS 风格不支持）。
7. **拿正则切空白**：`Fields` 比 `\s+` 的 Split 又快又好——能用字符串 API 就别上正则。

---
