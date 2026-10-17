// property_tree.cpp —— Boost.PropertyTree（2006）：通用树形配置——
// 一套代码读写 JSON/XML/INI/INF 四种格式。
// 对应文档：docs/30-serialization.md
#include <boost/property_tree/ptree.hpp>
#include <boost/property_tree/json_parser.hpp>
#include <boost/property_tree/xml_parser.hpp>
#include <boost/property_tree/ini_parser.hpp>
#include <iostream>
#include <sstream>

namespace pt = boost::property_tree;

int main() {
    // 1) 建树
    pt::ptree root;
    root.put("app.name", "guide");
    root.put("app.port", 8080);
    root.put("app.debug", true);
    pt::ptree tags;
    for (const char* t : {"cpp", "boost", "tutorial"}) {
        pt::ptree item;
        item.put("", t);
        tags.push_back(std::make_pair("", item));
    }
    root.put_child("app.tags", tags);

    // 2) 序列化成 JSON
    std::ostringstream json_out;
    pt::write_json(json_out, root, false);           // false = 紧凑
    std::cout << "JSON = " << json_out.str() << '\n';

    // 3) 读回：路径访问（点号分层）
    pt::ptree loaded;
    std::istringstream json_in(R"({"app":{"name":"guide2","port":9090}})");
    pt::read_json(json_in, loaded);
    std::cout << "name = " << loaded.get<std::string>("app.name")
              << " port = " << loaded.get<int>("app.port") << '\n';

    // 4) 带默认值的取数（缺键不炸）
    std::cout << "缺省值 = " << loaded.get("app.missing", std::string("无")) << '\n';

    // 5) 同一棵树写 XML / INI——"一套数据结构，多格式出口"
    std::ostringstream xml_out;
    pt::write_xml(xml_out, root);
    std::cout << "XML 首段 = " << xml_out.str().substr(0, 40) << "...\n";

    // 6) 解析 INI
    pt::ptree ini;
    std::istringstream ini_in("[main]\ncount = 42\n");
    pt::read_ini(ini_in, ini);
    std::cout << "INI count = " << ini.get<int>("main.count") << '\n';

    // 7) put 与 add 的分野：put 改**已有的第一个**同名节点，add 追加**新的**
    pt::ptree conf;
    conf.put("conf.urls.url", "url1");
    conf.put("conf.urls.url", "url2");      // 改掉 url1（不是追加！）
    conf.add("conf.urls.url", "url3");      // 追加新节点
    int urls = 0;
    for (const auto& u : conf.get_child("conf.urls")) (void)u, ++urls;
    std::cout << "put 覆盖 + add 追加: " << urls << " 个 url\n";

    // 8) XML 的三件特殊节点：属性 <xmlattr> / 注释 <xmlcomment> / 文本 <xmltext>
    pt::ptree x;
    std::istringstream xml_in(
        "<conf><!-- note --><gui>1</gui>"
        "<theme id=\"001\">matrix</theme></conf>");
    pt::read_xml(xml_in, x);
    std::cout << "XML: theme=" << x.get<std::string>("conf.theme")
              << " 属性 id=" << x.get<int>("conf.theme.<xmlattr>.id")
              << " 注释=" << x.get<std::string>("conf.<xmlcomment>") << '\n';

    // 9) 路径分隔符可换（键名本身带点号时）；异常版与 optional 版的取数
    pt::ptree dotted;
    dotted.put("theme.name1", "v1");                // 这是两层！
    pt::ptree::path_type slash("theme.name1", '/'); // 斜杠视作普通字符
    dotted.put(slash, "整键");
    std::cout << "斜杠路径下 \"theme.name1\" 是一个整键? "
              << (dotted.get<std::string>(slash) == "整键") << '\n';
    bool threw = false;
    try {
        dotted.get<std::string>("no.such.path");
    } catch (const pt::ptree_error&) {
        threw = true;                                // ptree_bad_path / ptree_bad_data
    }
    std::cout << "缺路径抛 ptree_error? " << threw
              << " get_optional 版? "
              << dotted.get_optional<std::string>("no.such.path").has_value()
              << "（optional 版不抛）\n";

    std::cout << "自检通过\n";
    return 0;
}
