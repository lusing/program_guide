# FreePascal/Lazarus 教程重写实施计划（2026-09-19）

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.
>
> **状态：实施中**

**Goal:** 将 `freepascal/` 重写为对齐 cpp20/zig/julia/freebasic 标准的 24 章教程（docs/ 分章 +
章号=示例目录号 + 递进讲解 + 坑位清单 + CLI 双通道/GUI selftest 多层验证 + 记事本+ 实战收官）。

**Architecture:** 先删旧建新验证骨架（build.ps1/run-all.sh + 02_hello 冒烟），再按批次
"示例先行、正文随后"逐批交付（语言篇 4 批 → GUI 篇 3 批 → 实战 1 批），每批 build.ps1
全绿即提交；最后 01 章/CHEATSheet/README/根 README/记忆收官并全量终验。

**Tech Stack:** FPC 3.2.2 x86_64-win64（Lazarus 自带）、Lazarus 4.8 lazbuild（LCL win32 控件集）、
PowerShell 7（pwsh）、Git Bash（run-all.sh）。

**Spec:** `docs/superpowers/specs/2026-09-19-freepascal-tutorial-rewrite-design.md`（含 §4 环境实测
结论与 §5 章节结构表——本计划的章节内容清单即出自该表，执行时以 spec 为准）

## Global Constraints（实施遵守，摘自 spec §3/§4/§6）

- 工具链：`FPC=G:\scoop\apps\lazarus\current\fpc\3.2.2\bin\x86_64-win64\fpc.exe`、
  `LAZBUILD=G:\scoop\apps\lazarus\current\lazbuild.exe`；脚本按 环境变量 FPC/LAZBUILD → PATH →
  固定路径 顺序探测（旧 build.ps1 的 Resolve-Tool 逻辑可从 `git show HEAD:freepascal/build.ps1` 复用）。
- 编码纪律三件套：源码 **UTF-8 无 BOM + `{$codepage utf8}`**（放 `{$mode objfpc}` 同行旁）+
  运行前 `chcp 65001`（脚本代设）。所有 .pas/.lpr/.lfm/.md 均无 BOM。
- 语言模式全线 `{$mode objfpc}`（方言对照只在 01 章讲，不做第二验证通道）。
- CLI 双通道：检查 `-MObjFPC -Cr -Co -Ci -Sa -B`、发布 `-MObjFPC -O2`；`-FE/-FU/-o` 一律绝对路径
  （相对路径会按源文件目录解析——旧脚本注释里的实测教训）。
- 四条判定（每通道/每个 selftest 日志）：退出码 0、stderr 空、无控制字符（TAB/LF/CR 除外）、
  含标记 `==== NN 结束 ====`（GUI 为 `==== NN selftest OK ====`）；双通道 stdout SHA256 一致
  （不一致 → warn + diff 预览，不算 fail）。任一示例失败脚本 exit 1。
- 确定性纪律（双通道逐字节一致的前提）：随机演示固定 `RandSeed := 42`（不调 Randomize）；
  时间演示用 `EncodeDate/EncodeTime` 固定时刻，Now 只演示不打印；不读 stdin。
- GUI 工程：手写最小 .lpi（模板见下）+ .lpr（`--selftest` 分支）；lazbuild 只认 .lpi；
  exe 落 `lib/$(TargetCPU)-$(TargetOS)/`；selftest 运行 cwd=示例目录，日志 `selftest.log`
  写示例目录（.gitignore 需加 `freepascal/examples/*/selftest.log`）。
- 章正文 200–350 行（⭐ 章不压缩）：`# NN · 标题` 开头、`## 1..N` 分节、每章末 `## N. 坑位清单`
  （3–6 条实测坑）、最后一行导航 `上一章：[..](..) ｜ 下一章：[..](..) ｜ 返回：[README](../README.md)`
  （01 章无上一章、24 章无下一章）。
- CLI 示例骨架（所有 NN_topic.pas 遵守）：

```pascal
{$mode objfpc}{$codepage utf8}{$H+}
program NN_topic;
uses SysUtils;

// ═══ N.M 小节标题（与正文小节号一致）
begin
  // 演示输出 + 关键路径 Assert 自检（{$C+} 下双通道都生效）
  WriteLn('==== NN 结束 ====');
end.
```

- GUI .lpi 模板（已实测 lazbuild 4.8 接受；Units 里列出本工程全部单元）：

