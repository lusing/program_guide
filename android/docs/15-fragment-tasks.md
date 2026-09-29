# 15 · Fragment 与任务栈

> 对应示例：`compose_examples/.../samples/FragmentSamples.kt`（androidx.fragment，需 Gradle 工程——`examples/` 的裸 android.jar 里没有 AndroidX）。取材：李刚《疯狂Android讲义（第3版）》4.3.3（加载模式）、4.4–4.5（Fragment 全套）。04 章讲了 Activity 的生命周期，本章补上它缺的另一半：**页面模块化（Fragment）与栈调度（加载模式）**。

## 1. Fragment 是什么，为什么要有它

Fragment 是 **Activity 的模块化子单元**：有自己的生命周期、能收自己的输入事件、有自己的（可选）布局，但必须寄生在 Activity 里——宿主暂停它暂停、宿主销毁它销毁（书 4.4.1）。

它出生（Android 3.0）的直接动机是**平板**：新闻应用在平板上"左列表右详情"一屏装下，在手机上拆成两屏。用 Fragment 把两块各封成一个模块，同一对组件在平板上并排摆、在手机上分两个 Activity 各摆一个——UI 模块一次编写，布局形态按屏裁剪。

十年后的定位清单（先知道都在哪遇见它）：

- ViewPager2 的页（`FragmentStateAdapter`）
- Navigation（NavGraph 的目的地——21 章 Compose 版同思想）
- BottomSheetDialogFragment、对话框
- 存量工程的 Activity 壳 + 多 Fragment 切换架构（"单 Activity 多 Fragment"曾是主流架构）

Compose 时代 Fragment 的地盘被 `NavHost` + 组合函数蚕食，但混合工程（老页面 Fragment、新页面 Compose）里它仍是活的——这也是教程用 androidx Fragment 而不是书里已被删除的 `android.app.Fragment` 讲这一章的原因。

## 2. 最小 Fragment 与 androidx 坐标

```kotlin
class LifecycleFragment : Fragment() {
    override fun onCreateView(
        inflater: LayoutInflater, container: ViewGroup?, savedInstanceState: Bundle?
    ): View {
        // 本教程无 XML 资源，直接代码建根视图；真实工程主流是
        // inflater.inflate(R.layout.fragment_xxx, container, false)
        return TextView(requireContext()).apply { text = "I am a Fragment" }
    }
}
```

创建 Fragment 与创建 Activity 几乎同构：回调方法名一致，多出 `onCreateView`（返回 Fragment 的根视图）。书 4.4.2 说的"三个最常重写的方法"：`onCreate`（初始化与 UI 无关的状态）、`onCreateView`（建视图）、`onPause`（持久化收尾）。

**androidx 校准**（书写作时只有 framework Fragment，全变了）：

| 书里（android.app.Fragment，已死） | 今天（androidx.fragment） |
|---|---|
| `Activity.getFragmentManager()` | `FragmentActivity.getSupportFragmentManager()`（宿主必须继承 FragmentActivity/AppCompatActivity） |
| `android.app.ListFragment` | 已废弃：自己 RecyclerView，或用 `RecyclerViewFragment` 自封装 |
| `onActivityCreated()` | **已废弃**：逻辑挪进 `onViewCreated(view, savedInstanceState)` |
| `getActivity()` 可空返回 | `getActivity()`（可空）/ **`requireActivity()`**（非空，为空直接抛） |

## 3. FragmentManager 与事务

往界面上挂 Fragment 是一次**事务**（`FragmentTransaction`）——和数据库事务同语义：攒一批 add/replace/remove，一次 `commit()` 生效（书 4.4.4）：

```kotlin
supportFragmentManager.commit {                     // fragment-ktx 的扩展：begin+commit 一对
    setReorderingAllowed(true)                     // 允许系统重排合并事务（动画与状态恢复的前提）
    replace(R.id.container, ArgsFragment.newInstance("第 3 页"))
    addToBackStack(null)                           // 进回退栈：BACK 键能退回替换前的状态
}
```

`replace` = remove 旧 + add 新；不 `addToBackStack` 就一去不回。回退栈的栈是**宿主 Activity 的**，`popBackStack()` 手工弹（宿主返回键的默认行为就是它）。`FragmentManager` 另两件常事：`findFragmentById/findFragmentByTag` 找孩子；`addOnBackStackChangedListener` 听栈变。

