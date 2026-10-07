# 设计模式教程（C++23）实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 在 `G:\code\guide\designpattern\` 交付 40 章 C++23 设计模式教程（40 篇正文 + 40 个自校验示例 + README/CHEATSheet），MSVC+clang 双通道零告警全绿。

**Architecture:** 每章 = 意图/动机场景 → 朴素坏代码 → 经典模式逐段讲解 → C++23 现代写法对比 → 取舍/陷阱，代码全部内嵌正文；示例工程 assert 自检 + 末行"自检通过"。构建脚本复用 datastruct 的自动发现式双通道框架。素材：之禅 epub 全文直抽为纲，刘伟教材与 GoF 扫描件按批次选择性 OCR。

**Tech Stack:** C++23；MSVC cl（VS18）、clang（scoop llvm）；Python 3 + pymupdf + rapidocr-onnxruntime；PowerShell 7 + Git Bash。

**Spec:** `docs/superpowers/specs/2026-10-04-designpattern-tutorial-design.md`（随本计划同行，每个任务都隐含遵守该 spec 与本计划 Global Constraints）。

## Global Constraints

- 工程根：`G:\code\guide\designpattern\`；素材目录 `materials/` 与 `build/` 一律不入库。
- 手搓代码统一用 `namespace dp`；头文件 `.hpp` 与 `main.cpp` 同目录，`#include "x.hpp"` 引号包含。
- 编译参数固定：
  - MSVC：`/nologo /std:c++latest /EHsc /utf-8 /permissive- /Zc:__cplusplus /W4`，vcvars64：`G:\Program Files\Microsoft Visual Studio\18\Community\VC\Auxiliary\Build\vcvars64.bat`
  - clang：`-std=c++23 -Wall -Wextra`（`G:\scoop\apps\llvm\current\bin\clang++.exe`）
- 判定六条（复用 datastruct 框架）：退出码 0；stderr 空；stdout 非空；无多余控制字符；含末行"自检通过"；编译日志零告警。gcc 通道探针门控只登记不判失败；MSVC 与 clang 必须全绿。
- 确定性禁打：指针/地址、sizeof/capacity、chrono 原值；随机只用固定种子；平局按编号/字典序。
- **每章双线**：经典 OO 写法（虚函数、继承）+ C++23 现代写法（concepts / `std::variant`+`overload` / `std::function` / CRTP / ranges / designated initializers / magic static 等），正文必须给出两版取舍结论。
- **正文以讲解为主体**：只读 `docs/` 不打开 `examples/` 也能完整学会本章；任何嵌入代码段前有"为什么/要解决什么"，后有"逐块在做什么、关键点是什么"；文字篇幅多于代码；每章 ≥200 行。
- 每章正文固定结构：`# NN · 标题`（直接进正文）→ 意图与动机场景 → 朴素写法及其坏处 → 经典模式逐段讲解（角色表+内嵌代码）→ C++23 现代写法对比 → 两版取舍 → 陷阱清单（每个坑：现象/原因/后果）→ **末尾**一行斜体：`*可选延伸：可运行示例见 examples/NN_name/。*`。
- OCR 运行前置：`PATH="/g/cudnn/9.24/bin/12.9/x64:$PATH"`；OCR 文本只作素材，事实表述以书为准、写作时须与两源交叉核对。
- 提交：每批一次，信息 `feat(designpattern): 批次N——……`，末尾 `Co-Authored-By: Claude Code <noreply@anthropic.com>`。

## File Structure

```
designpattern/
├── .gitignore
├── README.md                 # 批次一占位骨架 → 批次八定稿（三书导读+40 章导航）
├── CHEATSheet.md             # 批次八定稿（模式选型表/经典vs现代对照/坑位清单）
├── build.ps1                 # 复制自 datastruct，改注释 28→40
├── run-all.sh                # 同上
├── tools/
│   ├── extract_zen.py        # 之禅 epub 165 xhtml → materials/zen/NNN.txt（书页顺序）
│   ├── ocr_pages.py          # 指定 PDF 页区间 rapidocr → materials/ocr/<name>.txt
│   ├── scan_gof.py           # GoF 13 个 PDF 首页 OCR → materials/gof_index.txt（卷→章节映射）
│   └── ocr_liuwei_toc.py     # 刘伟目录页 OCR → materials/liuwei_toc.txt（章→页码映射）
├── docs/                     # 01-intro.md … 40-cheatsheet.md（40 篇）
├── examples/                 # 01_intro … 40_cheatsheet（40 个，main.cpp + 0–4 个 hpp）
└── materials/                # gitignore，不入库
    ├── zen/                  # 000.txt … 164.txt
    └── ocr/                  # gof-*.txt、liuwei-*.txt
```

示例目录名（与章号一一对应，文档名 `NN-<同名slug>.md`）：
`01_intro, 02_srp_ocp, 03_lsp_dip, 04_isp_lod_crp, 05_simplefactory, 06_factorymethod, 07_abstractfactory, 08_singleton, 09_prototype, 10_builder, 11_adapter, 12_bridge, 13_composite, 14_decorator, 15_facade, 16_flyweight, 17_proxy, 18_chainofresp, 19_command, 20_interpreter, 21_iterator, 22_mediator, 23_memento, 24_observer, 25_state, 26_strategy, 27_templatemethod, 28_visitor, 29_polymorphism, 30_typeerasure, 31_logging, 32_eventbus, 33_statemachine, 34_objpool, 35_plugins, 36_evaluator, 37_docexport, 38_permission, 39_antipatterns, 40_cheatsheet`

素材索引（Task 1 生成，写作前先查）：
- `materials/zen/`：之禅全文，按 xhtml 序号；章→文件号用 `grep -l "<章名关键词>" materials/zen/*.txt` 定位。
- `materials/gof_index.txt`：GoF 各卷首页标题；写作某模式章时选对应卷整卷 OCR（每卷 ≤40 页）。
- `materials/liuwei_toc.txt`：刘伟各章 PDF 页码；OCR 命令 `python tools/ocr_pages.py "G:/book/计算机/设计模式/设计模式（第2版）.pdf" <起> <止> liuwei-cNN`。

---

## Task 1: 工程骨架 + 素材工具与索引

**Files:**
- Create: `designpattern/.gitignore`, `designpattern/build.ps1`, `designpattern/run-all.sh`, `designpattern/tools/extract_zen.py`, `designpattern/tools/ocr_pages.py`, `designpattern/tools/scan_gof.py`, `designpattern/tools/ocr_liuwei_toc.py`, `designpattern/README.md`（骨架）
- Create dirs: `designpattern/docs`, `designpattern/examples`
- Produce（后续所有任务依赖）：`materials/zen/*.txt` 全量；`materials/gof_index.txt`；`materials/liuwei_toc.txt`；双通道构建脚本

