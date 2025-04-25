import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'home_screen.dart';

class HistoryScreen extends StatefulWidget {
  @override
  _HistoryScreenState createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  DateTime selectedDate = DateTime.now();
  List<Map<String, dynamic>> tempHistory = [
    {'value': 37.2, 'timestamp': DateTime.now().subtract(Duration(minutes: 5))},
    {'value': 37.8, 'timestamp': DateTime.now().subtract(Duration(hours: 1))},
    {'value': 38.1, 'timestamp': DateTime.now().subtract(Duration(days: 1))},
    {'value': 36.8, 'timestamp': DateTime.now().subtract(Duration(days: 2))},
    {'value': 37.5, 'timestamp': DateTime.now()},
  ];

  List<Map<String, dynamic>> getFilteredHistory() {
    return tempHistory
        .where((entry) =>
    entry['timestamp'].year == selectedDate.year &&
        entry['timestamp'].month == selectedDate.month &&
        entry['timestamp'].day == selectedDate.day)
        .toList();
  }

  Color getTemperatureColor(double value) {
    if (value >= 38.0) return Colors.red;
    if (value >= 37.5) return Colors.orange;
    if (value >= 36.5) return Colors.green;
    return Colors.blue;
  }

  String formatDateTime(DateTime dateTime) {
    return DateFormat('MMM d, yyyy - h:mm a').format(dateTime);
  }

  String formatTime(DateTime dateTime) {
    return DateFormat('h:mm a').format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    final filteredHistory = getFilteredHistory();

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        title: Text(
          "Temperature History",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.home),
            onPressed: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => HomeScreen()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          Container(
            padding: EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 5,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Select Date",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                ),
                SizedBox(height: 8),
                InkWell(
                  onTap: () async {
                    final DateTime? pickedDate = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                      builder: (context, child) {
                        return Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: ColorScheme.light(
                              primary: Colors.teal,
                              onPrimary: Colors.white,
                              onSurface: Colors.black,
                            ),
                          ),
                          child: child!,
                        );
                      },
                    );
                    if (pickedDate != null && pickedDate != selectedDate) {
                      setState(() {
                        selectedDate = pickedDate;
                      });
                    }
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          DateFormat('EEEE, MMMM d, yyyy').format(selectedDate),
                          style: TextStyle(fontSize: 16),
                        ),
                        Icon(Icons.calendar_today, color: Colors.teal),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: filteredHistory.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.history,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  SizedBox(height: 16),
                  Text(
                    "No temperature records found",
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Try selecting a different date",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            )
                : ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: filteredHistory.length,
              itemBuilder: (context, index) {
                final temp = filteredHistory[index];
                final double value = temp['value'];
                final DateTime timestamp = temp['timestamp'];
                final Color tempColor = getTemperatureColor(value);

                return Container(
                  margin: EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ListTile(
                    contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    leading: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: tempColor.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Icon(
                          Icons.thermostat_rounded,
                          color: tempColor,
                          size: 28,
                        ),
                      ),
                    ),
                    title: Row(
                      children: [
                        Text(
                          "${value.toStringAsFixed(1)}°C",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: tempColor,
                          ),
                        ),
                        SizedBox(width: 8),
                        _getTemperatureStatusWidget(value),
                      ],
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        formatTime(timestamp),
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 15,
                        ),
                      ),
                    ),
                    trailing: IconButton(
                      icon: Icon(Icons.more_vert),
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          builder: (context) => _buildBottomSheet(temp),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.teal,
        child: Icon(Icons.add),
        onPressed: () {
          // Add new temperature record
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Add new temperature feature coming soon!")),
          );
        },
      ),
    );
  }

  Widget _getTemperatureStatusWidget(double value) {
    String status;
    Color color;

    if (value >= 38.0) {
      status = "Fever";
      color = Colors.red;
    } else if (value >= 37.5) {
      status = "Elevated";
      color = Colors.orange;
    } else if (value >= 36.5) {
      status = "Normal";
      color = Colors.green;
    } else {
      status = "Low";
      color = Colors.blue;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildBottomSheet(Map<String, dynamic> tempData) {
    final double value = tempData['value'];
    final DateTime timestamp = tempData['timestamp'];

    return Container(
      padding: EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Temperature Details",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          ListTile(
            leading: Icon(Icons.thermostat, color: getTemperatureColor(value)),
            title: Text("Temperature"),
            subtitle: Text("${value.toStringAsFixed(1)}°C"),
          ),
          ListTile(
            leading: Icon(Icons.access_time, color: Colors.blue),
            title: Text("Time"),
            subtitle: Text(formatDateTime(timestamp)),
          ),
          SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              TextButton.icon(
                icon: Icon(Icons.edit),
                label: Text("Edit"),
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Edit feature coming soon!")),
                  );
                },
              ),
              TextButton.icon(
                icon: Icon(Icons.delete, color: Colors.red),
                label: Text(
                  "Delete",
                  style: TextStyle(color: Colors.red),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Delete feature coming soon!")),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}