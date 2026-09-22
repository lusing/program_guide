{$mode objfpc}{$codepage utf8}{$H+}
unit uvaluebar;
{ 34 · 自定义控件：TValueBar = class(TCustomControl)——published 属性（流可存）、
  setter 里 Invalidate（改值必须请求重绘）、Paint 自绘、Click 行为、
  default 指令的存储语义。TBadgeLabel = class(TGraphicControl)——无句柄轻量版。
  见 docs/34-custom-controls.md。 }

interface

uses
  Classes, SysUtils, Controls, Graphics, StdCtrls, LMessages;

type
  TValueBar = class(TCustomControl)
  private
    FValue: Integer;             // 0..Max
    FMax: Integer;
    FBarColor: TColor;
    procedure SetValue(AValue: Integer);
    procedure SetMax(AValue: Integer);
    procedure SetBarColor(AValue: TColor);
  protected
    procedure Paint; override;   // 自绘控件的心脏（27 章的功夫在这兑现）
  public
    constructor Create(AOwner: TComponent); override;
    procedure Click; override;   // 点一下 +10——行为也是控件的一部分
  published
    // published：能进 .lfm 流、能进 IDE 属性面板（35 章联动）
    property Value: Integer read FValue write SetValue default 0;
    property Max: Integer read FMax write SetMax default 100;
    property BarColor: TColor read FBarColor write SetBarColor default clTeal;
    // 把祖先的有用属性放行到 published（TCustomControl 默认全护着）
    property Align;
    property Color;
    property Enabled;
    property OnClick;
    property OnDblClick;
    property ParentColor;
    property ShowHint;
    property Hint;
  end;

  { TGraphicControl 系：没有句柄（不占系统资源、不能持焦点/收键盘），
    只管画——静态徽章/装饰的最佳性价比 }
  TBadgeLabel = class(TGraphicControl)
  private
    FBgColor: TColor;
    procedure SetBgColor(AValue: TColor);
  protected
    procedure Paint; override;
  public
    constructor Create(AOwner: TComponent); override;
  published
    property BgColor: TColor read FBgColor write SetBgColor default clSilver;
    property Align;
  end;

implementation

constructor TValueBar.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  // ControlStyle 微调：csClickEvents 已含——我们要标准点击语义
  FValue := 0;
  FMax := 100;
  FBarColor := clTeal;
  Width := 160;                  // 默认尺寸（IDE 拖出来的初始大小）
  Height := 20;
end;

procedure TValueBar.SetValue(AValue: Integer);
begin
  if AValue > FMax then AValue := FMax;      // 钳制（17 章值域控件的家族纪律）
  if AValue < 0 then AValue := 0;
  if AValue = FValue then Exit;              // 不变不动（省一次重绘）
  FValue := AValue;
  Invalidate;                                // ★ 数据变了通知重绘——setter 铁律
end;

procedure TValueBar.SetMax(AValue: Integer);
begin
  if AValue < 1 then AValue := 1;
  if AValue = FMax then Exit;
  FMax := AValue;
  if FValue > FMax then FValue := FMax;      // 值域变了要重钳
  Invalidate;
end;

procedure TValueBar.SetBarColor(AValue: TColor);
begin
  if AValue = FBarColor then Exit;
  FBarColor := AValue;
  Invalidate;
end;

procedure TValueBar.Paint;
var
  BarW: Integer;
begin
  // 背景（满宽暗色）
  Canvas.Brush.Color := clBtnFace;
  Canvas.FillRect(0, 0, Width, Height);
  // 值条（按比例）
  if FMax > 0 then
  begin
    BarW := (Width - 4) * FValue div FMax;
    Canvas.Brush.Color := FBarColor;
    Canvas.FillRect(2, 2, 2 + BarW, Height - 2);
  end;
  // 值文字
  Canvas.Font.Color := clBlack;
  Canvas.TextOut(6, (Height - Canvas.TextHeight('0')) div 2,
    Format('%d/%d', [FValue, FMax]));
end;

procedure TValueBar.Click;
begin
  Value := FValue + 10;          // 点一下涨 10（到顶钳住）
  inherited Click;               // 再跑 OnClick（别吞用户的挂接）
end;

{ TBadgeLabel }

constructor TBadgeLabel.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FBgColor := clSilver;
  Width := 80; Height := 24;
end;

procedure TBadgeLabel.SetBgColor(AValue: TColor);
begin
  if AValue = FBgColor then Exit;
  FBgColor := AValue;
  Invalidate;
end;

procedure TBadgeLabel.Paint;
begin
  Canvas.Brush.Color := FBgColor;
  Canvas.FillRect(0, 0, Width, Height);
  Canvas.Brush.Color := clGray;
  Canvas.FrameRect(Rect(0, 0, Width, Height));
end;

end.
