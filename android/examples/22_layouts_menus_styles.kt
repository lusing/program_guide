package guide.android.examples

import android.app.Activity
import android.app.AlertDialog
import android.graphics.Color
import android.graphics.drawable.AnimationDrawable
import android.graphics.drawable.ClipDrawable
import android.graphics.drawable.ColorDrawable
import android.graphics.drawable.GradientDrawable
import android.graphics.drawable.StateListDrawable
import android.os.Bundle
import android.view.Gravity
import android.view.Menu
import android.view.MenuItem
import android.view.View
import android.view.ViewGroup
import android.widget.Button
import android.widget.EditText
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.PopupWindow
import android.widget.TableLayout
import android.widget.TableRow
import android.widget.TextView
import android.widget.Toast
import android.widget.GridLayout

// ---- 12 章第 1 节：TableLayout，列的报名制 + 三种列行为 ----

class Example22TableLayout : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val table = TableLayout(this).apply {
            setColumnStretchable(1, true)          // 第 2 列吃掉剩余宽度
        }
        table.addView(Button(this).apply { text = "独占一行的按钮（不裹 TableRow）" })
        table.addView(TableRow(this).apply {
            addView(TextView(this@Example22TableLayout).apply { text = "姓名" })
            addView(EditText(this@Example22TableLayout).apply { hint = "拉伸列自动变宽" })
        })
        table.addView(TableRow(this).apply {
            addView(TextView(this@Example22TableLayout).apply { text = "备注" })
            addView(EditText(this@Example22TableLayout))
            addView(Button(this@Example22TableLayout).apply { text = "…" })
        })
        setContentView(table)
    }
}

// ---- 12 章第 1 节：GridLayout 计算器界面（书 2.2.5 实例复刻）----

class Example22GridLayout : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val grid = GridLayout(this).apply { columnCount = 4 }
        val display = TextView(this).apply {
            text = "0"
            gravity = Gravity.END or Gravity.CENTER_VERTICAL
            textSize = 28f
            setPadding(0, 32, 0, 32)
        }
        val displayParams = GridLayout.LayoutParams(
            GridLayout.spec(0),                          // 第 0 行
            GridLayout.spec(0, 4, 1f)                    // 从第 0 列起跨 4 列，权重均分
        ).apply {
            width = GridLayout.LayoutParams.MATCH_PARENT
        }
        grid.addView(display, displayParams)
        val keys = listOf("7", "8", "9", "÷", "4", "5", "6", "×",
            "1", "2", "3", "−", "C", "0", "=", "+")
        keys.forEachIndexed { i, label ->
            val lp = GridLayout.LayoutParams(
                GridLayout.spec(i / 4 + 1, 1f),         // 权重写法：行内均分
                GridLayout.spec(i % 4, 1f)
            ).apply {
                width = 0
                height = GridLayout.LayoutParams.WRAP_CONTENT
            }
            grid.addView(Button(this).apply { text = label }, lp)
        }
        setContentView(grid)
    }
}

// ---- 12 章第 3 节：AlertDialog 六法之三 + PopupWindow ----

class Example22Dialogs : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val root = LinearLayout(this).apply { orientation = LinearLayout.VERTICAL }
        root.addView(Button(this).apply {
            text = "消息对话框"
            setOnClickListener { showMessageDialog() }
        })
        root.addView(Button(this).apply {
            text = "单选列表对话框"
            setOnClickListener { showSingleChoiceDialog() }
        })
        setContentView(root)
    }

    private fun showMessageDialog() {
        AlertDialog.Builder(this).apply {
            setTitle("删除确认")
            setMessage("这份便签将永久删除。")
            setPositiveButton("删除") { _, _ ->
                Toast.makeText(context, "已删除", Toast.LENGTH_SHORT).show()
            }
            setNegativeButton("取消", null)
            setNeutralButton("详情") { _, _ ->
                Toast.makeText(context, "查看详情", Toast.LENGTH_SHORT).show()
            }
        }.show()
    }

    private fun showSingleChoiceDialog() {
        val sizes = arrayOf("小", "中", "大")
        AlertDialog.Builder(this).apply {
            setTitle("字号")
            setSingleChoiceItems(sizes, 1) { _, which ->
                Toast.makeText(context, "选择了 ${sizes[which]}", Toast.LENGTH_SHORT).show()
            }
            setPositiveButton("确定", null)
        }.show()
    }
}

