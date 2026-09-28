# 34 · ODBC 数据库：CDatabase / CRecordset / RFX

> 对应示例：`examples/34_odbc`（支持 `-test` 无 UI 自测）

> **本章你将学会**：MFC 的 ODBC 门面（CDatabase/CRecordset）、DSN-less 连接串、RFX 字段交换的标准写法、参数化过滤、以及一套**文本驱动实测结论**——它把“教科书写法”和“驱动现实”的差距摆到了台面上。
> **前置知识**：第 17 章的序列化（另一条持久化路线）、第 03 章的异常宏。

两本 MFC 书的数据库篇覆盖 ODBC 和 DAO 各一半（编程实例第 13 章例 72/73；扩展编程实例第 12 章实例 44/45 做 ODBC/DAO 编辑器）。二十多年过去：**DAO 谣退**（随 Office 时代落幕，MFC 里的 `CDaoDatabase` 仅存于维护模式），**ODBC 的 MFC 门面原样健在**，连接 SQL Server / Access / Excel / CSV 都走它。本章示例用「Microsoft Access Text Driver」把一个 CSV 目录当数据库——零安装、人人可复现；连真数据库只需换连接串。

## 1. 连接：CDatabase 与 DSN-less

```cpp
CDatabase db;
db.OpenEx(_T("Driver={Microsoft Access Text Driver (*.txt, *.csv)};DBQ=C:\\data;"),
          CDatabase::noOdbcDialog);
```

- **DSN-less**：不预注册数据源，连接串里说清驱动 + 位置。对比老书时代的 DSN 注册（控制面板 → ODBC 数据源管理器），今天几乎总选 DSN-less——部署少一步配置。
- `noOdbcDialog`：禁止驱动弹配置对话框（否则缺参数时会卡一个系统对话框）。
- 常用连接串速查：

| 数据源 | 连接串 |
|---|---|
| CSV 目录（本例） | `Driver={Microsoft Access Text Driver (*.txt, *.csv)};DBQ=<目录>;` |
| Access | `Driver={Microsoft Access Driver (*.mdb, *.accdb)};DBQ=<文件>;` |
| SQL Server | `Driver={ODBC Driver 17 for SQL Server};Server=<主机>;Database=<库>;Trusted_Connection=Yes;` |

错误处理走 `CDBException`（和 `CFileException` 同款 **MFC 异常是对象指针、catch 后要 `e->Delete()`** 的规矩，第 21 章详述）：

```cpp
try {
    db.OpenEx(cs, CDatabase::noOdbcDialog);
} catch (CDBException* e) {
    TCHAR msg[512] = {};
    e->GetErrorMessage(msg, 512);
    e->Delete();
}
```

## 2. 写入：ExecuteSQL

```cpp
db.ExecuteSQL(_T("INSERT INTO [data.txt] (name, qty) VALUES ('keyboard', 3)"));
```

DDL（CREATE TABLE / CREATE INDEX）也走 `ExecuteSQL`——**前提是驱动支持**（文本驱动不支持，见第 6 节）。批量插入之间 `Commit` 一下（支持事务的驱动）比逐条自动提交快一个量级。

## 3. 读取一：CRecordset + GetFieldValue（动态列）

不写字段绑定、列名运行期才知道（或像本章一样驱动对绑定不友好）时的标准解：

```cpp
CRecordset rs(&db);
rs.Open(CRecordset::forwardOnly, _T("SELECT name, qty FROM [data.txt] ORDER BY qty DESC"),
        CRecordset::readOnly);
CDBVariant var;
while (!rs.IsEOF()) {
    CString name;
    rs.GetFieldValue(_T("name"), name);      // 按列名取
    rs.GetFieldValue((short)1, var);         // 按序号取，类型枚举判读
    long qty = (var.m_dwType == DBVT_LONG) ? var.m_lVal : 0;
    rs.MoveNext();
}
rs.Close();
```

- **openType**：`forwardOnly`（只读向前，最轻、兼容性最好——本例用）；`snapshot`（静态快照，要驱动支持书签/双向游标）；`dynaset`（动态集，可回写）。ISAM 类驱动（文本/Excel）通常只有 forwardOnly 稳。
- `CDBVariant` 是个 tagged union（`m_dwType` 判 `DBVT_LONG/DBVT_STRING/...`），比猜类型安全。
- 过滤排序放 SQL 里（`WHERE`/`ORDER BY`），别把整表拉回内存筛——这是老书例 72 反复强调的量级问题。

## 4. 读取二：RFX 字段交换（真数据库的教科书）

派生 CRecordset、重写 `DoFieldExchange`，列值直接落到成员——**对 Access/SQL Server 这是标准姿势**，MFC 向导生成的就是它：

```cpp
class CItemSet : public CRecordset {
public:
    CItemSet(CDatabase* pDB) : CRecordset(pDB) {
        m_nParams = 1;                     // 基类成员：有一个 ? 要绑（不是新成员！）
    }
    CString m_name;
    long    m_qty = 0;
    long    m_paramMinQty = 0;             // 参数成员

    CString GetDefaultSQL() override { return _T("[data.txt]"); }

    void DoFieldExchange(CFieldExchange* pFX) override {
        pFX->SetFieldType(CFieldExchange::outputColumn);   // 输出列
        RFX_Text(pFX, _T("[name]"), m_name);
        RFX_Long(pFX, _T("[qty]"), m_qty);
        pFX->SetFieldType(CFieldExchange::param);          // 参数（对应 SQL 里的 ?）
        RFX_Long(pFX, _T("[minQty]"), m_paramMinQty);
    }
};

// 用：参数化过滤 —— 值永不拼进 SQL 文本，注入免疫
rs.m_strFilter = _T("qty > ?");
rs.m_paramMinQty = 2;
rs.Open(CRecordset::forwardOnly, nullptr, CRecordset::readOnly);
```

