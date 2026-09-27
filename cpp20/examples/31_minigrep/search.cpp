#include "search.h"

#include <cctype>
#include <fstream>
#include <sstream>
#include <utility>

namespace {

bool equal_ic(char a, char b) {
    if (a == b) {
        return true;
    }
    auto ua = static_cast<unsigned char>(a);
    auto ub = static_cast<unsigned char>(b);
    return std::tolower(ua) == std::tolower(ub);
}

}  // namespace

std::size_t find_in_line(std::string_view line, std::string_view pattern, bool ignore_case) {
    if (pattern.empty() || line.size() < pattern.size()) {
        return std::string_view::npos;
    }
    for (std::size_t p = 0; p + pattern.size() <= line.size(); ++p) {
        bool hit = true;
        for (std::size_t k = 0; k < pattern.size(); ++k) {
            char a = line[p + k];
            char b = pattern[k];
            if (ignore_case ? !equal_ic(a, b) : a != b) {
                hit = false;
                break;
            }
        }
        if (hit) {
            return p;
        }
    }
    return std::string_view::npos;
}

std::vector<Match> search_text(std::string_view content,
                               std::string_view pattern,
                               bool ignore_case) {
    std::vector<Match> hits;
    std::size_t line_start = 0;
    int line_no = 1;
    for (std::size_t i = 0; i <= content.size(); ++i) {
        if (i == content.size() || content[i] == '\n') {
            std::string_view line = content.substr(line_start, i - line_start);
            if (find_in_line(line, pattern, ignore_case) != std::string_view::npos) {
                hits.push_back({line_no, std::string(line)});
            }
            line_start = i + 1;
            ++line_no;
        }
    }
    return hits;
}

std::vector<Match> search_file(const std::filesystem::path& file,
                               std::string_view pattern,
                               bool ignore_case) {
    std::ifstream in{file};
    if (!in) {
        return {};  // 打不开就跳过（权限、被占用……）
    }
    std::ostringstream buffer;
    buffer << in.rdbuf();  // 整文件读入
    return search_text(buffer.str(), pattern, ignore_case);
}
