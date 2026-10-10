# 06 · 集合：数组与字典

> 对应示例：`examples/06_collections/`

## 6.1 示例全文

`examples/06_collections/main.gd`：

```gdscript
extends SceneTree

func _initialize():
    var inventory: Array[String] = ["苹果", "水晶"]
    inventory.append("火把")
    inventory.sort()
    print("背包：", inventory)
    print("第一件：", inventory[0], "，共 ", inventory.size(), " 件")
    print("是否拥有火把：", "火把" in inventory)

    var loot: Array[int] = [7, 3, 5]
    loot.shuffle()
    print("洗劫后的掉落顺序：", loot)

    var stats := {"hp": 100, "mana": 80, "level": 3}
    stats["hp"] -= 30
    print("HP = ", stats["hp"])
    print("防御 = ", stats.get("defense", 0))

    for key in stats:
        print(key, " = ", stats[key])

    for key in stats.keys():
        print("键：", key)
    print("所有值：", stats.values())

    stats.erase("mana")
    print("删掉 mana 后：", stats)
    quit()
```

实测输出（`shuffle` 每次运行顺序不同）：

```text
背包：["水晶", "火把", "苹果"]
第一件：水晶，共 3 件
是否拥有火把：true
洗劫后的掉落顺序：[5, 7, 3]
HP = 70
防御 = 0
hp = 70
mana = 80
level = 3
键：hp
键：mana
键：level
所有值：[70, 80, 3]
删掉 mana 后：{ "hp": 70, "level": 3 }
```

## 6.2 Array：类型化与排序

`var inventory: Array[String] = [...]` 是**类型化数组**：append 一个 `int` 会编译
报错（第 11 章的 `Array[Dictionary]` 同理）。不写注解的 `Array` 就是 `Array[Variant]`，
什么都能装——和 03 章的变量注解哲学一致：能锁就锁。

API 速查（示例用到的 + 高频未用到的）：

| 调用 | 语义 |
|---|---|
| `append(x)` / `push_back` / `push_front` | 尾插/头插 |
| `pop_back()` / `pop_front()` | 弹出；空数组上调用返回 `null`（4.7.1 实测不中断执行） |
| `insert(i, x)` / `remove_at(i)` | 指定位置插入/删除 |
| `size()` / `is_empty()` | 长度 / 判空 |
| `sort()` | **原地**排序；要"排序后的副本"只能 `duplicate()` 后再 `sort()`（**没有** `sorted()`，4.7.1 实测无此方法） |
| `shuffle()` | 原地洗牌 |
| `pick_random()` | 随机取一个（掉落、AI 决策高频） |
| `find(x)` / `has(x)` | 查找；`x in arr` 是 `has` 的运算符写法（示例的"是否拥有火把"） |

`背包` 一行暴露了字符串排序规则：按 **Unicode 码位**——`水(U+6C34) < 火(U+706B) < 苹(U+82F9)`，
所以中文"字典序"和直觉拼音序不同，展示给玩家前要么自定比较（`sort_custom(func(a, b): return a["name"] < b["name"])`），
要么在数据层解决。

## 6.3 Dictionary：游戏数据的事实标准

`stats := {"hp": 100, ...}` 用 `:=` 推断出 `Dictionary`（键值类型都可选注解：
`Dictionary[String, int]`）。三个姿势读值：

```gdscript
stats["hp"]              # 无键 → 运行时报 "Invalid get index" ——确定存在时用
stats.get("defense", 0)  # 无键 → 返回默认值 0 ——不确定存在时用（示例的"防御"行）
stats.has("hp")          # 先判断再读
```

写值 `stats["hp"] -= 30` 直接改（"HP = 70" 行）。删除用 `erase(key)`（无 `del`），
示例最后一行可见 mana 消失。输出 `{ "hp": 70, ... }` 的带空格引号形式就是
Dictionary 的 `str()` 外观——它会原样出现在你的 `print` 日志里，习惯就好。

**遍历**：`for key in stats` 迭代的是**键**（示例第 5–7 行）；`stats.keys()` /
`stats.values()` 返回两个独立数组（示例第 8–9 行）。注意：**没有 `items()`**——
`for entry in stats.items()` 直接编译错误（本项目实测）。要键值成对就
`for k in stats:` 里手动 `stats[k]`，或 `for k in stats.keys(): var v = stats[k]`。

**迭代中修改**：GDScript 对"遍历 Dictionary 时 erase/insert"给出的行为不保证安全
（其他迭代器语言的老坑）——要删就收集键、迭代结束后统一 `erase`。

## 6.4 引用语义：赋值不是复制

`Array` 与 `Dictionary` 都是**引用类型**：

```gdscript
var a := [1, 2, 3]
var b = a          # b 与 a 指向同一份数组
b.append(4)
print(a)           # 实测输出 [1, 2, 3, 4] ——a "被"改了
var c := a.duplicate()   # 想要副本：duplicate(true) 连嵌套内容一起复制
```

第 11 章的战斗系统里 `enemies` 数组、`player` 字典传给 `_strike()` 后修改 HP，
靠的正是这个引用语义；反过来，函数收到 Dictionary 随手一改就影响调用方——
改谁的数据，注释里写清楚。

## 6.5 坑位清单

1. **无 `items()`**：键值成对只能 `for k in dict` + `dict[k]`（6.3 实测编译错误）。
2. **`sort()` 原地改**，返回 `void`；`a = a.sort()` 会把 a 变成 `null`。没有
   `sorted()` 方法（4.7.1 实测编译错误），要"排好序的副本"写
   `var copy := a.duplicate(); copy.sort()`。
3. **`dict["无键"]` 运行时炸**，`get(key, 默认)` 才稳（6.3）；读玩家可缺省的数据
   （存档字段）一律 `get`。
4. **引用赋值共享底层数据**（6.4）：`var b = a` 后 `a.sort()`，b 同步变。
5. **中文排序按码位不按拼音**（6.2）：玩家可见列表自己定比较规则。
6. **Dictionary 的键是值语义**：`dict[Vector2(1,1)] = x` 合法；用对象做键则按
   实例身份——释放对象后键残留，谨慎。

上一章：[05 · 函数与 Callable](05-functions.md) ｜ 下一章：[07 · 节点与场景树](07-nodes.md) ｜ 返回：[README](../README.md)
