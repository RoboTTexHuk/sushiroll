import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show MethodChannel;
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:timezone/data/latest.dart' as tzd;
import 'package:timezone/timezone.dart' as tzu;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:appsflyer_sdk/appsflyer_sdk.dart';
import 'package:url_launcher/url_launcher.dart' show canLaunchUrl, launchUrl, LaunchMode;

import 'WP.dart' show SushiRollPushPage;

final List<String> BANANA_AD_URLS = [
  ".*.doubleclick.net/.*",
  ".*.ads.pubmatic.com/.*",
  ".*.googlesyndication.com/.*",
  ".*.google-analytics.com/.*",
  ".*.adservice.google.*/.*",
  ".*.adbrite.com/.*",
  ".*.exponential.com/.*",
  ".*.quantserve.com/.*",
  ".*.scorecardresearch.com/.*",
  ".*.zedo.com/.*",
  ".*.adsafeprotected.com/.*",
  ".*.teads.tv/.*",
  ".*.outbrain.com/.*",
];

// --------- SUPER NESTED SINGLETON -------------
class BananaSingleton {
  static final BananaSingleton _willy = BananaSingleton._internal();
  factory BananaSingleton() => _willy;
  BananaSingleton._internal();

  final BananaTokenProvider tokenProvider = BananaTokenProvider();
  final WatermelonDeviceRepo deviceRepo = WatermelonDeviceRepo();
  final PineappleAnalyticsVM analyticsVM = PineappleAnalyticsVM();
  final OrangePushManager pushManager = OrangePushManager();
  final CrazyLoaderProvider loaderProvider = CrazyLoaderProvider();
  final NestedInjector nestedInjector = NestedInjector();
}

// --------- INJECTOR CHAIN -------------
class NestedInjector {
  final SubInjector subInjector = SubInjector();
  DataMegaInjector get dataMegaInjector => subInjector.dataMegaInjector;
}

class SubInjector {
  final DataMegaInjector dataMegaInjector = DataMegaInjector();
}

class DataMegaInjector {
  final DataSubInjector dataSubInjector = DataSubInjector();
}

class DataSubInjector {
  final CatnipInjector catnipInjector = CatnipInjector();
  final PineapplePurrInjector pineapplePurrInjector = PineapplePurrInjector();

  ChonkyDeviceEntity? cachedDeviceEntity;
  void storeDevice(ChonkyDeviceEntity entity) {
    cachedDeviceEntity = entity;
  }
}

class CatnipInjector {
  Future<void> injectCatnip(InAppWebViewController controller, ChonkyDeviceEntity entity, String? token) async {
    await controller.evaluateJavascript(source: '''
      localStorage.setItem('catnip', JSON.stringify(${jsonEncode(entity.toJson(fcmToken: token))}));
    ''');
  }
}

class PineapplePurrInjector {
  Future<void> injectPurr(InAppWebViewController controller, Map<String, dynamic> purrData) async {
    await controller.evaluateJavascript(
        source: "sendRawData(${jsonEncode(jsonEncode(purrData))});");
  }
}

// --------- МОДЕЛЬКА-ДАННЫХ -------------
class ChonkyDeviceEntity {
  final String? deviceId;
  final String? instanceId;
  final String? osType;
  final String? osVersion;
  final String? appVersion;
  final String? language;
  final String? timezone;
  final bool pushEnabled;

  ChonkyDeviceEntity({
    this.deviceId,
    this.instanceId,
    this.osType,
    this.osVersion,
    this.appVersion,
    this.language,
    this.timezone,
    required this.pushEnabled,
  });

  Map<String, dynamic> toJson({String? fcmToken}) => {
    "fcm_token": fcmToken ?? "no_fcm_token",
    "device_id": deviceId ?? 'no_device',
    "app_name": "Sushiroll",
    "instance_id": instanceId ?? 'no_instance',
    "platform": osType ?? 'no_type',
    "os_version": osVersion ?? 'no_os',
    "app_version": appVersion ?? 'no_app',
    "language": language ?? 'en',
    "timezone": timezone ?? 'UTC',
    "push_enabled": pushEnabled,
  };
}

// --------- РЕПОЗИТОРИЙ-АРБУЗ -------------
class WatermelonDeviceRepo {
  Future<ChonkyDeviceEntity> fetchWatermelonInfo() async {
    final deviceInfo = DeviceInfoPlugin();
    String? deviceId, osType, osVersion;
    if (Platform.isAndroid) {
      final info = await deviceInfo.androidInfo;
      deviceId = info.id;
      osType = "android";
      osVersion = info.version.release;
    } else if (Platform.isIOS) {
      final info = await deviceInfo.iosInfo;
      deviceId = info.identifierForVendor;
      osType = "ios";
      osVersion = info.systemVersion;
    }
    final packageInfo = await PackageInfo.fromPlatform();
    final language = Platform.localeName.split('_')[0];
    final timezone = tzu.local.name;
    return ChonkyDeviceEntity(
      deviceId: deviceId ?? 'no_device',
      instanceId: "instance-${DateTime.now().millisecondsSinceEpoch}",
      osType: osType ?? 'unknown',
      osVersion: osVersion ?? 'unknown',
      appVersion: packageInfo.version,
      language: language,
      timezone: timezone,
      pushEnabled: true,
    );
  }
}