- [ ] **Step 1: 建目录与 .gitignore**

```bash
mkdir -p "G:/code/guide/designpattern/docs" "G:/code/guide/designpattern/examples" "G:/code/guide/designpattern/tools"
```

`designpattern/.gitignore`：

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
cp "G:/code/guide/datastruct/build.ps1" "G:/code/guide/designpattern/build.ps1"
cp "G:/code/guide/datastruct/run-all.sh" "G:/code/guide/designpattern/run-all.sh"
```

`build.ps1` 注释行 `docs/ 下 28 章正文…` → `docs/ 下 40 章正文…`；`run-all.sh` 同类 `28 章` → `40 章`（行为不变，脚本自动发现 examples/*）。

- [ ] **Step 3: tools/extract_zen.py（epub 全文直抽）**

```python
# 之禅 epub：EPUB/*.xhtml 按数值序去标签 → materials/zen/NNN.txt
import pathlib, re, zipfile

SRC = r"G:\book\计算机\设计模式\设计模式之禅（第2版）.epub"
OUT = pathlib.Path(__file__).resolve().parents[1] / "materials" / "zen"
OUT.mkdir(parents=True, exist_ok=True)

with zipfile.ZipFile(SRC) as z:
    names = [n for n in z.namelist() if n.startswith("EPUB/") and n.endswith(".xhtml")]
    names.sort(key=lambda n: int(pathlib.Path(n).stem))
    for n in names:
        raw = z.read(n).decode("utf-8")
        raw = re.sub(r"<[^>]+>", "\n", raw)
        raw = re.sub(r"\n{2,}", "\n", raw)
        out = OUT / f"{pathlib.Path(n).stem:0>3}.txt"
        out.write_text(raw, encoding="utf-8")
        print(f"{out.name}: {len(raw)} chars")
```

- [ ] **Step 4: tools/ocr_pages.py（从 datastruct 复制，改输出目录注释即可，行为不变）**

```bash
cp "G:/code/guide/datastruct/tools/ocr_pages.py" "G:/code/guide/designpattern/tools/ocr_pages.py"
```

- [ ] **Step 5: tools/scan_gof.py + tools/ocr_liuwei_toc.py（两份索引）**

`scan_gof.py`：对 `G:\book\计算机\设计模式\设计模式可复用面向对象软件基础\` 下 `001.PDF … 013.PDF` 各渲染第 1 页（dpi=200）OCR，写 `materials/gof_index.txt`，每行 `001.PDF | <OCR文本前80字符>`。

`ocr_liuwei_toc.py`：对 452 页 PDF 渲染第 3–10 页 OCR，写 `materials/liuwei_toc.txt`；若未含完整目录则扩展到第 14 页。两脚本共用 ocr_pages.py 里的 RapidOCR 初始化写法（dpi=200、`engine(pix.tobytes("png"))`）。

- [ ] **Step 6: 生成全部素材并人工核验索引**

```bash
cd "G:/code/guide/designpattern"
export PATH="/g/cudnn/9.24/bin/12.9/x64:$PATH"
python tools/extract_zen.py
python tools/scan_gof.py
python tools/ocr_liuwei_toc.py
grep -l "单例" materials/zen/*.txt | head -3   # 抽查章定位可用
cat materials/gof_index.txt
cat materials/liuwei_toc.txt
```

预期：zen 165 个 txt 均非空；两份索引能读出"哪卷/哪些页对应哪个模式章"。`<generator>` 支持探针：两通道各试编一个 `#include <generator>` 的 10 行程序（MSVC `/std:c++latest`、clang `-std=c++23`）；任一通道不支持则第 21 章的现代线改手写 coroutine generator（更利于教学），结论记入批次四备注。

- [ ] **Step 7: README 骨架**

```markdown
# 设计模式教程（C++23）

以三本书为纲：《设计模式之禅（第2版）》、刘伟《设计模式（第2版）》、GoF《设计模式：可复用面向对象软件的基础》。每章经典写法与 C++23 现代写法对照。

构建：`pwsh ./build.ps1 -All`（MSVC）；`./run-all.sh`（clang/gcc 门控）。

> 章节导航在全 40 章完成后补全。
```

- [ ] **Step 8: 提交**

```bash
cd "G:/code/guide"
git add designpattern
git commit -m "feat(designpattern): 批次一骨架——双通道构建+素材抽取与索引脚本+README"
```

---

## Task 2: 批次二——准备与原则篇 1–4 章

素材：之禅第 1 篇（六大原则）——`grep -l "单一职责\|开闭\|里氏\|依赖倒置\|迪米特" materials/zen/*.txt`；GoF 第 1 章（引言）——按 gof_index.txt 定位卷号后整卷 OCR（`python tools/ocr_pages.py "<卷路径>" 1 <页数> gof-ch1`）。

**Files:**

| 章 | 文档 | 示例 | 头文件 |
|---|---|---|---|
| 1 | `docs/01-intro.md` | `examples/01_intro/main.cpp` | — |
| 2 | `docs/02-srp_ocp.md` | `examples/02_srp_ocp/` | `srp.hpp`, `ocp.hpp` |
| 3 | `docs/03-lsp_dip.md` | `examples/03_lsp_dip/` | `lsp.hpp`, `dip.hpp` |
| 4 | `docs/04-isp_lod_crp.md` | `examples/04_isp_lod_crp/` | `isp.hpp`, `lod.hpp`, `crp.hpp` |

**Interfaces:**

```cpp
// srp.hpp
struct ds::Employee { std::string name; double base; int hours; };
// 坏：Employee 里塞 calculate_pay + format_report + save；好：拆三职责
double dp::calculate_pay(const Employee&);          // 财务域
std::string dp::format_report(const Employee&);     // 报表域（纯文本行）

// ocp.hpp：图形面积——加新形状不许改旧代码
class dp::Shape { public: virtual ~Shape() = default; virtual double area() const = 0; };
class dp::Circle : public Shape { double r; public: explicit Circle(double); double area() const override; };
class dp::Rect   : public Shape { double w, h; /* 同上 */ };
double dp::total_area(std::span<const std::unique_ptr<Shape>>);  // OCP 之后 total 不再修改
// 现代线：total_area2 模板 + concepts：template<ShapeLike S> double total_area2(span<const S>)

// lsp.hpp：正方形/长方形经典反例
class dp::RectL { public: virtual ~RectL()=default; virtual void set_w(int); virtual void set_h(int); int w() const; int h() const; private: int w_=0,h_=0; };
class dp::SquareL : public RectL { /* set_w 同时设 h —— 违反 LSP */ };
int dp::area_after_resize(RectL&);   // set_w(5); set_h(4); return w*h —— SquareL 上得 16 而非 20

