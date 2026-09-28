# 20 · 实战项目：客房管理系统

> 对应示例：`examples/20_project/csharp`（C# 三层实现：登录门卫 + MDI 主界面 + 入住/退房/查询/关于五窗体 + SQLite）

> **本章你将学会**：把前 19 章串成一个完整应用：三层架构落地、登录门卫、MDI 子窗体调度、业务闭环（入住→在住→结账→历史）。
> **前置章节**：全部。

## 1. 需求与设计（对照书第 11 章）

书的实战项目是酒店管理系统（11.2 概要设计 → 11.3 数据库 → 11.4 实体 → 11.5 DAL → 11.6 BLL → 11.7 表示层七个界面）。本教程按同一骨架做**客房管理**核心环，现代替换：SQL Server → SQLite、DataSet → 直接实体类。

### 功能清单

| 功能 | 窗体 | 用到的章 |
|---|---|---|
| 登录门卫 | `LoginForm` | 03（模态/DialogResult） |
| MDI 主界面 + 菜单 | `MainForm` | 08、10 |
| 入住登记（选空房） | `CheckInForm` | 06（ComboBox） |
| 退房结账（预估/账单） | `CheckOutForm` | 07（ListBox 装对象） |
| 住客查询（在住/历史） | `QueryForm` | 07（ListView.Details） |
| 关于 | `AboutForm` | 03（对话框形态） |

### 数据模型

```text
rooms(number PK, type, price, occupied)          7 间种子房
stays(id PK AUTOINCREMENT, room, name, phone,
      checkin, checkout, checkedout, roomprice)  入住记录（checkedout=0 即"在住"）
```

退房时 `UPDATE rooms SET occupied=0` + `UPDATE stays SET checkedout=1, checkout=now`——**状态一致性由 DAL 的一个方法保证**（事务没开，教学版可接受；生产化清单见 §6）。

## 2. 分层落地的样子

```text
csharp/
├── Models.cs        Room / StayRecord（实体，含计算属性 Nights/Status）
├── HotelDb.cs       数据层：Rooms/CheckIn/CheckOut/ActiveStays/Search（全部参数化）
├── Program.cs       入口 + LoginForm
├── MainForm.cs      MDI 容器 + 菜单（static HotelDb Db 单例）
├── CheckInForm.cs / CheckOutForm.cs / QueryForm.cs / AboutForm.cs
└── HotelApp.csproj  Microsoft.Data.Sqlite 10.0.0
```

UI 层只调用 `HotelDb` 的方法，**一行 SQL 都不见**——18 章雏形的完全体。`MainForm.Db` 静态属性是最简的单例注入（教学取舍）；正式项目走构造注入或 DI 容器。

## 3. 登录门卫：DialogResult 当通行证

```csharp
using (var login = new LoginForm())
    if (login.ShowDialog() != DialogResult.OK)
        return;                          // 没登录，MainForm 根本不创建

Application.Run(new MainForm());
```

`LoginForm` 里"账号不对就拦下"的写法（03 章的进阶用法）：

```csharp
ok.Click += (s, e) =>
{
    if (_user.Text.Trim() != "admin" || _pwd.Text != "1234")
    {
        MessageBox.Show(this, "账号或密码不对（演示：admin / 1234）", …);
        DialogResult = DialogResult.None;   // ★ 拦下"确定"：窗体不关，ShowDialog 不返回 OK
    }
};
```

`DialogResult.None` 是"明明点了确定却不让关窗"的正解。

## 4. MDI 子窗体调度：同类只开一份

```csharp
private void OpenChild<T>() where T : Form, new()
{
    foreach (Form f in MdiChildren)
        if (f is T existing) { existing.Activate(); return; }   // 已开着：激活
    var child = new T { MdiParent = this };
    child.Show();
}
```

入住/退房/查询三个业务窗体由菜单/快捷键（Ctrl+N/U/F）调度——10 章 `MdiChildren` 的实战应用。

## 5. 业务闭环的两个细节

**入住选空房**——ComboBox 只装 `Rooms(occupied: false)` 的结果，办理完立刻重载：

```csharp
MainForm.Db.CheckIn(roomNumber, _name.Text.Trim(), _phone.Text.Trim());
ReloadRooms();       // 房态刷新，别的窗体下次拉取自然最新
```

**退房的"对象装进 ListBox"**（07 章 Tag 模式的同族技巧）：

```csharp
private record StayTag(long Id, string Desc)
{
    public override string ToString() => Desc;    // ListBox 显示用
}
_stays.Items.Add(new StayTag(st.Id, $"{st.CheckIn:MM-dd HH:mm}  {st.RoomNumber} 房  …"));
…
if (_stays.SelectedItem is not StayTag tag) return;
decimal bill = MainForm.Db.CheckOut(tag.Id);      // 结账在 DAL：一锤子买卖
```

预估账单实时显示（选中即算），实收以 `CheckOut` 返回值为准——**展示与事务分离**。

查询窗体把在住/已退混排，已退灰显（`row.ForeColor = Color.Gray`）——15 章 CellFormatting 的轻量版（ListView 无绑定，手动着色）。

## 6. 生产化清单（从这里到"能上线"的距离）

1. **口令**：admin/1234 是演示——真做要库表 + **盐值哈希**（17 章的 PBKDF2 同款），绝不存明文
2. **事务**：退房的"改 stays + 改 rooms"两步应包 `BEGIN…COMMIT`（SqliteConnection.BeginTransaction）
3. **并发**：两个前台同时订同一间房？乐观锁（`WHERE occupied=0` 的 UPDATE 影响行数判定）或库级约束
4. **备份**：SQLite 单文件，定时 File.Copy（加" quiet 期"或用 SQLite Online Backup）
5. **日志**：替换 MessageBox 为日志文件（谁在什么时候办了什么）
6. **配置**：数据库路径进 `appsettings.json` / 用户设置，别钉死 %TEMP%
7. **三语言的取舍**：F# 版适合把 `HotelDb` 换成函数式管道；C++/CLI 版适合接入现有酒店硬件 SDK（门锁/公安上传的国产 SDK 多为 C++）——18 章的混合方案就是为此准备的

## 7. 验收路径（10 分钟能走完的业务环）

1. 启动 → 登录（admin / 1234；输错一次看拦截）
2. 前台 → 入住登记：选 201，填"测试客人"
3. 前台 → 退房结账：列表出现刚办的在住单，选中看预估，结账看账单
4. 前台 → 住客查询：搜"测试"——在住记录；退房后变灰显"已退（N 晚 ￥X）"
5. 关掉主窗体：`%TEMP%\winforms20.db` 留着，下次启动数据还在（自建库 + 播种幂等）

## 坑位清单

1. 登录框点了确定还是关了——没设 `DialogResult = DialogResult.None` 拦截。
2. 退房后房间还显示占用——两步 UPDATE 少了一步（或没用同一连接/事务）。
3. 子窗体开着又开一份——没用 `OpenChild<T>` 的查重。
4. ListBox 塞纯字符串 → 结账时不知道对应哪条记录；塞对象 + 重写 ToString。
5. 日期存文本读回不解析 → `DateTime.Parse` 文化差异；统一 `yyyy-MM-dd HH:mm` 格式串。

## 自测

1. 登录门卫的"拦截"是怎么实现的？（哪个属性赋了什么值）
2. `OpenChild<T>` 保证了什么交互性质？
3. 退房业务为什么必须在一个 DAL 方法里改两张表？
4. 本项目的单例（`MainForm.Db`）有什么教学取舍？正式做法？
5. F#/C++/CLI 各自接手这个项目时的最佳切入点？
