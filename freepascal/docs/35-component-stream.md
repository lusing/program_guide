# 35 · 组件流与对象持久化（⭐）

从 15 章起每个 `.lfm` 都在悄悄干活：{$R *.lfm} 把文本描述变成活生生的控件
树。本章拆开这台机器：**.lfm 是什么、怎么写出来、怎么读回去**——掌握它，
"保存界面布局""导出配置""克隆控件"都是流水线操作。

## 1. .lfm 的真相：组件树的文本序列化

35 工程把一个 TPanel（内含按钮）写成了文本流（selftest.log 有全文）：

```text
object SrcPanel: TPanel
  Left = 16
  Height = 80
  ...
  Caption = '源面板'
  object InnerBtn: TButton      ← 子控件递归嵌套
    Left = 8
    ...
  end
end
```

三个事实：

- 写出：`WriteComponentAsTextToStream(Txt, AComponent)`（LResources 单元）；
- **只有 published 属性落流**（RTTI 是序列化的眼睛——34 章 published 的
  又一个理由）；
- **无 Name 的组件不落流**（`Name := 'InnerBtn'` 不是装饰）。

## 2. 读回：从文本重建组件树

```pascal
RegisterClass(TPanel);  RegisterClass(TButton);   // 类解析表先备好
Restored := TPanel.Create(nil);
ReadComponentFromTextStream(Txt, TComponent(Restored), @FindClass, nil, nil);
```

**坑（实测，本章头号）**：`OnFindComponentClass` 参数**必须给**——LCL 的
`ReadComponentFromBinaryStream` 拿到 nil 也会直接调用它（源码里没有
nil 检查），AV 就地正法。自备一个走 RegisterClass 表的：

```pascal
procedure TStreamForm.FindClass(Reader: TReader; const AClassName: string;
  var AClass: TComponentClass);
begin
  AClass := TComponentClass(GetClass(AClassName));
end;
```

读回后 `FindComponent('InnerBtn')` 拿到重建的按钮——整棵树属性全在
（selftest 逐项断言 Caption/子数）。

## 3. default 指令的存储语义（流级实证）

34 章说 `default` 是"存储约定"——现在用流验证它到底存不存：

```pascal
TMiniCfg = class(TComponent)
published
  property X: Integer read FX write FX default 7;   // 声明默认 7
  property Y: Integer read FY write FY;             // 无 default
```

实测结果（断言在 selftest）：

| 状态 | 落流？ |
|---|---|
| X = 7（等于 default） | **省略**（流里没有 X 行） |
| Y = 42（无 default） | 落 `Y = 42` |

两点推论：**.lfm 里没写的属性 = 读回后取类默认值**（15 章那些"lfm 缺行"
的疑惑全解）；default 只管存储、不管赋值——构造器里 `FX := 7` 还得手写
（34 章铁律 3 的实证）。

## 4. 二进制通道：.res 里就是它

fpc 编译 `{$R *.lfm}` 时把文本转成二进制资源（`LRSObjectTextToBinary`），
运行时装载走二进制。直接用二进制持久化（更紧凑）：

```pascal
WriteComponentAsBinaryToStream(Bin, Cfg);              // 写
ReadComponentFromBinaryStream(Bin, Cmp, @FindClass, nil, nil);   // 读
```

**坑（实测）**：裸用 `TWriter.WriteComponent`/`TReader.ReadComponent` 缺
"根组件头"仪式（`Driver.BeginRootComponent` 配对）直接 AV——上面的封装
函数内部替你做了。想看仪式长什么样，读 lresources.pp 的
ReadComponentFromBinaryStream 实现（BeginReferences → BeginRootComponent →
ReadComponent → FixupReferences）。

## 5. 流的应用谱系

| 场景 | 做法 |
|---|---|
| 窗体资源（.lfm→.res） | fpc 编译期自动（15 章） |
| 保存/恢复界面布局 | WriteComponentAsTextToStream 存到用户目录 |
| 克隆控件 | 写出→读回（同一流装到新实例） |
| 配置对象持久化 | 自制 TComponent 子类 + published（比手写 INI 省心） |
| 跨进程传组件 | 文本流天然可 diff、可手改 |

与 11 章 INI 的分工：INI 存**标量配置**（路径/开关），组件流存**对象状态**
（整棵控件树的属性）——布局恢复用它，不是 INI。

## 6. 示例与验证

```powershell
pwsh -File build.ps1 -Example 35_component_stream
```

selftest 覆盖：写出文本的语法特征（object 行/属性行）、读回整树（根属性/
子组件重建/属性值）、default 省略与落流、二进制往返、同一流多轮装载。

## 7. 坑位清单（实测）

1. **OnFindComponentClass 传 nil = AV**（无 nil 检查，源码直调）——自备
   GetClass 转发器，RegisterClass 表先注册。
2. 裸 TReader/TReader 缺根组件头仪式 = AV——用 LCL 的
   Read/WriteComponentAsBinaryStream 封装。
3. 无 Name 的组件**不落流**（root 与子组件都一样）。
4. default 只省存储不赋初值——构造器手工初始化不能省。
5. 类型声明区里不能夹过程实现（program 结构：type 区整块在前）——
   编译器报 "BEGIN expected" 时先看是不是实现插错了段。
6. 只有 published 属性可流——private 字段想持久化先开属性（34 章）。

---
上一章：[34 自定义控件与组件开发](34-custom-controls.md) ｜ 下一章：[36 国际化](36-i18n.md) ｜ 返回：[README](../README.md)
