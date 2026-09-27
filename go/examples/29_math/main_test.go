package main

import (
	"math"
	"math/big"
	"reflect"
	"testing"
)

func TestRounding(t *testing.T) {
	if math.Round(2.5) != 3 || math.Round(-2.5) != -3 {
		t.Error("Round 是远离零")
	}
	if math.RoundToEven(2.5) != 2 || math.RoundToEven(3.5) != 4 {
		t.Error("RoundToEven 是银行家舍入")
	}
}

func TestNegativeMod(t *testing.T) {
	if -7%3 != -1 {
		t.Errorf("Go 的 %% 跟被除数同号，got %d", -7%3)
	}
	if math.Mod(-7, 3) != -1 {
		t.Errorf("math.Mod 也跟被除数同号（同 fmod），got %v", math.Mod(-7, 3))
	}
	if got := ((-7 % 3) + 3) % 3; got != 2 {
		t.Errorf("非负模惯用法 = %d, want 2", got)
	}
}

func TestNaNComparisons(t *testing.T) {
	nan := math.NaN()
	if nan == nan || nan < 1 || nan > 1 || nan <= nan {
		t.Error("NaN 与任何值的比较都应为 false")
	}
	if !math.IsNaN(nan) {
		t.Error("IsNaN 应为 true")
	}
}

func TestFactorial(t *testing.T) {
	want, ok := new(big.Int).SetString("2432902008176640000", 10) // 20!
	if !ok {
		t.Fatal("测试数据坏了")
	}
	if Factorial(20).Cmp(want) != 0 {
		t.Errorf("20! = %v", Factorial(20))
	}
	if got := len(Factorial(100).String()); got != 158 {
		t.Errorf("100! 有 %d 位，want 158", got)
	}
}

func TestRollReproducible(t *testing.T) {
	a, b := Roll(42, 42, 10), Roll(42, 42, 10)
	if !reflect.DeepEqual(a, b) {
		t.Errorf("同种子应同序列：%v vs %v", a, b)
	}
	if c := Roll(43, 42, 10); reflect.DeepEqual(a, c) {
		t.Error("换种子应换序列（运气好撞上才算失败，概率 (1/6)^10）")
	}
	for _, v := range a {
		if v < 1 || v > 6 {
			t.Errorf("骰子出界: %d", v)
		}
	}
}