// dip.hpp：高层 Switch 不依赖具体灯
class dp::Switchable { public: virtual ~Switchable()=default; virtual void on()=0; virtual void off()=0; };
class dp::Light : public Switchable;  class dp::Fan : public Switchable;
class dp::Switch { public: explicit Switch(Switchable&); void toggle(); bool is_on() const; };

// isp.hpp：胖接口 Machine（print/fax/scan）拆三个小接口；OldPrinter 只实现需要的
// lod.hpp：客户只认识直接朋友——Wallet::pay(Merchant) 内部经 invoice，不摸 customer.wallet().money()
// crp.hpp：组合优先——Player 持 unique_ptr<Weapon>（Strategy 雏形）而非继承 Sword
```

**章节 assert 规格：**

- **01**：打印 23 模式三分法清单（创建 5/结构 7/行为 11，逐行列名）；assert 断言 `5+7+11==23`；`static_assert(__cplusplus >= 202302L || _MSVC_LANG >= 202302L)` 佐证标准档；打印三书分工表（固定文本）。
- **02**：SRP——坏版 `Employee` 三职责混一次演示（不 assert，正文讲解）；好版 `calculate_pay`（base+hours*rate）、`format_report` 含 name 与金额行；OCP——`total_area({Circle(1), Rect(2,3)})==7.0`；`total_area2` 模板版同值；再放一个新形状进 total_area 不改任何旧代码（编译即证，正文点破）。
- **03**：LSP——`area_after_resize(RectL)` 得 20，`area_after_resize(SquareL)` 得 16，两个值都打印并 assert 各自值（正文讲"为什么 16 是坏味道"）；DIP——`Switch` 驱动 Light 与 Fan 各 toggle 一次，`is_on` 状态翻转 assert。
- **04**：ISP——OldPrinter 调用 print 成功、不再被迫实现 fax/scan（编译期即证，运行 assert print 结果）；LoD——`pay()` 返回金额 assert，正文画调用链对比图；CRP——`Player` 换武器后 attack 值变化 assert（10→25）。

- [ ] **Step 1: 7 个 hpp + 4 个 main.cpp（末行 `std::println("自检通过")`）**
- [ ] **Step 2: 双通道逐示例验证**

```bash
pwsh ./build.ps1 -Example 01_intro   # 依次 01…04
./run-all.sh 1 2 3 4
```

- [ ] **Step 3: 4 篇 docs（真实输出粘进正文；每章现代线照 Global Constraints 双线要求）**
- [ ] **Step 4: 全量回归 + 提交**

```bash
pwsh ./build.ps1 -All
cd "G:/code/guide" && git add designpattern
git commit -m "feat(designpattern): 批次二——01-04 开篇与六大原则（双通道全绿）"
```

---

## Task 3: 批次三——创建型篇 5–10 章

素材：之禅创建型篇各章（grep 定位：简单工厂/工厂方法/抽象工厂/单例/原型/建造者）；刘伟对应章（liuwei_toc.txt 定页）；GoF 第 3 章（Creational Patterns）整卷 OCR。

**Files:**

| 章 | 文档 | 示例 | 头文件 |
|---|---|---|---|
| 5 | `docs/05-simplefactory.md` | `examples/05_simplefactory/` | `simple_factory.hpp`, `registry_factory.hpp` |
| 6 | `docs/06-factorymethod.md` | `examples/06_factorymethod/` | `factory_method.hpp` |
| 7 | `docs/07-abstractfactory.md` | `examples/07_abstractfactory/` | `abstract_factory.hpp` |
| 8 | `docs/08-singleton.md` | `examples/08_singleton/` | `singleton.hpp`, `once_singleton.hpp` |
| 9 | `docs/09-prototype.md` | `examples/09_prototype/` | `prototype.hpp` |
| 10 | `docs/10-builder.md` | `examples/10_builder/` | `builder.hpp` |

**Interfaces:**

```cpp
// simple_factory.hpp
struct dp::Shape { virtual ~Shape()=default; virtual std::string name() const=0; };
struct dp::Circle: dp::Shape; struct dp::Square: dp::Shape;
std::expected<std::unique_ptr<dp::Shape>, std::string> dp::create_shape(std::string_view kind);

// registry_factory.hpp：字符串→构造器注册表（自注册雏形）
using dp::ShapeMaker = std::function<std::unique_ptr<dp::Shape>()>;
class dp::ShapeRegistry { public: static ShapeRegistry& instance();
    bool add(std::string kind, ShapeMaker); std::expected<std::unique_ptr<dp::Shape>, std::string> make(std::string_view kind);
    size_t size() const; };

// factory_method.hpp：日志器家族
struct dp::Logger { virtual ~Logger()=default; virtual void log(std::string_view msg)=0; };
struct dp::FileLogger: dp::Logger;  struct dp::ConsoleLogger: dp::Logger;
struct dp::LoggerCreator { virtual ~LoggerCreator()=default; virtual std::unique_ptr<Logger> create() const=0; void use() const; /* 模板方法：create()+log("hi") */ };
struct dp::FileLoggerCreator: LoggerCreator;  struct dp::ConsoleLoggerCreator: LoggerCreator;

// abstract_factory.hpp：控件族 Win/Linux
struct dp::Button { virtual std::string render() const=0; virtual ~Button()=default; };
struct dp::Border { virtual std::string render() const=0; virtual ~Border()=default; };
struct dp::WidgetFactory { virtual std::unique_ptr<Button> make_button() const=0;
                           virtual std::unique_ptr<Border> make_border() const=0; virtual ~WidgetFactory()=default; };
struct dp::WinFactory: WidgetFactory;  struct dp::LinuxFactory: WidgetFactory;
template<typename F> concept WidgetFactoryLike = requires(F f) { {f.make_button()} -> std::convertible_to<std::unique_ptr<Button>>; {f.make_border()}; };
std::string dp::draw_dialog(const WidgetFactory&);  // button+border 渲染拼接

// singleton.hpp：Meyers 单例
class dp::Config { public: static Config& instance(); void set(std::string k, std::string v);
                   std::string get(std::string_view k) const; size_t count() const;
  private: Config()=default; std::unordered_map<std::string,std::string> kv_; };
// once_singleton.hpp：std::call_once + unique_ptr 版，行为同上但可注入构造参数

// prototype.hpp
struct dp::Monster { virtual ~Monster()=default; virtual std::unique_ptr<Monster> clone() const=0;
                     virtual std::string describe() const=0; };
