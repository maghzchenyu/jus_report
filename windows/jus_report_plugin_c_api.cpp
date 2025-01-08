#include "include/jus_report/jus_report_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "jus_report_plugin.h"

void JusReportPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  jus_report::JusReportPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
