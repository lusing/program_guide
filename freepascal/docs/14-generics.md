# 14 · 泛型与容器

## 1. generic / specialize：objfpc 的泛型语法

FPC 的泛型语法与 Delphi 2009+ **不同**——objfpc 模式用两个关键字：

```pascal
type
  generic TBox<T> = class            // 声明加 generic
  private
    FValue: T;
  public
    property Value: T read FValue write FValue;
  end;

  TIntBox = specialize TBox<Integer>;    // 实例化加 specialize
```

> 坑（实测）：`var list: TList<Integer>;` 直接报 `";" expected but "<" found`——
> **objfpc 模式下泛型在任何使用点都要 specialize**（Delphi 模式不用）。惯例是给常用
> 泛型起别名：`TIntList = specialize TList<Integer>;` 之后当普通类型用。

> 坑（实测）：FPC 3.2.2 **没有独立泛型函数**（`generic function MaxOf<T>` 是 3.3+ 特性）
> ——泛型算法要包进泛型类里当 class function（示例 TMath<T>.MaxOf 就是这么落地的）。

`Default(T)` 给出类型零值（Integer=0、string=''、类=nil）——泛型代码里判"空"的标准姿势。

## 2. 约束：给 T 划底线

```pascal
generic TRefList<T: class> = class      // T 必须是类类型
generic TBox2<T: IComparable> = class   // 必须实现某接口
generic TN<T: constructor> = class      // 必须有无参构造
```

约束后 T 拥有对应能力（class 约束可用 `is`/`T.Create`）。无约束时 T 只有 TObject 级能力
——运算符比较都不行（示例 TMath<T>.MaxOf 用 `>`，在 Integer/string 实例化时通过，
record 自定义类型就要自己提供比较器）。

## 3. Generics.Collections 三件套

FPC 3.2.2 自带 `Generics.Collections`（rtl-generics 包，uses 直接可用）——
**新代码一律用它**：

```pascal
type
  TIntList = specialize TList<Integer>;
  TStrList = specialize TList<string>;
  TU8IntDict = specialize TDictionary<UTF8String, Integer>;
  TObjList = specialize TObjectList<TObject>;

var
  list: TIntList;
begin
  list := TIntList.Create;
  list.AddRange([5, 3, 8, 1]);
  list.Sort;                            // 默认比较器升序
  for i in list do ...;                 // 支持枚举
```

| 容器 | 元素语义 | 特点 |
|---|---|---|
| `TList<T>` | 值拷贝 | 动态数组 + 增删查排；Integer/string 直接存 |
| `TObjectList<T>` | 对象引用 | **OwnsObjects 默认 True**——容器 Free 时元素连坐释放 |
| `TDictionary<K,V>` | 哈希表 | Add/TryGetValue/AddOrSetValue/Keys |

**中文键大坑（实测，本章头号坑）**：`TDictionary<string, Integer>` 的键用中文字面量时，
`Add('一', 1)` 之后 `TryGetValue('一', n)` **查不到**——默认比较器对码页标记敏感
（Add 存的键标记 cp65001、查询路径判定不一致；经变量中转或 AddOrSetValue 的标记又不同）。
**可靠配方：键类型用 `UTF8String`**（码页恒 65001，字面量直通，实测全通）；
或键先赋给 `string` 变量、Add 与查询用同一变量。

## 4. 与老容器对照（读老代码用）

| 容器 | 单元 | 状态 |
|---|---|---|
| `TList`（无类型 Pointer 袋） | Classes | 老代码遍地——存取全靠强转，勿新写 |
| `TObjectList` | Contnrs | 无类型版本，同上 |
| `TFPGList<T>` | FGL | 泛型先行者——只支持序数/指针/record，**string/类不行** |
| `TList<T>` 家族 | Generics.Collections | **现代标准** |

老代码迁移：`TList` → `TList<T>`（删强转）、`TObjectList` → `TObjectList<T>`。

## 5. 泛型的价值场景

- **类型安全容器**（编译期拦住 `list.Add('oops')` 混进整数表）
- **零拷贝接口**：TList<UTF8String> 不需要像 TList 那样装对象包一层
- **算法复用**：一份 TMath<T>.MaxOf 服务所有可比较类型
- 14 章之后 GUI 篇直接受益：`TObjectList<TTabSheet>`、`TDictionary<UTF8String, Integer>`
  （24 章记事本+ 的标签页管理与字数统计就是这两个）

## 6. 示例与验证

本章示例 `examples/14_generics`：TBox<T>、TMath<T>.MaxOf（泛型算法包进类的实测理由）、
TRefList<T: class> 约束、三件套容器、中文键对照实验（注释里给了 string 版失败的完整
实验记录）、老容器对照。

```powershell
pwsh -File build.ps1 -Example 14_generics
```

## 7. 坑位清单（实测）

1. **objfpc 泛型处处 specialize**——var/参数里的内联 `TList<Integer>` 是语法错误；
   起别名一劳永逸。
2. **3.2.2 无独立泛型函数**（3.3+ 才有）——泛型算法包进泛型类。
3. **TDictionary<string,...> 中文键查不到**（默认比较器码页敏感）——键类型用 UTF8String。
4. `MaxOf('甲','乙')` 返回'甲'：UTF-8 字节序=码点序（甲 U+7532 > 乙 U+4E59）——
   字符串比较按字节，但中文字典序恰好安全。
5. TObjectList 的 OwnsObjects 默认 True——手动再 Free 元素就是双重释放；要自管传
   `Create(False)`。
6. TFPGList 不支持 string/类元素——见到它就知道是过渡期代码。

---
上一章：[13 OOP II：继承与多态](13-oop2.md) ｜ 下一章：[15 Lazarus 入门](15-lazarus.md) ｜ 返回：[README](../README.md)
