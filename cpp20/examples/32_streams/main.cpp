#include <fstream>
#include <iomanip>
#include <iostream>
#include <limits>
#include <print>
#include <sstream>
#include <string>
#include <vector>

// 32 流 I/O：输入解析、流状态、操纵符与文件 —— print 之外的另一半

// ═══ 32.8 自定义类型接入流：operator<< / operator>>（规则四条见文档）═══
class Fraction {
public:
    Fraction(int n, int d) : num{n}, den{d} {}
    friend std::istream& operator>>(std::istream& in, Fraction& f) {        // 输入：非常量引用
        return in >> f.num >> f.den;                                        // 分子分母各读一个
    }
    friend std::ostream& operator<<(std::ostream& out, const Fraction& f) { // 输出：常量引用
        return out << f.num << '/' << f.den;                                // 返回流引用（链式）
    }
private:
    int num, den;
};

int main() {
    // ═══ 32.1 键盘替身：istringstream 模拟 cin（让示例可自动验证）═══
    std::istringstream input{"2000 11"};
    int a{}, b{};
    input >> a >> b;                                    // >> 跳空白、按类型解析
    std::println(">> 读入 {} 和 {}，和 = {}", a, b, a + b);

    // ═══ 32.2 流状态：while(cin >> x) 的全部原理 ═══
    std::istringstream nums{"10 20 x 40"};              // 第三个 token 是字母——类型不符
    std::vector<int> got;
    int x{};
    while (nums >> x) got.push_back(x);                 // 流到 bool 的转换：fail 即停
    std::println("循环读到 fail 为止：读到 {} 个（{} 和 {}）", got.size(), got[0], got[1]);
    std::println("fail 位已置：{}，且失败的 >> 把 x 清成了 {}", nums.fail(), x);   // C++11 规则
    nums.clear();                                       // 复位状态位
    nums.ignore(1);                                     // 只跳过错 token（坏整行用 ignore(max,'\n')）
    nums >> x;
    std::println("clear + ignore 跳过坏 token 后继续读：{}", x);

    // ═══ 32.3 操纵符：粘性与 setw 的一次性 ═══
    std::ostringstream fmt;
    fmt << std::hex << 255 << " " << std::oct << 8 << " " << std::dec << 16;   // 进制：粘
    fmt << " | " << std::setw(6) << std::setfill('.') << 42 << '|' << 42 << '|';   // setw 只管下一次！
    fmt << " | " << std::fixed << std::setprecision(3) << 3.14159;              // 粘
    fmt << ' ' << 2.5;
    fmt << " | " << std::boolalpha << true;
    std::println("操纵符全家：[{}]", fmt.str());

    // ═══ 32.4 getline 与 >> 混用：残留换行的经典坑 ═══
    {
        std::istringstream l1{"42\nhello world\n"};
        int n{}; std::string s;
        l1 >> n;                                        // 读 42，行尾 '\n' 留在流里
        std::getline(l1, s);
        std::println(">> 后直接 getline：拿到空行？{}（残留 '\\n' 被当整行）", s.empty());   // 坑现形
    }
    {
        std::istringstream l2{"42\nhello world\n"};
        int n{}; std::string s;
        l2 >> n;
        l2.ignore(std::numeric_limits<std::streamsize>::max(), '\n');   // 正确清场：先清残留
        std::getline(l2, s);
        std::println("ignore 清场后再 getline：[{}]（含空格整行到手）", s);
    }

    // ═══ 32.5 stringstream：解析与拼接 ═══
    std::istringstream parser{"3.14 2.72"};
    double p1{}, p2{};
    parser >> p1 >> p2;                                 // 连续解析 + 可判错：比 stoi 稳
    std::ostringstream joiner;
    joiner << "两数 = " << p1 << " / " << p2;           // 流式拼接（一次性场景用 format 更好）
    std::println("stringstream 解析+拼接：{}", joiner.str());

    // ═══ 32.6 fstream：RAII 管文件，逐行读 ═══
    {
        std::ofstream out{"stream_demo.txt"};           // 构造即打开；析构自动关
        out << "alpha 1\nbeta 2\ngamma 3\n";
    }                                                   // ← out 在这里析构、落盘
    std::ifstream in{"stream_demo.txt"};
    if (!in) {                                          // 打不开必须查（默认不抛异常）
        std::println("文件打不开");
        return 1;
    }
    std::string word;
    int count = 0, total = 0;
    while (in >> word >> x) {                           // 成对读：单词 + 数字
        ++count; total += x;
    }
    std::println("成对读入 {} 组，数字合计 = {}", count, total);

    // rdbuf 整文件搬运一瞥：out2 << in2.rdbuf() 一行拷贝整个文件（in2 需重开——上面的流已到 EOF）
    std::ifstream in2{"stream_demo.txt"};
    std::ostringstream whole;
    whole << in2.rdbuf();
    std::println("rdbuf 整读 {} 字节", whole.str().size());

    // ═══ 32.7 自定义类型：Fraction 像内建类型一样可流 ═══
    std::istringstream fin{"3 4"};
    Fraction f{1, 1};
    fin >> f;                                           // operator>> 解析输入——无替代品
    std::ostringstream fout;
    fout << f;                                          // operator<< 输出
    std::println("Fraction 流入流出：{}", fout.str());

    std::println("自检通过");
}