**commit 家族四兄弟**（面试与事故现场都在这）：

| 方法 | 语义 | 什么时候用 |
|---|---|---|
| `commit()` | 异步提交（进主线程消息队列） | 默认答案 |
| `commitNow()` | 同步执行完再返回 | 需要立即可见/配合 `setPrimaryNavigationFragment` |
| `commitAllowingStateLoss()` | 状态保存后也允许提交（**丢状态换不崩**） | 已经 onSaveInstanceState 之后必须提交时 |
| `executePendingTransactions()` | 把已 commit 的立刻刷完 | 少用 |

书里"兼顾屏幕分辨率的应用"（`values-large/refs.xml` 让同一布局 ID 在大屏指向双栏版）是 Fragment 使命的完整示范——今天等价物是 `values-sw600dp` 布局变体 + 窗口大小类（21 章自适应布局），思想未变：**一份模块，多种编排**。

## 4. Fragment 的生命周期：两条链

Fragment 的生命周期是 04 章 Activity 那条的**加粗版**（书 4.5 的十一个回调按序）：

```text
onAttach → onCreate → onCreateView → onViewCreated → onStart → onResume
        ── 运行 ──
onPause → onStop → onDestroyView → onDestroy → onDetach
```

真正的关键是**两条链的分离**——Fragment 自己的生命周期和**它的 View 的生命周期**不是一回事：

- `onDestroyView` 销毁视图但**不销毁 Fragment**——ViewPager2 翻页把页面刷掉再翻回来，走的是 `onDestroyView → onCreateView` 的**小循环**，Fragment 实例（及其字段）全程活着
- 所以观察 View 级数据要用 **`viewLifecycleOwner`**（视图死了自动取消观察），用 `this`（Fragment 自己）当 LifecycleOwner 是内存泄漏与"视图没了还在更新"的经典来源
- 书里 `onActivityCreated` 的位置由 `onViewCreated(view, savedInstanceState)` 顶替——视图就绪、能安全 `view.findViewById` 的最早时机

与宿主的联动一句诀：**宿主的每个生命周期事件都会广播给所有子 Fragment**——Activity `onPause` → 所有 Fragment `onPause`；反过来 Fragment 自己的进退（replace/addToBackStack）只影响自己走小循环，宿主不动。

## 5. 通信的三条正道

Fragment 没有 Context 地位、不该自己抓 Activity 的引用乱调——通信有固定轨道（书 4.4.3 的思路 + 现代替换）：

**① Activity → Fragment：`arguments` Bundle**。永远配 `newInstance` 工厂（**构造参数是陷阱**：系统重建 Fragment 走无参构造，写在构造器里的参数直接蒸发——`FragmentSamples.kt` 里是标准写法）：

```kotlin
class ArgsFragment : Fragment() {
    private val title get() = requireArguments().getString("title")!!

    companion object {
        fun newInstance(title: String) = ArgsFragment().apply {
            arguments = bundleOf("title" to title)      // 重建后仍在
        }
    }
}
```

**② Fragment → Activity / Fragment ↔ Fragment：`FragmentResult` API**（替代书里"定义回调接口 + Activity 实现"的老套路，类型安全零接口样板）：

```kotlin
// 接收端（Activity 或另一个 Fragment，一次注册）
supportFragmentManager.setFragmentResultListener("pick") { _, bundle ->
    toast("收到：${bundle.getString("name")}")
}
// 发送端（任意 Fragment）
parentFragmentManager.setFragmentResult("pick", bundleOf("name" to "Kotlin"))
```

**③ 状态共享：ViewModel 挂宿主**——`activityViewModels()` 让同宿主的多个 Fragment 看同一份数据（21 章 ViewModel 的天然延伸），双栏"左选右更"的标准解。书里"Activity 实现回调接口"的做法在读老代码时仍会遇到，认识即可。

方向反过来（Fragment 找宿主）：`requireActivity()`。但把它强转成具体 Activity 再调业务方法 = 耦合，宁可走 ②③。

## 6. 任务栈与四种加载模式

06 章第 6 节立过"Task = Activity 栈"的骨架，这里把**加载模式**补全（书 4.3.3，四模式一张矩阵）：

