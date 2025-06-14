import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:monitoringtemp/main.dart';

class AlertModel {
  // Singleton instance
  static final AlertModel _instance = AlertModel._internal();
  factory AlertModel() => _instance;
  AlertModel._internal();

  // Notification plugin
  final FlutterLocalNotificationsPlugin _localNotificationsPlugin = FlutterLocalNotificationsPlugin();

  // Alert state
  bool _hasShownMildAlert = false;
  bool _hasShownCriticalAlert = false;
  bool _isPersistentAlert = false;
  DateTime? _lastAlertTime;
  Timer? _persistentAlertTimer;
  double _currentTemp = 0.0;

  // Initialize the notifications plugin
  Future<void> initialize() async {
    // This is typically done in main.dart, but included here for completeness
    // You can remove this if it's already initialized in main.dart
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initSettings = InitializationSettings(android: androidSettings);
    await _localNotificationsPlugin.initialize(initSettings);
  }

  // Show a notification
  Future<void> showNotification(String title, String body) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'temp_alerts_channel', // ID
      'Temperature Alerts', // Name
      channelDescription: 'Notification for temperature thresholds',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );

    const NotificationDetails notificationDetails = NotificationDetails(android: androidDetails);

    await flutterLocalNotificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000, // Unique ID
      title,
      body,
      notificationDetails,
    );
  }

  // Process temperature updates and show alerts if needed
  void processTemperatureUpdate(double newTemp) {
    _currentTemp = newTemp;

    // Cancel any existing timer if temperature normalized
    if (newTemp < 35.0) {
      _resetAlerts();
      return;
    }

    // 🟡 Mild Alert (35 ≤ temp < 40)
    if (newTemp >= 35.0 && newTemp < 40.0) {
      _processMildAlert(newTemp);
    }
    // 🔴 Critical Alert (≥ 40)
    else if (newTemp >= 40.0) {
      _processCriticalAlert(newTemp);
    }
  }

  // Reset all alert states
  void _resetAlerts() {
    _persistentAlertTimer?.cancel();
    _persistentAlertTimer = null;
    _isPersistentAlert = false;
    _hasShownMildAlert = false;
    _hasShownCriticalAlert = false;
  }

  // Process mild temperature alerts
  void _processMildAlert(double temp) {
    if (!_hasShownMildAlert) {
      // First time alert
      _hasShownMildAlert = true;
      _hasShownCriticalAlert = false;
      _lastAlertTime = DateTime.now();
      showNotification("Mild Fever Alert", "Temperature has reached $temp°C");

      // Start timer for persistent alert
      _persistentAlertTimer = Timer(const Duration(minutes: 1), () {
        if (_currentTemp >= 38.0 && _currentTemp < 40.0) {
          _isPersistentAlert = true;
          showNotification("Persistent Mild Fever",
              "Temperature remains high at $temp°C for 1 minute");
        }
      });
    }
    else if (_isPersistentAlert) {
      // Reset for next persistent alert
      _isPersistentAlert = false;
      _persistentAlertTimer = Timer(const Duration(minutes: 1), () {
        if (_currentTemp >= 38.0 && _currentTemp < 40.0) {
          _isPersistentAlert = true;
          showNotification("Persistent Mild Fever",
              "Temperature remains high at $temp°C for another minute");
        }
      });
    }
  }

  // Process critical temperature alerts
  void _processCriticalAlert(double temp) {
    if (!_hasShownCriticalAlert) {
      // First time alert
      _hasShownCriticalAlert = true;
      _hasShownMildAlert = true;
      _lastAlertTime = DateTime.now();
      showNotification("🔥 Critical Alert", "High temperature detected: $temp°C!");

      // Start timer for persistent alert
      _persistentAlertTimer = Timer(const Duration(minutes: 1), () {
        if (_currentTemp >= 40.0) {
          _isPersistentAlert = true;
          showNotification("🔥 Persistent Critical Alert",
              "Dangerous temperature remains at $temp°C for 1 minute");
        }
      });
    }
    else if (_isPersistentAlert) {
      // Reset for next persistent alert
      _isPersistentAlert = false;
      _persistentAlertTimer = Timer(const Duration(minutes: 1), () {
        if (_currentTemp >= 40.0) {
          _isPersistentAlert = true;
          showNotification("🔥 Persistent Critical Alert",
              "Dangerous temperature remains at $temp°C for another minute");
        }
      });
    }
  }

  // Clean up any resources when done
  void dispose() {
    _persistentAlertTimer?.cancel();
  }

  // Check if temperature is in alert range
  bool get hasHighTempAlert => _currentTemp >= 38.0;
}