;; project.clj - Leiningen 工程描述（Windows 侧验证入口）
;; 与 deps.edn（Clojure CLI，macOS/Linux 侧）声明同一组依赖，两边等效。
;; 运行方式见 build.ps1：lein 负责解析依赖并给出 classpath，
;; 示例脚本统一由 `java -cp <classpath> clojure.main <file>` 执行。
(defproject clojure-guide "1.0.0"
  :description "Clojure 编程指南——示例与验证工程"
  :license {:name "Eclipse Public License - v 1.0"
            :url "https://www.eclipse.org/legal/epl-v10.html"}
  :dependencies [[org.clojure/clojure "1.12.6"]
                 [org.clojure/core.async "1.9.865"]
                 [ring/ring-core "1.15.5"]
                 [ring/ring-jetty-adapter "1.15.5"]]
  :source-paths ["examples"]
  :target-path "target")
