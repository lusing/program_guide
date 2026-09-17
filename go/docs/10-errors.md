# 10 · 错误处理

> 对应示例：`examples/10_errors/`

## 10.1 error 就是一个接口

```go
type error interface {
	Error() string
}
```

没有异常、没有栈展开、没有 try/catch——**错误是普通值**，走函数返回值通道（05 章多返回值为此而生）。招牌三连一天写五十遍：

```go
data, err := Load(path)
if err != nil {
	return fmt.Errorf("加载配置: %w", err)   // 包一层上下文再上抛
}
```

## 10.2 三种错误形态

```go
// ① 哨兵错误：包级变量，调用方按身份识别
var ErrNotFound = errors.New("记录不存在")

// ② 自定义错误类型：携带结构化信息
type FieldError struct {
	Field, Why string
}
func (e *FieldError) Error() string {
	return fmt.Sprintf("字段 %s 不合法：%s", e.Field, e.Why)
}

// ③ 动态错误：errors.New / fmt.Errorf 就地造
```

## 10.3 包装与解包：%w、Is、As

```go
// 包装：底层错误用 %w（不是 %v！），包上下文同时保留原错误
return "", fmt.Errorf("加载记录 %d: %w", id, ErrNotFound)

// errors.Is：沿包装链问"是不是它"（替代 == 比较）
if errors.Is(err, ErrNotFound) { ... }

// errors.As：沿包装链把指定类型的错误抠出来
var fe *FieldError
if errors.As(err, &fe) {
	fmt.Println(fe.Field, fe.Why)    // 拿到结构化字段
}
```

- `%v` 包错误 = **切断链条**，Is/As 从此找不到底层——包错误一律 `%w`（要断链另说，但那是刻意的）；
- `err == ErrNotFound` 直接比较对包装后的错误失明——**永远 errors.Is**（io.EOF、context.Canceled、fs.ErrNotExist 同理）；
- errors.As 的第二个参数是**指针的指针**（`&fe`），fe 声明成目标错误类型的指针。

## 10.4 errors.Join：一次报多个（1.20+）

```go
joined := errors.Join(err1, err2)
fmt.Println(joined)                    // 两行错误拼一起
errors.Is(joined, err1)                // true：穿透 Join
```

批量校验（表单、多文件加载）收错利器；配合 `errors.Is/As` 依旧能拆。

## 10.5 panic 与 recover：不是异常的"异常"

```go
func SafeRun(f func()) (err error) {
	defer func() {
		if r := recover(); r != nil {       // recover 只在 defer 里有效
			err = fmt.Errorf("panic 已恢复: %v", r)
		}
	}()
	f()
	return nil
}
```

panic 是"程序员的 bug"（空指针、越界、不可能的状态），不是控制流。**库代码不 panic**（返回 error），**服务边界用 recover 兜底**（HTTP 中间件、goroutine 顶层——否则一个 panic 带崩整个进程）。panic 时已 defer 的函数会执行，这是 recover 能工作的原因。

## 10.6 什么时候返回 error、什么时候 panic

| 场景 | 选择 |
|---|---|
| 调用方可能处理（文件不存在、网络超时、非法输入） | error |
| 程序员错误（下标越界、nil 解引用） | panic（运行时替你 panic 了） |
| 初始化不可能失败（map 没初始化） | panic 一次暴露 bug 优于静默错 |
| 库的公开 API | 一律 error |

## 10.7 错误处理的编排习惯

```go
// 只包一层、最外层最具体；别每层都 fmt.Errorf 全链复读
func LoadConfig(path string) error {
	data, err := os.ReadFile(path)          // "open x.yml: ..."
	if err != nil {
		return fmt.Errorf("读配置: %w", err)
	}
	...
}

// 调用方决定"处理 / 上抛 / 换语义"
if errors.Is(err, fs.ErrNotExist) {
	return DefaultConfig()    // 缺文件→用默认，消化掉
}
```

## 10.8 坑位清单

1. **%v 包错误断链**：`fmt.Errorf("...: %v", err)` 之后 errors.Is/As 全瞎——要保留链用 `%w`。
2. **err == io.EOF**：直接比较对包装错误失明，标准姿势 `errors.Is(err, io.EOF)`。
3. **errors.As 参数写错**：必须传 `&fe`（**T 的指针的指针**），直接传 fe 编译错（这是好事）。
4. **goroutine 里的 panic 没人 recover**：整个进程崩——worker 顶层 defer recover 是标配（17/18 章示例有）。
5. **在 defer 里改返回值忘了命名返回值**：`func f() (err error)` 才能在 defer 里 `err = ...` 生效。
6. **每次都包一层**：五层函数包五遍"加载失败"，日志复读机——就近包一次，语义够用即可。

---
