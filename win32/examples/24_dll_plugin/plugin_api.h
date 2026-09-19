// plugin_api.h — 宿主与插件之间的唯一契约：纯 C、无 CRT 依赖
#pragma once

#define PLUGIN_API_VERSION 1

typedef struct PluginInfo {
    int apiVersion;              // 宿主先核对版本再使用
    const wchar_t* name;
    double (*area)(double r);    // 纯函数：不跨边界分配/释放内存
} PluginInfo;

// 每个插件导出这一个函数，返回只读信息结构：
// extern "C" __declspec(dllexport) const PluginInfo* query_plugin(void);
typedef const PluginInfo* (*PFN_query_plugin)(void);
