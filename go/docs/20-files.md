# 20 · 文件与 IO

> 对应示例：`examples/20_files/`

## 20.1 io.Reader / io.Writer：全库的地基

```go
type Reader interface {
	Read(p []byte) (n int, err error)
}
type Writer interface {
	Write(p []byte) (n int, err error)
}
```

文件、网络连接、内存缓冲、压缩流、加密流……**全是这两个接口的实现**（09 章小接口哲学的最佳广告）。函数签名收 `io.Reader` 而不是 `*os.File`，从此吃进一切：

```go
func CountLines(r io.Reader) (int, error) { ... }

CountLines(f)                       // 文件
CountLines(bytes.NewBuffer(b))      // 内存
CountLines(resp.Body)               // HTTP 响应
CountLines(gzip.NewReader(f))       // 解压流（套娃）
```

## 20.2 os：一把梭与精细档

```go
os.ReadFile(path)                    // 一把读进内存（[]byte, error）
os.WriteFile(path, data, 0o644)      // 一把写

f, err := os.Open(path)              // 精细档：打开（只读）
defer f.Close()
buf := make([]byte, 4096)
n, err := f.Read(buf)                // 按块读

os.CreateTemp("", "guide-*.txt")     // 临时文件（测试/中间产物）
```

大文件流式处理（20.3）或随机访问（`f.ReadAt`/`Seek`）才需要精细档；几 KB 的配置直接 ReadFile。权限位用八进制字面量 `0o644`（不是裸 644）。

## 20.3 bufio：缓冲与按行

```go
sc := bufio.NewScanner(f)
sc.Buffer(make([]byte, 0, 64*1024), 4<<20)   // 单行上限放大到 4 MiB
for sc.Scan() {                              // Scan 剥掉换行符
	line := sc.Text()
}
if err := sc.Err(); err != nil { }           // 循环外查错
```

**Scanner 默认单行上限 64 KiB**——日志/数据文件偶发超长行直接报 `token too long`，生产代码预调 Buffer（示例 20 的 CountLines 与 24 章 minigrep 都带着）。要连换行符一起拿用 `bufio.Reader.ReadString('\n')`；格式化写用 `bufio.NewWriter` + `Flush`（忘了 Flush 丢尾部，和 Zig 的 Writer 一个脾气）。

## 20.4 filepath 与目录遍历

```go
filepath.Join("a", "b", "c.txt")     // 平台正确的拼接（Windows 也用 /）
filepath.Base(p) / filepath.Ext(p)   // 文件名 / 扩展名

filepath.WalkDir(root, func(path string, d fs.DirEntry, err error) error {
	if err != nil {
		return err                    // 目录不可访问：上抛停止
	}
	if !d.IsDir() && filepath.Ext(path) == ".go" {
		found = append(found, path)
	}
	return nil
})
```

`WalkDir`（1.16+）回调给 `DirEntry`——**不用为每个文件 stat**，比老 `Walk` 快且是现代默认。控制遍历：返回 `filepath.SkipDir` 跳过目录（.git 这类）。文件不存在时错误哨兵是 `fs.ErrNotExist`，用 `errors.Is` 判（10 章）。

## 20.5 os.Root：钉死根目录（1.24+）

```go
root, _ := os.OpenRoot("./data")
defer root.Close()

root.ReadFile("notice.txt")     // ✅ 根内相对路径
root.ReadFile("../go.mod")      // ❌ 拒绝：../ 逃逸被挡下
```

处理用户给的路径（上传、解压、模板）时，**Root 把 `../../etc/passwd` 这类攻击面焊死**——所有方法只认根内相对路径，越界报错。新代码里用户路径一律过 Root（示例 20 实测了越界被拒）。

## 20.6 go:embed：文件编进二进制

```go
import "embed"

//go:embed notice.txt
var noticeFS embed.FS              // 单文件/目录/通配符都能嵌

data, _ := noticeFS.ReadFile("notice.txt")
```

编译期把资源嵌进 exe——**部署单文件、运行零依赖**（示例 20 的 notice.txt 就是嵌进去的）。嵌目录后配合 `fs.Sub` 拿到子树，当只读文件系统用；`embed.FS` 实现了 `fs.FS` 接口，喂给 http.FileServer / template 全线通用。

## 20.7 io 工具箱

| 函数 | 干什么 |
|---|---|
| `io.Copy(w, r)` | 把 r 全倒进 w（返回字节数） |
| `io.CopyN(w, r, n)` | 只倒 n 字节 |
| `io.ReadAll(r)` | 读尽成 []byte（注意内存） |
| `io.LimitReader(r, n)` | 包一层限流（防超大输入） |
| `io.MultiReader(a, b)` | 串流 |
| `io.TeeReader(r, w)` | 边读边写（日志/复制） |

组合拳（示例 22 的 POST 处理就是 `io.ReadAll(io.LimitReader(r.Body, 1<<20))`——**别无限信任输入**）。

## 20.8 坑位清单

1. **Scanner 64KiB 行上限**：`token too long` 一报就是它——预调 `sc.Buffer`。
2. **defer f.Close() 的错误没人看**：写文件时 Close 可能才真正落盘失败——`f.Sync()` 或用 WriteFile；读文件 Close 错误可忽略。
3. **路径拼接用字符串 +**：分隔符与 `..` 全是坑——`filepath.Join` 包圆。
4. **Walk 与 WalkDir 混淆**：老 Walk 回调给 FileInfo（每文件一次 stat）——新代码 WalkDir。
5. **临时文件忘删**：`os.CreateTemp` + `defer os.Remove(name)` 成对出现（测试里用 t.TempDir 自动删）。
6. **embed 路径是相对源文件**：`//go:embed ../x` 不允许越出包目录——嵌内容放本包内。

---
