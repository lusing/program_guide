plugins {
    kotlin("jvm")   // 版本继承根目录，多模块版本不漂移
}

kotlin {
    jvmToolchain(21)
}

// implementation：内部实现细节，不泄漏给下游（对照 api：会出现在下游的编译 classpath）
dependencies {
    testImplementation(kotlin("test"))
}

tasks.test {
    useJUnitPlatform()
}
