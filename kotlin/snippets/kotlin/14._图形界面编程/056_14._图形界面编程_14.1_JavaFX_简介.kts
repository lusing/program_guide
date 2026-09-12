plugins {
    kotlin("jvm") version "1.9.24"
}

repositories {
    mavenCentral()
}

dependencies {
    implementation(kotlin("stdlib"))
    implementation("org.openjfx:javafx-controls:21:win")
    implementation("org.openjfx:javafx-fxml:21:win")
}

tasks.named<JavaExec>("run") {
    val jvmArgs = listOf(
        "--add-modules", "javafx.controls,javafx.graphics",
        "--add-opens", "javafx.graphics/javafx.scene=ALL-UNNAMED"
    )
    this.jvmArgs = jvmArgs
}
