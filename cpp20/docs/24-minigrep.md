# 24 · 实战：迷你 grep

> 对应示例：`examples/24_minigrep/`（search.h / search.cpp / output.h / output.cpp / main.cpp 五文件）

## 24.1 成品与用法

```text
用法: minigrep <dir> <pattern> [-i] [-t N]
  <dir>      递归搜索的目录
  <pattern>  搜索的文本
  -i         忽略大小写
  -t N       线程数（默认 4）
```

真实跑一把（在 cpp20 目录下）：

```text
$ ./build/24_minigrep.exe examples/24_minigrep warning -i
examples/24_minigrep\main.cpp:53:  "warning: disk almost full\n"    ← 命中段红色高亮
examples/24_minigrep\main.cpp:54:  "another WARNING here\n"
……
共 6 处命中
```

（以上是 Windows 上的样子：可执行文件带 `.exe`，`std::filesystem` 打出来的路径分隔符是 `\`。
macOS / Linux 上写成 `./build/24_minigrep examples/24_minigrep warning -i`，分隔符显示为 `/`，
**命中数与行号完全一致** —— 两个入口都验过。）

这是全教程的收官项目：递归遍历（第 22 章）、多线程（第 19–20 章）、多文件工程组织（第 18 章）、自检（第 23 章）全部落进一个 200 行的真实工具。**无参数运行时它跑内置自检**——这就是 build.ps1 能把它纳入三层验证的原因。

## 24.2 多文件组织：接口先行

单文件教程到此为止——真实工具按**层**拆分，每层一个接口（.h）加实现（.cpp）：

```text
24_minigrep/
├── search.h     搜索层接口：Match 结构 + 三个函数声明
├── search.cpp   搜索层实现：纯逻辑，零输出
├── output.h     输出层接口：print_match 声明
├── output.cpp   输出层实现：高亮打印
└── main.cpp     组装：参数解析、自检、线程编排
```

分层的判据是**变化方向**：搜索逻辑（怎么找）与输出格式（怎么显示）各自独立变化——将来加"输出成 JSON"不动 search.cpp，加"正则模式"不动 output.cpp。头文件就是第 18 章的声明快递包：main.cpp `#include "search.h"` 拿到签名即可调用，实现由链接器缝合（build.ps1 已自动编译目录下全部 .cpp）。

## 24.3 搜索层：纯逻辑的地盘

```cpp
struct Match {
    int line_no;
    std::string text;
};

std::size_t find_in_line(std::string_view line, std::string_view pattern, bool ignore_case);
std::vector<Match> search_text(std::string_view content, std::string_view pattern, bool ignore_case);
std::vector<Match> search_file(const std::filesystem::path& file, std::string_view pattern, bool ignore_case);
```

三个函数各管一层粒度，**全部基于 string_view/span 心智**（第 06 章）：`find_in_line` 找 pattern 在行内的位置（大小写折叠用 `tolower` 对比 `equal_ic`，注意 `unsigned char` 转换——第 22 章的守则）；`search_text` 把内容按 `\n` 切行、逐行调 find（**吃 string_view 吐 vector<Match>，纯函数**——第 23 章的可测性原理）；`search_file` 加 IO 外壳（ifstream 打不开返回空——权限、占用都当"跳过"）。

**为什么不用 std::regex**：朴素双指针匹配对"字面量子串"比正则引擎快一个量级且零构造开销——第 22 章性能结论的实战应用。文件读取用 `buffer << in.rdbuf()` 整读（第 22 章惯用法），一次 IO 换掉逐行 getline 的循环。

## 24.4 输出层：把显示格式关进一个文件

```cpp
void print_match(const std::filesystem::path& file, const Match& match,
                 std::string_view pattern, bool ignore_case) {
    std::println("{}:{}:{}{}{}{}{}",
                 file.string(), match.line_no,
                 std::string_view{match.text}.substr(0, pos),
                 kRed,                                            // \033[31;1m
                 std::string_view{match.text}.substr(pos, pattern.size()),
                 kReset,                                          // \033[0m
                 std::string_view{match.text}.substr(pos + pattern.size()));
}
```

输出格式对齐真 grep 的惯例 **`file:line:text`**（编辑器能点击跳转的那种）；命中段用 ANSI 转义（`\033[31;1m` 红 + `\033[0m` 复位）高亮——终端能力，pwsh 7/Windows Terminal 都认。实现里复用 search 层的 `find_in_line` 定位命中点——**分层不是复制代码，是把能力放在唯一的地方**。

## 24.5 参数解析与退出码

```cpp
Options parse_args(int argc, char** argv) {
    if (argc < 3) {
        std::println("用法: minigrep <dir> <pattern> [-i] [-t N]");
        std::exit(2);
    }
    Options opt;
    opt.dir = argv[1];
    opt.pattern = argv[2];
    for (int i = 3; i < argc; ++i) {
        std::string arg = argv[i];
        if (arg == "-i") { opt.ignore_case = true; }
        else if (arg == "-t" && i + 1 < argc) { opt.threads = std::max(1, std::stoi(argv[++i])); }
    }
    return opt;
}
```

