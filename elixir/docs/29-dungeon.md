# 29 · 领域建模实战：回合制地下城

> 对应示例：`examples/29_dungeon/`（独立 mix 工程，17 个源文件，含 ExUnit 测试、doctest 与 `run.exs` 驱动脚本）
>
> 取材自《函数式编程入门：使用 Elixir》第 6 章「设计 Elixir 应用程序」+ 附录 1「为游戏添加房间」——全书的压轴项目。玩家在满地怪物的地下城里醒来，穿过一个个房间（宝藏、陷阱、敌人、出口），谁先没血谁输。书里用交互式 CLI + `Enum.random`；本章做**纯函数化改造**：交互与随机被推到边界，引擎只吃数据、只吐事件流——第 28 章纪律的一次大阅兵。

## 29.1 从需求到模型：模块地图

游戏规则翻译成领域模型，每个概念落一个模块：

```text
Ex29Dungeon.Character          角色 struct：英雄与敌人共用（+ @type t）
Ex29Dungeon.Heroes / Enemies   数据即配置：三英雄、三怪物
Ex29Dungeon.Display            协议：多态渲染（defprotocol/defimpl）
Ex29Dungeon.Room.Action        动作 struct（forward / rest / search）
Ex29Dungeon.Room               房间：引用 struct 的 struct
Ex29Dungeon.Room.Trigger       行为：@callback run/2——触发器契约
Ex29Dungeon.Room.Triggers.*    六种触发器：出口/敌人/伏击/陷阱/宝藏/休息
Ex29Dungeon.Rooms              房间全集
Ex29Dungeon.Battle             纯函数战斗：伤害由注入的 roll 决定
Ex29Dungeon.Engine             爬塔引擎：房间序列 + 动作脚本 → 事件流
```

对比第 24 章收官：那边用 OTP（GenServer/Supervisor）装纯函数核心；
这边反过来——**纯函数引擎 + 数据化配置**，连「随机」都注入化。两章
合起来是同一条架构准则的两副面孔。

## 29.2 角色：defstruct 与 @type t

英雄与敌人**共用**一个 struct——struct 描述「角色是什么」，正邪之分
是数据的事：

```elixir
defmodule Ex29Dungeon.Character do
  defstruct name: nil,
            description: nil,
            hit_points: 0,
            max_hit_points: 0,
            attack_description: nil,
            damage_range: nil

  @type t :: %__MODULE__{
          name: String.t(),
          hit_points: non_neg_integer(),
          max_hit_points: non_neg_integer(),
          damage_range: Range.t(),
          ...
        }
```

三条纪律：

- 结构体**不允许在定义之外添加新属性**——角色在程序的任何角落保持
  一致的形状，拼错字段名是编译错误不是隐式 nil；
- `@type t` 给每个属性定类型，`@callback`、`@spec`、1.20 的渐进
  类型检查器都引用它（typespec 是行为契约的语言）；
- 受击/治疗都是**返回新 struct**，且带钳制——没有负血量、没有超血：

```elixir
def take_damage(character, damage),
  do: %{character | hit_points: max(0, character.hit_points - damage)}

def heal(character, healing_value),
  do: %{character | hit_points: min(character.hit_points + healing_value, character.max_hit_points)}
```

## 29.3 数据即配置：英雄与怪物全集

`Heroes`/`Enemies` 是 map + 固定顺序表——**加一个英雄不改任何逻辑**，
往 map 添一项、顺序表加一个键：

```text
-- 1. 英雄与怪物：struct 是形状，数据是血肉 --
  英雄 Knight (18/18) —— a sword，伤害 4..5
  英雄 Wizard (8/8) —— a fireball，伤害 6..10
  英雄 Rogue (12/12) —— a dagger，伤害 1..12
  怪物 Ogre (12/12) —— a hammer，伤害 3..5
  怪物 Orc (8/8) —— an axe，伤害 2..4
  怪物 Goblin (4/4) —— a dagger，伤害 1..2
```

注意 `all/0` 不用 `Map.values/1`（map 迭代顺序不保证，第 5 层验证的
逐字节一致会翻车）——顺序自己掌握在 `@order` 里。书里选怪用
`Enum.random`；这里换成按英雄最大生命值取模的**确定性挑选**
（`Enemies.pick/1`），随机性被赶出引擎（第 28 章）。

