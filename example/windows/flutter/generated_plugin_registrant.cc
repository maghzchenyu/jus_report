//
//  Generated file. Do not edit.
//

// clang-format off

#include "generated_plugin_registrant.h"

#include <jus_report/jus_report_plugin_c_api.h>
#include <permission_handler_windows/permission_handler_windows_plugin.h>
#include <sim_card_info/sim_card_info_plugin_c_api.h>

void RegisterPlugins(flutter::PluginRegistry* registry) {
  JusReportPluginCApiRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("JusReportPluginCApi"));
  PermissionHandlerWindowsPluginRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("PermissionHandlerWindowsPlugin"));
  SimCardInfoPluginCApiRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("SimCardInfoPluginCApi"));
}
