#include "include/guide_battery/guide_battery_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "guide_battery_plugin.h"

void GuideBatteryPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  guide_battery::GuideBatteryPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
