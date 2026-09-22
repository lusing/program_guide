# 23 测试层：minitest 套件（自包含，不 require main.rb —— 避免把演示输出打进测试结果）
# frozen_string_literal: true
require "minitest/autorun"
require "fiddle"
require "fiddle/import"

# 句柄两分支：macOS/Linux 用当前进程句柄（libSystem/libc 已随进程加载）；
# Windows 进程句柄只搜 exe 导出表，C 运行时在 ucrtbase.dll（见 main.rb 23.1 的坑位注释）
LIBC = Fiddle.dlopen(Gem.win_platform? ? "ucrtbase" : nil)

class TestFiddle < Minitest::Test
  def test_sqrt_function
    sqrt = Fiddle::Function.new(LIBC["sqrt"], [Fiddle::TYPE_DOUBLE], Fiddle::TYPE_DOUBLE)
    assert_in_delta 1.4142135623730951, sqrt.call(2.0), 1e-15
    assert_in_delta 2.0, sqrt.call(4.0), 1e-15
  end

  def test_int_and_double_type_mapping
    c_abs = Fiddle::Function.new(LIBC["abs"], [Fiddle::TYPE_INT], Fiddle::TYPE_INT)
    c_pow = Fiddle::Function.new(LIBC["pow"],
                                 [Fiddle::TYPE_DOUBLE, Fiddle::TYPE_DOUBLE], Fiddle::TYPE_DOUBLE)
    assert_equal 42, c_abs.call(-42)
    assert_in_delta 1024.0, c_pow.call(2, 10), 1e-12
    assert_in_delta 1024.0, c_pow.call(2.0, 10.0), 1e-12
  end

  def test_pointer_malloc_write_read
    buf = Fiddle::Pointer.malloc(16)
    assert_equal 16, buf.size
    buf[0, 5] = "hello"
    assert_equal "hello", buf[0, 5]
    assert_equal "h", buf[0, 1]
    buf[0, 5] = "HELLO"
    assert_equal "HELLO", buf[0, 5]
    assert buf.to_i > 0
  end

  def test_strlen_matches_bytesize
    c_strlen = Fiddle::Function.new(LIBC["strlen"], [Fiddle::TYPE_VOIDP], Fiddle::TYPE_SIZE_T)
    assert_equal 5, c_strlen.call("hello")
    assert_equal 6, c_strlen.call("你好")
    assert_equal "你好".bytesize, c_strlen.call("你好")
    assert_equal 2, "你好".length
  end

  def test_pointer_to_s_binary_encoding
    sp = Fiddle::Pointer["指针也能包字符串"]
    assert_equal "指针也能包字符串".bytesize, sp.to_s.bytesize
    assert_equal Encoding::BINARY, sp.to_s.encoding
    assert_equal "指针也能包字符串", sp.to_s.force_encoding(Encoding::UTF_8)
  end

  def test_importer_struct_point
    geom = Module.new do
      extend Fiddle::Importer
      dlload nil
      const_set(:Point, struct("point { double x; double y; }"))
    end
    p1 = geom::Point.malloc
    p1.x = 3.5
    p1.y = -2.0
    assert_in_delta 3.5, p1.x, 1e-12
    assert_in_delta(-2.0, p1.y, 1e-12)
    assert_equal 16, geom::Point.size
    p2 = geom::Point.malloc
    p2.x = 1.0
    refute_in_delta p1.x, p2.x # 实例内存独立
  end

  def test_qsort_with_closure_callback
    compare = Class.new(Fiddle::Closure) do
      def call(a, b)
        Fiddle::Pointer.new(a)[0, 4].unpack1("l<") <=> Fiddle::Pointer.new(b)[0, 4].unpack1("l<")
      end
    end
    cmp = compare.new(Fiddle::TYPE_INT, [Fiddle::TYPE_VOIDP, Fiddle::TYPE_VOIDP])
    c_qsort = Fiddle::Function.new(LIBC["qsort"],
      [Fiddle::TYPE_VOIDP, Fiddle::TYPE_SIZE_T, Fiddle::TYPE_SIZE_T, Fiddle::TYPE_VOIDP],
      Fiddle::TYPE_VOID)
    arr = [5, 1, 4, 2, 3]
    raw = arr.pack("l<*")
    mem = Fiddle::Pointer.malloc(raw.bytesize)
    mem[0, raw.bytesize] = raw
    c_qsort.call(mem, arr.size, 4, cmp)
    assert_equal [1, 2, 3, 4, 5], mem.to_s(arr.size * 4).unpack("l<*")
  end

  def test_block_caller_callback
    double_cb = Fiddle::Closure::BlockCaller.new(Fiddle::TYPE_INT, [Fiddle::TYPE_INT]) { |x| x * 2 }
    assert_equal 42, double_cb.call(21)
  end

  def test_correct_signatures_keep_process_alive
    # 签名正确的调用不会段错误 —— FFI 纪律的正面验证
    sqrt = Fiddle::Function.new(LIBC["sqrt"], [Fiddle::TYPE_DOUBLE], Fiddle::TYPE_DOUBLE)
    c_abs = Fiddle::Function.new(LIBC["abs"], [Fiddle::TYPE_INT], Fiddle::TYPE_INT)
    assert_in_delta 3.0, sqrt.call(9.0), 1e-15
    assert_equal 7, c_abs.call(-7)
  end
end
