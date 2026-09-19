{$mode objfpc}{$codepage utf8}{$H+}
program oop1_demo;
{ 12 · OOP I：类与封装——class 声明、Create/Free、property、访问级别、
  同单元无隐私坑、Self、TObject。正文见 docs/12-oop1.md。 }
uses SysUtils;

type
  // ═══ 12.1 最小的类：字段 + 方法 + 构造
  TCounter = class
  private
    FCount: Integer;                     // 字段命名惯例 F 前缀（Field）
  public
    constructor Create(Initial: Integer = 0);
    procedure Inc_;
    function Value: Integer;
  end;

  // ═══ 12.2/12.3 property：字段的外交通道（可带校验）
  TBankAccount = class
  private
    FBalance: Currency;                  // 私有存储
    FOwner: string;
    procedure SetBalance(NewValue: Currency);   // 写通道走校验
  protected
    function FeeRate: Double; virtual;   // protected：子类可改写（13 章用）
  public
    constructor Create(const Owner: string);
    property Owner: string read FOwner;                  // 只读属性（直通字段）
    property Balance: Currency read FBalance write SetBalance;  // 读写属性（写走方法）
  end;

  // ═══ 12.4 同单元无隐私：private 只"对外单元"成立
  TSecret = class
  private
    FHidden: string;
  public
    constructor Create;
  end;

constructor TCounter.Create(Initial: Integer);
begin
  inherited Create;                      // 先构造祖先（TObject.Create）——惯例放第一行
  FCount := Initial;
end;

procedure TCounter.Inc_;
begin
  Inc(FCount);
end;

function TCounter.Value: Integer;
begin
  Result := FCount;
end;

constructor TBankAccount.Create(const Owner: string);
begin
  inherited Create;
  FOwner := Owner;
  FBalance := 0;
end;

procedure TBankAccount.SetBalance(NewValue: Currency);
begin
  if NewValue < 0 then
    raise Exception.Create(Format('余额不能为负：%m', [NewValue]));
  FBalance := NewValue;
end;

function TBankAccount.FeeRate: Double;
begin
  Result := 0.01;
end;

constructor TSecret.Create;
begin
  inherited Create;
  FHidden := '秘密';
end;

var
  cnt: TCounter;
  acct: TBankAccount;
  sec: TSecret;
  obj: TObject;
begin
  WriteLn('═══ 12.1 类 = 指针 + 方法表');
  cnt := TCounter.Create(10);            // 类变量是引用（指针）——Create 在堆上造对象
  try
    cnt.Inc_;
    cnt.Inc_;
    Assert(cnt.Value = 12);
    WriteLn('  计数器：10 + 2 = ', cnt.Value);
  finally
    cnt.Free;                            // 类必须手动 Free（没有引用计数——接口才有）
  end;

  WriteLn('═══ 12.2/12.3 property 与校验');
  acct := TBankAccount.Create('张三');
  try
    Assert(acct.Owner = '张三');
    acct.Balance := 100;                 // 走 SetBalance 校验
    Assert(acct.Balance = 100);
    try
      acct.Balance := -1;                // 写通道拒绝非法值
      Assert(False, '不会到达');
    except
      on E: Exception do
        Assert(Pos('不能为负', E.Message) > 0);
    end;
    WriteLn('  账户：Owner=', acct.Owner, ' Balance=', acct.Balance, '（负值被属性校验拦截）');
  finally
    acct.Free;
  end;

  WriteLn('═══ 12.4 同单元无隐私');
  sec := TSecret.Create;
  try
    // 同一单元内直接摸 private 字段【编译通过】——private 只跨单元生效！
    sec.FHidden := '同单元直接改私有字段';
    Assert(sec.FHidden = '同单元直接改私有字段');
    WriteLn('  同单元访问 private 字段：编译器放行（跨单元才会报错）');
  finally
    sec.Free;
  end;

  WriteLn('═══ 12.5 TObject：万物之祖');
  obj := TCounter.Create(1);             // 祖先指针可引用任何后代
  try
    Assert(obj is TCounter);
    Assert(obj.ClassName = 'TCounter');
    WriteLn('  ClassName=', obj.ClassName, '  ToString=', obj.ToString);
  finally
    obj.Free;
  end;

  WriteLn('═══ 12.6 FreeAndNil 与悬垂防线');
  cnt := TCounter.Create(5);
  FreeAndNil(cnt);                       // Free + 置 nil：双重 Free/悬垂引用当场暴露
  Assert(cnt = nil);
  cnt.Free;                              // nil 上调 Free 合法（TObject.Free 内置 nil 检查）
  WriteLn('  FreeAndNil 后再 Free 不炸（Free 有 nil 保护）；但别依赖——统一 FreeAndNil');
  WriteLn;
  WriteLn('==== 12 结束 ====');
end.
