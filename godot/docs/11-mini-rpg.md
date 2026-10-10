# 11 · 实战：回合制战斗系统

> 对应示例：`examples/11_mini_rpg/`

本章把前十章的知识——变量与格式化（03）、循环与 match（04）、函数（05）、
Dictionary/Array 与引用语义（06）、信号（08）——组装成一个有完整规则的小系统：
勇者连续对战两只怪物的回合制战斗，全程命令行输出战斗日志。

## 11.1 示例全文

`examples/11_mini_rpg/main.gd`：

```gdscript
extends SceneTree

signal hp_changed(who: String, hp: int)

func _initialize():
    hp_changed.connect(func(who: String, hp: int):
        print("  [%s] HP -> %d" % [who, hp]))

    var player := {"name": "勇者", "hp": 100, "atk": 12}
    var enemies: Array[Dictionary] = [
        {"name": "史莱姆", "hp": 40, "atk": 5},
        {"name": "哥布林", "hp": 55, "atk": 8},
    ]

    var turns := 0
    for enemy in enemies:
        print("—— 遭遇 %s（HP %d）——" % [enemy.name, enemy.hp])
        while player.hp > 0 and enemy.hp > 0:
            turns += 1
            _strike(player, enemy)
            if enemy.hp <= 0:
                break
            _strike(enemy, player)
        if player.hp <= 0:
            print("勇者倒下了……战斗在第 %d 回合结束" % turns)
            break
        print("击败 %s！勇者剩余 HP %d" % [enemy.name, player.hp])

    if player.hp > 0:
        print("战斗结束：勇者 HP = %d，共 %d 个攻击回合" % [player.hp, turns])
    quit()

func _strike(attacker: Dictionary, defender: Dictionary) -> void:
    defender.hp = maxi(defender.hp - attacker.atk, 0)
    hp_changed.emit(defender.name, defender.hp)
```

实测输出：

```text
—— 遭遇 史莱姆（HP 40）——
  [史莱姆] HP -> 28
  [勇者] HP -> 95
  [史莱姆] HP -> 16
  [勇者] HP -> 90
  [史莱姆] HP -> 4
  [勇者] HP -> 85
  [史莱姆] HP -> 0
击败 史莱姆！勇者剩余 HP 85
—— 遭遇 哥布林（HP 55）——
  [哥布林] HP -> 43
  [勇者] HP -> 77
  [哥布林] HP -> 31
  [勇者] HP -> 69
  [哥布林] HP -> 19
  [勇者] HP -> 61
  [哥布林] HP -> 7
  [勇者] HP -> 53
  [哥布林] HP -> 0
击败 哥布林！勇者剩余 HP 53
战斗结束：勇者 HP = 53，共 9 个攻击回合
```

## 11.2 设计决策逐条拆读

**数据用 Dictionary，不用类。** 一个角色就是 `{"name", "hp", "atk"}` 三条键值，
读取支持 `enemy.hp` 属性式语法（Dictionary 的便捷访问，与 `enemy["hp"]` 等价）。
原型阶段这是最快的路径；规模上去后再迁移到 `class_name Enemy extends RefCounted`
（12 章方向）——字段即属性，迁移成本几乎为零。

**伤害规则进函数，一处修改全局生效。** `_strike()` 只有两行：扣血下限钳制
（`maxi(..., 0)`，GDScript 4 专门给整数用的 `maxi`/`mini`，避免 `max` 的泛型开销）
和广播。血量、攻击力都在字典里改，但"一次攻击发生什么"只写了一次。

**信号当战斗日志总线。** `hp_changed(who, hp)` 带完整上下文——谁的血量、变成了
多少。战斗逻辑只管 `emit`，不关心日志格式、UI 刷新、成就统计……这些"旁观者"
各连各的。本章把订阅者写成 lambda 打印；真实项目里它会是 HUD 里的血条动画回调。
注意缩进的日志行由回调打印，**逻辑层没有任何 print 语句**——这就是关注点分离。

**循环骨架：外层遭遇、内层回合。** 结构是双 `while/for` 嵌套：

- `for enemy in enemies`：敌人队列逐个遭遇（引用语义保证 `_strike` 改的就是队列
  里这只怪，06 章 6.4 的知识）；
- `while player.hp > 0 and enemy.hp > 0`：双方都活着才继续回合；
- 两处 `break` 语义不同：内层"怪物先死就不用反咬"，外层"勇者倒下就不用打下一个"
  ——内层 break 退出回合循环、外层 break 退出遭遇循环，嵌套层次靠缩进一眼可辨。

**确定性数值。** 伤害取固定 `atk`，日志可原样复现（教程里每一行输出都是实测）。
要随机手感换 `randi_range`：GDScript 4 的全局随机**默认已播种**，无需 `randomize()`。

## 11.3 三组练手扩展（由易到难）

1. **暴击**：给字典加 `"crit": 0.2`，`_strike` 里
   `if randf() < attacker.crit: damage *= 2`，并用信号参数标记暴击（改签名
   `hp_changed(who, hp, is_crit)`，回调里加感叹号）——体会 08 章"改信号要全库
   搜回调"。
2. **道具回合**：玩家每 3 回合（`if turns % 3 == 0`）改用 `apply_potion` 式回血
   而非普攻——把回合循环从"双方互砍"扩展成"行动选择"。
3. **战斗节奏化**：在每次 `_strike` 之间插
   `await create_timer(0.4).timeout`（10 章），日志逐条"打出来"而不是瞬间刷完；
   顺手把 10.5 的"引用容器"模式用成战斗状态机（`state = {"phase": "player_turn"}`，
   等玩家输入信号、限时窗口）。

## 11.4 坑位清单

1. **`enemy.name` 是取键，不是取属性**：Dictionary 的便捷语法拼错键同样运行时
   炸——数据字段多时建议老实写 `enemy["name"]` 或迁移到类。
2. **`hp_changed` 声明在 `SceneTree` 脚本上**：真实项目信号属于节点（敌人/战斗
   管理器），发射点随数据主人走（08 章 8.6）。
3. **`while` 条件要写全**：漏了 `player.hp > 0`，团灭后还会继续互相砍 0 血——
   终止条件是循环的生命线。
4. **引用语义的远程修改**：`_strike(enemy, player)` 改 `player.hp` 合法且有意，
   但别在无关函数里顺手 `defender.hp = 0`——给改数据的函数起诚实的名字。

上一章：[10 · await 与计时器](10-await.md) ｜ 下一章：[12 · 进阶路线与总结](12-roadmap.md) ｜ 返回：[README](../README.md)
