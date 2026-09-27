// 29_math：math 舍入/取模/NaN、cmplx、math/rand/v2 可复现流、math/big 大数。
// 对照 docs/29-math.md。
package main

import (
	"fmt"
	"math"
	"math/big"
	"math/cmplx"
	"math/rand/v2"
	"time"
)

// Factorial 精确阶乘——int64 在 21! 就溢出，big 无压力。
func Factorial(n int64) *big.Int {
	return new(big.Int).MulRange(1, n)
}

// Roll 用固定种子的 PCG 流掷骰子 n 次——种子相同，序列相同（可复现）。
func Roll(seed1, seed2 uint64, n int) []int {
	r := rand.New(rand.NewPCG(seed1, seed2))
	out := make([]int, n)
	for i := range out {
		out[i] = r.IntN(6) + 1
	}
	return out
}

func main() {
	fmt.Println("== 舍入家族 ==")
	fmt.Println("Round(2.5) =", math.Round(2.5), "/ Round(-2.5) =", math.Round(-2.5))
	fmt.Println("RoundToEven(2.5) =", math.RoundToEven(2.5), "/ RoundToEven(3.5) =", math.RoundToEven(3.5))

	fmt.Println("== 取模：Go 的模跟被除数同号（Python/JS 惯性注意）==")
	fmt.Println("-7 % 3 =", -7%3, "/ math.Mod(-7,3) =", math.Mod(-7, 3), "/ 非负模惯用法 =", ((-7%3)+3)%3)

	fmt.Println("== NaN：与谁都不相等，包括自己 ==")
	nan := math.NaN()
	fmt.Println("nan == nan:", nan == nan, "/ IsNaN:", math.IsNaN(nan))
	fmt.Println("Sort 前先洗掉 NaN——它让 Less 失去传递性")

	fmt.Println("== cmplx：复数运算 ==")
	z := complex(3, 4)
	fmt.Printf("z = %v, Abs = %v, Phase = %.3f rad\n", z, cmplx.Abs(z), cmplx.Phase(z))
	r, theta := cmplx.Polar(z)
	fmt.Printf("Polar: r=%v θ=%.3f → 还原 %v\n", r, theta, cmplx.Rect(r, theta))
	euler := cmplx.Exp(complex(0, math.Pi))
	fmt.Printf("e^{iπ} = %v（虚部是浮点尾巴）\n", euler)

	fmt.Println("== rand/v2：全局源（并发安全、自动随机）==")
	fmt.Println("IntN(100):", rand.IntN(100), "Float64:", rand.Float64())
	d := rand.N(10 * time.Second)
	fmt.Println("N(10s):", d)
	sl := []int{1, 2, 3, 4, 5}
	rand.Shuffle(len(sl), func(i, j int) { sl[i], sl[j] = sl[j], sl[i] })
	fmt.Println("Shuffle:", sl)
	fmt.Println("Perm(5):", rand.Perm(5))

	fmt.Println("== rand/v2：PCG 固定种子 = 可复现流 ==")
	a := Roll(42, 42, 6)
	b := Roll(42, 42, 6)
	c := Roll(43, 42, 6)
	fmt.Println("同种子两次:", a, b, "一致 =", fmt.Sprint(a) == fmt.Sprint(b))
	fmt.Println("换一次种子:", c)

	fmt.Println("== big：大数没有心理负担 ==")
	fmt.Println("20! =", Factorial(20))
	fmt.Println("100! 的位数:", len(Factorial(100).String()))
	u := new(big.Int).SetUint64(math.MaxUint64)
	v := big.NewInt(1)
	sum := new(big.Int).Add(u, v)
	fmt.Printf("MaxUint64+1 = %v（int64 早爆了）\n", sum)
	frac := new(big.Rat).SetFrac(big.NewInt(1), big.NewInt(3))
	f64, _ := frac.Float64()
	fmt.Printf("Rat 1/3: 精确表示 %v → float %v\n", frac, f64)
}
