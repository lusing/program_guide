plugins {
    kotlin("jvm")
    application   // 提供 run 任务与可执行 jar 的 Main-Class 清单
}

kotlin {
    jvmToolchain(21)
}

dependencies {
    implementation(project(":lib"))          // 多模块依赖：app 用 lib
    testImplementation(kotlin("test"))
}

application {
    mainClass.set("MainKt")
}

tasks.test {
    useJUnitPlatform()
}

// fat jar：把 runtimeClasspath 全部解包进一个可 `java -jar` 直跑的包
val appAllJar = tasks.register<Jar>("appAllJar") {
    archiveBaseName.set("app")
    archiveClassifier.set("all")
    manifest { attributes["Main-Class"] = application.mainClass.get() }
    duplicatesStrategy = DuplicatesStrategy.EXCLUDE
    from(sourceSets.main.get().output)
    from(configurations.runtimeClasspath.get().map { if (it.isDirectory) it else zipTree(it) }) {
        exclude("META-INF/*.SF", "META-INF/*.DSA", "META-INF/*.RSA")
    }
}

tasks.named("build") { dependsOn(appAllJar) }
