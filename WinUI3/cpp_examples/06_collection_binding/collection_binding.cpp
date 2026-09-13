#include <iostream>
#include <string>
#include <vector>

namespace winui3_guide::collection_binding {

struct TaskItem {
    std::string title;
    bool done{};
};

class TaskListViewModel {
public:
    void add_task(std::string title)
    {
        tasks_.push_back(TaskItem{std::move(title), false});
    }

    void toggle_done(std::size_t index)
    {
        if (index >= tasks_.size()) {
            return;
        }
        tasks_[index].done = !tasks_[index].done;
    }

    [[nodiscard]] std::size_t done_count() const
    {
        std::size_t count = 0;
        for (const auto& item : tasks_) {
            if (item.done) {
                ++count;
            }
        }
        return count;
    }

private:
    std::vector<TaskItem> tasks_;
};

} // namespace winui3_guide::collection_binding

int main()
{
    winui3_guide::collection_binding::TaskListViewModel vm;
    vm.add_task("Design page");
    vm.add_task("Wire bindings");
    vm.toggle_done(1);
    std::cout << "Done count: " << vm.done_count() << '\n';
    return 0;
}
