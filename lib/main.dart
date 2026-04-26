import 'dart:io';
import 'package:blotpay/providers/PackageProvider/beneficiary_provider.dart';
import 'package:blotpay/providers/ReferralProvider/referral_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:freshchat_sdk/freshchat_sdk.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:blotpay/providers/AuthProvider/auth_provider.dart';
import 'package:blotpay/providers/Database/db_provider.dart';
import 'package:blotpay/providers/PackageProvider/airtime2cash_provider.dart';
import 'package:blotpay/providers/PackageProvider/airtime_provider.dart';
import 'package:blotpay/providers/PackageProvider/bulk_sms_provider.dart';
import 'package:blotpay/providers/PackageProvider/cable_provider.dart';
import 'package:blotpay/providers/PackageProvider/data_provider.dart';
import 'package:blotpay/providers/PaymentProvider/payment_provider.dart';
import 'package:blotpay/providers/SlideProvider/slides_provider.dart';
import 'package:blotpay/providers/TransactionProvider/transaction_provider.dart';
import 'package:blotpay/providers/UserProvider/user_provider.dart';
import 'package:blotpay/splash.dart';
import 'package:blotpay/styles/colors.dart';
import 'package:provider/provider.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'providers/PackageProvider/electricity_provider.dart';
import 'providers/PackageProvider/exam_provider.dart';



final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse notificationResponse) {
  // ignore: avoid_print
  print('notification(${notificationResponse.id}) action tapped: '
      '${notificationResponse.actionId} with'
      ' payload: ${notificationResponse.payload}');
  if (notificationResponse.input?.isNotEmpty ?? false) {
    // ignore: avoid_print
    print(
        'notification action tapped with input: ${notificationResponse.input}');
  }
}

Future<void> _initializeFreshchat() async {
  String appId = "34667a33-2005-4f67-b0d8-cb5f1743d597";
  String appKey = "5510036c-0118-4a29-bb54-af9730a11aa3";
  String domain = "msdk.me.freshchat.com";
  Freshchat.init(appId, appKey, domain);
}

Future<void> _initializeLocalNotifications() async {
  const AndroidInitializationSettings initializationSettingsAndroid =
  AndroidInitializationSettings('logo');

  const DarwinInitializationSettings initializationSettingsIOS =
  DarwinInitializationSettings(
    requestAlertPermission: true,
    requestBadgePermission: true,
    requestSoundPermission: true,
  );

  const DarwinInitializationSettings initializationSettingsMacOS =
  DarwinInitializationSettings();

  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: initializationSettingsIOS,
    macOS: initializationSettingsMacOS,
  );

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  if (Platform.isAndroid) {
    final androidImplementation =
    flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    await androidImplementation?.requestNotificationsPermission() ?? false;
    await androidImplementation?.requestExactAlarmsPermission() ?? false;
  }

  if (Platform.isIOS || Platform.isMacOS) {
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
        MacOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }
}

Future<void> _initializeOneSignal() async {
  // Debug logs
  OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
  OneSignal.Debug.setAlertLevel(OSLogLevel.none);

  // Initialize with your OneSignal app ID
  OneSignal.initialize("f73d1186-4a67-4b6b-90be-e0319829d1cb");

  // DO NOT prompt automatically here.
  // Instead, you’ll call OneSignal.Notifications.requestPermission(true)
  // from a settings screen when the user enables notifications.

  // Default: opt-out until user explicitly opts in
  await OneSignal.User.pushSubscription.optOut();
}

Future<void> _checkSavedPreference() async {
  // Respect saved preference
  final prefs = await SharedPreferences.getInstance();
  final enabled = prefs.getBool("push_notifications_enabled") ?? false;
  if (enabled) {
    await OneSignal.User.pushSubscription.optIn();
    print("✅ Push Notifications Enabled (from prefs)");
  } else {
    await OneSignal.User.pushSubscription.optOut();
    print("🔕 Push Notifications Disabled (from prefs)");
  }

}


void main() async{
  WidgetsFlutterBinding.ensureInitialized();

  await _initializeFreshchat();
  await _initializeLocalNotifications();
  await _initializeOneSignal();
  await _checkSavedPreference();

  SystemChrome.setPreferredOrientations(
      [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    // final textTheme = Theme.of(context).textTheme;
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
        statusBarColor: primaryColor,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: black,
        systemNavigationBarDividerColor: black,
        systemNavigationBarIconBrightness: Brightness.light
    ));

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthenticationProvider()),
        ChangeNotifierProvider(create: (_) => DatabaseProvider()),
        ChangeNotifierProvider(create: (_) => SlideProvider()),
        ChangeNotifierProvider(create: (_) => AirtimeProvider()),
        ChangeNotifierProvider(create: (_) => DataProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => CableProvider()),
        ChangeNotifierProvider(create: (_) => ElectricityProvider()),
        ChangeNotifierProvider(create: (_) => ExamProvider()),
        ChangeNotifierProvider(create: (_) => Airtime2CashProvider()),
        ChangeNotifierProvider(create: (_) => BulkSmsProvider()),
        ChangeNotifierProvider(create: (_) => TransactionProvider()),
        ChangeNotifierProvider(create: (_) => PaymentProvider()),
        ChangeNotifierProvider(create: (_) => ReferralProvider()),
        ChangeNotifierProvider(create: (_) => BeneficiaryProvider()),

      ],
      child: MaterialApp(
        title: 'Blotpay',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
            appBarTheme: AppBarTheme(
              color: primaryColor,
            ),
            fontFamily: "Rubik",
            primaryColor: primaryColor),
        home: const SplashScreen(),
      ),
    );
  }
}
