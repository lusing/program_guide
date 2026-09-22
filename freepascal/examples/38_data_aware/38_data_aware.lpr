{$mode objfpc}{$codepage utf8}{$H+}
program data_aware_demo;
{ 38 · 数据感知控件：SQLDB 三件套（TSQLite3Connection + TSQLTransaction +
  TSQLQuery）→ TDataSource → TDBGrid/TDBEdit/TDBNavigator 自动跟随。
  sqlite3.dll 由 selftest 启动时从 System32 的 winsqlite3.dll 复制（公共域库，
  Windows 10+ 自带）——真实部署随 exe 带 dll。正文见 docs/38-data-aware.md。 }

uses
  Interfaces, Forms, Controls, StdCtrls, ExtCtrls, Grids, DBGrids, DBCtrls,
  Graphics, LCLIntf, DB, SQLDB, SQLite3Conn,
  Classes, SysUtils, LazUTF8, Windows;

const
  DbFile = 'demo38.db';

type
  TDbForm = class(TForm)
    Conn: TSQLite3Connection;
    Trans: TSQLTransaction;
    Query: TSQLQuery;
    Src: TDataSource;
    Grid: TDBGrid;
    Nav: TDBNavigator;
    Info: TLabel;
  public
    constructor Create(AOwner: TComponent); override;
    procedure OpenAll;
    function RowCount: Integer;
  end;

constructor TDbForm.Create(AOwner: TComponent);
begin
  inherited CreateNew(AOwner);
  Caption := '38 · 数据感知';
  Width := 620; Height := 420;

  // ── 三件套：连接 → 事务 → 查询（一条链，缺一环 Active 不了）──
  Conn := TSQLite3Connection.Create(Self);
  Conn.DatabaseName := DbFile;

  Trans := TSQLTransaction.Create(Self);
  Trans.DataBase := Conn;              // 事务绑连接

  Query := TSQLQuery.Create(Self);
  Query.DataBase := Conn;
  Query.Transaction := Trans;
  Query.SQL.Text := 'select id, name, score from students order by id';

  // ── 数据源：数据集与控件之间的总线 ──
  Src := TDataSource.Create(Self);
  Src.DataSet := Query;                // 控件都挂 Src，不直连 Query

  // ── 数据感知控件：挂上 Src 自动跟随（显示/导航/编辑回写）──
  Grid := TDBGrid.Create(Self);
  Grid.Parent := Self;
  Grid.Align := alClient;
  Grid.DataSource := Src;

  Nav := TDBNavigator.Create(Self);    // 首尾/翻页/增删/提交/取消 一排按钮
  Nav.Parent := Self;
  Nav.Align := alTop;
  Nav.DataSource := Src;

  Info := TLabel.Create(Self);
  Info.Parent := Self;
  Info.Align := alBottom;
  Info.Height := 24;
end;

procedure TDbForm.OpenAll;
begin
  Conn.Open;
  Trans.StartTransaction;
  Query.Open;                          // 执行 SQL、数据集成型
end;

function TDbForm.RowCount: Integer;
begin
  Result := Query.RecordCount;
end;

procedure EnsureSqliteDll;
var
  SysDir: array[0..260] of Char;
begin
  if FileExists('sqlite3.dll') then Exit;
  // Windows 10+ 自带 winsqlite3.dll（API 集的一部分）——复制一份改名即可
  // （SQLDB 的绑定找的是 sqlite3.dll 这个名字）
  if GetSystemDirectory(@SysDir, 260) > 0 then
    if not CopyFile(PChar(StrPas(@SysDir) + '\winsqlite3.dll'),
      'sqlite3.dll', False) then
      raise Exception.Create('复制 winsqlite3.dll 失败（部署时可随包带 sqlite3.dll）');
end;

procedure RunSelfTest;
var
  f: TDbForm;
  Log: TextFile;
