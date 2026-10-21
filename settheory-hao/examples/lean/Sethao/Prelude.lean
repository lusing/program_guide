import Mathlib.Tactic

/-!
# Prelude：工程常驻模块

全工程唯一的公共职责：预热 mathlib 导入，验证钉版路径依赖可用。
各章模块自带所需 import，不依赖本模块。
-/

#check @Set.ext          -- 外延公理在 mathlib 中的影子
#check @Set.powerset     -- 幂集
#check @Ordinal.type     -- 序数通道的入口之一
#check @Cardinal.mk      -- 基数通道的入口之一
