#pragma once
// 34 对象池实战：单例池 + 复用契约 + RAII 归还。第 16 章享元管"共享不可变"，
// 对象池管"复用可变但昂贵"——借出/归还的生命周期是池的全部业务。
#include <cstddef>
#include <stdexcept>
#include <vector>

namespace dp {

class Pool;

// 池中对象：id 唯一且永不变（创建序号），used_ 只有 Pool 能碰。
class Conn {
public:
    explicit Conn(int id) : id_(id) {}
    int id() const { return id_; }
    bool in_use() const { return used_; }

private:
    friend class Pool;               // 池是唯一有权改 used_ 的角色
    void acquire() { used_ = true; }
    void release() { used_ = false; }

    int id_;
    bool used_ = false;
};

class Pool {
public:
    static Pool& instance() { static Pool p; return p; }   // Meyers 单例：首次调用即构造

    Conn& acquire() {
        for (auto& c : pool_)
            if (!c.used_) { c.acquire(); return c; }      // 复用空闲：created 不涨
        if (pool_.size() >= kLimit) throw std::runtime_error("pool exhausted");
        pool_.emplace_back(static_cast<int>(created_));
        Conn& c = pool_.back();
        c.acquire();
        ++created_;                                        // 只有新建才涨 created
        return c;
    }

    void release(Conn& c) { c.release(); }
    std::size_t created() const { return created_; }
    std::size_t in_use_count() const {
        std::size_t n = 0;
        for (const auto& c : pool_) if (c.used_) ++n;
        return n;
    }

private:
    Pool() { pool_.reserve(kLimit); }   // 上限预留：acquire 返回的引用不会因扩容失效
    static constexpr std::size_t kLimit = 4;

    std::vector<Conn> pool_;
    std::size_t created_ = 0;
};

// RAII 守卫：构造即借、析构即还——异常路径也归还，与第 32 章订阅句柄同一手法。
class Connection {
public:
    explicit Connection(Pool& p) : pool_(p), conn_(p.acquire()) {}
    ~Connection() { pool_.release(conn_); }
    Connection(const Connection&) = delete;             // 一借一还，拷贝即双重归还
    Connection& operator=(const Connection&) = delete;
    Conn& get() { return conn_; }

private:
    Pool& pool_;
    Conn& conn_;
};

}  // namespace dp