struct dp::Goblin: Monster;  struct dp::GoblinChief: Goblin { /* 覆写 clone 协变、加 buff 计数 */ };
std::vector<std::unique_ptr<dp::Monster>> dp::spawn_wave(const dp::Monster& proto, size_t n);

// builder.hpp：HttpRequest 流式建造
struct dp::HttpRequest { std::string method, url, body; std::vector<std::pair<std::string,std::string>> headers; };
class dp::RequestBuilder { public: RequestBuilder& method(std::string); RequestBuilder& url(std::string);
    RequestBuilder& header(std::string k, std::string v); RequestBuilder& body(std::string);
    HttpRequest build() &&; private: HttpRequest req_; };
// 现代线：designated initializers 一行造 HttpRequest 与 build() 对照；Diretor::construct(RequestBuilder&)
```

**章节 assert 规格：**

- **05**：`create_shape("circle")` 得 name=="circle"；`create_shape("hex")` 返 expected 错误（catch/has_value 双路径 assert）；Registry 注册 2 种后 size()==2、make 未注册返错误；正文讲三段演化：if-else 简单工厂 → 注册表 → 为什么 GoF 认为它不算模式。
- **06**：`use()`（模板方法）对两种 creator 分别打印对应 log 行；`LoggerCreator` 返回类型 `unique_ptr<Logger>` 所有权转移 assert（use 后原指针不可持有）；正文重点：**构造器中不调用工厂方法**（GoF 陷阱）+ C++23 `std::move_only_function` 备选。
- **07**：`draw_dialog(WinFactory)` 含 "win-button/win-border"，Linux 同理；混族编译失败（正文以注释展示被 concepts 拦截的写法）；`static_assert(WidgetFactoryLike<WinFactory>)`。
- **08**：两次 `Config::instance()` 地址相同——**比较 & 打印"相同/不同"字符串而非地址值**；set/get 往返 assert；`call_once` 版构造次数恰 1（静态计数 assert）；正文给单例可测试性反思与依赖注入替代。
- **09**：`spawn_wave(Goblin{}, 3)` 得 3 个独立 describe=="goblin"；改一个不影响其余；GoblinChief::clone 返回 GoblinChief（`typeid`/tag 判定 assert，不打印 typeid 文本以免平台差异——用自定义 `kind()` 虚函数）。
- **10**：RequestBuilder 链式 method/url/header×2/body 后 build 各字段 assert；Director 固定剧本产出一致请求；designated initializer 版与 builder 版逐字段相等；正文讲"何时 builder 才值得"（≥4 参数/不变量校验/多表示）。

- [ ] **Step 1: 10 个 hpp + 6 个 main.cpp**
- [ ] **Step 2: 双通道逐示例验证**（`pwsh ./build.ps1 -Example 05_simplefactory` … `./run-all.sh 5 6 7 8 9 10`）
- [ ] **Step 3: 6 篇 docs（真实输出进正文；两版取舍结论每章必须有）**
- [ ] **Step 4: 全量回归 + 提交** `git commit -m "feat(designpattern): 批次三——05-10 创建型六示例（双通道全绿）"`

---

## Task 4: 批次四——结构型篇 11–17 章

素材：之禅结构型篇各章；刘伟对应章；GoF 第 4 章（Structural Patterns）整卷 OCR。

**Files:**

| 章 | 文档 | 示例 | 头文件 |
|---|---|---|---|
| 11 | `docs/11-adapter.md` | `examples/11_adapter/` | `object_adapter.hpp`, `template_adapter.hpp` |
| 12 | `docs/12-bridge.md` | `examples/12_bridge/` | `bridge.hpp` |
| 13 | `docs/13-composite.md` | `examples/13_composite/` | `composite.hpp`, `variant_composite.hpp` |
| 14 | `docs/14-decorator.md` | `examples/14_decorator/` | `decorator.hpp` |
| 15 | `docs/15-facade.md` | `examples/15_facade/` | `facade.hpp` |
| 16 | `docs/16-flyweight.md` | `examples/16_flyweight/` | `flyweight.hpp` |
| 17 | `docs/17-proxy.md` | `examples/17_proxy/` | `proxy.hpp` |

**Interfaces:**

```cpp
// object_adapter.hpp：旧 VectorStack（Adaptee，push/pop/top）适配成 Target 栈接口
class dp::LegacyStack { public: void push(int); int pop(); int top() const; size_t size() const; };
struct dp::StackLike { virtual ~StackLike()=default; virtual void push(int)=0; virtual int pop()=0; virtual bool empty() const=0; };
class dp::StackAdapter : public StackLike { public: explicit StackAdapter(LegacyStack&); /*…*/ };
// template_adapter.hpp：多继承类适配器 class Adapter : public Target, private LegacyStack

// bridge.hpp：Shape(抽象)×Renderer(实现) 两维
struct dp::Renderer { virtual std::string render_circle(double r) const=0; virtual ~Renderer()=default; };
struct dp::VectorRenderer: Renderer;  struct dp::RasterRenderer: Renderer;
class dp::BridgeCircle { public: BridgeCircle(const Renderer&, double); std::string draw() const; private: const Renderer* r_; double radius_; };
// 现代线：pImpl 对照——class Widget { Widget(); ~Widget(); … std::unique_ptr<Impl> p_; }

// composite.hpp：文件系统树
class dp::FsNode { public: virtual ~FsNode()=default; virtual std::string name() const=0; virtual size_t size() const=0; };
class dp::File: FsNode; class dp::Folder: FsNode { void add(std::unique_ptr<FsNode>); size_t size() const override; /*递归求和*/ };
// variant_composite.hpp：std::variant<FileV, FolderV> + overload 递归 size/depth

// decorator.hpp：流式文本
struct dp::Stream { virtual std::string write(std::string_view s) const=0; virtual ~Stream()=default; };
struct dp::PlainStream: Stream;      // 原样
class dp::UpperDecorator: Stream;    // 转大写
class dp::TimestampDecorator: Stream;// 前缀 [T0]/[T1] 计数器（不用 chrono，静态递增保证确定）
// 逐层包装：Timestamp(Upper(Plain)) 输出可预测

// facade.hpp：编译子系统的 3 个零件 + 一个 compile() 门面
struct dp::Lexer { std::vector<std::string> tokenize(std::string_view); };
struct dp::Parser { size_t parse(std::span<const std::string> tokens); };
struct dp::CodeGen { std::string emit(size_t nodes); };
class dp::Compiler { public: std::string compile(std::string_view src); private: Lexer lex_; Parser par_; CodeGen gen_; };

// flyweight.hpp：字型共享
struct dp::Glyph { char ch; int font; };   // 内蕴状态
class dp::GlyphFactory { public: const Glyph& get(char ch, int font); size_t pool_size() const;
  private: std::map<std::pair<char,int>, std::unique_ptr<Glyph>> pool_; };
