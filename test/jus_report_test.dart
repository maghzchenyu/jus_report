import 'package:flutter_test/flutter_test.dart';
import 'package:jus_report/jus_report.dart';
import 'package:jus_report/jus_report_platform_interface.dart';
import 'package:jus_report/jus_report_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockJusReportPlatform
    with MockPlatformInterfaceMixin
    implements JusReportPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final JusReportPlatform initialPlatform = JusReportPlatform.instance;

  test('$MethodChannelJusReport is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelJusReport>());
  });

  test('getPlatformVersion', () async {
    JusReport jusReportPlugin = JusReport();
    MockJusReportPlatform fakePlatform = MockJusReportPlatform();
    JusReportPlatform.instance = fakePlatform;
  });
}
