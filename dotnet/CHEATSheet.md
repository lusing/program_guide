# .NET 开发清单

配合 [docs/](docs/) 24 章教程使用；每条主题链接到对应章节。

## 环境设置（[第 01 章](docs/01-overview.md)）

- [ ] 安装 .NET 10 SDK（LTS，支持至 2028-11）
- [ ] 验证安装：`dotnet --version`
- [ ] 选编辑器：VS / VS Code + C# 扩展 / Rider

## 项目创建（[第 01 章](docs/01-overview.md)）

```bash
dotnet new console -n MyApp      # 控制台
dotnet new classlib -n MyLib     # 类库
dotnet new webapi -n MyApi       # Web API
dotnet new xunit -n MyTests      # 单元测试
```

## 章节速查

| 主题 | 章节 |
|---|---|
| 类型/控制流/方法参数 | [第 03 章](docs/03-types.md) |
| OOP：类、继承、接口 | [第 04 章](docs/04-oop.md) |
| record / 模式匹配 | [第 05 章](docs/05-records.md) |
| 泛型 / 扩展方法 | [第 06 章](docs/06-generics.md) |
| 委托 / lambda / 事件 | [第 07 章](docs/07-delegates.md) |
| 集合选型 | [第 08 章](docs/08-collections.md) |
| LINQ / 延迟执行 | [第 09 章](docs/09-linq.md) |
| 可空引用类型 | [第 10 章](docs/10-nullable.md) |
| 异常 / Result | [第 11 章](docs/11-errors.md) |
| 文件 / JSON | [第 12 章](docs/12-files-json.md) |
| async/await | [第 13 章](docs/13-async.md) |
| 并行 / Span | [第 14 章](docs/14-parallel.md) / [第 15 章](docs/15-span.md) |
| Web API / EF Core / 测试 | [第 16](docs/16-webapi.md) / [17](docs/17-efcore.md) / [18 章](docs/18-testing.md) |
| 跨平台 / 老平台支持 / Mono | [第 19 章](docs/19-portable.md) |
| 版本特性演进 | [第 20 章](docs/20-modern-csharp.md) |
| 正则 / GeneratedRegex | [第 21 章](docs/21-regex.md) |
| TCP·UDP / 字节序 / 分帧 | [第 22 章](docs/22-networking.md) |
| Process / P/Invoke / 反射 | [第 23 章](docs/23-interop.md) |
| 同步原语 / 管道 / FSW | [第 24 章](docs/24-sync.md) |

## 高频坑位速查

- [ ] 读写文件**不显式 `Encoding.UTF8`** → 中文乱码（[第 12 章](docs/12-files-json.md)）
- [ ] LINQ 查询**用两次没 ToList** → 重复计算/数据漂移（[第 09 章](docs/09-linq.md)）
- [ ] `async void` / `.Result` → 异常丢失 / 死锁（[第 13 章](docs/13-async.md)）
- [ ] 循环里逐个 await 该并发 → 慢 N 倍，先启动后 `Task.WhenAll`（[第 13 章](docs/13-async.md)）
- [ ] 并行循环里裸 `total++` → 丢更新，用 `Interlocked`（[第 14 章](docs/14-parallel.md)）
- [ ] record 里放可变 List，`with` 浅拷贝共享 → 幽灵修改（[第 05 章](docs/05-records.md)）
- [ ] JSON 字段名大小写不匹配 → 静默得 null（[第 12 章](docs/12-files-json.md)）
- [ ] EF `Add` 后忘 `SaveChanges` → 数据没进库（[第 17 章](docs/17-efcore.md)）
- [ ] 扩展方法点不出来 → 缺 `using System.Linq`（[第 06 章](docs/06-generics.md)）
- [ ] 硬编码 `\` 或 `/` 拼路径 → 跨平台炸，用 `Path.Combine`（[第 19 章](docs/19-portable.md)）
- [ ] 正则不设超时处理用户输入 → ReDoS 挂死（[第 21 章](docs/21-regex.md)）
- [ ] TCP 把流当消息读 → 粘包/半包，长度前缀分帧（[第 22 章](docs/22-networking.md)）
- [ ] 子进程先 WaitForExit 后读输出 → 死锁，先读后等（[第 23 章](docs/23-interop.md)）
- [ ] `lock(this)` / `lock("字符串")` → 用 `private readonly object`（[第 24 章](docs/24-sync.md)）

## 开发流程

- [ ] 每章：读讲解 → 跑示例 → 改代码再跑
- [ ] 新项目直接 .NET 10；老平台兼容需求先读[第 19 章](docs/19-portable.md)的支持矩阵
- [ ] 修 bug 先写复现测试（[第 18 章](docs/18-testing.md)）
- [ ] 性能优化先剖析再动手；热点路径才上 Span（[第 15 章](docs/15-span.md)）

## 部署（[第 19 章](docs/19-portable.md)）

- [ ] `dotnet publish -c Release -r <RID>`（win-x64 / linux-x64 / osx-arm64）
- [ ] 目标机免装运行时 → `--self-contained true`（注意运行时安全更新期限）
- [ ] 单文件分发 → `-p:PublishSingleFile=true`
