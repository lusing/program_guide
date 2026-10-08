# 37 · FileGuard：快照式文件完整性监护器

十大实战缺口的收官章，取材《Learning Zig》第 13 章"Real-World Zig"的 FileGuard 项目。先划清与既有章节的分工：**27 章**教你遍历目录，**28 章**的 zwatch 是"监视器"——时间维度上轮询等事件，变更只有 created/modified/removed 三类；本章的 FileGuard 是"**完整性台账**"——空间维度上一次全量扫描建出带**内容哈希**和 **inode** 的清册，两份清册求差。这个架构能给出 28 章给不出的东西：**moved 检测**（"A 移到 B"与"删 A 建 B"是两种信息量完全不同的事件），以及**同尺寸暗改检测**（size/mtime 都没变、只有哈希抓得到的篡改）。原书点名的应用场景：DevOps 配置漂移检测、安全团队监控关键系统文件、CI 跟踪源码变更。

原书实现是 8 文件工程，代码针对 Zig 0.14，且有两处真问题（下面逐节点名）。本章按 0.17.0 实测重写为单文件六节（`examples/37_fileguard/main.zig`，7 个 test + 自导自演演示），原书的架构思想全部保留并讲透。

## 37.0 架构决策：四块基石

原书的四个设计决策是全章的灵魂，先讲清"为什么"再上代码：

1. **两阶段求差，不碰 OS 事件 API**。inotify/kqueue/ReadDirectoryChangesW 三平台能力与边界各异（网络盘、高频变更各有坑，28 章实测 Windows 那套要手写 extern）。周期扫描 + 智能求差跨平台一致、易懂易调试。代价是实时性，换来的是可移植性与**可测试性**——求差是纯函数，tmpDir 里就能测。
2. **inode 跟踪做移动检测**。Unix inode / Windows file ID 在 rename/move 后不变。"A 处消失 + B 处出现**同 inode**"⇒ moved，免内容比对。用文件系统自己的唯一 ID，比内容比对快且可靠。
3. **可选内容哈希，默认关**。开了能抓 size 不变的暗改，但磁盘 I/O 立刻成为主要代价——"速度 vs 彻底"的权衡交给用户，是一个 `--hash` 开关。
4. **glob 模式过滤，exclude 优先**。include/exclude 两组模式，exclude 先查——保镖先看黑名单再看普通名单。

资源画像也要有数：内存随文件数线性增长；CPU 空闲近零、扫描时短暂活跃；开哈希后**磁盘 I/O 是主要代价**。

## 37.1 FileMetadata：一个文件的身份证

```zig
const Metadata = struct {
    path: []const u8,     // 借用 map key 的内存，自己绝不 free
    size: u64,
    mtime_ns: i96,        // Io.Timestamp.nanoseconds
    inode: i64,           // ⚠️ 0.17 实测 stat.inode 是 i64，不是 u64
    checksum: ?[32]u8,    // 不开哈希就是 null
};
```

三个设计点：

- **path 不归 Metadata 管**。原书让 FileMetadata 持有分配器、自己 free path，还要专门写 `clone()` 深拷贝。本章把所有权收拢到 FileIndex 的 map key 上（37.3），Metadata 退化成纯值——**所有权单点化**之后，clone/deinit/errdefer 那套样板整个消失。这是相对原书最重要的简化。
- **inode 的类型与哨兵**。0.17 的 `statFile` 返回里 `inode` 是 `i64`（探针实测 `inode=5910974510954966`，Windows 上 std 用 NTFS file index 合成）。`0` 是"无有效 inode"哨兵：拿不到有效 inode 的文件不进 inode 索引（37.3 的 `add` 里那个 `if`），move 检测自然跳过它。
- **checksum 是可选值而不是空串**。`null` 明确表达"没开哈希"，`modifiedReason`（37.5）里"两边都有哈希才比内容"的优先级链就靠它守卫。

### 流式哈希：4KB 缓冲吃下任意大的文件

原书特别强调：哈希 10GB 文件不能先读进内存。`hashFile`（示例 37.1）用 20 章的 `File.Reader` 三件套写流式喂哈希：

```zig
while (true) {
    if (r.bufferedLen() > 0) {
        h.update(r.buffered());
        r.tossBuffered();
        continue;
    }
    r.fillMore() catch |err| switch (err) {
        error.EndOfStream => break,
        else => return err,
    };
}
```

