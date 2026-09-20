defmodule Ex02HelloTest do
  use ExUnit.Case, async: true

  doctest Ex02Hello

  test "hello/0 返回固定问候语" do
    assert Ex02Hello.hello() == "Hello, Elixir!"
  end

  test "greet/1 与 greet/2 是两个不同的函数（arity 属于函数名）" do
    assert Ex02Hello.greet("世界") == "你好，世界！"
    assert Ex02Hello.greet("Hi", "world") == "Hi，world！"
    assert function_exported?(Ex02Hello, :greet, 1)
    assert function_exported?(Ex02Hello, :greet, 2)
  end

  test "parse_age/1 走 {:ok, _} / {:error, _} 约定" do
    assert Ex02Hello.parse_age("  42 ") == {:ok, 42}
    assert Ex02Hello.parse_age("0") == {:ok, 0}
    assert Ex02Hello.parse_age("-1") == {:error, :invalid_age}
    assert Ex02Hello.parse_age("12abc") == {:error, :invalid_age}
    assert Ex02Hello.parse_age("") == {:error, :invalid_age}
  end

  test "render/1：元组不能插值，但永远能 inspect" do
    assert Ex02Hello.render({1, 2}) == {"(不可插值)", "{1, 2}"}
    assert Ex02Hello.render(%{a: 1}) == {"(不可插值)", "%{a: 1}"}
    assert Ex02Hello.render(:ok) == {"ok", ":ok"}
    assert Ex02Hello.render(nil) == {"", "nil"}
  end

  test "render/1：列表插值按 charlist 解释，这是 Elixir 字符串的另一半真相" do
    # 'hi' 是码点列表 [104, 105]，to_string 把它当 charlist 还原成 "hi"
    assert Ex02Hello.render(~c"hi") == {"hi", "~c\"hi\""}

    # 而 [1, 2, 3] 不是可打印文本，插值会得到控制字符 —— 所以教程纪律是
    # 「打印结构一律用 inspect」
    {interpolated, inspected} = Ex02Hello.render([1, 2, 3])
    assert inspected == "[1, 2, 3]"
    assert byte_size(interpolated) == 3
  end

  test "私有函数外部调不到，但模块内部可用" do
    assert Ex02Hello.doubled(21) == 42
    refute function_exported?(Ex02Hello, :internal_only, 1)
  end
end
