# 25 · 工具链深入：dtools 与生态

> 对应示例：`examples/25_dtools/`（程序内部分：符号修饰/反修饰、编译器内省）
> 本章大量"命令行工具"，**每节命令都在本机双平台（Win/Linux + DMD 2.113）实测**，输出为真实捕获。

## 25.1 dtools 是什么

随 DMD 发行的一小套命令行工具（dmd.org 安装包 `bin64/` 目录里那几个"不是 dmd"的可执行文件），加上 DUB 的工具面，再加上社区生态工具，构成本章地图：

| 层级 | 成员 | 作用 |
|---|---|---|
| **随 DMD 发行** | `rdmd` `ddemangle` `dustmite` | 脚本运行 / 读符号 / 最小化复现（**dtools 狭义**） |
| 随 DMD（Windows 限定） | `dman` | 离线查标准库文档 |
| 官方独立发行 | `dub` | 包管理 + 构建 + **通用工具启动器**（25.6） |
| 编译器自带"工具模式" | `-D` `-cov` `-H` `-X` `-Xi` | 文档 / 覆盖率 / 头文件 / JSON .di（23 章） |
| 社区生态 | dfmt、D-Scanner、serve-d、unit-threaded、reggae | 格式化 / lint / LSP / 测试增强 / 元构建 |

## 25.2 rdmd：D 脚本解释器（其实是缓存编译器）

"`.d` 文件直接当脚本跑"——shebang + 自动编译 + **结果缓存**（第二次起秒开）。

```bash
#!/usr/bin/env rdmd          # 文件头一行，chmod +x 后直接 ./hello.d
import std.stdio, std.algorithm, std.range;
void main() { 10.iota.filter!(n => n % 2 == 0).map!(n => n * n).writeln; }
```

```text
$ ./hello.d                  # 实测输出
[0, 4, 16, 36, 64]
$ rdmd --eval='writeln([1,2,3].sum);'     # 一行式（实测）
rdmd eval: 6
```

与 `dmd -run` 的差别：rdmd 把编译产物缓存在用户缓存目录（Linux `~/.cache/rdmd`，Windows `%LOCALAPPDATA%\rdmd`），**重复运行不重新编译**；适合常驻脚本。CI 里要最新编译时 `rdmd --force`。

## 25.3 ddemangle：读懂链接器在说什么

D 把完整类型签名编进符号名（模板实例尤甚），`nm`/链接错误里全是 `_D3std9algorithm...`。`ddemangle` 把管道里的修饰名**原地还原**——本机实测：

```text
$ nm hello.o | ddemangle | grep writeln
0000000000000000 W @safe void std.stdio.writeln!(
    std.algorithm.iteration.MapResult!(...))
```

程序内对应物是 `std.demangle.demangle` + `mangleof`（见 `25_dtools` 示例）：类符号得 `C4main6Parser` 这种 C 前缀形式、函数才 `_D` 开头、模板实例连推导属性（`pure nothrow @nogc @safe`）都编进名字。

> C++ 符号别喂它——`c++filt` 管那片。

## 25.4 dustmite：bug 复现自动瘦身器

手工缩 bug 复现工程（几百行 → 十行）是体力活；`dustmite <源码目录> <测试命令>` 自动做：**只要测试命令退出码 0 就持续删代码**，收敛到最小复现。本机完整实测：

```bash
mkdir -p src && cd src              # 一个 8 行小程序 + 检查脚本
cat > test.sh <<'EOF'
#!/bin/sh
dmd -run app.d 2>&1 | grep -q "result 242"
EOF
dustmite src ../test.sh
```

```text
Done in 102 tests and 18 secs and 513 ms; reduced version is in src.reduced
=== src.reduced/app.d ===
import std;
int compute(int x) { return x * 2; }
void main() {
    auto r = compute(21) + compute(100);
    writeln("result ", r);
}
```

`import std.stdio` 收敛成 `import std;`、无关 `writeln("start")` 被删掉，而测试仍然通过。上报编译器/库 bug 前必跑——维护者只看 5 行就能定位。

## 25.5 dman 与文档获取

- **`dman std.algorithm.sort`**：打印（Windows 版随包；**Linux 发行版与 dmd.org tarball 均未附带**，用在线 https://dlang.org/phobos 或 zeal 的 D docset 代替）。
- `dmd -D -o- source.d`：给自己工程生成 ddoc 文档（23 章）。
- 标准库源码就是文档：`/usr/include/dlang/dmd/std/*.d`（Linux）每个 public 函数都有 ddoc 头。

## 25.6 dub 的工具面：`dub run` 当"通用启动器"

21 章讲了 dub 管工程；这里讲它的另一面——**跑任何注册表上的 D 工具而不必正式安装**（首次编译后走全局缓存）：

```bash
dub run dfmt -- --inplace src/        # 官方格式化器（-- 后是该工具的参数）
dub run dscanner -- --styleCheck src/ # 静态检查
dub fetch unit-threaded && dub run unit-threaded # 增强测试库
```

CI/本地统一环境的标准姿势；dfmt 配置写 `dfmt.json`（`dub run dfmt -- --help` 查项）。

## 25.7 生态速览

| 工具 | 干什么 | 装法 |
|---|---|---|
| **dfmt** | 官方风格格式化（D 的 gofmt） | `dub run dfmt` |
| **D-Scanner** | lint + 符号大纲 + ddoc 静态站 | `dub run dscanner` |
| **serve-d** | 编辑器 LSP（VS Code / vim / emacs 的 D 插件后端） | 插件自带 |
| **unit-threaded** | 并行跑单测、属性测试 | `dub run unit-threaded` |
| **reggae** | 元构建系统（生成 ninja/make） | `dub run reggae` |

## 25.8 坑位清单

1. **dustmite 的测试命令相对源码目录解析**：`dustmite src test.sh` 会提示"try ../test.sh instead"——测试脚本对 src 内文件**以目录内路径**引用（`dmd -run app.d`），调用时写 `dustmite src ../test.sh`。
2. **dustmite 不弄脏原目录**：结果落在 `src.reduced/`，原 `src/` 原样保留（实测）——但别指向没备份的大目录，磁盘上两份。
3. **rdmd 缓存**在 `~/.cache/rdmd`：换了 dmd 版本记得 `--force` 或清目录，否则可能跑旧产物。
4. **类的 `mangleof` 不是 `_D` 开头**：是 `C4main6Parser` 式（C = class 类型标签）；函数/变量才 `_D` 开头（25_dtools 示例实测）。
5. **ddemangle 只管 D 符号**；混编 C++ 的输出要 `| c++filt` 另接一段。
6. **dman 只有 Windows 版随包**——Linux 查文档用 dlang.org/phobos 或装 zeal docset。

---
