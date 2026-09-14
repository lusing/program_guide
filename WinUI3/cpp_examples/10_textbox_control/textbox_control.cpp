#include <iostream>
#include <string>
#include <vector>

namespace winui3_guide::textbox_control {

class TextBoxViewModel {
public:
    void set_text(std::string value)
    {
        text_ = std::move(value);
    }

    bool validate() const
    {
        return text_.size() >= 3;
    }

    std::string text() const
    {
        return text_;
    }

private:
    std::string text_;
};

std::string on_text_changed(TextBoxViewModel& vm)
{
    if (!vm.validate()) {
        return "Username must be at least 3 characters";
    }
    return "Username valid: " + vm.text();
}

} // namespace winui3_guide::textbox_control

int main()
{
    winui3_guide::textbox_control::TextBoxViewModel vm;
    vm.set_text("AL");
    std::cout << winui3_guide::textbox_control::on_text_changed(vm) << '\n';

    vm.set_text("Alice");
    std::cout << winui3_guide::textbox_control::on_text_changed(vm) << '\n';

    return 0;
}
