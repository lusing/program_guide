package guide.android.compose

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
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
import guide.android.compose.samples.ComposeCardListSample
import guide.android.compose.samples.ComposeCounterSample
import guide.android.compose.samples.ComposeFormValidationSample
import guide.android.compose.samples.ComposeLazyListSample
import guide.android.compose.samples.ComposeLayoutRowSample
import guide.android.compose.samples.ComposeThemeToggleSample
import guide.android.compose.samples.ComposeWeightSample
import guide.android.compose.samples.JniStatusSample
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

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContent {
            Surface(color = MaterialTheme.colorScheme.background, modifier = Modifier.fillMaxSize()) {
                // verticalScroll：示例总数已超一屏，整列可滚动
                //（嵌在其中的 LazyColumn/Scaffold 必须定高，见第 12 章第 8 节）
                Column(
                    modifier = Modifier
                        .fillMaxSize()
                        .verticalScroll(rememberScrollState())
                        .padding(16.dp)
                ) {
                    // 第 12 章基础示例（ComposeSamples.kt）
                    ComposeCounterSample()
                    ComposeLazyListSample()
                    ComposeThemeToggleSample()
                    ComposeFormValidationSample()
                    ComposeCardListSample()
                    ComposeLayoutRowSample()
                    ComposeWeightSample()
                    JniStatusSample()
                    // 第 13 章组件与交互示例（UiSamples.kt）
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
                    // 第 14 章架构示例（AdvancedSamples.kt）
                    AdvancedViewModelStateFlowSample()
                    AdvancedNavigationSample()
                    AdvancedRoomArchitectureSample()
                    AdvancedWorkManagerSample()
                    AdvancedUiStateSample()
                }
            }
        }
    }
}