## 29.4 显示：自定义协议 → String.Chars

选项列表既要显示英雄又要显示动作——两种 struct、一个接口。先照书
写自定义协议：

```elixir
defprotocol Ex29Dungeon.Display do
  def info(value)
end

defimpl Ex29Dungeon.Display, for: Ex29Dungeon.Character do
  def info(character),
    do: "#{character.name} (#{character.hit_points}/#{character.max_hit_points})"
end
```

defimpl 挂在 struct 自己的文件里（书「组织协议」的规矩：**拥有
struct，实现放 struct 文件；拥有协议，实现放协议文件；都没有，单独
建文件**）。再加一层内建协议——`String.Chars` 让插值直接可用：

```elixir
defimpl String.Chars do
  def to_string(character), do: character.name
end
```

```text
-- 2. 协议 Display：多态渲染；String.Chars：插值即名字 --
  Display.info(hero)  => "Knight (18/18)"
  Display.info(action) => "Search the room."
  String.Chars 插值    => "Wizard casts!"
```

战报里 `"#{attacker.name} attacks with ..."` 走的就是 String.Chars。
自定义协议管「选项列表怎么渲染」，内建协议管「插值怎么显示」——
各司其职，扩展新类型不改任何调用方。

## 29.5 房间与动作：结构体引用结构体

`Room` 装着若干 `Action`，外加一个**触发器模块**（存的是模块名
原子）：

```elixir
defmodule Ex29Dungeon.Room do
  defstruct description: nil, actions: [], trigger: nil
  @type t :: %__MODULE__{description: String.t(), actions: [Action.t()], trigger: module()}
end
```

```text
-- 3. 行为 @callback：六种触发器都实现 run/2（漏了编译器就告警）--
  :exit => Triggers.Exit，动作 [:forward]
  :enemy => Triggers.Enemy，动作 [:forward]
  :hidden => Triggers.EnemyHidden，动作 [:forward, :rest]
  :trap => Triggers.Trap，动作 [:forward, :search]
  :treasure => Triggers.Treasure，动作 [:forward, :search]
  :rest => Triggers.Rest，动作 [:forward, :rest]
```

## 29.6 触发器：@behaviour 契约

每种房间的「进入后果」是一个独立模块，共同遵守一份契约：

```elixir
defmodule Ex29Dungeon.Room.Trigger do
  @callback run(Character.t(), Action.t()) ::
              {Character.t(), :exit | :forward, [String.t()]}
end
```

触发器模块用 `@behaviour` 认领契约、`@impl` 标注实现。**漏实现
`run/2`，编译器直接告警**——契约违约拦在编译期，这是 behaviour 相对
「口头约定」的全部价值。与书的差异：书里触发器用 `Shell.info` 直接
打印、返回二元组；这里返回**三元组（多一列事件流）**——打印这个
副作用变成了数据。

六种触发器（附录 1 的四个全在）都极短，陷阱房是完整一例：

```elixir
defmodule Ex29Dungeon.Room.Triggers.Trap do
  @behaviour Ex29Dungeon.Room.Trigger

  def run(character, %Ex29Dungeon.Room.Action{id: :forward}) do
    {character, :forward, ["You're walking cautiously and can see the next room."]}
  end

  def run(character, %Ex29Dungeon.Room.Action{id: :search}) do
    damage = 3
    messages = [..., "You are hit by an arrow, losing #{damage} hit points."]
    {Character.take_damage(character, damage), :forward, messages}
  end
end
```

**按动作分派**就是函数子句：搜房间的代价写在 `:search` 子句里，
别的触发器（伏击房对 `:rest`、宝藏房对 `:search`）同款形状。加一种
房间 = 加一个触发器模块 + Rooms 里一项，**引擎零改动**——这就是
行为带来的开闭结构。

## 29.7 战斗：纯函数化的 fight

书 6.4.3 的 `fight/2`：轮流互攻，一方倒下即停（死者不还手）。书里
伤害是 `Enum.random(range)`；这里把随机性**注入化**：

