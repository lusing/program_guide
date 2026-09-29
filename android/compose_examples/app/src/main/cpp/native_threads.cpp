// 第 30 章：原生线程与同步——pthread/互斥/条件变量/信号量/AttachCurrentThread
// Kotlin 侧镜像：jni/NativeThreadBridge.kt
#include <jni.h>
#include <cstdio>
#include <pthread.h>
#include <semaphore.h>
#include <sched.h>
#include <string>
#include <unistd.h>

// native-lib.cpp 在 JNI_OnLoad 里缓存；JavaVM 进程级有效，JNIEnv 才是线程局部
extern JavaVM* g_guideJavaVm;

// 回调所需的 jclass / jmethodID 在 JNI_OnLoad（app 类加载器上下文）里预取并
// 提升为全局——原生线程里 FindClass 会走系统类加载器，找不到应用类（经典坑）。
static jclass g_bridgeClass = nullptr;
static jmethodID g_onNativeMessage = nullptr;

extern "C" JNIEXPORT jint JNI_OnLoad(JavaVM* vm, void*) {
    JNIEnv* env = nullptr;
    if (vm->GetEnv(reinterpret_cast<void**>(&env), JNI_VERSION_1_6) != JNI_OK) {
        return JNI_ERR;
    }
    jclass local = env->FindClass("guide/android/compose/jni/NativeThreadBridge");
    if (local == nullptr) {
        env->ExceptionClear();
        return JNI_VERSION_1_6;  // 类还没编译进去也不阻塞库加载，仅回调功能失效
    }
    g_bridgeClass = static_cast<jclass>(env->NewGlobalRef(local));
    g_onNativeMessage = env->GetStaticMethodID(
            g_bridgeClass, "onNativeMessage", "(Ljava/lang/String;)V");
    if (g_onNativeMessage == nullptr) {
        env->ExceptionClear();
    }
    return JNI_VERSION_1_6;
}

// ---------- pthread_create + mutex + condvar ----------
namespace {

struct SumJob {
    jint n;
    jlong result;
    pthread_mutex_t mutex;
    pthread_cond_t done;
    bool finished;
};

void* sum_worker(void* arg) {
    auto* job = static_cast<SumJob*>(arg);
    jlong sum = 0;
    for (jint i = 1; i <= job->n; i++) {
        sum += i;
    }
    pthread_mutex_lock(&job->mutex);
    job->result = sum;
    job->finished = true;
    pthread_cond_signal(&job->done);   // 通知主线程：结果就绪
    pthread_mutex_unlock(&job->mutex);
    return nullptr;
}

}  // namespace

extern "C" JNIEXPORT jlong JNICALL
Java_guide_android_compose_jni_NativeThreadBridge_threadSpawnSum(JNIEnv* env, jobject, jint n) {
    SumJob job{};
    job.n = n;
    job.result = 0;
    job.finished = false;
    pthread_mutex_init(&job.mutex, nullptr);
    pthread_cond_init(&job.done, nullptr);

    pthread_t worker;
    int rc = pthread_create(&worker, nullptr, sum_worker, &job);
    if (rc != 0) {
        pthread_cond_destroy(&job.done);
        pthread_mutex_destroy(&job.mutex);
        return -(jlong) rc;  // 哨兵：创建失败的 errno
    }

    pthread_mutex_lock(&job.mutex);
    while (!job.finished) {
        pthread_cond_wait(&job.done, &job.mutex);  // 用 while 防"虚假唤醒"
    }
    pthread_mutex_unlock(&job.mutex);

    pthread_join(worker, nullptr);          // 回收线程资源
    pthread_cond_destroy(&job.done);
    pthread_mutex_destroy(&job.mutex);
    return job.result;
}

