{$mode objfpc}{$codepage utf8}{$H+}
program lists_demo;
{ 26 · 列表与树视图：TListBox（多选/样式）、TListView（vsReport 列/子项/排序/选中）、
  TTreeView/TTreeNode（层级 + Data 指针 + 遍历）。正文见 docs/26-lists.md。 }

uses
  Interfaces, Forms, Controls, StdCtrls, ComCtrls,
  Classes, SysUtils;

type
  TPerson = class                        // 挂在树节点 Data 上的对象
    Name: string;
    Age: Integer;
    constructor Create(const AName: string; AAge: Integer);
  end;

  TEmpRec = record                       // 虚拟模式的数据层（自管存储）
    Name: string;
    Age: Integer;
  end;

  TDemoForm = class(TForm)
    Lst: TListBox;
    View: TListView;
    VList: TListView;                    // OwnerData 虚拟列表
    Tree: TTreeView;
    Log: TMemo;
    procedure VListData(Sender: TObject; Item: TListItem);
  public
    Emps: array of TEmpRec;              // 一万行住数组里，不住控件里
    constructor Create(AOwner: TComponent); override;
    function SelectedCount: Integer;
  end;

constructor TPerson.Create(const AName: string; AAge: Integer);
begin
  inherited Create;
  Name := AName;
  Age := AAge;
end;

constructor TDemoForm.Create(AOwner: TComponent);
var
  i: Integer;
  li: TListItem;
begin
  inherited CreateNew(AOwner);
  Caption := '26 · 列表与树';
  Width := 760; Height := 480;

  // ── TListBox：多选与样式 ──
  Lst := TListBox.Create(Self);
  Lst.Parent := Self;
  Lst.Align := alLeft;
  Lst.Width := 180;
  Lst.MultiSelect := True;               // Ctrl/Shift 多选
  Lst.ExtendedSelect := True;
  Lst.Items.Add('苹果');
  Lst.Items.Add('香蕉');
  Lst.Items.Add('橘子');
  Lst.Items.Add('葡萄');
  Lst.Items.Add('西瓜');

  // ── TListView（vsReport 报表视图）：列 + 子项 ──
  View := TListView.Create(Self);
  View.Parent := Self;
  View.Align := alClient;
  View.ViewStyle := vsReport;            // 大图标/小图标/列表/报表四种视图
  View.RowSelect := True;
  View.ReadOnly := True;
  with View.Columns.Add do begin Caption := '姓名'; Width := 90; end;
  with View.Columns.Add do begin Caption := '年龄'; Width := 60; end;
  with View.Columns.Add do begin Caption := '城市'; Width := 90; end;
  for i := 0 to 2 do
  begin
    li := View.Items.Add;                // Add 返回主项（第 0 列）
    li.Caption := Format('员工%d', [i + 1]);       // 第 0 列
    li.SubItems.Add(IntToStr(25 + i * 5));          // 第 1 列起全叫 SubItems
    li.SubItems.Add(Format('城市%d', [i + 1]));     // 第 2 列
    li.Data := TPerson.Create(li.Caption, 25 + i * 5);   // 任意对象挂 Data（Pointer）
  end;

  // ── TListView 虚拟模式（OwnerData）：万行不卡 ──
  SetLength(Emps, 10000);
  for i := 0 to High(Emps) do
  begin
    Emps[i].Name := '员工' + IntToStr(i);
    Emps[i].Age := 20 + i mod 40;
  end;
  VList := TListView.Create(Self);
  VList.Parent := Self;
  VList.SetBounds(240, 150, 220, 130);
  VList.ViewStyle := vsReport;
  VList.RowSelect := True;
  with VList.Columns.Add do begin Caption := '姓名'; Width := 90; end;
  with VList.Columns.Add do begin Caption := '年龄'; Width := 60; end;
  VList.OwnerData := True;               // 开虚拟：不再真灌 Items
  VList.Items.Count := Length(Emps);     // 只声明行数
  VList.OnData := @VListData;            // 可见行按需取数

  // ── TTreeView：层级树 ──
  // 坑（实测）：Items[] 是【深度优先】线性化序，建完树后 [3] 不再是"第 4 个插入的"——
  // 按索引回填 Data 会挂错节点（AV/张冠李戴）。要挂数据就用 AddChild 的返回值：
  Tree := TTreeView.Create(Self);
  Tree.Parent := Self;
  Tree.Align := alRight;
  Tree.Width := 200;
  Tree.Items.AddChild(nil, '公司');
  Tree.Items.AddChild(Tree.Items[0], '研发部');
  Tree.Items.AddChild(Tree.Items[0], '市场部');
  with Tree.Items.AddChild(Tree.Items[1], 'Pascal 组') do   // 挂在"研发部"下
    Data := TPerson.Create('组长', 35);
  Tree.Items[0].Expanded := True;

  Log := TMemo.Create(Self);
  Log.Parent := Self;
  Log.Align := alBottom;
  Log.Height := 90;
  Log.ReadOnly := True;
end;

function TDemoForm.SelectedCount: Integer;
var
  i: Integer;
begin
  Result := 0;
  for i := 0 to Lst.Items.Count - 1 do
    if Lst.Selected[i] then              // 多选状态按索引查
      Inc(Result);
end;

procedure TDemoForm.VListData(Sender: TObject; Item: TListItem);
begin
  // Item.Index = 数据下标：赋完即显示（列表框只构造可见行的壳）
  Item.Caption := Emps[Item.Index].Name;
  Item.SubItems.Add(IntToStr(Emps[Item.Index].Age));
