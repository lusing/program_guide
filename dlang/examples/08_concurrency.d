module ex08_concurrency;

import core.thread : Thread;
import core.time : dur;
import std.concurrency : receive, send, spawn;
import std.stdio;

void worker()
{
    receive(
        (string msg) {
            writeln("worker got: ", msg);
        }
    );
}

void main()
{
    auto tid = spawn(&worker);
    send(tid, "ping");
    Thread.sleep(dur!"msecs"(20));
}
