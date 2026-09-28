# 37. 数据持久化：生命周期、SQLite 与数据服务

> 对应《Learn WinUI 3》第 6 章。书用 `Microsoft.Data.Sqlite`（ADO.NET 提供程序）+ Dapper（微型 ORM）写数据层——两者都是 .NET 专属。C++/WinRT 的路线更底层也更透明：**直接把 SQLite 官方合并源码（amalgamation）编进工程，用 `sqlite3_*` C API 手写数据访问**。没有 ORM 帮忙，但每一行绑定代码你都看得见——这恰好是教学想要的。

本章的示例工程是 `examples/37-media-library`——书的"My Media Collection"应用的 C++ 核心复刻：媒体列表 + 类别过滤 + 增删，数据落在 `%LOCALAPPDATA%\MediaLibrary\media.db`，**重启不丢**。

## 37.1 生命周期：数据保存挂在哪个事件上

书 6.1 的生命周期讨论在 C++ 侧完全成立（这些是框架事件，与语言无关），先把结论表立起来：

| 时机 | 事件/方法 | 该做什么 |
|---|---|---|
| 启动一次 | `App::OnLaunched` | 建主窗口、初始化服务（数据库在后台线程开） |
| 窗口每次激活 | `Window::Activated` | 轻量刷新（无 Window.Loaded！见下） |
| 元素加载中/完毕 | `FrameworkElement::Loading` / `Loaded` | Loaded 后才能安全操作子元素 |
| 页面离树 | `FrameworkElement::Unloaded` | 释放页面级资源 |
| 窗口关闭 | `Window::Closed` | **保存内存态的最后时机** |
| 应用退出 | （无对应事件） | 见下 |

三个 C++ 视角的补充：

1. **WinUI 3 桌面应用没有挂起/恢复**（那是 UWP 的模型）。书 6.1.2 的这句对 C++ 同样成立：要么运行要么没运行。
2. **Window 没有 Loaded 事件**——书用 `Activated` + 首次标志替代。C++ 侧还有第三条路：直接在构造函数尾做（本教程工程的做法），因为 `InitializeComponent()` 之后子控件引用（`StatusText()`）已可用。
3. **`Window::Closed` 是唯一可靠的"收尾"事件**。`wWinMain` 返回前什么都不会再给你——`Application::Start` 返回时窗口已全灭。要做"退出前 flush"，挂在 `Window::Closed`。

MediaLibrary 的选择：**SQLite 本身就是即时落盘的**（每次 INSERT/DELETE 执行完就提交），所以不需要"退出前保存"的仪式——这比 JSON 快照（[35 章](35-taskflow.md)的 Storage）少一个丢数据窗口。这是数据库路线的第一个红利。

## 37.2 SQLite 是什么、C++ 怎么拿

SQLite 是嵌在用户进程里的一个 C 库：整个数据库是磁盘上一个文件，没有服务端、没有安装、没有网络。**官方分发形态就是一个 9 万行的 `sqlite3.c` + 一个 `sqlite3.h`**（合并源码，amalgamation），编进任何 C/C++ 工程即可。

书 6.2 走 NuGet（`Microsoft.Data.Sqlite` 把原生 dll 打包并给 ADO.NET 接口）；C++ 工程直接用源头：

```
examples/37-media-library/thirdparty/
├── sqlite3.c    # 9.5 MB，SQLite 3.53.4 官方合并源码
└── sqlite3.h    # 0.7 MB
```

工程登记只要三笔（vcxproj 摘录）：

```xml
<ClCompile Include="thirdparty\sqlite3.c">
  <PrecompiledHeader>NotUsing</PrecompiledHeader>   <!-- 纯 C，不吃 pch -->
  <WarningLevel>Level1</WarningLevel>               <!-- 三方代码降警 -->
  <DisableSpecificWarnings>4996;4267;4244;4311;4131;4100;4189</DisableSpecificWarnings>
</ClCompile>
```

**不要加任何 `SQLITE_OMIT_*`/`SQLITE_ENABLE_*` 宏**——默认编译就是线程安全（`SQLITE_THREADSAFE=1`，串行模式）的完整功能集，教学与生产都从默认开始。想升级 SQLite 时换两个文件重编即可，这就是合并源码路线的维护成本上限。

> 取源：`https://sqlite.org/download.html` → "amalgamation" zip。本教程用的版本 3.53.4（2026 年线）。

## 37.3 C API 五步曲：准备语句

SQLite 的 C API 只有一个中心模式，**准备语句（prepared statement）**：

