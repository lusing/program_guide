// 模板模板参数自动推导
template<typename T>
class Container {};

template<typename T>
void process(Container<T>) {}

Container c{1, 2, 3};  // C++17 类模板实参推导
process(c);

// constexpr if
template<typename T>
auto process_value(T value) {
    if constexpr (std::is_integral_v<T>) {
        return value * 2;
    } else if constexpr (std::is_floating_point_v<T>) {
        return value * 3.14;
    } else {
        return value;
    }
}
