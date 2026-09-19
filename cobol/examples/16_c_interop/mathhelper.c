/* mathhelper.c — 供 COBOL CALL 的 C 函数（第 16 章 C 互操作示例）。
 *
 * 约定（实测）：COBOL 的 CALL ... USING 默认 BY REFERENCE，
 * 所以 C 侧收到的是【数据项的指针】，不是值。要读 *p，要写 *out=...。
 * 数值字段用 PIC S9(9) COMP-5（或 BINARY）对应 C 的 int（4 字节本机整数）。
 * 字符串字段 PIC X(n) 对应 char*，但【不带 NUL 结尾】——是定长 n 字节、
 * 以空格补齐，所以 C 侧要自己数长度、别用 strlen 直接读到尾。
 */

/* 两整数相加，结果写回 *out；返回 0 表示成功 */
int c_add(int *a, int *b, int *out) {
    *out = *a + *b;
    return 0;
}

/* 求定长字符字段里、第一个空格之前的有效长度，写回 *n */
int c_word_len(char *s, int *cap, int *n) {
    int i = 0;
    int limit = *cap;            /* 字段容量由 COBOL 侧一并传入 */
    while (i < limit && s[i] != ' ' && s[i] != '\0') i++;
    *n = i;
    return 0;
}

/* 把字符字段原地转大写（就地修改，演示 COBOL 侧能看到变化） */
int c_upper(char *s, int *cap) {
    int i;
    int limit = *cap;
    for (i = 0; i < limit; i++) {
        if (s[i] >= 'a' && s[i] <= 'z') s[i] = s[i] - 32;
    }
    return 0;
}
