package guide.android.compose

import android.os.Bundle
import androidx.activity.compose.setContent
import androidx.fragment.app.FragmentActivity
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import guide.android.compose.samples.AdvancedNavigationSample
import guide.android.compose.samples.AdvancedRoomArchitectureSample
import guide.android.compose.samples.AdvancedUiStateSample
import guide.android.compose.samples.AdvancedViewModelStateFlowSample
import guide.android.compose.samples.AdvancedWorkManagerSample
import guide.android.compose.samples.FragmentTransactionSample
import guide.android.compose.samples.AnimCustomTypeSample
import guide.android.compose.samples.AnimFavButtonSample
import guide.android.compose.samples.AnimManualSample
import guide.android.compose.samples.AnimShimmerSample
import guide.android.compose.samples.AnimSpecCompareSample
import guide.android.compose.samples.AnimTransitionSample
import guide.android.compose.samples.ComposeCardListSample
import guide.android.compose.samples.ComposeCounterSample
import guide.android.compose.samples.ComposeFormValidationSample
import guide.android.compose.samples.ComposeInteropSample
import guide.android.compose.samples.ComposeLazyListSample
import guide.android.compose.samples.ComposeLayoutRowSample
import guide.android.compose.samples.ComposeThemeToggleSample
import guide.android.compose.samples.ComposeWeightSample
import guide.android.compose.samples.DrawCacheSample
import guide.android.compose.samples.DrawCanvasSample
import guide.android.compose.samples.DrawLayerSample
import guide.android.compose.samples.EcoManualDiSample
import guide.android.compose.samples.GestureAnchoredDragSample
import guide.android.compose.samples.GestureDragSample
import guide.android.compose.samples.GestureFlingSample
import guide.android.compose.samples.GestureNestedScrollSample
import guide.android.compose.samples.GestureTapSample
import guide.android.compose.samples.GestureTransformSample
import guide.android.compose.samples.JniStatusSample
import guide.android.compose.samples.BionicFileSample
import guide.android.compose.samples.BionicStlSample
import guide.android.compose.samples.BionicSystemSample
import guide.android.compose.samples.BionicUidSample
import guide.android.compose.samples.JniDeepArraySample
import guide.android.compose.samples.JniDeepBufferSample
import guide.android.compose.samples.JniDeepExceptionSample
import guide.android.compose.samples.JniDeepFieldMethodSample
import guide.android.compose.samples.JniDeepReferenceSample
import guide.android.compose.samples.JniDeepStringSample
import guide.android.compose.samples.JniLogSample
import guide.android.compose.samples.MediaBitmapSample
import guide.android.compose.samples.MediaNeonSample
import guide.android.compose.samples.MediaProbeSample
import guide.android.compose.samples.NativeThreadSample
import guide.android.compose.samples.SocketEchoSample
import guide.android.compose.samples.SocketLocalEchoSample
import guide.android.compose.samples.LayoutBaselineSample
import guide.android.compose.samples.LayoutCustomColumnSample
import guide.android.compose.samples.LayoutIntrinsicSample
import guide.android.compose.samples.StateDerivedSample
import guide.android.compose.samples.StateHolderSample
import guide.android.compose.samples.StateKeySample
import guide.android.compose.samples.StateRememberUpdatedSample
import guide.android.compose.samples.StateSaveableSample
import guide.android.compose.samples.StateSnapshotFlowSample
import guide.android.compose.samples.StateStabilitySample
import guide.android.compose.samples.UiAnimationTransitionSample
import guide.android.compose.samples.UiAnimationValueSample
import guide.android.compose.samples.UiAnimationVisibilitySample
import guide.android.compose.samples.UiButtonsSample
import guide.android.compose.samples.UiDialogSample
import guide.android.compose.samples.UiInfinitePulseSample
import guide.android.compose.samples.UiListKeySample
import guide.android.compose.samples.UiScaffoldSample
import guide.android.compose.samples.UiSelectionSample
import guide.android.compose.samples.UiSideEffectSample
import guide.android.compose.samples.UiThemeCustomizeSample

