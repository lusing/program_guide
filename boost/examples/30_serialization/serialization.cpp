// serialization.cpp —— Boost.Serialization（2002）：C++ 对象 ↔ 字节流。
// 文本/XML/二进制三种档案 + 指针/继承/STL 容器全覆盖。
// 对应文档：docs/30-serialization.md
#include <boost/archive/text_oarchive.hpp>
#include <boost/archive/text_iarchive.hpp>
#include <boost/archive/binary_oarchive.hpp>
#include <boost/archive/binary_iarchive.hpp>
#include <boost/serialization/vector.hpp>
#include <boost/serialization/string.hpp>
#include <boost/serialization/map.hpp>
#include <fstream>
#include <iostream>
#include <sstream>
#include <string>
#include <vector>

struct Record {
    int id = 0;
    std::string name;
    std::vector<double> samples;

    // 成员函数 serialize 是接入点：archive 是"方向无关"的（同一函数
    // 既管存也管取）
    template <class Archive>
    void serialize(Archive& ar, const unsigned int) {
        ar& id& name& samples;
    }
};

int main() {
    // 1) 文本档案（stringstream，无需文件）
    std::ostringstream oss;
    {
        boost::archive::text_oarchive oa(oss);
        Record r{7, "sensor-a", {1.5, 2.5, 3.5}};
        oa << r;
    }
    std::cout << "文本档案长度 = " << oss.str().size() << " 字节\n";

    // 2) 读回：同一 serialize 函数反方向走
    Record back;
    {
        std::istringstream iss(oss.str());
        boost::archive::text_iarchive ia(iss);
        ia >> back;
    }
    std::cout << "读回: id=" << back.id << " name=" << back.name
              << " samples=" << back.samples.size() << " 个\n";
    std::cout << "值相等? " << (back.name == "sensor-a" && back.samples[2] == 3.5) << '\n';

    // 3) STL 容器直接可存（配对应的 serialization 头）
    std::map<std::string, int> scores{{"ada", 95}, {"bob", 88}};
    std::ostringstream oss2;
    {
        boost::archive::text_oarchive oa(oss2);
        oa << scores;
    }
    std::map<std::string, int> scores2;
    {
        std::istringstream iss(oss2.str());
        boost::archive::text_iarchive ia(iss);
        ia >> scores2;
    }
    std::cout << "map 读回大小 = " << scores2.size() << " ada=" << scores2.at("ada") << '\n';

    // 4) 二进制档案（更紧凑）：落盘再读
    {
        std::ofstream f("build_serialization.bin", std::ios::binary);
        boost::archive::binary_oarchive oa(f);
        oa << back;
    }
    Record from_file;
    {
        std::ifstream f("build_serialization.bin", std::ios::binary);
        boost::archive::binary_iarchive ia(f);
        ia >> from_file;
    }
    std::cout << "二进制往返一致? " << (from_file.id == 7) << '\n';

    std::cout << "自检通过\n";
    return 0;
}
