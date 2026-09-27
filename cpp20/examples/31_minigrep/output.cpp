#include "output.h"

#include <print>

namespace {
constexpr std::string_view kRed = "\033[31;1m";
constexpr std::string_view kReset = "\033[0m";
}  // namespace

void print_match(const std::filesystem::path& file,
                 const Match& match,
                 std::string_view pattern,
                 bool ignore_case) {
    std::size_t pos = find_in_line(match.text, pattern, ignore_case);
    if (pos == std::string_view::npos) {
        std::println("{}:{}:{}", file.string(), match.line_no, match.text);
        return;
    }
    std::println("{}:{}:{}{}{}{}{}",
                 file.string(), match.line_no,
                 std::string_view{match.text}.substr(0, pos),
                 kRed,
                 std::string_view{match.text}.substr(pos, pattern.size()),
                 kReset,
                 std::string_view{match.text}.substr(pos + pattern.size()));
}
