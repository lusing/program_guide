# 数据结构教程（C++23）实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 在 `G:\code\guide\datastruct\` 交付 28 章 C++23 数据结构教程（28 篇正文 + 28 个自校验示例 + README/CHEATSheet），三通道零告警全绿。

**Architecture:** 每章 = 手搓 ADT（现代 C++23：RAII、概念、span/string_view、expected/optional、print）+ assert 自检 main + 正文文档（内嵌真实输出）；构建脚本复用 cpp20 教程的自动发现式多通道框架。素材来自 Sahni 文本层直抽 + 两本扫描书选择性 OCR。

**Tech Stack:** C++23；MSVC cl（VS18，主通道）、clang 23.1.2、gcc 15.2（探针门控）；Python 3 + pymupdf + rapidocr-onnxruntime；PowerShell 7 + Git Bash。

**Spec:** `docs/superpowers/specs/2026-10-04-datastruct-design.md`（随本计划同行，每个任务都隐含遵守该 spec 与本计划 Global Constraints）。

## Global Constraints

- 工程根：`G:\code\guide\datastruct\`；素材目录 `datastruct/materials/` 与 `datastruct/build/` 一律不入库。
- 手搓代码统一用 `namespace ds`；头文件 `.hpp` 与 `main.cpp` 同目录，`#include "x.hpp"` 引号包含。
- 编译参数固定：
  - MSVC：`/nologo /std:c++latest /EHsc /utf-8 /permissive- /Zc:__cplusplus /W4`，vcvars64：`G:\Program Files\Microsoft Visual Studio\18\Community\VC\Auxiliary\Build\vcvars64.bat`
  - clang/gcc：`-std=c++23 -Wall -Wextra`（clang：`G:\scoop\apps\llvm\current\bin\clang++.exe`；gcc：`G:\scoop\apps\gcc\current\bin\g++.exe`）
- 判定六条：退出码 0；stderr 空；stdout 非空；无多余控制字符（TAB/LF/CR 除外）；含末行"自检通过"；编译日志零告警。
- gcc 通道用探针门控（`<print>` 已知坏），门控失败只登记不判失败；MSVC 与 clang 必须全绿。
- 确定性禁打：指针/地址、sizeof/capacity/chrono 原始值；随机只用固定种子 `std::mt19937 rng{5489}`；平局按编号/字典序。
- 错误处理：教学 ADT 约定——编程错误（越界、空容器 pop）throw 标准异常；可预期失败返回 `std::expected`/`optional`；每处选型在正文说明。
- **正文以讲解为主体，示例代码是辅助**：只读 `docs/`、不打开 `examples/` 也必须能完整学会本章。禁止"连续大段代码无讲解"——任何嵌入代码段前面要有"为什么/要解决什么"，后面要有"逐行/逐块在做什么、关键不变量是什么"；代码段是论证的论据，不是内容本身。概念用直觉引入（生活类比/图示性文字/小实例手工推演），再给形式化合同。
- 每章正文固定结构：`# NN · 标题`（开头直接进正文，不放示例指路）→ 动机与直觉 → ADT 合同（操作语义用文字+小例子讲清）→ 设计与不变量（分步推演，关键代码小块嵌入并逐块讲解）→ 复杂度推导 → **完整示例输出**（真实粘贴+逐行解释说明了什么）→ std 对照 → 坑位（每个坑：现象/原因/后果）→ **末尾**才用一行斜体给出可选项：`*可选延伸：可运行示例见 examples/NN_name/。*`。每章正文不少于 200 行，讲解文字篇幅明显多于代码。
- 提交：每批一次提交，信息 `feat(datastruct): 批次N——……`，末尾 `Co-Authored-By: Claude Code <noreply@anthropic.com>`；中文斜杠串若被安全层拦截，改写文件用 `git commit -F`。

## File Structure

```
datastruct/
├── .gitignore
├── README.md                 # 批次一占位骨架 → 批次七定稿（三书导读+28 章导航）
├── CHEATSheet.md             # 批次七定稿（复杂度总表/选型表/坑位清单）
├── build.ps1                 # 复制自 cpp20，改注释 36→28
├── run-all.sh                # 同上
├── tools/
│   ├── extract_sahni.py      # 17 个分章 PDF 文本层 → materials/sahni/NN.txt
│   └── ocr_pages.py          # 指定 PDF 页区间 rapidocr → materials/ocr/<name>.txt
├── docs/                     # 01-intro.md … 28-cases.md（28 篇）
├── examples/                 # 01_intro … 28_cases（28 个，下列每章 main.cpp + 0–3 个 hpp）
└── materials/                # gitignore，不入库
    ├── sahni/                # 01.txt … 17.txt
    └── ocr/
```

示例目录名（与章号一一对应）：
`01_intro, 02_performance, 03_recursion, 04_arraylist, 05_linkedlist, 06_listvariants, 07_stack, 08_queue, 09_string, 10_matrix, 11_binarytree, 12_treeforest, 13_heap, 14_leftisttree, 15_huffman_lzw, 16_dict, 17_searchtree, 18_btree, 19_graph, 20_graphalgo, 21_sort1, 22_sort2, 23_greedy, 24_divideconquer, 25_dp, 26_backtrack, 27_branchbound, 28_cases`

文档名：同序 `NN-slug.md`（slug 与示例名一致，连字符风格），见各任务。

---

## Task 1: 工程骨架 + 批次一素材

**Files:**
- Create: `datastruct/.gitignore`, `datastruct/build.ps1`, `datastruct/run-all.sh`, `datastruct/tools/extract_sahni.py`, `datastruct/tools/ocr_pages.py`, `datastruct/README.md`（骨架）
- Create dirs: `datastruct/docs`, `datastruct/examples`
- Produce（后续所有任务依赖）：可运行的 `pwsh build.ps1 -Example <name>` 与 `./run-all.sh <NN>` 通道；`materials/sahni/01.txt,02.txt`；`materials/ocr/b2-01.txt`

- [ ] **Step 1: 建目录与 .gitignore**

```bash
mkdir -p "G:/code/guide/datastruct/docs" "G:/code/guide/datastruct/examples" "G:/code/guide/datastruct/tools"
```

`datastruct/.gitignore` 内容：

```gitignore
build/
materials/
*.exe
*.obj
*.o
*.ii
*.s
*.pcm
gcm.cache/
```

- [ ] **Step 2: 复制构建脚本并改注释**

