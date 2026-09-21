# 17 · 序列化深入与文档版本化

> 对应示例：`examples/17_serialize`

> **本章你将学会**：`CArchive` 的读写分派机制、怎么让自定义类可序列化、文件格式版本化的两层做法（文档级文件头 + 对象级 schema），以及容器序列化时的指针所有权约定。
> **前置知识**：第 15 章的 Doc/View 架构、第 16 章的运行时类信息。

## 1. CArchive 是什么

`CArchive` 是"字节流 + 类型分派"的包装——它自己不碰磁盘，挂在 `CFile` 上：

```text
你的对象  ←→  CArchive（<< >>，带类型信息）  ←→  CFile  ←→  磁盘
```

`Serialize(CArchive& ar)` 里用 `IsStoring()` 分方向，读写共用一个函数——格式只写一遍，不会存取不匹配：

```cpp
void CShopDoc::Serialize(CArchive& ar) {
    if (ar.IsStoring()) {
        ar << kFileVer << (int)m_items.GetSize();   // 头
        for (...) ar << m_items[i];                 // 内容
    } else {
        WORD ver; ar >> ver;                        // 顺序严格对称
        ...
    }
}
```

`<<`/`>>` 的重载覆盖面：

| 类型 | 说明 |
|---|---|
| `BYTE`/`WORD`/`DWORD`/`int`/`LONG`/`float`/`double`/`LONGLONG` | 定长二进制 |
| `CString` | 带长度前缀，含中文（Unicode 下按 UTF-16 写） |
| `CObject*` | **写类名 + schema 号**，读时反射创建（第 2 节） |
| `CByteArray`/`CDWordArray` 等 | `Serialize` 成员，自带实现 |
| `void*` 裸内存 | 走 `Write`/`Read`——**不含类型信息**，慎用 |

两个纪律：写和读的**顺序严格对称**（差一个字段，后面全部错位）；`Serialize` 保持纯数据，不碰 UI、不广播（第 15 章已讲）。

## 2. 让自定义类可序列化

```cpp
class CItem : public CObject {
    DECLARE_SERIAL(CItem)             // 头文件：声明 + Serialize 虚函数
public:
    CItem() = default;                // 反射创建必须有默认构造
    void Serialize(CArchive& ar) override;
    CString m_name;
    int     m_qty   = 0;
    double  m_price = 0.0;
    CString m_note;                   // v2 新增字段
};

IMPLEMENT_SERIAL(CItem, CObject, 2)   // cpp 文件：末参是 schema 版本号
```

和第 15 章的 `DYNCREATE` 一样是宏对：DECLARE 在头文件、IMPLEMENT 在 **cpp**，缺一个链接就报 `unresolved external`。`IMPLEMENT_SERIAL` 的第三个参数是**对象级版本号**（schema）。

为什么类必须是 `CObject` 派生 + 默认构造？看 `ar << p`（`CObject*`）实际写了什么：

```text
ar << (CItem*)p  ──►  WriteObject：
                        [类名 "CItem"] [schema 2] [CItem::Serialize 写的字段]
ar >> p          ──►  ReadObject：
                        读类名 → 在模块类表里反查 CRuntimeClass
                        → CreateObject()（new 一个默认构造的 CItem）
                        → 把流里的 schema 存好，调用 p->Serialize(ar)
```

读代码**不需要认识 CItem**——类名在文件里，`CRuntimeClass` 在类表里。这也是为什么字段里放 `CObject*` 指针（对象由 `new` 创建、归文档所有），而不是内嵌对象：内嵌对象没有指针，反射无处安放，直接调 `obj.Serialize(ar)` 即可（afx.h 注释原话："Use the Serialize member function directly for embedded objects"）。

一个签名细节：`operator>>` 只有 `CObject*&` 版本，没有派生类指针的模板重载——所以读取要借道：

```cpp
CObject* p = nullptr;
ar >> p;                              // CObject*& —— OK
m_items.Add(static_cast<CItem*>(p));  // 再转回具体类型
```

