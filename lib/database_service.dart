import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class DatabaseService {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  //refresh data each time changes
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  // Stream controllers
  final _userDataController = StreamController<Map<String, dynamic>>.broadcast();
  final _toddlerDataController = StreamController<Map<String, dynamic>>.broadcast();
  final _temperatureController = StreamController<Map<String, dynamic>>.broadcast();
  final _alertsController = StreamController<Map<String, dynamic>>.broadcast();
  final _temperatureHistoryController = StreamController<List<Map<String, dynamic>>>.broadcast();

  // Stream getters
  Stream<Map<String, dynamic>> get userData => _userDataController.stream;
  Stream<Map<String, dynamic>> get toddlerData => _toddlerDataController.stream;
  Stream<Map<String, dynamic>> get temperatureData => _temperatureController.stream;
  Stream<Map<String, dynamic>> get alertsData => _alertsController.stream;
  Stream<List<Map<String, dynamic>>> get temperatureHistory => _temperatureHistoryController.stream;

  // Stored data
  String? _toddlerId;

  // Stream subscriptions for cleanup
  StreamSubscription? _temperatureSubscription;
  StreamSubscription? _alertsSubscription;
  StreamSubscription? _temperatureHistorySubscription;

  void dispose() {
    _temperatureSubscription?.cancel();
    _alertsSubscription?.cancel();
    _temperatureHistorySubscription?.cancel();


    // _userDataController.close();
    // _toddlerDataController.close();
    // _temperatureController.close();
    // _alertsController.close();
    // _temperatureHistoryController.close();
  }

  // Get current user dynamically
  User? get _currentUser => FirebaseAuth.instance.currentUser;

  bool get isUserLoggedIn => _currentUser != null;

  String? get currentUserId => _currentUser?.uid;

  String? get toddlerId => _toddlerId;

  void clearData() {
    _toddlerId = null;
    _temperatureSubscription?.cancel();
    _alertsSubscription?.cancel();
    _temperatureHistorySubscription?.cancel();
    _temperatureSubscription = null;
    _alertsSubscription = null;
    _temperatureHistorySubscription = null;
  }

  Future<void> initialize() async {
    if (!isUserLoggedIn) {
      throw Exception("No user logged in. Please sign in.");
    }
    clearData();
    await loadUserData();
    await loadToddlerData();
    setupRealtimeListeners();
  }

  Future<void> loadUserData() async {
    final currentUser = _currentUser;
    if (currentUser == null) {
      throw Exception("No user logged in");
    }

    final snapshot = await _database.child('users/${currentUser.uid}').get();

    if (!snapshot.exists) {
      throw Exception("User data not found in database");
    }

    final userData = snapshot.value as Map<dynamic, dynamic>;
    _userDataController.add({
      'user_name': userData['user_name']?.toString() ?? "Unknown",
      'user_email': userData['user_email']?.toString() ?? "",
    });
  }

  Future<void> loadToddlerData() async {
    final currentUser = _currentUser;
    if (currentUser == null) {
      throw Exception("No user logged in");
    }

    final userToddlerSnapshot = await _database.child('user_toddler/${currentUser.uid}').get();

    if (!userToddlerSnapshot.exists) {
      _toddlerDataController.add({
        'toddler_name': "No data found",
        'toddler_age': 0,
        'toddler_id': null,
        'has_toddler': false,
      });

      _temperatureController.add({
        'value': '0.0',
        'timestamp': DateTime.now().toIso8601String(),
        'has_data': false,
      });

      _alertsController.add({});
      _temperatureHistoryController.add([]);
      return;
    }

    final toddlerId = (userToddlerSnapshot.value as Map<dynamic, dynamic>).keys.first;
    _toddlerId = toddlerId;

    final toddlerSnapshot = await _database.child('toddlers/$toddlerId').get();

    if (!toddlerSnapshot.exists) {
      _toddlerDataController.add({
        'toddler_name': "No data found",
        'toddler_age': 0,
        'toddler_id': toddlerId,
        'has_toddler': false,
      });

      _temperatureController.add({
        'value': '0.0',
        'timestamp': DateTime.now().toIso8601String(),
        'has_data': false,
      });

      _alertsController.add({});
      _temperatureHistoryController.add([]);
      return;
    }

    final toddlerData = toddlerSnapshot.value as Map<dynamic, dynamic>;
    _toddlerDataController.add({
      'toddler_name': toddlerData['toddler_name']?.toString() ?? "Unknown",
      'toddler_age': (toddlerData['toddler_age'] as num?)?.toInt() ?? 0,
      'toddler_id': toddlerId,
      'has_toddler': true,
    });

    await loadInitialTemperature(toddlerId);
    await loadInitialAlerts(toddlerId);
    await loadTemperatureHistory(toddlerId);
  }

  Future<void> loadInitialTemperature(String toddlerId) async {
    final snapshot = await _database.child('current_temperature/$toddlerId').get();

    if (snapshot.exists) {
      final tempData = snapshot.value as Map<dynamic, dynamic>;
      final updatedTempData = Map<String, dynamic>.from(tempData);
      updatedTempData['has_data'] = true;
      _temperatureController.add(updatedTempData);
    } else {
      _temperatureController.add({
        'value': '0.0',
        'timestamp': DateTime.now().toIso8601String(),
        'has_data': false,
      });
    }
  }

  Future<void> loadInitialAlerts(String toddlerId) async {
    final snapshot = await _database.child('toddler_alerts/$toddlerId').get();

    if (snapshot.exists) {
      final alertsData = snapshot.value as Map<dynamic, dynamic>;
      _alertsController.add(Map<String, dynamic>.from(alertsData));
    } else {
      _alertsController.add({});
    }
  }

  Future<void> loadTemperatureHistory(String toddlerId) async {
    final snapshot = await _database.child('temperature_history/$toddlerId').get();

    if (snapshot.exists) {
      final historyData = snapshot.value as Map<dynamic, dynamic>;
      final List<Map<String, dynamic>> historyList = [];

      historyData.forEach((key, value) {
        final historyEntry = value as Map<dynamic, dynamic>;
        historyList.add({
          'id': key,
          'value': double.tryParse(historyEntry['history_temp']?.toString() ?? '0.0') ?? 0.0,
          'timestamp': DateTime.tryParse(historyEntry['history_timestamp']?.toString() ?? '') ?? DateTime.now(),
        });
      });

      historyList.sort((a, b) => (b['timestamp'] as DateTime).compareTo(a['timestamp'] as DateTime));

      _temperatureHistoryController.add(historyList);
    } else {
      _temperatureHistoryController.add([]);
    }
  }

  void setupRealtimeListeners() {
    if (_toddlerId == null) {
      return;
    }

    _temperatureSubscription?.cancel();
    _alertsSubscription?.cancel();
    _temperatureHistorySubscription?.cancel();

    _temperatureSubscription = _database.child('current_temperature/$_toddlerId').onValue.listen((event) {
      if (event.snapshot.exists) {
        final tempData = event.snapshot.value as Map<dynamic, dynamic>;
        final updatedTempData = Map<String, dynamic>.from(tempData);
        updatedTempData['has_data'] = true;
        _temperatureController.add(updatedTempData);
      } else {
        _temperatureController.add({
          'value': '0.0',
          'timestamp': DateTime.now().toIso8601String(),
          'has_data': false,
        });
      }
    });

    _alertsSubscription = _database.child('toddler_alerts/$_toddlerId').onValue.listen((event) {
      if (event.snapshot.exists) {
        final alertsData = event.snapshot.value as Map<dynamic, dynamic>;
        _alertsController.add(Map<String, dynamic>.from(alertsData));
      } else {
        _alertsController.add({});
      }
    });

    _temperatureHistorySubscription = _database.child('temperature_history/$_toddlerId').onValue.listen((event) {
      if (event.snapshot.exists) {
        final historyData = event.snapshot.value as Map<dynamic, dynamic>;
        final List<Map<String, dynamic>> historyList = [];

        historyData.forEach((key, value) {
          final historyEntry = value as Map<dynamic, dynamic>;
          historyList.add({
            'id': key,
            'value': double.tryParse(historyEntry['history_temp']?.toString() ?? '0.0') ?? 0.0,
            'timestamp': DateTime.tryParse(historyEntry['history_timestamp']?.toString() ?? '') ?? DateTime.now(),
          });
        });

        historyList.sort((a, b) => (b['timestamp'] as DateTime).compareTo(a['timestamp'] as DateTime));
        _temperatureHistoryController.add(historyList);
      } else {
        _temperatureHistoryController.add([]);
      }
    });
  }

  // -- User and Toddler Updates --

  Future<void> updateUserData({required String name, required String email}) async {
    final currentUser = _currentUser;
    if (currentUser == null) throw Exception("No user logged in");
    await _database.child('users/${currentUser.uid}').update({
      'user_name': name,
      'user_email': email,
    });
    await loadUserData();
  }

  Future<void> updateToddlerData({required String toddlerId, required String name, required int age}) async {
    await _database.child('toddlers/$toddlerId').update({
      'toddler_name': name,
      'toddler_age': age,
    });
    await loadToddlerData();
  }

  // -- Other database functions below remain unchanged --

  Future<void> addAlert(Map<String, dynamic> alertData) async {
    if (_toddlerId == null) {
      throw Exception("No toddler ID available");
    }

    final alertsRef = _database.child('toddler_alerts/$_toddlerId').push();
    await alertsRef.set(alertData);
  }

  Future<void> addTemperatureHistory({
    required double temperature,
    required DateTime timestamp,
  }) async {
    if (_toddlerId == null) {
      throw Exception("No toddler ID available");
    }

    try {
      final historyRef = _database.child('temperature_history/$_toddlerId').push();
      await historyRef.set({
        'history_temp': temperature.toString(),
        'history_timestamp': timestamp.toIso8601String(),
      });
    } catch (e) {
      throw Exception("Failed to add temperature history: ${e.toString()}");
    }
  }

  Future<void> deleteTemperatureHistory(String historyId) async {
    if (_toddlerId == null) {
      throw Exception("No toddler ID available");
    }

    try {
      await _database.child('temperature_history/$_toddlerId/$historyId').remove();
    } catch (e) {
      throw Exception("Failed to delete temperature history: ${e.toString()}");
    }
  }

  Future<void> updateTemperatureHistory({
    required String historyId,
    required double temperature,
    required DateTime timestamp,
  }) async {
    if (_toddlerId == null) {
      throw Exception("No toddler ID available");
    }

    try {
      await _database.child('temperature_history/$_toddlerId/$historyId').update({
        'history_temp': temperature.toString(),
        'history_timestamp': timestamp.toIso8601String(),
      });
    } catch (e) {
      throw Exception("Failed to update temperature history: ${e.toString()}");
    }
  }

  Future<void> addToddler({
    required String name,
    required int age,
  }) async {
    final currentUser = _currentUser;
    if (currentUser == null) {
      throw Exception("No user logged in");
    }

    if (name.trim().isEmpty) {
      throw Exception("Toddler name cannot be empty");
    }
    if (age < 1 || age > 10) {
      throw Exception("Toddler age must be between 1 and 10 years");
    }

    try {
      final toddlerRef = _database.child('toddlers').push();
      final toddlerId = toddlerRef.key!;

      await toddlerRef.set({
        'toddler_name': name.trim(),
        'toddler_age': age,
        'created_at': DateTime.now().toIso8601String(),
        'created_by': currentUser.uid,
      });

      await _database.child('user_toddler/${currentUser.uid}/$toddlerId').set({
        'assigned_at': DateTime.now().toIso8601String(),
      });

      await _database.child('current_temperature/$toddlerId').set({
        'value': '0.0',
        'timestamp': DateTime.now().toIso8601String(),
      });

      await _database.child('toddler_alerts/$toddlerId').set({
        'initialized': true,
      });

      await _database.child('temperature_history/$toddlerId').set({
        'initialized': true,
      });

      _toddlerId = toddlerId;
      await loadToddlerData();
      setupRealtimeListeners();
    } catch (e) {
      throw Exception("Failed to add toddler: ${e.toString()}");
    }
  }

  Future<void> removeToddler(String toddlerId) async {
    final currentUser = _currentUser;
    if (currentUser == null) {
      throw Exception("No user logged in");
    }

    try {
      await _database.child('user_toddler/${currentUser.uid}/$toddlerId').remove();
      clearData();
      await loadToddlerData();
    } catch (e) {
      throw Exception("Failed to remove toddler: ${e.toString()}");
    }
  }
}