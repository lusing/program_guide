# 03 测试层：minitest 套件
# frozen_string_literal: true
require "minitest/autorun"

class TestNumbers < Minitest::Test
  def test_integer_no_overflow
    assert_equal 9_223_372_036_854_775_808, 9_223_372_036_854_775_807 + 1
    assert_equal 31, (2**100).to_s.size
  end

  def test_bases
    assert_equal 10, 0b1010
    assert_equal 255, 0xFF
    assert_equal "ff", 255.to_s(16)
    assert_equal 255, "ff".to_i(16)
  end

  def test_float_classics
    refute_equal 0.3, 0.1 + 0.2
    assert_in_delta 0.3, 0.1 + 0.2, 1e-9
    assert_predicate 0.0 / 0.0, :nan?
    assert_equal Float::INFINITY, 1.0 / 0.0
  end

  def test_rational_complex
    assert_equal Rational(1, 2), Rational(1, 3) + Rational(1, 6)
    assert_equal Rational(1, 3), Rational("3/9")
    assert_equal Complex(5, 0), Complex(1, 2) * Complex(1, -2)
    assert_equal 5.0, (3 + 4i).abs
  end

  def test_floor_division
    assert_equal(-4, 7 / -2)
    assert_equal [-4, -1], 7.divmod(-2)
    assert_equal(-1, 7 % -2)
    assert_equal 2, -7 % 3
    assert_equal -3.5, 7.fdiv(-2)
  end

  def test_conversion_tolerance
    assert_equal 42, "42abc".to_i
    assert_equal 0, "abc".to_i
    assert_raises(ArgumentError) { Integer("42abc") }
  end

  def test_rounding
    assert_equal 3, 2.5.round
    assert_equal(-4, (-3.5).round)
    assert_equal 3, 3.99.to_i
    assert_equal 4, 3.99.round
  end

  def test_clamp_and_friends
    assert_equal 10, 15.clamp(0, 10)
    assert_equal 3, 3.gcd(18)
    assert_equal 12, 4.lcm(6)
  end
end
