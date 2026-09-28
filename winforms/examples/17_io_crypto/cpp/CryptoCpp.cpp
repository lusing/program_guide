// 17 文件 IO 与加密（C++/CLI 版）
using namespace System;
using namespace System::Drawing;
using namespace System::IO;
using namespace System::Security::Cryptography;
using namespace System::Windows::Forms;

namespace CryptoCpp {

    // ── 静态工具 ──
    ref class Crypto abstract sealed
    {
    public:
        static array<unsigned char>^ Sha256(String^ path)
        {
            auto sha = SHA256::Create();
            auto fs = File::OpenRead(path);
            auto hash = sha->ComputeHash(fs);
            delete fs; delete sha;
            return hash;
        }

        static array<unsigned char>^ DeriveKey(String^ pwd, array<unsigned char>^ salt, int len)
        {
            return Rfc2898DeriveBytes::Pbkdf2(pwd, salt, 100000, HashAlgorithmName::SHA256, len);
        }

        // 加密产物布局：[16 字节盐][16 字节 IV][密文]
        static void EncryptFile(String^ src, String^ dst, String^ pwd)
        {
            auto aes = Aes::Create();                 // 默认 CBC + PKCS7
            auto salt = RandomNumberGenerator::GetBytes(16);
            aes->Key = DeriveKey(pwd, salt, aes->KeySize / 8);
            aes->IV = RandomNumberGenerator::GetBytes(16);

            auto outFs = File::Create(dst);
            outFs->Write(salt, 0, salt->Length);
            outFs->Write(aes->IV, 0, aes->IV->Length);
            auto enc = aes->CreateEncryptor();
            auto cs = gcnew CryptoStream(outFs, enc, CryptoStreamMode::Write);
            auto inFs = File::OpenRead(src);
            inFs->CopyTo(cs);
            delete inFs; delete cs; delete enc; delete outFs; delete aes;
        }

        static void DecryptFile(String^ src, String^ dst, String^ pwd)
        {
            auto aes = Aes::Create();
            auto inFs = File::OpenRead(src);
            auto salt = gcnew array<unsigned char>(16);
            auto iv = gcnew array<unsigned char>(16);
            inFs->ReadExactly(salt, 0, 16);
            inFs->ReadExactly(iv, 0, 16);
            aes->Key = DeriveKey(pwd, salt, aes->KeySize / 8);
            aes->IV = iv;
            auto dec = aes->CreateDecryptor();
            auto cs = gcnew CryptoStream(inFs, dec, CryptoStreamMode::Read);
            auto outFs = File::Create(dst);
            cs->CopyTo(outFs);                        // 口令不对时这里抛 CryptographicException
            delete outFs; delete cs; delete dec; delete inFs; delete aes;
        }
    };

    // ═══ C++/CLI 没有 lambda：后台任务的参数捕获用小状态类 ═══
    // DecryptJob 的方法体要摸 MainForm 的成员，但类在 MainForm 之前定义——先声明，方法体挪到 MainForm 之后
    ref class MainForm;

    ref class EncryptJob
    {
    private:
        // 注意：^ 不随逗号声明传播——String^ a, b; 的 b 是裸 String（C3149）
        String^ _src;
        String^ _dst;
        String^ _pwd;
    public:
        EncryptJob(String^ src, String^ dst, String^ pwd) { _src = src; _dst = dst; _pwd = pwd; }
        void Run() { Crypto::EncryptFile(_src, _dst, _pwd); }
    };

    ref class DecryptJob
    {
    private:
        String^ _enc;
        String^ _dec;
        String^ _pwd;
        String^ _orig;
        MainForm^ _form;
        bool _same;

    public:
        DecryptJob(String^ enc, String^ dec, String^ pwd, String^ orig, MainForm^ form);
        void Run();
        void RunUi();
        void BadPwdUi();

    private:
        static bool EnumerableEquals(array<unsigned char>^ a, array<unsigned char>^ b);
    };