```
prepare → bind（填参数） → step（执行/取行） → column（读列） → finalize（释放）
```

`LibraryStore.cpp` 用一个 30 行的 RAII 包装把最后一步自动化：

```cpp
// examples/37-media-library/LibraryStore.cpp
struct Statement
{
    Statement(sqlite3* db, wchar_t const* sql) : m_db{ db }
    {
        // sqlite3_prepare16_v2 吃 UTF-16 SQL —— Windows 宽字符串零转换直入
        int rc = sqlite3_prepare16_v2(db, sql, -1, &m_stmt, nullptr);
        if (rc != SQLITE_OK) { throw std::runtime_error("sqlite3_prepare16_v2 failed"); }
    }
    ~Statement() { if (m_stmt) { sqlite3_finalize(m_stmt); } }
    sqlite3_stmt* Handle() { return m_stmt; }
    ...
};
```

**实测要点：`prepare`/`bind`/`column` 都有 16 版本，`sqlite3_exec` 没有**。exec 只有 UTF-8 形态——建表这种无参数 DDL 要么转 UTF-8，要么和 DML 一样走 prepare16+step。教程选择后者，全文一套模式。

### 增（INSERT，参数绑定）

```cpp
int64_t LibraryStore::Insert(std::wstring const& name, std::wstring const& category)
{
    Statement insert{ m_db,
        L"INSERT INTO MediaItems (Name, Category, Location) VALUES (?1, ?2, 'Digital')" };
    // 占位符序号从 1 起；SQLITE_TRANSIENT = "请立即拷贝这份缓冲"
    sqlite3_bind_text16(insert.Handle(), 1, name.c_str(), -1, SQLITE_TRANSIENT);
    sqlite3_bind_text16(insert.Handle(), 2, category.c_str(), -1, SQLITE_TRANSIENT);
    if (sqlite3_step(insert.Handle()) != SQLITE_DONE)
    {
        throw std::runtime_error("INSERT failed");
    }
    return sqlite3_last_insert_rowid(m_db);   // AUTOINCREMENT 刚发的行号
}
```

**参数只 bind、永不拼接**。这条纪律同时解决 SQL 注入与语句复用两个问题——书 6.2.4 里 Dapper 帮 C# 做的事，C++ 里就是这四行的纪律。

`SQLITE_TRANSIENT` vs `SQLITE_STATIC`：前者要求 sqlite 立刻拷贝数据（调用方字符串可先死），后者承诺缓冲在语句 finalize 前一直有效。**默认写 TRANSIENT**，性能敏感的热路径再换 STATIC。

### 查（SELECT，过滤也走参数）

```cpp
std::vector<MediaRow> LibraryStore::List(std::wstring const& categoryFilter) const
{
    std::vector<MediaRow> result;
    Statement list{ m_db,
        L"SELECT Id, Name, Category, Location FROM MediaItems "
        L"WHERE ?1 = 'All' OR Category = ?1 ORDER BY Name" };   // "All" 也走参数
    sqlite3_bind_text16(list.Handle(), 1, categoryFilter.c_str(), -1, SQLITE_TRANSIENT);

    while (sqlite3_step(list.Handle()) == SQLITE_ROW)   // 每行一步
    {
        MediaRow row;
        row.id = sqlite3_column_int64(list.Handle(), 0);
        row.name = ColumnText(list.Handle(), 1);
        row.category = ColumnText(list.Handle(), 2);
        result.push_back(std::move(row));
    }
    return result;
}
```

`WHERE ?1 = 'All' OR Category = ?1` 是一个把"不过滤"也参数化的小技巧：UI 过滤框的 `All` 值直接进 SQL，C++ 侧不需要 if/else 两条语句。返回 `std::vector`（原生类型）而不是 WinRT 集合——**数据层的边界就在这里**，WinRT 化是 ViewModel 的事。

### 建表与种子（幂等启动）

```cpp
wchar_t const* sql =
    L"CREATE TABLE IF NOT EXISTS MediaItems ("
    L"  Id INTEGER PRIMARY KEY AUTOINCREMENT,"
    L"  Name NVARCHAR(200) NOT NULL,"
    L"  Category NVARCHAR(20) NOT NULL,"
    L"  Location NVARCHAR(20) NOT NULL)";
Statement create{ m_db, sql };
sqlite3_step(create.Handle());
```

