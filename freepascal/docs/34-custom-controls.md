# 34 · 自定义控件与组件开发（⭐）

控件库里没有你要的？27 章学会了"往别人的控件里画"，本章学会**造自己的
控件**：published 属性、自绘、行为，一套下来你写的东西和原生控件用起来
没有区别——还能进 IDE 组件面板（注册流程）分发给别的项目。

## 1. 两系基类：句柄系与无句柄系

```text
TControl
 ├── TGraphicControl   无句柄：只画，不占系统资源、不能持焦点/收键盘
 └── TWinControl       有句柄：真窗口，能持焦点、收键盘、当容器
      └── TCustomControl  ← 自绘控件的家（= 句柄 + 一张 Canvas）
```

选型一句话：**要交互（点击/键盘/嵌子控件）→ TCustomControl；纯展示装饰
（徽章/水印/背景）→ TGraphicControl**。34 工程两系各写了一个：
TValueBar（可点的值条）与 TBadgeLabel（纯画徽章）。

编译器替你把关（实测）：`Badge is TWinControl` 直接**编译错**（类不相关）、
`Badge.TabStop` 也编译错（无句柄系没这属性）——两系的边界在类型系统里，
写错过不了编译。

## 2. 控件的完整解剖（uvaluebar.pas 全文可查）

```pascal
TValueBar = class(TCustomControl)
private
  FValue: Integer;
  procedure SetValue(AValue: Integer);   // setter：钳制 + Invalidate
...
published
  property Value: Integer read FValue write SetValue default 0;
  property Max: Integer read FMax write SetMax default 100;
  property BarColor: TColor read FBarColor write SetBarColor default clTeal;
  property Align;      // 祖先的有用属性放行（TCustomControl 默认全护着）
  property OnClick;
```

四条铁律：

1. **setter 必调 Invalidate**——"数据变了必须请求重绘"，忘了就是"改值
   不刷新"的经典 bug。同值早退（`if AValue = FValue then Exit`）省一次
   无效重绘。
2. **值域联动重钳**——Max 收紧后 Value 立刻钳（17 章值域控件的家族纪律；
   selftest 断言 Max 50 时 Value 500 → 50）。
3. **default 指令**——声明属性默认值：等于 default 的值**不写进 .lfm 流**
   （35 章看得见效果），构造器里还得显式初始化（default 只是"存储约定"
   不是"赋值"）。
4. **published 放行**——TCustomControl 把属性全藏在 protected，你挑有用的
   重新 published（Align/OnClick/Hint…），用户在 IDE 属性面板看到的才是
   你批准过的。

## 3. Paint：27 章功夫的兑现

```pascal
procedure TValueBar.Paint;
var BarW: Integer;
begin
  Canvas.Brush.Color := clBtnFace;
  Canvas.FillRect(0, 0, Width, Height);          // 背景
  BarW := (Width - 4) * FValue div FMax;          // 按比例
  Canvas.Brush.Color := FBarColor;
  Canvas.FillRect(2, 2, 2 + BarW, Height - 2);    // 值条
  Canvas.TextOut(6, ..., Format('%d/%d', [FValue, FMax]));
end;
```

27 章的规则全部适用：只在 Paint 里画（冲掉逻辑）、 Invalidate 驱动重绘、
双缓冲由基类的 ControlStyle 管（csOpaque 不设即透明底）。区别只是身份：
那时你在**别人的** OnPaint 里画，现在 Paint 是**你自己类的方法**——
绘制逻辑随类走，这就是"控件"与"窗体代码"的分界。

## 4. 行为：覆写 Click

```pascal
procedure TValueBar.Click;
begin
  Value := FValue + 10;     // 点一下涨 10（到顶钳住）
  inherited Click;          // ★ 再跑用户的 OnClick——别吞挂接
end;
```

覆写交互方法（Click/DblClick/KeyDown…）是控件"自带行为"的写法；
`inherited` 调用保住用户挂的事件——忘写就是"我的控件OnClick 不触发"
的又一个人工坑。

## 5. 注册进 IDE 组件面板

命令行/纯代码用控件不需要注册（uses 单元即可）——本章工程就这样。要
进 IDE 面板（拖拽使用）加一个注册单元：

```pascal
unit valuereg;
uses ComponentEditors;   // 实为：procedure Register; 无需特殊 uses
procedure Register;
begin
  RegisterComponents('教程控件', [TValueBar, TBadgeLabel]);
end;
```

再打包成**包**（.lpk：File → New → Package，把两个单元加进去，IDE 里
"编译并安装"）——面板出现新页，拖进窗体、属性面板编辑 published、存进
.lfm 流（35 章）。命令行工程想用包内的控件则要在 .lpi 的
RequiredPackages 挂包（18 章 DateTimeCtrls 同款机制）。

## 6. 什么时候不用自定义控件

| 场景 | 更合适的 |
|---|---|
| 一处窗体的特殊绘制 | OnPaint + TPaintBox（27 章） |
| 一组控件打包复用 | TFrame（22 章） |
| 跨项目分发、IDE 拖拽 | 本章（自定义控件 + 包） |
| 全新交互范式 | 本章 + 30 章 WndProc 拦截 |

## 7. 示例与验证

```powershell
pwsh -File build.ps1 -Example 34_custom_controls
```

selftest 覆盖：published 回环、Value 越界钳、Max 收紧联动重钳、
Click 行为（+10×2）、放行的祖先属性、两系身份（is 判定）、
default 初值（新实例）。

## 8. 坑位清单（实测）

1. setter 忘 `Invalidate` → "改值不刷新"（全控件通用铁律）。
2. 覆写 Click/KeyDown 忘 `inherited` → 用户的 OnXxx 挂接被吞。
3. `default` 只是存储约定——构造器里仍要显式初始化初值。
4. TCustomControl 的属性默认全在 protected——不放行 published 用户
   在 IDE 里看不到。
5. TGraphicControl 写 `is TWinControl`/`TabStop` 编译器直接拒——
   两系边界在类型系统。
6. 自绘坐标用 ClientWidth/ClientHeight 语义（Paint 的 Width/Height 即
   客户区——无 NC 区）。

---
上一章：[33 剪贴板与拖放](33-clipboard-dnd.md) ｜ 下一章：[35 组件流与对象持久化](35-component-stream.md) ｜ 返回：[README](../README.md)
