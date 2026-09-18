rootProject.name = "kt-gradle-demo"

// 依赖仓库集中声明（现代写法）：模块里不再写 repositories
dependencyResolutionManagement {
    repositories {
        mavenCentral()
    }
}

include("lib", "app")