size_t dp::render_text(std::string_view text, int font, const GlyphFactory&, std::string& out);
// 100 字符只入池 ≤26 的演示；外蕴状态(位置)在 render 循环里

// proxy.hpp：懒加载图片
struct dp::Image { virtual void draw() const=0; virtual ~Image()=default; };
struct dp::RealImage: Image { explicit RealImage(std::string name); static int constructed; /*静态计数*/ void draw() const; };
class dp::LazyImageProxy: Image { public: explicit LazyImageProxy(std::string); void draw() const override; private: mutable std::unique_ptr<RealImage> real_; };
// 现代线：std::optional 惰性 + shared_ptr 写时复制计数
```

**章节 assert 规格：**

- **11**：StackAdapter push×3/pop 顺序 LIFO assert；类适配器同结果；正文讲对象适配器优先（组合）与私有继承的取舍。
- **12**：`BridgeCircle(VectorRenderer,2).draw()` 含 "vector circle r=2"，Raster 版含 "raster"；pImpl 版行为一致；正文讲两维独立变化与 pImpl 的关系（编译防火墙）。
- **13**：Folder 嵌套 size 递归求和 assert（叶子 1+2+子夹(3)==6）；variant 版 size/depth 同值（depth==2）；正文给两表示的遍历/扩展/性能对照表。
- **14**：`Timestamp(Upper(Plain)).write("hi")`=="[T0]HI"、第二次调用得 "[T1]HI"（计数确定）；三层包装顺序敏感性 assert；正文讲模板 policy 链替代运行时链。
- **15**：`compile("int x = 1;")` 输出 "tokens:5 nodes:1 code"（Lexer/Parser/CodeGen 行为在正文分别演示后由 facade 串联）；assert 含 "nodes:1"。
- **16**：`render_text("mississippi…", …)` 100 字符后 `pool_size()<=26` assert；相同字符返回同一 Glyph（取 `&glyph1==&glyph2` 转布尔 assert，不打印地址）；正文算内存账。
- **17**：`RealImage::constructed==0` → proxy 构造后仍 0 → draw() 后 1（静态计数 assert）；二次 draw 不再构造；正文给代理家族（虚/保护/智能引用）与现代 `optional`/`shared_ptr` 对照。

- [ ] **Step 1: 12 个 hpp + 7 个 main.cpp**
- [ ] **Step 2: 双通道逐示例验证**（11…17）
- [ ] **Step 3: 7 篇 docs**
- [ ] **Step 4: 全量回归 + 提交** `feat(designpattern): 批次四——11-17 结构型七示例（双通道全绿）`

---

## Task 5: 批次五——行为型上篇 18–23 章

素材：之禅行为型篇前半（职责链/命令/解释器/迭代器/中介者/备忘录）；刘伟对应章；GoF 第 5 章相应节 OCR。

**Files:**

| 章 | 文档 | 示例 | 头文件 |
|---|---|---|---|
| 18 | `docs/18-chainofresp.md` | `examples/18_chainofresp/` | `chain.hpp` |
| 19 | `docs/19-command.md` | `examples/19_command/` | `command.hpp` |
| 20 | `docs/20-interpreter.md` | `examples/20_interpreter/` | `interp.hpp`, `variant_interp.hpp` |
| 21 | `docs/21-iterator.md` | `examples/21_iterator/` | `tree.hpp`, `gen.hpp` |
| 22 | `docs/22-mediator.md` | `examples/22_mediator/` | `mediator.hpp` |
| 23 | `docs/23-memento.md` | `examples/23_memento/` | `memento.hpp` |

**Interfaces:**

```cpp
// chain.hpp：报销审批
struct dp::Approver { virtual ~Approver()=default; void set_next(std::unique_ptr<Approver> n);
    std::string handle(int amount); protected: virtual std::string approve(int) const=0; virtual int limit() const=0;
    std::unique_ptr<Approver> next_; };
struct dp::Manager: Approver { int limit() const override { return 1000; } /*…*/ };
struct dp::Director: Approver { int limit() const override { return 5000; } };
struct dp::Ceo: Approver { int limit() const override { return 100000; } };
// 现代线：vector<function<bool(int&)>> 处理器表 + optional 传播
std::string dp::handle_with_table(std::span<const std::function<bool(int)>>, int amount);

// command.hpp：编辑器撤销
class dp::Document { std::string text_; public: void insert(size_t pos, std::string_view s); void erase(size_t pos, size_t n);
    std::string text() const; };
class dp::Command { public: virtual ~Command()=default; virtual void execute()=0; virtual void undo()=0; };
class dp::InsertCommand: Command { /* 记录 pos/内容 */ };
class dp::EraseCommand: Command;   // undo 时回插
class dp::History { public: void push(std::unique_ptr<Command>); bool undo(); size_t size() const; };
// 现代线：std::function 命令 +闭包捕获，undo 用对称 lambda 对

// interp.hpp：后缀布尔表达式树（and/or/not + 变量）
struct dp::BoolExpr { virtual bool eval(std::span<const bool> vars) const=0; virtual ~BoolExpr()=default; };
struct dp::Var: BoolExpr;  struct dp::And: BoolExpr;  struct dp::Or: BoolExpr;  struct dp::Not: BoolExpr;
// variant_interp.hpp：BExprV = variant<VarV, AndV, OrV, NotV>（递归 variant）+ overload eval + 简化规则 fold

// tree.hpp：带父指针的三节点二叉树 + 中序迭代器
template<class T> struct dp::TreeNode { T v; TreeNode *l=nullptr,*r=nullptr; };
template<class T> class dp::Tree { public: void insert(const T&); class inorder_iterator { /* 前向迭代器，栈式中序 */ };
    inorder_iterator begin(); std::default_sentinel_t end(); };
// gen.hpp：协程生成器
// 若 Task 1 探针两通道均支持 <generator>：std::generator<int> fib_gen(int n)；
// 否则手写 cppcoro 风格 minimal_generator<T>（promise_type + iterator 适配 ranges 输入）

// mediator.hpp：聊天室
class dp::ChatRoom { public: void join(std::string name); void send(std::string_view from, std::string_view msg);
    size_t log_size() const; private: /* 名字表+消息日志 "from->msg" */ };
struct dp::User { std::string name; ChatRoom* room; void say(std::string_view); };
// 现代线：信号槽（vector<function<void(string_view,string_view)>> 广播）

// memento.hpp：文本撤销快照
class dp::TextEditor { public: void append(std::string_view); void snapshot(); bool rollback();  // 快照栈
    std::string text() const; size_t snapshots() const; };