```bash
cp "G:/code/guide/cpp20/build.ps1" "G:/code/guide/datastruct/build.ps1"
cp "G:/code/guide/cpp20/run-all.sh" "G:/code/guide/datastruct/run-all.sh"
```

对 `build.ps1` 做两处替换（注释行，脚本行为不变；脚本自动发现 `examples/*` 目录，无硬编码章数）：

- `docs/ 下 36 章正文里嵌了示例的完整输出，改一行文案就要同步 36 篇文档` → `docs/ 下 28 章正文里嵌了示例的完整输出，改一行文案就要同步 28 篇文档`

对 `run-all.sh`：

- `本教程 36 章的正文（docs/*.md）里嵌了示例的完整输出` → `本教程 28 章的正文（docs/*.md）里嵌了示例的完整输出`
- `26_modules 走真正的模块构建` 一行及 `build_with_modules` 函数保留不动（无示例名 26_modules，惰性代码；删除会牵动主循环判定，不碰）。

- [ ] **Step 3: 写素材脚本 tools/extract_sahni.py**

```python
# 抽取 Sahni 17 个分章 PDF 的文本层 → materials/sahni/NN.txt（UTF-8）
import pathlib
import fitz

SRC = pathlib.Path(r"G:\book\计算机\数据结构\数据结构算法与应用-C++语言描述")
OUT = pathlib.Path(__file__).resolve().parents[1] / "materials" / "sahni"
OUT.mkdir(parents=True, exist_ok=True)

for i in range(1, 18):
    doc = fitz.open(SRC / f"{i:03d}.PDF")
    text = "\n".join(page.get_text() for page in doc)
    (OUT / f"{i:02d}.txt").write_text(text, encoding="utf-8")
    print(f"{i:02d}: {len(text)} chars")
```

- [ ] **Step 4: 写素材脚本 tools/ocr_pages.py**

```python
# 用法: python tools/ocr_pages.py <pdf路径> <起始页> <结束页> <输出名>
# 页号 1-based（与 PDF 书签一致），含两端；输出 materials/ocr/<名>.txt
import sys
import pathlib
import fitz
from rapidocr_onnxruntime import RapidOCR

pdf, start, end, name = sys.argv[1], int(sys.argv[2]), int(sys.argv[3]), sys.argv[4]
out_dir = pathlib.Path(__file__).resolve().parents[1] / "materials" / "ocr"
out_dir.mkdir(parents=True, exist_ok=True)

# 默认 CPU 会话即可完成本教程的 OCR 量；如需 CUDA/TensorRT 加速，
# 按 rapidocr_onnxruntime 文档给 RapidOCR 传 det/rec 的 EP 配置，
# 运行库在 G:\cudnn\9.24（加入 PATH）。OCR 文本只作素材，事实须与 Sahni 文本层核对。
engine = RapidOCR()
doc = fitz.open(pdf)
lines: list[str] = []
for pno in range(start, end + 1):
    pix = doc[pno - 1].get_pixmap(dpi=200)
    result, _ = engine(pix.tobytes("png"))
    lines.append(f"\n===== PDF page {pno} =====")
    if result:
        lines.extend(item[1] for item in result)
    print(f"page {pno}: {0 if result is None else len(result)} lines")
(out_dir / f"{name}.txt").write_text("\n".join(lines), encoding="utf-8")
```

- [ ] **Step 5: 抽 Sahni 全部文本层并 OCR 书 2 第 1 章**

```bash
cd "G:/code/guide/datastruct"
python tools/extract_sahni.py
python tools/ocr_pages.py "G:/book/计算机/数据结构/用C++实现数据结构程序设计.pdf" 11 30 b2-01
```

预期：`materials/sahni/01.txt … 17.txt` 均非空（每文件数千至数万字符）；`materials/ocr/b2-01.txt` 生成。

- [ ] **Step 6: README 骨架**

`datastruct/README.md`：

```markdown
# 数据结构教程（C++23）

以三本书为纲：Sahni《数据结构算法与应用 - C++ 语言描述》、《用 C++ 实现数据结构程序设计》、《新编数据结构案例教程（C/C++ 语言）》。

构建：`pwsh ./build.ps1 -All`（Windows/MSVC）；`./run-all.sh`（clang/gcc）。

> 章节导航在全 28 章完成后补全。
```

- [ ] **Step 7: 提交**

```bash
cd "G:/code/guide"
git add datastruct
git commit -m "feat(datastruct): 批次一骨架——多通道构建+素材脚本+README"
```

---

## Task 2: 批次二——基础篇 1–3 章

**Files（每章 = docs + examples 两个产物）：**

| 章 | 文档 | 示例 | 头文件 |
|---|---|---|---|
| 1 | `docs/01-intro.md` | `examples/01_intro/main.cpp` | — |
| 2 | `docs/02-performance.md` | `examples/02_performance/main.cpp` | `perf.hpp` |
| 3 | `docs/03-recursion.md` | `examples/03_recursion/main.cpp` | `recursion.hpp` |

**Interfaces（示例内部接口，供正文引用）：**

`perf.hpp`：

```cpp
namespace ds {
long long sum_loop(int n);                 // 1+…+n，循环
constexpr long long sum_formula(int n);    // n(n+1)/2
struct Counter { int value; int copies; };// copies 在拷贝构造时 ++
void insertion_sort_with_count(std::span<Counter> a, long long& comparisons);
}
```

`recursion.hpp`：

```cpp
namespace ds {
long long fact(int n);
long long fib(int n);                 // 朴素递归
long long fib_memo(int n);            // memo
bool binary_search_rec(std::span<const int> a, int target);
using Move = std::pair<char, char>;
void hanoi(int n, char from, char via, char to, std::vector<Move>& moves);
}
```

**章节规格：**

- **01 绪论**：无 ADT。main 固定打印"逻辑结构四类（集合/线性/树形/图）、存储结构四类（顺序/链接/索引/散列）"案例地图；assert：`4 == 4` 之类无意义——改为真实断言：对内置数组演示"同一逻辑结构（线性表）两种存储"：`int a[5]` 与节点链表各存放 `{3,1,4,1,5}`，断言两表示逐项相等、`sizeof` 只进 `static_assert(sizeof(int) <= sizeof(long long))` 不打印。
- **02 性能**：assert `sum_loop(100)==5050` 且等于 `sum_formula`；逆序数组长度 8 经 `insertion_sort_with_count` 后有序且 `comparisons == 8*7/2`（28）；循环求和的"步数"打印 `n`、公式法打印 `1`（固定 n=100，确定性）；正文讲 O/Ω/Θ/o 并给三书页码索引。禁打 chrono 原值（正文中可讨论基准法）。
- **03 递归**：assert `fact(5)==120`；`fib(10)==55` 且 fib_memo 同值；`binary_search_rec` 对固定有序数组命中/未命中两情形；`hanoi(3,'A','B','C',moves)`：`moves.size()==7`，首步 `(A,B)`（n=3 小盘 A→B）、末步 `(B,C)`；打印全部 7 步。正文用 moves 输出解释调用栈。

