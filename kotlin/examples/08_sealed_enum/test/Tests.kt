// 08 的测试：枚举行为、穷尽 when、表达式求值、状态机
import kotlin.test.assertEquals

fun testPlanet() {
    assertEquals(9.81, Planet.EARTH.gravity)
    assertEquals(60.0 * 3.71, Planet.MARS.weightOn(60.0), 1e-9)
    assertEquals(4, Planet.entries.size)
}

fun testOps() {
    assertEquals(9, Ops.ADD.apply(6, 3))
    assertEquals(3, Ops.SUB.apply(6, 3))
    assertEquals(18, Ops.MUL.apply(6, 3))
}

fun testEval() {
    assertEquals(1.0, eval(Expr.Num(1.0)))
    assertEquals(0.0, eval(Expr.Zero))
    assertEquals(4.0, eval(Expr.Add(Expr.Num(1.0), Expr.Num(3.0))))
    assertEquals(-6.0, eval(Expr.Neg(Expr.Mul(Expr.Num(2.0), Expr.Num(3.0)))))
    // 1 + 2×(-3.5) = -6
    assertEquals(-6.0, eval(Expr.Add(Expr.Num(1.0), Expr.Mul(Expr.Num(2.0), Expr.Neg(Expr.Num(3.5))))))
}

fun testRender() {
    assertEquals("1.0", render(Expr.Num(1.0)))
    assertEquals("(1.0 + 3.0)", render(Expr.Add(Expr.Num(1.0), Expr.Num(3.0))))
    assertEquals("(-2.0)", render(Expr.Neg(Expr.Num(2.0))))
    assertEquals("0", render(Expr.Zero))
}

fun testOrderState() {
    assertEquals("等待支付", nextAction(OrderState.Created))
    assertEquals("已收款 199，安排发货", nextAction(OrderState.Paid(199)))
    assertEquals("运输中（SF123456），等签收", nextAction(OrderState.Shipped("SF123456")))
    assertEquals("订单完成，可归档", nextAction(OrderState.Done))
}

fun main() {
    testPlanet()
    testOps()
    testEval()
    testRender()
    testOrderState()
    println("08_sealed_enum 全部测试通过")
}
