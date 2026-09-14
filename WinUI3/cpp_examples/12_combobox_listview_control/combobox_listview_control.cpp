#include <iostream>
#include <string>
#include <vector>

namespace winui3_guide::combobox_listview_control {

struct ThemeOption {
    std::string name;
};

class ThemeViewModel {
public:
    ThemeViewModel()
    {
        options_ = { {"Light"}, {"Dark"}, {"System"} };
    }

    std::vector<ThemeOption> options() const
    {
        return options_;
    }

    std::string selected_theme() const
    {
        return selected_theme_;
    }

    void set_selected_index(std::size_t index)
    {
        if (index < options_.size()) {
            selected_theme_ = options_[index].name;
        }
    }

private:
    std::vector<ThemeOption> options_;
    std::string selected_theme_ = "Light";
};

class TodoListViewModel {
public:
    void add_task(std::string task)
    {
        tasks_.push_back(std::move(task));
    }

    const std::vector<std::string>& tasks() const
    {
        return tasks_;
    }

private:
    std::vector<std::string> tasks_ = { "Learn WinUI 3", "Review API", "Organize samples" };
};

} // namespace winui3_guide::combobox_listview_control

int main()
{
    winui3_guide::combobox_listview_control::ThemeViewModel theme_vm;
    theme_vm.set_selected_index(2);
    std::cout << "Selected theme: " << theme_vm.selected_theme() << '\n';

    winui3_guide::combobox_listview_control::TodoListViewModel tasks;
    tasks.add_task("Submit practice code");

    for (const auto& task : tasks.tasks()) {
        std::cout << task << '\n';
    }

    return 0;
}