- [ ] **Step 1: 按规格写三章 hpp + main.cpp**

每个 main 末尾打印 `std::println("自检通过");`，所有校验用 `assert`（含 `<cassert>`）；输出只含固定值（见规格）。

- [ ] **Step 2: 逐示例双通道验证**

```bash
cd "G:/code/guide/datastruct"
pwsh ./build.ps1 -Example 01_intro
pwsh ./build.ps1 -Example 02_performance
pwsh ./build.ps1 -Example 03_recursion
./run-all.sh 1 2 3
```

预期：MSVC 与 clang 全绿；gcc 被 `<print>` 探针门控跳过（脚本打印门控原因）。若 gcc 门控意外放行，也必须绿。

- [ ] **Step 3: 写三篇 docs，把真实输出粘进"完整示例输出"节**

按 Global Constraints 的正文固定结构；std 对照节：01 讲 ADT 与类的对应；02 对照 `<chrono>` 基准写法；03 对照迭代版并给"递归→栈"的转换预告。

- [ ] **Step 4: 全量回归 + 提交**

```bash
pwsh ./build.ps1 -All
cd "G:/code/guide"
git add datastruct
git commit -m "feat(datastruct): 批次二——01 绪论/02 性能/03 递归（三通道全绿）"
```

---

## Task 3: 批次三——线性结构篇 4–9 章

先备素材（页区间为 PDF 页，含两端）：

```bash
cd "G:/code/guide/datastruct"
python tools/ocr_pages.py "G:/book/计算机/数据结构/用C++实现数据结构程序设计.pdf" 31 57 b2-02
python tools/ocr_pages.py "G:/book/计算机/数据结构/用C++实现数据结构程序设计.pdf" 74 91 b2-04
python tools/ocr_pages.py "G:/book/计算机/数据结构/用C++实现数据结构程序设计.pdf" 92 101 b2-05
python tools/ocr_pages.py "G:/book/计算机/数据结构/用C++实现数据结构程序设计.pdf" 102 121 b2-06
```

Sahni 对应：`materials/sahni/03.txt`（线性表）、`05.txt`（栈）、`06.txt`（队列）。

**Files：**

| 章 | 文档 | 示例 | 头文件 |
|---|---|---|---|
| 4 | `docs/04-arraylist.md` | `examples/04_arraylist/` | `array_list.hpp` |
| 5 | `docs/05-linkedlist.md` | `examples/05_linkedlist/` | `singly_list.hpp`, `doubly_list.hpp`, `circular_list.hpp` |
| 6 | `docs/06-listvariants.md` | `examples/06_listvariants/` | `static_list.hpp`, `indirect_list.hpp`, `union_find.hpp`, `polynomial.hpp` |
| 7 | `docs/07-stack.md` | `examples/07_stack/` | `array_stack.hpp`, `linked_stack.hpp`, `calculator.hpp`, `maze.hpp` |
| 8 | `docs/08-queue.md` | `examples/08_queue/` | `array_queue.hpp`, `linked_queue.hpp`, `simulation.hpp` |
| 9 | `docs/09-string.md` | `examples/09_string/` | `string_match.hpp`, `string_index.hpp` |

**Interfaces：**

```cpp
// array_list.hpp
template <std::copyable T>
class ds::ArrayList {
public:
    ArrayList() = default;
    explicit ArrayList(size_t cap);
    ArrayList(std::initializer_list<T> il);
    ArrayList(const ArrayList&); ArrayList(ArrayList&&) noexcept;
    ArrayList& operator=(const ArrayList&); ArrayList& operator=(ArrayList&&) noexcept;
    ~ArrayList();
    [[nodiscard]] size_t size() const noexcept;
    [[nodiscard]] bool empty() const noexcept;
    size_t capacity() const noexcept;            // 原值禁打印
    void reserve(size_t n);
    void push_back(const T& v);
    void insert(size_t pos, const T& v);        // 0<=pos<=size，否则 throw out_of_range
    void erase(size_t pos);                     // 否则 throw out_of_range
    void pop_back();
    T& operator[](size_t i); const T& operator[](size_t i) const;  // 越界 throw
    T* begin() noexcept; T* end() noexcept;
    const T* begin() const; const T* end() const;
    bool operator==(const ArrayList&) const;
    std::span<T> as_span() noexcept;
};

// singly_list.hpp
template <std::copyable T>
class ds::SinglyList {
public:
    void push_front(const T&); void pop_front();
    void insert(size_t pos, const T&); void erase(size_t pos);
    const T& front() const; size_t size() const; bool empty() const;
    void reverse();
    class iterator { /* 前向迭代器：operator*,++,== */ };
    iterator begin(); iterator end();
    bool operator==(const SinglyList&) const;
};

// doubly_list.hpp：push_front/back、pop_front/back、insert/erase(pos)、
//   双向 iterator、void splice_after? → merge_sorted(SinglyList&) 放此头文件作自由函数

// circular_list.hpp：CircularList<T>，rotate()、size()，尾节点 next 回头；
//   拷贝/析构正确断环。

// static_list.hpp：StaticList<T, size_t N>，节点存 int next（模拟指针），
//   int alloc_node(...)、void free_node(int)，int head()，insert/erase；
//   空槽串成 freelist。
// indirect_list.hpp：IndirectList<T> 存 T* 数组；sort() 只动指针；data_untouched 可查。
// union_find.hpp：UnionFind { int count; int find(int); bool unite(int a,int b); int size(int); }（快速版）
// polynomial.hpp：struct Term { double coef; int exp; }；
//   Polynomial（零项不存）：add、multiply；operator==。

// array_stack.hpp：ArrayStack<T> push/pop/top/empty/size；空 top/pop throw std::runtime_error。
// linked_stack.hpp：LinkedStack<T> 同合同。
// calculator.hpp：
double ds::eval_postfix(std::string_view expr);              // 空格分隔音 token
std::string ds::to_postfix(std::string_view infix);          // + - * / ( ) 与数字 token
bool ds::balanced(std::string_view expr);
// maze.hpp：
std::vector<std::pair<int,int>> ds::solve_maze(std::span<const std::string_view> grid,
                                               std::pair<int,int> start, std::pair<int,int> goal);

// array_queue.hpp：ArrayQueue<T> 循环数组，enqueue/dequeue/front/size/empty，空 dequeue throw。
// linked_queue.hpp：LinkedQueue<T> 同合同。
// simulation.hpp：
struct ds::SimResult { double avg_wait; int max_wait; int served; };
SimResult ds::bank_simulation(std::span<const int> arrivals, std::span<const int> services);
int ds::josephus(int n, int k);                              // 1-based，返回幸存编号

// string_match.hpp：
size_t ds::bf_find(std::string_view text, std::string_view pat, size_t pos = 0);
std::vector<size_t> ds::build_pi(std::string_view pat);
size_t ds::kmp_find(std::string_view text, std::string_view pat, size_t pos = 0);
// string_index.hpp：
struct WordPos { std::string word; size_t pos; };
std::vector<WordPos> ds::build_index(std::string_view text);   // 去重、按词排序
const WordPos* ds::lookup(std::span<const WordPos> idx, std::string_view word);
```

