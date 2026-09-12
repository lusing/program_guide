plugins {
    kotlin("js") version "1.9.24"
}

kotlin {
    js {
        nodejs {
            binaries.executable()
        }
    }
}

dependencies {
    implementation(kotlin("stdlib-js"))
}
