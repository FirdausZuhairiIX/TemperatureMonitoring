import 'package:flutter/material.dart';
import 'package:monitoringtemp/database_service.dart';
import 'dart:async';
import 'package:intl/intl.dart';

class AlertScreen extends StatefulWidget {
  final List<Map<String, dynamic>> alerts;
  final DatabaseService databaseService;

  const AlertScreen({
    Key? key,
    required this.alerts,
    required this.databaseService,
  }) : super(key: key);

  @override
  State<AlertScreen> createState() => _AlertScreenState();
}

class _AlertScreenState extends State<AlertScreen> {
  late List<Map<String, dynamic>> _alerts;
  late StreamSubscription _alertsSubscription;
  late StreamSubscription _temperatureSubscription;

  @override
  void initState() {
    super.initState();
    _alerts = widget.alerts;

    // Listen to alerts data
    _alertsSubscription = widget.databaseService.alertsData.listen((alertsData) {
      _processAlerts(alertsData);
    });

    // Listen to temperature data
    _temperatureSubscription = widget.databaseService.temperatureData.listen((tempData) {
      _checkForHighTemperature(tempData);
    });
  }

  @override
  void dispose() {
    _alertsSubscription.cancel();
    _temperatureSubscription.cancel();
    super.dispose();
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
          'location': value['location']?.toString() ?? 'Unknown location',
        });
      }
    });

    alertsList.sort((a, b) => b['time'].compareTo(a['time']));
    setState(() => _alerts = alertsList);
  }

  void _checkForHighTemperature(Map<dynamic, dynamic> tempData) {
    tempData.forEach((key, value) async {
      if (value is Map && value.containsKey('temperature') && value.containsKey('timestamp')) {
        double? temperature = double.tryParse(value['temperature'].toString());
        if (temperature != null && temperature >= 35.0) {
          // Save alert to database
          await widget.databaseService.addAlert({
            'alert_type': 'High Temperature',
            'temperature': temperature,
            'timestamp': value['timestamp'],
            'location': value['location'] ?? 'Unknown location',
          });
        }
      }
    });
  }

  String _formatTimestamp(String timestamp) {
    try {
      final dateTime = DateTime.parse(timestamp);
      return DateFormat('MMM dd, hh:mm a').format(dateTime);
    } catch (e) {
      return timestamp;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(20.0),
          child: Text(
            "Temperature Alerts",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(30),
                topRight: Radius.circular(30),
              ),
            ),
            child: _alerts.isEmpty
                ? _buildNoAlertsView()
                : ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: _alerts.length,
              itemBuilder: (context, index) {
                final alert = _alerts[index];
                final isHighAlert = double.tryParse(alert['temp'].toString()) != null &&
                    double.parse(alert['temp'].toString()) >= 35.0;

                return _buildAlertCard(alert, isHighAlert, index);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNoAlertsView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_outline, size: 70, color: Colors.green),
          SizedBox(height: 16),
          Text("No Alerts", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          Text("Everything looks good. No temperature alerts.", style: TextStyle(color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildAlertCard(Map<String, dynamic> alert, bool isHighAlert, int index) {
    return Card(
      elevation: 3,
      margin: EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(
          color: isHighAlert ? Colors.red.shade200 : Colors.orange.shade200,
          width: 1,
        ),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: isHighAlert ? Colors.red.shade100 : Colors.orange.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            isHighAlert ? Icons.warning_rounded : Icons.info_outline,
            color: isHighAlert ? Colors.red : Colors.orange,
            size: 28,
          ),
        ),
        title: Text(
          isHighAlert ? "High Temperature Alert" : "Temperature Alert",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 6),
            Text("${alert['temp']}°C at ${alert['time']}", style: TextStyle(fontSize: 15, color: Colors.grey[700])),
            SizedBox(height: 4),
            Text(alert['location'] ?? "Unknown location", style: TextStyle(fontSize: 14, color: Colors.grey[600])),
          ],
        ),
        trailing: IconButton(
          icon: Icon(Icons.more_vert),
          onPressed: () => _showAlertOptions(context, index),
        ),
        onTap: () => _showAlertDetails(context, alert),
      ),
    );
  }

  void _showAlertDetails(BuildContext context, Map<String, dynamic> alert) {
    // Your existing bottom sheet alert detail implementation
  }

  void _showAlertOptions(BuildContext context, int index) {
    // Your existing bottom sheet alert options implementation
  }

  void _dismissAlert(int index) {
    setState(() {
      _alerts.removeAt(index);
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Alert dismissed"), duration: Duration(seconds: 2)));
  }

  void _muteAlert(int index) {
    setState(() {
      _alerts[index]['muted'] = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Alert muted"), duration: Duration(seconds: 2)));
  }

  void _shareAlert(Map<String, dynamic> alert) {
    final String message =
        "Temperature Alert: ${alert['temp']}°C at ${alert['time']} in ${alert['location'] ?? 'Unknown location'}";
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Sharing alert..."), duration: Duration(seconds: 2)));
  }

  void _resolveAlert(Map<String, dynamic> alert) {
    final index = _alerts.indexWhere((a) =>
    a['temp'] == alert['temp'] && a['time'] == alert['time'] && a['location'] == alert['location']);

    if (index != -1) {
      setState(() {
        _alerts.removeAt(index);
      });
    }

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Alert resolved"), duration: Duration(seconds: 2)));
  }
}
