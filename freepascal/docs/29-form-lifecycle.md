# 29 · 应用与窗体生命周期（⭐）

15–28 章控件都是"窗体里的零件"；本章把镜头拉远看**窗体本身**：它从生到死
发哪些事件、什么顺序；Show 与 ShowModal 的本质差别；关闭前的否决权；
以及 LCL 的招牌复用术——**窗体继承**。

## 1. 事件顺序实测（selftest.log 的证据链）

29 工程把生命周期事件逐个记录，无头实测结论：

```text
Create(nil)        → （构造器本体——纯代码窗体没有 OnCreate！）
Show               → OnShow → OnActivate
（另一个窗体激活） → OnDeactivate（本窗体）
Close              → OnCloseQuery → OnClose
Free               → OnDestroy（最后一个）
```

三条实测要点：

1. **纯代码窗体（CreateNew）没有 OnCreate**。OnCreate 是 IDE 生成窗体的
   机制（`Create` 从 .lfm 流装配完回调它）；我们 15 章起的纯代码路线里，
   **构造器就是你的 OnCreate**——初始化代码直接写在 Create 里。
2. **OnCloseQuery 拦得住 Close**（`CanClose := False` 后实测：序列停在
   OnCloseQuery，OnClose 不来，窗体可见性不变）——"有未保存修改"的弹窗
   就挂在这。
3. OnShow 先于 OnActivate（先"显示出来"再"成为活动窗体"）。OnDeactivate/
   OnHide 只在相应时刻发，顺序依赖用户操作，别写依赖它们的时序逻辑。

## 2. OnClose 的 TCloseAction：四种死法

```pascal
procedure TLifeForm.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  CloseAction := caHide;   // 你说了算
end;
```

| 值 | 语义 | 用在 |
|---|---|---|
| `caNone` | 拒绝关闭（窗体留着） | 极少用（否决应该走 OnCloseQuery） |
| `caHide` | 隐藏不销毁（**默认**） | 常驻窗体：下次 Show 秒开、状态保留 |
| `caFree` | 销毁窗体 | 一次性对话框/子窗体 |
| `caMinimize` | 最小化代替关闭 | 托盘程序（32 章 TrayIcon 配套） |

**坑**：`caFree` 内部走 `Release`（**异步**——等消息循环空了才真释放）。
Close 之后立刻访问窗体字段在 caHide 下没事、在 caFree 下是竞态。托盘化
程序的标准姿势：OnClose 里 `Action := caHide + TrayIcon.Visible := True`。

## 3. Show vs ShowModal：消息循环的两个用法

```pascal
Form2.Show;              // 非模态：立刻返回，两个窗体都能点（OnClose 常配 caHide）
Form2.ShowModal;         // 模态：内嵌一个消息循环，直到 ModalResult ≠ 0 才返回
```

ShowModal 的返回值是 `ModalResult`——按钮上直接设（ubaseform.lfm 里
`ModalResult = 1` 即 mrOk）：

```pascal
if AdvForm.ShowModal = mrOk then   // 用户点了"确定"
  ApplySettings;
```

模态循环里点击设了 ModalResult 的按钮 → 窗体关闭 → ShowModal 返回该值。
**无头验证没法跑 ShowModal**（会进内嵌消息循环挂住）——selftest 只断言
ModalResult 的纯逻辑（mrOk=1/mrCancel=2 的设定值），交互层留给人工。
这也是 25 章一以贯之的策略：**可无头测试的逻辑剥成纯函数**。

## 4. 窗体继承：class(TBaseForm) + inherited .lfm

LCL 的招牌复用术（Delphi 血统）。三件套：

```pascal
// 子窗体声明
TAdvForm = class(TBaseForm)      // ubaseform.pas 的父：LblTitle + BtnOk/BtnCancel
```

```text
inherited BaseForm: TAdvForm     ← uadvform.lfm 全文
  Caption = '高级设置'
  Height = 160
end
```

```pascal
constructor TAdvForm.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);                 // 父资源先装配（按钮全建出来）
  LblTitle.Caption := '高级设置（子窗体改的）';   // 子控件覆盖走代码
end;
```

机制与坑和 22 章 Frame 继承**完全同源**（`InitLazResourceComponent` 沿类链
递归加载父资源，再叠加子资源差异）：

- **根级属性覆盖**（Caption/Height/…）写 inherited lfm——实测生效；
- **子控件块**（`inherited LblName: TLabel`）运行时报 Duplicate name——
  子控件属性覆盖写进子类构造器代码；
- 子窗体 `is TBaseForm` 为真，父级事件处理器直接沿用。

工程价值：一套"基座对话框"（标题 + 确定取消 + 边距），十个子对话框各自
只写差异。IDE 里是"File → New → 继承的窗体"；命令行就是上面三件套。

## 5. 与 Application 对象的关系

`Application: TApplication`（Forms 单元的全局）是应用级枢纽，常用的几个：

- `Application.Initialize`——进任何窗体操作前调一次（selftest 也不例外）；
- `Application.Run`——**主消息循环**：取消息→翻译→分发，直到主窗体关；
- `Application.ProcessMessages`——"手动泵一把消息"（29 的 selftest 靠它
  不进 Run 也能让 Show/Close 的事件送达；长循环里防"无响应"也是它，
  但要防重入——30 章消息循环全解）；
- `Application.Terminate`——请求退出循环（不立即断，当前代码跑完）；
- `Application.MainForm`——主窗体（`.lpr` 里第一个 Create 的、传给 Run 的）。

主窗体关闭 = 应用退出（消息循环结束）——"关了主窗体别的窗体还活着"不是
bug 是设计（主窗体是生命周期锚点）。

## 6. 示例与验证

```powershell
pwsh -File build.ps1 -Example 29_form_lifecycle
```

selftest 覆盖：Show 事件顺序（OnShow→OnActivate）、Close 顺序
（OnCloseQuery→OnClose）、CanClose 否决（序列停在 OnCloseQuery、窗体
可见性不变）、CloseAction 参数回写、ModalResult 设定值、窗体继承
（父按钮装配/inherited 根级覆盖/代码改子控件/is 判定）、Free→OnDestroy。

## 7. 坑位清单（实测）

1. **纯代码窗体（CreateNew）没有 OnCreate**——构造器本体就是它；
   OnCreate 属于 .lfm 流装配路线。
2. `caFree` 走异步 Release——Close 后立刻碰窗体字段是竞态。
3. ShowModal 无头环境挂死——selftest 只测 ModalResult 纯逻辑。
4. 窗体继承的子控件级 inherited 块运行时 Duplicate name（同 22 章）——
   覆盖写代码。
5. OnActivate/OnDeactivate 顺序随用户操作漂移——别在它们里写时序依赖。
6. 主窗体关闭即应用退出——别的窗体的释放责任在 Owner 链。

---
上一章：[28 多线程与后台任务](28-threads.md) ｜ 下一章：[30 事件系统与消息循环](30-events-messages.md) ｜ 返回：[README](../README.md)
