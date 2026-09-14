#include <windows.h>
#include <psapi.h>

#include <chrono>
#include <condition_variable>
#include <functional>
#include <future>
#include <iostream>
#include <mutex>
#include <queue>
#include <string>
#include <thread>
#include <vector>

namespace winui3_guide::os_integration {

struct ProcessInfo {
    DWORD pid = 0;
    std::wstring image_name;
};

class UiTaskQueue {
public:
    void enqueue(std::function<void()> task)
    {
        {
            std::lock_guard lock(mutex_);
            queue_.push(std::move(task));
        }
        condition_.notify_one();
    }

    std::function<void()> take()
    {
        std::unique_lock lock(mutex_);
        condition_.wait(lock, [this] { return stop_ || !queue_.empty(); });

        if (stop_ && queue_.empty()) {
            return {};
        }

        auto task = std::move(queue_.front());
        queue_.pop();
        return task;
    }

    void stop()
    {
        {
            std::lock_guard lock(mutex_);
            stop_ = true;
        }
        condition_.notify_all();
    }

private:
    std::mutex mutex_;
    std::condition_variable condition_;
    std::queue<std::function<void()>> queue_;
    bool stop_ = false;
};

class ThreadPool {
public:
    explicit ThreadPool(std::size_t workers)
    {
        for (std::size_t i = 0; i < workers; ++i) {
            workers_.emplace_back([this] {
                for (;;) {
                    std::function<void()> task;
                    {
                        std::unique_lock lock(mutex_);
                        condition_.wait(lock, [this] { return stop_ || !tasks_.empty(); });

                        if (stop_ && tasks_.empty()) {
                            return;
                        }

                        task = std::move(tasks_.front());
                        tasks_.pop();
                    }

                    task();
                }
            });
        }
    }

    template <class F>
    void submit(F&& task)
    {
        {
            std::lock_guard lock(mutex_);
            tasks_.emplace(std::forward<F>(task));
        }
        condition_.notify_one();
    }

    ~ThreadPool()
    {
        {
            std::lock_guard lock(mutex_);
            stop_ = true;
        }
        condition_.notify_all();
        for (auto& worker : workers_) {
            worker.join();
        }
    }

private:
    std::vector<std::thread> workers_;
    std::queue<std::function<void()>> tasks_;
    std::mutex mutex_;
    std::condition_variable condition_;
    bool stop_ = false;
};

bool launch_notepad()
{
    STARTUPINFOW si{};
    PROCESS_INFORMATION pi{};

    std::wstring command = L"notepad.exe";
    BOOL ok = CreateProcessW(
        nullptr,
        command.data(),
        nullptr,
        nullptr,
        FALSE,
        0,
        nullptr,
        nullptr,
        &si,
        &pi);

    if (!ok) {
        return false;
    }

    CloseHandle(pi.hThread);
    CloseHandle(pi.hProcess);
    return true;
}

std::vector<ProcessInfo> snapshot_processes()
{
    std::vector<ProcessInfo> processes;

    DWORD pids[1024] = {};
    DWORD needed = 0;
    if (!EnumProcesses(pids, sizeof(pids), &needed)) {
        return processes;
    }

    const DWORD count = needed / sizeof(DWORD);
    for (DWORD i = 0; i < count; ++i) {
        if (pids[i] == 0) {
            continue;
        }

        HANDLE process = OpenProcess(PROCESS_QUERY_LIMITED_INFORMATION, FALSE, pids[i]);
        if (!process) {
            continue;
        }

        wchar_t buffer[MAX_PATH] = {};
        DWORD size = MAX_PATH;
        if (QueryFullProcessImageNameW(process, 0, buffer, &size)) {
            processes.push_back(ProcessInfo{ pids[i], buffer });
        }

        CloseHandle(process);
    }

    return processes;
}

void worker_task(std::vector<int>& data)
{
    for (int i = 0; i < 5; ++i) {
        data.push_back(i * 10);
    }
}

void demo_threading()
{
    std::vector<int> values;
    std::thread worker(worker_task, std::ref(values));
    worker.join();

    std::cout << "Thread produced: ";
    for (int value : values) {
        std::cout << value << ' ';
    }
    std::cout << '\n';
}

void demo_ui_task_queue()
{
    UiTaskQueue ui_queue;
    ThreadPool pool(2);

    pool.submit([&ui_queue] {
        std::this_thread::sleep_for(std::chrono::milliseconds(80));
        auto process_count = snapshot_processes().size();
        ui_queue.enqueue([process_count] {
            std::cout << "UI queue received process count: " << process_count << '\n';
        });
    });

    auto task = ui_queue.take();
    if (task) {
        task();
    }
    ui_queue.stop();
}

std::future<int> demo_future_pattern()
{
    return std::async(std::launch::async, [] {
        std::this_thread::sleep_for(std::chrono::milliseconds(50));
        return 42 + 8;
    });
}

int fork_join_sum(const std::vector<int>& data)
{
    if (data.size() <= 2048) {
        int sum = 0;
        for (int value : data) {
            sum += value;
        }
        return sum;
    }

    std::size_t mid = data.size() / 2;

    auto left = std::async(std::launch::async, [&] {
        std::vector<int> left_data(data.begin(), data.begin() + static_cast<std::ptrdiff_t>(mid));
        return fork_join_sum(left_data);
    });

    auto right = std::async(std::launch::async, [&] {
        std::vector<int> right_data(data.begin() + static_cast<std::ptrdiff_t>(mid), data.end());
        return fork_join_sum(right_data);
    });

    return left.get() + right.get();
}

void demo_fork_join()
{
    std::vector<int> numbers;
    numbers.reserve(10000);
    for (int i = 0; i < 10000; ++i) {
        numbers.push_back(i + 1);
    }

    int sum = fork_join_sum(numbers);
    std::cout << "Fork-join sum: " << sum << '\n';
}

void CALLBACK fiber_work(void* param)
{
    auto* value = static_cast<int*>(param);
    *value += 1;
}

void demo_fiber()
{
    int value = 0;
    auto main_fiber = ConvertThreadToFiber(nullptr);
    auto worker_fiber = CreateFiber(0, fiber_work, &value);

    SwitchToFiber(worker_fiber);
    DeleteFiber(worker_fiber);
    ConvertFiberToThread();

    std::cout << "Fiber final value: " << value << '\n';
    (void)main_fiber;
}

} // namespace winui3_guide::os_integration

int main()
{
    bool ok = winui3_guide::os_integration::launch_notepad();
    std::cout << "Launch notepad: " << (ok ? "success" : "failed") << '\n';

    auto processes = winui3_guide::os_integration::snapshot_processes();
    std::cout << "Visible processes: " << processes.size() << '\n';

    winui3_guide::os_integration::demo_threading();
    winui3_guide::os_integration::demo_ui_task_queue();

    auto future_result = winui3_guide::os_integration::demo_future_pattern();
    std::cout << "Future result: " << future_result.get() << '\n';

    winui3_guide::os_integration::demo_fork_join();
    winui3_guide::os_integration::demo_fiber();

    return 0;
}
