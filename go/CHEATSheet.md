# Go 1.27 速查表

语法速查 + 坑位索引。详细讲解见对应章（表中 N.M = 第 N 章 M 节）。

## 1. 命令速查

```powershell
go run .                        # 编译+运行（`.` 是包目录，不是 main.go）
go build -o out.exe .           # 产可执行（macOS/Linux 不带 .exe）
go test [-v] [-race] [-bench .] [-cover] .
go vet . / gofmt -l .           # 静态检查 / 格式检查（-l 输出空 = 合格）
go mod init|tidy|why            # 模块管理（14）
go doc fmt.Println              # 命令行文档
go tool pprof|trace <file>      # 性能画像（23）
$env:GOOS="linux"; go build .   # 交叉编译（PowerShell；用完清掉！）
GOOS=linux go build .           # 交叉编译（bash；只作用于这一条命令）
go build -ldflags "-s -w -X main.ver=1.0" .
```

`-race` 需要 cgo：Windows 装 gcc，macOS 用自带 clang。`go env CGO_ENABLED` 看是否可用。

## 2. 声明与类型（03）

```go
var s string          // 零值 ""：Go 没有"未初始化"
x := 1                // 短声明（函数内）；左侧至少一个新变量
const pi = 3.14       // 无类型常量：任意精度
type Celsius float64  // 命名类型：底层同也不同型，显式转换才通
i := int(3.99)        // 3：向零截断；四舍五入 math.Round
min(a, b); max(a, b); clear(s)   // 1.21+ 内建（不能当函数值传）
```

| 坑 | 解法 |
|---|---|
| int/int64 混算编译错 | 显式转换 `int64(x)`（03.5） |
| `int32(1 << 40)` 静默截断 | 转换不查溢出，自己判（03.5） |
| 枚举打出来是数字 | 给类型实现 `String()`（03.6） |

## 3. 控制流（04）

```go
for i := range 10 { }        // 1.22+：range 整数
for cond { }                 // while
for { break }                // 无限
outer: for { for { break outer } }   // 标签跳出
switch v := x.(type) { case int: }   // 类型 switch
switch { case c1: }          // 无表达式 = if-else 链
// case 默认不穿透；fallthrough 强穿（不看条件）
```

| 坑 | 解法 |
|---|---|
| map 遍历顺序随机 | `slices.Sorted(maps.Keys(m))`（12.5） |
| range 的 v 是副本 | 改原切片用 `s[i]`，别改 v（04.7） |
| range 字符串 i 跳字节 | 按字符先 `[]rune(s)`（06.6） |

## 4. 函数与 defer（05）

```go
func f(a, b int) (int, error) { }     // 多返回值；错误走返回值
func g(nums ...int) { }               // 变参；切片展开 g(s...)
defer f.Close()                       // LIFO；参数立刻求值
defer func() { fmt.Println(x) }()     // 延迟求值包闭包
c := Counter()                        // 闭包持有环境
// 1.22+：循环变量每轮新副本（老共享坑已修）
```

| 坑 | 解法 |
|---|---|
| defer 记住旧值 | 参数立刻求值——要新值套闭包（05.4） |
| 循环里 defer 积压 | 循环体抽成函数（05.8） |
| 没有重载/默认参数 | 变参 / options 模式（05.6） |

## 5. 切片与字符串（06）

```go
s := make([]T, 0, n)      // 预分配防搬家
s = append(s, v)
view := a[low:high:max]   // 三下标限死 cap：append 必搬家
copy(dst, src); slices.Clone(s)
len("你好")               // 6：字节数！
utf8.RuneCountInString(s) // 字符数
[]rune(s)[0]              // 首 rune（string→[]rune 复制）
```

