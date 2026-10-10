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
