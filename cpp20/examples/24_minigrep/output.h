#pragma once

#include <filesystem>
#include <string_view>

#include "search.h"

// 24 迷你 grep：输出层——file:line:文本，命中段 ANSI 红色高亮
void print_match(const std::filesystem::path& file,
                 const Match& match,
                 std::string_view pattern,
                 bool ignore_case);
