int main() {
    ThreadPool pool(4);

    auto f1 = pool.enqueue([] {
        std::cout << "Hello from task 1\n";
        return 42;
    });

    auto f2 = pool.enqueue([] (int x) {
        std::cout << "Task 2: " << x << "\n";
        return x * 2;
    }, 10);

    std::cout << "Result 1: " << f1.get() << "\n";
    std::cout << "Result 2: " << f2.get() << "\n";
}