```elixir
def roll(i, range) do
  size = range.last - range.first + 1
  range.first + rem(i * 7 + 3, size)
end

def fight(char_a, char_b, roll \\ &__MODULE__.roll/2)
```

`roll/2` 以攻击序号为自变量——**同样的序列永远同样的战斗**，可
doctest、可逐字节复跑；测试想构造「一刀秒杀」的场景，注入
`fn _, _ -> 99 end` 即可。战报消息按名字分派（书 6.4.3 的
`%{name: "You"}` 子句——引擎把玩家角色统一改名 You，代入感来自
模式匹配）：

```text
-- 4. 战斗：伤害由 roll(攻击序号, 区间) 决定——同样的序列同样的战斗 --
  Wizard attacks with a fireball and deals 9 damage.
  Goblin receives 9. Current HP: 0.
  终局 => Wizard (8/8) vs Goblin (0/4)
```

## 29.8 引擎：把交互推到边界

书的 `crawl/2` 混着清屏、提问、随机选房；纯函数版长这样：

```elixir
def play(hero, room_keys, script, opts \\ []) do
  roll = Keyword.get(opts, :roll, &Battle.roll/2)
  hero = %{hero | name: "You"}
  crawl(hero, room_keys, script, welcome(hero), roll)
end

defp crawl(%{hit_points: 0} = hero, _rooms, _script, events, _roll),
  do: %{outcome: :lost, hero: hero, events: events ++ death_events()}

defp crawl(hero, [], _script, events, _roll),
  do: %{outcome: :out_of_rooms, hero: hero, events: events ++ [...]}

defp crawl(hero, [room_key | rest_rooms], script, events, roll) do
  room = Rooms.get(room_key)
  {action, script_rest} = pick_action(script, room)
  ...
  {hero, flag, trigger_events} = room.trigger.run(hero, action)
  case flag do
    :exit -> %{outcome: :won, ...}
    :forward -> crawl(hero, rest_rooms, script_rest, events, roll)
  end
end
```

三个入口三种子句——死、走完、进房。**房间序列与动作脚本都是数据**：
`play(wizard, [:trap, :enemy, :exit], [:search, :forward, :forward])`
就是一整局。同一个引擎，`run.exs` 拿它做演示、ExUnit 拿它做断言；
想接真正的 CLI，只在最外层把脚本换成读输入（第 28 章的依赖注入）。

三局经典对局（真实战报节选）：

```text
-- 5. 胜局：Wizard 走 [:trap, :enemy, :exit]，脚本 [:search, :forward, :forward] --
  ...
  You are hit by an arrow, losing 3 hit points.      # 陷阱 -3 → 5/8
  ...
  The enemy Goblin wants to fight.
  You were prepared and attack first.
  You attack with a fireball and deal 9 damage.      # 一发带走 4 血哥布林
  Goblin receives 9. Current HP: 0.
  ...
  You found the exit. You won the game. Congratulations!
  [结局] won，终局 5/8 HP，共 33 条事件
```

```text
-- 5. 败局：Knight 走 [:hidden, :enemy]，脚本 [:rest, :forward] --
  ...
  The enemy Ogre surprises you and attacks first.    # 伏击：怪先手
  Ogre attacks with a hammer and deals 3 damage.
  ...
  You attack with a sword and deal 5 damage.         # 第二个食人魔
  Ogre attacks with a hammer and deals 4 damage.
  You receive 4. Current HP: 0.
  Unfortunately your wounds are too many to keep walking.
  You fall onto the floor without strength to carry on.
  Game over!
```

```text
-- 5. 治疗局：Rogue 走 [:trap, :treasure, :exit]，脚本 [:search, :search, :forward] --
  You are hit by an arrow, losing 3 hit points.      # 12 → 9
  You drink the potion and restore 5 hit points.     # min(9+5, 12) = 12（钳到上限）
  ...
  [结局] won，终局 12/12 HP
```

三局覆盖了全部出口：`:won`、`:lost`、治疗钳制；败局里骑士共出手
五次、两次食人魔战报全靠同一个 `roll` 序列复现。

## 29.9 协议 vs 行为：一张表分清