class Example22PopupWindow : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val anchor = Button(this).apply { text = "点我弹出浮层" }
        setContentView(anchor)
        anchor.setOnClickListener { v ->
            val content = LinearLayout(v.context).apply {
                orientation = LinearLayout.VERTICAL
                setBackgroundColor(Color.WHITE)
                addView(TextView(v.context).apply {
                    text = "PopupWindow：浮层不抢模态"
                    setPadding(32, 32, 32, 32)
                })
            }
            val popup = PopupWindow(
                content,
                ViewGroup.LayoutParams.WRAP_CONTENT,
                ViewGroup.LayoutParams.WRAP_CONTENT
            ).apply {
                isFocusable = true          // 吃返回键关闭
                isOutsideTouchable = true   // 点外部关闭
            }
            popup.showAsDropDown(v)         // 挂在锚点下方
        }
    }
}

// ---- 12 章第 4 节：三种菜单之选项菜单与上下文菜单 ----

class Example22Menus : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val tv = TextView(this).apply { text = "长按我呼出上下文菜单" }
        setContentView(tv)
        registerForContextMenu(tv)
    }

    override fun onCreateOptionsMenu(menu: Menu): Boolean {
        menu.add(0, 1, 0, "新建")
        menu.add(0, 2, 1, "排序").subMenu?.apply {   // 子菜单：无图标、不可嵌套
            add(0, 21, 0, "按时间")
            add(0, 22, 1, "按名称")
            setHeaderTitle("排序方式")
        }
        menu.setGroupCheckable(0, true, false)        // 组内可勾选（非互斥）
        return true
    }

    override fun onOptionsItemSelected(item: MenuItem): Boolean = when (item.itemId) {
        1 -> {
            Toast.makeText(this, "新建", Toast.LENGTH_SHORT).show()
            true
        }
        else -> super.onOptionsItemSelected(item)
    }

    override fun onCreateContextMenu(menu: android.view.ContextMenu, v: View, menuInfo: android.view.ContextMenu.ContextMenuInfo) {
        super.onCreateContextMenu(menu, v, menuInfo)
        menu.setHeaderTitle("上下文菜单")
        menu.add(0, 101, 0, "复制")
        menu.add(0, 102, 1, "删除")
    }

    override fun onContextItemSelected(item: MenuItem): Boolean = when (item.itemId) {
        101 -> {
            Toast.makeText(this, "复制", Toast.LENGTH_SHORT).show()
            true
        }
        else -> super.onContextItemSelected(item)
    }
}

// ---- 12 章第 6 节：Drawable 四件套的代码真身 ----

class Example22Drawables : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val root = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(32, 32, 32, 32)
        }

        // shape：GradientDrawable 圆角渐变底
        val shape = GradientDrawable().apply {
            shape = GradientDrawable.RECTANGLE
            cornerRadius = 16f
            colors = intArrayOf(0xFF6699FF.toInt(), 0xFF3366CC.toInt())
            orientation = GradientDrawable.Orientation.TL_BR
            setStroke(2, 0xFF113366.toInt())
        }
        root.addView(TextView(this).apply {
            text = "GradientDrawable（<shape> 的代码真身）"
            setTextColor(Color.WHITE)
            background = shape
            setPadding(24, 24, 24, 24)
        })

        // selector：按下变深
        val selector = StateListDrawable().apply {
            addState(intArrayOf(android.R.attr.state_pressed), ColorDrawable(0xFF3366CC.toInt()))
            addState(intArrayOf(android.R.attr.state_enabled), ColorDrawable(0xFF6699FF.toInt()))
        }
        root.addView(Button(this).apply {
            text = "StateListDrawable（按下试试）"
            setTextColor(Color.WHITE)
            background = selector
        })

        // clip：按 level 裁剪（0–10000）
        val clip = ClipDrawable(
            GradientDrawable().apply { setColor(0xFF4C4C1D.toInt()) },
            Gravity.LEFT,
            ClipDrawable.HORIZONTAL
        )
        root.addView(ImageView(this).apply {
            setImageDrawable(clip)
            setImageLevel(6000)               // 60% 展开
            minimumHeight = 48
        })

        // 逐帧：AnimationDrawable 要等挂载后再 start
        val frames = AnimationDrawable().apply {
            isOneShot = false
            addFrame(ColorDrawable(0xFFFF4444.toInt()), 400)
            addFrame(ColorDrawable(0xFF44FF44.toInt()), 400)
            addFrame(ColorDrawable(0xFF4444FF.toInt()), 400)
        }
        val frameView = View(this).apply { background = frames }
        root.addView(frameView, LinearLayout.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT, 64).apply {
            topMargin = 24
        })
        frameView.post { frames.start() }     // post：等挂载完成再启动

        setContentView(root)
    }
}
