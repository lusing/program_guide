# 31 · 压缩与归档：gzip / zlib / flate / bzip2 / tar / zip

> 对应示例：`examples/31_archive/`。压缩（把字节变少）与归档（把多文件打成一包）是两件事——zip 两者都做。

## 31.1 家族关系：flate 是地基

```text
compress/flate   DEFLATE 原始算法（RFC 1951）——一般不直接用
compress/zlib    flate + 帧头 + Adler-32 校验（RFC 1950）
compress/gzip    flate + 文件头 + CRC32 + 时间戳（RFC 1952）——.gz 文件
compress/bzip2   BWT 算法——只有读没有写！
archive/tar      只归档不压缩（.tar；.tar.gz = tar 外面套 gzip）
archive/zip      归档 + 每文件可选压缩（.zip）
```

`os.Open` 打开的 `.gz` 包 `gzip.NewReader` 一裹就能读；写文件时 `gzip.NewWriter(file)` 裹一层，照常 `io.Copy`（20 章的管道思维：**压缩只是套在 Writer 外面的另一层管道**）。

## 31.2 gzip 读写

```go
// 写
var buf bytes.Buffer
zw := gzip.NewWriter(&buf)            // 或 NewWriterLevel(&buf, gzip.BestCompression)
zw.Write(data)
zw.Close()                            // 必须关：尾部 CRC 和长度在 Close 时才写！

// 读
zr, err := gzip.NewReader(bytes.NewReader(buf.Bytes()))  // 自动识别多成员流
defer zr.Close()
plain, err := io.ReadAll(zr)

// 头部元信息
zr.Name / zr.Comment / zr.ModTime     // 读侧能拿到（写侧在 Header 字段里设）
zr.Multistream(true)                  // .gz 可以串多个成员，默认自动拼
```

压缩级别：`gzip.NoCompression`（最快最大）→ `gzip.BestCompression`（最慢最小），`DefaultCompression` 居中。**压缩的是重复度**——随机数据压不动（甚至变大 0.03%）；文本/日志常见 3–10 倍。

## 31.3 tar：打包

```go
// 写：每个文件 = 一个 Header + 一段内容
var buf bytes.Buffer
tw := tar.NewWriter(&buf)
for name, content := range files {
    hdr := &tar.Header{
        Name: name, Mode: 0o644,
        Size: int64(len(content)), ModTime: time.Now(),
        Typeflag: tar.TypeReg,               // 普通文件；目录是 TypeDir
    }
    tw.WriteHeader(hdr)                       // 先头
    tw.Write([]byte(content))                 // 后内容（长度必须等于 hdr.Size）
}
tw.Close()

// 读：Next 逐文件推进
tr := tar.NewReader(bytes.NewReader(buf.Bytes()))
for {
    hdr, err := tr.Next()
    if err == io.EOF { break }
    if err != nil { return err }
    switch hdr.Typeflag {
    case tar.TypeReg:
        content, _ := io.ReadAll(tr)          // 只读当前文件的字节
    }
}
```

解包写盘时**先校验路径**（`filepath.Clean` 后确认落在目标目录内——恶意 tar 里 `../../etc/passwd` 是真实攻击面；1.24 起直接用 20 章的 `os.Root` 钉死）。

## 31.4 zip：归档 + 压缩

```go
// 写
zw := zip.NewWriter(&buf)
for name, content := range files {
    w, _ := zw.Create(name)                   // 默认 Deflate；CreateHeader 可选 Store（仅存不压）
    w.Write([]byte(content))
}
zw.Close()

// 读
zr, err := zip.NewReader(bytes.NewReader(data), int64(len(data)))  // 要 ReaderAt + 总长
for _, f := range zr.File {                   // zr.File 是目录清单
    rc, err := f.Open()                       // 每个条目单独打开
    defer rc.Close()
    content, _ := io.ReadAll(rc)
    fmt.Println(f.Name, f.Method, f.Modified)
}
```

`zip.NewReader` 要的是 `io.ReaderAt` 和**精确总长**（zip 的目录在文件尾部，需要随机访问）——所以 zip 也能直接从 `os.File` 读（实现 ReaderAt），但不能从流式网络读（得先落盘或攒进内存）。`f.Open()` 返回的 `io.ReadCloser` **用完必须关**，不然句柄泄漏。

## 31.5 速查

| 需求 | 用 |
|---|---|
| 压缩单段字节/文件 | `gzip.NewWriter` |
| 带校验的紧凑流 | `compress/zlib` |
| 打包多文件（Unix 风） | `tar`（配 gzip 成 .tar.gz） |
| 桌面右键那种 zip | `archive/zip` |
| 读 .bz2 | `compress/bzip2`（只读） |
| 内存里做全套 | `bytes.Buffer` 当中转（示例 31 的做法） |

## 31.6 坑位清单

1. **gzip.Writer 忘 Close**：尾部 CRC32 缺失，读侧报 `unexpected EOF`——`defer zw.Close()` 但注意**读完错误前别提前退出**；Flush 也只是刷缓冲不带尾。
2. **tar 的 Write 长度 ≠ hdr.Size**：解包时读错位——按 `io.CopyN`/`io.ReadAll` 精确读 `hdr.Size` 字节。
3. **解 tar 不验路径**：`../` 逃逸攻击——`filepath.Clean` + 前缀校验或 `os.Root`。
4. **zip.NewReader 传 0 长度**：目录解析失败——总长必须是字节数据的精确长度。
5. **条目 f.Open() 不关**：zr.File 循环里泄漏句柄——当轮 defer 改显式关。
6. **期待压缩随机数据**：加密后/已压缩过的数据再压白费 CPU，体积反涨一点。
7. **bzip2 找 Writer**：包里**只有 Reader**——要写 bzip2 得引第三方库。

---

---

上一章：[30 编码三件套](30-encoding.md) · 下一章：[32 进程与信号](32-process.md)