| 坑 | 解法 |
|---|---|
| append 覆盖兄弟切片 | 三下标 `a[l:h:h]` 或 Clone（06.4） |
| 扩容后旧指针失效 | 缓存下标不缓存 &s[i]（06.8） |
| `s[:cap(s)]` 合法但半垃圾 | 切片表达式上限是 cap 不是 len（06.8） |
| 大字符串切片不放内存 | `string(s[100:])` 强制复制（06.8） |

## 6. map 与结构体（07/08）

```go
v, ok := m[k]              // 逗号 ok：存在性唯一正道
m[k]++                     // 零值起步计数
set := map[string]struct{} // set 惯用法
delete(m, k)               // 幂等
type Set map[string]struct{}
func (s Set) Has(k string) bool { _, ok := s[k]; return ok }
func (r *Rect) Scale(k float64) // 改自身必须指针接收者
type A struct { B }               // 嵌入：字段方法提升，不是继承
func (x T) String() string       // Stringer：控制 %v
```

| 坑 | 解法 |
|---|---|
| nil map 写入 panic | `make` 初始化再写（07.4） |
| 并发读写 map 直接崩 | Mutex / sync.Map（18.4） |
| `m[k].Field = x` 编译不过 | 存 `map[K]*V` 或取改放回（07.7） |
| 值接收者改字段无效 | 指针接收者；接口装值时方法集对不上（08.2） |

## 7. 接口与错误（09/10）

```go
var s Shape = Rect{}       // 隐式实现；接口 = (动态类型, 动态值)
if v, ok := x.(Shape); ok { }
if errors.Is(err, ErrNotFound) { }        // 哨兵：穿透包装链
var fe *FieldError; errors.As(err, &fe)   // 结构化：注意 &fe
fmt.Errorf("ctx: %w", err)                // 包装必须 %w
errors.Join(e1, e2)                       // 1.20+
defer func() { if r := recover(); r != nil { } }()  // panic 兜底
```

| 坑 | 解法 |
|---|---|
| typed-nil：返回具体类型 nil 变量当 error | `err != nil` 误判——返回 nil 字面量（09.4） |
| `%v` 包错误断链 | 一律 `%w`（10.3） |
| `err == io.EOF` | 包装后失明——errors.Is（10.8） |
| goroutine panic 没人接 | worker 顶层 defer recover（10.5） |

## 8. 泛型与集合库（11/12）

```go
func Max[T cmp.Ordered](a, b T) T { }
type Stack[T any] struct{ items []T }
func (s *Stack[T]) Push(v T)             // 方法不重复声明 T
type Number interface { ~int | ~float64 } // ~ = 底层类型
slices.Sort / SortFunc(s, func(a, b T) int { return cmp.Compare(a, b) })
slices.Index / Contains / Equal / Clone / Compact / Insert / Concat
maps.Clone / Copy / DeleteFunc
slices.Sorted(maps.Keys(m))               // 有序键（1.23+ 迭代器）
slices.Collect(maps.Values(m))
```

| 坑 | 解法 |
|---|---|
| BinarySearch 前没排序 | 静默给垃圾——先 Sort（12.1） |
| SortFunc 返回 bool | 那是 sort.Slice；slices.SortFunc 要 int（12.2） |
| 约束忘了 ~ | `type X int` 进不来——数值约束都要 ~（11.3） |
| 方法不能有自己的类型参数 | 泛型方法不存在——写成顶层函数（11.8） |

## 9. 迭代器（13）

```go
func All(l *List) iter.Seq[int] {          // range over func（1.23+）
	return func(yield func(int) bool) {
		for n := l.head; n != nil; n = n.next {
			if !yield(n.val) { return }
		}
	}
}
for v := range All(list) { }
slices.Collect(seq); slices.Backward(s)
strings.SplitSeq(s, ",")                   // 1.24+：不落中间切片
next, stop := iter.Pull(seq); defer stop() // 拉模式
```

| 坑 | 解法 |
|---|---|
| yield false 还继续 | 调用方已 break——立刻 return（13.8） |
| Pull 不 stop | defer stop()（13.6） |
| maps.Keys 当切片用（老教程） | 1.23+ 是迭代器——Collect/Sorted（12.5） |

