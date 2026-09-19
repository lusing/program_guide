// plugin_circle.cpp — 插件：圆面积（编译成 plugin_circle.dll）
#include "plugin_api.h"

static double CircleArea(double r) { return 3.14159265358979 * r * r; }

static const PluginInfo g_info = { PLUGIN_API_VERSION, L"圆形（πr²）", CircleArea };

extern "C" __declspec(dllexport) const PluginInfo* query_plugin(void) {
    return &g_info;
}
