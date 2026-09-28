// 34_odbc：ODBC 数据库编程 —— CDatabase / CRecordset / RFX。
//
// 书1 第13 章 例72（ODBC）+ 书2 实例44（ODBC 编辑器）的现代版：
// DAO 已随时代退役（书中另一半），ODBC 的 MFC 门面今天依然原样可用。
//
// 本例用「Microsoft Access Text Driver」把一个 CSV 目录当数据库（DSN-less，
// 零安装、可复现）；换成 Access/SQL Server 只需换连接串 —— 教学重心在 MFC 侧：
//   1. CDatabase::OpenEx + 连接串；ExecuteSQL 干 INSERT/DDL
//   2. CRecordset + GetFieldValue：动态取列（列在运行期才知道时的标准解）
//   3. 过滤与排序：m_strFilter / ORDER BY（SQL 侧完成，别把整表拉回来筛）
//   4. 事务：CanTransact 探测（文本驱动不支持 —— 真数据库才有的能力清单）
//
// —— 本机（VS18 + Office16 ACE x64）文本驱动的实测边界，doc 第 34 章展开：
//   - CREATE TABLE 不可用：数据文件与 schema.ini 得自己铺
//   - 表引用必须带扩展名：SELECT ... FROM [data.txt]；写 [data] 会报
//     “已被独占打开”这种张冠李戴的错，别被它带偏
//   - UPDATE/DELETE 不支持（CSV 无法原地改行）
//   - 中文值：INSERT 没问题，读回是空串（驱动字符集转换的锅）——示例用 ASCII
//   - RFX 输出列取值恒空、?-参数绑定在 mso20win32client.dll 里崩 ——
//     这两条是本机驱动的实测结论；对 Access/SQL Server 等真数据库，
//     RFX + 参数化（源码里保留的 CItemSet 写法）依然是教科书正解
//
// 自测：34_odbc.exe -test（无 UI 跑完整链路，写 %TEMP%\mfc_guide_34\selftest.log）
// 编译运行：.\build.ps1 -File 34_odbc

#include "resource.h"
#include <afxwin.h>
#include <afxdb.h>     // CDatabase / CRecordset

// 标准的 RFX + 参数化写法（对 Access/SQL Server 等“真”数据库有效）。
// 本机文本驱动上输出列取值为空、参数绑定崩溃（文件头注释），故自测与按钮不启用它，
// 留作连接真实数据库时的模板。
class CItemSet : public CRecordset {
public:
    CItemSet(CDatabase* pDB) : CRecordset(pDB) {
        m_nParams = 1;    // 基类成员：告诉框架有一个 ? 要绑定（不是新成员！）
    }

    CString m_name;
    long    m_qty = 0;
    long    m_paramMinQty = 0;

    CString GetDefaultConnect() override { return _T(""); }
    CString GetDefaultSQL() override { return _T("[data.txt]"); }

    void DoFieldExchange(CFieldExchange* pFX) override {
        pFX->SetFieldType(CFieldExchange::outputColumn);
        RFX_Text(pFX, _T("[name]"), m_name);
        RFX_Long(pFX, _T("[qty]"), m_qty);
        pFX->SetFieldType(CFieldExchange::param);
        RFX_Long(pFX, _T("[minQty]"), m_paramMinQty);
    }
};

class CDbDlg : public CDialog {
    DECLARE_MESSAGE_MAP()
public:
    CDbDlg() : CDialog(IDD_MAIN) {}

    BOOL OnInitDialog() override {
        CDialog::OnInitDialog();
        CenterWindow();
        m_log.SubclassDlgItem(IDC_EDIT_LOG, this);
        SetDlgItemText(IDC_EDIT_MINQTY, _T("2"));
        m_dir = TestDir();
        Append(_T("就绪。数据目录：") + m_dir + _T("\r\n按 1 → 2 → 3 的顺序玩。\r\n"));
        return TRUE;
    }

    static CString TestDir() {
        wchar_t tmp[MAX_PATH] = {};
        GetTempPathW(MAX_PATH, tmp);
        CString dir = CString(tmp) + _T("mfc_guide_34");
        CreateDirectoryW(dir, nullptr);
        return dir;
    }

