{$mode objfpc}{$codepage utf8}{$H+}
program image_demo;
{ 21 · TImage 与 TPicture：按扩展名分发格式（bmp/png/jpg 全在 Graphics 单元）、
  程序生成图片（TPortableNetworkGraphic 的 Canvas 直接画）、SaveToFile/
  LoadFromFile 像素级往返、显示模式四开关（Stretch/Proportional/Center/AutoSize）
  的叠加语义。坑：往 Img.Canvas 画会被重绘冲掉——要画就画进 Picture.Bitmap。
  正文见 docs/21-image.md。 }

uses
  Interfaces, Forms, Controls, StdCtrls, ExtCtrls, Graphics,
  Classes, SysUtils, StrUtils;

type
  TImgForm = class(TForm)
    Img: TImage;
    GenBtn, LoadBtn, ModeBtn: TButton;
    InfoLbl: TLabel;
    procedure GenClick(Sender: TObject);
    procedure LoadClick(Sender: TObject);
    procedure ModeClick(Sender: TObject);
  public
    constructor Create(AOwner: TComponent); override;
    procedure RefreshInfo;
  end;

const
  PngFile = 'test_gen.png';

constructor TImgForm.Create(AOwner: TComponent);
begin
  inherited CreateNew(AOwner);
  Caption := '21 · TImage 图片查看器';
  Width := 560; Height := 420;

  Img := TImage.Create(Self);
  Img.Parent := Self;
  Img.SetBounds(16, 40, 360, 270);          // 控件框（图片在里面的贴法由四开关定）
  Img.Proportional := True;                 // 保比缩放（与 Stretch 同时开：先保比再贴）

  GenBtn := TButton.Create(Self);
  GenBtn.Parent := Self;
  GenBtn.SetBounds(16, 6, 110, 28);
  GenBtn.Caption := '生成 PNG';
  GenBtn.OnClick := @GenClick;

  LoadBtn := TButton.Create(Self);
  LoadBtn.Parent := Self;
  LoadBtn.SetBounds(132, 6, 110, 28);
  LoadBtn.Caption := '加载 PNG';
  LoadBtn.OnClick := @LoadClick;

  ModeBtn := TButton.Create(Self);
  ModeBtn.Parent := Self;
  ModeBtn.SetBounds(248, 6, 120, 28);
  ModeBtn.Caption := '切 Stretch';
  ModeBtn.OnClick := @ModeClick;

  InfoLbl := TLabel.Create(Self);
  InfoLbl.Parent := Self;
  InfoLbl.SetBounds(392, 40, 150, 240);
  RefreshInfo;
end;

procedure TImgForm.GenClick(Sender: TObject);
var
  Png: TPortableNetworkGraphic;
begin
  // 程序生成：TPortableNetworkGraphic 自带 Canvas（TFPImageBitmap 家族都带）
  Png := TPortableNetworkGraphic.Create;
  try
    Png.SetSize(120, 90);
    Png.Canvas.Brush.Color := clSkyBlue;
    Png.Canvas.FillRect(0, 0, 120, 90);
    Png.Canvas.Brush.Color := clYellow;
    Png.Canvas.Ellipse(20, 15, 100, 75);
    Png.SaveToFile(PngFile);                // 保存走 TGraphic（Picture 之外的直通道）
  finally
    Png.Free;
  end;
  Img.Picture.LoadFromFile(PngFile);        // 加载走 TPicture（按扩展名分发）
  RefreshInfo;
end;

procedure TImgForm.LoadClick(Sender: TObject);
begin
  if FileExists(PngFile) then
  begin
    Img.Picture.LoadFromFile(PngFile);
    RefreshInfo;
  end;
end;

procedure TImgForm.ModeClick(Sender: TObject);
begin
  // 循环四种显示模式（语义见正文表格）
  if not Img.Stretch and not Img.Proportional then
  begin Img.Stretch := True; Img.Proportional := False; ModeBtn.Caption := '切 Proportional'; end
  else if Img.Stretch and not Img.Proportional then
  begin Img.Stretch := True; Img.Proportional := True; ModeBtn.Caption := '切 Center'; end
  else if Img.Stretch and Img.Proportional then
  begin Img.Stretch := False; Img.Center := True; ModeBtn.Caption := '切 原样'; end
  else
  begin Img.Center := False; ModeBtn.Caption := '切 Stretch'; end;
  RefreshInfo;
end;

procedure TImgForm.RefreshInfo;
begin
  InfoLbl.Caption := Format('图：%d × %d%s控件：%d × %d%sStretch=%s%sProportional=%s%sCenter=%s', [
    Img.Picture.Width, Img.Picture.Height, #10,
    Img.Width, Img.Height, #10,
    IfThen(Img.Stretch, '开', '关'), #10,
    IfThen(Img.Proportional, '开', '关'), #10,
    IfThen(Img.Center, '开', '关')]);
