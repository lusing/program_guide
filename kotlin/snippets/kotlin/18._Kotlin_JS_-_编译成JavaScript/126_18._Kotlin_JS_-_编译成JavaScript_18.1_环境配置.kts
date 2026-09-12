plugins {
    kotlin("js") version "1.9.24"
}

kotlin {
    js {
        browser {
            commonWebpackConfig {
                cssSupport {
                    enabled = true
                }
            }
        }
        binaries.executable()
    }
}

dependencies {
    implementation(kotlin("stdlib-js"))
    // React 依赖（可选）
    implementation("org.jetbrains.kotlin-wrappers:kotlin-react:18.2.0-pre.610")
    implementation("org.jetbrains.kotlin-wrappers:kotlin-react-dom:18.2.0-pre.610")
}
