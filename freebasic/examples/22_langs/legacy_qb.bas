' legacy_qb.bas —— QB 方言示范：行号、Gosub/Return、隐式变量、On..Gosub
' 编译：fbc -lang qb legacy_qb.bas（build.ps1 的第三验证通道）
' 注意：此文件故意保留 QB 风格（大写关键字、冒号连行）——它就是教材。

10 DEFINT A-Z                        ' A-Z 开头的变量默认 Integer（qb 方言特性）
20 LET x = 5                          ' 隐式变量 + LET（fb 方言都不允许）
30 PRINT "QB 方言模式：x ="; x
40 GOSUB 1000                         ' 跳子程序
50 ON x GOTO 200, 300, 400            ' x=5 超出 3 个目标 → 不跳转，继续下一行
60 PRINT "ON x GOTO 越界不跳转，落在 60 行"
70 y = 1
80 ON y GOSUB 2000, 3000              ' y=1 → 跳 2000 号子程序
90 PRINT "回到主线"
95 PRINT "[OK] legacy_qb"
100 END

1000 PRINT "  [GOSUB 1000] 子程序"
1010 RETURN

2000 PRINT "  [ON..GOSUB 2000] 第一个目标"
2010 RETURN

3000 PRINT "  [ON..GOSUB 3000] 第二个目标"
3010 RETURN

200 PRINT "  [GOTO 200]"
210 GOTO 60
300 PRINT "  [GOTO 300]"
310 GOTO 60
400 PRINT "  [GOTO 400]"
410 GOTO 60
