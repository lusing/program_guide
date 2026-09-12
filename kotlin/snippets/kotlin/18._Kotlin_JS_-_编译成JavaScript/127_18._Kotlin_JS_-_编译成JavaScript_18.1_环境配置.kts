kotlin {
    js {
        sourceSets {
            val main by getting {
                dependencies {
                    implementation(npm("react", "18.2.0"))
                    implementation(npm("react-dom", "18.2.0"))
                }
            }
        }
    }
}