begin
  EnsureSqliteDll;                     // dll 先就位（复制型依赖，不入库）
  Application.Initialize;
  SysUtils.DeleteFile(DbFile);         // 每次跑都是干净库
  f := TDbForm.Create(nil);
  AssignFile(Log, 'selftest.log');
  Rewrite(Log);
  try
    // 1) 建库建表插数据（DDL/DML 走 ExecuteDirect + 事务提交）
    f.Conn.Open;
    f.Trans.StartTransaction;
    f.Conn.ExecuteDirect(
      'create table students (id integer primary key, name text, score integer)');
    f.Conn.ExecuteDirect('insert into students values (1, ''张三'', 77)');
    f.Conn.ExecuteDirect('insert into students values (2, ''李四'', 58)');
    f.Conn.ExecuteDirect('insert into students values (3, ''王五'', 90)');
    f.Trans.Commit;                    // 提交落盘
    f.Conn.Close;

    // 2) 三件套打开 + 数据集读取
    f.OpenAll;
    if f.RowCount <> 3 then
      raise Exception.Create(Format('行数应 3，实测 %d', [f.RowCount]));
    if f.Query.Fields[1].DisplayName <> 'name' then
      raise Exception.Create('字段元数据异常');

    // 3) 遍历数据集（First/Next/Eof 循环——DBGrid 显示的就是这条游标）
    f.Query.First;
    if f.Query.FieldByName('name').AsString <> '张三' then
      raise Exception.Create('首行应张三（中文键值走 AsString 正常）');
    f.Query.Next;
    f.Query.Next;
    if f.Query.FieldByName('name').AsString <> '王五' then
      raise Exception.Create('第三行应王五');

    // 4) 数据感知绑定结构（控件 ← Src ← Query 的总线拓扑）
    if f.Src.DataSet <> f.Query then
      raise Exception.Create('DataSource 应挂 Query');
    if f.Grid.DataSource <> f.Src then
      raise Exception.Create('DBGrid 应挂 DataSource');
    if f.Nav.DataSource <> f.Src then
      raise Exception.Create('DBNavigator 应挂 DataSource');
    if not f.Grid.DataSource.DataSet.Active then
      raise Exception.Create('经总线看数据集应 Active');

    // 5) 编辑回写四步：Edit → 赋值 → Post → ApplyUpdates → Commit
    //    坑（实测，本章头号）：TSQLQuery 内建缓存更新——Post 只进本地缓冲，
    //    少调 ApplyUpdates 的话 Commit 也"成功"、重开后数据还是旧值！
    f.Query.First;
    f.Query.Edit;
    f.Query.FieldByName('score').AsInteger := 80;
    f.Query.Post;
    f.Query.ApplyUpdates;              // ★ 缓存刷库（发 UPDATE）
    f.Trans.Commit;                    // 再提交事务
    f.Query.Close;  f.Query.Open;      // 重开验证（真从库里读）
    f.Query.First;
    if f.Query.FieldByName('score').AsInteger <> 80 then
      raise Exception.Create('编辑未回写数据库');

    // 6) Locate 定位。坑（实测）：SQLite 的 TEXT 在 SQLDB 里映射成 ftMemo——
    //    Locate('name',...) 直接报 invalid field type (Memo)！按数值键定位没这问题
    if not f.Query.Locate('id', 2, []) then
      raise Exception.Create('Locate(id=2) 应命中');
    if f.Query.FieldByName('name').AsString <> '李四' then
      raise Exception.Create('Locate 后游标异常');
    // 文本查找的替代：遍历比对（数据量小）或 SQL where（大）
    f.Query.First;
    while not f.Query.Eof do
    begin
      if f.Query.FieldByName('name').AsString = '李四' then Break;
      f.Query.Next;
    end;
    if f.Query.Eof then
      raise Exception.Create('循环文本查找应命中李四');

    WriteLn(Log, 'Rows=', f.RowCount, ' 中文=',
      f.Query.FieldByName('name').AsString);
    WriteLn(Log, '==== 38 selftest OK ====');
  finally
    CloseFile(Log);
    f.Free;
    SysUtils.DeleteFile(DbFile);
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
  EnsureSqliteDll;
  with TDbForm.Create(nil) do
  begin
    Show;
    OpenAll;
    Application.Run;
    Free;
  end;
end.
