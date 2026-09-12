tasks {
    // 开发构建
    named("browserDevelopmentWebpack") {
        doLast {
            println("Development build complete!")
        }
    }
    
    // 生产构建
    named("browserProductionWebpack") {
        doLast {
            println("Production build complete!")
        }
    }
    
    // 开发服务器
    named("browserDevelopmentRun") {
        doFirst {
            println("Starting dev server at http://localhost:8080")
        }
    }
}
