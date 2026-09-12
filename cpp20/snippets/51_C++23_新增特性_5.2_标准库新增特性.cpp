#include <stacktrace>

void print_trace() {
    auto trace = std::stacktrace::current();
    std::cout << "Stack trace:\n";
    for (const auto& frame : trace) {
        std::cout << "  " << frame << "\n";
    }
}
