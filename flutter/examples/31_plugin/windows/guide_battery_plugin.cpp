#include "guide_battery_plugin.h"

// This must be included before many other Windows headers.
#include <windows.h>

#include <chrono>
#include <memory>

#include <flutter/event_stream_handler_functions.h>

namespace guide_battery {

// static
void GuideBatteryPlugin::RegisterWithRegistrar(
    flutter::PluginRegistrarWindows *registrar) {
  // Method channel: Dart asks, native answers.
  auto method_channel =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          registrar->messenger(), "guide_battery",
          &flutter::StandardMethodCodec::GetInstance());

  auto plugin = std::make_unique<GuideBatteryPlugin>();

  method_channel->SetMethodCallHandler(
      [plugin_pointer = plugin.get()](const auto &call, auto result) {
        plugin_pointer->HandleMethodCall(call, std::move(result));
      });

  // Event channel: native pushes, Dart listens.
  // The channel name must match the Dart-side EventChannel exactly.
  plugin->status_channel_ =
      std::make_unique<flutter::EventChannel<flutter::EncodableValue>>(
          registrar->messenger(), "guide_battery_status",
          &flutter::StandardMethodCodec::GetInstance());

  // StreamHandlerFunctions: the two callbacks map to onListen / onCancel.
  auto handler =
      std::make_unique<flutter::StreamHandlerFunctions<flutter::EncodableValue>>(
          [plugin_pointer = plugin.get()](
              const flutter::EncodableValue *arguments,
              std::unique_ptr<flutter::EventSink<flutter::EncodableValue>> &&events) {
            plugin_pointer->StartStatusStream(std::move(events));
            return nullptr;
          },
          [plugin_pointer = plugin.get()](const flutter::EncodableValue *arguments) {
            plugin_pointer->StopStatusStream();
            return nullptr;
          });

  plugin->status_channel_->SetStreamHandler(std::move(handler));

  registrar->AddPlugin(std::move(plugin));
}

GuideBatteryPlugin::GuideBatteryPlugin() {}

GuideBatteryPlugin::~GuideBatteryPlugin() {
  // Stop the thread before members die: the loop must not touch a dying sink.
  StopStatusStream();
}

void GuideBatteryPlugin::HandleMethodCall(
    const flutter::MethodCall<flutter::EncodableValue> &method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  if (method_call.method_name().compare("getBatteryLevel") == 0) {
    SYSTEM_POWER_STATUS sps;
    if (GetSystemPowerStatus(&sps) &&
        sps.BatteryLifePercent != 255) {  // 255 = unknown (desktop PC)
      result->Success(flutter::EncodableValue(
          static_cast<int32_t>(sps.BatteryLifePercent)));
    } else {
      // Error(code, message, details) becomes a PlatformException on Dart side.
      result->Error("UNAVAILABLE", "battery level not readable on this machine");
    }
  } else {
    result->NotImplemented();
  }
}

void GuideBatteryPlugin::StartStatusStream(
    std::unique_ptr<flutter::EventSink<flutter::EncodableValue>> sink) {
  StopStatusStream();  // re-listen after hot restart: clean up first
  {
    std::lock_guard<std::mutex> lock(sink_mutex_);
    sink_ = std::move(sink);
  }
  polling_ = true;
  poll_thread_ = std::thread([this]() { PollLoop(); });
}

void GuideBatteryPlugin::StopStatusStream() {
  polling_ = false;
  if (poll_thread_.joinable()) {
    poll_thread_.join();
  }
  std::lock_guard<std::mutex> lock(sink_mutex_);
  sink_ = nullptr;
}

// static
std::string GuideBatteryPlugin::ReadStatus() {
  SYSTEM_POWER_STATUS sps;
  if (GetSystemPowerStatus(&sps)) {
    if (sps.ACLineStatus == 1) {  // plugged in
      return (sps.BatteryLifePercent >= 100) ? "full" : "charging";
    }
    return "discharging";
  }
  return "unknown";
}

void GuideBatteryPlugin::PollLoop() {
  std::string last;
  // Half-second cadence: snappy enough for plug/unplug, negligible CPU.
  // A production plugin would listen for WM_POWERBROADCAST instead.
  while (polling_) {
    const std::string status = ReadStatus();
    if (status != last) {
      last = status;
      std::lock_guard<std::mutex> lock(sink_mutex_);
      if (sink_) {
        sink_->Success(flutter::EncodableValue(status));
      }
    }
    std::this_thread::sleep_for(std::chrono::milliseconds(500));
  }
}

}  // namespace guide_battery