**章节 assert 规格：**

- **04**：`ArrayList<int>{2,4,6}` size/元素；push_back 8 后逐项；insert(1,3) 后为 2,3,4,6,8；erase 后复位；拷贝后改副本互不影响；移动后源 empty；`operator[]` 越界与 insert 越界各自被 catch（bool 标记）；`as_span().size()==size()`；`==` 语义。
- **05**：单链 push/pop/insert/erase 内容序列；reverse 后等于期望；iterator 遍历计数；双链双向遍历、erase 中部；merge_sorted 两个有序链结果有序完整；循环链连续 rotate n 步回头，size 不变，析构不挂。
- **06**：StaticList 释放后再分配复用同一槽号；IndirectList sort 后指针序变而原数据顺序未动；UnionFind 两次 unite 后 size 与根；Polynomial：`(x+1)+(x-1)=2x`（1 项）、`(x+1)*(x-1)=x²-1`（2 项）。
- **07**：栈 LIFO、空 pop throw；balanced 四正两负；to_postfix(`3 + 4 * 2 / ( 1 - 5 )`)==`3 4 2 * 1 5 - / +`；eval_postfix 该串==1.0（注意空格分隔音 token）；迷宫固定 8×8 网格，路径首格起点、末格终点、每步四邻接且不撞墙。
- **08**：FIFO 与循环回绕（连续 enq/deq 100 次内容正确）；josephus(5,2)==3；bank_simulation(arrivals=[0,2,4,6], services=[3,3,3,3])：avg_wait==1.5、max_wait==3、served==4（等待口径 = 开始服务时刻−到达时刻；原计划写的 0.75/1 是误把"到达时前面人数"当等待时间，已订正）。
- **09**：bf/kmp 在固定文本上命中同一位置、未命中返回 npos；build_pi("ababaca")==[0,0,1,2,3,0,1]；pos=起始偏移参数生效；index 中 lookup("data") 位置正确、不存在词返回 nullptr。

- [ ] **Step 1: 18 个头文件按合同实现（RAII：拷贝/移动/析构齐全，零裸泄漏）**
- [ ] **Step 2: 6 个 main.cpp 按 assert 规格编写 + 末行"自检通过"**
- [ ] **Step 3: 双通道逐示例验证**

```bash
pwsh ./build.ps1 -Example 04_arraylist   # 依次 04…09
./run-all.sh 4 5 6 7 8 9
```

预期：MSVC、clang 全绿，gcc 门控跳过。

- [ ] **Step 4: 6 篇 docs（含真实输出；std 对照：vector/list/forward_list/stack/queue/deque/string/string_view）**
- [ ] **Step 5: 全量回归 + 提交**

```bash
pwsh ./build.ps1 -All
cd "G:/code/guide" && git add datastruct
git commit -m "feat(datastruct): 批次三——04-09 线性结构六示例（三通道全绿）"
```

---

## Task 4: 批次四——多维与树形结构篇 10–15 章

素材：

```bash
cd "G:/code/guide/datastruct"
python tools/ocr_pages.py "G:/book/计算机/数据结构/用C++实现数据结构程序设计.pdf" 122 149 b2-07
python tools/ocr_pages.py "G:/book/计算机/数据结构/用C++实现数据结构程序设计.pdf" 150 188 b2-08
```

Sahni：`04.txt`（数组/矩阵）、`08.txt`（二叉树）、`09.txt`（堆/左高树）、`10.txt`（竞赛树）；LZW 在 `07.txt`。

**Files：**

| 章 | 示例 | 头文件 |
|---|---|---|
| 10 `docs/10-matrix.md` | `examples/10_matrix/` | `compressed_matrix.hpp`, `sparse_matrix.hpp`, `cross_list.hpp`, `general_list.hpp` |
| 11 `docs/11-binarytree.md` | `examples/11_binarytree/` | `binary_tree.hpp` |
| 12 `docs/12-treeforest.md` | `examples/12_treeforest/` | `tree_forest.hpp`, `union_find2.hpp` |
| 13 `docs/13-heap.md` | `examples/13_heap/` | `binary_heap.hpp` |
| 14 `docs/14-leftisttree.md` | `examples/14_leftisttree/` | `leftist_tree.hpp`, `winner_tree.hpp` |
| 15 `docs/15-huffman-lzw.md` | `examples/15_huffman_lzw/` | `huffman.hpp`, `lzw.hpp` |

**Interfaces：**

