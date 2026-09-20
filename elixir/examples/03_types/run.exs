# 第 03 章驱动脚本：cd examples/03_types && mix run run.exs

# BEAM 的 :standard_io 编码取自系统 locale；LANG/LC_ALL 未设时退回 latin1，
# 中文会被 IO.puts 打成 \x{7ED3}\x{675F} 这样的字面转义（08 章展开，
# CHEATSheet 有专条）。显式设成 utf8，脚本就与 locale 无关了。
:io.setopts(:standard_io, encoding: :utf8)

# 纪律：不打印时间戳、pid、reference、函数对象的 inspect（都含运行期编号）。
# pid/reference/function 一律只打印「类型标签」这类确定性结论 ——
# run-all.sh 第 5 层要求单调度器重跑后 stdout 逐字节一致。

alias Ex03Types

IO.puts("==== 03 基础类型与不可变性 ====")

IO.puts("\n-- 1. 数字：/ vs div vs rem --")
IO.puts("7 / 2            => #{inspect(7 / 2)}   （/ 永远返回浮点）")
IO.puts("4 / 2            => #{inspect(4 / 2)}     （整除也是浮点）")
IO.puts("div(7, 2)        => #{inspect(div(7, 2))}")
IO.puts("div(-7, 2)       => #{inspect(div(-7, 2))}    （向零截断，同 C；Python 的 // 是 -4）")
IO.puts("rem(-7, 2)       => #{inspect(rem(-7, 2))}    （符号跟随被除数）")
IO.puts("rem(7, -2)       => #{inspect(rem(7, -2))}")
IO.puts("2 ** 64          => #{inspect(2 ** 64)}  （整数底+非负指数 => 精确整数，并非浮点！）")
IO.puts("3.0 ** 40 (float) => #{inspect(trunc(3.0 ** 40))}  （混入浮点：低位被 52 位尾数吞掉）")
IO.puts("Integer.pow(3,40) => #{inspect(Integer.pow(3, 40))}  （精确整数，二者相差 33）")
IO.puts("2 ** -1          => #{inspect(2 ** -1)}  （负指数静默转浮点；Integer.pow 会抛 ArithmeticError）")

IO.puts("\n-- 2. 任意精度整数与进制字面量 --")
IO.puts("Integer.pow(2, 64)  => #{inspect(Ex03Types.pow2(64))}  （超过 u64 也不回绕）")

IO.puts(
  "Integer.pow(2, 128) == 2 * Integer.pow(2, 127) => #{inspect(Ex03Types.pow2(128) == 2 * Ex03Types.pow2(127))}"
)

IO.puts("0xFF             => #{inspect(0xFF)}   （十六进制）")
IO.puts("0o777            => #{inspect(0o777)}   （八进制）")
IO.puts("0b1010           => #{inspect(0b1010)}    （二进制）")
IO.puts("1_000_000        => #{inspect(1_000_000)}   （下划线只是可读性分隔符）")

IO.puts("\n-- 3. 浮点相等陷阱 --")
IO.puts("0.1 + 0.2               => #{inspect(0.1 + 0.2)}")
IO.puts("0.1 + 0.2 == 0.3        => #{inspect(0.1 + 0.2 == 0.3)}")

IO.puts(
  "nearly_equal(0.1+0.2, 0.3) => #{inspect(Ex03Types.nearly_equal(0.1 + 0.2, 0.3))}   （容差比较才是正解）"
)

IO.puts("\n-- 4. 原子：true/false/nil 都是原子，原子表只增不减 --")

IO.puts(
  "is_atom(:ok) / is_atom(true) / is_atom(nil) => #{inspect(is_atom(:ok))} / #{inspect(is_atom(true))} / #{inspect(is_atom(nil))}"
)

