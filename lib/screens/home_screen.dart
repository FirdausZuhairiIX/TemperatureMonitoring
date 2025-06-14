import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'history_screen.dart';
import 'setting_screen.dart';
import 'alert_screen.dart';
import 'add_toddler.dart';
import 'package:monitoringtemp/database_service.dart';
import 'package:monitoringtemp/model/alert_model.dart';
import 'package:monitoringtemp/model/side_drawer_model.dart';
import 'package:monitoringtemp/model/home_screen_model.dart';
import 'package:monitoringtemp/confirm_user.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  final DatabaseService _databaseService = DatabaseService(); // Singleton
  final AlertModel _alertModel = AlertModel();

  String _userName = "Loading...";
  String _userEmail = "";
  String _toddlerName = "Loading...";
  int _toddlerAge = 0;
  String? _toddlerId;
  bool _hasToddler = true;

  double _currentTemp = 0.0;
  String _lastUpdateTime = "No data";
  late AnimationController _tempAnimationController;
  late Animation<double> _tempAnimation;

  List<Map<String, dynamic>> _alerts = [];
  bool _hasHighTempAlert = false;

  bool _isLoading = true;
  String _errorMessage = "";
  int _currentTabIndex = 0;

  late StreamSubscription _userDataSubscription;
  late StreamSubscription _toddlerDataSubscription;
  late StreamSubscription _temperatureSubscription;
  late StreamSubscription _alertsSubscription;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadInitialData();
  }

  void _initializeAnimations() {
    _tempAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _tempAnimation = Tween<double>(begin: 0, end: 0).animate(_tempAnimationController);
    _tempAnimationController.addListener(() => setState(() {}));
  }

  Future<void> _loadInitialData() async {
    try {
      if (!_databaseService.isUserLoggedIn) {
        setState(() {
          _errorMessage = "No user logged in. Please sign in.";
          _isLoading = false;
        });
        return;
      }
      _setupStreamListeners();
      await _databaseService.initialize();
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _errorMessage = "Failed to load data: ${e.toString()}";
        _isLoading = false;
      });
    }
  }

  void _setupStreamListeners() {
    _userDataSubscription = _databaseService.userData.listen((userData) {
      if (mounted) {
        setState(() {
          _userName = userData['user_name'] ?? "Unknown";
          _userEmail = userData['user_email'] ?? "";
        });
      }
    });

    _toddlerDataSubscription = _databaseService.toddlerData.listen((toddlerData) {
      if (mounted) {
        setState(() {
          _toddlerName = toddlerData['toddler_name'] ?? "No data found";
          _toddlerAge = toddlerData['toddler_age'] ?? 0;
          _toddlerId = toddlerData['toddler_id'];
          _hasToddler = toddlerData['has_toddler'] ?? true;
        });
      }
    });

    _temperatureSubscription = _databaseService.temperatureData.listen((tempData) {
      if (mounted) {
        _updateTemperature(tempData);
      }
    });

    _alertsSubscription = _databaseService.alertsData.listen((alertsData) {
      if (mounted) {
        _processAlerts(alertsData);
      }
    });
  }

  void _updateTemperature(Map<dynamic, dynamic> data) {
    final tempStr = data['value']?.toString() ?? '0.0';
    final newTemp = tempStr.toLowerCase() == 'nan'
        ? 0.0
        : double.tryParse(tempStr) ?? 0.0;
    final timestamp = data['timestamp']?.toString() ?? "Unknown";
    final hasData = data['has_data'] ?? true;

    _tempAnimationController.reset();
    _tempAnimation = Tween<double>(begin: _currentTemp, end: newTemp)
        .animate(_tempAnimationController);
    _tempAnimationController.forward();

    if (hasData && _hasToddler) {
      _alertModel.processTemperatureUpdate(newTemp);
    }

    setState(() {
      _currentTemp = newTemp;
      _lastUpdateTime = hasData && _hasToddler
          ? _formatTimestamp(timestamp)
          : "No data available";
      _hasHighTempAlert = _hasToddler ? _alertModel.hasHighTempAlert : false;
    });
  }

  void _processAlerts(Map<dynamic, dynamic> alertsData) {
    final alertsList = <Map<String, dynamic>>[];

    alertsData.forEach((key, value) {
      if (value is Map) {
        alertsList.add({
          'id': key.toString(),
          'type': value['alert_type']?.toString() ?? 'unknown',
          'temp': value['temperature']?.toString() ?? '0.0',
          'time': _formatTimestamp(value['timestamp']?.toString() ?? 'Unknown'),
        });
      }
    });

    alertsList.sort((a, b) => b['time'].compareTo(a['time']));
    setState(() => _alerts = alertsList);
  }

  String _formatTimestamp(String timestamp) {
    try {
      final dateTime = DateTime.parse(timestamp);
      return DateFormat('MMM dd, hh:mm a').format(dateTime);
    } catch (e) {
      return timestamp;
    }
  }

  void _onTabChanged(int index) {
    setState(() {
      _currentTabIndex = index;
    });
  }

  void _navigateToAddToddler() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddToddlerScreen(
          onToddlerAdded: () {
            _loadInitialData();
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _tempAnimationController.dispose();
    _userDataSubscription.cancel();
    _toddlerDataSubscription.cancel();
    _temperatureSubscription.cancel();
    _alertsSubscription.cancel();
    _alertModel.dispose();
    // Do NOT close _databaseService StreamControllers if using singleton
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double displayTemperature = _tempAnimationController.isAnimating
        ? _tempAnimation.value
        : _currentTemp;
    final List<Color> gradientColors = HomeScreenUI.getBackgroundGradient(displayTemperature);

    if (_isLoading) {
      return HomeScreenUI.buildLoadingScreen(_toddlerName);
    }

    if (_errorMessage.isNotEmpty) {
      return HomeScreenUI.buildErrorScreen(
        context: context,
        errorMessage: _errorMessage,
        onRetry: _loadInitialData,
      );
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          IconButton(
            icon: Badge(
              label: Text(_alerts.length.toString()),
              child: const Icon(Icons.notifications, color: Colors.white),
            ),
            onPressed: () {
              setState(() {
                _currentTabIndex = 1;
              });
            },
          ),
        ],
      ),
      drawer: SideDrawerModel(
        userName: _userName,
        currentTabIndex: _currentTabIndex,
        onTabChanged: _onTabChanged,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: _buildTabContent(displayTemperature),
        ),
      ),
    );
  }

  Widget _buildTabContent(double displayTemperature) {
    switch (_currentTabIndex) {
      case 0:
        return _buildDashboardTab(displayTemperature);
      case 1:
        return _hasToddler
            ? AlertScreen(
          alerts: _alerts,
          databaseService: _databaseService,
        )
            : _buildNoToddlerMessage("No alerts available without toddler assignment");
      case 2:
        return _hasToddler
            ? const HistoryScreen()
            : _buildNoToddlerMessage("No temperature history available without toddler assignment");
      case 3:
        return const SettingsScreen();
      default:
        return _buildDashboardTab(displayTemperature);
    }
  }

  Widget _buildNoToddlerMessage(String message) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.info_outline,
              size: 40,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _navigateToAddToddler,
              icon: const Icon(Icons.add),
              label: const Text('Add Toddler'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF66A6FF),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardTab(double displayTemperature) {
    final tempStatus = HomeScreenUI.getTemperatureStatus(displayTemperature);
    double gaugePosition = (displayTemperature - 35) / 5;
    gaugePosition = gaugePosition.clamp(0.0, 1.0);

    return SingleChildScrollView(
      child: Column(
        children: [
          HomeScreenUI.buildHeaderSection(
            userName: _userName,
            toddlerName: _hasToddler ? _toddlerName : "No toddler assigned",
          ),
          const SizedBox(height: 16),
          HomeScreenUI.buildDateDisplay(),
          if (!_hasToddler) ...[
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.child_care,
                    size: 48,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "No Toddler Assigned",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Add your toddler's information to start temperature monitoring.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _navigateToAddToddler,
                      icon: const Icon(Icons.add),
                      label: const Text('Add Toddler'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF66A6FF),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            HomeScreenUI.buildToddlerInfoCard(
              toddlerName: _toddlerName,
              toddlerAge: _toddlerAge,
            ),
            HomeScreenUI.buildTemperatureCard(
              context: context,
              displayTemperature: displayTemperature,
              gaugePosition: gaugePosition,
              tempStatus: tempStatus,
              lastUpdateTime: _lastUpdateTime,
            ),

            // ---- Bluetooth button BELOW the gauge ----
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.bluetooth),
                  label: const Text("Connect to Device"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2A54D5),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    textStyle: const TextStyle(fontSize: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _toddlerId == null
                      ? null
                      : () async {
                    // Optionally: show a loading indicator here

                    // Navigate and send user to device
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ConfirmUserPage(
                          loggedInUser: _toddlerId!,
                        ),
                      ),
                    );

                    // Optionally: handle result or show a snackbar
                    if (result != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(result.toString())),
                      );
                    }
                  },
                ),
              ),
            )

          ],
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}