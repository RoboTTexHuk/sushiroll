import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show MethodCall, MethodChannel;
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:timezone/data/latest.dart' as tzd;
import 'package:timezone/timezone.dart' as tzu;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:app_tracking_transparency/app_tracking_transparency.dart'
    show AppTrackingTransparency, TrackingStatus;
import 'package:appsflyer_sdk/appsflyer_sdk.dart'
    show AppsFlyerOptions, AppsflyerSdk;

import 'main.dart' show FILT;

// --- MVVM/Provider слои ---

// Модель-пингвин
class PenguinDeviceModel {
  final String? penguinId;
  final String? instanceIceberg;
  final String? osType;
  final String? osVersion;
  final String? appVersion;
  final String? language;
  final String? timezone;
  final bool pushEnabled;

  PenguinDeviceModel({
    this.penguinId,
    this.instanceIceberg,
    this.osType,
    this.osVersion,
    this.appVersion,
    this.language,
    this.timezone,
    required this.pushEnabled,
  });

  Map<String, dynamic> toJson({String? fishToken}) => {
    "fcm_token": fishToken ?? "no_fcm_token",
    "device_id": penguinId ?? 'no_penguin',
    "app_name": "Sushiroll",
    "instance_id": instanceIceberg ?? 'no_iceberg',
    "platform": osType ?? 'no_type',
    "os_version": osVersion ?? 'no_os',
    "app_version": appVersion ?? 'no_app',
    "language": language ?? 'en',
    "timezone": timezone ?? 'UTC',
    "push_enabled": pushEnabled,
  };
}

// Репозиторий-Антарктида
class AntarcticaRepository {
  Future<PenguinDeviceModel> getPenguinInfo() async {
    final deviceInfo = DeviceInfoPlugin();
    String? penguinId, osType, osVersion;
    if (Platform.isAndroid) {
      final info = await deviceInfo.androidInfo;
      penguinId = info.id;
      osType = "android";
      osVersion = info.version.release;
    } else if (Platform.isIOS) {
      final info = await deviceInfo.iosInfo;
      penguinId = info.identifierForVendor;
      osType = "ios";
      osVersion = info.systemVersion;
    }
    final packageInfo = await PackageInfo.fromPlatform();
    final language = Platform.localeName.split('_')[0];
    final timezone = tzu.local.name;
    return PenguinDeviceModel(
      penguinId: penguinId ?? 'no_penguin',
      instanceIceberg: "iceberg-${DateTime.now().millisecondsSinceEpoch}",
      osType: osType ?? 'unknown',
      osVersion: osVersion ?? 'unknown',
      appVersion: packageInfo.version,
      language: language,
      timezone: timezone,
      pushEnabled: true,
    );
  }
}

// ViewModel-Щука (логика для данных)
class PikeViewModel extends ChangeNotifier {
  PenguinDeviceModel? penguin;
  Future<void> fetchPenguin() async {
    penguin = await AntarcticaRepository().getPenguinInfo();
    notifyListeners();
  }
}

// ViewModel для пушей
class CrabPushViewModel extends ChangeNotifier {
  String? crabToken;
  bool isWaiting = true;

  Future<void> requestCrabToken() async {
    FirebaseMessaging m = FirebaseMessaging.instance;
    await m.requestPermission(alert: true, badge: true, sound: true);
    crabToken = await m.getToken();
    isWaiting = false;
    notifyListeners();
  }
}

// ViewModel для AppsFlyer
class SquidAnalyticsViewModel extends ChangeNotifier {
  AppsflyerSdk? _squid;
  String squidId = "";
  String squidConversion = "";

  void initSquid(VoidCallback onUpdate) {
    final options = AppsFlyerOptions(
      afDevKey: "qsBLmy7dAXDQhowM8V3ca4",
      appId: "6747172624",
      showDebug: true,
    );
    _squid = AppsflyerSdk(options);
    _squid?.initSdk(
      registerConversionDataCallback: true,
      registerOnAppOpenAttributionCallback: true,
      registerOnDeepLinkingCallback: true,
    );
    _squid?.startSDK(
      onSuccess: () => print("Squid Analytics swim!"),
      onError: (int code, String msg) => print("Squid error $code $msg"),
    );
    _squid?.onInstallConversionData((result) {
      squidConversion = result.toString();
      onUpdate();
    });
    _squid?.getAppsFlyerUID().then((val) {
      squidId = val.toString();
      onUpdate();
    });
  }
}

// ViewModel-осьминог для ATT
class OctopusAttViewModel extends ChangeNotifier {
  TrackingStatus attStatus = TrackingStatus.notDetermined;
  String uuid = "";

  Future<void> requestAtt() async {
    attStatus = await AppTrackingTransparency.trackingAuthorizationStatus;
    if (attStatus == TrackingStatus.notDetermined) {
      await Future.delayed(const Duration(milliseconds: 1000));
      await AppTrackingTransparency.requestTrackingAuthorization();
      attStatus = await AppTrackingTransparency.trackingAuthorizationStatus;
    }
    uuid = await AppTrackingTransparency.getAdvertisingIdentifier();
    notifyListeners();
  }
}

// ---------- WIDGET+MVVM Вебвью (SushiRollPage) -----------

class SushiRollPushPage extends StatelessWidget {
  final String url;
  const SushiRollPushPage(this.url, {super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PikeViewModel()..fetchPenguin()),
        ChangeNotifierProvider(create: (_) => CrabPushViewModel()..requestCrabToken()),
        ChangeNotifierProvider(create: (_) => SquidAnalyticsViewModel()..initSquid(() {})),
        ChangeNotifierProvider(create: (_) => OctopusAttViewModel()..requestAtt()),
      ],
      child: _SushiRollPushMVVM(url: url),
    );
  }
}

