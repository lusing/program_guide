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
