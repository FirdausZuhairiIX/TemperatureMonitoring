import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'home_screen.dart';
import 'package:monitoringtemp/database_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  _HistoryScreenState createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  DateTime? selectedDate; // Made nullable - null means show latest records
  List<Map<String, dynamic>> tempHistory = [];
  bool isLoading = true;
  String errorMessage = '';

  late DatabaseService _databaseService;

  @override
  void initState() {
    super.initState();
    _databaseService = DatabaseService();
    _initializeData();
  }

  @override
  void dispose() {
    _databaseService.dispose();
    super.dispose();
  }

  Future<void> _initializeData() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = '';
      });

      await _databaseService.initialize();

      // Listen to temperature history changes
      _databaseService.temperatureHistory.listen((history) {
        if (mounted) {
          setState(() {
            tempHistory = history;
            isLoading = false;
          });
        }
      });

    } catch (e) {
      if (mounted) {
        setState(() {
          errorMessage = e.toString();
          isLoading = false;
        });
      }
    }
  }

  List<Map<String, dynamic>> getFilteredHistory() {
    if (selectedDate == null) {
      // Show latest 5 records when no date is selected
      List<Map<String, dynamic>> sortedHistory = List.from(tempHistory);
      sortedHistory.sort((a, b) => b['timestamp'].compareTo(a['timestamp']));
      return sortedHistory.take(5).toList();
    } else {
      // Filter by selected date
      return tempHistory
          .where((entry) =>
      entry['timestamp'].year == selectedDate!.year &&
          entry['timestamp'].month == selectedDate!.month &&
          entry['timestamp'].day == selectedDate!.day)
          .toList();
    }
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

  // Clear date filter to show latest records
  void _clearDateFilter() {
    setState(() {
      selectedDate = null;
    });
  }

  void _showAddTemperatureDialog() {
    final TextEditingController tempController = TextEditingController();
    DateTime selectedDateTime = DateTime.now();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add Temperature Record'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: tempController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Temperature (°C)',
                  hintText: 'e.g., 37.5',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('Date & Time'),
                subtitle: Text(formatDateTime(selectedDateTime)),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: selectedDateTime,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (date != null) {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.fromDateTime(selectedDateTime),
                    );
                    if (time != null) {
                      setDialogState(() {
                        selectedDateTime = DateTime(
                          date.year,
                          date.month,
                          date.day,
                          time.hour,
                          time.minute,
                        );
                      });
                    }
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final tempText = tempController.text.trim();
                if (tempText.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a temperature')),
                  );
                  return;
                }

                final temperature = double.tryParse(tempText);
                if (temperature == null || temperature < 30.0 || temperature > 45.0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a valid temperature between 30.0 and 45.0°C')),
                  );
                  return;
                }

                try {
                  await _databaseService.addTemperatureHistory(
                    temperature: temperature,
                    timestamp: selectedDateTime,
                  );

                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Temperature record added successfully!')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to add temperature record: $e')),
                  );
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditTemperatureDialog(Map<String, dynamic> tempData) {
    final TextEditingController tempController = TextEditingController(
      text: tempData['value'].toStringAsFixed(1),
    );
    DateTime selectedDateTime = tempData['timestamp'];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Edit Temperature Record'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: tempController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Temperature (°C)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('Date & Time'),
                subtitle: Text(formatDateTime(selectedDateTime)),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: selectedDateTime,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (date != null) {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.fromDateTime(selectedDateTime),
                    );
                    if (time != null) {
                      setDialogState(() {
                        selectedDateTime = DateTime(
                          date.year,
                          date.month,
                          date.day,
                          time.hour,
                          time.minute,
                        );
                      });
                    }
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final tempText = tempController.text.trim();
                if (tempText.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a temperature')),
                  );
                  return;
                }

                final temperature = double.tryParse(tempText);
                if (temperature == null || temperature < 30.0 || temperature > 45.0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a valid temperature between 30.0 and 45.0°C')),
                  );
                  return;
                }

                try {
                  await _databaseService.updateTemperatureHistory(
                    historyId: tempData['id'],
                    temperature: temperature,
                    timestamp: selectedDateTime,
                  );

                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Temperature record updated successfully!')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to update temperature record: $e')),
                  );
                }
              },
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }

  void _deleteTemperatureRecord(Map<String, dynamic> tempData) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Temperature Record'),
        content: Text(
          'Are you sure you want to delete the temperature record of ${tempData['value'].toStringAsFixed(1)}°C recorded on ${formatDateTime(tempData['timestamp'])}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              try {
                await _databaseService.deleteTemperatureHistory(tempData['id']);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Temperature record deleted successfully!')),
                );
              } catch (e) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to delete temperature record: $e')),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        backgroundColor: Colors.grey[100],
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          title: const Text(
            "Temperature History",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (errorMessage.isNotEmpty) {
      return Scaffold(
        backgroundColor: Colors.grey[100],
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          title: const Text(
            "Temperature History",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 80,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                "Error loading data",
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  errorMessage,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _initializeData,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final filteredHistory = getFilteredHistory();

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        title: const Text(
          "Temperature History",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => const HomeScreen()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: const BoxDecoration(
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      selectedDate == null ? "Latest Records" : "Filter by Date",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                    ),
                    if (selectedDate != null)
                      TextButton.icon(
                        onPressed: _clearDateFilter,
                        icon: const Icon(Icons.clear, size: 16),
                        label: const Text("Show Latest", style: TextStyle(fontSize: 12)),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () async {
                    final DateTime? pickedDate = await showDatePicker(
                      context: context,
                      initialDate: selectedDate ?? DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                      builder: (context, child) {
                        return Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: const ColorScheme.light(
                              primary: Colors.teal,
                              onPrimary: Colors.white,
                              onSurface: Colors.black,
                            ),
                          ),
                          child: child!,
                        );
                      },
                    );
                    if (pickedDate != null) {
                      setState(() {
                        selectedDate = pickedDate;
                      });
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                      color: selectedDate == null ? Colors.grey[50] : Colors.white,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          selectedDate == null
                              ? "Tap to filter by specific date"
                              : DateFormat('EEEE, MMMM d, yyyy').format(selectedDate!),
                          style: TextStyle(
                            fontSize: 16,
                            color: selectedDate == null ? Colors.grey[600] : Colors.black87,
                            fontStyle: selectedDate == null ? FontStyle.italic : FontStyle.normal,
                          ),
                        ),
                        const Icon(Icons.calendar_today, color: Colors.teal),
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
                  const SizedBox(height: 16),
                  Text(
                    selectedDate == null
                        ? "No temperature records found"
                        : "No records for selected date",
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    selectedDate == null
                        ? "Add some temperature records to get started"
                        : "Try selecting a different date or clear the filter",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filteredHistory.length,
              itemBuilder: (context, index) {
                final temp = filteredHistory[index];
                final double value = temp['value'];
                final DateTime timestamp = temp['timestamp'];
                final Color tempColor = getTemperatureColor(value);

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
                        const SizedBox(width: 8),
                        _getTemperatureStatusWidget(value),
                      ],
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        selectedDate == null
                            ? formatDateTime(timestamp) // Show full date and time for latest records
                            : formatTime(timestamp), // Show only time for date-filtered records
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 15,
                        ),
                      ),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.more_vert),
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
        child: const Icon(Icons.add),
        onPressed: _showAddTemperatureDialog,
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Row(
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
          const SizedBox(height: 20),
          ListTile(
            leading: Icon(Icons.thermostat, color: getTemperatureColor(value)),
            title: const Text("Temperature"),
            subtitle: Text("${value.toStringAsFixed(1)}°C"),
          ),
          ListTile(
            leading: const Icon(Icons.access_time, color: Colors.blue),
            title: const Text("Time"),
            subtitle: Text(formatDateTime(timestamp)),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              TextButton.icon(
                icon: const Icon(Icons.edit),
                label: const Text("Edit"),
                onPressed: () {
                  Navigator.pop(context);
                  _showEditTemperatureDialog(tempData);
                },
              ),
              TextButton.icon(
                icon: const Icon(Icons.delete, color: Colors.red),
                label: const Text(
                  "Delete",
                  style: TextStyle(color: Colors.red),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  _deleteTemperatureRecord(tempData);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}