// --------- ПРОВАЙДЕР-ТОКЕН -------------
class BananaTokenProvider extends ChangeNotifier {
  String? bananaToken;
  void setBananaToken(String? token) {
    bananaToken = token;
    notifyListeners();
  }
}

// --------- ПРОВАЙДЕР-ЛОАДЕР -------------
class CrazyLoaderProvider extends ChangeNotifier {
  double crazyProgress = 0.0;
  void setCrazyProgress(double value) {
    crazyProgress = value;
    notifyListeners();
  }
}

// --------- АНАЛИТИКА-АНАНАС -------------
class PineappleAnalyticsVM extends ChangeNotifier {
  AppsflyerSdk? _sdk;
  String pineappleId = "";
  String pineappleConversion = "";

  void initPineapple(VoidCallback onUpdate) {
    final options = AppsFlyerOptions(
      afDevKey: "qsBLmy7dAXDQhowM8V3ca4",
      appId: "6747172624",
      showDebug: true,
    );
    _sdk = AppsflyerSdk(options);
    _sdk?.initSdk(
      registerConversionDataCallback: true,
      registerOnAppOpenAttributionCallback: true,
      registerOnDeepLinkingCallback: true,
    );
    _sdk?.startSDK(
      onSuccess: () => print("Pineapple Analytics started!"),
      onError: (int code, String msg) => print("Pineapple error $code $msg"),
    );
    _sdk?.onInstallConversionData((result) {
      pineappleConversion = result.toString();
      onUpdate();
    });
    _sdk?.getAppsFlyerUID().then((val) {
      pineappleId = val.toString();
      onUpdate();
    });
  }
}

// --------- PUSH-ОПОВЕЩЕНИЯ-АПЕЛЬСИН -------------
class OrangePushManager extends ChangeNotifier {
  String? orangeToken;
  bool isJuicing = true;

  Future<void> squeezeOrangeToken({Function(String)? onJuice}) async {
    try {
      OrangeTokenChannel.listenJuicy((token) {
        orangeToken = token;
        isJuicing = false;
        notifyListeners();
        if (onJuice != null) onJuice(token);
      });
      Future.delayed(const Duration(seconds: 8), () {
        if (isJuicing) {
          isJuicing = false;
          orangeToken = "";
          notifyListeners();
          if (onJuice != null) onJuice("");
        }
      });
    } catch (e, stack) {
      print("OrangePushManager.squeezeOrangeToken error: $e\n$stack");
      isJuicing = false;
      orangeToken = "";
      notifyListeners();
      if (onJuice != null) onJuice("");
    }
  }
}

// --------- КАНАЛ-ТОКЕН-ОРАНЖ -------------
class OrangeTokenChannel {
  static const MethodChannel _c = MethodChannel('com.example.fcm/token');
  static void listenJuicy(Function(String token) onJuice) {
    _c.setMethodCallHandler((call) async {
      if (call.method == 'setToken') {
        final String token = call.arguments as String;
        onJuice(token);
      }
    });
  }
}

// --------- MVVM-КЛАСС ДЛЯ ВЕБВЬЮ (КОТ-ВИДЖЕТ) -------------
class CatWebViewModel extends ChangeNotifier {
  bool isMeowing = false;
  InAppWebViewController? catWebController;

  void setMeowing(bool value) {
    isMeowing = value;
    notifyListeners();
  }

  Future<void> callSuperInjector(
      ChonkyDeviceEntity entity, String? orangeToken) async {
    final injector = BananaSingleton().nestedInjector;
    final controller = catWebController!;
    await injector
        .dataMegaInjector
        .dataSubInjector
        .catnipInjector
        .injectCatnip(controller, entity, orangeToken);
  }

