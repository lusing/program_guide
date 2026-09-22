# 23 Fiddle C 互操作：dlopen、函数签名、指针、字符串、结构体、qsort 回调、FFI 纪律
# 运行：ruby main.rb
# frozen_string_literal: true

require "fiddle"
require "fiddle/import"

def sec(title)
  puts("\n---- #{title} ----")
end

def ok(cond, msg = "断言失败")
  raise(msg) unless cond
end

# 坑：别硬编码系统库路径（各平台差异巨大）。Fiddle.dlopen(nil) 拿「当前进程」句柄 ——
# macOS 的 libSystem（含 libc/libm 常用函数）早已随进程加载，sqrt/pow/strlen/qsort 全能解析。
LIBC = Fiddle.dlopen(nil)

# ═══ 23.1 dlopen + Function：最小调用 sqrt
sec("23.1 最小调用：sqrt")
# Fiddle::Function(函数指针, 参数类型表, 返回类型) —— 签名必须与 C 原型一字不差
sqrt = Fiddle::Function.new(LIBC["sqrt"], [Fiddle::TYPE_DOUBLE], Fiddle::TYPE_DOUBLE)
r2 = sqrt.call(2.0)
ok (r2 - 1.4142135623730951).abs < 1e-15, "sqrt(2.0) 应约等于 1.41421..."
ok (sqrt.call(4.0) - 2.0).abs < 1e-15
puts "sqrt(2.0) = #{r2}（确定性小数，Fiddle::TYPE_DOUBLE 签名）"

# ═══ 23.2 参数与返回类型映射：TYPE_INT / TYPE_DOUBLE / TYPE_VOIDP
sec("23.2 类型映射：INT / DOUBLE / VOIDP")
c_abs = Fiddle::Function.new(LIBC["abs"], [Fiddle::TYPE_INT], Fiddle::TYPE_INT)
c_pow = Fiddle::Function.new(LIBC["pow"], [Fiddle::TYPE_DOUBLE, Fiddle::TYPE_DOUBLE], Fiddle::TYPE_DOUBLE)
ok c_abs.call(-42) == 42              # 整数进出：TYPE_INT
ok c_pow.call(2, 10) == 1024.0        # 整数字面量自动转 double（可表示范围内安全）
ok c_pow.call(2.0, 10.0) == 1024.0
puts "abs(-42) = #{c_abs.call(-42)}；pow(2,10) = #{c_pow.call(2, 10)} —— Ruby 值按签名表自动转换"

# ═══ 23.3 malloc / free 与 Fiddle::Pointer
sec("23.3 malloc/free 与 Pointer")
# Fiddle::Pointer.malloc：Ruby 侧分配并托管（GC 时自动 free），比裸调 libc malloc 省心
buf = Fiddle::Pointer.malloc(16)
ok buf.size == 16
buf[0, 5] = "hello"                   # 按字节写入 C 内存
ok buf[0, 5] == "hello"               # 读回指定长度
ok buf[0, 1] == "h"
buf[0, 5] = "HELLO"
ok buf[0, 5] == "HELLO"
addr = buf.to_i                       # 地址本身是个整数（可传给需要指针的 C 函数）
ok addr > 0
puts "分配 16 字节、写入读回 hello/HELLO；地址只做断言（addr > 0 = #{addr > 0}），不打印裸地址"

# ═══ 23.4 字符串传递：C 字符串与 Ruby String
sec("23.4 字符串传递")
c_strlen = Fiddle::Function.new(LIBC["strlen"], [Fiddle::TYPE_VOIDP], Fiddle::TYPE_SIZE_T)
# TYPE_VOIDP 参数可直接吃 Ruby String（自动转成 C 字符串指针）
ok c_strlen.call("hello") == 5
ok c_strlen.call("你好") == 6          # UTF-8 下「你好」= 2 字符 × 3 字节
ok c_strlen.call("你好") == "你好".bytesize, "strlen 应等于 bytesize（C 看字节，Ruby 看字符）"
ok "你好".length == 2
sp = Fiddle::Pointer["指针也能包字符串"]   # Fiddle::Pointer[str]：包装已有字符串
# 坑：to_s 从 C 内存读回，编码是 ASCII-8BIT —— C 世界只有字节，没有「编码」概念
ok sp.to_s.bytesize == "指针也能包字符串".bytesize
ok sp.to_s.force_encoding(Encoding::UTF_8) == "指针也能包字符串"
ok sp.size == "指针也能包字符串".bytesize
puts "strlen(\"你好\") = 6 == bytesize（length 是 2）—— C 世界没有字符，只有字节"