## 10. 测试（15）

```go
func TestX(t *testing.T) { t.Parallel(); t.Helper(); t.Run("子", f) }
func ExampleX() { /* Output:\n结果 */ }    // 文档即测试
func BenchmarkX(b *testing.B) { for b.Loop() { } }   // 1.24+
func FuzzX(f *testing.F) { f.Add(seed); f.Fuzz(func(t *testing.T, s string) {}) }
synctest.Test(t, func(t *testing.T) { })  // 假时钟气泡（1.27 实测签名）
dir := t.TempDir(); ctx := t.Context()    // 1.24+
```

| 坑 | 解法 |
|---|---|
| Example 输出差一个空格 | 逐字符匹配——`%q` 显形（15.8） |
| 子 goroutine t.Fatal | 不中断测试——Error + 通道回传（15.8） |
| synctest 里做真 IO | 时间不前进死锁——气泡里纯内存（15.6） |
| 老基准 for b.N | 新代码 b.Loop()（15.4） |

## 11. 并发（16/17/18）

```go
var wg sync.WaitGroup
wg.Go(func() { })            // 1.25+：Add+go+Done 三合一
wg.Wait()
var n atomic.Int64; n.Add(1)
once.Do(init)                // / sync.OnceValue(f)
ch := make(chan T)           // 无缓冲=会合点；make(chan T, n) 缓冲
ch <- v; v = <-ch; close(ch)
for v := range ch { }        // 消费到 close
v, ok := <-ch                // 探测关闭
select { case <-ctx.Done(): return ctx.Err()
         case <-time.After(d): }
ctx, cancel := context.WithTimeout(ctx, d); defer cancel()
mu.Lock(); defer mu.Unlock()
```

| 坑 | 解法 |
|---|---|
| main 先退输出消失 | channel/WaitGroup 等（16.1） |
| `count++` 并发丢数 | 锁 / atomic / 不共享（16.3） |
| 消费者 close channel | 只有生产者关（17.2） |
| 锁被拷贝 | 值接收者藏 Mutex——vet copylocks（18.7） |
| cancel 不调泄漏 | defer cancel() 肌肉记忆（18.5） |

## 12. 时间 / 文件 / JSON / HTTP（19–22）

```go
t.Format("2006-01-02 15:04:05")     // 布局 = 参考时间长相
time.Parse(layout, s)
_ = "time/tzdata"                   // Windows 必带；macOS/Linux 冗余但无害（19.3）
d := 3 * time.Second                // Duration 永远带单位
os.ReadFile / os.WriteFile
sc := bufio.NewScanner(f); sc.Buffer(nil, 4<<20)  // 长行必调
filepath.WalkDir(root, fn)          // 别再用 Walk
root, _ := os.OpenRoot("."); root.ReadFile("x")  // 1.24+ 防逃逸
//go:embed file.txt; var fs embed.FS
type T struct { X int `json:"x,omitempty"` }     // 标签/omitempty/"-"
mux.HandleFunc("GET /u/{name}", h)  // 1.22+ 方法路由；PathValue
srv := &http.Server{Handler: withLogging(mux)}
defer resp.Body.Close()             // 客户端必做
jsonv2.Marshal / jsontext.NewEncoder(w, jsontext.WithIndent("  "))  // 1.27
```

| 坑 | 解法 |
|---|---|
| Scanner 报 token too long | 64KiB 默认上限——sc.Buffer 放大（20.3） |
| LoadLocation 报错（Windows） | `import _ "time/tzdata"`；macOS/Linux 有系统 tzdata（19.3） |
| any 解码数字变 float64 | json.Number 或结构体目标（21.2） |
| nil 切片序列化成 null | 初始化 `[]T{}`（21.7） |
| DefaultClient 无超时 | 自建 Client{Timeout}（22.4） |