// ---------- 原生线程回调 Kotlin：AttachCurrentThread ----------
namespace {

struct NotifyJob {
    jint value;
    char message[128];
};

void* notify_worker(void* arg) {
    auto* job = static_cast<NotifyJob*>(arg);
    snprintf(job->message, sizeof(job->message), "原生线程 tid=%d 算完 %d 的平方=%d",
             (int) gettid(), job->value, job->value * job->value);

    JNIEnv* env = nullptr;
    JavaVMAttachArgs args{};
    args.version = JNI_VERSION_1_6;
    args.name = const_cast<char*>("guide-native-worker");  // debugger 里可见的线程名
    args.group = nullptr;
    if (g_guideJavaVm == nullptr || g_bridgeClass == nullptr || g_onNativeMessage == nullptr) {
        return nullptr;
    }
    if (g_guideJavaVm->AttachCurrentThread(&env, &args) == JNI_OK && env != nullptr) {
        jstring msg = env->NewStringUTF(job->message);
        env->CallStaticVoidMethod(g_bridgeClass, g_onNativeMessage, msg);
        if (env->ExceptionCheck()) {   // 回调抛了异常也要清掉再分离
            env->ExceptionClear();
        }
        env->DeleteLocalRef(msg);
        g_guideJavaVm->DetachCurrentThread();  // 不分离会泄漏 JNI 线程槽
    }
    return nullptr;
}

}  // namespace

extern "C" JNIEXPORT jstring JNICALL
Java_guide_android_compose_jni_NativeThreadBridge_threadNotifyBack(JNIEnv* env, jobject, jint value) {
    NotifyJob job{};
    job.value = value;
    pthread_t worker;
    if (pthread_create(&worker, nullptr, notify_worker, &job) != 0) {
        return env->NewStringUTF("pthread_create 失败");
    }
    pthread_join(worker, nullptr);
    return env->NewStringUTF(job.message);
}

// ---------- 信号量：两线程乒乓 ----------
namespace {

struct PingPongJob {
    jint count;
    jint hits;
    sem_t ping;
    sem_t pong;
};

void* ping_worker(void* arg) {
    auto* job = static_cast<PingPongJob*>(arg);
    for (jint i = 0; i < job->count; i++) {
        sem_wait(&job->ping);          // 等"该我发球"
        sem_post(&job->pong);          // 把球打回去
    }
    return nullptr;
}

}  // namespace

extern "C" JNIEXPORT jint JNICALL
Java_guide_android_compose_jni_NativeThreadBridge_threadSemPingpong(JNIEnv* env, jobject, jint count) {
    PingPongJob job{};
    job.count = count;
    job.hits = 0;
    sem_init(&job.ping, 0, 0);
    sem_init(&job.pong, 0, 0);

    pthread_t worker;
    if (pthread_create(&worker, nullptr, ping_worker, &job) != 0) {
        sem_destroy(&job.ping);
        sem_destroy(&job.pong);
        return -1;
    }
    for (jint i = 0; i < count; i++) {
        sem_post(&job.ping);      // 主线程发球
        sem_wait(&job.pong);      // 等回球
        job.hits++;
    }
    pthread_join(worker, nullptr);
    sem_destroy(&job.ping);
    sem_destroy(&job.pong);
    return job.hits;
}

// ---------- 调度策略与优先级的现实 ----------
// 非 root 应用线程只能用 SCHED_OTHER；SCHED_FIFO/SCHED_RR 需要特权，
// 且 Android 不保证 cap 被授予——"实时优先级"在应用层基本是幻觉。
extern "C" JNIEXPORT jstring JNICALL
Java_guide_android_compose_jni_NativeThreadBridge_threadSchedInfo(JNIEnv* env, jobject) {
    int policy = 0;
    struct sched_param param{};
    pthread_getschedparam(pthread_self(), &policy, &param);
    std::string name = (policy == SCHED_OTHER) ? "SCHED_OTHER" : "其他策略";
    char buf[256];
    snprintf(buf, sizeof(buf), "策略=%s sched_priority=%d（SCHED_OTHER 恒为 0；"
             "min/max=%d/%d）", name.c_str(), param.sched_priority,
             sched_get_priority_min(SCHED_OTHER), sched_get_priority_max(SCHED_OTHER));
    return env->NewStringUTF(buf);
}