    static CString ConnStrFor(const CString& dir) {
        // DSN-less：不用预先在 ODBC 数据源管理器里登记，连接串里说清就行
        return _T("Driver={Microsoft Access Text Driver (*.txt, *.csv)};DBQ=") + dir + _T(";");
    }

    // ============ 1. 铺文件 + 写入 ============

    void OnCreate() {
        // 文本驱动没有 CREATE TABLE：数据文件与 schema.ini 得自己铺
        CFile f;
        if (!f.Open(m_dir + _T("\\data.txt"), CFile::modeCreate | CFile::modeWrite)) {
            Append(_T("[建库] 建文件失败\r\n"));
            return;
        }
        const BYTE bom[] = { 0xEF, 0xBB, 0xBF };
        f.Write(bom, 3);
        f.Write("name,qty\r\n", 9);
        f.Close();

        CFile ini;
        if (ini.Open(m_dir + _T("\\schema.ini"), CFile::modeCreate | CFile::modeWrite)) {
            // 列型全靠它：TEXT 宽度、INTEGER、日期格式…… 漏了列就全按 TEXT 猜
            const char* iniText =
                "[data.txt]\r\n"
                "Format=CSVDelimited\r\n"
                "ColNameHeader=True\r\n"
                "CharacterSet=65001\r\n"
                "Col1=name Text Width 50\r\n"
                "Col2=qty Integer\r\n";
            ini.Write(iniText, (UINT)strlen(iniText));
            ini.Close();
        }

        CDatabase db;
        try {
            db.OpenEx(ConnStrFor(m_dir), CDatabase::noOdbcDialog);
            db.ExecuteSQL(_T("INSERT INTO [data.txt] (name, qty) VALUES ('keyboard', 3)"));
            db.ExecuteSQL(_T("INSERT INTO [data.txt] (name, qty) VALUES ('monitor', 1)"));
            db.ExecuteSQL(_T("INSERT INTO [data.txt] (name, qty) VALUES ('mouse', 12)"));
            db.ExecuteSQL(_T("INSERT INTO [data.txt] (name, qty) VALUES ('dock', 5)"));
            db.Close();
            Append(_T("[写入] 4 行已入库\r\n"));
        } catch (CDBException* e) {
            ReportDbError(_T("写入"), e);
            e->Delete();
        }
    }

    // ============ 2. GetFieldValue 查询 ============

    void OnQuery() {
        CDatabase db;
        try {
            db.OpenEx(ConnStrFor(m_dir), CDatabase::noOdbcDialog);
            CRecordset rs(&db);
            // 文本驱动：只读向前最稳（snapshot 需要书签/双向游标，ISAM 没有）
            rs.Open(CRecordset::forwardOnly,
                    _T("SELECT name, qty FROM [data.txt] ORDER BY qty DESC"),
                    CRecordset::readOnly);
            Append(_T("[查询] 按 qty 降序：\r\n"));
            int n = QueryOut(rs);
            CString tail;
            tail.Format(_T("[查询] 共 %d 行\r\n"), n);
            Append(tail);
            rs.Close();
            db.Close();
        } catch (CDBException* e) {
            ReportDbError(_T("查询"), e);
            e->Delete();
        }
    }

    // ============ 3. 过滤（字面量） ============

    void OnParam() {
        CString minStr;
        GetDlgItemText(IDC_EDIT_MINQTY, minStr);
        int minQty = _ttoi(minStr);
        if (minQty <= 0) minQty = 2;

        CDatabase db;
        try {
            db.OpenEx(ConnStrFor(m_dir), CDatabase::noOdbcDialog);
            CRecordset rs(&db);
            // 文本驱动上 ?-参数绑定实测崩溃（文件头注释），这里用校验过的整数字面量。
            // 真数据库上应改回 "qty > ?" + 参数成员（见 CItemSet 模板）
            CString sql;
            sql.Format(_T("SELECT name, qty FROM [data.txt] WHERE qty > %d"), minQty);
            rs.Open(CRecordset::forwardOnly, sql, CRecordset::readOnly);
            CString head;
            head.Format(_T("[过滤] qty > %d 的行：\r\n"), minQty);
            Append(head);
            int n = QueryOut(rs);
            CString tail;
            tail.Format(_T("[过滤] 共 %d 行\r\n"), n);
            Append(tail);
            rs.Close();
            db.Close();
        } catch (CDBException* e) {
            ReportDbError(_T("过滤"), e);
            e->Delete();
        }
    }