这个循环的顺序是契约：`fillMore` 返回 `EndOfStream` 时缓冲里可能还有最后一批数据（std 文档明说"刚好读到 0 字节才算流结束"），所以**先把 buffered 榨干，再要新的**。先 fillMore 后检查会丢尾巴。SHA-256 在 0.17 是 `std.crypto.hash.sha2.Sha256`，`init`/`update`/`final` 三段式；一次性写法是 `hash(data, &out, .{})`——⚠️ 签名是**三参**（输出缓冲区是第二参），照抄旧书的两参写法编译就拒。

## 37.2 手写 glob：20 行换掉 fnmatch

原书的 `pattern.zig` 包 C 的 `fnmatch`，有两个真问题——这是原书代码里值得点名的 bug 级瑕疵：

1. **`@ptrCast(pattern.ptr)` 把切片当 C 字符串传**：Zig 切片不带 NUL 终止，fnmatch 越界读，是 UB；
2. **fnmatch 是 POSIX 专属**，Windows 上根本没有这个头文件——一本讲"跨平台抽象之美"的书，在模式匹配上恰恰不跨平台。

手写递归匹配器（示例 37.2）让三个问题一起消失：

```zig
fn globMatch(pattern: []const u8, name: []const u8) bool {
    if (pattern.len == 0) return name.len == 0;
    switch (pattern[0]) {
        '*' => { /* 先试匹配 0 个，再逐个多吃 */ },
        '?' => return name.len > 0 and globMatch(pattern[1..], name[1..]),
        else => /* 字面字符逐个对 */,
    }
}
```

`*` 分支是唯一的非平凡处：递归地尝试"`*` 匹配 0 个字符、1 个、2 个……"，任一成功即整体成功——朴素的指数级最坏情况，但 glob 模式短、文件名短，完全够用（生产级换迭代+回溯指针，思想相同）。只支持 `*` 与 `?`、对 **basename** 匹配（不含目录），这是有意收窄：fnmatch 的全语法（`[...]` 字符类、FNM_PATHNAME）对"监控哪些文件"是过度武装。测试（37.2 glob 匹配）钉住了 8 个用例，包括 `*.zig` 不能匹配 `main.zig.bak` 这种边界。

`shouldInclude` 一句话规则：**exclude 命中直接拒，否则需命中任一 include**。默认 include 是 `&.{"*"}`——全收。

## 37.3 FileIndex：双索引清册

```zig
const FileIndex = struct {
    files: std.StringHashMap(Metadata),      // path → 元数据
    inodes: std.AutoHashMap(i64, []const u8), // inode → path（借用 files 的 key）
};
```

**为什么双索引**（原书核心设问）：path 索引答"这条路径下的文件现在什么样"；inode 索引答"这个 inode 现在挂在哪条路径下"。第一遍求差时发现 `util.zig` 消失，拿它的 inode 问第二张表"这个 inode 现在叫什么"，答出 `lib.zig`——moved 成立。没有第二张表，这个问题要 O(n²) 地逐对比对。

### 内存所有权：一张 key 养三张引用

原书为路径内存专设**第三张表** `path_storage: StringHashMap(void)` 当分配台账（12.7 的坑：`StringHashMap` 的 key 是借用的，不好"只遍历 key 来释放"），原书称之为"一点额外记账换干净的内存管理"。本章用更省的一招达到同一目的：

- `add()` 里 `a.dupe(u8, path)` **一次**，这份内存同时是：`files` 的 key、`Metadata.path` 的值、`inodes` 的 value——**一份内存，三处借用，唯一主人是 files 的 key**；
- `deinit()` 顺序即纪律：先 `inodes.deinit()`（它借 key，先死）→ 遍历 `files.keyIterator()` 逐个 `free` → 最后 `files.deinit()`。顺序反了就是悬垂或泄漏。

台账表与单主 key 是同一思想的两种实现；36.7 的 `HashMap(K, void)` 正是原书台账的写法，两种都认得，读别人的代码不懵。

`add` 里还有一处细节：`errdefer a.free(owned)` 之后 `files.put` 再 `inodes.put`——第二个 put 失败时 owned 已由 files 表持有吗？没有：errdefer 覆盖整个函数，任何一步失败都释放。这是 10 章"条数 = 已获取资源数"的回滚纪律。

## 37.4 遍历：max_depth 需要自己写递归

27 章有现成的 `walk()`，为什么 FileGuard 手写递归（`traverse`，示例 37.4）？因为 `walk` 不给**深度上限**这个旋钮，而递归遍历的爆栈风险需要 `max_depth` 兜底（原书决策四件套之一）。

