#include <memory>
#include <vector>
#include <iostream>

class Observer;

class Subject {
private:
    std::vector<std::weak_ptr<Observer>> observers;
public:
    void attach(std::shared_ptr<Observer> obs) {
        observers.push_back(obs);
    }

    void notify() {
        for (auto& weak_obs : observers) {
            if (auto obs = weak_obs.lock()) {
                obs->on_notify();
            }
        }
    }
};

class Observer : public std::enable_shared_from_this<Observer> {
public:
    void on_notify() {
        std::cout << "Observer notified\n";
    }
};
