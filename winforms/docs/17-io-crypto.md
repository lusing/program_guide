# 17 · 文件 IO 与加密：哈希、AES、口令派生

> 对应示例：`examples/17_io_crypto`（文件保险箱：选文件 → SHA256 → AES 加密 → 解密 → 哈希校验闭环）

> **本章你将学会**：文件哈希、对称加密 AES、口令派生 PBKDF2、加解密流水线、后台执行不冻 UI。
> **前置章节**：[09 对话框](09-dialogs.md)、[16 线程](16-threading.md)。IO 基础见 [dotnet 12 章](../../dotnet/docs/12-files-json.md)。

## 1. 文件哈希：数字指纹

```csharp
private static byte[] Sha256(string path)
{
    using var sha = SHA256.Create();
    using var fs = File.OpenRead(path);
    return sha.ComputeHash(fs);           // 流式读：大文件不吃内存
}
```

SHA256 是完整性的标尺：**一字节不同，哈希全变**。17 示例的闭环实测（fsx 脚本验证过的真实输出）：

```text
原文哈希   EE882C95B3028168
加密后大小 96（原 52 + 32 头 + PKCS7 填充）
密文哈希   0AEEA01CA5D626AB（与原文完全不同）
解密哈希   EE882C95B3028168
往返一致:   true
错口令拦截: true
```

## 2. 口令不是密钥：PBKDF2

AES 要 32 字节密钥，用户口令是人话。**直接 hash 口令当密钥**是安全大忌（字典攻击一秒跑完）——正解是带盐拉伸：

```csharp
private static byte[] DeriveKey(string pwd, byte[] salt, int len) =>
    Rfc2898DeriveBytes.Pbkdf2(pwd, salt, 100_000, HashAlgorithmName.SHA256, len);
```

- **盐（salt）**：随机 16 字节，每次加密都换——同样的口令+同样的文件，两次密文完全不同（17 示例特意让用户验证这一点）
- **10 万轮迭代**：合法用户多花几毫秒，暴力破解成本乘十万倍

## 3. AES 加密文件：布局与流水线

```csharp
using var aes = Aes.Create();                    // 默认 CBC + PKCS7（教材时代的默认即安全）
byte[] salt = RandomNumberGenerator.GetBytes(16);
aes.Key = DeriveKey(pwd, salt, aes.KeySize / 8);
aes.IV = RandomNumberGenerator.GetBytes(16);

using (var outFs = File.Create(dst))
{
    outFs.Write(salt, 0, salt.Length);           // 盐不保密，跟着文件走
    outFs.Write(aes.IV, 0, aes.IV->Length);      // IV 同理
    using var enc = aes.CreateEncryptor();
    using var cs = new CryptoStream(outFs, enc, CryptoStreamMode.Write);
    using (var inFs = File.OpenRead(src)) inFs.CopyTo(cs);
    // CryptoStream 关闭时自动补 PKCS7 填充——密文尾部那几字节
}
```

**文件布局 `[16 盐][16 IV][密文]`**：解密端先读头 32 字节恢复参数再解密。解密口令不对时，PKCS7 校验失败抛 `CryptographicException`——"口令错误"就是靠这个异常识别的（比返回错误码诚实）。

```csharp
inFs.ReadExactly(salt, 0, salt.Length);          // .NET 7+：读不满直接抛（旧的 Read 会短读）
inFs.ReadExactly(iv, 0, iv.Length);
…
using var cs = new CryptoStream(inFs, dec, CryptoStreamMode.Read);
cs.CopyTo(outFs);                                // ← 口令错时这里抛 CryptographicException
```

## 4. UI 编排：后台干活 + 弹回汇报

加密/解密都跑在 `Task.Run`（16 章的规矩），完成后回 UI 线程弹结果——三语言三种编排：

- **C#**：`async void` 事件处理器 + `await Task.Run(...)`（16 章同款）
- **F#**：`Task.Run(fun () -> …)` 里 try/with 包住，`form.BeginInvoke` 弹回（17 的 F# 版完整示例）
- **C++/CLI**：**小状态类当闭包**——没有 lambda 的世界里捕获参数的惯用法：

```cpp
ref class DecryptJob
{
    String^ _enc; String^ _dec; String^ _pwd; String^ _orig;
    MainForm^ _form;
    bool _same;
public:
    DecryptJob(…);                    // 声明在前（要用 MainForm 的成员）
    void Run();                       // 跑在线程池：只算数不碰控件
    void RunUi();                     // BeginInvoke 弹回 UI 后弹窗汇报
};

// 使用：
auto job = gcnew DecryptJob(enc, dec, _pwd->Text, _picked, this);
Task::Run(gcnew Action(job, &DecryptJob::Run));
```

`Run()` 干完活 `_form->BeginInvoke(gcnew Action(this, &DecryptJob::RunUi))`。**方法体要摸 MainForm 成员的类，先声明、MainForm 之后再定义方法体**（前向引用的 C++ 老规矩）。

## 5. 老教材 → 现代 API 对照（书的第 8 章）

| 书里（2018/教材） | 现代 .NET（本教程） |
|---|---|
| `DESCryptoServiceProvider` | **已删**。用 `Aes.Create()` |
| `RijndaelManaged` | 同上（AES 即 Rijndael 的标准化） |
| `new RNGCryptoServiceProvider()` | `RandomNumberGenerator.GetBytes(n)`（静态） |
| `Rfc2898DeriveBytes(pwd, salt)` 构造 | `Rfc2898DeriveBytes.Pbkdf2(...)` 静态方法（默认 SHA1 → 显式 SHA256） |
| `md5 / SHA1` 演示 | 教学可提，**生产用 SHA256 起**（MD5/SHA1 已可碰撞） |

## 6. 坑位清单

1. 口令直接当 Key（或 hash 一下当 Key）→ 字典攻击秒破；PBKDF2 + 随机盐。
2. 盐/IV 也保密 → 没必要还难自洽；它们**跟着文件走**（明文头）。
3. 每次加密用同一个 IV → 同明文同密文，模式泄露；**每次随机**。
4. 用 `Stream.Read` 读定长头 → 短读悄悄错位；`ReadExactly`。
5. C++/CLI `String^ a, b;` 逗号声明 → `b` 是裸 String（C3149）；^ 不随逗号传播，逐个声明。
6. C++/CLI 给 `Btn(text, &MainForm::OnX)` 这类"成员函数指针形参"造委托 → C3754；老老实实每个按钮 `+= gcnew EventHandler(this, &T::OnX)`。

## 自测

1. 为什么"原文哈希 == 解密哈希"能证明还原成功？它同时证明了哪两件事？
2. 盐为什么要每次随机？它保密吗？存在哪？
3. 口令错误时异常从哪一步抛出？异常类型？
4. `[盐][IV][密文]` 布局中，解密端前 32 字节的读取为什么必须"读满"？
5. C++/CLI 版为什么需要 DecryptJob 这个类？它替代了 C# 的什么语法？
