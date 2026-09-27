#include <cctype>
#include <print>
#include <string>
#include <string_view>
#include <vector>

// 07 字符串深入：std::string 的构造、查找、修改与转换

int main() {
    // ═══ 7.1 构造与初始化：() 与 {} 不是一回事 ═══
    std::string literal{"Many a mickle makes a muckle"};
    std::string repeated(6, 'z');               // () ：重复 6 次 'z'
    // std::string wrong{6, 'z'};               // {}：把 6 当字符码——编译过但结果诡异
    std::string head{literal, 0, 4};            // 子串构造：起点 0、长度 4 → "Many"
    std::string tail{literal, 20};              // 只给起点：取到末尾 → "muckle"
    std::println("repeated = {}，head = {}，tail = {}", repeated, head, tail);

    // ═══ 7.2 拼接：+ 的两侧至少要有一个 string ═══
    std::string first{"Phil"};
    std::string full = first + " " + "McCavity";  // 字面量相邻拼接后再遇 string，合法
    // std::string bad = "Phil" + " " + first;    // 编译错：字面量 + 字面量不行
    std::println("full = {}（长度 {}）", full, full.size());
    // 字符 + 字符更隐蔽：不是拼接而是码点相加
    char comma{','}, space{' '};
    int code = comma + space;                     // 44 + 32 = 76，恰好是 'L'
    std::println("',' + ' ' 的算术结果是 {}（'L' 的字符码）", code);

    // ═══ 7.3 查找家族：返回下标或 npos 哨兵 ═══
    std::string sentence{"Manners maketh man"};
    std::println("find(\"man\")  = {}", sentence.find("man"));       // 15（子串 man）
    std::println("find('k')     = {}", sentence.find('k'));          // 10
    std::println("find(\"an\", 3) = {}", sentence.find("an", 3));     // 16：从下标 3 起再找
    std::println("rfind(\"an\")  = {}", sentence.rfind("an"));        // 16：反向找最后一个
    std::println("找不到时 find 返回 npos？{}", sentence.find('x') == std::string::npos);
    std::string separators{" ,.;:!?"};
    std::println("第一个分隔符在 {}（find_first_of）", sentence.find_first_of(separators));
    std::println("第一个非分隔字符在 {}（find_first_not_of）",
                 sentence.find_first_not_of(separators));
    // C++20/23 的三个“只问在不在/前后缀”的布尔查询
    std::println("contains \"an\"? {}; starts_with \"Man\"? {}; ends_with '.'? {}",
                 sentence.contains("an"), sentence.starts_with("Man"), sentence.ends_with('.'));

    // ═══ 7.4 子串与修改：C++ 标记法 = 起点 + 长度 ═══
    std::string phrase{"The higher the fewer."};
    std::string word{phrase.substr(4, 6)};       // 从下标 4 起取 6 个字符 → "higher"
    std::string to_end{phrase.substr(4, 100)};   // 长度越界不报错：截到串尾
    std::println("substr(4,6) = {}，substr(4,100) = {}", word, to_end);
    std::string text{"A rose is a rose is a rose."};
    text.replace(2, 4, "dandelion");             // 把下标 2 起 4 个字符换成新串（长度可不同）
    std::println("replace 后：{}", text);
    text.erase(0, 2);                            // 起点 + 长度：删掉 "A "
    std::println("erase(0,2) 后：{}", text);
    // erase(i) 是“从 i 删到尾”，不是“删第 i 个”——删单个要写 erase(i, 1)

    // ═══ 7.5 比较：字典序（按字符码逐位比较） ═══
    std::string a{"age"};
    std::string b{"beauty"};
    std::println("{} < {} ? {}", a, b, a < b);                 // a 的首字符码更小
    std::println("\"apple\" < \"applesauce\" ? {}", std::string{"apple"} < std::string{"applesauce"});
    const auto order{a <=> b};                                  // 三路比较：一次分出 < = >
    std::println("a <=> b 小于零？{}", std::is_lt(order));

    // ═══ 7.6 数值 ⇄ 字符串 ═══
    std::string num = std::to_string(3.14159);    // 固定 6 位小数，不可定制
    std::println("to_string(3.14159) = {}", num);
    std::println("stoi(\"245\") = {}", std::stoi(std::string{"245"}));
    // 要控制格式 → std::format/print；要无异常最快解析 → from_chars（第 10 章）

    // ═══ 7.7 string_view：零拷贝只读视图 ═══
    std::string_view sv{literal};                // 不拷贝字符，只是“指针 + 长度”
    std::string_view slice{sv.substr(10, 6)};    // 切片同样零拷贝
    std::println("view 切片 = {}", slice);
    // view → string 必须显式（一定伴随拷贝），编译器不代劳
    std::string owned{slice};
    owned += "!";
    std::println("物化成 string 后可拼接：{}", owned);

    // ═══ 7.8 原始字符串字面量：反斜杠不再转义 ═══
    auto path{R"(C:\ProgramData\guide\file.ext)"};
    std::println("路径字面量 = {}", path);
    auto regex_like{R"(\d{4}-\d{2})"};           // 正则写法原样保留（第 29 章实战）
    std::println("正则字面量 = {}", regex_like);

    // ═══ 7.9 逐字符处理：<cctype> 的分类与大小写 ═══
    std::string mixed{"Hello, C++ 23!"};
    int letters = 0, spaces = 0;
    for (unsigned char ch : mixed) {             // <cctype> 函数要求 unsigned char
        if (std::isalpha(ch)) ++letters;
        if (std::isspace(ch)) ++spaces;
    }
    for (char& ch : mixed) {
        ch = static_cast<char>(std::toupper(ch));
    }
    std::println("字母 {} 个、空白 {} 个；全大写：{}", letters, spaces, mixed);

    std::println("自检通过");
}
