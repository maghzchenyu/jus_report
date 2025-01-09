//
//  Generated file. Do not edit.
//

import FlutterMacOS
import Foundation

import device_info_plus
import jus_report
import network_info_plus
import package_info
import path_provider_foundation
import shared_preferences_foundation
import sim_card_info

func RegisterGeneratedPlugins(registry: FlutterPluginRegistry) {
  DeviceInfoPlusMacosPlugin.register(with: registry.registrar(forPlugin: "DeviceInfoPlusMacosPlugin"))
  JusReportPlugin.register(with: registry.registrar(forPlugin: "JusReportPlugin"))
  NetworkInfoPlusPlugin.register(with: registry.registrar(forPlugin: "NetworkInfoPlusPlugin"))
  FLTPackageInfoPlugin.register(with: registry.registrar(forPlugin: "FLTPackageInfoPlugin"))
  PathProviderPlugin.register(with: registry.registrar(forPlugin: "PathProviderPlugin"))
  SharedPreferencesPlugin.register(with: registry.registrar(forPlugin: "SharedPreferencesPlugin"))
  SimCardInfoPlugin.register(with: registry.registrar(forPlugin: "SimCardInfoPlugin"))
}
