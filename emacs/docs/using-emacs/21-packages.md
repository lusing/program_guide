# 21 · 安装扩展包

Emacs 的扩展生态里绝大多数东西都是「包（package）」—— 一组 Elisp 文件，打包后放到公共仓库里供人下载。这一章讲怎么用 Emacs 自带的 `package.el` 从仓库里把包装下来、用起来、更新它、卸载它。注意：这是「**用**别人写的扩展」，不是「**写**扩展」——写扩展是隔壁 [Emacs 扩展开发指南](../extending-emacs/README.md) 的事。

## 21.1 包仓库：GNU ELPA 与 NonGNU ELPA

Emacs 31.1 默认配了两个官方仓库，变量 `package-archives` 里能看到：

```elisp
;; C-h v package-archives 看到的默认值
(("gnu" . "https://elpa.gnu.org/packages/")
 ("nongnu" . "https://elpa.nongnu.org/nongnu/"))
```

- **GNU ELPA**：包由 Emacs 官方维护，代码许可证必须是 GNU 兼容的。
- **NonGNU ELPA**：也是官方托管，但包的许可证不一定 GNU 兼容——很多流行的第三方包（如 `use-package`、`magit`）在这里。

你可以用 `customize` 界面（`M-x customize-variable RET package-archives RET`）添加第三方仓库（比如 MELPA），但**强烈建议先只用默认的两个**，等熟悉之后再扩展。第三方仓库的包质量参差不齐。

## 21.2 `M-x list-packages`：包菜单

`M-x list-packages`（命令 `list-packages`）会打开一个叫 `*Packages*` 的 buffer，列出所有仓库里可装的包。每一行长这样：

```text
 avl-trees       2.1.1          installed  Balanced binary trees
 magit           3.3.0          available  A Git porcelain
 use-package     2.4.5          installed  A configuration macro
```

从左到右：**包名**、**版本**、**状态**（`available`/`installed`/`new`/`dependency`/`unsigned`/`incompat` 等）、**简介**。

`*Packages*` 用的是 `package-menu-mode`，里面的键和 Dired 很像：

| 键 | 命令 | 作用 |
|---|---|---|
| `i` | `package-menu-mark-install` | 标记安装 |
| `d` | `package-menu-mark-delete` | 标记删除 |
| `u` | `package-menu-mark-unmark` | 取消标记 |
| `x` | `package-menu-execute` | 执行所有标记 |
| `U` | `package-menu-mark-upgrades` | 把所有可升级的包标记为「删旧装新」 |
| `r` | `revert-buffer` | 刷新列表 |
| `RET` / `f` | `package-menu-describe-package` | 查看包的说明 |
| `h` / `?` | `package-menu-quick-help` | 显示键位帮助 |
| `q` | `quit-window` | 关闭 buffer |

典型流程：`M-x list-packages` → `U`（标记所有可升级的包）→ `x`（执行）→ 回车确认。

## 21.3 按名字装一个包

如果你已经知道要装哪个包（比如看教程推荐了 `magit`），不需要进菜单：

```text
M-x package-install RET magit RET
```

Emacs 会下载它以及它依赖的所有包，装到 `package-user-dir`（默认是 `~/.emacs.d/elpa/`），装完后自动可用——不需要重启 Emacs，也不需要手动 `require`（大多数包都声明了 autoload）。

`M-x describe-package`（快捷键 `C-h P`）可以查看任意包的说明，包括它提供了什么命令、依赖什么、版本历史等。

## 21.4 装完之后

装完包后：

- 大多数包**立刻就能用**——它们的命令会出现在 `M-x` 补全里，快捷键会生效。
- 有些包需要你手动启用它的 minor mode（比如 `global-display-line-numbers-mode`），或加几行配置到 init 文件（见第 20 章）。包的说明里通常会写。
- 想升级：`M-x list-packages` → `U` → `x`，或者 `M-x package-menu-mark-upgrades` 后 `x`。
- 想清理不再被依赖的旧包：`M-x package-autoremove`（命令 `package-autoremove`）。它会删掉所有「没有任何已安装包依赖它」的包。

## 21.5 包的状态与签名

在 `*Packages*` 里你会看到几种状态：

- **`available`**：仓库里有，本地没装。
- **`installed`**：已装。
- **`new`**：仓库里新出现的包（自上次刷新后）。
- **`dependency`**：作为别的包的依赖被装进来的，不能单独删。
- **`unsigned`**：包没签名。GNU ELPA 的包都有签名；NonGNU ELPA 和第三方仓库的包不一定有。没签名的包也能装，只是 Emacs 会警告一下。
- **`incompat`**：包和你当前的 Emacs 版本不兼容。

## 21.6 一个最小化的 init 片段

装完包后，大多数情况下你只需要在 init 文件里 `require` 一下或打开它的 minor mode。比如装了 `display-line-numbers` 后想让所有程序 buffer 显示行号：

```elisp
;; 在 ~/.emacs.d/init.el 里
(add-hook 'prog-mode-hook #'display-line-numbers-mode)
```

不需要 `require`——`display-line-numbers-mode` 是内置的。但如果你装的是第三方包（比如 `magit`），通常也不用手动 `require`，因为包自带 autoload 声明；你直接 `M-x magit-status` 就能用。只有少数包需要你显式 `(require 'magit)`，包的文档会告诉你。

## 21.7 小结

- `M-x list-packages` 打开包菜单，`i`/`d`/`x` 是核心操作。
- `M-x package-install` 按名字装包。
- `M-x package-autoremove` 清理不再被依赖的包。
- 默认仓库是 GNU ELPA + NonGNU ELPA，够用；加第三方仓库要谨慎。
- 装完的包通常立刻可用，不需要重启。

---

上一章：[20 · 定制 Emacs](20-customization.md) ｜ 下一章：[22 · 会话与启动](22-sessions-and-startup.md) ｜ 返回：[使用 Emacs 教程](README.md)