    public ref class MainForm : public Form
    {
    private:
        Label^ _status;
        TextBox^ _file;
        TextBox^ _pwd;
        Label^ _hash;
        String^ _picked;

    public:
        MainForm()
        {
            Text = L"文件保险箱（C++/CLI）";
            ClientSize = System::Drawing::Size(640, 300);
            StartPosition = FormStartPosition::CenterScreen;
            Font = gcnew Drawing::Font(L"微软雅黑", 10.0f);
            FormBorderStyle = System::Windows::Forms::FormBorderStyle::FixedDialog;
            MaximizeBox = false;
            _picked = nullptr;

            _file = gcnew TextBox(); _file->Location = System::Drawing::Point(70, 30);
            _file->Width = 370; _file->ReadOnly = true;
            _pwd = gcnew TextBox(); _pwd->Location = System::Drawing::Point(70, 70);
            _pwd->Width = 370; _pwd->UseSystemPasswordChar = true;

            auto fileLbl = gcnew Label(); fileLbl->Text = L"文件："; fileLbl->AutoSize = true;
            fileLbl->Location = System::Drawing::Point(16, 34);
            auto pwdLbl = gcnew Label(); pwdLbl->Text = L"口令："; pwdLbl->AutoSize = true;
            pwdLbl->Location = System::Drawing::Point(16, 74);

            auto pick = Btn(L"① 选一个文件…");
            pick->Click += gcnew EventHandler(this, &MainForm::OnPick);
            auto hash = Btn(L"② 算 SHA256");
            hash->Click += gcnew EventHandler(this, &MainForm::OnHash);
            auto enc = Btn(L"③ 加密 → .enc");
            enc->Click += gcnew EventHandler(this, &MainForm::OnEncrypt);
            auto dec = Btn(L"④ 解密 → .dec 并校验");
            dec->Click += gcnew EventHandler(this, &MainForm::OnDecrypt);

            _hash = gcnew Label(); _hash->AutoSize = true;
            _hash->Location = System::Drawing::Point(16, 200);
            _hash->ForeColor = Color::DimGray; _hash->Text = L"哈希会显示在这里";

            _status = gcnew Label(); _status->Dock = DockStyle::Bottom; _status->Height = 60;
            _status->BackColor = Color::Gainsboro; _status->TextAlign = ContentAlignment::MiddleLeft;

            Controls->AddRange(gcnew array<Control^>
            {
                _status, _hash, dec, enc, hash, _pwd, pick, _file, pwdLbl, fileLbl
            });
            Say(L"小提示：先拿个小文本文件练手。加解密在线程池跑，完事弹回 UI。");
        }

    private:
        int _nextY = 30;

        Button^ Btn(String^ text)
        {
            auto b = gcnew Button();
            b->Text = text; b->AutoSize = true;
            b->Location = System::Drawing::Point(460, _nextY);
            _nextY += 40;
            return b;
        }

        void Say(String^ msg) { _status->Text = L"  " + msg; }

        void OnPick(Object^ s, EventArgs^ e)
        {
            auto dlg = gcnew OpenFileDialog();
            dlg->Filter = L"所有文件|*.*";
            if (dlg->ShowDialog(this) == System::Windows::Forms::DialogResult::OK)
            {
                _picked = dlg->FileName;
                _file->Text = _picked;
                _hash->Text = L"哈希会显示在这里";
            }
            delete dlg;
        }

        void OnHash(Object^ s, EventArgs^ e)
        {
            if (_picked == nullptr) { Say(L"先选文件"); return; }
            auto hex = Convert::ToHexString(Crypto::Sha256(_picked));
            _hash->Text = String::Format(L"SHA256 = {0}…（前 16 位十六进制）", hex->Substring(0, 16));
            Say(L"哈希已算出。加密后再算 .enc 的哈希对比——完全不同；解密回来应当与现在一致");
        }

        // 后台加密：线程池干活（状态类捕获参数），UI 不冻
        void OnEncrypt(Object^ s, EventArgs^ e)
        {
            if (_picked == nullptr) { Say(L"先选文件"); return; }
            if (_pwd->Text->Length < 4) { Say(L"口令至少 4 个字符"); return; }
            auto job = gcnew EncryptJob(_picked, _picked + L".enc", _pwd->Text);
            Threading::Tasks::Task::Run(gcnew Action(job, &EncryptJob::Run));
            Say(String::Format(L"后台加密中 → {0}.enc。每次加密结果都不同（随机盐 + 随机 IV）", _picked));
        }

        void OnDecrypt(Object^ s, EventArgs^ e)
        {
            if (_picked == nullptr) { Say(L"先选文件"); return; }
            String^ enc = _picked + L".enc";
            if (!File::Exists(enc)) { Say(String::Format(L"没找到 {0}，先加密", enc)); return; }
            auto job = gcnew DecryptJob(enc, _picked + L".dec", _pwd->Text, _picked, this);
            Threading::Tasks::Task::Run(gcnew Action(job, &DecryptJob::Run));
            Say(L"正在解密并校验（后台线程）…");
        }

    public:
        // DecryptJob 弹回 UI 后的收尾（只能由 UI 线程调）
        void ReportResult(bool same)
        {
            Say(same ? L"还原成功" : L"还原失败");
        }
    };

    // ── DecryptJob 的方法体（MainForm 已完整可见）──
    DecryptJob::DecryptJob(String^ enc, String^ dec, String^ pwd, String^ orig, MainForm^ form)
    {
        _enc = enc; _dec = dec; _pwd = pwd; _orig = orig; _form = form; _same = false;
    }

    void DecryptJob::Run()
    {
        try
        {
            Crypto::DecryptFile(_enc, _dec, _pwd);
            _same = EnumerableEquals(Crypto::Sha256(_orig), Crypto::Sha256(_dec));
            _form->BeginInvoke(gcnew Action(this, &DecryptJob::RunUi));
        }
        catch (CryptographicException^)
        {
            _form->BeginInvoke(gcnew Action(this, &DecryptJob::BadPwdUi));
        }
        catch (Exception^ ex)
        {
            Console::WriteLine(ex->Message);
        }
    }

    void DecryptJob::RunUi()
    {
        MessageBox::Show(_form,
            _same ? L"✔ 哈希一致——解密还原成功（口令正确、数据未被动过）"
                  : L"✘ 哈希不一致！（口令错了或文件被动过）", L"校验结果");
        _form->ReportResult(_same);
    }

    void DecryptJob::BadPwdUi()
    {
        MessageBox::Show(_form, L"口令不对（AES 解不开）", L"校验结果");
        _form->ReportResult(false);
    }

    bool DecryptJob::EnumerableEquals(array<unsigned char>^ a, array<unsigned char>^ b)
    {
        if (a->Length != b->Length) return false;
        for (int i = 0; i < a->Length; i++)
            if (a[i] != b[i]) return false;
        return true;
    }

    public ref class App
    {
    public:
        static void Run()
        {
            Application::EnableVisualStyles();
            Application::SetCompatibleTextRenderingDefault(false);
            Application::Run(gcnew MainForm());
        }
    };
}