IO.puts(~s|:"hello world"（引号原子）      => #{inspect(:"hello world")}|)
IO.puts("to_string(:atom)                => #{inspect(to_string(:atom))}")

for s <- ["nil", "true", "Ex03Types", "no_such_atom_for_sure_9x7"] do
  IO.puts("atom_from(#{inspect(s)}) => #{inspect(Ex03Types.atom_from(s))}")
end

IO.puts("（atom_from 走 String.to_existing_atom/1：不存在的原子报错而不是新建；")
IO.puts("  拿 String.to_atom/1 处理外部输入 = 无上限造原子 = 内存泄漏 + DoS）")

IO.puts("\n-- 5. 真假值：只有 false 和 nil 是假 --")

for value <- [false, nil, true, 0, 0.0, "", [], [nil], :ok] do
  IO.puts(
    "truthy?(#{String.pad_trailing(inspect(value), 6)}) => #{inspect(Ex03Types.truthy?(value))}"
  )
end

IO.puts("nil || \"默认值\"  => #{inspect(nil || "默认值")}   （|| 返回操作数本身）")
IO.puts("0 || \"默认值\"    => #{inspect(0 || "默认值")}             （0 是真值！与 C/Python/JS 相反）")
IO.puts("\"a\" && \"b\"      => #{inspect("a" && "b")}")

IO.puts("\n-- 6. 字符串（UTF-8 二进制） vs charlist（码点列表）--")

IO.puts(
  "is_binary(\"abc\") / is_list(~c\"abc\") => #{inspect(is_binary("abc"))} / #{inspect(is_list(~c"abc"))}"
)

IO.puts(~s|~c"abc" == [97,98,99] => #{inspect(~c"abc" == [97, 98, 99])}   （charlist 的真身就是码点列表）|)

combined = "e\u0301"

IO.puts("单码点 \"\u00E9\"（U+00E9）——字节 / 码点 / 字素簇是三个不同单位：")
IO.puts("  byte_size(\"\u00E9\")     => #{inspect(byte_size("\u00E9"))}   （UTF-8 字节数）")
IO.puts("  codepoints(\"\u00E9\") 数 => #{inspect(length(String.codepoints("\u00E9")))}   （码点数）")
IO.puts("  String.length(\"\u00E9\") => #{inspect(String.length("\u00E9"))}   （字素簇数，不是码点！）")

IO.puts(
  "组合序列 e+U+0301（两个码点拼成一个字素簇）：字节=#{inspect(byte_size(combined))}，码点=#{inspect(length(String.codepoints(combined)))}，字素簇=#{inspect(String.length(combined))}"
)

IO.puts("  graphemes => #{inspect(String.graphemes(combined))}   （String.length 数字素簇，不是码点）")

IO.puts("\n-- 7. 元组：定长、按位 O(1)、不可变 --")
t = {:ok, 42, "extra"}
IO.puts("t                    => #{inspect(t)}")
IO.puts("tuple_size(t)        => #{inspect(tuple_size(t))}")
IO.puts("elem(t, 1)           => #{inspect(elem(t, 1))}   （按位取，O(1)）")
t2 = put_elem(t, 1, 99)
IO.puts("put_elem(t, 1, 99) 后：原 t => #{inspect(t)}（没变），新值 => #{inspect(t2)}")

IO.puts("\n-- 8. 列表：cons 单元链 --")
[h | rest] = [1, 2, 3]
IO.puts("[h | rest] = [1, 2, 3]  => h = #{inspect(h)}, rest = #{inspect(rest)}")
IO.puts("list_parts([])          => #{inspect(Ex03Types.list_parts([]))}   （空列表没有头尾）")
IO.puts("[1, 2] ++ [3]           => #{inspect([1, 2] ++ [3])}")
IO.puts("[1, 2, 1, 3] -- [1]     => #{inspect([1, 2, 1, 3] -- [1])}   （-- 只删每个元素的第一次出现）")

IO.puts(
  "keyword 语法糖：[name: \"x\"] == [{:name, \"x\"}] => #{inspect(Ex03Types.keyword_is_sugar())}"
)

IO.puts("\n-- 9. 不可变性：更新 = 返回新值 --")
original = %{count: 1}
{was, updated} = Ex03Types.bump(original, :count)
IO.puts("bump(%{count: 1}, :count) => 原值 #{inspect(was)} 与新值 #{inspect(updated)} 并存")

x = 1
x = x + 1
IO.puts("x = 1; x = x + 1 后 x => #{inspect(x)}   （这是重新绑定，不是修改；旧值 1 从未被改）")

s = "abc"
s2 = s <> "d"
IO.puts("s = \"abc\"; s <> \"d\" => #{inspect(s2)}，而 s 仍是 #{inspect(s)}")

IO.puts("\n-- 10. 类型判定全家桶 --")

samples = [
  {"nil", nil},
  {"true", true},
  {":ok", :ok},
  {"42", 42},
  {"3.14", 3.14},
  {"\"bin\"", "bin"},
  {"<<1::1>>", <<1::1>>},
  {"~c\"abc\"", ~c"abc"},
  {"[1, 2]", [1, 2]},
  {"{1, 2}", {1, 2}},
  {"%{a: 1}", %{a: 1}},
  {"%Point{}", %Ex03Types.Point{}},
  {"fn -> :ok end", fn -> :ok end},
  {"self()", self()},
  {"make_ref()", make_ref()}
]

for {label, value} <- samples do
  IO.puts("type_of(#{String.pad_trailing(label, 14)}) => #{inspect(Ex03Types.type_of(value))}")
end

IO.puts(
  "number?(42)/number?(3.14) => #{inspect(Ex03Types.number?(42))} / #{inspect(Ex03Types.number?(3.14))}"
)

IO.puts(
  "is_bitstring(\"bin\")       => #{inspect(is_bitstring("bin"))}   （binary 是 bit_size 为 8 倍数的 bitstring）"
)

IO.puts(
  "is_struct(%Point{})       => #{inspect(is_struct(%Ex03Types.Point{}))}   （struct 也是 map：#{inspect(is_map(%Ex03Types.Point{}))}）"
)

IO.puts("is_exception(%ArgumentError{}) => #{inspect(is_exception(%ArgumentError{}))}")

IO.puts(
  "is_exception({:error, :oops}) => #{inspect(is_exception({:error, :oops}))}   （error 元组不是异常）"
)

IO.puts("\n-- 11. term 全序：混合类型排序不崩 --")

terms = [42, 3.14, :ok, make_ref(), fn -> :ok end, self(), {1}, %{a: 1}, [1], "bin"]
IO.puts("对 [整数, 浮点, 原子, ref, 函数, pid, 元组, map, 列表, 二进制] 做 Enum.sort/1")
IO.puts("排序后的类型标签 => #{inspect(Ex03Types.sort_labels(terms))}")
IO.puts("number 内部按值排（3.14 < 42，故 float 在 integer 前）；大类全序：")
IO.puts("number < atom < reference < function < port < pid < tuple < map < list < binary")

IO.puts(
  "Enum.sort([:zebra, :apple]) => #{inspect(Enum.sort([:zebra, :apple]))}   （OTP26 起原子按文本字节序）"
)

IO.puts("\n==== 03 结束 ====")