end;

procedure RunSelfTest;
var
  f: TDemoForm;
  Log: TextFile;
  node: TTreeNode;
  p: TPerson;
  depthSum, i: Integer;
begin
  Application.Initialize;
  f := TDemoForm.Create(nil);
  AssignFile(Log, 'selftest.log');
  Rewrite(Log);
  try
    // ── ListBox ──
    if f.Lst.Items.Count <> 5 then
      raise Exception.Create('ListBox 数量异常');
    f.Lst.Selected[1] := True;           // 程序化多选
    f.Lst.Selected[3] := True;
    if f.SelectedCount <> 2 then
      raise Exception.Create('多选计数异常');
    // 实测：程序化 Selected[i] 赋值【不】联动 ItemIndex（保持 -1/原值）——
    // 要焦点+选中一起设用 Lst.ItemIndex := i（单选语义），多选状态另管
    WriteLn(Log, 'ListBox：5 项，多选 2 项（1,3），ItemIndex=', f.Lst.ItemIndex,
      '（程序化 Selected 不联动 ItemIndex——实测）');

    // ── ListView ──
    if f.View.Items.Count <> 3 then
      raise Exception.Create('ListView 项数异常');
    if f.View.Items[1].SubItems.Count <> 2 then
      raise Exception.Create('子项数量异常');
    if f.View.Items[1].SubItems[0] <> '30' then
      raise Exception.Create('子项内容异常');
    f.View.Items[0].Selected := True;
    if f.View.Selected = nil then
      raise Exception.Create('ListView 选中异常');
    p := TPerson(f.View.Selected.Data);
    if (p.Name <> '员工1') or (p.Age <> 25) then
      raise Exception.Create('Data 对象读取异常');
    WriteLn(Log, 'ListView：3 行 3 列，Selected.Data=', p.Name, '/', p.Age);

    // 排序（按 Caption 字符串序）
    f.View.Items[2].Caption := '员工0';
    f.View.AlphaSort;                    // 主项字符串排序
    if f.View.Items[0].Caption <> '员工0' then
      raise Exception.Create('AlphaSort 异常');
    WriteLn(Log, 'ListView.AlphaSort → 首行=', f.View.Items[0].Caption);

    // ── 虚拟 ListView（OwnerData）──
    if f.VList.Items.Count <> 10000 then
      raise Exception.Create('OwnerData Count 应为 10000（纯计数器）');
    if not f.VList.OwnerData then
      raise Exception.Create('OwnerData 应回环 True');
    // 访问任意行都合法——内部现调 OnData 装壳
    if f.VList.Items[9999].Caption <> '员工9999' then
      raise Exception.Create('第 9999 行数据异常：' + f.VList.Items[9999].Caption);
    if f.VList.Items[9999].SubItems[0] <> IntToStr(20 + 9999 mod 40) then
      raise Exception.Create('第 9999 行年龄异常');
    // 数据层更新 + Invalidate = 虚拟模式的"改行"（LCL 无 VCL 的逐行 UpdateItems）
    f.Emps[0].Name := '改名了';
    f.VList.Invalidate;                  // 整体重取（可见行会重新走 OnData）
    if f.VList.Items[0].Caption <> '改名了' then
      raise Exception.Create('数据层更新后应重取');

    // ── TreeView ──
    for i := 0 to f.Tree.Items.Count - 1 do
    begin
      if f.Tree.Items[i].Parent <> nil then
        WriteLn(Log, Format('  节点[%d] "%s" Level=%d Parent="%s"', [i,
          f.Tree.Items[i].Text, f.Tree.Items[i].Level, f.Tree.Items[i].Parent.Text]))
      else
        WriteLn(Log, Format('  节点[%d] "%s" Level=%d Parent=<根>', [i,
          f.Tree.Items[i].Text, f.Tree.Items[i].Level]));
    end;
    // 坑（实测）：Items[] 是【深度优先】线性化顺序，不是 AddChild 的插入顺序——
    // 本树 DFS 序：公司[0] 研发部[1] Pascal组[2] 市场部[3]（市场部第 3 个插入却排最后）
    if f.Tree.Items.Count <> 4 then
      raise Exception.Create('树节点数量异常');
    if f.Tree.Items[2].Text <> 'Pascal 组' then
      raise Exception.Create('DFS 序断言失败');
    if f.Tree.Items[2].Parent.Text <> '研发部' then
      raise Exception.Create('父子关系异常');
    if f.Tree.Items[2].Level <> 2 then
      raise Exception.Create('层级深度异常');
    depthSum := 0;
    for i := 0 to f.Tree.Items.Count - 1 do
      depthSum += f.Tree.Items[i].Level;
    if depthSum <> 4 then                // 0+1+2+1（DFS 序）
      raise Exception.Create('层级遍历异常');
    p := TPerson(f.Tree.Items[2].Data);
    if p.Age <> 35 then
      raise Exception.Create('树节点 Data 异常');
    node := f.Tree.Items[2].GetFirstChild;   // 叶子节点无孩子
    if node <> nil then
      raise Exception.Create('叶子节点不应有孩子');
    WriteLn(Log, 'TreeView：4 节点（DFS 序）深度和=4，叶子 Data.Age=', p.Age);
    WriteLn(Log, '==== 26 selftest OK ====');
  finally
    CloseFile(Log);
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
  with TDemoForm.Create(nil) do
  begin
    Show;
    Application.Run;
    Free;
  end;
end.
