#pragma once

#include <filesystem>
#include <string>
#include <string_view>
#include <vector>

// 24 迷你 grep：搜索层（与输出层分离，便于测试）

struct Match {
    int line_no;
    std::string text;
};

// 在一段文本里逐行查找 pattern（可忽略大小写）
std::vector<Match> search_text(std::string_view content,
                               std::string_view pattern,
                               bool ignore_case);

// 找 pattern 在 line 中首次出现的位置；找不到返回 npos
std::size_t find_in_line(std::string_view line,
                         std::string_view pattern,
                         bool ignore_case);

// 搜索单个文件；打不开/读不了返回空
std::vector<Match> search_file(const std::filesystem::path& file,
                               std::string_view pattern,
                               bool ignore_case);
