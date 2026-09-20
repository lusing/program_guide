# 18 · 测试

> 对应示例：`examples/16_testing.clj`

> `clojure.test` 是内置测试框架：deftest/is/are/testing 三件套 + fixtures。
> 小而够用；属性测试（test.check）在 19 章的 spec 里另有入口。

## 18.1 三件套

```clojure
(ns my-app.core-test
  (:require [clojure.test :refer [deftest is are testing run-tests]]
            [my-app.core :as core]))

(deftest fee-test                          ; 1) deftest：一个测试单元
  (is (= 30 (core/fee 10)))                ; 2) is：一条断言（失败时打印两边的值）
  (is (pos? (core/fee 1)))
  (is (thrown? ArithmeticException (/ 1 0))))   ; 断"会抛"

(deftest fib-test
  (testing "fib 的边界"                     ; 3) testing：分组描述（失败信息带上下文）
    (is (= 0 (core/fib 0)))
    (is (= 1 (core/fib 1))))
  (testing "fib 的递推"
    (is (= 55 (core/fib 10)))))
```

`is` 的失败信息把**实际值**打出来——Clojure 表达式求值即数据，断言失败自带现场：

```
expected: (= 30 (core/fee 10))
  actual: (not (= 30 25))
```

## 18.2 断言全家

| 断言 | 判什么 |
|---|---|
| `(is (= a b))` | 相等（**结构相等**，05 章——map/vector 深比） |
| `(is (instance? X v))` | 类型 |
| `(is (thrown? ExType body))` | 抛指定类型异常 |
| `(is (thrown-with-msg? ExType #"regex" body))` | 抛异常且消息匹配 |
| `(is (some? x))` / `nil?` / 真值表达式 | 直接判 |

```clojure
(is (thrown-with-msg? IllegalArgumentException #"negative"
    (core/factorial -1)))
```

## 18.3 are：表驱动断言

```clojure
(deftest fib-table
  (are [n expected] (= expected (core/fib n))
    0 0
    1 1
    2 1
    10 55
    20 6765))
```

`are` = "同一条断言 × N 行数据"——测试数据成表，一眼看全边界。**新用例优先往表里加行**，而不是复制 deftest。

## 18.4 运行与报告

```clojure
(run-tests)                                ; 当前 ns 全部 deftest
(run-tests 'my-app.core-test 'other-test)  ; 指定 ns
(clojure.test/run-all-tests)               ; 全世界（正则可过滤）
```

REPL 输出：

```
Testing my-app.core-test

Ran 2 tests containing 6 assertions.
0 failures, 0 errors.
```

命令行（工具链差异）：

```bash
lein test                          # Leiningen：自动发现 test/ 下 *-test ns
clojure -X:test                    # CLI：deps.edn 配 :test alias + cognitect test-runner
```

退出码：有失败 = 非零，可直接进 CI（26 章的四步验证链第一步就是它）。

## 18.5 fixtures：setup / teardown

```clojure
(use-fixtures :once fixture-fn)      ; 整个 ns 跑一次（昂贵准备：连库、建表）
(use-fixtures :each fixture-fn)      ; 每个 deftest 前后各一次（干净状态）

(defn db-fixture [f]                 ; fixture 形状：吃"跑测试的函数"，前后包夹
  (setup-db!)
  (f)
  (teardown-db!))
```

fixture 是"高阶函数包夹测试"——和中间件（25 章）同一个思想，测什么都没变。

## 18.6 测什么、怎么组织

- **纯函数测试最便宜**——数据进数据出，无需 mock；设计上尽量把逻辑挤进纯函数（数据管线 22 章的形状）。
- 含状态的函数：每个测试自己造状态（`:each` fixture 或测试内 `atom`），不共享。
- 文件/网络：小文件用 `java.io.tmpdir` 下的临时目录，用完删（16 章模板）；外部服务集成测试单独 ns，CI 里可跳过。
- 命名：`<被测函数>-test` 或 `<场景>-test`；测试 ns 名一律 `-test` 结尾（runner 按此发现）。

## 18.7 坑位清单

1. **deftest 是"注册"不是"执行"**——定义后要 run-tests（或 lein test）；REPL 里 deftest 立即跑一次是便利，不是契约。
2. **`= 对 float 不友好**：`(is (= 0.1 (+ 0.05 0.05)))` 可能假（浮点误差）——用范围断言 `(is (< (Math/abs (- x y)) 1e-9))`。
3. **惰性 seq 的断言**：`(= (map inc xs) ...)` 对无限 seq 挂死——断言前 take/doall 成具体形状。
4. **thrown? 抓的异常类型要精确**：`(is (thrown? Exception ...))` 太宽——把实现 bug 也当"预期"放过了。
5. **测试之间共享可变状态**：`(def state (atom ...))` 被多个 deftest 改 → 测试顺序敏感、单独跑绿全跑红。每个测试自建状态。
6. **run-tests 的返回值**是 map（`{:test 2 :pass 6 :fail 0 :error 0}`），不抛异常——CI 判断要看退出码/`:fail`/`:error`。
7. **private 函数测不了**：`defn-` 的符号 require 后不可见——要么测公共行为，要么 `@#'my-ns/private-f` 取 Var（测试专属逃生门）。

---

上一章：[17 命名空间](17-namespaces.md) · 下一章：[19 clojure.spec](19-spec.md)