```xml
<?xml version="1.0" encoding="UTF-8"?>
<CONFIG>
  <ProjectOptions>
    <Version Value="12"/>
    <PathDelim Value="/"/>
    <General>
      <MainUnit Value="0"/>
      <Title Value="NN_topic"/>
      <UseXPManifest Value="True"/>
    </General>
    <BuildModes Count="1">
      <Item1 Name="Default" Default="True"/>
    </BuildModes>
    <RequiredPackages Count="1">
      <Item1>
        <PackageName Value="LCL"/>
      </Item1>
    </RequiredPackages>
    <Units Count="1">
      <Unit0>
        <Filename Value="NN_topic.lpr"/>
        <IsPartOfProject Value="True"/>
      </Unit0>
    </Units>
  </ProjectOptions>
  <CompilerOptions>
    <Version Value="11"/>
    <PathDelim Value="/"/>
    <SearchPaths>
      <UnitOutputDirectory Value="lib/$(TargetCPU)-$(TargetOS)"/>
    </SearchPaths>
  </CompilerOptions>
</CONFIG>
```

- GUI .lpr selftest 骨架（已实测；`Interfaces` 必须最先 uses；不 Show 窗体）：

```pascal
{$mode objfpc}{$codepage utf8}{$H+}
program NN_topic;
uses Interfaces, Forms, Controls, {按需 StdCtrls/...}, Classes, SysUtils;

procedure RunSelfTest;
var
  f: TForm;
  Log: TextFile;
begin
  Application.Initialize;
  f := TForm.Create(nil);
  // ...创建控件、跑逻辑、Assert 检查（日志只写结果值，不写实时时间）...
  AssignFile(Log, 'selftest.log');
  Rewrite(Log);
  WriteLn(Log, '...结果行...');
  WriteLn(Log, '==== NN selftest OK ====');
  CloseFile(Log);
  f.Free;
end;

begin
  if ParamStr(1) = '--selftest' then
  begin
    RunSelfTest;
    Halt(0);
  end;
  Application.Initialize;
  Application.CreateForm(TMainForm, MainForm); // 或纯代码建主窗体
  Application.Run;
end.
```

- build.ps1：pwsh 7、UTF-8 无 BOM、参数 `-All / -Example NN_topic|-Gui / -Gui / -Clean`；
  CLI 通道目录 `build/check|release/NN_topic.{exe,out,err,build.log}`；GUI 段对 15–24 目录
  逐个 `lazbuild xx.lpi` + 运行 `lib/x86_64-win64/xx.exe --selftest` + 校验 `selftest.log` 四条。
- run-all.sh：Git Bash 等价入口（`chcp.com 65001` 生效于同一控制台后续进程）。
- 提交信息 `docs(freepascal): ...` 风格，末尾 `Co-Authored-By: Claude Code <noreply@anthropic.com>`。
- 实测中新发现的坑随时记入：① 对应章"坑位清单"；② spec §4（追加行）；③ 本计划"执行勘误"节。

## Tasks

### Task 1: 基建——删旧 + 验证骨架 + 冒烟

**Files:**
- Delete: `Free Pascal编程指南.md`、旧 `examples/`（15 项）、旧 `build/`
- Rewrite: `build.ps1`、`run-all.sh`
- Modify: 根 `.gitignore`（若无 `freepascal/examples/*/selftest.log` 规则则补）
- Create: `examples/02_hello/02_hello.pas`（冒烟，正式内容 Task 2 完善）

- [ ] Step 1: `git rm` 旧指南/示例（脚本先不删，Task 1 末统一替换）；从
  `git show HEAD:freepascal/build.ps1` 取 Resolve-Tool/四条判定/Invoke-Tool 骨架复用
- [ ] Step 2: 写新 `build.ps1`（双通道 + GUI selftest 段，参数与目录约定见 Global Constraints）
- [ ] Step 3: 写 `run-all.sh` 等价入口
- [ ] Step 4: 写 02_hello.pas 冒烟示例（WriteLn 中文 + Assert + 结束标记）
- [ ] Step 5: `pwsh -NoProfile -ExecutionPolicy Bypass -File build.ps1 -Example 02_hello`
  → 双通道 [OK] + [same]；`./run-all.sh 02` 同验
- [ ] Step 6: `git rm Free Pascal编程指南.md` + 旧 examples，与新骨架/冒烟示例同批提交
  `docs(freepascal): 重写基建——删旧指南与示例，新 build.ps1/run-all.sh 双通道验证骨架 + 02 冒烟`

