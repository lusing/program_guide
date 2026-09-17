# 20 · 数据交换：JSON 与 CSV

> 对应示例：`examples/20_json/`

## 20.1 2.113 的 std.json 现状

**老 API（parseJSON/toJSON/JSONValue）仍是当前版本**——社区重写的新 API（parseJSONValue 等）还没进发布版。网上两套教程并存，认准本机实测的这套。

## 20.2 解析：parseJSON

```d
import std.json;

JSONValue jv = parseJSON(`{"name": "D 语言", "year": 2001, "ok": true,
                          "tags": ["系统", "GC"], "inner": {"k": 1}}`);

jv["name"].str;                 // string → .str
jv["year"].integer;             // 整数 → .integer（long）
jv["ok"].boolean;               // bool → .boolean
jv["inner"]["k"].get!int;       // 统一取值（按目标类型转）

jv.type == JSONType.object;     // 类型判别（switch 好搭档）
jv["tags"].array;               // 数组 → JSONValue[]
jv["inner"].object;             // 对象 → JSONValue[string]（就是 AA）
```

JSONType 成员：`null_ string integer uinteger float_ array object true_ false_`。

**访问不存在的键抛 JSONException**——先 `"k" in jv.object`（注意 `in` 返回**指针**，打印要 `!is null`）。

## 20.3 构造与序列化

```d
JSONValue root = JSONValue.emptyObject;      // 空对象要显式初始化！
root["name"] = "D 语言";                     // 原生值直接赋（自动包）
root["year"] = JSONValue(2001L);             // 显式包也行

JSONValue langs;                             // 数组：先装好再挂
langs.array = [JSONValue("D"), JSONValue("Go")];
root["langs"] = langs;

toJSON(root);                                // 紧凑
toJSON(root, true);                          // pretty 是第二个布尔参数（不在 JSONOptions 里！）
```

## 20.4 实战：带兜底的配置读取

```d
DbConfig loadConfig(string json) {
    auto jv = parseJSON(json);
    DbConfig cfg;
    cfg.host = "host" in jv.object ? jv["host"].str : "localhost";
    cfg.port = "port" in jv.object ? jv["port"].get!int : 5432;
    cfg.replicas = ("replicas" in jv.object)
        ? jv["replicas"].array.map!(r => r.str).array : [];
    return cfg;
}
```

模式：**in 判存在 + 类型断言取值 + 缺省兜底**——配置解析三件套。

## 20.5 CSV：手写二十行就够

std.csv 存在但 API 偏绕；规则数据用 std.string 手写更透明：

```d
string[][] parseCsv(string text) {
    return text.splitLines.map!(l => l.split(",").array).array;
}
string toCsv(string[][] rows) {
    return rows.map!(r => r.join(",")).join("\n");
}
```

（字段带引号/逗号的完整 CSV 再上 std.csv。）

## 20.6 坑位清单

1. **`toJSON` 的 pretty 是布尔参数**：`toJSON(root, true)`——`JSONOptions.prettyPrint` 不存在（枚举里只有 escapeNonAsciiChars 等六个选项）。
2. **默认构造的 JSONValue 不是数组**：`JSONValue v; v ~= x;` 运行时抛 "JSONValue is not an array"——先 `v.array = [...]`。
3. **`"k" in jv.object` 返回指针**：直接 writeln 打出指针值——判存在用 `("k" in obj) !is null`。
4. **超 long 的整数字面量抛 ConvOverflowException**（不会降级 float）：`parseJSON("92233720368547758079")` 直接炸。
5. `jv["missing"]` 读**和**写路径都可能抛 JSONException（读必抛；写要先存在或 root 是 emptyObject）。
6. 序列化中文默认不转义（直接 UTF-8 输出）——需要 `\uXXXX` 传 `JSONOptions.escapeNonAsciiChars`。

---