  Future<void> callSuperPurrInjector(
      PineappleAnalyticsVM analyticsVM,
      ChonkyDeviceEntity deviceEntity,
      String? orangeToken) async {
    final injector = BananaSingleton().nestedInjector;
    final controller = catWebController!;
    final data = {
      "content": {
        "af_data": analyticsVM.pineappleConversion,
        "af_id": analyticsVM.pineappleId,
        "fb_app_name": "Sushiroll",
        "app_name": "Sushiroll",
        "deep": null,
        "bundle_identifier": "sushiroll.cushiorl.surollx",
        "app_version": "1.0.0",
        "apple_id": "6747172624",
        "fcm_token": orangeToken ?? "no_fcm_token",
        "device_id": deviceEntity.deviceId ?? "no_device",
        "instance_id": deviceEntity.instanceId ?? "no_instance",
        "platform": deviceEntity.osType ?? "no_type",
        "os_version": deviceEntity.osVersion ?? "no_os",
        "app_version": deviceEntity.appVersion ?? "no_app",
        "language": deviceEntity.language ?? "en",
        "timezone": deviceEntity.timezone ?? "UTC",
        "push_enabled": deviceEntity.pushEnabled,
        "useruid": analyticsVM.pineappleId,
      },
    };
    await injector
        .dataMegaInjector
        .dataSubInjector
        .pineapplePurrInjector
        .injectPurr(controller, data);
  }
}

// --------- MAIN -------------
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(_bananaBgHandler);

  if (Platform.isAndroid) {
    await InAppWebViewController.setWebContentsDebuggingEnabled(true);
  }
  tzd.initializeTimeZones();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => BananaSingleton().loaderProvider),
        ChangeNotifierProvider(create: (context) => BananaSingleton().tokenProvider),
        ChangeNotifierProvider(create: (context) => BananaSingleton().analyticsVM),
        ChangeNotifierProvider(create: (context) => BananaSingleton().pushManager),
      ],
      child: MaterialApp(home: ChubbyTokenInitPage()),
    ),
  );
}

@pragma('vm:entry-point')
Future<void> _bananaBgHandler(RemoteMessage msg) async {
  print("Banana BG Message: ${msg.messageId}");
  print("Banana BG Data: ${msg.data}");
}

// --------- СТРАНИЦА СБОРКИ ТОКЕНА -------------
class ChubbyTokenInitPage extends StatefulWidget {
  const ChubbyTokenInitPage({super.key});
  @override
  State<ChubbyTokenInitPage> createState() => _ChubbyTokenInitPageState();
}

class _ChubbyTokenInitPageState extends State<ChubbyTokenInitPage> {
  @override
  void initState() {
    super.initState();

    BananaSingleton().tokenProvider.setBananaToken(null);

    OrangeTokenChannel.listenJuicy((token) {
      BananaSingleton().tokenProvider.setBananaToken(token);
      print('🍌 FCM Banana Token updated: $token');

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => CrazyUniWebPage(token)),
            (Route<dynamic> route) => false,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

// --------- КЛАСС КОТОРЫЙ ОТКРЫВАЕТ ВЕБВЬЮ (MVVM) -------------
class CrazyUniWebPage extends StatefulWidget {
  final String? bananaToken;
  const CrazyUniWebPage(this.bananaToken, {super.key});
  @override
  State<CrazyUniWebPage> createState() => _CrazyUniWebPageState();
}

class _CrazyUniWebPageState extends State<CrazyUniWebPage> {
  late InAppWebViewController _catController;
  final CatWebViewModel _catWebVM = CatWebViewModel();
  final String _crazyUrl = "https://game.2stickgame.asia/";
  late ChonkyDeviceEntity _chonkyDevice;
  final List<ContentBlocker> contentBlockers = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    for (final adUrlFilter in BANANA_AD_URLS) {
      contentBlockers.add(
        ContentBlocker(
          trigger: ContentBlockerTrigger(urlFilter: adUrlFilter),
          action: ContentBlockerAction(type: ContentBlockerActionType.BLOCK),
        ),
      );
    }
    contentBlockers.add(ContentBlocker(
      trigger: ContentBlockerTrigger(
        urlFilter: ".cookie",
        resourceType: [ContentBlockerTriggerResourceType.RAW],
      ),
      action: ContentBlockerAction(
        type: ContentBlockerActionType.BLOCK,
        selector: ".notification",
      ),
    ));
    contentBlockers.add(ContentBlocker(
      trigger: ContentBlockerTrigger(
        urlFilter: ".cookie",
        resourceType: [ContentBlockerTriggerResourceType.RAW],
      ),
      action: ContentBlockerAction(
        type: ContentBlockerActionType.CSS_DISPLAY_NONE,
        selector: ".privacy-info",
      ),
    ));
    contentBlockers.add(ContentBlocker(
      trigger: ContentBlockerTrigger(urlFilter: ".*"),
      action: ContentBlockerAction(
        type: ContentBlockerActionType.CSS_DISPLAY_NONE,
        selector: ".banner, .banners, .ads, .ad, .advert",
      ),
    ));
    _setupChannels();
    FirebaseMessaging.onBackgroundMessage(_bananaBgHandler);
    _initChubbyATT();
    BananaSingleton().analyticsVM.initPineapple(() {
      setState(() {});
    });
    _initChonkyData();
    _initChubbyFCM();

    FirebaseMessaging.onMessage.listen((RemoteMessage msg) {
      if (msg.data['uri'] != null) {
        _loadBananaUrl(msg.data['uri'].toString());
      } else {
        _resetBananaUrl();
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage msg) {
      if (msg.data['uri'] != null) {
        _loadBananaUrl(msg.data['uri'].toString());
      } else {
        _resetBananaUrl();
      }
    });

    Future.delayed(const Duration(seconds: 6), () async {
      await _catWebVM.callSuperPurrInjector(
        BananaSingleton().analyticsVM,
        _chonkyDevice,
        widget.bananaToken,
      );
    });
  }

  Future<void> _initChubbyFCM() async {
    FirebaseMessaging m = FirebaseMessaging.instance;
    await m.requestPermission(alert: true, badge: true, sound: true);
  }

  Future<void> _initChubbyATT() async {
    final TrackingStatus s =
    await AppTrackingTransparency.trackingAuthorizationStatus;
    if (s == TrackingStatus.notDetermined) {
      await Future.delayed(const Duration(milliseconds: 1000));
      await AppTrackingTransparency.requestTrackingAuthorization();
    }
    final uuid = await AppTrackingTransparency.getAdvertisingIdentifier();
    print("CHUBBY UUID: $uuid");
  }


  void _setupChannels() {
    MethodChannel('com.example.fcm/notification').setMethodCallHandler((
        call,
        ) async {
      if (call.method == "onNotificationTap") {
        final Map<String, dynamic> data = Map<String, dynamic>.from(
          call.arguments,
        );
        if (data["uri"] != null && !data["uri"].contains("Нет URI")) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (context) => SushiRollPushPage(data["uri"]),
            ),
                (route) => false,
          );
        }
      }
    });
  }

