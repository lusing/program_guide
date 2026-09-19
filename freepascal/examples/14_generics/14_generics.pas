{$mode objfpc}{$codepage utf8}{$H+}
program generics_demo;
{ 14 · 泛型与容器：generic/specialize、约束、Generics.Collections 三件套、
  与 Classes.TList/TFPGList 对照。正文见 docs/14-generics.md。 }
uses SysUtils, Classes, Contnrs, FGL, Generics.Collections;

type
  // ═══ 14.1 自定义泛型：generic 声明 + specialize 实例化（objfpc 语法）
  generic TBox<T> = class
  private
    FValue: T;
  public
    property Value: T read FValue write FValue;
    function IsSet: Boolean;
  end;

  TIntBox = specialize TBox<Integer>;         // specialize 造出具体类
  TStrBox = specialize TBox<string>;

  // 坑（实测）：objfpc 模式下泛型在 var/参数里内联使用也必须写 specialize
  //（Delphi 模式不用）——var list: TList<Integer> 直接报 ";" expected but "<"。
  // 惯例：给常用泛型起别名，用起来干净
  TIntList = specialize TList<Integer>;
  TStrList = specialize TList<string>;
  TU8IntDict = specialize TDictionary<UTF8String, Integer>;   // 键用 UTF8String（见下）
  TObjList = specialize TObjectList<TObject>;

  // ═══ 14.2 约束：class 要求 T 必须是类（可用 is/Free/默认 Create）
  generic TRefList<T: class> = class
  private
    FItems: array of T;
  public
    procedure Add(Item: T);
    function Count: Integer;
  end;

  // 坑（实测）：FPC 3.2.2 没有【独立】泛型函数（3.3+ 才加入）——
  // Syntax error, ";" expected but "<" found。泛型算法要包进泛型类：
  generic TMath<T> = class
    class function MaxOf(const a, b: T): T;    // 需要 T 有 > 运算，实例化时检查
  end;

function TBox.IsSet: Boolean;
begin
  Result := FValue <> Default(T);               // Default(T)：类型零值
end;

class function TMath.MaxOf(const a, b: T): T;
begin
  if a > b then Result := a else Result := b;
end;

procedure TRefList.Add(Item: T);
begin
  SetLength(FItems, Length(FItems) + 1);
  FItems[High(FItems)] := Item;
end;

function TRefList.Count: Integer;
begin
  Result := Length(FItems);
end;

var
  ib: TIntBox;
  sb: TStrBox;
  list: TIntList;                       // Generics.Collections（rtl-generics 包）
  strs: TStrList;
  dict: TU8IntDict;
  ol: TObjList;                         // OwnsObjects 默认 True：自动 Free 元素
  i, n: Integer;
  s: string;
  c: TComponent;
  legacy: TList;
begin
  WriteLn('═══ 14.1 自定义泛型');
  ib := TIntBox.Create;
  try
    ib.Value := 42;
    Assert(ib.Value = 42);
    Assert(ib.IsSet);
  finally
    ib.Free;
  end;
  sb := TStrBox.Create;
  try
    Assert(not sb.IsSet, 'Default(string) 是空串');
  finally
    sb.Free;
  end;
  WriteLn('  TBox<Integer>/TBox<string> 就位，Default(T) 零值机制实测');

  WriteLn('═══ 14.2 约束与泛型算法');
  Assert(specialize TMath<Integer>.MaxOf(3, 9) = 9);
  Assert(specialize TMath<string>.MaxOf('甲', '乙') = '甲',
    'UTF-8 字节比较：甲(U+7532) > 乙(U+4E59)——字节序恰好等于码点序');
  WriteLn('  specialize TMath<Integer>.MaxOf(3,9) = ', specialize TMath<Integer>.MaxOf(3, 9));

  WriteLn('═══ 14.3 Generics.Collections 三件套');
  list := TIntList.Create;
  try
    list.AddRange([5, 3, 8, 1]);
    Assert(list.Count = 4);
    list.Sort;
    Assert((list[0] = 1) and (list[3] = 8));
    Assert(list.IndexOf(8) = 3);
    Write('  TList<Integer> 排序后：');
    for i in list do
      Write(' ', i);
    WriteLn;
  finally
    list.Free;
  end;

  strs := TStrList.Create;
  try
    strs.Add('苹果');
    strs.Add('香蕉');
    Assert(strs[1] = '香蕉');           // 值类型 string 直接存——不用 TObjectList
    WriteLn('  TList<string>[1] = ', strs[1]);
  finally
    strs.Free;
  end;

  // 坑（实测）：键类型用 string（动态码页 AnsiString）时，中文字面量键 Add 后
  // TryGetValue 查不到——默认比较器对码页标记敏感（Add 存 cp65001、查询路径判定不一致，
  // 而经 string 变量进出或 AddOrSetValue 落盘的键标记又不同）。
  // 可靠配方：键类型固定为 UTF8String（码页恒 65001，字面量直通，实测全通）
  dict := TU8IntDict.Create;
  try
    dict.Add('一', 1);
    dict.AddOrSetValue('二', 2);
    Assert(dict['一'] = 1);
    Assert(dict.TryGetValue('三', n) = False);
    Assert(dict.TryGetValue('二', n) and (n = 2));
    WriteLn('  TDictionary<UTF8String, Integer>：Count=', dict.Count,
      ' 二=', dict['二'], '（TryGetValue 双向出参）');
  finally
    dict.Free;
  end;

  ol := TObjList.Create;                // OwnsObjects=True 默认
  try
    c := TComponent.Create(nil);
    ol.Add(c);
    WriteLn('  TObjectList：添加 ', ol.Count, ' 个组件，Free 时自动释放（无需手动）');
  finally
    ol.Free;                            // 里面的 TComponent 在这里被自动 Free
  end;

  WriteLn('═══ 14.4 与老容器对照');
  legacy := TList.Create;               // Classes.TList：无类型（Pointer 袋）
  try
    legacy.Add(Pointer(42));
    Assert(Integer(legacy[0]) = 42);
    WriteLn('  Classes.TList 装 Pointer 要双向强转（Integer(legacy[0])）——泛型版免转');
  finally
    legacy.Free;
  end;
  // TFPGList（FGL 单元）：泛型早于 rtl-generics 的方案，只支持序数/指针/record 元素
  // （string/类都不行）；新代码一律 Generics.Collections
  WriteLn('  TFPGList 是过渡方案（不支持 string/类），新代码用 Generics.Collections');

  WriteLn;
  WriteLn('==== 14 结束 ====');
end.