书 6.4 的收尾对比，也是本章的题眼：

| | 协议（protocol） | 行为（behaviour） |
|---|---|---|
| 面向 | **数据**（struct） | **模块** |
| 声明 | `defprotocol` + 函数签名 | `@callback` |
| 实现 | `defimpl ... for:` | `@behaviour` + `@impl` |
| 分派 | 按值的类型运行时分派 | 调用方写 `mod.fun(...)` |
| 本章 | `Display.info/1`：角色与动作 | `Trigger.run/2`：六种触发器 |
| 违约 | 未实现的类型调用时崩 | 缺函数**编译期告警** |
| 亲戚 | Java/C# 接口（数据侧） | Java/C# 接口（类侧）、callback |

选型口诀：**同一操作要吃多种数据 → 协议；多种模块要长同一个模子
→ 行为**。第 10 章、第 15/16 章（GenServer/Supervisor 的
`@behaviour`）分别铺过这两条路，这里是合流。

## 29.10 要点小结

```text
  struct 定形状：不许场外加字段；受击/治疗返回新值并钳制
  数据即配置：英雄/怪物/房间全是 map + 固定顺序表，加内容零改逻辑
  map 迭代顺序不保证：要顺序就自己持顺序表（@order）
  自定义协议管多态渲染；String.Chars 让插值即名字；组织协议有归档规矩
  behaviour 是模块契约：漏实现编译期告警；@impl 标注实现
  触发器按动作 id 分派成函数子句；事件流代替打印（副作用变数据）
  战斗随机注入化：roll(i, range) 确定性掷骰，fight 可 doctest 可复跑
  引擎吃「房间序列 + 动作脚本」吐事件流；:won/:lost/:out_of_rooms 三出口
  协议管数据、行为管模块；本章与 24 章互为纯核心架构的两面
```

## 29.11 坑位清单

1. **`Battle.fight/2` 的返回按参数顺序**：`{A 终态, B 终态, 战报}`——
   解构反了英雄就会「变成」怪物终态（本项目实测踩过：败局战报显示
   0/4 血的"骑士"）。契约再清楚，也要在调用处当场核对一次。
2. **`function_exported?/3` 对未加载模块恒 false**：Room 里存的是
   模块名原子，真正调用前模块可能还没加载；批量校验契约先
   `Code.ensure_loaded!/1`，否则断言随机翻车（测试顺序相关）。
3. **`Map.values/1` 顺序不保证**：涉及输出顺序的「全集」必须自己持
   顺序键列表——第 5 层逐字节验证会逮住任何侥幸。
4. **多子句触发器要把通用 `:forward` 子句写全**：漏掉某个动作 id 的
   子句，运行时 FunctionClauseError（没有兜底子句是刻意设计：
   新动作必须逐房间显式表态，而不是静默吞掉）。
5. **`run.exs` 用 `--no-compile` 跑前先编译**：示例目录的默认 `_build`
   与 run-all.sh 的 `MIX_BUILD_ROOT` 是两套产物；手动看过时输出别当
   结论（本教程验证一律以 run-all.sh 五层为准）。
6. **defimpl 与 struct 的编译依赖**：`defimpl Display, for: Character`
   要求 Character 先编译——放在 struct 自己的文件里，编译器自己解
   依赖；拆开放反而要小心顺序。
7. **`@impl` 标注要写**：不带 `@impl` 的实现和普通函数没区别，契约
   改名时不会收到「回调缺失」告警——写上，让编译器替你盯契约。

---

教程正文到此结束。收官六段路线回顾：

- **24 章**：OTP 收官——监督树、Task 并发、let-it-crash；
- **25 章**：函数式思维——不可变、纯函数、声明式的世界观；
- **26 章**：闭包与组合——函数是值的全部含义；
- **27 章**：递归治理——减治、分治与无界的护栏；
- **28 章**：非纯函数驯化——五种策略与手写错误单子；
- **29 章**：领域建模——struct/协议/行为/typespec 合流成纯函数引擎。

两个导航性文件：

- 速查与坑位索引：[CHEATSheet](../CHEATSheet.md)
- 分章总览与运行方法：[README](../README.md)
