import 'package:flutter_local_notifications/flutter_local_notifications.dart';

sendNotification(String title, String body) async {
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();
  var android = const AndroidNotificationDetails('id', 'channel',
      channelDescription: 'description',
      priority: Priority.high,
      importance: Importance.max,
    icon: '@mipmap/ic_launcher',
  );
  var iOS = const DarwinNotificationDetails();
  var platform = NotificationDetails(android: android, iOS: iOS);
  await flutterLocalNotificationsPlugin.show(0, title, body, platform,
      payload: "$title|$body");

}