直接写 `ar >> (CItem*)变量` 编译不过（没有能绑定 `CItem*&` 的重载）。

## 3. 版本化：让旧文件还能打开

文件格式一定会进化。MFC 提供两层版本机制，管不同粒度：

| | 文档级文件头（手写 WORD） | 对象级 schema（`GetObjectSchema`） |
|---|---|---|
| 覆盖范围 | **整个文件** | **单个对象类** |
| 谁写 | 你在 `Serialize` 开头 `ar << kFileVer` | `WriteObject` 自动写 IMPLEMENT_SERIAL 的版本号 |
| 谁读 | 你读出来自己判断 | `ReadObject` 存进 `m_nObjectSchema`，对象自己查 |
| 适用 | 格式闸门：程序太旧拒绝打开新文件；整体结构变更 | 类字段演化：v2 加字段，读 v1 跳过 |

**对象级是字段演化的正解**。文档级头写在 `Serialize` 开头，但 `CItem::Serialize` 执行时根本看不到它——所以"v2 给 CItem 加了 m_note"这种改动，只能靠对象级 schema：

```cpp
void CItem::Serialize(CArchive& ar) {
    CObject::Serialize(ar);
    if (ar.IsStoring()) {
        ar << m_name << m_qty << m_price << m_note;
    } else {
        ar >> m_name >> m_qty >> m_price;
        if (ar.GetObjectSchema() >= 2)   // 流里记录的是写文件时的版本
            ar >> m_note;                // v2：照读
        else
            m_note = _T("（v1 文件，无备注）");   // v1：流里没有这个字段
    }
}
```

两个硬约束都写在 `GetObjectSchema` 的实现里（arcobj.cpp:276）：**只在读 `CObject*` 时有效**（此时 `m_nObjectSchema` 被赋成流里的值），**每个对象只能查一次**（查完置 -1）。

文档级头管另一件事——闸门：

```cpp
WORD ver = 0;
ar >> ver;
if (ver > CShopDoc::kFileVer)
    AfxThrowArchiveException(CArchiveException::badSchema);  // 文件比程序新：
                                                             // 字段布局未知，趁早拒绝
```

读到一半发现不认识的数据只能抛异常报"文件损坏"；开头就检查版本，能给出体面的错误。两层搭配：**头管"能不能读"，schema 管"读几个字段"**。

升级策略三条：只加字段不删字段（旧版本永远是新版本的"前缀"，读起来最简单）；字段语义不复用（v1 的 `m_price` 到 v2 变成"含税价"，别原地改义——加 `m_priceWithTax`）；写侧 schema 号和格式同步改（`IMPLEMENT_SERIAL` 末参 + `kFileVer` 一起动）。

## 4. 容器与指针所有权

容器序列化就是循环展开：

```cpp
// 写：个数 + 逐个指针（WriteObject 对同一指针只写一次，其余是"引用标记"，
//     恢复时多份指针指向同一个对象——共享结构不裂开）
ar << (int)m_items.GetSize();
for (int i = 0; i < m_items.GetSize(); ++i)
    ar << m_items[i];

// 读：个数 + 逐个反射
int n; ar >> n;
for (int i = 0; i < n; ++i) {
    CObject* p = nullptr;
    ar >> p;
    m_items.Add(static_cast<CItem*>(p));
}
```

`CObList`/`CObArray` 的 `Serialize` 成员已经内置了这套循环（还能处理环状引用——先登记再反序列化）；自己拿 `CArray<CItem*>` 写循环也一样。**所有权约定**：容器里的对象由文档 `new` 出来、由文档 `delete`——释放的统一入口是 `DeleteContents`，框架在新建/打开/关闭文档前都会调它：

```cpp
void CShopDoc::DeleteContents() override {
    for (int i = 0; i < m_items.GetSize(); ++i)
        delete m_items[i];
    m_items.RemoveAll();
    m_nextId = 1;
}
```

放这里而不是析构函数有两个原因：新建/打开文档时旧对象也要释放（析构时已经太晚）；打开失败的中途路径框架也会走 `DeleteContents` 收尾。

