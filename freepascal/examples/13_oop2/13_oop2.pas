{$mode objfpc}{$codepage utf8}{$H+}
program oop2_demo;
{ 13 · OOP II：继承、virtual/override、多态、is/as、类引用、类方法、接口。
  正文见 docs/13-oop2.md。 }
uses
  {$IFDEF UNIX}cwstring,{$ENDIF}   // ★ Unix：必须是 uses 第一个——否则 WriteLn 中文字面量全变 ?（见 02 章 2.3）
  SysUtils, Classes;

type
  // ═══ 13.1/13.2 继承与虚方法
  TShape = class abstract                // abstract 类：不能直接实例化
  protected
    FName: string;
    function Area: Double; virtual; abstract;   // abstract 方法：子类必须实现
    function Perimeter: Double; virtual;        // 虚方法：子类可选改写
  public
    constructor Create(const AName: string);
    function Describe: string;                  // 调虚方法的"模板方法"
    property Name: string read FName;
  end;

  TCircle = class(TShape)
  private
    FRadius: Double;
  protected
    function Area: Double; override;
    function Perimeter: Double; override;
  public
    constructor Create(R: Double);
  end;

  TRect = class(TShape)
  private
    FW, FH: Double;
  protected
    function Area: Double; override;
    function Perimeter: Double; override;
  public
    constructor Create(W, H: Double);
  end;

  // ═══ 13.5 类引用：类型当值传（LCL 里 TComponent.Create(Owner) 的机制源头）
  TShapeClass = class of TShape;

  TShapeFactory = class
  public
    class function Make(AClass: TShapeClass; const AName: string): TShape;
    class var Count: Integer;             // class var：类级变量（全体实例共享）
  end;

  // ═══ 13.7 接口：引用计数的契约
  ISpeaker = interface                    // 接口名 I 前缀
    ['{1B6E9A50-8F2D-4E7B-9C3A-52D1E7F0A001}']   // GUID：可选但建议（COM 需要它）
    function Speak: string;
  end;

  TDog = class(TInterfacedObject, ISpeaker)     // TInterfacedObject：自带引用计数
  public
    function Speak: string;
    destructor Destroy; override;               // 证明引用计数自动回收
  end;

  // implements：把接口实现委托给内部对象（本类不写 Speak，转发给 FDog）
  TRobot = class(TInterfacedObject, ISpeaker)
  private
    FDog: TDog;
  public
    constructor Create;
    destructor Destroy; override;
    property Inner: TDog read FDog implements ISpeaker;   // 委托：接口调用直达内部对象
  end;

constructor TShape.Create(const AName: string);
begin
  inherited Create;
  FName := AName;
end;

function TShape.Perimeter: Double;
begin
  Result := 0;                            // 基类默认：子类按需 override
end;

function TShape.Describe: string;
begin
  // 模板方法：基类定流程，细节留给子类的虚方法（多态的日常用法）
  Result := Format('%s：面积 %.2f，周长 %.2f', [FName, Area, Perimeter]);
end;

constructor TCircle.Create(R: Double);
begin
  inherited Create(Format('圆(r=%.1f)', [R]));
  FRadius := R;
end;

function TCircle.Area: Double;
begin
  Result := Pi * FRadius * FRadius;
end;

function TCircle.Perimeter: Double;
begin
  Result := 2 * Pi * FRadius;
end;

constructor TRect.Create(W, H: Double);
begin
  inherited Create(Format('矩形(%.1fx%.1f)', [W, H]));
  FW := W; FH := H;
end;

function TRect.Area: Double;
begin
  Result := FW * FH;
end;

function TRect.Perimeter: Double;
begin
  Result := 2 * (FW + FH);
end;

class function TShapeFactory.Make(AClass: TShapeClass; const AName: string): TShape;
begin
  Inc(Count);
  // 注意（正文 13.5）：类引用调构造器走的是【基类签名】的构造器（编译期按 TShapeClass
  // 解析）——所以 TRect.Create(W,H) 没被用上，FW/FH 是 0。LCL 的 TComponent.Create
  // 声明为 virtual，正是为了让类引用构造走子类实现（窗体流机制的地基）
  Result := AClass.Create(AName);         // 按实际类造对象（TRect 的实例，但用 TShape 构造器）
end;

function TDog.Speak: string;
begin
  Result := '汪汪';
end;

destructor TDog.Destroy;
begin
  WriteLn('  [TDog 析构]——接口引用归零自动触发');
  inherited Destroy;
end;

constructor TRobot.Create;
begin
  inherited Create;
  FDog := TDog.Create;
end;

destructor TRobot.Destroy;
begin
  FDog.Free;
  inherited Destroy;
end;

procedure ShowPolymorphism;
var
  shapes: array[0..2] of TShape;          // 基类数组装子类实例
  i: Integer;
begin
  shapes[0] := TCircle.Create(1);
  shapes[1] := TRect.Create(3, 4);
  shapes[2] := TCircle.Create(2);
  try
    for i := 0 to 2 do
      WriteLn('  ', shapes[i].Describe);  // 同一调用点，三个实现——运行期按实际类型分派
    Assert(Abs(TCircle(shapes[0]).Area - Pi) < 1e-9);
    // is / as：向下转型的安全带
    Assert(shapes[1] is TRect);
    Assert(not (shapes[1] is TCircle));
    Assert(Abs((shapes[1] as TRect).Area - 12) < 1e-9, 'as 转型后调子类成员');
  finally
    for i := 0 to 2 do
      shapes[i].Free;                     // 基类指针 Free：析构是虚的，子类析构会被调到
  end;
end;

procedure ShowClassRef;
var
  s: TShape;
begin
  s := TShapeFactory.Make(TRect, '工厂造的矩形');
  try
    Assert(s is TRect);
    Assert(TShapeFactory.Count = 1);      // class var 全类共享
    WriteLn('  类引用工厂：', s.Describe, '（累计 ', TShapeFactory.Count, ' 个）');
  finally
    s.Free;
  end;
end;

procedure ShowInterface;
var
  spk: ISpeaker;                          // 接口变量：引用计数自动管理生命周期
begin
  spk := TDog.Create;                     // 对象只经接口引用持有（别同时拿类指针——双重释放坑）
  WriteLn('  ISpeaker → ', spk.Speak);
  spk := nil;                             // 引用归零 → TDog.Destroy 自动执行（见析构输出）
  WriteLn('  归零自动析构 ✓（类世界要手动 Free，接口世界免了）');

  spk := TRobot.Create;                   // implements 委托：Speak 实际由内部的 FDog 提供
  WriteLn('  TRobot 委托 → ', spk.Speak);
  spk := nil;                             // Robot 析构（内部 FDog.Free 也在析构里）
end;

begin
  WriteLn('═══ 13.1/13.2 继承与虚方法');
  ShowPolymorphism;
  WriteLn('═══ 13.5 类引用与类方法');
  ShowClassRef;
  WriteLn('═══ 13.7 接口与引用计数');
  ShowInterface;
  WriteLn;
  WriteLn('==== 13 结束 ====');
end.
