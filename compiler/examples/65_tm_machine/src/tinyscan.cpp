// file: src/tinyscan.cpp
#include "tinyscan.hpp"

#include <cctype>
#include <map>
#include <stdexcept>

namespace tiny {

namespace {

const std::map<std::string, Tok> &keywords() {
    static const std::map<std::string, Tok> kw = {
        {"if", Tok::If},       {"then", Tok::Then}, {"else", Tok::Else},
        {"end", Tok::End},     {"repeat", Tok::Repeat}, {"until", Tok::Until},
        {"read", Tok::Read},   {"write", Tok::Write},
    };
    return kw;
}

bool identStart(char c) { return std::isalpha(static_cast<unsigned char>(c)); }
bool identChar(char c) {
    return std::isalnum(static_cast<unsigned char>(c)) || c == '_';
}

}  // namespace

const char *tokName(Tok t) {
    switch (t) {
    case Tok::If: return "if";       case Tok::Then: return "then";
    case Tok::Else: return "else";   case Tok::End: return "end";
    case Tok::Repeat: return "repeat"; case Tok::Until: return "until";
    case Tok::Read: return "read";   case Tok::Write: return "write";
    case Tok::Assign: return ":=";   case Tok::Eq: return "=";
    case Tok::Lt: return "<";        case Tok::Add: return "+";
    case Tok::Sub: return "-";       case Tok::Mul: return "*";
    case Tok::Div: return "/";       case Tok::LParen: return "(";
    case Tok::RParen: return ")";    case Tok::Semi: return ";";
    case Tok::Num: return "NUM";     case Tok::Id: return "ID";
    case Tok::EndOfFile: return "EOF";
    }
    return "?";
}

std::vector<ScanTok> scan(const std::string &src) {
    std::vector<ScanTok> out;
    size_t i = 0;
    int line = 1;
    auto fail = [&](const std::string &why) {
        throw ParseError{"词法: " + why, line};
    };
    while (i < src.size()) {
        char c = src[i];
        if (c == '\n') { ++line; ++i; continue; }
        if (std::isspace(static_cast<unsigned char>(c))) { ++i; continue; }
        if (c == '{') {   // 注释到配对 }
            ++i;
            while (i < src.size() && src[i] != '}') {
                if (src[i] == '\n') ++line;
                ++i;
            }
            if (i >= src.size()) fail("注释未闭合");
            ++i;
            continue;
        }
        if (identStart(c)) {
            size_t j = i;
            while (j < src.size() && identChar(src[j])) ++j;
            std::string w = src.substr(i, j - i);
            auto it = keywords().find(w);
            ScanTok t;
            t.line = line;
            t.text = w;
            t.kind = it != keywords().end() ? it->second : Tok::Id;
            out.push_back(t);
            i = j;
            continue;
        }
        if (std::isdigit(static_cast<unsigned char>(c))) {
            size_t j = i;
            while (j < src.size() && std::isdigit(static_cast<unsigned char>(src[j]))) ++j;
            ScanTok t;
            t.kind = Tok::Num;
            t.text = src.substr(i, j - i);
            t.num = std::stoll(t.text);
            t.line = line;
            out.push_back(t);
            i = j;
            continue;
        }
        if (c == ':' && i + 1 < src.size() && src[i + 1] == '=') {
            out.push_back({Tok::Assign, ":=", 0, line});
            i += 2;
            continue;
        }
        Tok one;
        switch (c) {
        case '=': one = Tok::Eq; break;
        case '<': one = Tok::Lt; break;
        case '+': one = Tok::Add; break;
        case '-': one = Tok::Sub; break;
        case '*': one = Tok::Mul; break;
        case '/': one = Tok::Div; break;
        case '(': one = Tok::LParen; break;
        case ')': one = Tok::RParen; break;
        case ';': one = Tok::Semi; break;
        default: fail(std::string("无法成词的字符 '") + c + "'");
        }
        out.push_back({one, std::string(1, c), 0, line});
        ++i;
    }
    out.push_back({Tok::EndOfFile, "", 0, line});
    return out;
}

}  // namespace tiny
