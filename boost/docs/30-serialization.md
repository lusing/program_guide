# 30 · 序列化与配置：serialization / property_tree / json

> 对应示例：`examples/30_serialization/`（3 个例程）

三个库三种定位：**Serialization** 管"C++ 对象 ↔ 字节流"（版本化、指针图）、**PropertyTree** 管"多格式配置文件"（JSON/XML/INI 一套通吃）、**JSON** 管"高性能 JSON 专精"（DOM/SAX 双模）。

## 30.1 Boost.Serialization（2002）：对象持久化

接入点是**方向无关**的 `serialize` 成员函数（同一函数既存又取）：

```cpp
struct Record { int id; std::string name; std::vector<double> samples;
    template <class Archive>
    void serialize(Archive& ar, const unsigned int) { ar& id& name& samples; }
};
boost::archive::text_oarchive oa(oss);   oa << r;
boost::archive::text_iarchive ia(iss);   ia >> back;
```

运行输出（`serialization.cpp`）：

```text
文本档案长度 = 122 字节
读回: id=7 name=sensor-a samples=3 个
值相等? 1
map 读回大小 = 2 ada=95
二进制往返一致? 1
自检通过
```

看家本领（例程外）：**指针序列化**（多态指针存取自动恢复动态类型）、**对象追踪**（同一指针两次存档只存一份，读回仍是同一对象）、**版本化**（`BOOST_CLASS_VERSION` + serialize 的第二参数做档案演进）、STL 容器全家（每个容器一个 `boost/serialization/xxx.hpp`）。**注意**：它不是 JSON/XML 那种"数据交换格式"，是有版本语义的**二进制/文本存档**——跨版本兼容要自己管。⭐ 保存/恢复程序状态的标准答案。

## 30.2 Boost.PropertyTree（2006）：一套树，四种格式

```cpp
ptree root;
root.put("app.port", 8080);                 // 点号路径
pt::write_json(oss, root);                  // JSON 出口
pt::read_xml / read_ini / read_info;        // 同一棵树的其他出口
loaded.get<int>("app.port");                // 带类型取数
loaded.get("app.missing", "无");            // 带默认值
```

运行输出（`property_tree.cpp`）：

```text
JSON = {"app":{"name":"guide","port":"8080","debug":"true","tags":["cpp","boost","tutorial"]}}
name = guide2 port = 9090
缺省值 = 无
XML 首段 = <?xml version="1.0" encoding="utf-8"?>
INI count = 42
自检通过
```

**注意输出的真相**：ptree 把所有值存成**字符串**——JSON 里 `"port":"8080"` 不是数字！这是它与真正的 JSON 库的本质差异（快糙猛换通用性）。适合配置文件读写、格式互转；**不适合 API 对接**（类型语义丢了）。⭐ 小工具配置的事实答案。

## 30.3 Boost.JSON（2021）：专而快的现代 JSON

```cpp
json::value v = json::parse(R"({"name":"ada",...})");
v.at("address").at("city").as_string();
json::value obj = {{"ok", true}, {"items", {1, 2, 3}}};   // initializer 直观构造
v.as_object()["extra"] = "added";                          // 就地改
json::parser p;  p.write(...);  p.release();               // SAX 流式
```

运行输出（`json.cpp`）：

```text
name = "ada"
age = 36
tags 数 = 2
city = "London"
构造 = {"ok":true,"items":[1,2,3]}
age 改后 = 37 extra = "added"
序列化 = {"name":"ada","age":37,"tags":["pioneer"...
字符串取 as_int64 被抓住
SAX 流式 = {"streamed":true}
自检通过
```

三大件：**DOM**（value/object/array，类型严格）、**SAX parser**（流式处理 GB 级文件不建树）、**serializer/存储策略**（monotonic 分配器零碎片）。C++ 没有标准 JSON，Boost.JSON 是"准标准"选择之一（nlohmann/json 是流行第三方，接口更甜但依赖重）。

> 实测坑：`json::parser` **喂半截就 `release()` 会抛 system_error**（incomplete）——未捕获直接 fail-fast（0xC0000409，连 stderr 都来不及写）。流式解析要保证最后一次 `write` 喂完整文本；parser 也没有 `finish()` 成员。

## 30.4 选型速查

```text
保存/恢复程序状态（对象图、版本演进） → Serialization
读写小配置文件（JSON/XML/INI 互转）   → PropertyTree
API 对接/高性能 JSON/大文件流式       → Boost.JSON
```

---


> 上一章：[29 · 进程与系统](29-process-system.md) ｜ 下一章：[31 · 运行时结构与散珠](31-runtime-structures.md) ｜ 返回：[README](../README.md)
