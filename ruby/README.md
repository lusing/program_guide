# Ruby 编程指南（4.0）

面向**会编程、初学 Ruby** 的读者：从第一个 `puts` 一路教到 Ruby 4.0 的现代写法——`frozen_string_literal` 纪律、关键字参数分离后的参数族、`case/in` 模式匹配、Ractor 并行，旧写法只在坑位清单里教「认得」。**Ruby 特色全部独立成章细讲**：Enumerable 全家桶（11）、块与闭包（14）、元编程（15）、Ractor 真并行（21）、Fiber 协程（22）、Fiddle C 互操作（23）；收官实战是一个约 100 行的迷你 Markdown → HTML 渲染器（24）。每章末尾「坑位清单」收录 8–13 条实测坑（全书合计 275 条），速查见 [CHEATSheet.md](CHEATSheet.md)。

> 网上大量教程停留在 1.8/2.x 时代写法，在 4.0 上有静默差异或直接报错（`Fixnum` 已不存在、位置哈希塞给关键字参数抛 `ArgumentError`、gsub 块参数只剩 1 个、Ractor `.take` 已删除）。本书所有代码在 **Ruby 4.0.7** 实测（macOS x86_64-darwin23 与 Windows x64-mingw-ucrt 双平台）。

## 目录结构

```text
ruby/
├── README.md       本文件
├── docs/           24 章教程（01 → 24 顺序阅读）
├── examples/       23 个示例目录（02–24，章号 = 目录号；24 为综合收官）
├── run-all.sh      shell 入口（双入口之一，macOS/Linux）
├── build.ps1       PowerShell 入口（双入口之一，判定与 run-all.sh 逐条一致）
└── CHEATSheet.md   语法速查 + 4.0 实测坑位索引（275 条）
```

## 章节索引

| 章 | 主题 | 示例 |
|---|---|---|
| [01 全景](docs/01-overview.md) | Ruby 是什么、版本演进小史、全书约定与双层验证 | — |
| [02 第一个程序](docs/02-hello.md) | 输出三件套、插值/heredoc、ARGV 与 DATA、一切皆表达式 | `02_hello` |
| [03 数值类型](docs/03-numbers.md) | 整数无溢出、整除家族（商向负无穷）、Rational/Complex、转换两派 | `03_numbers` |
| [04 控制流](docs/04-control.md) | 真值语义、case/when 与 `===`、⭐case/in 模式匹配、for 的作用域坑 | `04_control` |
| [05 方法](docs/05-methods.md) | 参数全家桶、块/yield、Proc vs lambda、运算符即方法 | `05_methods` |
| [06 类与对象](docs/06-classes.md) | attr_*、可见性、Struct vs Data、相等性三件套、dup vs clone | `06_classes` |
| [07 模块](docs/07-modules.md) | include/extend/prepend、方法查找链、Comparable、to_s/inspect | `07_modules` |
| [08 字符串](docs/08-strings.md) | 编码与转码、冻结纪律、gsub/format、拼接性能 | `08_strings` |
| [09 数组](docs/09-arrays.md) | 索引与 fetch、增删家族、排序、共享引用陷阱 | `09_arrays` |
| [10 哈希与集合](docs/10-hashes.md) | 键相等性、默认值陷阱、fetch/dig、merge、Set | `10_hashes` |
| [11 ⭐Enumerable](docs/11-enumerable.md) | each 契约、变换/折叠/查找、Enumerator、lazy 无限流 | `11_enumerable` |
| [12 符号与正则](docs/12-symbols-regex.md) | Symbol 本质、MatchData、贪婪懒惰、锚点、4.0 gsub 变更 | `12_symbols_regex` |
| [13 异常](docs/13-exceptions.md) | 异常层级、四段式、raise 三形态、retry、ensure 陷阱 | `13_exceptions` |
| [14 块与闭包](docs/14-blocks.md) | 闭包绑定变量本身、curry、define_method、make_counter | `14_blocks` |
| [15 ⭐元编程](docs/15-metaprogramming.md) | send/method_missing、define_method、eval/binding、微 DSL | `15_metaprogramming` |
| [16 GC 与性能](docs/16-performance.md) | GC.stat 探针、+ vs <<、Struct vs OpenStruct、确定性纪律 | `16_performance` |
| [17 标准库精选](docs/17-stdlib.md) | JSON、date/time、set、forwardable、pathname、marshal | `17_stdlib` |
| [18 测试](docs/18-testing.md) | minitest 6 断言族、setup/teardown、Spec 风格、mock | `18_testing` |
| [19 文件与 IO](docs/19-files.md) | File/Dir/FileUtils、Pathname、tempfile、JSON 落盘 | `19_files` |
| [20 线程](docs/20-threads.md) | GVL、Queue 生产者消费者、Mutex、ConditionVariable | `20_threads` |
| [21 ⭐Ractor 并行](docs/21-ractors.md) | .value 收口、Port、shareable?、并行分治求和 | `21_ractors` |
| [22 ⭐Fiber 与协程](docs/22-fibers.md) | resume/yield 协议、Enumerator 本质、手写生成器 | `22_fibers` |
| [23 ⭐Fiddle C 互操作](docs/23-ffi.md) | 签名表、Pointer、Importer 结构体、Closure 回调 | `23_ffi` |
| [24 实战：迷你 Markdown 渲染器](docs/24-capstone.md) | 纯函数核心、块切分、转义管线、错误输入规则 | `24_capstone` |

