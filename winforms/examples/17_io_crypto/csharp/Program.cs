// 17 文件 IO 与加密：SHA256 完整性、AES 对称加密、PBKDF2 口令派生（书的第 8 章现代版）
using System.Drawing;
using System.Security.Cryptography;
using System.Windows.Forms;

namespace CryptoWin;

internal class MainForm : Form
{
    private Label _status;
    private TextBox _file;
    private TextBox _pwd;
    private Label _hash;
    private string _picked;

    public MainForm()
    {
        Text = "文件保险箱";
        ClientSize = new Size(640, 300);
        StartPosition = FormStartPosition.CenterScreen;
        Font = new Font("微软雅黑", 10F);
        FormBorderStyle = FormBorderStyle.FixedSingle;
        MaximizeBox = false;

        var pick = Btn("① 选一个文件…", Pick);
        _file = Box(30, readOnly: true);
        _pwd = Box(70, readOnly: false);
        _pwd.UseSystemPasswordChar = true;
        var hash = Btn("② 算 SHA256", DoHash);
        var enc = Btn("③ 加密 → .enc", Encrypt);
        var dec = Btn("④ 解密 → .dec 并校验", Decrypt);

        _hash = new Label { AutoSize = true, Location = new Point(16, 200), ForeColor = Color.DimGray, Text = "哈希会显示在这里" };
        _status = new Label { Dock = DockStyle.Bottom, Height = 60, BackColor = Color.Gainsboro, TextAlign = ContentAlignment.MiddleLeft, Padding = new Padding(8, 0, 0, 0) };

        Controls.AddRange(new Control[] { _status, _hash, dec, enc, hash, _pwd, pick, _file, Lbl(70, "口令："), Lbl(30, "文件：") });
        Say("小提示：先拿个小文本文件练手。加密/解密在后台线程跑，不冻界面。");
    }

    private static Label Lbl(int y, string t) => new() { Text = t, AutoSize = true, Location = new Point(16, y + 4) };

    private Button Btn(string text, Action onClick)
    {
        var b = new Button { Text = text, AutoSize = true, Location = new Point(460, _nextY) };
        b.Click += (s, e) => onClick();
        _nextY += 40;
        return b;
    }
    private int _nextY = 30;

    private static TextBox Box(int y, bool readOnly)
    {
        var t = new TextBox { Location = new Point(70, y), Width = 370, ReadOnly = readOnly };
        return t;
    }

    private void Say(string msg) => _status.Text = "  " + msg;

    private void Pick()
    {
        using var dlg = new OpenFileDialog { Filter = "所有文件|*.*" };
        if (dlg.ShowDialog(this) != DialogResult.OK) return;
        _picked = dlg.FileName;
        _file.Text = _picked;
        _hash.Text = "哈希会显示在这里";
    }

    // ═══ 17.1 SHA256：文件指纹，一字节不同则全变 ═══
    private void DoHash()
    {
        if (_picked is null) { Say("先选文件"); return; }
        _hash.Text = $"SHA256 = {Convert.ToHexString(Sha256(_picked))[..16]}…（前 16 位十六进制）";
        Say("哈希已算出。加密后再算 .enc 的哈希对比——完全不同；解密回来应当与现在一致");
    }

    // ═══ 17.2/17.3 加密：口令 → PBKDF2 → AES ═══
    private async void Encrypt()
    {
        if (_picked is null) { Say("先选文件"); return; }
        if (_pwd.Text.Length < 4) { Say("口令至少 4 个字符"); return; }
        Say("正在加密（后台线程）…");
        try
        {
            string enc = await Task.Run(() => AesFile(_picked, _picked + ".enc", _pwd.Text, encrypt: true));
            Say($"已生成 {enc}。现在点 ② 算一下 .enc 的哈希？——每次加密结果都不同（随机盐 + 随机 IV）");
        }
        catch (Exception ex) { Say($"加密失败：{ex.Message}"); }
    }

    private async void Decrypt()
    {
        string enc = _picked + ".enc";
        if (_picked is null) { Say("先选文件"); return; }
        if (!File.Exists(enc)) { Say($"没找到 {enc}，先加密"); return; }
        string dec = _picked + ".dec";
        Say("正在解密并校验（后台线程）…");
        try
        {
            await Task.Run(() => AesFile(enc, dec, _pwd.Text, encrypt: false));
            // ═══ 17.4 完整性校验：原文与解密文哈希必须一致 ═══
            bool same = Sha256(_picked).SequenceEqual(Sha256(dec));
            MessageBox.Show(this, same
                ? "✔ 哈希一致——解密还原成功（口令正确、数据未被动过）"
                : "✘ 哈希不一致！（口令错了或文件被动过）", "校验结果");
            Say(same ? "还原成功" : "还原失败");
        }
        catch (CryptographicException)
        {
            MessageBox.Show(this, "口令不对（AES 解不开）", "校验结果");
            Say("口令错误");
        }
        catch (Exception ex) { Say($"解密失败：{ex.Message}"); }
    }

    // ── 工具 ──
    private static byte[] Sha256(string path)
    {
        using var sha = SHA256.Create();
        using var fs = File.OpenRead(path);
        return sha.ComputeHash(fs);
    }

    // 加/解密一个文件。加密产物布局：[16 字节盐][16 字节 IV][密文]
    private static string AesFile(string src, string dst, string pwd, bool encrypt)
    {
        using var aes = Aes.Create();               // 默认 CBC + PKCS7
        if (encrypt)
        {
            byte[] salt = RandomNumberGenerator.GetBytes(16);
            aes.Key = DeriveKey(pwd, salt, aes.KeySize / 8);
            aes.IV = RandomNumberGenerator.GetBytes(16);
            using (var outFs = File.Create(dst))
            {
                outFs.Write(salt, 0, salt.Length);  // 盐不保密，跟着文件走
                outFs.Write(aes.IV, 0, aes.IV.Length);
                using var enc = aes.CreateEncryptor();
                using var cs = new CryptoStream(outFs, enc, CryptoStreamMode.Write);
                using (var inFs = File.OpenRead(src)) inFs.CopyTo(cs);
            }
        }
        else
        {
            using var inFs = File.OpenRead(src);
            byte[] salt = new byte[16], iv = new byte[16];
            inFs.ReadExactly(salt);
            inFs.ReadExactly(iv);
            aes.Key = DeriveKey(pwd, salt, aes.KeySize / 8);
            aes.IV = iv;
            using var dec = aes.CreateDecryptor();
            using var cs = new CryptoStream(inFs, dec, CryptoStreamMode.Read);
            using var outFs = File.Create(dst);
            cs.CopyTo(outFs);                       // 口令不对时这里抛 CryptographicException
        }
        return dst;
    }

    // PBKDF2：口令不是密钥——拉伸 + 加盐，每秒百万次尝试的代价
    private static byte[] DeriveKey(string pwd, byte[] salt, int len) =>
        Rfc2898DeriveBytes.Pbkdf2(pwd, salt, 100_000, HashAlgorithmName.SHA256, len);
}

internal static class Program
{
    [STAThread]
    static void Main()
    {
        Application.EnableVisualStyles();
        Application.SetCompatibleTextRenderingDefault(false);
        Application.Run(new MainForm());
    }
}