class _SushiRollPushMVVM extends StatefulWidget {
  final String url;
  const _SushiRollPushMVVM({required this.url});

  @override
  State<_SushiRollPushMVVM> createState() => _SushiRollPushMVVMState();
}

class _SushiRollPushMVVMState extends State<_SushiRollPushMVVM> {
  late InAppWebViewController _octoController;
  bool _loading = false;
  final List<ContentBlocker> _blockers = [];

  @override
  void initState() {
    super.initState();

    _blockers.add(ContentBlocker(
      trigger: ContentBlockerTrigger(urlFilter: ".cookie", resourceType: [ContentBlockerTriggerResourceType.RAW]),
      action: ContentBlockerAction(type: ContentBlockerActionType.BLOCK, selector: ".notification"),
    ));
    _blockers.add(ContentBlocker(
      trigger: ContentBlockerTrigger(urlFilter: ".cookie", resourceType: [ContentBlockerTriggerResourceType.RAW]),
      action: ContentBlockerAction(type: ContentBlockerActionType.CSS_DISPLAY_NONE, selector: ".privacy-info"),
    ));
    _blockers.add(ContentBlocker(
      trigger: ContentBlockerTrigger(urlFilter: ".*"),
      action: ContentBlockerAction(type: ContentBlockerActionType.CSS_DISPLAY_NONE, selector: ".banner, .banners, .ads, .ad, .advert"),
    ));

    _setupChannels();
 //   FirebaseMessaging.onBackgroundMessage(_msgBgHandler);
    FirebaseMessaging.onMessage.listen((RemoteMessage msg) {
      if (msg.data['uri'] != null) {
        _loadUrl(msg.data['uri'].toString());
      } else {
        _resetUrl();
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage msg) {
      if (msg.data['uri'] != null) {
        _loadUrl(msg.data['uri'].toString());
      } else {
        _resetUrl();
      }
    });

    Future.delayed(const Duration(seconds: 6), () {
      _sendSquidDataToWeb();
    });
  }

  void _setupChannels() {
    MethodChannel('com.example.fcm/notification').setMethodCallHandler((call) async {
      if (call.method == "onNotificationTap") {
        final Map<String, dynamic> data = Map<String, dynamic>.from(call.arguments);
        if (data["uri"] != null && !data["uri"].contains("Нет URI")) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => SushiRollPushPage(data["uri"])),
                (route) => false,
          );
        }
      }
    });
  }

  void _loadUrl(String uri) async {
    await _octoController.loadUrl(urlRequest: URLRequest(url: WebUri(uri)));
  }

  void _resetUrl() async {
    Future.delayed(const Duration(seconds: 3), () {
      _octoController.loadUrl(urlRequest: URLRequest(url: WebUri(widget.url)));
    });
  }

  Future<void> _sendSquidDataToWeb() async {
    final penguinVM = context.read<PikeViewModel>();
    final squidVM = context.read<SquidAnalyticsViewModel>();

    if (penguinVM.penguin == null) return;

    final data = {
      "content": {
        "af_data": squidVM.squidConversion,
        "af_id": squidVM.squidId,
        "fb_app_name": "Sushiroll",
        "app_name": "Sushiroll",
        "deep": null,
        "bundle_identifier": "sushiroll.cushiorl.surollx",
        "app_version": "1.0.0",
        "apple_id": "6747172624",
        "device_id": penguinVM.penguin!.penguinId ?? "default_device_id",
        "instance_id": penguinVM.penguin!.instanceIceberg ?? "default_instance_id",
        "platform": penguinVM.penguin!.osType ?? "unknown_platform",
        "os_version": penguinVM.penguin!.osVersion ?? "default_os_version",
        "app_version": penguinVM.penguin!.appVersion ?? "default_app_version",
        "language": penguinVM.penguin!.language ?? "en",
        "timezone": penguinVM.penguin!.timezone ?? "UTC",
        "push_enabled": penguinVM.penguin!.pushEnabled,
        "useruid": squidVM.squidId,
      },
    };
    final jsonString = jsonEncode(data);
    print("SUSHI SQUID JSON $jsonString");
    await _octoController.evaluateJavascript(
      source: "sendRawData(${jsonEncode(jsonString)});",
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          InAppWebView(
            initialSettings: InAppWebViewSettings(
              javaScriptEnabled: true,

              disableDefaultErrorPage: true,
              mediaPlaybackRequiresUserGesture: true,
              allowsInlineMediaPlayback: true,
              allowsPictureInPictureMediaPlayback: true,
              useOnDownloadStart: true,
              supportZoom: true,
              contentBlockers: _blockers,
              javaScriptCanOpenWindowsAutomatically: true,
            ),
            initialUrlRequest: URLRequest(url: WebUri(widget.url)),
            onWebViewCreated: (controller) {
              _octoController = controller;
              _octoController.addJavaScriptHandler(
                  handlerName: 'onServerResponse',
                  callback: (args) {
                    print("🐟 JS args: $args");
                    return args.reduce((curr, next) => curr + next);
                  });
            },
            onLoadStop: (controller, url) async {
              await controller.evaluateJavascript(source: "console.log('Hello from JS!');");
            },
            shouldOverrideUrlLoading: (controller, navigationAction) async {
              return NavigationActionPolicy.ALLOW;
            },
          ),
          if (_loading) const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}