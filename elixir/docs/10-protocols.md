# 10 · 协议与行为

> 对应示例：`examples/10_protocols/`（独立 mix 工程，含 ExUnit 测试、doctest 与 `run.exs` 驱动脚本）

Elixir 没有继承，却有两种「多态」机制，名字相近、用途完全不同：

- **协议（protocol）**：按**值的运行时类型**分派。你可以在不修改 Integer、Map 或
  别人定义的 struct 的前提下，给它们补上某个协议的实现——这是 Elixir 扩展性的核心；
- **行为（behaviour）**：模块之间的**编译期接口契约**。模块声明「我实现了这个行为」，
  编译器检查回调是否齐全；调用时由调用方显式传入实现模块。

一句话区分：协议回答「这个值该怎么做」，行为回答「哪个模块来做」。

## 10.1 定义协议与内置类型实现

协议里只写函数头，没有函数体：

```elixir
defprotocol Ex10Protocols.Describable do
  @fallback_to_any true
  def describe(value)
  def category(value)
end

defimpl Ex10Protocols.Describable, for: [Integer, Float] do
  def describe(n), do: "number #{n}"
  def category(_), do: :number
end
```

`for:` 后面可以放单个类型，也可以放 `[Integer, Float]` 让一组类型共享实现。
本章还实现了 `BitString`（描述字素数）和 `List`（描述元素数）：

```text
-- 1. 协议定义与内置类型实现 --
  42        => number / number 42
  3.14      => number / number 3.14
  "hello"   => text / string of 5 grapheme(s)
  [1, 2]    => sequence / list of 2 element(s)
```

注意两个语法事实：定义用的是 **`defprotocol`**，不是 `defmodule`
（在普通模块里写无函数体的 `def describe(value)` 会得到
「implementation not provided」编译错误，本章开发时实际踩过）；
实现用 **`defimpl`**，一个实现模块里必须把协议的**每个**函数都实现全。

## 10.2 给 struct 实现协议

协议最大的用武之地是 struct：struct 是后来定义的类型，协议允许它
「后补」行为，而不需要任何继承关系：

```elixir
defmodule Ex10Protocols.Box do
  defstruct [:item]
end

defimpl Ex10Protocols.Describable, for: Ex10Protocols.Box do
  def describe(%Ex10Protocols.Box{item: item}), do: "box holding #{inspect(item)}"
  def category(_), do: :container
end
```

```text
-- 2. struct 的显式实现 --
  %Ex10Protocols.Box{item: 1} => {:container, "box holding 1"}
```

字段完全一样的普通 map 不会命中这个实现——协议分派看的是类型标记，
这与第 09 章 `%Box{}` 模式匹配的名义类型语义一致。**编译顺序**上，
struct 模块必须在 `defimpl ... for: Box` 之前定义，否则报
`Box.__struct__/1 is undefined, cannot expand struct`（同样实测踩过）。

## 10.3 Any 兜底与 @derive

协议默认对未实现的类型抛 `Protocol.UndefinedError`。两种「兜底」手段：

1. 协议声明 `@fallback_to_any true`，再提供 `for: Any` 的实现，
   所有没有专门实现的类型都会落到这里；
2. 某个 struct 想复用 Any 的函数体，不必重写，在结构体模块上写
   `@derive 协议名`，编译器会为它生成一个委托给 Any 的实现。

```text
-- 3. @fallback_to_any 与 @derive --
  没有专门实现的原子 => {:unknown, "unknown :hello"}
  @derive 的 Bag（复用 Any 函数体）=> {:unknown, "unknown %Ex10Protocols.Bag{items: [1, 2, 3]}"}
```

`@derive` 生成的是**独立的实现模块**（下一节的实现清单里能同时看到 `Any` 和
`Ex10Protocols.Bag`），函数体则照搬 Any。知名例子是 `@derive Jason.Encoder`：
JSON 库借此让 struct 按字段序列化。

## 10.4 impl_for 与协议合并（consolidation）

协议的分派是运行时查表：

```text
-- 4. impl_for 查询与 consolidation --
  impl_module(42)     => Ex10Protocols.Describable.Integer
  impl_module(:hello) => Ex10Protocols.Describable.Any
  consolidated?       => true
  impls（排序后）      => [["Any"], ["BitString"], ["Ex10Protocols", "Bag"], ..., ["Integer"], ["List"]]
  Enumerable impl_for(box) => nil（struct 默认没有）
```

- `Protocol.impl_for/1` 返回实现模块，没有实现且无 Any 兜底时返回 `nil`；
  `impl_for!/1` 同样情况下抛 `Protocol.UndefinedError`，错误信息还会列出
  「当前已为哪些类型实现」；
- **协议合并**：mix 编译时（dev/test/prod 都默认开启）会把协议的分派表
  提前固化成一个模块，消除运行时查表开销。`__protocol__(:impls)` 返回
  `{:consolidated, 类型清单}`；清单里给的是**类型名**（`Integer`、
  `Ex10Protocols.Bag`），而 `impl_for/1` 给的是**实现模块名**
  （`Ex10Protocols.Describable.Integer`），别混。
- 副作用：**合并之后再动态加实现不生效**。脚本/热更新场景需要
  `Protocol.consolidate/1` 或在编译期关闭合并；常规 mix 工程不用管。

## 10.5 内置协议速览

Elixir 标准库本身就建立在协议上，最常打交道的四个：

| 协议 | 谁在用 | struct 默认 |
|---|---|---|
| `Enumerable` | `Enum`、`Stream` 的全部函数 | 未实现 |
| `Collectable` | `Enum.into/2`、`for` 的 `:into` | 未实现 |
| `String.Chars` | `to_string/1`、字符串插值 `"#{}"` | 未实现 |
| `Inspect` | `inspect/1`、IEx 显示 | 有默认实现（结构体原样打印） |