要点：

- 一个 `?` 对一个 param 成员，`m_nParams` 计数；漏计数 = 绑定错位。
- `RFX_` 家族按列型选：`RFX_Text/RFX_Long/RFX_Double/RFX_Date/RFX_Bool...`（afxdb.h 全表）。
- `m_strFilter` 是 WHERE 子句（不带 WHERE 关键字）、`m_strSort` 是 ORDER BY——传 `nullptr` 的 lpszSQL 时框架用 `GetDefaultSQL` + filter + sort 拼 SQL。
- 参数化在**真数据库**上是最重要的安全实践——SQL 注入的第一道闸。

示例 34 保留了完整的 `CItemSet` 模板（注释标明它是真数据库路线），但按钮和自测走 GetFieldValue——原因正是下一节。

## 5. 事务与能力探测

```cpp
if (!db.CanTransact()) {
    // 驱动不支持 —— 文本 ISAM 的常态
} else {
    db.BeginTrans();
    db.ExecuteSQL(_T("INSERT ... "));
    db.Rollback();     // 或 Commit()
}
```

事务三板斧（Begin/Commit/Rollback）是“多条写入要么全成要么全无”的唯一保证。`CanTransact` 先探测——别假设。

## 6. 文本驱动实测：教科书与现实的差距

以下全部是本机（Windows 11 + VS18 MFC + Office16 ACE x64 驱动）**实测**结论，示例 34 的注释与自测逻辑就是按它们设计的。换 Access/SQL Server 时这些坑大多不存在，但“驱动能力有边界”这个意识永远成立：

1. **CREATE TABLE 不可用**：`ExecuteSQL("CREATE TABLE ...")` 报“文件名无效”。数据文件（带表头行）和 `schema.ini`（列型定义）得自己铺——示例 34 的“建库”按钮干的就是这个。
2. **表引用必须带扩展名**：`SELECT ... FROM [data.txt]` ✓；写成 `[data]` 时 INSERT 能过、SELECT 却报 **“已被其他用户以独占方式打开”**——张冠李戴的误导性错误，排查时别被它带偏（我们为此付出了一下午）。
3. **UPDATE/DELETE 不支持**：CSV 行无法原地改写，报 HY000。要改就整文件重写（或用真数据库）。
4. **中文值读回为空**：`CharacterSet=65001` 下 INSERT 中文没问题（文件里是 UTF-8），但 SQLGetData 取回空串——驱动字符集转换的缺陷。示例数据因此用 ASCII。
5. **RFX 输出列取值恒空；`?`-参数绑定直接崩**（`mso20win32client.dll`，Office 遥测栈的异常 0x01483052）——所以示例的参数过滤用**校验过类型的字面量**（`_ttoi` 后 Format 成 int），真实数据库上应改回 `?` 参数。
6. **写后独占**：同连接 INSERT 之后再 SELECT 报独占错。纪律：**写完立刻 `db.Close()`**，读时重开。MFC 无连接池，Close 即真断。

把“驱动能力矩阵”当设计输入：写 CSV 原型验证 UI，数据层留好换 Access/SQL Server 的缝（连接串 + 表名集中在一处常量），是老书“识别要打开的文件”（例 63）思路的现代延续。

## 7. 无 UI 自测

示例 34 支持 `34_odbc.exe -test`：完整跑 铺文件 → 连接 → 写三行 → GetFieldValue 查询（验证排序与行数）→ 字面量过滤（验证行数），结果写 `%TEMP%\mfc_guide_34\result.log`，退出码 0 = 全过。CI/脚本里一条命令完成回归：

```powershell
.\build\34_odbc.exe -test
$LASTEXITCODE    # 0 = 全绿
```

## 实战建议

- 列名/表名带保留字或空格时用 `[]` 包裹；文本驱动的表名是**文件名**，含点必须方括号。
- `CRecordset` 用完 `Close`、`CDatabase` 用完 `Close`——RAII 不覆盖“连接占着驱动文件”这种资源。
- 连接串里的密码别硬编码：从环境变量/凭据管理器取（`CredRead`），或干脆用集成认证（`Trusted_Connection`）。
- 大结果集用 `CRecordset::fetchForward` + 逐行处理；`GetRecordCount` 对 forwardOnly 返回的是**已取过的行数**，不是总行数（老书就提过的经典陷阱）。

## 常见坑（实测）

1. **`m_nParams` 写成 const 新成员遮蔽基类**：编译器不报错（只是 shadowing），参数永远绑不上——在构造函数里给基类成员赋值才是对的（示例 34 注释特地标了这一点）。
2. **`CDBException` catch 后不 `Delete()`**：MFC 异常对象泄漏（第 21 章的通用规矩，这里最容易忘）。
3. **`GetRecordCount` 当总行数用**：见上，forwardOnly 下它是“已迭代数”。
4. **忘了 `afxdb.h`**：`CDatabase` 未定义；链接不用操心，头文件里有 `#pragma comment(lib, "odbc32.lib")`。
5. **32/64 位驱动**：连接失败先查位数（`odbcad32.exe` 在 System32/SysWOW64 各有一份，看到的不一样）。本机 64 位 Access Text Driver 与 x64 构建匹配，所以一切正常。