## 构建工具链

- Ruby **4.0.7**：macOS 为 MacPorts `port install ruby40`（`/opt/local/bin/ruby4.0`）；Windows 为 RubyInstaller/scoop（`x64-mingw-ucrt`，PATH 上命令名 `ruby`）。`ruby --version` 为 4.x 的任意渠道均可。
- 两个验证入口都**自动定位**解释器，不硬编码路径——顺序为：环境变量 `RUBY` 显式指定 → PATH 上的 `ruby4.0`，其次 `ruby` → 常见安装位置（MacPorts `/opt/local/bin`、Homebrew `/opt/homebrew/bin`、`/usr/local/bin`；Windows 另查 `%LOCALAPPDATA%\Programs\Ruby*`、`C:\Ruby*`）。
- **刻意不用本机 `/opt/local/bin/ruby1.8`（1.8.7）**，理由三条：缺现代语法的关键部分（无编码系统、无 `frozen_string_literal`、关键字参数语义完全不同，示例大多直接报错）；2011 年就停止维护；留着的唯一用途是**演进史参照**（01 章的版本演进小史）。想看化石，`docs/01-overview.md` 里有几行 ruby1.8 实测探针。
- 每示例含 `main.rb`（`sec` 分节演示 + `ok` 断言自检 + 结束标记）与 `runtests.rb`（独立 minitest 套件）。

## 验证命令

```bash
cd ruby
./run-all.sh              # shell 入口：全部 23 个示例（运行层 + 测试层）
./run-all.sh -v 03        # 附带指定示例的完整输出
./run-all.sh 13 21        # 只跑指定编号（或目录名，如 09_arrays）
# Windows 上用 Git Bash 跑同一入口：bash run-all.sh（判定逻辑与 POSIX 完全一致）
```

```powershell
cd ruby
pwsh -ExecutionPolicy Bypass -File build.ps1 -All                # PowerShell 入口，等价
pwsh -ExecutionPolicy Bypass -File build.ps1 -Example 09_arrays  # 单个示例
```

两层验证：**运行层**（`ruby main.rb`，六条判定：退出码 0、stderr 为空、stdout 非空、无多余控制字符、含 `==== NN 结束 ====` 标记、无 Ruby 诊断字样）→ **测试层**（`ruby runtests.rb` 的独立 minitest 套件 → exit 0）。两层全绿才算通过，两个入口共用同一套判定标准。

单跑某个示例（每章标准学法）——改代码后重跑：

```bash
cd ruby/examples/09_arrays
ruby main.rb && ruby runtests.rb    # 改完立刻看效果
```

**输出确定性纪律**：示例不打印耗时、随机值与机器路径（时间演示用 `Time.at(0).utc` 固定基准、线程/Ractor 结果 join 后按固定顺序汇总、临时文件用 `Dir.mktmpdir` 且不打印随机路径）——本书各章引用的实测输出都来自 `build/` 快照，与你自己跑出来的结果逐字节一致；不一致先查 `ruby -v`。

## 兼容性与实测坑（Ruby 4.0.7 / macOS + Windows）

前十条是网上旧教程搬到 4.0 上最容易翻车的语言坑，11–13 是双平台校验实测的平台差异，全部在各章坑位清单里有出处：