// 现代线：不可变 std::string 值语义天然是备忘录；immutable + persistent 思想
```

**章节 assert 规格：**

- **18**：链上 900→Manager、3000→Director、99999→Ceo 各自 approve 名字 assert（返回 "manager"/"director"/"ceo"）；表驱动版同结果；正文讲链断裂/无人接时的默认策略。
- **19**：insert("ab")→insert("cd")→erase→undo×逐次恢复，`History::size` 与 text 状态逐点 assert；function 版对称 undo 等效。
- **20**：`(v0 and (not v1)) or v2` 树在 8 组真值组合下与手算表全等（穷举 assert）；variant 版逐组同值；正文给文法/语法树/解释器三层对应与 variant 简化规则演示。
- **21**：Tree 插入乱序 7 个 int，中序输出升序 assert；`std::default_sentinel` 结束比较有效；fib_gen 前 8 项 assert；正文讲经典迭代器接口在 C++ ranges 时代还剩什么职责。
- **22**：join 3 人 send 2 条 log_size()==2 且日志含 "->" 行；信号槽版订阅者收到的条数 assert；正文讲网状 vs 星型耦合。
- **23**：append×2 → snapshot → append → rollback 后 text 回到快照 assert；snapshots()==1；正文给窄接口/宽接口与不可变值语义的现代省思。

- [ ] **Step 1: 12 个 hpp + 6 个 main.cpp**
- [ ] **Step 2: 双通道逐示例验证**（18…23）
- [ ] **Step 3: 6 篇 docs**
- [ ] **Step 4: 全量回归 + 提交** `feat(designpattern): 批次五——18-23 行为型上六示例（双通道全绿）`

---

## Task 6: 批次六——行为型下篇 24–28 章

素材：之禅行为型篇后半（观察者/状态/策略/模板方法/访问者）；刘伟对应章；GoF 第 5 章相应节 OCR。

**Files:**

| 章 | 文档 | 示例 | 头文件 |
|---|---|---|---|
| 24 | `docs/24-observer.md` | `examples/24_observer/` | `observer.hpp` |
| 25 | `docs/25-state.md` | `examples/25_state/` | `state.hpp`, `variant_state.hpp` |
| 26 | `docs/26-strategy.md` | `examples/26_strategy/` | `strategy.hpp` |
| 27 | `docs/27-templatemethod.md` | `examples/27_templatemethod/` | `template_method.hpp`, `crtp_method.hpp` |
| 28 | `docs/28-visitor.md` | `examples/28_visitor/` | `visitor.hpp`, `variant_visitor.hpp` |

**Interfaces:**

```cpp
// observer.hpp：气象站
class dp::Observer { public: virtual ~Observer()=default; virtual void on_update(double t)=0; };
class dp::Subject { public: void attach(Observer*); void detach(Observer*); void notify(double t);
    size_t count() const; protected: std::vector<Observer*> obs_; };
struct dp::DisplayA: Observer { double last=-999; void on_update(double t) override; };
struct dp::DisplayB: Observer;   // last 值 + 是否收到过（bool received）
// 现代线：vector<std::function<void(double)>> + 移除时迭代器失效坑；线程安全讨论（正文，不真开线程断言）

// state.hpp：自动售货机
struct dp::Vending { virtual ~Vending()=default; virtual std::string coin(int) =0; virtual std::string crank()=0; };
class dp::Machine { public: std::string coin(int v); std::string crank(); std::string state_name() const;
    int credit() const; friend struct states…; private: /* 状态枚举+转换表 或 状态对象 */ };
// variant_state.hpp：StateV = variant<Idle, HasCredit, Dispensing>，机器持 variant，事件→新状态
// assert: 投 5 分不找零/出货/重置三事件的完整序列

// strategy.hpp：折扣
struct dp::Discount { virtual double apply(double o) const=0; virtual ~Discount()=default; };
struct dp::NoDiscount: Discount;  struct dp::PercentDiscount: Discount;  // ctor 收百分数
struct dp::ThresholdDiscount: Discount;  // 满 200 减 30
double dp::checkout(const dp::Discount&, double origin);
// 现代线：using DiscountFn = std::function<double(double)>；concepts 策略 static 分发
template<typename F> concept DiscountLike = requires(F f, double o) { {f(o)} -> std::convertible_to<double>; };

// template_method.hpp：游戏骨架
class dp::Game { public: void run();  // 模板方法：initialize()→take_turn×3→end()
  protected: virtual ~Game()=default; virtual std::string initialize()=0; virtual std::string take_turn(int i)=0; virtual std::string end()=0; };
struct dp::Chess: Game;  struct dp::Go: Game;   // 各自实现，run() 固定剧本
// crtp_method.hpp：template<class D> struct GameCRTP { void run(); … } 静态分发版 + static_cast<D*>(this)->…

// visitor.hpp：图形导出（双重分派）
struct dp::Circle; struct dp::Rect; struct dp::Tri;
struct dp::ShapeV { virtual ~ShapeV()=default; virtual void accept(dp::Visitor&) const=0; };
struct dp::Visitor { virtual ~Visitor()=default; virtual void visit(const Circle&)=0; virtual void visit(const Rect&)=0; virtual void visit(const Tri&)=0; };
// AreaVisitor（返回累计：成员 double total）、JsonVisitor（拼字符串）
// variant_visitor.hpp：ShapeS = variant<CircleS, RectS, TriS>；overload 一处写全；std::visit 对比 accept/visit
```

**章节 assert 规格：**

- **24**：attach 2 个显示板 notify(25.5) 后各自 last==25.5；detach A 后 count()==1 再 notify 只 B 更新；function 版订阅 lambda 收值 assert；正文给观察者 O(n) 通知与失效/线程讨论。
- **25**：序列 coin(25)→crank→"dispense"→回 idle；credit 不足时 crank 提示语句 assert；variant 版逐事件同输出；正文给转换表与 variant 状态机的 exhaustive 收益。
- **26**：三种折扣 100 元结果分别 100/80/100（Threshold 不达门槛）与 260 元 230 assert；function 版与虚版逐点同值；`static_assert(DiscountLike<PercentDiscount>)`；正文讲算法族切换与 lambda 的边界（有状态策略仍需对象）。
- **27**：Chess::run 输出三段固定文本（initialize/turn1..3/end 拼接 assert）；Go 同；CRTP 版输出一致且无虚表（正文讲编译期成本收益）；钩子默认实现演示。
- **28**：三形状进 AreaVisitor total==已知和；JsonVisitor 串含各类型标记；variant 版同 total；正文给双重分派四节点调用序图（shape→visitor→shape）与 variant 缺点（类型封闭）。

- [ ] **Step 1: 10 个 hpp + 5 个 main.cpp**
- [ ] **Step 2: 双通道逐示例验证**（24…28）
- [ ] **Step 3: 5 篇 docs**
- [ ] **Step 4: 全量回归 + 提交** `feat(designpattern): 批次六——24-28 行为型下五示例（双通道全绿）`

---

## Task 7: 批次七——现代专题 29–32 章

素材：GoF 各模式的"实现"节回查（已 OCR 卷复用）；之禅混编篇定位；现代专题以语言能力为主线，书作对照。

**Files:**

| 章 | 文档 | 示例 | 头文件 |
|---|---|---|---|
| 29 | `docs/29-polymorphism.md` | `examples/29_polymorphism/` | `virtual_poly.hpp`, `concept_poly.hpp`, `variant_poly.hpp` |
| 30 | `docs/30-typeerasure.md` | `examples/30_typeerasure/` | `erase.hpp` |
| 31 | `docs/31-logging.md` | `examples/31_logging/` | `logger.hpp` |
| 32 | `docs/32-eventbus.md` | `examples/32_eventbus/` | `eventbus.hpp` |

**Interfaces:**

```cpp
// virtual_poly.hpp / concept_poly.hpp / variant_poly.hpp：同一 Drawable 场景三种实现
//  virtual: struct Drawable{virtual void draw() const=0;}; struct Sq:Drawable; struct Ci:Drawable;
//  concept: template<DrowableLike D> void render(span<const D>);   // 每类型实例化
//  variant: using AnyShape=variant<Sq,Ci>; render(span<const AnyShape>);
// 三版统一合同：render 返回拼接 "sq;ci" 类输出，size 计数

