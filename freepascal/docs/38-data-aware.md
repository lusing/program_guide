# 38 · 数据感知控件：SQLDB + SQLite

LCL 生态的看家本领：**控件直连数据库**——DBGrid 显示、DBNavigator 翻页、
改格子回写。这一章用 SQLite（单文件库、零配置）把 SQLDB 三件套、
TDataSource 总线、数据感知控件一次走通。本章的坑位密度是全书第一梯队
——每个都是"不踩不知道"。

## 1. 依赖就位：sqlite3.dll 的零下载方案

TSQLite3Connection 动态加载 `sqlite3.dll`。Windows 10+ 系统自带
`System32\winsqlite3.dll`（公共域库）——复制改名即可（38 工程的
EnsureSqliteDll 在启动时自动做）：

```pascal
if not FileExists('sqlite3.dll') then
  CopyFile(SystemDir + '\winsqlite3.dll', 'sqlite3.dll', False);
```

真实部署随 exe 带官方 sqlite3.dll（或干脆链接静态库——进阶话题）。
本章示例**不提交 dll 进仓库**——它是环境事实不是教程内容。

## 2. 三件套 + 总线：五件东西一条链

```pascal
Conn := TSQLite3Connection.Create(Self);   // ① 连接：哪个库
Conn.DatabaseName := 'demo38.db';

Trans := TSQLTransaction.Create(Self);     // ② 事务：一批操作的边界
Trans.DataBase := Conn;

Query := TSQLQuery.Create(Self);           // ③ 查询：哪批数据（游标）
Query.DataBase := Conn;
Query.Transaction := Trans;
Query.SQL.Text := 'select id, name, score from students order by id';

Src := TDataSource.Create(Self);           // ④ 数据源：控件与数据集的总线
Src.DataSet := Query;

Grid := TDBGrid.Create(Self);              // ⑤ 数据感知控件：挂总线自动跟随
Grid.DataSource := Src;
Nav := TDBNavigator.Create(Self);          //    翻页/增删/提交一排按钮
Nav.DataSource := Src;

Conn.Open;  Trans.StartTransaction;  Query.Open;   // 开闸顺序
```

设计意图：控件**永远不直连 Query**——都挂 TDataSource（一个数据集可以
同时喂 Grid + 若干 DBEdit + Navigator，四处同步）。

## 3. 建库与读数

DDL/DML 走 `ExecuteDirect`（不要结果的语句）+ 事务提交：

```pascal
Conn.ExecuteDirect('create table students (id integer primary key, name text, score integer)');
Conn.ExecuteDirect('insert into students values (1, ''张三'', 77)');
Trans.Commit;                              // 不提交=库里没有
```

读数是游标模型（First/Next/Eof——DBGrid 显示的就是这条游标）：

```pascal
Query.First;
while not Query.Eof do begin
  Log(Query.FieldByName('name').AsString);
  Query.Next;
end;
```

中文值经 `AsString` 正常收发（selftest 实测：'张三'/'李四'/'王五' 全过）。

## 4. 坑（实测，本章头号）：编辑回写五步走

DBGrid 里改一个格子（或代码里 Edit/Post），到数据库落盘是**五步**：

```pascal
Query.Edit;                          // ① 进编辑态
Query.FieldByName('score').AsInteger := 80;
Query.Post;                          // ② 提交进【本地缓冲】
Query.ApplyUpdates;                  // ③ ★ 缓存刷库（这才发 UPDATE）
Trans.Commit;                        // ④ 事务提交
// ⑤ 信任但要验证：重开数据集读回来对一遍
```

**少调 `ApplyUpdates` 的症状**（实测）：一切"成功"、无异常，Commit 也过
——重开数据集，**数据还是旧值**。TSQLQuery 内建缓存更新（cached
updates），Post 只动本地缓冲。DBNavigator 的"提交"按钮内部就是
ApplyUpdates+Commit——点它没问题，自己写代码容易漏。

## 5. 坑（实测，二号）：TEXT 字段是 Memo

SQLite 的 `text` 列在 SQLDB 里默认映射 **ftMemo**——后果：

```pascal
Query.Locate('name', '李四', []);    // ✗ 运行时炸：
// Field "name" has an invalid field type (Memo) to base index on
Query.Locate('id', 2, []);            // ✓ 数值键（integer 主键）没这问题
```

文本定位的替代：小数据遍历比对、大数据 SQL `where` 重查。
（让 text 映射成 ftString 需要在字段设计期手工指定——本教程立足实测默认
行为。）

## 6. 数据感知控件全家

| 控件 | 干什么 |
|---|---|
| `TDBGrid` | 表格显示 + 就地编辑（列宽/列序可配，自绘走 OnDrawColumnCell——27 章功夫） |
| `TDBNavigator` | 首尾/前后/增/删/改/提交/取消/刷新 一排按钮 |
| `TDBEdit`/`TDBText` | 单字段编辑/显示（DataField 指字段） |
| `TDBComboBox`/`TDBCheckBox` | 字段的枚举/布尔编辑 |

它们与 19 章 TStringGrid 的本质差别：**数据主权在数据库**——控件只是
游标的视口；19 章的表格数据在控件里。小工具/纯内存表用 TStringGrid；
有持久化/查询需求走本章。

## 7. 何时不用数据感知

数据感知的甜头是零代码；代价是行为藏在链路里（本章两个坑都是链路的
隐性行为）。经验法则：

- 管理后台/浏览数据 → 数据感知（快）；
- 业务表单（验证/联动多）→ 普通 TEdit + 手动读写 SQLDB（31 章验证器 +
  参数化查询 `Query.Params`）；
- 大结果集 → 只 select 需要的页（`limit/offset`），别 Open 整表。

## 8. 示例与验证

```powershell
pwsh -File build.ps1 -Example 38_data_aware
```

selftest 覆盖：建库建表插三行（含中文）、三件套打开、RecordCount/字段
元数据、游标遍历、总线拓扑断言（Grid/Nav←Src←Query）、编辑回写五步
（重开数据集验证真落库）、Locate 数值键 + 循环文本查找。
（临时 db 文件测试后删除；dll 复制在启动时自动完成。）

## 9. 坑位清单（实测）

1. **Post 后必须 ApplyUpdates**——缓存更新机制：漏了不报错、Commit
   "成功"、数据没变（重开才现形）。
2. **SQLite text 列 = ftMemo**——Locate 文本键直接炸；数值键定位或改用
   SQL where。
3. ExecuteDirect 的 DDL 也要 Commit——建表语句不提交，下个连接看不到。
4. 三件套是一条链：Transaction 没绑 DataBase / Query 没绑 Transaction，
   Open 时才报错（配置错误报得晚）。
5. sqlite3.dll 找不到时报的是连接错误（信息不直说缺 dll）——
   EnsureSqliteDll 放最前。
6. 每次测试删掉旧库文件——"数据怎么不对了"九成是上次的库还在。

---
上一章：[37 高 DPI 深入与暗色主题](37-hidpi-dark.md) ｜ 下一章：[39 调试、性能与部署](39-debug-deploy.md) ｜ 返回：[README](../README.md)
