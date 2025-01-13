import 'dart:io';

import 'package:advertising_id/advertising_id.dart';
import 'package:aliyun_log_dart_sdk/aliyun_log_dart_sdk.dart';
import 'package:android_id/android_id.dart';
import 'package:connection_network_type/connection_network_type.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:package_info/package_info.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sim_plugin/sim_plugin.dart';
import 'package:uuid/uuid.dart';

class JSReport {
  static JSReport? _instance;
  static const _androidIdPlugin = AndroidId();
  final _publicData = _ReportPublicData();
  AliyunLogDartSdk? _aliyunLogSdk;
  late final AppLifecycleListener _appLifecycleListener;
  final _userProperty = <String, dynamic>{};
  var _isDebug = false;

  factory JSReport() {
    _instance ??= JSReport._internal();
    return _instance!;
  }

  JSReport._internal() {}

  /// 初始化
  /// [isDebug] 是否开启日志
  /// [endpoint] 日志服务地址
  /// [project] 日志服务项目
  /// [logstore] 日志服务日志库
  /// [accessKeyId] 日志服务AccessKeyId
  /// [accessKeySecret] 日志服务AccessKeySecret
  setup(
      {bool? isDebug,
      required String endpoint,
      required String project,
      required String logstore,
      required String accessKeyId,
      required String accessKeySecret}) async {
    if (isDebug != null) {
      _isDebug = isDebug;
    }
    await _setupAliLogSDK(
        endpoint, project, logstore, accessKeyId, accessKeySecret);
    await _initGlobalReportData();
    _dynamicListen();
  }

  /// 设置用户ID
  /// [userId] 用户ID
  setUserId(String userId) {
    _publicData.userID = userId;
  }

  /// 设置用户全局属性
  /// [name] 属性名
  /// [value] 属性值
  setUserProperty({
    required String name,
    required dynamic? value,
  }) {
    _userProperty[name] = value;
  }

  /// 设置用户全局属性
  /// [properties] 属性集合
  serUserProperties(Map<String, dynamic> properties) {
    _userProperty.addAll(properties);
  }

  /// 移除用户全局属性
  /// [name] 属性名
  removeUserProperty(String name) {
    _userProperty.remove(name);
  }

  /// 移除所有用户全局属性
  removeAllUserProperty() {
    _userProperty.clear();
  }

  /// 设置context，之后在插件内部获取一些需要context获取的数据
  /// [context] context
  setContext(BuildContext context) {
    _publicData.systemLang = Localizations.localeOf(context).languageCode;
  }

  /// 初始化埋点全局数据
  _initGlobalReportData() async {
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    _publicData.processID = _getUUID();
    _publicData.sessionID = _getUUID();
    if (Platform.isAndroid) {
      _publicData.androidID = await _androidIdPlugin.getId();
    } else if (Platform.isIOS) {
      _publicData.IDFV = (await deviceInfo.iosInfo).identifierForVendor;
    }
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    _publicData.appName = packageInfo.appName;
    _publicData.packageName = packageInfo.packageName;
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
    NetworkStatus networkStatus =
        await ConnectionNetworkType().currentNetworkStatus();
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
  _dynamicListen() {
    ConnectionNetworkType()
        .onNetworkStateChanged
        .listen((NetworkStatus networkStatus) {
      _publicData.network = _getNetworkStatusName(networkStatus);
    });
    _appLifecycleListener = AppLifecycleListener(
      onHide: _onHide,
    );
  }

  /// 进入后台回调
  _onHide() {
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
    Directory directory = await getApplicationSupportDirectory();
    configuration.persistentFilePath = directory.path;
    configuration.persistentMaxFileCount = 20;
    _aliyunLogSdk = AliyunLogDartSdk();
    LogProducerResult result = await _aliyunLogSdk!.initProducer(configuration);
    if (_isDebug) {
      print('aliyun log init result: ${result.toString()}');
    }
  }

  /// 生成UUID
  String _getUUID() {
    final uuidGenerator = Uuid();
    final uniqueIdV4 = uuidGenerator.v4();
    return uniqueIdV4;
  }

  /// 上报事件
  /// [reportData] 上报数据
  logEvent(Map<String, dynamic> reportData) async {
    Map<String, dynamic> reportMap = _publicData.toJson();
    reportData.forEach((key, value) {
      reportMap[key] = value;
    });
    _userProperty.forEach((key, value) {
      reportMap[key] = value;
    });
    DateTime dateTime = DateTime.now();
    DateFormat formatter = DateFormat('yyyy-MM-dd HH:mm:ss');
    String formatted = formatter.format(dateTime);
    reportMap[_ReportJsonKey.eventID.name] =  _getUUID();
    reportMap[_ReportJsonKey.eventTime.name] = formatted;
    reportMap[_ReportJsonKey.eventTimeStamp.name] =
        dateTime.millisecondsSinceEpoch;
    reportMap[_ReportJsonKey.timeZone.name] = dateTime.timeZoneName;
    LogProducerResult code = await _aliyunLogSdk!.addLog(reportMap);
    if (_isDebug) {
      print('aliyun log add log data: ${reportMap.toString()}');
      print('aliyun log add log result code: $code');
    }
  }

  /// 获取网络状态名称
  /// [networkStatus] 网络状态
  _getNetworkStatusName(NetworkStatus networkStatus) {
    switch (networkStatus) {
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

class _ReportPublicData {
  /// 用户ID
  String? userID;
  /// 进程ID
  String? processID;
  /// AndroidID
  String? androidID;
  /// 会话ID，一次完成的前台生命周期
  String? sessionID;
  /// iOS 广告ID
  String? IDFA;
  /// iOS 设备ID
  String? IDFV;
  /// FirebaseID
  String? firebaseID;
  /// 应用名
  String? appName;
  /// 平台ID
  String? platID;
  /// 包名
  String? packageName;
  /// 客户端版本
  String? clientVersion;
  /// 运营商
  String? telecomOper;
  /// 系统类型
  String? systemType;
  /// 系统版本
  String? systemVersion;
  /// 系统设备类型
  String? systemDeviceType;
  /// 网络类型
  String? network;
  // int? proxy;
  /// 系统语言
  String? systemLang;
  /// 是否模拟器
  bool? isEmulator;
  /// 设备唯一标识
  String? deviceID;
  /// 国家码
  String? countryCode;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> map = {};
    map[_ReportJsonKey.processID.name] = processID;
    map[_ReportJsonKey.sessionID.name] = sessionID;
    map[_ReportJsonKey.IDFA.name] = IDFA;
    map[_ReportJsonKey.IDFV.name] = IDFV;
    map[_ReportJsonKey.androidID.name] = androidID;
    map[_ReportJsonKey.firebaseID.name] = firebaseID;
    map[_ReportJsonKey.appName.name] = appName;
    map[_ReportJsonKey.platID.name] = platID;
    map[_ReportJsonKey.userID.name] = userID;
    map[_ReportJsonKey.packageName.name] = packageName;
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
    return map;
  }
}

enum _ReportJsonKey {
  eventID,
  systemDeviceType,
  processID,
  sessionID,
  eventTime,
  eventTimeStamp,
  timeZone,
  deviceID,
  IDFA,
  IDFV,
  androidID,
  firebaseID,
  platID,
  userID,
  packageName,
  countryCode,
  clientVersion,
  telecomOper,
  systemType,
  network,
  systemLang,
  isEmulator,
  appName,
  systemVersion,
}
