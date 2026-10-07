//! 17.7 `zig translate-c` 的产物：**手工裁剪版**，按惯例提交进源码树。
//!
//! 生成命令：
//!     zig translate-c include/ci.h > src/bindings_ci.zig
//!
//! 原始产物 420 行，其中 400 行是 `<stddef.h>` 展开带来的编译器内置宏
//! （`__STDC_VERSION__`、`__LDBL_MAX__`、`__GNUC__`……）和一个翻译不了的
//! `offsetof` 宏。真正属于本工程接口的只有下面这 6 行 —— 这就是 17.7 说的
//! "裁剪"：把几十万个宏删掉，只留冰山一角。
//!
//! 对比 `b.addTranslateC`：那条路产物落在 `zig-cache/`，看不见摸不着，
//! 但增量构建时只翻译一次；这条路产物进仓库，可以 code review、可以手工加注释、
//! 还能让没装 clang 的机器构建。代价是**头文件改了要记得重新生成**。
//!
//! ⚠️ 裁剪时保留的那条注释值得注意：`ci_strlen` 的 C 原型是
//! `size_t ci_strlen(const char *)`，翻译成 `[*c]const u8` 而不是 `[:0]const u8` ——
//! 0.17 的 translate-c 产出的是 `[ *c]` 哨兵指针（见 17.5）。

pub extern fn ci_add(a: c_int, b: c_int) c_int;
pub extern fn ci_triple(a: c_int) c_int;
pub extern fn ci_strlen(s: [*c]const u8) usize;
pub extern fn ci_strcmp(a: [*c]const u8, b: [*c]const u8) c_int;

// ci.h 里声明的、实现在 Zig 侧的函数（17.3 export fn）
pub extern fn zig_add(a: c_int, b: c_int) c_int;
pub extern fn zig_version() [*c]const u8;