    // ============ 4. 事务探测 ============

    void OnTransaction() {
        CDatabase db;
        try {
            db.OpenEx(ConnStrFor(m_dir), CDatabase::noOdbcDialog);
            if (!db.CanTransact()) {
                Append(_T("[事务] 驱动不支持事务（文本 ISAM 的常态）。\r\n")
                       _T("   BeginTrans/Commit/Rollback 三板斧要 Access/SQL Server 才有意义。\r\n"));
            } else {
                db.BeginTrans();
                db.ExecuteSQL(_T("INSERT INTO [data.txt] (name, qty) VALUES ('tx-row', 99)"));
                db.Rollback();
                Append(_T("[事务] 已回滚，“tx-row”不应出现在查询里\r\n"));
            }
            db.Close();
        } catch (CDBException* e) {
            ReportDbError(_T("事务"), e);
            e->Delete();
        }
    }

    // ================= 基础设施 =================

    // 统一的取行输出：按列名 + 按序号（CDBVariant）两种取法都演示
    int QueryOut(CRecordset& rs) {
        int n = 0;
        CDBVariant var;
        while (!rs.IsEOF()) {
            CString name;
            rs.GetFieldValue(_T("name"), name);     // 按列名
            long qty = 0;
            rs.GetFieldValue((short)1, var);        // 按序号，类型枚举判读
            if (var.m_dwType == DBVT_LONG)
                qty = var.m_lVal;
            CString line;
            line.Format(_T("   %-10s qty=%ld\r\n"), (LPCTSTR)name, qty);
            Append(line);
            n++;
            rs.MoveNext();
        }
        return n;
    }

    void ReportDbError(const CString& tag, CDBException* e) {
        CString msg;
        e->GetErrorMessage(msg.GetBuffer(512), 512);
        msg.ReleaseBuffer();
        Append(_T("[") + tag + _T("] ") + msg + _T("\r\n"));
    }

    void Append(const CString& line) {
        int len = m_log.GetWindowTextLength();
        m_log.SetSel(len, len);
        m_log.ReplaceSel(line);
    }

    CEdit   m_log;
    CString m_dir;
};

BEGIN_MESSAGE_MAP(CDbDlg, CDialog)
    ON_BN_CLICKED(IDC_BTN_CREATE, OnCreate)
    ON_BN_CLICKED(IDC_BTN_QUERY, OnQuery)
    ON_BN_CLICKED(IDC_BTN_PARAM, OnParam)
    ON_BN_CLICKED(IDC_BTN_TRANSACTION, OnTransaction)
END_MESSAGE_MAP()

class CDbApp : public CWinApp {
public:
    int m_testExit = 0;

    BOOL InitInstance() override {
        // -test：无 UI 自测（CI/脚本用）。完整跑 建库→写入→查询→过滤，
        // 结果写 %TEMP%\mfc_guide_34\selftest.log，退出码 0=全过
        if (__argc > 1 && wcscmp(__wargv[1], L"-test") == 0) {
            m_testExit = RunSelfTest() ? 0 : 1;
            return FALSE;    // AfxWinMain 随后调 ExitInstance，退出码从那取
        }

        CDbDlg dlg;
        m_pMainWnd = &dlg;
        dlg.DoModal();
        return FALSE;
    }

    int ExitInstance() override {
        return m_testExit;    // InitInstance 返回 FALSE 时 AfxWinMain 用这个当退出码
    }

    static void Tick(const CString& line) {
        CFile f;
        if (f.Open(CDbDlg::TestDir() + _T("\\selftest.log"),
                   CFile::modeWrite | CFile::modeNoTruncate | CFile::modeCreate)) {
            f.SeekToEnd();
            CT2A utf8(line + _T("\r\n"), CP_UTF8);
            f.Write((LPCSTR)utf8, (UINT)strlen((LPCSTR)utf8));
        }
    }