手写 argv 循环对三个参数绰绰有余（真工具会选 CLI11/ctre 一类库——第 23 章生态观的呼应）。**退出码的行规**值得较真：0=成功、2=用法错误（本示例统一 0 是教学简化）；真 grep 是 0=有命中、1=无命中、2=出错——shell 脚本按码分支（`grep -q pat && ...`），退出码是 CLI 工具的 API。

## 24.6 自检模式：可验证的示例

```cpp
void run_self_test() {
    fs::path dir = fs::temp_directory_path() / "minigrep_selftest";
    fs::remove_all(dir);
    fs::create_directories(dir);
    {
        std::ofstream{dir / "alpha.txt"} << "normal line\nwarning: disk almost full\n"
                                            "another WARNING here\nall good\n";
        std::ofstream{dir / "beta.md"} << "# notes\nthere is a Warning inside\n";
        std::ofstream{dir / "gamma.dat"} << "nothing to see\n";
    }
    auto hits_a = search_file(dir / "alpha.txt", "warning", true);
    // ……
    assert(hits_a.size() == 2 && hits_a[0].line_no == 2 && hits_a[1].line_no == 3);
    assert(hits_b.size() == 1 && hits_b[0].line_no == 2);
    assert(hits_g.empty());
    fs::remove_all(dir);
    std::println("minigrep 自检通过");
}
```

**临时目录当夹具**：程序自己在 temp 下造三个已知内容的文件（含命中、大小写、无命中三种情况），断言命中数与行号，清理现场。无参数运行即进自检——**示例有了自证能力，才配进 build.ps1 的三层验证**（第 23 章测试观的落点）。这套"自检型示例"模式可以直接抄进你自己的小工具。

## 24.7 多线程搜索：原子游标

```cpp
int search_directory(const Options& opt) {
    std::vector<fs::path> files;
    for (const auto& e : fs::recursive_directory_iterator{opt.dir}) {
        if (e.is_regular_file()) {
            files.push_back(e.path());
        }
    }
    std::sort(files.begin(), files.end());  // 输出顺序稳定

    std::atomic<std::size_t> cursor{0};
    std::atomic<int> total{0};
    std::mutex print_mtx;  // 命中行整行打印，不许交错
    std::vector<std::jthread> team;
    for (int t = 0; t < opt.threads; ++t) {
        team.emplace_back([&] {
            std::size_t i;
            while ((i = cursor.fetch_add(1)) < files.size()) {  // 领下一个文件
                for (const auto& m : search_file(files[i], opt.pattern, opt.ignore_case)) {
                    {
                        std::lock_guard lock{print_mtx};
                        print_match(files[i], m, opt.pattern, opt.ignore_case);
                    }
                    total.fetch_add(1);
                }
            }
        });
    }
    for (auto& t : team) {
        t.join();
    }
    return total.load();
}
```

并发设计的每一笔都对应前面章节：**文件先收集再分派**（遍历与处理解耦，还顺手 sort 保证输出确定）；**原子游标 `cursor.fetch_add(1)`** 让线程自己领文件——这是"线程池任务队列"的极简形态（旧教程有线程池一章 70 行，本质就是"队列 + 一组常驻工人"，这里 15 行取其神）；**打印互斥**（print_mtx 保行完整——并发输出交错的坑，第 19 章）；**jthread 自动 join**；**锁外搜索锁内打印**（临界区最小化——第 19 章设计观）。

线程数默认 4：文件多于线程时分工自然均衡；文件少于线程时多余工人第一轮领不到任务即收工（`fetch_add` 越界退出）。

## 24.8 扩展方向

把本工具当练手底座：`-w` 全词匹配（find_in_line 前后查边界字节）、`--include "*.md"` 过滤（path 后缀判断）、正则模式（换 std::regex，注意循环外构造）、`-c` 只输出计数、统计最慢文件（chrono 计时）。每一条都恰好压在某一章的知识点上——这正是它作为收官项目的用意。

## 24.9 坑位清单

1. **递归遍历遇符号链接绕圈**：目录自引用→无限递归。`recursive_directory_iterator` 默认不 follow 符号链接，**别手贱开选项**；真要开得记 visited。
2. **二进制文件当文本搜**：exe/dll 里乱码行刷屏——真 grep 有 `-I` 跳过二进制；教学版可按 NUL 字节探测（扩展方向之一）。
3. **线程数开过文件数**：多余线程空转领任务即退——无害但白开（-t 1000 搜 3 个文件的荒谬感）。
4. **输出不锁**：两个线程的半行交错——多线程打印必须互斥（本例 print_mtx 的存在理由）。
5. **自检造的临时目录没清理**：炸在 assert 也该清场——把 remove_all 放函数末尾的失败路径也覆盖（工程版用 RAII 目录守卫）。
6. **路径含空格没引号**：shell 层的问题但最常被怪到工具头上——用法说明里提示用户加引号。