# ═══ 23.5 结构体：Fiddle::Importer#struct
sec("23.5 结构体：Importer#struct")
# Importer 把一组 C 声明挂到一个模块上；struct 的返回值就是结构体类
# 坑：在 Module.new 块里写 `Point = struct(...)` 会撞外层常量名（already initialized 告警），
# 所以用 const_set 把结构体类挂到命名空间下
Geom = Module.new do
  extend Fiddle::Importer
  dlload nil                          # 同样用当前进程，不写死路径
  const_set(:Point, struct("point { double x; double y; }"))
end
p1 = Geom::Point.malloc              # malloc 出实例（GC 托管）
p1.x = 3.5
p1.y = -2.0
ok p1.x == 3.5 && p1.y == -2.0
ok Geom::Point.size == 16            # 2 × double = 16 字节
p2 = Geom::Point.malloc
p2.x = 1.0
p2.y = 2.0
ok p1.x != p2.x                       # 两个实例内存独立
puts "自定义 struct point{x,y}：p1 = (#{p1.x}, #{p1.y})，sizeof = #{Geom::Point.size} 字节"

# ═══ 23.6 回调：Fiddle::Closure + libc qsort
sec("23.6 回调：Closure 包 qsort")
# C 函数指针要求「可调用的 C 地址」—— Ruby 块不行，要包成 Fiddle::Closure（生成 C 兼容回调）
Compare = Class.new(Fiddle::Closure) do
  def call(a, b)                       # a、b 是指向两个 int 的指针
    Fiddle::Pointer.new(a)[0, 4].unpack1("l<") <=> Fiddle::Pointer.new(b)[0, 4].unpack1("l<")
  end
end
cmp = Compare.new(Fiddle::TYPE_INT, [Fiddle::TYPE_VOIDP, Fiddle::TYPE_VOIDP])
c_qsort = Fiddle::Function.new(LIBC["qsort"],
  [Fiddle::TYPE_VOIDP, Fiddle::TYPE_SIZE_T, Fiddle::TYPE_SIZE_T, Fiddle::TYPE_VOIDP],
  Fiddle::TYPE_VOID)
arr = [5, 1, 4, 2, 3]
raw = arr.pack("l<*")                  # int 数组 → 二进制
mem = Fiddle::Pointer.malloc(raw.bytesize)
mem[0, raw.bytesize] = raw
c_qsort.call(mem, arr.size, 4, cmp)    # C 侧原地排序，回调回到 Ruby 比较
sorted = mem.to_s(arr.size * 4).unpack("l<*")
ok sorted == [1, 2, 3, 4, 5], "qsort + Closure 应排好序"
puts "qsort 原地排 Ruby 传入的 int 数组，结果 = #{sorted.inspect}（回调在 Ruby 里比较）"
# 简单回调也可用 BlockCaller（块一包了事，语义同 Closure）
double_cb = Fiddle::Closure::BlockCaller.new(Fiddle::TYPE_INT, [Fiddle::TYPE_INT]) { |x| x * 2 }
ok double_cb.call(21) == 42
puts "BlockCaller 版回调：double_cb(21) = #{double_cb.call(21)}"

# ═══ 23.7 FFI 的边界：签名错误即段错误
sec("23.7 FFI 的边界纪律")
# 纪律（纯注释，演示只打印安全结论）：
# * FFI 没有护栏 —— 把 double 签名传成 int、少传一个参数、给 strlen 传空指针，
#   编译器不会救你，运行时直接 SIGSEGV 拖死整个 Ruby 进程（Ruby 异常救援不了段错误）。
# * 所以每次绑定前：查 C 原型（man sqrt）、数清参数个数与类型、确认返回类型；
#   签名表就是唯一契约。
# * 指针安全性：Pointer.malloc 的内存由 GC 托管；裸 to_i 地址要在使用期间保证原对象存活。
# 本示例全程只用「签名正确的调用」，所以输出确定、进程平安：
ok (sqrt.call(9.0) - 3.0).abs < 1e-15
ok c_abs.call(-7) == 7
puts "本节所有调用签名正确 —— 进程无段错误、输出确定；签名纪律：查原型、数参数、对类型"

puts
puts("==== 23 结束 ====")
