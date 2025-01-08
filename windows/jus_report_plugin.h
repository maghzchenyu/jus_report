#ifndef FLUTTER_PLUGIN_JUS_REPORT_PLUGIN_H_
#define FLUTTER_PLUGIN_JUS_REPORT_PLUGIN_H_

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>

#include <memory>

namespace jus_report {

class JusReportPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

  JusReportPlugin();

  virtual ~JusReportPlugin();

  // Disallow copy and assign.
  JusReportPlugin(const JusReportPlugin&) = delete;
  JusReportPlugin& operator=(const JusReportPlugin&) = delete;

  // Called when a method is called on this plugin's channel from Dart.
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
};

}  // namespace jus_report

#endif  // FLUTTER_PLUGIN_JUS_REPORT_PLUGIN_H_
