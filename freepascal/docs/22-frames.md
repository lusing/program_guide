# 22 · TFrame 与界面复用（⭐）

"地址块、页头、登录条"这种**一组控件的组合**要在多个窗体里重复出现——
复制粘贴三份，改一处忘两处。TFrame 是 LCL 的答案：**可嵌入的迷你窗体**，
一处定义、处处实例、独立状态。本章还做 Frame 继承的实测（LCL 流机制的
深水区）。

## 1. Frame 的标准形态：单元对

Frame 天生与 .lfm 配对——`Create` 从流装配，**没有** `CreateNew` 逃生门
（15 章纯代码窗体的路对 Frame 不存在）：

```text
uaddressframe.pas   类声明 + {$R *.lfm} + 行为方法
uaddressframe.lfm   控件描述（与窗体 lfm 同一种格式，object 开头）
```

```pascal
TAddressFrame = class(TFrame)
  LblName: TLabel;                      // 子控件声明（published 区，流装配靠它）
  EdName: TEdit;
  ...
implementation
{$R *.lfm}                              // 资源配对在这行生效
```

使用处两行：

```pascal
FrameA := TAddressFrame.Create(Self);   // Create 内部完成流装配（子控件全建好）
FrameA.Parent := SomePanel;             // 挂进任意容器——窗体、Panel、另一个 Frame
```

少 .lfm 报 `Resource TAddressFrame not found`——这是"Frame 单元没配对"的
标准症状（漏 {$R *.lfm} 或文件名不匹配都会到这一步）。

## 2. 多实例：状态天然独立

22 工程同时实例化两个 TAddressFrame（一个挂窗体、一个挂 Panel）：

```pascal
FrameA.SetAddress('张三', '北京');
FrameB.SetAddress('李四', '上海');
// 改 B 不影响 A（selftest 断言过）——每个实例有自己的子控件树
```

这就是 Frame 相对"全局窗体"的根本优势：**窗体是单例思维（Form2.ShowModal），
Frame是组件思维（Create 多份）**。

## 3. Frame 是真类：公共 API 与事件

子控件是 published 字段，行为是你写的方法——对外只暴露意图接口：

```pascal
public
  function FullAddress: string;                  // 拼接展示
  procedure SetAddress(const AName, ACity: string);
  procedure ClearAddress;
```

调用方不碰 EdName/EdCity（内部控件可以随便重构，接口不动）。Frame 里的
事件照常工作：`EdName.OnChange` 计数器在 selftest 里验证——TEdit 程序赋值
触发 OnChange 的语义在 Frame 里原样成立（16 章实测，17 章横评表）。

## 4. Frame 继承（实测深水区）

子 Frame 声明为 `class(父Frame)`，配自己的 .lfm——首行 `inherited`：

```pascal
TLangFrame = class(TAddressFrame)     // ulangframe.pas
  CbCountry: TComboBox;               // 代码追加的控件
implementation
{$R *.lfm}
```

```text
inherited AddressFrame: TLangFrame     ← ulangframe.lfm 全文就这么几行
  Height = 92
end
```

**运行机制**（LCL `InitLazResourceComponent` 源码级）：创建 TLangFrame 时
先沿类链递归加载**父类资源**（TAddressFrame 的 lfm 先装配出全部子控件），
再加载子类资源做差异叠加。所以子类 lfm 只写"跟父不一样的地方"。

**实测坑（本章最有价值的发现）**：差异叠加里，**根级属性覆盖没问题**
（Height/Caption 等），但 `inherited LblName: TLabel` 这样的**子控件块
运行时报 Duplicate name**——流装配器把"改 LblName 的属性"当成了"再建一个
LblName"。结论：**子控件属性覆盖写在子类构造器里最稳**：

```pascal
constructor TLangFrame.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);       // 父资源 + 根级差异都装配完
  LblName.Caption := '收件人';    // 子控件覆盖用代码（inherited 块会炸）
  CbCountry := TComboBox.Create(Self);   // 新控件也代码加
  ...
end;
```

继承语义照样完整：`Lang is TAddressFrame` 为真、父级事件处理器直接沿用
（selftest 全断言过）。IDE 里设计时继承另有一套（存储 DFM 差异），本教程
立足命令行/运行时行为，以实测为准。

## 5. 复用手段选型

| 手段 | 适合 | 代价 |
|---|---|---|
| TFrame | 一组控件 + 行为，多处实例 | 单元对（pas+lfm） |
| 组合 Panel（纯代码） | 一次性小组合 | 复用要复制代码 |
| 自定义控件（34 章） | 要上组件面板、跨项目分发 | 写 published、注册 |
| 窗体嵌窗体（29 章） | ❌ 别这么干 | LCL 不支持嵌入 TForm |

## 6. 示例与验证

```powershell
pwsh -File build.ps1 -Example 22_frame
```

界面：地址 Frame ×2（窗体直挂 + Panel 内嵌）+ 继承 Frame（收件人标签 +
国家下拉）。selftest 覆盖：双实例独立性、公共 API、ClearAddress、
TEdit 程序赋值触发 Frame 内事件、`is` 父类判定、lfm 根级覆盖生效、
代码追加控件在位、子类沿用父级事件、嵌套容器关系（Parent=Panel）。

## 7. 坑位清单（实测）

1. **Frame 没有 CreateNew**——Create 必须找到同名 lfm 资源（缺了报
   Resource not found）。
2. 子控件级的 `inherited Xxx` 块在**运行时**流装配报 Duplicate name——
   子控件覆盖写进子类构造器代码（根级属性覆盖没事）。
3. Frame 继承的资源装配是**先父后子递归**（类链向上）——子类 lfm 只写差异。
4. 帧的子控件声明放默认（published）区——流装配按 RTTI 找名字，显式
   private 反而装不上。
5. 挂 Frame 的 Parent 指目标容器（窗体/Panel），Owner 建议传宿主窗体
   （随窗体释放）。
6. 别用"嵌 TForm"做复用——那是 Frame 的活（LCL 的 TForm 不当子控件用）。

---
上一章：[21 图像显示](21-image.md) ｜ 下一章：[23 布局与锚定](23-layout.md) ｜ 返回：[README](../README.md)
