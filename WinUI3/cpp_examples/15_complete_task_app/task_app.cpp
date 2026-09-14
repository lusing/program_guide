#include <functional>
#include <iostream>
#include <string>
#include <utility>
#include <vector>

namespace winui3_guide::task_app {

struct TaskItem {
    std::string title;
    bool done = false;
};

class RelayCommand {
public:
    explicit RelayCommand(std::function<void()> execute)
        : execute_(std::move(execute))
    {
    }

    void execute() const
    {
        if (execute_) {
            execute_();
        }
    }

private:
    std::function<void()> execute_;
};

class TaskViewModel {
public:
    TaskViewModel()
        : add_command_([this]() { add_task(); })
    {
        tasks_ = {
            {"Plan WinUI app", false},
            {"Design page layout", false},
            {"Review data binding", true}
        };
    }

    void set_new_title(std::string title)
    {
        new_title_ = std::move(title);
    }

    const std::vector<TaskItem>& tasks() const
    {
        return tasks_;
    }

    const RelayCommand& add_command() const
    {
        return add_command_;
    }

    std::size_t completed_count() const
    {
        std::size_t count = 0;
        for (const auto& task : tasks_) {
            if (task.done) {
                ++count;
            }
        }
        return count;
    }

private:
    void add_task()
    {
        if (!new_title_.empty()) {
            tasks_.push_back(TaskItem{new_title_, false});
            new_title_.clear();
        }
    }

    std::vector<TaskItem> tasks_;
    std::string new_title_;
    RelayCommand add_command_;
};

std::string describe(const TaskViewModel& vm)
{
    std::string summary = "Tasks=" + std::to_string(vm.tasks().size());
    summary += ", Completed=" + std::to_string(vm.completed_count());
    return summary;
}

} // namespace winui3_guide::task_app

int main()
{
    winui3_guide::task_app::TaskViewModel vm;
    vm.set_new_title("Write WinUI tutorial");
    vm.add_command().execute();

    std::cout << winui3_guide::task_app::describe(vm) << '\n';
    for (const auto& task : vm.tasks()) {
        std::cout << "- " << task.title << (task.done ? " [done]" : " [pending]") << '\n';
    }

    return 0;
}