### Task 2: 批次 A——语言篇 02–05（4 章 4 示例）

**Files:**
- Create: `docs/02-hello.md`（编码纪律三变体故事展开）、`docs/03-types.md`、`docs/04-control.md`、`docs/05-procedures.md`
- Create: `examples/02_hello/`（完善）、`03_types/`、`04_control/`、`05_procedures/`

- [ ] 示例先行：按 spec §5 主题清单实现 4 个 CLI 示例（03 打印全尺寸表并 Assert 关键值；04 覆盖
  div/mod/case/三循环/for-in/短路；05 覆盖 const/var/out/默认参数/开放数组/重载/递归）
- [ ] 每示例 `-Example NN_topic` 过双通道，再 `-All` 全绿
- [ ] 正文随后：4 章按示例分节（`# ═══ N.M` 对应），坑位清单收实测坑
- [ ] 提交 `docs(freepascal): 02–05 章——第一个程序/类型/控制流/过程 + 四示例双通道验证通过`

### Task 3: 批次 B——语言篇 06–08（3 章 3 示例）

**Files:**
- Create: `docs/06-arrays.md`、`docs/07-strings.md`（⭐码页转换实测展开 spec §4）、`docs/08-records.md`
- Create: `examples/06_arrays/`、`07_strings/`、`08_records/`（含 DLL 调用 + heaptrc 小节演示——
  heaptrc 只写文档不进通道）

- [ ] 示例：06 动态数组/set 运算；07 AnsiString/UTF8String/转换族/Format；08 record 方法与运算符/
  指针/New-Dispose/GetMem/POINTERMATH/过程类型回调/`external 'msvcrt'` printf 实测
- [ ] 双通道全绿（含 -All 回归批次 A）
- [ ] 正文 3 章 + 提交 `docs(freepascal): 06–08 章——数组集合/字符串编码/记录指针（含 DLL 调用与 heaptrc）+ 三示例验证通过`

### Task 4: 批次 C——语言篇 09–11（3 章 3 示例，09 多文件）

**Files:**
- Create: `docs/09-units.md`（含条件编译小节）、`docs/10-exceptions.md`、`docs/11-files.md`
- Create: `examples/09_units/`（main.pas + 2 个单元：几何单元展示 interface/implementation/init/
  循环引用解法）、`10_exceptions/`、`11_files/`（TextFile/typed file/TFileStream/TIniFile/
  固定时刻 FormatDateTime/RandSeed=42）

- [ ] 示例 + 双通道全绿（09 用 build.ps1 显式传多文件或 fpc 编 main 自动拉单元——实测定稿并记录）
- [ ] 正文 3 章 + 提交 `docs(freepascal): 09–11 章——单元工程（多文件）/异常资源/文件序列化 + 三示例验证通过`

### Task 5: 批次 D——语言篇 12–14（3 章 3 示例，语言篇收官）

**Files:**
- Create: `docs/12-oop1.md`、`docs/13-oop2.md`（含接口）、`docs/14-generics.md`
- Create: `examples/12_oop1/`、`13_oop2/`、`14_generics/`（14 用 Generics.Collections——
  fpc 3.2.2 单元路径实测确认，必要时 -Fu 补 rtl-generics 路径）

- [ ] 示例 + 双通道全绿；CLI 全量 `-All`（02–14 共 13 示例）终验
- [ ] 正文 3 章 + 提交 `docs(freepascal): 12–14 章——OOP 封装/继承多态与接口/泛型容器 + 三示例验证，语言篇收官`

### Task 6: 批次 E——GUI 篇 15–17（3 章 3 示例，.lpi/.lfm 定稿）

**Files:**
- Create: `docs/15-lazarus.md`（⭐三件套逐行讲 + lazbuild + 控件集）、`docs/16-controls.md`（⭐基础控件与事件）、`docs/17-more-controls.md`（⭐数值/日期/StringGrid/TabControl/TFrame）
- Create: `examples/15_lazarus_hello/`（纯代码建窗体+按钮+标签，selftest 验 Caption/事件计数）、
  `16_controls/`（输入/按钮/选择/容器矩阵 + 事件日志）、`17_more_controls/`（TrackBar/SpinEdit/
  ProgressBar/DateTimePicker/StringGrid 单元格/TabControl/TFrame）

