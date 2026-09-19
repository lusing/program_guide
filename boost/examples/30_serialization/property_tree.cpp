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

    std::cout << "自检通过\n";
    return 0;
}