## 常见坑

1. **只写 `DECLARE_SERIAL` 没写 `IMPLEMENT_SERIAL`**
   链接报 `CRuntimeClass` 相关的 `unresolved external`。宏对必须跨头文件/cpp 成对，版本号写在 IMPLEMENT 的末参上。

2. **自定义类没有可用的默认构造函数**
   `ReadObject` 反射时先 `new` 再 `Serialize`——构造是 `private` 或只有带参构造，编译就过不去。让成员用默认初始化，业务初始化别指望构造函数。

3. **版本号只在写侧改，读侧没判断**
   v2 程序加了字段但 `IMPLEMENT_SERIAL` 版本没动，v1 文件读进来字段错位，表现为乱码或断言。**任何字段布局变化都要动版本号**，读侧按 schema 分支。

4. **用 `ar.Write` 直接写含指针的对象内存**
   `Write(&obj, sizeof(obj))` 把指针原样写进文件，下次读出来指向随机地址；还有 padding 和版本对齐问题。逐字段 `<<`，或老老实实走 `Serialize`。

5. **读取失败路径上泄漏**
   `ar >> p` 反射 `new` 出来的对象没人管时，异常一抛全漏。对象一读出来就 `Add` 进归文档所有的容器，让 `DeleteContents` 兜底。

6. **`GetObjectSchema` 在存储分支或查第二次**
   它只在"读 `CObject*`"时有效，且**一次 `Serialize` 只能查一次**（查完置 -1，第二次返回垃圾）。要多次用就先存进局部变量。

## 实战建议

- **文件格式第一版就写版本头**——两行代码，换来以后随便加字段的权利
- 类字段演化用对象级 schema，格式闸门用文档级头，别混着用也别指望一个顶两个
- 序列化逻辑用 `CMemFile` 做单测：`CMemFile` + `CArchive` 就能跑"存了再读"的全流程，不用启动界面、不碰磁盘
- `Serialize` 里不调 `UpdateAllViews`、不弹对话框（第 15 章铁律）；加载完成后框架统一触发视图刷新
- 存档格式要考虑 Unicode：`CString` 走 `<<` 自带长度，跨版本安全；裸 `char[]` 缓冲区是最容易错的写法

## 自测

1. **`ar << (CItem*)p` 写进文件的不只是字段，还有什么？读回来自动完成哪几步？**
   —— 还写了类名和 schema 号。读回时按类名在模块类表里反查 `CRuntimeClass`，`CreateObject()` 反射 `new`（所以要默认构造），把流里的 schema 存好后再调用对象的 `Serialize`。

2. **给 CItem 加一个 v2 字段，为什么不能用文档级版本头做兼容？**
   —— 文档头在 `CShopDoc::Serialize` 开头读，`CItem::Serialize` 执行时看不到它。类自己的字段演化要靠对象级 schema：`IMPLEMENT_SERIAL` 升版本号，读时 `GetObjectSchema()` 分支——流里每个对象都记录了写它时的版本。

3. **`GetObjectSchema` 有哪两个使用约束？**
   —— 只在读 `CObject*`（`ReadObject` 流程）时有效；每个对象只能查一次，查完即失效（返回前把 `m_nObjectSchema` 置 -1）。多次使用要先存局部变量。

4. **容器里的序列化对象归谁所有？释放代码写在哪个函数里，为什么？**
   —— 归文档所有。释放写在 `DeleteContents`：框架在新建/打开/关闭文档前都会调它，旧对象及时释放，打开失败的中途路径也有统一收尾；析构函数覆盖不到前两种时机。

5. **`ar.Write(&obj, sizeof(obj))` 为什么不行？**
   —— 裸内存里含指针（读到的是随机地址）、含 padding、没有类型和版本信息，跨进程跨版本都不可靠。逐字段 `<<` 或实现 `Serialize` 才是正道。

---
上一章：[16 MDI 多文档与分割窗口](16-mdi-splitter.md) ｜ 下一章：[18 GDI 绘图](18-gdi.md)