每轮 `entry` 的处理流程：拼相对路径（`std.fs.path.join`，`defer a.free`）→ `switch (entry.kind)`：

- `.file`：先 `shouldInclude` 过滤（**遍历期就过滤**——不给不监控的文件建元数据，这是原书性能四件套之一），过了才 `statFile` + 可选 `hashFile`，`ix.add` 入册；
- `.directory`：深度未超限就递归，depth+1；
- 其余（**含符号链接**）：跳过。

符号链接默认不跟，理由原书讲得很透：跟随有两大已知危险——成环（A→B→C→A）与同一文件经多条路径重复入索引。原书选择"可选跟随、接受重复"，本章取更保守的默认（连选项都不给），把"要不要跟链接"留给读者当扩展题——真要做，正解是**用 inode 集合记录已访问目标**，双索引现成的。

⚠️ 27 章老坑依然蹲在这里：`entry.name` 活不过下一次 `next()`。代码里 `rel` 是立刻 dupe/join 出来的自有内存，`statFile`/`hashFile`/`ix.add` 全部在本轮内用完，安全。

## 37.5 变更检测：两遍扫描

```zig
const ChangeKind = enum { created, deleted, modified, moved };
const ModifiedReason = enum { content, size, mtime };
```

主算法 `detectChanges(old, new, journal)` 严格按原书两遍扫描：

**第一遍（在 old 里找 deleted/moved）**：路径在新清册里还在 → 跳过；不在 → 拿 inode 问新清册的 inode 表，命中 ⇒ `.moved`（old_path→new_path），否则 ⇒ `.deleted`。

**第二遍（在 new 里找 created/modified）**：路径在老清册里就有 → 交给 `modifiedReason` 查修改；没有 → 先查"它是不是某个 moved 的目的地"（老清册 inode 表命中 ⇒ 第一遍已记过，跳过），都不是 ⇒ `.created`。

两遍的衔接就靠那两次 inode 反查：**第一遍认领 moved 的旧名，第二遍靠 inode 认出新名已有主**——少任何一次反查，moved 都会退化成 delete+create 两条。

### modifiedReason 的优先级链

命中即停，最硬的证据先说：

1. **content**（两边都有哈希且不等）→ 暗改实锤；
2. **size**（不等）→ 内容必变，不需要哈希也知道；
3. **mtime**（不等）→ 最弱信号：可能只是被 touch 了一下，内容没动。

测试"同尺寸暗改只有哈希抓得到"演示了这条链的价值：`aaaa` 换成 `bbbb`，size 一样；不开哈希时只能靠 mtime 赌运气（mtime 若在文件系统精度内撞车就完全隐形），开哈希后检出 `reason=content`。

### Journal：报告拥有它打印的每个字

求差之后旧索引就销毁换血——所以 `FileChange` 里的路径字符串**必须自有**（`Journal.add` 里 dupe，deinit 里逐个 free）。借旧索引的 key 就是悬空，28 章的事件名是同一纪律。`print()` 按种类格式化输出，演示里长这样：

```
第二轮扫描检出 4 条变更：
  [MOVED]   ...\src\util.zig -> ...\src\lib.zig
  [DELETED] ...\src\main.zig
  [MODIFIED] ...\README.md（content）
  [CREATED] ...\docs.zig
```

## 37.6 CLI 与监护循环

### 手写参数解析（顺带两个 0.17 实测坑）

原书引第三方库 `zig-args`，本章按教程惯例手写（22 章范式），`--hash` / `--max-depth=N` / `--include=PAT` / `--exclude=PAT` / `--help`。实测踩到两个坑，都是 Windows 上参数处理的活教材：

- **⚠️ `args.iterate()` 在 Windows 是编译错误**：`@compileError("In Windows, use initAllocator instead.")`——WTF-16 → WTF-8 转码需要缓冲，跨平台代码必须 `init.minimal.args.iterateAllocator(a)` 且用完 `deinit()`。
- **⚠️ 迭代器返回的切片指向内部缓冲，`deinit()` 后全部悬空**。第一版 `opt.path = s` 直接借，parseArgs 返回后 buffer 已释放，再拿去 openDir 报 `error.BadPathName`（InvalidWtf8）——内存被复用后连编码都坏了。修法：落进 Options 的一律 `a.dupe`。另外 `args.vector` 在 Windows 上**不是 argv 数组**而是整条命令行的 `[]const u16`（实测 len 是字符数），数参数个数要靠迭代，示例用 `seen_any` 标志。