```cpp
// compressed_matrix.hpp
class ds::SymmetricMatrix {
public: explicit SymmetricMatrix(int n); double& at(int r,int c); /* 映射 i>=j: i(i+1)/2+j */ };
// sparse_matrix.hpp（COO）
struct Triple { int r, c; double v; };
class ds::SparseMatrix {
public:
    SparseMatrix(int rows, int cols, std::initializer_list<Triple>);
    SparseMatrix transpose() const;
    SparseMatrix operator+(const SparseMatrix&) const;
    std::span<const Triple> triples() const;
};
// cross_list.hpp：十字链表（节点 int right/down 索引 + 行/列头数组，自有定长 arena）
class ds::CrossList {
public:
    CrossList(int rows, int cols);
    void set(int r, int c, double v); double get(int r,int c) const;
    size_t node_count() const; std::vector<Triple> row(int r) const;
};
// general_list.hpp：广义表（节点 = 原子 double 或子表；int tag）
class ds::GeneralList {
public: static GeneralList parse(std::string_view s); int length() const; int depth() const;
    std::vector<double> flatten() const; };

// binary_tree.hpp
template <std::copyable T>
class ds::BinaryTree {
public:
    static BinaryTree from_pre_in(std::span<const T> pre, std::span<const T> in);
    std::vector<T> preorder() const; std::vector<T> inorder() const;
    std::vector<T> postorder() const; std::vector<T> postorder_iter() const;
    std::vector<T> levelorder() const;
    int size() const; int height() const; int leaves() const;
    BinaryTree(const BinaryTree&); BinaryTree(BinaryTree&&) noexcept;
    BinaryTree& operator=(const BinaryTree&); BinaryTree& operator=(BinaryTree&&) noexcept;
    ~BinaryTree();
};

// tree_forest.hpp
template <std::copyable T>
class ds::Tree {                    // 长子-兄弟表示
public: void add_root(const T&); void add_child(const T& parent, const T& child);
    std::vector<T> preorder() const; };
BinaryTree<T> ds::to_binary_tree(const Tree<T>&);
Tree<T> ds::from_binary_tree(const BinaryTree<T>&);
// union_find2.hpp：按秩合并 + 路径压缩；find/unite/rank/depth_sanity()

// binary_heap.hpp
template <std::totally_ordered T, class Compare = std::less<T>>
class ds::BinaryHeap {
public: void push(const T&); const T& top() const; void pop();
    BinaryHeap() = default; BinaryHeap(std::span<const T>);
    bool empty() const; size_t size() const; bool is_heap() const; };
void ds::heap_sort(std::span<int>);

// leftist_tree.hpp
template <std::totally_ordered T, class Compare = std::less<T>>
class ds::LeftistTree {
public: void meld(LeftistTree& other); void push(const T&); const T& top() const; void pop();
    int root_s() const; size_t size() const; bool property_ok() const; };
// winner_tree.hpp：k 路归并
std::vector<int> ds::kway_merge(std::span<const std::vector<int>> runs);

// huffman.hpp（平局先按字符编号：堆元素 (freq, id)）
struct HuffCode { char ch; std::string bits; };
class ds::Huffman {
public: explicit Huffman(std::span<const std::pair<char,int>> freqs);
    std::vector<HuffCode> codes() const;
    std::string encode(std::string_view text) const;
    std::string decode(std::string_view bits) const; };
// lzw.hpp
std::vector<int> ds::lzw_encode(std::string_view text);
std::string ds::lzw_decode(std::span<const int> codes);
```

**章节 assert 规格：**

- **10**：SymmetricMatrix at(r,c)==at(c,r) 映射同槽；SparseMatrix 固定例 transpose 后行列互换、triples 按 (r,c) 有序；相加零项消失；CrossList set/get 往返、row() 与 triples 数量一致、node_count 确定；GeneralList parse(`(a,(b,(c)),d)`)：length()==3、depth()==3、flatten 顺序 a,b,c,d。
- **11**：from_pre_in(pre="ABDECFG", in="DBEAFCG")：postorder=="DEBFGCA"、postorder_iter 相同、levelorder=="ABCDEFG"、size 7、height 3、leaves 3；拷贝独立性 + 移动后 empty。
- **12**：给定两棵树组成的森林，preorder 固定序列；to_binary_tree 再 from_binary_tree 的 preorder 与原森林一致；UnionFind2：unite 后 find 同根、rank 单调、1000 次操作后深度 sanity（rank≤⌊log₂n⌋+1）。
- **13**：逐 push 后 is_heap；heapify `[3,1,4,1,5,9,2,6]` 后 pop 序列 `9,6,5,4,3,2,1,1`；heap_sort 对固定数组有序且为降/升预期。
- **14**：meld 后 property_ok（s(left)≥s(right)、s=1+min）；root_s 确定；pop 序列降序；kway_merge 三个有序段结果与手工 expected 完全一致且长度守恒。
- **15**：codes 前缀自由（两两互不为前缀）；encode 后 decode 还原原文（含每字符频率>0 的固定串）；平局 id 序保证输出确定；lzw 固定串 "ababcbababaaaaaaa"：encode/decode roundtrip；码表初始 0–25（单字母码），首个新码==256。

- [ ] **Step 1: 实现 12 个头文件（树结构拷贝/移动/递归析构尤其防泄漏）**
- [ ] **Step 2: 6 个 main.cpp（末行"自检通过"）**
- [ ] **Step 3: 双通道逐示例验证 + 全量回归**

```bash
./run-all.sh 10 11 12 13 14 15
pwsh ./build.ps1 -All
```

- [ ] **Step 4: 6 篇 docs（std 对照：priority_queue；无对应 std 的结构说明取舍）**
- [ ] **Step 5: 提交**

```bash
cd "G:/code/guide" && git add datastruct
git commit -m "feat(datastruct): 批次四——10-15 多维与树形结构六示例（三通道全绿）"
```

---

## Task 5: 批次五——字典与图 16–20 章

素材：

```bash
cd "G:/code/guide/datastruct"
python tools/ocr_pages.py "G:/book/计算机/数据结构/用C++实现数据结构程序设计.pdf" 189 233 b2-09
python tools/ocr_pages.py "G:/book/计算机/数据结构/用C++实现数据结构程序设计.pdf" 234 260 b2-10
python tools/ocr_pages.py "G:/book/计算机/数据结构/用C++实现数据结构程序设计.pdf" 283 298 b2-12
```

Sahni：`07.txt`（跳表/散列）、`11.txt`（搜索树）、`12.txt`（图）。

**Files：**

| 章 | 示例 | 头文件 |
|---|---|---|
| 16 `docs/16-dict.md` | `examples/16_dict/` | `skip_list.hpp`, `hash_chained.hpp`, `hash_open.hpp` |
| 17 `docs/17-searchtree.md` | `examples/17_searchtree/` | `bst.hpp`, `avl.hpp`, `red_black.hpp` |
| 18 `docs/18-btree.md` | `examples/18_btree/` | `b_tree.hpp`, `bplus_tree.hpp`, `inverted_index.hpp` |
| 19 `docs/19-graph.md` | `examples/19_graph/` | `adj_matrix.hpp`, `adj_list.hpp`, `traversal.hpp`, `topo.hpp` |
| 20 `docs/20-graphalgo.md` | `examples/20_graphalgo/` | `shortest_path.hpp`, `mst.hpp`, `critical_path.hpp` |

