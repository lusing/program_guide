# 设计模式教程（C++23）

以三本书为纲：《设计模式之禅（第2版）》、刘伟《设计模式（第2版）》、GoF《设计模式：可复用面向对象软件的基础》。每章经典写法与 C++23 现代写法对照，全部讲解内嵌正文代码，配套 40 个可运行示例（MSVC + clang 双通道逐字节一致）。

## 快速开始

```bash
pwsh ./build.ps1 -All          # 全量 80 项（40 示例 × 2 通道），应"通过 80 失败 0"
pwsh ./build.ps1 -Example 25_state   # 单示例双通道验证
./run-all.sh                   # clang/gcc 门控通道
```

判定六条：exit 0、stderr 空、stdout 非空、无控制字符、以"自检通过"结尾、零告警；输出确定性（不打印地址/时间戳/浮点直接值/类型大小）。

## 章节导航

### 第〇篇 原则与地基（1-4）

- [01 · 引论：为什么是模式](docs/01-intro.md)
- [02 · 单一职责与开闭](docs/02-srp_ocp.md)
- [03 · 里氏替换与依赖倒置](docs/03-lsp_dip.md)
- [04 · 接口隔离、迪米特与合成复用](docs/04-isp_lod_crp.md)

### 第一篇 创建型（5-10）

- [05 · 简单工厂](docs/05-simplefactory.md)
- [06 · 工厂方法](docs/06-factorymethod.md)
- [07 · 抽象工厂](docs/07-abstractfactory.md)
- [08 · 单例](docs/08-singleton.md)
- [09 · 原型](docs/09-prototype.md)
- [10 · 建造者](docs/10-builder.md)

### 第二篇 结构型（11-17）

- [11 · 适配器](docs/11-adapter.md)
- [12 · 桥接](docs/12-bridge.md)
- [13 · 组合](docs/13-composite.md)
- [14 · 装饰器](docs/14-decorator.md)
- [15 · 外观](docs/15-facade.md)
- [16 · 享元](docs/16-flyweight.md)
- [17 · 代理](docs/17-proxy.md)

### 第三篇 行为型（18-28）

- [18 · 责任链](docs/18-chainofresp.md)
- [19 · 命令](docs/19-command.md)
- [20 · 解释器](docs/20-interpreter.md)
- [21 · 迭代器](docs/21-iterator.md)
- [22 · 中介者](docs/22-mediator.md)
- [23 · 备忘录](docs/23-memento.md)
- [24 · 观察者](docs/24-observer.md)
- [25 · 状态](docs/25-state.md)
- [26 · 策略](docs/26-strategy.md)
- [27 · 模板方法](docs/27-templatemethod.md)
- [28 · 访问者](docs/28-visitor.md)

### 第四篇 现代专题（29-32）

- [29 · 多态的三副面孔（虚函数/concepts/variant）](docs/29-polymorphism.md)
- [30 · 类型擦除](docs/30-typeerasure.md)
- [31 · 日志系统：四模式混编现场](docs/31-logging.md)
- [32 · 事件总线：观察者的解耦终点](docs/32-eventbus.md)

### 第五篇 实战篇（33-36）

- [33 · 状态机实战：一张表，两种执行](docs/33-statemachine.md)
- [34 · 对象池实战：借出、归还、上限](docs/34-objpool.md)
- [35 · 自注册插件框架](docs/35-plugins.md)
- [36 · 表达式求值器：四模式一条流水线](docs/36-evaluator.md)

### 第六篇 收官（37-40）

- [37 · 文档导出：桥与外观的合体](docs/37-docexport.md)
- [38 · 权限校验：三模式的管道切面](docs/38-permission.md)
- [39 · 反模式三幕](docs/39-antipatterns.md)
- [40 · 收官：速查表、决策树与学习路线](docs/40-cheatsheet.md)

## 三本书怎么配合

刘伟《设计模式（第2版）》建直觉（实例驱动）→ GoF 定标准（意图/适用性/实现判据）→ 之禅补判断（原则与最佳实践）。每章末"三书对应"给出该章素材的精确出处与页内小节。

## 示例目录

`examples/NN_name/` 与章号一一对应：每章示例 = 头文件（模式骨架）+ `main.cpp`（断言到行为面的自检）。39/40 章为 main-only。构建产物在 `build/`（不入库），OCR 素材在 `materials/`（不入库）。
