#include <functional>
#include <iostream>
#include <string>
#include <utility>

namespace winui3_guide::mvvm_command {

class RelayCommand {
public:
    explicit RelayCommand(std::function<void()> execute)
        : execute_(std::move(execute))
    {
    }

    void execute() const
    {
        execute_();
    }

private:
    std::function<void()> execute_;
};

class TaskViewModel {
public:
    TaskViewModel()
        : add_task_command_([this]() { add_task(); })
    {
    }

    void set_task_name(std::string value)
    {
        task_name_ = std::move(value);
    }

    const std::string& status_text() const
    {
        return status_text_;
    }

    const RelayCommand& add_task_command() const
    {
        return add_task_command_;
    }

private:
    void add_task()
    {
        if (task_name_.empty()) {
            status_text_ = "Task name cannot be empty.";
            return;
        }
        status_text_ = "Added task: " + task_name_;
    }

    std::string task_name_{"Learn WinUI3 C++"};
    std::string status_text_{"Waiting..."};
    RelayCommand add_task_command_;
};

} // namespace winui3_guide::mvvm_command

int main()
{
    winui3_guide::mvvm_command::TaskViewModel vm;
    vm.add_task_command().execute();
    std::cout << vm.status_text() << '\n';
    return 0;
}
