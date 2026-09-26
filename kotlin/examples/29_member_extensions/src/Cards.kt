// 29 · 纸牌模型：枚举 + infix + data class（Main.kt 用 import 静态导入枚举常量）

enum class Rank(val label: String) { ACE("A"), KING("K"), QUEEN("Q"), JACK("J"), TEN("10") }

enum class Suit(val symbol: String) { SPADES("♠"), HEARTS("♥"), DIAMONDS("♦"), CLUBS("♣") }

data class Card(val rank: Rank, val suit: Suit) {
    override fun toString(): String = "${rank.label}${suit.symbol}"
}

/** 中缀造牌：KING of HEARTS —— 编译期杜绝不存在的牌 */
infix fun Rank.of(suit: Suit): Card = Card(this, suit)
