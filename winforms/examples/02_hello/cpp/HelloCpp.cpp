// 02 第一个 WinForms 程序（C++/CLI 版）
// 与 csharp/ 的 C# 版功能一致。C++/CLI 语法地图：
//   gcnew T(...)        托管堆分配（对应 C# 的 new）    句柄类型 T^
//   btn->Text           句柄用 -> 访问成员（同 C++ 指针）
//   gcnew EventHandler(this, &T::OnX)   成员函数做事件处理器（对应 C# 的方法组）
//   L"..."              宽字符串字面量；String^ 拼接用 String::Concat / String::Format
using namespace System;
using namespace System::Windows::Forms;

namespace HelloCpp {

    public ref class MainForm : public Form
    {
    private:
        int _count;
        Label^ _label;
        Button^ _button;

    public:
        MainForm()
        {
            _count = 0;

            Text = L"你好，WinForms（C++/CLI）";
            Width = 420; Height = 170;
            StartPosition = FormStartPosition::CenterScreen;

            _label = gcnew Label();
            _label->Text = L"等你点击下面的按钮";
            _label->Dock = DockStyle::Top;
            _label->Height = 60;

            _button = gcnew Button();
            _button->Text = L"点我一下";
            _button->Dock = DockStyle::Bottom;
            _button->Height = 45;
            // 事件接线：gcnew EventHandler 把成员函数包成委托再 +=（等价于 C# 的 this.OnClick +=）
            _button->Click += gcnew EventHandler(this, &MainForm::OnClick);

            Controls->Add(_label);
            Controls->Add(_button);
        }

    private:
        void OnClick(Object^ sender, EventArgs^ e)
        {
            _count++;
            _label->Text = String::Format(L"第 {0} 次点击——C++/CLI 版与 C# 版行为一致", _count);
        }
    };

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