| launchMode | 语义 | 目标已在栈顶 | 目标已在栈内（非顶） | 目标不存在 |
|---|---|---|---|---|
| `standard`（默认） | 来一次建一次 | 新建实例 | 新建实例 | 新建实例 |
| `singleTop` | 栈顶去重 | **复用 + `onNewIntent`** | 新建实例 | 新建实例 |
| `singleTask` | 栈内唯一 | 同 singleTop | **清掉它上面的所有 Activity，转到顶 + `onNewIntent`** | 新建（可能配 `taskAffinity` 开新栈） |
| `singleInstance` | 全局唯一 | 同上 | 同上（且独占一个 Task） | **新建 Task 装它，该栈只有它一个** |

两个配套概念：**`onNewIntent`**——复用而非新建时，新 Intent 从这个回调进来（06 章 Contact 示例用过；**singleTop 复用时旧的 extras 不会自动清**，处理完记得 `setIntent`）；**`taskAffinity`**——Activity 想进的栈的"户籍"，singleTask + affinity 组合能把页面归到独立栈。

**2026 校准**：四模式仍是面试必考、存量必读，但新代码的多数诉求已有更精细的工具——通知点进详情页用 `FLAG_ACTIVITY_CLEAR_TOP | SINGLE_TOP` 组合、多文档窗口用 document launch flags、"全局唯一"的地图/通话页场景在App 里越来越少（大多内嵌化）。原则不变：**先问"这个页面在回退栈里该出现几次"，再挑最弱的那个模式**——standard 能对就 standard，去重需求优先 singleTop，动用 singleTask/singleInstance 前写注释说明为什么。

## 7. 常见坑

**构造函数传参，旋转屏幕后消失**：系统重建只认无参构造 + `arguments`。参数一律走 `newInstance` + `setArguments`，字段只是 arguments 的缓存视图。

**在 `onCreateView` 里 `requireActivity()` 拿宿主当 Context 建 UI**：能跑，但 `onAttach` 之前没有宿主、`onDetach` 之后再有回调就炸——Fragment 里建 View 统一 `requireContext()`。

**用 `this` 而不是 `viewLifecycleOwner` 观察数据**：视图销毁后观察还挂 在 Fragment 上，轻则泄漏重则"更新一个已死的 View"。规则：**碰 View 的观察给 viewLifecycleOwner，不碰 View 的才给 this**。

**`commit()` 后立刻 `findFragmentById` 拿不到**：commit 是异步的——要同步结果用 `commitNow()`，或把后续逻辑放进事务后的同一消息。

**`onSaveInstanceState` 之后 `commit()` 抛 `IllegalStateException`**：Activity 状态已存档、事务丢了没人恢复——要么在 `onStop` 前完成提交，要么明确可丢状态用 `commitAllowingStateLoss()`。

**ViewPager2 配 `FragmentPagerAdapter`**：错搭档——FragmentPagerAdapter 的页面**永不销毁视图**（内存常驻），FragmentStateAdapter 才是翻页场景的正解（现页面邻页保留、远处销毁走小循环）。

**singleTask 想当然"全局单例"**：默认 affinity 下它只是**本 Task 内**唯一；真全局唯一是 singleInstance。跨应用复用（书里 exported + 隐式 Intent 的例子）今天还要 `exported="true"` 显式声明（API 31 起强制）。

## 8. 实战建议

- 新项目纯 Compose 不必引入 Fragment；混合/迁移期，Fragment 是新老页面的**接缝层**（`ComposeView` 进 Fragment，或 `AndroidView` 包 FragmentContainerView）
- 页面模块的默认边界感：一块可独立复用的 UI + 自己的状态 + 明确的输入（arguments）输出（result/ViewModel）→ 值得一个 Fragment
- 通信三选一：参数进（arguments）、事件出（FragmentResult）、状态共享（activityViewModels）——除此之外的"直接互相引用"都算越轨
- 生命周期观察一律先问"我在观察的东西属于视图还是属于数据"，再选 owner
- 加载模式只在清单里声明一次、写一行 why；运行时拼 launchFlags 组合时先在纸上画栈——Task 行为靠脑补必错
- 下一章进多媒体：Fragment 的双链条生命周期在"播放器页退出即停"的场景里立刻用上

---
上一章：[14 动画三体系](14-view-animations.md) ｜ 下一章：[16 多媒体开发](16-media.md) ｜ 返回：[README](../README.md)
