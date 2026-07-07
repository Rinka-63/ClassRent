import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _androidChannel = AndroidNotificationChannel(
  'classrent_notifications',
  'ClassRent Notifications',
  description: 'Booking, agency, payment, and reminder notifications.',
  importance: Importance.high,
);

class FcmService {
  FcmService(this._client);

  final SupabaseClient _client;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> initialize({required String userId}) async {
    if (_initialized) return;
    _initialized = true;

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initializationSettings = InitializationSettings(
      android: androidSettings,
    );
    await _localNotifications.initialize(initializationSettings);

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_androidChannel);

    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    await _saveCurrentToken(userId);
    _messaging.onTokenRefresh.listen((token) => _saveToken(userId, token));

    FirebaseMessaging.onMessage.listen((message) {
      final notification = message.notification;
      final title = notification?.title ?? message.data['title']?.toString();
      final body = notification?.body ?? message.data['body']?.toString();
      if (title == null && body == null) return;
      _localNotifications.show(
        message.hashCode,
        title,
        body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _androidChannel.id,
            _androidChannel.name,
            channelDescription: _androidChannel.description,
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
        ),
      );
    });
  }

  Future<void> _saveCurrentToken(String userId) async {
    final token = await _messaging.getToken();
    if (token != null && token.isNotEmpty) {
      await _saveToken(userId, token);
    }
  }

  Future<void> _saveToken(String userId, String token) async {
    await _client.from('users').update({'fcm_token': token}).eq('id', userId);
    await _client.from('user_sessions').upsert(
      {
        'user_id': userId,
        'device_id': token,
        'device_os': Platform.operatingSystem,
        'fcm_token': token,
        'last_seen_at': DateTime.now().toUtc().toIso8601String(),
      },
      onConflict: 'user_id,device_id',
    );
  }
}
