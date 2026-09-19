// server.cpp — 进程内 COM 服务器（编译成 calcdll.dll）
//
// 对应教程：docs/24-COM实现.md
#include "calc.h"
#include <new>

static HMODULE g_module = nullptr;

// ── 组件实现：引用计数 + QueryInterface ───────────────────────
class Calc : public ICalc {
    LONG m_ref = 1;                       // 诞生即被引用一次
public:
    STDMETHODIMP QueryInterface(REFIID riid, void** ppv) override {
        if (!ppv) return E_POINTER;
        if (riid == IID_IUnknown || riid == IID_ICalc) {
            *ppv = static_cast<ICalc*>(this);
            AddRef();                     // 给出指针就要 AddRef——COM 铁律
            return S_OK;
        }
        *ppv = nullptr;
        return E_NOINTERFACE;
    }
    STDMETHODIMP_(ULONG) AddRef() override {
        return InterlockedIncrement(&m_ref);
    }
    STDMETHODIMP_(ULONG) Release() override {
        ULONG n = InterlockedDecrement(&m_ref);
        if (n == 0) delete this;          // 归零自毁——COM 的生命周期规则
        return n;
    }
    STDMETHODIMP Add(int a, int b, int* result) override {
        if (!result) return E_POINTER;
        *result = a + b;
        return S_OK;
    }
    STDMETHODIMP Sub(int a, int b, int* result) override {
        if (!result) return E_POINTER;
        *result = a - b;
        return S_OK;
    }
};

// ── 类厂：CoCreateInstance 与对象之间的中介 ────────────────────
class CalcFactory : public IClassFactory {
    LONG m_ref = 1;
public:
    STDMETHODIMP QueryInterface(REFIID riid, void** ppv) override {
        if (!ppv) return E_POINTER;
        if (riid == IID_IUnknown || riid == IID_IClassFactory) {
            *ppv = static_cast<IClassFactory*>(this);
            AddRef();
            return S_OK;
        }
        *ppv = nullptr;
        return E_NOINTERFACE;
    }
    STDMETHODIMP_(ULONG) AddRef() override { return InterlockedIncrement(&m_ref); }
    STDMETHODIMP_(ULONG) Release() override {
        ULONG n = InterlockedDecrement(&m_ref);
        if (n == 0) delete this;
        return n;
    }
    STDMETHODIMP CreateInstance(IUnknown* outer, REFIID riid, void** ppv) override {
        if (outer) return CLASS_E_NOAGGREGATION;   // 教学版不支持聚合
        Calc* obj = new (std::nothrow) Calc();
        if (!obj) return E_OUTOFMEMORY;
        HRESULT hr = obj->QueryInterface(riid, ppv);   // QI 已 AddRef
        obj->Release();                                // 抵消构造时的 1
        return hr;
    }
    STDMETHODIMP LockServer(BOOL) override {
        return S_OK;    // 教学版不做服务器级锁计数
    }
};

// ── 四个标准导出（COM DLL 的门面）────────────────────────────
STDAPI DllGetClassObject(REFCLSID rclsid, REFIID riid, void** ppv) {
    if (rclsid != CLSID_Calc) return CLASS_E_CLASSNOTAVAILABLE;
    CalcFactory* f = new (std::nothrow) CalcFactory();
    if (!f) return E_OUTOFMEMORY;
    HRESULT hr = f->QueryInterface(riid, ppv);
    f->Release();
    return hr;
}

STDAPI DllCanUnloadNow() {
    return S_FALSE;    // 教学版常驻内存
}

static const wchar_t* kClsidPath =
    L"Software\\Classes\\CLSID\\{6B92FBEE-1E6D-4010-9AC0-5783E288F9C1}";
static const wchar_t* kInproc =
    L"Software\\Classes\\CLSID\\{6B92FBEE-1E6D-4010-9AC0-5783E288F9C1}"
    L"\\InprocServer32";

STDAPI DllRegisterServer() {
    // 写 HKCU\Software\Classes\...：免管理员的 per-user 注册
    wchar_t path[MAX_PATH];
    GetModuleFileNameW(g_module, path, MAX_PATH);

    HKEY key;
    if (RegCreateKeyExW(HKEY_CURRENT_USER, kInproc, 0, nullptr, 0,
                        KEY_SET_VALUE, nullptr, &key, nullptr) != ERROR_SUCCESS) {
        return E_FAIL;
    }
    RegSetValueExW(key, nullptr, 0, REG_SZ, (const BYTE*)path,
                   (DWORD)((wcslen(path) + 1) * sizeof(wchar_t)));
    const wchar_t* apartment = L"Apartment";
    RegSetValueExW(key, L"ThreadingModel", 0, REG_SZ,
                   (const BYTE*)apartment,
                   (DWORD)((wcslen(apartment) + 1) * sizeof(wchar_t)));
    RegCloseKey(key);
    return S_OK;
}

STDAPI DllUnregisterServer() {
    RegDeleteTreeW(HKEY_CURRENT_USER, kClsidPath);
    return S_OK;
}

BOOL APIENTRY DllMain(HMODULE hinst, DWORD reason, LPVOID) {
    if (reason == DLL_PROCESS_ATTACH) {
        g_module = hinst;                  // 记下自己，注册时要写全路径
        DisableThreadLibraryCalls(hinst);
    }
    return TRUE;
}