- [ ] 示例先行：GUI 模板（Global Constraints）逐个实现，`-Example NN` 走 lazbuild + selftest；
  涉及 .lfm 的（15 章教语法）用文本 .lfm 实测 lazbuild 自动编译
- [ ] `-Gui` 全绿 + CLI `-All` 回归
- [ ] 正文 3 章 + 提交 `docs(freepascal): 15–17 章——Lazarus 入门三件套/基础控件事件/更多控件（表格与 TFrame）+ 三 GUI 示例 selftest 验证`

### Task 7: 批次 F——GUI 篇 18–20（3 章 3 示例）

**Files:**
- Create: `docs/18-layout.md`、`docs/19-menus.md`（Action 统一命令）、`docs/20-dialogs.md`
- Create: `examples/18_layout/`（Align/Anchors/Splitter/PageControl 自适应）、`19_menus_actions/`
  （菜单+工具栏+ActionList 三绑定+状态栏）、`20_dialogs/`（Open/Save/Font/Color 对话框 +
  MessageDlg 家族；selftest 用代码路径模拟——对话框不 Show，只验 API 状态）

- [ ] 示例 + `-Gui`/`-All` 全绿（对话框 selftest 只验属性设置/过滤器构造等无 UI 依赖路径）
- [ ] 正文 3 章 + 提交 `docs(freepascal): 18–20 章——布局与高 DPI/菜单工具栏 Action/对话框 + 三示例验证`

### Task 8: 批次 G——GUI 篇 21–23（3 章 3 示例，含 ⭐canvas/⭐threads）

**Files:**
- Create: `docs/21-lists.md`、`docs/22-canvas.md`（⭐双缓冲/鼠标画板——selftest 画到离屏 TBitmap
  断言像素）、`docs/23-threads.md`（⭐TThread/Synchronize vs Queue——selftest 用 CheckSynchronize 泵）
- Create: `examples/21_lists_trees/`（ListView vsReport 排序 + TreeView）、`22_paint/`、`23_threads/`

- [ ] 示例 + `-Gui`/`-All` 全绿（线程示例确定性：固定任务量断言结果汇总）
- [ ] 正文 3 章 + 提交 `docs(freepascal): 21–23 章——列表树视图/Canvas 绘图双缓冲/多线程 + 三示例验证，GUI 篇收官`

### Task 9: 24 章——实战记事本+

**Files:**
- Create: `docs/24-notepad.md`（⭐架构图/数据流/分模块讲解 + selftest→测试思想与 lazbuild/CI 收官一节）
- Create: `examples/24_notepad_plus/`（工程：主窗体单元 + `uchecks.pas` 迷你断言单元；
  功能清单见 spec §5 第 24 行：多标签/编码保存/查找替换/修改跟踪/状态栏/字体只读换行 INI/About/
  --selftest 临时文件开-改-存-比对）

- [ ] 示例：完整实现 + `-Example 24_notepad_plus` 全绿；正常分支人工启动冒烟（截图不需要，确认能开窗即可）
- [ ] 正文 24 章 + 提交 `docs(freepascal): 24 章——实战记事本+（多标签/编码/查找替换/selftest 全功能自检）+ 工程验证通过`

### Task 10: 收官——01 章/CHEATSheet/README/根 README/记忆/终验

**Files:**
- Create: `docs/01-overview.md`（全景：家族史/方言对照表/编译模型/工具链安装/开关总览——吸收全部
  批次实测坑的"元视角"）、`CHEATSheet.md`（语法速查 + 3.2.2/4.8 坑位索引）
- Rewrite: `README.md`（FB 风格：定位段 + ⚠️过时资料警告 + 目录结构 + 24 章索引表 + 工具链 +
  验证命令 + 学习路线）；Modify: 根 `README.md` freepascal 条目
- Create: 记忆 `G:\xulun\.claude\projects\G--code-guide\memory\freepascal-tutorial-build.md` +
  更新 MEMORY.md 索引

- [ ] `pwsh build.ps1 -All`（CLI 13 双通道 + GUI 10 selftest）全绿；`./run-all.sh` 同验
- [ ] 24 章导航链逐章抽查（上一章/下一章链接有效）
- [ ] 提交 `docs(freepascal): 收官——01 全景 + CHEATSheet + README，23 示例多层终验全绿`
- [ ] 写记忆文件（结构 + 全部实测坑位索引）

## 执行勘误（实施中实测发现，随时追加）

（暂无——发现即记：① 对应章坑位清单 ② spec §4 ③ 此处）