// erase.hpp：手工类型擦除（小 type erasure 完整骨架）
class dp::AnyDrawable { public: template<DrowableLike D> AnyDrawable(D d);  // 内嵌 model<D> : concept_
    void draw() const; size_t id() const; private: struct concept_; template<class D> struct model; std::unique_ptr<concept_> self_; };
// 对照 std::function<void()> 与 function_ref 引用语义（正文讲所有权差异）

// logger.hpp：可扩展日志系统（实战 31）
enum class dp::Level { debug, info, warn, error };
struct dp::Sink { virtual ~Sink()=default; virtual void write(dp::Level, std::string_view msg)=0; };
struct dp::CountSink: Sink;           // 收集 "L<级别号>:<msg>" 便于断言
class dp::Logger { public: void set_level(dp::Level); void add_sink(std::unique_ptr<Sink>);
    void log(dp::Level, std::string_view);  private: std::vector<std::unique_ptr<Sink>> sinks_; dp::Level min_ = dp::Level::debug; };
// 装饰 Sink（PrefixSink）+ 工厂 make_sink(kind)；现代线：模板 Sink policy + std::function sink

// eventbus.hpp：事件总线（实战 32）
struct dp::Evt { std::string topic; std::string payload; };
class dp::EventBus { public: size_t subscribe(std::string topic, std::function<void(const dp::Evt&)>);
    bool unsubscribe(size_t id); void publish(const dp::Evt&);  private: std::unordered_map<std::string,
    std::vector<std::pair<size_t, std::function<void(const dp::Evt&)>>>> subs_; size_t next_id_ = 1; };
// 单测合同：同 topic 两订阅、异 topic 不串、退订后不再收（收包计数器）
```

**章节 assert 规格：**

- **29**：三版 render 输出逐字符相同（"sq;ci"）；正文给编译期实例化数量/错误信息质量/二进制体积三栏对比表（文字论述，不打印尺寸值）；结论：接口稳定选虚函数，类型集合封闭选 variant，纯编译期选 concepts。
- **30**：AnyDrawable 分别装 Sq/Ci/lambda（闭包类型不可名状）draw 均正确 assert；正文逐步实现 concept_/model 并解释虚函数在擦除里的位置。
- **31**：Logger 三级过滤（debug 被滤、info/warn 通过）按 CountSink 收包数 assert；add 两 sink 同条消息双写；PrefixSink 输出前缀 assert；正文按"策略(级别)+装饰(sink)+工厂(make_sink)"混编讲解。
- **32**：订阅 3（topicA×2、topicB×1）publish A 两条各收 2/0，退订一个再 publish 计数变化 assert；id 单调递增 assert（`next_id` 不打印只比大小）。

- [ ] **Step 1: 8 个 hpp + 4 个 main.cpp**
- [ ] **Step 2: 双通道逐示例验证**（29…32）
- [ ] **Step 3: 4 篇 docs**
- [ ] **Step 4: 全量回归 + 提交** `feat(designpattern): 批次七——29-32 现代专题与实战四示例（双通道全绿）`

---

## Task 8: 批次八——实战篇 33–36 章

素材：之禅混编章、GoF 相关实现节回查。

**Files:**

| 章 | 文档 | 示例 | 头文件 |
|---|---|---|---|
| 33 | `docs/33-statemachine.md` | `examples/33_statemachine/` | `fsm.hpp` |
| 34 | `docs/34-objpool.md` | `examples/34_objpool/` | `pool.hpp` |
| 35 | `docs/35-plugins.md` | `examples/35_plugins/` | `plugin.hpp` |
| 36 | `docs/36-evaluator.md` | `examples/36_evaluator/` | `eval.hpp` |

**Interfaces:**

```cpp
// fsm.hpp：编译期状态机（实战 33）
enum class dp::Ev { coin, crank, reset };
enum class dp::St { idle, paid, dispensing };
struct dp::Trans { dp::St from; dp::Ev ev; dp::St to; };
// constexpr 状态机：find_next(span<const Trans>, St, Ev) -> optional<St>；类内 static constexpr 表
// 运行期 Machine 用同表 walk 并记录路径；static_assert(两步 coin,crank: idle→paid→dispensing)
std::vector<dp::St> dp::walk(std::span<const Trans>, dp::St init, std::span<const Ev>);

// pool.hpp：对象池（实战 34）
class dp::Conn { public: explicit Conn(int id); int id() const; bool in_use() const; void release();
  private: int id_; bool used_ = false; friend class Pool; };
class dp::Pool { public: static Pool& instance();
    Conn& acquire();          // 复用空闲或新建，池上限 4，超出 throw runtime_error
    void release(Conn&); size_t created() const; size_t in_use_count() const; };
// RAII 守卫 Connection{Pool&}（析构自动 release）；断言 created 不会因重复 acquire 而虚增

// plugin.hpp：自注册插件框架（实战 35）
struct dp::Codec { virtual ~Codec()=default; virtual std::string name() const=0; virtual std::string encode(std::string_view) const=0; };
class dp::Registry { public: static Registry& instance();
    bool add(std::unique_ptr<Codec>); const dp::Codec* find(std::string_view) const; size_t size() const; };
