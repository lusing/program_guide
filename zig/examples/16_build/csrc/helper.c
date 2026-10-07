/* 16 章的 C 侧：一个纯整数函数，故意不带任何 libc 依赖，
   这样不 link_libc 也能链接成功——证明 addCSourceFiles 走的是
   同一个编译单元列表，而不是"顺带帮你链了 libc"。 */
int build16_c_triple(int x) {
    return x * 3;
}

int build16_c_add(int a, int b) {
    return a + b;
}