`IF NOT EXISTS` 让每次启动都跑同一段建表代码。种子数据的幂等判据是行数（`SELECT COUNT(*)` 为零才插入书里那三条）——**先数后插只对单进程应用安全**；多实例并发首启要用 `INSERT OR IGNORE` + 唯一键。本教程应用是单实例语义（[31.6](31-window-shell.md) 的单实例方向），COUNT 判据够用。

## 37.4 数据放哪：unpackaged 的老结论

[34.2](34-os-integration.md) 实测过：非打包进程调 `ApplicationData` 抛"没有程序包标识符"。数据库路径与 JSON 时代同一纪律：

```cpp
// LibraryViewModel.cpp —— 数据目录
std::wstring dir{ std::wstring{ buffer, len } + L"\\MediaLibrary" };  // %LOCALAPPDATA%
std::error_code ec;
std::filesystem::create_directories(directory, ec);   // 整链一次建齐，已存在是 no-op
```

窗口底部状态条显示完整 db 路径（`ViewModel.DbPath`），调试时可以直接拿 DB Browser for SQLite（书 6.3 推荐的工具，sqlitebrowser.org）打开同一个文件对账。**打包后的路径会变成 `%LOCALAPPDATA%\Packages\<包名>\LocalCache`**——[42 章](42-packaging-deploy.md)实测。

## 37.5 线程纪律：数据库永远在后台线程碰

书 6.2 的 async/await 在 C++ 里是 [32.7](32-binding-mvvm.md) 的协程纪律，一比一复用：

```cpp
winrt::Windows::Foundation::IAsyncAction LibraryViewModel::InitializeAsync()
{
    auto lifetime = get_strong();

    co_await winrt::resume_background();          // ① 文件 IO 去线程池
    std::wstring status = m_store.Open(dir);      // ② 纯 C++ 层，无 WinRT 控件

    m_dispatcherQueue.TryEnqueue([this, status]   // ③ 回 UI 线程刷状态与列表
    {
        (void)ReloadAsync(status, L"");
    });
}
```

增删同构（`AddItemAsync`/`DeleteItemAsync`，见源码）。三处细节：

- **`resume_foreground` 永不恢复**（32.7 头号坑），回 UI 只用 `DispatcherQueue::TryEnqueue`。
- **列表整体重建优于逐条增删**（ReloadAsync）：一次 `Items.Clear()` + N 次 `Append` 让 UI 只做一次布局，对几百行的表没有可感延迟。
- **乐观 UI**：AddItemAsync 在后台 INSERT 成功后才把行 Append 进可观察集合——失败时界面根本没有这行，不需要回滚 UI。删除同理（先移除后落库是另一种合法次序，取舍见 35 章讨论）。

## 37.6 ViewModel：书 3-4 章模式的落点

MediaLibrary 的 ViewModel 是前面所有章的汇合处，成员表即"MVVM 检查清单"：

| 成员 | 章节 | 说明 |
|---|---|---|
| `Items : IObservableVector<MediaItem>` | [32.4](32-binding-mvvm.md) | 列表绑定源 |
| `Status / SelectedCategory / HasSelection` + INPC | [32.2](32-binding-mvvm.md) | x:Bind OneWay/TwoWay 数据 |
| `AddItem()/DeleteSelected()` | [32.6](32-binding-mvvm.md) | 函数绑定入口 |
| `SelectedCategory` setter 级联 ReloadAsync | 书 3.4 | 书里 `OnSelectedMediumChanged` 的 C++ 形态 |
| `HasSelection` 替代 CanExecute | [36.3](36-mvvm-commands-di.md) | `IsEnabled` 直绑属性 |

类别过滤的 ComboBox 没有 ViewModel 属性——静态条目用内联 `<x:String>`（[07 设置中心](07-button.md)的 DensityBox 同款），原因见 37.8 第 8 条的坑位实录。

书的 `IDataService` 接口抽象在本工程简化为 `LibraryStore` 直用——**只有第二个数据源出现时才值得抽接口**（36.5 的装配哲学）。`MediaRow`（原生 struct）与 `MediaItem`（runtimeclass）的双层是刻意的：数据库行 → WinRT 投影对象的翻译发生在 ViewModel 层，`LibraryStore` 保持零 WinRT 依赖、可以脱离 UI 单测。

## 37.7 与书实现的差异清单

