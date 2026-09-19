// 04_control 的 swift-testing 测试
import Testing

@testable import Ch04Control

@Test func 骰子命名() {
    #expect(diceName(1) == "一点")
    #expect(diceName(6) == "六点")
    #expect(diceName(7) == "不是骰子")
}

@Test func 象限判定() {
    #expect(quadrant(x: 0, y: 0) == "原点")
    #expect(quadrant(x: 3, y: 0) == "x 轴")
    #expect(quadrant(x: 0, y: -2) == "y 轴")
    #expect(quadrant(x: 1, y: 1) == "第一象限")
    #expect(quadrant(x: -1, y: 2) == "第二象限")
    #expect(quadrant(x: -3, y: -4) == "第三象限")
    #expect(quadrant(x: 5, y: -1) == "第四象限")
}

@Test func 分数等级() {
    #expect(scoreLevel(59) == "不及格")
    #expect(scoreLevel(60) == "及格")
    #expect(scoreLevel(79) == "及格")
    #expect(scoreLevel(80) == "良好")
    #expect(scoreLevel(90) == "优秀")
    #expect(scoreLevel(100) == "优秀")
}

@Test func guard提前退出() {
    #expect(describeTraffic(light: nil) == "没有信号")
    #expect(describeTraffic(light: "") == "没有信号")
    #expect(describeTraffic(light: "红") == "信号灯是红")
}

@Test func fizzBuzz元组模式() {
    #expect(fizzBuzz(1) == "1")
    #expect(fizzBuzz(3) == "Fizz")
    #expect(fizzBuzz(5) == "Buzz")
    #expect(fizzBuzz(15) == "FizzBuzz")
    #expect(fizzBuzz(7) == "7")
}