    static BOOL RunSelfTest() {
        Tick(_T("start"));
        CString dir = CDbDlg::TestDir();
        CFile f;
        if (!f.Open(dir + _T("\\data.txt"), CFile::modeCreate | CFile::modeWrite))
            return FALSE;
        const BYTE bom[] = { 0xEF, 0xBB, 0xBF };
        f.Write(bom, 3);
        f.Write("name,qty\r\n", 9);
        f.Close();
        CFile ini;
        if (!ini.Open(dir + _T("\\schema.ini"), CFile::modeCreate | CFile::modeWrite))
            return FALSE;
        const char* iniText =
            "[data.txt]\r\nFormat=CSVDelimited\r\nColNameHeader=True\r\n"
            "CharacterSet=65001\r\nCol1=name Text Width 50\r\nCol2=qty Integer\r\n";
        ini.Write(iniText, (UINT)strlen(iniText));
        ini.Close();
        Tick(_T("files laid"));

        CString log;
        int fails = 0;

        // 写入
        {
            CDatabase db;
            try {
                Tick(_T("insert: open"));
                db.OpenEx(CDbDlg::ConnStrFor(dir), CDatabase::noOdbcDialog);
                db.ExecuteSQL(_T("INSERT INTO [data.txt] (name, qty) VALUES ('keyboard', 3)"));
                db.ExecuteSQL(_T("INSERT INTO [data.txt] (name, qty) VALUES ('monitor', 1)"));
                db.ExecuteSQL(_T("INSERT INTO [data.txt] (name, qty) VALUES ('mouse', 12)"));
                db.Close();
                Tick(_T("insert: OK"));
                log += _T("insert: OK\r\n");
            } catch (CDBException* e) {
                e->Delete();
                Tick(_T("insert: FAIL"));
                log += _T("insert: FAIL\r\n");
                fails++;
            }
        }
        // 查询（GetFieldValue，按 qty 降序）
        {
            CDatabase db;
            try {
                Tick(_T("query: open"));
                db.OpenEx(CDbDlg::ConnStrFor(dir), CDatabase::noOdbcDialog);
                CRecordset rs(&db);
                rs.Open(CRecordset::forwardOnly,
                        _T("SELECT name, qty FROM [data.txt] ORDER BY qty DESC"),
                        CRecordset::readOnly);
                Tick(_T("query: opened"));
                int n = 0;
                CString first;
                CDBVariant var;
                while (!rs.IsEOF()) {
                    if (n == 0) {
                        rs.GetFieldValue(_T("name"), first);
                    }
                    n++;
                    rs.MoveNext();
                }
                rs.Close();
                db.Close();
                bool ok = (n == 3 && first == _T("mouse"));
                Tick(first.IsEmpty() ? CString(_T("query: first EMPTY")) : (CString(_T("query: first=")) + first));
                log += (ok ? _T("query: OK (3 rows, top=mouse)\r\n")
                           : _T("query: FAIL\r\n"));
                if (!ok) fails++;
            } catch (CDBException* e) {
                e->Delete();
                Tick(_T("query: FAIL"));
                log += _T("query: FAIL(exception)\r\n");
                fails++;
            }
        }
        // 过滤（字面量）
        {
            CDatabase db;
            try {
                db.OpenEx(CDbDlg::ConnStrFor(dir), CDatabase::noOdbcDialog);
                CRecordset rs(&db);
                rs.Open(CRecordset::forwardOnly,
                        _T("SELECT name, qty FROM [data.txt] WHERE qty > 2"),
                        CRecordset::readOnly);
                int n = 0;
                while (!rs.IsEOF()) { n++; rs.MoveNext(); }
                rs.Close();
                db.Close();
                bool ok = (n == 2);       // keyboard 3、mouse 12
                log += (ok ? _T("filter: OK (qty>2 -> 2 rows)\r\n")
                           : _T("filter: FAIL\r\n"));
                if (!ok) fails++;
            } catch (CDBException* e) {
                e->Delete();
                log += _T("filter: FAIL(exception)\r\n");
                fails++;
            }
        }

        Tick(_T("end"));
        CFile out;
        if (out.Open(dir + _T("\\result.log"), CFile::modeCreate | CFile::modeWrite)) {
            CT2A utf8(log, CP_UTF8);
            out.Write((LPCSTR)utf8, (UINT)strlen((LPCSTR)utf8));
            out.Close();
        }
        return fails == 0 ? TRUE : FALSE;
    }
};

CDbApp theApp;