// FragmentActivity（ComponentActivity 的子类）：第 15 章 Fragment 事务需要 supportFragmentManager
class MainActivity : FragmentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContent {
            Surface(color = MaterialTheme.colorScheme.background, modifier = Modifier.fillMaxSize()) {
                // verticalScroll：示例总数已超一屏，整列可滚动
                //（嵌在其中的 LazyColumn/Scaffold 必须定高，见第 19 章第 8 节）
                Column(
                    modifier = Modifier
                        .fillMaxSize()
                        .verticalScroll(rememberScrollState())
                        .padding(16.dp)
                ) {
                    // 第 15 章 Fragment 与任务栈示例（FragmentSamples.kt）
                    FragmentTransactionSample()
                    // 第 19 章基础示例（ComposeSamples.kt）
                    ComposeCounterSample()
                    ComposeLazyListSample()
                    ComposeThemeToggleSample()
                    ComposeFormValidationSample()
                    ComposeCardListSample()
                    ComposeLayoutRowSample()
                    ComposeWeightSample()
                    ComposeInteropSample()
                    JniStatusSample()
                    // 第 20 章组件与交互示例（UiSamples.kt）
                    UiButtonsSample()
                    UiSelectionSample()
                    UiScaffoldSample()
                    UiDialogSample()
                    UiListKeySample()
                    UiSideEffectSample()
                    UiAnimationValueSample()
                    UiAnimationTransitionSample()
                    UiAnimationVisibilitySample()
                    UiInfinitePulseSample()
                    UiThemeCustomizeSample()
                    // 第 21 章架构示例（AdvancedSamples.kt）
                    AdvancedViewModelStateFlowSample()
                    AdvancedNavigationSample()
                    AdvancedRoomArchitectureSample()
                    AdvancedWorkManagerSample()
                    AdvancedUiStateSample()
                    // 第 22 章状态与重组示例（StateSamples.kt）
                    StateSaveableSample()
                    StateStabilitySample()
                    StateKeySample()
                    StateDerivedSample()
                    StateSnapshotFlowSample()
                    StateRememberUpdatedSample()
                    StateHolderSample()
                    // 第 23 章自定义布局与绘制示例（LayoutDrawSamples.kt）
                    LayoutBaselineSample()
                    LayoutCustomColumnSample()
                    LayoutIntrinsicSample()
                    DrawCanvasSample()
                    DrawLayerSample()
                    DrawCacheSample()
                    // 第 24 章动画进阶示例（AnimationSamples.kt）
                    AnimSpecCompareSample()
                    AnimTransitionSample()
                    AnimManualSample()
                    AnimCustomTypeSample()
                    AnimShimmerSample()
                    AnimFavButtonSample()
                    // 第 25 章手势示例（GestureSamples.kt）
                    GestureTapSample()
                    GestureDragSample()
                    GestureTransformSample()
                    GestureAnchoredDragSample()
                    GestureNestedScrollSample()
                    GestureFlingSample()
                    // 第 26 章生态示例（EcosystemSamples.kt）
                    EcoManualDiSample()
                    // 第 27–32 章原生线示例（JniSamples.kt + cpp/ 六个文件）
                    JniLogSample()
                    JniDeepStringSample()
                    JniDeepArraySample()
                    JniDeepBufferSample()
                    JniDeepFieldMethodSample()
                    JniDeepExceptionSample()
                    JniDeepReferenceSample()
                    BionicSystemSample()
                    BionicUidSample()
                    BionicFileSample()
                    BionicStlSample()
                    NativeThreadSample()
                    SocketEchoSample()
                    SocketLocalEchoSample()
                    MediaBitmapSample()
                    MediaNeonSample()
                    MediaProbeSample()
                }
            }
        }
    }
}