### 单次扫描与监护循环

CLI 模式（带参数运行）是 `runOnce`：建一份清册、打印统计——这是监护循环的"建 baseline"那一半。main 的无参模式则在 `/tmp` 沙盒里**自导自演完整监护循环**：布景四个文件 → baseline（`build.log` 被 include 过滤，入册 3 个）→ 四种破坏各来一份（rename、同尺寸换内容、删除、新建）→ 二轮扫描求差 → 打印上面那四条变更 → 换血收尾（`baseline.deinit` 后 `baseline = current`——循环里就是这一句）。

真实部署把沙盒换成目标目录、把"搞破坏"换成 `Io.Clock.sleep` 等待，就是原书的 continuous 模式。原书还有一条错误韧性纪律值得带走：**continuous 模式下某轮遍历失败只警告、继续等下轮**，单次模式才直接返回错误——监控器的使命是"一直在场"，一次瞬态错误（目录被临时锁住）不该把它打趴。

### ⚠️ 自己的工程目录要加 exclude

拿示例程序扫本仓库的 `examples/35_zls`（开哈希）：入册 **28** 个文件——`.zig-cache` 全家都在。生产使用务必 `--exclude` 掉 `.zig-cache`、`zig-out`、`.git` 这类目录，否则报告全是噪音（原书的"专业化清单"第一条就是变更过滤）。glob 目前只匹配 basename，排除目录需要 `exclude` 命中目录名时整枝剪掉——这是留给读者的第一个扩展题。

## 37.7 扩展方向与原书的项目点子

原书章末给了 FileGuard 的专业化路线和其他项目点子，择其有价值者：

- **FileGuard 进阶**：JSON/CSV 机器可读输出（接 jq 进 CI）；变更写日志文件；变更触发自定义命令（配置改了就 reload）；目录级 exclude（上面那道题）；符号链接跟随 + inode 去重。
- **同样量级、同样练"系统编程全身肌肉"的项目**（原书十个点子里最值的五个）：日志切片分析器（24 章 minigrep 的表哥）、文件变更自动重启的 dev server（37 章 + 22 章子进程）、目录同步器/简化 rsync（37 章双清册 + 20 章写文件）、配置校验器（13/14 章 comptime 反射的用武之地）、构建产物清理器（27 章遍历 + 磁盘用量统计）。
- **社区在哪儿**：Zig Discord（最活跃）、Ziggit 论坛（长讨论）、GitHub 主仓库。原书出版时的"roadmap"里，自托管编译器与 std.Io 异步 I/O 已经兑现——0.17 的 Build Server Protocol（35 章）正是下一个。

## 37.8 坑位清单

1. `stat.inode` 在 0.17 是 **i64**；`inode == 0` 当哨兵，无有效 inode 的文件不进 inode 索引。
2. `Sha256.hash` 一次性写法是**三参**（`hash(data, &out, .{})`）；流式是 `init/update/final`。流式循环**先榨干 buffered 再 fillMore**——EndOfStream 时缓冲里可能还有最后一批。
3. 原书 fnmatch 路线有两个真问题：切片 `@ptrCast` 当 C 字符串是 UB；fnmatch 是 POSIX 专属。手写 glob 20 行，跨平台且零 UB。
4. `StringHashMap` key 借用不拥有（12.7）：路径内存要么台账表、要么单主 key，**deinit 先死借用方、再 free 主人、最后拆柜子**。
5. `entry.name` 活不过下一次 `next()`（27 章）——本轮内 dupe 或用完。
6. `walk()` 没有深度上限；要 `max_depth` 就手写递归。
7. Windows 参数：`iterate()` 编译错误，必须 `iterateAllocator` + `deinit`；迭代器切片随 deinit 悬空，落配置一律 dupe；`args.vector` 是 WTF-16 整条命令行，不是 argv。
8. `writeFile` 不建中间目录，先 `createDirPath`（自导自演的沙盒里实测踩到）。
9. 哈希默认关、遍历期就过滤、`max_depth` 兜底——性能与安全的三件套都是配置项，不是事后优化。
10. continuous 模式的纪律：单轮失败只警告不退出；baseline 换血在**求差完成之后**（求差要用旧清册）。

---

上一章：[36 指针与内存深水区](36-pointers.md)
