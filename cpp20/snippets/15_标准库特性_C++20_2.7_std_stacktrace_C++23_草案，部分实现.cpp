#include <stacktrace>

void function_c() {
    auto trace = std::stacktrace::current();
    for (const auto& frame : trace) {
        std::cout << frame << "\n";
    }
}
