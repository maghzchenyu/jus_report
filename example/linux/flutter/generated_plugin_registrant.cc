//
//  Generated file. Do not edit.
//

// clang-format off

#include "generated_plugin_registrant.h"

#include <jus_report/jus_report_plugin.h>
#include <sim_card_info/sim_card_info_plugin.h>

void fl_register_plugins(FlPluginRegistry* registry) {
  g_autoptr(FlPluginRegistrar) jus_report_registrar =
      fl_plugin_registry_get_registrar_for_plugin(registry, "JusReportPlugin");
  jus_report_plugin_register_with_registrar(jus_report_registrar);
  g_autoptr(FlPluginRegistrar) sim_card_info_registrar =
      fl_plugin_registry_get_registrar_for_plugin(registry, "SimCardInfoPlugin");
  sim_card_info_plugin_register_with_registrar(sim_card_info_registrar);
}