1. **chilled strings 告警**：没写 `# frozen_string_literal: true` 的文件里裸改字符串字面量（`s << "x"`）照常执行，但 stderr 打出 `warning: literal string will be frozen in the future...`——本书示例全带魔法注释，可变副本用 `+"abc"` 或 `.dup`（01.3、02.8）。
2. **`case/in` 不能单行**：`case 1 in String then :s end` 是语法错误，`in` 前必须换行；而 `case/when` 的单行形式反而合法——Prism 下实测，两者别记反（4.6）。
3. **gsub 块只收 1 个参数**：旧教程「块参数个数 = 捕获组数 + 1」在 4.0 已不成立，写成 `|whole, g1|` 拿到一串 nil 且不报错——捕获组用 `$~`/`$1` 取；gsub 第二参收 Symbol 的旧写法也已移除，字符替换用 `tr`（12.6）。
4. **Ractor 三连**：`.take` 已删除（取值一律 `.value`）；实验告警默认打 stderr（`Warning[:experimental] = false` 必须在第一行代码）；块里引用外层局部变量是**编译期** `ArgumentError`，数据只能走参数/消息/可共享常量（21 章）。
5. **minitest 6 三变化**：裸 `must_equal` 被移除（必须 `value(x)`/`_(x)` 包装）；测试方法默认乱序执行（`test_order =` 配置已移除）；`minitest/mock` 拆成独立 gem（`require` 抛 `LoadError`）（18 章）。
6. **`Time#utc` 是原地修改**：调用后原对象自身变成 UTC，返回值还是它自己——要新对象用 `getutc`（17.2）。
7. **ensure 里 `return` 吞异常**：正在传播的异常凭空消失，方法安静返回 ensure 的值——ensure 只做清理，不做流程控制（13.7）。
8. **`Hash.new([])` 共享同一个默认对象**：`h[:a] << 1` 改的是共享对象且键没存进去（`key?` 为 false）——可变默认值必须用默认块 `Hash.new { |h, k| h[k] = [] }`，与 `Array.new(3, [])` 同源（10.3、9.7）。
9. **商向负无穷、余数跟除数同号**：`7 / -2 == -4`、`-7 % 3 == 2`——从 C/Java 移植整除/取模逻辑必错（3.5）。
10. **`1` 与 `1.0` 不是同一个 Hash 键**：`1 == 1.0` 为真但 `1.eql?(1.0)` 为假（4.0.7 实测），Hash 按 `eql?` 判键（6.6、10.6）。

Windows（`x64-mingw-ucrt`，4.0.7）双平台校验实测出的三条平台差异，示例已内置分支/规避，各章坑位清单有详解：

11. **`sort` 平局顺序平台相关**：同款降序比较器，92 分平局 macOS 出 `tom`、Windows 出 `anna`——比较器没写平局裁决就别断言具体元素（11.8、11.9 #10）。
12. **Ractor × minitest 并行线程池死锁**：minitest 6 默认起与核数等大的空闲线程池，池 ≥2 时主线程 `Ractor#value` 丢唤醒永久阻塞（另一线程定时器到期才能「撞醒」）；`require "minitest/autorun"` 前 `ENV["MT_CPU"] = "1"` 十连绿，macOS 不受影响（21.9 #13）。
13. **Fiddle 进程句柄在 Windows 解析不到 libc 符号**：`unknown symbol "sqrt"`——C 运行时在 `ucrtbase.dll`，`Fiddle.dlopen(Gem.win_platform? ? "ucrtbase" : nil)` 一行跨三平台（23.8 #1）。

## 当前状态

- **23/23 示例 × 2 入口全绿（Ruby 4.0.7 / macOS）**：`./run-all.sh` 与 `pwsh ./build.ps1 -All` 均通过（运行层六条判定 + minitest 测试层，两层全绿）。
- **23/23 示例 × 2 入口全绿（Ruby 4.0.7 / Windows 11，x64-mingw-ucrt）**：Git Bash `bash run-all.sh` 与 `pwsh ./build.ps1 -All` 均通过；三处平台差异（sort 平局、Ractor×minitest、Fiddle 句柄）已修复并记入坑位清单。
- 速查与坑位索引见 [CHEATSheet.md](CHEATSheet.md)（语法速查 + 275 条实测坑位索引，条目数与各章坑位清单逐一对应）。

## 相关教程

同仓库其他语言教程风格一致，可交叉阅读：[julia](../julia/README.md)、[dart](../dart/README.md)、[go](../go/README.md) 等（各教程目录树平级）。
