# 16 · 构建系统与包管理 ⭐

> 对应示例：`examples/16_build/`（build.zig 工程）
>
> 构建脚本是一门全功能语言——没有 CMake DSL、没有 Makefile 语法，就是 Zig。

## 16.1 工程解剖：zig init 的三件套

```bash
zig init    # 生成骨架，本章示例就是它改的
```

```text
16_build/
├── build.zig       构建描述（Zig 代码）
├── build.zig.zon    包清单（依赖与元数据）
└── src/
    ├── main.zig     入口（main）
    └── greet.zig    被相对导入的模块
```

**build.zig 不是脚本，是描述**：`pub fn build(b: *std.Build) void` 在构建前运行，往 `b` 里登记"要做什么"（构建图），外部 runner 按依赖并行执行、全量缓存。理解这个"描述先于执行"的模型，build.zig 的写法就不再神秘。

## 16.2 build.zig 逐段读（本教程模板）

```zig
pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});     // -Dtarget
    const optimize = b.standardOptimizeOption(.{});  // -Doptimize

    const exe = b.addExecutable(.{
        .name = "16_build",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });
    b.installArtifact(exe);                          // 装到 zig-out/

    const run_cmd = b.addRunArtifact(exe);           // "跑这个产物"的步骤
    run_cmd.step.dependOn(b.getInstallStep());       // 先装再跑
    if (b.args) |args| run_cmd.addArgs(args);        // -- 后的参数透传
    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    const unit_tests = b.addTest(.{ .root_module = b.createModule(.{ ... }) });
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&b.addRunArtifact(unit_tests).step);
}
```

三对概念：**module**（源文件集合+编译选项，`createModule` 是匿名模块）→ **artifact**（可执行/库产物，`addExecutable/addTest`）→ **step**（命名任务，`zig build <name>` 触发）。依赖关系用 `dependOn` 串成图——run 依赖 install，test 独立并行。

## 16.3 命令行约定

```bash
zig build                     # 默认 step（install）
zig build run                 # 跑起来
zig build run -- greet.txt    # -- 之后是给程序的参数
zig build test                # 跑测试
zig build -Doptimize=ReleaseFast run
zig build -Dtarget=aarch64-linux   # 交叉编译白送（18 章）
zig build --help              # 列出全部 step 和选项
```

## 16.4 build.zig.zon：包清单

```zig
.{
    .name = .build16,             // 包名（必须是合法标识符，不能数字开头！）
    .version = "0.1.0",
    .fingerprint = 0x7941b290a7f6b461,  // 包指纹：与名字绑定，新包由编译器提示
    .minimum_zig_version = "0.16.0",
    .paths = .{ "build.zig", "build.zig.zon", "src" },  // 进包哈希的文件集
}
```

zon 是 Zig 的数据格式（就是 Zig 语法本身）。**fingerprint 是全局包身份**：首次写 `0x0` 跑一次构建，编译器直接把正确值打在错误里，抄进去即可。`paths` 决定"发布包里有什么"——只列编译必需文件（整个 `src` 目录可以一行写全）。

## 16.5 依赖：本地路径版（实测通过）

消费端 zon 声明依赖：

```zig
// app/build.zig.zon
.dependencies = .{
    .mylib = .{ .path = "../mylib" },   // 本地路径依赖（url+hash 的亲兄弟）
},
```

被依赖方 build.zig 必须**暴露模块**：

```zig
// mylib/build.zig
pub fn build(b: *std.Build) void {
    _ = b.addModule("mylib", .{          // 对外暴露名为 mylib 的模块
        .root_source_file = b.path("mylib.zig"),
        .target = b.graph.host,
    });
}
```

消费端 build.zig 接线：

```zig
const mylib = b.dependency("mylib", .{});       // 取依赖（参数是传给它的 -D 选项）
const exe = b.addExecutable(.{ ..., .root_module = b.createModule(.{
    ...,
    .imports = &.{
        .{ .name = "mylib", .module = mylib.module("mylib") },  // 挂进 import 表
    },
}) });
```

源码里 `const mylib = @import("mylib");` 直接用。**关键认知：依赖默认只是"拿到了"，必须 addModule + imports 接线才会被链接进来**——这是"声明"和"使用"分离的设计。

## 16.6 远程依赖：zig fetch

```bash
zig fetch --save git+https://github.com/.../#<commit-hash>   # 拉取并写进 zon
zig build --fetch                                            # 只拉依赖不构建
```

远程依赖是 `url + hash`（multihash 格式）——**hash 是事实，url 只是镜像**：内容变了构建直接失败（供应链投毒的闸门）。包索引见 [ziglibs / astrolabe.pm 等社区源]，官方明确不做中心化 registry。全部依赖落进全局缓存后，**构建不再需要网络**。

## 16.7 缓存与产物

```text
.zig-cache/     增量缓存（删了就全量重建，别提交进 git）
zig-out/        安装产物（bin/ 下）
```

构建按内容哈希缓存——改注释可能不触发重编（产物没变），怀疑缓存不对劲用 `zig build --cacheless` 一把梭。`.gitignore` 里这两个目录该被忽略（本仓库已配）。

## 16.8 坑位清单

1. **包名不能数字开头**：`@"16_build"` 也不行（zon 校验裸标识符）——`16_build` 工程的包名叫 `.build16`。
2. **fingerprint 与包名绑定**：抄别包的指纹直接报 invalid，按错误提示的值替换即可；改了包名要重新生成指纹。
3. **依赖声明了却"找不到"**：`b.dependency` 拿到的是包，还要 `mylib.module("mylib")` 且被依赖方 `addModule` 暴露——三层少一层都 panic（实测踩满）。
4. **给依赖传不存在的 -D 选项**：`b.dependency("x", .{ .optimize = ... })` 而 x 的 build.zig 没声明该选项 → "invalid option"——依赖的选项是它自己 build.zig 决定的。
5. **`zig build run -- args` 忘 `--`**：参数被 zig build 自己吃了，程序拿不到。
6. **改了依赖没生效**：路径依赖默认也有缓存，`zig build --fetch` 或动一下 zon 触发重解析。

---

上一章：[15 测试](15-testing.md) · 下一章：[17 C 互操作](17-c-interop.md)
