#ifndef FLUTTER_PLUGIN_GUIDE_BATTERY_PLUGIN_H_
#define FLUTTER_PLUGIN_GUIDE_BATTERY_PLUGIN_H_

#include <flutter/event_channel.h>
#include <flutter/event_sink.h>
#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>

#include <atomic>
#include <memory>
#include <mutex>
#include <string>
#include <thread>

namespace guide_battery {

class GuideBatteryPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

  GuideBatteryPlugin();

  virtual ~GuideBatteryPlugin();

  // Disallow copy and assign.
  GuideBatteryPlugin(const GuideBatteryPlugin&) = delete;
  GuideBatteryPlugin& operator=(const GuideBatteryPlugin&) = delete;

  // Handles 'getBatteryLevel' on the method channel.
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

 private:
  // EventChannel onListen: take the sink and start the poll thread.
  void StartStatusStream(
      std::unique_ptr<flutter::EventSink<flutter::EncodableValue>> sink);

  // EventChannel onCancel: stop the thread and drop the sink.
  void StopStatusStream();

  // Read system power status once; maps to "full"/"charging"/"discharging".
  static std::string ReadStatus();

  // Poll loop running on its own thread; pushes changes through the sink.
  void PollLoop();

  std::unique_ptr<flutter::EventChannel<flutter::EncodableValue>>
      status_channel_;
  std::unique_ptr<flutter::EventSink<flutter::EncodableValue>> sink_;
  std::mutex sink_mutex_;
  std::thread poll_thread_;
  std::atomic<bool> polling_{false};
};

}  // namespace guide_battery

#endif  // FLUTTER_PLUGIN_GUIDE_BATTERY_PLUGIN_H_
