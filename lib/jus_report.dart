
import 'jus_report_platform_interface.dart';

class JusReport {
  Future<String?> getPlatformVersion() {
    return JusReportPlatform.instance.getPlatformVersion();
  }
}