```text
-- 5. 内置协议 --
  safe_count([1,2,3]) => 3
  safe_count(box)     => {:raised, Protocol.UndefinedError}
  safe_to_string(box) => {:raised, Protocol.UndefinedError}
  自定义 Inspect      => #Secret<masked:42>
  自定义 String.Chars => "secret(42)"
  Enum.into/2 走 Collectable => [1, 2]
```

本章的 `Secret` struct 同时实现了 `Inspect`（日志里打码）和 `String.Chars`
（允许插值）。两点关键经验：

- **struct 默认不能 `Enum.count/1`、不能插值**——这是新手最常见的
  `Protocol.UndefinedError`。要么实现协议，要么显式 `inspect/1`；
- 1.20 的类型检查器会在**编译期**发现这种错误：直接写
  `to_string(%Box{})` 会得到「expected a type that implements the
  String.Chars protocol」告警（`--warnings-as-errors` 下编译失败）。
  本章用参数类型为 `term()` 的 `safe_count/1`、`safe_to_string/1`
  包住这类「故意在运行时演示失败」的调用。

## 10.6 @behaviour：编译期契约

行为用 `@callback` 声明函数规格，用 `@optional_callbacks` 声明可选项，
实现方写 `@behaviour 模块` 和 `@impl true`：

```elixir
defmodule Ex10Protocols.Storage do
  @callback get(store :: term(), key :: term()) :: {:ok, term()} | :error
  @callback put(store :: term(), key :: term(), value :: term()) :: term()
  @callback keys(store :: term()) :: [term()]
  @optional_callbacks keys: 1

  def fetch!(impl, store, key) do           # 公共 API 可以放在行为模块里共享
    case impl.get(store, key) do
      {:ok, value} -> value
      :error -> raise KeyError, key: key, term: store
    end
  end
end
```

```text
-- 6. @behaviour：按模块分派、编译期检查回调 --
  get :a / :missing   => {:ok, 1} / :error
  keys（可选回调）     => [:a, :b]
  Storage.fetch!      => 1
  漏写回调的编译诊断   => function put/3 required by behaviour Ex10Protocols.Storage
                         is not implemented (in module Ex10Protocols.BadStorageSample)
```

- 声明了 `@behaviour` 却漏写**必选**回调，是**编译告警**（不是运行时崩溃）；
  本章的 `missing_callback_diagnostic/0` 用 `Code.with_diagnostics/1`
  动态编译一个坏模块并截获诊断，避免污染 stderr；
- `@impl true` 让编译器帮你核对函数名/参数个数是否真的是回调——
  给不是回调的函数（如构造函数 `new/0`）标 `@impl true` 同样告警；
- 调用方式是 `Storage.fetch!(MemoryStorage, store, :a)`：**实现模块显式入参**，
  这是依赖注入最朴素的形式——测试时换一个 `MockStorage` 即可。

## 10.7 协议 vs 行为

```text
  分派依据    协议：值的运行时类型        行为：调用方显式传入模块
  检查时机    协议：运行时 Protocol 错误   行为：编译期缺回调告警
  开放程度    协议：可给任何类型后补实现    行为：模块自己声明 @behaviour
  典型用途    Enumerable / Jason.Encoder  存储后端 / Strategy 插件
```

选择规则很简单：想让**同一套函数对各种数据类型**生效（序列化、遍历、显示），
用协议；想定义**一组可互换的后端/策略**（存储、通知渠道、支付网关），用行为。
两者经常配合：行为规定回调，回调内部对状态数据用协议多态。

## 10.8 坑位清单

1. **用 `defprotocol` 而不是 `defmodule`**：在普通模块里写无函数体的
   `def f(x)` 报「implementation not provided」。实现用 `defimpl`。

2. **defimpl 必须实现协议的全部函数**，少一个就是编译错误；
   `for:` 列表可以让多个类型共享一个实现模块。

3. **struct 必须先定义再 defimpl**：编译顺序反了报
   `X.__struct__/1 is undefined`。同一文件里按「struct 模块在前」排。

4. **struct 默认不实现 Enumerable / Collectable / String.Chars**：
   不能 `Enum.into`、不能插值，先确认协议是否存在。
   `Inspect` 有默认实现，所以 inspect 永远不报错。

5. **1.20 编译期就查协议实现**：`to_string(%Box{})` 这类调用在
   `--warnings-as-errors` 下直接编译失败。要在运行时处理「可能没实现」，
   把参数藏进 `term()` 类型的函数，或用 `impl_for/1` 先查表。

6. **Any 兜底必须双开**：协议里 `@fallback_to_any true` **和**
   `defimpl ... for: Any` 缺一不可；只写后者不会被使用。

7. **合并后动态加实现无效**：mix 默认 consolidation；REPL/脚本里
   合并状态不同，行为可能与工程内不一致（本章脚本实测分派表不可用）。
   另外 `:impls` 清单是类型名，`impl_for/1` 是实现模块名。

8. **`@impl true` 只能标在回调上**：标错函数告警；反过来漏标 `@impl`
   不报错但会丢失编译器的签名核对，团队规约建议一律标。

9. **行为契约只管回调存在**：不检查返回值是否符合 `@callback` 的 spec
   （那是 Dialyzer 的活，见第 23 章）；必选回调缺失只是告警，
   要在 CI 用 `--warnings-as-errors` 把它变成硬失败。

---

下一章：[11 · 错误处理与日志](11-errors.md)
