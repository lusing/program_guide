define config.name = _("生命周期演示")
define config.version = "1.0"

# 免素材：用引擎内置的静音伪文件当作主菜单音乐（第 20 章讲过音频的特殊文件名）
define config.main_menu_music = "<silence 30.0>"

# 转场全部用内建转场，无需任何图片
define config.end_splash_transition = Dissolve(0.5)   # 开场动画 → 主菜单
define config.end_game_transition = Dissolve(0.5)     # 游戏 → 主菜单

define config.developer = True