**Interfaces：**

```cpp
// skip_list.hpp（mt19937 rng{5489}；层随机，max_level 16）
template <std::totally_ordered K, std::copyable V>
class ds::SkipList {
public: void insert(const K&, const V&); std::optional<V> get(const K&) const;
    bool erase(const K&); bool contains(const K&) const;
    std::vector<std::pair<K,V>> sorted_entries() const; size_t size() const; };
// hash_chained.hpp：定桶 vector<forward_list<pair>>，insert/get/erase/load_factor/rehash
// hash_open.hpp：线性探查 vector<slot(empty/active/deleted)>，同接口；rehash 阈值 0.7
// 两表统一：
template <class K, class V>
class /*ChainedHash, OpenAddressHash*/ {
public: void insert(const K&, const V&); std::optional<V> get(const K&) const;
    bool erase(const K&); size_t size() const; double load_factor() const; void rehash(size_t); };

// bst.hpp
template <std::totally_ordered K, std::copyable V>
class ds::BSTree {
public: void insert(const K&, const V&); std::optional<V> search(const K&) const;
    bool erase(const K&); std::vector<K> keys_sorted() const; };
// avl.hpp：同接口 + int height 平衡；私有的 rotate_left/right/LR/RL
// red_black.hpp：insert + 修复；bool rb_legal()（根黑、无连续红、黑高一致）

// b_tree.hpp（m=3，即 2-3 树实现；键升序、分裂）
template <std::totally_ordered K>
class ds::BTree {
public: explicit BTree(int order = 3);
    void insert(const K&); bool contains(const K&) const;
    std::vector<K> all_keys() const; std::vector<K> root_keys() const; };
// bplus_tree.hpp：叶节点链表
class ds::BPlusTree {
public: void insert(const K&); bool contains(const K&) const;
    std::vector<K> range(const K& lo, const K& hi) const; };
// inverted_index.hpp
class ds::InvertedIndex {
public: void add_doc(int id, std::string_view text);
    std::vector<int> postings(std::string_view word) const;  // 升序
    size_t doc_count() const; };

// adj_matrix.hpp：AdjMatrix(int n, bool directed)；add_edge(u,v[,w])；remove_edge；has_edge；n
// adj_list.hpp：AdjList 同合同；neighbors(v) span/vector
// traversal.hpp：std::vector<int> bfs(const Graph&, int s); dfs(...)（邻点按编号升序）
// topo.hpp：std::optional<std::vector<int>> topo_sort(const AdjList&)（Kahn；环→nullopt）

// shortest_path.hpp
std::vector<double> ds::dijkstra(const AdjList& g, int s);
struct DistMatrix { std::vector<double> d; /* n*n，infinity=-1 占位打印 */ };
DistMatrix ds::floyd(const AdjMatrix& g);
// mst.hpp
struct MstResult { double total; std::vector<std::pair<int,int>> edges; };
MstResult ds::prim(const AdjMatrix& g, int s);
MstResult ds::kruskal(const AdjMatrix& g);
// critical_path.hpp（AOE）
struct CritResult { int length; std::vector<std::pair<int,int>> activities; };
std::optional<CritResult> ds::critical_path(const AdjList& g);
```

**章节 assert 规格：**

- **16**：跳表插入固定键序列后 get 全中、sorted_entries 按键升序、erase 后 get==nullopt；固定种子下 size/层级统计两次运行一致（main 内插同样数据两遍，断言统计相同）；两哈希表：插入 30 键 get 全中、erase 10 键后其余仍中、rehash 前后内容一致；构造桶数 4 的小表插入同余键（如 0,4,8）三键互不覆盖。
- **17**：BST 插入/删除后 keys_sorted 有序、search；AVL 四情形（插 3,2,1 → LL；插 1,2,3 → RR；插 3,1,2 → LR；插 1,3,2 → RL）各自 preorder（含高度）精确断言：LL 后根为 2、子 1,3，balance 全 0；删除后仍平衡；红黑：固定插入序列（1..7）后 rb_legal，根键与黑高确定。
- **18**：BTree 顺序插入 1..10：每步 all_keys 有序；root_keys 在各次分裂点精确断言（插 4 后首次分裂 root=={3}，自己推其余关键点至少断言 3 个分裂时刻）；contains；BPlus range(3,7)==[3,4,5,6,7] 且叶链不重不漏；倒排：三文档固定文本，postings 升序精确、未登录词空。
- **19**：固定无向图 7 顶点：边数、bfs(0) 与 dfs(0) 顺序精确（邻点升序，自己先在草稿纸/程序核对后写死）；固定 DAG topo 精确一解；有环图 topo==nullopt。
- **20**：图（无向，边 0-1:4, 0-2:1, 2-1:2, 1-3:1, 2-3:5, 3-4:3）：dijkstra(0)==[0,3,1,4,7]；floyd 行 0 相同且 [i][i]==0；prim 与 kruskal total 都==7、边集（排序后）相同。AOE DAG（0→1:3, 0→2:2, 1→3:1, 2→3:3）：length==5，activities=={(0,2),(2,3)}。

- [ ] **Step 1: 15 个头文件实现（指针节点全部 RAII/工厂封装；迭代器失效条件在正文写明）**
- [ ] **Step 2: 5 个 main.cpp；图算法顺序类断言先跑程序核对再写死**
- [ ] **Step 3: 双通道验证 + 全量回归**

```bash
./run-all.sh 16 17 18 19 20
pwsh ./build.ps1 -All
```

- [ ] **Step 4: 5 篇 docs（std 对照：unordered_map/map/set；文件索引节融入书 2 第 12 章）**
- [ ] **Step 5: 提交**

```bash
cd "G:/code/guide" && git add datastruct
git commit -m "feat(datastruct): 批次五——16-20 字典搜索树与图五示例（三通道全绿）"
```

---

## Task 6: 批次六——排序两章 21–22

素材：

```bash
cd "G:/code/guide/datastruct"
python tools/ocr_pages.py "G:/book/计算机/数据结构/用C++实现数据结构程序设计.pdf" 58 73 b2-03
python tools/ocr_pages.py "G:/book/计算机/数据结构/用C++实现数据结构程序设计.pdf" 261 282 b2-11
python tools/ocr_pages.py "G:/book/计算机/数据结构/新编数据结构案例教程（C_C++语言）-微课版.pdf" 317 344 b3-09
```

