// 20 · 数据交换：std.json 与手写 CSV
// 2.113 的 std.json 还是"旧 API"（parseJSON/toJSON/JSONValue）——新版重写尚未落地（坑）
import std.stdio, std.json, std.algorithm, std.array, std.conv, std.string,
       std.exception : assertThrown;
import std.range : enumerate;

// ── 解析：parseJSON → JSONValue ─────────────────────────────
void parseDemo() {
    auto txt = `
    {
        "name": "D 语言",
        "year": 2001,
        "stable": true,
        "designers": ["Walter", "Andrei"],
        "grades": { "phobos": 9, "dub": 8 },
        "realExample": null
    }`;

    JSONValue jv = parseJSON(txt);

    // 类型判别：.type 是 JSONType 枚举（switch 的好搭档）
    writeln(jv.type);                                   // object

    // 字段访问：jv["k"] 拿 JSONValue，再按类型取值
    writeln("名字：", jv["name"].str);                   // string → .str
    writeln("年份：", jv["year"].integer);               // 整数 → .integer (long)
    writeln("稳定：", jv["stable"].boolean);             // bool  → .boolean
    // 数字也可能是浮点：.floating；统一取值用 .get!T
    writeln("phobos 分：", jv["grades"]["phobos"].get!int);

    // null 判别
    writeln("null 字段？", jv["realExample"].type == JSONType.null_);

    // 数组遍历
    foreach (i, designer; jv["designers"].array.enumerate)
        writeln("  设计者[", i, "]：", designer.str);

    // 对象遍历（键值对）
    foreach (key, val; jv["grades"].object)
        writeln("  ", key, " → ", val.integer);

    // 不存在的键：直接 ["missing"] 会抛 JSONException——先判存在（in 返回的是指针！）
    writeln("有 grades 键？", ("grades" in jv.object) !is null);
}

// ── 构造与序列化 ────────────────────────────────────────────
string buildDemo() {
    JSONValue root = JSONValue.emptyObject;

    root["name"] = "D 语言";                    // opAssign 直接接原生值（自动包 JSONValue）
    root["year"] = JSONValue(2001L);
    root["stable"] = JSONValue(true);

    JSONValue langs;                            // 数组：先装好再挂（默认 JSONValue 不是数组，~ 会抛）
    langs.array = [JSONValue("D"), JSONValue("Go"), JSONValue("Zig")];
    root["langs"] = langs;

    JSONValue scores = JSONValue.emptyObject;   // 空对象要显式初始化
    scores["phobos"] = JSONValue(9);
    scores["dub"] = JSONValue(8);
    root["scores"] = scores;

    // toJSON：紧凑 / pretty（pretty 是布尔参数，不在 JSONOptions 里——2.113 的怪）
    writeln("--- 紧凑 ---");
    writeln(toJSON(root));
    writeln("--- pretty ---");
    return toJSON(root, true);
}

// ── 实战：从 JSON 文本提取配置（带类型兜底）───────────────────
struct DbConfig {
    string host;
    int port;
    string[] replicas;
}

DbConfig loadConfig(string json) {
    auto jv = parseJSON(json);
    DbConfig cfg;
    cfg.host = "host" in jv.object ? jv["host"].str : "localhost";
    cfg.port = "port" in jv.object ? jv["port"].get!int : 5432;
    cfg.replicas = ("replicas" in jv.object)
        ? jv["replicas"].array.map!(r => r.str).array
        : [];
    return cfg;
}

// ── 附赠：CSV 手写（std.csv 在 2.113 仍可用，但 API 相对绕）──
string[][] parseCsv(string text) {
    return text.splitLines.map!(line => line.split(",").array).array;
}

string toCsv(string[][] rows) {
    return rows.map!(r => r.join(",")).join("\n");
}

void main() {
    parseDemo();
    writeln(buildDemo());

    auto cfg = loadConfig(`{"host": "db.example.com", "port": 6543, "replicas": ["r1", "r2"]}`);
    writefln("配置：%s:%s，副本 %s 个", cfg.host, cfg.port, cfg.replicas.length);
    auto fallback = loadConfig(`{}`);
    writefln("兜底：%s:%s", fallback.host, fallback.port);

    // CSV
    auto table = parseCsv("D,2001\nGo,2009\nZig,2016");
    writeln(table);
    writeln(toCsv(table) == "D,2001\nGo,2009\nZig,2016" ? "CSV 往返一致" : "CSV 错了");
}

unittest {
    auto jv = parseJSON(`{"a": [1, 2], "b": {"c": 3}, "d": 1.5, "e": true}`);
    assert(jv.type == JSONType.object);
    assert(jv["a"].array.length == 2);
    assert(jv["a"].array[1].integer == 2);
    assert(jv["b"]["c"].integer == 3);
    assert(jv["d"].type == JSONType.float_);
    assert(jv["e"].boolean);
    assertThrown!JSONException(parseJSON(`{不是 json`));

    // 边界：超出 long 的整数字面量直接抛 ConvOverflowException（不会降级成浮点）
    import std.conv : ConvOverflowException;
    assertThrown!ConvOverflowException(parseJSON(`92233720368547758079`));

    JSONValue obj = JSONValue.emptyObject;
    obj["k"] = JSONValue(42);
    assert(toJSON(obj) == `{"k":42}`);
    assert(parseJSON(toJSON(obj))["k"].integer == 42);

    // loadConfig 全路径
    auto c = loadConfig(`{"port": 80}`);
    assert(c.host == "localhost" && c.port == 80 && c.replicas == []);
    assert(parseCsv("a,b\nc,d") == [["a", "b"], ["c", "d"]]);
}
