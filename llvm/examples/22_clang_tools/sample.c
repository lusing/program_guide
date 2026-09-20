/* 第 22 章样例：给 clang 前端工具当实验品 */
#include <stdio.h>

static int add(int a, int b) { return a + b; }

int main(void) {
    int sum = 0;
    for (int i = 1; i <= 10; i++)
        sum = add(sum, i);
    printf("sum = %d\n", sum);
    printf("==== 22 ir ok ====\n");
    return 0;
}
