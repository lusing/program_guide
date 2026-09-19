// plugin_square.cpp — 插件：正方形面积（编译成 plugin_square.dll）
#include "plugin_api.h"

static double SquareArea(double a) { return a * a; }

static const PluginInfo g_info = { PLUGIN_API_VERSION, L"正方形（a²）", SquareArea };

extern "C" __declspec(dllexport) const PluginInfo* query_plugin(void) {
    return &g_info;
}
