;; lein-lab 的 project.clj —— Leiningen 工程的标准描述文件
;;
;; 对照根目录的 deps.edn（Clojure CLI）：两者只是工具不同，职责一致。
;; 常用命令：
;;   lein test                       跑 test/ 下全部测试
;;   lein run                        运行 :main 命名空间的 -main
;;   lein uberjar                    打"独立可执行"jar（内含全部依赖）
;;   lein with-profile +dev run      附加 :dev profile 运行
;;   java -jar target/uberjar/lein-lab-1.0.0-standalone.jar
(defproject lein-lab "1.0.0"
  :description "Leiningen 工作流实验：源码布局 / 测试 / profile / uberjar"
  :license {:name "Eclipse Public License - v 1.0"
            :url "https://www.eclipse.org/legal/epl-v10.html"}
  :dependencies [[org.clojure/clojure "1.12.6"]]
  ;; 源码与测试的默认目录就是 src/ 和 test/，按命名空间映射路径：
  ;; 命名空间 lein-lab.core  ->  src/lein_lab/core.clj（连字符转下划线）
  :main lein-lab.core
  :profiles {:dev     {:global-vars {*warn-on-reflection* true}
                       :jvm-opts ["-Xmx512m"]}
             :uberjar {:aot :all}}
  :target-path "target")
