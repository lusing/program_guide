#include <thread>
#include <queue>
#include <mutex>
#include <condition_variable>
#include <functional>
#include <future>
#include <iostream>
#include <atomic>

class DebugThreadPool {
private:
    std::vector<std::thread> workers;
    std::queue<std::function<void()>> tasks;
    std::mutex queue_mutex;
    std::condition_variable condition;
    std::atomic<bool> stop{false};
    std::atomic<int> active_tasks{0};
    std::mutex debug_mutex;

public:
    DebugThreadPool(size_t threads) {
        for (size_t i = 0; i < threads; ++i) {
            workers.emplace_back([this, id = i] {
                std::cout << "Worker " << id << " started\n";
                while (true) {
                    std::function<void()> task;
                    {
                        std::unique_lock<std::mutex> lock(queue_mutex);
                        condition.wait(lock, [this] {
                            return stop.load() || !tasks.empty();
                        });

                        if (stop && tasks.empty()) return;

                        task = std::move(tasks.front());
                        tasks.pop();
                        active_tasks.fetch_add(1);
                    }

                    task();
                    active_tasks.fetch_sub(1);
                }
            });
        }
    }

    template<class F>
    auto enqueue(F&& f) -> std::future<typename std::invoke_result<F>::type> {
        using return_type = typename std::invoke_result<F>::type;

        auto task = std::make_shared<std::packaged_task<return_type()>>(
            std::forward<F>(f)
        );

        std::future<return_type> res = task->get_future();

        {
            std::lock_guard<std::mutex> lock(queue_mutex);
            if (stop) throw std::runtime_error("enqueue on stopped ThreadPool");
            tasks.emplace([task]() { (*task)(); });
        }

        condition.notify_one();
        return res;
    }

    ~DebugThreadPool() {
        {
            std::lock_guard<std::mutex> lock(queue_mutex);
            stop = true;
        }
        condition.notify_all();
        for (std::thread& worker : workers) {
            worker.join();
        }
    }

    void print_status() {
        std::lock_guard<std::mutex> lock(queue_mutex);
        std::cout << "Active tasks: " << active_tasks.load()
                  << ", Queue size: " << tasks.size() << "\n";
    }
};