| 书（C#） | 本教程（C++） | 备注 |
|---|---|---|
| `Microsoft.Data.Sqlite` NuGet | vendored `sqlite3.c` 直编 | 无依赖管理开销，版本完全自控 |
| `SqliteConnection` + `CommandText` | `sqlite3*` 裸句柄 + RAII Statement | 打开/关闭的时机自己管 |
| Dapper `QueryAsync<T>` 自动映射 | 手写 column→struct 循环 | 多写 10 行，换来零魔法 |
| `await` 全链异步 | 协程 + TryEnqueue | 32.7 纪律 |
| DI 容器管理 DataService 单例 | App 级 `shared_ptr` | 36.5 |
| `ApplicationData.Current.LocalFolder` | `%LOCALAPPDATA%\<App>` | 34.2 unpackaged 结论 |
| 参数 `@Name` 命名式 | `?1` 序号式 | 两种占位符 SQLite 都收；16 系 API 配 `?N` 最直 |

## 37.8 实测坑位（本章新增）

1. **`sqlite3_exec` 没有 UTF-16 版本**——宽字符 SQL 一律 `prepare16_v2 + step`。编译器不会提醒你（exec 收 `char const*`，误传 `wchar_t const*` 直接类型错）。
2. **`sqlite3_open16` 的路径参数是宽字符串**，与 `sqlite3_open`（UTF-8）成对；混用会在中文用户名路径上炸出无法打开的库文件。
3. **`sqlite3_bind_text16` 的第五参数不能省**：`SQLITE_TRANSIENT`（拷贝）或 `SQLITE_STATIC`（不拷贝）。传 `nullptr` 等价 STATIC——绑临时字符串就是悬垂指针。
4. **VC 诊断把 `.c` 当 C 编**——`thirdparty/sqlite3.c` 必须显式 `PrecompiledHeader: NotUsing`，否则 pch 强制包含直接报错。
5. **`m_store` 所在的 ViewModel 持有后台线程回调**：回调里 `this` 必须由 `get_strong()` 兜底（37.5 代码第 2 行），否则窗口快速关闭时协程复活一个死对象。
6. **`sqlite3_last_insert_rowid` 返回的是连接级状态**——两个线程共用一个连接交错插入时它不可靠。单连接 + UI 串行化（本工程形态）没问题；多线程写要用 `RETURNING` 子句或每线程独立连接。
7. **NAVCHAR 长度不截断**：SQLite 的类型亲和性把 `NVARCHAR(200)` 当 TEXT，长度约束不生效（不像 SQL Server）。要约束得用 `CHECK(length(Name) <= 200)`。
8. **`ItemsSource="{x:Bind ViewModel.Categories}"`（返回 `IVector<String>`）在 1.8 运行期 stowed E_INVALIDARG**——本工程首启白窗的直接死因（App.UnhandledException 落盘 + 六轮对照实验定位，[41 章](41-debugging.md)的方法论实战）。**静态条目改内联 `<x:String>`，动态条目改代码填充**；本指南此前所有 ItemsSource 绑的都是 runtimeclass 集合，string 集合直绑是未踩过的地雷。
9. **`SelectedIndex` 不能写在 ItemsSource 之前**：XAML 属性按出现序赋值，空集合上设选中索引，Selector 直接抛（同一 stowed 形态）。默认选中放首次 `Activated` 回调（代码见 MainWindow 构造）。
10. **`App::UnhandledException` 是无调试器流程的第一现场**：三行落盘代码把 stowed 的 HRESULT 与消息写进 `%TEMP%` 日志——比事件日志的偏移地址便宜一个数量级（41 章 41.4 的实际应用，37 例里保留为常驻代码）。

## 37.9 练习与思考

1. 给 MediaLibrary 加"借出"功能：`Location` 列存 `InCollection/Digital/Lent`，UI 加 ComboBox 修改选中行的位置——这需要 UPDATE 语句，写出 `LibraryStore::UpdateLocation(id, location)` 并接进 ViewModel。
2. 把种子判据从 `COUNT(*)==0` 换成 `INSERT OR IGNORE` + `Name` 唯一索引。两种幂等策略各在什么场景下错？（提示：两个进程同时首启。）
3. 在 `List` 的 SQL 里加 `LIMIT ?2 OFFSET ?3`，把列表做成分页加载——每页 50 行，滚到底部触发下一页。分页与"整体重建 Items"策略怎么共存？
4. 用事务把"删 100 行"包成一个 `BEGIN/COMMIT`（`sqlite3_exec` 收 UTF-8 的 `BEGIN` 恰好可用），对比逐条提交的耗时差。什么操作必须用事务？
5. 思考：为什么 `LibraryStore` 刻意不包含任何 `winrt/` 头文件？如果它返回 `IObservableVector<MediaRow>` 会失去什么？
