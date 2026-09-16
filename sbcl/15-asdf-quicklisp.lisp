;;;; ============================================================
;;;; 15-asdf-quicklisp.lisp — ASDF 系统定义与 Quicklisp
;;;; ============================================================
;;;;
;;;; 本例程演示：
;;;;   1. ASDF 简介与系统定义
;;;;   2. 创建 .asd 文件
;;;;   3. 加载与编译系统
;;;;   4. Quicklisp 安装与使用
;;;;   5. 常用 Quicklisp 命令
;;;;   6. 项目结构最佳实践
;;;;   7. 创建可发布的项目
;;;;   8. 常用第三方库推荐
;;;;
;;;; 运行方式：sbcl --script 15-asdf-quicklisp.lisp
;;;; ============================================================

#.(progn (require :asdf) nil)

;;; ----------------------------------------------------------
;;; 1. ASDF 简介
;;; ----------------------------------------------------------

(format t "~%=== ASDF 简介 ===~%")

;; ASDF（Another System Definition Facility）是 Common Lisp
;; 的标准系统定义工具，类似于 Makefile 或 package.json
;;
;; 功能：
;;   - 定义项目的文件结构和依赖关系
;;   - 编译和加载 Lisp 系统
;;   - 管理包和模块
;;
;; ASDF 已内置在 SBCL 中

;; 查看 ASDF 版本
(format t "ASDF 版本: ~A~%" (asdf:asdf-version))

;; 加载 ASDF（通常已自动加载）
(require :asdf)


;;; ----------------------------------------------------------
;;; 2. 创建 .asd 文件
;;; ----------------------------------------------------------

(format t "~%=== 系统定义 ===~%")

