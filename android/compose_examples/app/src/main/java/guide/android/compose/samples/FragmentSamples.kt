package guide.android.compose.samples

// 第 15 章 Fragment 与任务栈示例（androidx.fragment）
// 本文件演示：newInstance+arguments 传参、两条生命周期链、FragmentResult 通信、
// 事务与回退栈。宿主 MainActivity 是 FragmentActivity，本示例用 AndroidView
// 承载一个 FrameLayout 容器再往里 commit Fragment。

import android.graphics.Color
import android.os.Bundle
import android.util.Log
import android.view.Gravity
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.Button
import android.widget.FrameLayout
import android.widget.LinearLayout
import android.widget.TextView
import android.widget.Toast
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Button
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.dp
import androidx.compose.ui.viewinterop.AndroidView
import androidx.core.os.bundleOf
import androidx.fragment.app.Fragment
import androidx.fragment.app.FragmentActivity
import androidx.fragment.app.commit

private const val TAG = "FragmentLifecycle"

/** 生命周期打点 + arguments 传参 + FragmentResult 发送端 */
class LifecycleFragment : Fragment() {

    private val title: String
        get() = requireArguments().getString(ARG_TITLE) ?: "?"

    companion object {
        private const val ARG_TITLE = "title"
        const val RESULT_KEY = "fragment_pick"

        // 系统重建只认无参构造：参数必须走 arguments，工厂函数是标准姿势
        fun newInstance(title: String): LifecycleFragment = LifecycleFragment().apply {
            arguments = bundleOf(ARG_TITLE to title)
        }
    }

    override fun onAttach(context: android.content.Context) {
        super.onAttach(context); Log.d(TAG, "[$title] onAttach")
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState); Log.d(TAG, "[$title] onCreate")
    }

    override fun onCreateView(
        inflater: LayoutInflater, container: ViewGroup?, savedInstanceState: Bundle?
    ): View {
        Log.d(TAG, "[$title] onCreateView")
        // 无 XML 资源的教学工程：代码建根视图（真实工程主流是 inflate 布局）
        return LinearLayout(requireContext()).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER
            setBackgroundColor(0xFFE8F0FE.toInt())
            addView(TextView(requireContext()).apply {
                text = title
                textSize = 22f
            })
            addView(TextView(requireContext()).apply {
                text = "替换我 + BACK 试试小循环（onDestroyView→onCreateView）"
                setPadding(24, 8, 24, 8)
                gravity = Gravity.CENTER
            })
            addView(Button(requireContext()).apply {
                text = "向宿主发 Result"
                setOnClickListener {
                    // ② Fragment → Activity：FragmentResult API
                    parentFragmentManager.setFragmentResult(
                        RESULT_KEY, bundleOf("msg" to "$title 说：收到请回答"))
                }
            })
        }
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState); Log.d(TAG, "[$title] onViewCreated")
        // 视图就绪的最早安全时机（旧 onActivityCreated 的现代替身）
    }

    override fun onStart() { super.onStart(); Log.d(TAG, "[$title] onStart") }
    override fun onResume() { super.onResume(); Log.d(TAG, "[$title] onResume") }
    override fun onPause() { super.onPause(); Log.d(TAG, "[$title] onPause") }
    override fun onStop() { super.onStop(); Log.d(TAG, "[$title] onStop") }
    override fun onDestroyView() { super.onDestroyView(); Log.d(TAG, "[$title] onDestroyView") }
    override fun onDestroy() { super.onDestroy(); Log.d(TAG, "[$title] onDestroy") }
    override fun onDetach() { super.onDetach(); Log.d(TAG, "[$title] onDetach") }
}

/** Compose 侧宿主：AndroidView 挖一个容器，按钮驱动事务 */
@Composable
fun FragmentTransactionSample() {
    val activity = LocalContext.current as? FragmentActivity ?: return
    val counter = remember { intArrayOf(0) }
    val containerId = remember { View.generateViewId() }

    // 接收端：一次注册，任意子 Fragment 都能发
    activity.supportFragmentManager.setFragmentResultListener(
        LifecycleFragment.RESULT_KEY, activity
    ) { _, bundle ->
        Toast.makeText(activity, bundle.getString("msg"), Toast.LENGTH_SHORT).show()
    }

    Column(Modifier.padding(vertical = 8.dp)) {
        Text("Fragment 事务与回退栈（第 15 章）", Modifier.padding(bottom = 4.dp))
        Row {
            Button(onClick = {
                counter[0]++
                activity.supportFragmentManager.commit {
                    setReorderingAllowed(true)
                    replace(containerId, LifecycleFragment.newInstance("第 ${counter[0]} 个"))
                    addToBackStack(null)          // 进回退栈：BACK 能退回上一个
                }
            }) { Text("replace + 入栈") }
            androidx.compose.foundation.layout.Spacer(Modifier.padding(4.dp))
            Button(onClick = { activity.supportFragmentManager.popBackStack() }) {
                Text("popBackStack")
            }
        }
        Text(
            "看 logcat 标签 $TAG：replace→onDestroyView（小循环）、" +
                "BACK→onCreateView 回来、Activity 旋转/退出→全链走完",
            Modifier.padding(top = 4.dp)
        )
        // MainActivity 外层 verticalScroll：互操作视图必须定高
        AndroidView(
            factory = { ctx ->
                FrameLayout(ctx).apply {
                    id = containerId
                    setBackgroundColor(Color.LTGRAY)
                    // 首个 Fragment：不进回退栈
                    activity.supportFragmentManager.commit {
                        setReorderingAllowed(true)
                        add(containerId, LifecycleFragment.newInstance("第 0 个"))
                    }
                }
            },
            modifier = Modifier
                .fillMaxWidth()
                .height(220.dp)
                .padding(top = 8.dp)
        )
    }
}
