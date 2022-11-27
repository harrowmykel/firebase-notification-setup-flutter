import 'dart:async';
import 'dart:io' show Platform;
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:ng_yoruba_movies_demo/utils/string_util.dart';

///this file stores functions sets up firebase component like
///push notification and controls how notifcations are shown

//handles push notification that are sent when the app is minimised
//or closed. this should be a stand alone function and should not be included
//in the class FirebaseMessagingSetup
Future<void> _firebaseMessagingBackgroundHandler(
  RemoteMessage message,
) async {
  //initialise Firebase core
  await Firebase.initializeApp();
  //set up firebase notification
  await FirebaseMessagingSetup.instance.setupFlutterNotifications();
  //show the message
  FirebaseMessagingSetup.instance.showFlutterNotification(message);
  // If you're going to use other Firebase services in the background, such as Firestore,
  // make sure you call `initializeApp` before using other Firebase services.
  // print('Handling a background message ${message.messageId}');
}

class FirebaseMessagingSetup {
  //singleton instance of this class
  static FirebaseMessagingSetup? _instance;

  // get the instance
  static FirebaseMessagingSetup get instance {
    //init if not yet init-ed
    _instance ??= FirebaseMessagingSetup();
    return _instance!;
  }

  /// Create a [AndroidNotificationChannel] for heads up notifications
  AndroidNotificationChannel? channel;

  //check if we have already initialised flutter notifications
  bool isFlutterLocalNotificationsInitialized = false;

  Future<void> setupFlutterNotifications() async {
    if (isFlutterLocalNotificationsInitialized) {
      return;
    }

    //if is not web platform
    if (kIsWeb) {
      return;
    }
    //handle notifications for android
    channel ??= const AndroidNotificationChannel(
      // id
      'high_importance_channel',
      // title
      'High Importance Notifications',
      // description
      description: 'This channel is used for important notifications.',
      importance: Importance.high,
    );

    flutterLocalNotificationsPlugin ??= FlutterLocalNotificationsPlugin();
    //handle notifications for android
    channel ??= const AndroidNotificationChannel(
      // id
      'high_importance_channel',
      // title
      'High Importance Notifications',
      // description
      description: 'This channel is used for important notifications.',
      importance: Importance.high,
    );

    /// Create an Android Notification Channel.
    ///
    /// We use this channel in the `AndroidManifest.xml` file to override the
    /// default FCM channel to enable heads up notifications.
    await flutterLocalNotificationsPlugin!
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel!);

    /// Update the iOS foreground notification presentation options to allow
    /// heads up notifications.
    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
    isFlutterLocalNotificationsInitialized = true;
  }

  // function  to show a Notification
  void showFlutterNotification(RemoteMessage message) async {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;
    //show android notification
    // print('new notification in Backround');

    //handle notifications for android
    channel ??= AndroidNotificationChannel(
      // id
      'high_importance_channel_' + StringUtil.randomString(length: 2),
      // title
      'High Importance Notifications',
      // description
      description: 'This channel is used for important notifications.',
      importance: Importance.high,
    );

    if (notification != null && android != null && !kIsWeb) {
      DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      bool isLollipop = androidInfo.version.sdkInt == 21;
      flutterLocalNotificationsPlugin ??= FlutterLocalNotificationsPlugin();
      flutterLocalNotificationsPlugin?.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            channel!.id,
            channel!.name,
            channelDescription: channel!.description,
            // lollipop uses only black and white icons
            icon: isLollipop
                ? '@drawable/ic_stat_onesignal_default'
                : '@mipmap/launcher_icon',
          ),
        ),
      );
    }
  }

  /// Initialize the [FlutterLocalNotificationsPlugin] package.
  FlutterLocalNotificationsPlugin? flutterLocalNotificationsPlugin;

  //this function must be called in the main() function in main.dart
  Future<void> initiateOnMain() async {
    await Firebase.initializeApp();
    // Set the background messaging handler early on, as a named top-level function
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    await setupFlutterNotifications();
  }

  //this function must be called in the initSTate of the MyApp in main.dart
  Future<void> initiateInAppInitState(BuildContext context) async {
    Firebase.initializeApp().then((value) {
      //subscribe to the public channel
      FirebaseMessaging.instance.subscribeToTopic('all');

      if (Platform.isAndroid) {
        FirebaseMessaging.instance.subscribeToTopic('android_device');
      } else if (Platform.isIOS) {
        FirebaseMessaging.instance.subscribeToTopic('ios_device');
      }
      FirebaseMessaging.onMessage.listen(showFlutterNotification);

      //if a notification was clicked
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        // print('A new onMessageOpenedApp event was published!');
      });
    });
  }
}
