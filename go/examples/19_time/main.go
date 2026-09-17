// 19_time：Duration、参考时间格式化、时区、Timer/Ticker。
// 注意 import _ "time/tzdata"：Windows 没有系统 tz 数据库，不带上它
// LoadLocation 会报错——这是 Windows 上用tz 的第一个坑。
package main

import (
	"fmt"
	"time"
	_ "time/tzdata" // 把 IANA 时区库嵌进二进制（约 450KB）
)

// layoutCN 格式串就是"参考时间"本身：2006-01-02 15:04:05（Go 生日时刻）。
const layoutCN = "2006-01-02 15:04:05"

// NextMonday 返回 t 之后（不含当天）的第一个周一。
func NextMonday(t time.Time) time.Time {
	days := (int(time.Monday) - int(t.Weekday()) + 7) % 7
	if days == 0 {
		days = 7
	}
	return t.AddDate(0, 0, days)
}

func main() {
	fmt.Println("== Duration：强类型时间段，秒/毫秒不会混写 ==")
	d := 2*time.Hour + 15*time.Minute
	fmt.Println(d, "≈", d.Minutes(), "分钟 =", int(d.Seconds()), "秒")

	fmt.Println("== 时间点运算（AddDate 月末会归一化，见坑位） ==")
	now := time.Date(2026, 9, 17, 10, 30, 0, 0, time.UTC) // 固定时刻，输出确定
	fmt.Println("原时刻:  ", now.Format(layoutCN), now.Weekday())
	fmt.Println("加90分钟:", now.Add(90*time.Minute).Format(layoutCN))
	fmt.Println("加一个月:", now.AddDate(0, 1, 0).Format(layoutCN))
	fmt.Println("下个周一:", NextMonday(now).Format(layoutCN))

	fmt.Println("== 格式化：布局串 = 参考时间的模样 ==")
	fmt.Println(now.Format(layoutCN))
	fmt.Println(now.Format("2006/1/2 3:04 PM"))
	fmt.Println(now.Format(time.RFC3339), "（RFC3339 常量现成）")

	fmt.Println("== 解析 ==")
	t, err := time.Parse(layoutCN, "2026-10-01 09:00:00")
	if err != nil {
		fmt.Println("解析失败:", err)
	} else {
		fmt.Println("国庆是", t.Weekday(), "距现在", t.Sub(now).Hours(), "小时")
	}

	fmt.Println("== 时区转换 ==")
	utc := time.Date(2026, 9, 17, 0, 0, 0, 0, time.UTC)
	tokyo, err := time.LoadLocation("Asia/Tokyo")
	if err != nil {
		fmt.Println("LoadLocation:", err)
	} else {
		fmt.Println(utc.In(tokyo).Format(layoutCN), "东京")
	}
	cst := time.FixedZone("CST", 8*3600) // 固定偏移 +8：不查表、不会错
	fmt.Println(utc.In(cst).Format(layoutCN), "北京时间")

	fmt.Println("== 单调时钟：Since 测耗时不受改系统时间影响 ==")
	start := time.Now()
	time.Sleep(20 * time.Millisecond)
	fmt.Println("睡了约", time.Since(start).Round(time.Millisecond))

	fmt.Println("== Timer / Ticker ==")
	timer := time.NewTimer(10 * time.Millisecond)
	<-timer.C // 到点往 C 里投一个值
	fmt.Println("timer 触发")
	ticker := time.NewTicker(5 * time.Millisecond)
	hits := 0
	for range ticker.C {
		hits++
		if hits == 3 {
			ticker.Stop() // 仍应显式 Stop（1.23 起忘了不再泄漏，但停掉更干净）
			break
		}
	}
	fmt.Println("ticker 命中", hits, "次")
}