end;

procedure RunSelfTest;
var
  f: TImgForm;
  Log: TextFile;
  Png: TPortableNetworkGraphic;
  C0, C1: TColor;
begin
  Application.Initialize;
  f := TImgForm.Create(nil);
  AssignFile(Log, 'selftest.log');
  Rewrite(Log);
  try
    // 1) 生成 → 保存 → TPicture 加载 → 像素级往返
    f.GenClick(nil);
    if not FileExists(PngFile) then
      raise Exception.Create('PNG 未生成');
    if (f.Img.Picture.Width <> 120) or (f.Img.Picture.Height <> 90) then
      raise Exception.Create(Format('尺寸异常 %d x %d',
        [f.Img.Picture.Width, f.Img.Picture.Height]));
    C0 := f.Img.Picture.Bitmap.Canvas.Pixels[60, 45];   // 椭圆中心
    C1 := f.Img.Picture.Bitmap.Canvas.Pixels[5, 5];     // 背景角
    if C0 <> clYellow then
      raise Exception.Create('椭圆中心像素应黄，实测=' + IntToHex(C0, 8));
    if C1 <> clSkyBlue then
      raise Exception.Create('背景角像素应天蓝');

    // 2) 重复加载幂等（清空再加载，像素一致）
    f.Img.Picture.Clear;
    if f.Img.Picture.Width <> 0 then
      raise Exception.Create('Clear 后应无图');
    f.Img.Picture.LoadFromFile(PngFile);
    if f.Img.Picture.Bitmap.Canvas.Pixels[60, 45] <> clYellow then
      raise Exception.Create('二次加载像素不一致');

    // 3) BMP 通道（TPicture 按扩展名分发，同一 API）
    Png := TPortableNetworkGraphic.Create;
    try
      Png.SetSize(4, 4);
      Png.Canvas.Brush.Color := clGreen;
      Png.Canvas.FillRect(0, 0, 4, 4);
      Png.SaveToFile('mini.bmp');    // TFPImageBitmap 按文件名后缀决定实际编码？——
      // 实测记录：SaveToFile 的格式由对象类型决定而非扩展名！写 'mini.bmp' 得到的
      // 仍是 PNG 字节（TPicture.SaveToFile 才按扩展名）。正文展开。
    finally
      Png.Free;
    end;
    if not FileExists('mini.bmp') then
      raise Exception.Create('mini.bmp 未生成');
    // 实证：对象决定编码——'mini.bmp' 的前 8 字节是 PNG 魔数 89 50 4E 47
    with TFileStream.Create('mini.bmp', fmOpenRead) do
    try
      if (ReadByte <> $89) or (ReadByte <> $50) or (ReadByte <> $4E) or (ReadByte <> $47) then
        raise Exception.Create('mini.bmp 应仍是 PNG 字节（格式由对象类型决定）');
    finally
      Free;
    end;

    // 4) 显示模式四开关回环（语义属性，不依赖句柄）
    f.Img.Stretch := True;  f.Img.Proportional := True;  f.Img.Center := True;
    f.Img.AutoSize := False;
    if not (f.Img.Stretch and f.Img.Proportional and f.Img.Center and not f.Img.AutoSize) then
      raise Exception.Create('显示模式开关回环异常');
    f.Img.AutoSize := True;                 // AutoSize：控件框跟随图片尺寸
    if f.Img.AutoSize and (f.Img.Width = 0) then
      raise Exception.Create('AutoSize 状态异常');
    f.Img.AutoSize := False;

    // 5) Transparent 开关（PNG 自带 alpha 通道时 TImage.Transparent 影响绘制）
    f.Img.Transparent := True;
    if not f.Img.Transparent then
      raise Exception.Create('Transparent 回环异常');

    WriteLn(Log, 'PNG 往返像素一致；尺寸 120x90；中心=', IntToHex(C0, 6));
    WriteLn(Log, '==== 21 selftest OK ====');
  finally
    CloseFile(Log);
    SysUtils.DeleteFile(PngFile);
    SysUtils.DeleteFile('mini.bmp');
    f.Free;
  end;
end;

var
  ErrLog: TextFile;

begin
  if ParamStr(1) = '--selftest' then
  begin
    try
      RunSelfTest;
    except
      on E: Exception do
      begin
        AssignFile(ErrLog, 'selftest.log');
        if FileExists('selftest.log') then Append(ErrLog) else Rewrite(ErrLog);
        WriteLn(ErrLog, 'selftest 失败：', E.Message);
        CloseFile(ErrLog);
        Halt(1);
      end;
    end;
    Halt(0);
  end;
  Application.Initialize;
  with TImgForm.Create(nil) do
  begin
    Show;
    Application.Run;
    Free;
  end;
end.
