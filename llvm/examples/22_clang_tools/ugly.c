/* 故意写得难看：给 clang-format 当实验品 */
#include <stdio.h>
static int f(int x){if(x<0){return -x;}return x;}
int main(void){int a=3;int b=-5;printf("abs3=%d abs5=%d\n",f(a),f(b));printf("==== 22 fmt ok ====\n");return 0;}
