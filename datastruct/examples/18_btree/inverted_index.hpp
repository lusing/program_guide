#ifndef DS_INVERTED_INDEX_HPP
#define DS_INVERTED_INDEX_HPP

#include <cctype>
#include <cstddef>
#include <map>
#include <set>
#include <stdexcept>
#include <string>
#include <string_view>
#include <vector>

namespace ds {

// 倒排索引：词 → 包含该词的文档编号集合（postings list）。
//
// 文档加入时按非字母数字字符分词、统一转小写；同一文档编号不得重复加入。
// 内部用 std::map<std::string, std::set<int>>：词与文档编号都自动有序，
// 于是 postings 天然按升序返回。
class InvertedIndex {
public:
    // 加入一篇文档。重复 id 抛 invalid_argument。
    void add_doc(int id, std::string_view text) {
        if (!docs_.insert(id).second) {
            throw std::invalid_argument("InvertedIndex::add_doc: duplicate doc id");
        }
        for (std::string_view token : tokenize(text)) {
            postings_[std::string(token)].insert(id);
        }
    }

    // 返回包含该词的全部文档编号（升序）；未登录词返回空向量。
    [[nodiscard]] std::vector<int> postings(std::string_view word) const {
        std::vector<int> out;
        if (auto it = postings_.find(std::string(word)); it != postings_.end()) {
            out.assign(it->second.begin(), it->second.end());
        }
        return out;
    }

    [[nodiscard]] size_t doc_count() const noexcept { return docs_.size(); }

private:
    std::map<std::string, std::set<int>> postings_;
    std::set<int> docs_;

    // 按非字母数字字符切词，每段转小写（token 只含 ASCII 字母数字）。
    static std::vector<std::string> tokenize(std::string_view text) {
        std::vector<std::string> tokens;
        std::string current;
        for (char ch : text) {
            if (std::isalnum(static_cast<unsigned char>(ch))) {
                current.push_back(static_cast<char>(
                    std::tolower(static_cast<unsigned char>(ch))));
            } else if (!current.empty()) {
                tokens.push_back(std::move(current));
                current.clear();
            }
        }
        if (!current.empty()) {
            tokens.push_back(std::move(current));
        }
        return tokens;
    }
};

}  // namespace ds

#endif  // DS_INVERTED_INDEX_HPP