struct dp::RegisterOne { template<class C> explicit RegisterOne() { Registry::instance().add(std::make_unique<C>()); } };
// 各"插件"cpp：static dp::RegisterOne reg_hex;  main 前 3 个插件已在册（hex/b64/reverse）
std::string dp::encode_with(std::string_view kind, std::string_view data); // find+encode，未知名返 "err"

// eval.hpp：表达式求值器（实战 36：解释器+组合+访问者+备忘录）
// 词法→递归下降→AST（variant 节点：Num/Var/Add/Mul）→ 求值环境 map<string,double>
struct dp::Num { double v; }; struct dp::Var { std::string name; };
struct dp::Add { std::unique_ptr<Ast>, Ast>… };  // 各持两个 std::unique_ptr<Ast>
using dp::Ast = std::variant<Num, Var, Add, Mul>;
std::expected<dp::Ast, std::string> dp::parse(std::string_view src);   // 支持 + * 与标识符，空格容忍
std::expected<double, std::string> dp::eval(const Ast&, std::span<const std::pair<std::string,double>> env);
std::expected<double, std::string> dp::eval_cached(const Ast&, std::span<...>, std::map<std::string,double>& memo); // Var 结果备忘录
```

**章节 assert 规格：**

- **33**：静态表 walk("coin,crank") 路径 [idle,paid,dispensing]；非法事件（crank@idle）返 idle 并计一次拒绝（拒绝计数 assert）；`static_assert` 编译期判定两转移；正文给表驱动 vs 状态对象 vs variant 三版演化。
- **34**：acquire×2 得不同 id（0/1，比较不相等而非打印）；release 后再次 acquire 复用（created 不变）；第 5 个 acquire throw（catch 标记 assert）；RAII 守卫异常路径也归还（in_use_count 归零）。
- **35**：main 直接 find("hex") 命中（自注册已发生，正文讲静态初始化顺序与内联坑——register 静态量须在同 TU）；encode_with("b64","hi") 固定输出 assert；encode_with("nope")=="err"；size()==3。
- **36**：parse("2*x + y") 得 Ast；eval env {x:3,y:4}==10；语法错误 "2+*" 返 expected 错误（has_value()==false assert）；eval_cached 二次求值命中 memo（命中计数 assert）；正文给四模式在 200 行实战里各自承担的角色图。

- [ ] **Step 1: 4 个 hpp + 4 个 main.cpp**
- [ ] **Step 2: 双通道逐示例验证**（33…36）
- [ ] **Step 3: 4 篇 docs**
- [ ] **Step 4: 全量回归 + 提交** `feat(designpattern): 批次八——33-36 实战四示例（双通道全绿）`

---

## Task 9: 批次九——收官 37–40 章 + README/CHEATSheet 定稿

**Files:**

| 章 | 文档 | 示例 | 头文件 |
|---|---|---|---|
| 37 | `docs/37-docexport.md` | `examples/37_docexport/` | `exporter.hpp` |
| 38 | `docs/38-permission.md` | `examples/38_permission/` | `pipeline.hpp` |
| 39 | `docs/39-antipatterns.md` | `examples/39_antipatterns/main.cpp` | — |
| 40 | `docs/40-cheatsheet.md` | `examples/40_cheatsheet/main.cpp` | — |
| — | `README.md`（定稿：三书导读+40 章导航） | | |
| — | `CHEATSheet.md`（定稿） | | |

**Interfaces:**

```cpp
// exporter.hpp：文档导出（抽象工厂+桥+外观）
struct dp::DocElement { virtual ~DocElement()=default; };
struct dp::Para { std::string text; }; struct dp::Table { std::vector<std::string> cells; int cols; };
// Renderer 家族（html/plain）×Document 组装（add_para/add_table）→ Export::render() 一行门面
// 现代线：variant 元素 + overload 渲染器，元素类型增删成本对比

// pipeline.hpp：权限校验管道（职责链+策略+代理）
struct dp::Request { std::string user, action; bool admin = false; int hour = 0; };
struct dp::Verdict { bool allow = false; std::string why; };
using dp::Guard = std::function<bool(dp::Request&, dp::Verdict&)>;   // 返 false 即终止并已填 why
dp::Guard dp::auth_guard();        // user=="anon" 拒
dp::Guard dp::role_guard();        // 非 admin 只许 "read"
dp::Guard dp::time_guard();        // hour<8 或 hour>22 拒
class dp::Api { public: void add_guard(dp::Guard); dp::Verdict check(dp::Request); };
// 代理视角：Api 即真服务的门面守卫（正文讲三者协作分工）

// 39 示例：三个小场景对比"用模式"与"不用"——(a) 一个 lambda 能解决却上 AbstractFactory 的反例；
// (b) 过度装饰链 5 层 vs 两行模板；(c) 单例全局态导致测试污染（同进程两次 Config 冲突演示）。
// main 固定打印三组"症状→改法"，assert 全部改后行为。
```

**章节 assert 规格：**

- **37**：Document(2 段 1 表) 经 HtmlRenderer 得含 "<p>/<table>" 串，PlainRenderer 得 "|---|" 串（各自 assert）；variant 版输出一致；正文给"加一种元素 vs 加一种渲染器"两个方向的修改面分析。
- **38**：anon+write → auth 拒；admin+write@9 → 三关全过 allow；user+read@9 → allow；user+write@23 → time 拒或 role 拒（按管道顺序，why 首字符 assert）；正文画管道切面图。
- **39**：三组改法各 assert（工厂反例收敛为直接调用、装饰收敛为模板、全局态收敛为注入 Config&）；打印症状→改法表。
- **40**：main 打印 23 模式×(一句话意图/现代替代)两栏速查表（固定文本逐行），并 assert 表行数==23；正文为收官长文：模式选择决策树+三书对照总表+学习路线。

- [ ] **Step 1: 2 个 hpp + 4 个 main.cpp**
- [ ] **Step 2: 双通道逐示例验证**（37…40）
- [ ] **Step 3: 4 篇 docs + CHEATSheet.md + README 定稿**
- [ ] **Step 4: 全量回归 + 提交** `feat(designpattern): 批次九——37-40 收官+README/CHEATSheet 定稿（双通道全绿）`

---

## Self-Review 记录

- 章数核对：4+6+7+6+5+4+4+4=40 ✓；slug 与目录名清单一致 ✓。
- `<generator>` 支持性不确定 → Task 1 Step 6 探针 + 21 章降级路径，无悬空假设 ✓。
- 确定性约束：所有涉及"同一性/计数"的断言均转成布尔或计数比较，不打印地址/时间/尺寸 ✓。
- 39 章示例含三组反例，须保证"改后行为"可 assert，规格已给 ✓。
