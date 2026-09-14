package guide.android.compose

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import guide.android.compose.samples.AdvancedNavigationSample
import guide.android.compose.samples.AdvancedRoomArchitectureSample
import guide.android.compose.samples.AdvancedViewModelStateFlowSample
import guide.android.compose.samples.AdvancedWorkManagerSample
import guide.android.compose.samples.ComposeCardListSample
import guide.android.compose.samples.ComposeCounterSample
import guide.android.compose.samples.ComposeFormValidationSample
import guide.android.compose.samples.ComposeLazyListSample
import guide.android.compose.samples.ComposeThemeToggleSample
import guide.android.compose.samples.JniStatusSample

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContent {
            Surface(color = MaterialTheme.colorScheme.background, modifier = Modifier.fillMaxSize()) {
                Column(modifier = Modifier.padding(16.dp)) {
                    ComposeCounterSample()
                    ComposeLazyListSample()
                    ComposeThemeToggleSample()
                    ComposeFormValidationSample()
                    ComposeCardListSample()
                    JniStatusSample()
                    AdvancedViewModelStateFlowSample()
                    AdvancedNavigationSample()
                    AdvancedRoomArchitectureSample()
                    AdvancedWorkManagerSample()
                }
            }
        }
    }
}