;; 一个典型的 .asd 文件（my-project.asd）：
;;
;; (asdf:defsystem #:my-project
;;   :description "我的项目描述"
;;   :author "作者名 <email@example.com>"
;;   :license "MIT"
;;   :version "0.1.0"
;;   :depends-on (#:cl-ppcre #:alexandria)
;;   :serial t
;;   :components ((:module "src"
;;                 :serial t
;;                 :components ((:file "package")
;;                              (:file "utils")
;;                              (:file "config")
;;                              (:file "models")
;;                              (:file "handlers")
;;                              (:file "main"))))
;;   :in-order-to ((asdf:test-op (asdf:test-op #:my-project/tests))))
;;
;; (asdf:defsystem #:my-project/tests
;;   :depends-on (#:my-project #:fiveam)
;;   :serial t
;;   :components ((:module "tests"
;;                 :serial t
;;                 :components ((:file "package")
;;                              (:file "test-main"))))
;;   :perform (asdf:test-op (op c)
;;              (uiop:symbol-call :my-project/tests :run-tests)))

;; 创建一个示例系统定义文件
(with-open-file (out "example-project.asd"
                     :direction :output
                     :if-exists :supersede)
  (format out ";;;; example-project.asd~%")
  (format out "~%")
  (format out "(asdf:defsystem #:example-project~%")
  (format out "  :description \"示例项目\"~%")
  (format out "  :author \"Lisper <lisp@example.com>\"~%")
  (format out "  :license \"MIT\"~%")
  (format out "  :version \"0.1.0\"~%")
  (format out "  :serial t~%")
  (format out "  :components ((:module \"src\"~%")
  (format out "                :serial t~%")
  (format out "                :components ((:file \"package\")~%")
  (format out "                             (:file \"utils\")~%")
  (format out "                             (:file \"main\")))))~%"))

(format t "已创建 example-project.asd~%")

;; 创建示例源文件
(ensure-directories-exist "src/")

(with-open-file (out "src/package.lisp"
                     :direction :output
                     :if-exists :supersede)
  (format out "(defpackage #:example-project~%")
  (format out "  (:use #:cl)~%")
  (format out "  (:export #:main #:greet))~%"))

(with-open-file (out "src/utils.lisp"
                     :direction :output
                     :if-exists :supersede)
  (format out "(in-package #:example-project)~%")
  (format out "~%")
  (format out "(defun greet (name)~%")
  (format out "  (format nil \"你好，~~A！\" name))~%"))

(with-open-file (out "src/main.lisp"
                     :direction :output
                     :if-exists :supersede)
  (format out "(in-package #:example-project)~%")
  (format out "~%")
  (format out "(defun main ()~%")
  (format out "  (format t \"~~A~~%\" (greet \"世界\")))~%"))

(format t "已创建示例源文件~%")


;;; ----------------------------------------------------------
;;; 3. 加载与编译系统
;;; ----------------------------------------------------------

(format t "~%=== 加载系统 ===~%")

;; 将当前目录添加到 ASDF 搜索路径
(push (truename ".") asdf:*central-registry*)

;; 加载系统
;; (asdf:load-system :example-project)

;; 编译系统
;; (asdf:compile-system :example-project)

;; 测试系统
;; (asdf:test-system :example-project)

;; 查看系统信息
;; (asdf:find-system :example-project)

;; 使用 ql:quickload（如果安装了 Quicklisp）
;; (ql:quickload :example-project)

(format t "系统加载命令见注释~%")

;; 清理示例文件
(dolist (f '("example-project.asd" "src/package.lisp"
             "src/utils.lisp" "src/main.lisp"))
  (when (probe-file f)
    (delete-file f)))


;;; ----------------------------------------------------------
;;; 4. Quicklisp 安装与使用
;;; ----------------------------------------------------------

(format t "~%=== Quicklisp ===~%")

;; Quicklisp 是 Common Lisp 的包管理器
;;
;; 安装步骤：
;;   1. 下载 quicklisp.lisp:
;;      curl -O https://beta.quicklisp.org/quicklisp.lisp
;;
;;   2. 在 SBCL 中安装:
;;      sbcl --load quicklisp.lisp
;;      (quicklisp-quickstart:install)
;;      (ql:add-to-init-file)  ; 添加到 ~/.sbclrc
;;
;;   3. 之后每次启动 SBCL 都会自动加载 Quicklisp

;; 检查 Quicklisp 是否已安装
(format t "Quicklisp 已安装: ~A~%"
        (if (find-package :ql)
            "是"
            "否（需要手动安装）"))


;;; ----------------------------------------------------------
;;; 5. 常用 Quicklisp 命令
;;; ----------------------------------------------------------

(format t "~%=== Quicklisp 命令 ===~%")

;; 加载库（自动下载并安装）
;; (ql:quickload :cl-ppcre)        ; 正则表达式
;; (ql:quickload :alexandria)       ; 工具函数库
;; (ql:quickload :bordeaux-threads) ; 可移植线程
;; (ql:quickload :hunchentoot)      ; Web 服务器
;; (ql:quickload :drakma)           ; HTTP 客户端
;; (ql:quickload :cl-json)          ; JSON 解析
;; (ql:quickload :postmodern)       ; PostgreSQL 客户端
;; (ql:quickload :fiveam)           ; 测试框架
;; (ql:quickload :cffi)             ; FFI
;; (ql:quickload :usocket)          ; Socket 编程
;; (ql:quickload :ironclad)         ; 加密库
;; (ql:quickload :local-time)       ; 时间处理
;; (ql:quickload :split-sequence)   ; 序列拆分
;; (ql:quickload :iterate)          ; 迭代库
;; (ql:quickload :serapeum)         ; 更多工具

;; 搜索库
;; (ql:system-apropos "json")

;; 更新 Quicklisp
;; (ql:update-dist "quicklisp")

;; 更新所有已安装的库
;; (ql:update-all-dists)

;; 卸载库
;; (ql:uninstall :library-name)

;; 查看已安装的库
;; (ql:dist-list)

;; 查看依赖关系
;; (ql:who-depends-on :alexandria)

(format t "Quicklisp 命令见注释~%")


;;; ----------------------------------------------------------
;;; 6. 项目结构最佳实践
;;; ----------------------------------------------------------

(format t "~%=== 项目结构 ===~%")

;; 推荐的 Common Lisp 项目结构：
;;
;; my-project/
;; ├── my-project.asd          ; 系统定义
;; ├── README.md               ; 项目说明
;; ├── LICENSE                 ; 许可证
;; ├── src/
;; │   ├── package.lisp        ; 包定义
;; │   ├── utils.lisp          ; 工具函数
;; │   ├── config.lisp         ; 配置
;; │   ├── models.lisp         ; 数据模型
;; │   ├── handlers.lisp       ; 业务逻辑
;; │   └── main.lisp           ; 入口
;; ├── tests/
;; │   ├── package.lisp        ; 测试包定义
;; │   ├── test-utils.lisp     ; 工具测试
;; │   └── test-main.lisp      ; 主测试
;; └── docs/
;;     └── manual.md           ; 文档

;; package.lisp 最佳实践：
(format t "
推荐的 package.lisp 结构：
  (defpackage #:my-project
    (:use #:cl)
    (:export
     ;; 主要 API
     #:main
     #:start
     #:stop
     ;; 配置
     #:*config*
     ;; 版本
     #:*version*))
")

;; 版本管理：
(format t "
推荐的版本常量：
  (defconstant +version+ \"0.1.0\")
  (defparameter *version* +version+)
")


;;; ----------------------------------------------------------
;;; 7. 创建可发布的项目
;;; ----------------------------------------------------------

(format t "~%=== 可发布项目 ===~%")

;; 使用 Quickproject 快速创建项目骨架
;; (ql:quickload :quickproject)
;; (quickproject:make-project #p"~/my-new-project/"
;;                            :author "Your Name"
;;                            :license "MIT"
;;                            :depends-on '(:cl-ppcre :alexandria))

;; 手动创建项目骨架的步骤：
;; 1. 创建目录结构
;; 2. 编写 .asd 文件
;; 3. 编写 package.lisp
;; 4. 编写源代码
;; 5. 编写测试
;; 6. 将项目目录放入 ~/quicklisp/local-projects/
;; 7. (ql:quickload :my-project)

;; 生成可执行文件
(format t "
生成可执行文件的完整流程：
  1. sbcl --eval '(ql:quickload :my-project)' \\
          --eval '(sb-ext:save-lisp-and-die \"my-app\" \\
                    :toplevel #'my-project:main \\
                    :executable t)' \\
          --quit

  2. 运行：./my-app
")


;;; ----------------------------------------------------------
;;; 8. 常用第三方库推荐
;;; ----------------------------------------------------------

(format t "~%=== 推荐库 ===~%")

(format t "
Web 开发：
  hunchentoot     — Web 服务器
  clack           — Web 框架抽象层
  ningle          — 轻量 Web 框架
  caveman         — 全功能 Web 框架
  djula           — 模板引擎
  spinneret       — HTML 生成

数据库：
  postmodern      — PostgreSQL
  cl-dbi          — 数据库抽象层
  mito            — ORM
  sxql            — SQL 生成器

工具库：
  alexandria      — 必备工具函数
  serapeum        — 更多工具
  split-sequence  — 序列拆分
  iterate         — 更好的迭代
  trivia          — 模式匹配
  arrow-macros    — 箭头宏（-> ->>）

数据格式：
  cl-json         — JSON
  yason           — JSON（流式）
  cl-csv          — CSV
  xmls            — XML
  cl-yaml         — YAML

网络：
  drakma          — HTTP 客户端
  usocket         — Socket
  cl-async        — 异步 IO

测试：
  fiveam          — 测试框架
  prove           — 测试框架
  parachute       — 测试框架

其他：
  bordeaux-threads — 可移植线程
  lparallel        — 并行计算
  ironclad         — 加密
  local-time       — 时间处理
  cl-ppcre         — 正则表达式
  log4cl           — 日志
  trivial-backtrace — 回溯
")

(format t "~%==== 15 结束 ====~%")
