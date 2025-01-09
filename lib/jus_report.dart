import 'dart:ffi';
import 'dart:io';

import 'package:advertising_id/advertising_id.dart';
import 'package:aliyun_log_dart_sdk/aliyun_log_dart_sdk.dart';
import 'package:android_id/android_id.dart';
import 'package:connection_network_type/connection_network_type.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/cupertino.dart';
import 'package:package_info/package_info.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sim_plugin/sim_plugin.dart';
import 'package:uuid/uuid.dart';

import 'jus_report_platform_interface.dart';

class JusReport {
  static JusReport? _instance;
  static const _androidIdPlugin = AndroidId();
  ReportPublicData _publicData = ReportPublicData();
  AliyunLogDartSdk? _aliyunLogSdk;
  bool _isInit = false;
  final String _deviceIdKey = "jus_device_id";

  late final AppLifecycleListener _appLifecycleListener;

  factory JusReport() {
    _instance ??= JusReport._internal();
    return _instance!;
  }

  JusReport._internal() {}

  Future<String?> getPlatformVersion() {
    return JusReportPlatform.instance.getPlatformVersion();
  }

  /// 初始化(可选字段除了forceInit，其他都是全局字段需要，如果初始化时无法获取，可在后去能够
  /// 获取到的时候通过getPublicData再设置)
  /// [forceInit] 是否强制初始化
  /// [googleID] 谷歌ID
  /// [platID] 平台ID
  /// [userID] 用户ID
  /// [systemLang] 系统语言
  /// [countryCode] 国家代码
  /// [premiumStatus] 会员订阅状态
  setupJusReport(
      {bool forceInit = false,
        String? googleID,
        String? platID,
        String? userID,
        String? systemLang,
        String? countryCode,
        int? premiumStatus,
        required String endpoint,
        required String project,
        required String logstore,
        required String accessKeyId,
        required String accessKeySecret}) {
    if (_isInit && !forceInit) {
      return;
    }
    _isInit = true;
    _setupAliLogSDK(endpoint, project, logstore, accessKeyId, accessKeySecret);
    _initGlobalReportData();
    _dynamicListen();
    _publicData.googleID = googleID;
    _publicData.platID = platID;
    _publicData.userID = userID;
    _publicData.systemLang = systemLang;
    _publicData.countryCode = countryCode;
  }

  /// 初始化埋点全局数据
  _initGlobalReportData() async {
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    _publicData.progressID = _getUUID();
    _publicData.sessionID = _getUUID();

    if (Platform.isAndroid) {
      _publicData.androidID = await _androidIdPlugin.getId();
      SharedPreferences prefs = await SharedPreferences.getInstance();
      if (_publicData.androidID != null) {
        _publicData.deviceID = _publicData.androidID;
      } else {
        _publicData.deviceID = prefs.getString(_deviceIdKey);
        if (_publicData.deviceID == null) {
          String deviceId = _getUUID();
          _publicData.deviceID = deviceId;
          prefs.setString(_deviceIdKey, deviceId);
        }
      }
    } else if (Platform.isIOS) {
      _publicData.deviceID = (await deviceInfo.iosInfo).identifierForVendor;
      _publicData.IDFV = _publicData.deviceID;
    }
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    _publicData.appName = packageInfo.appName;
    _publicData.appPackage = packageInfo.packageName;
    _publicData.clientVersion = packageInfo.version;
    if (Platform.isAndroid) {
      _publicData.systemType = "Android";
      _publicData.systemVersion =
          (await deviceInfo.androidInfo).version.release;
      _publicData.systemDeviceType = (await deviceInfo.androidInfo).model;
      _publicData.isEmulator = !(await deviceInfo.androidInfo).isPhysicalDevice;
    } else if (Platform.isIOS) {
      _publicData.systemType = "iOS";
      _publicData.systemVersion = (await deviceInfo.iosInfo).systemVersion;
      _publicData.systemDeviceType = (await deviceInfo.iosInfo).model;
      _publicData.isEmulator = !(await deviceInfo.iosInfo).isPhysicalDevice;
      _publicData.IDFA = await AdvertisingId.id(true);
    }

    NetworkStatus networkStatus = await ConnectionNetworkType().currentNetworkStatus();
    _publicData.network = _getNetworkStatusName(networkStatus);

    _getTelecomOper();
  }

