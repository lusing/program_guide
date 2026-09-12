// 自定义范围
class Range {
    int begin_, end_;
public:
    Range(int end) : begin_(0), end_(end) {}

    struct iterator {
        int value;
        int operator*() const { return value; }
        iterator& operator++() { ++value; return *this; }
        bool operator!=(const iterator& other) const { return value != other.value; }
    };

    iterator begin() const { return {begin_}; }
    iterator end() const { return {end_}; }
};

for (int i : Range(5)) {
    std::cout << i << " "; // 0 1 2 3 4
}
