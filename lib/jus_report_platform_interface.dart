import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'jus_report_method_channel.dart';

abstract class JusReportPlatform extends PlatformInterface {
  /// Constructs a JusReportPlatform.
  JusReportPlatform() : super(token: _token);

  static final Object _token = Object();

  static JusReportPlatform _instance = MethodChannelJusReport();

  /// The default instance of [JusReportPlatform] to use.
  ///
  /// Defaults to [MethodChannelJusReport].
  static JusReportPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [JusReportPlatform] when
  /// they register themselves.
  static set instance(JusReportPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