  Future<void> _initChonkyData() async {
    _chonkyDevice = await BananaSingleton().deviceRepo.fetchWatermelonInfo();
    if (_catController != null) {
      await _catWebVM.callSuperInjector(_chonkyDevice, widget.bananaToken);
    }
    setState(() {});
  }

  void _loadBananaUrl(String uri) async {
    if (_catController != null) {
      await _catController.loadUrl(urlRequest: URLRequest(url: WebUri(uri)));
    }
  }

  void _resetBananaUrl() async {
    Future.delayed(const Duration(seconds: 3), () {
      if (_catController != null) {
        _catController.loadUrl(urlRequest: URLRequest(url: WebUri(_crazyUrl)));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    _setupChannels();
    return Scaffold(
      body: Stack(
        children: [
          InAppWebView(
            initialSettings: InAppWebViewSettings(
              javaScriptEnabled: true,
              disableDefaultErrorPage: true,
              contentBlockers: contentBlockers,
              userAgent: 'random',
              mediaPlaybackRequiresUserGesture: false,
              allowsInlineMediaPlayback: true,
              allowsPictureInPictureMediaPlayback: true,
              useOnDownloadStart: true,
              supportZoom: true,
              javaScriptCanOpenWindowsAutomatically: true,
            ),
            initialUrlRequest: URLRequest(url: WebUri(_crazyUrl)),
            onWebViewCreated: (controller) {
              _catController = controller;
              _catWebVM.catWebController = controller;


                _catController = controller;
                _catWebVM.catWebController = controller;

                _catWebVM.catWebController?.addJavaScriptHandler(
                  handlerName: 'onServerResponse',
                  callback: (args) async {
                    print("😺 JS args: $args");
                    // args может быть как Map, так и List (в зависимости от JS).
                    // Универсально:

                    print("😺 JS URLargs:" +args[0]["url"]);


                    if (args[0]["url"].toString()==("https://play.famobi.com/sushi-roll?ctag=1750251981986-4782004&btag=sushiroll_cushiorl_surollx")) {
                      final famobiUrl = Uri.parse(args[0]["url"].toString());

                    //    await launchUrl(famobiUrl, mode: LaunchMode.externalApplication);

                      return null; // или любой ответ JS (если нужно)
                    }
                    // Обычное поведение
                    if (args is List && args.length > 1) {
                      return args.reduce((curr, next) => curr + next);
                    }
                    return args;
                  },
                );

            },
            onLoadStop: (controller, url) async {
              print("🍌 load my url $url");
              await controller.evaluateJavascript(
                source: "console.log('Hello from JS!');",
              );
            await _catWebVM.callSuperInjector(_chonkyDevice, widget.bananaToken);
            },
            shouldOverrideUrlLoading: (controller, navigationAction) async {
              return NavigationActionPolicy.ALLOW;
            },
          ),
          if (_isLoading) const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}