**Files：**

| 章 | 示例 | 头文件 |
|---|---|---|
| 21 `docs/21-sort1.md` | `examples/21_sort1/` | `basic_sort.hpp` |
| 22 `docs/22-sort2.md` | `examples/22_sort2/` | `advanced_sort.hpp`（heap_sort 从 13 章思路重述，不跨示例 include） |

**Interfaces：**

```cpp
// basic_sort.hpp
void ds::insertion_sort(std::span<int>);
void ds::binary_insertion_sort(std::span<int>);
void ds::bubble_sort(std::span<int>);
void ds::selection_sort(std::span<int>);
void ds::quick_sort(std::span<int>);                       // 首元素划分也可，固定确定性
// advanced_sort.hpp
void ds::shell_sort(std::span<int>);                      // increments n/2 序列
void ds::heap_sort(std::span<int>);
void ds::merge_sort(std::span<int>);
void ds::radix_sort(std::span<unsigned int>);             // LSD base 10
void ds::bucket_sort(std::span<int>, int lo, int hi);
std::vector<int> ds::external_sort_sim(std::span<const int> input, size_t run_size); // 分段排序+k路归并
```

**assert 规格：**

- **21**：五种排序对固定夹具 `{3,1,4,1,5,9,2,6,-3,0}` 全部与 `std::sort` 结果逐元素相等；另测已排序、单元素、全相等三夹具；稳定性演示（按 key 排序 pair，插入/冒泡保持原序，选择排序不保证——正文说明，不在 assert 里强求不稳定者）；quick_sort 固定数组排序正确。
- **22**：六种算法对同一批夹具（含非负给 radix）正确；shell/heap/merge 对逆序 100 元素与 std 结果一致；external_sort_sim run_size=4 结果有序且长度守恒；正文给九算法复杂度/稳定性总表与 std::sort（introsort：快排+堆排兜底）对照及选型建议；桶排序固定桶分布计数确定。

- [ ] **Step 1: 两个头文件实现**
- [ ] **Step 2: 两个 main.cpp（逐算法 assert；末行"自检通过"）**
- [ ] **Step 3: 双通道验证 + 全量回归**

```bash
./run-all.sh 21 22 && pwsh ./build.ps1 -All
```

- [ ] **Step 4: 两篇 docs（总表必须与示例实测一致）**
- [ ] **Step 5: 提交**

```bash
cd "G:/code/guide" && git add datastruct
git commit -m "feat(datastruct): 批次六——21-22 排序上下两示例（三通道全绿）"
```

---

## Task 7: 批次七——算法设计五章 23–27

素材：Sahni `materials/sahni/13.txt … 17.txt`（文本层，直接用）。

**Files：**

| 章 | 示例 | 头文件 |
|---|---|---|
| 23 `docs/23-greedy.md` | `examples/23_greedy/` | `greedy.hpp` |
| 24 `docs/24-divideconquer.md` | `examples/24_divideconquer/` | `divconquer.hpp` |
| 25 `docs/25-dp.md` | `examples/25_dp/` | `dp.hpp` |
| 26 `docs/26-backtrack.md` | `examples/26_backtrack/` | `backtrack.hpp` |
| 27 `docs/27-branchbound.md` | `examples/27_branchbound/` | `branchbound.hpp` |

**Interfaces + 固定数据/期望值：**

```cpp
// greedy.hpp
int ds::container_loading(std::span<const int> weights, int cap);       // 最多装几箱
double ds::fractional_knapsack(std::span<const double> values,
                               std::span<const double> weights, double cap);
struct Job { int deadline; int profit; };
int ds::job_sequencing(std::span<const Job> jobs);                      // 最大利润

// divconquer.hpp
using Board = std::array<std::array<int,4>,4>;
Board ds::tromino(int mr, int mc);                                      // 缺格 (mr,mc)
struct MM { int min; int max; int comparisons; };
MM ds::min_max(std::span<const int> a);
int ds::quickselect(std::span<int> a, int k);                           // 0-based 第 k 小

// dp.hpp
struct KnapsackSol { int value; std::vector<int> items; };
KnapsackSol ds::knapsack_dp(std::span<const int> values,
                            std::span<const int> weights, int cap);
int ds::matrix_chain(std::span<const int> dims);
int ds::coin_change_ways(std::span<const int> coins, int amount);
struct BstCost { double cost; int root; };
BstCost ds::optimal_bst(std::span<const double> p, std::span<const double> q);

// backtrack.hpp（枚举顺序固定，结果确定）
int ds::queens(int n);                        // 解的个数
int ds::colorings(int colors, std::span<const std::pair<int,int>> edges, int n);
KnapsackSol ds::knapsack_bt(std::span<const int> values,
                            std::span<const int> weights, int cap);
std::vector<std::vector<int>> ds::subset_sum_lists(std::span<const int> a, int target);

// branchbound.hpp
struct BnBSol { int value; int nodes_expanded; };
BnBSol ds::knapsack_bnb(std::span<const int> values,
                        std::span<const int> weights, int cap);
int ds::tsp_bnb(std::span<const int> flat_matrix, int n);               // 最小回路长
```

**固定数据与期望值（直接写进 assert）：**

- **23**：container_loading([10,20,30], cap 50)==2；fractional_knapsack(values[60,100,120], weights[10,20,30], cap 50)==240.0；job_sequencing(jobs {(2,100),(1,19),(2,27),(1,25),(3,15)})==142。
- **24**：tromino 缺格 (1,2)：板上 0 只出现 1 次（缺格），其余编号 1..5 各恰好出现 3 次；min_max 长度 4：comparisons==4；quickselect 对固定数组 [7,2,5,1,8,3] k=2 → 3。
- **25**：knapsack_dp(values[3,4,5,6], weights[2,3,4,5], cap 5)：value==7，items 排序后 [0,1]；matrix_chain([10,30,5,60])==4500；coin_change_ways([1,2,5],5)==4；optimal_bst(p[.15,.1,.05,.1,.2], q[.05,.1,.05,.05,.05,.1])：cost≈2.75（误差<1e-9），root==1（0-based，键 k1）。
- **26**：queens(4)==2、queens(8)==92；colorings(3, 三角形边 {(0,1),(1,2),(0,2)}, 3)==6；knapsack_bt 同 25 数据 value==7；subset_sum 固定集合解系列表（先程序核对后写死个数与各解）。
- **27**：knapsack_bnb 同数据 value==7；性质断言：每个被剪节点的乐观上界 ≤ 当前最优（实现里记录 `prunes_all_dominating==true`）；nodes_expanded 与 naive 枚举 2ⁿ 比较确定为更小（main 内同时跑穷举计数，断言 `<`）；tsp_bnb 用 4 点固定矩阵（`[[0,10,15,20],[10,0,35,25],[15,35,0,30],[20,25,30,0]]`）结果==80（经典 TSP 例：20+25+35... 让我核对：路径 0→1→3→2→0 = 10+25+30+15=80）。