  /// 获取运营商
  _getTelecomOper() async {
    try {
      final simPlugin = SimPlugin();
      final simSupportedIsOK = await simPlugin.simSupportedIsOK();
      final currentCarrierName = await simPlugin.getCurrentCarrierName();
      if (Platform.isAndroid) {
        _publicData.telecomOper = currentCarrierName;
      } else if (Platform.isIOS && simSupportedIsOK) {
        _publicData.telecomOper = currentCarrierName;
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  /// 监听一些可能全局变更的数据
  _dynamicListen(){
    ConnectionNetworkType().onNetworkStateChanged
        .listen((NetworkStatus networkStatus) {
      _publicData.network = _getNetworkStatusName(networkStatus);
    });

    _appLifecycleListener = AppLifecycleListener(
      onHide: _onHide,
    );
  }

  /// 进入后台回调
  _onHide(){
    _publicData.sessionID = _getUUID();
  }

  _setupAliLogSDK(String endpoint, String project, String logstore,
      String accessKeyId, String accessKeySecret) async {
    LogProducerConfiguration configuration = LogProducerConfiguration(
        endpoint: endpoint, project: project, logstore: logstore);
    //阿里云访问密钥AccessKey。更多信息，请参见访问密钥。阿里云账号AccessKey拥有所有API的访问权限，风险很高。强烈建议您创建并使用RAM用户进行API访问或日常运维。
    configuration.accessKeyId = accessKeyId;
    configuration.accessKeySecret = accessKeySecret;
    configuration.persistent = true;
    Directory directory = await getApplicationDocumentsDirectory();
    configuration.persistentFilePath = directory.path;
    configuration.persistentMaxFileCount = 20;
    _aliyunLogSdk = AliyunLogDartSdk();
    LogProducerResult result = await _aliyunLogSdk!.initProducer(configuration);
    print('init aliyun log sdk result: $result');
  }

  /// 生成UUID
  String _getUUID() {
    final uuidGenerator = Uuid();
    final uniqueIdV4 = uuidGenerator.v4();
    return uniqueIdV4;
  }

  /// 获取公共数据配置对象
  /// [publicData] 公共数据配置对象
  getPublicData() {
    return _publicData;
  }

  /// 从外部设置公共配置对象，会覆盖内部对象
  /// [publicData] 公共数据配置对象
  setPublicData(ReportPublicData publicData) {
    _publicData = publicData;
  }
  
  /// 上报事件
  /// [eventID] 事件ID
  /// [reportData] 上报数据
  reportEvent(String eventID, Map<String, dynamic> reportData) async {
    Map<String, dynamic> reportMap = _publicData.toJson();
    reportData.forEach((key, value) {
      reportMap[key] = value;
    });
    reportMap[_ReportJsonKey.requestID.name] = _getUUID();
    reportMap[_ReportJsonKey.eventID.name] = eventID;
    reportMap[_ReportJsonKey.eventTime.name] = DateTime.now().toString();
    reportMap[_ReportJsonKey.eventTimeStamp.name] = DateTime.now().millisecondsSinceEpoch;
    reportMap[_ReportJsonKey.timeZone.name] = DateTime.now().timeZoneName;
    LogProducerResult code = await _aliyunLogSdk!.addLog(reportMap);
    debugPrint('report event json: ${reportMap.toString()}');
    print('report event result: $code');
  }

  /// 获取网络状态名称
  /// [networkStatus] 网络状态
  _getNetworkStatusName(NetworkStatus networkStatus) {
    switch(networkStatus) {
      case NetworkStatus.unreachable:
        return "none";
      case NetworkStatus.wifi:
        return "wifi";
      case NetworkStatus.mobile2G:
        return "2G";
      case NetworkStatus.mobile3G:
        return "3G";
      case NetworkStatus.mobile4G:
        return "4G";
      case NetworkStatus.mobile5G:
        return "5G";
      case NetworkStatus.otherMobile:
        return "other";
    }
  }
}

class ReportPublicData {
  String? progressID;
  String? sessionID;
  String? IDFA;
  String? IDFV;
  String? androidID;
  String? googleID;
  String? firebaseID;
  String? appName;
  String? platID;
  String? userID;
  String? appPackage;
  String? clientVersion;
  String? telecomOper;
  String? systemType;
  String? systemVersion;
  String? systemDeviceType;
  String? network;
  int? proxy;
  String? systemLang;
  bool? isEmulator;
  String? deviceID;
  String? countryCode;
  int? premiumStatus;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> map = {};
    map[_ReportJsonKey.progressID.name] = progressID;
    map[_ReportJsonKey.sessionID.name] = sessionID;
    map[_ReportJsonKey.IDFA.name] = IDFA;
    map[_ReportJsonKey.IDFV.name] = IDFV;
    map[_ReportJsonKey.androidID.name] = androidID;
    map[_ReportJsonKey.googleID.name] = googleID;
    map[_ReportJsonKey.firebaseID.name] = firebaseID;
    map[_ReportJsonKey.appName.name] = appName;
    map[_ReportJsonKey.platID.name] = platID;
    map[_ReportJsonKey.userID.name] = userID;
    map[_ReportJsonKey.appPackage.name] = appPackage;
    map[_ReportJsonKey.clientVersion.name] = clientVersion;
    map[_ReportJsonKey.telecomOper.name] = telecomOper;
    map[_ReportJsonKey.systemType.name] = systemType;
    map[_ReportJsonKey.systemVersion.name] = systemVersion;
    map[_ReportJsonKey.systemDeviceType.name] = systemDeviceType;
    map[_ReportJsonKey.network.name] = network;
    map[_ReportJsonKey.systemLang.name] = systemLang;
    map[_ReportJsonKey.isEmulator.name] = isEmulator;
    map[_ReportJsonKey.deviceID.name] = deviceID;
    map[_ReportJsonKey.countryCode.name] = countryCode;
    map[_ReportJsonKey.premiumStatus.name] = premiumStatus;
    return map;

  }
}

enum _ReportJsonKey {
  requestID,
  eventID,
  systemDeviceType,
  progressID,
  sessionID,
  eventTime,
  eventTimeStamp,
  timeZone,
  deviceID,
  IDFA,
  IDFV,
  androidID,
  googleID,
  firebaseID,
  domainID,
  platID,
  userID,
  premiumStatus,
  appPlatfrom,
  appPackage,
  countryCode,
  clientVersion,
  telecomOper,
  systemType,
  network,
  proxy,
  systemLang,
  isEmulator,
  appName,
  systemVersion
}