- [ ] **Step 1: 5 个头文件实现**
- [ ] **Step 2: 5 个 main.cpp 按上表固定值断言**
- [ ] **Step 3: 双通道验证 + 全量回归**

```bash
./run-all.sh 23 24 25 26 27
pwsh ./build.ps1 -All
```

- [ ] **Step 4: 5 篇 docs（每章"三书页码"索引；回溯↔分支限界对照在 27 章总结）**
- [ ] **Step 5: 提交**

```bash
cd "G:/code/guide" && git add datastruct
git commit -m "feat(datastruct): 批次七——23-27 算法设计五示例（三通道全绿）"
```

---

## Task 8: 批次八——收官：28 章 + README + CHEATSheet

素材：

```bash
cd "G:/code/guide/datastruct"
python tools/ocr_pages.py "G:/book/计算机/数据结构/新编数据结构案例教程（C_C++语言）-微课版.pdf" 345 365 b3-10
python tools/ocr_pages.py "G:/book/计算机/数据结构/新编数据结构案例教程（C_C++语言）-微课版.pdf" 366 368 b3-syllabus
```

**Files：** `docs/28-cases.md`, `examples/28_cases/main.cpp` + `cases.hpp`, `README.md`（定稿，覆写骨架），`CHEATSheet.md`（新建定稿）。

**Interfaces：**

```cpp
// cases.hpp
int ds::merge_file_cost(std::span<const int> file_sizes);   // Huffman 归并最小总代价
int ds::island_count(std::span<const std::string_view> grid); // 洪水填充/并查集皆可
struct ScheduleReport { int critical_length; std::vector<int> critical_path; };
ScheduleReport ds::project_schedule(const /* 复用 19/20 章思路的固定图数据结构*/);
int ds::calculator_full(std::string_view expr);             // 多位整数 + - * / ( )
```

**固定数据与期望值：**

- merge_file_cost([5,9,12,13,8])：Huffman WPL，归并序平局取小数：先算：取5+8=13 → {9,12,13,13}；9+12=21 → {13,13,21}；13+13=26 → {21,26}；21+26=47；总代价 13+21+26+47==107。
- island_count：固定 5×5 网格（01 串），在 main 里给出，期望个数先程序核对写死（挑一个手算 3 的网格，例如三行 `11000`/`10001`/`00011` → 岛数：左上一块、右上(0,4)一个、右下(2,3)(2,4)一块 → 3）。
- project_schedule：固定 AOE 图，critical_length 与 20 章同法核对写死。
- calculator_full("( 3 + 4 ) * 2")==14、"100 / 5 / 2"==10、除零行为：throw（main catch 为 bool）。
- `28-cases.md` 含"考研大纲考点 ↔ 本教程章节"对照表（依据 b3-syllabus OCR），逐条可定位。

**README 定稿必须含：** 三书一段式导读（各自定位/优缺点/为何这样组合）；环境要求（三种编译器版本与 vcvars 路径）；28 章完整导航表（篇/章/文档/示例/核心 ADT）；最后附"全部示例 ×3 通道 84 项全绿（gcc 门控说明）"声明，数字以实际通道运行为准。

**CHEATSheet 必须含三张表 + 一张清单：**
1. 九排序 + 查找/各 ADT 操作复杂度总表（平均/最坏/空间/稳定性）；
2. 选型决策表（"要……就用……"，含 std 与手搓两列）；
3. 渐近记号与递归式求解速查（Master 定理三情形）；
4. 全教程坑位清单（每条：章号 + 一句话 + 后果），条目来自 28 章"坑位"节，不得少于每章 1 条。

- [ ] **Step 1: cases.hpp + main.cpp（末行"自检通过"）**
- [ ] **Step 2: 双通道验证 28_cases**

```bash
pwsh ./build.ps1 -Example 28_cases
./run-all.sh 28
```

- [ ] **Step 3: 写 28-cases.md（含考研对照表）**
- [ ] **Step 4: 定稿 README.md（先跑全量取得准确数字）**

```bash
pwsh ./build.ps1 -All
./run-all.sh
```

预期：MSVC 28/28、clang 28/28 全绿，两通道输出逐字节一致；gcc 门控登记。把真实摘要数写进 README。

- [ ] **Step 5: 写 CHEATSheet.md（表内数值全部回查正文/实测）**
- [ ] **Step 6: 收官提交**

```bash
cd "G:/code/guide" && git add datastruct
git commit -m "feat(datastruct): 批次八收官——28 ACM 考研案例+README 三书导读+CHEATSheet"
```

---

## Self-Review 结论

- **Spec coverage**：spec §3 的 28 章逐一落在 Task 2–8（1-3→T2，4-9→T3，10-15→T4，16-20→T5，21-22→T6，23-27→T7，28→T8）；§4 工程形态 → T1；§5 三通道六判定 → Global + 每批验证步骤；§6 确定性 → Global；§7 C++23 约定 → Global；§8 OCR → T1 脚本 + 每批素材步骤；§9 七个里程碑 → 本计划 8 个任务（骨架独立成 Task 1，与 spec 批次一=骨架+1-3 略有细化：骨架与基础章拆为两个可独立评审任务，交付内容不变）；§10 验收 → T8。
- **Placeholder scan**：无 TBD/TODO；所有 ADT 均给出签名，所有断言均给出固定输入与期望值；个别"先程序核对写死"仅限遍历顺序类输出（19 章 bfs/dfs、26 章子集解个数），且都指明了确定算法（邻点升序、枚举顺序固定）与夹具，执行者据此得到唯一值，不是占位。
- **Type consistency**：`Self` 命名统一（SimResult/MM/BstCost/BnBSol/ScheduleReport）；heap_sort 在 13 章与 22 章为各自示例内同名实现（计划已注明不跨示例 include）；UnionFind（ch6 快速版）与 union_find2（ch12 按秩版）有意区分，名称不冲突。
